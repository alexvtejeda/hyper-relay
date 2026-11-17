# hyper-relay A: the fork's home Implementation Plan

**Card:** The fork's home (`09c73bab-55f1-4768-93e8-8889d4134ef6`)

> **For agentic workers:** REQUIRED SUB-SKILL: executing-plans (the relay-executor preloads it). Tasks 1–8 are the
> executor's, in `.worktrees/hyper-relay-a-forks-home`. Task 9 is the orchestrator's, run with the owner after the
> merge. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the owner's daily workflow skills (14 upstream skills with the owner's edits, `visual-companion`,
`voice-to-specs` with its history, `add-card-line.sh` and its tests) into hyper-relay, a private plugin for Claude Code
and OpenCode, with no behaviour change except voice-to-specs' venv location.

**Architecture:** Commits in the spec's §2 order on top of obra's v5.1.0 history: strip the other harnesses, move
upstream's docs aside, import each edited skill as an exact mirror of its loose copy (one commit per skill, before any
rename), add visual-companion, add voice-to-specs by a non-squashed `git subtree add`, move the add-card-line suite,
rename to hyper-relay, then move the venv. `scripts/check-import.sh` re-applies the rename rule and the venv move to a
temp copy of every loose skill and diffs it against `skills/`: an empty diff is the proof. The switch-over (GitHub,
installs, edits outside the repo) is Task 9, run by the orchestrator with the owner.

