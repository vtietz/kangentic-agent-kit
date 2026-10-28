#!/usr/bin/env bash
# Compose Kangentic card preparation with repository pull-request operations.
#
#   ./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh status
#   KANBAN_CARD_NUMBER=<n> KANBAN_CARD_TITLE='<title>' ./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh prepare [card-dir]
#   ./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh reopen
#   ./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh finalize
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
action="${1:-status}"
card_dir="${2:-}"

case "$action" in
  status|reopen|finalize)
    exec ./scripts/project-pipeline/pull-request.sh "$action"
    ;;

  prepare)
    existing="$(./scripts/project-pipeline/pull-request.sh status)"
    if [[ "$existing" != "null" && "$(jq -r .state <<<"$existing")" != "OPEN" ]]; then
      echo "release-pull-request: PR #$(jq -r .number <<<"$existing") is $(jq -r .state <<<"$existing"); explicitly reopen it or keep the rejection" >&2
      exit 1
    fi

    if [[ -n "$card_dir" ]]; then
      ./.agents/skills/kangentic-release-workflow/scripts/ship.sh "$card_dir"
    else
      ./.agents/skills/kangentic-release-workflow/scripts/ship.sh
    fi
    exec ./scripts/project-pipeline/pull-request.sh create-or-update
    ;;

  *)
    echo "release-pull-request: usage: $0 {status|prepare|reopen|finalize} [card-dir]" >&2
    exit 1
    ;;
esac
