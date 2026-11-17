# hyper-relay A: the fork's home (design)

**Date:** 2026-11-17 · **Status:** design approved by the owner in chat on 2026-11-17
**Card:** The fork's home (`09c73bab-55f1-4768-93e8-8889d4134ef6`)
**Initiative:** hyper-relay · **Piece:** A · **Followed by:** B (per-repo config and generic agents), C (our own
executing-plans), D (the orchestrator)
**Scope:** this repo; the owner's `~/.claude/` (`CLAUDE.md`, `skills/`); OpenCode's `~/.config/opencode/opencode.json`;
SAT's two agent files; the home repo's tracking of `add-card-line` and `voice-to-specs`. One plan.

## Goal

The workflow skills the owner runs every day are copies of superpowers v5.1.0 in `~/.claude/skills/`, edited in place
and in no git repo: brainstorming's Quartz steps, writing-plans' changes and three smaller edits exist only on this
disk. Piece A moves them into **hyper-relay**, a versioned, private, installable plugin for Claude Code and OpenCode,
**with no behaviour change**. Pieces B–D change behaviour; A only gives them a home.

hyper-relay is Quartz's companion: the role agents plus the board are what make the workflow the owner's own. Later
pieces design around Quartz; piece A keeps every existing Quartz step exactly as it is, and each still falls back to
plain Markdown when Quartz is absent.

## Decisions (owner, 2026-11-17)

| # | Question | Decision |
|---|---|---|
| A1 | Who is it for? | The owner first; shareable with other people later. **Not published** to any marketplace. So no skill names a path on this machine. |
| A2 | Soft or hard fork? | **Hard fork**, display name and plugin id **`hyper-relay`** (Claude Code refuses a plugin id that is not kebab-case, so `superpowers++` was out). Base: v5.1.0 **with obra's git history**; obra's repo is the `upstream` remote, and its fixes come over by cherry-pick when wanted. |
| A3 | Where does the history live? | A **private GitHub repo** `hyper-relay` as `origin` (a GitHub fork of a public repo cannot be private). |
| A4 | What moves in? | **A straight move:** all 14 upstream skills (test-driven-development included) with the owner's edits, plus `visual-companion`, plus **`voice-to-specs` with its own history** (the owner's first skill), plus `add-card-line.sh` and its tests. Nothing pruned or rewritten. |
| A5 | Which harnesses? | **Claude Code and OpenCode.** Codex, Cursor and Gemini support is stripped; another harness, if ever needed, is adapted then. |
| A6 | Quartz | **Quartz-first, not Quartz-required** (see Goal). |
| A7 | Where is it tracked? | Its own Quartz project, `hyper-relay`; specs and plans in this repo under `docs/superpowers/`. |
| A8 | Session-start primer | **None.** Upstream injects `using-superpowers` into every session; the owner's setup never has, and it costs tokens every session. |
| A9 | Names | `using-superpowers` becomes **`using-hyper-relay`**; every other skill keeps its name under the `hyper-relay:` prefix. Version **0.1.0**. |

## 1. What the repo holds

### 1.1 Identity

- `.claude-plugin/plugin.json`: name `hyper-relay`, version `0.1.0`, the owner as author, the GitHub repo as
  `repository`, licence MIT. `.claude-plugin/marketplace.json`: marketplace `hyper-relay`, one plugin, source `./`.
- `LICENSE` keeps obra's copyright line and adds the owner's. `README.md` says what hyper-relay is (the workflow; Quartz
  is the board), how to install it in both harnesses, and "forked from superpowers v5.1.0", with credit.
- `package.json` keeps only what `scripts/bump-version.sh` needs (its `main`, which named the OpenCode plugin, goes).

### 1.2 Skills (`skills/`)

