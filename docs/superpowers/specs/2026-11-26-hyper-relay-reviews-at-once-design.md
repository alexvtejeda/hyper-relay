# hyper-relay: the reviews start at once, in one fix loop that reruns what each fix touches (design)

**Date:** 2026-11-26 · **Status:** written from the owner's brainstorm of 2026-11-26, waiting on the owner's review
**Card:** Code review alongside acceptance, in one fix loop that reruns what each fix touches (`22db9543-8836-44ff-a6e4-f4600c930458`)
**Scope:** this repo. The `orchestrating` skill (`reviewing.md`, `quartz.md`, `SKILL.md`, and the lines of
`parallel.md` and `dispatching.md` that name the review order or a moment's number), `requesting-code-review`
(`SKILL.md`), one line of `writing-plans/SKILL.md`, then a release.
**Order:** this design is written against the review leg as the shared-checkout plan leaves it (spec
`2026-11-26-hyper-relay-shared-checkout-and-code-review-steps-design.md`, plan
`docs/superpowers/plans/2026-11-26-hyper-relay-shared-checkout-and-code-review-steps.md`). It is planned once that
plan's branch has merged, so its planner reads the merged files.

## Goal

Two cards from the SAT run report (card `f7b71482`, "What didn't" 1 and 5), merged by the owner because both reshape
the review leg's fix loop.

- **The code review runs beside acceptance** (card A). Today it runs last, after acceptance and its fixes, so its
  findings start a second round of fixes and rechecks after acceptance is done. On System emails C it found the run's
  two worst defects (an `href` security hole and a race that lost drafts) after acceptance, and both forced rechecks.
  Since 2026-11-20 the owner has run SAT this way by hand, through a memory rule that overrides `reviewing.md` §3.
- **One rerun rule for every fix round** (card B). Today an acceptance fix reruns "only the steps that failed", a
  Critical's fix reruns "the steps the fix touches", and a gap the owner decides to fix on the branch, which is no
  FAIL, has no rule at all. On System emails C the tú/usted fix left the orchestrator unsure, and the reviewer was not
  rerun.

After this change the reviews all start when the hand-back is verified (acceptance, the code review and the skill
tests), every finding they make feeds one fix loop, and after each round everything the round touched is checked
again, whatever started the round.

## Decisions (owner)

1. **The skill tests start beside acceptance too**, with the code review. Why: a failed GREEN found after the loop is
   the same lateness this card removes.
2. **Approach 1: each round waits for every review.** The first fix round starts when all three reviews are back and
   checked, and takes every finding at once. After each round all three recheck at once, and the next round waits for
   all three rechecks. Why: the fewest rounds, one rule for every round, and nothing reads the checkout while the
   executor changes it.
3. **Each reviewer decides for its own steps which ones a round touched,** and its recheck report lists every step as
   rerun or skipped, with the reason. The orchestrator never reads the plan whole, and steps often name commands
   rather than files, so a match by file name would miss.
4. **The playback, both parts, as written in §1 to §3 below**, including: the code reviewer's range fixed at the tip
   it starts on; a fresh code reviewer on the round's range when the resumed one is gone; every GREEN redone when a
   round changes anything in the skills folder; the cap unchanged.
5. **Order and release:** planned after the shared-checkout plan merges; released as the next patch after it (0.2.11
   when that one is 0.2.10); the SAT memory deleted after the owner has updated.

## How it works

Read on `main` at `e2c68cd`, version 0.2.9, on 2026-11-26. The shared-checkout plan changes some of these lines
(noted), so the line numbers are a guide, not a target; its planner reads the merged files.

**The review leg today** (`skills/orchestrating/reviewing.md`, 18,279 bytes):

- §1 (line 11) dispatches the acceptance reviewer alone, then posts moment 5 (line 23). A plan with no `reviewer`
  steps skips it and posts moment 6 at once.
- §2 sorts each FAIL and BLOCKING finding: an execution bug is a fix round for the executor; a gap in the spec or plan
  goes to the owner at once, who decides "fix it on this branch (it goes to the executor as a finding, and you record
  it as a deviation), or a new card". After a round is verified, "the reviewer, resumed or fresh, reruns only the
  steps that failed, and appends a `## Rerun after fix round <k>` section to `report.md`" (line 72). The cap (line 76)
  reads `fix-rounds:` from `main`'s facts file, 2 without it; a finding still failing after that many rounds becomes a
  "fix cap reached" card. When the loop ends it posts moment 6 (line 89), and a plan stacked on this one is cut (line
  94; the shared-checkout plan moves this trigger to the end of §3, after the base's code review).
- §3, "The code review, last" (line 96), starts "when every acceptance FAIL is fixed, capped, or turned into a card",
  with the range `$(git merge-base main <branch>)..<branch>`, and "runs once per branch, after acceptance and its
  fixes, so it reads the final diff" (line 103). A real Critical is a fix round; then "resume the code reviewer to
  check only the fix commits (when it cannot be resumed, read that diff yourself), and have the acceptance reviewer
  rerun the steps the fix touches (all its steps, when that is unclear)" (line 109).
- §3's skill tests run "at the same time as the code review" (line 114). They read copies of the skills, put in
  `<run>/skill-tests/red/` and `green/` by `git archive` (step 1), never the checkout. Step 5 (line 150): a failed
  GREEN is a fix round, after which a fresh copy goes in `green/` and only that step's GREEN reruns. A GREEN that
  passed is never rerun, even when a later fix changes the skill it tests.
- Moments 7 and 8 (line 154) post the code review's dispatch and its end.

**The board** (`skills/orchestrating/quartz.md` §4, lines 174–185): moment 5 is "the acceptance reviewer is
dispatched, and each fix round"; 6 is `acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds`, `next: the code review
and the skill tests`; 7 is `code review and skill tests`; 8 is `code review done, C Critical (x fixed, y dropped), I
Important, m Minor; skill tests G/S GREEN`, `next: stop 4`; 9 is stop 4; 10 is after the merge. The shared-checkout
plan adds `plan steps P/Q PASS` to moment 8 and, for a base with a plan stacked on it, `next: cut <S> in this
checkout`. `moment <n>` is named 9 times in `reviewing.md`, 3 in `planning.md` and 2 in `dispatching.md`
(`grep -n 'moment [0-9]' skills/orchestrating/*.md`), and the shared-checkout plan may add more in `parallel.md`.

**`orchestrating/SKILL.md`** (10,257 bytes): its table for statuses written before `next:` existed sends
"acceptance done" to `reviewing.md` §3 and "code review done" to stop 4 (lines 88–89). New statuses always carry
`next:`, so those rows only read old cards.

**`requesting-code-review/SKILL.md`** (4,166 bytes) says the order in five places: the description (line 3, "once
per branch and last"), the core principle (line 10, "one review of the whole branch, last"), When to Request (line
15, "after its acceptance check and the fixes it led to"), the example's first line (line 53, "Acceptance passed on
the branch index-repair; the fixes it led to are committed") and Integration (line 80, "once per branch, last: after
the acceptance check and its fixes, so it reads the final diff"). Its step 1 already fixes `HEAD_SHA` with
`git rev-parse <branch>`. `code-reviewer.md` takes `{BASE_SHA}` and `{HEAD_SHA}` (lines 28–35) and reviews that range
against the plan.

**`writing-plans/SKILL.md`** line 113: "The orchestrator runs each scenario on both, after acceptance and beside the
code review".

**The acceptance reviewer templates** (`templates/agents/reviewer-commands.md` line 94, `reviewer-browser.md` line
114) already say "a rerun after a fix round appends a `## Rerun after fix round <k>` section". They run only what the
dispatch names, so they need no change, and the repos' role agents need no regeneration.

**The executor's fix round** (`skills/executing-plans/SKILL.md` §Fix rounds, line 115) reruns only the tests that pin
the fix and appends `## Fix round <k>` to `executor.md`, each fix with its commit. Unchanged.

**The guard** (`tests/orchestrating/run-tests.sh`, "48 passed, 0 failed") pins nothing about the review order. Three
of its checks bound the new wording: `skills/requesting-code-review` must not say `each task`, `per task`, `next
task`, `task <digit>` or `completing tasks` (check 1); `skills/orchestrating` must not say `rerun the gates` (check
15) or `second fix round` (check 16), and `reviewing.md` must keep a line with `fix-rounds` (check 16).

**The SAT memory** is `~/.claude/projects/-home-noob-master-sat-pentraze-com/memory/code-review-alongside-acceptance.md`,
indexed at line 4 of that folder's `MEMORY.md`. Two other memories there link to it: `test-suite-cadence.md` line 15
(`Related: [[code-review-alongside-acceptance]], …`) and `reviewer-checks-handback.md` line 11 (`(see
[[code-review-alongside-acceptance]])`).

**Flagged for the planner to re-check:** the text and line numbers of `reviewing.md`, `quartz.md`, `parallel.md`,
`SKILL.md` and `requesting-code-review/SKILL.md` after the shared-checkout plan merges, because that plan rewrites the
same paragraphs. This design names what changes by meaning, so it holds whatever the exact merged wording is.

## Approaches

- **1. Each round waits for every review (picked).** All three start together; the first round waits for all three
  and takes every finding; after each round all three recheck at once, and the next round waits for them. The first
  fix waits for the slowest review, usually the skill tests. In return: the fewest rounds, one rule, and nothing reads
  the checkout while the executor changes it.
- **2. Fix as reports arrive.** A round starts once acceptance and the code review are back; the skill tests, which
  read their own copy, keep running, and their failures join the next round. The first fix comes sooner, but rounds
  multiply, the cap fills faster, and a GREEN can judge text a fix already changed.
- **Dropped:** keeping two loops and only starting them together (the second loop is what card A removes); having
  `relay-plan` match a step's text against a round's changed files to choose the reruns (steps often name commands,
  not files).

## 1. The reviews start at once

**One dispatch.** When `dispatching.md` §7 has verified the hand-back and run `quartz review`, one message dispatches,
in the background:

- **the acceptance reviewer**, on the plan's `reviewer` steps, with today's §1 prompt;
- **the code reviewer**, on the whole branch, with today's §3 prompt, the shared-checkout plan's `{PLAN_STEPS}`, and
  `{HEAD_SHA}` fixed at the branch's tip as it is now (`git rev-parse <branch>`), not the branch's name: the reviewer
  reads exactly what acceptance reads;
- **the skill-test runs**, RED and GREEN for each `skill-test` step, set up as §3's steps 1–3 say today; the judge goes
  when every run has replied, as today.

A plan with no `reviewer` steps dispatches no acceptance reviewer, and one with no `skill-test` steps runs no skill
tests; the code review always runs. Then post the status note (§3 below).

**Why they can run at once:** none of them changes anything. The acceptance reviewer is report-only and runs its
checks in the checkout; the code reviewer reads a fixed range; the skill-test runs read copies in the run folder.

**Each summary is verified as it arrives,** as today: the acceptance reviewer's (every named step has a verdict, each
PASS its evidence, one FAIL rerun where read-only); each Critical and each `code-review` FAIL checked against the code
(`hyper-relay:receiving-code-review`), a wrong one dropped with its reason for stop 4; the judge's verdicts.

**The first fix round waits** until all three are back and verified. Then §2 sorts everything at once.

`reviewing.md` keeps its section numbers, so every `reviewing.md §<n>` reference elsewhere still holds: §1 becomes
the reviews' start (all three dispatches), §2 the fix loop, §3 how the code review and the skill tests are set up and
verified, no longer "last" (my call: the builder may move text between §1 and §3, but not renumber).

## 2. One fix loop

**One sort.** Every finding from any review goes through §2's sort: an acceptance FAIL or BLOCKING finding, a real
Critical, a `code-review` step's FAIL, a failed GREEN.

| Kind | Goes to |
|---|---|
| An execution bug | The next fix round, with every other such finding |
| A gap in the spec or the plan | The owner, at once, as today; when they decide to fix it on this branch, it is a finding in the next round, recorded as a deviation |

Important and Minor findings, and PRE-EXISTING and POLISH ones, stay proposed cards, as today.

**The round.** Today's fix prompt, with every finding the round takes, each as its verdict line and its evidence path
in the run folder. The executor's side does not change. The round is verified with `dispatching.md` §7's checks as
today. The round's range is `<R>..<tip>`: `<R>` is the tip the reviews last read (the tip they started on, for round
1; the tip after the previous round, after that), and `<tip>` the branch's tip after the fix. `<R>` goes in the
round's status line (§3), so it survives a `/clear`.

**The rechecks, one rule for every round, whatever started it.** When the round is verified, one message sends all
three, each on the round's range:

- **The acceptance reviewer**, resumed or fresh: rerun every step that failed, and each passed step whose files the
  round touched (`git diff --name-only <R>..<tip>` lists them); when it is unclear whether the round touched a step,
  rerun it. NEEDS-HUMAN steps stay for the owner. Its `## Rerun after fix round <k>` section lists every `reviewer`
  step as rerun, with its new verdict, or skipped, with why. You verify that every step has a line. A plan with no
  `reviewer` steps skips it.
- **The code reviewer**, resumed: review only `<R>..<tip>`, against the findings the round fixed: whether each is
  fixed, and whether the commits break anything; rerun its `code-review` steps that failed or that the round touched;
  append a `## Fix round <k>` section to `code-review.md`; file new Important and Minor findings as proposed cards, and
  never re-file earlier ones. When it cannot be resumed, a fresh code reviewer, a general-purpose agent on Sonnet, gets
  `code-reviewer.md` with `{BASE_SHA}` `<R>` and `{HEAD_SHA}` `<tip>`, and the same instruction in its prompt, with
  the path of `code-review.md` for what the branch review found. (Today the orchestrator reads that diff itself; it
  reviews nothing itself anywhere else.)
- **The skill tests:** when `git diff --name-only <R>..<tip> -- <skills>` prints anything (`<skills>` as §3 step 1
  names it), put a fresh copy of the branch's skills in `green/`, rerun every step's GREEN, and have the judge,
  resumed or fresh, judge every step again; otherwise rerun only a GREEN that failed, if any. RED never reruns:
  `main` has not changed.

A finding that has reached the cap is not rerun in later rechecks: its line says `skipped: capped, card <card id>`,
and it is no new finding (my call). A stop-4 "one more round" for it is a round like any other, with all three
rechecks after it.

The next round waits until all three rechecks are back and verified. A new finding from a recheck, such as a Critical
in a fix commit or a step a fix broke, goes through the same sort and joins it.

**A review that cannot finish** (my call, as today): when `relay-plan scenarios` exits 1, the skill tests stop and the
owner is told at once, as §3 step 2 says today, and the loop goes on with the other reviews; stop 4 says so. A summary
that fails its verification goes back to its agent, as today, and the wait goes on.

**The cap does not change.** `fix-rounds:` from `main`'s facts file, 2 without it. A round counts once for each
finding in it; a finding still failing after the cap becomes the "fix cap reached" card, and the loop carries on;
stop 4 opens with it. A finding a fix introduced starts its own count. A gap is not capped.

**When the loop ends** (every finding fixed, capped, dropped, or made a card by the owner; NEEDS-HUMAN steps may
remain): post the "reviews done" status (§3). A plan stacked on this one is cut now, as the shared-checkout plan
says for the point its base's reviews are done: that point is this one.

What §2 and §3 say today and this replaces: "reruns only the steps that failed" (§2); the Critical's own recheck
paragraph and "read that diff yourself" (§3); step 5's rerun of only the failed GREEN (§3). A capped finding, the
cards, and the conflict round are unchanged.

## 3. The board, and where work stands

**The status moments** (`quartz.md` §4). Today's 5 to 8 become two, and 9 and 10 become 7 and 8; every `moment <n>`
in the skills follows (my call; the builder greps `moment [0-9]`):

| # | Moment | `<where it stands>` | `next:` |
|---|---|---|---|
| 5 | The reviews are dispatched, each fix round, and each round's rechecks (`reviewing.md` §1 and §2) | `reviews: <the reviews dispatched>`; `fix round <k> of <cap>, from <R>: <findings>`; `rechecks after fix round <k>` | `the fix loop`; `verify the fix`; `the fix loop` |
| 6 | The fix loop ends (`reviewing.md` §2) | `reviews done: acceptance N/M PASS, K NEEDS-HUMAN; code review C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN; F fix rounds` | `stop 4` (for a base with a plan stacked on it, the shared-checkout plan's `cut <S> in this checkout`) |

`<the reviews dispatched>` names those that ran (`acceptance, code review, skill tests`); "reviews done" leaves out
the acceptance part for a plan with no `reviewer` steps, `plan steps` for one with no `code-review` steps, and the
skill tests for one without them. `agents:` names every review agent still running, as today; the skill-test runs go
by their number. Moment 4's `next:` becomes `the reviews`.

**After a `/clear`,** `SKILL.md`'s Finding where work stands holds as it is: while `agents:` names a review whose
report is not in the run folder (`acceptance/report.md`, `code-review.md`, the skill-test answer files and
`verdicts.md`; for a recheck, its round's section), you wait as it says, and once every report is in, `next: the fix
loop` is §2's sort of what they found. A round's status is posted in the message that sends it, so a round decided but
not sent is no state of its own.

**`orchestrating/SKILL.md`:** the stops table and the legs table need no change. The table for statuses written before
`next:` existed keeps its rows, as they describe old cards (my call); the builder checks that "acceptance done" still
leads to the code review and the skill tests in §3's new text.

## 4. The other skills

- **`requesting-code-review/SKILL.md`:** its five lines say the new order: in the relay, once per branch, beside the
  acceptance check, when the executor hands back; then on each fix round's commits. The description becomes, for
  example, "in the relay, once per branch beside the acceptance check, run by orchestrating's reviewing.md"; the
  example's first line becomes a verified hand-back, with acceptance starting beside the review. None of them may say
  a phrase guard check 1 refuses (How it works). It stays well under 20,000 bytes.
- **`code-reviewer.md`:** unchanged. A recheck's instruction is the orchestrator's prompt (§2), on top of the template
  for a fresh reviewer (my call: it keeps the template one review of one range).
- **`writing-plans/SKILL.md` line 113:** "after acceptance and beside the code review" becomes "beside acceptance and
  the code review". A planner's behaviour does not change, so it has no scenario.
- **`parallel.md` and `dispatching.md`:** only the lines that name the review order or a moment's number.

## 5. Pressure scenarios (the plan's skill tests)

For each behaviour the text changes, the situation, what an agent with the new text must do (GREEN), and what one with
today's text does instead (RED). The plan writes each as a `skill-test` step with its situation in a fence. All six
are the orchestrator's.

| # | Situation | GREEN must | RED is expected to |
|---|---|---|---|
| 1 | The executor's hand-back for `index-repair` is verified and `quartz review` has run. The plan's acceptance steps: 1–3 `reviewer`, 4–5 `skill-test`, 6 `owner`. | In one message, dispatch the acceptance reviewer (steps 1–3), the code reviewer (range from `git merge-base main index-repair` to the tip's SHA) and four skill-test runs (RED and GREEN for steps 4 and 5); then post the `reviews:` status. | Dispatch the acceptance reviewer alone; the code review and the skill tests wait for the fix loop to end. |
| 2 | Step 2 came back FAIL, an execution bug, confirmed; the code reviewer and the four skill-test runs have not replied. | Send no fix round yet; wait for the code review and the judge. | Send fix round 1 for step 2 now. |
| 3 | All three reviews are back and verified: step 2 FAIL (an execution bug); one Critical, checked against the code and real; skill tests 2/2 GREEN. | One fix round 1 that carries both the step-2 FAIL and the Critical. | A fix round for step 2 alone; the Critical waits for a round of its own. |
| 4 | Fix round 1 from `a1b2c3d` fixed step 2, changing only `bin/tool`, and is verified. Step 1 (PASS) runs `bin/tool --check`; step 3 (PASS) reads `docs/tool.md`. No file under `skills/` changed. | In one message: the acceptance reviewer to rerun step 2 and each passed step the round touched (rerun it when unsure), listing every step as rerun or skipped with why; the code reviewer, resumed, on `a1b2c3d..<tip>` only; no GREEN rerun. | Rerun step 2 alone, and give the fix commits no code review. |
| 5 | The owner decided a spec gap (a heading's wording) is fixed on the branch. Fix round 1 changed `skills/foo/SKILL.md` and is verified. No step had failed; the skill tests were 2/2 GREEN. | Recheck all three: the acceptance reviewer on the steps the round touched (all when unclear); the code reviewer on the round's range; a fresh `green/` copy, both GREENs rerun, and the judge again. | Rerun nothing, since nothing failed, and go on to stop 4. |
| 6 | Fix round 2 is verified; resuming the code reviewer fails because the agent is gone. | Dispatch a fresh code reviewer on Sonnet with `code-reviewer.md`, the round's range as `{BASE_SHA}`..`{HEAD_SHA}`, and the instruction to check only those commits against the round's findings. | Read the round's diff itself. |

Scenario 5 is card B's case. In every scenario, RED reads `main`'s skills as the shared-checkout plan leaves them
(`reviewing.md` §3 step 1), which is what this change starts from.

## 6. Testing and acceptance

- **Gates:** `sh tests/orchestrating/run-tests.sh` (still `0 failed`: checks 1, 15 and 16 bound the new wording),
  `sh tests/skill-size/run-tests.sh`, `sh tests/skill-layout/run-tests.sh`, and `claude plugin validate .` with its
  three known warnings. No `bin/` script changes.
- **No new guard check** (my call): the skill tests carry the behaviour, and a check that tests one phrase is what card
  `6b541c88` calls thin.
- **The skill tests:** §5's six scenarios.
- **Acceptance**, as `code-review` steps (the kind the shared-checkout plan adds): the branch changes only the files in
  Scope; `reviewing.md` no longer says "reruns only the steps that failed", "read that diff yourself" or that the code
  review runs last, and `requesting-code-review` no longer says "last" about the relay's order; every `moment <n>` in
  `skills/` names a row of the new table.

## 7. Release, and the SAT memory

The merge changes `skills/`, so it is released as the next patch after the shared-checkout plan's release (0.2.11
when that one is 0.2.10), unless the owner names another (`CLAUDE.md`, How a change reaches the owner). The plan's
acceptance task ends with these `after merge` steps, in order:

1. The release: `scripts/bump-version.sh <x.y.z>`, a commit of `package.json` and `.claude-plugin/plugin.json`
   (`chore: release v<x.y.z>`), the tag, then push `main` and the tag.
2. The owner updates (`claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins`).
3. Only then, with the owner: delete the SAT memory file, its line in that folder's `MEMORY.md`, the
   `[[code-review-alongside-acceptance]]` link in `test-suite-cadence.md`'s `Related:` line, and the
   `(see [[code-review-alongside-acceptance]])` in `reviewer-checks-handback.md` (How it works). Until the owner has
   updated, a SAT session still loads today's `reviewing.md`, and the memory is what keeps its order.

## 8. Out of scope, and left to the builder

**Out of scope:**

- What the executor runs in a fix round (still only the tests that pin the fix).
- The fix-round cap's value and how a capped finding is handled.
- `code-reviewer.md`, the acceptance reviewer templates, `relay-plan`, `wt` and `relay-merge`.
- Stacked plans beyond moving their cut to the base's "reviews done".

**My calls, for the owner to check while reading:**

- `reviewing.md` keeps its section numbers (§1).
- The round's start tip `<R>` goes in the fix round's status line (§2).
- The four moments become two and the rest renumber (§3).
- The old-status rows in `SKILL.md` stay (§3).
- `code-reviewer.md` does not change; a recheck is the orchestrator's prompt (§4).
- No new guard check (§6).
- A capped finding is skipped in later rechecks (§2).
- A review that cannot finish leaves the loop going with the others, as the skill tests do today (§2).

**Left to the builder:** the exact wording in each file; how text moves between `reviewing.md` §1 and §3; the order
of the changes; the names in the scenarios' situations.
