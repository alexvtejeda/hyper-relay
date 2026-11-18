# Handing a plan to an executor

The orchestrator's half of `executing-plans`. You are the session the owner talks to. You hand ONE approved plan to
ONE executor, keep working while it runs, verify what it hands back, and see the plan through review and merge. You
never execute a plan yourself: a fresh executor, in its own context, works better than a window full of decisions
and explanations. (`SKILL.md`, beside this file, is the executor's process.)

**A branch run is active exactly when the repo's main checkout is not on `main`:**
`GIT_OPTIONAL_LOCKS=0 git -C <main checkout> branch --show-current` prints another branch. Nothing else needs
remembering, so this holds after a `/clear` or in a new session.

## 1. Handoff: always a stop

This is the phase gate between plan and execution: stop for the owner's answer. First read the `execute:` line from
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one.

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
- **While a branch run is active, Branch is not offered.** Say that one is active, and offer Worktree.

The owner's answer is the go-ahead to dispatch this plan; do not ask again.

## 2. Preconditions

- **Branch:** the main checkout is on `main`; `git rev-parse -q --verify MERGE_HEAD` prints nothing; and
  `git status --porcelain --untracked-files=no` prints nothing (untracked files are fine).
- **Worktree:** the new worktree is cut from `main`. The main checkout may be on a branch run.
- **The plan is committed on `main`:** `git log -1 --format=%h main -- <plan path>` prints a commit. A plan that is
  not (it is gitignored, or it was written during a branch run and held back) goes to the executor by its absolute
  path, and step 4 never runs `quartz link-branch` for it: Quartz would link the main checkout's current branch,
  which during a branch run is the other plan's. Move its cards by hand.

If a precondition fails, tell the owner which one, and stop.

## 3. Setup

The branch is the plan's file name without its date and `.md`:
`2026-11-17-hyper-relay-c-executing-plans.md` → `hyper-relay-c-executing-plans`.

- **Branch:** in the main checkout, `git switch -c <branch>`.
- **Worktree:** in the main checkout, `mkdir -p .worktrees`; then `git check-ignore -q .worktrees` must succeed.
  If it fails, `.worktrees/` is not ignored yet: add a `.worktrees/` line to `.gitignore` and commit just that file
  (`git add .gitignore`, then `git commit -m "chore: ignore .worktrees/" -- .gitignore`); during a branch run, add
  the line to `.git/info/exclude` instead, which is not tracked. Then
  `git worktree add .worktrees/<branch> -b <branch> main`.

  Never enter the worktree: no `EnterWorktree` (so not `hyper-relay:using-git-worktrees`, which uses it), and no `cd`
  that outlives one command. Run commands there as `(cd <worktree> && …)` or `git -C <worktree> …`.

## 4. Link (when the plan or its spec names a Quartz card)

- **A plan committed on `main`:** `quartz link-branch <plan path>`, run where the branch is checked out, with the
  plan's path inside that checkout: in the main checkout for a branch run,
  `(cd <worktree> && quartz link-branch <plan path>)` for a worktree run. Its cards move to In progress.
- **A plan that is not committed, or a link that fails:** move the cards to In progress through the Quartz MCP, and
  say so.

Without Quartz, skip this step.

## 5. Dispatch

Dispatch ONE executor, in the background:
- the repo's `<project>-executor`, when it has generated agents (`.claude/agents/<project>-executor.md`);
- otherwise a general-purpose agent whose first instruction is "Invoke the `hyper-relay:executing-plans` skill and
  follow it." (In OpenCode: the `general` subagent, told to load the `executing-plans` skill first.)

The prompt gives what the executor's `SKILL.md` lists under "The dispatch prompt gives":
- the plan's path (absolute when it is not committed on `main`), and which tasks are the executor's, e.g. "Tasks 1–8;
  Task 9 is the orchestrator's";
- the mode, `branch` or `worktree`;
- the checkout's absolute path (the main checkout, or the worktree) and the branch;
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.

Then tell the owner it is running, and carry on with other work. Where the harness cannot run a subagent in the
background, the dispatch waits for it; every rule below still holds.

## 6. While a branch run is active: the hold-back rules

Until the branch merges, you share the main checkout's working tree with the executor. Keep working (brainstorm,
write specs and plans) by these rules:

- **Create new files only.** Do not edit a tracked file: the edit would land in the executor's working tree, and it
  can block the later `git switch main`. An edit waits for the merge.
- **Write specs and plans; do not commit them.** `quartz link-doc <path>` puts one on its cards meanwhile.
  `hyper-relay:brainstorming` and `hyper-relay:writing-plans` keep to this themselves.
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit` or `merge`. Run read-only git as
  `GIT_OPTIONAL_LOCKS=0 git …`, so a `git status` never holds `index.lock` while the executor commits.
- **A second plan runs only in a worktree** (step 1).
- **Code you read meanwhile may be the branch's half-finished work.** Read `main`'s with `git show main:<path>`.

## 7. Verify the hand-back

Before relaying anything, where the branch is checked out:

1. Rerun the gates the report names. Their counts must match the report's.
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`. Each of the executor's
   tasks ends in a commit carrying its `Plan-Task:` trailer.
3. Check the tree is clean: `GIT_OPTIONAL_LOCKS=0 git status --short` prints nothing but, on a branch run, your
   held-back docs (`??` under `docs/superpowers/`).
4. Weigh every deviation the report lists: accept it, or tell the owner why not.
5. Act on every `quartz:` line the report quotes.

Then run `quartz review` there (the cards move to In review); if it fails, move the cards by hand through the Quartz
MCP. Tell the owner only failures, gate results, deviations and the decisions you need: the board shows the rest.

## 8. Click-through and merge

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).

## 9. After a branch merge

The main checkout is back on `main`. Make the edits that waited, and commit the specs and plans you held back, each
staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks upload them. Task
ticks queued during the run drain at the next stop.
