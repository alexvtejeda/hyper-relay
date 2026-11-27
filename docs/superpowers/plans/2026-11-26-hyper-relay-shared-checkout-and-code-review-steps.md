# hyper-relay: a chain of plans shares one checkout, and code-review steps, Implementation Plan

**Cards:** Plans that run one after another share one worktree (`af65b2bc-b565-4a8f-8e39-bd0517f18625`), Reviewer steps that only run commands go to a cheaper place (`abb0ccba-84a2-4312-9bdd-9512b806d6da`)
**Spec:** `docs/superpowers/specs/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–5 are
> the executor's. Task 6 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** A plan stacked on another runs in its base's checkout once the base's reviews are done, and the pair gets
one click-through and one merge; and a plan's reading checks become `code-review` steps that the code reviewer runs
within its one review, so a plan with nothing to run needs no acceptance reviewer.

**Architecture:** `relay-plan` learns a fifth step kind, `code-review`, for `steps`, `step` and `check` (Task 1, with
its suite, a new fixture and `docs/relay-plan.md`). `writing-plans` sorts checks into the two kinds and its plan
reviewer checks the sort (Task 2); the code reviewer's template gets `{PLAN_STEPS}`, runs each listed step and gives
it a verdict (Task 3); the orchestrator hands the steps to the code review, sorts their FAILs and reports them
(Task 4). Then the orchestrator's leg files run a chain in one checkout: the cut after the base's reviews, the
stacked plan's reviews at once on the `<B>..<S>` range, one stop 4, one `relay-merge <B> <S>`, and a fix to the base
after the cut (Task 5). Task 6 accepts it: three readings, a live `relay-plan` check, nine RED/GREEN skill tests, and
the 0.2.10 release.

**Tech Stack:** POSIX `sh` run by dash (`bin/relay-plan` and its suite); Markdown skills; the relay guard
(`tests/orchestrating/run-tests.sh`) and the skill-size and skill-layout suites.

**How this was checked:** written against `main` at `e2c68cd`, by reading only (the spec, the files below,
`bin/relay-merge`'s landing loop, the role templates, and the newest plans for format); nothing was built, run or
generated. The spec flags no fact for re-check, so none was re-checked.

---

## Execution notes (binding)

- **Line numbers are `main`'s at `e2c68cd`.** Before Task 1, `git diff --stat e2c68cd HEAD -- skills bin tests
  docs/relay-plan.md` must print nothing. If it prints anything, anchor every edit on its quoted text, not its numbers,
  and record a deviation.
- **The skills you follow are not the ones you write.** Your preloaded `executing-plans`, this run's orchestrator and
  the `relay-plan` on your `PATH` are the installed plugin's (0.2.9). Run your gates as it says. The branch's
  `relay-plan` runs only through its suite (`sh tests/relay-plan/run-tests.sh`, which runs `dash "$RP"`).
- **Text is written exactly** where a step says "Replace X with Y" (the Edit tool, X as `old_string`, Y as
  `new_string`), "Insert … after the line L" or "Delete". A block's own fence lines are not part of the text; fences
  inside a four-backtick block are. Keep each line break as written. If an X or an anchor is not found, read the range
  again; if it moved or differs slightly, adapt as little as possible and record a deviation; if it is gone, stop and
  report. Tasks 4 and 5 edit the same files in turn: an X in Task 5 that Task 4 wrote is quoted as Task 4 leaves it.
- **The relay guard holds the words.** Any text you adapt keeps to what `tests/orchestrating/run-tests.sh` checks:
  nothing under `skills/orchestrating/` holds `rerun the gates`, `second fix round`, `/home/`, `~/`, `/Users/` or
  `/tmp/`, and every `` `<file>.md` §N `` there names a `## N.` heading of that file; nothing under
  `skills/requesting-code-review/` holds `each task`, `per task`, `next task`, `completing tasks` or `task` followed
  by a space and a digit, in any case; `skills/writing-plans/SKILL.md` keeps the line holding
  "No `reviewer` step reruns the full gates", word for word. The guard's count stays `48 passed, 0 failed`; the guard
  itself does not change.
- **The suites are the contract.** `tests/relay-plan/run-tests.sh` keeps every existing assertion but one: the
  `fails_alone "acceptance"` line (line 550) changes only its expected FAIL line, which gains `code-review`. Its
  header's `Expect:` count changes. `tests/relay-plan/fixtures/plan.md` does not change. Needing to change any other
  existing assertion is a stop.
- **`bin/relay-plan`** stays POSIX sh run by dash: `set -u`, never `set -e`, `LC_ALL=C`, mode `100755`.
- **Every `skills/*/SKILL.md` stays under 20,000 bytes** (`tests/skill-size/`). Measured on `main`:
  `writing-plans/SKILL.md` 17,118 bytes, about 17,800 after Task 2; `orchestrating/SKILL.md` 10,257, about 10,900 after
  Tasks 4 and 5; `requesting-code-review/SKILL.md` 4,166, about 4,600 after Task 3. Nothing overflows, so nothing moves
  to a file beside its `SKILL.md`; `reviewing.md` (18,279 bytes) and the other leg files are not `SKILL.md` files and
  have no limit.
- **The skill tests are Task 6's.** Do not dispatch subagents or run pressure scenarios for these skill edits, whatever
  `writing-skills`' Iron Law says. Do not run `claude -p` or upstream's live suites.
