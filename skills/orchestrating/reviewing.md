# The review leg, the click-through and the merge

The last leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when `dispatching.md` §7 has
verified the executor's hand-back and run `quartz review`, and it runs on its own until stop 4, except for a gap in
the spec or plan and a second failed fix round, which go to the owner. You review nothing yourself: the acceptance
reviewer and the code reviewer do, each in its own context.

## 1. Acceptance

Dispatch the repo's `<project>-reviewer` (`.claude/agents/<project>-reviewer.md`) in the background. The prompt
gives:

- the plan's path and its acceptance task (its last task);
- **the step numbers marked `reviewer`**, which are the only ones it runs;
- the checkout and the branch;
- what the executor's report says it left running (URLs, logins);
- an evidence folder outside the checkout: your harness's scratchpad when it has one, otherwise a new `mktemp -d`.

When the plan has no `reviewer` steps, skip the dispatch, say so at stop 4, and post §2's status note now, as
`` `<plan path>`: acceptance done, no reviewer steps. ``

**Without a generated reviewer** (`SKILL.md`, Fallbacks), dispatch a general-purpose agent (in OpenCode, the
`general` subagent) with the same prompt and this standing brief:

> You are report-only. Run each named step exactly as the plan writes it. For each, give PASS, FAIL or NEEDS-HUMAN,
> with the command, the lines that decide it and the exit code, quoted. Save each step's output in the evidence
> folder. Never edit, commit, install anything or change any config.

**Verify the report:**

- every named step has a verdict;
- a PASS without quoted evidence counts as not run: it goes back to the reviewer;
- rerun one FAIL yourself, where its command is read-only, to confirm it is real.

## 2. The fix loop

Sort each FAIL and each BLOCKING finding:

| Kind | Goes to |
|---|---|
| An execution bug: the code does not do what the plan says | The executor that ran the plan, resumed with its context (`SKILL.md`, Fallbacks). When it cannot be resumed, a fresh executor, dispatched as `dispatching.md` §5 says, with the plan and the findings. |
| A gap in the spec or the plan | The owner, who decides: fix it on this branch (it goes to the executor as a finding, and you record it as a deviation), or a new card |
| PRE-EXISTING, or POLISH | A proposed card (§4) |

The executor's fix prompt gives:

- the findings with their evidence, verbatim;
- the plan, the mode, the checkout and the branch;
- fix root causes;
- commit each fix staging named files only, with the attribution lines and **no** `Plan-Task:` trailer;
- rerun the gates, and report.

After a fix, verify it with `dispatching.md` §7's checks 1–4 (the gates, the new commits, a clean tree, the
deviations). `quartz review` does not run again: the cards are already In review. Then the reviewer, resumed or
fresh, reruns only the steps that failed. A step that fails again after its second fix round goes to the owner.

**The status note.** When the fix loop ends (every FAIL fixed, or made a card by the owner), and the repo uses Quartz
with its MCP loaded (`quartz.md` §1 and §2), post a status note on each of the plan's cards (its card line, or its
spec's): `add_note` with `status: true`, at most 500 characters:

`` `<plan path>`: acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds. ``

N of the M `reviewer` steps passed and K are NEEDS-HUMAN, after F fix rounds. A status replaces the card's previous
one, which is enough: the code review runs only after acceptance. A resumed orchestrator reads it (`SKILL.md`,
Finding where work stands). A note that fails is reported once, in one line (`quartz.md` §2).

When the fix loop ends and a plan is stacked on this one, cut and dispatch it now (`parallel.md` §3).

## 3. The code review, last

When every acceptance FAIL is fixed, or turned into a card by the owner (NEEDS-HUMAN steps may remain), run one code
review of the whole branch, as `hyper-relay:requesting-code-review` says: a general-purpose agent on Sonnet
(`SKILL.md`, Fallbacks), given that skill's `code-reviewer.md` (`../requesting-code-review/code-reviewer.md` from
this file) with the range `$(git merge-base main <branch>)..<branch>`, the plan and the spec. It runs once per
branch, after acceptance and its fixes, so it reads the final diff.

