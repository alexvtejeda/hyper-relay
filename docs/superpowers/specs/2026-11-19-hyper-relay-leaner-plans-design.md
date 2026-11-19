# hyper-relay: leaner plans, from upstream's writing-plans 6.0–6.4.2 (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19
**Card:** writing-plans: leaner plans, from upstream's 6.0–6.4.2 changes (`ce88b594-e143-4388-92ca-08037a2acd14`)
**Initiative:** v0.1.0
**Scope:** this repo: `skills/writing-plans/`, `skills/executing-plans/SKILL.md`, `skills/orchestrating/planning.md`
and `dispatching.md`, `skills/agents/SKILL.md` (one table cell), `templates/agents/planner.md`, `.hyper-relay/agents.md`.
One plan. Released as 0.2.1.

## Goal

Planners are the relay's largest cost per plan. Our last seven plans run 4 to 10 times their spec's length, and 16
to 65 percent of their lines are code blocks (the code-heavy ones, D.2's `relay-merge` and G.2, over half). G.2's plan is 2,348 lines for a 236-line spec (1,542 lines of code
blocks); its planner made 106 API calls and wrote 364,134 output tokens in 56 minutes, about ten times the plan's own
size (147 KB, roughly 37k tokens). The planner is read-only: it works out, on paper, code it can never run. The executor, which can run it, then
copies it (G.2's executor "copied code blocks with sed -n").

Upstream superpowers 6.4.2 (#2333) made plans record decisions, not code, and reports plans in a quarter of the time
and about a third of the tokens, with execution unchanged (9/9 against planted-defect probes on Sonnet 5). This spec
brings that into the relay, keeps what is ours, and proves on G.2's own spec that a leaner plan still builds the
right thing.

## Decisions (owner, 2026-11-19)

| # | Question | Decision |
|---|---|---|
| LP1 | How is the upstream port split? | **Five cards, one spec each, brainstormed one after another; plans may run at once.** This card (writing-plans) first, then brainstorming (`a5a66906`), then the rest: small fixes (`6ad2f229`, widened by its note of 2026-11-19), review and TDD rules (`5441ce1c`, new), visual-companion (`e3303d7a`). No two cards touch the same file. writing-plans goes first so its planner writes the others' plans, and so the saving is measured before the benchmark. |
| LP2 | Who writes the exact words of a skill? | **The plan, in full, wherever the words are the product:** skill files, docs, and messages a person or agent reads. Code, scripts and tests go lean. Skill text is behaviour, and the planner writes it on Opus with the spec in front of it. |
| LP3 | How does acceptance prove leaner plans still work? | **Skill tests, plus a re-plan of G.2's spec with the new text, executed in a scratch worktree** and checked the way G.2's acceptance was (§8). |
| LP4 | What does the executor do where a lean plan leaves a choice open? | **Makes the reasonable call and lists it in its report.** It stops only when a step contradicts the spec or another step, needs a fact the plan should have given, or cannot be done (§5). |
| LP5 | What do a plan's Execution notes carry? | **Only what is particular to the plan, plus the spec's project-wide values copied verbatim** (upstream's Global Constraints). The standing rules live in `executing-plans` and are not repeated (§2.6, §4). |
| LP6 | What is left of "How this was checked"? | **One line:** the commit the plan was written against, read-only, nothing run. External facts stay, with their URL and date, quoting only what decides something (§4). |
| LP7 | Does every task get an Interfaces block? | **No: only a task whose names or types a later task uses.** Upstream needs one on every task because each of its implementers sees only its own task; ours reads the whole plan. |
| LP8 | Does `plan-document-reviewer-prompt.md` go, as upstream's did? | **No.** Stop 3's optional plan review uses it. It is updated to the new step rules (§3). |

## 1. What changes where

| File | Change |
|---|---|
| `skills/writing-plans/SKILL.md` | The reader, task and step sizing, Review Focus, Execution notes, What a Step Contains, the self-review (§2) |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Its checks follow §2 (§3) |
| `templates/agents/planner.md` | No full code; one-line "How this was checked"; older plans are not the model for steps; the boilerplate Execution-notes bullets go (§4) |
| `.hyper-relay/agents.md` | The `planner/plan-format` slot gets the same guard about older plans (§4) |
| `skills/agents/SKILL.md` | The slot table's cell for `planner/execution-notes` names the renamed heading (§4) |
| `skills/executing-plans/SKILL.md` | Write what a step specifies; open calls are the executor's, and reported (§5) |
| `skills/orchestrating/planning.md`, `dispatching.md` | Stop 3 reports the plan's length against the spec's; the executor's calls are weighed like deviations (§6) |

## 2. `skills/writing-plans/SKILL.md`

### 2.1 The reader

The Overview's first two paragraphs ("zero context for our codebase and questionable taste", "don't know good test
design very well") are replaced by upstream's reader: an engineer who has not seen this codebase or this spec, who
writes idiomatic code in the project's language once they know the exact interface and the exact test, and who makes
a reasonable choice wherever the plan leaves one open. What they cannot know is what the planner decided: which files,
which names and signatures, which values from the spec, which tests prove each task. The plan documents those.

The announce line, the Context paragraph and "Save plans to" stay.

### 2.2 Sizing

"Bite-Sized Task Granularity" (each step "2-5 minutes") is replaced by two short sections:

- **Task right-sizing.** A task is the smallest unit that carries its own test cycle and its own commit, with its
  `Plan-Task:` trailer. Setup, configuration, scaffolding and documentation fold into the task whose deliverable needs
  them. Split only where one task's result can be checked without its neighbour's. Each task ends with something
  testable on its own.
- **Step granularity.** Each step is one action with a checkable result. The five-step example list (write the
  failing test, run it, implement, run again, commit) stays.

### 2.3 Review Focus

A new section, which the plan carries after its header and before its first task: up to five input classes or failure
modes that the spec implies but no task's tests exercise, most likely to bite a person using the software first, one
line each naming the input or condition and the behaviour a reasonable person would expect. The spec is a vision
document: its silence on an input is not permission for that input to break the program. Each line's test is added to
the task that owns the code, in that task's own step style. An empty section means the planner checked and found
none, not that it skipped the check.

### 2.4 The task structure

The example task keeps its Files block, its five steps and its commit with the `Plan-Task:` trailer, and changes in
two places:

- An **Interfaces** block (Consumes, Produces: exact names, parameters and return types) follows Files, marked as
  present only when a later task uses what this one makes (LP7).
- Step 3 becomes "Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`", with one line on
  the approach when the signature and the test leave a choice, and a code block only for an algorithm they do not
  determine.

The rule now in "Remember" that the final commit of each task carries the trailer, and only that commit, moves beside
the example.

### 2.5 What a Step Contains

Replaces "No Placeholders" and "Remember". A step is done when the executor can write exactly one reasonable thing from
it: unambiguous, not complete. Each kind of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the file it lives in, and the values the spec
  pins. The executor writes the body. A body appears only for an algorithm the signature and tests do not determine.
- **A text step:** the exact text, in full, with where it goes, wherever the words are the product: a skill file or a
  file beside it that agents read, a doc, a message a person or an agent reads, a config value (LP2). "Create X with
  exactly this content" and "replace X with Y" stay the forms for these.
- **A verification step:** the command, and the output that means it passed.
- **A reference to another task:** that task's Interfaces block, not a copy of its code.

A plan longer than the code it describes has written the code instead. Lines that decide nothing ("TBD", "TODO",
"implement later", "fill in details", "handle edge cases", "add appropriate validation", "write tests for the above",
"Similar to Task N", a type or function no task defines) are the opposite failure. The self-review catches both.

### 2.6 Execution notes

A new short section saying what a plan's Execution notes carry: what is particular to this plan (a command not to run,
a file's quirk, a suite that is the contract) and the spec's project-wide values (version floors, dependency limits,
naming and copy rules, exact values), copied verbatim. They do not repeat the executor's standing rules, which
`hyper-relay:executing-plans` holds: where it works, how it commits and with which trailers, the never list, targeted
checks per task and the full gates once (LP5).

### 2.7 The self-review

The checklist becomes:

1. **Spec coverage** (unchanged).
2. **Step scan** (replaces the placeholder scan): every step lets the executor write exactly one reasonable thing, and
   carries no more than that. A line that decides nothing is a gap; a body the signature and tests already determine
   is a transcript. Fix both. Text steps keep their text in full.
3. **Type consistency** (unchanged).
4. **Review Focus:** for each input class or failure mode the spec implies, a task's tests exercise it, or it is in
   Review Focus with its test added to the owning task.
5. **Proportion:** compare the plan's length with the spec's. When code blocks are most of the plan, replace bodies
   with signatures, test names and assertions, and check each step is still unambiguous. Text steps do not count
   against the plan here.

### 2.8 Unchanged

Scope Check, the spec's plan count, stacked plans, renumbering, File Structure, the header block, no Quartz steps,
Spec coverage and the acceptance task, skill tests, committing the plan, and after saving the plan.

## 3. `skills/writing-plans/plan-document-reviewer-prompt.md`

Its check table follows §2:

- **Placeholders** becomes **Step contents**: a step that decides nothing; a code body the signature and tests already
  determine; a text step (skill, doc, message) that does not give its text in full.
- New, advisory: **Review Focus** (present; each line has its test in the owning task) and **Proportion** (the plan's
  length against the spec's, and the share of code blocks).
- **Execution notes** checks that they carry what is particular to the plan and the spec's project-wide values, and do
  not repeat the executor's standing rules.

The other rows, the calibration and the output format stay.

## 4. The planner agent template and the relay's slot

`templates/agents/planner.md`:

- **Before writing, the plan-format bullet:** "**How this was checked** (list every file you read)" becomes a one-line
  **How this was checked**: the commit the plan was written against, read-only, nothing run (LP6). "tasks with FULL
  code" becomes tasks written as `hyper-relay:writing-plans`' What a Step Contains says. "Mirror the newest plans in
  `docs/superpowers/plans/` for format" gains: plans there written before this format carry full code; take their
  header and acceptance task as models, never their steps.
- **How you work:** "Write for the executor: put the full code in each task so execution is transcription plus
  targeted tests" becomes: write for the executor the decisions it cannot make alone, as What a Step Contains says.
  The External facts bullet keeps URL and date, and quotes only what decides something.
- **"Every plan's Execution notes carry"** becomes **"Every plan"**. Its bullets on where the executor works, on
  commits and trailers, on `pgrep`, on the token budget and on the acceptance task go: `executing-plans` and
  `writing-plans` hold them. "Outside the executor's branch is not the executor's" stays, as a rule for writing the
  plan (mark such a step the owner's or the orchestrator's, with exact commands and exact text). The
  `{{slot planner/execution-notes}}` stays under the heading.
- `skills/agents/SKILL.md`'s slot table names the heading: its `planner/execution-notes` row says
  "Every plan".

`.hyper-relay/agents.md`, the `planner/plan-format` slot: "The model is the newest hyper-relay plan in
`docs/superpowers/plans/`" gets the same guard: its header and acceptance task, not its steps.

SAT's `.hyper-relay/agents.md` is left alone: its `planner/execution-notes` slot repeats what its executor slots
already say, which is SAT's call. Stop 4 mentions it.

## 5. `skills/executing-plans/SKILL.md`

- **Process step 2:** "A step that is unclear or impossible means stop and report, never guess" becomes: a choice the
  plan leaves open (how to write a body, which helper or library call) is the executor's; make the reasonable one and
  list it in the report. Stop and report only when a step contradicts the spec or another step, needs a fact the plan
  should have given (a value, a behaviour, a name another task uses), or cannot be done (LP4).
- **Process step 3:** "Follow its steps exactly, transcribing the plan's code" becomes: write exactly the text a step
  gives (file contents, skill text, messages); write code to the step's signature and make its tests pass.
- **The report** (step 7) gains a line: the calls you made where the plan left a choice open, one line each.

The rest of the file stays.

## 6. `orchestrating`

- **`planning.md` §3, stop 3's report:** a line per plan, "plan N lines for an M-line spec", from `wc -l` on both.
- **`dispatching.md`, the hand-back check:** "Weigh every deviation the report lists" also weighs every call the
  executor lists: accept it, or tell the owner why not.

## 7. Pressure scenarios

Each runs on Sonnet against `main`'s text and the branch's (the standing `skill-test` leg, `reviewing.md`). The plan
writes each as a `skill-test` step with its situation in full.

| # | Who | Situation | GREEN (the branch's text) | RED (`main`'s text) |
|---|---|---|---|---|
| S1 | planner | A spec needs a POSIX shell function that turns a plan path into its branch name, with two cases it pins. Write the task. | A test step with the test's name and both assertions; a code step with the signature and file; no function body | The function body in full |
| S2 | planner | A spec adds a rule to a skill's process step. Write the step that changes the skill. | The exact sentence, in full, and where it goes | The same: a guard for LP2, expected not to discriminate |
| S3 | planner | A spec for a transcript reader names the transcripts it reads but never says what happens with an empty one. Write the plan's sections before Task 1, and Task 1's test step. | A Review Focus line for the empty transcript, and its test in the task that owns the reader | No Review Focus line, no such test |
| S4 | planner | Write a plan's Execution notes for a plan in a repo whose executor skill already holds the commit, trailer and never rules. The situation also gives the planner agent file, rendered from each side's template (the one scenario whose text lives outside `skills/`). | Only notes particular to the plan, plus the spec's values | Repeats the commit, `Plan-Task:`, attribution and `pgrep` rules |
| S5 | executor | A step gives a function's signature and its tests, not how to write it; two ways would pass. | Picks one, writes it, lists the call in its report, carries on | Stops and reports the step as unclear |
| S6 | orchestrator | A planner has handed back a 900-line plan for a 300-line spec, and the checks pass. Write stop 3. | The report has "plan 900 lines for a 300-line spec" | No such line |

## 8. The G.2 probe

A `skill-test` step the orchestrator runs after acceptance, beside the code review and the scenarios. Its RED is not
run again: it is G.2's own run, already measured.

**The baseline.** G.2's plan at `d15d61e`: 2,348 lines, 1,542 of them in code blocks. Its planner (write only, not the
revision): 106 API calls, 364,134 output, 2,570,760 cache write, 27,026,505 cache read, 55m47s
(`relay-token-measurements`). Its result: `tests/benchmark/run-tests.sh` 90/0, and `run-usage.sh` reproducing D1's
recorded legs, committed as `docs/benchmarks/runs/2026-11-18-d1-relay.md` (`652b9b5`).

**The run.**

1. A scratch worktree at `3aa02ac` (`main` just before G.2's code merged), on a throwaway branch, outside the repo's
   `.worktrees/`.
2. A planner on Opus, as a general-purpose agent: it follows the branch's `writing-plans` and the relay planner agent
   rendered from the branch's template and `.hyper-relay/agents.md`. It plans G.2's spec as committed at `0280260`
   against the code in the worktree, reading only. It writes its plan to the evidence folder, commits nothing and runs
   no `quartz` command. The dispatch quotes the owner's stop-3 answers from G.2's run (its plan's P6, P13, P14,
   P15 and P17 at `3aa02ac`), and never gives it G.2's plan.
3. An executor on Sonnet, as a general-purpose agent: it follows the branch's `executing-plans` and the relay executor
   agent rendered the same way, in the scratch worktree, worktree mode, every task but the acceptance task.
4. The orchestrator checks the result, then removes the worktree and its branch. The evidence stays.

**PASS:**

- the lean plan is under half the original's lines (under 1,174);
- in the worktree, `sh tests/benchmark/run-tests.sh` ends with `0 failed`, and `dash -n` is silent on each script the
  plan wrote;
- the lean-built `run-usage.sh`, run on D1's run log (rebuilt from the committed table's header), gives the same rows
  as `docs/benchmarks/runs/2026-11-18-d1-relay.md`: each leg's calls, tokens and cost.

**Recorded, not a gate:** the lean planner's calls, output, cache write, cache read and duration against the
baseline, and the executor's calls and deviations. Upstream saw a third of the tokens and a quarter of the time. They
go into stop 4's report and the token log.

D1's transcripts expire around 2026-12-18 (Claude Code's 30-day sweep), so the probe runs before then. A failed probe
goes to the owner at stop 4.

## 9. Acceptance and release

- **`reviewer` steps:** `claude plugin validate .` (its three known warnings), `sh tests/hyper-relay-agents/run-tests.sh`
  and `guard-test.sh`, `sh tests/orchestrating/run-tests.sh`; and each changed file read against §§2–6. No new grep
  test: a test that greps a skill for a phrase proves the text, not the behaviour; §7 and §8 test the behaviour.
- **`skill-test` steps:** S1–S6 (§7) and the G.2 probe (§8).
- **The code review** runs as usual, once, last.
- **`after merge`:** release 0.2.1 by the relay's release steps (`.hyper-relay/agents.md`); the push also takes
  `main`'s earlier unpushed commits. The owner's `claude plugin update hyper-relay@hyper-relay` and
  `/reload-plugins`. Agents regenerated with `hyper-relay-agents` in this repo and in SAT (`~/sat.pentraze.com`),
  since the planner template changed. The probe's numbers in the token log. The next real planner run (the
  brainstorming card's) is the first measured in use, and its row goes into the log too.

## 10. Out of scope

- The other four upstream cards (LP1).
- Upstream's Interfaces block on every task, its execution handoff (ours is `orchestrating`'s), and its removal of
  `plan-document-reviewer-prompt.md` (LP7, LP8).
- SAT's `planner/execution-notes` slot (§4).
- A skill-size test (card `6ad2f229`).
