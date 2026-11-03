---
name: voice-to-specs
description: Use when the user provides audio/video files to transcribe. Runs Whisper transcription, segments the transcript into structured briefs (meetings, testing sessions, idea dumps), and tracks their status through the spec pipeline.
---

# Voice-to-Specs

Transcribe audio/video recordings, segment them into structured briefs, and track their progress through the spec pipeline.

**Announce at start:** "I'm using the voice-to-specs skill to transcribe and segment this recording."

## Prerequisites

`ffmpeg` and Python 3.10+. The command in Step 1 checks for them and sets up its own venv.

## Workflow Step 1: Run Whisper Transcription

Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that.

```bash
sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base
```

If it exits non-zero, see Error Handling.

The script:
- Converts any audio/video format to WAV via ffmpeg
- Transcribes with Whisper using the specified model
- Outputs a `.txt` file alongside the source file
- Cleans up the temporary WAV file after transcription

After transcription completes, read the generated `.txt` file to obtain the transcript content.

For multiple files (including glob patterns), transcribe each file sequentially. Combine all transcripts into one working document, clearly noting the source file at the start of each section.

## Workflow Step 2: Detect Recording Type

Two sources of type information exist. **User prompt takes priority.**

**From the user prompt:**
- "testing session" or "test" → testing session
- "meeting", "client call", or "standup" → meeting
- "ideas", "brainstorm", or "thinking" → idea dump

**From the transcript content:**
- Trigger phrases like "This is a testing session" → testing session
- Navigation cues like "/login", "/dashboard", route names → testing session
- Bug indicators like "this should not happen", "that's wrong" → testing session
- Topic transitions like "next topic", "let's talk about" → meeting
- Free-flowing idea chains without an agenda → idea dump

If the type is unclear after checking both sources, default to **meeting** and confirm with the user before proceeding.

Tell the user what type was detected and why (e.g., "I detected this as a testing session because the transcript contains navigation cues like /dashboard and phrases like 'this should not happen'.").

## Workflow Step 3: Segment the Transcript

### Meetings / Idea Dumps — Segment by Topic

Look for explicit transitions:
- "next topic", "moving on", "let's talk about", "another thing"

If no explicit transitions, fall back to thematic shifts in vocabulary and subject matter.

Each segment should correspond to one feature, topic, or idea.

### Testing Sessions — Segment by Concern and Domain

Identify concern type:
- **Bugs:** "this should not happen", "that's a bug", "expected X but got Y", "it should do X"
- **UI friction:** "this is slow", "this looks off", "this feels wrong", "I would prefer"
- **Feature ideas:** "it would be nice if", "we should add", "can we have"

Identify domain:
- **Frontend:** routes, UI elements, layout, CSS, animations, page behavior
- **Backend:** API responses, database queries, auth logic, server errors

### Choose Where Briefs Go, Then Confirm

If `mcp__quartz__add_tasks` is available in this session, use the **card path**. Count it as available if it is among your tools or your deferred tools; load a deferred tool with ToolSearch before calling it. If it is in neither list, use the **Markdown path**, without searching for the tool and without mentioning Quartz or cards to the user.

On the card path, call `project_status` before asking for confirmation. The first line of its output is the project name; name it in your question, for example "these 4 briefs become cards on project SAT". This catches a wrong token or repo before anything is written. If `project_status` fails, say so and offer the Markdown path, and do not create cards in this run. Do not call `add_tasks` to try anyway, even if the user tells you to create the cards: give them the error, which only they can fix, and the Markdown offer.

**Present the proposed segmentation to the user and wait for confirmation before writing any briefs.** The user can merge segments, split segments, reorder them, or rename them. Only proceed once the user has confirmed the segmentation.

## Workflow Step 4: Save Briefs

Use the appropriate template below based on the segment type, on both paths.

### Card Path

The card is the brief. After confirmation, call `add_tasks` with one item per brief, in segment order:

- `title`: the brief's title
- `body`: the brief's template without its `# <Title>` heading
- `labels`: `["voice"]`

`add_tasks` takes at most 20 items per call and puts each call's cards on top of the column. With more than 20 briefs, send the last 20 first and work backwards, so the column reads in segment order.