| Skill | Source |
|---|---|
| brainstorming, writing-plans, subagent-driven-development, using-git-worktrees | upstream + the owner's edit (69, 19, 2 and 2 changed lines; brainstorming also lost its companion server to `visual-companion`) |
| using-hyper-relay | upstream `using-superpowers` + the owner's edit (8 lines), renamed |
| dispatching-parallel-agents, executing-plans, finishing-a-development-branch, receiving-code-review, requesting-code-review, systematic-debugging, test-driven-development, verification-before-completion, writing-skills | upstream, byte-identical to the owner's copies today |
| visual-companion | the owner's own (`~/.claude/skills/visual-companion`, identical to `~/.config/opencode/skills/visual-companion`) |
| voice-to-specs | the owner's own repo (`~/.claude/skills/voice-to-specs/.git`, 11 commits from 2026-03-20), history kept |

`brainstorming/scripts/add-card-line.sh` comes with brainstorming; its suite moves from the home repo's
`.claude/tests/add-card-line/` to `tests/add-card-line/`. Every other skill in `~/.claude/skills/` (elenchus, grill-me,
the course-video skill and the rest) stays where it is.

### 1.3 Harness support

**Claude Code** installs the plugin from the **GitHub repo only, never from a local path.** A local-directory
marketplace loads the plugin in place, gitignored files included, and a `.mcp.json` at the plugin root is read as the
plugin's own MCP servers: this checkout's Quartz wiring would ship as a broken `quartz` server. A git install clones
committed files only. (Facts in §5.)

**OpenCode** reads hyper-relay through the `skills` array of `~/.config/opencode/opencode.json`, pointed at this
repo's main checkout, `~/hyper-relay/skills`. That checkout moves only when a branch merges, because hyper-relay itself
is developed in worktrees. **Upstream's `.opencode/plugins/superpowers.js` is removed, not trimmed** (a change from the
chat, where it was to be cut down to registering `skills/`): it is written against OpenCode's V1 plugin API, whose
`config` hook and `experimental.chat.messages.transform` hook the V2 API replaced, and the installed OpenCode is v2.3.0.
A `skills` entry needs no code at all, and the only other thing the plugin did was the session primer that A8 drops.

**Removed:** `.codex-plugin/`, `.cursor-plugin/`, `.opencode/`, `GEMINI.md`, `gemini-extension.json`, `hooks/`
(upstream's session-start injection and its Cursor hooks), `scripts/sync-to-codex-plugin.sh`, `tests/codex-plugin-sync/`
and the Codex/Cursor/Gemini sections of the docs.

### 1.4 Docs, tests and local files

- Upstream's own specs and plans move from `docs/superpowers/` to `docs/upstream/`, so `docs/superpowers/` holds only
  hyper-relay's, which are what the Quartz hooks upload.
- The repo's `CLAUDE.md` and `AGENTS.md` are rewritten for developing hyper-relay (OpenCode reads `AGENTS.md`). They
  take over the home `CLAUDE.md`'s "Scope boundary: voice-to-specs" rule: voice-to-specs stops at writing briefs and
  never writes specs, plans or code.
- Tests kept: `claude-code`, `explicit-skill-requests`, `opencode`, `skill-triggering`, `subagent-driven-dev`.
  `brainstorm-server` follows the server code: the owner's edit moved the companion server out of brainstorming into
  `visual-companion`, which carries its own `scripts/run-tests.sh`, so the plan checks what upstream's suite covers
  that `run-tests.sh` does not, and moves it into `visual-companion` or drops it as superseded. Added:
  `tests/add-card-line/` and voice-to-specs' `tests/transcribe-sh.test.sh`.
- `.env`, `.envrc` and `.mcp.json` (this checkout's Quartz wiring) stay gitignored: done in `cd3fb50`.

## 2. How the fork is built

Each step is its own small commit, so `git log` shows exactly what differs from obra and why:

| # | Commit |
|---|---|
| 1 | Strip Codex, Cursor and Gemini support, `hooks/` and the OpenCode V1 plugin (§1.3). |
| 2 | Move upstream's specs and plans to `docs/upstream/`. |
| 3 | **Import the owner's edits, one commit per skill:** make `skills/<skill>` an exact mirror of `~/.claude/skills/<skill>` (files the owner removed are deleted too: brainstorming loses upstream's companion server, `scripts/{server.cjs,helper.js,frame-template.html,start-server.sh,stop-server.sh}` and `visual-companion.md`, which moved into `visual-companion`) for brainstorming, writing-plans, using-superpowers, subagent-driven-development and using-git-worktrees. Each diff is precisely that edit against v5.1.0, BEFORE any rename. |
| 4 | Add `visual-companion`. |
| 5 | Add `voice-to-specs` **with its history**: `git subtree add --prefix=skills/voice-to-specs <its repo> <its branch>` (not squashed), so its first commit from March stays in the log. |
| 6 | Move the `add-card-line` tests in. |
| 7 | **Rename to hyper-relay** (the rules below), the plugin files, README, LICENSE, `CLAUDE.md`, `AGENTS.md`. |
| 8 | voice-to-specs' venv moves out of the skill (below). |

**The rename rule:**

| Changes | Stays |
|---|---|
| The `superpowers:` skill prefix (26 uses) → `hyper-relay:` | **`docs/superpowers/` paths** (10 uses): Quartz's hooks accept specs and plans only there, and every repo already has docs there |
| `using-superpowers` → `using-hyper-relay` | **`.superpowers/` working folders**: visual-companion keeps its screens there, and SAT's mockups live there |
| Prose that names the plugin "Superpowers" | Credits to obra and to superpowers (README, LICENSE) |
| An absolute path to a skill's own files (`~/.claude/skills/<skill>/…`: brainstorming's `add-card-line.sh`, visual-companion's `start-server.sh`, voice-to-specs' `transcribe.sh`) → **`${CLAUDE_SKILL_DIR}/…`**, worded so OpenCode finds the same file (below) | `writing-skills`' examples and advice about personal skill folders: they describe `~/.claude/skills` in general, not this plugin |

