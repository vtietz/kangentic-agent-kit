#!/usr/bin/env bash
# Publish one report to every place it belongs: the card, and the issue if there is one.
#
#   ./.agents/skills/kangentic-release-workflow/scripts/report.sh <card-id> <file.md> [--commit <sha>] [--issue <n>|--no-issue] [--dry-run]
#
# Write the text ONCE, into a file, and let this distribute it. An agent that
# composes the same paragraph twice - once for kangentic_update_task, once for
# `gh issue comment` - pays for it twice and the two copies drift apart.
#
# Finding the issue, in order of how much it can be trusted:
#   1. --issue <n>                  you said so
#   2. tasks.external_url           ground truth: what the importer recorded
#   3. `Closes #<n>` in the landed commit (from --commit or the report)
#   4. nothing                      the card came from no issue; skip GitHub
#
# Only (2) means the board actually knows about the issue. (3) exists because a
# card created by hand can still be *about* an issue - that is how the first
# closed one on this board happened - but then the link lives in the commit
# message and nowhere else, which is worth reporting rather than hiding.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
die() { echo "release-report: $*" >&2; exit 1; }

card_id="${1:-}"
file="${2:-}"
[[ -n "$card_id" && -n "$file" ]] || die "usage: $0 <card-id> <file.md> [--commit <sha>] [--issue <n>|--no-issue] [--dry-run]"
shift 2

issue=""
source_of_issue=""
commit=""
no_issue=""
dry_run=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)    issue="${2:-}"; [[ -n "$issue" ]] || die "--issue needs a number"
                source_of_issue="you said so"; shift 2 ;;
    --commit)   commit="${2:-}"; [[ -n "$commit" ]] || die "--commit needs a SHA"; shift 2 ;;
    --no-issue) no_issue="1"; shift ;;
    --dry-run)  dry_run="1"; shift ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -s "$file" ]] || die "no such file, or it is empty: ${file}"
[[ -z "$issue" || -z "$no_issue" ]] || die "--issue and --no-issue cannot be combined"

# A landed report already names the authoritative squash. Prefer that over the
# worktree HEAD: after landing, HEAD can still be the old branch tip while the
# closing commit lives on main.
if [[ -z "$commit" ]]; then
  commit="$(sed -n -E 's/^- \*\*Commit:\*\* `([0-9a-fA-F]{7,40})`.*/\1/p' "$file" | head -n 1)"
fi
if [[ -n "$commit" ]]; then
  commit="$(git rev-parse --verify "${commit}^{commit}" 2>/dev/null)" || die "landed commit is not available locally"
fi

eval "$(./scripts/kangentic-mcp-env.sh)"

mcp() {
  python3 - "$1" "$2" <<'PY'
import json, os, sys, urllib.error, urllib.request
payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                      "params": {"name": sys.argv[1], "arguments": json.loads(sys.argv[2])}}).encode()
request = urllib.request.Request(
    os.environ["KANGENTIC_MCP_URL"], data=payload,
    headers={"Content-Type": "application/json",
             "Accept": "application/json, text/event-stream",
             "X-Kangentic-Token": os.environ["KANGENTIC_MCP_TOKEN"]})
try:
    with urllib.request.urlopen(request, timeout=30) as response:
        result = json.load(response)
except urllib.error.URLError as error:
    sys.exit(f"release-report: cannot reach the board MCP server: {error}")
if "error" in result:
    sys.exit(f"release-report: the board refused the call: {result['error']}")
print(result["result"]["content"][0]["text"])
PY
}

# (2) what the board recorded
if [[ -z "$issue" ]]; then
  sql="select external_url from tasks where id = '${card_id//\'/}' or cast(display_id as text) = '${card_id//\'/}'"
  external="$(mcp kangentic_query_db "$(python3 -c 'import json,sys; print(json.dumps({"sql": sys.argv[1]}))' "$sql")" || true)"
  issue="$(printf '%s' "$external" | sed -n -E 's#.*/issues/([0-9]+).*#\1#p' | head -n 1)"
  [[ -z "$issue" ]] || source_of_issue="tasks.external_url"
fi

# (3) a link a human put in the commit message
if [[ -z "$issue" && -n "$commit" ]]; then
  issue="$(git show -s --format=%B "$commit" | sed -n -E 's/.*[Cc]loses #([0-9]+).*/\1/p' | head -n 1)"
  [[ -z "$issue" ]] || source_of_issue="the commit message only - the board has no external_url for this card"
fi

# Suppression is only an assertion that no linked issue exists. It must not be
# an escape hatch for skipping the final write-back when either durable source
# proves the link.
if [[ -n "$no_issue" ]]; then
  [[ -z "$issue" ]] || die "--no-issue conflicts with issue #${issue} found via ${source_of_issue}"
  issue="none"
fi

if [[ -n "$dry_run" ]]; then
  echo "release-report: DRY RUN"
  echo "  card:  ${card_id}"
  echo "  file:  ${file} ($(wc -c <"$file" | tr -d ' ') bytes)"
  [[ -z "$commit" ]] || echo "  commit: ${commit}"
  case "$issue" in
    none) echo "  issue: skipped (--no-issue)" ;;
    "")   echo "  issue: none found - the card came from no issue, GitHub would be skipped" ;;
    *)    echo "  issue: would comment on #${issue}  (from ${source_of_issue})" ;;
  esac
  exit 0
fi

body="$(python3 -c 'import json,sys; print(json.dumps({"taskId": sys.argv[1], "appendDescription": "\n" + open(sys.argv[2], encoding="utf-8").read().rstrip() + "\n"}))' "$card_id" "$file")"
mcp kangentic_update_task "$body" >/dev/null
echo "release-report: appended to card ${card_id}"

case "$issue" in
  none) echo "release-report: GitHub skipped (--no-issue)"; exit 0 ;;
  "")   echo "release-report: no issue to comment on; the card came from none."; exit 0 ;;
esac

command -v gh >/dev/null || die "gh is not installed, but issue #${issue} needs the comment"
echo "release-report: issue #${issue} found via ${source_of_issue}"
gh issue comment "$issue" --body-file "$file"
echo "release-report: commented on issue #${issue}"
