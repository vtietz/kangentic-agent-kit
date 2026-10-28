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
