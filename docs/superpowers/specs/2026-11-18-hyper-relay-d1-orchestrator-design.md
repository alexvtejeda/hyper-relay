# hyper-relay D1: the orchestrator's relay loop (design)

**Date:** 2026-11-18 · **Status:** design approved by the owner in chat on 2026-11-18
**Card:** The  orchestrator (`342aada1-4c49-41fc-bd7d-abceda538efe`)
**Initiative:** hyper-relay · **Piece:** D, first half (D1) · **Depends on:** C (merged `ee63e34`)
**Scope:** this repo (a new `orchestrating` skill; `brainstorming`, `writing-plans`, `executing-plans`,
`requesting-code-review` and the skills that point at the handoff; the planner and reviewer templates; README and
`CLAUDE.md`); both repos' generated agents; the owner's global `~/.claude/CLAUDE.md`. One plan.

## Goal

C put the handoff and the executor leg into a skill (`executing-plans`' `dispatching.md`). The rest of the relay still
lives only in the owner's global `CLAUDE.md` and in session memory: no skill dispatches the planner, checks its plan,
dispatches the acceptance reviewer, runs a code review, or says where the owner is asked and where the loop runs on its
own. `brainstorming` still ends by invoking `writing-plans` inline, so a session with only hyper-relay installed writes
the plan itself instead of handing it to a planner.

D1 makes the plugin carry the whole relay for one spec: approved spec → planner leg → plan check → handoff → executor
→ acceptance → code review → the owner's click-through → merge, with four stops for the owner. The owner's global
Workflow section shrinks to a pointer plus their own habits.

## Decisions (owner, 2026-11-17 and 2026-11-18)

| # | Question | Decision |
|---|---|---|
| R1 | How is D scoped? | **Split.** D1 is the relay loop for one spec. **D2** (card `68fab05e-4083-41bf-820f-8c201a951c50`) runs several plans at once: conflict checks, stacking, the preview stack. It is brainstormed after E, because the preview stack rests on `wt`. |
| R2 | What counts as done? | **The plugin carries the whole relay.** With hyper-relay installed and no personal workflow instructions, a session runs the loop with its stops. The owner's Workflow section becomes a pointer plus their habits. |
| R3 | Who checks a plan before the owner reads it? | **The orchestrator, mechanically and inline** (§3.2). Then it **offers** a fresh plan reviewer each time: a general-purpose agent on Sonnet. The owner decides. |
| R4 | What does the review leg run? | **The acceptance reviewer, always,** on the plan's reviewer steps (skipped only when a plan has none). Then **a code review, always, once per branch, last**: after acceptance and its fixes, so it reads the final diff. Sonnet. **Never per task.** |
| R5 | What happens to code-review findings? | **Critical** (must be fixed before the merge) goes back to the executor, after the orchestrator checks it against the code. **Important and Minor** become proposed Quartz cards for the owner to keep or drop; they never block the merge. |
| R6 | Who fixes a FAIL or a Critical finding? | **The executor that ran the plan,** resumed with its context (`SendMessage`). When it cannot be resumed, a fresh executor gets the plan and the findings. A gap in the **spec or plan** goes to the owner first. A step still failing after its second fix round goes to the owner (R9, §5.2). |
| R7 | The small-task off-ramp | **The plugin adopts it, as an experiment,** in one block in `brainstorming` (§6.1): a closed list, and the agent **asks the owner** before skipping the relay. If agents rationalize past it, the owner deletes the block. |
| R8 | Layout | **A new skill, `orchestrating`:** `SKILL.md` (the map) plus one file per leg, `planning.md`, `dispatching.md` (moved from `executing-plans`) and `reviewing.md`. The role skills become single-purpose: `writing-plans` is the planner's, `executing-plans` the executor's, `requesting-code-review` the code reviewer's. |
| R9 | Where is the owner asked? | **Four stops** (§2.2). Between stop 3 and stop 4 the loop runs on its own, except for a spec or plan gap and a second failed fix round. |
| R10 | A spec with several plans | **One planner per plan, in parallel**, as SAT does. The plans then **run one after another**: plan k+1's handoff comes after plan k merges, so it is cut from a `main` that has plan k. Running them at once is D2. |
| R11 | Agents for the two reviews | **No new generated roles.** The plan reviewer and the code reviewer are general-purpose agents given a prompt file; in Claude Code the dispatch sets `model: sonnet`. |
| R12 | D1's own run | **It follows this design by hand,** as the first trial: `relay-planner`, the hand-back check, stop 3, `relay-executor`, `relay-reviewer`, then a Sonnet code review. The stop-4 report gives the reviewers' token counts against the executor's. |

## 1. What changes where

| Where | Change |
|---|---|
| `skills/orchestrating/SKILL.md` | New: the map (§2). |
| `skills/orchestrating/planning.md` | New: the planner leg (§3). |
| `skills/orchestrating/dispatching.md` | Moved from `skills/executing-plans/`, §1–7 unchanged but for pointers (§4). |
| `skills/orchestrating/reviewing.md` | New: the review leg through the merge, taking over `dispatching.md` §8–9 (§5). |
| `skills/brainstorming/SKILL.md` | Hands the approved spec to `orchestrating`; the off-ramp block (§6.1). |
| `skills/writing-plans/SKILL.md`, `plan-document-reviewer-prompt.md` | The planner's skill only; the reviewer prompt updated (§6.2). |
| `skills/executing-plans/SKILL.md` | The executor's only; pointers (§6.3). |
| `skills/requesting-code-review/SKILL.md`, `code-reviewer.md` | One review per branch; the per-task and SDD blocks go (§6.4). |
| `skills/using-git-worktrees/SKILL.md`, `skills/agents/SKILL.md` | Pointers to `dispatching.md` (§6.5). |
| `templates/agents/planner.md`, `reviewer-commands.md`, `reviewer-browser.md` | Plan format, who runs each acceptance step, `index.lock` (§7). |
| `README.md`, `CLAUDE.md` | Say what the repo now does (§8). |
| Both repos' generated agents, the owner's `~/.claude/CLAUDE.md`, SAT's orchestrator memory | The last task, with the owner (§10.3). |

`receiving-code-review`, `verification-before-completion`, `finishing-a-development-branch` and `using-hyper-relay`
are unchanged.

## 2. The map (`skills/orchestrating/SKILL.md`)

### 2.1 Description and role

The description triggers when the session the owner talks to has a spec just approved, finds a spec or plan whose work
is unfinished (after a `/clear` or in a new session), has a plan ready to hand off, or gets a report back from a
planner, executor or reviewer. It says the skill runs the relay from approved spec to merge, and that a dispatched
planner, executor or reviewer never uses it. The body opens the same way: you are the orchestrator; you never write a
plan, execute one or review one yourself; a fresh agent in its own context does each leg.

### 2.2 The legs and the stops

| Leg | File | Ends in |
|---|---|---|
| Design and spec | `hyper-relay:brainstorming` | stops 1 and 2 |
| Planner | `planning.md` | stop 3 |
| Handoff and executor | `dispatching.md` | a verified hand-back (no stop) |
| Review, click-through, merge | `reviewing.md` | stop 4, then the merge |

| Stop | What the owner gets | The owner's answer starts |
|---|---|---|
| 1. Design | The design, section by section (`brainstorming`) | the spec |
| 2. Spec | The written spec (`brainstorming`) | the planner leg: approval is the go-ahead, no second ask |
| 3. Plan ready | The hand-back check's result, the planner's deviations, the decisions the owner must make, the plan-review offer, the handoff question (§3.3) | execution, a plan review, or plan changes |
| 4. Ready to merge | Gate and acceptance results, fixes made, Critical findings fixed or dropped, proposed cards (§5.4) | the click-through and the merge |

A stop ends the message: the next leg never starts in the message that reaches a stop. Read each leg's file when the
loop reaches that leg, not before.

### 2.3 Finding where work stands

After a `/clear` or in a new session, find the leg from files and git, never from memory. With Quartz, the card's
column is a cross-check.

| State | Leg |
|---|---|
| A spec that no plan's `**Spec:**` line names | Planner leg. Never brainstorm it again. |
| A plan with no branch of its name, and no `Plan-Task:` commits for it on `main` | Stop 3 (the owner has not approved it yet) or the handoff, by what the owner says |
| A plan's branch with some of its tasks committed, and no executor report in this session | **Ask the owner** whether its executor is still running elsewhere. Two executors on one branch collide. |
| A plan's branch with all its executor tasks committed | `dispatching.md` §7 (verify), then `reviewing.md` |
| The branch merged, with an after-merge step of the plan's acceptance task left | `reviewing.md` §5.5 |

The branch name comes from the plan's file name (`dispatching.md` §3). A branch run is active exactly when the main
checkout is not on `main`.

### 2.4 Quartz duties

Moved from the owner's global `CLAUDE.md`. Each falls back to plain Markdown and git without Quartz.

- Every spec and plan carries its card line in its header (`add-card-line.sh`; full UUIDs only).
- A spec or plan is committed only while the main checkout is on `main`; during a branch run, `quartz link-doc <path>`
  and commit after the merge.
- `quartz link-branch` at dispatch and `quartz review` after verifying the hand-back (`dispatching.md`).
- A `quartz:` line printed by a commit is the only Quartz output to act on: do what it says.
- **Don't report what the board shows:** never list done tasks, tick counts or per-task commits. Report failures, gate
  results, deviations and the decisions the owner must make.
- The proposed cards the owner keeps are added through the Quartz MCP (§5.4).

### 2.5 Fallbacks

- **No generated agents** (`.claude/agents/<project>-planner.md` and the rest): offer `hyper-relay:agents` first. If
  the owner declines, each leg dispatches a general-purpose agent told to invoke its skill (`writing-plans`,
  `executing-plans`); the acceptance reviewer, which has no skill, gets the standing brief in `reviewing.md` (§5.1).
- **Models:** the generated agents carry their own. The plan reviewer and the code reviewer run on Sonnet in Claude
  Code (`model: sonnet` on the dispatch); in OpenCode, the `general` subagent's configured model.
- **Resuming an agent** with its context uses `SendMessage` where the harness has it. Otherwise, or when the agent is
  gone, a fresh agent gets what it needs in its prompt.
- **No background agents** (a harness that waits for a subagent): every rule still holds; the owner just cannot work
  meanwhile.

## 3. The planner leg (`skills/orchestrating/planning.md`)

### 3.1 Dispatch

Straight after the owner approves the written spec, in the background. Then tell the owner it is running and carry on.

- **Plan paths:** the orchestrator names them: `docs/superpowers/plans/<today>-<topic>.md`, where `<topic>` is the
  spec's file name without its date and `-design`. A spec with `**Plans:** n` gets n paths, each with a suffix the
  spec gives its part (`-api`, `-web`), in the spec's order. The branch for each is its file name without the date
  (`dispatching.md` §3).
- **One planner per plan,** in parallel: `<project>-planner`, or the fallback (§2.5) told to invoke
  `hyper-relay:writing-plans` and that it may only read code and write its plan file.
- **The prompt gives:** the spec's path (absolute when it is not committed on `main`); the plan path and branch; the
  sibling plans' paths and branches, and that the spec's contract between them binds; the commit message and the
  attribution lines; the Claude-Session URL; anything unusual. During a branch run that includes: read `main`'s code
  with `git show main:<path>`, and the plan will not be committed (the planner's own check refuses).

### 3.2 Check the hand-back

Inline, with git and grep, before the owner sees anything:

1. The plan is committed on `main` (`git log -1 --format=%h main -- <plan>` prints a commit), or, during a branch run,
   the file exists and is on its card through `quartz link-doc`.
2. Its header has a card line, or inherits one through a `**Spec:**` line naming the spec.
3. Each task with a commit step carries its own `Plan-Task: <plan path>#<N>` once, with the plan's own path.
4. The last task is the acceptance task, and each of its steps says who runs it (§7).
5. No placeholder: `grep -n -E 'TBD|TODO|implement later|fill in details|Similar to Task'` finds nothing outside
   quoted text.
6. The plan's **Spec coverage** table (§7) maps every `## ` section of the spec to at least one task.
7. With sibling plans, their **Contract** sections match.

A failed check goes back to the planner (resumed, or fresh with the list) before stop 3. The orchestrator does not read
the whole plan line by line.

### 3.3 Stop 3

The plan path(s) and task counts; the planner's deviations and ambiguities with its resolutions; external facts it
re-verified and any differences; the decisions the owner must make. Then two questions in one message:

- "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the spec."
- The handoff question from `dispatching.md` §1, for the first plan to run.

The answer leads one of three ways:

- **Approve, with a mode** → `dispatching.md` §2 (the answer is the go-ahead; do not ask again).
- **Plan review** → dispatch a general-purpose agent on Sonnet with `writing-plans`' `plan-document-reviewer-prompt.md`.
  Its findings go to the planner, which revises and commits again; then §3.2 and a short stop 3.
- **Changes** → the planner revises (resumed, or fresh with the owner's list) and commits again; then §3.2 and stop 3.

**Only the planner edits a plan.** When the spec's `**Plans:**` count is wrong, the planner reports it; the orchestrator
asks the owner, updates the spec's line itself (committed by C11's rule), and dispatches again.

### 3.4 Several plans

They run one after another, in the spec's order. After plan k merges (`reviewing.md` §5.5), plan k+1 gets its own
stop-3 handoff question, and its branch is cut from the new `main`.

## 4. The handoff (`skills/orchestrating/dispatching.md`)

`git mv skills/executing-plans/dispatching.md skills/orchestrating/dispatching.md`. Its §1–7 keep their text, with
these changes:

- The opening says it is the handoff leg of `orchestrating`, reached from stop 3 (`planning.md`).
- §7 ends: "Then continue with `reviewing.md`." Its last sentence about what to tell the owner stays.
- §8 (click-through and merge) and §9 (after a branch merge) move to `reviewing.md` (§5.4, §5.5).
- Every reference to "this file" or `SKILL.md` beside it is re-pointed: the executor's process is
  `hyper-relay:executing-plans`.

## 5. The review leg (`skills/orchestrating/reviewing.md`)

It starts when `dispatching.md` §7 has verified the hand-back and run `quartz review`.

### 5.1 Acceptance

Dispatch `<project>-reviewer` in the background. The prompt gives: the plan's path and its acceptance task; **the step
numbers marked `reviewer`**, which are the only ones it runs; the checkout and branch; what the executor's report says it
left running (URLs, logins); an evidence folder outside the checkout (the harness's scratchpad when it has one,
otherwise `mktemp -d`).

When the plan has no `reviewer` steps, skip the dispatch and say so at stop 4.

**Fallback brief** (no generated reviewer): a general-purpose agent told: you are report-only; run each named step
exactly as written; for each, give PASS, FAIL or NEEDS-HUMAN with the command, the lines that decide it and the exit
code, quoted; save each step's output in the evidence folder; never edit, commit, install anything or change any config.

**Verify the report:** every named step has a verdict; a PASS without quoted evidence counts as not run and goes back to
the reviewer; rerun one FAIL yourself, where its command is read-only, to confirm it is real.

### 5.2 The fix loop

Sort each FAIL and each BLOCKING finding:

| Kind | Goes to |
|---|---|
| An execution bug: the code does not do what the plan says | The executor (R6). Its prompt: the findings with their evidence, verbatim; the plan, mode, checkout and branch; fix root causes; commit each fix staging named files, with the attribution lines and **no** `Plan-Task:` trailer; rerun the gates; report. |
| A gap in the spec or plan | The owner: fix it on this branch (it goes to the executor as a finding, and the orchestrator records it as a deviation), or a new card |
| PRE-EXISTING, or POLISH | A proposed card (§5.4) |

After a fix: verify it as `dispatching.md` §7 does (the gates, the new commits, a clean tree), then the reviewer
(resumed, or fresh) reruns only the steps that failed. A step that fails again after its second fix round goes to the
owner.

### 5.3 The code review, last

When every acceptance FAIL is fixed, or turned into a card by the owner (NEEDS-HUMAN may remain), dispatch a general-purpose agent on Sonnet with
`requesting-code-review`'s `code-reviewer.md`: the range `$(git merge-base main <branch>)..<branch>`, the plan and the
spec.

- **Critical:** check each one against the code first (`hyper-relay:receiving-code-review`). A wrong one is dropped,
  with the reason, in the stop-4 report. A real one goes to the executor as in §5.2. Then the code reviewer is resumed
  to check only the fix commits (or, when it cannot be resumed, the orchestrator reads that diff), and the acceptance
  reviewer reruns the steps the fix touches (all its steps, when that is unclear).
- **Important and Minor:** proposed cards.

### 5.4 Stop 4, the click-through and the merge

One report:

- the acceptance verdicts, with each NEEDS-HUMAN step listed as the owner's;
- each fix round and what it changed;
- the Critical findings fixed, and those dropped with why;
- the proposed cards, one line each (title, file, why), for the owner to keep or drop;
- the token counts of the acceptance reviewer and the code reviewer against the executor's (R12), until the owner says
  they have seen enough;
- where to click through: on the normal stack once the executor's "On a branch" acceptance steps have run, or on the
  worktree's `wt` stack.

The cards the owner keeps go to Needs brainstorming through the Quartz MCP, kind `bug` or `change`, in the plan's
initiative, each body naming the plan, the file and the evidence. Without Quartz they stay listed in the report.

Then the owner clicks through and decides the merge through `hyper-relay:finishing-a-development-branch` (C's §8 text,
moved here unchanged: a branch is merged and deleted from `main`; a worktree is merged, then removed, after
`(cd <worktree> && wt down)` when it has a stack).

### 5.5 After the merge

C's §9 text, moved here: commit the held-back specs and plans on `main`, each staged by its path. Then run the plan's
`after merge` acceptance steps with the owner. When the spec has another plan, its handoff follows (§3.4).

## 6. Changes to other skills

### 6.1 `brainstorming`

- **Hand over to `orchestrating`.** Checklist item 10, the flow diagram's end node, "The terminal state is …" and the
  "Implementation" section all name `hyper-relay:orchestrating`: after the owner approves the written spec, invoke it;
  its planner leg writes the plan. Do not write the plan, and do not invoke `writing-plans`.
- Line 117's pointer for held-back specs (`dispatching.md`, step 9) becomes `orchestrating`'s `reviewing.md` (§5.5).
- **The off-ramp.** The HARD-GATE's "This applies to EVERY project regardless of perceived simplicity" and the
  "This Is Too Simple" section gain "except an off-ramp case (below)", and one new section follows:

  > **The off-ramp (experiment).** A request may skip the relay (no design, spec or plan) only when it is one of: a
  > typo; a one-line config change; a rename; a single obvious bugfix; a question that changes no files. For any of
  > them except the question, say which case it matches and ask, in a message of its own: "This looks like an
  > off-ramp case (*a one-line config change*). I'd do it directly, with no spec or plan. OK?" Skip the relay only on
  > a yes. When the owner already said to just do it, that is the yes. Anything not on the list, or any doubt, goes
  > through the relay without asking. If the work turns out bigger than one change, stop and take it through the
  > relay.

### 6.2 `writing-plans`

- **Description:** for a planner dispatched to write an implementation plan from an approved spec (the planner agents
  preload it); an orchestrator with an approved spec uses `orchestrating`, which dispatches the planner.
- **The spec's plan count:** "stop and ask the user" becomes: stop and report the mismatch; the orchestrator asks the
  owner and updates the spec (§3.3). The planner never edits the spec (its guard allows plans only).
- The pointers on lines 16, 69, 148 and 153 name `orchestrating` (`dispatching.md`, `reviewing.md`, `planning.md`).
  Line 153: report the path and task count to the orchestrator, and stop.
- **`plan-document-reviewer-prompt.md`** is updated for this plan format: spec coverage (every requirement has a task),
  placeholders, names consistent across tasks, each committing task's `Plan-Task:` trailer, the acceptance task last
  with who runs each step, Execution notes present, external facts cited. Read-only. It reports issues that block
  execution separately from advisory ones.

### 6.3 `executing-plans`

The description and the first body line send an orchestrator to `hyper-relay:orchestrating`, not to `dispatching.md`
beside it. The Integration lines name `orchestrating` as the one that hands the plan over and owns the merge.

### 6.4 `requesting-code-review`

- **Description:** a branch's code review before it merges (in the relay, once per branch and last, run by
  `orchestrating`'s `reviewing.md`), or ad hoc when stuck or before a refactor.
- **When:** mandatory once per branch, after acceptance and its fixes, before the merge; optional when stuck, before
  refactoring, after a complex bug.
- **How:** `BASE_SHA=$(git merge-base main <branch>)`, `HEAD_SHA` the branch's head; a general-purpose agent, with
  `model: sonnet` in Claude Code; the placeholders gain `{SPEC}`.
- **Act on feedback:** Critical is fixed before the merge (in the relay, by the executor, after the orchestrator checks
  it with `receiving-code-review`); Important and Minor become proposed cards, or are noted in the report.
- The per-task example is replaced by a branch example. "Integration with Workflows" loses its Subagent-Driven
  Development and per-task Executing Plans blocks; it keeps two: **In the relay** and **Ad hoc**. Red Flags' "Proceed
  with unfixed Important issues" becomes "Merge with an unfixed Critical issue" and "Drop a finding without recording
  it".
- **`code-reviewer.md`:** takes the spec too, and defines the grades: **Critical**, must be fixed before the merge (a
  bug, a security hole, data loss, a missing spec requirement); **Important**, should be fixed but can wait for a card;
  **Minor**, polish.

### 6.5 Pointers

`using-git-worktrees`' description and `skills/agents/SKILL.md` line 60 name `orchestrating`'s `dispatching.md`.

## 7. Templates

- **`planner.md`, plan format:** a **Spec coverage** table mapping each `## ` section of the spec to task numbers; with
  sibling plans, a **Contract** section, identical in each.
- **`planner.md`, Execution notes:** the acceptance bullet says each step names who runs it: **`reviewer`** (before the
  merge), **`owner`** (at the click-through), or **`after merge`** (the owner and the orchestrator: live sessions,
  reinstalls, edits outside the repo), with its command or action and the result that counts as PASS.
- **`planner.md`, Committing:** if `git commit` fails on `index.lock`, wait a second and retry once (parallel planners
  commit side by side).
- **`reviewer-commands.md` and `reviewer-browser.md`:** the description and "Before you start" step 1 say the reviewer
  runs only the acceptance steps the dispatch names, the plan's `reviewer` steps.
- `executor.md` is unchanged. The generator is unchanged; its tests change only where they assert template text.

Every repo's generated planner and reviewers fall out of date: regenerate, then start a new session (C12).

## 8. Docs

- **`README.md`:** the relay table's Plan row says a planner agent writes the plan; its Review row names the acceptance
  reviewer, `requesting-code-review` (one review per branch) and `receiving-code-review`; a line under the table says
  `orchestrating` runs the legs from approved spec to merge and stops for the owner at four points. The roadmap's D row
  becomes **D1** (the relay loop for one spec: on `main`) and **D2** (several plans at once: planned, after `wt`). The
  status line stops saying later releases add the role agents and the orchestrator.
- **`CLAUDE.md`:** "the 16 skills" becomes 17.

## 9. OpenCode

The skill is Markdown and loads by its bare name. C's probe showed OpenCode returns control while a dispatched
executor runs. Whether OpenCode can resume a finished subagent, or set a model per dispatch, is not documented here: the
planner re-verifies both, and the fallbacks (§2.5) hold either way.

## 10. Testing and acceptance

### 10.1 The executor's gates

- `claude plugin validate .` passes with its known warnings, and the skill count is 17.
- `tests/hyper-relay-agents/run-tests.sh` and `guard-test.sh`, and `tests/add-card-line/run-tests.sh`: `0 failed`.
- `git grep -n -E 'executing-plans.{0,6}dispatching'` over `skills/`, `templates/`, `README.md` and `CLAUDE.md` finds
  nothing; every line `git grep -n 'dispatching\.md' -- skills templates ':!skills/orchestrating'` prints also names
  `orchestrating`; `skills/executing-plans/dispatching.md` no longer exists; `git grep -n -i 'subagent-driven'` over
  the same paths finds nothing;
  `requesting-code-review` has no per-task wording; `brainstorming` has no "invoke writing-plans".
- `skills/orchestrating/` holds exactly `SKILL.md`, `planning.md`, `dispatching.md` and `reviewing.md`, and names no
  path on this machine.

### 10.2 `reviewer` steps, before the merge

`relay-reviewer` runs the checks of §10.1 as written, reads each new file for references to skills or files that do not
exist, and checks every `${CLAUDE_SKILL_DIR}` reference also names its file relative to the skill.

### 10.3 `after merge` steps, the orchestrator with the owner

1. Push `main`; the owner reinstalls (`/plugin install hyper-relay@hyper-relay`, checked in the cache, not the message).
   The version stays 0.1.0.
2. Regenerate hyper-relay's and SAT's agents; show the owner each diff; start a new session.
3. **The owner's `~/.claude/CLAUDE.md`:** the Workflow section becomes a pointer to `hyper-relay:orchestrating` plus
   the owner's habits (the `tasks/todo.md` scratch tracker for off-ramp work that runs to more than a couple of steps,
   a high-level explanation as the work goes); the Quartz section's duties go, now that §2.4 carries them. The exact
   text is shown to the owner before the edit.
4. **Live probes**, in a throwaway repo without Quartz, with a facts file (`execute: branch`, `reviewer: commands`),
   generated agents and a committed toy spec, each in a new session started after the regeneration:
   - **(a) The loop.** "The spec `<path>` is approved." PASS: a planner is dispatched in the background (no plan
     written inline); stop 3 carries the check, the plan-review offer and the handoff question; after "branch", an
     executor; then the reviewer with only the `reviewer` steps; then a code review on Sonnet; stop 4 with token
     counts; "merge it" merges.
   - **(b) The off-ramp.** "Fix the typo 'teh' in README.md": PASS when it asks before editing. "Just fix the typo
     'recieve' in README.md": PASS when it edits without asking. "Add a `--loud` flag to greet": PASS when it starts
     brainstorming, with no off-ramp question.
   - **(c) Resuming.** A committed spec with no plan; "Pick up the probe spec." PASS: it goes to the planner leg, with
     no brainstorming questions.
   - **(d) OpenCode (the owner, with a model they pick):** "The spec `<path>` is approved. Load the orchestrating
     skill and follow it." PASS: it reaches stop 3.
5. Update SAT's `orchestrator-workflow` memory and this repo's handoff memory to point at `orchestrating`.

The fix loop is not forced in a probe; it is recorded the first time it runs for real.

## 11. External facts (checked 2026-11-18)

- **Claude Code's Agent tool** takes a `model` (`sonnet`, `opus`, `haiku`, `fable`) that overrides the agent
  definition's model, and `SendMessage` continues a previously spawned agent with its context (the tool descriptions in
  this session).
- **A running session keeps the agent definitions it loaded** (C12): after regenerating, start a new session.
- **No session-start primer** (A's decision A8): `using-hyper-relay` loads only when something triggers it, so the
  off-ramp lives in `brainstorming` and the relay's entry points are skill descriptions.
- **The installed plugin** (`~/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0`) matched `ee63e34` file for file
  on 2026-11-18; the shell's `claude plugin install` does not refresh it, the in-session `/plugin install` does.
- **Quartz's `add_tasks`** puts cards in Needs brainstorming, with an optional initiative, piece and kind (`bug` or
  `change`).

## 12. Out of scope

Several plans at once, stacking, conflict checks and the preview stack (D2); moving `wt` into the plugin (E); renaming
`docs/superpowers/` (F); a session-start primer; generated agents for the plan reviewer or the code reviewer;
`brainstorming`'s orphaned `spec-document-reviewer-prompt.md`; changing Quartz; a per-task review of any kind.

## 13. Plans

One plan, `docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md`, on the branch
`hyper-relay-d1-orchestrator` (this repo's `execute: branch`). Its run follows this design by hand (R12). §10.3 is its
last task, run by the orchestrator with the owner after the merge.