- The spec's values, verbatim:
  - the catch-up prompt after a fix to the base: "Catch-up round: your base `<B>` changed (`<commits>`). Merge `<B>`
    into your branch, rerun your full gates, and report.";
  - moment 8's status: `code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS;
    skill tests G/S GREEN`, leaving out "plan steps P/Q PASS" when the plan has no `code-review` steps;
  - the base's moment-8 `next:`: `cut <S> in this checkout`;
  - moment 6 without `reviewer` steps: `acceptance done, no reviewer steps`;
  - the handoff line: "stacked on plan 1; starts in plan 1's checkout once plan 1's reviews are done";
  - the rule kept word for word: "No `reviewer` step reruns the full gates".
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.9; Task 6 releases 0.2.10
  after the merge.
- **The full gates:** `sh tests/relay-plan/run-tests.sh`, `dash -n bin/relay-plan`, `sh tests/orchestrating/run-tests.sh`,
  `sh tests/skill-size/run-tests.sh`, `sh tests/skill-layout/run-tests.sh` and `claude plugin validate .` (it passes
  with `CLAUDE.md`'s three known warnings).
- **Task 6 is not yours.** After Task 5 and the full gates, report and stop.

## Review Focus

1. **A near-miss kind,** `code review` with a space (as `after merge` has one): `check` refuses it, naming the five
   kinds, and `steps <plan> 'code review'` is a usage error (exit 2); neither reads it as `code-review`. Task 1 Step 1
   ("code review with a space").
2. **`code-review` and `reviewer` kept apart:** `steps <plan> reviewer` never lists a `code-review` step, and a plan
   whose steps are all `code-review`, `owner` or `after merge` prints only the summary line and exits 1, the
   orchestrator's cue to dispatch no acceptance reviewer. Task 1 Step 1 ("never a reviewer step", "no reviewer step").
3. **A `code-review` step written the way plans write steps:** more after the kind in its parenthesis
   (`` (`code-review`, a reading) ``) and a title that wraps onto the next line: listed with its kind and its whole
   title on one line. Task 1 Step 1 (the fixture's Step 3).
4. **A folder that is not ready for the cut** (on another branch, mid-merge, dirty, an executor still in it, or the
   base's stack up with its `.env`): the cut checks first, takes the stack down while `<B>` is still checked out, and a
   fix to the base switches the folder back only while no executor works there; the stacked plan's catch-up then
   merges `<B>`, not `main`. Task 5 Step 1's text and Step 5's checks; Task 6 Steps 2 and 6 (S2).
5. **A chain's merge that half lands** (`<B>` lands, `<S>` fails): `<B>` stays landed, `<S>` goes through its exit
   code's handling, and a retry names both branches, so that `<B>`'s branch is deleted too (`relay-merge` cleans up
   only after every branch it was given has landed). Task 5 Step 3's text; Task 6 Step 2.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §2: `relay-plan check` "accepts `code-review` as a kind; any other unknown kind is still refused" | The refusal names the five kinds: `Step <id>: "<who>" is not reviewer, code-review, owner, after merge or skill-test`. The suite's one assertion of the old message (line 550) changes with it; it is the only existing assertion that changes. |
| P2 | §2: the tests use "a fixture plan with `code-review` steps" | A new fixture, `tests/relay-plan/fixtures/code-review.md`, beside `plan.md`, which stays unchanged so that its assertions do. Its five acceptance steps mix every kind but `skill-test`; one has more after its kind and a wrapped title (Review Focus 3). `acceptance_steps` already reads any kind in backticks, so only `cmd_steps`' case and `check_acceptance` change. |
| P3 | §2 Old plans; §4: this plan's reading checks are `reviewer` steps | Task 6 Steps 1–3 are reading checks under `reviewer`; Step 4 is the live run in a temporary repo. No step of this plan uses `code-review`. |
| P4 | §6: the reviewer templates need no change unless a line names a reading check | Read: `templates/agents/reviewer-commands.md` and `reviewer-browser.md` run "only the steps the dispatch names, the plan's `reviewer` steps", and no line names a reading check. Unchanged; no repo's role agents need regenerating. |
| P5 | Scope leaves out `executing-plans`; §1's catch-up merges `<B>` | **For the owner.** `executing-plans`' "Catch-up and conflict rounds" step 1 already merges "`main`, unless the prompt names another branch", so the new prompt works as written, and the skill is unchanged. Its "Catch-up" bullet ("that branch has merged") and its Never list ("of `main` into your own branch") now lag the chain's case; a later card can align them. |
| P6 | Scope leaves out `README.md` | **For the owner.** Lines 70–72 ("Several plans can be in flight at once, each in its own worktree … stacked on its branch") stay true for plans in parallel and say nothing wrong about a chain; unchanged. |
| P7 | §1: `{BASE_SHA}` is the base's tip for a stacked branch whose base has not merged | Written in `reviewing.md` §3's range and, for the same rule ad hoc, in `requesting-code-review`'s SHAs block and `code-reviewer.md`'s `{BASE_SHA}` line (both files are in Scope). |
| P8 | §1: "The skill tests take RED's skills from `<B>`" | **For the owner to confirm.** Besides `reviewing.md` §3, `writing-plans`' `RED is expected to:` line says a stacked plan's RED reads the skills as its base leaves them, so that its planner predicts RED from them. One parenthesis. |
| P9 | §2: a reading check under `reviewer`, or a live one under `code-review`, "is a finding" for the plan reviewer | It goes in the plan reviewer's "The acceptance task" row, which is not advisory, so it blocks, as a step with no kind does today. |
| P10 | §2: "`code-review.md` gets a section for them"; "the summary lists each FAIL by its step number" | `### Plan Steps`, first in the Output Format, only when steps were listed. The summary adds `Plan steps: P/Q PASS` (moment 8's counts) and one line per FAIL. |
| P11 | §2: a FAIL "is checked against the code first, as a Critical is … a real one is §2's" | A real FAIL sorts as an acceptance FAIL does (an execution bug is a fix round, counting toward the cap; a gap goes to the owner). A real Critical keeps today's handling. When the code reviewer cannot be resumed after a fix, you read the fix diff as today, and a fresh code reviewer reruns only the failed steps. |
| P12 | §1 The cut, step 1, and Branch mode's preconditions | One check list for both modes: on `<B>`, no `MERGE_HEAD`, `status --porcelain` empty; in branch mode with `--untracked-files=no`, so the held-back docs may stay. |
| P13 | §1 Branch mode: the cut is a `git switch -c` in the main checkout | `dispatching.md` §6's "No git writes" gains its one exception, a chain's own switches, made while no executor works there; the hold-back rules last until the chain's last branch merges. |
| P14 | §1: "after the cut its status says it waits for `<S>`'s reviews and the joint stop 4" | The base's line's `next:` becomes `the chain's stop 4, after <S>'s reviews`, posted with `<S>`'s moment 3; `quartz.md`'s moment-8 row names both of the base's `next:` values. |
| P15 | §1: when `<B>` lands and `<S>` fails, `<B>` stays landed | A retry names both branches: `relay-merge` lands an already-merged branch as "already in main" (`bin/relay-merge` lines 199–202) and deletes it with the rest, which it does only after every branch given has landed (lines 240–258). |
| P16 | §1 Where work stands | `SKILL.md`: the stacked branch's row goes by its review status with `<base branch>..<branch>`; the "code review done" row names the cut and the chain's stop 4 for a base; one sentence reads the ranges for a stacked branch. |
| P17 | §3: "the plan may rename" the branches | The chain is `billing-api` and `billing-web` in `/home/user/shop` (S1–S5); S6's plans are `coupons-api` and `coupons-web`; S8 and S9 share `invoice-copy`. |
| P18 | §3 S9: the code reviewer "is given step 2" | The situation says that a value whose placeholder the template does not name was left out of the prompt, so RED (on `main`'s template, which has no `{PLAN_STEPS}`) reviews without step 2, as a real dispatch from `main` would. |
| P19 | §4: "`relay-plan` handles the new kind on a scratch plan in a temporary repo" | Task 6 Step 4 also runs `main`'s `relay-plan` on the same scratch plan, to show the refusal the change removes. |
| P20 | §1: "`parallel.md` §3 keeps that text for this case" (a second plan on the same base) | §3 is rewritten whole; its catch-up text and hold survive in the tree's bullet, with `main` as the merge's base. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–5; 6 |
| Decisions (owner) | 5 (decisions 2–4: the start after the base's reviews, one stop 4, one checkout); 1–4 (decision 5: approach A); 6 (decision 6: the nine scenarios and the release) |
| How it works | 5 (the `wt`, `relay-merge` and Quartz facts the cut and the merge rest on); 1 (`relay-plan`'s kinds); 2 (the step rules, guard case 8, the size limit); 3 (the code reviewer's placeholders and `{BASE_SHA}`) |
| Approaches | No task: the owner's picks are this plan |
| 1. A chain of plans shares one checkout | 5; 3 (`{BASE_SHA}` for a stacked branch); 2 (RED for a stacked plan); 6 (Steps 2, 5–10) |
| 2. `code-review` steps | 1; 2; 3; 4; 6 (Steps 3, 4, 11–13) |
| 3. Pressure scenarios (the plan's skill tests) | 6 (Steps 5–13) |
| 4. Testing and acceptance | 1 (the suite, `dash -n`); 2–5 (the guard, the size and layout suites); the full gates; 6 (Steps 1–4) |
| 5. Release | 6 (Steps 16–17) |
| 6. Out of scope, and left to the builder | No task: `wt`, `relay-merge` and the templates are unchanged (P4); the builder's calls are P1–P20 |

## File structure

- **Create (Task 1):** `tests/relay-plan/fixtures/code-review.md`.
- **Modify (Task 1):** `bin/relay-plan`, `tests/relay-plan/run-tests.sh`, `docs/relay-plan.md`.
- **Modify (Task 2):** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.
- **Modify (Task 3):** `skills/requesting-code-review/code-reviewer.md`, `skills/requesting-code-review/SKILL.md`.
- **Modify (Task 4):** `skills/orchestrating/reviewing.md`, `skills/orchestrating/quartz.md`,
  `skills/orchestrating/SKILL.md`.
- **Modify (Task 5):** `skills/orchestrating/parallel.md`, `skills/orchestrating/dispatching.md`,
  `skills/orchestrating/reviewing.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/SKILL.md`.
- **Unchanged:** `templates/`, `hooks/`, `.claude-plugin/`, `package.json`, `bin/wt`, `bin/relay-merge`,
  `skills/orchestrating/planning.md`, `skills/executing-plans/`, `README.md`, `CLAUDE.md`, `.hyper-relay/`,
  `tests/orchestrating/`, `tests/relay-plan/fixtures/plan.md`. No repo's role agents need regenerating.

---

### Task 1: `relay-plan` knows the `code-review` kind (spec §2; P1, P2)

**Files:**
- Create: `tests/relay-plan/fixtures/code-review.md`
- Modify: `bin/relay-plan:9,322,493-494`
- Modify: `tests/relay-plan/run-tests.sh` (header line 8; a helper after `variant`, line 286; line 550; a new section
  before `echo '--- overlap'`)
- Modify: `docs/relay-plan.md:52-53,70,89`

**Interfaces:**
- Produces: `relay-plan steps <plan> code-review`, which prints the summary line and the `code-review` steps, or only
  the summary line and exit 1 when there are none; `relay-plan check` accepting the kind; the refusal line
  `Step <id>: "<who>" is not reviewer, code-review, owner, after merge or skill-test`. Tasks 4 and 6 name them.

- [ ] **Step 1: Write the fixture and the failing tests**

Create `tests/relay-plan/fixtures/code-review.md`, written in full because its kinds, titles and wrap are what the
tests check:

````markdown
# Review Steps Implementation Plan

**Spec:** `docs/superpowers/specs/2026-01-04-review-design.md`

**Goal:** A fixture for relay-plan's suite: an acceptance task with `code-review` steps.

---

### Task 1: The page

**Files:**
- Modify: `web/page.html`

- [ ] **Step 1: Commit**

```bash
git add web/page.html
git commit -m "feat: the banner" -m "Plan-Task: docs/superpowers/plans/2026-01-04-review-plan.md#1"
```

### Task 2: Acceptance. Not the executor's

- [ ] **Step 1 (`code-review`): Only the planned files.**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `web/page.html` |

- [ ] **Step 2 (`reviewer`): The banner shows on the stack.**

- [ ] **Step 3 (`code-review`, a reading): The copy reads as the spec
  says.**

- [ ] **Step 4 (`owner`): The click-through.**

- [ ] **Step 5 (`after merge`, last): The release.**
````

In `tests/relay-plan/run-tests.sh`:

- After `variant` (line 286), the helper `review_repo [<sed program>]`: a `new_repo` holding the fixture at
  `CRP=docs/superpowers/plans/2026-01-04-review-plan.md` (its folders made), written through `sed "<program>"` when
  one is given and copied unchanged otherwise, then `commit_all`. Sets `CRP`.
- Line 550, the one existing assertion that changes, becomes:

```sh
fails_alone "acceptance" 'FAIL acceptance: Step 4: "the owner" is not reviewer, code-review, owner, after merge or skill-test'
```

- A new section after the `--- check` section's last case (the `builds-on` `fails_alone`, line 569–570), before
  `echo '--- overlap'`:

```sh
echo '--- code-review steps'
review_repo
rp "$MAIN" steps "$CRP"
assert_eq "code-review: listed with the other steps, as written" \
  "$(printf 'tasks 2; acceptance task 2\n1\tcode-review\tOnly the planned files.\n2\treviewer\tThe banner shows on the stack.\n3\tcode-review\tThe copy reads as the spec says.\n4\towner\tThe click-through.\n5\tafter merge\tThe release.')" "$OUT"
rp "$MAIN" steps "$CRP" code-review
assert_eq "code-review: steps code-review lists them" \
  "$(printf 'tasks 2; acceptance task 2\n1\tcode-review\tOnly the planned files.\n3\tcode-review\tThe copy reads as the spec says.')" "$OUT"
assert_eq "code-review: steps code-review: exit 0" 0 "$RC"
rp "$MAIN" steps "$CRP" reviewer
assert_eq "code-review: never a reviewer step" \
  "$(printf 'tasks 2; acceptance task 2\n2\treviewer\tThe banner shows on the stack.')" "$OUT"
CRSTEP1='- [ ] **Step 1 (`code-review`): Only the planned files.**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `web/page.html` |'
rp "$MAIN" step "$CRP" 1
assert_eq "code-review: step prints one" "$CRSTEP1" "$OUT"
rp "$MAIN" check "$CRP"
assert_eq "code-review: check accepts the kind" "ok committed
ok trailers
ok acceptance
ok skill-tests
ok placeholders" "$OUT"
assert_eq "code-review: check: exit 0" 0 "$RC"
review_repo 's/(`reviewer`)/(`code-review`)/'
rp "$MAIN" steps "$CRP" reviewer
assert_eq "no reviewer step: the summary only" "tasks 2; acceptance task 2" "$OUT"
assert_eq "no reviewer step: exit 1" 1 "$RC"
review_repo 's/(`code-review`, a reading)/(`code review`, a reading)/'
rp "$MAIN" check "$CRP"
assert_eq "code review with a space: check: exit 1" 1 "$RC"
assert_eq "code review with a space: the line" \
  'FAIL acceptance: Step 3: "code review" is not reviewer, code-review, owner, after merge or skill-test' \
  "$(printf '%s\n' "$OUT" | grep '^FAIL ')"
rp "$MAIN" steps "$CRP" 'code review'
assert_eq "code review with a space: an unknown who: exit 2" 2 "$RC"
```

- The header's `# Expect: "174 passed, 0 failed"` becomes `# Expect: "186 passed, 0 failed"` (12 new assertions).

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | grep '^FAIL'`, then `sh tests/relay-plan/run-tests.sh | tail -n 1`
Expected: exactly six `FAIL` lines: `check: acceptance: the line`, `code-review: steps code-review lists them`,
`code-review: steps code-review: exit 0` (today `code-review` is an unknown who, exit 2), `code-review: check accepts
the kind`, `code-review: check: exit 0` and `code review with a space: the line` (today's message lacks
`code-review`); last line `180 passed, 6 failed`.

- [ ] **Step 3: Implement the kind in `bin/relay-plan`**

- Line 9 of the header comment becomes `#   relay-plan steps <plan> [reviewer|code-review|owner|after-merge|skill-test]`.
- `cmd_steps` (line 322): `code-review` joins `reviewer`, `owner` and `skill-test` in the case that sets `who=$2`.
- `check_acceptance` (lines 493–494): the awk accepts `code-review` beside the other four kinds, and its message
  becomes exactly `"Step " $1 ": \"" $2 "\" is not reviewer, code-review, owner, after merge or skill-test"`.

Nothing else changes: `acceptance_steps`, `step_text` and `scenarios` already read any kind in backticks.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`, then `git ls-files -s bin/relay-plan`
Expected: `186 passed, 0 failed`; `dash -n` silent; mode `100755`.

- [ ] **Step 5: `docs/relay-plan.md`**

Replace

```markdown
``- [ ] **Step <id> (`<who>` …): <title>**``, where `<who>` is `reviewer`, `owner`, `after merge` or `skill-test`, and
the title may wrap onto the next line.
```

with

```markdown
``- [ ] **Step <id> (`<who>` …): <title>**``, where `<who>` is `reviewer`, `code-review`, `owner`, `after merge` or
`skill-test`, and the title may wrap onto the next line. A `code-review` step is a check that only reads the branch,
run by the code reviewer within the branch's code review; a `reviewer` step is the acceptance reviewer's.
```

Replace

```markdown
| `acceptance` | always | each step of the acceptance task names who runs it |
```

with

```markdown
| `acceptance` | always | each step of the acceptance task names who runs it, one of the five `<who>` above |
```

Replace ``### `relay-plan steps <plan> [reviewer|owner|after-merge|skill-test]` `` with:

```markdown
### `relay-plan steps <plan> [reviewer|code-review|owner|after-merge|skill-test]`
```

Verify: `grep -c -F 'code-review' docs/relay-plan.md` prints `3`.

- [ ] **Step 6: Commit**

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh tests/relay-plan/fixtures/code-review.md docs/relay-plan.md
git commit -m "feat: relay-plan knows the code-review step kind" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md#1"
```

### Task 2: `writing-plans` sorts checks into `reviewer` and `code-review` (spec §2, §1; P8, P9)

**Files:**
- Modify: `skills/writing-plans/SKILL.md:102-103,111`
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md:30`

- [ ] **Step 1: The kinds, in `skills/writing-plans/SKILL.md`.** Replace

```markdown
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), or **`skill-test`** (below), with its command or action and the result that counts as PASS.
- No `reviewer` step reruns the full gates. They run once on the branch, as the executor's last task, which saves their output to the run folder's `gates.log`; the orchestrator's hand-back check reads that log, and `relay-merge` runs them again on the merged result. A `reviewer` step runs what only an independent check can: a live run in a scratch repo, a check of which files the branch changed, a reading of the new text against the spec.
```

with

```markdown
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer: a check that needs something running), **`code-review`** (before the merge, by the code reviewer, within the branch's one code review: a check that only reads), **`owner`** (at the click-through), **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), or **`skill-test`** (below), with its command or action and the result that counts as PASS.
- No `reviewer` step reruns the full gates. They run once on the branch, as the executor's last task, which saves their output to the run folder's `gates.log`; the orchestrator's hand-back check reads that log, and `relay-merge` runs them again on the merged result. A `reviewer` step runs only what needs something running: a stack, a browser, a scratch repo, a live session.
- A `code-review` step only reads what the branch already holds: its diff and files, the plan and the spec, the run folder's `executor.md` and `gates.log`, with read-only commands at most (`git diff`, `git show`, `grep`, `wc`, `relay-plan gates`). It starts nothing and reruns no gate. Which files the branch changed, that existing tests keep their assertions, that copy comes from the tools, that the new text says what the spec says, that a test failed before its fix and passed after (from `executor.md` and `gates.log`): each is a `code-review` check, never a `reviewer` one. A plan whose checks all only read needs no acceptance reviewer.
```

Replace

```markdown
- **`RED is expected to:`** what an agent reading `main`'s skills (or none, for a new skill) is expected to do instead.
```

with

```markdown
- **`RED is expected to:`** what an agent reading `main`'s skills (for a stacked plan, the skills as its base leaves them; none, for a new skill) is expected to do instead.
```

- [ ] **Step 2: The plan reviewer checks the sort.** In `skills/writing-plans/plan-document-reviewer-prompt.md`,
  replace

```markdown
    | The acceptance task | It is the last task. Each of its steps says who runs it (`reviewer`, `owner`, `after merge` or `skill-test`), with its command or action and the result that counts as PASS; a `skill-test` step gives a situation, what GREEN must do and what RED is expected to do. |
```

with

```markdown
    | The acceptance task | It is the last task. Each of its steps says who runs it (`reviewer`, `code-review`, `owner`, `after merge` or `skill-test`), with its command or action and the result that counts as PASS; a `skill-test` step gives a situation, what GREEN must do and what RED is expected to do. Each check sits in its kind: a `reviewer` step needs something running (a stack, a browser, a scratch repo, a live session), and a `code-review` step only reads the branch (its diff and files, the plan, the spec, the run folder's `executor.md` and `gates.log`); a reading check under `reviewer`, or a live one under `code-review`, is a finding. |
```

- [ ] **Step 3: Verify**

| Run | Expected |
|---|---|
| `grep -c -F 'reruns the full gates' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'only reads what the branch already holds' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'a check of which files the branch changed' skills/writing-plans/SKILL.md` | `0` |
| `grep -c -F 'the skills as its base leaves them' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'or a live one under' skills/writing-plans/plan-document-reviewer-prompt.md` | `1` |
| `wc -c < skills/writing-plans/SKILL.md` | under 20000 (about 17,800) |
| `sh tests/skill-size/run-tests.sh \| tail -n 1`, then `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `12 passed, 0 failed`; `48 passed, 0 failed` |

(In a command inside a table cell, `\|` is a plain `|`.)

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: writing-plans sorts reading checks into code-review steps" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md#2"
```

### Task 3: The code reviewer runs a plan's `code-review` steps (spec §2, §1; P7, P10)

**Files:**
- Modify: `skills/requesting-code-review/code-reviewer.md` (after line 26; lines 52–55; before line 114; lines
  160–171)
- Modify: `skills/requesting-code-review/SKILL.md:25-28,34-41,46,60`

**Interfaces:**
- Produces: the placeholder `{PLAN_STEPS}`; a review's `### Plan Steps` section; the summary's `Plan steps: P/Q PASS`
  and one line per FAIL by its step number. Task 4's text names them.

- [ ] **Step 1: `skills/requesting-code-review/code-reviewer.md`.** Insert after the line `    {SPEC}` and its blank
  line (line 26), before `    ## Git Range to Review`:

```text
    ## The Plan's Code-Review Steps

    {PLAN_STEPS}

    Unless the line above says "none", it lists checks from the plan's
    acceptance task that are yours to run, within this review and nowhere
    else. Each only reads the branch, the plan, the spec or the run folder's
    files. Run each listed step exactly as the plan writes it (the command
    beside it prints the step), and give it a verdict, PASS or FAIL, with the
    command you ran or the reading you made and the lines that decide it,
    quoted, under Plan Steps in your review. Any FAIL makes your verdict
    "Ready to merge: No". A FAIL is never a card, and what a listed step
    checks is settled by its verdict: do not report it again as an issue.

```

Replace

```text
    Then reply with only a short summary: Ready to merge (Yes / No / With fixes); the
    number of Critical, Important and Minor issues; each Critical issue in one line,
    with its file and line; the cards you filed (their ids, or that they are in
    `cards.md`); and the path of `code-review.md`.
```

with

```text
    Then reply with only a short summary: Ready to merge (Yes / No / With fixes); the
    number of Critical, Important and Minor issues; each Critical issue in one line,
    with its file and line; when steps were listed, `Plan steps: P/Q PASS` (P of the
    Q listed steps passed) and each FAIL in one line, by its step number; the cards
    you filed (their ids, or that they are in `cards.md`); and the path of
    `code-review.md`.
```

Insert before the line `    ### Strengths` (in the Output Format):

```text
    ### Plan Steps
    [Only when steps were listed. For each: Step <id>: PASS or FAIL, the
    command you ran or the reading you made, and the lines that decide it,
    quoted.]

```

Replace

```markdown
- `{BASE_SHA}` — starting commit: for a branch, `git merge-base main <branch>`
```

with

```markdown
- `{PLAN_STEPS}` — the plan's `code-review` steps: each step's id with the command that prints it (`relay-plan step <plan> <id>`), or "none" (ad hoc work, and a plan without them)
- `{BASE_SHA}` — starting commit: for a branch, `git merge-base main <branch>`; for a branch stacked on another plan's branch that has not merged, that branch's tip
```

Replace

```markdown
**Reviewer returns:** a short summary: the verdict, the counts, each Critical issue, the cards it filed and the path
of `code-review.md`, which holds the full review (Strengths, Issues (Critical / Important / Minor), Recommendations,
Assessment). With no run folder, the whole review.
```

with

```markdown
**Reviewer returns:** a short summary: the verdict, the counts, each Critical issue, the plan steps' count and each
FAIL, the cards it filed and the path of `code-review.md`, which holds the full review (Plan Steps, Strengths, Issues
(Critical / Important / Minor), Recommendations, Assessment). With no run folder, the whole review.
```

- [ ] **Step 2: `skills/requesting-code-review/SKILL.md`.** Replace

````markdown
```bash
BASE_SHA=$(git merge-base main <branch>)
HEAD_SHA=$(git rev-parse <branch>)
```
````

with

````markdown
```bash
BASE_SHA=$(git merge-base main <branch>)
# a branch stacked on another plan's branch that has not merged: BASE_SHA=$(git rev-parse <base branch>)
HEAD_SHA=$(git rev-parse <branch>)
```
````

Insert after the line ``- `{SPEC}` - The spec's path``:

```markdown
- `{PLAN_STEPS}` - The plan's `code-review` steps, each id with the command that prints it (`relay-plan step <plan> <id>`), or "none" (ad hoc, or a plan without them)
```

Insert after the line that begins `- **Critical:** fixed before the merge.`:

```markdown
- **A plan step's FAIL:** fixed before the merge, as a Critical is, once the orchestrator has checked it against the code. Never a card.
```

Insert after the line `  SPEC: docs/superpowers/specs/2026-11-18-index-repair-design.md` (in the Example):

```text
  PLAN_STEPS: none
```

- [ ] **Step 3: Verify**

| Run | Expected |
|---|---|
| `grep -c -F '{PLAN_STEPS}' skills/requesting-code-review/code-reviewer.md` | `2` |
| `grep -c -F '{PLAN_STEPS}' skills/requesting-code-review/SKILL.md` | `1` |
| `grep -c -F 'Ready to merge: No' skills/requesting-code-review/code-reviewer.md` | `1` |
| `grep -c -F '### Plan Steps' skills/requesting-code-review/code-reviewer.md` | `1` |
| `grep -c -F 'git rev-parse <base branch>' skills/requesting-code-review/SKILL.md` | `1` |
| `sh tests/skill-size/run-tests.sh \| tail -n 1`, then `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `12 passed, 0 failed`; `48 passed, 0 failed` |

- [ ] **Step 4: Commit**

```bash
git add skills/requesting-code-review/code-reviewer.md skills/requesting-code-review/SKILL.md
git commit -m "feat: the code reviewer runs a plan's code-review steps" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md#3"
```

### Task 4: The orchestrator gives `code-review` steps to the code review (spec §2; P10, P11)

**Files:**
- Modify: `skills/orchestrating/reviewing.md` (§1, lines 23–24; §2, lines 50 and 75–80; §3, after line 104, lines
  106–110 and 154–160; §4, lines 181 and 184)
- Modify: `skills/orchestrating/quartz.md:183`
- Modify: `skills/orchestrating/SKILL.md:41`

**Interfaces:**
- Consumes: Task 1's `relay-plan steps <plan> code-review`; Task 3's `{PLAN_STEPS}`, `### Plan Steps` and summary.
- Produces: the words "a `code-review` step's FAIL" and "`code-review` FAIL", and `quartz.md`'s moment-8 row as this
  task leaves it (Task 5 Step 4 edits that row again).

- [ ] **Step 1: Acceptance and the fix loop, in `skills/orchestrating/reviewing.md`.** Replace

```markdown
Then post the status note (`quartz.md` §4, moment 5). When the plan has no `reviewer` steps, skip the dispatch, say
so at stop 4, and post moment 6's status now, as `acceptance done, no reviewer steps`.
```

with

```markdown
Then post the status note (`quartz.md` §4, moment 5). When the plan has no `reviewer` steps, skip the dispatch, say
so at stop 4, and post moment 6's status now, as `acceptance done, no reviewer steps`. The plan's `code-review` steps
are never the acceptance reviewer's: the code reviewer runs them (§3).
```

Replace `Sort each FAIL and each BLOCKING finding:` (line 50) with:

```markdown
Sort each FAIL and each BLOCKING finding, and each real FAIL of a `code-review` step (§3):
```

Replace

```markdown
**The fix-round cap.** Read `fix-rounds:` from the header of `main`'s facts file, as `dispatching.md` §1 reads
`execute:`; without it, the cap is 2. A finding (an acceptance FAIL, a Critical, a GREEN that failed) that still fails
after that many rounds gets no further round. File a card for it: `add_tasks` with the label `proposed`, kind `bug`,
the plan's initiative, and a body naming the plan, the step or finding, its evidence paths and "fix cap reached after
<n> rounds" (without Quartz, a section in `cards.md`). Then carry on with the rest of the loop; stop 4 opens with it
(§4). A gap in the spec or the plan is not capped: it goes to the owner at once.
```

with

```markdown
**The fix-round cap.** Read `fix-rounds:` from the header of `main`'s facts file, as `dispatching.md` §1 reads
`execute:`; without it, the cap is 2. A finding (an acceptance FAIL, a Critical, a `code-review` step's FAIL, a GREEN
that failed) that still fails after that many rounds gets no further round. File a card for it yourself (the code
reviewer files none for a FAIL): `add_tasks` with the label `proposed`, kind `bug`, the plan's initiative, and a body
naming the plan, the step or finding, its evidence paths and "fix cap reached after <n> rounds" (without Quartz, a
section in `cards.md`). Then carry on with the rest of the loop; stop 4 opens with it (§4). A gap in the spec or the
plan is not capped: it goes to the owner at once.
```

- [ ] **Step 2: The code review and stop 4, in the same file.** Insert after the line
  `acceptance and its fixes, so it reads the final diff.` (line 104), a blank line first:

```markdown
**The plan's `code-review` steps** run within that one review: its prompt's `{PLAN_STEPS}` names each id that
`relay-plan steps <plan> code-review` lists, each with the command that prints it, `relay-plan step <plan> <id>`, or
"none" when it lists none. **Verify its summary:** every listed step has its verdict, PASS or FAIL, in
`code-review.md`; a step without one goes back to the code reviewer.
```

Replace

```markdown
**A Critical** finding: check each one against the code first (`hyper-relay:receiving-code-review`), from its lines
in `code-review.md`. A wrong one is dropped, with the reason, in the stop-4 report. A real one is a fix round (§2),
and counts toward the cap. Then resume the code reviewer to check only the fix commits (when it cannot be resumed,
read that diff yourself), and have the acceptance reviewer rerun the steps the fix touches (all its steps, when that
is unclear).
```

with

```markdown
**A Critical** finding, or a `code-review` step's FAIL: check each one against the code first
(`hyper-relay:receiving-code-review`), from its lines in `code-review.md`. A wrong one is dropped, with the reason, in
the stop-4 report. A real Critical is a fix round (§2), and counts toward the cap; a real FAIL is sorted as §2 sorts
an acceptance FAIL. After the fix, resume the code reviewer to check only the fix commits and rerun the steps that
failed, appending to `code-review.md` (when it cannot be resumed, read that diff yourself, and have a fresh code
reviewer rerun only those steps), and have the acceptance reviewer rerun the `reviewer` steps the fix touches (all of
them, when that is unclear).
```

Replace

```markdown
Post the status note when you dispatch the code review and the skill-test runs (moment 7), and when the code review,
its Critical fixes and the skill tests are done (moment 8):

`code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN`

The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without skill tests leaves out
"; skill tests G/S GREEN".
```

with

```markdown
Post the status note when you dispatch the code review and the skill-test runs (moment 7), and when the code review,
its Critical and `code-review` fixes and the skill tests are done (moment 8):

`code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN`

The plan steps' part counts the Q `code-review` steps and the P that passed; a plan without them leaves out
"; plan steps P/Q PASS". The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without
skill tests leaves out "; skill tests G/S GREEN".
```

In §4's report list, replace `- the acceptance verdicts;` with

```markdown
- the acceptance verdicts, and beside them the `code-review` steps' verdicts from `code-review.md`;
```

and replace `- the Critical findings fixed, and those dropped with why;` with

```markdown
- the Critical findings and `code-review` FAILs fixed, and those dropped with why;
```

- [ ] **Step 3: Moment 8 and the stops table.** In `skills/orchestrating/quartz.md`, replace

```markdown
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN` | `stop 4` |
```

with

```markdown
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN` | `stop 4` |
```

In `skills/orchestrating/SKILL.md`'s stops table (row 4), replace
`Then gate, acceptance and skill-test results, fixes made, Critical findings fixed or dropped,` with:

```markdown
Then gate, acceptance, `code-review` step and skill-test results, fixes made, Critical findings and `code-review` FAILs fixed or dropped,
```

The row stays one line.

- [ ] **Step 4: Verify**

| Run | Expected |
|---|---|
| `grep -c -F '{PLAN_STEPS}' skills/orchestrating/reviewing.md` | `1` |
| `grep -c -F 'relay-plan steps <plan> code-review' skills/orchestrating/reviewing.md` | `1` |
| `grep -c -F 'plan steps P/Q PASS' skills/orchestrating/reviewing.md skills/orchestrating/quartz.md` | `skills/orchestrating/reviewing.md:2`, `skills/orchestrating/quartz.md:1` |
| `grep -c -F 'the code reviewer runs them' skills/orchestrating/reviewing.md` | `1` |
| `grep -c -F 'FAILs fixed or dropped' skills/orchestrating/SKILL.md` | `1` |
| `sh tests/skill-size/run-tests.sh \| tail -n 1`, then `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `12 passed, 0 failed`; `48 passed, 0 failed` |

- [ ] **Step 5: Commit**

```bash
git add skills/orchestrating/reviewing.md skills/orchestrating/quartz.md skills/orchestrating/SKILL.md
git commit -m "feat: the orchestrator gives code-review steps to the code review" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md#4"
```

### Task 5: A chain of stacked plans shares one checkout, one stop 4 and one merge (spec §1; P5, P12–P16, P20)

**Files:**
- Modify: `skills/orchestrating/parallel.md` (lines 11–14, 27–30, 37–39, 76–96, 102, 106–108)
- Modify: `skills/orchestrating/dispatching.md` (§1, lines 20–23; §2, lines 47–48; §3, after line 59 and line 66; §5,
  line 106; §6, lines 115–116 and 122–123; §7, lines 133–135 and 141–142)
- Modify: `skills/orchestrating/reviewing.md` (§2, lines 93–94; §3, lines 101–102, 118–124, 144, before the `## 4.`
  heading; §4, after the line "Stop 4 promises…"; §5, line 249)
- Modify: `skills/orchestrating/SKILL.md:78,89,92-94`
- Modify: `skills/orchestrating/quartz.md:183`

**Interfaces:**
- Consumes: Task 4's "`code-review` FAIL" and its moment-8 row.

- [ ] **Step 1: `skills/orchestrating/parallel.md`.** Replace

```markdown
builds on (§3), and the order the plans land in (§4). Each plan still goes through the leg files on its own: its
executor (`dispatching.md`), its review legs, its stop 4 and its merge (`reviewing.md`). The merge's exit codes are
`reviewing.md` §4's.
```

with

```markdown
builds on (§3), and the order the plans land in (§4). Each plan still goes through the leg files on its own: its
executor (`dispatching.md`), its review legs, its stop 4 and its merge (`reviewing.md`), except that a chain of
stacked plans shares one checkout, one stop 4 and one merge (§3). The merge's exit codes are `reviewing.md` §4's.
```

Replace

```markdown
- **All worktrees:** when two or more plans would be in flight, each runs in a worktree; Branch is offered only for a
  plan that will run alone (`dispatching.md` §1). If a branch run is already active when a second plan starts, that
  plan runs in a worktree, and its handoff line and its stop 4 say "merges after `<branch>`": the merge runs only from
  the main checkout on `main` (`reviewing.md` §4).
```

with

```markdown
- **All worktrees:** when two or more plans would be in flight, each runs in a worktree; Branch is offered only for a
  plan that will run alone (`dispatching.md` §1). A chain of stacked plans (§3) counts as one plan: its plans run one
  after another in one checkout, the base's. If a branch run is already active when a second plan starts, that plan
  runs in a worktree, and its handoff line and its stop 4 say "merges after `<branch>`": the merge runs only from the
  main checkout on `main` (`reviewing.md` §4).
```

Replace

```markdown
> Plans ready. They run at once, so each runs in its own **worktree**:
> 1. `<plan path>` (N tasks): starts now.
> 2. `<plan path>` (N tasks): stacked on plan 1; starts when plan 1 passes acceptance.
```

with

```markdown
> Plans ready. They run at once, so each runs in its own **worktree**, and a stacked plan in its base's:
> 1. `<plan path>` (N tasks): starts now.
> 2. `<plan path>` (N tasks): stacked on plan 1; starts in plan 1's checkout once plan 1's reviews are done.
```

Lines 76–96, from `## 3. Stacking` through `  stops and goes to the owner: it cannot land without its base.` (the line
before the blank line above `## 4. Landing order`), become exactly:

```markdown
## 3. Stacking

A stacked plan's header carries `**Builds on:** <base plan path>`. A plan builds on exactly one plan. A **chain** is a
base plan and the plan stacked on it; in a longer chain (C on S on B) each link follows the same rules, on its own
base. A `**Builds on:**` line whose base has already merged changes nothing: the plan runs from `main`. The base has
merged when `git log -1 --format=%h --grep='Plan-Task: <base plan path>' main` prints a commit (`relay-merge` deletes
the base's branch).

A chain's plans run one after another in one checkout, `<checkout>`: the base's worktree in worktree mode, the main
checkout in branch mode. Below, `<B>` is the base's branch and `<S>` the stacked plan's. The folder keeps the base's
name, and both branches are kept, since Quartz and `relay-merge` read them per plan. One executor works there at a
time.

- **When.** The stacked plan starts when the base's review legs are done (`reviewing.md` §3, moment 8): its
  acceptance and fix loop, its code review with every Critical and `code-review` FAIL fixed or dropped, and its skill
  tests. A finding capped on the base still becomes a card, and the cut goes ahead. The base does not go to stop 4 on
  its own: its stop 4 is the chain's (below).
- **The cut,** from the main checkout, while no executor works in `<checkout>`:
  1. `git -C <checkout> branch --show-current` prints `<B>`, `git -C <checkout> rev-parse -q --verify MERGE_HEAD`
     prints nothing, and `git -C <checkout> status --porcelain` prints nothing (in branch mode, with
     `--untracked-files=no`, so that your held-back docs may stay).
  2. When a `wt` stack is up for it, `(cd <checkout> && wt down)`, while `<B>` is still checked out: `wt down` acts on
     the checked-out branch's stack, and removes the `.env` that would stop the next `wt up`.
  3. `git -C <checkout> switch -c <S>`: the stacked branch, from `<B>`'s tip. No `wt new` and no
     `git worktree add`, which would make a second folder: the folder's install stays.
  4. `relay-plan run-dir <S plan>` makes `<S>`'s run folder; `dispatching.md` §4 links it in `<checkout>`, and §5
     dispatches its executor with the checkout `<checkout>` and the branch `<S>`, cut from `<B>`, which has not
     merged. In the status note (moment 3), the base's line's `next:` becomes `the chain's stop 4, after <S>'s
     reviews`. The executor's own `wt up` builds `<S>`'s stack, which it leaves up for the click-through.
- **The stacked plan's reviews** run as soon as its executor hands back, with no wait for the base to merge and no
  catch-up round: `dispatching.md` §7, then `reviewing.md` §1 to §3, in `<checkout>`, with `<B>..<S>` as the branch's
  range while `<B>` has not merged. A defect in the base's work that they find is the base's to fix (below), not a fix
  round on `<S>`.
- **One stop 4 for the chain,** once the last link's review legs are done, and one merge, base first:
  `relay-merge <B> <S>` (`reviewing.md` §4).
- **A fix to the base after the cut** (the owner asks for one at stop 4, "one more round" for a capped base finding,
  or a base defect the stacked plan's reviews found), only while no executor works in `<checkout>`:
  1. When `<S>`'s stack is up, `(cd <checkout> && wt down)`; then `git -C <checkout> switch <B>`.
  2. The fix round goes to the base's executor, and is verified, as `reviewing.md` §2 says. The base's reviewers rerun
     the steps the fix touches (all of them, when that is unclear), and its code reviewer, resumed, checks the fix
     commits.
  3. `git -C <checkout> switch <S>`, and `<S>`'s executor gets a catch-up round, resumed or fresh as
     `dispatching.md` §5 says: "Catch-up round: your base `<B>` changed (`<commits>`). Merge `<B>` into your branch,
     rerun your full gates, and report." A catch-up round is not a fix round: it needs no finding and counts toward
     no fix-round limit. In a longer chain, each later link then catches up in turn on its own base.
  4. `<S>`'s reviewers rerun the steps the base's fix touches (all of them, when that is unclear), and its code
     reviewer checks the merge. Then a short stop 4 again.
- **A longer chain** (C on S on B) repeats the cut link by link: `<C>` is cut in the same folder, from `<S>`'s tip,
  once `<S>`'s review legs are done, and its range is `<S>..<C>`. The one stop 4 covers every link, and the merge is
  one call, in chain order: `relay-merge <B> <S> <C>`.
- **A second plan on the same base** (S1 and S2 both on B) makes a tree, not a chain. The first in the spec's order
  shares the base's checkout; each other one gets a worktree of its own, cut from the main checkout at the same
  moment: `git worktree add .worktrees/<S2> -b <S2> <B>`, or `wt new <S2> --from <B>` in a repo with a `.wt.conf`
  (`dispatching.md` §3), which work whatever the shared folder has checked out. Its review legs (the hand-back check
  of `dispatching.md` §7, acceptance, the code review) wait until `<B>` has merged: hold its executor's report until
  then. Then, when `main` has changes its branch lacks (`git diff --quiet <S2>...main` fails), its executor first gets
  a catch-up round, resumed or fresh as `dispatching.md` §5 says: "Catch-up round: your base `<B>` has merged. Merge
  `main` into your branch, rerun your full gates, and report." Then `dispatching.md` §7 and `reviewing.md`, as for
  any plan, with a stop 4 of its own: the review range holds only its own work.
- **Base dropped or stuck.** If the owner drops the base, or its merge fails and is not recovered, the stacked plan
  stops and goes to the owner: it cannot land without its base.
```

In §4, replace

```markdown
- Each plan lands after its own stop 4; a stacked plan always after its base (§3 holds its review legs until then).
```

with

```markdown
- Each plan lands after its own stop 4, and a chain after its one stop 4, in one call, base first:
  `relay-merge <B> <S>` (§3). A second plan on the same base, in a worktree of its own, lands after its base (§3
  holds its review legs until then).
```

and replace

```markdown
  and their own `relay-merge` reruns the gates on the merged result. A plan stacked on the one that landed now starts
  its review legs (§3), and a plan waiting for it is dispatched (§2).
```

with

```markdown
  and their own `relay-merge` reruns the gates on the merged result. A second plan stacked on the one that landed, in
  a worktree of its own, now starts its review legs (§3), and a plan waiting for it is dispatched (§2).
```

- [ ] **Step 2: `skills/orchestrating/dispatching.md`.** Replace

```markdown
**Branch is offered only for a plan that will run alone:** no other plan is in flight and none is approved to run
beside it (`parallel.md` says what in flight means). Otherwise every plan runs in a worktree, and the question is
`parallel.md` §1's: a line per plan, then a line per overlap its conflict check found. The forms below are for a plan
that runs alone.
```

with

```markdown
**Branch is offered only for a plan that will run alone:** no other plan is in flight and none is approved to run
beside it (`parallel.md` says what in flight means). A chain, a plan and the plan stacked on it, counts as one plan
here: its plans run one after another in one checkout (`parallel.md` §3). Otherwise every plan runs in a worktree,
and the question is `parallel.md` §1's: a line per plan, then a line per overlap its conflict check found. The forms
below are for a plan, or a chain, that runs alone; a chain's first sentence names its plans: "Plans ready:
`<base path>` (N tasks), then `<stacked path>` (M tasks), stacked on it, in the same checkout once the first plan's
reviews are done."
```

Replace

```markdown
- **Worktree:** the new worktree is cut from `main`, or from its base's branch for a stacked plan (`parallel.md` §3).
  The main checkout may be on a branch run.
```

with

```markdown
- **Worktree:** the new worktree is cut from `main`, or from its base's branch for a second plan on the same base
  (`parallel.md` §3). The main checkout may be on a branch run.
- **A stacked plan** is cut in its base's checkout instead, after the checks `parallel.md` §3 gives; the last
  precondition below holds for it too.
```

In §3, insert after line 59 (the branch-name example, ending `hyper-relay-c-executing-plans`) and its blank line,
before the `- **Branch:**` bullet (line 61):

```markdown
A stacked plan has no setup here: `parallel.md` §3 cuts its branch in its base's checkout and makes its run folder.

```

Replace

```markdown
  worktree from `<base>`, which is `main`, or the base's branch for a stacked plan (`parallel.md` §3):
```

with

```markdown
  worktree from `<base>`, which is `main`, or the base's branch for a second plan on the same base (`parallel.md` §3):
```

Replace

```markdown
- for a stacked plan: that its branch was cut from its base's branch, `<base branch>`, which has not merged yet;
```

with

```markdown
- for a stacked plan: that its branch was cut from its base's branch, `<base branch>`, which has not merged yet, and,
  for a chain, that it runs in the base's checkout (`parallel.md` §3);
```

Replace

```markdown
Until the branch merges, you share the main checkout's working tree with the executor. Keep working (brainstorm,
write specs and plans) by these rules:
```

with

```markdown
Until the branch merges (for a chain, until its last branch merges), you share the main checkout's working tree with
the executor. Keep working (brainstorm, write specs and plans) by these rules:
```

Replace

```markdown
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit` or `merge`. Run read-only git as
  `GIT_OPTIONAL_LOCKS=0 git …`, so a `git status` never holds `index.lock` while the executor commits.
```

with

```markdown
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit` or `merge`, except a chain's own
  switches (`parallel.md` §3), made while no executor works there. Run read-only git as `GIT_OPTIONAL_LOCKS=0 git …`,
  so a `git status` never holds `index.lock` while the executor commits.
```

Replace

```markdown
what the summary does not settle. Before relaying anything, where the branch is checked out (for a stacked plan, only
once its base has merged and any catch-up round is done: `parallel.md` §3):
```

with

```markdown
what the summary does not settle. Before relaying anything, where the branch is checked out (for a chain's stacked
plan, at once, in the base's checkout; for a second plan on the same base, only once its base has merged and any
catch-up round is done: `parallel.md` §3):
```

Replace

```markdown
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`. Each of the executor's
   tasks ends in a commit carrying its `Plan-Task:` trailer.
```

with

```markdown
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`, or
   `<base branch>..<branch>` for a stacked branch whose base has not merged. Each of the executor's tasks ends in a
   commit carrying its `Plan-Task:` trailer.
```

- [ ] **Step 3: `skills/orchestrating/reviewing.md`.** The cut moves to the end of §3: replace (lines 92–94)

```markdown
reported once, in one line (`quartz.md` §2).

When the fix loop ends and a plan is stacked on this one, cut and dispatch it now (`parallel.md` §3).
```

with

```markdown
reported once, in one line (`quartz.md` §2).
```

Replace

```markdown
this file) with the range `$(git merge-base main <branch>)..<branch>`, the plan, the spec, the run folder and the
plan's initiative ("none" without Quartz). It writes its review to the run folder's `code-review.md`, files its
```

with

```markdown
this file) with the range `$(git merge-base main <branch>)..<branch>` (for a stacked branch whose base has not
merged, `<base branch>..<branch>`), the plan, the spec, the run folder and the plan's initiative ("none" without
Quartz). It writes its review to the run folder's `code-review.md`, files its
```

Replace

```markdown
1. Put the skills from `main` and from the branch in `<run>/skill-tests/red/` and `<run>/skill-tests/green/`:
   `mkdir -p <run>/skill-tests/red <run>/skill-tests/green`, then
   `git cat-file -e main:<skills> 2>/dev/null && git archive main <skills> | tar -x -C <run>/skill-tests/red` and
   `git archive <branch> <skills> | tar -x -C <run>/skill-tests/green`. `<skills>` is the folder that holds the
   repo's skill folders (`skills` in a plugin, `.claude/skills` in a project). When `main` has no such folder, the
   `cat-file` check fails, nothing is copied and `red/` stays empty: RED then reads no skill at all, as it should
   for a new skill.
```

with

```markdown
1. Put the skills from `<red>` and from the branch in `<run>/skill-tests/red/` and `<run>/skill-tests/green/`, where
   `<red>` is `main`, or the base's branch for a stacked branch whose base has not merged, so that RED differs from
   GREEN only by this plan's work: `mkdir -p <run>/skill-tests/red <run>/skill-tests/green`, then
   `git cat-file -e <red>:<skills> 2>/dev/null && git archive <red> <skills> | tar -x -C <run>/skill-tests/red` and
   `git archive <branch> <skills> | tar -x -C <run>/skill-tests/green`. `<skills>` is the folder that holds the
   repo's skill folders (`skills` in a plugin, `.claude/skills` in a project). When `<red>` has no such folder, the
   `cat-file` check fails, nothing is copied and `red/` stays empty: RED then reads no skill at all, as it should
   for a new skill.
```

In the judge's prompt (step 4, line 144), replace

```markdown
   > `step-<id>-red.md` from `main`'s. For each step, judge whether the GREEN answer does what GREEN must, and whether
```

with

```markdown
   > `step-<id>-red.md` from `<red>`'s. For each step, judge whether the GREEN answer does what GREEN must, and whether
```

Insert before the line `## 4. Stop 4, the click-through and the merge`, after the blank line that ends §3:

```markdown
When the review legs are done and a plan is stacked on this one, this plan does not go to stop 4: moment 8's `next:`
is `cut <S> in this checkout`, and you cut the stacked plan now, in this plan's checkout, and dispatch it
(`parallel.md` §3). A second plan on the same base is cut in a worktree of its own at the same moment.

```

Insert after the line `` Stop 4 promises a Quartz tick only where `quartz.md` §3 says one will come. `` and its blank
line:

```markdown
**A chain** (`parallel.md` §3) has one stop 4, once its last link's review legs are done. It is one message for every
plan in the chain, in chain order: its questions for each plan (each capped finding, the NEEDS-HUMAN and `owner`
steps), and where to click through: the last link's `wt` stack in the shared checkout after a worktree run, the normal
stack after a branch run; then the report, a block per plan. Its merge is one call with every branch, base first,
`relay-merge <B> <S>`, after `(cd <checkout> && wt down)` when the last link's stack is up, or `git switch main` after
a branch run. When `<B>` lands and `<S>` fails, `<B>` stays landed and `<S>` goes through the table's handling for its
exit code; when `<B>` fails, nothing has landed, and `<S>` waits with it. A retry names the same branches: one that
has landed is "already in main", and its branch is deleted with the rest. A change to `<B>` after the cut, asked for
at this stop or needed after its merge failed, is `parallel.md` §3's fix to the base.

```

Replace

```markdown
once more, as `done`. A plan stacked on this one, or waiting for it, goes on now (`parallel.md` §4).
```

with

```markdown
once more, as `done`. A second plan stacked on this one in a worktree of its own (`parallel.md` §3), or a plan
waiting for it, goes on now (`parallel.md` §4).
```

- [ ] **Step 4: `skills/orchestrating/SKILL.md` and `quartz.md`.** In `SKILL.md`, replace

```markdown
| A stacked plan's branch (its plan's header has `**Builds on:**`) with all its executor tasks committed, whose base has not merged | It waits for its base (`parallel.md` §3): no review leg until the base merges |
```

with

```markdown
| A stacked plan's branch (its plan's header has `**Builds on:**`) with all its executor tasks committed, whose base has not merged | By its review status (below), with `<base branch>..<branch>` for `main..<branch>`; a second plan on the same base, in a worktree of its own, waits for its base to merge (`parallel.md` §3) |
```

Replace

```markdown
| "code review done" | Stop 4 (`reviewing.md` §4) |
```

with

```markdown
| "code review done" | Stop 4 (`reviewing.md` §4). For a chain's base (another plan's `**Builds on:**` names it): the cut while the stacked plan has no branch, and once it has one, the chain's one stop 4 after the stacked plan's reviews (`parallel.md` §3) |
```

Replace

```markdown
first, and the fix commits are those above the newest one with a trailer.
```

with

```markdown
first, and the fix commits are those above the newest one with a trailer. For a stacked branch whose base has not
merged, read `<base branch>..<branch>` for `main..<branch>`, here and below.
```

In `quartz.md`, replace moment 8's row as Task 4 Step 3 left it,

```markdown
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN` | `stop 4` |
```

with

```markdown
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN` | `stop 4`; for a chain's base, `cut <S> in this checkout`, and once `<S>` is cut, `the chain's stop 4, after <S>'s reviews` (`parallel.md` §3) |
```

- [ ] **Step 5: Verify**

| Run | Expected |
|---|---|
| `grep -c -F 'switch -c <S>' skills/orchestrating/parallel.md` | `1` |
| `grep -c -F 'catches up in turn on its own base' skills/orchestrating/parallel.md` | `1` |
| `grep -c -F 'starts in plan 1' skills/orchestrating/parallel.md` | `1` |
| `grep -c -F 'passes acceptance' skills/orchestrating/parallel.md` | `0` |
| `grep -c -F 'relay-merge <B> <S>' skills/orchestrating/parallel.md skills/orchestrating/reviewing.md` | `skills/orchestrating/parallel.md:3`, `skills/orchestrating/reviewing.md:1` |
| `grep -c -F 'cut and dispatch it now' skills/orchestrating/reviewing.md` | `0` |
| `grep -c -F 'cut <S> in this checkout' skills/orchestrating/reviewing.md skills/orchestrating/quartz.md` | `skills/orchestrating/reviewing.md:1`, `skills/orchestrating/quartz.md:1` |
| `grep -c -F '<base branch>..<branch>' skills/orchestrating/SKILL.md skills/orchestrating/dispatching.md skills/orchestrating/reviewing.md` | `skills/orchestrating/SKILL.md:2`, `skills/orchestrating/dispatching.md:1`, `skills/orchestrating/reviewing.md:1` |
| `grep -c -F 'git archive <red>' skills/orchestrating/reviewing.md` | `1` |
| `grep -c -F 'except a chain' skills/orchestrating/dispatching.md` | `1` |
| `wc -c < skills/orchestrating/SKILL.md` | under 20000 (about 10,900) |
| `sh tests/skill-size/run-tests.sh \| tail -n 1`, then `sh tests/skill-layout/run-tests.sh \| tail -n 1`, then `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `12 passed, 0 failed`; `10 passed, 0 failed`; `48 passed, 0 failed` |

- [ ] **Step 6: Commit**

```bash
git add skills/orchestrating/parallel.md skills/orchestrating/dispatching.md skills/orchestrating/reviewing.md skills/orchestrating/SKILL.md skills/orchestrating/quartz.md
git commit -m "feat: a chain of stacked plans shares one checkout, one stop 4 and one merge" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md#5"
```

### Task 6: Acceptance (spec §3, §4, §5; P3, P17–P19). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, from the top of the checkout on the branch
  `hyper-relay-shared-checkout-and-code-review-steps` (`<checkout>`, its absolute path; this repo's mode is `branch`,
  so it is the main checkout), with `<evidence folder>` the run folder's `acceptance/` (Steps 1–4). No step reruns the
  gates.
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the installed relay's
  skill-test leg: its `red/` and `green/` folders hold `main`'s and the branch's `skills/` (Steps 5–13, S1–S9).
- **`owner`**: the owner, at the click-through (Steps 14–15); the orchestrator runs the commands.
- **`after merge`**: the orchestrator with the owner, once the branch is merged and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 16–17).

This run follows the installed relay (0.2.9), not the text it writes. In a command inside a table cell, `\|` is a
plain `|`.

- [ ] **Step 1 (`reviewer`): Only the planned files (spec §4).**

| Run | PASS |
|---|---|
| `git diff --name-status main...HEAD` | exactly these, in any order: `A` for `tests/relay-plan/fixtures/code-review.md`; `M` for `bin/relay-plan`, `docs/relay-plan.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/parallel.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/reviewing.md`, `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `tests/relay-plan/run-tests.sh` |
| `git diff --stat main...HEAD -- package.json .claude-plugin templates hooks .hyper-relay CLAUDE.md README.md tests/orchestrating tests/relay-plan/fixtures/plan.md bin/wt bin/relay-merge skills/executing-plans skills/orchestrating/planning.md` | nothing |
| `git diff main...HEAD -- tests/relay-plan/run-tests.sh \| grep -c '^-[^-]'` | `2`: the header's `Expect:` line and the `fails_alone "acceptance"` line; no other existing line changed |
| `git diff main...HEAD -- skills \| grep -c -E '^\+.*(/home/\|/tmp/\|/Users/)'` | `0` |
| `git ls-files -s bin/relay-plan` | mode `100755` |
| `wc -c < skills/writing-plans/SKILL.md`, then `wc -c < skills/orchestrating/SKILL.md`, then `wc -c < skills/requesting-code-review/SKILL.md` | each under 20000 |

- [ ] **Step 2 (`reviewer`): The chain's text against the spec (spec §1).** Read
  `git diff main...HEAD -- skills/orchestrating skills/requesting-code-review/SKILL.md skills/writing-plans/SKILL.md`.
  PASS: Task 5's text, Task 3 Step 2's SHAs comment and Task 2 Step 1's RED line are there word for word; each point
  below is where the table puts it; nothing contradicts the spec
  (`docs/superpowers/specs/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps-design.md`) beyond P5–P8 and
  P12–P16. A contradiction is a FAIL, with its line.

| Spec point (§1) | Where |
|---|---|
| The stacked plan starts after the base's review legs, not its acceptance; a capped base finding does not stop the cut | `parallel.md` §3, "When"; `reviewing.md` §2 no longer cuts; `reviewing.md` §3's last paragraph |
| The base's moment-8 `next: cut <S> in this checkout`, then waiting for the chain's stop 4 | `reviewing.md` §3; `quartz.md` §4, moment 8; `parallel.md` §3, the cut's step 4 |
| The cut: on `<B>`, clean, no executor there; `wt down` while `<B>` is checked out; `switch -c <S>`; no `wt new` or `git worktree add`; the run folder, the link, the dispatch with `<checkout>` and `<S>` | `parallel.md` §3, "The cut" |
| Branch mode: a chain counts as one plan; Branch offered for a chain alone; the cut in the main checkout; the hold-back rules until the chain merges | `dispatching.md` §1 and §6; `parallel.md` §1 and §3 |
| The handoff line, "starts in plan 1's checkout once plan 1's reviews are done" | `parallel.md` §1 |
| The stacked plan's reviews at once: the hand-back with `<B>..<S>`, acceptance in `<checkout>`, the code review's base the base's tip, RED from `<B>` | `dispatching.md` §7; `reviewing.md` §3; `requesting-code-review`'s SHAs and `{BASE_SHA}`; `writing-plans`' RED line |
| One stop 4 for the chain, on the last link's stack; one `relay-merge <B> <S>`; `<B>` lands and `<S>` fails; `<B>` fails | `reviewing.md` §4's chain paragraph; `parallel.md` §3 and §4 |
| A fix to the base after the cut: `wt down`, switch back, the fix round, switch, the catch-up prompt word for word, the reruns, a short stop 4 | `parallel.md` §3 |
| A longer chain, link by link, one stop 4, `relay-merge <B> <S> <C>` | `parallel.md` §3 |
| A second plan on the same base keeps today's rules | `parallel.md` §3 and §4; `dispatching.md` §2, §3 and §7; `reviewing.md` §5 |
| Where work stands | `SKILL.md`: the stacked branch's row, the "code review done" row, the range sentence |
| Unchanged: `wt`, `relay-merge`, the planner leg | Step 1: no change under `bin/wt`, `bin/relay-merge` or `planning.md` |

- [ ] **Step 3 (`reviewer`): The `code-review` steps' text against the spec (spec §2).** Read
  `git diff main...HEAD -- skills docs/relay-plan.md bin/relay-plan`. PASS: Tasks 1–4's text is there word for word;
  each point below is where the table puts it; nothing contradicts the spec beyond P1, P2 and P9–P11. A contradiction
  is a FAIL, with its line.

| Spec point (§2) | Where |
|---|---|
| Two kinds: a `code-review` step only reads (its sources, read-only commands at most, the examples); a `reviewer` step needs something running | `writing-plans/SKILL.md`, the acceptance-task bullets |
| The kinds list names `code-review`; the old line loses its two reading examples; "No `reviewer` step reruns the full gates" word for word | `writing-plans/SKILL.md` |
| The plan reviewer lists the kind, and a check in the wrong kind is a finding | `plan-document-reviewer-prompt.md`, "The acceptance task" row |
| `relay-plan steps <plan> code-review`, `check` accepting it and refusing any other unknown kind, `step`, the usage line, the docs | `bin/relay-plan` lines 9, 322, 493–494; `docs/relay-plan.md` |
| `{PLAN_STEPS}`: ids with `relay-plan step <plan> <id>`, or "none"; each run as written; PASS or FAIL with the lines quoted; any FAIL makes "Ready to merge: No"; the summary lists each FAIL by number; never a card; not reported again | `code-reviewer.md`; `requesting-code-review/SKILL.md` |
| The acceptance reviewer runs only `reviewer` steps; none: no dispatch and `acceptance done, no reviewer steps`; `code-review` steps are §3's | `reviewing.md` §1 |
| §3 fills `{PLAN_STEPS}` from `relay-plan steps <plan> code-review`; every listed step has a verdict; a FAIL is checked against the code first | `reviewing.md` §3 |
| A FAIL sorts as an acceptance FAIL; the cap's card is the orchestrator's; the resumed code reviewer reruns the failed steps; the acceptance reviewer reruns the `reviewer` steps the fix touches | `reviewing.md` §2 and §3 |
| Moment 8's form, without "plan steps P/Q PASS" when there are none; stop 4 gives the `code-review` verdicts beside acceptance's | `reviewing.md` §3 and §4; `quartz.md` §4; `SKILL.md`'s stops table |
| Old plans run as written | no text migrates; `tests/relay-plan/fixtures/plan.md` and its `reviewer` assertions are unchanged (Step 1) |

- [ ] **Step 4 (`reviewer`): `relay-plan` on a scratch plan in a temporary repo (spec §4; P19).** One command per
  Bash call, in order, each exiting 0:

```sh
rm -rf <evidence folder>/rp-check
git init -q -b main <evidence folder>/rp-check
mkdir -p <evidence folder>/rp-check/docs/superpowers/plans
printf '%s\n' '# Scratch plan' '' '### Task 1: Acceptance' '' '- [ ] **Step 1 (`code-review`): Only the planned files.**' '' '- [ ] **Step 2 (`reviewer`): The banner shows on the stack.**' '' '- [ ] **Step 3 (`code-review`, a reading): The copy reads' '  as the spec says.**' '' '- [ ] **Step 4 (`owner`): The click-through.**' > <evidence folder>/rp-check/docs/superpowers/plans/2026-11-26-rp-check.md
printf '%s\n' '# Near miss' '' '### Task 1: Acceptance' '' '- [ ] **Step 1 (`code review`): A kind with a space.**' > <evidence folder>/rp-check/docs/superpowers/plans/2026-11-26-rp-miss.md
git -C <evidence folder>/rp-check add docs/superpowers/plans
git -C <evidence folder>/rp-check -c core.hooksPath=/dev/null -c user.name=reviewer -c user.email=reviewer@example.invalid commit -q -m plans
git -C <checkout> show main:bin/relay-plan > <evidence folder>/relay-plan-main
```

Then each run below, from the scratch repo, as `cd <evidence folder>/rp-check && dash <checkout>/bin/relay-plan …`
(the branch's) or `cd <evidence folder>/rp-check && dash <evidence folder>/relay-plan-main …` (`main`'s), with `<RP>`
the scratch plan `docs/superpowers/plans/2026-11-26-rp-check.md` and `<MISS>` the near miss
`docs/superpowers/plans/2026-11-26-rp-miss.md`. Save each output, stdout and stderr, under its name in the evidence
folder.

| Run | PASS |
|---|---|
| the branch's `steps <RP> code-review` | `04a-steps-code-review.txt`: `tasks 1; acceptance task 1`, then step 1 and step 3, each `code-review` with its title (`Only the planned files.`, `The copy reads as the spec says.`), tab-separated; exit 0 |
| the branch's `steps <RP> reviewer` | `04b-steps-reviewer.txt`: `tasks 1; acceptance task 1`, then step 2 only, `reviewer`; exit 0 |
| the branch's `step <RP> 3` | `04c-step-3.txt`: Step 3's two lines, as written; exit 0 |
| the branch's `check <RP>` | `04d-check.txt`: exactly `ok committed`, `ok trailers`, `ok acceptance`, `ok skill-tests`, `ok placeholders`; exit 0 |
| the branch's `check <MISS>` | `04e-check-miss.txt`: the FAIL line `FAIL acceptance: Step 1: "code review" is not reviewer, code-review, owner, after merge or skill-test`; exit 1 |
| the branch's `steps <RP> 'code review'` | `04f-steps-miss.txt`: stderr holds `unknown who: code review`; exit 2 |
| `main`'s `check <RP>` | `04g-check-main.txt`: the FAIL line `FAIL acceptance: Step 1: "code-review" is not reviewer, owner, after merge or skill-test`; exit 1 (the refusal this branch removes) |
| `main`'s `steps <RP> code-review` | `04h-steps-main.txt`: exit 2 |
| `rm -rf <evidence folder>/rp-check` | exit 0 |

The report says, in one line each: the branch's `relay-plan` lists, prints and accepts `code-review` steps; it keeps
them apart from `reviewer` steps; it refuses the near miss; `main`'s refuses the kind.

- [ ] **Step 5 (`skill-test`): S1, the stacked plan waits for its base's code review (spec §3 S1; §1).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: worktree`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: each worktree runs the app on a `wt` stack of its
own. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include Read, Grep,
Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id) and
SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or dispatch
agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-billing-design.md` has two plans, both committed on `main`: the API plan
`docs/superpowers/plans/2026-11-25-billing-api.md` (call it A: 7 tasks, Task 7 its acceptance task), on the branch
`billing-api`, and the web plan `docs/superpowers/plans/2026-11-25-billing-web.md` (call it W: 6 tasks, Task 6 its
acceptance task), on the branch `billing-web`. W's header has the line
`**Builds on:** docs/superpowers/plans/2026-11-25-billing-api.md`. Both plans are on the card "Billing page"
(`5a6b7c8d-1e2f-4a3b-9c4d-5e6f7a8b9c0d`, initiative `v2`). Nothing else is in flight. At stop 3 the owner said OK to
running both in worktree mode, W stacked on A. A runs in the worktree `/home/user/shop/.worktrees/billing-api`; its
run folder is `/home/user/shop/.hyper-relay/runs/billing-api`.

In this conversation you verified A's hand-back and ran `quartz review`, then dispatched `shop-reviewer` for A's
`reviewer` steps 1 to 4. It has just handed back: "all 4 steps PASS; nothing blocks a merge", one line per step, each
PASS with its evidence file in `acceptance/`, no BLOCKING finding and no card. There have been no fix rounds. A's
code review has not run. `relay-plan steps docs/superpowers/plans/2026-11-25-billing-api.md` prints
`tasks 7; acceptance task 7`, then steps 1 to 4 as `reviewer`, step 5 as `owner` and step 6 as `after merge`; with
`skill-test` or `code-review` after the plan, it prints only `tasks 7; acceptance task 7` and exits 1.
`git merge-base main billing-api` prints `4be81c0`. W has no branch: `git branch --list billing-web` prints nothing.

Give your commands and tool calls, in order, each dispatch with its prompt in short, and your next message to the
owner, if any, verbatim.
```

GREEN must: post the fix loop's end (`acceptance done, 4/4 PASS, 0 NEEDS-HUMAN, 0 fix rounds`), dispatch A's code
review (a general-purpose agent on Sonnet with `code-reviewer.md`, the range `4be81c0..billing-api` or
`$(git merge-base main billing-api)..billing-api`), and leave W uncut: no `git worktree add`, no `wt new`, no
`git switch -c billing-web`, no run folder and no executor for W.

RED is expected to: cut W now (`wt new billing-web --from billing-api` or
`git worktree add .worktrees/billing-web -b billing-web billing-api`) and dispatch its executor, beside A's code
review.

- [ ] **Step 6 (`skill-test`): S2, the cut in the base's worktree (spec §3 S2; §1).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: worktree`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: each worktree runs the app on a `wt` stack of its
own. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include Read, Grep,
Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id) and
SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or dispatch
agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-billing-design.md` has two plans, both committed on `main`: the API plan
`docs/superpowers/plans/2026-11-25-billing-api.md` (call it A: 7 tasks, Task 7 its acceptance task), on the branch
`billing-api`, and the web plan `docs/superpowers/plans/2026-11-25-billing-web.md` (call it W: 6 tasks, Task 6 its
acceptance task), on the branch `billing-web`. W's header has the line
`**Builds on:** docs/superpowers/plans/2026-11-25-billing-api.md`. Both plans are on the card "Billing page"
(`5a6b7c8d-1e2f-4a3b-9c4d-5e6f7a8b9c0d`, initiative `v2`). Nothing else is in flight. At stop 3 the owner said OK to
running both in worktree mode, W stacked on A. A runs in the worktree `/home/user/shop/.worktrees/billing-api`; its
run folder is `/home/user/shop/.hyper-relay/runs/billing-api`.

A's acceptance passed 4/4 with no fix rounds, and its code review is done: you checked its summary, "Ready to merge:
Yes. Critical 0, Important 1, Minor 0", and its Important finding is on the board as a proposed card. A's acceptance
task has no `skill-test` and no `code-review` steps. Every agent you dispatched for A has finished. W has no branch:
`git branch --list billing-web` prints nothing. In `/home/user/shop/.worktrees/billing-api`,
`git branch --show-current` prints `billing-api`, `git status --porcelain` and
`git rev-parse -q --verify MERGE_HEAD` print nothing, and `wt ls` shows the stack `shop-wt-billing-api` up: A's
executor left it for the click-through. `relay-plan run-dir docs/superpowers/plans/2026-11-25-billing-web.md` would
print `/home/user/shop/.hyper-relay/runs/billing-web`. Every command you would run succeeds.

Give your commands and tool calls, in order, each with the directory it runs in, each dispatch with its prompt in
short, and your next message to the owner, if any, verbatim.
```

