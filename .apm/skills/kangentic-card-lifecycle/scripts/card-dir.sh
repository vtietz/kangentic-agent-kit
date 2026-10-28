#!/usr/bin/env bash
# Print this card's directory under .kanban/, or fail with a reason.
#
#   card_dir="$(./.agents/skills/kangentic-card-lifecycle/scripts/card-dir.sh "${1:-}")"
#
# A worktree used to hold exactly one card directory, so "the only one" was a
# safe guess. It is not any more: plan.md, review.md and closeout.md are
# committed, so every card that ships leaves its directory on main and every
# later worktree inherits it. The count grows with each release, and both
# Release and browser-test workflows refuse the no-argument form
# the first time a card landed.
#
# The branch name is the reliable signal instead: kanban branches end in the
# first 8 characters of the card id (improve-public-seen-eed139aa).
#
# Active directories carry the bare card id. Released directories use a readable
# `<number>-<title-slug>` name and carry their stable UUID in card.json. Legacy
# released `<number>-<card-id>` directories remain supported.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

explicit="${1:-}"
if [[ -n "$explicit" ]]; then
  [[ -d "$explicit" ]] || { echo "No such card directory: ${explicit}" >&2; exit 1; }
  printf '%s\n' "$explicit"
  exit 0
fi

# while-read rather than mapfile: macOS ships bash 3.2, which has neither.
dirs=()
while IFS= read -r dir; do
  dirs+=("$dir")
done < <(find .kanban -mindepth 1 -maxdepth 1 -type d ! -name roles | sort)
count=${#dirs[@]}

branch="$(git rev-parse --abbrev-ref HEAD)"
suffix="${branch##*-}"

if [[ "$suffix" =~ ^[0-9a-f]{8}$ && "$count" -gt 0 ]]; then
  match=""
  matches=0
  for dir in "${dirs[@]}"; do
    card_id="$(./.agents/skills/kangentic-card-lifecycle/scripts/card-id.sh "$dir" 2>/dev/null || true)"
    if [[ "${card_id:0:8}" == "$suffix" ]]; then
      match="$dir"
      matches=$((matches + 1))
    fi
  done
  if [[ "$matches" -eq 1 ]]; then
    printf '%s\n' "$match"
    exit 0
  fi
fi

if [[ "$count" -eq 1 ]]; then
  printf '%s\n' "${dirs[0]}"
  exit 0
fi

candidates="none"
if [[ "$count" -gt 0 ]]; then
  candidates="$(printf '%s ' "${dirs[@]}")"
fi
{
  echo "Cannot tell which card directory belongs to this branch."
  echo "  branch:     ${branch}"
  echo "  candidates: ${candidates}"
  echo
  echo "Kanban branches end in the card id's first 8 characters. This one does not"
  echo "match exactly one directory identity, and more than one is present. Every"
  echo "shipped card leaves its paperwork on main. Pass it explicitly:"
  echo "  $0 .kanban/<card-directory>"
} >&2
exit 1