`${CLAUDE_SKILL_DIR}` is Claude Code's documented variable for a skill's own folder. OpenCode does not substitute it,
so each such line also names the path relative to the skill ("`scripts/transcribe.sh` beside this SKILL.md"), and the
plan checks live in OpenCode v2.3.0 that the script is found.

**voice-to-specs' venv** moves from `skills/voice-to-specs/scripts/venv` to
`${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv`, read by both `setup.sh` and `transcribe.sh`. A
plugin update replaces the installed folder, which would delete a venv inside it. Claude Code's `${CLAUDE_PLUGIN_DATA}`
was considered and not used: OpenCode does not set it. This is piece A's **one behaviour change**: the first use after
the switch reinstalls whisper (a venv cannot be moved).

## 3. Switching over

In one sitting, while no planner or executor is running anywhere:

1. Push to the private GitHub repo and tag `v0.1.0`. For background plugin updates, git must reach the repo
   non-interactively: `gh auth login` then `gh auth setup-git` (an environment token alone does not authenticate the
   background check).
2. Claude Code: `/plugin marketplace add <owner>/hyper-relay`, then `/plugin install hyper-relay@hyper-relay`. For a
   few minutes both copies exist; `brainstorming` and `hyper-relay:brainstorming` are different names, so nothing
   collides.
3. OpenCode: add `~/hyper-relay/skills` to `skills` in `~/.config/opencode/opencode.json`. Explicit `skills` entries
   take precedence over `~/.claude/skills`, so hyper-relay wins any same-named skill from then on.
