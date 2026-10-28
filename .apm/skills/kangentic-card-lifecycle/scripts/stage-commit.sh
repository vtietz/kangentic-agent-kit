#!/usr/bin/env bash
# Commit the current stage's work on a card branch.
#
#   ./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh <stage-label>
#
# These are working commits, not history. They exist so that each pipeline stage
# is isolatable with `git diff` while the card is in flight. The release ship helper
# squashes them into one conventional commit before anything reaches main.
#
# No-op when the tree is clean, so it is safe to call unconditionally.
set -euo pipefail

stage="${1:?usage: stage-commit.sh <stage-label>}"
cd "$(git rev-parse --show-toplevel)"

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" == "main" ]]; then
  echo "Refusing to commit directly on main. A card must run on its own branch." >&2
  exit 1
fi

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Nothing to commit for stage '$stage'."
  exit 0
fi

git add -A
git commit -q -m "wip(${branch}): ${stage}"
echo "Committed stage '$stage' on ${branch}: $(git rev-parse --short HEAD)"
