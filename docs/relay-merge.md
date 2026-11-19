# relay-merge: land branches on main, gated

`relay-merge` lands finished branches on `main`, one at a time. Each lands as a merge commit, and the checks you name
for the files it changed run on the merged result before the next branch starts. It stops at the first branch that
fails.

It ships with hyper-relay as `bin/relay-merge`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `relay-merge` by name. For your own shell (and OpenCode's), symlink it from a
clone into a directory on your `PATH`:

```sh
ln -sfn /path/to/hyper-relay/bin/relay-merge ~/.local/bin/relay-merge
```

## Requirements

- A POSIX shell: `relay-merge` is written for dash and runs as `#!/bin/sh`.
- git and `awk`, and whatever your gates run.
- Optionally `wt` ([docs/wt.md](wt.md)): when it is on `PATH`, a branch whose worktree has a `wt` stack up is refused.

## Usage

```sh
relay-merge feat/login fix/typo
```

Run it in the repo's main checkout, on `main`. It lands the branches in the order given and stops at the first one
that fails; the branches before it stay landed. It takes no options: its settings are environment variables (below).

### Each branch

1. **The checks,** which refuse before anything changes (exit 1):
   - it runs in the main checkout, not in a worktree; that checkout is on `main`, with no merge in progress;
   - `main` has no uncommitted changes to tracked files under the paths the gates watch, or anywhere when there is no
     `merge.conf` (untracked files do not count);
   - the branch exists, and is not `main`;
   - when the branch is checked out in a worktree, that worktree has no uncommitted or untracked files, and `wt ls`
     lists no stack for it.
2. **Already in `main`:** a branch whose commits are all in `main` is skipped. It still counts as landed, so the
   cleanup removes it.
3. **The merge:** `git merge --no-ff`, so every landing leaves a merge commit named for its branch: the message is
   `Merge branch '<branch>'`, then, when `RELAY_MERGE_TRAILERS` is set, a blank line and its lines. If the merge
   conflicts, `relay-merge` runs `git merge --abort`, so `main` is unchanged, and stops (exit 2): merge `main` into
   the branch, resolve the conflict there, and run `relay-merge` again. If git refuses to start the merge (a staged
   change on `main`, or an untracked file the branch would overwrite), `main` is unchanged too (exit 1).
4. **The gates,** on the merged result: each line of `.hyper-relay/merge.conf` whose prefix matches a file the branch
   changed (below). Their output goes to a log, and the terminal shows one line per gate. When one fails, everything
   stops (exit 3): the merge stays on `main`, not pushed and not undone, and `relay-merge` prints the log's last 20
   lines, the log's path and the commit `main` was on before the merge. Fix forward on a new branch, or undo the merge
   yourself.

### Once every branch is in

- **The push:** `PUSH=1` pushes `main` to its remote and `PUSH=0` does not. Otherwise `relay-merge` asks on the
  terminal, after dropping anything typed while the gates ran, so a stray Enter cannot answer for you. With no
  terminal (piped, or run by an agent) the answer is no. When `main` is level with its upstream, there is nothing to
  push and nothing is asked.
- **The cleanup:** unless `KEEP=1`, each landed branch's worktree goes with `git worktree remove`, then the branch with
  `git branch -d`: the forms git refuses for an unclean worktree or an unmerged branch, so the cleanup cannot lose
  work.

A failed push or cleanup prints a warning and does not change the exit code. After a failure, nothing is pushed or
cleaned up.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Every branch landed. |
| `1` | A check refused a branch; that branch did not change `main`. |
| `2` | A merge conflict; it was aborted, and `main` is unchanged for that branch. |
| `3` | A gate failed; the merge is on `main`, not pushed. |

Whatever the code, the branches before the one that stopped it stay landed, and `relay-merge` names them.

## Environment

| Variable | Effect |
|---|---|
| `PUSH` | `1` pushes `main` without asking; `0` never pushes. Unset, or any other value: asks on a terminal, and with no terminal does not push. |
| `KEEP` | `1` keeps the landed branches and their worktrees. |
| `SKIP_TESTS` | `1` skips the `test` gates; the `build` gates still run. |
| `RELAY_MERGE_TRAILERS` | Lines added to the end of every merge message, after a blank line, so git reads them as its trailers: for example `Co-Authored-By:` lines. |
| `XDG_STATE_HOME` | The logs go to `$XDG_STATE_HOME/relay-merge/`, or to `~/.local/state/relay-merge/` when it is unset. |

## `.hyper-relay/merge.conf`

Commit a `.hyper-relay/merge.conf` in the repo, with one gate per line:

```
<prefix> <kind> <command>
```

- **prefix:** a path from the repo's top, with no leading `/` or `./`. The gate runs when the branch added, changed,
  deleted or renamed a file whose path starts with it, as text: `core/` matches `core/a.c`, and `bin/tool` matches
  both `bin/tool` and `bin/tool-extra`. The prefix `.` matches any change.
- **kind:** `build` or `test`. `SKIP_TESTS=1` skips the `test` lines.
- **command:** the rest of the line, run with `sh -c` from the repo's top, with no terminal input. It passes when it
  exits 0.

A line whose first word starts with `#` is a comment, and blank lines are skipped. Any other kind, a line with no
command, or a prefix that starts with `/` or `./` stops `relay-merge` before anything changes, naming the line.

The gates run in the file's order, each command once per branch however many matching lines name it, so put the quick
checks first. Their output is appended to a log named for the repo, the time and the branch.

```
# prefix   kind   command
core/      build  make -C core
core/      test   make -C core test
ui/        test   npm --prefix ui test
.          test   sh tests/smoke.sh
```

**The file is read from `main`'s last commit** when `relay-merge` starts: not from the working tree, and not from a
branch being landed. A branch cannot change its own gates, and the commands are as trusted as `main` is. A change to
`merge.conf` gates the branches landed after it, in a later run.

**Without a `merge.conf`,** `relay-merge` lands with no gates and says so, and refuses an uncommitted change to any
tracked file on `main`.

## Safety

- **It never undoes a merge.** After a failed gate the merge stays, for you to fix forward or undo.
- **It never pushes unasked.** Without `PUSH=1` or a yes on a terminal, `main` stays local.
- **It never forces.** The cleanup uses only the forms git refuses for unclean worktrees and unmerged branches, and a
  refusal is only a warning.
- **The gates run the merged code.** The gate commands come from `main`, but they run the branch's code with your
  privileges: land only branches whose code you would run.
