# hyper-relay C: our own executing-plans (design)

**Date:** 2026-11-17 · **Status:** design approved by the owner in chat on 2026-11-17
**Card:** Our own executing-plans (`87182271-355e-4fdf-a9d9-cd25365b1302`)
**Initiative:** hyper-relay · **Piece:** C · **Depends on:** B (its executor and planner templates, its generator and
`.hyper-relay/agents.md`), merged before C's plan is written
**Scope:** this repo (the `executing-plans` skill, the skills that point at execution, B's templates and generator,
the deletion of `subagent-driven-development`); the facts files and generated agents of hyper-relay and SAT; the
owner's global `~/.claude/CLAUDE.md`. One plan.

## Goal

`executing-plans` is still upstream's, and it disagrees with how the owner works. It tells the agent to prefer
`subagent-driven-development` when subagents exist, to raise concerns with "your human partner", and to finish with
`finishing-a-development-branch`. The executor agents (`relay-executor`, SAT's, B's executor template) each override
it: they run as a dispatched subagent with no partner, commit per task with `Plan-Task:` trailers, run the full gates
once, never tick and stop before merging. The orchestrator's side of the handoff (the 1/2/3 question, worktree setup,
dispatch, verifying the hand-back) lives only in the owner's global `CLAUDE.md`. `writing-plans` still offers
upstream's two options.

Piece C makes the skill say what the owner's executors do, and ships the orchestrator's half with it. It also adds a
second place to run, **a branch in the main checkout**, because worktrees cost time: setup, a `wt` stack per app, and
plans that carry worktree plumbing.

## Decisions (owner, 2026-11-17)

