# hyper-relay: long gates without the waiting (design)

**Date:** 2026-11-26 · **Status:** written from the owner's brainstorm of 2026-11-26, waiting on the owner's review
**Card:** Too many tasks when a subagent executor needs to wait (`8791dd9a-ad05-4cb8-8417-f637e750d0ce`)
**Scope:** this repo: `bin/relay-plan`'s `gate` gets a `--pane` option, with its tests and docs; the
`executing-plans` skill and one line of `orchestrating`'s `dispatching.md`; then a release.

## Goal

When an executor reaches a gate that runs long, like SAT's integration suite (`-timeout 45m`), it burns tokens
waiting. The Bash tool's foreground limit is 10 minutes, so the executor puts the gate in the background, then keeps
itself busy with Monitors, keep-alive sleeps and polling loops. Each of those is a turn that re-reads its whole
context, and none of them is stopped before it hands back (card `8791dd9a`, and How it works below).

This work makes an executor wait for a long gate at the cost of one wake-up, and shows the owner each running gate in
a tmux pane beside their Claude session:

- **The executor wakes itself.** It starts its gates in the background, ends its turn, and is woken once when they
  are done. Nobody resumes it or dispatches a fresh one by hand.
- **A pane on screen means a gate is running.** Each gate run with `--pane` shows its output in a pane split from the
  owner's window, which closes when the gate ends.

**Non-goals:** the acceptance reviewer's long steps (card `685357e9`, filed in this brainstorm); waiting on anything
that is not a gate (`wt up`, a dev server); panes for agents' other commands.

**Anti-goals** (failures even if everything else works):
- a gate that gives a different result in a pane than in place (another `PATH`, environment, directory or stdin);
- the owner's focus or layout changed by anything but the pane appearing and going away;
- a pane, a Monitor or a background shell left behind after the executor hands back;
- a gate that cannot run at all where there is no tmux, or where the window has no room.

## Decisions (owner, 2026-11-26)

1. **The executor wakes itself** when its long gate ends; nobody resumes it or dispatches a fresh one by hand. Why:
   resuming by hand was only a workaround for the wasted waiting.
2. **Keep the tmux pane.** Why: "it would be handy to know when an integration suite is running".
3. **Approach A** (below): a `--pane` option on `relay-plan gate`, not a separate helper. Why: the smallest change;
   `relay-plan` already owns gate runs and `gates.log`, and nothing else needs a pane yet.

The playback (the executor runs its gates in one background call and wakes once; a pane per gate, closed when it ends;
fall back to running in place) stood without corrections. Each call below that is mine, not the owner's, says so.

## How it works

Checked on 2026-11-26 on this machine (Claude Code 2.1.332, tmux 3.4), unless a line says otherwise.

**Today's waste** (card `8791dd9a`'s notes):
- The SAT executor on `launch-unverified-sender-api` (2026-11-25; transcript
  `~/.claude/projects/-home-noob-master-sat-pentraze-com/f5934df9-8a83-4723-a87f-df1dc3691722/subagents/agent-a8cb8cfc249886322.jsonl`)
  took 144 turns and read 35.4M cached tokens. From the moment it put the integration gate in the background to its
  hand-back, about 60 turns and 17M of those tokens went to waiting, each turn re-reading about 275k. It made 12
  Monitors (`sleep 600`…`sleep 1700`, `until`/`while pgrep` loops) and stopped none. One of them woke it again after its
  hand-back, which cost two more turns.
- About 10 `sat-executor` runs since 2026-11-20 made 10–29 waits each (Monitors, and Bash calls that start with
  `until`, `while` or `sleep`), and two `sat-reviewer` runs made 12 and 8.

**Claude Code** (live checks, this brainstorm):
- A subagent can wait for one wake-up. A Haiku subagent ran `sleep 40; echo …` with `run_in_background: true`, then
  ended its turn with plain text. It was not made to hand back. After 40 seconds the completion notification woke it as
  a new turn, and it then handed back. 1 tool call, about 50k tokens (card note `13039524`).
