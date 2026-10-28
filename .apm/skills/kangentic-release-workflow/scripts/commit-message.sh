#!/usr/bin/env bash
# Print the complete commit message from a closeout's final named section.
set -euo pipefail

file="${1:-}"
[[ -f "$file" ]] || { echo "kanban-commit-message: no closeout: ${file}" >&2; exit 1; }

awk '
  /^##[[:space:]]+Suggested commit message[[:space:]]*$/ { found=1; next }
  found && /^##[[:space:]]+/ { exit }
  found && /^```[[:space:]]*$/ { next }
  found { lines[++count] = $0 }
  END {
    first = 1
    while (first <= count && lines[first] ~ /^[[:space:]]*$/) first++
    last = count
    while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
    for (i = first; i <= last; i++) print lines[i]
  }
' "$file"