| # | Question | Decision |
|---|---|---|
| C1 | Who runs `executing-plans`? | **Only a dispatched executor**, in a fresh context. "Solo" (the orchestrator executing a plan itself) is removed: the orchestrator's context is full of decisions and explanations, and a fresh window works better. |
| C2 | `subagent-driven-development` | **Deleted from the plugin**, with its live suites. Its per-task reviews cost too many tokens for what they catch, and its description ("REQUIRED whenever the user asks to … dispatch agents") fights the handoff, which the owner's `CLAUDE.md` had to override. |
| C3 | Where does the executor run? | **Two modes, both one background executor.** **Branch:** a new branch in the main checkout. **Worktree:** its own worktree. Never on `main` itself: code would land before the owner's click-through, `quartz link-branch` refuses `main`, and OpenCode reads this repo's `skills/` from the main checkout live. |
| C4 | The price of Branch | While a branch run is active the orchestrator **writes but does not commit** (§3.2); only one branch run per checkout; Quartz's task ticks queue until the main checkout is back on `main` (§8). |
| C5 | Per-repo default | A header key in `.hyper-relay/agents.md`: **`execute: branch`** or **`execute: worktree`**. The handoff then only confirms it or takes an override. With no key, or no facts file, the handoff asks. |
| C6 | Does C include the orchestrator's half? | **Yes, for one plan at a time**: handoff, setup, link, dispatch, hold-back, verifying the hand-back, review, merge, committing held-back docs. Branch mode is unsafe without the hold-back rules, so they ship with it. **D** adds several plans at once, stacking dependent plans, migration and shared-file conflict checks, and the stack to click through. |
| C7 | Layout | **One skill.** `skills/executing-plans/SKILL.md` is the executor's process (what the executor preloads); `skills/executing-plans/dispatching.md` is the orchestrator's half. `SKILL.md`'s first line sends an orchestrator there. |
| C8 | Acceptance facts depend on the mode | `wt` refuses a main checkout, so B's `executor/acceptance` slot splits into **`executor/acceptance-worktree`** and **`executor/acceptance-branch`**, both optional. The dispatch prompt names the mode and the executor follows the matching one. |
| C9 | Defaults | **hyper-relay: `execute: branch`** (no app stack). **SAT: `execute: worktree`** (Branch would run its migrations against the owner's real dev database; `wt` exists for exactly this). |
| C10 | Quartz's two manual steps | **The orchestrator runs both**: `quartz link-branch` at dispatch, `quartz review` after verifying the hand-back. Plans stop carrying them. |
| C11 | The commit invariant | **A spec or plan is committed only when the main checkout is on `main`.** B's planner already checks this before committing; C adds it to `brainstorming` and `writing-plans`. A branch run is detected from git state, so the rule holds after a `/clear` or in a new session. |
| C12 | Regenerated agents in a running session (added 2026-11-17, after B's Task 7) | A running session keeps the agent definitions it loaded (§8), so after regenerating, the session still dispatches the old agents. **The generator and the `agents` skill say so** (§5.3): start a new session to use them. |

## 1. What changes where

| Where | Change |
|---|---|
| `skills/executing-plans/SKILL.md` | Rewritten: the executor's process (§2). |
| `skills/executing-plans/dispatching.md` | New: the orchestrator's half (§3). |
| `skills/subagent-driven-development/` | Deleted (§4.1). |
| `skills/writing-plans/SKILL.md` | Execution pointers, the handoff, the Quartz steps, the commit rule (§4.2). |
| `skills/brainstorming/SKILL.md` | The commit rule (§4.3). |
| `skills/using-git-worktrees/SKILL.md` | No longer triggered by the handoff (§4.4). |
| `skills/dispatching-parallel-agents/SKILL.md`, `requesting-code-review/SKILL.md`, `voice-to-specs/SKILL.md`, `writing-skills/render-graphs.js` | Their `subagent-driven-development` mentions (§4.1). |
| `templates/agents/executor.md`, `templates/agents/planner.md` | Shrink and re-point (§5.1, §5.2). |
| `bin/hyper-relay-agents`, `tests/hyper-relay-agents/run-tests.sh` | The `execute` key, the two acceptance slots, `###` headings, the restart line (§5.3). |
| `skills/agents/SKILL.md` | The restart line (§5.3). |
| `.hyper-relay/agents.md` | `execute: branch` (§5.4). |
| `README.md`, `CLAUDE.md`, `docs/testing.md` | Say what the repo now does (§4.1, §6). |
| Owner's `~/.claude/CLAUDE.md`, SAT's `.hyper-relay/agents.md`, both repos' generated agents | The last task, with the owner (§7.2). |

## 2. The executor's process (`skills/executing-plans/SKILL.md`)

Its description says it is for an executor dispatched to run one approved plan, and that an orchestrator handing a
plan off reads `dispatching.md` instead. Its first body line says the same.

### 2.1 The dispatch prompt gives

The plan's path; the **mode** (`branch` or `worktree`); the checkout's path and the branch; which tasks are the
executor's; the Claude-Session URL for the commit trailers; anything unusual (e.g. `main` moved since the plan was
written, or a plan read by absolute path because it is gitignored).

### 2.2 The process

1. **Check where you are.** The checkout and `git branch --show-current` must match the prompt. If not, stop and
   report; never switch branches. Read `CLAUDE.md` at the checkout's top. The plan's Execution notes are binding.
2. **No review gate.** The plan is approved. An unclear or impossible step means stop and report, never guess.
3. **Each task, in order:** follow its steps exactly, transcribing the plan's code; run only that task's checks;
   commit at its end, staging named files only (never `git add -A` / `git add .`). The task's final commit carries
   `Plan-Task: <plan path>#<N>` and the attribution lines the executor's instructions give, all in one final
   paragraph. Report every `quartz:` line a commit prints, verbatim. Never tick the plan.
4. **When the code is not what the plan expects** (an expected line differs, a file moved): adapt as little as
   possible and record it as a deviation. A step that fails twice the same way: stop and report.
5. **Full gates, once,** after the last task: the ones the Execution notes name and the agent's own
   (`executor/gates`).
6. **Acceptance:** follow the agent's acceptance facts for the mode (`In a worktree` or `On a branch`, §5.1), then copy
   the plan's acceptance checklist into the report.
7. **Report, then stop.** Its shape, which the orchestrator verifies: tasks done n/N with commit hashes; each gate
   with pass/fail counts; every deviation and why; every `quartz:` line; the acceptance output (e.g. URLs); anything
   left for the owner.

### 2.3 Never, in either mode

Switch branches, stash, reset, rebase, merge, push or tag; tick the plan; invoke `finishing-a-development-branch`;
start a live `claude -p` or `opencode run` session, install or uninstall a plugin, or add a marketplace; call a real
third-party API or use real credentials (tests use fakes); touch anything outside the checkout (`~/.claude/`,
`~/.config/opencode/`, other repos, other worktrees). Never wait with a self-matching `pgrep`, never `pkill -f` a
pattern in its own command line; stop a server it started by its PID. Read files in targeted ranges and pipe long
output through `tail` or `grep`.

### 2.4 Branch mode adds

- Untracked files under `docs/superpowers/` that the executor did not create are the orchestrator's: never stage,
  edit, move or delete them. A "the tree is clean" check ignores them.
- If a git command fails on `index.lock`, wait a second and retry once.
- Quartz may print that a task "ticks at the next drain" because the main checkout is on this branch (§8). That is
  expected; report it like any `quartz:` line.

## 3. The orchestrator's half (`skills/executing-plans/dispatching.md`)

For one plan. A branch run is active exactly when **the main checkout is not on `main`**; nothing else needs
remembering.

### 3.1 The steps

1. **Handoff.** Always a stop for the owner's answer (the phase gate). Read `execute:` from the header of
   `.hyper-relay/agents.md`, if there is one.
   - With a default: "Plan ready at `<path>` (N tasks). Running it on a **branch** (this repo's default). OK, or
     worktree?" (or the same with worktree).
   - Without: "Plan ready at `<path>` (N tasks). Where should the executor run? 1. **Branch**: this checkout, a new
     branch; you click through on your normal stack; new specs and plans stay uncommitted until it merges. 2.
     **Worktree**: its own worktree; nothing held back, can run beside a branch run; worktree setup, and a `wt`
     stack for an app."
   - Warnings, where they apply: Branch means task ticks arrive at the merge, not live; in a repo with a `.wt.conf`,
     Branch runs on the owner's normal stack and database. **Branch is not offered while a branch run is active**;
     the handoff says so and offers Worktree.
2. **Preconditions.** Branch: the main checkout is on `main`, with no `MERGE_HEAD` and no tracked changes
   (untracked files are fine). Worktree: the worktree is cut from `main`; the main checkout may be on a branch run.
   The plan is committed on `main`. A plan that is not (gitignored, or held back during a branch run) is passed to
   the executor by absolute path, and **step 4 never runs `quartz link-branch` for it**: Quartz would resolve the
   main checkout's current branch, which during a branch run is the other plan's (§8). Its card is moved by hand.
3. **Setup.** The branch is the plan's file name without its date and `.md`
   (`2026-11-17-hyper-relay-c-executing-plans.md` → `hyper-relay-c-executing-plans`).
   - Branch: `git switch -c <branch>` in the main checkout.
   - Worktree: check that `.worktrees/` is gitignored, then `git worktree add .worktrees/<branch> -b <branch> main`.
     The orchestrator never enters the worktree (no `EnterWorktree`): it runs commands there as
     `(cd <worktree> && …)` or `git -C <worktree> …`.
4. **Link** (when the plan or its spec names a card). A committed plan: `quartz link-branch <plan path>`, run where
   the branch is checked out, with the plan's path inside that checkout. An uncommitted plan, or a failed link: move
   the card to In progress through the Quartz MCP and say so.
5. **Dispatch** one executor in the background: `<project>-executor` when the repo has generated agents, otherwise a
   general-purpose agent whose first instruction is to invoke `hyper-relay:executing-plans`. The prompt carries §2.1.
   Then tell the owner it is running, and carry on with other work. Where the harness cannot run a subagent in the
   background, the dispatch waits for it; every rule below still holds.
6. **While a branch run is active** (§3.2).
7. **Verify the hand-back** before relaying anything: rerun the gates the report names where the branch is checked
   out; check the commits (count, `Plan-Task:` trailers) and that the tree is clean (held-back docs aside); weigh
   every deviation; act on
   every `quartz:` line. Then `quartz review` (cards to In review); if it fails, move the cards by hand. Tell the
   owner only failures, gate results, deviations and decisions; the board shows the rest.
8. **Click-through and merge.** The owner clicks through: on the normal stack after the `On a branch` acceptance
   steps, or on the worktree's `wt` stack. The owner decides the merge through `finishing-a-development-branch`,
   which handles both: for a branch, check out `main`, merge, delete the branch; for a worktree, merge, then remove
   the worktree (and stop its `wt` stack first when it has one).
9. **After a branch merge,** commit the held-back specs and plans on `main`, staged by name, so the hooks upload
   them. Queued ticks drain at the next stop.

### 3.2 The hold-back rules (while a branch run is active)

- **Create new files only.** Do not edit a tracked file: an edit can block the later `git switch main`, and it
  would share the executor's working tree. An edit waits for the merge.
- **Write specs and plans, do not commit them.** `quartz link-doc <path>` puts them on their cards meanwhile.
  `brainstorming` and `writing-plans` enforce this themselves (§4.2, §4.3), and B's planner already does.
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit`, `merge`. Read-only git runs with
  `GIT_OPTIONAL_LOCKS=0`, so `git status` never holds `index.lock` while the executor commits.
- A second plan can only run in a worktree.
- Code read during brainstorming may be the branch's half-finished work.

## 4. Changes to other skills and docs

### 4.1 Deleting `subagent-driven-development`

- Delete `skills/subagent-driven-development/` (its `SKILL.md` and three prompt files).
- Delete its live tests: `tests/subagent-driven-dev/`, `tests/claude-code/test-subagent-driven-development.sh` and
  `test-subagent-driven-development-integration.sh`, and every prompt and script in `tests/explicit-skill-requests/`
  that exists to test it; the runners (`tests/claude-code/run-skill-tests.sh`, `tests/explicit-skill-requests/run-all.sh`)
  stop listing them, and a runner left with nothing to run is deleted. `docs/testing.md` and
  `tests/claude-code/README.md` lose their sections on it.
- Re-point the mentions: `dispatching-parallel-agents`' description ("For executing an approved plan, use
  executing-plans"); `requesting-code-review` loses "After each task in subagent-driven development";
  `voice-to-specs` line 281 names `executing-plans`; `render-graphs.js`' usage examples use `../brainstorming`.
- `README.md`: the relay table's Execute row names `executing-plans`, `using-git-worktrees` and
  `test-driven-development`, handing over "commits, one per task, on a branch or in a worktree". `CLAUDE.md`: the
  skill count (16) and the Layout's list of live suites.
- Untouched, as records: `docs/upstream/`, `docs/plans/`, `RELEASE-NOTES.md`, A's spec and plan, and the retired
  `scripts/check-import.sh`.

### 4.2 `writing-plans`

- The header line for agentic workers names `executing-plans` only ("the executor preloads it").
- Line 16's "created via using-git-worktrees at execution time" becomes: the orchestrator sets up the branch or
  worktree at the handoff (`executing-plans`' `dispatching.md`); a plan names neither the mode nor a path.
- The `quartz link-branch` first step (lines 69–71) and the `quartz review` click-through step (line 77) go: the
  orchestrator runs both (C10).
- "Execution Handoff" (upstream's two options) becomes: after saving the plan, report and stop; the orchestrator
  runs the handoff in `dispatching.md`.
- The commit rule (C11) wherever the skill commits (the plan, and line 27's spec update): only when the main
  checkout is on `main`; otherwise `quartz link-doc <path>` and leave the commit to `dispatching.md` step 9.

### 4.3 `brainstorming`

Checklist item 7 and "Commit the design document to git" gain C11: commit on `main`; when the main checkout is on
another branch, run `quartz link-doc <spec>` instead and leave the commit for after the merge. The user-review line
then says "written" rather than "written and committed".

### 4.4 `using-git-worktrees`

Its description drops "or picks the worktree option at a plan-to-execute handoff". An executor's worktree is created
by `dispatching.md` with `git worktree add` and never entered; `EnterWorktree` would move the orchestrator into it.

## 5. B's templates, generator and facts

### 5.1 `templates/agents/executor.md`

The general rules (Where, Token budget, Constraints, Committing, Report) move into §2. What stays:

- Frontmatter: `name`, `model`, `disallowedTools: Agent`, `skills: hyper-relay:executing-plans`. The description
  says it executes one approved plan for `{{project}}` ({{root}}) "on the branch it is given, in the main checkout or
  its own worktree".
- A short intro: follow the preloaded skill; the dispatch prompt gives the plan, the mode, the checkout and branch.
- `## Setup` with `{{slot executor/setup}}`; `## Full gates (once, at the end)` with `{{slot! executor/gates}}`;
  `## Constraints` with `{{slot executor/constraints}}`.
- `## Acceptance`, with `### In a worktree` / `{{slot executor/acceptance-worktree}}` and `### On a branch` /
  `{{slot executor/acceptance-branch}}`.

### 5.2 `templates/agents/planner.md`, "Every plan's Execution notes carry"

- "Work in `.worktrees/<branch>` … the first task starts with `quartz link-branch`" becomes: the executor works where
  the dispatch prompt says; a plan names no mode, path or `cd` prefix, and carries no Quartz step.
- "Outside the worktree is not the executor's" becomes "outside the executor's branch": `main`, another repo, the
  owner's config, GitHub, real credentials, live sessions.
- The acceptance bullet drops "the executor runs `quartz review`": the orchestrator does (C10).

### 5.3 The generator

- Header key **`execute`**, value `branch` or `worktree`, optional; any other value is an error. The unknown-key
  message lists it. The generator only validates it; `dispatching.md` reads it.
- The slot names `executor/acceptance-worktree` and `executor/acceptance-branch` replace `executor/acceptance`. A
  facts file still using the old name gets B's "matches no slot" error.
- A `### ` heading left with no content is dropped like a `## ` one (B's D6), so an executor without branch facts has
  no empty `### On a branch`, and `## Acceptance` disappears when both are missing.
- **The restart line.** When a run writes at least one agent (`written`, with or without `--force`), its output ends
  with one line: "Start a new session to use them: a running session keeps the agent definitions it loaded." A run
  that writes only the guard, or nothing, does not print it. `skills/agents/SKILL.md`'s "Run the generator" step
  says the same (§8). It replaces B's assumption that an existing `.claude/agents/` folder needs no restart.
- `tests/hyper-relay-agents/run-tests.sh` gains cases for each of these (§7.1).

### 5.4 Facts files

- hyper-relay's `.hyper-relay/agents.md` gains `execute: branch` (C9).
- SAT's (written by B's Task 7) gains `execute: worktree`, and its `executor/acceptance` section is renamed
  `executor/acceptance-worktree` (§7.2).

## 6. OpenCode

The skill is plain Markdown and works the same there. B's `skills/agents/opencode.md` already has an adapted
executor load `executing-plans` first. Whether OpenCode runs a dispatched subagent in the background is not
documented; if it waits instead, the hold-back rules are trivially kept, but the owner cannot brainstorm meanwhile.
§7.2 records what happens.

## 7. Testing and acceptance

### 7.1 Checks the executor runs

- `claude plugin validate .` passes; its warnings are the known two (the root `CLAUDE.md`, `ICON_MISSING`). The skill
  count is 16.
- `tests/hyper-relay-agents/run-tests.sh`: `execute: branch` and `execute: worktree` accepted; another value refused;
  `executor/acceptance` refused as matching no slot; each acceptance slot rendered under its `###` heading; an absent
  one leaves no heading; both absent leave no `## Acceptance`; the restart line follows a run that writes an agent and
  is absent from a run that writes nothing; hyper-relay's own facts file renders, and `--check` is silent after
  generation. `tests/hyper-relay-agents/guard-test.sh` and `tests/add-card-line/run-tests.sh` unchanged
  and passing.
- `git grep -n subagent-driven` finds only the records listed in §4.1.
- `dash -n` on every `#!/bin/sh` script touched.

### 7.2 The last task: the orchestrator with the owner, after the merge

1. Re-run §7.1 on `main`; push `main`; the owner reinstalls (`claude plugin install hyper-relay@hyper-relay`). The
   version stays 0.1.0.
2. **The session-start notice, for real.** The executor and planner templates changed, so a new session in
   hyper-relay and in SAT reports their agents out of date. Update SAT's facts file (§5.4) and commit it there by
   name; regenerate both repos; diff each executor and planner against its backup with the owner.
3. **The owner's `~/.claude/CLAUDE.md`:** the "Plan → Execute handoff" section (the three options, the lookup table,
   the per-task paragraphs) becomes a pointer to `hyper-relay:executing-plans`' `dispatching.md`; the Quartz bullet
   "Two steps stay manual, and the plans carry them" says the orchestrator runs them; the Worktrees section says an
   executor runs on a branch or in a worktree per the repo's `execute:` key.