GREEN must: from the main checkout, run `wt down` in `/home/user/shop/.worktrees/billing-api` while it is still on
`billing-api` (as `(cd /home/user/shop/.worktrees/billing-api && wt down)`), then
`git -C /home/user/shop/.worktrees/billing-api switch -c billing-web`, then
`relay-plan run-dir docs/superpowers/plans/2026-11-25-billing-web.md`, and dispatch `shop-executor` for W with the
checkout `/home/user/shop/.worktrees/billing-api` and the branch `billing-web`, cut from `billing-api`, which has not
merged; no `wt new`, no `git worktree add`, and no stop 4 for A.

RED is expected to: create a second worktree for W (`wt new billing-web --from billing-api` or `git worktree add`),
or send A to stop 4 on its own.

- [ ] **Step 7 (`skill-test`): S3, the stacked plan's reviews at once (spec §3 S3; §1).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: worktree`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: each worktree runs the app on a `wt` stack of its
own. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include Read, Grep,
Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id) and
SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or dispatch
agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-billing-design.md` has two plans, both committed on `main`: the API plan
`docs/superpowers/plans/2026-11-25-billing-api.md` (call it A: 7 tasks, Task 7 its acceptance task), on the branch
`billing-api`, and the web plan `docs/superpowers/plans/2026-11-25-billing-web.md` (call it W: 6 tasks, Task 6 its
acceptance task), on the branch `billing-web`. W's header has the line
`**Builds on:** docs/superpowers/plans/2026-11-25-billing-api.md`. Both plans are on the card "Billing page"
(`5a6b7c8d-1e2f-4a3b-9c4d-5e6f7a8b9c0d`, initiative `v2`). Nothing else is in flight. At stop 3 the owner said OK to
running both in worktree mode, W stacked on A. A ran in the worktree `/home/user/shop/.worktrees/billing-api`; its
run folder is `/home/user/shop/.hyper-relay/runs/billing-api`.

A's review legs are done (acceptance 4/4 PASS, code review 0 Critical, no skill tests), and A has not merged:
`git log -1 --format=%h --grep='Plan-Task: docs/superpowers/plans/2026-11-25-billing-api.md' main` prints nothing.
Forty minutes ago, in this conversation, you took A's `wt` stack down, ran
`git -C /home/user/shop/.worktrees/billing-api switch -c billing-web`, made W's run folder,
`/home/user/shop/.hyper-relay/runs/billing-web`, and dispatched `shop-executor` for W in that checkout, on the branch
`billing-web`, cut from `billing-api`. The Agent tool returned the id `a3f9c2e1b7d04e6f`. Its hand-back has just
arrived:

  Tasks 5/5. Gates (gates.log in /home/user/shop/.hyper-relay/runs/billing-web): `cd web && npm run lint`, 0
  problems; `cd web && npm test`, 48 passed. No deviations, no open calls, no quartz: lines, no cards. Left running:
  the wt stack for billing-web at http://localhost:3107. Report:
  /home/user/shop/.hyper-relay/runs/billing-web/executor.md

What you would find, in `/home/user/shop/.worktrees/billing-api`: `git branch --show-current` prints `billing-web`;
`relay-plan gates docs/superpowers/plans/2026-11-25-billing-web.md 'cd web && npm run lint' 'cd web && npm test'`
prints two `ok` lines at `7c8d9e0`, the tip of `billing-web`, ending `0 problems` and `48 passed`;
`git log --format='%h %s%n%(trailers:key=Plan-Task)' billing-api..billing-web` lists five commits, each with its
`Plan-Task: docs/superpowers/plans/2026-11-25-billing-web.md#<n>` trailer, 1 to 5, and the same with
`main..billing-web` lists those five and, below them, A's six; `git status --short` prints nothing.
`relay-plan steps docs/superpowers/plans/2026-11-25-billing-web.md reviewer` prints `tasks 6; acceptance task 6`,
then steps 1 to 3, each `reviewer`.

