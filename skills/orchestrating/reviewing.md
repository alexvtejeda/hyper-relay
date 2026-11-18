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

When the plan has no `reviewer` steps, skip the dispatch and say so at stop 4.

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

After a fix, verify it as `dispatching.md` §7 does: the gates, the new commits, a clean tree. Then the reviewer,
resumed or fresh, reruns only the steps that failed. A step that fails again after its second fix round goes to the
owner.

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

## 4. Stop 4, the click-through and the merge

One report, which ends the message:

- the acceptance verdicts, with each NEEDS-HUMAN step listed as the owner's;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- the proposed cards, one line each (title, file, why), for the owner to keep or drop;
- the token counts of the acceptance reviewer and the code reviewer against the executor's, as your harness reports
  them, until the owner says they have seen enough;
- the plan's `owner` steps, which the owner runs at the click-through;
- where to click through (below).

The cards the owner keeps go to Needs brainstorming through the Quartz MCP, kind `bug` or `change`, in the plan's
initiative, each body naming the plan, the file and the evidence. Without Quartz, they stay listed in the report.

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).

## 5. After the merge

After a branch merge, the main checkout is back on `main`. Make the edits that waited, and commit the specs and plans
you held back, each staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks
upload them. Task ticks queued during the run drain at the next stop.

Then, in either mode, run the plan's `after merge` acceptance steps with the owner. When the spec has another plan,
its handoff follows (`planning.md` §4).
