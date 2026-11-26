# Handing a plan to an executor

The handoff leg of `orchestrating` (`SKILL.md` beside this file is the map), reached from stop 3 (`planning.md` §3).
You are the session the owner talks to. You hand ONE approved plan to ONE executor, keep working while it runs, and
verify what it hands back; `reviewing.md` sees the plan through review and merge. You never execute a plan yourself:
a fresh executor, in its own context, works better than a window full of decisions and explanations. The executor's
process is the `hyper-relay:executing-plans` skill.

**A branch run is active exactly when the repo's main checkout is not on `main`:**
`GIT_OPTIONAL_LOCKS=0 git -C <main checkout> branch --show-current` prints another branch. Nothing else needs
remembering, so this holds after a `/clear` or in a new session.

## 1. Handoff: always a stop

This is the phase gate between plan and execution: stop for the owner's answer. First read the `execute:` line from
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one. N below, the plan's task count, is in the first line `relay-plan steps <plan>` prints:
`tasks <N>; acceptance task <M>`.

**Branch is offered only for a plan that will run alone:** no other plan is in flight and none is approved to run
beside it (`parallel.md` says what in flight means). Otherwise every plan runs in a worktree, and the question is
`parallel.md` §1's: a line per plan, then a line per overlap its conflict check found. The forms below are for a plan
that runs alone.

- **`execute: branch`:** "Plan ready at `<path>` (N tasks). Running it on a **branch** (this repo's default). OK, or
  worktree?"
- **`execute: worktree`:** "Plan ready at `<path>` (N tasks). Running it in a **worktree** (this repo's default). OK,
  or branch?"
- **No key, or no facts file:**

  > Plan ready at `<path>` (N tasks). Where should the executor run?
  > 1. **Branch**: this checkout, a new branch; you click through on your normal stack; new specs and plans stay
  >    uncommitted until it merges.
  > 2. **Worktree**: its own worktree; nothing held back, can run beside a branch run; worktree setup, and a `wt`
  >    stack for an app.

Add each warning that applies:
- Branch: task ticks arrive at the merge, not live.
- Branch, in a repo with a `.wt.conf`: it runs on the owner's normal stack and database.
The owner's answer is the go-ahead to dispatch the plan, or each plan the question names when `parallel.md` says it
starts; do not ask again.

## 2. Preconditions

- **Branch:** the main checkout is on `main`; `git rev-parse -q --verify MERGE_HEAD` prints nothing; and
  `git status --porcelain --untracked-files=no` prints nothing (untracked files are fine).
- **Worktree:** the new worktree is cut from `main`, or from its base's branch for a stacked plan (`parallel.md` §3).
  The main checkout may be on a branch run.
- **The plan is committed on `main`:** `git log -1 --format=%h main -- <plan path>` prints a commit. A plan that is
  not (it is gitignored, or it was written during a branch run and held back) goes to the executor by its absolute
  path, and §4 never runs `quartz link-branch` for it: Quartz would link the main checkout's current branch,
  which during a branch run is the other plan's. Move its cards by hand.

If a precondition fails, tell the owner which one, and stop.

## 3. Setup

The branch is the plan's file name without its date and `.md`:
`2026-11-17-hyper-relay-c-executing-plans.md` → `hyper-relay-c-executing-plans`.

- **Branch:** in the main checkout, `git switch -c <branch>`.
- **Worktree:** in the main checkout, `mkdir -p .worktrees`; then `git check-ignore -q .worktrees` must succeed.
  If it fails, `.worktrees/` is not ignored yet: add a `.worktrees/` line to `.gitignore` and commit just that file
  (`git add .gitignore`, then `git commit -m "chore: ignore .worktrees/" -- .gitignore`); during a branch run, add
  the line to the file `git rev-parse --git-path info/exclude` prints instead, which is not tracked. Then cut the
  worktree from `<base>`, which is `main`, or the base's branch for a stacked plan (`parallel.md` §3):
  `git worktree add .worktrees/<branch> -b <branch> <base>`; in a repo with a `.wt.conf`,
  `wt new <branch> --from <base>`, which makes the same worktree and runs the repo's worktree setup.

  Never enter the worktree: no `EnterWorktree` (so not `hyper-relay:using-git-worktrees`, which uses it), and no `cd`
  that outlives one command. Run commands there as `(cd <worktree> && …)` or `git -C <worktree> …`.

Then, in either mode, create the plan's run folder: `relay-plan run-dir <plan>`, in the main checkout. It prints the
folder's absolute path, `<main checkout>/.hyper-relay/runs/<branch>/`, which git ignores (it adds the line to the
repo's local exclude file when needed); it never clears what an earlier leg left there. Every dispatch prompt from
here on names it: each agent writes its full report there (`SKILL.md`, Plans and reports by path), and its
`acceptance/` is the acceptance reviewer's evidence folder.