- While it waits, its caller gets an interim notice, "Agent … is waiting on its own background work", with "This
  agent has not reported yet". Later the real hand-back arrives as a message from the agent, followed by a notice that
  it finished (this session's two checks).
- A background Bash call outlasts the 10-minute foreground limit: the SAT executor's background integration gate ran
  from 19:54 to about 20:06 on 2026-11-25 (the transcript above). The foreground limit is 600000 ms (the Bash tool's
  `timeout` parameter).
- A subagent's shell has the session's `TMUX` and `TMUX_PANE`: a Haiku subagent printed `TMUX_PANE=%4`, the pane the
  main session runs in.

**tmux** (`man tmux`, and checks in a throwaway server, `tmux -L <name> -f /dev/null`):
- `split-window -d` makes a pane without making it the current one; `-h` puts it beside the target, `-l <n>%` sizes
  it, `-t` names the pane to split, `-P -F '#{pane_id}'` prints the new pane's id.
- **A new pane does not get its caller's environment.** It gets tmux's global and session environment
  (`man tmux`, GLOBAL AND SESSION ENVIRONMENT). Check: a variable exported by the caller printed `unset` in a pane
  started with `split-window '<command>'`.
- `split-window -I` makes an empty pane that shows whatever arrives on the caller's stdin (`man tmux`, its example:
  `make 2>&1|tmux splitw -dI &`). Check: `sh -c 'echo "FOO=$FOO"; sleep 1; echo line2' | tmux splitw -dI -P -F
  '#{pane_id}'` showed `FOO=caller` and `line2`, so the command ran in the caller's own environment. After the input
  ended, the pane **stayed**, marked dead (`#{pane_dead}` = 1): it has to be closed with `kill-pane`.
- A split fails with `no space for new pane`, exit 1, when the window is too small: a 60-column window refused its
  sixth side-by-side split.
- A pane running a command closes when the command exits, unless the `remain-on-exit` option is on (`man tmux`).
- `wait-for <channel>` blocks until another client runs `wait-for -S <channel>` (checked); approach A does not need it.

**`relay-plan` today** (`bin/relay-plan`, `cmd_gate` and `cmd_gates`):
- `gate <plan> <command>` runs `sh -c <command>` from the checkout's top with stdin from `/dev/null`, stdout and
  stderr together, into a temporary file. It appends `GATE <sha> <command>`, the output and `EXIT <code>` to the run
  folder's `gates.log`, prints the last 5 lines and `EXIT <code>`, and exits with the code.
- `gates` ignores a block with no `EXIT` line and judges the command by its latest complete block.
- The executor (`skills/executing-plans/SKILL.md`, process step 5 and Fix rounds step 2) runs each gate once, in the
  foreground, and has no rule for a gate past the limit or for background work left running at hand-back.

## Approaches

- **A. A `--pane` option on `relay-plan gate`** (picked). It shows a gate's output in a pane beside the owner's
  Claude pane, while the gate itself runs exactly as it does today. The executor skill runs its gates that way, in
  the background, and wakes once. Trade-off: only gates get a pane.
- **B. A separate `relay-pane '<command>'` helper**, wrapping any command: `relay-pane relay-plan gate …`. It would
  also suit `wt up` or the reviewer's suites, but it is one more tool with its own tests, docs and link in
  `~/.local/bin`, plus a longer command for the executor to get right, and only gates need it today. Dropped. The
  code can move into a helper if a second use appears.
- **Skill text only** (run in the background, wake once, no pane). It fixes the tokens but drops the pane the owner
  wants. Dropped.

## 1. `relay-plan gate --pane` (my calls, within decision 3)

`relay-plan gate --pane <plan> <command>` behaves exactly like `relay-plan gate <plan> <command>`: the same run, the
same `gates.log` block, the same printed tail and `EXIT` line, the same exit code. In addition, while the gate runs, its
output shows in a pane:

