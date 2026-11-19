# hyper-relay: leaner plans, from upstream's writing-plans 6.0–6.4.2, Implementation Plan

**Card:** writing-plans: leaner plans, from upstream's 6.0–6.4.2 changes (`ce88b594-e143-4388-92ca-08037a2acd14`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-leaner-plans-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–6 are
> the executor's. Task 7 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Make the relay's plans record decisions instead of code: `writing-plans` takes upstream superpowers
6.0–6.4.2's reader, sizing, Review Focus, Interfaces, "What a Step Contains" and self-review while keeping skill text in
full; the planner template drops its full-code and boilerplate rules; the executor makes, and reports, the calls a lean
plan leaves open; stop 3 reports each plan's length against its spec's; and acceptance proves it with six pressure
scenarios and a re-plan of G.2's spec.

**Architecture:** Text only. Six skill files, the planner template, this repo's facts file and one README cell change,
each by exact replacements, each task checked with greps and the guard suite that reads its files; no code and no new
test (spec §9). Acceptance adds the standing skill-test leg's six scenarios and the G.2 probe: a planner and an executor,
dispatched with the branch's text into a scratch clone of `main` from before G.2's code, checked against G.2's own
results.

**Tech Stack:** Markdown skills and agent templates. `bin/hyper-relay-agents` (unchanged) renders the planner template;
its suites and the relay-skills guard (`tests/orchestrating/`) are the regression checks, with `claude plugin validate .`.
For acceptance: Claude Code general-purpose subagents (Sonnet for the scenarios and the probe's executor, Opus for its
planner), git and jq.

**How this was checked:** written against `main` at `1f2dcfc` by reading only; nothing was built, run, installed or
generated. Read in this repo: `CLAUDE.md` (in full); the spec (in full); `skills/writing-plans/SKILL.md`,
`skills/writing-plans/plan-document-reviewer-prompt.md`, `skills/executing-plans/SKILL.md`,
`skills/orchestrating/planning.md`, `skills/orchestrating/dispatching.md`, `templates/agents/planner.md`,
`templates/agents/executor.md`, `.hyper-relay/agents.md`, `.hyper-relay/merge.conf`,
`docs/benchmarks/runs/2026-11-18-d1-relay.md` (all in full); `skills/orchestrating/reviewing.md` (1–195);
`skills/orchestrating/quartz.md` (1–140); `skills/agents/SKILL.md` (55–94); `bin/hyper-relay-agents` (1–40, 255–571);
`tests/hyper-relay-agents/run-tests.sh` (40–260, 370–394); `tests/orchestrating/run-tests.sh` (1–180); `README.md`
(48–63); G.2's plan (1–270, 2140–2377, the model for this plan's header and acceptance task); D.3's plan (1–175,
1242–1301); D.2 plan 2's (1440–1610, 1794–1883). Read-only git: `git ls-files docs/superpowers/plans`; `git log` of
`main` and of the files this plan touches; `git diff --stat` of `3aa02ac..main`, `0280260..3aa02ac` and
`ed3eb05..3aa02ac`; `git diff 3aa02ac main` of G.2's plan (ticks and its record only); `git show 0280260:` of G.2's spec
(in full); `git show v7.0.2:skills/writing-plans/SKILL.md` (in full) and `git grep` of `v7.0.2:RELEASE-NOTES.md`;
`git grep` of the suites for every phrase this plan removes (none is asserted), of `scripts/bump-version.sh` for its
usage, and of `.claude-plugin/plugin.json` and `package.json` for the version (`0.2.0`); `git rev-parse --git-path
hooks`. Read outside the repo, read-only: `.git/config`, `.git/hooks/post-commit` and `post-merge`, `~/.gitconfig` (no
`init.templateDir`, no `core.hooksPath`), and the auto-memory `relay-token-measurements.md` (in full).

