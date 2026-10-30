#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

{
  printf 'name: kangentic-kit-fixture\n'
  printf 'version: 0.0.0\n'
  printf 'targets:\n'
  printf '  - codex\n'
  printf '  - claude\n'
  printf '  - copilot\n'
  printf 'dependencies:\n'
  printf '  apm:\n'
  printf '    - path: %s\n' "$root"
} >"$fixture/apm.yml"

cd "$fixture"
apm install

for skill in kangentic-card-lifecycle kangentic-kit-development kangentic-planner-role kangentic-setup; do
  [[ -f ".agents/skills/$skill/SKILL.md" ]] || {
    echo "fixture missing installed skill: $skill" >&2
    exit 1
  }
done

[[ -x .agents/skills/kangentic-card-lifecycle/scripts/mcp-env.sh ]] || {
  echo 'fixture missing executable Kangentic MCP environment helper' >&2
  exit 1
}

if grep -R -n 'scripts/kangentic-mcp-env\.sh' .agents/skills; then
  echo 'fixture contains an undeclared consumer MCP helper reference' >&2
  exit 1
fi

if grep -F -R -n 'eval "$(' \
  .agents/skills/kangentic-card-lifecycle/scripts \
  .agents/skills/kangentic-release-workflow/scripts; then
  echo 'fixture contains eval with an unchecked command-substitution failure' >&2
  exit 1
fi

[[ -f .codex/agents/planner.toml ]] || {
  echo 'fixture missing Codex planner registration' >&2
  exit 1
}
[[ -f .claude/agents/planner.md ]] || {
  echo 'fixture missing Claude planner registration' >&2
  exit 1
}
[[ -f .github/agents/planner.agent.md ]] || {
  echo 'fixture missing Copilot planner registration' >&2
  exit 1
}

apm install --frozen
apm audit --ci
printf 'APM fixture install passed.\n'
