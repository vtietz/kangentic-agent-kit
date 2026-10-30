#!/usr/bin/env bash
# Print shell exports for the live, project-scoped Kangentic MCP endpoint.
set -euo pipefail

PY="${PYTHON:-$(command -v python3 || command -v python || echo python3)}"

# Kangentic stores runtime configuration in the main checkout. Resolve it via
# the shared Git directory so this also works from a card worktree.
cd "$(dirname "$(cd "$(git rev-parse --git-common-dir)" && pwd)")"

"$PY" - <<'PY'
import glob
import json
import os
import shlex
import sys


def project_scoped(url):
    base, separator, tail = url.partition("/mcp/")
    if not separator:
        return url
    parts = [part for part in tail.split("/") if part]
    return f"{base}/mcp/{parts[0]}" if parts else url


def emit(url, token):
    print(f"export KANGENTIC_MCP_URL={shlex.quote(project_scoped(url))}")
    print(f"export KANGENTIC_MCP_TOKEN={shlex.quote(token)}")


existing_url = os.environ.get("KANGENTIC_MCP_URL")
existing_token = os.environ.get("KANGENTIC_MCP_TOKEN")
if existing_url and existing_token:
    emit(existing_url, existing_token)
    sys.exit(0)

candidates = [".kangentic/mcp-config.json"]
candidates += sorted(
    glob.glob(".kangentic/sessions/*/mcp.json"),
    key=os.path.getmtime,
    reverse=True,
)

for path in candidates:
    try:
        with open(path, encoding="utf-8") as source:
            server = json.load(source)["mcpServers"]["kangentic"]
        emit(server["url"], server["headers"]["X-Kangentic-Token"])
    except (OSError, KeyError, TypeError, ValueError):
        continue
    sys.exit(0)

sys.exit(
    "kangentic-mcp-env: no live Kangentic MCP configuration found; "
    "start Kangentic and open this repository"
)
PY
