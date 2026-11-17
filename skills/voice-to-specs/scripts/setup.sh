#!/bin/bash
set -e
# Sets up the Python venv and installs whisper for the voice-to-specs skill.
# Run once: bash setup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating venv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

if python -c "import whisper" 2>/dev/null; then
    echo "openai-whisper already installed."
    exit 0
fi

echo "Installing openai-whisper..."
pip install openai-whisper

echo "Setup complete. Venv at $VENV_DIR"
