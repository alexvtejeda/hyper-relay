# hyper-relay: a chain of plans shares one checkout, and reading checks go to the code review (design)

**Date:** 2026-11-26 · **Status:** written from the owner's brainstorm of 2026-11-26, waiting on the owner's review
**Cards:** Plans that run one after another share one worktree (`af65b2bc-b565-4a8f-8e39-bd0517f18625`), Reviewer steps that only run commands go to a cheaper place (`abb0ccba-84a2-4312-9bdd-9512b806d6da`)
**Scope:** this repo. The `orchestrating` skill (`SKILL.md`, `parallel.md`, `dispatching.md`, `reviewing.md`,
`quartz.md`), `writing-plans` (`SKILL.md`, `plan-document-reviewer-prompt.md`), `requesting-code-review` (`SKILL.md`,
`code-reviewer.md`), `bin/relay-plan` with its tests and `docs/relay-plan.md`, then a release.

## Goal

Two cards from the SAT run report (card `f7b71482`, "Report from a real run"), brainstormed together because both cut
what a relay run spends without weakening any check, and both rewrite the same review leg.

- **A chain of plans shares one checkout** (card `af65b2bc`). When one plan builds on another (a web plan on an API
  plan), today's skill cuts the second plan its own worktree, with its own install and its own stack, and holds its
  reviews until the first plan has merged. The owner already runs SAT's pairs differently, in one worktree, and wants
  that to be the relay's rule: "I would prefer it, if we have one worktree for both plans in this case. Run the API's
  tests and code review, and then start implementing the web plan on that same worktree."
- **Reading checks run once, in the code review** (card `abb0ccba`). A plan's acceptance task holds two sorts of
  `reviewer` step: checks that need something running (a stack, a browser, a scratch repo, a live session), and checks
  that only read the diff, the text or the executor's logs. The second sort repeats the code review, which already
  reads the branch's whole diff against its plan and its spec. On the upstream-fixes run of 2026-11-26, every
  acceptance step was a reading check: the acceptance reviewer spent 89,021 tokens on them, and the code reviewer then
  spent 91,704 going over much the same ground (How it works).

**Success:** a chain of plans uses one folder, one install and one stack at a time, with one click-through and one
merge for the whole chain; a plan with nothing to run needs no acceptance reviewer; and every check still runs once,
by an agent other than the executor.

## Decisions (owner)

All from the brainstorm of 2026-11-26, recorded on the cards as they were made.

1. **One spec for both cards.**
2. **When the stacked plan starts: after its base's code review and its fixes** (option B). Why: one executor in the
   folder at a time; only a fix at stop 4 would need the folder switched back, and the stacked executor builds on a
   base that is already fixed.
3. **One stop 4 for the chain** (joint). Both plans share one ready-to-merge stop and one click-through, on the stacked
   plan's stack (it holds both), and the stacked plan's reviews run before the base merges, on its own commits on top
   of the base. `relay-merge` then lands the base, then the stacked plan. Why: one click-through, as the owner already
   does in SAT (three pairs since 2026-11-23).
4. **One worktree for both plans** (the owner's words above). Part 1 of the playback confirmed: in worktree mode the
   base's worktree, in branch mode the main checkout; only the base's `wt` stack comes down, and the folder's installs
   stay. Plans that run side by side still get a worktree each.
5. **Reading checks: approach A.** Acceptance keeps only checks that need something running; the reading checks
   become a new step kind the code reviewer runs; a plan with no live step skips the acceptance reviewer. Why: it
   removes a check done twice instead of moving it, and every check stays independent of the executor. Part 2 of the
   playback confirmed it as written in §2.
6. **Part 3 confirmed:** the nine pressure scenarios of §3, one plan, and the release of §5.

## How it works

Checked on 2026-11-26 against `main` at `355b97e` (hyper-relay 0.2.9), and against SAT's run folders. None of these
needs re-checking by the planner.

**Stacked plans today.**

- `skills/orchestrating/parallel.md` §3: a stacked plan is cut "when the base passes acceptance (its fix loop has
  ended)", into its own worktree: `git worktree add .worktrees/<S> -b <S> <B>`, or `wt new <S> --from <B>`. Its review
  legs (the hand-back check, acceptance, the code review) "wait until its base has merged", then a catch-up round
  merges `main` into it. `reviewing.md` §2 (line 94) triggers the cut: "When the fix loop ends and a plan is stacked
  on this one, cut and dispatch it now." `SKILL.md`'s Finding-where-work-stands table (line 78) holds a stacked branch
  whose base has not merged: "no review leg until the base merges".
