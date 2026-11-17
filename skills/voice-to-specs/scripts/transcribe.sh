#!/bin/sh
# The single entry point for transcription. It decides whether this machine can run
# the tools, so the agent does not have to: a non-zero exit and its message are all
# the agent reacts to.
# Usage: sh transcribe.sh <file>... [--model base]
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyper-relay/voice-to-specs/venv"

# File tests only: `import whisper` loads torch and takes seconds.
whisper_installed() {
    [ -x "$VENV_DIR/bin/python" ] || return 1
    for init in "$VENV_DIR"/lib/python*/site-packages/whisper/__init__.py; do
        [ -f "$init" ] && return 0
    done
    return 1
}

# First, and for .wav too: Whisper's audio loader runs ffmpeg even when
# transcribe.py has nothing to convert. Fail here, not after a large install.
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "voice-to-specs: ffmpeg is not installed. Install it with: sudo apt install ffmpeg" >&2
    exit 1
fi

if ! whisper_installed; then
    if ! bash "$SCRIPT_DIR/setup.sh"; then
        echo "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." >&2
        exit 1
    fi
fi

exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/transcribe.py" "$@"
