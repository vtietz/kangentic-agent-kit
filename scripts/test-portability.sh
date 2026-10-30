#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
timeout_script="./.apm/skills/kangentic-card-lifecycle/scripts/timeout.sh"
mcp_env_script="$(pwd)/.apm/skills/kangentic-card-lifecycle/scripts/mcp-env.sh"

status=0
PYTHON=python "$timeout_script" 1 python -c 'import time; time.sleep(10)' || status=$?
[[ "$status" -eq 124 ]] || {
  echo "timeout test: expected 124, got ${status}" >&2
  exit 1
}

status=0
PYTHON=python "$timeout_script" 2 python -c 'import sys; sys.exit(7)' || status=$?
[[ "$status" -eq 7 ]] || {
  echo "exit propagation test: expected 7, got ${status}" >&2
  exit 1
}

fixture="$(mktemp -d)"
git init -q "$fixture"
mkdir -p "$fixture/.kangentic"
cat >"$fixture/.kangentic/mcp-config.json" <<'JSON'
{
  "mcpServers": {
    "kangentic": {
      "url": "http://127.0.0.1:4321/mcp/project-id/session-id",
      "headers": {"X-Kangentic-Token": "test token"}
    }
  }
}
JSON

exports="$(cd "$fixture" && PYTHON=python "$mcp_env_script")"
grep -Fq "export KANGENTIC_MCP_URL=http://127.0.0.1:4321/mcp/project-id" <<<"$exports"
grep -Fq "export KANGENTIC_MCP_TOKEN='test token'" <<<"$exports"

git -C "$fixture" -c user.name=Fixture -c user.email=fixture@example.invalid \
  commit -q --allow-empty -m fixture
worktree_parent="$(mktemp -d)"
git -C "$fixture" worktree add -q -b fixture-card "$worktree_parent/card"
worktree_exports="$(cd "$worktree_parent/card" && PYTHON=python "$mcp_env_script")"
[[ "$worktree_exports" == "$exports" ]] || {
  echo 'MCP environment helper resolved different values from a worktree' >&2
  exit 1
}

missing_fixture="$(mktemp -d)"
git init -q "$missing_fixture"
status=0
missing_error="$(cd "$missing_fixture" && PYTHON=python "$mcp_env_script" 2>&1)" || status=$?
[[ "$status" -ne 0 ]] || {
  echo 'MCP environment helper accepted a repository with no live config' >&2
  exit 1
}
grep -Fq 'no live Kangentic MCP configuration found' <<<"$missing_error"

printf 'Portability tests passed.\n'
