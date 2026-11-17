# Voice-to-Specs Skill

A standalone Claude Code skill that transcribes audio/video recordings using OpenAI Whisper, segments the transcript into structured briefs, and tracks their progress through the spec pipeline.

## Setup

### Requirements
- **Python 3.10+**
- **ffmpeg** — install with `sudo apt install ffmpeg`

### Setup

Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv` with CPU-only `torch` and the `openai-whisper` package installed, outside the plugin, so that a plugin update does not delete it. Torch comes from PyTorch's CPU index first: whisper alone would pull PyPI's default CUDA build, whose GPU check segfaults under WSL.

## How It Works

### scripts/transcribe.sh

The single entry point for transcription, and the only command `SKILL.md` runs. POSIX shell, run by dash; verify with `dash -n`. In order:

1. If `ffmpeg` is not on `PATH`, it exits 1 with one message.
2. If the venv's Python is not executable or whisper is not in the venv, it runs `setup.sh`. If that fails, it exits 1 with one message.
3. Otherwise it runs `transcribe.py` with the venv's Python, passing its arguments through. The exit status is `transcribe.py`'s.

The checks are file tests, because `import whisper` takes seconds. The agent reacts only to a non-zero exit.

**Usage:**
```bash
sh scripts/transcribe.sh <file_path> --model base
```

**Model options:** tiny, base, small, medium, large (default: base)

**Tests:** `sh tests/transcribe-sh.test.sh` and `sh tests/setup-sh.test.sh` (expect `0 failed` from each). They need no real venv, whisper or ffmpeg, and download nothing.

### scripts/transcribe.py

Transcription script that:
1. Takes one or more audio/video file paths as arguments
2. Converts each to 16kHz mono WAV using ffmpeg
3. Transcribes using OpenAI Whisper
4. Saves a `.txt` file alongside the original (same name, `.txt` extension)
5. Cleans up temporary WAV files

### scripts/setup.sh

Idempotent setup script that creates the Python venv and installs dependencies. `transcribe.sh` calls it when needed.

## Pipeline position

Voice-to-specs is the first stage of this pipeline:

```
voice-to-specs → brainstorming → writing-plans → subagent execution
```

The skill deliberately stops at saving briefs, as Quartz cards or Markdown files. Do not extend it to write specs, plans, or code — those belong to downstream skills.

**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code and OpenCode load at runtime: an edit reaches Claude Code when the hyper-relay plugin updates, and OpenCode when it merges to the main checkout.

## Related but separate codebase

`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses `scripts/transcribe.py` in this folder. Don't conflate the two when editing.

## When modifying the skill

- Keep the design spec and plan in sync with `SKILL.md` changes. The spec is marked "Approved (v2)" — meaningful scope changes warrant a new version note.
- The skill announces itself at start ("I'm using the voice-to-specs skill...") and requires user confirmation of segmentation before writing briefs. Preserve both behaviors.
- Markdown briefs always land in the **caller's** working directory, never inside this repo. Don't write transcription outputs into this skill's folder.
- Edits to `SKILL.md` are tested with fresh agents against a throwaway Quartz project on an isolated stack, never a real board. Subagents inherit the parent's MCP servers, so use `claude -p --strict-mcp-config --mcp-config <file>`.
- The venv lives outside the repo (see Setup). `scripts/.gitignore` still ignores a stray `scripts/venv/`, and `whisperVenv/` is gitignored by convention — do not commit either.

## Skill Workflow

See SKILL.md for the full workflow. In summary:

1. Transcribe audio/video via Whisper
2. Detect recording type (meeting, testing session, idea dump)
3. Segment transcript into topics/concerns
4. User confirms segmentation
5. Save briefs: as cards in Needs brainstorming, labelled `voice`, when `mcp__quartz__add_tasks` is available; otherwise to `docs/superpowers/transcriptions/`
6. On the Markdown path only, update the STATUS.md and CLAUDE.md tracking files

## Output Location

On the card path, the brief is a card on the board of the project the repo's token belongs to, and no brief file is written. On the Markdown path, including any brief that could not become a card, briefs are written to the **current project's** `docs/superpowers/transcriptions/` directory, not inside this skill directory. The `.txt` transcript is written next to the source file on both paths.
