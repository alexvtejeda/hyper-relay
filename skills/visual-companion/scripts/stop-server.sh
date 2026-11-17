#!/usr/bin/env bash
# Stop the brainstorm server and clean up
# Usage: stop-server.sh <session_dir>
#
# Kills the server process. Only deletes session directory if it's
# under /tmp (ephemeral). Persistent directories (.superpowers/) are
# kept so mockups can be reviewed later.

SESSION_DIR="$1"

if [[ -z "$SESSION_DIR" ]]; then
  echo '{"error": "Usage: stop-server.sh <session_dir>"}'
  exit 1
fi

STATE_DIR="${SESSION_DIR}/state"
PID_FILE="${STATE_DIR}/server.pid"

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")

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
  # state/port is deliberately KEPT — it is what makes the URL stable next time.
  rm -f "$PID_FILE" "${STATE_DIR}/server.log" "${STATE_DIR}/server-info"

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
