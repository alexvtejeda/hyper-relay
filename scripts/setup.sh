#!/bin/bash
# Sets up the Python venv and installs whisper for the voice-to-specs skill.
# Run once: bash setup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

if [ -d "$VENV_DIR" ]; then
    echo "Venv already exists at $VENV_DIR"
    exit 0
fi

echo "Creating venv at $VENV_DIR..."
python3 -m venv "$VENV_DIR"

echo "Installing openai-whisper..."
source "$VENV_DIR/bin/activate"
pip install openai-whisper

echo "Setup complete. Venv at $VENV_DIR"
