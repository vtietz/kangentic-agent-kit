#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0
fail() {
  printf 'validation: %s\n' "$*" >&2
  status=1
}

for skill in .apm/skills/*; do
  [[ -f "$skill/SKILL.md" ]] || fail "missing SKILL.md: $skill"
done

for role in refiner planner implementer reviewer; do
  [[ -f ".apm/agents/$role.agent.md" ]] || fail "missing agent: $role"
  [[ -f ".apm/skills/kangentic-$role-role/SKILL.md" ]] || fail "missing role skill: $role"
  [[ -f ".apm/skills/kangentic-setup/assets/board-roles/$role.md" ]] || fail "missing board adapter: $role"
done

jq empty .apm/skills/kangentic-setup/assets/templates/kangentic.template.json \
  .apm/skills/kangentic-setup/assets/templates/kangentic-config.example.json

while IFS= read -r -d '' script; do
  bash -n "$script" || status=1
done < <(find .apm scripts -type f -name '*.sh' -print0)

if rg -n -i 'mirulist|MIRULIST_INSTANCE|TMDB|run\.sh|frontend/|backend/|docs/backlog|docker|compose\.ya?ml|nestjs|typeorm|marketing' \
  .apm/skills .apm/agents; then
  fail 'portable package contains project-specific terms'
fi

git diff --check || status=1
exit "$status"
