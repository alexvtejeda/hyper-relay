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

## Pipeline position

Voice-to-specs is the first stage of this pipeline:

```
voice-to-specs → brainstorming → writing-plans → subagent execution
```

The skill deliberately stops at writing briefs. Do not extend it to write specs, plans, or code — those belong to downstream skills.

**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is untracked but is what Claude Code loads at runtime.

## Related but separate codebase

`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses the script at `.claude/skills/voice-to-specs/scripts/transcribe.py`. Don't conflate the two when editing.

## When modifying the skill

- Keep the design spec and plan in sync with `SKILL.md` changes. The spec is marked "Approved (v2)" — meaningful scope changes warrant a new version note.
- The skill announces itself at start ("I'm using the voice-to-specs skill...") and requires user confirmation of segmentation before writing briefs. Preserve both behaviors.
- Briefs always land in the **caller's** working directory, never inside this repo. Don't write transcription outputs into `.claude/skills/voice-to-specs/`.
- Python venvs under `scripts/venv/` and `whisperVenv/` are gitignored by convention — do not commit them.

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
