#!/usr/bin/env bash
# Squash a finished card into one conventional commit and put it on main.
#
#   ./.agents/skills/kangentic-release-workflow/scripts/ship.sh [card-dir]
#
# Three states, deliberately separate:
#
#   ./.agents/skills/kangentic-release-workflow/scripts/ship.sh  rehearse - squash the branch, stop
#   KANBAN_SHIP_LAND=1 ./scripts/...         land    - fast-forward local main
#   KANBAN_SHIP_PUSH=1 ./scripts/...         publish - land, then push to origin
#
# Landing is what unblocks other cards: they merge local main. Publishing is the
# only outward-facing step, and the only one that is not undoable, so it is opt-in
# separately rather than bundled into "ship".
#
# Design: the card's wip commits are squashed into a single commit on the card
# branch, which leaves main able to fast-forward. That means main never sees the
# working commits, and this never has to check main out - which matters, because
# main is checked out in another worktree.
set -euo pipefail
PY="${PYTHON:-$(command -v python3 || command -v python || echo python3)}"

cd "$(git rev-parse --show-toplevel)"
branch="$(git rev-parse --abbrev-ref HEAD)"

die() { echo "REFUSING: $*" >&2; exit 1; }

[[ "$branch" != "main" ]] || die "already on main; a card must ship from its own branch"
[[ -z "$(git status --porcelain)" ]] || die "working tree is dirty; commit or discard first"

card_dir="$(./.agents/skills/kangentic-card-lifecycle/scripts/card-dir.sh "${1:-}")" || exit 1

closeout="${card_dir}/closeout.md"
[[ -f "$closeout" ]] || die "no ${closeout}; the card never completed implementation"

# The complete section is the message. Both fenced and plain Markdown are valid;
# extraction stops at the next level-two heading so later closeout sections can
# never leak into git history.
msg="$(./.agents/skills/kangentic-release-workflow/scripts/commit-message.sh "$closeout")"
[[ -n "$msg" ]] || die "no '## Suggested commit message' section in ${closeout}"

# Imported issues close only when the squash reaches GitHub with its closing
# footer intact. Labels and the final report are independent writes, so neither
# can compensate for an omitted footer. Resolve the durable board link here,
# where every release path (PR, local land, and publish) passes.
linked_issue="$(./.agents/skills/kangentic-release-workflow/scripts/linked-issue.sh "$card_dir")"

base="$(git merge-base main HEAD)"
if [[ "$base" != "$(git rev-parse main)" ]]; then
  # Not an error condition - just another card shipped while this one was open.
  # The branch has to be re-synced and re-verified before it can go, because what
  # a human approved is no longer what would land.
  echo "REFUSING: main has moved past this card's base." >&2
  echo "Landing is a fast-forward, which needs main to be an ancestor of this" >&2
  echo "branch. Re-sync, then re-verify in proportion to what arrived:" >&2
  echo "  git merge --no-edit main" >&2
  echo "  git diff --name-only HEAD@{1}..main   # what actually came in" >&2
  echo "  run the project profile's repository check, security scan, and selected browser validation when applicable" >&2
  echo "  $0" >&2
  echo "If the merge brings in changes near this card's, say so before shipping." >&2
  exit 1
fi
[[ "$(git rev-parse HEAD)" != "$base" ]] || die "this branch has no commits to ship"

# Give the released card a readable, stable directory and preserve its UUID in
# card.json. Kangentic only interpolates {{taskId}}, so active stages keep using
# the bare UUID and this rename happens once on the way to main.
name_card_dir() {
  local num="${KANBAN_CARD_NUMBER:-}"
  local title="${KANBAN_CARD_TITLE:-}"
  local name pre_count pre_tip slug target card_id
  name="$(basename "$card_dir")"

  # Already renamed by an earlier run of this script (rehearse, then land), or
  # a historical release using the old numbered UUID shape.
  [[ ! "$name" =~ ^[0-9]+- ]] || return 0

  if [[ -z "$num" ]]; then
    echo "NOTE: KANBAN_CARD_NUMBER is unset, so ${card_dir} lands unnumbered."
    echo "      It is the card's display_id, which kangentic_find_task returns."
    return 0
  fi
  [[ "$num" =~ ^[0-9]+$ ]] || die "KANBAN_CARD_NUMBER must be digits, got '${num}'"
  [[ -n "$title" ]] || die "KANBAN_CARD_TITLE is required with KANBAN_CARD_NUMBER"

  card_id="$(./.agents/skills/kangentic-card-lifecycle/scripts/card-id.sh "$card_dir")" || exit 1
  slug="$("$PY" - "$title" <<'PY'
import re
import sys
import unicodedata

value = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode("ascii").lower()
value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")[:64].rstrip("-")
print(value or "card")
PY
)"

  target=".kanban/$(printf '%04d' "$num")-${slug}"
  [[ ! -e "$target" ]] || die "${target} exists; is ${num} this card's number?"

  "$PY" - "$card_dir/card.json" "$card_id" "$num" "$title" <<'PY'
