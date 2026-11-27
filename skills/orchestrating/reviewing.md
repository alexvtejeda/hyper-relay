# The review leg, the click-through and the merge

The last leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when `dispatching.md` §7 has
verified the executor's hand-back and run `quartz review`, and it runs on its own until stop 4, except for a gap in
the spec or plan, which goes to the owner at once. You review nothing yourself: the acceptance reviewer, the code
reviewer and the skill-test judge do, each in its own context. Each writes its full report to the plan's run folder
(`dispatching.md` §3) and hands back a short summary; you open a report only for a line the summary does not settle.

## 1. Acceptance

Dispatch the repo's `<project>-reviewer` (`.claude/agents/<project>-reviewer.md`) in the background. The prompt
gives:

- the plan's path and its acceptance task (its last task);
- **the step numbers marked `reviewer`**, which are the only ones it runs: `relay-plan steps <plan> reviewer` lists
  them;
- the checkout and the branch;
- what the executor's summary says it left running (URLs, logins);
- the run folder, whose `acceptance/` is its evidence folder and holds its full report, `report.md`;
- when the repo uses Quartz, the plan's initiative, for the cards it files; otherwise "Run no Quartz command and use
  no Quartz tool."

Then post the status note (`quartz.md` §4, moment 5). When the plan has no `reviewer` steps, skip the dispatch, say
so at stop 4, and post moment 6's status now, as `acceptance done, no reviewer steps`. The plan's `code-review` steps
are never the acceptance reviewer's: the code reviewer runs them (§3).

**Without a generated reviewer** (`SKILL.md`, Fallbacks), dispatch a general-purpose agent (in OpenCode, the
`general` subagent) with the same prompt and this standing brief:

> You are report-only. Run each named step exactly as the plan writes it. For each, give PASS, FAIL or NEEDS-HUMAN,
> with the command, the lines that decide it and the exit code, quoted. Save each step's output in the evidence
> folder, and write your full report to its `report.md`. Classify each finding as BLOCKING (this plan's work is
> wrong, or a step fails), PRE-EXISTING (caused by earlier work) or POLISH (works, but could be better). File each
> PRE-EXISTING and POLISH finding as a proposed card: `add_tasks` with the label `proposed`, kind `bug` or `change`,
> the initiative this prompt gives, and a body naming the plan, the file and the evidence path. When `add_tasks`
> fails, or this prompt says to use no Quartz tool, append the card to the run folder's `cards.md` instead, as a
> `## <title>` section with its kind, the file, the evidence and why. Write nowhere else. Never edit, commit, install
> anything or change any config. Hand back only a short summary: the verdict line, one line per step, each BLOCKING
> finding in one line with its evidence path, the cards you filed, and the path of `report.md`.

**Verify the summary:**

- every named step has a verdict;
- each PASS has its evidence file in `acceptance/`; a PASS without one counts as not run: it goes back to the
  reviewer;
