---
name: agents
description: Use when a repo needs its role agents (planner, executor, reviewer) generated or refreshed from hyper-relay's templates, when a session starts with a "hyper-relay: ... out of date" notice, when hyper-relay-agents refuses a file, or when those agents must be adapted for OpenCode
---

# Role agents for a repo

A repo's role agents are generated, never written by hand. hyper-relay's templates hold the general rules of each
role. The repo's committed facts file, `.hyper-relay/agents.md`, holds only what is true of this repo. The
`hyper-relay-agents` generator combines the two into `.claude/agents/<project>-planner.md`, `<project>-executor.md`
and `<project>-reviewer.md`, plus the planner's guard, `.claude/hooks/hyper-relay-planner-guard.py`. None of those
four is committed: they come from the templates and the facts, and they hold this machine's paths.

Where a lesson goes:
- **True only in this repo** → a section of this repo's facts file.
- **True in any repo of its kind** → a template change in hyper-relay. That is a hyper-relay change through a spec
  and a plan (a card), never a quick edit, and never an edit to a generated agent.

## Running the generator

In Claude Code the plugin puts `hyper-relay-agents` on the Bash tool's PATH. If the command is not found, run it by
its path: `${CLAUDE_SKILL_DIR}/../../bin/hyper-relay-agents` (`../../bin/hyper-relay-agents` from the folder that
holds this SKILL.md). Run it in the repo's main checkout, where the orchestrator dispatches agents from: the
planner's guard hook finds its copy through `$CLAUDE_PROJECT_DIR`, the folder the session started in.

| Command | What it does |
|---|---|
| `hyper-relay-agents` | Writes the four files, one line each: `written`, `unchanged`, or `refused` with the reason. Exit 1 if any is refused or the facts file has a problem; then nothing is half-written. |
| `hyper-relay-agents --force` | The same, and also overwrites a refused file. Only after the owner has agreed (step 3). |
| `hyper-relay-agents --check` | Writes nothing. One line per file that is missing, out of date, edited by hand or written by hand; exit 1 if there is any. |

Each generated file carries a marker line with the SHA-256 of its content. That is how the generator tells a file it
wrote from one someone edited. A file is out of date when its content differs from what the templates and the facts
give now; the version in the marker does not decide it.

## The facts file

```markdown
---
project: myapp
reviewer: browser
model.executor: sonnet
---
Notes for humans. The generator ignores everything before the first ## heading.

## planner/before-writing
- Take the next free migration number from `db/migrations/` on main.

## executor/gates
- `make build`, `make lint`, `make test`.
```

**Header**, plain `key: value` lines between the two `---` lines:

| Key | Value |
|---|---|
| `project` (required) | Lowercase letters, digits and `-`. Names the files: `<project>-planner.md`. |
| `reviewer` (required) | `browser` (a click-through of a running app) or `commands` (acceptance by running commands and live CLI sessions). |
| `model.planner`, `model.executor`, `model.reviewer` | A Claude Code model: `opus`, `sonnet`, `haiku` or a full model id. Defaults: planner `opus`, executor `sonnet`, reviewer `sonnet`. |

Any other key is an error.

**Sections:** `## <role>/<slot>`, one per slot the repo fills. The body is copied verbatim into that slot of the
template, which sits inside or after a bullet list, so write bullets. Every `## ` line starts a section; use `###`
inside a body. A section that matches no slot, an empty section, or a section given twice is an error. A slot without
a section is left out, and so is a heading left with nothing under it.

