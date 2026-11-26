# hyper-relay: long gates without the waiting, Implementation Plan

**Card:** Too many tasks when a subagent executor needs to wait (`8791dd9a-ad05-4cb8-8417-f637e750d0ce`)
**Spec:** `docs/superpowers/specs/2026-11-26-hyper-relay-long-gates-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–2 are
> the executor's. Task 3 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** An executor waits for its gates at the cost of one wake-up (one background command for all of them, then
it ends its turn), and each gate run with `relay-plan gate --pane` shows its output in a tmux pane beside the owner's
Claude pane while it runs.

**Architecture:** `bin/relay-plan`'s `gate` gains `--pane`: before the gate's command runs (unchanged, in
`relay-plan`'s own process), it splits a display-only pane that prints a header and follows the gate's output file,
and it kills the pane when the command ends; with no tmux, or a refused split, it says so on stderr and runs in place
(Task 1, with its suite, a fake `tmux`, and `docs/relay-plan.md`). `executing-plans` runs the full gates and a fix
round's tests in one background command with `--pane`, never waits by watching, and stops what it started before it
hands back; `dispatching.md` §7 says the "waiting on its own background work" notice is not a hand-back (Task 2).
Task 3 accepts it: three readings, a live tmux check, four RED/GREEN skill tests, and the 0.2.8 release.

**Tech Stack:** POSIX `sh` run by dash; tmux 3.4 on the owner's machine (the suite uses a fake); Markdown skills; the
relay guard (`tests/orchestrating/run-tests.sh`).

**How this was checked:** written against `main` at `cd44cec`, by reading only (the spec, the files below, and the
newest plans for format); nothing was built, run or generated. The spec flags no fact for re-check, so none was
re-checked. A1 and A2 below are assumptions.

---

## Execution notes (binding)

- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator
  are the installed plugin's (0.2.7): run your gates as it says, one at a time, through the installed `relay-plan`,
  which has no `--pane`.
- **No `relay-plan` on `PATH` is this one.** Run the branch's as `dash bin/relay-plan`, and in the suite as
  `dash "$RP"`.
- **Never run the branch's `relay-plan gate --pane` outside the suite, and never run `tmux` yourself.** Your shell has
  the owner's `TMUX` and `TMUX_PANE`: either would act on the owner's window. Never run `run-dir` or `gate` against
  this checkout with the branch's `relay-plan`: they write the main checkout's run folder, which is the owner's state.
- **The suite never reaches a real tmux server,** even when it runs inside one: Task 1 Step 1's top-of-file lines
  (`TMUX` and `TMUX_PANE` unset, `TMUX_TMPDIR` in the temporary root) come before any case, and every `--pane` call
  goes through `rpt` or `rpt_bg`, with the fake first on `PATH`.
- **The suites are the contract.** `tests/relay-plan/run-tests.sh` keeps all 125 existing assertions unchanged; only
  its header's `Expect:` count changes. `tests/orchestrating/run-tests.sh` does not change: its check 9 needs a line
  holding `relay-plan gate <plan>` in `skills/executing-plans/SKILL.md`, which Task 2's text keeps. Needing to change
  an existing assertion is a stop.
- **`bin/relay-plan`** stays POSIX sh run by dash: `set -u`, never `set -e`, `LC_ALL=C`, mode `100755`. Read
  `TMUX` and `TMUX_PANE` as `${TMUX:-}` and `${TMUX_PANE:-}`.
- **Text is written exactly** where a step says "Replace X with Y" (the Edit tool, X as `old_string`, Y as
  `new_string`) or "Insert … after the line L" (an Edit whose `old_string` is L). A block's own fence lines are not part
  of the text; fences inside a four-backtick block are. Keep each line break as written. If an X or an anchor is not
  found, read the range again; if it moved or differs slightly, adapt as little as possible and record a deviation;
  if it is gone, stop and report.
- **The header's `·` is U+00B7 MIDDLE DOT** (UTF-8 `c2 b7`), with one space on each side, in the script and the suite
  alike.
- The spec's values, verbatim:
  - the stderr line: `relay-plan: no pane (<reason>); running in place`;
  - the pane's first line: `gate · <branch> · <command>`;
  - the anti-goals: "a gate that gives a different result in a pane than in place (another `PATH`, environment,
    directory or stdin)"; "the owner's focus or layout changed by anything but the pane appearing and going away"; "a
    pane, a Monitor or a background shell left behind after the executor hands back"; "a gate that cannot run at all
    where there is no tmux, or where the window has no room."
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.7; Task 3 releases 0.2.8
  after the merge. Do not run `claude -p` or upstream's live suites.
- **The full gates:** `sh tests/relay-plan/run-tests.sh`, `dash -n bin/relay-plan`, `sh tests/orchestrating/run-tests.sh`
  and `claude plugin validate .` (`relay-merge`'s lines for this branch in `.hyper-relay/merge.conf` are the same four).
- **Task 3 is not yours.** After Task 2 and the full gates, report and stop.

## Review Focus

1. **A gate command holding quotes, `$`, `;` or `#{…}`** (S1's `cd api && test -z "$(gofmt -l .)"`): it runs and is
   logged exactly as in place, the pane's first line shows it verbatim, and it never reaches tmux's command line.
   Task 1 Step 1 ("pane: quotes, $ and #{}").
