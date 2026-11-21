# relay-plan: a plan's answers, for the relay

`relay-plan` answers the relay orchestrator's questions about a plan, so that it never reads a plan whole: whether a
newly written plan passes the hand-back checks, whether it can run beside the plans in flight, which acceptance steps
there are and who runs each, one step's text, and the skill-test situations as files. It also keeps each plan's run
folder, where the relay's agents leave their reports, and the branch's gate runs in it.

It ships with hyper-relay as `bin/relay-plan`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `relay-plan` by name. For your own shell (and OpenCode's), symlink it from a
clone into a directory on your `PATH`:

```sh
ln -sfn /path/to/hyper-relay/bin/relay-plan ~/.local/bin/relay-plan
```

## Requirements

- A POSIX shell: `relay-plan` is written for dash and runs as `#!/bin/sh`.
- git 2.31 or later, and `awk`.

## Plans, branches and run folders

Run it anywhere in the repo's main checkout or in one of its worktrees. A `<plan>` is a path from the repo's top, or an
absolute path, and the file must exist.

A plan's branch is its file name without a leading `YYYY-MM-DD-` and without `.md`:
`docs/superpowers/plans/2026-11-20-demo.md` runs on the branch `demo`.

Its run folder is `.hyper-relay/runs/<branch>/` in the main checkout (the parent of
`git rev-parse --path-format=absolute --git-common-dir`), so the main checkout and every worktree share it. Git
ignores `.hyper-relay/runs/`: when it does not yet, `relay-plan` adds that line to the repo's local exclude file (the
file `git rev-parse --git-path info/exclude` names), never to `.gitignore`. Nothing in a run folder is ever cleared.

## Output and exit codes

One line per item. Under a `FAIL` line, at most 5 lines of detail, each indented by two spaces.

| Exit | Means |
|---|---|
| 0 | all ok |
| 1 | a check failed, or nothing was found |
| 2 | a usage error, a missing file, or a missing branch or log |

`gate` exits with its command's code instead.

## Reading a plan

Nothing inside a fenced code block counts as a task, a step, a heading, a path or a placeholder, so a plan that quotes
another plan or a skill's text in a fence is read right. A task is a `### Task <N>` heading, and runs to the next `## `
or `### ` heading. The last task is the acceptance task. Its steps are written
``- [ ] **Step <id> (`<who>` …): <title>**``, where `<who>` is `reviewer`, `owner`, `after merge` or `skill-test`, and
the title may wrap onto the next line.

## Commands

### `relay-plan run-dir <plan>`

Creates the plan's run folder when it does not exist, and prints its absolute path.

### `relay-plan check <plan> [--spec <spec>] [--sibling <plan>]… [--base <plan>]`

The checks of a newly written plan, in this order, one line each: `ok <check>`, or `FAIL <check>: <detail>`.

| Check | Runs | Passes when |
|---|---|---|
| `committed` | always | `main` has a commit of the plan; when the main checkout is on another branch (a branch run), the file exists |
| `card` | with `--spec` | the spec's header names no card, or the plan's header has a `**Card:**` or `**Cards:**` line, or a `**Spec:**` line naming the spec |
| `trailers` | always | each task that commits carries `Plan-Task: <plan path>#<N>` once, with its own number |
| `acceptance` | always | each step of the acceptance task names who runs it |
| `skill-tests` | always | each `skill-test` step has a `Situation:` line, then a fence opened as ```` ```text ````, and a `GREEN must:` and a `RED is expected to:` line |
| `placeholders` | always | no `TBD`, `TODO`, `implement later`, `fill in details` or `Similar to Task` outside fences and inline code |
| `coverage` | with `--spec` | every `## ` heading of the spec is the first cell of a row in the plan's `## Spec coverage` table |
| `contract` | with `--sibling` | the plan's `## Contract` section is the same, line for line, as each sibling's |
| `builds-on` | with `--base` | the plan's header has a `**Builds on:**` line naming the base |

A task commits when one of its `bash`, `sh` or `shell` code blocks runs `git commit`, and a trailer counts only in such
a block. The acceptance task needs no trailer: its commits, if it has any, are the release's.

### `relay-plan overlap <plan> <other>…`

Whether `<plan>` can run beside each `<other>`: a plan, or a branch in flight. A plan's paths are the quoted ones on
its `- Create:`, `- Modify:` and `- Test:` lines, without a `:<lines>` part. A branch's are its plan's
(`docs/superpowers/plans/<YYYY-MM-DD>-<branch>.md`) and what `git diff --name-only main...<branch>` lists. It prints
`shared <path> (<other>)` for each path in both, and `numbered <folder><digits> (<other>)` when both create files in
one folder whose names start with the same digits followed by `_` or `.`, such as migrations (a date is not a
number here). No output, and exit 0: no overlap.

### `relay-plan steps <plan> [reviewer|owner|after-merge|skill-test]`

The acceptance task's steps, all or one who's. The first line is `tasks <N>; acceptance task <M>`: the plan's number of
tasks, and the acceptance task's number (the tasks before it are the executor's). Then one line per step: its id, who
runs it (as the plan writes it, `after merge` with its space) and its title, separated by tabs.

### `relay-plan step <plan> <id>`

One acceptance step's full text, from its `- [ ] **Step <id>` line to the next step or the end of the task.

### `relay-plan scenarios <plan> <dir>`

Writes each `skill-test` step's situation, the text of the first fenced block after its `Situation:` line without the
fence lines, to `<dir>/step-<id>.txt`, and prints its id, that file and its title, separated by tabs. A `skill-test`
step with no fenced situation prints `FAIL <id>: no fenced situation`, and the exit is 1.

### `relay-plan gate <plan> <command>`

Runs `<command>` with `sh -c` from the top of the current checkout (the main checkout or a worktree), and appends a
block to the run folder's `gates.log`:

```text
GATE <full sha of the checkout's HEAD> <command>
<the command's stdout and stderr>
EXIT <code>
```

It prints the output's last 5 lines, then `EXIT <code>`, and exits with the command's code. The log is only ever
appended to. A command is known by its exact text, so give `gates` the same text; a command must be one line.

### `relay-plan gates <plan> [<command>…]`

For each command in `gates.log`, or each one named, its latest block, as
`ok <command>: exit <code> at <short sha>: <last non-empty output line>`, or `FAIL` in the same form when the exit is
not 0 or the block ran at another commit than the tip of the plan's branch. A named command that never ran is
`FAIL <command>: not in gates.log`. After a fix round the earlier blocks are older than the tip and FAIL, so the check
after a fix round names the commands it reran.
