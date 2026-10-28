#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
output="${1:-build/agent-plugin}"

if [[ -e "$output" ]]; then
  echo "output already exists: $output" >&2
  exit 1
fi

mkdir -p "$output/skills"
cp -R .apm/skills/. "$output/skills/"
cp LICENSE "$output/LICENSE"

sed \
  -e 's|__VERSION__|0.3.0|g' \
  scripts/plugin.template.json >"$output/plugin.json"

printf 'Built Agent Plugins package: %s\n' "$output"