4. **Live probe, in a throwaway repo without Quartz,** with a 2-task toy plan. Branch mode: a fresh executor runs it
   while the orchestrator writes a spec in the same checkout. PASS: the commits are on the branch only, with their
   trailers; the spec is untouched and uncommitted until the merge, then committed on `main`. Then the same plan in
   Worktree mode. PASS: the main checkout never leaves `main`.
5. **OpenCode (owner):** dispatch the toy plan's executor from OpenCode in Branch mode; record whether it ran in the
   background.

## 8. External facts (checked 2026-11-17)

- **`wt`** (`~/.claude/bin/wt`, `locate_worktree`, line 37): in a main checkout it dies with "this is a main checkout,
  not a worktree; wt only runs inside a worktree".
- **Quartz** (`~/.local/bin/quartz`): `link-branch` "link[s] the current branch to a plan" and refuses with "on main:
  create a branch before linking a plan". Observed on B: run from B's worktree with B's gitignored plan's absolute
  path, it refused, so it finds the repo from the plan's path, not the working directory. The post-commit tick hook,
  when the main checkout is on another branch, prints "main is on <branch>; task <N> ticks at the next drain", and
  `quartz hook flush` (Stop/SubagentStop) drains it later. `quartz link-doc` uploads a doc that is not committed (B's
  gitignored plan, 2026-11-17).