**Tech Stack:** Markdown skills, POSIX `sh` (dash) and bash scripts, `git subtree`, GNU `tar`/`sed`/`awk`/`diff`,
Node (visual-companion's tests), Claude Code 2.1.326 (`claude plugin validate`), OpenCode v2.3.0, `gh`.

**Spec:** `docs/superpowers/specs/2026-11-17-hyper-relay-a-forks-home-design.md` (owner-approved 2026-11-17, one
plan, decisions A1–A9, facts in §5). The README starts from `docs/README.draft.md` (2026-11-17); this plan settles its
two `TO VERIFY` notes (deviations D27, External facts).

**How this was checked:** written against `main` at `af1d79b` by reading only; nothing was built, run, installed or
fetched into the repo. Read in this repo: the spec (in full); `docs/README.draft.md`; `CLAUDE.md` (= `AGENTS.md`, a
symlink to it, mode 120000); `README.md`; `LICENSE`; `package.json`; `.claude-plugin/{plugin.json,marketplace.json}`;
`.version-bump.json`; `.gitignore`; `.gitattributes`; `scripts/bump-version.sh`; `docs/README.opencode.md` (1–30);
`docs/windows/polyglot-hooks.md` (1–12); `tests/opencode/{setup.sh,run-tests.sh}` and a grep of the suite;
`tests/brainstorm-server/{server.test.js (1–60 and every test name),windows-lifecycle.test.sh (1–30)}` and the test
names of `ws-protocol.test.js`; `skills/writing-skills/render-graphs.js` (1–25); the local agents
`.claude/agents/relay-{executor,planner}.md` (and a grep of `relay-reviewer.md`); `git ls-files`; greps for
harness names, `superpowers`, the upstream doc file names and `brainstorm-server`. Read outside the repo:
`git diff --no-index` (numstat, summary, full text) of every upstream skill against `~/.claude/skills/<skill>`;
`git ls-files -o` listings of the 16 loose skills; `~/.claude/skills/visual-companion/` (`SKILL.md` 70–129 and
greps, `scripts/run-tests.sh`, `test-session.cjs` 1–40 and its case names, `test-injection.cjs` 1–30, greps of
`server.cjs`) and its diff against `~/.config/opencode/skills/visual-companion/` (identical);
`~/.claude/skills/voice-to-specs/` (`SKILL.md` 1–30 and greps, `CLAUDE.md`, `scripts/{setup.sh,transcribe.sh,.gitignore}`,
`tests/transcribe-sh.test.sh`; its repo's `log`, `ls-files -s`, `status --ignored`);
`~/.claude/tests/add-card-line/run-tests.sh`; `~/.claude/CLAUDE.md`; `/home/noob_master/CLAUDE.md` (1–42);
`/home/noob_master/package.json`; the home repo's `ls-files`, `status` and `diff --cached` for the paths it will stop
tracking; `~/.config/opencode/opencode.json` and `~/.config/opencode/skills/`;
`~/sat.pentraze.com/.claude/agents/sat-planner.md` (1–27) and `sat-executor.md` (1–20); greps of
`~/.claude/{CLAUDE.md,settings.json,settings.local.json,hooks,agents,commands,rules,bin}`,
`~/.claude/projects/*/memory/*.md`, `~/sat.pentraze.com/{CLAUDE.md,.claude/}`, every other loose skill in
`~/.claude/skills/`, `~/.claude/skills/synced/<id>/manifest.json`, `~/.claude/plugins/{installed_plugins,known_marketplaces}.json`
and `~/quartz` (for `add-card-line`); `~/sat.pentraze.com/docs/superpowers/plans/2026-11-16-system-emails-admin-web.md`
(1–80, for this format).

**Numbers re-checked today (spec §1.2, §2):**

| Spec says | Found | |
|---|---|---|
| brainstorming 69 changed lines | `SKILL.md` +47/−22 = 69; plus `scripts/add-card-line.sh` added (93 lines) and 6 companion files deleted | as spec |
| writing-plans 19 | +18/−1 = 19 | as spec |
| subagent-driven-development 2, using-git-worktrees 2 | +1/−1 each (their `description`) | as spec |
| using-superpowers 8 | `SKILL.md` +2/−6 = 8, **and** the loose copy has no `references/` (3 files upstream has) | D2 |
| nine skills byte-identical | eight are; **dispatching-parallel-agents** has a 1-line `description` edit and a stray `.zip` | D1 |
| 26 `superpowers:` prefix uses | 26 uses on 25 lines (executing-plans 5, subagent-driven-development 8, systematic-debugging 3, writing-plans 5, writing-skills 5), all skill prefixes | as spec |
| 10 `docs/superpowers/` uses | 10 (9 in the upstream-derived skills, 1 in visual-companion's `test-session.cjs`); voice-to-specs adds 7 `docs/superpowers/transcriptions/` uses; all stay | D3 |
| visual-companion identical in both harnesses | identical (`git diff --no-index` empty) | as spec |
| voice-to-specs: 11 commits from 2026-03-20, branch `master` | 11 commits, first 2026-03-20, working tree clean; only `scripts/venv/` is untracked (ignored by its `scripts/.gitignore`) | as spec |

**Junk in the loose copies, and how the mirror leaves it out:** `dispatching-parallel-agents/.zip` (3,009 bytes) and
voice-to-specs' `scripts/venv/` (whisper and torch) and `.git/`. Nothing else: no `__pycache__`, `node_modules`,
`.superpowers/` screens or logs in any of the 16. The mirror is
`tar -C <loose> --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C <dest> -xf -`, the same
exclusions `scripts/check-import.sh` uses; voice-to-specs itself comes in by `git subtree add`, which takes committed
files only.

**External facts (re-verified 2026-11-17):**
- OpenCode skills, [opencode.ai/docs/skills](https://opencode.ai/docs/skills/): `skills` in `opencode.json` is a
  **flat array of strings** (directories or URLs; `~` accepted; a relative path resolves from OpenCode's working
  directory); explicit entries have the highest precedence; skills are also discovered in `~/.config/opencode/skills`,
  `~/.claude/skills`, `~/.agents/skills` and the project's `.opencode/`, `.claude/`, `.agents/` folders; grouping
  folders add no prefix (so discovery is recursive: `teams/release/SKILL.md` is `release`); paths inside a skill are
  relative to its `SKILL.md`, and the agent is given the skill's base directory; no variable substitution. This settles
  the draft README's `TO VERIFY` on the `skills` shape.
- Claude Code skills, [code.claude.com/docs/en/skills.md](https://code.claude.com/docs/en/skills.md):
  `${CLAUDE_SKILL_DIR}` is the folder holding the skill's `SKILL.md` (for a plugin, the skill's own subfolder), and is
  substituted in the skill's Markdown content and its `allowed-tools`; plugin skills are `plugin-name:skill-name`; a
  bare `/name` still invokes a plugin skill unless another command already uses that name.
- Sub-agents, [code.claude.com/docs/en/sub-agents.md](https://code.claude.com/docs/en/sub-agents.md): `skills:`
  preloads full skill content; the examples show only bare names; a missing or disabled listed skill is skipped with a
  warning in the debug log. Prefixed names are still undocumented (so §3.4's test stands).
- Plugin manifest, [code.claude.com/docs/en/plugins-reference.md](https://code.claude.com/docs/en/plugins-reference.md):
  `name` is the only required field (kebab-case); `author` needs `name`; `homepage` must parse as a URL;
  **a `CLAUDE.md` at the plugin root is not loaded as context and `claude plugin validate` warns about it**;
  `${CLAUDE_PLUGIN_DATA}` survives updates (`~/.claude/plugins/data/<id>/`).
- Plugin CLI, [code.claude.com/docs/en/plugins/cli-reference.md](https://code.claude.com/docs/en/plugins/cli-reference.md):
  `claude plugin validate <dir>` with both `marketplace.json` and `plugin.json` validates the marketplace, the manifest
  and the component files (v2.1.289+); it prints README **advice** (not a warning) unless the README has a
  `plugin install <name>@<marketplace>` line; `claude plugin marketplace add` takes `owner/repo[#ref]`;
  `claude plugin tag` would name a tag `hyper-relay--v0.1.0` (this plan tags `v0.1.0`, as the spec says).
- Loading, [code.claude.com/docs/en/plugins/loading.md](https://code.claude.com/docs/en/plugins/loading.md): a
  local-directory marketplace loads in place, a GitHub one is copied into `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`;
  a pinned `version` keeps users on that copy until it changes; **auto-update is off by default for every marketplace
  that is not Anthropic's**; Node dependencies install only when the plugin root has `package.json` **and** a lockfile.
- Marketplace, [code.claude.com/docs/en/plugins/marketplace-reference.md](https://code.claude.com/docs/en/plugins/marketplace-reference.md):
  `name`, `owner` (with `name`) and `plugins` are required; validate warns on a missing top-level `description` and
  when an entry sets `version` that `plugin.json` also sets.
- Differences from spec §5, all handled below: the `CLAUDE.md` warning (D16), auto-update being off (D20), bare names
  still invoking plugin skills (D24, D25), OpenCode's recursive discovery (D25).

---

## Execution notes (binding)

- **Where.** Work only in `/home/noob_master/hyper-relay/.worktrees/hyper-relay-a-forks-home` on branch
  `hyper-relay-a-forks-home` (already created from `main`). The shell does not keep its directory between Bash calls:
  start every call with `cd /home/noob_master/hyper-relay/.worktrees/hyper-relay-a-forks-home && `. Paths below are
  relative to that root unless absolute.
- **The loose copies are read-only inputs.** Read `~/.claude/skills/<skill>`, `~/.claude/tests/add-card-line/` and
  `~/.config/opencode/skills/visual-companion` and copy FROM them; never modify them, `~/.claude/` or the home repo.
  `git subtree add` only fetches from the voice-to-specs repo.
- **If the loose copies changed since this plan** (an import's numstat differs from the one shown), STOP and report:
  the owner edited a skill after planning.
- **Commits.** Commit after every task (several commits where a task says so), staging named paths only (never
  `git add -A` / `git add .`). Put the trailers in ONE final paragraph, so git reads them all as trailers: each task's
  final commit is
  `git commit -m "<subject>" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#<N>`
  followed, inside the same quoted paragraph, by the two attribution lines your instructions give
  (`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and `Claude-Session:` with the real URL from your
  dispatch prompt). Earlier commits in a task carry only the attribution paragraph. The commands below show these
  lines; put the dispatch prompt's URL where they say `<the URL your dispatch prompt gives>`.
- **A `quartz:` line printed by a commit:** report it. Never add card lines to upstream's docs.
- **Never** start a live `claude -p` / `opencode run` session, install a plugin, add a marketplace, push, tag, or
  create anything on GitHub. `claude plugin validate .` is fine. Never run `transcribe.sh` for real (it would build a
  whisper venv); the tests use stubs.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line. visual-companion's
  `run-tests.sh` starts and stops its own servers on `127.0.0.1`; if a port is taken, report it.
- **Token budget.** Each task runs its targeted check only. The full gates run once, in Task 8. Syntax-check every
  script you touch (`dash -n` for `#!/bin/sh`, `bash -n` for bash).
- `sed -i` and `tar --exclude` below are GNU forms (this is Linux). `scripts/bump-version.sh --check` needs `jq`: if
  `jq` is missing, say so and skip that one check.
- Task 9 is not the executor's. After Task 8, report and stop.

## Spec ambiguities and deviations (each decided here)

| # | Question | Decision |
|---|---|---|
| D1 | Spec: nine skills byte-identical | **dispatching-parallel-agents is not:** the owner rewrote its `description` (1 line) and its folder holds a stray `.zip`. It gets a sixth import commit (Task 3); the `.zip` is left out. |
| D2 | using-superpowers' import | The loose copy also lacks upstream's `references/{codex-tools,copilot-tools,gemini-tools}.md`, so the mirror deletes them. Its line 36 still points at two of them: a dangling reference that exists today, moved as is (no behaviour change); a later piece can fix it. |
| D3 | `docs/superpowers/` count | 10 as the spec says, plus voice-to-specs' 7 `docs/superpowers/transcriptions/` uses the spec did not count. All stay. |
| D4 | `~/.config/superpowers/` (5 uses about global worktrees, 1 example path in subagent-driven-development) | Not in the rule table. **They stay**, like `.superpowers/`: renaming would change where existing global worktrees are found. |
| D5 | "Prose that names the plugin" | 5 lines: executing-plans 14, finishing-a-development-branch 183, using-superpowers 20 and 23, and visual-companion's `frame-template.html` `<title>` (a browser tab now reads "hyper-relay Brainstorming"). |
| D6 | Spec §1.4 keeps `tests/opencode` | **Removed in Task 1:** all four of its tests install and exercise `.opencode/plugins/superpowers.js` (the V1 plugin the spec removes), so the suite could never run again. **Owner: confirm, or keep it as a dead suite.** |
| D7 | Docs of removed things | `docs/README.opencode.md` (installs the V1 plugin) and `docs/windows/polyglot-hooks.md` (documents `hooks/run-hook.cmd`) go in Task 1 with what they document. |
| D8 | "Codex/Cursor/Gemini sections of the docs" | `README.md` and `CLAUDE.md` lose theirs in their wholesale rewrites (Task 7), not by trimming in Task 1. Upstream's `RELEASE-NOTES.md`, `docs/testing.md`, `docs/plans/`, `.github/`, `CODE_OF_CONDUCT.md`, `.gitattributes` and `assets/{app-icon.png,superpowers-small.svg}` stay as upstream wrote them (history and credit; renaming them changes nothing). |
| D9 | §1.4: `tests/brainstorm-server` | **Dropped as superseded (Task 4).** It tests a different server: `skills/brainstorming/scripts/server.cjs`, which Task 3 deletes. `ws-protocol.test.js` unit-tests WebSocket framing functions the owner's `server.cjs` does not have (it exports only `startServer`; the browser polls `/poll`); `server.test.js` needs the `ws` package and covers WebSocket relays, `state/events` click capture and reload pushes that the owner removed on purpose (the companion is display-only); `windows-lifecycle.test.sh` targets brainstorming's scripts and a `server.js` that does not exist, on Windows only. None of it runs against visual-companion without a rewrite. visual-companion's `run-tests.sh` covers named sessions (directory, restart keeps screens, same port, second start returns the running server, stop) and the inject-before-the-last-`</body>` regression. **Not covered there, and worth a later card:** upstream's HTTP cases (waiting page, helper injected, `Content-Type`, full documents as-is, fragments wrapped in the frame, newest file by mtime, non-HTML ignored, `server-info` written). |
| D10 | Does the rename touch tests? | Yes, the skill prefix only: 8 lines in 7 kept test files name `superpowers:<skill>` in prompts or assertions, which would never match a plugin named hyper-relay. |
| D11 | voice-to-specs' `CLAUDE.md` | Its own-path lines 29, 63 and 69 become skill-relative (`${CLAUDE_SKILL_DIR}` is not expanded in a `CLAUDE.md`); line 59 ("an edit here is live at once, on any branch") is false once the skill is a plugin and is rewritten; lines 13 and 71 follow the venv (Task 8). `scripts/check-import.sh` encodes each line. |
| D12 | "Worded so OpenCode finds the same file" | Each `${CLAUDE_SKILL_DIR}/scripts/<x>` line also names `` `scripts/<x>` beside this SKILL.md ``, which reads right in both harnesses after substitution. |
| D13 | The voice-to-specs test and the venv | `tests/transcribe-sh.test.sh` builds its stub venv where `transcribe.sh` now looks (`XDG_DATA_HOME` inside the sandbox) and gains one case for the `$HOME/.local/share` fallback (18 checks, was 17). |
| D14 | `package.json` keeps "only what bump-version needs" | It becomes `name` + `version`. `"type": "module"` goes too: it would make `skills/writing-skills/render-graphs.js` (CommonJS `require`) fail inside the plugin, while the loose copy runs as CommonJS today (`~/package.json` has no top-level `type`). |
| D15 | Versions | The marketplace entry no longer repeats `version` (validate warns when entry and `plugin.json` both set it); `.version-bump.json` lists `package.json` and `plugin.json`. |
| D16 | §4.2 "no warning about the name, the README or the licence" | Still required. Validate will also warn about the root `CLAUDE.md` that §1.4 asks for; that one warning is expected. |
| D17 | §2 step 7 is one row | It lands as Task 6 (`check-import.sh` commit, then the rename-rule commit) and Task 7 (identity files). `.playwright-mcp/` is ignored in its own commit before step 1. The order is the spec's. |
| D18 | §2 steps 5 and 6 | One task (Task 5) with two commits: `git subtree add` writes its commit with `commit-tree`, which runs no hooks, so the add-card-line commit carries the task's trailer. |
| D19 | When the switch-over runs | **After the owner merges** the branch: OpenCode reads `~/hyper-relay/skills` on `main` (§1.3), and Claude Code installs GitHub's default branch. The card will show merged before the live proofs. **Owner: confirm.** |
| D20 | §3.1 background updates | Auto-update is off by default for non-Anthropic marketplaces, and `version` is pinned: an update arrives only after a version bump, and in the background only if the owner turns on auto-update for this marketplace. The README says so. |
| D21 | Not in spec §3.4: this repo's local agents | `.claude/agents/relay-planner.md` (`skills: writing-plans`) and `relay-executor.md` (`skills: executing-plans`, plus `finishing-a-development-branch` in prose) get the same edits as SAT's (Task 9 Step 6). **Owner: confirm** (untracked local files). |
| D22 | §3.4's fallback for planners | `sat-planner` and `relay-planner` have an explicit `tools:` list without `Skill`; the fallback adds `Skill` to it. |
| D23 | Global `CLAUDE.md`'s add-card-line line | The spec's "brainstorming's `scripts/add-card-line.sh`" plus the machine path in the main checkout (`~/hyper-relay/skills/brainstorming/scripts/add-card-line.sh`), stable across plugin versions: Quartz's own errors tell agents to "run add-card-line.sh", and an agent without brainstorming loaded needs a path. |
| D24 | Other loose skills | elenchus-build, elenchus-plan, elenchus-tui, design-recon, finishing-implementation-elenchus, parallel-subagent-execution and producing-course-videos name moved skills by bare name in prose (no paths, no prefixes). Left as they are; Task 9 Step 10 checks that a bare name still resolves after the deletion. **Owner decides** if it does not. |
| D25 | `~/.claude/skills/synced/<id>/{brainstorming,using-superpowers,writing-skills}` | claude.ai-synced old copies of three moved skills. OpenCode may discover them (recursive discovery), but the explicit `skills` entry outranks them; Task 9 Step 7 confirms. In Claude Code, if they load as bare names, a bare `brainstorming` would reach the old copy after the deletion. **Owner decides** (for example, remove them from the claude.ai account). |
| D26 | Memories | Only instruction lines are rewritten (Task 9 Step 6 lists them); dated logs and status notes stay as history. `memory/sat-fake-login-step02-video.md:58` names `~/.claude/skills/brainstorming/scripts/server.cjs`, already stale since the companion split; left. |
| D27 | Draft README `TO VERIFY` | Quartz has no public URL: the link becomes plain text "(not public yet)". OpenCode's `skills` shape is verified (flat array). Also corrected: "run `setup.sh` once" → the first transcription builds the venv. |
| D28 | "The owner as author" | `Alex` with `https://github.com/alexvtejeda` in `plugin.json`, the marketplace `owner` and `LICENSE`. **Owner: change** if a full name or email is wanted. |
| D29 | Tag name | Plain annotated `v0.1.0`, as the spec says. |
| D30 | Home repo | `/home/noob_master/CLAUDE.md` is untracked there, so its edit is a file edit; only the three tracked paths are untracked by commit. |

## File structure

- **Delete (Task 1):** `.codex-plugin/`, `.cursor-plugin/`, `.opencode/`, `GEMINI.md`, `gemini-extension.json`,
  `hooks/`, `scripts/sync-to-codex-plugin.sh`, `tests/codex-plugin-sync/`, `tests/opencode/`,
  `docs/README.opencode.md`, `docs/windows/`. **Modify:** `.gitignore`, `.version-bump.json`, `package.json`.
- **Move (Task 2):** `docs/superpowers/{plans,specs}/<upstream files>` → `docs/upstream/{plans,specs}/`.
- **Mirror (Task 3):** `skills/{brainstorming,writing-plans,using-superpowers,subagent-driven-development,using-git-worktrees,dispatching-parallel-agents}/`.
- **Create (Task 4):** `skills/visual-companion/`. **Delete:** `tests/brainstorm-server/`.
- **Create (Task 5):** `skills/voice-to-specs/` (subtree), `tests/add-card-line/run-tests.sh`.
- **Create (Task 6):** `scripts/check-import.sh`. **Rename:** `skills/using-superpowers` → `skills/using-hyper-relay`.
  **Modify:** 13 skill files, 7 test files.
- **Modify (Task 7):** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `package.json`,
  `.version-bump.json`, `LICENSE`, `CLAUDE.md` (and so `AGENTS.md`). **Move:** `docs/README.draft.md` → `README.md`.
- **Modify (Task 8):** `skills/voice-to-specs/{scripts/setup.sh,scripts/transcribe.sh,CLAUDE.md,tests/transcribe-sh.test.sh}`.

---

### Task 1: Strip Codex, Cursor and Gemini, `hooks/` and the OpenCode V1 plugin (spec §2 step 1)

**Files:**
- Modify: `.gitignore`, `.version-bump.json`, `package.json`
- Delete: `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.opencode/INSTALL.md`,
  `.opencode/plugins/superpowers.js`, `GEMINI.md`, `gemini-extension.json`, `hooks/hooks-cursor.json`,
  `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start`, `scripts/sync-to-codex-plugin.sh`,
  `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh`, `tests/opencode/` (7 files), `docs/README.opencode.md`,
  `docs/windows/polyglot-hooks.md`

- [x] **Step 1: Link the branch.** After creating your branch, run
  `quartz link-branch docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md` in the worktree. If it fails,
  report the failure and carry on.

- [x] **Step 2: Ignore `.playwright-mcp/`.** Append to `.gitignore` (after the last line, `.mcp.json`):

```gitignore

# Playwright MCP output (screenshots, logs) from browser checks.
.playwright-mcp/
```

- [x] **Step 3: Commit it on its own.**

```bash
git add .gitignore
git commit -m "chore: ignore .playwright-mcp/" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 4: Remove the other harnesses, the hooks and the V1 plugin.**

```bash
git rm -r -q .codex-plugin .cursor-plugin .opencode hooks tests/codex-plugin-sync tests/opencode docs/windows
git rm -q GEMINI.md gemini-extension.json scripts/sync-to-codex-plugin.sh docs/README.opencode.md
```

- [x] **Step 5: `.version-bump.json`** loses the three removed manifests. Its whole content becomes:

```json
{
  "files": [
    { "path": "package.json", "field": "version" },
    { "path": ".claude-plugin/plugin.json", "field": "version" },
    { "path": ".claude-plugin/marketplace.json", "field": "plugins.0.version" }
  ],
  "audit": {
    "exclude": [
      "CHANGELOG.md",
      "RELEASE-NOTES.md",
      "node_modules",
      ".git",
      ".version-bump.json",
      "scripts/bump-version.sh"
    ]
  }
}
```

- [x] **Step 6: `package.json`** loses `main`, which named the removed plugin. Its whole content becomes:

```json
{
  "name": "superpowers",
  "version": "5.1.0",
  "type": "module"
}
```

- [x] **Step 7: Check.**

Run: `git add .version-bump.json package.json && git diff --cached --name-status | sort`
Expected: 21 `D` lines (the files listed above) and 2 `M` lines (`.version-bump.json`, `package.json`).

Run: `git grep -n -i -e codex -e cursor -e gemini -e opencode -- . ':!skills' ':!docs' ':!tests' ':!RELEASE-NOTES.md' ':!README.md' ':!CLAUDE.md' ':!.github'`
Expected: no output.

- [x] **Step 8: Commit.**

```bash
git commit -m "chore: strip Codex, Cursor and Gemini support, hooks/ and the OpenCode V1 plugin" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#1
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: Upstream's specs and plans move to `docs/upstream/` (spec §2 step 2)

**Files:**
- Move: `docs/superpowers/plans/{2026-01-22-document-review-system,2026-02-19-visual-brainstorming-refactor,2026-03-11-zero-dep-brainstorm-server,2026-03-23-codex-app-compatibility,2026-04-06-worktree-rototill}.md` → `docs/upstream/plans/`
- Move: `docs/superpowers/specs/{2026-01-22-document-review-system-design,2026-02-19-visual-brainstorming-refactor-design,2026-03-11-zero-dep-brainstorm-server-design,2026-03-23-codex-app-compatibility-design,2026-04-06-worktree-rototill-design}.md` → `docs/upstream/specs/`

hyper-relay's own spec and this plan stay where they are.

- [x] **Step 1: Move the ten files.**

```bash
mkdir -p docs/upstream/plans docs/upstream/specs
git mv docs/superpowers/plans/2026-01-22-document-review-system.md docs/upstream/plans/
git mv docs/superpowers/plans/2026-02-19-visual-brainstorming-refactor.md docs/upstream/plans/
git mv docs/superpowers/plans/2026-03-11-zero-dep-brainstorm-server.md docs/upstream/plans/
git mv docs/superpowers/plans/2026-03-23-codex-app-compatibility.md docs/upstream/plans/
git mv docs/superpowers/plans/2026-04-06-worktree-rototill.md docs/upstream/plans/
git mv docs/superpowers/specs/2026-01-22-document-review-system-design.md docs/upstream/specs/
git mv docs/superpowers/specs/2026-02-19-visual-brainstorming-refactor-design.md docs/upstream/specs/
git mv docs/superpowers/specs/2026-03-11-zero-dep-brainstorm-server-design.md docs/upstream/specs/
git mv docs/superpowers/specs/2026-03-23-codex-app-compatibility-design.md docs/upstream/specs/
git mv docs/superpowers/specs/2026-04-06-worktree-rototill-design.md docs/upstream/specs/
```

- [x] **Step 2: Check.**

Run: `git ls-files docs/superpowers`
Expected exactly:
```
docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md
docs/superpowers/specs/2026-11-17-hyper-relay-a-forks-home-design.md
```
Run: `git ls-files docs/upstream | wc -l` — Expected: `10`.

- [x] **Step 3: Commit.**

```bash
git commit -m "docs: upstream's specs and plans move to docs/upstream/" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#2
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: Import the owner's edits, one commit per skill, before any rename (spec §2 step 3)

**Files:**
- Mirror: `skills/brainstorming/`, `skills/writing-plans/`, `skills/using-superpowers/`,
  `skills/subagent-driven-development/`, `skills/using-git-worktrees/`, `skills/dispatching-parallel-agents/`

Each step makes `skills/<skill>` an exact mirror of `~/.claude/skills/<skill>`: files the owner removed are deleted.
Six commits; the last carries the trailer. If a numstat below differs, STOP and report (Execution notes).

- [x] **Step 1: brainstorming.**

```bash
git rm -r -q skills/brainstorming
mkdir -p skills/brainstorming
tar -C /home/noob_master/.claude/skills/brainstorming --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/brainstorming -xf -
git add skills/brainstorming
git diff --cached --numstat
```
Expected (any order):
```
47	22	skills/brainstorming/SKILL.md
93	0	skills/brainstorming/scripts/add-card-line.sh
0	214	skills/brainstorming/scripts/frame-template.html
0	88	skills/brainstorming/scripts/helper.js
0	354	skills/brainstorming/scripts/server.cjs
0	148	skills/brainstorming/scripts/start-server.sh
0	56	skills/brainstorming/scripts/stop-server.sh
0	287	skills/brainstorming/visual-companion.md
```
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/brainstorming skills/brainstorming` — Expected: no output.
Run: `test -x skills/brainstorming/scripts/add-card-line.sh && echo executable` — Expected: `executable`.

```bash
git commit -m "import: the owner's brainstorming (Quartz steps, add-card-line.sh; the companion server moved to visual-companion)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 2: writing-plans.**

```bash
git rm -r -q skills/writing-plans
mkdir -p skills/writing-plans
tar -C /home/noob_master/.claude/skills/writing-plans --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/writing-plans -xf -
git add skills/writing-plans
git diff --cached --numstat
```
Expected: `18	1	skills/writing-plans/SKILL.md` and nothing else.
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/writing-plans skills/writing-plans` — Expected: no output.

```bash
git commit -m "import: the owner's writing-plans (plan count, branch link, review step, Plan-Task trailers)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 3: using-superpowers** (still under its upstream name).

```bash
git rm -r -q skills/using-superpowers
mkdir -p skills/using-superpowers
tar -C /home/noob_master/.claude/skills/using-superpowers --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/using-superpowers -xf -
git add skills/using-superpowers
git diff --cached --numstat
```
Expected (any order):
```
2	6	skills/using-superpowers/SKILL.md
0	59	skills/using-superpowers/references/codex-tools.md
0	42	skills/using-superpowers/references/copilot-tools.md
0	51	skills/using-superpowers/references/gemini-tools.md
```
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/using-superpowers skills/using-superpowers` — Expected: no output.

```bash
git commit -m "import: the owner's using-superpowers (Claude Code and AGENTS.md only; no Copilot, Gemini or references/)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 4: subagent-driven-development.**

```bash
git rm -r -q skills/subagent-driven-development
mkdir -p skills/subagent-driven-development
tar -C /home/noob_master/.claude/skills/subagent-driven-development --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/subagent-driven-development -xf -
git add skills/subagent-driven-development
git diff --cached --numstat
```
Expected: `1	1	skills/subagent-driven-development/SKILL.md` and nothing else.
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/subagent-driven-development skills/subagent-driven-development` — Expected: no output.

```bash
git commit -m "import: the owner's subagent-driven-development (its description)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 5: using-git-worktrees.**

```bash
git rm -r -q skills/using-git-worktrees
mkdir -p skills/using-git-worktrees
tar -C /home/noob_master/.claude/skills/using-git-worktrees --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/using-git-worktrees -xf -
git add skills/using-git-worktrees
git diff --cached --numstat
```
Expected: `1	1	skills/using-git-worktrees/SKILL.md` and nothing else.
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/using-git-worktrees skills/using-git-worktrees` — Expected: no output.

```bash
git commit -m "import: the owner's using-git-worktrees (its description)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 6: dispatching-parallel-agents** (D1; the stray `.zip` stays out).

```bash
git rm -r -q skills/dispatching-parallel-agents
mkdir -p skills/dispatching-parallel-agents
tar -C /home/noob_master/.claude/skills/dispatching-parallel-agents --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/dispatching-parallel-agents -xf -
git add skills/dispatching-parallel-agents
git diff --cached --numstat
```
Expected: `1	1	skills/dispatching-parallel-agents/SKILL.md` and nothing else.
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/dispatching-parallel-agents skills/dispatching-parallel-agents`
Expected: one line, for `.../dispatching-parallel-agents/.zip` (`Bin 3009 -> 0 bytes`), and `1 file changed`.

- [x] **Step 7: Check the other eight are untouched.** For each of `executing-plans`, `finishing-a-development-branch`,
  `receiving-code-review`, `requesting-code-review`, `systematic-debugging`, `test-driven-development`,
  `verification-before-completion`, `writing-skills`, run
  `git diff --no-index --stat /home/noob_master/.claude/skills/<skill> skills/<skill>` — Expected: no output for every one.

- [x] **Step 8: Commit.**

```bash
git commit -m "import: the owner's dispatching-parallel-agents (its description)" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#3
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: Add visual-companion; drop the brainstorm-server tests it supersedes (spec §2 step 4, §1.4)

**Files:**
- Create: `skills/visual-companion/{SKILL.md,scripts/frame-template.html,scripts/helper.js,scripts/run-tests.sh,scripts/server.cjs,scripts/start-server.sh,scripts/stop-server.sh,scripts/test-injection.cjs,scripts/test-session.cjs}`
- Delete: `tests/brainstorm-server/` (5 files)

- [x] **Step 1: Check the two loose copies still agree.**

Run: `git diff --no-index --stat /home/noob_master/.claude/skills/visual-companion /home/noob_master/.config/opencode/skills/visual-companion`
Expected: no output.

- [x] **Step 2: Add it.**

```bash
mkdir -p skills/visual-companion
tar -C /home/noob_master/.claude/skills/visual-companion --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . | tar -C skills/visual-companion -xf -
git add skills/visual-companion
git diff --cached --name-only | wc -l
```
Expected: `9`.
Run: `git diff --no-index --stat /home/noob_master/.claude/skills/visual-companion skills/visual-companion` — Expected: no output.

- [x] **Step 3: Run its tests.**

Run: `bash skills/visual-companion/scripts/run-tests.sh; echo "exit $?"`
Expected: `== test-injection.cjs` and `== test-session.cjs` headers, `ok` lines (five in test-session), no `FAIL`, `exit 0`.

- [x] **Step 4: Commit the skill.**

```bash
git commit -m "feat: add visual-companion, the owner's browser companion" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 5: Drop `tests/brainstorm-server`** (D9: it tests the WebSocket server Task 3 removed).

```bash
git rm -r -q tests/brainstorm-server
git diff --cached --name-only
```
Expected: the five files `tests/brainstorm-server/{package-lock.json,package.json,server.test.js,windows-lifecycle.test.sh,ws-protocol.test.js}`.

- [x] **Step 6: Commit.**

```bash
git commit -m "test: drop tests/brainstorm-server, superseded by visual-companion's run-tests.sh" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#4
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: voice-to-specs with its history, then the add-card-line tests (spec §2 steps 5 and 6)

**Files:**
- Create: `skills/voice-to-specs/` by `git subtree add` (7 files)
- Create: `tests/add-card-line/run-tests.sh`

- [x] **Step 1: Check the source is clean.**

Run: `git -C /home/noob_master/.claude/skills/voice-to-specs status --short`
Expected: no output (the venv is ignored). Run: `git status --short` in the worktree — Expected: no output (subtree refuses a dirty tree).

- [x] **Step 2: Add it, not squashed.** If `git subtree` refuses (for example in a worktree), STOP and report; never fall
  back to `--squash` or a plain copy, because the history is the point.

```bash
git subtree add --prefix=skills/voice-to-specs /home/noob_master/.claude/skills/voice-to-specs master -m "feat: add voice-to-specs with its history (11 commits since 2026-03-20)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 3: Check the history and the files.**

Run: `git log -1 --format=%P | wc -w` — Expected: `2` (a merge).
Run: `git rev-list --count HEAD^2` — Expected: `11`.
Run: `git log --reverse --format=%ad --date=short HEAD^2 | head -n 1` — Expected: `2026-03-20`.
Run: `git diff --stat HEAD^2^{tree} HEAD:skills/voice-to-specs` — Expected: no output.
Run: `git ls-files skills/voice-to-specs`
Expected:
```
skills/voice-to-specs/CLAUDE.md
skills/voice-to-specs/SKILL.md
skills/voice-to-specs/scripts/.gitignore
skills/voice-to-specs/scripts/setup.sh
skills/voice-to-specs/scripts/transcribe.py
skills/voice-to-specs/scripts/transcribe.sh
skills/voice-to-specs/tests/transcribe-sh.test.sh
```
Run: `sh skills/voice-to-specs/tests/transcribe-sh.test.sh` — Expected: last line `17 passed, 0 failed`.

- [x] **Step 4: Move the add-card-line suite in.** It finds the script as `../../skills/brainstorming/scripts/add-card-line.sh`
  from its own folder, the same layout as in `~/.claude`, so it moves byte for byte.

```bash
mkdir -p tests/add-card-line
cp /home/noob_master/.claude/tests/add-card-line/run-tests.sh tests/add-card-line/run-tests.sh
cmp /home/noob_master/.claude/tests/add-card-line/run-tests.sh tests/add-card-line/run-tests.sh && echo same
```
Expected: `same`.

- [x] **Step 5: Run it.**

Run: `sh tests/add-card-line/run-tests.sh | tail -n 2`
Expected: `<n> passed, 0 failed` (`dash -n passes` and `script is executable` among the passes).

- [x] **Step 6: Commit.**

```bash
git add tests/add-card-line/run-tests.sh
git commit -m "test: the add-card-line suite moves in from the home repo" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#5
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: The check script, then the rename rule (spec §2 step 7, first half; §4.1)

**Files:**
- Create: `scripts/check-import.sh`
- Rename: `skills/using-superpowers/` → `skills/using-hyper-relay/`
- Modify: `skills/{brainstorming/SKILL.md,executing-plans/SKILL.md,finishing-a-development-branch/SKILL.md,subagent-driven-development/SKILL.md,systematic-debugging/SKILL.md,using-hyper-relay/SKILL.md,visual-companion/SKILL.md,visual-companion/scripts/frame-template.html,voice-to-specs/CLAUDE.md,voice-to-specs/SKILL.md,writing-plans/SKILL.md,writing-skills/SKILL.md,writing-skills/testing-skills-with-subagents.md}`
- Modify: `tests/claude-code/{test-requesting-code-review.sh,test-subagent-driven-development-integration.sh}`, `tests/subagent-driven-dev/{run-test.sh,go-fractals/plan.md,go-fractals/scaffold.sh,svelte-todo/plan.md,svelte-todo/scaffold.sh}`

- [x] **Step 1: Write `scripts/check-import.sh`** (the whole file):

```sh
#!/bin/sh
# check-import.sh: piece A's proof that moving the skills into hyper-relay changed no
# behaviour (spec §4.1). For each of the 16 skills it copies the loose copy the skill came
# from, applies the spec §2 rename rule and voice-to-specs' venv move to that copy, and
# compares the result with skills/<skill>, files and executable bits. Any difference fails.
#
# Usage: sh scripts/check-import.sh        Expect: "16 skills match their loose copies"
#   LOOSE_SKILLS_DIR=<dir> compares against <dir> instead of ~/.claude/skills. Once the
#   loose copies are deleted (spec §3.5) there is nothing to compare, and it exits 2.
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOOSE=${LOOSE_SKILLS_DIR:-$HOME/.claude/skills}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
trap 'exit 1' INT TERM
status=0
checked=0

# <skill in skills/> <its loose copy>
SKILLS='brainstorming brainstorming
dispatching-parallel-agents dispatching-parallel-agents
executing-plans executing-plans
finishing-a-development-branch finishing-a-development-branch
receiving-code-review receiving-code-review
requesting-code-review requesting-code-review
subagent-driven-development subagent-driven-development
systematic-debugging systematic-debugging
test-driven-development test-driven-development
using-git-worktrees using-git-worktrees
using-hyper-relay using-superpowers
verification-before-completion verification-before-completion
visual-companion visual-companion
voice-to-specs voice-to-specs
writing-plans writing-plans
writing-skills writing-skills'

fail() {
    echo "check-import: $*" >&2
    status=1
}

# edit <file> <old line> <new text>: replace the one line of <file> that equals <old line>.
# awk reads both strings from the environment, so nothing in them is interpreted.
edit() {
    n=$(OLD=$2 awk '$0 == ENVIRON["OLD"] { n++ } END { print n + 0 }' "$1")
    if [ "$n" != 1 ]; then
        fail "${1#"$TMP"/}: expected exactly one line to replace, found $n: $2"
        return 0
    fi
    OLD=$2 NEW=$3 awk '$0 == ENVIRON["OLD"] { print ENVIRON["NEW"]; next } { print }' "$1" >"$TMP/edit.out"
    cat "$TMP/edit.out" >"$1"
}

# The rename rule's mechanical part, on every file under $1: the skill prefix,
# using-superpowers' new name, and prose naming the plugin. `docs/superpowers/`,
# `.superpowers/` and `~/.config/superpowers/` contain none of these strings, so they stay.
rename_rule() {
    find "$1" -type f -exec sed -i -e 's/superpowers:/hyper-relay:/g' \
        -e 's/using-superpowers/using-hyper-relay/g' -e 's/Superpowers/hyper-relay/g' {} +
}

# The rename rule's named lines: an absolute path to a skill's own files becomes
# ${CLAUDE_SKILL_DIR}, and the line also names the file relative to SKILL.md for OpenCode.
path_lines() { # <skill> <dir>
    case $1 in
    brainstorming)
        edit "$2/SKILL.md" \
            '- When the work has a Quartz card, run `~/.claude/skills/brainstorming/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.' \
            '- When the work has a Quartz card, run `${CLAUDE_SKILL_DIR}/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` (`scripts/add-card-line.sh` beside this SKILL.md) straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.'
        ;;
    visual-companion)
        edit "$2/SKILL.md" \
            'skill'\''s directory:' \
            'skill'\''s directory (the script is `scripts/start-server.sh` beside this SKILL.md):'
        edit "$2/SKILL.md" \
            '~/.claude/skills/visual-companion/scripts/start-server.sh \' \
            '${CLAUDE_SKILL_DIR}/scripts/start-server.sh \'
        ;;
    voice-to-specs)
        edit "$2/SKILL.md" \
            'Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that.' \
            'Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that. The script is `scripts/transcribe.sh` beside this SKILL.md.'
        edit "$2/SKILL.md" \
            'sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base' \
            'sh ${CLAUDE_SKILL_DIR}/scripts/transcribe.sh <file_path> --model base'
        edit "$2/CLAUDE.md" \
            'sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base' \
            'sh scripts/transcribe.sh <file_path> --model base'
        edit "$2/CLAUDE.md" \
            '**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code loads at runtime, so an edit here is live at once, on any branch.' \
            '**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code and OpenCode load at runtime: an edit reaches Claude Code when the hyper-relay plugin updates, and OpenCode when it merges to the main checkout.'
        edit "$2/CLAUDE.md" \
            '`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses the script at `.claude/skills/voice-to-specs/scripts/transcribe.py`. Don'\''t conflate the two when editing.' \
            '`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses `scripts/transcribe.py` in this folder. Don'\''t conflate the two when editing.'
        edit "$2/CLAUDE.md" \
            '- Markdown briefs always land in the **caller'\''s** working directory, never inside this repo. Don'\''t write transcription outputs into `.claude/skills/voice-to-specs/`.' \
            '- Markdown briefs always land in the **caller'\''s** working directory, never inside this repo. Don'\''t write transcription outputs into this skill'\''s folder.'
        ;;
    esac
}

# voice-to-specs' venv moves out of the skill (spec §2): setup.sh and transcribe.sh read
# ${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv, and the docs and test follow.
venv_lines() { # <dir>
    for f in scripts/setup.sh scripts/transcribe.sh; do
        edit "$1/$f" 'VENV_DIR="$SCRIPT_DIR/venv"' \
            'VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyper-relay/voice-to-specs/venv"'
    done
    edit "$1/CLAUDE.md" \
        'Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `scripts/venv/` with the `openai-whisper` package installed.' \
        'Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv` with the `openai-whisper` package installed, outside the plugin, so that a plugin update does not delete it.'
    edit "$1/CLAUDE.md" \
        '- Python venvs under `scripts/venv/` and `whisperVenv/` are gitignored by convention — do not commit them.' \
        '- The venv lives outside the repo (see Setup). `scripts/.gitignore` still ignores a stray `scripts/venv/`, and `whisperVenv/` is gitignored by convention — do not commit either.'
    t=$1/tests/transcribe-sh.test.sh
    edit "$t" \
        '# real venv, whisper or ffmpeg, and never touches the real scripts/venv.' \
        '# real venv, whisper or ffmpeg, and never touches the real venv: XDG_DATA_HOME points into the sandbox.'
    edit "$t" '    export BOX DIR' \
        '    XDG_DATA_HOME="$BOX/data"
    VENV="$XDG_DATA_HOME/hyper-relay/voice-to-specs/venv"
    export BOX DIR XDG_DATA_HOME VENV'
    sed -i 's|\$DIR/venv|$VENV|g' "$t"
    edit "$t" \
        '    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"' \
        '    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"

# No XDG_DATA_HOME: the venv is under $HOME/.local/share.
new_box
unset XDG_DATA_HOME
HOME="$BOX/home"
VENV="$HOME/.local/share/hyper-relay/voice-to-specs/venv"
export HOME VENV
make_venv
run x.m4a
check "no XDG_DATA_HOME: the venv under HOME/.local/share is used" "$PY [x.m4a]" "$CALLS"'
}

if [ ! -d "$LOOSE" ]; then
    echo "check-import: no loose copies at $LOOSE (deleted after spec §3.5?), nothing to compare" >&2
    exit 2
fi

# Every folder in skills/ must be one of the 16.
for d in "$ROOT"/skills/*/; do
    name=${d%/}
    name=${name##*/}
    case "
$SKILLS
" in
    *"
$name "*) ;;
    *) fail "skills/$name was not imported from a loose copy" ;;
    esac
done

while read -r name src; do
    if [ ! -d "$LOOSE/$src" ]; then
        fail "$LOOSE/$src is missing"
        continue
    fi
    if [ ! -d "$ROOT/skills/$name" ]; then
        fail "skills/$name is missing"
        continue
    fi
    work=$TMP/$name
    mkdir -p "$work"
    # The mirror's exclusions: voice-to-specs' own .git and venv, and a stray .zip.
    tar -C "$LOOSE/$src" --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . |
        tar -C "$work" -xf -
    rename_rule "$work"
    path_lines "$name" "$work"
    if [ "$name" = voice-to-specs ]; then
        venv_lines "$work"
    fi
    if ! diff -r "$work" "$ROOT/skills/$name"; then
        fail "skills/$name differs from $LOOSE/$src after the rename rule and the venv move (diff above)"
    fi
    a=$(cd "$work" && find . -type f -perm -u+x | sort)
    b=$(cd "$ROOT/skills/$name" && find . -type f -perm -u+x | sort)
    if [ "$a" != "$b" ]; then
        fail "skills/$name: executable files differ from $LOOSE/$src"
    fi
    checked=$((checked + 1))
done <<EOF
$SKILLS
EOF

if [ "$status" -eq 0 ]; then
    echo "$checked skills match their loose copies"
fi
exit "$status"
```

- [x] **Step 2: Syntax-check and make it executable.**

Run: `dash -n scripts/check-import.sh && chmod +x scripts/check-import.sh && echo ok` — Expected: `ok`.

- [x] **Step 3: Run it before the rename (red).**

Run: `sh scripts/check-import.sh; echo "exit $?"`
Expected: `exit 1`, with `check-import:` lines for `skills/using-superpowers was not imported from a loose copy`,
`skills/using-hyper-relay is missing`, and differs-lines (diffs above them) for `brainstorming`, `executing-plans`,
`finishing-a-development-branch`, `subagent-driven-development`, `systematic-debugging`, `visual-companion`,
`voice-to-specs`, `writing-plans` and `writing-skills`. No line for the other six. No `match` line.

- [x] **Step 4: Commit the check.**

```bash
git add scripts/check-import.sh
git commit -m "test: check-import.sh, piece A's proof that the move changed nothing" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 5: The rename rule's mechanical part**, on `skills/` and the kept tests' skill names (D10):

```bash
git mv skills/using-superpowers skills/using-hyper-relay
find skills -type f -exec sed -i -e 's/superpowers:/hyper-relay:/g' -e 's/using-superpowers/using-hyper-relay/g' -e 's/Superpowers/hyper-relay/g' {} +
sed -i 's/superpowers:/hyper-relay:/g' tests/claude-code/test-requesting-code-review.sh tests/claude-code/test-subagent-driven-development-integration.sh tests/subagent-driven-dev/run-test.sh tests/subagent-driven-dev/go-fractals/plan.md tests/subagent-driven-dev/go-fractals/scaffold.sh tests/subagent-driven-dev/svelte-todo/plan.md tests/subagent-driven-dev/svelte-todo/scaffold.sh
```

- [x] **Step 6: The named lines** (D11, D12). Make each replacement with the Edit tool, exactly.

`skills/brainstorming/SKILL.md`, replace:
```text
- When the work has a Quartz card, run `~/.claude/skills/brainstorming/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.
```
with:
```text
- When the work has a Quartz card, run `${CLAUDE_SKILL_DIR}/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` (`scripts/add-card-line.sh` beside this SKILL.md) straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.
```

`skills/visual-companion/SKILL.md`, replace the line `skill's directory:` with:
```text
skill's directory (the script is `scripts/start-server.sh` beside this SKILL.md):
```
and replace the line `~/.claude/skills/visual-companion/scripts/start-server.sh \` with:
```text
${CLAUDE_SKILL_DIR}/scripts/start-server.sh \
```

`skills/voice-to-specs/SKILL.md`, replace:
```text
Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that.
```
with:
```text
Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that. The script is `scripts/transcribe.sh` beside this SKILL.md.
```
and replace `sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base` with:
```text
sh ${CLAUDE_SKILL_DIR}/scripts/transcribe.sh <file_path> --model base
```

`skills/voice-to-specs/CLAUDE.md`, replace `sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base` with:
```text
sh scripts/transcribe.sh <file_path> --model base
```
replace:
```text
**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code loads at runtime, so an edit here is live at once, on any branch.
```
with:
```text
**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code and OpenCode load at runtime: an edit reaches Claude Code when the hyper-relay plugin updates, and OpenCode when it merges to the main checkout.
```
replace:
```text
`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses the script at `.claude/skills/voice-to-specs/scripts/transcribe.py`. Don't conflate the two when editing.
```
with:
```text
`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses `scripts/transcribe.py` in this folder. Don't conflate the two when editing.
```
and replace:
```text
- Markdown briefs always land in the **caller's** working directory, never inside this repo. Don't write transcription outputs into `.claude/skills/voice-to-specs/`.
```
with:
```text
- Markdown briefs always land in the **caller's** working directory, never inside this repo. Don't write transcription outputs into this skill's folder.
```

- [x] **Step 7: Check the diff.**

Run: `git add skills tests/claude-code tests/subagent-driven-dev && git diff --cached -M --numstat`
Expected (any order; the `using-hyper-relay` line shows as a rename):
```
1	1	skills/brainstorming/SKILL.md
5	5	skills/executing-plans/SKILL.md
1	1	skills/finishing-a-development-branch/SKILL.md
8	8	skills/subagent-driven-development/SKILL.md
3	3	skills/systematic-debugging/SKILL.md
3	3	skills/{using-superpowers => using-hyper-relay}/SKILL.md
2	2	skills/visual-companion/SKILL.md
1	1	skills/visual-companion/scripts/frame-template.html
4	4	skills/voice-to-specs/CLAUDE.md
2	2	skills/voice-to-specs/SKILL.md
4	4	skills/writing-plans/SKILL.md
4	4	skills/writing-skills/SKILL.md
1	1	skills/writing-skills/testing-skills-with-subagents.md
2	2	tests/claude-code/test-requesting-code-review.sh
1	1	tests/claude-code/test-subagent-driven-development-integration.sh
1	1	tests/subagent-driven-dev/go-fractals/plan.md
1	1	tests/subagent-driven-dev/go-fractals/scaffold.sh
1	1	tests/subagent-driven-dev/run-test.sh
1	1	tests/subagent-driven-dev/svelte-todo/plan.md
1	1	tests/subagent-driven-dev/svelte-todo/scaffold.sh
```

- [x] **Step 8: Run the check after the rename.**

Run: `sh scripts/check-import.sh; echo "exit $?"`
Expected: `exit 1` with exactly one `check-import:` line, for `skills/voice-to-specs`, and the diff above it touches
only the venv lines Task 8 changes: `scripts/setup.sh` and `scripts/transcribe.sh` (`VENV_DIR`), `CLAUDE.md` (the
Setup paragraph and the venv bullet) and `tests/transcribe-sh.test.sh`. Anything else is a transcription error in Step 6:
fix it and re-run.

Run: `sh tests/add-card-line/run-tests.sh | tail -n 1` — Expected: `... 0 failed`.

- [x] **Step 9: Commit.**

```bash
git commit -m "feat: rename to hyper-relay in skills and tests (skill prefix, using-hyper-relay, own paths via CLAUDE_SKILL_DIR)" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#6
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 7: The plugin's identity: manifests, LICENSE, README, CLAUDE.md (spec §2 step 7, second half; §1.1, §1.4)

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `package.json`, `.version-bump.json`,
  `LICENSE`, `CLAUDE.md` (`AGENTS.md` is a symlink to it and stays one)
- Move: `docs/README.draft.md` → `README.md` (replacing upstream's)

- [x] **Step 1: `.claude-plugin/plugin.json`**, the whole file:

```json
{
  "name": "hyper-relay",
  "description": "Workflow skills for Claude Code and OpenCode: brainstorm, spec, plan, execute, review and merge, each leg handing a written artefact to the next. Forked from superpowers v5.1.0.",
  "version": "0.1.0",
  "author": {
    "name": "Alex",
    "url": "https://github.com/alexvtejeda"
  },
  "homepage": "https://github.com/alexvtejeda/hyper-relay",
  "repository": "https://github.com/alexvtejeda/hyper-relay",
  "license": "MIT",
  "keywords": [
    "skills",
    "workflow",
    "planning",
    "tdd",
    "debugging",
    "quartz"
  ]
}
```

- [x] **Step 2: `.claude-plugin/marketplace.json`**, the whole file (no entry `version`, D15):

```json
{
  "name": "hyper-relay",
  "description": "hyper-relay's own marketplace: the one hyper-relay plugin, installed from this repo.",
  "owner": {
    "name": "Alex",
    "url": "https://github.com/alexvtejeda"
  },
  "plugins": [
    {
      "name": "hyper-relay",
      "description": "Workflow skills for Claude Code and OpenCode: brainstorm, spec, plan, execute, review and merge, each leg handing a written artefact to the next. Forked from superpowers v5.1.0.",
      "source": "./",
      "author": {
        "name": "Alex",
        "url": "https://github.com/alexvtejeda"
      }
    }
  ]
}
```

- [x] **Step 3: `package.json`**, the whole file (D14):

```json
{
  "name": "hyper-relay",
  "version": "0.1.0"
}
```

- [x] **Step 4: `.version-bump.json`**, the whole file:

```json
{
  "files": [
    { "path": "package.json", "field": "version" },
    { "path": ".claude-plugin/plugin.json", "field": "version" }
  ],
  "audit": {
    "exclude": [
      "CHANGELOG.md",
      "RELEASE-NOTES.md",
      "node_modules",
      ".git",
      ".version-bump.json",
      "scripts/bump-version.sh"
    ]
  }
}
```

- [x] **Step 5: `LICENSE`**: obra's line stays, the owner's is added below it. Replace line 3
  `Copyright (c) 2025 Jesse Vincent` with these two lines; the rest of the file is unchanged:

```text
Copyright (c) 2025 Jesse Vincent
Copyright (c) 2026 Alex (https://github.com/alexvtejeda)
```

- [x] **Step 6: `README.md`** from the draft:

Run: `git mv -f docs/README.draft.md README.md`

Then write `README.md` as exactly this (the draft with its header comment removed and its `TO VERIFY` notes settled, D27):

````markdown
# hyper-relay

<p align="center">
  <img src="assets/hyper-relay.jpg" width="500" alt="Two robots sprint down a floodlit stadium track; the white one hands a glowing baton to the red-and-black one under a HYPER-RELAY banner.">
</p>

**A relay for coding agents: one idea, handed cleanly from brainstorm to merge.**

hyper-relay is a set of skills for [Claude Code](https://code.claude.com) and [OpenCode](https://opencode.ai) that
turns "build me X" into a disciplined pipeline. It covers brainstorming, a written spec, an implementation plan,
execution in isolation, a review by clicking through the running app, and a merge you decide on. Each stage hands a
written artefact to the next, the way a relay team hands over the baton. Nothing is carried in anyone's head, and the
last leg is always yours.

It is a hard fork of [obra/superpowers](https://github.com/obra/superpowers) (v5.1.0), reshaped around one way of
working: an orchestrating session that you talk to, role agents that do the legwork, and a board that knows where
everything stands.

> **Status: 0.1.0.** This release moves the skills into a versioned plugin with **no behaviour change**. Later releases
> add the role agents, per-repo configuration and the orchestrator (see [Roadmap](#roadmap)).

## The relay

```
 voice-to-specs ─▶ brainstorming ─▶ spec ─▶ writing-plans ─▶ execute ─▶ review ─▶ you ─▶ merge
   (optional)        (you + the        (committed)   (one plan per    (isolated)  (clicks,   (anchor
                      orchestrator)                    subsystem)                  not tests)   leg)
```

| Leg | Skill | Hands over |
|---|---|---|
| Capture | `voice-to-specs` | Briefs or board cards from a recording. It stops there and never writes specs, plans or code. |
| Design | `brainstorming` (+ `visual-companion` for mockups) | An approved design, written as a spec in `docs/superpowers/specs/` |
| Plan | `writing-plans` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with full code, tests and a binding contract between plans |
| Execute | `executing-plans`, `subagent-driven-development`, `using-git-worktrees`, `test-driven-development` | Commits, one per task, in their own worktree |
| Review | `verification-before-completion`, `requesting-code-review`, `receiving-code-review` | Evidence that it works: tests, then a click-through of the running app |
| Finish | `finishing-a-development-branch` | A merge, on your call |

Also in the box: `systematic-debugging` (root cause before any fix), `dispatching-parallel-agents`, `writing-skills`
and `using-hyper-relay` (how to find and use the skills).

### The rules of the relay

- **A gate between every leg.** Each phase ends with your approval, and the next one never starts in the same breath.
- **Hand-offs are files, not memory.** A spec, a plan, a commit or a report. If it isn't written down, it wasn't handed
  over.
- **Acceptance is by clicking.** A green test suite is necessary, not sufficient.
- **Root causes only.** No band-aids, and no "it passes when run alone".

## Quartz: the board

hyper-relay is designed to run alongside Quartz, a project board built for exactly this pipeline (not public yet).

With Quartz connected:

- **Every spec and plan names its card(s)** in its header (`**Card:**` / `**Cards:**`), and committing the file uploads
  it to them.
- **Plan tasks tick themselves.** The commit that finishes a task carries a `Plan-Task: <plan>#<n>` trailer, and a git
  hook ticks that task on the board.
- **Cards move with the work:** brainstorming, In progress (`quartz link-branch`), In review (`quartz review`), and
  merged (a git hook).

Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown, and the skills work on their own. But
the board is half the point: it is what lets a long-running, multi-agent pipeline stay legible.

## Install

### Claude Code

```text
/plugin marketplace add alexvtejeda/hyper-relay
/plugin install hyper-relay@hyper-relay
```

Skills appear as `hyper-relay:<skill>`, for example `hyper-relay:brainstorming`.

- **The repo is private,** so Claude Code clones it with your own git credentials. For background updates to work too,
  give git a credential helper: `gh auth login`, then `gh auth setup-git`.
- **Updates follow the version.** `plugin.json` pins it, so an installed copy changes only when a release raises it.
  Claude Code checks a marketplace that is not Anthropic's in the background only if you turn on auto-update for it
  (`/plugin`, then **Marketplaces**); otherwise run `claude plugin update hyper-relay@hyper-relay`.
- **Install from GitHub, not from a local clone.** A local-directory marketplace loads files in place, gitignored ones
  included, so a developer's local `.mcp.json` would load as the plugin's own MCP servers.

### OpenCode

Clone the repo, then point OpenCode's `skills` setting at its `skills/` folder in `~/.config/opencode/opencode.json`:

```json
{
  "skills": ["/path/to/hyper-relay/skills"]
}
```

Use an absolute path: OpenCode resolves a relative one from its working directory. Skills from an explicit `skills`
entry take precedence over same-named skills OpenCode finds elsewhere (it also reads `~/.claude/skills/`). Update with
`git pull` on the clone's `main`.

### voice-to-specs

It needs Python 3.10+ and ffmpeg. The first transcription runs its `scripts/setup.sh`, which builds a Python venv with
whisper under `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/`, outside the plugin, so updates never
delete it.

## Roadmap

| Piece | What | Status |
|---|---|---|
| A | **The fork's home:** the skills as a versioned plugin for Claude Code and OpenCode, with no behaviour change | 0.1.0 |
| B | **Per-repo config and generic role agents:** a planner, an executor and a reviewer that read one small config file per repo (how to start a test stack, how to merge, which checks to run, which model each role uses) | planned |
| C | **Our own executing-plans:** executes in the worktree it is given (or on a branch, per repo), commits per task with `Plan-Task` trailers, runs the full checks once, and stops before merging | planned |
| D | **The orchestrator:** dispatches the legs, verifies every hand-back, stacks dependent plans, checks for migration and shared-file conflicts, and hands you the stack to click through | planned |

## Credits

hyper-relay stands on [superpowers](https://github.com/obra/superpowers) by Jesse Vincent and contributors. Most of
its skills began there, and its design philosophy (skills as tested, composable process) is theirs. obra's repo stays
this one's `upstream`, and fixes from it are ported by hand.

## License

MIT. See [LICENSE](LICENSE), which keeps the original superpowers copyright notice.
````

- [x] **Step 7: `CLAUDE.md`**, the whole file (it replaces upstream's contributor guidelines; `AGENTS.md` links to it):

````markdown
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
````

- [x] **Step 8: Validate.**

Run: `claude plugin validate .`
Expected: `Validation passed` or `Validation passed with warnings`, where the only warning is about `CLAUDE.md` at the
plugin root (D16). No error; no warning about the name, the README, the licence, `version` or an unknown field; no
README `Advice` block. A warning about a skill's frontmatter: report it, do not edit the skill (no behaviour change).

Run: `test -L AGENTS.md && readlink AGENTS.md` — Expected: `CLAUDE.md`.

- [x] **Step 9: Commit.**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json package.json .version-bump.json LICENSE README.md CLAUDE.md
git status --short
```
Expected: the seven files staged (README.md may show as `R docs/README.draft.md -> README.md`), nothing unstaged.

```bash
git commit -m "feat: hyper-relay 0.1.0: plugin and marketplace manifests, LICENSE, README, CLAUDE.md" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#7
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 8: voice-to-specs' venv moves out of the skill; the headless proofs (spec §2 step 8; §4.1–4.3)

**Files:**
- Modify: `skills/voice-to-specs/tests/transcribe-sh.test.sh`, `skills/voice-to-specs/scripts/transcribe.sh`,
  `skills/voice-to-specs/scripts/setup.sh`, `skills/voice-to-specs/CLAUDE.md`

- [ ] **Step 1: The test first.** In `skills/voice-to-specs/tests/transcribe-sh.test.sh`:

Run: `sed -i 's|\$DIR/venv|$VENV|g' skills/voice-to-specs/tests/transcribe-sh.test.sh`
(9 uses, in the `make-venv.sh` heredoc and in the "no whisper" and "dangling python" cases.)

Then, with the Edit tool, replace line 4:
```text
# real venv, whisper or ffmpeg, and never touches the real scripts/venv.
```
with:
```text
# real venv, whisper or ffmpeg, and never touches the real venv: XDG_DATA_HOME points into the sandbox.
```
replace the line `    export BOX DIR` (inside `new_box`) with:
```sh
    XDG_DATA_HOME="$BOX/data"
    VENV="$XDG_DATA_HOME/hyper-relay/voice-to-specs/venv"
    export BOX DIR XDG_DATA_HOME VENV
```
and replace the last `check` argument line:
```text
    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"
```
with:
```sh
    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"

# No XDG_DATA_HOME: the venv is under $HOME/.local/share.
new_box
unset XDG_DATA_HOME
HOME="$BOX/home"
VENV="$HOME/.local/share/hyper-relay/voice-to-specs/venv"
export HOME VENV
make_venv
run x.m4a
check "no XDG_DATA_HOME: the venv under HOME/.local/share is used" "$PY [x.m4a]" "$CALLS"
```

- [ ] **Step 2: Run it (red).**

Run: `dash -n skills/voice-to-specs/tests/transcribe-sh.test.sh && sh skills/voice-to-specs/tests/transcribe-sh.test.sh | tail -n 4`
Expected: `FAIL:` lines (for example "healthy: only transcribe.py runs, once, with its arguments": setup runs, because
`transcribe.sh` still looks beside itself) and a last line with a non-zero `failed` count.

- [ ] **Step 3: The venv path.** In BOTH `skills/voice-to-specs/scripts/transcribe.sh` (line 9) and
  `skills/voice-to-specs/scripts/setup.sh` (line 7), replace:

```sh
VENV_DIR="$SCRIPT_DIR/venv"
```
with:
```sh
VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyper-relay/voice-to-specs/venv"
```
(`python3 -m venv` creates the missing parent folders; nothing else changes in either script.)

- [ ] **Step 4: Run it (green).**

Run: `dash -n skills/voice-to-specs/scripts/transcribe.sh && bash -n skills/voice-to-specs/scripts/setup.sh && sh skills/voice-to-specs/tests/transcribe-sh.test.sh | tail -n 1`
Expected: `18 passed, 0 failed`.

- [ ] **Step 5: The docs follow.** In `skills/voice-to-specs/CLAUDE.md`, replace:

```text
Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `scripts/venv/` with the `openai-whisper` package installed.
```
with:
```text
Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv` with the `openai-whisper` package installed, outside the plugin, so that a plugin update does not delete it.
```
and replace:
```text
- Python venvs under `scripts/venv/` and `whisperVenv/` are gitignored by convention — do not commit them.
```
with:
```text
- The venv lives outside the repo (see Setup). `scripts/.gitignore` still ignores a stray `scripts/venv/`, and `whisperVenv/` is gitignored by convention — do not commit either.
```

- [ ] **Step 6: The proof (§4.1).**

Run: `sh scripts/check-import.sh; echo "exit $?"`
Expected: `16 skills match their loose copies` and `exit 0`.

- [ ] **Step 7: The full gates, once (§4.2, §4.3).**

| Run | Expected |
|---|---|
| `claude plugin validate .` | as Task 7 Step 8: passes; the only warning is the root `CLAUDE.md` |
| `sh tests/add-card-line/run-tests.sh \| tail -n 1` | `... 0 failed` |
| `sh skills/voice-to-specs/tests/transcribe-sh.test.sh \| tail -n 1` | `18 passed, 0 failed` |
| `bash skills/visual-companion/scripts/run-tests.sh; echo "exit $?"` | no `FAIL`, `exit 0` |
| `dash -n scripts/check-import.sh skills/brainstorming/scripts/add-card-line.sh tests/add-card-line/run-tests.sh` (one file per call) | silent |
| `bash -n scripts/bump-version.sh` and `bash -n` on `skills/visual-companion/scripts/{run-tests.sh,start-server.sh,stop-server.sh}` | silent |
| `scripts/bump-version.sh --check` (needs `jq`) | `All declared files are in sync at 0.1.0` |
| `git grep -n -i superpowers -- skills \| grep -v -e 'docs/superpowers/' -e '\.superpowers' -e '\.config/superpowers/'` | no output (what remains is the 10 + 7 `docs/superpowers/` paths, `.superpowers/` folders and `~/.config/superpowers/`; 33 lines in all) |
| `git grep -n '\.claude/skills' -- skills ':!skills/writing-skills'` | no output (writing-skills' 15 general mentions stay, per the rule) |
| `git ls-files skills \| cut -d/ -f2 \| sort -u \| wc -l` | `16` |

Upstream's live suites are NOT run here (report this): `tests/claude-code`, `tests/explicit-skill-requests`,
`tests/skill-triggering` and `tests/subagent-driven-dev` each start real `claude -p` sessions (`--plugin-dir`), which
spend the owner's usage and which the executor may not start. The owner may run them later from a worktree.

- [ ] **Step 8: Commit.**

```bash
git add skills/voice-to-specs/tests/transcribe-sh.test.sh skills/voice-to-specs/scripts/transcribe.sh skills/voice-to-specs/scripts/setup.sh skills/voice-to-specs/CLAUDE.md
git commit -m "feat: voice-to-specs' venv moves to XDG_DATA_HOME, so plugin updates keep it" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#8
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 9: In review.** Run `quartz review` in the worktree. If it fails, report the failure and carry on. Then
  report (gate results with counts, every deviation, the suites not run and why) and stop: Task 9 is not yours.

### Task 9: Switch-over (spec §3, §4.4–4.6). The orchestrator runs it with the owner; NOT the executor

**Precondition:** the orchestrator has verified Task 8's report, and **the owner has merged**
`hyper-relay-a-forks-home` into `main` (D19). No planner or executor is running anywhere. Everything here happens in
the main checkout `/home/noob_master/hyper-relay` or outside the repo.

**Files (outside the repo):** `~/.config/opencode/opencode.json`, `~/.claude/CLAUDE.md`,
`~/sat.pentraze.com/.claude/agents/{sat-planner,sat-executor}.md`,
`/home/noob_master/hyper-relay/.claude/agents/{relay-planner,relay-executor}.md`, the memories in Step 6,
`/home/noob_master/CLAUDE.md`, the home repo's index. In the repo: this plan (Step 11).

- [ ] **Step 1: Re-check on main.** `sh /home/noob_master/hyper-relay/scripts/check-import.sh` → `16 skills match
  their loose copies`. `git -C /home/noob_master/hyper-relay status --short` → nothing but ignored local files.

- [ ] **Step 2: GitHub (§3.1).**

```bash
gh repo create alexvtejeda/hyper-relay --private --description "Workflow skills for Claude Code and OpenCode, forked from superpowers v5.1.0"
git -C /home/noob_master/hyper-relay remote add origin https://github.com/alexvtejeda/hyper-relay.git
git -C /home/noob_master/hyper-relay push -u origin main
git -C /home/noob_master/hyper-relay tag -a v0.1.0 -m "hyper-relay 0.1.0: the fork's home"
git -C /home/noob_master/hyper-relay push origin v0.1.0
gh repo view alexvtejeda/hyper-relay --json visibility,defaultBranchRef
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/alexvtejeda/hyper-relay.git HEAD
```
Expected: `"visibility":"PRIVATE"`, default branch `main`; `ls-remote` prints a SHA without prompting (the credential
helper works non-interactively). Push only `main` and `v0.1.0`, not upstream's tags.

- [ ] **Step 3: Claude Code (§3.2).** In a shell (or in a session: `/plugin marketplace add alexvtejeda/hyper-relay`,
  `/plugin install hyper-relay@hyper-relay`):

```bash
claude plugin marketplace add alexvtejeda/hyper-relay
claude plugin install hyper-relay@hyper-relay
claude plugin list --json
ls -a /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/
test -x /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/brainstorming/scripts/add-card-line.sh && echo executable
```
Expected: `hyper-relay@hyper-relay`, version `0.1.0`, enabled; the cache folder has no `.mcp.json`, `.env`, `.envrc`,
`.claude/` or `.worktrees/`; `executable`. (Auto-update stays off unless the owner turns it on, D20.)

- [ ] **Step 4: OpenCode (§3.3).** `~/.config/opencode/opencode.json` becomes exactly:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": [
    "/home/noob_master/hyper-relay/skills"
  ],
  "mcp": {
    "servers": {
      "codebase-memory-mcp": {
        "type": "local",
        "command": [
          "/home/noob_master/.local/bin/codebase-memory-mcp"
        ]
      },
      "playwright": {
        "type": "local",
        "command": [
          "npx",
          "@playwright/mcp@latest"
        ]
      }
    }
  }
}
```

- [ ] **Step 5: Does a `skills:` list take a plugin-prefixed name? (§3.4)** Write the temporary probe
  `/home/noob_master/.claude/agents/hr-probe.md`:

```markdown
---
name: hr-probe
description: Temporary probe for the hyper-relay switch-over; delete after use. Reports which skills were preloaded into it.
tools: Read
skills:
  - hyper-relay:writing-plans
---

Reply with only the first line that starts with "# " of each skill preloaded into your context, one per line. If no
skill was preloaded, reply with the single word NONE. Do nothing else.
```

Run from `/tmp`: `claude --debug -p "Use the Agent tool to run the hr-probe agent with the prompt 'go', then print its reply verbatim and nothing else."`
Then read the newest file in `~/.claude/debug/` for lines naming `hyper-relay:writing-plans` or `hr-probe`.
- **Option A works** if the reply is `# Writing Plans` and the log has no skip warning for it.
- **Option B is needed** if the reply is `NONE` or the log says the skill was missing or skipped.

Delete `/home/noob_master/.claude/agents/hr-probe.md`. Record the outcome (Step 11).

- [ ] **Step 6: Point everything at the new names (§3.4).**

**6a. `~/.claude/CLAUDE.md`.** Prefix the seven backticked skill names:

```bash
sed -i -E 's/`(brainstorming|writing-plans|executing-plans|subagent-driven-development|finishing-a-development-branch|dispatching-parallel-agents|using-git-worktrees)`/`hyper-relay:\1`/g' /home/noob_master/.claude/CLAUDE.md
```
That changes 15 names on lines 11, 12, 13, 33, 34, 40 (two), 41, 42, 44, 51, 55, 92 and 100, and nothing else (check
with `git diff --no-index` against a copy taken first). Then replace lines 63–65:
```text
  its HEADER (above the first `---` or `## `). Write the line with
  `~/.claude/skills/brainstorming/scripts/add-card-line.sh <doc> <card-id>...` (it calls
  `quartz card-line`). Its shape is ``**Card:** <title> (`<uuid>`)``, or `**Cards:**` with several,
```
with (D23):
```text
  its HEADER (above the first `---` or `## `). Write the line with brainstorming's
  `scripts/add-card-line.sh <doc> <card-id>...` (on this machine
  `~/hyper-relay/skills/brainstorming/scripts/add-card-line.sh`; it calls
  `quartz card-line`). Its shape is ``**Card:** <title> (`<uuid>`)``, or `**Cards:**` with several,
```

**6b. SAT's agents, option A** (a prefixed name preloads):
- `~/sat.pentraze.com/.claude/agents/sat-planner.md` line 12 `  - writing-plans` → `  - hyper-relay:writing-plans`;
  line 24 `preloaded \`writing-plans\` skill.` → `preloaded \`hyper-relay:writing-plans\` skill.` (rest of the line unchanged).
- `~/sat.pentraze.com/.claude/agents/sat-executor.md` line 5 `  with the executing-plans skill.` →
  `  with the hyper-relay:executing-plans skill.`; line 11 `  - executing-plans` → `  - hyper-relay:executing-plans`;
  line 16 `` the preloaded `executing-plans` skill, `` → `` the preloaded `hyper-relay:executing-plans` skill, ``;
  line 48 `` invoke `finishing-a-development-branch`. `` → `` invoke `hyper-relay:finishing-a-development-branch`. ``

**6b'. Option B instead** (the prefixed name is skipped): make the same prose edits, and also
- `sat-planner.md`: delete lines 11–12 (`skills:` and its item); line 10 becomes
  `tools: Read, Grep, Glob, WebFetch, WebSearch, Write, Edit, Bash, Skill` (D22); after the `# SAT planner` heading
  and its blank line, insert this paragraph and a blank line:
  ```text
  **First, before anything else:** invoke `hyper-relay:writing-plans` with the Skill tool. It is the skill this file calls preloaded.
  ```
- `sat-executor.md`: delete lines 10–11 (`skills:` and its item); after the `# SAT executor` heading and its blank
  line, insert:
  ```text
  **First, before anything else:** invoke `hyper-relay:executing-plans` with the Skill tool. It is the skill this file calls preloaded.
  ```

**6c. This repo's local agents (D21)**, same option as 6b:
- `/home/noob_master/hyper-relay/.claude/agents/relay-planner.md`: line 12 `  - writing-plans` →
  `  - hyper-relay:writing-plans`; line 24 `` preloaded `writing-plans` skill. `` → `` preloaded `hyper-relay:writing-plans` skill. ``
  (option B: as `sat-planner.md`, heading `# hyper-relay planner`).
- `/home/noob_master/hyper-relay/.claude/agents/relay-executor.md`: line 5 `executing-plans skill` →
  `hyper-relay:executing-plans skill`; line 11 `  - executing-plans` → `  - hyper-relay:executing-plans`; line 17
  `` the preloaded `executing-plans` skill `` → `` the preloaded `hyper-relay:executing-plans` skill ``; line 49
  `` `finishing-a-development-branch` `` → `` `hyper-relay:finishing-a-development-branch` ``
  (option B: as `sat-executor.md`, heading `# hyper-relay executor`).

**6d. Memories (D26).** On exactly these lines, write each moved skill's name as `hyper-relay:<name>` (keep any
backticks or bold around it); change nothing else:

| File under `/home/noob_master/.claude/projects/` | Lines |
|---|---|
| `-home-noob-master-sat-pentraze-com/memory/orchestrator-workflow.md` | 3, 14, 15, 18, 22, 34 |
| `-home-noob-master-sat-pentraze-com/memory/MEMORY.md` | 12 |
| `-home-noob-master-sat-pentraze-com/memory/owner-runs-merge.md` | 15 |
| `-home-noob-master/memory/dispatch-plan-with-executing-plans.md` | 3, 8 (not the `name:` on line 2) |
| `-home-noob-master/memory/MEMORY.md` | 19 |
| `-home-noob-master/memory/alex-subagent-workflow.md` | 11 |
| `-home-noob-master-cube-tournament-display/memory/execute-plans-inline.md` | 3, 11, 12, 22 |
| `-home-noob-master-cube-tournament-display/memory/MEMORY.md` | 3 |
| `-home-noob-master-murmur/memory/design-workflow-pipeline.md` | 10, 15, 18, 19, 20, 24 |
| `-home-noob-master-murmur/memory/MEMORY.md` | 6 |
| `-home-noob-master-murmur-qwen3-tts/memory/design-workflow-pipeline.md` | 10, 15, 18, 19, 20, 24 |
| `-home-noob-master-murmur-qwen3-tts/memory/MEMORY.md` | 6 |
| `-home-noob-master-qwen3-tts/memory/design-workflow-pipeline.md` | 11, 16, 19, 20, 21 |
| `-home-noob-master-qwen3-tts/memory/MEMORY.md` | 5 |
| `-home-noob-master-tickets-ctf-interuniversitario/memory/shared-checkout-concurrent-sessions.md` | 20 |

and in `-home-noob-master-playground/memory/visual-companion-cannot-serve-sibling-assets.md` line 11, replace
`` `visual-companion`'s server (`~/.claude/skills/visual-companion/scripts/server.cjs`) has `` with
`` `hyper-relay:visual-companion`'s server (its `scripts/server.cjs`) has ``.
The hyper-relay project's own handoff memory is the orchestrator's to update as usual.

**6e. The home repo.** Its `CLAUDE.md` (untracked, D30) loses three rows of the staging table and the voice-to-specs
section. Delete these three lines:
```text
| `.claude/skills/voice-to-specs/` | the voice-to-specs skill |
| `.claude/skills/brainstorming/scripts/add-card-line.sh` | writes a doc's Quartz card line; the rest of the skill is untracked |
| `.claude/tests/add-card-line/` | its test suite |
```
and delete this block, with the blank line after it:
```text
## Scope boundary: voice-to-specs

Voice-to-specs stops at writing briefs. **Do not extend it to write specs, plans, or code** — those belong to downstream skills in the pipeline.

Setup, script interface, architecture, and modification rules live in `.claude/skills/voice-to-specs/CLAUDE.md`; the authoritative workflow (segmentation rules, templates, boundaries, example sessions) lives in `.claude/skills/voice-to-specs/SKILL.md`.
```
Then stop tracking the three paths (the files stay on disk until §3.5):

```bash
git -C /home/noob_master diff --cached --name-only
git -C /home/noob_master rm --cached -q .claude/skills/brainstorming/scripts/add-card-line.sh .claude/skills/voice-to-specs/CLAUDE.md .claude/tests/add-card-line/run-tests.sh
git -C /home/noob_master diff --cached --name-status
```
Expected: the first prints nothing (if anything was already staged, stop and ask the owner); the last prints exactly
three `D` lines. Commit WITHOUT a pathspec (a pathspec would re-add the files from disk), never with `-a`:
`git -C /home/noob_master commit -m "chore: stop tracking add-card-line and voice-to-specs, which live in hyper-relay now" -m "<the committing session's attribution lines>"`.
The owner's uncommitted `.gitignore` change stays unstaged.

- [ ] **Step 7: Live proofs (§4.4–4.6).**

**Claude Code (§4.4)**, in a new session in `/tmp`:
1. `/skills` (or `/plugin`, then the hyper-relay plugin's skills) lists 16 `hyper-relay:` skills, each once. The loose
   bare names are still there until Step 10 (expected, spec §3.2). Note any bare `brainstorming`,
   `using-superpowers` or `writing-skills` that comes from `~/.claude/skills/synced/` (D25).
2. Ask: "Invoke hyper-relay:brainstorming. Do not start brainstorming. Quote its checklist item 1 and its line about
   add-card-line.sh exactly, then run `test -x` on that script's path and print the result." Expected: item 1 is
   **Tick Brain**; the path is
   `/home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/brainstorming/scripts/add-card-line.sh`;
   the test passes.
3. The same for `hyper-relay:visual-companion` (its `start-server.sh` line) and `hyper-relay:voice-to-specs` (its Step 1
   command), told not to run anything: both show the cache path, not `${CLAUDE_SKILL_DIR}`.
4. In `~/sat.pentraze.com`: `claude --debug -p "Dispatch the sat-planner agent with exactly this prompt: 'Probe only, write nothing: reply with the first line starting with # of every skill preloaded into your context, or NONE.' Print its reply verbatim."`
   Option A: the reply is `# Writing Plans` and the debug log has no skip warning. Option B: the agent's first tool
   call is the Skill tool loading `hyper-relay:writing-plans`.

**OpenCode (§4.5):** `opencode run "List the skills named brainstorming, voice-to-specs, writing-plans and using-hyper-relay with the folder each loads from. Then load brainstorming and quote its checklist item 1. Then load voice-to-specs and brainstorming and give the absolute paths of the transcribe.sh and add-card-line.sh they tell you to run, and run test -f on both. Do nothing else."`
Expected: every folder is under `/home/noob_master/hyper-relay/skills/`; item 1 is **Tick Brain** (so hyper-relay's
copy beat the loose and synced ones); both paths are under that folder and exist.

**voice-to-specs (§4.6):**

```bash
ffmpeg -f lavfi -i "sine=frequency=440:duration=3" -ar 16000 -ac 1 /tmp/hr-sample.wav
sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/voice-to-specs/scripts/transcribe.sh /tmp/hr-sample.wav --model base
ls /home/noob_master/.local/share/hyper-relay/voice-to-specs/venv/bin/python /tmp/hr-sample.txt
```
Expected: `setup.sh` prints `Creating venv at /home/noob_master/.local/share/hyper-relay/voice-to-specs/venv...` (or
under `$XDG_DATA_HOME` if the owner sets it) and installs whisper (minutes: this is piece A's one behaviour change),
then the transcription exits 0 and writes `/tmp/hr-sample.txt` (a tone has no words, so it may be empty: the point is
the pipeline). A second run starts transcribing at once. A real short recording works too.

- [ ] **Step 8: Anything failed?** Fix it on a branch through the usual plan → merge → push, bump nothing until the
  owner says, and repeat the failed proof. Rolling back before Step 10: `claude plugin uninstall hyper-relay@hyper-relay`
  and remove the `skills` entry from `opencode.json`.

- [ ] **Step 9: Optional, owner's call:** run upstream's live suites from a worktree (never the main checkout, which
  holds `.mcp.json`), for example `tests/skill-triggering/run-all.sh`. They spend usage and were written for
  upstream's session primer, which A8 drops.

- [ ] **Step 10 (§3.5): THE OWNER ALONE deletes the loose copies**, only after Steps 1–7 pass:

```bash
rm -rf /home/noob_master/.claude/skills/brainstorming /home/noob_master/.claude/skills/dispatching-parallel-agents /home/noob_master/.claude/skills/executing-plans /home/noob_master/.claude/skills/finishing-a-development-branch /home/noob_master/.claude/skills/receiving-code-review /home/noob_master/.claude/skills/requesting-code-review /home/noob_master/.claude/skills/subagent-driven-development /home/noob_master/.claude/skills/systematic-debugging /home/noob_master/.claude/skills/test-driven-development /home/noob_master/.claude/skills/using-git-worktrees /home/noob_master/.claude/skills/using-superpowers /home/noob_master/.claude/skills/verification-before-completion /home/noob_master/.claude/skills/writing-plans /home/noob_master/.claude/skills/writing-skills /home/noob_master/.claude/skills/visual-companion /home/noob_master/.claude/skills/voice-to-specs
rm -rf /home/noob_master/.config/opencode/skills/visual-companion
rm -rf /home/noob_master/.claude/tests/add-card-line
```
This also deletes voice-to-specs' own `.git` (its 11 commits live in hyper-relay: `git log --oneline <subtree merge>^2`)
and its old venv. Afterwards: `/skills` in a new Claude Code session shows no bare copies of the 16 (except any synced
ones, D25); "use the writing-plans skill" loads `hyper-relay:writing-plans` (D24); OpenCode still lists hyper-relay's
skills; `scripts/check-import.sh` now exits 2 (expected).

- [ ] **Step 11: Record and commit.** Append to this plan, on `main`, keeping the bullet that happened and filling the
  date and results:

```markdown
## Switch-over record (Task 9)

- **Agent `skills:` lists (§3.4), Claude Code 2.1.326, <date>:** Option A: a plugin-prefixed name preloads (`hr-probe`
  replied `# Writing Plans`; no skip warning in the debug log). The agents list `hyper-relay:<skill>`.
- **Agent `skills:` lists (§3.4), Claude Code 2.1.326, <date>:** Option B: a plugin-prefixed name is skipped (debug
  log: `<the warning line>`). The agents invoke `hyper-relay:<skill>` with the Skill tool as their first step.
- **Live proofs:** §4.4 <pass/fail and notes>; §4.5 <pass/fail and notes>; §4.6 <pass/fail and notes>.
```

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece A switch-over record" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md#9
<the committing session's attribution lines>"
git -C /home/noob_master/hyper-relay push origin main
```
