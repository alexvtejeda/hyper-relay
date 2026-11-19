---
name: executing-plans
description: Use when an approved implementation plan is to be executed. The executor dispatched to run one plan follows this file; an orchestrator handing a plan off uses orchestrating instead, and never executes the plan itself.
---

# Executing Plans

**Handing a plan off, as the orchestrator?** Invoke `hyper-relay:orchestrating` and follow it instead of this file.
You never execute a plan yourself.

This file is for the **executor**: the agent dispatched, in a fresh context, to run ONE approved plan. You run every
task that is yours, in order, yourself; then you report and stop. There is no partner to ask: the orchestrator reads
your report. Your agent file (`<project>-executor`, when the repo has one) adds what is particular to the repo: its
setup, its full gates, its constraints and its acceptance steps.

**Announce at start:** "I'm using the executing-plans skill to execute this plan."

## The dispatch prompt gives

- the plan's path (absolute when the plan is not committed on `main`), and which of its tasks are yours;
- the **mode**: `branch` (a new branch in the repo's main checkout) or `worktree` (the branch's own worktree);
- the checkout's path and the branch;
- the Claude-Session URL for your commit trailers;
- anything unusual, for example `main` having moved since the plan was written.

## The process

1. **Check where you are.** In the checkout the prompt names, `git rev-parse --show-toplevel` must print that
   checkout and `git branch --show-current` the branch. If not, stop and report: never switch branches. Work only
   there: start every shell command with `cd <checkout> && ` (your shell may not keep its directory between
   calls); the plan's paths are relative to the checkout's top. Read `CLAUDE.md` at the top. The plan's Execution
   notes are binding.
2. **No review gate.** The plan is approved: do not re-plan it or ask about it. A choice the plan leaves open (how to
   write a body, which helper or library call) is yours: make the reasonable one, and list it in your report. Stop
   and report only when a step contradicts the spec or another step, needs a fact the plan should have given (a
   value, a behaviour, a name another task uses), or cannot be done.
3. **Each task, in order:**
   - Follow its steps in order. Write exactly the text a step gives (file contents, skill text, messages). Write code
     to the step's signature, by the algorithm its code block gives when it gives one, and make its tests pass.
   - Run only that task's checks.
   - Commit at its end, staging named files only (never `git add -A` / `git add .`). The task's final commit carries
     `Plan-Task: <plan path>#<N>` and the attribution lines your instructions give (in Claude Code, a
     `Co-Authored-By:` line and `Claude-Session:` with the URL from the dispatch prompt), all in ONE final
     paragraph, so git reads them all as trailers:

     ```bash
     git commit -m "<subject>" -m "Plan-Task: <plan path>#<N>
     Co-Authored-By: <the line your instructions give>
     Claude-Session: <the URL the dispatch prompt gives>"
     ```

   - Report every `quartz:` line a commit prints, verbatim. Never tick the plan: its hooks or the orchestrator do.
4. **When the code is not what the plan expects** (an expected line differs, a file moved): adapt as little as
   possible, and record it as a deviation with the reason. A step that fails twice the same way: stop and report.
5. **Full gates, once,** after your last task: the ones the plan's Execution notes name, and your agent's own
   ("Full gates").
6. **Acceptance:** follow your agent's acceptance steps for your mode, under "In a worktree" or "On a branch", when
   it has them. Then copy the plan's acceptance checklist (its last task) into your report.
7. **Report, then stop.** The orchestrator verifies every line of it:
   - tasks done (n/N), each with its commit hash;
   - each gate, with its pass/fail counts;
   - every deviation from the plan, and why;
   - the calls you made where the plan left a choice open, one line each;
   - every `quartz:` line, verbatim;
   - the acceptance output: URLs, logins, anything left running;
   - anything left for the owner: a task that is theirs, a step you stopped at.

## Never, in either mode

- Switch branches, stash, reset, rebase, push or tag. Merge your branch into anything: the orchestrator lands it. Your
  one merge is a catch-up or conflict round's, of `main` into your own branch (below). Tick the plan. Invoke
  `hyper-relay:finishing-a-development-branch`: the owner decides the merge.
- Start a live `claude -p` or `opencode run` session, install or uninstall a plugin, or add a marketplace.
- Call a real third-party API or use real credentials: tests use fakes.
- Touch anything outside your checkout: `~/.claude/`, `~/.config/opencode/`, other repos, other worktrees. A task
  marked as the owner's or the orchestrator's is not yours, even when it gives commands.
- Wait with a self-matching `pgrep`, or `pkill -f` a pattern that appears in your own command line. Stop a server
  you started by its PID.

Read files in targeted ranges, and pipe long output through `tail` or `grep`: the owner rations usage.

## Catch-up and conflict rounds

After your tasks, the orchestrator may resume you, or dispatch a fresh executor with the plan, for one of two rounds:

- **Catch-up:** your plan was stacked on another plan's branch; that branch has merged, and `main` has changes your
  branch lacks.
- **Conflict:** `relay-merge` could not merge your branch into `main` because of a conflict, and left `main` unchanged.

Either way, in your checkout and on your branch (process step 1):

1. Merge `<base>` into your branch: `main`, unless the prompt names another branch. The merge commit carries the
   attribution lines your instructions give, in one final paragraph, and no `Plan-Task:` trailer:

   ```bash
   git merge -m "Merge branch '<base>' into <branch>" -m "Co-Authored-By: <the line your instructions give>
   Claude-Session: <the URL the dispatch prompt gives>" <base>
   ```

   "Already up to date." means there is nothing to merge: say so in your report.
2. On a conflict, resolve each conflicted file so that both sides' changes hold, and stage each by name
   (`git add <file>`). Then commit the merge with the same two messages:
   `git commit -m "Merge branch '<base>' into <branch>" -m "<the same attribution lines>"`. When the two sides cannot
   both hold, run `git merge --abort`, then stop and report the files and why.
3. Rerun the full gates (process step 5).
4. Report: the merge commit's hash, each conflict and how you resolved it, and the gates with their counts.

Never merge your branch into `main` or any other branch: the orchestrator lands it with `relay-merge`.

## Branch mode adds

You share the repo's main checkout with the orchestrator, who keeps working while you run.

- Untracked files under `docs/superpowers/` that you did not create are the orchestrator's held-back specs and plans:
  never stage, edit, move or delete them. A "the tree is clean" check ignores them.
- If a git command fails on `index.lock` ("Unable to create '…/index.lock': File exists"), wait a second and retry
  once.
- A commit may print that a task "ticks at the next drain", because the main checkout is on your branch. That is
  expected: report it like any `quartz:` line.

## Integration

- `hyper-relay:orchestrating` hands you the plan (its `dispatching.md`) and owns the review and the merge.
- `hyper-relay:writing-plans` is the planner's: a planner wrote the plan you run.
- `hyper-relay:test-driven-development`: when a task writes a test first, watch it fail before you make it pass.
- The orchestrator lands your branch with `relay-merge`, after the click-through.
  `hyper-relay:finishing-a-development-branch` is for work outside the relay.
