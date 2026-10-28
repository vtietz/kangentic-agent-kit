#!/usr/bin/env bash
# Refuse a Kangentic Implementation → Review handoff missing its durable state.
# Usage: pre-review.sh .kanban/<card-id> <initial|review|human>
set -euo pipefail

card_dir="${1:?usage: $0 .kanban/<card-id> <initial|review|human>}"
source="${2:?usage: $0 .kanban/<card-id> <initial|review|human>}"
case "$source" in initial|review|human) ;; *) echo "Unknown source: $source" >&2; exit 2 ;; esac
cd "$(git rev-parse --show-toplevel)"

for file in "$card_dir/plan.md" "$card_dir/e2e-specs.txt" "$card_dir/closeout.md"; do
  [[ -f "$file" ]] || { echo "Missing handoff artifact: $file" >&2; exit 1; }
done
grep -q '^## Commands run' "$card_dir/closeout.md" || { echo 'closeout.md lacks ## Commands run' >&2; exit 1; }
grep -q '^## Open problems' "$card_dir/closeout.md" || { echo 'closeout.md lacks ## Open problems' >&2; exit 1; }
grep -q '^## Suggested commit message' "$card_dir/closeout.md" || { echo 'closeout.md lacks ## Suggested commit message' >&2; exit 1; }

if grep -q '^## Self-planned' "$card_dir/closeout.md"; then
  grep -q '^## Fast lane brief' "$card_dir/plan.md" || { echo 'Self-planned work lacks ## Fast lane brief' >&2; exit 1; }
fi
if [[ "$source" == review ]]; then
  grep -A1 '^## Correction response' "$card_dir/closeout.md" | grep -q '^-' || { echo 'Review correction lacks ## Correction response' >&2; exit 1; }
fi

[[ -z "$(git status --porcelain)" ]] || { echo 'Uncommitted changes remain before Review' >&2; exit 1; }
[[ "$(git rev-parse --abbrev-ref HEAD)" != main ]] || { echo 'Refusing a Review handoff from main' >&2; exit 1; }
git diff --check main...HEAD
echo "Pre-review handoff ready: $card_dir ($source)"