**External facts (re-verified 2026-11-19):**
- **`git clone`** ([git-scm.com/docs/git-clone](https://git-scm.com/docs/git-clone), fetched 2026-11-19): for a local
  path, the default "clones the repository by making a copy of `HEAD` and everything under objects and refs
  directories"; "Specifying `--no-local` will override the default when `/path/to/repo` is given, using the regular Git
  transport instead". `--single-branch`: "Clone only the history leading to the tip of a single branch, either specified
  by the `--branch` option or …". `--no-tags`: tags are not cloned. `--branch` takes a branch name (or a tag), not a
  commit. **Used by** Task 7 Step 14 (P6): the probe's clone holds `ed3eb05`'s history and nothing after it.
- **Quartz's post-commit tick** (D.3's plan, its facts re-verified 2026-11-18 from Quartz's `plantick.go` and
  `installgithook.go`; not re-read here): the hook reads HEAD's `Plan-Task:` trailer and acts when the main checkout, the
  parent of the git common dir, has a configured `.mcp.json`; the hooks sit under the common dir, "so one install covers
  every worktree". This checkout's `.git/hooks/post-commit` is `quartz hook merge-commit || true` (read). **Used by** P6.
- **Upstream** (`git show v7.0.2:RELEASE-NOTES.md`, its v6.4.2 and v6.4.1 sections, and
  `git show v7.0.2:skills/writing-plans/SKILL.md`, read 2026-11-19): 6.4.2 (#2333) "plans took a quarter of the time and
  about a third of the tokens"; "Every plan written by the new skill executed 9/9 against planted-defect probes on Sonnet
  5"; "Removed `plan-document-reviewer-prompt.md`. Nothing referenced it." 6.4.1 (#2319): Review Focus, "up to five
  inputs or failure modes the spec implies but no task's tests exercise". **As spec Goal**; LP8 keeps our reviewer
  prompt on purpose (`planning.md` §3 uses it).

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top. This plan is committed on `main`.
- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator are
  the installed plugin's (0.2.0). This plan rewrites `writing-plans`, `executing-plans`, two `orchestrating` files and
  the planner template: follow your agent instructions and this plan, not the new text.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#<N>` followed, inside the same quoted
  paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and `Claude-Session:` with
  the URL from your dispatch prompt). The commands below write them as `<the line your instructions give>` and `<the
  URL your dispatch prompt gives>`: put the real lines there. Never tick the plan. Report every `quartz:` line a commit
  prints, verbatim.
- **Replacements are exact.** "Replace X with Y" means the Edit tool, with X as `old_string` and Y as `new_string`, each
  exactly the lines of its block in this plan. The fence lines (three or four backticks) are not part of the text, and
  an X that starts mid-line (Task 1 Step 5) matches mid-line. If X is not found, read the range again; if the text moved
  or differs slightly, adapt as little as possible and record it as a deviation; if it is gone, stop and report. Every
  other line of the file stays as it is.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|` (Markdown's escape inside a table): run
  `sh tests/orchestrating/run-tests.sh | tail -n 1`, and `grep -c -E 'a|b'` (alternation); a check that needs a literal
  `|` uses `grep -F` or a basic regex, where `|` is literal.
- **Never run `hyper-relay-agents`** in your checkout, with or without `--force` or `--check`: during a branch run the
  main checkout's gitignored `.claude/agents/` and `.claude/hooks/` are the orchestrator's live relay agents, and a run
  would rewrite them from the branch's templates. `tests/hyper-relay-agents/run-tests.sh` renders the templates in
  temporary repos: that is how this plan checks them.
- **Never** start a live `claude` / `claude -p` / `opencode run` session, install, update or uninstall a plugin, push,
  tag, or create anything on GitHub. `claude plugin validate .` is fine: it starts no session. Do not run upstream's live
  suites (`tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`).
- **Outside your branch is not yours.** Never touch `main`, `~/.claude/`, `~/.config/opencode/`, SAT's repo
  (`~/sat.pentraze.com`), any other project's repo or the home directory's own repo. Task 7's `skill-test`, `owner` and
  `after merge` steps do what is needed there, and they are not yours.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's scratch tracker: never stage, edit,
  move or delete either. A "the tree is clean" check ignores them.
- **This repo is public.** Nothing you write into the repo or a commit message names another project.
- **No new test** (spec §9): the greps in each task are checks you run once, not a suite to add.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs only its own checks (its greps and the guard suite that reads its files, piped
  through `tail -n 1`). The full gates run once, in Task 6: `tests/orchestrating/`, both `tests/hyper-relay-agents/`
  suites, and `claude plugin validate .`.
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.0; Task 7's `after merge`
  steps release 0.2.1.
- **Acceptance.** The plan ends with Task 7. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`skill-test`** (the orchestrator, after acceptance, beside the code review), **`owner`** (at the click-through) or
  **`after merge`** (the owner and the orchestrator), with its command or action and the result that counts as PASS.
  After Task 6, report (gate results with counts, every deviation, any `quartz:` line, the suites not run and why), copy
  Task 7's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §1 lists the files that change; `README.md` is not among them | `README.md:57` says a plan holds "every task with full code", which this change makes false. Task 6 Step 1 rewrites that one cell. No other card in flight touches `README.md` (LP1); card G, which rewrites the README later, waits on G.2's results. **The owner may drop Task 6 Step 1 at stop 3.** |
| P2 | §2.6: Execution notes carry "what is particular to this plan (a command not to run, a file's quirk, a suite that is the contract)" and not the standing "targeted checks per task and the full gates once" | The section also names "the suites its full gates run" as particular content: `executing-plans` step 5 runs "the ones the plan's Execution notes name". The standing rule it does not repeat is *running* each task's checks and the gates once. |
| P3 | §3: "The other rows, the calibration and the output format stay" | Two small edits, so the prompt does not contradict itself or LP4. The calibration's "when a check above fails" becomes "when a check above not marked advisory fails": otherwise the two advisory rows would block. Buildability's "without getting stuck or guessing" becomes "without getting stuck, or guessing a fact the plan should give (…)", adding that a choice the plan leaves open is the executor's: otherwise a reviewer would block every lean code step. |
| P4 | §4: the planner template's plan-format bullet changes three things | It also names **Review Focus** among the plan's sections: that bullet lists them, and a planner reading it as complete would leave Review Focus out. |
| P5 | §5: "write exactly the text a step gives …; write code to the step's signature and make its tests pass" | Adds "by the algorithm its code block gives when it gives one": §2.5 lets a plan give a body for an algorithm the signature and tests do not determine, and the executor follows it. |
| P6 | §8 run 1: "A scratch worktree at `3aa02ac` …, on a throwaway branch, outside the repo's `.worktrees/`" | **A clone at `ed3eb05`**, on the throwaway branch `g2-lean-probe`, in the evidence folder. `ed3eb05` is `3aa02ac` without G.2's plan (`git diff --stat ed3eb05 3aa02ac` lists that one file), the commit G.2's own planner wrote against; the code is the same. At `3aa02ac`, G.2's plan is the newest file in `docs/superpowers/plans/`, which the planner agent is told to take as its model. A linked worktree would also share this repo's hooks, and its "main checkout" would be this connected one: the probe executor's `Plan-Task:` commits would run Quartz's tick against the live board, and the generator's `{{root}}` would name this checkout, where G.2's plan and code are merged. A `--no-local --single-branch --no-tags` clone with its `origin` removed has none of G.2's commits, no Quartz hooks and no `.mcp.json`. The throwaway branch lives in the main repo only for the clone's few seconds; the clone keeps its own. |
| P7 | §7 S4: "the planner agent file, rendered from each side's template"; §8: agents "rendered from the branch's template and `.hyper-relay/agents.md`" | The generator writes into the repo that holds the current folder and takes its templates from beside itself. Task 7's skill-test preamble makes two scratch folders, `<E>/render-red` and `<E>/render-green`, each from `git archive <side> bin templates .hyper-relay .claude-plugin`, runs `git init` in each, and runs that folder's own `bin/hyper-relay-agents` there. Nothing touches the main checkout's live `.claude/agents/` or `.claude/hooks/`, and a hash check before and after proves it. The rendered `{{root}}` is the scratch folder; `sed` rewrites it to `/home/noob_master/hyper-relay` for S4 and to the clone for the probe. |
| P8 | §8: D1's run log "rebuilt from the committed table's header"; "gives the same rows" | The committed table ends with the run log it read, verbatim (its `## The run log it read` block): the probe extracts that block. When the lean tool reads a different run-log form (G.2's spec fixes the contents, not the key names), the orchestrator writes the same values in the lean form and records each change. Rows are compared first with `diff`, then by value (calls, input, both cache writes, cache read, output, cost) when only the table's form differs. |
| P9 | §8: "never gives it G.2's plan" | Validity checks, not in the spec: the clone holds no G.2 commit (`git cat-file -e d15d61e` fails there); neither probe agent's tool calls name the main checkout; the planner's transcript holds no sentence from G.2's plan. A failed check voids the probe, and stop 4 says so. |
| P10 | §8 runs 2 and 3: the two dispatches | Their prompts also forbid reading the main checkout and running G.2's two tools outside their suite: with a real `HOME`, `superpowers-env.sh` builds config folders and installs plugins, and `run-usage.sh` reads the owner's transcripts. The planner may read what G.2's spec names outside the repo, transcripts by field only. |
| P11 | `.hyper-relay/agents.md`, Releases: the release steps come "last"; §9: agents are regenerated "since the planner template changed", after the owner's update | The release (Steps 18–19) comes before the regeneration (Step 20), the token log (Step 21) and the record (Step 22), as D.2 plan 2 did: those three change no file the plugin loads (the generated agents are gitignored, the token log is outside the repo, the record is a plan doc), and the regeneration needs the update first. |
| P12 | §9: agents regenerated "in SAT (`~/sat.pentraze.com`)" | Not while a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: that would change the relay under measurement. The orchestrator asks the owner first then. |
| P13 | §7: the six situations | Each runs on a toy repo, except S4, which needs a rendered planner and so uses hyper-relay's own (its executors follow `executing-plans`, which holds the commit, trailer and never rules), with a toy spec for this repo. |
| P14 | §2: "upstream's reader", sizing, Review Focus, task structure, What a Step Contains, self-review | Adapted from `v7.0.2:skills/writing-plans/SKILL.md`. Not taken: its "**Spec:**" header line (our planner template already requires one), its "Global Constraints" heading (the values go into Execution notes, LP5), Interfaces on every task (LP7), "or for exact copy the spec fixes" in the code step (ours is the text step, LP2), "worth a fresh reviewer's gate" in right-sizing (ours: its own commit and `Plan-Task:` trailer, §2.2), and its Execution Handoff (§2.8). |
| P15 | §8: "Recorded, not a gate: the lean planner's calls, output, cache write, cache read and duration" | Summed by unique `message.id` over the agent's transcript, the token log's method, skipping `<synthetic>` messages (no usage). Duration and tool uses come from the completion notification. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–6; 7 (Step 14, the G.2 probe) |
| Decisions (owner, 2026-11-19) | LP1: scope only, no task: §1's files, plus P1's README cell. LP2: 1 (the text step), 3. LP3: 7 (Steps 8–14). LP4: 4, 5. LP5: 1 (Execution notes), 3 ("Every plan"). LP6: 3. LP7: 1 (Interfaces). LP8: 2 |
| 1. What changes where | 1–5; 6 (P1) |
| 2. `skills/writing-plans/SKILL.md` | 1; 7 (Steps 4, 8–11, 14) |
| 3. `skills/writing-plans/plan-document-reviewer-prompt.md` | 2; 7 (Step 5) |
| 4. The planner agent template and the relay's slot | 3; 7 (Steps 3, 6, 11, 20) |
| 5. `skills/executing-plans/SKILL.md` | 4; 7 (Steps 7, 12) |
| 6. `orchestrating` | 5; 7 (Steps 7, 13) |
| 7. Pressure scenarios | 7 (Steps 8–13) |
| 8. The G.2 probe | 7 (Step 14; Step 21 logs its numbers) |
| 9. Acceptance and release | 6 (the full gates); 7 (Steps 1–7 `reviewer`, 8–14 `skill-test`, 18–22 `after merge`) |
| 10. Out of scope | No task (File structure's Unchanged list); 7 (Step 2: only the planned files) |

## File structure

- **Modify (Task 1):** `skills/writing-plans/SKILL.md`.
- **Modify (Task 2):** `skills/writing-plans/plan-document-reviewer-prompt.md`.
- **Modify (Task 3):** `templates/agents/planner.md`, `.hyper-relay/agents.md`, `skills/agents/SKILL.md`.
- **Modify (Task 4):** `skills/executing-plans/SKILL.md`.
- **Modify (Task 5):** `skills/orchestrating/planning.md`, `skills/orchestrating/dispatching.md`.
- **Modify (Task 6):** `README.md` (P1).
- **Unchanged:** `bin/`, `hooks/`, `.claude-plugin/`, `package.json`, the other templates and skills, every suite.
- **Task 7, outside the branch (orchestrator and owner):** the evidence folder's scratch copies, renders and the probe's
  clone; the release on `main`; the installed plugin; this repo's and SAT's generated agents; the token log; this plan's
  record.

---

### Task 1: `writing-plans` records decisions, not code (spec §2; LP2, LP5, LP7; P2, P14)

**Files:**
- Modify: `skills/writing-plans/SKILL.md:10-12` (Overview), `:48-50` (sizing), `:75` (new sections before "No Quartz
  steps"), `:102` (Interfaces), `:117-122` (Step 3), `:137-152` ("No Placeholders", "Remember"), `:160-162`
  (self-review)

- [x] **Step 1: The reader (§2.1).** Replace:

```text
Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.
```

with:

```text
Write implementation plans for an engineer who has not seen this codebase or this spec. They write idiomatic code in the project's language once they know the exact interface and the exact test, and they make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. DRY. YAGNI. TDD. Frequent commits.
```

- [x] **Step 2: Sizing (§2.2).** Replace:

```text
## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
```

with:

```text
## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and its own commit, with its `Plan-Task:` trailer. Fold setup, configuration, scaffolding and documentation into the task whose deliverable needs them. Split only where one task's result can be checked without its neighbour's. Each task ends with something testable on its own.

## Step Granularity

**Each step is one action with a checkable result:**
```

(The five example lines under it stay.)

- [x] **Step 3: Execution notes and Review Focus (§2.6, §2.3).** Replace:

```text
## No Quartz steps in a plan
```

with:

```text
## Execution notes

A plan's **Execution notes** carry what is particular to it: a command not to run, a file's quirk, a suite that is the contract, the suites its full gates run. They also carry the spec's project-wide values (version floors, dependency limits, naming and copy rules, exact values), copied verbatim, one line each. They do not repeat the executor's standing rules, which `hyper-relay:executing-plans` holds: where it works, how it commits and with which trailers, its never list, and running each task's own checks with the full gates once at the end.

## Review Focus

After its header and before its first task, the plan carries a **Review Focus** section: up to five input classes or failure modes that the spec implies but no task's tests exercise, the ones most likely to bite a person using the software, most likely first. Each is one line, naming the input or condition and the behaviour a reasonable person would expect. The spec is a vision document: its silence on an input is not permission for that input to break the program. Add each line's test to the task that owns the code, in that task's own step style. An empty section means you checked and found none, not that you skipped the check.

## No Quartz steps in a plan
```

- [x] **Step 4: The Interfaces block (§2.4; LP7).** Replace:

```text
- Test: `tests/exact/path/to/test.py`
```

with:

```text
- Test: `tests/exact/path/to/test.py`

**Interfaces** (only when a later task uses what this one makes):
- Consumes: [what this task uses from earlier tasks: exact names and signatures]
- Produces: [what later tasks use: exact function names, parameters and return types]
```

- [x] **Step 5: The example's Step 3 (§2.4).** This X starts mid-line, after the line's `- [ ] `. Replace:

````text
**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```
````

with:

```text
**Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice (which library call, which data structure); a code block only for an algorithm they do not determine.
```

- [x] **Step 6: The trailer beside the example, and What a Step Contains (§2.4, §2.5; LP2).** Replace:

```text
## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- The **final** commit step of each task carries the plan's own path and the task's number as a git trailer: `-m "Plan-Task: docs/superpowers/plans/<this plan>.md#<N>"`. Earlier commits in the same task and tasks with no commit step do not carry it.
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits
```

with:

```text
The **final** commit step of each task carries the plan's own path and the task's number as a git trailer, as above: `-m "Plan-Task: docs/superpowers/plans/<this plan>.md#<N>"`. Earlier commits in the same task and tasks with no commit step do not carry it.

The executor reads the whole plan, so a task has an **Interfaces** block only when a later task uses its names or types. The later task's steps point to that block instead of repeating its code.

## What a Step Contains

A step is done when the executor can write exactly one reasonable thing from it: unambiguous, not complete. Each kind of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the file it lives in, and the values the spec pins. The executor writes the body. A body appears only for an algorithm the signature and the tests do not determine.
- **A text step:** the exact text, in full, and where it goes, wherever the words are the product: a skill file or a file beside it that agents read, a doc, a message a person or an agent reads, a config value. "Create X with exactly this content" and "Replace X with Y" are the forms for these.
- **A verification step:** the command, and the output that means it passed.
- **A reference to another task:** that task's Interfaces block, not a copy of its code.

A plan is the set of decisions the executor cannot make alone. A plan longer than the code it describes has written the code instead. Lines that decide nothing ("TBD", "TODO", "implement later", "fill in details", "handle edge cases", "add appropriate validation", "write tests for the above", "Similar to Task N", a type or function no task defines) are the opposite failure. The self-review catches both.
```

- [x] **Step 7: The self-review (§2.7).** Replace:

```text
**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.
```

with:

```text
**2. Step scan:** Every step lets the executor write exactly one reasonable thing, and carries no more than that. A line that decides nothing is a gap; a body the signature and the tests already determine is a transcript. Fix both. Text steps keep their text in full.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, a task's tests exercise it, or it is in Review Focus with its test added to the task that owns the code.

**5. Proportion:** Compare the plan's length with the spec's. When code blocks are most of the plan, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous. Text steps do not count against the plan here.
```

- [x] **Step 8: Check it.**

| Run | Expected |
|---|---|
| `grep -c '^## ' skills/writing-plans/SKILL.md` | `19` |
| `grep -n '^## ' skills/writing-plans/SKILL.md` | in order: Overview, Scope Check, The spec's plan count, Stacked plans, Sent back to renumber, File Structure, Task Right-Sizing, Step Granularity, Plan Document Header, Execution notes, Review Focus, No Quartz steps in a plan, Spec coverage and the acceptance task, Skill tests, Task Structure, What a Step Contains, Self-Review, Committing the plan, After saving the plan |
| `grep -c -E 'questionable taste\|Bite-Sized\|2-5 minutes\|No Placeholders\|^## Remember\|Complete code in every step\|Placeholder scan\|Write minimal implementation' skills/writing-plans/SKILL.md` | `0` |
| `grep -c -F 'Plan-Task:' skills/writing-plans/SKILL.md` | `3` (right-sizing, the example's commit, the sentence after the example) |
| `grep -n -E '^\*\*[1-5]\. ' skills/writing-plans/SKILL.md` | five lines: Spec coverage, Step scan, Type consistency, Review Focus, Proportion |
| `git diff main -- skills/writing-plans/SKILL.md \| grep -c -E '^[-+](---\|name:\|description:\|\*\*Announce\|\*\*Context:\|\*\*Save plans)'` | `0` (the frontmatter, the announce line, Context and Save plans to are untouched) |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |

- [x] **Step 9: Commit.**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: writing-plans records decisions, not code (upstream 6.0–6.4.2)" -m "The reader is an engineer who writes idiomatic code once given the exact interface and test. Tasks are sized by their own test cycle and commit, steps by a checkable result. A plan carries Review Focus and lean Execution notes; a task has Interfaces only when a later task uses it. What a Step Contains replaces No Placeholders: tests and signatures, not bodies, and skill text, docs and messages in full. The self-review adds the step scan, Review Focus and proportion." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: The plan reviewer's prompt follows (spec §3; LP8; P3)

**Files:**
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md:23` (Placeholders), `:27-29` (Execution notes,
  Buildability, new rows), `:33-34` (calibration)

- [x] **Step 1: Step contents.** Replace:

```text
    | Placeholders | "TBD", "TODO", "implement later", "fill in details", "Similar to Task N", or a step that says what to do without the code or text to do it. |
```

with:

```text
    | Step contents | A step that decides nothing ("TBD", "TODO", "implement later", "fill in details", "handle edge cases", "Similar to Task N", a name no task defines); a code body that the step's signature and tests already determine; a text step (a skill, a doc, a message) that does not give its text in full. |
```

- [x] **Step 2: Execution notes, Buildability, and the two advisory rows.** Replace:

```text
    | Execution notes | Present: how to commit, what is not the executor's, the full gates. |
    | External facts | Each fact the spec asks to re-verify is cited with its URL and the date it was checked; a difference is listed as a deviation. |
    | Buildability | Could an executor follow every step without getting stuck or guessing? |
```

with:

```text
    | Execution notes | Present. They carry what is particular to this plan and the spec's project-wide values, copied verbatim, and do not repeat the executor's standing rules (where it works, how it commits and its trailers, its never list, running each task's checks and the full gates once). |
    | External facts | Each fact the spec asks to re-verify is cited with its URL and the date it was checked; a difference is listed as a deviation. |
    | Buildability | Could an executor follow every step without getting stuck, or guessing a fact the plan should give (a value, a behaviour, a name another task uses)? A choice the plan leaves open, such as how to write a body, is the executor's. |
    | Review Focus (advisory) | The section is present, after the header and before the first task, with up to five lines; each line's test is in the task that owns the code. |
    | Proportion (advisory) | The plan's length against the spec's (`wc -l` on both), and the share of its lines inside code blocks. Text steps (skill text, docs, messages) do not count against it. |
```

- [x] **Step 3: The calibration.** Replace:

```text
    An issue **blocks execution** when an executor would build the wrong thing or get
    stuck, or when a check above fails. Wording, style and "nice to have" are advisory.
```

with:

```text
    An issue **blocks execution** when an executor would build the wrong thing or get
    stuck, or when a check above not marked advisory fails. Wording, style and "nice to
    have" are advisory.
```

- [x] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c '^    \| ' skills/writing-plans/plan-document-reviewer-prompt.md` | `11` (the header row and ten checks) |
| `grep -c -F '\| Placeholders \|' skills/writing-plans/plan-document-reviewer-prompt.md` | `0` |
| `grep -c -F '(advisory)' skills/writing-plans/plan-document-reviewer-prompt.md` | `2` |
| `grep -c -F 'not marked advisory' skills/writing-plans/plan-document-reviewer-prompt.md` | `1` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |

- [x] **Step 5: Commit.**

```bash
git add skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: the plan reviewer checks step contents, Review Focus and proportion" -m "Placeholders becomes Step contents: a step that decides nothing, a body the signature and tests determine, or skill text not given in full. Execution notes are checked for what is particular to the plan. Review Focus and Proportion are advisory rows, and only a non-advisory check blocks. A choice the plan leaves open is the executor's, not a buildability gap." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: The planner template, the relay's slot and the slot table (spec §4; LP5, LP6; P4)

**Files:**
- Modify: `templates/agents/planner.md:31-34` (plan format), `:50-53` (how you work), `:55-71` ("Every plan")
- Modify: `.hyper-relay/agents.md:17-18` (`planner/plan-format`)
- Modify: `skills/agents/SKILL.md:74` (the slot table)
- Test: `tests/hyper-relay-agents/run-tests.sh` (renders the templates and this repo's facts file)

- [x] **Step 1: The plan-format bullet.** In `templates/agents/planner.md`, replace:

```text
- Plan format: a header with the **Card:** line (from the spec) and a **Spec:** line (the spec's repo-relative
  path), Goal / Architecture / Tech Stack / **How this was checked** (list every file you read), binding
  **Execution notes**, tasks with FULL code, and a **Spec ambiguities / deviations** table. Mirror the newest plans
  in `docs/superpowers/plans/` for format.
```

with:

```text
- Plan format: a header with the **Card:** line (from the spec) and a **Spec:** line (the spec's repo-relative
  path), Goal / Architecture / Tech Stack / **How this was checked** (one line: the commit the plan was written
  against, read-only, nothing run), binding **Execution notes**, **Review Focus**, tasks written as
  `hyper-relay:writing-plans`' "What a Step Contains" says, and a **Spec ambiguities / deviations** table. Mirror
  the newest plans in `docs/superpowers/plans/` for format. Plans there written before this format carry full code:
  take their header and acceptance task as models, never their steps.
```

- [x] **Step 2: How you work.** In `templates/agents/planner.md`, replace:

```text
- **External facts** the spec says to re-verify: check them with WebFetch/WebSearch, cite URL + date in the plan,
  and list any difference as a deviation, never a silent design change.
- Write for the `{{project}}-executor` agent: put the full code in each task so execution is transcription plus
  targeted tests.
```

with:

```text
- **External facts** the spec says to re-verify: check them with WebFetch/WebSearch, cite URL + date in the plan,
  quote only what decides something, and list any difference as a deviation, never a silent design change.
- Write for the `{{project}}-executor` agent the decisions it cannot make alone, as `hyper-relay:writing-plans`'
  "What a Step Contains" says.
```

- [x] **Step 3: "Every plan".** In `templates/agents/planner.md`, replace:

```text
## Every plan's Execution notes carry
- The executor works where its dispatch prompt says: a branch in the main checkout or its own worktree, chosen at
  the handoff. A plan names no mode, no checkout path and no `cd` prefix, and carries no Quartz step: the
  orchestrator runs `quartz link-branch` and `quartz review`.
- Commit after every task, staging named files only (never `git add -A` / `git add .`), ending with the
  attribution trailer the executor's instructions give. The final commit of each task also carries
  `Plan-Task: <plan path>#<N>`.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- Token budget: targeted tests per task; the full gates once at the end.
- **Outside the executor's branch is not the executor's.** Anything that touches `main`, another repo, the owner's
  own config, or GitHub (push, tag, repo settings), or that needs real credentials, a real third-party API or a live
  Claude Code or OpenCode session, is an owner/orchestrator task: mark it so, with exact commands and exact text.
  Tests use fakes.
- A plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by
  the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the
  orchestrator: live sessions, reinstalls, edits outside the repo); and it gives its command or action and the
  result that counts as PASS, so it can be run as written.
```

with:

```text
## Every plan
- **Outside the executor's branch is not the executor's.** Anything that touches `main`, another repo, the owner's
  own config, or GitHub (push, tag, repo settings), or that needs real credentials, a real third-party API or a live
  Claude Code or OpenCode session, is an owner/orchestrator task: mark it so, with exact commands and exact text.
  Tests use fakes.
```

(The `{{slot planner/execution-notes}}` line after it stays.)

- [x] **Step 4: The relay's slot.** In `.hyper-relay/agents.md`, replace:

```text
- The model is the newest hyper-relay plan in `docs/superpowers/plans/`; upstream's older plans in `docs/upstream/`
  and `docs/plans/` are not.
```

with:

```text
- The model is the newest hyper-relay plan in `docs/superpowers/plans/`, for its header and acceptance task, not its
  steps; upstream's older plans in `docs/upstream/` and `docs/plans/` are not.
```

- [x] **Step 5: The slot table.** In `skills/agents/SKILL.md`, replace:

```text
| `planner/execution-notes` | planner, "Every plan's Execution notes carry" | the full gates; how stacks may be started; owner-only steps |
```

with:

```text
| `planner/execution-notes` | planner, "Every plan" | the full gates; how stacks may be started; owner-only steps |
```

- [x] **Step 6: Check it.**

| Run | Expected |
|---|---|
| `grep -c -E 'FULL code\|transcription plus\|Execution notes carry\|list every file you read\|self-matching\|Token budget' templates/agents/planner.md` | `0` |
| `grep -c -x '## Every plan' templates/agents/planner.md` | `1` |
| `grep -A 7 -x '## Every plan' templates/agents/planner.md` | the heading, the "Outside the executor's branch" bullet (four lines), `{{slot planner/execution-notes}}`, a blank line, `## Committing` |
| `grep -c -F 'What a Step Contains' templates/agents/planner.md` | `2` |
| `grep -c -F 'header and acceptance task, not its' .hyper-relay/agents.md` | `1` |
| `grep -c -F 'planner, "Every plan" \|' skills/agents/SKILL.md` | `1` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |

- [x] **Step 7: Commit.**

```bash
git add templates/agents/planner.md .hyper-relay/agents.md skills/agents/SKILL.md
git commit -m "feat: the planner template asks for decisions, not full code" -m "How this was checked is one line. Tasks follow writing-plans' What a Step Contains, and older plans are models for their header and acceptance task only, here and in this repo's slot. The template's Execution-notes boilerplate goes (executing-plans and writing-plans hold it); the section becomes Every plan, keeping the rule that outside the branch is not the executor's, and the slot table names it." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `executing-plans` makes, and reports, the open calls (spec §5; LP4; P5)

**Files:**
- Modify: `skills/executing-plans/SKILL.md:33-34` (step 2), `:36` (step 3), `:59` (step 7)

- [x] **Step 1: Process step 2.** Replace:

```text
2. **No review gate.** The plan is approved: do not re-plan it or ask about it. A step that is unclear or impossible
   means stop and report, never guess.
```

with:

```text
2. **No review gate.** The plan is approved: do not re-plan it or ask about it. A choice the plan leaves open (how to
   write a body, which helper or library call) is yours: make the reasonable one, and list it in your report. Stop
   and report only when a step contradicts the spec or another step, needs a fact the plan should have given (a
   value, a behaviour, a name another task uses), or cannot be done.
```

- [x] **Step 2: Process step 3.** Replace:

```text
   - Follow its steps exactly, transcribing the plan's code.
```

with:

```text
   - Follow its steps in order. Write exactly the text a step gives (file contents, skill text, messages). Write code
     to the step's signature, by the algorithm its code block gives when it gives one, and make its tests pass.
```

- [x] **Step 3: The report.** Replace:

```text
   - every deviation from the plan, and why;
```

with:

```text
   - every deviation from the plan, and why;
   - the calls you made where the plan left a choice open, one line each;
```

- [x] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c -E 'unclear or impossible\|transcribing\|never guess' skills/executing-plans/SKILL.md` | `0` |
| `grep -c -F 'left a choice open' skills/executing-plans/SKILL.md` | `1` (step 7's list) |
| `grep -c -F 'leaves open' skills/executing-plans/SKILL.md` | `1` (step 2) |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |

- [x] **Step 5: Commit.**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat: the executor makes the calls a lean plan leaves open, and reports them" -m "A choice the plan leaves open, such as how to write a body, is the executor's: it makes the reasonable one and lists it in its report. It stops only when a step contradicts the spec or another step, lacks a fact the plan should give, or cannot be done. Text a step gives is written exactly; code is written to the step's signature and made to pass its tests." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `orchestrating`: the plan's length at stop 3, and the executor's calls weighed (spec §6)

**Files:**
- Modify: `skills/orchestrating/planning.md:74` (stop 3's report)
- Modify: `skills/orchestrating/dispatching.md:125` (the hand-back check)

- [x] **Step 1: Stop 3's report.** In `skills/orchestrating/planning.md`, replace:

```text
- the plan paths and their task counts;
```

with:

```text
- the plan paths and their task counts;
- a line per plan, "plan N lines for an M-line spec", from `wc -l` on the plan and on its spec;
```

- [x] **Step 2: The hand-back check.** In `skills/orchestrating/dispatching.md`, replace:

```text
4. Weigh every deviation the report lists: accept it, or tell the owner why not.
```

with:

```text
4. Weigh every deviation the report lists, and every call the executor made where the plan left a choice open: accept
   each, or tell the owner why not.
```

- [x] **Step 3: Check it.**

| Run | Expected |
|---|---|
| `grep -n -F 'lines for an M-line spec' skills/orchestrating/planning.md` | one line, in §3's report list |
| `grep -n -F 'left a choice open' skills/orchestrating/dispatching.md` | one line, §7's check 4 |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |

- [x] **Step 4: Commit.**

```bash
git add skills/orchestrating/planning.md skills/orchestrating/dispatching.md
git commit -m "feat: stop 3 reports each plan's length against its spec's; the executor's calls are weighed" -m "Stop 3's report gains a line per plan, plan N lines for an M-line spec, from wc -l. The hand-back check weighs every call the executor lists where the plan left a choice open, as it weighs deviations." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: README's Plan row, and the full gates (spec §9; P1)

**Files:**
- Modify: `README.md:57`

- [x] **Step 1: The Plan row (P1).** In `README.md`, replace:

```text
| Plan | `writing-plans`, run by a planner agent | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with full code, tests and a binding contract between plans |
```

with:

```text
| Plan | `writing-plans`, run by a planner agent | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with its files, its tests and the decisions the executor cannot make alone (signatures, the spec's values, skill text in full), and a binding contract between plans |
```

- [x] **Step 2: Commit.**

```bash
git add README.md
git commit -m "docs: README's Plan row says what a plan holds now" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 3: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` (the guard is untouched; a regression check) |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/agents.md`, `README.md`, `skills/agents/SKILL.md`, `skills/executing-plans/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/planning.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `templates/agents/planner.md` |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Upstream's live suites are not run (report this): they start real `claude -p` sessions. Then report, copy Task 7's
checklist (Steps 1–22, each with its marker and its PASS) into your report, and stop: Task 7 is not yours.

### Task 7: Acceptance (spec §7, §8, §9; P6–P13, P15). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-leaner-plans`) its dispatch names, from the checkout's top (Steps 1–7). It never runs
  `hyper-relay-agents` in the checkout; Step 3 renders in its evidence folder (`<evidence>` below).
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the standing leg
  (`reviewing.md` §3, the installed relay's): `<E>` is that leg's evidence folder, an absolute path, whose `red/` and
  `green/` hold `main`'s and the branch's `skills/`. Steps 8–13 are S1–S6: each is dispatched twice, on Sonnet, in the
  background, with the leg's standing preamble and then the step's situation, verbatim. Step 14 is the G.2 probe.
  Before Steps 11 and 14, render each side's agents (P7), in order, one command per line:

```bash
sha256sum /home/noob_master/hyper-relay/.claude/agents/relay-planner.md /home/noob_master/hyper-relay/.claude/agents/relay-executor.md /home/noob_master/hyper-relay/.claude/agents/relay-reviewer.md /home/noob_master/hyper-relay/.claude/hooks/hyper-relay-planner-guard.py > <E>/live-agents.sha256
mkdir -p <E>/render-red <E>/render-green
git -C /home/noob_master/hyper-relay archive main bin templates .hyper-relay .claude-plugin | tar -x -C <E>/render-red
git -C /home/noob_master/hyper-relay archive hyper-relay-leaner-plans bin templates .hyper-relay .claude-plugin | tar -x -C <E>/render-green
git init -q <E>/render-red
git init -q <E>/render-green
(cd <E>/render-red && sh bin/hyper-relay-agents)
(cd <E>/render-green && sh bin/hyper-relay-agents)
```

  PASS: each run prints `written .claude/agents/relay-planner.md`, `written .claude/agents/relay-executor.md`,
  `written .claude/agents/relay-reviewer.md`, `written .claude/hooks/hyper-relay-planner-guard.py` and the restart line,
  and exits 0; `grep -c -x '## Every plan' <E>/render-green/.claude/agents/relay-planner.md` prints `1` and the same on
  `render-red` prints `0`. After Step 14, `sha256sum -c <E>/live-agents.sha256` prints `OK` for all four files: the
  main checkout's live agents never changed.
- **`owner`**: the owner, at the click-through (Steps 15–16).
- **`after merge`**: the orchestrator with the owner, once the branch is merged into `main` and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 17–22). The orchestrator runs the commands; the owner runs the
  plugin update and the reload.

In a command inside a table cell, `\|` is a plain `|`, as in the Execution notes.

**This plan's run follows the installed relay** (0.2.0's `orchestrating`, `executing-plans` and planner), not the text
it writes: the new behaviour reaches a session only after the release and the owner's update (Steps 18–19).

- [ ] **Step 1 (`reviewer`): The suites and the manifest.**

| Run | PASS |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout, `PRIVACY_URL_MISSING`; no other warning |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `git show HEAD:.claude-plugin/plugin.json \| grep -F '"version"'` | `"version": "0.2.0",` (the release is after the merge) |

- [ ] **Step 2 (`reviewer`): Only the planned files (spec §1, §10; P1).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the nine files of Task 6 Step 3 |
| `git diff main...HEAD -- skills templates .hyper-relay README.md \| grep -c -E '^\+.*(/home/\|~/\|/tmp/\|/Users/)'` | `0` |
| `git diff main...HEAD -- skills templates \| grep -c -i -E '^\+.*subagent-driven'` | `0` |
| `git log --format=%B main..HEAD \| grep -c -i -w -e sat -e pentraze` | `0` |

- [ ] **Step 3 (`reviewer`): The planner renders (spec §4).** In the evidence folder, never in the checkout:

```bash
mkdir -p <evidence>/render
git archive HEAD bin templates .hyper-relay .claude-plugin | tar -x -C <evidence>/render
git init -q <evidence>/render
(cd <evidence>/render && sh bin/hyper-relay-agents)
```

| Run | PASS |
|---|---|
| the last command above | `written .claude/agents/relay-planner.md` and the three other `written` lines; exit 0 |
| `grep -c -x '## Every plan' <evidence>/render/.claude/agents/relay-planner.md` | `1` |
| `grep -c -e 'tasks with FULL code' -e 'put the full code' -e 'Execution notes carry' -e 'pgrep' -e 'Token budget' -e 'list every file you read' <evidence>/render/.claude/agents/relay-planner.md` | `0` |
| `grep -c -F 'header and acceptance task' <evidence>/render/.claude/agents/relay-planner.md` | `2` (the template's guard and the slot's) |
| `awk '/^## Every plan$/,/^## Committing$/' <evidence>/render/.claude/agents/relay-planner.md` | the "Outside the executor's branch" bullet, then this repo's three `planner/execution-notes` bullets (`The full gates:`, `Also the owner's or the orchestrator's:`, `**Releases**`), then `## Committing`; nothing else |
| `grep -c '{{' <evidence>/render/.claude/agents/relay-planner.md` | `0` |
| `git status --short` | nothing new: the render wrote only under `<evidence>` |

- [ ] **Step 4 (`reviewer`): `writing-plans` against spec §2 (P2, P14).** Read `skills/writing-plans/SKILL.md` in full
  and `git diff main...HEAD -- skills/writing-plans/SKILL.md`. PASS, each point quoted with its line:
  - the Overview's reader is §2.1's (not seen the codebase or the spec; idiomatic code once given the interface and the
    test; a reasonable choice where the plan leaves one; the plan documents the files, names and signatures, the spec's
    values and the tests), and the announce line, Context and "Save plans to" are unchanged;
  - "Task Right-Sizing" and "Step Granularity" say what §2.2 says, with the five example steps;
  - "Review Focus" has every element of §2.3, including the empty-section sentence;
  - the Task Structure example has an Interfaces block after Files, marked as present only when a later task uses it,
    its Step 3 is "Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`" with the one-line
    approach, and the final-commit trailer rule sits after the example (§2.4);
  - "What a Step Contains" has the five kinds of §2.5, the text step with LP2's list and its two forms, and both
    failures with the listed phrases;
  - "Execution notes" is §2.6's, plus P2's "the suites its full gates run";
  - the self-review has §2.7's five checks;
  - the diff touches none of §2.8's sections. Any sentence that contradicts the spec beyond the P-notes is a FAIL, with
    its line.

- [ ] **Step 5 (`reviewer`): The reviewer prompt against spec §3 (P3).** Read
  `git diff main...HEAD -- skills/writing-plans/plan-document-reviewer-prompt.md`. PASS: Placeholders became Step
  contents with §3's three cases; Review Focus and Proportion are marked advisory with §3's contents; Execution notes
  checks what is particular and the spec's values, not the standing rules; the only other changes are P3's two (the
  calibration's "not marked advisory", Buildability's fact the plan should give); the output format is unchanged.

- [ ] **Step 6 (`reviewer`): The template, the slot and the slot table against spec §4 (P4).** Read
  `git diff main...HEAD -- templates/agents/planner.md .hyper-relay/agents.md skills/agents/SKILL.md`. PASS: "How this
  was checked" is one line (the commit, read-only, nothing run); tasks follow "What a Step Contains"; the older-plans
  guard is in the template and in the `planner/plan-format` slot; External facts quote only what decides something;
  "Write for the executor" names the decisions it cannot make alone; the section is "Every plan", keeps only "Outside
  the executor's branch is not the executor's" and the slot; the slot table's cell says "Every plan"; plus P4's Review
  Focus; nothing else changed.

- [ ] **Step 7 (`reviewer`): `executing-plans`, `orchestrating` and README against spec §5, §6 (P1, P5).** Read
  `git diff main...HEAD -- skills/executing-plans/SKILL.md skills/orchestrating README.md`. PASS: step 2 makes an open
  choice the executor's, reported, and stops only on §5's three cases; step 3 writes a step's text exactly and code to
  its signature and tests (P5's algorithm clause); step 7's report lists the calls; `planning.md` §3's report has "plan
  N lines for an M-line spec" from `wc -l`; `dispatching.md` §7 weighs every call like a deviation; README's Plan row
  is P1's; nothing else in those files changed.

- [ ] **Step 8 (`skill-test`): S1, a planner writes a code task.**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it). The repo is /work/toy, a small POSIX shell project with no app. Its CLAUDE.md says:
scripts are POSIX sh run by dash (`dash -n` must be silent); each suite prints "<n> passed, <m> failed" and must end
"0 failed".

The approved spec, docs/superpowers/specs/2026-11-19-toy-branch-name-design.md, says in full:

  # toy: branch names from plan paths (design)
  ## Goal
  The relay names a plan's branch after the plan's file. One shell function does it, so every script names branches
  the same way.
  ## The function
  `scripts/branch-name.sh` defines `branch_name`, a POSIX shell function. It takes one argument, a plan's path, and
  prints the plan's file name without its leading date (`YYYY-MM-DD-`) and without `.md`, then a newline. Two cases
  are fixed:
  - `docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md` → `hyper-relay-c-executing-plans`
  - `docs/superpowers/plans/2026-11-18-billing.md` → `billing`
  ## Tests
  `tests/branch-name/run-tests.sh` sources `scripts/branch-name.sh` and checks both cases; it ends "0 failed".

Write the plan's Task 1, which builds `scripts/branch-name.sh` and its suite, exactly as it would appear in the plan:
its heading, its Files block, and every step in full, with whatever code blocks the steps need.
```

GREEN must: give a test step whose code asserts both cases with the spec's values verbatim (both paths, both branch
names); give a code step that names `branch_name <plan path>`, what it prints, and its file `scripts/branch-name.sh`,
with at most one line on the approach; and give no code block holding `branch_name`'s body (no `branch_name() {` with
its commands).

RED is expected to: give `branch_name`'s body in full in a code block.

- [ ] **Step 9 (`skill-test`): S2, a planner changes a skill's process step (LP2).**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it). The repo is /work/toy, a Claude Code plugin made of Markdown skills.

Its skill `skills/greeting/SKILL.md` is, in full:

  ---
  name: greeting
  description: Use when a session starts and the user has not been greeted yet.
  ---
  # Greeting
  ## Process
  1. **Check.** Look for a greeting earlier in this session.
  2. **Greet.** Say hello, by the user's name when you know it.
  3. **Stop.** Ask what they want to work on.

The approved spec, docs/superpowers/specs/2026-11-19-toy-greeting-once-design.md, says: "Process step 2 gains one
rule: never greet twice in one session; when step 1 found an earlier greeting, skip step 2 and go to step 3." Nothing
else changes.

Write the plan's step that changes `skills/greeting/SKILL.md`, exactly as it would appear in the plan.
```

GREEN must: give process step 2's new text in full, verbatim, and where it goes (a "Replace X with Y" of step 2's line
in `skills/greeting/SKILL.md`, or the file's whole new content), not a description such as "add a sentence saying …".

RED is expected to: do the same. This is LP2's guard: it is not expected to discriminate, and a GREEN that describes the
text instead of giving it is a fix round.

- [ ] **Step 10 (`skill-test`): S3, a spec silent on an empty input (§2.3).**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it). The repo is /work/toy, a small POSIX shell project; jq 1.7 is installed; scripts are
POSIX sh run by dash; each suite ends "0 failed".

The approved spec, docs/superpowers/specs/2026-11-19-toy-count-calls-design.md, says in full:

  # toy: counting a session's API calls (design)
  ## Goal
  Count the API calls in a Claude Code session transcript.
  ## The tool
  `scripts/count-calls.sh <transcript>` reads one transcript: a JSON Lines file, one record per line, as Claude Code
  writes it under `~/.claude/projects/<project>/<session>.jsonl`. An assistant record has `"type":"assistant"` and a
  `message` with an `id`; one API call can be written as several records with the same `message.id`, so the tool counts
  each `message.id` once. It prints `calls: <n>` and exits 0.
  ## Tests
  `tests/count-calls/run-tests.sh`, with small fixture transcripts that the suite writes: a transcript with three
  records of one `message.id` and one of another prints `calls: 2`.

Write the plan's sections that come after its header and before Task 1, and then Task 1's first step (its failing
test), where Task 1 builds `scripts/count-calls.sh` and its suite.
```

GREEN must: include a Review Focus section with a line for an empty transcript (a zero-byte file, or one with no
assistant record) and the behaviour a person would expect (`calls: 0`, exit 0); and Task 1's test step tests that case
besides the spec's.

RED is expected to: have no Review Focus section and no test for an empty transcript.

- [ ] **Step 11 (`skill-test`): S4, a planner writes Execution notes (§2.6, §4; LP5; P7, P13).** First make the two
  agent files (after the renders in this task's preamble):

```bash
G=$(cd <E>/render-green && pwd -P); sed "s#$G#/home/noob_master/hyper-relay#g" <E>/render-green/.claude/agents/relay-planner.md > <E>/s4-planner-green.md
R=$(cd <E>/render-red && pwd -P); sed "s#$R#/home/noob_master/hyper-relay#g" <E>/render-red/.claude/agents/relay-planner.md > <E>/s4-planner-red.md
grep -c -F 'render-' <E>/s4-planner-green.md <E>/s4-planner-red.md
```

The last prints `0` for each file. In the situation below, replace the line `<AGENT FILE>` with the whole of
`<E>/s4-planner-green.md` for GREEN, and of `<E>/s4-planner-red.md` for RED, verbatim.

Situation:

```text
You are a planner: the relay's planner agent for the hyper-relay repo. Your agent file is below, between the lines
"--- agent file ---" and "--- end ---"; it names the skill you follow, `writing-plans` (hyper-relay:writing-plans).
This repo's executors follow the `executing-plans` skill.

--- agent file ---
<AGENT FILE>
--- end ---

The approved spec, docs/superpowers/specs/2026-11-19-hyper-relay-agents-version-design.md, says in full:

  # hyper-relay: `hyper-relay-agents --version` (design)
  ## Goal
  The owner can ask the generator which hyper-relay version it belongs to.
  ## The flag
  `bin/hyper-relay-agents --version` prints exactly `hyper-relay-agents <version>`, where `<version>` is the
  `"version"` of the `.claude-plugin/plugin.json` beside the generator, and exits 0. It reads no facts file and writes
  nothing. Any other unknown flag is a usage error, as today.
  ## Constraints
  - The generator stays POSIX shell run by dash: no `[[`, `local`, arrays or `$'…'`.
  - `tests/hyper-relay-agents/run-tests.sh` gains the flag's test; today it ends "153 passed, 0 failed".
  ## Out of scope
  Any other change to the generator or its templates.

Write the plan's Execution notes section, in full, exactly as it would appear in the plan.
```

GREEN must: carry the spec's constraints (dash only, with its list; the suite's new test) and the exact output form
`hyper-relay-agents <version>`, and things particular to this plan (for example the suite as the contract, `dash -n
bin/hyper-relay-agents`, the full gates this plan touches); and carry none of these standing rules: where the executor
works (branch or worktree), staging named files / never `git add -A`, the `Plan-Task:` trailer, the `Co-Authored-By` /
`Claude-Session` attribution lines, the `pgrep` / `pkill` rule, "targeted tests per task, the full gates once".

RED is expected to: repeat the commit, `Plan-Task:`, attribution and `pgrep` rules, which `main`'s agent file lists
under "Every plan's Execution notes carry".

- [ ] **Step 12 (`skill-test`): S5, an executor meets an open choice (§5; LP4).**

Situation:

```text
You are the executor: you run ONE approved plan, following the `executing-plans` skill (its SKILL.md). The repo is
/work/toy, a POSIX shell project. Your checkout is /work/toy, on the branch `toy-branch-name` (mode `branch`), and
`git rev-parse --show-toplevel` and `git branch --show-current` print those. The plan is
docs/superpowers/plans/2026-11-19-toy-branch-name.md, committed on `main`; Tasks 1–2 are yours. Your attribution lines
are `Co-Authored-By: Claude <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_x`. Task 1 is
done and committed: `tests/branch-name/run-tests.sh` sources `scripts/branch-name.sh` and checks that
`branch_name docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md` prints `hyper-relay-c-executing-plans`
and `branch_name docs/superpowers/plans/2026-11-18-billing.md` prints `billing`. It fails now ("0 passed, 2 failed"):
the script does not exist.

Task 2 of the plan, in full:

  Task 2: `branch_name`
  Files: Create `scripts/branch-name.sh`.
  Step 1: Implement `branch_name <plan path>` in `scripts/branch-name.sh`. A POSIX sh function: it prints the plan's
  file name without its leading `YYYY-MM-DD-` and without `.md`, then a newline.
  Step 2: Run the suite. Run: `sh tests/branch-name/run-tests.sh | tail -n 1`. Expected: `2 passed, 0 failed`.
  Step 3: Commit. `git add scripts/branch-name.sh`, then commit with the subject "feat: branch_name" and the trailer
  `Plan-Task: docs/superpowers/plans/2026-11-19-toy-branch-name.md#2` with your attribution lines.

The plan does not say how to write the body. At least two ways pass the suite: `basename "$1" .md` piped to a `sed`
that strips the date, or the shell's own `${1##*/}`, `${f%.md}` and `${f#????-??-??-}`. Task 2 is your last task.
Give the commands you run, in order, and then your report.
```

GREEN must: choose one way, write `scripts/branch-name.sh` with it, run the suite to `2 passed, 0 failed`, commit with
the trailer and the attribution lines, and carry on to its gates and report, whose list names the choice in one line
(which way, and that the plan left it open); it does not stop at Step 1.

RED is expected to: stop at Step 1 and report it as unclear, since `main`'s step 2 says "A step that is unclear or
impossible means stop and report, never guess".

- [ ] **Step 13 (`skill-test`): S6, stop 3 for a long plan (§6).**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main` and clean; no plan is in flight; `git show
main:.hyper-relay/agents.md` has `execute: branch` in its header; `git config --get hyper-relay.quartz` prints `off`.
The owner approved the spec docs/superpowers/specs/2026-11-19-toy-report-design.md (no `**Plans:**` line). The planner
has handed back docs/superpowers/plans/2026-11-19-toy-report.md, committed on `main`, and every hand-back check passed.
Its report lists one deviation, P1: "the spec's §3 names no file for the report's template: `templates/report.md`,
beside the script", and no external facts. There are no decisions for the owner.

Output you already have, verbatim:

  $ git log -1 --format=%h main -- docs/superpowers/plans/2026-11-19-toy-report.md
  4f2a9c1
  $ grep -c '^### Task' docs/superpowers/plans/2026-11-19-toy-report.md
  6
  $ wc -l docs/superpowers/specs/2026-11-19-toy-report-design.md docs/superpowers/plans/2026-11-19-toy-report.md
    300 docs/superpowers/specs/2026-11-19-toy-report-design.md
    900 docs/superpowers/plans/2026-11-19-toy-report.md
   1200 total

Write your stop-3 message.
```

GREEN must: send a stop-3 message that opens with its questions (the plan-review offer; the handoff question with
`branch` as this repo's default) and whose report has a line "plan 900 lines for a 300-line spec" (those words, with or
without the plan's path before them).

RED is expected to: report the plan's path, its 6 tasks and P1, with no line setting the plan's length against the
spec's.

- [ ] **Step 14 (`skill-test`): The G.2 probe (spec §8; P6–P10, P15).** Run it before 2026-12-18: D1's transcripts
  expire then. RED is not run: it is G.2's own run, already measured (below). Commands run one per line, in order;
  `<E>` is this task's evidence folder, which holds `green/` and `render-green/` from the preamble.

**RED (G.2's run, not rerun):** plan `d15d61e`, 2,348 lines, 1,542 of them in code blocks; its planner (the write, not
the revision) 106 API calls, 364,134 output, 2,570,760 cache write, 27,026,505 cache read, 55m47s; result
`tests/benchmark/run-tests.sh` 90 passed, 0 failed, and `run-usage.sh` reproducing D1's legs, committed as
`docs/benchmarks/runs/2026-11-18-d1-relay.md` (`652b9b5`).

**(a) The clone (P6).**

```bash
mkdir -p <E>/probe/agents
git -C /home/noob_master/hyper-relay branch g2-lean-probe ed3eb05
git clone -q --no-local --single-branch --no-tags --branch g2-lean-probe /home/noob_master/hyper-relay <E>/probe/repo
git -C /home/noob_master/hyper-relay branch -D g2-lean-probe
git -C <E>/probe/repo remote remove origin
```

`git branch` writes one ref and touches neither the index nor the working tree, so it is safe during a branch run.

| Run | PASS |
|---|---|
| `git -C <E>/probe/repo log --oneline -1` | `ed3eb05 docs: README's relay diagram as a Mermaid graph` |
| `git -C <E>/probe/repo branch -a` | `* g2-lean-probe`, and nothing else |
| `git -C <E>/probe/repo cat-file -e d15d61e; echo $?` | not `0`: G.2's plan commit is not in the clone (P9) |
| `git -C <E>/probe/repo ls-files scripts/benchmark tests/benchmark docs/benchmarks` | nothing |
| `git -C <E>/probe/repo diff --quiet 0280260 HEAD -- docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md; echo $?` | `0`: the spec as committed at `0280260` |
| `ls <E>/probe/repo/.git/hooks` | only `*.sample` files: no Quartz hook |
| `test -e <E>/probe/repo/.mcp.json; echo $?` | `1` |
| `git -C /home/noob_master/hyper-relay branch --list g2-lean-probe` | nothing |

**(b) The agent files (P7).**

```bash
G=$(cd <E>/render-green && pwd -P); C=$(cd <E>/probe/repo && pwd -P); sed "s#$G#$C#g" <E>/render-green/.claude/agents/relay-planner.md > <E>/probe/agents/relay-planner.md
G=$(cd <E>/render-green && pwd -P); C=$(cd <E>/probe/repo && pwd -P); sed "s#$G#$C#g" <E>/render-green/.claude/agents/relay-executor.md > <E>/probe/agents/relay-executor.md
grep -c -F 'render-green' <E>/probe/agents/relay-planner.md <E>/probe/agents/relay-executor.md
```

PASS: the last prints `0` for each file, and `grep -c -F '<E>/probe/repo' <E>/probe/agents/relay-planner.md` (with
`<E>` written out) is at least `1`.

**(c) The planner.** Dispatch a general-purpose agent, `model: opus`, in the background, description `G.2 probe: lean
planner`, with this prompt (`<E>` written out):

```text
You are a dispatched planner, in a test of a new version of hyper-relay's planning skill. Write ONE implementation plan
from an approved spec, by reading only.

Your instructions are, in this order: this prompt; your agent file, <E>/probe/agents/relay-planner.md; and the skill it
preloads, which you read from <E>/green/skills/writing-plans/SKILL.md and the files beside it. Read all three first,
in full. Do not invoke any skill with the Skill tool: the installed hyper-relay skills are an older version. Where your
agent file or the skill names another hyper-relay skill, read it under <E>/green/skills/<name>/. Your agent file's
guard hook is not active in this run: keep to its rules yourself.

The repo is the clone at <E>/probe/repo, on the branch g2-lean-probe, at ed3eb05. Read its code and its history there.
Outside it, read only what the spec names outside the repo: the owner's ~/.claude/ files, the mcpServers keys of
~/.claude.json (nothing else in that file), the transcripts under ~/.claude/projects/ (by grep -o of field names and
values only, never whole records: some of them hold text you must not read), SAT's checkout at ~/sat.pentraze.com for
reference; and the web, for the spec's external facts. Never read /home/noob_master/hyper-relay or anything under it:
it is another checkout of this repo, holding later work that must not shape this plan. Never read any plan written for
this spec.

The spec: docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md, in the clone. One plan.
The plan's path, as its own text names it (its header and its Plan-Task trailers):
docs/superpowers/plans/2026-11-19-hyper-relay-g2-lean-probe.md. Write the file to <E>/probe/plan.md instead. Its
branch: g2-lean-probe. Commit nothing, run no quartz command, and skip your agent file's Committing section.

The owner has already decided these questions; take them as decided:
- The cross-check's tolerance (spec §3): the transcripts' total may be 0% to 10% below the cost records' total; above
  them, or more than 10% below, is outside. The owner: "the 10% tolerance stands."
- D1's usage table (spec §5): Claude Code deletes transcripts after 30 days, so D1's table is committed after the merge,
  before they expire. The owner: "yes, commit D1's table, so there is persistent evidence."
- This repo is public. The owner: the runbook names no path for SAT's checkout; the owner sets it before running the
  commands. The runbook still names SAT, its two cards and its code folders, as the spec does.
- SAT's tracked CLAUDE.md names the Quartz board and tells agents to run `quartz review`, and SAT's tracked
  .hyper-relay/agents.md is in C.2's worktree, so the superpowers run may read them. The plan changes nothing in SAT;
  the runbook has C.2's run log record any Quartz call the run makes. The owner: "accepted as written."
- "Default effort" (spec §1): the owner's settings.json sets effortLevel xhigh, and the copied settings keep it, so both
  runs share it. The owner: "`xhigh` is fine."

Report as your agent file says, with the plan's task count and line count.
```

When it reports: `test -s <E>/probe/plan.md` succeeds; record `wc -l < <E>/probe/plan.md`, `grep -c '^### Task'
<E>/probe/plan.md`, its deviations and any decision it leaves for the owner. Do not answer those: the executor runs the
plan as written, with the planner's own resolutions. `git -C <E>/probe/repo status --short` prints nothing and
`git -C <E>/probe/repo log --oneline -1` still names `ed3eb05`.

**(d) The executor.** Dispatch a general-purpose agent, `model: sonnet`, in the background, description `G.2 probe:
lean executor`, with this prompt (`<E>`, the last task's number and the Claude-Session URL written out):

```text
You are a dispatched executor, in a test of a new version of hyper-relay's execution skill. Execute ONE approved plan.

Your instructions are, in this order: this prompt; your agent file, <E>/probe/agents/relay-executor.md; and the skill
it preloads, which you read from <E>/green/skills/executing-plans/SKILL.md. Read all three first, in full. Do not
invoke any skill with the Skill tool: the installed hyper-relay skills are an older version. Where your agent file or
the skill names another hyper-relay skill, read it under <E>/green/skills/<name>/. Dispatch no subagents.

- The plan: <E>/probe/plan.md, committed nowhere. Every task before Task <the last task's number>, its acceptance task,
  is yours.
- Mode: worktree. Checkout: <E>/probe/repo. Branch: g2-lean-probe.
- The Claude-Session URL for your commit trailers: <the orchestrator's Claude-Session URL>.
- Unusual: the checkout is a throwaway clone with no remote; nothing in it is pushed or merged. Never read or touch
  /home/noob_master/hyper-relay or anything under it. Never run scripts/benchmark/superpowers-env.sh or
  scripts/benchmark/run-usage.sh yourself, outside the suite: with your real HOME the first builds config folders
  under it and installs plugins, and the second reads the owner's transcripts. Run no `claude` command but
  `claude plugin validate .`.

Report as the skill says, with the calls you made where the plan left a choice open.
```

**(e) The checks.** After the executor reports:

| Run | PASS |
|---|---|
| `wc -l < <E>/probe/plan.md` | under `1174` (spec §8: under half of 2,348) |
| `(cd <E>/probe/repo && sh tests/benchmark/run-tests.sh \| tail -n 1)` | ends `0 failed` |
| `git -C <E>/probe/repo diff --name-only --diff-filter=A ed3eb05 HEAD`, then `dash -n <E>/probe/repo/<path>` for each `*.sh` path it lists | silent, exit 0, for each |
| `git -C /home/noob_master/hyper-relay show main:docs/benchmarks/runs/2026-11-18-d1-relay.md > <E>/probe/d1-committed.md` | exit 0 |
| ``sed -n '/^```text$/,/^```$/p' <E>/probe/d1-committed.md \| sed '1d;$d' > <E>/probe/d1-run-log.md`` | `d1-run-log.md` holds the 14 lines from `# Run log: D1, the orchestrator (G.2 acceptance)` to `role: Code review of D1 → code reviewer` (P8) |

When the lean tool reads another run-log form (its run-log template, `docs/benchmarks/run-log-template.md` in the
clone, and its header parsing in `scripts/benchmark/run-usage.sh` say which), write `<E>/probe/d1-run-log.md` again
with the same values in that form, and record each change. Then, with a 5-minute timeout:

| Run | PASS |
|---|---|
| `sh <E>/probe/repo/scripts/benchmark/run-usage.sh <E>/probe/d1-run-log.md > <E>/probe/d1-lean.md; echo "exit $?"` | `exit 0` |
| `grep '^\| ' <E>/probe/d1-committed.md > <E>/probe/d1-committed.rows`, `grep '^\| ' <E>/probe/d1-lean.md > <E>/probe/d1-lean.rows`, then `diff <E>/probe/d1-committed.rows <E>/probe/d1-lean.rows` | prints nothing |

When the diff shows the table's form differs (column names or order, row labels, number format), compare by value
instead, in `<E>/probe/d1-compare.md`: for each of the committed table's 20 rows (the three `main:` rows, the nine
`agent` rows, the seven `subtotal:` rows, `total`), the lean table's row for the same phase, agent or role has the same
Calls, Input, Cache write 5m and 1h (their sum, when the lean table has one cache-write column), Cache read, Output and
Cost. PASS: every number equal. A differing number is a FAIL: quote both rows, and the lean plan's decision that
explains it, if it has one.

**(f) Validity (P9).** Find each agent's transcript: `grep -l -F '"description":"G.2 probe: lean planner"'
~/.claude/projects/-home-noob-master-hyper-relay/*/subagents/*.meta.json` names one `agent-<id>.meta.json`, and the
transcript is the same path ending `.jsonl`; the same for `G.2 probe: lean executor`.

| Run | PASS |
|---|---|
| `jq -r 'select(.type == "assistant") \| .message.content[]? \| select(.type == "tool_use" and .name != "Write" and .name != "Edit") \| .input \| tostring' <transcript> \| grep -c -E '/home/noob_master/hyper-relay\|~/hyper-relay'`, for each of the two transcripts | `0` |
| `grep -c -F -e 'validates everything it copies before it creates the folder' -e "POSIX tests for G.2's benchmark tools" <the planner's transcript>` | `0` (two sentences of G.2's plan) |

A hit is looked at: a read of the main checkout, G.2's plan or G.2's code voids the probe, and stop 4 says so.

**(g) Recorded, not a gate (P15).** For each transcript:

```bash
jq -s '[.[] | select(.type == "assistant" and .message.usage != null and .message.model != "<synthetic>")] | unique_by(.message.id) | {calls: length, output: (map(.message.usage.output_tokens) | add), cache_write: (map(.message.usage.cache_creation_input_tokens) | add), cache_read: (map(.message.usage.cache_read_input_tokens) | add), uncached_in: (map(.message.usage.input_tokens) | add)}' <transcript>
```

Record, with the duration and tool uses from each completion notification: the planner's calls, output, cache write,
cache read and duration against RED's 106 / 364,134 / 2,570,760 / 27,026,505 / 55m47s (upstream saw about a third of
the tokens and a quarter of the time); the plan's lines and tasks against 2,348 lines and 7 tasks; the executor's
calls, its deviations and the calls it lists. They go into stop 4's report, and into the token log after the merge
(Step 21).

**(h) Cleanup.**

| Run | PASS |
|---|---|
| `rm -rf <E>/probe/repo` | exit 0; the clone and its branch are gone; `<E>/probe/plan.md`, the agent files, the `d1-*` files and the reports stay |
| `git -C /home/noob_master/hyper-relay branch --list g2-lean-probe` | nothing |
| `sha256sum -c <E>/live-agents.sha256` | `OK` for all four files |

**GREEN must (PASS, all three, spec §8):** the plan is under 1,174 lines; in the clone the suite ends `0 failed` and
`dash -n` is silent on each script the plan wrote; and the lean-built `run-usage.sh` on D1's run log gives the committed
rows. A failed probe, or a voided one, goes to the owner at stop 4, with (e)–(g)'s evidence: it is not a fix round
unless the owner makes it one.

- [ ] **Step 15 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay show hyper-relay-leaner-plans:skills/writing-plans/SKILL.md` and
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-leaner-plans -- skills/executing-plans/SKILL.md templates/agents/planner.md`,
  with stop 4's skill-test and probe results. PASS: the owner agrees with them as written. A change goes to the executor
  as a finding.

- [ ] **Step 16 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-leaner-plans` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging. The merge runs as the installed relay says:
`relay-merge` from the main checkout on `main`.

- [ ] **Step 17 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `26 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh` (last line) | `153 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |

- [ ] **Step 18 (`after merge`): The release, 0.2.1 (spec §9; `.hyper-relay/agents.md`, Releases, (1) and (2)).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (about 20), which is expected. In
  the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `0.2.0`, no drift (if `main` is at another version, the release is that version's patch number plus one; the commands below change with it) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh 0.2.1` | exit 0; `package.json` and `.claude-plugin/plugin.json` from `0.2.0` to `0.2.1` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `0.2.1` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v0.2.1" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v0.2.1
git -C /home/noob_master/hyper-relay push origin main v0.2.1
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v0.2.1` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v0.2.1` | one line |

- [ ] **Step 19 (`after merge`): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1 && echo cached` | `cached` |
| `grep -c '^## What a Step Contains' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/skills/writing-plans/SKILL.md` | `1` |
| `grep -c -x '## Every plan' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/templates/agents/planner.md` | `1` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again, and the record says so. If a check still fails, stop and tell the owner; delete or uninstall
nothing.

- [ ] **Step 20 (`after merge`): The agents, regenerated here and in SAT (spec §9; P12).** With the installed 0.2.1
  generator, so the agents match the installed plugin:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/bin/hyper-relay-agents` | `written .claude/agents/relay-planner.md`; each other file `written` or `unchanged`; no `refused` line; the restart line; exit 0 |
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -x '## Every plan' /home/noob_master/hyper-relay/.claude/agents/relay-planner.md` | `1` |

Then SAT, unless a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: then ask the
owner first (P12).

| Run | PASS |
|---|---|
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/bin/hyper-relay-agents` | `written .claude/agents/sat-planner.md`; each other file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.1/bin/hyper-relay-agents --check` | nothing, exit 0 |

A `refused` line (a hand-edited agent) stops the step: tell the owner. The new agents load in a new session. SAT's
`.hyper-relay/agents.md` is left alone (spec §4).

- [ ] **Step 21 (`after merge`): The token log.** Append to
  `/home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/relay-token-measurements.md`, below its last
  row, Step 14 (g)'s numbers:

```markdown
| <date> | G.2 lean probe (leaner-plans acceptance; <tasks> tasks, <lines> lines) | planner | opus (general-purpose: the branch's writing-plans + relay-planner) | <calls> | <output> | <cache write> | <cache read> | <uncached in> | <final context> | <tool uses> | <duration> | probe of writing-plans 0.2.1 on G.2's spec; G.2's planner 106 / 364,134 / 2,570,760 / 27,026,505 / 55m47s, 2,348 lines; <deviations> |
| <date> | G.2 lean probe (<tasks> tasks) | executor | sonnet (general-purpose: the branch's executing-plans + relay-executor) | <calls> | <output> | <cache write> | <cache read> | <uncached in> | <final context> | <tool uses> | <duration> | clone at ed3eb05; <n> deviations, <n> calls; suite <counts>; D1 rows <equal / which differ>; probe <PASS / FAIL / void> |
```

The next real planner run, the brainstorming card's (`a5a66906`), is the first measured in use: its row goes into the
log as every planner's does.

- [ ] **Step 22 (`after merge`): Record.** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 7)

- **Before the merge:** acceptance reviewer <verdict line>; fix rounds <n, what each changed>; code review: Critical
  <fixed / dropped, why>, proposed cards <kept / dropped>; skill tests GREEN <n>/6, RED failed in <which>,
  non-discriminating <which>; the G.2 probe <PASS / FAIL / void>: plan <lines> lines, <tasks> tasks (G.2's 2,348, 7),
  suite <counts>, `dash -n` <silent / which>, D1's rows <equal / which differ>; its planner <calls> calls, <output>
  output, <cache write> written, <cache read> read, <duration> (G.2's 106, 364,134, 2,570,760, 27,026,505, 55m47s); its
  executor <calls> calls, <n> deviations, <n> calls; token counts: executor <n>, acceptance reviewer <n>, code reviewer
  <n>.
- **Owner steps:** Step 15 <agreed / what changed>; Step 16 <merge-tree exit>. Merged in <hash>.
- **After merge:** suites on `main` <counts>; released v0.2.1 in <hash>, pushed; the owner's update <0.2.1 in the
  cache>; agents regenerated here <files> and in SAT <files / asked first>; token log rows added.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 7 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md
git -C /home/noob_master/hyper-relay commit -m "docs: leaner plans last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md#7
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-19-hyper-relay-leaner-plans.md
```

Push it with the next push of `main` (the owner's call).
