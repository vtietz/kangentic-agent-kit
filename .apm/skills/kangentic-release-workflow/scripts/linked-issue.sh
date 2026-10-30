#!/usr/bin/env bash
# Print the GitHub issue number imported into a Kangentic card, or nothing when
# the card has no linked GitHub issue.
set -euo pipefail
PY="${PYTHON:-$(command -v python3 || command -v python || echo python3)}"

cd "$(git rev-parse --show-toplevel)"
card_dir="${1:-}"
[[ -d "$card_dir" ]] || { echo "linked-issue: no card directory: ${card_dir}" >&2; exit 1; }

card_id="$(./.agents/skills/kangentic-card-lifecycle/scripts/card-id.sh "$card_dir")" || exit 1

mcp_env="$(./.agents/skills/kangentic-card-lifecycle/scripts/mcp-env.sh)" || exit 1
eval "$mcp_env"

sql="select external_url from tasks where id = '${card_id}'"
if [[ -n "${KANBAN_CARD_NUMBER:-}" ]]; then
  [[ "$KANBAN_CARD_NUMBER" =~ ^[0-9]+$ ]] || { echo "linked-issue: KANBAN_CARD_NUMBER must be digits" >&2; exit 1; }
  sql="${sql} or cast(display_id as text) = '${KANBAN_CARD_NUMBER}'"
fi

response="$("$PY" - "$sql" <<'PY'
import json, os, sys, urllib.request

payload = json.dumps({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {"name": "kangentic_query_db", "arguments": {"sql": sys.argv[1]}},
}).encode()
request = urllib.request.Request(
    os.environ["KANGENTIC_MCP_URL"],
    data=payload,
    headers={
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
        "X-Kangentic-Token": os.environ["KANGENTIC_MCP_TOKEN"],
    },
)
with urllib.request.urlopen(request, timeout=30) as result:
    print(result.read().decode())
PY
)"

external_url="$(sed -nE 's#.*(https://github\.com/[^/" ]+/[^/" ]+/issues/[0-9]+).*#\1#p' <<<"$response" | head -n 1)"
[[ -n "$external_url" ]] || exit 0
sed -nE 's#.*/issues/([0-9]+).*#\1#p' <<<"$external_url"