- **A running Claude Code session keeps the agent definitions it loaded** (observed 2026-11-17, B's Task 7 Step 5):
  `relay-planner.md` was regenerated at 22:11 to call `.claude/hooks/hyper-relay-planner-guard.py` (prefix
  `planner guard:`); a `relay-planner` dispatched afterwards from the same session was refused with
  `sat-planner guard:`, the prefix of the hand-written definition's guard, `~/.claude/hooks/sat-planner-guard.py`.
- **B's planner template**, Committing step 1: `git -C {{root}} branch --show-current` must print `main` and
  `MERGE_HEAD` must not exist, or the planner does not commit.
- **git:** `git switch` carries untracked files across unless the target branch tracks the same path;
  `GIT_OPTIONAL_LOCKS=0` makes `git status` skip its optional index refresh, which takes `index.lock`; a commit while
  another process holds `index.lock` fails with "Unable to create '…/index.lock': File exists".
- **`finishing-a-development-branch`**, Steps 2 and 6: a normal checkout on a named branch gets the standard four
  options; Option 1 checks out the base, pulls, merges and deletes the branch; only a worktree under `.worktrees/` is
  removed.

## 9. Out of scope

Several plans at once, stacking dependent plans, migration and shared-file conflict checks, and handing the owner a
stack to click through (D); moving `wt` into the plugin (its own card); changing Quartz (its tick queue, or
`link-branch` for a plan outside the checkout); generating OpenCode agents; a per-task review loop of any kind.

## 10. Plans

One plan, `docs/superpowers/plans/YYYY-MM-DD-hyper-relay-c-executing-plans.md`, written after B merges. C's own run
uses today's process in Worktree mode, as B's did, since branch mode's rules exist only once C merges. §7.2 is its
last task, run by the orchestrator with the owner after the merge.
