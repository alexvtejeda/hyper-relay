# Voice-to-Specs Skill

A standalone Claude Code skill that transcribes audio/video recordings using OpenAI Whisper, segments the transcript into structured briefs, and tracks their progress through the spec pipeline.

## Setup

### Requirements
- **Python 3.10+**
- **ffmpeg** — install with `sudo apt install ffmpeg`

### First-Time Setup

Run the setup script to create the venv and install whisper:

```bash
bash ~/.claude/skills/voice-to-specs/scripts/setup.sh
```

This creates a Python venv at `scripts/venv/` with the `openai-whisper` package installed.

## How It Works

### scripts/transcribe.py

Transcription script that:
1. Takes one or more audio/video file paths as arguments
2. Converts each to 16kHz mono WAV using ffmpeg
3. Transcribes using OpenAI Whisper
4. Saves a `.txt` file alongside the original (same name, `.txt` extension)
5. Cleans up temporary WAV files

**Usage:**
```bash
source ~/.claude/skills/voice-to-specs/scripts/venv/bin/activate && python ~/.claude/skills/voice-to-specs/scripts/transcribe.py <file_path> --model base
```

**Model options:** tiny, base, small, medium, large (default: base)

### scripts/setup.sh

One-time setup script that creates the Python venv and installs dependencies.

## Skill Workflow

See SKILL.md for the full workflow. In summary:

1. Transcribe audio/video via Whisper
2. Detect recording type (meeting, testing session, idea dump)
3. Segment transcript into topics/concerns
4. User confirms segmentation
5. Write structured briefs to `docs/superpowers/transcriptions/`
6. Update STATUS.md and CLAUDE.md tracking files

## Output Location

Briefs are written to the **current project's** `docs/superpowers/transcriptions/` directory, not inside this skill directory.
