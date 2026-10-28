#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
timeout_script="./.apm/skills/kangentic-card-lifecycle/scripts/timeout.sh"

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

printf 'Portability tests passed.\n'