Report each card's id and title from the tool's output. Do not write brief files, `STATUS.md` or `CLAUDE.md`, and skip Step 5. The `.txt` transcript from Step 1 stays next to the source file.

**If `add_tasks` returns an error,** the error text names the cards already created, as `(already created: <id> · <title>; ...)`. Cards from earlier successful calls exist too.

1. Do not add those cards again, and do not retry `add_tasks`, not even only for the missing cards, after waiting, or because the user needs them on the board.
2. Write every brief without a card through the Markdown path, including Step 5 for those briefs only.
3. Tell the user which briefs became cards, which became files, and the error.

### Markdown Path

Create the directory `docs/superpowers/transcriptions/` in the current working directory if it does not already exist.

Name each file using the pattern: `YYYY-MM-DD-<topic-slug>.md`

Use the date of the recording if known, otherwise use today's date.

---

### Template: Meeting / Idea Dump

```markdown
# <Title>

**Source:** <audio/video filename>
**Date:** <YYYY-MM-DD>
**Type:** meeting | idea-dump

## Goal

<One sentence describing what this segment is about or what decision/outcome is needed.>

## Context

<Background information relevant to this topic. What led to this conversation?>

## Requirements

<Bullet list of things that need to happen, be built, or be decided.>

## Dependencies

<Other systems, teams, or briefs this depends on. Write "None mentioned" if not applicable.>

## Raw Excerpt

> <Direct quote or close paraphrase from the transcript relevant to this segment.>
```

---

### Template: Testing Session — Bug

```markdown
# <Title>

**Source:** <audio/video filename>
**Date:** <YYYY-MM-DD>
**Type:** bug
**Domain:** frontend | backend | fullstack

## Steps to Reproduce

1. <Step one>
2. <Step two>
3. ...

## Expected

<What should happen.>

## Actual

<What actually happened.>

## Route / URL

<The route or URL where the bug was observed. Write "Not mentioned in recording" if unknown.>

## Context

<Any additional context about the environment, user state, or conditions when the bug occurred.>

## Raw Excerpt

> <Direct quote or close paraphrase from the transcript relevant to this bug.>
```

---

### Template: Testing Session — UI Tweak / Feature Idea / Friction

```markdown
# <Title>

**Source:** <audio/video filename>
**Date:** <YYYY-MM-DD>
**Type:** ui-tweak | feature-idea | friction
**Domain:** frontend | backend | fullstack

## Category

ui-tweak | feature-idea | friction

## Goal

<What improvement or addition is being requested?>

## Context

<Where in the app was this observed? What was the user doing?>

## Requirements

<Bullet list of what needs to change or be added.>

## Raw Excerpt

> <Direct quote or close paraphrase from the transcript relevant to this item.>
```

---

### Template Selection Logic

- Bug reports → use the **Bug** template
- UI tweaks, feature ideas, or friction points → use the **UI Tweak / Feature Idea / Friction** template
- Meeting or idea dump segments → use the **Meeting / Idea Dump** template

If a field cannot be determined from the transcript, write `Not mentioned in recording` rather than leaving it blank.

## Workflow Step 5: Update Tracking Files (Markdown Path)

### STATUS.md

Location: `docs/superpowers/transcriptions/STATUS.md`

Maintain a table with the following columns:

| # | Brief | Source | Type | Status | Spec Path |
|---|-------|--------|------|--------|-----------|

**Status values:**
- `pending` — brief written, no spec started
- `in-progress` — spec is being written
- `done` — spec is complete

If the file already exists, append new rows to the existing table. Do not overwrite existing entries.

### CLAUDE.md

Location: `docs/superpowers/transcriptions/CLAUDE.md`

Include:
- A header explaining that this directory contains structured briefs generated from voice recordings
- A reference to STATUS.md for pipeline tracking
- A **Briefs** section with numbered entries, each showing: title, status, type, domain (if applicable), and a one-line summary
- Update rules for downstream agents: when the brainstorming skill completes a spec from a brief, it should update that brief's status in STATUS.md to `in-progress` or `done` and record the spec path

If the file already exists, update the Briefs section and STATUS.md reference rather than overwriting the header.

