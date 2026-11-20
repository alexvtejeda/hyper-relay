#!/usr/bin/env bash
# Start the brainstorm server and output connection info
# Usage: start-server.sh [--project-dir <path>] [--session <name>] [--idle-timeout-minutes <n>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
#
# Starts server on a random high port, outputs JSON with URL.
# Each session gets its own directory to avoid conflicts.
#
# Options:
#   --project-dir <path>  Store session files under <path>/.hyper-relay/companion/<session>/
#                         instead of /tmp. Files persist after server stops. A session
#                         from <path>/.superpowers/brainstorm/ moves here the first time it
#                         is started again. In a git repo, the folder is kept out of git
#                         through the repo's local exclude file (never .gitignore).
#   --session <name>      Name the session: a restart reuses its folder, port and key.
#   --idle-timeout-minutes <n>
#                         Stop after <n> minutes with no visit and no new screen (default
#                         4 hours). Used only when the session that started the server
#                         cannot be told; otherwise the server runs as long as that session.
#   --host <bind-host>    Host/interface to bind (default: 127.0.0.1).
#                         Use 0.0.0.0 in remote/containerized environments.
#   --url-host <host>     Hostname shown in returned URL JSON.
#   --foreground          Run server in the current terminal (no backgrounding).
#   --background          Force background mode (overrides Codex auto-foreground).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# pid_alive <pid>: the pid is all digits and the process exists.
pid_alive() {
  [[ "$1" =~ ^[0-9]+$ ]] && kill -0 "$1" 2>/dev/null
}

# carries_id <pid> <id>: one argument of the process is exactly --companion-id=<id>.
# This is how a pid is proved to be this script's own server and not a reused one.
carries_id() {
  if [[ -r "/proc/$1/cmdline" ]]; then
    tr '\0' '\n' < "/proc/$1/cmdline" | grep -q -x -F -- "--companion-id=$2"
  else
    ps -o args= -p "$1" 2>/dev/null | tr ' ' '\n' | grep -q -x -F -- "--companion-id=$2"
  fi
}

# Parse arguments
PROJECT_DIR=""
SESSION_NAME=""
SESSION_GIVEN="false"
FOREGROUND="false"
FORCE_BACKGROUND="false"
BIND_HOST="127.0.0.1"
URL_HOST=""
IDLE_MINUTES=""
IDLE_GIVEN="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --session)
      SESSION_NAME="$2"
      SESSION_GIVEN="true"
      shift 2
      ;;
    --idle-timeout-minutes)
      IDLE_MINUTES="$2"
      IDLE_GIVEN="true"
      shift 2
      ;;
    --host)
      BIND_HOST="$2"
      shift 2
      ;;
    --url-host)
      URL_HOST="$2"
      shift 2
      ;;
    --foreground|--no-daemon)
      FOREGROUND="true"
      shift
      ;;
    --background|--daemon)
      FORCE_BACKGROUND="true"
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown argument: $1\"}"
      exit 1
      ;;
  esac
done

if [[ "$IDLE_GIVEN" == "true" ]]; then
  if [[ ! "$IDLE_MINUTES" =~ ^[1-9][0-9]*$ ]]; then
    echo '{"error": "--idle-timeout-minutes must be a positive integer"}'
    exit 1
  fi
  export BRAINSTORM_IDLE_TIMEOUT_MS=$(( IDLE_MINUTES * 60000 ))
fi

# Everything this script makes is for its owner only: the key is in these files.
umask 077

if [[ -z "$URL_HOST" ]]; then
  if [[ "$BIND_HOST" == "127.0.0.1" || "$BIND_HOST" == "localhost" ]]; then
    URL_HOST="localhost"
  else
    URL_HOST="$BIND_HOST"
  fi
fi

# Some environments reap detached/background processes. Auto-foreground when detected.
if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
  FOREGROUND="true"
fi

# Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
  case "${OSTYPE:-}" in
    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
  esac
  if [[ -n "${MSYSTEM:-}" ]]; then
    FOREGROUND="true"
  fi
fi

# Session identity. A NAME makes a restart idempotent — same directory, same screens,
# same URL — which is what makes the idle timeout harmless. Without one we keep the old
# ephemeral id so non-interactive callers still work; the SKILL requires a name.
if [[ "$SESSION_GIVEN" == "true" ]]; then
  if [[ ! "$SESSION_NAME" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]]; then
    echo "{\"error\": \"Invalid --session name '$SESSION_NAME': must match ^[a-z0-9][a-z0-9-]{0,63}\$ — one path segment, lowercase, no slashes or dots\"}"
    exit 1
  fi
  SESSION_ID="$SESSION_NAME"
else
  SESSION_ID="$$-$(date +%s)"
fi

if [[ -n "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(mkdir -p -- "$PROJECT_DIR" && CDPATH='' cd -- "$PROJECT_DIR" && pwd)" || {
    echo '{"error": "Cannot create or enter --project-dir"}'
    exit 1
  }
  SESSION_DIR="${PROJECT_DIR}/.hyper-relay/companion/${SESSION_ID}"
  OLD_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
else
  SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
  OLD_DIR=""
fi

STATE_DIR="${SESSION_DIR}/state"
PID_FILE="${STATE_DIR}/server.pid"
LOG_FILE="${STATE_DIR}/server.log"

# A session from before the move: bring it over, screens and port included. If an old
# script's server is still running there, hand back its info and move nothing.
MOVED_FROM=""
if [[ -n "$OLD_DIR" && ! -e "$SESSION_DIR" && -d "$OLD_DIR" ]]; then
  if [[ -f "${OLD_DIR}/state/server.pid" && -f "${OLD_DIR}/state/server-info" ]] \
     && pid_alive "$(cat "${OLD_DIR}/state/server.pid")"; then
    cat "${OLD_DIR}/state/server-info"
    exit 0
  fi
  if ! { mkdir -p "$(dirname "$SESSION_DIR")" && mv "$OLD_DIR" "$SESSION_DIR"; }; then
    echo '{"error": "Cannot move the old session folder"}'
    exit 1
  fi
  MOVED_FROM="$OLD_DIR"
fi

# Reuse the session directory when it already exists. content/ is NEVER cleared — the
# screens written before a restart are the whole reason for naming sessions.
mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"

# A server is running for THIS session when its pid file holds a live process, server-info
# exists, and the process is proved ours: it carries the instance id in server-instance-id.
# A server an older script started has no such file; it counts as running (it is never
# signalled, only reported). Two servers on one content dir both "work" and each reports a
# different URL, which is exactly the confusion naming is meant to end.
ID_FILE="${STATE_DIR}/server-instance-id"
running="false"
if [[ -f "$PID_FILE" && -f "${STATE_DIR}/server-info" ]]; then
  running_pid=$(cat "$PID_FILE")
  if pid_alive "$running_pid"; then
    if [[ ! -f "$ID_FILE" ]]; then
      running="true"
    else
      running_id=$(tr -d '[:space:]' < "$ID_FILE")
      if [[ "$running_id" =~ ^[0-9a-f]{48}$ ]] && carries_id "$running_pid" "$running_id"; then
        running="true"
      fi
    fi
  fi
fi
if [[ "$running" == "true" ]]; then
  cat "${STATE_DIR}/server-info"
  exit 0
fi
# Not running: clear what the dead or reused server left, so no check can read a lie. The
# log goes too, so it is made again owner-only.
rm -f "$PID_FILE" "${STATE_DIR}/server-info" "${STATE_DIR}/server-stopped" "$LOG_FILE"

# Keep the companion's folder out of git, through the repo's local exclude file (shared by
# every worktree), never .gitignore. The line is anchored at the repo's top, so below the top
# it carries the folder's prefix. Added once: it is added only when git says the folder is
# not ignored yet (exit 1; 128 is an error).
GIT_EXCLUDE=""
if [[ -n "$PROJECT_DIR" ]] \
   && [[ "$(git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
  git -C "$PROJECT_DIR" check-ignore -q .hyper-relay/companion/ 2>/dev/null
  if [[ $? -eq 1 ]]; then
    EXCLUDE_FILE="$(git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-path info/exclude)"
    EXCLUDE_PREFIX="$(git -C "$PROJECT_DIR" rev-parse --show-prefix)"
    mkdir -p "$(dirname "$EXCLUDE_FILE")"
    if [[ -s "$EXCLUDE_FILE" && -n "$(tail -c 1 "$EXCLUDE_FILE")" ]]; then
      printf '\n' >> "$EXCLUDE_FILE"
    fi
    printf '/%s.hyper-relay/companion/\n' "$EXCLUDE_PREFIX" >> "$EXCLUDE_FILE"
    GIT_EXCLUDE="added"
  fi
fi

# Reuse the port this session bound last time so the URL is stable and can be stated once.
# server.cjs falls back to a random high port if it is taken, and rewrites state/port with
# whatever it actually bound.
REQUESTED_PORT=""
if [[ -f "${STATE_DIR}/port" ]]; then
  REQUESTED_PORT="$(tr -d '[:space:]' < "${STATE_DIR}/port")"
fi

cd "$SCRIPT_DIR"

# Resolve the harness PID (grandparent of this script).
# $PPID is the ephemeral shell the harness spawned to run us — it dies
# when this script exits. The harness itself is $PPID's parent. When that cannot be told,
# the owner is unknown and the server idles out instead.
OWNER_PID="$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')"
if [[ "$OWNER_PID" == "1" ]]; then
  OWNER_PID=""
fi

# This start's instance id: node carries it, and stop-server.sh proves a pid is ours by it.
INSTANCE_ID="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
if [[ ! "$INSTANCE_ID" =~ ^[0-9a-f]{48}$ ]]; then
  echo '{"error": "Cannot make an instance id"}'
  exit 1
fi
echo "$INSTANCE_ID" > "$ID_FILE"

# Foreground mode for environments that reap detached/background processes.
if [[ "$FOREGROUND" == "true" ]]; then
  echo "$$" > "$PID_FILE"
  exec env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_PORT="$REQUESTED_PORT" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" BRAINSTORM_GIT_EXCLUDE="$GIT_EXCLUDE" BRAINSTORM_MOVED_FROM="$MOVED_FROM" node server.cjs "--companion-id=$INSTANCE_ID"
fi

# Start server, capturing output to log file
# Use nohup to survive shell exit; disown to remove from job table
nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_PORT="$REQUESTED_PORT" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" BRAINSTORM_GIT_EXCLUDE="$GIT_EXCLUDE" BRAINSTORM_MOVED_FROM="$MOVED_FROM" node server.cjs "--companion-id=$INSTANCE_ID" > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
disown "$SERVER_PID" 2>/dev/null
echo "$SERVER_PID" > "$PID_FILE"

# Wait for server-started message (check log file)
for i in {1..50}; do
  if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
    # Verify server is still alive after a short window (catches process reapers)
    alive="true"
    for _ in {1..20}; do
      if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        alive="false"
        break
      fi
      sleep 0.1
    done
    if [[ "$alive" != "true" ]]; then
      echo "{\"error\": \"Server started but was killed. Retry in a persistent terminal with: $SCRIPT_DIR/start-server.sh${PROJECT_DIR:+ --project-dir $PROJECT_DIR} --host $BIND_HOST --url-host $URL_HOST --foreground\"}"
      exit 1
    fi
    grep "server-started" "$LOG_FILE" | head -1
    exit 0
  fi
  sleep 0.1
done

# Timeout - server didn't start
echo '{"error": "Server failed to start within 5 seconds"}'
exit 1
