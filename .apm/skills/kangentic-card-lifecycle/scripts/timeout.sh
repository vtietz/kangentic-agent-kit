#!/usr/bin/env bash
# Run a command with a portable wall-clock timeout.
#
#   ./.agents/skills/kangentic-card-lifecycle/scripts/timeout.sh <seconds> <command> [args...]
#
# Exit 124 means the deadline expired, matching GNU timeout. Python starts the
# command in its own process group so Docker/Compose children are stopped too.
set -euo pipefail

die() { echo "kangentic-timeout: $*" >&2; exit 2; }

seconds="${1:-}"
[[ "$seconds" =~ ^[1-9][0-9]*$ ]] || die "seconds must be a positive integer"
shift
[[ $# -gt 0 ]] || die "usage: $0 <seconds> <command> [args...]"

exec python3 - "$seconds" "$@" <<'PY'
import os
import signal
import subprocess
import sys

seconds = int(sys.argv[1])
command = sys.argv[2:]

try:
    process = subprocess.Popen(command, start_new_session=True)
except FileNotFoundError:
    sys.exit(f"kangentic-timeout: command not found: {command[0]}")

try:
    sys.exit(process.wait(timeout=seconds))
except subprocess.TimeoutExpired:
    print(
        f"kangentic-timeout: command exceeded {seconds}s; terminating",
        file=sys.stderr,
    )
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    sys.exit(124)
PY
