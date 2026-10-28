#!/usr/bin/env bash
# Print the authoritative Kangentic card UUID for an artifact directory.
set -euo pipefail

card_dir="${1:?usage: card-id.sh .kanban/<card-directory>}"
[[ -d "$card_dir" ]] || { echo "card-id: no card directory: ${card_dir}" >&2; exit 1; }

metadata="${card_dir}/card.json"
if [[ -f "$metadata" ]]; then
  python3 - "$metadata" <<'PY'
import json
import re
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as source:
        card_id = json.load(source).get("id", "")
except (OSError, json.JSONDecodeError) as error:
    raise SystemExit(f"card-id: cannot read {path}: {error}")

if not re.fullmatch(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", card_id):
    raise SystemExit(f"card-id: invalid id in {path}")
print(card_id)
PY
  exit 0
fi

# Compatibility for active `<uuid>` directories and historical
# `<number>-<uuid>` directories created before card.json became authoritative.
name="$(basename "$card_dir")"
card_id="$(sed -nE 's/^([0-9]+-)?([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/\2/p' <<<"$name")"
[[ -n "$card_id" ]] || {
  echo "card-id: ${card_dir} has no card.json and its name contains no card id" >&2
  exit 1
}
printf '%s\n' "$card_id"