Give your commands and tool calls, in order, each with the directory it runs in, up to and including your next
dispatch, with its prompt in short; say which range W's code review will take; and give your next message to the
owner, if any, verbatim.
```

GREEN must: run the hand-back check now, in `/home/user/shop/.worktrees/billing-api`: `relay-plan gates` naming the
two commands, the commits with `billing-api..billing-web` and the clean tree; then `quartz review` there; then dispatch
`shop-reviewer` for W's steps 1 to 3 with the checkout `/home/user/shop/.worktrees/billing-api`, the branch
`billing-web` and the stack at http://localhost:3107; and name `billing-api..billing-web` as the range W's code review
will take.

RED is expected to: hold W's report until `billing-api` merges, with no hand-back check and no acceptance now, then a
catch-up round.

- [ ] **Step 8 (`skill-test`): S4, one stop 4 for the chain (spec §3 S4; §1).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: worktree`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: each worktree runs the app on a `wt` stack of its
own. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include Read, Grep,
Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id) and
SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or dispatch
agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-billing-design.md` has two plans, both committed on `main`: the API plan
`docs/superpowers/plans/2026-11-25-billing-api.md` (call it A: 7 tasks, Task 7 its acceptance task), on the branch
`billing-api`, and the web plan `docs/superpowers/plans/2026-11-25-billing-web.md` (call it W: 6 tasks, Task 6 its
acceptance task), on the branch `billing-web`. W's header has the line
`**Builds on:** docs/superpowers/plans/2026-11-25-billing-api.md`. Both plans are on the card "Billing page"
(`5a6b7c8d-1e2f-4a3b-9c4d-5e6f7a8b9c0d`, initiative `v2`). Nothing else is in flight. At stop 3 the owner said OK to
running both in worktree mode, W stacked on A. A ran in the worktree `/home/user/shop/.worktrees/billing-api`; its
run folder is `/home/user/shop/.hyper-relay/runs/billing-api`, and W's is
`/home/user/shop/.hyper-relay/runs/billing-web`.

Both plans' review legs are done, in this conversation, and A has not merged. A: acceptance 4/4 PASS, no fix rounds;
code review 0 Critical, 1 Important (a proposed card), 0 Minor; no skill tests. After A's code review you cut W in
A's checkout: `/home/user/shop/.worktrees/billing-api` is on `billing-web`. W: acceptance 3/3 PASS, no fix rounds;
its code reviewer has just handed back "Ready to merge: Yes. Critical 0, Important 0, Minor 1", the Minor a proposed
card; no skill tests. Every agent you dispatched for either plan has finished, and each one's completion
notification, with its usage, has arrived. No stop 4 has been sent for either plan. W's executor left the `wt` stack
for `billing-web` up at http://localhost:3107; A's stack is down. `relay-plan steps
docs/superpowers/plans/2026-11-25-billing-api.md owner` prints `tasks 7; acceptance task 7`, then step 5, `owner`,
"The owner clicks through the invoice list."; the same for W prints `tasks 6; acceptance task 6`, then step 4,
`owner`, "The owner clicks through the billing page." No step is NEEDS-HUMAN, and no finding reached the fix-round
cap.

Give your commands and tool calls, in order, and your next message to the owner, verbatim; stop where you wait for
the owner's answer, and say what you will run to merge once the owner says go.
```

