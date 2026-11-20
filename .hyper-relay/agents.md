---
project: relay
reviewer: commands
execute: branch
---
hyper-relay's own role agents. `bin/hyper-relay-agents` combines this file with `templates/` into
`.claude/agents/relay-planner.md`, `relay-executor.md`, `relay-reviewer.md` and
`.claude/hooks/hyper-relay-planner-guard.py`, all gitignored. Edit this file, never the generated agents, then rerun
the generator (the hyper-relay:agents skill). The generator ignores everything before the first section heading.

## planner/before-writing
- hyper-relay is a Claude Code and OpenCode plugin: Markdown skills, shell scripts and their tests, with no app or
  stack.
- The outside systems this repo's specs depend on are usually Claude Code, OpenCode and GitHub.

## planner/plan-format
- The model is the newest hyper-relay plan in `docs/superpowers/plans/`, for its header and acceptance task, not its
  steps; upstream's older plans in `docs/upstream/` and `docs/plans/` are not.

## planner/execution-notes
- The full gates: the test suites the plan touches (the Checks table in `CLAUDE.md`), plus `claude plugin validate .`.
- Also the owner's or the orchestrator's: anything that touches `~/.claude/`, `~/.config/opencode/` or the home
  directory's own repo, and installing or uninstalling a plugin.
- **Releases** (`CLAUDE.md`, "How a change reaches the owner"): once `main`'s `.claude-plugin/plugin.json` is at 0.2.0
  or later, a plan that changes a file the plugin loads (under `skills/`, `bin/`, `templates/`, `hooks/` or
  `.claude-plugin/`) ends its acceptance task with these `after merge` steps, last, on `main` in the main checkout. (1)
  `scripts/bump-version.sh <x.y.z>`, where `<x.y.z>` is `main`'s version then (`scripts/bump-version.sh --check`) with
  its patch number raised by one, unless the owner names another; PASS: `--check` shows both files at `<x.y.z>`. (2) A
  commit of just `package.json` and `.claude-plugin/plugin.json`, `chore: release v<x.y.z>`, with the attribution lines;
  `git tag v<x.y.z>`; `git push origin main v<x.y.z>`. (3) The owner's `claude plugin update hyper-relay@hyper-relay`,
  then `/reload-plugins` in a running session (or a new session); PASS: the cache holds
  `~/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/`.

## executor/setup
- hyper-relay is a Claude Code and OpenCode plugin: Markdown skills, shell scripts and their tests. There is no app
  or stack to start.

## executor/gates
- The suites the plan touches, from the Checks table in `CLAUDE.md`, plus `claude plugin validate .`.
- Syntax-check each shell script you touched with `bash -n`, or `dash -n` for a `#!/bin/sh` one.

## executor/constraints
- `claude plugin validate .` is fine: it starts no session.

## reviewer/before-you-start
- hyper-relay is a Claude Code and OpenCode plugin: Markdown skills, shell scripts and their tests. Look first for
  a skill that doesn't load or loads under the wrong name.

## reviewer/helpers
- **Browser** (only for visual-companion screens): the Playwright MCP connects over CDP to
  `http://localhost:9444`. Check with `curl -s -m 2 http://127.0.0.1:9444/json/version`. If nothing answers
  (WSL usually can't reach Windows Chrome), start a headless Linux Chrome in the background:
  `google-chrome --headless=new --remote-debugging-address=127.0.0.1 --remote-debugging-port=9444
  --user-data-dir=<evidence folder>/chrome-profile --no-first-run --no-default-browser-check about:blank`.
  Note its PID from `ss -lntpH 'sport = :9444'`, so you can stop it at the end. Load the Playwright tools in
  ONE ToolSearch call. **Open a second tab before testing, and close the first:** in the first tab after a
  fresh Chrome launch, real mouse and keyboard events never reach the page, which reads as a product bug.

## reviewer/look-beyond
- **Skills:** a reference to a skill that doesn't exist.
- **This machine:** skill text that names a path on this machine (`/home/…`, `~/.claude/skills/…`). hyper-relay is
  meant to be shareable.
- **Both harnesses:** something that works in Claude Code but not in OpenCode, or the reverse
  (`${CLAUDE_SKILL_DIR}` is Claude Code's alone).