- `parallel.md` §1, "All worktrees": "when two or more plans would be in flight, each runs in a worktree; Branch is
  offered only for a plan that will run alone". `dispatching.md` §1 says the same. Its handoff question words a
  stacked plan's line "stacked on plan 1; starts when plan 1 passes acceptance".
- `parallel.md` §4: each plan lands after its own stop 4; a stacked plan always after its base.
- Ranges that assume the base has merged: `dispatching.md` §7 check 2 lists the branch's commits with
  `main..<branch>`; `reviewing.md` §3 gives the code reviewer `$(git merge-base main <branch>)..<branch>`, and its
  skill tests take RED's skills from `main` (`git archive main <skills>`). On a stacked branch whose base has not
  merged, each of these holds the base's work as well as its own.
- `quartz.md` §4, moment 8, posts `code review done, …` with `next: stop 4`, and `SKILL.md` (line 89) sends a
  "code review done" status to stop 4.

**`wt`** (`bin/wt`, `docs/wt.md`).

- A stack is named after the branch checked out in the folder: `locate_worktree` sets `STACK="$project-wt-$SLUG"`,
  with `SLUG` from `git branch --show-current` (`bin/wt` lines 32–45). After the folder switches branch, `wt` looks for
  a stack under the new branch's name.
- `wt down` without a name acts on the current worktree's stack (`docs/wt.md`, `wt ls` and `wt down`), so it has to
  run while the base's branch is still checked out. It deletes the stack's containers, database, images and state, and
  the `.env` it wrote (`bin/wt` lines 433–436).
- `wt up` refuses a `.env` that this stack did not write: "already exists and wt did not create it; move it away
  first" (`bin/wt` lines 108–110). So the base's stack must come down before the switch, or the stacked branch's
  `wt up` stops on the base's `.env`.
- `WT_SETUP` runs once per stack (`docs/wt.md`, step 5), so the stacked branch's new stack runs it once.
  `WT_NEW_SETUP` (the install, such as `npm ci`) runs only at `wt new`, so the folder's install stays.

**`relay-merge`** (`bin/relay-merge`).

- `relay-merge <B> <S>` lands the branches in the order given, each as a `--no-ff` merge whose result must pass the
  gates, and stops at the first failure; the branches before it stay landed (lines 182–221).
- `worktree_of <branch>` finds a worktree by the branch checked out there (lines 47–52). With the shared folder on
  `<S>`, `<B>` is checked out nowhere and lands as a plain branch; `<S>`'s worktree is the shared folder, which must be
  clean and have no `wt` stack up (lines 190–197).
- After every branch has landed, it removes each landed branch's worktree and deletes the branch with `git branch -d`
  (lines 241–258): `<B>` has no worktree, and `<S>`'s removal takes the shared folder. So `relay-merge` needs no change.

**Quartz.** `quartz link-branch <plan>` reads the branch checked out where it runs and stores the link in the repo's
git config as `branch.<branch>.quartzPlan` (`~/quartz/cli/internal/app/linkbranch.go` lines 17–63, `app/git.go` line
55). Git config is shared by every worktree of a repo, so the link follows the branch's name, not the folder: `<B>`'s
link stays when the folder switches to `<S>`, `<S>` gets its own, and removing the folder later changes neither. A
status note's body, `next:` included, is free text in `quartz.md` §4's form.