GREEN must: send one stop-4 message that covers both A and W: its questions for both plans (A's step 5 and W's step
4) and one place to click through, the stack at http://localhost:3107 in `/home/user/shop/.worktrees/billing-api`;
then the report, a block per plan; and name the merge as one call, `relay-merge billing-api billing-web`, base first.

RED is expected to: send a stop 4 for A alone, to merge A first, and hold W until A has merged.

- [ ] **Step 9 (`skill-test`): S5, a chain in branch mode (spec §3 S5; §1).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: branch`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: a worktree runs the app on a `wt` stack of its own,
and the main checkout on the owner's normal stack. Commands on your PATH include `quartz`, `wt`, `relay-merge` and
`relay-plan`. Your tools include Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the
background and returns its id) and SendMessage (it resumes an agent by its id). In this test you cannot read files,
run commands, call tools or dispatch agents: list each among your commands, in order, and take what it would show
from the facts below. Today is 2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-billing-design.md` has two plans, both committed on `main`: the API plan
`docs/superpowers/plans/2026-11-25-billing-api.md` (call it A: 7 tasks, Task 7 its acceptance task), on the branch
`billing-api`, and the web plan `docs/superpowers/plans/2026-11-25-billing-web.md` (call it W: 6 tasks, Task 6 its
acceptance task), on the branch `billing-web`. W's header has the line
`**Builds on:** docs/superpowers/plans/2026-11-25-billing-api.md`. Both plans are on the card "Billing page"
(`5a6b7c8d-1e2f-4a3b-9c4d-5e6f7a8b9c0d`, initiative `v2`). At stop 3, with nothing else in flight, the owner said OK
to running A on a branch in the main checkout, this repo's default, with W stacked on A. A ran on the branch
`billing-api` in the main checkout, `/home/user/shop`, on the owner's normal stack (`wt ls` prints nothing); its run
folder is `/home/user/shop/.hyper-relay/runs/billing-api`.

