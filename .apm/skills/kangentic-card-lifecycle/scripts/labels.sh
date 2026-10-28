#!/usr/bin/env bash
# Replace only pipeline-owned labels while preserving user/import labels. When
# the card came from GitHub, mirror the same labels to its linked issue and
# create missing repository labels automatically.
#
#   ./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> <stage:*|keep|clear> <wait:*|keep|clear>
set -euo pipefail
PY="${PYTHON:-$(command -v python3 || command -v python || echo python3)}"

cd "$(git rev-parse --show-toplevel)"
die() { echo "kanban-labels: $*" >&2; exit 1; }

card_id="${1:-}"
stage="${2:-keep}"
waiting="${3:-keep}"
[[ -n "$card_id" ]] || die "usage: $0 <card-id> <stage:*|keep|clear> <wait:*|keep|clear>"
[[ "$stage" == keep || "$stage" == clear || "$stage" == stage:* ]] || die "invalid stage label: ${stage}"
[[ "$waiting" == keep || "$waiting" == clear || "$waiting" == wait:* ]] || die "invalid wait label: ${waiting}"

eval "$(./scripts/kangentic-mcp-env.sh)"

"$PY" - "$card_id" "$stage" "$waiting" <<'PY'
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request

card_id, stage, waiting = sys.argv[1:]
url = os.environ["KANGENTIC_MCP_URL"]
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json, text/event-stream",
    "X-Kangentic-Token": os.environ["KANGENTIC_MCP_TOKEN"],
}

def call(name, arguments):
    payload = json.dumps({
        "jsonrpc": "2.0", "id": 1, "method": "tools/call",
        "params": {"name": name, "arguments": arguments},
    }).encode()
    request = urllib.request.Request(url, data=payload, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            result = json.load(response)
    except urllib.error.URLError as error:
        sys.exit(f"kanban-labels: cannot reach board MCP: {error}")
    if "error" in result:
        sys.exit(f"kanban-labels: board refused call: {result['error']}")
    tool_result = result["result"]
    if tool_result.get("isError"):
        sys.exit(f"kanban-labels: {tool_result['content'][0]['text']}")
    return tool_result["content"][0]["text"]

escaped = card_id.replace("'", "''")
text = call("kangentic_query_db", {
    "sql": f"select labels from tasks where id = '{escaped}' or cast(display_id as text) = '{escaped}'"
})
rows = [line for line in text.splitlines() if line.startswith("|")]
if len(rows) < 3:
    sys.exit(f"kanban-labels: card not found: {card_id}")
cell = rows[2].strip().strip("|").strip()
labels = json.loads(cell)

def replace_prefix(values, prefix, requested):
    if requested == "keep":
        return values
    values = [value for value in values if not value.startswith(prefix)]
    if requested != "clear":
        values.append(requested)
    return values

labels = replace_prefix(labels, "stage:", stage)
labels = replace_prefix(labels, "wait:", waiting)
call("kangentic_update_task", {"taskId": card_id, "labels": labels})

external_text = call("kangentic_query_db", {
    "sql": f"select external_url from tasks where id = '{escaped}' or cast(display_id as text) = '{escaped}'"
})
match = re.search(r"https://github\.com/([^/]+/[^/]+)/issues/(\d+)", external_text)

def run_gh(*arguments, capture=False):
    result = subprocess.run(
        ["gh", *arguments], text=True,
        stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        detail = result.stderr.strip() or "unknown GitHub CLI error"
        sys.exit(f"kanban-labels: GitHub sync failed: {detail}")
    return result.stdout if capture else ""

if match:
    if not shutil.which("gh"):
        sys.exit("kanban-labels: gh is not installed, but the card has a linked issue")
    repo, issue_number = match.groups()
    issue_url = f"https://github.com/{repo}/issues/{issue_number}"
    pipeline_labels = [
        label for label in labels
        if label.startswith("stage:") or label.startswith("wait:")
    ]
    colors = {
        "stage:refined": "eab308",
        "stage:planned": "8b5cf6",
        "stage:implemented": "2563eb",
        "stage:reviewed": "a855f7",
        "stage:landed": "0d9488",
        "stage:shipped": "10b981",
        "wait:promotion": "f97316",
        "wait:decision": "ef4444",
        "wait:pipeline": "b91c1c",
        "wait:pr": "0ea5e9",
        "wait:pr-feedback": "ec4899",
    }
    for label in pipeline_labels:
        namespace = "completed pipeline stage" if label.startswith("stage:") else "pipeline wait reason"
        run_gh(
            "label", "create", label, "--repo", repo,
            "--color", colors.get(label, "6b7280"),
            "--description", f"Kangentic {namespace}", "--force",
        )

    issue_labels = json.loads(run_gh(
        "issue", "view", issue_url, "--json", "labels", capture=True,
    ))["labels"]
    existing_pipeline = {
        item["name"] for item in issue_labels
        if item["name"].startswith("stage:") or item["name"].startswith("wait:")
    }
    desired_pipeline = set(pipeline_labels)
    for label in sorted(desired_pipeline - existing_pipeline):
        run_gh("issue", "edit", issue_url, "--add-label", label)
    for label in sorted(existing_pipeline - desired_pipeline):
        run_gh("issue", "edit", issue_url, "--remove-label", label)
    print(f"kanban-labels: mirrored to {issue_url}")
else:
    print("kanban-labels: no linked GitHub issue; mirror skipped")

print("kanban-labels: " + (", ".join(labels) if labels else "no labels"))
PY