**Who brings a stack up.** The executor: its acceptance output names "URLs, logins, anything left running"
(`skills/executing-plans/SKILL.md` line 86), the acceptance reviewer is told what it left running (`reviewing.md` §1),
and after a worktree run the owner clicks through on that worktree's `wt` stack (`reviewing.md` §4).

**`relay-plan`** (`bin/relay-plan`). Its step kinds are `reviewer`, `owner`, `after merge` and `skill-test`: `steps
<plan> [reviewer|owner|after-merge|skill-test]` (line 9, lines 322–323), and `check` refuses any other kind (lines
493–494: "is not reviewer, owner, after merge or skill-test").

**The step rules today.** `skills/writing-plans/SKILL.md` line 102 names the kinds; line 103 says "No `reviewer` step
reruns the full gates" and "A `reviewer` step runs what only an independent check can: a live run in a scratch repo, a
check of which files the branch changed, a reading of the new text against the spec." `tests/orchestrating/run-tests.sh`
case 8 requires the line "No `reviewer` step reruns the full gates" in that file. `writing-plans/SKILL.md` is 17,118
bytes; `tests/skill-size/` fails a `SKILL.md` at 20,000. `writing-plans/plan-document-reviewer-prompt.md` (line 30)
lists the kinds too.

**The code reviewer today.** `skills/requesting-code-review/code-reviewer.md` reviews "a branch's whole diff against
its plan, its spec", asking "Is every requirement of the spec met?" and "Is all planned functionality present?", and
flags unplanned changes. Its placeholders are listed in `requesting-code-review/SKILL.md` (lines 34–41). Its
`{BASE_SHA}` is `git merge-base main <branch>` for a branch.

**What the runs show.**