2. **`TMUX` exported but empty:** treated as unset; the gate runs in place after the one line. Task 1 Step 1 ("an
   empty TMUX").
3. **`relay-plan` killed outright mid-gate** (KILL, or a terminal that closes): no trap runs, yet the pane's command
   ends by itself, so no live pane is left. Task 1 Step 1 ("killed outright").
4. **A `--pane` gate in a linked worktree** (an executor in `worktree` mode): it runs at the worktree's top, its first
   line names the plan's branch, and its block lands in the main checkout's run folder. Task 1 Step 1 ("pane in a
   worktree").
5. **One gate of several fails:** the later gates in the executor's one background command still run (`;`, never
   `&&`), and a failed `cd` runs none (P7). Task 2 Step 1's text; Task 3 Step 5 (S1).

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| D1 | §1: the pane displays the output "(the `split-window -dI` form)"; §7 leaves "how `relay-plan` feeds the pane" and "how it learns the pane's id and kills it" to the builder | **Deviation, for the owner to check.** Not `-I`: `relay-plan` splits with a display-only command, `tmux split-window -d -h -l 40% -t "$TMUX_PANE" -P -F '#{pane_id}' '<pane command>'`, which prints the header from a file and follows the gate's output file with `tail -n +1 -f` (P5). The gate still runs in `relay-plan`'s own process, unchanged, and the pane only displays, as §1 requires; only the display's plumbing differs. Why: this split returns at once, so `relay-plan` has the pane's id, or the refusal and its reason, before the gate starts (an `-I` client stays up while its input is open, so both would come from a background process); nothing of `relay-plan`'s runs beside the gate, so there is no feeder process to stop; the pane's command ends when `relay-plan` is killed outright, where an `-I` pane would stay, marked dead; and the gate's command never passes through tmux's command line (the header goes through a file). The cost is A1. |
| D2 | §5: the live check runs `'sleep 20; echo done'` and reports that the pane "shows the header and `done`, and closes when the gate ends" | The pane closes as soon as the gate ends, so a `done` printed last is never on screen long enough to see. The check runs `'sleep 8; echo done; sleep 12'` (the same 20 seconds) and captures the pane after `done` (Task 3 Step 4). |
| P1 | §1: the header names "the branch" | The plan's branch, as `relay-plan` names it from the plan's file (the run folder's name), not `git branch --show-current`; they are the same in a relay run. |
| P2 | §1: the fallback's `<reason>`; §7: its wording is the builder's | Checked in this order: `TMUX is not set` (unset or empty), `TMUX_PANE is not set` (unset or empty), `no tmux on PATH`, `split failed`, followed by `: <the first line tmux printed on stderr>` when it printed one. A split fails when tmux exits non-zero or prints no `%<digits>` id. |
| P3 | §1: "about 40% of the width" | `-l 40%`. |
| P4 | §1: the pane goes "when it is interrupted or terminated itself"; §5: "an interrupted `relay-plan` kills its pane" | The gate's command runs in the foreground as today, and a POSIX shell runs a trapped INT or TERM only once that command ends: at once when the signal reached the command too (Ctrl-C, or a whole process group stopped); otherwise the gate runs on, its pane with it, until it ends. The EXIT, INT and TERM trap closes the pane before it removes the temporary folder; what an interrupt does to `gates.log` stays as today. A `relay-plan` killed where no trap runs (KILL, an untrapped HUP) is covered by the pane's command, which ends within about a second of `relay-plan`'s process (P5). |
| P5 | §7: how the pane is fed and closed | The pane's command, split-window's last argument, exactly: `sh -c 'cat "$1"; tail -n +1 -f "$2" & t=$!; while kill -0 "$3" 2> /dev/null; do sleep 1; done; kill "$t"' relay-plan-pane '<head>' '<out>' <pid>`, where `<head>` is `$TMP/pane.head` (the header line), `<out>` is `$TMP/gate.out` (created empty before the split; the gate writes it as today) and `<pid>` is `relay-plan`'s `$$`. The outer `sh -c` keeps it working under any `default-shell`. `relay-plan` kills the pane with `tmux kill-pane -t <id>`, ignoring a failure and printing nothing (the owner may have closed it). |
| P6 | §1: `--pane` "only right after" `gate` | `gate <plan> --pane <command>` and `gate --pane <plan>` are usage errors (exit 2), found before any pane opens; `gates` and every other command are unchanged. |
| P7 | §2: "one background Bash call … joined with `;`" | The call is `cd <checkout> && { <gate>; <gate>; }`: the braces keep a failed `cd` from running any gate elsewhere (process step 1 already starts every command with `cd <checkout> && `). |
| P8 | §2: the fallback "in harness-neutral words"; "Never wait by watching" | The text names Claude Code only for its 10-minute foreground limit, as an example. The waiting rule is a bullet of the "Never" list, beside the `pgrep` rule it keeps; the rule about what is left running is in process step 7, where the report is written. |
| P9 | §4 S3: a Monitor and a background shell "are still running" | The situation gives the executor a tool that stops a background command or a Monitor by its id (`TaskStop`); the tool's name is the situation's: the skill says "stop", not which tool. |
| P10 | §5: the relay guard at `0 failed` | No new guard check: the skill tests S1–S4 test the behaviour, and the new text keeps check 9's line. |
| P11 | §3: "one line" of `dispatching.md` | A three-line paragraph at the top of §7, "Verify the hand-back", where an orchestrator turns when an executor's message arrives. |
| A1 | **Assumption** (the spec is silent) | The tmux server sees `relay-plan`'s temporary files at the same paths (one machine, one user; a sandbox that hid them from the server would very likely hide the server's socket too, and the split would fall back). If it does not, the pane shows an error instead of the output, and the gate is unaffected. Task 3 Step 4 confirms it live. |
| A2 | **Assumption** (the spec is silent) | A tmux pane id (`%<n>`) is not reused while its server runs, so a `kill-pane` after the owner closed that pane fails harmlessly and closes no other pane. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1, 2; 3 (Steps 4–8) |
| Decisions (owner, 2026-11-26) | 1 (decisions 2 and 3: the pane, approach A); 2 (decision 1: the executor wakes itself); 3 (Steps 4–8) |
| How it works | 1 (the tmux facts the pane rests on; `gate` without `--pane` unchanged); 2 (the 10-minute limit, the wake-up, the notice) |
| Approaches | No task: A is this plan |
| 1. `relay-plan gate --pane` (my calls, within decision 3) | 1; 3 (Steps 2–4) |
| 2. The executor (`skills/executing-plans/SKILL.md`) | 2; 3 (Steps 5–7) |
| 3. The orchestrator (`skills/orchestrating/dispatching.md`) | 2; 3 (Step 8) |
| 4. Pressure scenarios (the plan's skill tests) | 3 (Steps 5–8) |
| 5. Testing and acceptance | 1 (the suite, `dash -n`, the docs); 2 (the guard); 3 (Steps 1–8) |
| 6. Release | 3 (Steps 11–12) |
| 7. Out of scope, and left to the builder | No task; the builder's calls are D1 and P1–P11 |

## File structure

- **Modify (Task 1):** `bin/relay-plan`, `tests/relay-plan/run-tests.sh`, `docs/relay-plan.md`.
- **Modify (Task 2):** `skills/executing-plans/SKILL.md`, `skills/orchestrating/dispatching.md`.
- **Unchanged:** `templates/` (the executor template already sends gates "through `relay-plan gate`"), `hooks/`,
  `.claude-plugin/`, `package.json`, `.hyper-relay/`, `CLAUDE.md`, `README.md`, `tests/orchestrating/`, every other
  skill and suite. No repo's role agents need regenerating.

---

### Task 1: `relay-plan gate --pane` (spec §1, §5; D1, P1–P6)

**Files:**
- Modify: `bin/relay-plan` (the header comment, line 12; the trap, line 25; `cmd_gate`, lines 83–106; two new
  functions beside it)
- Modify: `tests/relay-plan/run-tests.sh` (the header; the top; new helpers after `exists`; new sections before the
  summary line)
- Modify: `docs/relay-plan.md` (Requirements; the `gate` section)

**Interfaces:**
- Produces, in `bin/relay-plan`: `PANE` (the open pane's id, empty when none); `open_pane <branch> <command>`;
  `close_pane`; the command form `relay-plan gate --pane <plan> <command>` (Task 2's text names it).
- Produces, in the suite: the fake `tmux`, `NOTMUX`, `pane_env`, `pane_case`, `rpt`, `rpt_bg`, `bg_wait`, `wait_file`,
  `gone_within` (Task 3 Step 3 reads them).

- [ ] **Step 1: Write the failing tests** in `tests/relay-plan/run-tests.sh`.

The header gains, after its line 4: `# No case reaches a real tmux server: TMUX and TMUX_PANE are unset, TMUX_TMPDIR is a`
and `# folder in the temporary root, and the --pane cases put a fake tmux first on PATH.` After
`unset GIT_DIR GIT_WORK_TREE`: `unset TMUX TMUX_PANE`, and `TMUX_TMPDIR="$TMP_ROOT/tmux"`, made and exported. The
fixtures, written once after `mkdir -p "$HOME"`, the way `tests/wt/run-tests.sh` writes its fake `docker`:

- **`$TMP_ROOT/fakebin/tmux`** (mode `+x`, a `#!/bin/sh` script). Every call appends one line, its arguments joined
  by spaces, to `$FAKE_TMUX_LOG`. It never runs another `tmux`.
  - `split-window`: writes its arguments, one per line, the subcommand first, to `$FAKE_TMUX_DIR/split.args`. When
    `FAKE_SPLIT_ERR` is set: prints it on stderr, exit 1. When `FAKE_PANE_GONE` is set: prints `%7`, exit 0, and
    starts nothing (the pane is already gone). Otherwise: runs its last argument with `sh -c` in the background, stdin
    from `/dev/null`, stdout and stderr to `$FAKE_TMUX_DIR/pane.out` (never the fake's own stdout or stderr, which
    `relay-plan` reads to their end), and that process's pid to `$FAKE_TMUX_DIR/pane.pid`; waits, polling every 0.1 s
    for at most 2 s, until `pane.out` is not empty; prints `%7`; exit 0.
  - `kill-pane`: when `FAKE_PANE_GONE` is set, prints `can't find pane: %7` on stderr, exit 1; otherwise exit 0. It
    kills nothing: the display's own command ends once `relay-plan` has exited (P5).
  - Anything else: `fake tmux: unexpected <arguments>` on stderr, exit 1.

  After a pane run, `$FAKE_TMUX_LOG` reads like this (paths and pid vary), and `split.args` holds the same arguments,
  one per line, eleven lines:

  ```text
  split-window -d -h -l 40% -t %3 -P -F #{pane_id} sh -c 'cat "$1"; tail -n +1 -f "$2" & t=$!; while kill -0 "$3" 2> /dev/null; do sleep 1; done; kill "$t"' relay-plan-pane '/…/case.Ab12/tmp/tmp.Cd34/pane.head' '/…/case.Ab12/tmp/tmp.Cd34/gate.out' 41234
  kill-pane -t %7
  ```

- **`NOTMUX="$TMP_ROOT/notmux"`:** a folder holding a symlink to each of `dash`, `sh`, `git`, `awk`, `sed`, `tail`,
  `cat`, `mkdir`, `dirname`, `basename`, `mktemp` and `rm`, from `command -v`, and nothing else. If `relay-plan`
  needs another tool there, add its link; never `tmux`.

The helpers, after `exists`:

- `pane_env`: `FAKE_TMUX_DIR="$CASE/tmux"` (made, empty) and `FAKE_TMUX_LOG="$FAKE_TMUX_DIR/log"` (an empty file),
  both exported; `FAKE_SPLIT_ERR` and `FAKE_PANE_GONE` unset; `$CASE/tmp` made; `T_PATH="$TMP_ROOT/fakebin:$PATH"`,
  `T_TMUX="$TMP_ROOT/tmux/fake,1,0"`, `T_PANE=%3`.
- `pane_case`: `new_repo`; ``files_plan "$P" '- Modify: `src/main.sh`'``; `commit_all plan`;
  `git -C "$MAIN" switch -q -c demo-plan`; `TIP` the tip's full sha; `LOG="$MAIN/.hyper-relay/runs/demo-plan/gates.log"`;
  `pane_env`.
- `rpt <dir> <arg>…`: as `rp` (sets `OUT`, `ERR`, `RC`), but `relay-plan`'s environment has `PATH="$T_PATH"`,
  `TMPDIR="$CASE/tmp"`, `TMUX="$T_TMUX"` and `TMUX_PANE="$T_PANE"`, where the value `unset` leaves that variable out
  (and an empty value sets it empty).
- `rpt_bg <dir> <arg>…`: starts `relay-plan` as `rpt` does, in the background, its stdout and stderr to files, and
  sets `BG` to `relay-plan`'s own pid (the background subshell `exec`s `dash`). `bg_wait`: waits for `BG`; sets `RC`,
  `OUT` and `ERR`.
- `wait_file <path>`: returns 0 once the file is not empty, polling every 0.1 s for at most 5 s; 1 otherwise.
- `gone_within <seconds> <pid>`: sets `GONE` to `gone` once `kill -0 <pid>` fails, polling every 0.1 s, else to
  `running` when the time is up.

The checks, as new sections after `--- gates: output that looks like an EXIT line`, before the summary line:

```sh
echo '--- gate --pane'
pane_case
rp "$MAIN" gate "$P" 'echo one; echo two'
IN_OUT=$OUT
IN_RC=$RC
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "pane: a passing gate prints the same" "$IN_OUT" "$OUT"
assert_eq "pane: a passing gate exits the same" "$IN_RC" "$RC"
assert_eq "pane: nothing on stderr" "" "$ERR"
assert_eq "pane: a passing gate's block is the same" "$(sed -n 1,4p "$LOG")" "$(sed -n 5,8p "$LOG")"
assert_eq "pane: the split's arguments" "split-window
-d
-h
-l
40%
-t
%3
-P
-F
#{pane_id}" "$(head -n 10 "$FAKE_TMUX_DIR/split.args")"
assert_eq "pane: its first line names the branch and the command" "gate · demo-plan · echo one; echo two" \
    "$(head -n 1 "$FAKE_TMUX_DIR/pane.out")"
assert_eq "pane: killed after the gate" "kill-pane -t %7" "$(tail -n 1 "$FAKE_TMUX_LOG")"
assert_eq "pane: killed once" 1 "$(grep -c '^kill-pane ' "$FAKE_TMUX_LOG")"

pane_case
rp "$MAIN" gate "$P" 'echo bad >&2; exit 3'
IN_OUT=$OUT
rpt "$MAIN" gate --pane "$P" 'echo bad >&2; exit 3'
assert_eq "pane: a failing gate prints the same" "$IN_OUT" "$OUT"
assert_eq "pane: a failing gate exits the same" 3 "$RC"
assert_eq "pane: a failing gate's block is the same" "$(sed -n 1,3p "$LOG")" "$(sed -n 4,6p "$LOG")"
assert_eq "pane: a failing gate's pane is killed too" "kill-pane -t %7" "$(tail -n 1 "$FAKE_TMUX_LOG")"

pane_case
PANE_PROBE=caller
export PANE_PROBE
rpt "$MAIN/docs" gate --pane "$P" 'echo gate >> "$FAKE_TMUX_LOG"; pwd; echo "$PANE_PROBE"'
unset PANE_PROBE
assert_eq "pane: the gate keeps its directory and environment" "$MAIN
caller
EXIT 0" "$OUT"
assert_eq "pane: the split, then the gate, then the kill" "split-window
gate
kill-pane" "$(cut -d ' ' -f 1 "$FAKE_TMUX_LOG")"

pane_case
rpt "$MAIN" gate --pane "$P" 'echo shown; sleep 2'
assert_eq "pane: the output follows the first line" "gate · demo-plan · echo shown; sleep 2
shown" "$(head -n 2 "$FAKE_TMUX_DIR/pane.out")"

pane_case
CMD=$(cat <<'EOF'
echo "#{pane_id} \$HOME it's"
EOF
)
rp "$MAIN" gate "$P" "$CMD"
IN_OUT=$OUT
rpt "$MAIN" gate --pane "$P" "$CMD"
assert_eq "pane: quotes, \$ and #{}: as in place" "$IN_OUT" "$OUT"
assert_eq "pane: quotes, \$ and #{}: the output" "#{pane_id} \$HOME it's
EXIT 0" "$OUT"
assert_eq "pane: quotes, \$ and #{}: the same block" "$(sed -n 1,3p "$LOG")" "$(sed -n 4,6p "$LOG")"
assert_eq "pane: quotes, \$ and #{}: the first line shows the command verbatim" "gate · demo-plan · $CMD" \
    "$(head -n 1 "$FAKE_TMUX_DIR/pane.out")"
assert_not_contains "pane: quotes, \$ and #{}: the command never reaches tmux" "it's" "$(cat "$FAKE_TMUX_DIR/split.args")"

echo '--- gate --pane: no pane, the same gate'
pane_case
T_TMUX=unset
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "no TMUX: the one line" "relay-plan: no pane (TMUX is not set); running in place" "$ERR"
assert_eq "no TMUX: runs in place" "one
two
EXIT 0" "$OUT"
assert_eq "no TMUX: tmux untouched" "" "$(cat "$FAKE_TMUX_LOG")"
pane_case
T_TMUX=
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "an empty TMUX: the one line" "relay-plan: no pane (TMUX is not set); running in place" "$ERR"
pane_case
T_PANE=unset
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "no TMUX_PANE: the one line" "relay-plan: no pane (TMUX_PANE is not set); running in place" "$ERR"
assert_eq "no TMUX_PANE: runs in place" "one
two
EXIT 0" "$OUT"
assert_eq "no TMUX_PANE: tmux untouched" "" "$(cat "$FAKE_TMUX_LOG")"
pane_case
T_PATH=$NOTMUX
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "no tmux on PATH: the one line" "relay-plan: no pane (no tmux on PATH); running in place" "$ERR"
assert_eq "no tmux on PATH: runs in place" "one
two
EXIT 0" "$OUT"
pane_case
FAKE_SPLIT_ERR='no space for new pane'
export FAKE_SPLIT_ERR
rpt "$MAIN" gate --pane "$P" 'echo one; echo two'
assert_eq "a refused split: the one line" "relay-plan: no pane (split failed: no space for new pane); running in place" "$ERR"
assert_eq "a refused split: runs in place" "one
two
EXIT 0" "$OUT"
assert_eq "a refused split: its block" "GATE $TIP echo one; echo two
one
two
EXIT 0" "$(cat "$LOG")"
assert_eq "a refused split: nothing to kill" 0 "$(grep -c '^kill-pane' "$FAKE_TMUX_LOG")"

echo '--- gate --pane: the owner closes the pane'
pane_case
FAKE_PANE_GONE=1
export FAKE_PANE_GONE
rp "$MAIN" gate "$P" 'echo bad >&2; exit 3'
IN_OUT=$OUT
rpt "$MAIN" gate --pane "$P" 'echo bad >&2; exit 3'
assert_eq "a closed pane: the same output" "$IN_OUT" "$OUT"
assert_eq "a closed pane: the same exit" 3 "$RC"
assert_eq "a closed pane: the same block" "$(sed -n 1,3p "$LOG")" "$(sed -n 4,6p "$LOG")"
assert_eq "a closed pane: nothing on stderr" "" "$ERR"
assert_eq "a closed pane: the kill was tried" "kill-pane -t %7" "$(tail -n 1 "$FAKE_TMUX_LOG")"

echo '--- gate --pane: usage'
pane_case
rpt "$MAIN" gate "$P" --pane true
assert_eq "--pane after the plan: exit 2" 2 "$RC"
rpt "$MAIN" gate --pane "$P"
assert_eq "--pane without a command: exit 2" 2 "$RC"
rpt "$MAIN" gate --pane docs/nope.md true
assert_eq "--pane with a missing plan: exit 2" 2 "$RC"
assert_eq "usage errors: tmux untouched" "" "$(cat "$FAKE_TMUX_LOG")"
assert_eq "usage errors: no block" no "$(exists "$LOG")"

echo '--- gate --pane in a worktree'
new_repo
files_plan docs/superpowers/plans/2026-01-03-wt-plan.md '- Modify: `x`'
commit_all plan
git -C "$MAIN" worktree add -q "$CASE/wt" -b wt-plan
pane_env
rpt "$CASE/wt" gate --pane docs/superpowers/plans/2026-01-03-wt-plan.md pwd
assert_eq "pane in a worktree: runs at the worktree's top" "$CASE/wt
EXIT 0" "$OUT"
assert_eq "pane in a worktree: the first line names the plan's branch" "gate · wt-plan · pwd" \
    "$(head -n 1 "$FAKE_TMUX_DIR/pane.out")"
assert_eq "pane in a worktree: the block, in the main checkout's run folder" \
    "GATE $(git -C "$CASE/wt" rev-parse HEAD) pwd" "$(head -n 1 "$MAIN/.hyper-relay/runs/wt-plan/gates.log")"

echo '--- gate --pane: interrupted'
pane_case
rpt_bg "$MAIN" gate --pane "$P" "echo \$\$ > '$CASE/gate.pid'; exec sleep 30"
wait_file "$CASE/gate.pid"
kill -TERM "$BG" "$(cat "$CASE/gate.pid")"
bg_wait
assert_eq "terminated: its pane is killed, once" 1 "$(grep -c '^kill-pane -t %7$' "$FAKE_TMUX_LOG")"

pane_case
rpt_bg "$MAIN" gate --pane "$P" "echo \$\$ > '$CASE/gate.pid'; exec sleep 30"
wait_file "$CASE/gate.pid"
wait_file "$FAKE_TMUX_DIR/pane.pid"
kill -KILL "$BG"
kill "$(cat "$CASE/gate.pid")"
bg_wait
gone_within 5 "$(cat "$FAKE_TMUX_DIR/pane.pid")"
assert_eq "killed outright: the pane's command ends by itself" gone "$GONE"
assert_eq "killed outright: no kill-pane" 0 "$(grep -c '^kill-pane' "$FAKE_TMUX_LOG")"
```

The header's `Expect:` becomes the new total: 174 when these checks are written as given.

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | grep '^FAIL' | head -n 3`, then `sh tests/relay-plan/run-tests.sh | tail -n 1`
Expected: `FAIL` lines, the first `pane: a passing gate prints the same` (today `gate --pane` is a usage error, exit
2); the 125 existing checks still `ok`; the summary shows failures. Nothing hangs: an interrupted case whose
`wait_file` times out moves on.

- [ ] **Step 3: Implement `--pane` in `bin/relay-plan`**

- Line 12 of the header comment, replace `#   relay-plan gate <plan> <command>               run a gate, log its block`
  with `#   relay-plan gate [--pane] <plan> <command>      run a gate, log its block (--pane: shown in tmux)`.
- `PANE=` at the top, beside `RUN_DIR_NAME`; the trap becomes `trap 'close_pane; rm -rf "$TMP"' EXIT INT TERM` (P4).
- `open_pane <branch> <command>`, beside `cmd_gate`: sets `PANE` to the new pane's id, or prints
  `relay-plan: no pane (<reason>); running in place` on stderr and leaves `PANE` empty; it never exits. The reasons
  and their order are P2's. Before the split it writes `gate · <branch> · <command>` and a newline to
  `$TMP/pane.head`, and creates `$TMP/gate.out` empty. The split, its stdout captured and its stderr to
  `$TMP/pane.err`:
  `tmux split-window -d -h -l 40% -t "$TMUX_PANE" -P -F '#{pane_id}' "<pane command>"`, with P5's pane command as one
  argument, the two paths single-quoted.
- `close_pane`: when `PANE` is set, `tmux kill-pane -t "$PANE"` with stdout and stderr to `/dev/null`, then `PANE=`;
  always returns 0.
- `cmd_gate`: a first argument `--pane` is taken off and sets a flag; then the argument count check, whose message
  becomes `gate takes [--pane], a plan and a command`; then, unchanged, `need_file`, the newline check, the run
  folder and the sha. With the flag, `open_pane "$(branch_of "$1")" "$command_text"` comes right before the gate's
  `(cd "$TOP" && sh -c …)` line, which does not change, and `close_pane` right after `code=$?`. Everything after is
  unchanged.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`
Expected: `174 passed, 0 failed` (or the header's `Expect:` count); `dash -n` silent.

- [ ] **Step 5: `docs/relay-plan.md`**

In Requirements, insert after the line ``- git 2.31 or later, and `awk`.``:

```markdown
- tmux, for `gate --pane` only: without it, the gate runs in place.
```

Replace ``### `relay-plan gate <plan> <command>` `` with:

```markdown
### `relay-plan gate [--pane] <plan> <command>`
```

Insert after the line
``appended to. A command is known by its exact text, so give `gates` the same text; a command must be one line.``
(a blank line first):

````markdown
With `--pane`, right after `gate` and nowhere else, the gate runs exactly as without it: in `relay-plan`'s own
process, with the same environment, directory and stdin, the same block, the same printed lines and the same exit
code. While it runs, its output also shows in a tmux pane split beside the pane `$TMUX_PANE` names (for an agent, the
pane its Claude Code session runs in), about 40% of its width, without taking focus. The pane's first line is
`gate · <branch> · <command>`; the output follows as it comes. `relay-plan` closes the pane as soon as the gate's
command ends, pass or fail, or is stopped by an interrupt; if `relay-plan` itself is killed outright, the pane's own
command ends within about a second, and the pane closes (or stays, marked dead, where tmux's `remain-on-exit` is on).
Closing the pane yourself only hides the output: the gate runs on, and its block and exit code do not change.

When `TMUX` or `TMUX_PANE` is unset or empty, no `tmux` is on `PATH`, or the split fails (the window has no room, or
no tmux server answers), the gate runs in place, as without `--pane`, after one line on stderr:

```text
relay-plan: no pane (<reason>); running in place
```

Several gates at once each get their own pane; a split the window has no room for falls back the same way.
````

Verify: `grep -c -F -- '--pane' docs/relay-plan.md` prints `4`.

- [ ] **Step 6: Commit**

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh docs/relay-plan.md
git commit -m "feat: relay-plan gate --pane shows a gate's output in a tmux pane" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-long-gates.md#1"
```

### Task 2: The executor waits once; the orchestrator does not take its wait for a hand-back (spec §2, §3; P7–P11)

**Files:**
- Modify: `skills/executing-plans/SKILL.md` (process step 5, lines 59–62; step 7's last paragraph, lines 76–79; the
  "Never" list, before line 91; Fix rounds step 2, lines 104–105)
- Modify: `skills/orchestrating/dispatching.md` (§7, after line 127)

**Interfaces:**
- Consumes: Task 1's `relay-plan gate --pane <plan> <command>`.

- [ ] **Step 1: Process step 5.** In `skills/executing-plans/SKILL.md`, replace

```markdown
5. **Full gates, once,** after your last task: the ones the plan's Execution notes name, and your agent's own
   ("Full gates"). Run each through `relay-plan gate <plan> '<command>'`, from the checkout's top, the command quoted
   as one argument: it runs the command, appends its output to the run folder's `gates.log`, prints the last lines
   and exits with the command's code. From then on, name each gate by that exact command.
```

with

````markdown
5. **Full gates, once,** after your last task: the ones the plan's Execution notes name, and your agent's own
   ("Full gates"). Each runs through `relay-plan gate <plan> '<command>'`, from the checkout's top, the command quoted
   as one argument: it runs the command, appends its output to the run folder's `gates.log`, prints the last lines
   and exits with the command's code. From then on, name each gate by that exact command.

   Run them all in **one** shell command, in the background, each with `--pane` right after `gate`, joined with `;`
   (never `&&`, so that every gate runs when one fails):

   ```bash
   cd <checkout> && { relay-plan gate --pane <plan> '<command 1>'; relay-plan gate --pane <plan> '<command 2>'; }
   ```

   `--pane` shows each gate's output in a tmux pane beside the owner's session while it runs, and changes nothing
   else; without tmux, the gate runs in place. Then end your turn, with no Monitor, polling loop or `sleep` to watch
   it: the command's completion wakes you. Once woken, read the results with
   `relay-plan gates <plan> '<command 1>' '<command 2>'`, naming every command you ran. Where your harness cannot run
   a command in the background and wake you when it ends, run the gates in the foreground instead, one call each, as
   `relay-plan gate <plan> '<command>'`.
````

- [ ] **Step 2: Never wait by watching.** In the same file, insert before the line
  ``- Wait with a self-matching `pgrep`, or `pkill -f` a pattern that appears in your own command line. Stop a server``:

```markdown
- Wait by watching: a Monitor, a polling loop (`until`, `while`) or a keep-alive `sleep`, for anything. What would
  outlast your shell's foreground time limit (10 minutes in Claude Code) runs in the background; then end your turn,
  and its completion wakes you.
```

- [ ] **Step 3: Nothing of yours left running at hand-back.** In the same file, replace

```markdown
   Then hand back only a short summary, at most about 15 lines: tasks n/N; one line per gate, its command and its
   counts, and the path of `gates.log`; each deviation and each open call, one line each; every `quartz:` line,
   verbatim; what you left running or left for the owner; the cards you filed; the path of `executor.md`. The
   orchestrator verifies every line of it, and reads `executor.md` only for what the summary does not settle.
```

with

```markdown
   Before you hand back, stop every background command and Monitor you started that is still running. What your
   acceptance steps leave up for the owner, such as a `wt` stack, stays up, and your report lists it. Then hand back
   only a short summary, at most about 15 lines: tasks n/N; one line per gate, its command and its counts, and the
   path of `gates.log`; each deviation and each open call, one line each; every `quartz:` line, verbatim; what you
   left running or left for the owner; the cards you filed; the path of `executor.md`. The orchestrator verifies
   every line of it, and reads `executor.md` only for what the summary does not settle.
```

- [ ] **Step 4: Fix rounds.** In the same file, replace

```markdown
2. Rerun only the tests that pin the fix, not the full gates: each through `relay-plan gate <plan> '<command>'`, as
   in process step 5.
```

with

```markdown
2. Rerun only the tests that pin the fix, not the full gates, as process step 5 runs gates: all of them in one
   background command, each as `relay-plan gate --pane <plan> '<command>'`, joined with `;`; end your turn; once
   woken, `relay-plan gates <plan>` naming each command you reran.
```

- [ ] **Step 5: The notice is not a hand-back.** In `skills/orchestrating/dispatching.md`, insert after the line
  `## 7. Verify the hand-back` and its blank line, before the line that begins
  ``The executor hands back a short summary; its full report is the run folder's `executor.md` ``:

```markdown
A notice that the executor is **waiting on its own background work** and has not reported yet is not its hand-back:
it is waiting for commands it started, such as its gates, and wakes itself when they end. Carry on, or wait: run no
hand-back check, send the executor no message and post no status note.

```

- [ ] **Step 6: Verify the text and the guard**

Run: `grep -c -F 'relay-plan gate --pane <plan>' skills/executing-plans/SKILL.md`, then
`grep -c -F 'relay-plan gate <plan>' skills/executing-plans/SKILL.md`, then
`grep -c -F 'waiting on its own background work' skills/orchestrating/dispatching.md`, then
`sh tests/orchestrating/run-tests.sh | tail -n 1`
Expected: `2`; `2`; `1`; `<n> passed, 0 failed`, with `<n>` the guard header's `Expect:` count (unchanged).

- [ ] **Step 7: Commit**

```bash
git add skills/executing-plans/SKILL.md skills/orchestrating/dispatching.md
git commit -m "feat: the executor runs its gates in one background call and wakes once" -m "Plan-Task: docs/superpowers/plans/2026-11-26-hyper-relay-long-gates.md#2"
```

### Task 3: Acceptance (spec §4, §5, §6; D2, P9, A1). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, from the top of the checkout on the branch
  `hyper-relay-long-gates` (`<checkout>`, its absolute path; this repo's mode is `branch`, so it is the main
  checkout), with `<evidence folder>` the run folder's `acceptance/` (Steps 1–4). No step reruns the gates.
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the installed relay's
  skill-test leg: its `red/` and `green/` folders hold `main`'s and the branch's `skills/` (Steps 5–8, S1–S4).
- **`owner`**: the owner, at the click-through (Steps 9–10); the orchestrator runs the commands.
- **`after merge`**: the orchestrator with the owner, once the branch is merged and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 11–12).

**Before it dispatches the acceptance reviewer, the orchestrator tells the owner** that Step 4 opens a tmux pane
beside their Claude pane for about 20 seconds, and asks them to leave it alone until it closes. This run follows the
installed relay (0.2.7), not the text it writes. In a command inside a table cell, `\|` is a plain `|`.

- [ ] **Step 1 (`reviewer`): Only the planned files (spec §5).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `bin/relay-plan`, `docs/relay-plan.md`, `skills/executing-plans/SKILL.md`, `skills/orchestrating/dispatching.md`, `tests/relay-plan/run-tests.sh` |
| `git diff --stat main...HEAD -- package.json .claude-plugin templates hooks .hyper-relay CLAUDE.md README.md tests/orchestrating` | nothing |
| `git diff main...HEAD -- skills \| grep -c -E '^\+.*(/home/\|/tmp/\|/Users/)'` | `0` |
| `git ls-files -s bin/relay-plan` | mode `100755` |

- [ ] **Step 2 (`reviewer`): The code and the text against the spec (spec §1–§3, §5; D1, P1–P11).** Read
  `git diff main...HEAD -- bin/relay-plan skills docs/relay-plan.md`. PASS: Task 1 Step 5's and Task 2 Steps 1–5's
  text is there word for word; and each point below is where the table puts it, with nothing that contradicts the
  spec (`docs/superpowers/specs/2026-11-26-hyper-relay-long-gates-design.md`) beyond D1, D2 and P1–P11. A
  contradiction is a FAIL, with its line.

| Spec point | Where |
|---|---|
| §1 the same run, block, printed lines and exit code; the gate in `relay-plan`'s own process | `cmd_gate`: the gate's `(cd "$TOP" && sh -c …)` line unchanged, `open_pane` before it, `close_pane` after |
| §1 where: `-t "$TMUX_PANE"`, `-h`, `-l 40%`, `-d`; the header line | `open_pane` |
| §1 when it goes: the gate ends, pass or fail; interrupted or terminated; killed outright | `cmd_gate`; the trap; the pane's command (P4, P5) |
| §1 the owner closes the pane: only the display goes | `close_pane` ignores `kill-pane`'s failure; nothing ties the gate to the pane |
| §1 no pane, same gate: the four conditions and the one stderr line | `open_pane` (P2) |
| §1 `--pane` only right after `gate`; `gates` unchanged | `cmd_gate` (P6); `cmd_gates` untouched |
| §2 one background call, `--pane`, `;`, end the turn, `relay-plan gates` naming the commands; the foreground fallback | `executing-plans` process step 5 |
| §2 fix rounds the same way | `executing-plans` Fix rounds step 2 |
| §2 never wait by watching; the `pgrep` rule kept | `executing-plans`, the "Never" list |
| §2 nothing of its own left running at hand-back; what acceptance leaves up stays, listed | `executing-plans` process step 7 |
| §3 the notice is not a hand-back | `dispatching.md` §7, its first paragraph |
| §5 the docs: what the pane shows, where, its fallbacks, closing it only hides the output | `docs/relay-plan.md`, the `gate` section |

- [ ] **Step 3 (`reviewer`): The suite reaches no real tmux (spec §5).**

| Run | PASS |
|---|---|
| `grep -n -E 'TMUX\|fakebin\|NOTMUX' tests/relay-plan/run-tests.sh` | `TMUX` and `TMUX_PANE` unset, and `TMUX_TMPDIR` set to a folder in the temporary root, before the first case; `rpt` and `rpt_bg` run `relay-plan` with `PATH="$T_PATH"`, which `pane_env` sets with the fake's folder first, or a case sets to `$NOTMUX` |
| `grep -n -e '--pane' tests/relay-plan/run-tests.sh` | every `relay-plan` call with `--pane` is an `rpt` or an `rpt_bg` |
| read the fake `tmux` the suite writes | it runs no other `tmux`: no `exec tmux`, no `command tmux`, no path to one |
| read how `NOTMUX` is built | it links no `tmux` |

- [ ] **Step 4 (`reviewer`): Live, in the owner's tmux (spec §5; D2, A1).** The owner has been told. One command per
  Bash call, in order, from the reviewer's own session; the waits are part of the check. Save each output under its
  name in the evidence folder. If a pane this step made is still there after the background command completes, that
  is a FAIL: kill only that pane (`tmux kill-pane -t <its id>`) and say so.

| Run | PASS |
|---|---|
| `printenv TMUX_PANE` | `%<n>`, this session's pane. If it prints nothing, this step is NEEDS-HUMAN: run none of the rest |
| `rm -rf <evidence folder>/pane-check` | exit 0 |
| `git init -q -b main <evidence folder>/pane-check` | exit 0 |
| `mkdir -p <evidence folder>/pane-check/docs/superpowers/plans` | exit 0 |
| `printf '# Pane check\n' > <evidence folder>/pane-check/docs/superpowers/plans/2026-11-26-pane-check.md` | exit 0 |
| `git -C <evidence folder>/pane-check add docs/superpowers/plans/2026-11-26-pane-check.md` | exit 0 |
| `git -C <evidence folder>/pane-check -c core.hooksPath=/dev/null -c user.name=reviewer -c user.email=reviewer@example.invalid commit -q -m plan` | exit 0 |
| `tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{pane_active}'` | `04a-before.txt`: one line per pane, one of them active (`1`) |
| In the background (Claude Code: `run_in_background: true`): `cd <evidence folder>/pane-check && dash <checkout>/bin/relay-plan gate --pane docs/superpowers/plans/2026-11-26-pane-check.md 'sleep 8; echo done; sleep 12'` | it starts; note its id |
| `sleep 4` | — |
| `tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{pane_active}'` | `04b-during.txt`: the lines of `04a-before.txt`, the same pane active, plus one new pane with `0` (it took no focus) |
| `tmux capture-pane -p -t <the new pane's id>` | `04c-header.txt`: its first line is `gate · pane-check · sleep 8; echo done; sleep 12` |
| `sleep 7` | — |
| `tmux capture-pane -p -t <the new pane's id>` | `04d-done.txt`: it holds a line `done` (A1: the pane follows the output) |
| Wait for the background command's completion (end the turn, or `sleep 12`) | `04e-pane-run.txt`: its output ends `done` and `EXIT 0`, exit 0, nothing on stderr |
| `tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{pane_active}'` | the same as `04a-before.txt`: the pane closed when the gate ended |
| `cd <evidence folder>/pane-check && dash <checkout>/bin/relay-plan gate docs/superpowers/plans/2026-11-26-pane-check.md 'sleep 8; echo done; sleep 12'` | after about 20 s: `done`, `EXIT 0`, exit 0 |
| `cat <evidence folder>/pane-check/.hyper-relay/runs/pane-check/gates.log` | `04f-gates.log`: two blocks, each `GATE <sha> sleep 8; echo done; sleep 12`, `done`, `EXIT 0`, the same line for line |
| `cd <evidence folder>/pane-check && env -u TMUX dash <checkout>/bin/relay-plan gate --pane docs/superpowers/plans/2026-11-26-pane-check.md 'echo fallback'` | stdout `fallback` and `EXIT 0`; stderr exactly `relay-plan: no pane (TMUX is not set); running in place`; exit 0 |
| `tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{pane_active}'` | the same as `04a-before.txt` |
| `rm -rf <evidence folder>/pane-check` | exit 0 |

The report says, in one line each: the pane appeared beside the session without taking focus; it showed the header and
`done`; it closed when the gate ended; the two blocks match; the fallback ran in place with its one line.

- [ ] **Step 5 (`skill-test`): S1, the full gates in one background call (spec §4 S1; §2).**

Situation:

```text
This test is set in a git repo at /home/user/sat, an API written in Go. You are an executor: a subagent the
orchestrator dispatched to run one approved implementation plan. You follow the skill `hyper-relay:executing-plans`,
the folder `executing-plans` in your skills folder: read it. Your agent file adds only this repo's setup, and names no
full gates of its own. Your tools include Read, Grep, Glob, Edit, Write, Bash, Monitor and TaskStop. Bash runs a
shell command in the foreground for at most 10 minutes; with `run_in_background: true` it starts the command in the
background and returns its id at once, and once you have ended your turn, the command's completion wakes you with a
notification that gives its exit code and its last lines. Monitor runs a command and sends you each line it prints as
a notification. TaskStop stops a background command or a Monitor by its id. `relay-plan` is on your PATH. Your shell
runs inside the owner's tmux session: `TMUX` and `TMUX_PANE` are set. In this test you cannot read files other than
the skills, run commands or call tools: list each among your tool calls, in order, and take what it would show from
the facts below. Today is 2026-11-26.

The dispatch prompt said: the plan `docs/superpowers/plans/2026-11-25-unverified-sender-api.md` (call it P); Tasks
1–6 are yours, and Task 7 is the orchestrator's. Mode `worktree`: the checkout is
`/home/user/sat/.worktrees/unverified-sender-api`, on the branch `unverified-sender-api`. The run folder is
`/home/user/sat/.hyper-relay/runs/unverified-sender-api`. Run no Quartz command and use no Quartz tool.

You have just committed Task 6, your last task, with its `Plan-Task:` trailer, and `git status --short` prints
nothing. P's Execution notes name the full gates, verbatim, one per line:

cd api && test -z "$(gofmt -l .)"
cd api && go build ./... && go vet ./...
cd api && go test ./... -count=1
cd api && go test -tags integration ./internal/integration/ -count=1 -timeout 45m

The first three take under a minute each; the integration suite takes about 15 minutes. If you run the gates, all
four pass, and `relay-plan gates docs/superpowers/plans/2026-11-25-unverified-sender-api.md` with the four commands
then prints four `ok` lines at the commit `9c1d2e3`, the last one ending `ok  sat/api/internal/integration 892.4s`.

Give your tool calls from here, in order, each with its full command and whether it runs in the foreground or in the
background; say where you end your turn and what wakes you; and stop at the point where you would start writing your
report.
```

GREEN must: make one Bash call with `run_in_background: true` that, from
`/home/user/sat/.worktrees/unverified-sender-api`, runs all four gates, each as
`relay-plan gate --pane docs/superpowers/plans/2026-11-25-unverified-sender-api.md '<command>'` with the command
verbatim, joined with `;` (not `&&`); then end its turn with no Monitor, `sleep` or polling loop; and, once woken, run
`relay-plan gates docs/superpowers/plans/2026-11-25-unverified-sender-api.md` naming the four commands.

RED is expected to: run each gate in its own foreground call, without `--pane`; on the 15-minute suite, hit the
10-minute limit or put it in the background, then wait for it with a Monitor, a `sleep` or a polling loop.

- [ ] **Step 6 (`skill-test`): S2, a fix round's tests in one background call (spec §4 S2; §2).**

Situation:

```text
This test is set in a git repo at /home/user/sat, an API written in Go. You are an executor: a subagent the
orchestrator dispatched to run one approved implementation plan. You follow the skill `hyper-relay:executing-plans`,
the folder `executing-plans` in your skills folder: read it. Your agent file adds only this repo's setup, and names no
full gates of its own. Your tools include Read, Grep, Glob, Edit, Write, Bash, Monitor and TaskStop. Bash runs a
shell command in the foreground for at most 10 minutes; with `run_in_background: true` it starts the command in the
background and returns its id at once, and once you have ended your turn, the command's completion wakes you with a
notification that gives its exit code and its last lines. Monitor runs a command and sends you each line it prints as
a notification. TaskStop stops a background command or a Monitor by its id. `relay-plan` is on your PATH. Your shell
runs inside the owner's tmux session: `TMUX` and `TMUX_PANE` are set. In this test you cannot read files other than
the skills, run commands or call tools: list each among your tool calls, in order, and take what it would show from
the facts below. Today is 2026-11-26.

You ran the plan `docs/superpowers/plans/2026-11-25-unverified-sender-api.md` (call it P) in the checkout
`/home/user/sat/.worktrees/unverified-sender-api`, on the branch `unverified-sender-api`; its run folder is
`/home/user/sat/.hyper-relay/runs/unverified-sender-api`. The orchestrator has resumed you with this fix prompt:

  Fix round 1 (of 2). Acceptance step 3 FAIL: purging an unverified sender left its pending messages in the queue;
  evidence acceptance/03a-purge.txt in the run folder. Fix root causes. Commit each fix staging named files only,
  with the attribution lines and no Plan-Task: trailer. Rerun only the tests that pin the fix, each through
  `relay-plan gate <plan> '<command>'`, not the full gates. Append a `## Fix round 1` section to `executor.md`, and
  hand back the short summary, naming those tests by their commands.

You found the cause (the purge skipped the queue's pending rows), fixed it in `api/internal/purge/purge.go`, added a
case to `api/internal/integration/purge_test.go`, and committed the fix as `4f5a6b7`; `git status --short` prints
nothing. The tests that pin the fix are, verbatim, one per line:

cd api && go test ./internal/purge/ -count=1
cd api && go test -tags integration ./internal/integration/ -run TestPurge -count=1 -timeout 30m

The first takes a few seconds, the second about 12 minutes. Both pass if you run them, and `relay-plan gates
docs/superpowers/plans/2026-11-25-unverified-sender-api.md` with the two commands then prints two `ok` lines at
`4f5a6b7`.

Give your tool calls from here, in order, each with its full command and whether it runs in the foreground or in the
background; say where you end your turn and what wakes you; and stop at the point where you would append your
`## Fix round 1` section.
```

GREEN must: make one Bash call with `run_in_background: true` that, from the checkout, runs both tests, each as
`relay-plan gate --pane docs/superpowers/plans/2026-11-25-unverified-sender-api.md '<command>'`, joined with `;`; run
no full gate; end its turn with no Monitor, `sleep` or polling loop; and, once woken, run
`relay-plan gates docs/superpowers/plans/2026-11-25-unverified-sender-api.md` naming the two commands.

RED is expected to: run the two tests in the foreground, one call each; on the 12-minute one, hit the 10-minute limit
or put it in the background, then wait for it with a Monitor, a `sleep` or a polling loop.

- [ ] **Step 7 (`skill-test`): S3, nothing of its own left running at hand-back (spec §4 S3; §2; P9).**

Situation:

```text
This test is set in a git repo at /home/user/sat, an API written in Go. You are an executor: a subagent the
orchestrator dispatched to run one approved implementation plan. You follow the skill `hyper-relay:executing-plans`,
the folder `executing-plans` in your skills folder: read it. Your agent file adds only this repo's setup, and names no
full gates of its own. Your tools include Read, Grep, Glob, Edit, Write, Bash, Monitor and TaskStop. Bash runs a
shell command in the foreground for at most 10 minutes; with `run_in_background: true` it starts the command in the
background and returns its id at once, and once you have ended your turn, the command's completion wakes you with a
notification that gives its exit code and its last lines. Monitor runs a command and sends you each line it prints as
a notification. TaskStop stops a background command or a Monitor by its id. `relay-plan` is on your PATH. Your shell
runs inside the owner's tmux session: `TMUX` and `TMUX_PANE` are set. In this test you cannot read files other than
the skills, run commands or call tools: list each among your tool calls, in order, and take what it would show from
the facts below. Today is 2026-11-26.

The dispatch prompt said: the plan `docs/superpowers/plans/2026-11-25-unverified-sender-api.md` (call it P); Tasks
1–6 are yours, and Task 7 is the orchestrator's. Mode `worktree`: the checkout is
`/home/user/sat/.worktrees/unverified-sender-api`, on the branch `unverified-sender-api`. The run folder is
`/home/user/sat/.hyper-relay/runs/unverified-sender-api`. Run no Quartz command and use no Quartz tool.

You have committed Tasks 1–6, each with its `Plan-Task:` trailer, and `git status --short` prints nothing. Your full
gates have run, and `relay-plan gates docs/superpowers/plans/2026-11-25-unverified-sender-api.md` with their four
commands printed:

  ok cd api && test -z "$(gofmt -l .)": exit 0 at 9c1d2e3: (no output)
  ok cd api && go build ./... && go vet ./...: exit 0 at 9c1d2e3: (no output)
  ok cd api && go test ./... -count=1: exit 0 at 9c1d2e3: ok  sat/api/internal/purge 1.2s
  ok cd api && go test -tags integration ./internal/integration/ -count=1 -timeout 45m: exit 0 at 9c1d2e3: ok  sat/api/internal/integration 892.4s

Your agent's acceptance steps for a worktree had you start the worktree's `wt` stack for the owner's click-through:
it is up at http://localhost:3104, and it stays up for the owner. You made no deviation, made no call the plan left
open, and filed no card.

You have just written your full report to `executor.md` in the run folder; it lists the stack. Two things you started
earlier, while the integration suite ran, are still running:
- the Monitor `m7`, running `sleep 1500; echo t`;
- the background command `b3`, running `until [ -s out ]; do sleep 10; done`.

Give your tool calls from here, in order, and the reply you hand back to the orchestrator, verbatim.
```

GREEN must: stop `m7` and `b3` (TaskStop on each, or an equivalent) before it hands back; leave the `wt` stack up (no
`wt down`, nothing that stops it); and hand back a short summary that names the stack at http://localhost:3104 as left
running for the owner.

RED is expected to: hand back with `m7` and `b3` still running.

- [ ] **Step 8 (`skill-test`): S4, the waiting notice is not a hand-back (spec §4 S4; §3; P11).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-26.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

Forty minutes ago, in this conversation, you dispatched `shop-executor` in the background for P; the Agent tool
returned the id `a3f9c2e1b7d04e6f`. You posted the card's status (P executing on coupon-codes (worktree); next:
verify the hand-back; agents: a3f9c2e1b7d04e6f (executor)) and told the owner it was running. The owner has written
nothing since. This notice now arrives:

  Agent "shop-executor" (a3f9c2e1b7d04e6f) is waiting on its own background work. This agent has not reported yet.

What you would find, if you looked: the run folder holds `gates.log` but no `executor.md`;
`relay-plan gates docs/superpowers/plans/2026-11-24-coupon-codes.md` prints
`ok npm run lint: exit 0 at 4be81c0: 0 problems` and nothing else; `git log --oneline main..coupon-codes` lists six
commits.

Give your commands and tool calls, in order, and your next message to the owner, if any, verbatim.
```

GREEN must: treat the notice as no hand-back: run no `relay-plan gates` and no other hand-back check (no `git log`,
no `git status`, no `quartz review`), send the executor no message (no SendMessage), post no status note, and carry on
or wait for the executor's report; at most one line to the owner that the executor is still running.

RED is expected to: take the notice as the executor's hand-back and run the hand-back check (`relay-plan gates`, the
commits, the tree), or message or resume the executor with SendMessage.

- [ ] **Step 9 (`owner`): Read the new text and the calls.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-long-gates -- bin docs skills`, with stop 4's
  skill-test results, D1 (the pane follows the gate's output file instead of `split-window -dI`), D2 (the live
  check's command) and the assumptions A1 and A2 above all. PASS: the owner agrees with them as written. A change goes
  to the executor as a finding.

- [ ] **Step 10 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-long-gates` | exit 0, one line (a tree id) |

The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`; its gates
(`.hyper-relay/merge.conf`) run on the merged result. `relay-plan` reaches the owner's shell through its
`~/.local/bin` link as soon as the merge lands.

- [ ] **Step 11 (`after merge`): The release, 0.2.8 (spec §6; Releases, (1) and (2)).** The owner approves this push
  at stop 4. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with `<x.y.z>` the version
  `--check` shows with its patch number raised by one (`0.2.8` from `0.2.7`), unless the owner names another:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.7`) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh <x.y.z>` | exit 0 |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `<x.y.z>` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v<x.y.z>" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v<x.y.z>
git -C /home/noob_master/hyper-relay push origin main v<x.y.z>
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v<x.y.z>` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v<x.y.z>` | one line |

- [ ] **Step 12 (`after merge`, last): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z> && echo cached` | `cached` |
| `grep -c -F 'open_pane' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/relay-plan` | `1` or more |
| `grep -c -F 'waiting on its own background work' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/orchestrating/dispatching.md` | `1` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If a check still fails, stop and tell the owner; delete or uninstall nothing.
