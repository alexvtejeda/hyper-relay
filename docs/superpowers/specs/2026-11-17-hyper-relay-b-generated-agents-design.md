# hyper-relay B: role agents generated per project (design)

**Date:** 2026-11-17 · **Status:** design approved by the owner in chat on 2026-11-17
**Card:** per-repo config  and generic agents (`0ac47920-b892-42ac-bc46-10e7207ca912`)
**Initiative:** hyper-relay · **Piece:** B · **Depends on:** A (the plugin layout, `bin/`, the renamed skills)
**Scope:** this repo (templates, generator, skill, session-start check); the facts files and generated agents of SAT
(`~/sat.pentraze.com`) and of hyper-relay itself. One plan.

## Goal

The owner's role agents (planner, executor, reviewer) are written by hand for each project. SAT's three are about 70%
general rules for the role and 30% facts about SAT, and hyper-relay's `relay-*` agents began as word-for-word copies of
SAT's that still pointed at SAT until they were rewritten on 2026-11-17. A lesson learned in one project reaches
the others only if someone copies it.

Piece B splits the two parts. hyper-relay ships **role templates** holding the general rules. Each repo keeps a
committed **facts file** holding only its own facts. A **generator** combines them into the repo's
`.claude/agents/<project>-<role>.md`. A general lesson goes into a template and reaches every project on its next
regeneration. A project lesson goes into that project's facts file. Nobody edits a generated agent.

## Decisions (owner, 2026-11-17)