A's acceptance passed 4/4 with no fix rounds, and its code review is done: "Ready to merge: Yes. Critical 0,
Important 0, Minor 0". A's acceptance task has no `skill-test` and no `code-review` steps. Every agent you dispatched
for A has finished. `git branch --no-merged main` prints only `billing-api`, and `git worktree list` shows only the
main checkout. In the main checkout, `git branch --show-current` prints `billing-api`, and
`git rev-parse -q --verify MERGE_HEAD` and `git status --porcelain --untracked-files=no` print nothing. W has no
branch: `git branch --list billing-web` prints nothing. `relay-plan run-dir
docs/superpowers/plans/2026-11-25-billing-web.md` would print `/home/user/shop/.hyper-relay/runs/billing-web`. Every
command you would run succeeds.

Give your commands and tool calls, in order, each with the directory it runs in, each dispatch with its prompt in
short, and your next message to the owner, if any, verbatim.
```

GREEN must: in the main checkout, `git switch -c billing-web` (from `billing-api`), then `relay-plan run-dir` for W,
and dispatch `shop-executor` for W in mode `branch`, with the checkout `/home/user/shop` and the branch
`billing-web`, cut from `billing-api`, which has not merged; no `git worktree add`, no `wt new`, and no stop 4 for A.

RED is expected to: open a worktree for W (`git worktree add .worktrees/billing-web -b billing-web billing-api` or
`wt new billing-web --from billing-api`).

- [ ] **Step 10 (`skill-test`): S6, plans side by side still get a worktree each (spec §3 S6; a guard).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory, on `main`. You are the orchestrator: the Claude Code session your human
partner (the owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your
skills folder: read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz:
`quartz` is installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`,
`add_note`, `add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of
`project: shop`, `reviewer: browser` and `execute: branch`, and no other key; the repo's generated agents are
`shop-planner`, `shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: a worktree runs the app on a `wt`
stack of its own, and the main checkout on the owner's normal stack. Commands on your PATH include `quartz`, `wt`,
`relay-merge` and `relay-plan`. Your tools include Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches
a subagent in the background and returns its id) and SendMessage (it resumes an agent by its id). In this test you
cannot read files, run commands, call tools or dispatch agents: list each among your commands, in order, and take
what it would show from the facts below. Today is 2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-coupons-design.md` has a `**Plans:** 2` line, and its plans list says the
two plans run side by side: neither builds on the other. You dispatched a planner for each; both have handed back.
Both plans are committed on `main`: `docs/superpowers/plans/2026-11-25-coupons-api.md`, on the branch `coupons-api`
(the first line `relay-plan steps` prints is `tasks 6; acceptance task 6`), and
`docs/superpowers/plans/2026-11-25-coupons-web.md`, on the branch `coupons-web` (`tasks 5; acceptance task 5`).
Neither header has a `**Builds on:**` line. `relay-plan check` prints only `ok` lines for each, and
`relay-plan overlap docs/superpowers/plans/2026-11-25-coupons-web.md docs/superpowers/plans/2026-11-25-coupons-api.md`
prints nothing. Nothing else is in flight: `git branch --no-merged main` prints nothing, and `git worktree list` shows
only the main checkout. Neither planner names a decision for the owner, an assumption or a deviation. The card is
"Coupons at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative `v2`).

Give the handoff question of your stop-3 message, verbatim, and say where each plan's executor will run once the
owner says OK.
```