- rerun one FAIL yourself, where its command is read-only, to confirm it is real (`relay-plan step <plan> <id>` gives
  the step's text).

## 2. The fix loop

Sort each FAIL and each BLOCKING finding, and each real FAIL of a `code-review` step (§3):

| Kind | Goes to |
|---|---|
| An execution bug: the code does not do what the plan says | A fix round: the executor that ran the plan, resumed with its context (`SKILL.md`, Fallbacks). When it cannot be resumed, a fresh executor, dispatched as `dispatching.md` §5 says, with the plan and the findings. |
| A gap in the spec or the plan | The owner, at once, who decides: fix it on this branch (it goes to the executor as a finding, and you record it as a deviation), or a new card |

PRE-EXISTING and POLISH findings are not in the loop: the reviewer has filed them as proposed cards (below).

The executor's fix prompt gives:

- fix round `<k>` of the cap, and the findings, each as its verdict line and its evidence path in the run folder;
- the plan, the mode, the checkout, the branch and the run folder;
- fix root causes;
- commit each fix staging named files only, with the attribution lines and **no** `Plan-Task:` trailer;
- rerun only the tests that pin the fix, each through `relay-plan gate <plan> '<command>'`, not the full gates;
- append a `## Fix round <k>` section to `executor.md`, and hand back the short summary, naming those tests by their
  commands.

Post the status note when you send it (moment 5). After the fix, verify it with `dispatching.md` §7's checks, where
check 1 is `relay-plan gates <plan>` followed by the commands the round names: the full gates' earlier runs are older
than the new tip, so naming no command would fail by design. `quartz review` does not run again: the cards are
already In review. Then the reviewer, resumed or fresh, reruns only the steps that failed, and appends a
`## Rerun after fix round <k>` section to `report.md`.

**The fix-round cap.** Read `fix-rounds:` from the header of `main`'s facts file, as `dispatching.md` §1 reads
`execute:`; without it, the cap is 2. A finding (an acceptance FAIL, a Critical, a `code-review` step's FAIL, a GREEN
that failed) that still fails after that many rounds gets no further round. File a card for it yourself (the code
reviewer files none for a FAIL): `add_tasks` with the label `proposed`, kind `bug`, the plan's initiative, and a body
naming the plan, the step or finding, its evidence paths and "fix cap reached after <n> rounds" (without Quartz, a
section in `cards.md`). Then carry on with the rest of the loop; stop 4 opens with it (§4). A gap in the spec or the
plan is not capped: it goes to the owner at once.

**Proposed cards.** The agent that finds an issue files it: the acceptance reviewer its PRE-EXISTING and POLISH
findings, the code reviewer its Important and Minor ones (§3), the executor an issue it noticed outside its plan.
Each is an `add_tasks` card with the label `proposed`, kind `bug` or `change`, the plan's initiative, and a body
naming the plan, the file and the evidence (a path in the run folder); the agent's summary lists the card ids. When a
summary says the cards went to the run folder's `cards.md` instead (its `add_tasks` failed), file them yourself in one
`add_tasks` call, then delete `cards.md`. Without Quartz, `cards.md` keeps them for stop 4.

When the fix loop ends (every FAIL fixed, capped, or made a card by the owner), post the status note (moment 6):
`acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds`, where N of the M `reviewer` steps passed and K are
NEEDS-HUMAN, after F fix rounds, with `; step <id> capped, card <card id>` for each capped step. A note that fails is
reported once, in one line (`quartz.md` §2).

When the fix loop ends and a plan is stacked on this one, cut and dispatch it now (`parallel.md` §3).

## 3. The code review, last

When every acceptance FAIL is fixed, capped, or turned into a card by the owner (NEEDS-HUMAN steps may remain), run
one code review of the whole branch, as `hyper-relay:requesting-code-review` says: a general-purpose agent on Sonnet
(`SKILL.md`, Fallbacks), given that skill's `code-reviewer.md` (`../requesting-code-review/code-reviewer.md` from
this file) with the range `$(git merge-base main <branch>)..<branch>`, the plan, the spec, the run folder and the
plan's initiative ("none" without Quartz). It writes its review to the run folder's `code-review.md`, files its
Important and Minor findings as proposed cards (§2), and hands back a short summary. It runs once per branch, after
acceptance and its fixes, so it reads the final diff.

**The plan's `code-review` steps** run within that one review: its prompt's `{PLAN_STEPS}` names each id that
`relay-plan steps <plan> code-review` lists, each with the command that prints it, `relay-plan step <plan> <id>`, or
"none" when it lists none. **Verify its summary:** every listed step has its verdict, PASS or FAIL, in
`code-review.md`; a step without one goes back to the code reviewer.

**A Critical** finding, or a `code-review` step's FAIL: check each one against the code first
(`hyper-relay:receiving-code-review`), from its lines in `code-review.md`. A wrong one is dropped, with the reason, in
the stop-4 report. A real Critical is a fix round (§2), and counts toward the cap; a real FAIL is sorted as §2 sorts
an acceptance FAIL. After the fix, resume the code reviewer to check only the fix commits and rerun the steps that
failed, appending to `code-review.md` (when it cannot be resumed, read that diff yourself, and have a fresh code
reviewer rerun only those steps), and have the acceptance reviewer rerun the `reviewer` steps the fix touches (all of
them, when that is unclear).

**The skill tests** run when the plan's acceptance task has `skill-test` steps (`relay-plan steps <plan> skill-test`
lists them; `hyper-relay:writing-plans` requires them in a plan that creates or changes a file in a skill's folder),
at the same time as the code review. They are `hyper-relay:writing-skills`' RED/GREEN pressure tests. You never read
the steps yourself: `relay-plan` hands their situations to the runs, and a judge reads the rest. `<run>` is the run
folder:

