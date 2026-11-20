#!/usr/bin/env bash
# Stop the brainstorm server and clean up
# Usage: stop-server.sh <session_dir>
#
# Kills the server process, but only a process proved to be this session's own server: its
# command line must carry the instance id start-server.sh wrote. A pid file that names
# anything else (a reused pid) is stale, and nothing is signalled. Only deletes session
# directory if it's under /tmp (ephemeral). Persistent directories (.superpowers/) are
# kept so mockups can be reviewed later.

SESSION_DIR="$1"

if [[ -z "$SESSION_DIR" ]]; then
  echo '{"error": "Usage: stop-server.sh <session_dir>"}'
  exit 1
fi

STATE_DIR="${SESSION_DIR}/state"
PID_FILE="${STATE_DIR}/server.pid"
ID_FILE="${STATE_DIR}/server-instance-id"

# pid_alive <pid>: the pid is all digits and the process exists.
pid_alive() {
  [[ "$1" =~ ^[0-9]+$ ]] && kill -0 "$1" 2>/dev/null
}

# carries_id <pid> <id>: one argument of the process is exactly --companion-id=<id>.
carries_id() {
  if [[ -r "/proc/$1/cmdline" ]]; then
    tr '\0' '\n' < "/proc/$1/cmdline" | grep -q -x -F -- "--companion-id=$2"
  else
    ps -o args= -p "$1" 2>/dev/null | tr ' ' '\n' | grep -q -x -F -- "--companion-id=$2"
  fi
}

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")
  id=""
  [[ -f "$ID_FILE" ]] && id=$(tr -d '[:space:]' < "$ID_FILE")

  if ! { pid_alive "$pid" && [[ "$id" =~ ^[0-9a-f]{48}$ ]] && carries_id "$pid" "$id"; }; then
    # Not our server: signal nothing. A dead pid leaves a server-info describing a server
    # that no longer exists; a live one may be an old script's server, which keeps serving
    # what its server-info says.
    rm -f "$PID_FILE"
    pid_alive "$pid" || rm -f "${STATE_DIR}/server-info"
    echo '{"status":"stale_pid"}'
    exit 0
  fi

  # Try to stop gracefully, fallback to force if still alive
  kill "$pid" 2>/dev/null || true

  # Wait for graceful shutdown (up to ~2s)
  for i in {1..20}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  # If still running, escalate to SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true

    # Give SIGKILL a moment to take effect
    sleep 0.1
  fi

  if kill -0 "$pid" 2>/dev/null; then
    echo '{"status": "failed", "error": "process still running"}'
    exit 1
  fi

  # server-info too: if the process was SIGKILLed it never ran shutdown(), and a surviving
  # server-info makes every "is it still up?" check report a dead server as alive.
  # state/port and state/token are deliberately KEPT — they make the link stable next time.
  rm -f "$PID_FILE" "$ID_FILE" "${STATE_DIR}/server.log" "${STATE_DIR}/server-info"

  # Only delete ephemeral /tmp sessions — those whose directory name is the old
  # "<pid>-<timestamp>" id. A NAMED session is the user's artifact store: its screens are
  # meant to outlive the server, and deleting them would defeat the point of naming it.
  if [[ "$SESSION_DIR" == /tmp/* && "$(basename "$SESSION_DIR")" =~ ^[0-9]+-[0-9]+$ ]]; then
    rm -rf "$SESSION_DIR"
  fi

  echo '{"status": "stopped"}'
else
  echo '{"status": "not_running"}'
fi