- **Critical:** check each one against the code first (`hyper-relay:receiving-code-review`). A wrong one is dropped,
  with the reason, in the stop-4 report. A real one goes to the executor as in §2. Then resume the code reviewer to
  check only the fix commits (when it cannot be resumed, read that diff yourself), and have the acceptance reviewer
  rerun the steps the fix touches (all its steps, when that is unclear).
- **Important and Minor:** proposed cards (§4).

**The skill tests** run when the plan's acceptance task has `skill-test` steps (`hyper-relay:writing-plans` requires
them in a plan that creates or changes a file in a skill's folder), at the same time as the code review. They are
`hyper-relay:writing-skills`' RED/GREEN pressure tests:

1. Put the skills from `main` and from the branch in two scratch folders, inside an evidence folder as §1's:
   `mkdir -p <folder>/red <folder>/green`, then
   `git archive main <skills> | tar -x -C <folder>/red` and
   `git archive <branch> <skills> | tar -x -C <folder>/green`. `<skills>` is the folder that holds the repo's skill
   folders (`skills` in a plugin, `.claude/skills` in a project). When `main` has no such folder, `red/` stays empty:
   RED then reads no skill at all, as it should for a new skill.
2. Dispatch each step's scenario twice, in the background, each time to a general-purpose agent on Sonnet
   (`SKILL.md`, Fallbacks): GREEN given the `green/` folder, RED given the `red/` folder. Each prompt is this standing
   preamble, then the step's situation, verbatim:

   > You are taking part in a test of written skills. The skills are in `<the folder>`: read the ones the situation
   > needs, from that folder only, and nothing else on this machine. Run no command and change no file. Act as the
   > agent the situation names. Answer with the commands you would run, in order, and the next message you would
   > send, verbatim.

3. Judge each answer against its step. A GREEN that does not do what the step says GREEN must do is a fix round (§2),
   with the step, the scenario and the answer as its finding; after the fix, rerun that GREEN on a fresh copy of the
   branch's skills. A RED that does not fail (it already does what GREEN must) means the scenario does not test the
   change: stop 4 says so, and it blocks nothing.

When the code review, its Critical fixes and the skill tests are done, post the status note as §2 does:

`` `<plan path>`: code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN. At stop 4. ``

The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without skill tests leaves out
"; skill tests G/S GREEN".

## 4. Stop 4, the click-through and the merge

**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer, each skill-test run. An
agent's reply arrives before the notification that carries its usage. Where the harness reports no usage, stop 4 says
so.

One message, which ends there. It opens with its questions, numbered, in this order (`SKILL.md`, The stops):

- the proposed cards, one line each (title, file, why), for the owner to keep or drop;
- the NEEDS-HUMAN steps and the plan's `owner` steps, which the owner runs at the click-through;
- where to click through (below).

Then the report, short, one line per item:

- the acceptance verdicts;
- the skill-test verdicts, GREEN and RED for each scenario, naming each RED that did not fail;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- each deviation recorded on the way, such as an overlap the owner chose to run at once (`parallel.md` §2);
- the token counts of the acceptance reviewer, the code reviewer and the skill-test runs against the executor's, as
  your harness reports them ("not reported" where it reports none), until the owner says they have seen enough.

Stop 4 promises a Quartz tick only where `quartz.md` §3 says one will come.

The cards the owner keeps go to Needs brainstorming through the Quartz MCP, kind `bug` or `change`, in the plan's
initiative, each body naming the plan, the file and the evidence. When the repo does not use Quartz (`quartz.md` §1),
they stay listed in stop 4.

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
(`git switch <branch>`): an executor works only where its branch is checked out. Verify the round as §2 does. Then a
short stop 4 again, since the code changed after review: the conflict, how it was resolved, the gates. On the owner's
go-ahead, the merge again.

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

Then, in either mode, run the plan's `after merge` acceptance steps with the owner. When they are done, tick the
acceptance task by hand if no commit ticked it; where nothing ticks a committed task (`quartz.md` §3), tick every task
with a `Plan-Task:` commit in the same edit. A plan stacked on this one, or waiting for it, goes on now
(`parallel.md` §4).