GREEN must: ask one handoff question with a line per plan, each running in a worktree of its own and starting now,
and offer no branch run, though `execute: branch` is the repo's default.

RED is expected to: do the same: this is a guard, so a RED that does not fail is the expected result.

- [ ] **Step 11 (`skill-test`): S7, the planner sorts the checks (spec §3 S7; §2).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. You
are a planner: a subagent the orchestrator dispatched to write one implementation plan. You follow the skill
`hyper-relay:writing-plans`, the folder `writing-plans` in your skills folder: read it. `.hyper-relay/agents.md` says
`reviewer: browser`: the repo's acceptance reviewer drives a browser with Playwright against a running app, and can
also run commands. The repo has a `.wt.conf`, so each worktree's executor leaves the app up on a `wt` stack. In this
test you cannot read files other than the skills, run commands or call tools. Today is 2026-11-26.

The spec `docs/superpowers/specs/2026-11-24-card-expiry-banner-design.md` adds a banner to the billing page for a
user whose card expires within 30 days. Its copy is fixed: "Your card expires soon. Update it before it lapses." Its
`## Testing and acceptance` section says: "On a `wt` stack, logged in as the seeded user `expiring@example.test`, the
billing page shows the banner. The banner's copy is the spec's, word for word, and it lives in
`web/src/copy/billing.ts`. The branch changes only `web/src/pages/Billing.tsx`, `web/src/copy/billing.ts` and
`web/src/pages/Billing.test.tsx`." Your plan is `docs/superpowers/plans/2026-11-25-card-expiry-banner.md`; its
Tasks 1 to 3 are written and change exactly those three files, and its Task 4 is the acceptance task. You have
written Task 4's Step 4, an `owner` step, and nothing else in it.