## 4. Link (when the plan or its spec names a Quartz card)

- **A plan committed on `main`:** `quartz link-branch <plan path>`, run where the branch is checked out, with the
  plan's path inside that checkout: in the main checkout for a branch run,
  `(cd <worktree> && quartz link-branch <plan path>)` for a worktree run. Its cards move to In progress.
- **A plan that is not committed, or a link that fails:** move the cards to In progress through the Quartz MCP, and
  say so.

When the repo does not use Quartz (`quartz.md` §1), skip this step.

## 5. Dispatch

Dispatch ONE executor, in the background:
- the repo's `<project>-executor`, when it has generated agents (`.claude/agents/<project>-executor.md`);
- otherwise a general-purpose agent whose first instruction is "Invoke the `hyper-relay:executing-plans` skill and
  follow it." (In OpenCode: the `general` subagent, told to load the `executing-plans` skill first.)

The prompt gives what `hyper-relay:executing-plans` lists under "The dispatch prompt gives":
- the plan's path (absolute when it is not committed on `main`), and which tasks are the executor's: every task
  before the acceptance task that the first line of `relay-plan steps <plan>` names, e.g. "Tasks 1–8; Task 9 is the
  orchestrator's" for `tasks 9; acceptance task 9`;
- the mode, `branch` or `worktree`;
- the checkout's absolute path (the main checkout, or the worktree) and the branch;
- the run folder (§3);
- when the repo uses Quartz, the plan's card ids and its initiative; otherwise "Run no Quartz command and use no
  Quartz tool.";
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- for a stacked plan: that its branch was cut from its base's branch, `<base branch>`, which has not merged yet;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.

Then post the status note, with the executor's id (`quartz.md` §4, moment 3), tell the owner it is running, and carry
on with other work. Where the harness cannot run a subagent in the background, the dispatch waits for it; every rule
below still holds.

## 6. While a branch run is active: the hold-back rules

Until the branch merges, you share the main checkout's working tree with the executor. Keep working (brainstorm,
write specs and plans) by these rules:

- **Create new files only.** Do not edit a tracked file: the edit would land in the executor's working tree, and it
  can block the later `git switch main`. An edit waits for the merge.
- **Write specs and plans; do not commit them.** `quartz link-doc <path>` puts one on its cards meanwhile.
  `hyper-relay:brainstorming` and `hyper-relay:writing-plans` keep to this themselves.
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit` or `merge`. Run read-only git as
  `GIT_OPTIONAL_LOCKS=0 git …`, so a `git status` never holds `index.lock` while the executor commits.
- **A second plan runs only in a worktree** (§1).
- **Code you read meanwhile may be the branch's half-finished work.** Read `main`'s with `git show main:<path>`.

## 7. Verify the hand-back

A notice that the executor is **waiting on its own background work** and has not reported yet is not its hand-back:
it is waiting for commands it started, such as its gates, and wakes itself when they end. Carry on, or wait: run no
hand-back check, send the executor no message and post no status note.

The executor hands back a short summary; its full report is the run folder's `executor.md`, which you open only for
what the summary does not settle. Before relaying anything, where the branch is checked out (for a stacked plan, only
once its base has merged and any catch-up round is done: `parallel.md` §3):

1. **The gates, from `gates.log`:** `relay-plan gates <plan>`, then each gate's command as the summary names it,
   each quoted as one argument. Every line must be `ok`, which means that gate's latest run passed at the branch's
   tip, and its last output must match the counts the summary gives. You rerun no gate yourself: `relay-merge`
   runs them again on the merged result. A `FAIL` line, or counts that do not match, is a failure for the owner.
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`. Each of the executor's
   tasks ends in a commit carrying its `Plan-Task:` trailer.
3. Check the tree is clean: `GIT_OPTIONAL_LOCKS=0 git status --short` prints nothing but, on a branch run, your
   held-back docs (`??` under `docs/superpowers/`).
4. Weigh every deviation the summary lists, and every call the executor made where the plan left a choice open:
   accept each, or tell the owner why not.
5. Act on every `quartz:` line the summary quotes, and file any cards it says are in `cards.md` (`reviewing.md` §2).

Then run `quartz review` there (the cards move to In review); if it fails, move the cards by hand through the Quartz
MCP. Post the status note (`quartz.md` §4, moment 4). Tell the owner only failures, gate results, deviations and the
decisions you need: the board shows the rest.

Then continue with `reviewing.md`.
