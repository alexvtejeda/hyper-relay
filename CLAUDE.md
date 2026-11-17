# hyper-relay: developing the plugin

hyper-relay is a Claude Code and OpenCode plugin: the workflow skills (brainstorming, spec, plan, execution, review,
merge), forked from [obra/superpowers](https://github.com/obra/superpowers) v5.1.0. `README.md` says what it is and how
to install it. `AGENTS.md` is a link to this file, so OpenCode reads the same rules.

## Layout

- `skills/<name>/`: the 16 skills. Claude Code names them `hyper-relay:<name>`; OpenCode uses the bare name.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: the plugin, and the one-plugin marketplace that
  installs it (source `./`).
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts.
- `tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`, `tests/subagent-driven-dev/`:
  upstream's live suites. They run real `claude -p` sessions with `--plugin-dir`, which spends usage and loads the
  directory in place: run them from a worktree, never from a checkout that holds a `.mcp.json`. `docs/testing.md` is
  upstream's guide to them.
- `scripts/check-import.sh`: piece A's proof that moving the skills in changed nothing. It compares against the loose
  copies in `~/.claude/skills/`, so it stops working once those are deleted. `scripts/bump-version.sh`: version bumps.
- `docs/superpowers/`: hyper-relay's own specs and plans, which Quartz's git hooks upload. Upstream's are in
  `docs/upstream/` and `docs/plans/`.

## Rules

- **Skills are behaviour.** A changed sentence changes what agents do. Change a skill only through a spec and a plan
  that say which behaviour changes.
- **Quartz-first, not Quartz-required.** Every Quartz step falls back to plain Markdown when Quartz is absent.
- **No machine paths in skills.** A skill reaches its own files as `${CLAUDE_SKILL_DIR}/...` and also names them
  relative to its `SKILL.md`, because OpenCode does not expand the variable.
- **`docs/superpowers/` and `.superpowers/` keep their names.** Quartz accepts specs and plans only under
  `docs/superpowers/`, and visual-companion keeps its screens in `.superpowers/`.
- **voice-to-specs stops at writing briefs.** Never extend it to write specs, plans or code: those belong to the
  downstream skills. Its setup and script interface are in `skills/voice-to-specs/CLAUDE.md`.
- Stage named files only, never `git add -A` or `git add .`. `.env`, `.envrc` and `.mcp.json` hold this checkout's
  Quartz wiring and stay gitignored.
- `upstream` is obra/superpowers. A fix from it comes over by cherry-pick, when wanted; never merge upstream wholesale.

## How a change reaches the owner

- Develop on a branch in a worktree under `.worktrees/`, and merge to `main`.
- **Claude Code** installs from GitHub (`alexvtejeda/hyper-relay`), never from a local path: a local-directory
  marketplace loads gitignored files too, and this checkout's `.mcp.json` would load as the plugin's own MCP server.
  `plugin.json` pins `version`, so an installed copy changes only when the version does: raise it with
  `scripts/bump-version.sh <x.y.z>`, merge, push `main`, and tag `v<x.y.z>`.
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges.

## Checks

| What | Command | Expect |
|---|---|---|
| Manifests and skills | `claude plugin validate .` | Passes. Its one warning is about this `CLAUDE.md` at the plugin root, which is for developing hyper-relay, not for users |
| add-card-line | `sh tests/add-card-line/run-tests.sh` | `0 failed` |
| voice-to-specs | `sh skills/voice-to-specs/tests/transcribe-sh.test.sh` | `0 failed` |
| visual-companion | `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, exit 0 |
| Shell syntax | `dash -n` for a `#!/bin/sh` script, `bash -n` for a bash one | silent |