4. Point everything at the new names:
   - the global `~/.claude/CLAUDE.md`: every place that names a skill (the phase table, the handoff table, the
     worktrees section, `dispatching-parallel-agents`), and the Quartz section's `add-card-line.sh` path, which
     becomes "brainstorming's `scripts/add-card-line.sh`";
   - SAT's `.claude/agents/sat-planner.md` (`skills: writing-plans`) and `sat-executor.md` (`skills: executing-plans`).
     **The docs do not say whether a `skills:` list accepts a plugin-prefixed name.** The plan tests
     `hyper-relay:writing-plans` with `claude --debug`, which logs a listed skill it skipped. If it is skipped, the
     fallback is the agent's first instruction: "invoke `hyper-relay:<skill>` with the Skill tool before anything
     else". The plan records which one worked;
   - the memories that name skills (SAT's `orchestrator-workflow` and others the plan finds by grep);
   - the home repo: it stops tracking `.claude/skills/brainstorming/scripts/add-card-line.sh`,
     `.claude/tests/add-card-line/` and `.claude/skills/voice-to-specs/`, and its `CLAUDE.md` loses the
     voice-to-specs section and those rows of the staging table (each now lives in hyper-relay).
5. **The owner** removes the loose copies: the 14 upstream skills, `visual-companion` and `voice-to-specs` from
   `~/.claude/skills/`, and `visual-companion` from `~/.config/opencode/skills/`. Only after §4 passes. OpenCode reads
   `~/.claude/skills/` too, so this step switches it over as well.

**Rolling back:** until step 5, uninstall the plugin and drop the OpenCode entry, and nothing has changed. After step
5, the import commits (§2, 3–5) hold every edit and voice-to-specs' whole history, so even the deletion is recoverable.

## 4. Proof that nothing changed

All before step 5:

1. **A check script** (`scripts/check-import.sh`) compares every `skills/<skill>` with the loose copy it came from,
   after applying §2's rename rule and voice-to-specs' venv path. The diff must be empty. It is the definition of "no
   behaviour change" for this piece.
2. `claude plugin validate .` passes, with no warning about the name, the README or the licence.
3. `tests/add-card-line/` and voice-to-specs' `transcribe-sh` test pass in their new homes, and the kept upstream
   suites pass or are reported with the reason they cannot run here.
4. **Claude Code, live:** the skill list shows `hyper-relay:*` and no duplicate; `hyper-relay:brainstorming` loads
   with its Quartz steps and its `add-card-line.sh` path resolving; a SAT planner dispatch preloads
   `hyper-relay:writing-plans` (or the fallback of §3.4 is in place and works).
5. **OpenCode, live:** its skill tool lists the hyper-relay skills; voice-to-specs and brainstorming find their scripts.
6. voice-to-specs transcribes a short sample after `setup.sh` builds the new venv.

## 5. Facts checked (2026-11-17)

- **OpenCode** ([skills](https://opencode.ai/docs/skills/), [plugins](https://opencode.ai/docs/plugins/),
  [V1 migration](https://opencode.ai/docs/build/plugins/migrate-v1/)): skills are discovered in
  `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` and the project's `.opencode/`, `.claude/` and
  `.agents/` folders; the config's `skills` array adds directories and outranks them all; nothing turns the Claude
  locations off. So the owner's OpenCode runs today's loose copies, and a Claude Code plugin's skills (in its plugin
  cache) are invisible to it. The plugin config key is now `plugins`; V1's `config` hook and
  `experimental.chat.messages.transform` map to V2 transforms and `ctx.session.hook("context", …)`.
- **Claude Code** ([sub-agents](https://code.claude.com/docs/en/sub-agents.md),
  [plugin components](https://code.claude.com/docs/en/plugins/components.md),
  [install](https://code.claude.com/docs/en/plugins/install.md),
  [host a marketplace](https://code.claude.com/docs/en/plugins/host-marketplace.md),
  [loading](https://code.claude.com/docs/en/plugins/loading.md), [skills](https://code.claude.com/docs/en/skills.md)):
  a plugin's `.mcp.json` at its root declares its MCP servers; a local-directory marketplace loads in place (files on
  disk, gitignored ones included), a git one clones committed files only; private GitHub marketplaces use the
  machine's git credentials, and background updates need a credential helper (`gh auth setup-git`);
  `${CLAUDE_SKILL_DIR}` is a skill's own folder and `${CLAUDE_PLUGIN_ROOT}` changes with every version; the sub-agent
  docs show only bare names in `skills:` and say a missing one is skipped with a debug-log warning.

## 6. Out of scope

Every behaviour change except §2's venv: per-repo config and generic agents (B; the SAT agents also move into the
plugin then), our own executing-plans and the worktree-or-branch setting (C), the orchestrator (D), any session-start
primer, a hyper-relay icon or artwork (the Canva concept exists), and porting anything from upstream after v5.1.0.

## 7. Plans

One plan, `docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md`, executed in a worktree of this repo
(`.worktrees/` is already gitignored upstream). §3's steps that touch `~/.claude/`, OpenCode's config, the home repo or
GitHub are the plan's last task, run with the owner, and step 5 is the owner's alone.
