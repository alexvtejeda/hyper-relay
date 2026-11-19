# hyper-relay: developing the plugin

hyper-relay is a Claude Code and OpenCode plugin: the workflow skills (brainstorming, spec, plan, execution, review,
merge), forked from [obra/superpowers](https://github.com/obra/superpowers) v5.1.0. `README.md` says what it is and how
to install it. `AGENTS.md` is a link to this file, so OpenCode reads the same rules.

## Layout

- `skills/<name>/`: the 17 skills. Claude Code names them `hyper-relay:<name>`; OpenCode uses the bare name.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: the plugin, and the one-plugin marketplace that
  installs it (source `./`).
- `templates/agents/` and `templates/hooks/planner-guard.py`: the role templates and the planner's guard.
  `bin/hyper-relay-agents` combines them with a repo's committed `.hyper-relay/agents.md` into that repo's
  `.claude/agents/` and `.claude/hooks/` (the `agents` skill). Templates are not under `agents/`, which Claude Code
  would load as live plugin agents.
- `hooks/hooks.json`: one `SessionStart` hook, `hyper-relay-agents --check --hook`, which prints nothing unless the
  repo's generated agents are out of date.
- `.hyper-relay/agents.md`: this repo's own facts, for its `relay-*` agents.
- `bin/wt`: `wt`, a disposable Docker Compose stack for each git worktree (POSIX shell, run by dash). `docs/wt.md` is
  its user reference. Claude Code puts the plugin's `bin/` on the Bash tool's `PATH`, so skills call it by name.
- `bin/relay-merge`: `relay-merge`, which lands branches on `main` one at a time, each as a merge commit whose merged
  result must pass the repo's gates (POSIX shell, run by dash). `docs/relay-merge.md` is its user reference. This
  repo's gates are `.hyper-relay/merge.conf`, which maps its paths to the Checks table below.
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts. `tests/hyper-relay-agents/` tests the
  generator, its hook and the guard. `tests/wt/` tests `wt`, with a fake `docker` and `ss`. `tests/relay-merge/`
  tests `relay-merge`, on temporary git repos with a fake `wt`.
- `tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`:
  upstream's live suites. They run real `claude -p` sessions with `--plugin-dir`, which spends usage and loads the
  directory in place: run them from a worktree, never from a checkout that holds a `.mcp.json`. `docs/testing.md` is
  upstream's guide to them.
- `scripts/check-import.sh`: piece A's proof that moving the skills in changed nothing. It compares against the loose
  copies in `~/.claude/skills/`, so it stops working once those are deleted. `scripts/bump-version.sh`: version bumps.
- `scripts/benchmark/`: piece G.2's tools for a baseline against upstream superpowers. `superpowers-env.sh` builds a
  separate Claude Code config folder for the upstream run, and `run-usage.sh` (with `run-usage.jq` and `prices.tsv`)
  reads a run's transcripts into a usage table. `tests/benchmark/` tests both, with a fake `claude` and fixture
  transcripts. `docs/benchmarks/` holds the protocol's fixed prompts, its run-log template and its runbook.
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

- Develop on a branch, in the main checkout or in a worktree under `.worktrees/` (this repo's `execute:` default is
  `branch`), and merge to `main`.
- **Claude Code** installs from GitHub (`alexvtejeda/hyper-relay`), never from a local path: a local-directory
  marketplace loads gitignored files too, and this checkout's `.mcp.json` would load as the plugin's own MCP server.
  `plugin.json` pins `version`, so `claude plugin update` and auto-update change nothing until the version does.
- **Every merge that changes what the plugin ships is released** (owner, 2026-11-18; this replaces the 2026-11-17 rule
  "0.1.0 until the initiative is finished"). The first release is 0.2.0, once both of piece D.2's plans have merged;
  until then, a merge reaches Claude Code by pushing `main` and reinstalling with
  `claude plugin install hyper-relay@hyper-relay`, which refreshes the installed copy from `main`'s HEAD on GitHub (seen
  2026-11-17). From 0.2.0 on, a merge that changes a file the plugin loads (under `skills/`, `bin/`, `templates/`,
  `hooks/` or `.claude-plugin/`) raises the version: the patch number (0.2.2 next), unless the owner names another. A
  release, on `main` after the merge: `scripts/bump-version.sh <x.y.z>` (it sets `package.json` and
  `.claude-plugin/plugin.json`), a commit of just those two files, `chore: release v<x.y.z>`, the tag `v<x.y.z>`, then
  push `main` and the tag. A plan that ships such a change ends its acceptance task with these as `after merge` steps.
- **The owner updates** with `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in a running
  session (or a new session), instead of uninstalling and reinstalling.
- **Role agents** in a repo change only when its orchestrator reruns `hyper-relay-agents` there; the `SessionStart`
  check says when they are out of date.
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges, and during a branch
  run it sees that branch's skills.
- **`wt`** in the owner's shell is `~/.local/bin/wt`, a symlink to this main checkout's `bin/wt`: a change reaches it
  as soon as it merges, and during a branch run the shell runs that branch's `wt`.
- **`relay-merge`** in the owner's shell is `~/.local/bin/relay-merge`, a symlink to this main checkout's
  `bin/relay-merge`, as `wt`'s is: a change reaches it as soon as it merges.

## Checks

| What | Command | Expect |
|---|---|---|
| Manifests and skills | `claude plugin validate .` | Passes, with three warnings: this `CLAUDE.md` at the plugin root (for developing hyper-relay, not for users), `ICON_MISSING`, and, in this checkout only, `PRIVACY_URL_MISSING`, which comes from the gitignored `.mcp.json` (Quartz's MCP server) |
| add-card-line | `sh tests/add-card-line/run-tests.sh` | `0 failed` |
| voice-to-specs | `sh skills/voice-to-specs/tests/transcribe-sh.test.sh` and `sh skills/voice-to-specs/tests/setup-sh.test.sh` | `0 failed` from each |
| Role agents | `sh tests/hyper-relay-agents/run-tests.sh` and `sh tests/hyper-relay-agents/guard-test.sh` | `0 failed` from each |
| visual-companion | `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, exit 0 |
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
| benchmark | `sh tests/benchmark/run-tests.sh` | `0 failed` |
| Relay skills | `sh tests/orchestrating/run-tests.sh` | `0 failed` |
| Shell syntax | `dash -n` for a `#!/bin/sh` script, `bash -n` for a bash one | silent |