1. Put the skills from `main` and from the branch in `<run>/skill-tests/red/` and `<run>/skill-tests/green/`:
   `mkdir -p <run>/skill-tests/red <run>/skill-tests/green`, then
   `git cat-file -e main:<skills> 2>/dev/null && git archive main <skills> | tar -x -C <run>/skill-tests/red` and
   `git archive <branch> <skills> | tar -x -C <run>/skill-tests/green`. `<skills>` is the folder that holds the
   repo's skill folders (`skills` in a plugin, `.claude/skills` in a project). When `main` has no such folder, the
   `cat-file` check fails, nothing is copied and `red/` stays empty: RED then reads no skill at all, as it should
   for a new skill.
2. `relay-plan scenarios <plan> <run>/skill-tests` writes each step's situation to `step-<id>.txt` there, and prints
   one line per step: its id, the file and its title. When it exits 1 (a step's situation is not in a fence, as in a
   plan written before that rule), tell the owner and stop the skill tests: you do not read the steps yourself.
3. Dispatch two runs per step, in the background, each to a general-purpose agent on Sonnet (`SKILL.md`,
   Fallbacks): GREEN given `<run>/skill-tests/green`, RED given `<run>/skill-tests/red`. Each prompt is this
   preamble, filled in, and nothing else:

   > You are taking part in a test of written skills. Your situation is in `<run>/skill-tests/step-<id>.txt`, and the
   > skills are in `<the folder>`. Read the situation, then the skills it needs, from those two places only, and
   > nothing else on this machine. Run no command. Act as the agent the situation names. Write your answer to
   > `<run>/skill-tests/step-<id>-<green or red>.md`: the commands you would run, in order, and the next message you
   > would send, verbatim. Change no other file, and reply `done`.

4. When every run has replied, dispatch one judge, a general-purpose agent on Sonnet, with this prompt, filled in:

   > You judge a test of written skills. The acceptance task of the plan `<plan>` has the `skill-test` steps `<ids>`;
   > `relay-plan step <plan> <id>` prints one, with what GREEN must do and what RED is expected to do. In
   > `<run>/skill-tests/`, `step-<id>-green.md` answers that step's situation from the branch's skills, and
   > `step-<id>-red.md` from `main`'s. For each step, judge whether the GREEN answer does what GREEN must, and whether
   > the RED answer fails as RED is expected to: a RED that already does what GREEN must does not fail. Write
   > `verdicts.md` in that folder: for each step, its verdict and the lines of each answer that decide it, quoted.
   > Change no other file. Reply with one line per step, and nothing else:
   > `<id>: GREEN pass|fail, RED fails|does not fail: <reason, at most 15 words>`.

5. A GREEN that fails is a fix round (§2), with the step's id and the path of `verdicts.md` as its finding. After the
   fix, put a fresh copy of the branch's skills in `green/`, rerun that step's GREEN, and have the judge, resumed or
   fresh, judge that step again. A RED that does not fail means the scenario does not test the change: stop 4 says
   so, and it blocks nothing.

Post the status note when you dispatch the code review and the skill-test runs (moment 7), and when the code review,
its Critical and `code-review` fixes and the skill tests are done (moment 8):

`code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN`

The plan steps' part counts the Q `code-review` steps and the P that passed; a plan without them leaves out
"; plan steps P/Q PASS". The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without
skill tests leaves out "; skill tests G/S GREEN".

## 4. Stop 4, the click-through and the merge

**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer, each skill-test run and
the judge. An agent's reply arrives before the notification that carries its usage. Where the harness reports no
usage, stop 4 says so.

Post the status note first (moment 9). Then one message, which ends there. It opens with its questions, numbered, in
this order (`SKILL.md`, The stops):

- for each finding that reached the fix-round cap (§2): "Step <id> still fails after <n> fix rounds (card
  `<card id>`): merge with it open, hold the branch, or one more round?";
- the NEEDS-HUMAN steps and the plan's `owner` steps, which the owner runs at the click-through:
  `relay-plan steps <plan> owner` lists them, and `relay-plan step <plan> <id>` gives the text of one you show or
  run;
- where to click through (below).

Then the report, short, one line per item:

- the acceptance verdicts, and beside them the `code-review` steps' verdicts from `code-review.md`;
- the skill-test verdicts, the judge's line for each scenario, naming each RED that did not fail;
- each fix round, and what it changed;
- the Critical findings and `code-review` FAILs fixed, and those dropped with why;
- the proposed cards filed during the run, as their number (the owner prunes them on the board); without Quartz,
  each card in `cards.md` instead, one line each (title, file, why), for the owner to keep or drop;