| Section | Where it lands | For example |
|---|---|---|
| `planner/before-writing` | planner, "Before writing" | where a migration number comes from; which external facts specs usually cite |
| `planner/plan-format` | planner, after the plan-format line | extra header lines; a contract between paired plans |
| `planner/execution-notes` | planner, "Every plan's Execution notes carry" | the full gates; how stacks may be started; owner-only steps |
| `planner/report` | planner, end of "Report" | extra report items |
| `executor/setup` | executor, "Where" | an install step a worktree needs |
| `executor/gates` (**required**) | executor, "Full gates" | build, lint and test commands, and when the slow ones run |
| `executor/constraints` | executor, "Constraints" | the only allowed way to start a stack; a test that goes with a kind of change |
| `executor/acceptance` | executor, "A plan that ends with an acceptance task" | start the stack, leave it up, report its URLs and logins |
| `reviewer/before-you-start` | reviewer, "Before you start" | which URLs to check; commands never to run |
| `reviewer/helpers` | reviewer, "Helpers" | one-time codes, a mail catcher, read-only database queries, a browser |
| `reviewer/seed-facts` | reviewer, "Seed facts" | seeded logins and rate limits |
| `reviewer/gotchas` | reviewer, "Gotchas that look like bugs but aren't" | UI-library quirks |
| `reviewer/look-beyond` | reviewer, "Look beyond the checklist" | a second UI language; a second harness |

The templates themselves are in `${CLAUDE_SKILL_DIR}/../../templates/agents/` (`../../templates/agents/` from this
SKILL.md's folder): read them to see each slot in place.

## 1. No facts file yet

1. Read the repo's `CLAUDE.md`, its compose file and Makefile if it has them, and any hand-written agents in
   `.claude/agents/`.
2. Sort every line of those agents: **general** (a template already says it, or should: that is a hyper-relay
   change, say so) or **project-specific** (a facts section). A line that is neither, say why it can go.
3. Draft `.hyper-relay/agents.md`. Show the owner the draft and the sorting, line by line, and write the file only
   after the owner approves.
4. Commit it like any other file of the repo, staging it by its path.

## 2. Run the generator

Run `hyper-relay-agents` and tell the owner what changed, file by file. If it printed `Created .claude/agents/`, say
that the session must be restarted before any of these agents is dispatched: Claude Code watches only agent folders
that existed when the session started.

If the facts file has problems, nothing is written and every problem is listed. Fix them all, then run it again.

When a session starts with a `hyper-relay: … out of date` notice, run `hyper-relay-agents --check` to see which files
and why, then `hyper-relay-agents`. In OpenCode, adapt the changed agents again (step 5).

## 3. A refused file

`refused` means the file on disk is not what the generator last wrote: someone edited it, or it was written by hand
(it has no marker). Never overwrite it on your own.

1. Find the change. For an edited agent, the refusal names the heading it is under and the facts section it
   probably belongs in. Read that part of the file next to the same part of the template and the facts file's
   section: what is in neither is the hand edit. For a hand-written file, sort every line as in step 1.
2. Propose where it belongs. A project lesson goes into the facts file. A general one is a template change in
   hyper-relay: propose a card for it, and keep it in the facts file meanwhile if the owner wants it now.
3. Make the change the owner agrees to, then run `hyper-relay-agents --force`, and only then.

The guard is never edited per repo: its rules are the same everywhere. A refused guard means someone changed it by
hand; tell the owner, and restore it with `--force` once they agree.

## 4. Not ignored

The generated files must not be committed. Check:
`git check-ignore -v .claude/agents/<project>-planner.md .claude/hooks/hyper-relay-planner-guard.py`.
If either is not ignored, say so and propose these `.gitignore` lines (the generator never edits `.gitignore`):

```gitignore
# Generated by hyper-relay-agents from .hyper-relay/agents.md; never committed.
.claude/agents/<project>-*.md
.claude/hooks/hyper-relay-planner-guard.py
# OpenCode copies of them, with each person's model choice.
.opencode/agents/
```

## 5. In OpenCode

OpenCode does not read `.claude/agents/`. Generate first (the generator runs from a shell by its path, as above),
then follow `${CLAUDE_SKILL_DIR}/opencode.md` (`opencode.md` beside this SKILL.md) to adapt each agent.