After both files are written, report to the user:
- How many briefs were created
- The file names of the new briefs
- That STATUS.md and CLAUDE.md have been updated

## Error Handling

The Step 1 command decides whether the environment can run. React only to a non-zero exit:

- **File not found:** Tell the user the exact path that was not found and ask them to provide the correct path.
- **Any other non-zero exit:** Give the user the message exactly and stop. Do not inspect the venv, probe `ffmpeg`, retry or install anything.

After a successful exit:

- **Empty or very short transcript:** Warn the user that the transcript appears to be empty or unusually short. Ask if the file is valid and if they want to proceed anyway.

## Boundaries

This skill has a defined scope. It does **not**:
- Write specs (that is the brainstorming skill's job)
- Write implementation plans (that is the writing-plans skill's job)
- Execute plans or make code changes (that is the subagent-driven-development skill's job)
- Start servers or run the application
- Segment the transcript without user confirmation

Stay within these boundaries even if the user asks to proceed further within this skill.

## Red Flags

**Never:**
- Write briefs without the user confirming the segmentation
- Skip transcription and work from memory or assumptions
- Start brainstorming or spec writing within this skill
- Leave template fields blank (use "Not mentioned in recording")

**Always:**
- Announce the skill at the start
- Run Whisper via the Bash tool using the exact command above
- Present the proposed segmentation and wait for user confirmation
- Update both STATUS.md and CLAUDE.md after writing briefs
- Report a summary to the user when the skill completes

## Example Sessions

### Meeting Example

```
User: "Transcribe this standup recording: standup-2026-03-20.m4a"

Claude: "I'm using the voice-to-specs skill to transcribe and segment this recording."

[Runs Whisper on standup-2026-03-20.m4a]
[Reads transcript]

Claude: "I detected this as a meeting. The transcript contains explicit topic transitions like 'next topic' and 'let's talk about'.

I found 3 segments:
1. Payment webhook reliability — webhook failures in production, intermittent 500s
2. User onboarding redesign — simplify the signup flow, reduce steps
3. CI pipeline speed — builds taking 12+ minutes, blocking deploys

Does this segmentation look right? Any changes before I write the briefs?"

User: "Looks good."

[Claude writes 3 briefs, updates STATUS.md and CLAUDE.md]

Claude: "Done. Created 3 briefs:
- 2026-03-20-payment-webhook-reliability.md
- 2026-03-20-user-onboarding-redesign.md
- 2026-03-20-ci-pipeline-speed.md

STATUS.md and CLAUDE.md updated in docs/superpowers/transcriptions/."
```

### Testing Session Example

```
User: "Here's a testing recording, mostly frontend: test-session-2026-03-19.m4a"

Claude: "I'm using the voice-to-specs skill to transcribe and segment this recording."

[Runs Whisper on test-session-2026-03-19.m4a]
[Reads transcript]

Claude: "I detected this as a testing session based on your prompt and navigation cues in the transcript (/login, /dashboard).

I found 4 concerns:
1. Login redirect bug — after login, redirected to /home instead of /dashboard (bug / frontend)
2. Slow dashboard render — dashboard takes 4-5 seconds to load (friction / frontend)
3. Remember me checkbox — checkbox present but has no effect (feature idea / frontend)
4. Auth token not refreshing — token expires mid-session without refresh (bug / backend)

Does this segmentation look right? Any changes before I write the briefs?"

User: "Merge 1 and 4 into a single 'Authentication flow bugs' segment."

Claude: "Got it. Updated segmentation:
1. Authentication flow bugs — login redirect + token expiry (bug / fullstack)
2. Slow dashboard render — 4-5 second load time (friction / frontend)
3. Remember me checkbox — no effect when checked (feature idea / frontend)

Confirmed?"

User: "Yes."

[Claude writes 3 briefs, updates STATUS.md and CLAUDE.md]

Claude: "Done. Created 3 briefs:
- 2026-03-19-authentication-flow-bugs.md
- 2026-03-19-slow-dashboard-render.md
- 2026-03-19-remember-me-checkbox.md

STATUS.md and CLAUDE.md updated in docs/superpowers/transcriptions/."
```