- each deviation recorded on the way, such as an overlap the owner chose to run at once (`parallel.md` §2);
- the token counts of the acceptance reviewer, the code reviewer and the skill-test runs against the executor's, as
  your harness reports them ("not reported" where it reports none), until the owner says they have seen enough;
- last, the line that says this is a good moment to clear (`SKILL.md`, The stops).

Stop 4 promises a Quartz tick only where `quartz.md` §3 says one will come.

When the owner answers, add a decision note for each thing they decide, and post the status note again (moment 9).
"One more round" for a capped finding is a fix round (§2), then a short stop 4 again. Without Quartz, the cards the
owner keeps stay listed in stop 4.

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge. While a branch run is
active, a worktree plan's stop 4 says it "merges after `<branch>`": the merge runs only from the main checkout on
`main`.

**The merge** lands the branch with `relay-merge`: a `--no-ff` merge into `main`, the gates the repo's
`.hyper-relay/merge.conf` names run on the merged result, then the branch and its worktree removed (hyper-relay's
`docs/relay-merge.md`). Claude Code puts it on `PATH`; elsewhere the owner links it. When `command -v relay-merge`
finds nothing, tell the owner and stop. On the owner's go-ahead, in the main checkout:

1. After a branch run, `git switch main`. When the worktree has a `wt` stack up, `(cd <worktree> && wt down)`.
2. `PUSH=0 RELAY_MERGE_TRAILERS='<your attribution lines, one per line>' relay-merge <branch>`, with several branches
   in the order `parallel.md` §4 gives. `PUSH=0`: pushing stays the owner's call.
3. Read its exit code. Branches before the one that failed have landed, and stay landed: §5 runs for each of them.

| Exit | `relay-merge` | You |
|---|---|---|
| 0 | every branch landed | §5, for each plan that landed |
| 1 | refused by a check; that branch did not change `main` | Fix the cause when it is your own (a `wt` stack still up, the main checkout not on `main`), and run it again; otherwise bring the owner the check's message |
| 2 | a merge conflict; aborted, `main` unchanged for that branch | A conflict round (below), then a short stop 4 again |
| 3 | a gate failed; the merge is on `main`, unpushed | Stop at once (below) |

**A conflict round** is a fix round (§2) for the branch's executor, with this finding: "`relay-merge` could not merge
`<branch>` into `main`: a conflict in `<files>`. Merge `main` into your branch, resolve the conflict, rerun your full
gates, and report." (`hyper-relay:executing-plans` says how.) After a branch run, switch the main checkout back first
(`git switch <branch>`): an executor works only where its branch is checked out. Verify the round as §2 does, with
check 1 naming the full gates the round reran; it counts toward no fix-round cap. Then a short stop 4 again, since
the code changed after review: the conflict, how it was resolved, the gates. On the owner's go-ahead, the merge again.

**A failed gate** (exit 3): stop, and bring the owner the log's tail that `relay-merge` printed, at once, in a message
of its own. Nothing else lands until the owner decides:

- **Undo the unpushed merge:** check that `git log -1 --format=%s main` prints `Merge branch '<branch>'` and
  `git branch -r --contains main` prints nothing, then run `git reset --keep HEAD^1` in the main checkout on `main`.
  The branch and its worktree are still there: the failure goes to its executor as a fix round (§2; after a branch
  run, `git switch <branch>` first), then a short stop 4 again.
- **Fix forward:** on a new branch, as the owner says.

Plans in flight keep executing in their worktrees meanwhile.

## 5. After the merge

After a branch merge, the main checkout is back on `main`. Make the edits that waited, and commit the specs and plans
you held back, each staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks
upload them. Where Quartz's hook ticks tasks (`quartz.md` §3), the ticks queued during the run drain at the next
stop.

Post the status note (moment 10), naming the `after merge` steps left. Then, in either mode, run them with the
owner: `relay-plan steps <plan> after-merge` lists them, and `relay-plan step <plan> <id>` gives each one's text as
you reach it. When they are done, tick the acceptance task by hand if no commit ticked it; where nothing ticks a
committed task (`quartz.md` §3), tick every task with a `Plan-Task:` commit in the same edit. Post the status note
once more, as `done`. A plan stacked on this one, or waiting for it, goes on now (`parallel.md` §4).