- **The gate runs in `relay-plan`'s own process, as today.** The pane only displays the output (the `split-window
  -dI` form). That is how a gate keeps its caller's environment, directory and stdin (`/dev/null`), which a pane
  running the command itself would not get (How it works).
- **Where:** split from the pane `$TMUX_PANE` names (the owner's Claude pane, for an executor), side by side (`-h`),
  about 40% of the width, without taking focus (`-d`).
- **What it shows:** a first line naming the branch and the command (`gate · <branch> · <command>`), then the output
  as it comes.
- **When it goes:** `relay-plan` closes the pane (`kill-pane`) once the gate ends, pass or fail, and when it is
  interrupted or terminated itself. The `gates.log` block keeps the whole output.
- **If the owner closes the pane:** only the display goes. The gate runs on, and its block and exit code are what
  they would have been. Closing a pane must never stop or fail a gate. (In the playback I proposed that closing a
  pane cancels its gate. Running the gate outside the pane makes keeping it running simpler, and safer for a
  40-minute suite. **This is a change from the playback, for the owner to check.**)
- **No pane, same gate:** when `$TMUX` or `$TMUX_PANE` is unset, no `tmux` is on `PATH`, or the split fails (no
  room, no server), the gate runs in place as without `--pane`, after one line on stderr:
  `relay-plan: no pane (<reason>); running in place`.
- **Several at once:** each gate gets its own pane. Executors in parallel each split the owner's window, and a split
  refused for space falls back as above.

`--pane` is accepted only by `gate`, and only right after it, before the plan: `relay-plan gate --pane <plan>
<command>`. `relay-plan gates` and the `gates.log` format do not change.

## 2. The executor (`skills/executing-plans/SKILL.md`)

These behaviours change; the planner writes the text:

- **Full gates (process step 5):** after its last task, the executor runs **all** its full gates in **one**
  background Bash call, each as `relay-plan gate --pane <plan> '<command>'`, joined with `;` so every gate runs even
  when one fails. Then it ends its turn. When the call's completion wakes it, it reads the results with `relay-plan
  gates <plan>`, naming the commands it ran. One wake-up for all the gates replaces one turn per gate (my call: it is
  cheaper than today even when no gate is long, and gives every gate a pane).
- **Fix rounds (step 2):** the reruns go the same way: one background call, `--pane`, end the turn, `relay-plan
  gates` naming the reran commands.
- **Where the harness cannot run a command in the background and wake the agent** (an OpenCode session may not), the
  executor runs its gates one at a time in the foreground, as today. The text says this in harness-neutral words.
- **Never wait by watching:** no Monitor, polling loop or keep-alive `sleep` to wait for anything. Something that
  outlasts the foreground limit runs in the background, and the agent ends its turn until it is woken. The existing
  `pgrep` rule stays.
- **Nothing of its own left running at hand-back:** before it hands back, the executor stops every background shell
  or Monitor it started that is still running. What its acceptance steps leave up for the owner, such as a `wt` stack,
  stays up and is listed in its report, as today.

The role-agent template (`templates/agents/executor.md`) already sends gates "through `relay-plan gate`"; it needs
no change, and no repo's agents need regenerating.

## 3. The orchestrator (`skills/orchestrating/dispatching.md`)

One behaviour, so that the executor's new way of waiting does not look like a hand-back (my call: the interim notice
now comes at every gate run):

- A notice that the executor stopped while **waiting on its own background work**, with no report, is not its
  hand-back. The orchestrator carries on and waits: no hand-back check, no message to the executor, no status note.

## 4. Pressure scenarios (the plan's skill tests)

Each gives a situation, what an agent with the branch's text must do (GREEN), and what one with `main`'s text does
instead (RED). The runs are text only: an agent answers with the commands it would run and its next message, and the
situation gives any tool output it needs.

| # | Situation | GREEN | RED |
|---|---|---|---|
| S1 | The executor has finished its last task, inside tmux. Its full gates are `cd api && test -z "$(gofmt -l .)"`, `cd api && go build ./... && go vet ./...`, `cd api && go test ./... -count=1` and `cd api && go test -tags integration ./internal/integration/ -count=1 -timeout 45m`, which takes about 15 minutes. | One background Bash call running all four, each through `relay-plan gate --pane <plan> '<command>'`, joined with `;`, then ends its turn with no Monitor, sleep or polling. Once woken, runs `relay-plan gates <plan>` with the four commands. | Runs each gate in the foreground. On the long one it hits the limit or puts it in the background, then waits with Monitors, sleeps or polling loops. |
| S2 | Fix round 1: the executor has fixed a finding. The tests that pin the fix are `cd api && go test ./internal/purge/ -count=1` and a 12-minute `cd api && go test -tags integration ./internal/integration/ -run TestPurge -count=1 -timeout 30m`. | Both in one background call through `relay-plan gate --pane`, ends its turn, then `relay-plan gates` naming the two. | Foreground runs, then waits by watching on the long one. |
| S3 | The executor has written `executor.md`. A Monitor it started earlier (`sleep 1500; echo t`) and a background shell (`until [ -s out ]; do sleep 10; done`) are still running. Its acceptance step left a `wt` stack up for the owner. | Stops the Monitor and the shell, leaves the stack up, lists the stack in its report, then hands back. | Hands back with both still running. |
| S4 | The orchestrator gets a notice that the executor it dispatched for plan P "is waiting on its own background work" and "has not reported yet". | Treats it as no hand-back: carries on or waits. No `relay-plan gates`, no message to the executor, no status note. | Runs the hand-back check, or messages or resumes the executor. |

## 5. Testing and acceptance

- **`relay-plan`'s suite** (`tests/relay-plan/run-tests.sh`, `0 failed`) covers `--pane` with a fake `tmux` on
  `PATH`, the way `tests/wt/` fakes `docker`. The suite must never reach a real tmux server, even when it runs inside
  one, so it controls `TMUX` and `TMUX_PANE` itself. Cases to cover:
  - the pane path gives the same `gates.log` block, printed tail and exit code as without `--pane`, for a passing and
    a failing gate;
  - the split's arguments: `-d`, `-h`, the `$TMUX_PANE` target;
  - the pane is killed after the gate ends;
  - every fallback (no `TMUX`, no `TMUX_PANE`, a split that fails) runs in place with the one stderr line;
  - a display that dies mid-gate (the fake pane exits early) leaves the gate's result unchanged;
  - an interrupted `relay-plan` kills its pane.
- `dash -n bin/relay-plan` silent; `claude plugin validate .` with its known warnings; the relay guard
  (`tests/orchestrating/run-tests.sh`) at `0 failed`.
- `docs/relay-plan.md` documents `--pane`: what it shows, where, its fallbacks, and that closing the pane only hides
  the output.
- **Skill tests** S1–S4, on both texts.
- **Acceptance reviewer, live in tmux:** it runs `relay-plan gate --pane <plan> 'sleep 20; echo done'` in the
  background from a subagent. It reports that a pane appears beside the session without taking focus, shows the
  header and `done`, and closes when the gate ends, and that the `gates.log` block matches one from a run without
  `--pane`. It then runs it once with `TMUX` unset and reports the in-place fallback. The owner is told before the
  pane appears in their window.

## 6. Release

The merge changes files the plugin loads (`bin/`, `skills/`), so it is released as **0.2.8**, unless the owner names
another (`CLAUDE.md`, How a change reaches the owner). The plan's acceptance task ends with the release as `after
merge` steps. `relay-plan` reaches the owner's shell through its `~/.local/bin` link as soon as it merges.

## 7. Out of scope, and left to the builder

**Out of scope:** the reviewer's long acceptance steps (card `685357e9`); a `relay-pane` helper for non-gate
commands; changes to `gates.log`'s format or to `relay-plan gates`; regenerating role agents.

**Left to the builder:** how `relay-plan` feeds the pane and keeps the gate safe from a display that dies (for
example the gate writing to its file as today while a separate reader such as `tail -f` feeds `split-window -dI`); how
it learns the pane's id and kills it; the exact pane width within "about 40%"; the wording of every instruction and
of the stderr line; the fake `tmux`'s design.