- **SAT's three pairs** since 2026-11-23 (breach automatic notices, stepped-landing editing, launch-unverified sender)
  each ran the web plan in the API plan's worktree. stepped-landing-editing-web's executor report says "Branch
  stepped-landing-editing-web, checkout .worktrees/stepped-landing-editing-api", and the stacks were named per branch
  (`sat-pentraze-com-wt-breach-automatic-notices-api-…`, then `…-web-…`). Each pair merged within minutes: breach at
  13:38 and 13:39 on 2026-11-24, stepped-landing at 19:24 and 19:29, launch-unverified at 16:53 and 17:00. When the
  breach API needed a fix after the cut, its executor switched the folder back to the API branch, committed, and merged
  the API into web (breach-api's fix round 1: "worktree left on breach-automatic-notices-web"). Source:
  `~/sat.pentraze.com/.hyper-relay/runs/*/executor.md`.
- **SAT's last 8 plans** each have a "reads as the spec says" acceptance step, and most an "on a stack" or browser
  step. Their command steps need judgment, such as "`purge_guard_test.go` changes only the client entry".
- **System emails C** (card `abb0ccba`): an API acceptance of four command steps cost 12 minutes and 103k tokens.
- **The upstream-fixes run** (2026-11-26, `.hyper-relay/runs/hyper-relay-upstream-small-fixes/`): five `reviewer`
  steps, all reading checks (files changed, a word-for-word move, fixes against upstream, suites against the plan).
  The acceptance reviewer: 89,021 tokens; its step 5 first passed with no evidence file and was sent back. The code
  reviewer: 91,704 tokens, and its review re-checked the move line by line and reran four suites.

## Approaches

**Where and when a stacked plan runs (`af65b2bc`).**

- *Where.* Its own worktree, as today (a second install and stack, and nothing in the folder to switch), or the
  base's checkout (one install, one stack at a time; a fix to the base means switching the folder back). The owner
  picked the shared checkout (decision 4).
- *When.* A: after the base passes acceptance, as today: the stacked plan starts sooner, but a fix from the base's
  code review waits for the stacked executor to hand back, then is merged into the stacked branch, as SAT's breach did.
  B: after the base's code review and its fixes: it starts a few minutes later, and only a fix at stop 4 needs the
  switch back. The owner picked B (decision 2).
- *Stop 4.* Joint: one stop and one click-through on the stacked plan's stack, then `relay-merge <B> <S>`; if the
  stacked plan then fails its merge, the base stays merged alone. Separate: the base is clicked through and merged
  before the stacked plan is cut, so the stacked plan waits on the owner and there are two click-throughs. The owner
  picked joint (decision 3). Pairs that must land together or not at all stay on card `eaed0a9c`.

**Reading checks (`abb0ccba`).**

- **A (picked).** Acceptance keeps only checks that need something running; the reading checks become `code-review`
  steps that the code reviewer runs within its one review; a plan with no live step skips the acceptance reviewer.
  Text, plus one step kind in `relay-plan`.
- **B.** `relay-plan` runs exact-output checks itself, with no agent. Few checks qualify (most need judgment), and it
  is more code to build and test.
- **C.** Wording only: `writing-plans` asks for fewer command steps. The smallest change, and the smallest saving.

## 1. A chain of plans shares one checkout

A **chain** is a base plan and the plan stacked on it (a `**Builds on:**` line naming the base), and in a longer chain
(C on S on B) each link follows the same rules. A chain's plans run one after another in one checkout: the base's
worktree in worktree mode, the main checkout in branch mode. Below, `<B>` is the base's branch, `<S>` the stacked
plan's, and `<checkout>` the shared folder.

### When the stacked plan starts

When the base's review legs are done, not when its acceptance ends: its acceptance and fix loop (`reviewing.md` §2),
its code review with every Critical fixed or dropped, and its skill tests (§3: moment 8). A finding capped on the base
still becomes a card, and the loop carries on: the cut goes ahead, and the joint stop 4 opens with it.

At that point the base does not go to stop 4. Its moment-8 status says `next: cut <S> in this checkout`, and after the
cut its status says it waits for `<S>`'s reviews and the joint stop 4. `reviewing.md` §2's line 94 trigger moves to
the end of §3.

### The cut, in worktree mode

In the main checkout, with `<checkout>` the base's worktree:

1. `<checkout>` is on `<B>` and clean (`git -C <checkout> status --porcelain` prints nothing), and no executor works
   there.
2. If a `wt` stack is up for it, `(cd <checkout> && wt down)`, while `<B>` is still checked out (How it works: `wt
   down` acts on the checked-out branch's stack, and removes the `.env` that would stop the next `wt up`).
3. `git -C <checkout> switch -c <S>`: the stacked branch, cut from `<B>`'s tip. No `wt new` and no `git worktree add`
   (each makes a second folder), so `WT_NEW_SETUP` does not run and the folder's install stays.
4. `relay-plan run-dir <S plan>` makes `<S>`'s own run folder; `dispatching.md` §4's link runs in `<checkout>` as for
   any worktree run (`quartz link-branch` links the branch checked out there, now `<S>`); then `dispatching.md` §5
   dispatches `<S>`'s executor with the checkout `<checkout>` and the branch `<S>`, cut from `<B>`, which has not
   merged.

The folder keeps the base's name (`.worktrees/<B>`); both branches are kept, since Quartz and `relay-merge` read them
per plan. The stacked executor's own `wt up` builds `<S>`'s stack, named after `<S>`, and runs `WT_SETUP` once for it;
it leaves that stack up, as any executor does, and the joint click-through runs on it.

**A longer chain** (C on S on B) repeats the cut link by link: `<C>` is cut in the same folder, from `<S>`'s tip, once
`<S>`'s review legs are done. Each link's ranges use its own base's tip (`<S>..<C>`), the joint stop 4 opens after the
last link's reviews and covers every link, and the merge is one call, `relay-merge <B> <S> <C>`, in chain order.

**A second plan stacked on the same base** (S1 and S2 both on B) is a tree, not a chain. The first in the spec's
`## The plans` order shares the base's folder; each other one keeps today's rules: its own worktree, cut from `<B>` at
the same moment from the main checkout (`git worktree add .worktrees/<S2> -b <S2> <B>`, or `wt new <S2> --from <B>`,
which work whatever the shared folder has checked out), and its review legs wait until `<B>` merges, then a catch-up
round (`parallel.md` §3 keeps that text for this case).

### Branch mode

A chain counts as one plan for `dispatching.md` §1's rule that Branch is offered only for a plan that will run alone:
when no other plan is in flight or approved beside it, the handoff offers Branch for the whole chain, and the
repo's `execute:` default applies. Then the base runs in the main checkout, and the cut is
`git switch -c <S>` there, once the base's review legs are done (with `dispatching.md` §2's branch preconditions: no
`MERGE_HEAD`, and no tracked changes but the held-back docs). `dispatching.md` §6's hold-back rules last until the whole
chain has merged. The click-through is on the owner's normal stack, which now serves `<S>`, holding both plans.

When other plans are in flight, the chain runs in a worktree (the base's), as decision 4 says, and each plan beside it
in its own.

The handoff question (`parallel.md` §1) words a stacked plan's line by the new rule, for example "stacked on plan 1;
starts in plan 1's checkout once plan 1's reviews are done".

### The stacked plan's reviews

Right after its executor hands back, with no wait for the base to merge and no catch-up round (the base was fixed
before the cut, and the conflict check keeps other plans' files apart, as today):

- **The hand-back check** (`dispatching.md` §7) runs now, in `<checkout>`, with check 2's range `<B>..<S>` while `<B>`
  has not merged. `quartz review` runs there.
- **Acceptance** runs `<S>`'s `reviewer` steps in `<checkout>`, on `<S>`'s stack.
- **The code review** gets the range `<B>..<S>`: `{BASE_SHA}` is `<B>`'s tip for a stacked branch whose base has not
  merged, and `git merge-base main <branch>` otherwise.
- **The skill tests** take RED's skills from `<B>` (`git archive <B> <skills>`) instead of `main`, so RED reads the
  skills as the base leaves them and differs from GREEN only by `<S>`'s work.

A defect in the base's work that `<S>`'s reviews find is the base's to fix (below), not a fix round on `<S>`.

### One stop 4, and the merge

When `<S>`'s review legs are done (its moment 8), one stop-4 message covers the chain, as `reviewing.md` §4 says for
each plan, in its order:

- its questions, for every plan in the chain: each capped finding, the NEEDS-HUMAN and `owner` steps, and where to click
  through (`<S>`'s stack in `<checkout>`; the normal stack in branch mode);
- then the report, a block per plan.

On the owner's go-ahead, in the main checkout: `(cd <checkout> && wt down)` when `<S>`'s stack is up; in branch mode,
`git switch main`; then one call, `PUSH=0 RELAY_MERGE_TRAILERS='…' relay-merge <B> <S>`, base first, read by its exit
code as `reviewing.md` §4 says. When `<B>` lands and `<S>` fails, `<B>` stays landed and `<S>` goes through §4's
handling for its exit code (a conflict round, a refused check, a failed gate). When `<B>` fails, nothing has landed and
`<S>` waits with it. `reviewing.md` §5 then runs for each plan that landed.

### A fix to the base after the cut

When the base needs a change after `<S>` is cut (the owner asks for one at the joint stop 4, "one more round" for a
capped base finding, or a base defect `<S>`'s reviews found), and only while no executor works in `<checkout>`:

1. `wt down` `<S>`'s stack when it is up, then `git -C <checkout> switch <B>` (in branch mode, `git switch <B>`).
2. The fix round goes to the base's executor (`reviewing.md` §2) and is verified as §2 says. The base's reviewers
   rerun the steps the fix touches (all of them, when that is unclear), and the code reviewer, resumed, checks the fix
   commits.
3. `git -C <checkout> switch <S>`, and `<S>`'s executor gets a catch-up round: "Catch-up round: your base `<B>`
   changed (`<commits>`). Merge `<B>` into your branch, rerun your full gates, and report." As today, a catch-up round
   needs no finding and counts toward no fix-round cap. In a longer chain, each later link then catches up in turn on
   its own base (`<S>` on `<B>`, then `<C>` on `<S>`).
4. `<S>`'s reviewers rerun the steps the base's fix touches (all of them, when that is unclear), and the code reviewer
   checks the merge. Then a short joint stop 4 again.

### Unchanged

- Plans that build on nothing run at once, each in its own worktree (`parallel.md` §1).
- A base dropped or stuck stops the stacked plan, which goes to the owner (`parallel.md` §3).
- The planner leg: a stacked plan is planned once its base's plan is committed, against the files as the base leaves
  them (`planning.md` §1).
- `wt` and `relay-merge`: no code change (How it works).

### Where work stands

`SKILL.md`'s Finding-where-work-stands table follows the new rules: a stacked branch whose base has not merged goes by
its review status like any plan's, with the range `<B>..<S>`; a base whose review legs are done ("code review done")
while its stacked plan has no branch yet leads to the cut, not to stop 4; and a base whose stacked plan is in flight
waits for the joint stop 4. The status line's `next:` normally says all of this; the table is the fallback.

## 2. `code-review` steps

### Two kinds of check

A plan's acceptance task gets a fifth step kind, **`code-review`**: a check that only reads what the branch already
holds (its diff and files, the plan and the spec, the run folder's `executor.md` and `gates.log`), with read-only
commands at most (`git diff`, `git show`, `grep`, `wc`, `relay-plan gates`). It starts nothing: no stack, browser,
scratch repo or live session, and it reruns no gate. Examples: which files the branch changed, that existing tests
keep their assertions, that copy comes from the tools, that the new text says what the spec says, that a test failed
before its fix and passed after (from `executor.md` and `gates.log`).

A **`reviewer`** step keeps only the checks that need something running: a stack, a browser, a scratch repo, a live
session. `owner`, `after merge` and `skill-test` steps are unchanged.

### The planner sorts them

`writing-plans` (line 102) lists `code-review` among the kinds: run before the merge, by the code reviewer, within the
branch's one code review. Line 103's list of what a `reviewer` step runs loses "a check of which files the branch
changed, a reading of the new text against the spec", which become `code-review` examples. "No `reviewer` step reruns
the full gates" stays word for word (the guard's case 8), and the same holds for a `code-review` step.
`plan-document-reviewer-prompt.md` lists the new kind, and checks that each check sits in the right one: a reading
check under `reviewer` or a live one under `code-review` is a finding. `writing-plans/SKILL.md` stays under 20,000
bytes.

### `relay-plan`

- `relay-plan steps <plan> code-review` lists the `code-review` steps, as it lists the other kinds.
- `relay-plan check` accepts `code-review` as a kind; any other unknown kind is still refused.
- `relay-plan step <plan> <id>` prints one, as for any step.
- Its usage line, `docs/relay-plan.md` and `tests/relay-plan/` follow: a fixture plan with `code-review` steps, the
  listing, the check that accepts the kind, and the check that still refuses an unknown one.

### The code reviewer runs them

`code-reviewer.md` gets one more placeholder, `{PLAN_STEPS}`: the plan's `code-review` step numbers and the command
that prints each (`relay-plan step <plan> <id>`), or "none" (ad hoc reviews, and plans without them).
`requesting-code-review/SKILL.md`'s placeholder list names it. The reviewer runs each listed step as the plan writes
it, and `code-review.md` gets a section for them: per step, PASS or FAIL, with the command or the reading and the
lines that decide it, quoted. Any FAIL makes the verdict "Ready to merge: No", and the summary lists each FAIL by its
step number, as it lists a Critical. A FAIL is never a card. Its Strengths, Issues and grades are otherwise unchanged:
a listed step is checked once, there, and not again as a separate finding.

### The orchestrator

- **`reviewing.md` §1.** Unchanged in substance: the acceptance reviewer runs only the `reviewer` steps, and a plan
  with none skips the dispatch and posts moment 6 as `acceptance done, no reviewer steps`. It now says that the
  `code-review` steps are §3's.
- **§3.** The code reviewer's prompt fills `{PLAN_STEPS}` from `relay-plan steps <plan> code-review`. Verify its
  summary: every listed step has a verdict in `code-review.md`. A FAIL is checked against the code first, as a Critical
  is (`hyper-relay:receiving-code-review`): a wrong one is dropped with its reason at stop 4, a real one is §2's.
- **§2.** A `code-review` FAIL sorts as an acceptance FAIL does: an execution bug is a fix round, and counts toward
  the cap; a gap in the spec or the plan goes to the owner at once. One that still fails at the cap is handled as §2
  handles any capped finding: you file its "fix cap reached" card, and stop 4 opens with its question (merge with it
  open, hold the branch, or one more round). The code reviewer itself files no card for a FAIL. After the fix, the code reviewer, resumed, checks
  the fix commits and reruns the failed steps, appending to `code-review.md`; the acceptance reviewer reruns the
  `reviewer` steps the fix touches, as after a Critical.
- **Status and stop 4.** Moment 8 (`quartz.md` §4) becomes `code review done, C Critical (x fixed, y dropped), I
  Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN`, leaving out "plan steps P/Q PASS" when the plan has
  no `code-review` steps, as it leaves out the skill tests. Stop 4's report (`reviewing.md` §4, and `SKILL.md`'s
  stops table) gives the `code-review` verdicts beside the acceptance verdicts.

### Old plans

A plan written before this change keeps its reading checks under `reviewer`, and runs as written: the acceptance
reviewer runs them, as today. Nothing migrates. This spec's own plan is one of them: until it merges, `main`'s
`relay-plan check` refuses the new kind, so its reading checks are `reviewer` steps.

## 3. Pressure scenarios (the plan's skill tests)

For each behaviour the text changes, the situation, what an agent with the new text must do (GREEN), and what one with
today's text does instead (RED). The plan writes each as a `skill-test` step with its situation in a fence. Scenarios
1 to 6 and 8 are the orchestrator's; 7 is a planner's; 9 is the code reviewer's.

| # | Situation | GREEN must | RED is expected to |
|---|---|---|---|
| 1 | A spec's API plan and a web plan stacked on it, in worktree mode. The API plan's acceptance has just ended, 4/4 PASS, no fix rounds; its code review has not run. | Dispatch the API plan's code review, and leave the web plan uncut. | Cut the web plan and dispatch its executor now (`reviewing.md` §2 line 94). |
| 2 | The API plan's code review is done (0 Critical, no skill tests). It ran in `.worktrees/billing-api`, whose `wt` stack is up, in a repo with a `.wt.conf`. | `wt down` there, `git -C .worktrees/billing-api switch -c billing-web`, the run folder, and dispatch the web executor with that checkout and branch; no `wt new`, no `git worktree add`. | Create a second worktree (`wt new billing-web --from billing-api` or `git worktree add`). |
| 3 | The web executor hands back in `.worktrees/billing-api` on `billing-web`, gates ok; `billing-api` has not merged, its reviews done. | Run the hand-back check now with `billing-api..billing-web`, then dispatch the web plan's acceptance; its code review, after it, takes that range. | Hold the report until `billing-api` merges, then a catch-up round. |
| 4 | Both plans' reviews are done and clean; the web stack is up in the shared folder; no stop 4 has been sent. | One stop-4 message for both plans, clicking through on the web stack, naming `relay-merge billing-api billing-web` as the merge. | A stop 4 for the API plan alone, to merge it first. |
| 5 | `execute: branch`; the API plan ran on a branch in the main checkout, nothing else in flight; its reviews are done. | `git switch -c billing-web` in the main checkout, and dispatch the web executor there. | Open a worktree for the web plan. |
| 6 | Two plans from one spec, neither builds on the other, in a repo with `execute: branch`. | Run each in its own worktree, and say so in the handoff question (a guard: nothing changes here). | The same. |
| 7 | A planner writes the acceptance task for a plan that changes a web page: the page shows a banner on a stack, the copy matches the spec, only the named files change. | The browser check as `reviewer`; the copy check and the file check as `code-review`. | All three as `reviewer`. |
| 8 | A hand-back is verified; the plan's acceptance steps are 1 `code-review`, 2 `code-review`, 3 `owner`, 4 `after merge`. | Dispatch no acceptance reviewer, post `acceptance done, no reviewer steps`, and give the code reviewer steps 1 and 2. | Skip the acceptance reviewer, but give the code reviewer no steps, so steps 1 and 2 never run. |
| 9 | The code reviewer is given step 2: `git diff --name-only main...HEAD` prints exactly `a.md` and `b.md`. The diff also changes `c.md`. | Step 2 FAIL, with the lines quoted, and "Ready to merge: No"; no card for it. | Report `c.md` as an unplanned change, graded and carded, with no verdict for step 2. |

Scenarios 2 to 5 name the situation's own branches; the plan may rename them, keeping one chain per scenario.
Scenario 6 is a guard: an ordinary `skill-test` step whose RED is expected to do the same as GREEN. `relay-plan check`
asks only that a step has its fenced situation, `GREEN must:` and `RED is expected to:`, and stop 4 reports a RED that
does not fail, which blocks nothing (`reviewing.md` §3, step 5), as for the guards of earlier plans.

## 4. Testing and acceptance

- **Gates:** `sh tests/relay-plan/run-tests.sh` with its new cases, `sh tests/orchestrating/run-tests.sh` (its case 8
  still holds, and any case whose phrase the text changes moves with it), `sh tests/skill-size/run-tests.sh` and
  `sh tests/skill-layout/run-tests.sh`, `dash -n bin/relay-plan`, and `claude plugin validate .` with its three known
  warnings.
- **The skill tests:** §3's nine scenarios, run on `main`'s skills and the branch's (`reviewing.md` §3).
- **Acceptance**, as `reviewer` steps (Old plans, above): the branch changes only the files in Scope; the text says
  what §1 and §2 say; `relay-plan` handles the new kind on a scratch plan in a temporary repo.

## 5. Release

The merge changes `skills/` and `bin/`, so it is released as **0.2.10**, unless the owner names another (`CLAUDE.md`,
How a change reaches the owner). The plan ends its acceptance task with the release and the owner's update as `after
merge` steps.

## 6. Out of scope, and left to the builder

**Out of scope:**

- Pairs that must land together or not at all: card `eaed0a9c`.
- The code review at the same time as acceptance (card `516ad28d`) and rerunning the steps a fix touches (card
  `c12df29f`): this spec leaves the review's order as it is.
- Two executors in one folder at once: a chain runs one plan at a time.
- Changes to `wt` or `relay-merge`.
- Moving old plans' reading checks to the new kind.

**My calls, for the owner to check while reading:**

- **A second plan stacked on the same base** keeps today's rules (§1): the first in the spec's order shares the
  folder, and each other one gets its own worktree and waits for the base's merge. A chain is a line; this spec does
  not share a folder between branches of a tree.
- **A longer chain** repeats the cut link by link, with one joint stop 4 after the last link and one `relay-merge`
  call in chain order (§1).
- **A capped `code-review` FAIL** becomes the orchestrator's "fix cap reached" card, as any capped finding does (§2).
- **The base's moment-8 `next:`** names the cut, and the base's stop 4 becomes the chain's (§1).
- **RED's skills for a stacked plan come from the base's branch** (§1), so a skill test measures only the stacked
  plan's change.
- **A `code-review` FAIL counts like a Critical**, toward the fix-round cap (§2).
- **The acceptance reviewer templates** (`templates/agents/reviewer-*.md`) run only the steps the dispatch names, so
  they need no change; if the builder finds a line in them that names a reading check, it moves with §2, and the
  repos' role agents are regenerated by `hyper-relay-agents` as usual.

**Left to the builder:** the exact wording in each file; the order of the changes; the names in the scenarios'
situations; the fixture plans for `relay-plan`'s tests.