| # | Question | Decision |
|---|---|---|
| B1 | What does "agents from a template, on demand" mean? | **Per project:** generated once per repo from the templates plus the repo's facts, and generated again when either changes. Not per task. |
| B2 | How are they built? | **A facts file plus a generator** (approach 1). Not generic plugin agents that read the facts at run time: Claude Code ignores `hooks` on plugin agents, so the planner's guard would be lost, and every repo would get the same model per role. Not a one-time starter: template fixes would never reach existing projects, which is how `relay-*` ended up pointing at SAT. |
| B3 | Which roles? | **Planner, executor, reviewer.** The reviewer comes in two kinds: `browser` (a click-through of a running app, like SAT's) and `commands` (acceptance by running commands and live CLI sessions, like hyper-relay's). |
| B4 | Which harness? | **Claude Code** gets generated agents. **OpenCode** gets a guide (§5) that an OpenCode orchestrator follows to adapt the generated agents; it asks the owner which model to use for each role. |
| B5 | Who combines templates and facts? | **A deterministic POSIX shell script**, not the model: the same input gives the same output, it can be tested, and it costs no tokens. A skill covers the parts that need judgment. |
| B6 | What is under version control? | The **facts file is committed** in its repo. The **generated agents and the guard copy are not**: they come from the templates and the facts, and they hold this machine's paths. |
| B7 | How do agents pick up changes? | **A notice at session start:** a plugin `SessionStart` hook runs the generator's check, prints nothing when the agents are current, and prints one line when they are out of date. The orchestrator then regenerates. Not automatic regeneration (a bad release would reach every repo unseen), not manual only (stale agents go unnoticed). |
| B8 | Where does a lesson go? | General (true in any repo of that kind) → a template, through a hyper-relay change. Project-specific → that repo's facts file. |
| B9 | Is the `wt` move part of B? | **No**, it gets its own card: a straight move of the script into the plugin's `bin/`, its tests and its design spec. B's facts describe each repo's stack either way. |
| B10 | Where does the planner's guard live? | Copied by the generator into the repo's `.claude/hooks/`, and called through `$CLAUDE_PROJECT_DIR` (§1.3). |
| B11 | Default models | Planner `opus`, executor `sonnet`, reviewer `sonnet` (the owner's rule since 2026-11-11). A facts file can override each. |

## 1. What lives where

### 1.1 In the plugin

| Path | What |
|---|---|
| `templates/agents/planner.md`, `executor.md`, `reviewer-browser.md`, `reviewer-commands.md` | The general rules for each role, with slots for facts (§2.2). Built from SAT's `sat-*` agents and this repo's `relay-*` agents as of 2026-11-17. **Not under `agents/`**: Claude Code loads every file in a plugin's `agents/` as a live plugin agent. |
| `templates/hooks/planner-guard.py` | Today's `~/.claude/hooks/sat-planner-guard.py`, which already works for any repo. Its messages say "planner guard" instead of "sat-planner guard"; its rules do not change. |
| `bin/hyper-relay-agents` | The generator (§3). In `bin/`, so Claude's Bash tool runs it by name. It finds the templates relative to its own location, so a hyper-relay worktree's copy uses that worktree's templates. |
| `skills/agents/SKILL.md` (`hyper-relay:agents`) | Drafting a facts file, running the generator, handling a refused file, and pointing OpenCode at the guide (§4). |
| `skills/agents/opencode.md` | The OpenCode adaptation guide (§5). |
| `hooks/hooks.json` | One `SessionStart` hook: the out-of-date check (§3.3). Piece A deleted upstream's `hooks/`; this file adds back only the check. |
| `tests/hyper-relay-agents/` | The generator's and the hook's tests (§6.1). |

Templates and skills follow A1: they never name a path on this machine. The generator fills paths in.

### 1.2 In each repo

| Path | What | Committed? |
|---|---|---|
| `.hyper-relay/agents.md` | The facts file (§2.1). The `.hyper-relay/` folder leaves room for C's per-repo settings. | Yes |
| `.claude/agents/<project>-planner.md`, `<project>-executor.md`, `<project>-reviewer.md` | Generated agents. | No |
| `.claude/hooks/hyper-relay-planner-guard.py` | Generated copy of the guard. | No |

`.claude/` is already gitignored in SAT and in hyper-relay. In a repo where the generated paths are not ignored, the
skill says so and proposes the `.gitignore` lines. The generator itself never edits `.gitignore`.

### 1.3 Why the guard is copied into the repo

The plugin's install path changes with every version, and `${CLAUDE_PLUGIN_ROOT}` is not substituted in a project's
own agent files. A hook command pointing into the plugin would break after an update, and a hook whose command fails
does not stop the tool call, so the planner would silently lose its read-only guard. A copy inside the repo stays where
the hook expects it and always matches the template it was generated with. The planner's hook command is
`"$CLAUDE_PROJECT_DIR"/.claude/hooks/hyper-relay-planner-guard.py`.

Planners are dispatched from the orchestrator session in the main checkout, so `$CLAUDE_PROJECT_DIR` is the main
checkout, where the copy exists. A session started inside a worktree would not find it (`.claude/` is not checked out
there); the generated planner is for the main checkout's orchestrator.

## 2. The facts file and the templates

### 2.1 The facts file

```markdown
---
project: sat
reviewer: browser
model.executor: sonnet
---
Notes for humans. The generator ignores everything before the first ## heading.

## planner/before-writing
- Take the next free migration number from `api/db/migrations/` on main.

## executor/gates
- API: `go build ./...`, `go vet ./...`, `go test ./...`; the integration suite only if the plan changes SQL.

## reviewer/seed-facts
- `admin@acme.test` / `Password123!` (a super-admin on `wt` stacks).
```

- **Header:** plain `key: value` lines between `---` lines, read by the shell script, no YAML parser. Keys:
  `project` (required; lowercase letters, digits and `-`; names the generated files), `reviewer` (required;
  `browser` or `commands`), `model.planner`, `model.executor`, `model.reviewer` (optional; B11's defaults). Any other
  key is an error.
- **Sections:** `## <role>/<slot>`, one per slot the repo fills. The body is copied verbatim into the slot.

### 2.2 Templates and slots

A template is a complete agent file (frontmatter and body) with:

- **Values:** `{{project}}`, `{{root}}` (the main checkout's absolute path, found the way `wt` finds it: the parent of
  `git rev-parse --git-common-dir`) and `{{model}}` (this role's model).
- **Slots:** a line holding only `{{slot <role>/<name>}}` is replaced by the body of the facts section of that name. A
  missing section drops the line. A **required** slot, written `{{slot! <role>/<name>}}`, makes a missing section an
  error.
- A facts section that no template slot uses is an error ("is it a typo?"), the way `wt` checks its `WT_ENV` keys.

| Template | Slots |
|---|---|
| planner | `planner/before-writing`, `planner/plan-format` (e.g. SAT's migration number and API+web Contract), `planner/execution-notes`, `planner/report` |
| executor | `executor/setup` (e.g. `npm install` in `web/`), **`executor/gates` (required)**, `executor/constraints` (e.g. `wt` only, the nav-i18n test), `executor/acceptance` (e.g. `wt up` and report the URLs) |
| reviewer-browser, reviewer-commands | `reviewer/before-you-start`, `reviewer/helpers` (e.g. TOTP, MailHog, database queries), `reviewer/seed-facts`, `reviewer/gotchas`, `reviewer/look-beyond` (e.g. the Spanish UI) |

`executor/gates` is the one required slot because an executor without gates silently skips the final checks.

The templates' `skills:` lines name `writing-plans` and `executing-plans` in whichever form piece A's Task 9 proves
works: a plugin-prefixed name in the `skills:` list, or the fallback of an explicit first instruction to invoke the
skill (with `Skill` added to the agent's tools, A's D22).

## 3. The generator: `hyper-relay-agents`

A POSIX shell script run by dash, like `wt` and `ccs`. It must pass `dash -n`, use no bash-only syntax, and never lean
on ambient `set -e` inside a function.

### 3.1 Running it

`hyper-relay-agents [--force] [--check [--hook]]`, run anywhere inside a repo's checkout.

1. Find the checkout's top level and the main checkout (§2.2), then read `.hyper-relay/agents.md`. No file: error.
2. Validate the facts against the templates: header keys and values, the reviewer kind, required slots, sections
   that match no slot. Any error stops the run **before anything is written**, listing every problem found.
3. Write the three agents and the guard copy, one output line per file: `written`, `unchanged` or `refused` (with the
   reason).
4. If it had to create `.claude/agents/`, print that the session must be restarted (§7, Claude Code facts).

Exit codes: 0 when every file is written or unchanged, 1 on an error or any refused file.

### 3.2 The marker, and refusing hand edits

Each generated agent's first body line (after the frontmatter) is a marker:

```
<!-- generated by hyper-relay-agents <version> from .hyper-relay/agents.md; edit that file and rerun. sha256 <hash> -->
```

`<hash>` is the SHA-256 of the file's content without the marker line. The guard copy carries the same marker as a
`#` comment on its second line. On a rerun:

- **Content matches the hash** (never edited): overwritten if the new output differs, otherwise `unchanged`.
- **Content does not match** (edited by hand): `refused`. The message names the facts section the change probably
  belongs in.
- **No marker** (a hand-written agent, like today's `sat-planner.md`): `refused`.
- `--force` overwrites in both refused cases. It is for after someone has looked at the diff.

### 3.3 Out of date, and the session-start notice

`--check` writes nothing. It renders every output in memory and compares it with what is on disk, ignoring the marker
line, so a template change, a facts change or a missing file each count, while a version bump that changes nothing
does not. It prints one line per out-of-date or hand-edited file (`sat-planner: out of date (hyper-relay 0.2.0 →
0.3.0)`, `sat-reviewer: edited by hand`) and exits 1, or prints nothing and exits 0.

`--check --hook` is the same check for the `SessionStart` hook: it always exits 0, prints **nothing** when the agents
are current or the repo has no facts file or is not a git repo, and otherwise prints a single line:

```
hyper-relay: sat-planner, sat-executor are out of date; run hyper-relay-agents (see the hyper-relay:agents skill).
```

An internal error prints one line starting `hyper-relay: agents check failed:` and still exits 0, so the check can
never get in the way of a session. `hooks/hooks.json` calls `${CLAUDE_PLUGIN_ROOT}/bin/hyper-relay-agents --check --hook`.
This is not a session-start primer (A8): a repo whose agents are current gets no output at all.

## 4. The `hyper-relay:agents` skill

1. **No facts file yet.** Read the repo's `CLAUDE.md`, compose file, Makefile and any hand-written agents in
   `.claude/agents/`. Sort their lines: general (already in a template) or project-specific (a facts section). Draft
   `.hyper-relay/agents.md`, show it to the owner with the sorting, and write it only after approval.
2. **Run the generator** and say what changed. After a first generation that created `.claude/agents/`, say the
   session needs a restart.
3. **A refused file.** Show the hand edit and propose where it belongs: a project lesson goes into the facts file; a
   general one is a template change in hyper-relay, so a card, not a quick edit. Overwrite with `--force` only after
   the owner agrees.
4. **Not ignored.** If the generated paths are not gitignored, say so and propose the `.gitignore` lines.
5. **In OpenCode**, follow `opencode.md` (§5).

## 5. The OpenCode guide (`skills/agents/opencode.md`)

OpenCode's docs do not mention reading `.claude/agents/`, so it needs its own agent files. The body of each agent carries
over unchanged; the header and the guard are translated:

| Claude Code | OpenCode |
|---|---|
| `.claude/agents/<name>.md` | `.opencode/agents/<name>.md` (the agent's name is the file name) |
| `model: sonnet` | **The orchestrator asks the owner which model to use for each role**, listing the models OpenCode has configured. It does not translate the Claude Code model: OpenCode reaches other providers (e.g. GLM for the planner, a specific DeepSeek for the executor). On a later re-adaptation it keeps the model already in the existing OpenCode file unless the owner asks to change it. Also `mode: subagent`. |
| `tools`, `disallowedTools` | `permissions`: an ordered list of `{action, resource, effect}` rules; the last match wins. `bash` is `shell`; the `Agent` tool is `subagent`. |
| `skills: [writing-plans]` | No preload: the agent's first instruction is to load the skill with the `skill` tool. |
| The planner's guard hook | No per-agent hooks: the guard becomes permission rules: deny all `shell`, then allow `git status *`, `git log *` and the other read-only git commands, `git add`/`git commit` of plan paths and `quartz link-doc`; deny all `edit`, then allow `docs/superpowers/plans/*.md`. |

The guide says plainly that the last row only comes close: the guard checks a command's structure (for example, that
`git commit` names only plan files after `--`) and refuses shell operators, which patterns cannot fully express.

The model choice lives in the adapted OpenCode file, not in the committed facts file, so each person using a repo picks
their own. Each adapted file copies the marker line of the generated agent it came from, so it is visible when an
OpenCode agent was adapted from an older version.

## 6. Proof

### 6.1 Tests (`tests/hyper-relay-agents/run-tests.sh`, dash)

- Facts errors: no file, unknown header key, bad `project`, bad reviewer kind, missing required slot, a section that
  matches no slot. Each one stops the run with nothing written.
- Outputs: `written`, `unchanged`, refused for a hand edit, refused for no marker, `--force` overwriting both.
- Running twice in a row changes nothing.
- The restart message when `.claude/agents/` is created.
- `--check`: its lines and exit codes for current, out of date, edited by hand and missing files; a version-only bump is
  current.
- `--check --hook`: silent when current, in a repo with no facts file and outside git; one line when out of date; one
  line and exit 0 on an internal error.
- The rendered planner's hook command and the guard copy's path agree.
- The guard's own behaviour, which has no tests today: commands and paths it allows and refuses under its current rules.

### 6.2 Switching two real repos over

- **SAT.** `~/sat.pentraze.com/.hyper-relay/agents.md` is written from today's `sat-planner.md`, `sat-executor.md` and
  `sat-reviewer.md`. The plan accounts for **every line of those three files**: in a template, in SAT's facts, or
  dropped with a reason. The owner reviews that accounting with the plan, so no lesson is lost. The generator then
  replaces the hand-written files with `--force`.
- **hyper-relay.** Its own `.hyper-relay/agents.md` uses `project: relay` and `reviewer: commands`, so the generated
  agents keep today's `relay-*` names and replace the hand-written ones.

Both are outside the executor's worktree (SAT's repo, and this repo's main checkout), so they are the plan's last task,
run by the orchestrator with the owner.

### 6.3 Live

- **One dispatch of the generated `relay-planner`**, asked to run one command its guard refuses and one it allows.
  It proves at once that the generated agent loads, that its skill is preloaded, that it gets its model, and that the
  guard hook finds its copy through `$CLAUDE_PROJECT_DIR` (the riskiest piece: a hook that cannot find its script fails
  silently).
- **The session-start notice:** after a facts edit in hyper-relay's main checkout, a new session shows the one line;
  after regenerating, a new session shows nothing.
- **The owner, in OpenCode:** adapt `relay-planner` once with the guide; OpenCode lists it, and its permissions refuse
  a forbidden command.
- **The owner, afterwards:** once SAT's generated planner is in use, delete `~/.claude/hooks/sat-planner-guard.py`.

## 7. Facts checked (2026-11-17)

Gathered from the docs by research subagents in the brainstorming session on 2026-11-17 and not yet re-read first-hand:
**the plan re-verifies each one** and lists any difference as a deviation.

- **Claude Code** ([sub-agents](https://code.claude.com/docs/en/sub-agents.md),
  [plugin components](https://code.claude.com/docs/en/plugins/components.md),
  [manifest reference](https://code.claude.com/docs/en/plugins/manifest-reference.md),
  [skills](https://code.claude.com/docs/en/skills.md), [CLI](https://code.claude.com/docs/en/cli-reference.md)):
  - `.claude/agents/` and `~/.claude/agents/` are watched: a new or edited agent file is used from the next dispatch,
    without a restart, except when the `agents/` directory did not exist when the session started.
  - Plugin agents ignore `hooks`, `mcpServers` and `permissionMode` "for security reasons"; they are named
    `<plugin>:<agent>`.
  - A plugin's `bin/` is on the Bash tool's `PATH` while the plugin is enabled, after the user's own entries. Nothing
    documents it reaching the user's own shell.
  - `${CLAUDE_PLUGIN_ROOT}` is the installed version's path, and the plugin variables are not in the environment of
    commands run through the Bash tool; they are substituted in skill, agent and hook content.
  - A subagent's frontmatter hooks run only while it is active; a project agent's hooks need the folder's workspace
    trust.
  - `userConfig` options are per user (stored in `settings.json`), not per repo.
  - Whether `skills:` accepts a plugin-prefixed name is undocumented; piece A's Task 9 tests it.
  - From piece A's plan (D20): auto-update is off by default for marketplaces that are not Anthropic's, and an installed
    plugin updates only when its version changes, so a template change reaches other repos only with a release.
- **OpenCode** ([agents](https://opencode.ai/docs/agents/), [permissions](https://opencode.ai/docs/permissions/),
  [skills](https://opencode.ai/docs/skills/), [config](https://opencode.ai/docs/config/)), V2 docs, not yet confirmed
  against the installed v2.3.0:
  - Agents live in `~/.config/opencode/agents/` and `.opencode/agents/`; nothing documents reading `.claude/agents/`.
  - Frontmatter: `description`, `mode` (`primary`, `subagent`, `all`), `model` (`provider/model#variant`; a subagent
    without one inherits the parent's), `permissions`, `steps`, `hidden`, `color`, `disabled`. Legacy `tools`,
    `permission`, `prompt` and `maxSteps` are not to be used.
  - `permissions` rules are `{action, resource, effect}` with `*`/`?` wildcards, combined in order, last match wins;
    the actions include `shell`, `edit` (resource: the path), `subagent` and `skill`.
  - No per-agent hooks and no skill preloading are documented; subagents cannot start subagents by default.
  - Whether agent files are picked up live is undocumented.

## 8. Out of scope

Moving `wt` (its own card), per-task agents (B1), generating OpenCode agents automatically (B4), our own
executing-plans and the worktree-or-branch setting (C), the orchestrator (D), and roles beyond the three in B3.

## 9. Plans

One plan, `docs/superpowers/plans/YYYY-MM-DD-hyper-relay-b-generated-agents.md` (dated the day it is written), written after piece A merges and executed
in a worktree of this repo. §6.2's two switch-overs and §6.3's live checks are its last task, run by the orchestrator
with the owner.