import json
import sys

path, card_id, number, title = sys.argv[1:]
with open(path, "w", encoding="utf-8") as target:
    json.dump({"id": card_id, "number": int(number), "title": title}, target, ensure_ascii=False, indent=2)
    target.write("\n")
PY
  git mv "$card_dir" "$target"
  git add "$target/card.json"

  # Amend when the branch is already squashed. A second commit would leave the
  # squash below looking at a wip tip, so it would rebuild the message from
  # closeout.md and discard any amend made after the rehearsal - the regression
  # the note there describes.
  pre_count="$(git rev-list --count "${base}..HEAD")"
  pre_tip="$(git log -1 --format=%s)"
  if [[ "$pre_count" -eq 1 && "$pre_tip" != "wip("* ]]; then
    git commit -q --amend --no-edit
  else
    git commit -q -m "wip(${branch}): number card directory as $(basename "$target")"
  fi

  card_dir="$target"
  echo "Card directory numbered: ${target}"
}
name_card_dir

count="$(git rev-list --count "${base}..HEAD")"

# Do NOT re-squash a branch that is already squashed. This runs on the rehearsal
# AND on the land, so rebuilding the message from closeout.md the second time
# silently discards any amend made in between - and amending the message is the
# one edit the steward's contract allows a human to ask for. It shipped a commit
# without its `Closes #1` line exactly once; that is why this branch exists.
# The lifecycle stage-commit helper writes every working commit as
# `wip(<branch>): <stage>`, so a
# single non-wip commit is a finished squash and its message is authoritative.
tip_subject="$(git log -1 --format=%s)"
if [[ "$count" -eq 1 && "$tip_subject" != "wip("* ]]; then
  echo "Already squashed to $(git rev-parse --short HEAD). Keeping its message:"
  echo "---"; git log -1 --format=%B; echo "---"
else
  echo "Squashing ${count} commit(s) on ${branch} into:"
  echo "---"; echo "$msg"; echo "---"
  git reset --soft "$base"
  git commit -q -m "$msg"
  echo "Squashed to $(git rev-parse --short HEAD)"
fi

if [[ -n "$linked_issue" ]]; then
  landed_msg="$(git log -1 --format=%B HEAD)"
  if ! grep -Eiq "(^|[[:space:]])Closes[[:space:]]+#${linked_issue}([[:space:]]|$)" <<<"$landed_msg"; then
    die "card links GitHub issue #${linked_issue}, but the squash message lacks 'Closes #${linked_issue}'. Update ${closeout}, commit that correction, and rerun shipping"
  fi
fi

if [[ "${KANBAN_SHIP_LAND:-}" != "1" && "${KANBAN_SHIP_PUSH:-}" != "1" ]]; then
  echo
  echo "Rehearsal only: the branch is squashed and nothing else has moved."
  echo "  KANBAN_SHIP_LAND=1 $0     # fast-forward local main"
  echo "  KANBAN_SHIP_PUSH=1 $0     # ...and push it to origin/main"
  exit 0
fi

# Land. Done from the main worktree so git does not have to update a branch that
# is checked out elsewhere - which it refuses to do.
main_wt="$(git worktree list --porcelain | awk '/^worktree /{wt=$2} /^branch refs\/heads\/main$/{print wt; exit}')"
if [[ -n "$main_wt" ]]; then
  echo "Fast-forwarding local main (checked out at ${main_wt})..."
  git -C "$main_wt" merge --ff-only "$branch"
else
  echo "Fast-forwarding local main..."
  git fetch . "HEAD:main"
fi
echo "Local main is now at $(git rev-parse --short main)."

# Print what actually landed. A commit shipped once without its `Closes #<n>`
# line because this script rebuilt the message from closeout.md on the land run,
# discarding an amend made after the rehearsal. That is fixed above, but printing
# the landed message makes any recurrence visible in the same breath instead of
# depending on someone thinking to go and look.
echo "The message that landed:"
git log -1 --format=%B main | sed 's/^/  /'


if [[ "${KANBAN_SHIP_PUSH:-}" != "1" ]]; then
  echo
  echo "Landed, not published. Other cards can now merge main. To publish:"
  echo "  git push origin main"
  exit 0
fi

git remote get-url origin >/dev/null 2>&1 || die "no 'origin' remote to publish to"
echo "Pushing main to origin..."
git push origin "main:main"
echo "Published."