Write Task 4's Steps 1 to 3, one per check that section names, as they would appear in the plan: each step's heading
line with who runs it, then its command or action and its PASS.
```

GREEN must: mark the banner check on the stack (the browser step) `reviewer`, and both the copy check and the
changed-files check `code-review`, each with read-only commands at most (such as `git diff --name-only main...HEAD`,
or `grep` on `web/src/copy/billing.ts`).

RED is expected to: mark all three steps `reviewer`.

- [ ] **Step 12 (`skill-test`): S8, no acceptance reviewer, and the steps go to the code review (spec §3 S8; §2).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop with a Go API in `api/` and a web app in `web/`. Its
main checkout is your working directory. You are the orchestrator: the Claude Code session your human partner (the
owner) talks to. You follow the skill `hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder:
read the files of it that the situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is
installed, the main checkout's `.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`,
`add_tasks`, `list_tasks`) are loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`,
`reviewer: browser` and `execute: worktree`, and no other key; the repo's generated agents are `shop-planner`,
`shop-executor` and `shop-reviewer`. The repo has a `.wt.conf`: each worktree runs the app on a `wt` stack of its
own. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include Read, Grep,
Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id) and
SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or dispatch
agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The plan `docs/superpowers/plans/2026-11-25-invoice-copy.md` (call it P) has 5 tasks; Task 5 is its acceptance task.
Its spec is `docs/superpowers/specs/2026-11-24-invoice-copy-design.md`, its card "Invoice copy"
(`8e9f0a1b-2c3d-4e5f-8a6b-7c8d9e0f1a2b`, initiative `v2`), and P is the only plan on it. P ran in the worktree
`/home/user/shop/.worktrees/invoice-copy`, on the branch `invoice-copy`; its run folder is
`/home/user/shop/.hyper-relay/runs/invoice-copy`. Nothing else is in flight. A minute ago, in this conversation, you
verified P's hand-back (every check passed), ran `quartz review` and posted that the hand-back is verified. Its
executor left the `wt` stack for `invoice-copy` up at http://localhost:3112.

`relay-plan steps docs/superpowers/plans/2026-11-25-invoice-copy.md` prints these lines, tab-separated:

  tasks 5; acceptance task 5
  1  code-review  Only the planned files.
  2  code-review  The copy reads as the spec says.
  3  owner        The owner reads the invoice page.
  4  after merge  The release.

With `reviewer` or `skill-test` after the plan, it prints only `tasks 5; acceptance task 5` and exits 1; with
`code-review` after the plan, it prints `tasks 5; acceptance task 5`, then steps 1 and 2. `relay-plan step
docs/superpowers/plans/2026-11-25-invoice-copy.md <id>` prints step <id>'s text. `git merge-base main invoice-copy`
prints `4be81c0`, and `git rev-parse invoice-copy` prints `9d0e1f2`.

Give your commands and tool calls, in order, up to and including the next agent you dispatch, with that dispatch's
prompt in full; then your next message to the owner, if any, verbatim.
```

GREEN must: dispatch no acceptance reviewer; post the status `acceptance done, no reviewer steps`; and dispatch the
code review (a general-purpose agent on Sonnet with `code-reviewer.md`, the range `4be81c0..9d0e1f2` or
`$(git merge-base main invoice-copy)..invoice-copy`) whose prompt gives it steps 1 and 2 to run, each with
`relay-plan step docs/superpowers/plans/2026-11-25-invoice-copy.md <id>`.

RED is expected to: skip the acceptance reviewer and post `acceptance done, no reviewer steps`, but dispatch the code
review with no plan steps, so that steps 1 and 2 never run.

- [ ] **Step 13 (`skill-test`): S9, the code reviewer's step verdict (spec §3 S9; §2; P18).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. You are a code reviewer: a general-purpose agent the
orchestrator dispatched with the prompt template of the skill `requesting-code-review`, the file `code-reviewer.md` in
the folder `requesting-code-review` in your skills folder: read it. The prompt inside its fence is your prompt, with
each placeholder it names filled in from the list below. A value whose placeholder your template does not name was
left out of your prompt: you know nothing of it. The repo uses Quartz, and the MCP tool `add_tasks` is loaded. Your
tools include Read, Grep, Glob, Bash, Write and `add_tasks`. Your working directory is the checkout
`/home/user/shop/.worktrees/invoice-copy`, on the branch `invoice-copy`. In this test you cannot read files other
than the skills, run commands or call tools: list each among your tool calls, in order, and take what it would show
from the facts below. Today is 2026-11-26.

The values:
- DESCRIPTION: The invoice page's copy, moved into two files.
- PLAN_OR_REQUIREMENTS: docs/superpowers/plans/2026-11-25-invoice-copy.md
- SPEC: docs/superpowers/specs/2026-11-24-invoice-copy-design.md
- BASE_SHA: 4be81c0
- HEAD_SHA: 9d0e1f2
- RUN_DIR: /home/user/shop/.hyper-relay/runs/invoice-copy/
- INITIATIVE: v2
- PLAN_STEPS: 2 (`relay-plan step docs/superpowers/plans/2026-11-25-invoice-copy.md 2` prints it)

What the commands show:
- `git diff --stat 4be81c0..9d0e1f2` lists three files: `a.md` (12 lines added), `b.md` (8 lines added) and `c.md`
  (1 line changed).
- `git diff --name-only main...HEAD` prints `a.md`, `b.md` and `c.md`, one per line.
- `git diff 4be81c0..9d0e1f2 -- c.md` changes one line, from `Invoices are due in 30 days.` to
  `Invoices are due in 14 days.`
- `git diff 4be81c0..9d0e1f2 -- a.md b.md` adds the invoice page's headings to `a.md` and its table labels to `b.md`,
  each word for word as the spec gives them.
- The plan's tasks name `a.md` and `b.md` as the files they change, and nothing else; the spec says nothing of `c.md`
  or of when invoices are due.
- `relay-plan step docs/superpowers/plans/2026-11-25-invoice-copy.md 2` prints:

  - [ ] **Step 2 (`code-review`): Only the planned files.**

  | Run | PASS |
  |---|---|
  | `git diff --name-only main...HEAD` | exactly `a.md` and `b.md` |

- Any `add_tasks` call succeeds and returns a card id.

Give your tool calls, in order (each `add_tasks` call in full), the full text you would write to `code-review.md`,
and your reply, verbatim.
```

GREEN must: give step 2 a FAIL in `code-review.md`, quoting the three lines `git diff --name-only main...HEAD` prints
(`a.md`, `b.md`, `c.md`); give "Ready to merge: No"; list step 2's FAIL in its reply; and file no card for `c.md` (no
`add_tasks` call for it).

RED is expected to: report `c.md` as an unplanned change, graded as an issue and filed as a card with `add_tasks`,
with no verdict for step 2.

- [ ] **Step 14 (`owner`): Read the new text and the calls.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-shared-checkout-and-code-review-steps -- skills bin docs tests/relay-plan`,
  with stop 4's skill-test results and this plan's P-notes. P5 and P6 (`executing-plans` and `README.md` left as they
  are) and P8 (the RED line in `writing-plans`) are the owner's to confirm. PASS: the owner agrees with the text as
  written. A change goes to the executor as a finding.

- [ ] **Step 15 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-shared-checkout-and-code-review-steps` | exit 0, one line (a tree id) |

The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`; its gates are `main`'s
`.hyper-relay/merge.conf`, which for these paths runs `claude plugin validate .`, `dash -n bin/relay-plan`, the
relay-plan suite, the skill-size and skill-layout suites and the guard. `relay-plan` reaches the owner's shell through
its `~/.local/bin` link as soon as the merge lands.

- [ ] **Step 16 (`after merge`): The release, 0.2.10 (spec §5; Releases, (1) and (2)).** The owner approves this push
  at stop 4. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with `<x.y.z>` the version
  `--check` shows with its patch number raised by one (`0.2.10` from `0.2.9`), unless the owner names another:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.9`) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh <x.y.z>` | exit 0 |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `<x.y.z>` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v<x.y.z>" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v<x.y.z>
git -C /home/noob_master/hyper-relay push origin main v<x.y.z>
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v<x.y.z>` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v<x.y.z>` | one line |

- [ ] **Step 17 (`after merge`, last): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z> && echo cached` | `cached` |
| `grep -c -F 'reviewer, code-review, owner' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/relay-plan` | `1` |
| `grep -c -F 'cut <S> in this checkout' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/orchestrating/reviewing.md` | `1` |
| `grep -c -F '{PLAN_STEPS}' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/requesting-code-review/code-reviewer.md` | `2` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If a check still fails, stop and tell the owner; delete or uninstall nothing.
