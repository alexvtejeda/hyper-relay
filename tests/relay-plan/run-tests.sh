#!/bin/sh
# POSIX tests for relay-plan. Real git, on temporary repos; HOME is a temporary folder,
# so no git config, hook or state of this machine is used. Nothing here touches the
# repo this suite lives in.
# Usage: sh tests/relay-plan/run-tests.sh   (RELAY_PLAN_BIN overrides the script under test)
# No case reaches a real tmux server: TMUX and TMUX_PANE are unset, TMUX_TMPDIR is a
# folder in the temporary root, and the --pane cases put a fake tmux first on PATH.
# Expect: "174 passed, 0 failed"
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
RP="${RELAY_PLAN_BIN:-$HERE/../../bin/relay-plan}"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

unset GIT_DIR GIT_WORK_TREE
unset TMUX TMUX_PANE
TMUX_TMPDIR="$TMP_ROOT/tmux"
mkdir -p "$TMUX_TMPDIR"
export TMUX_TMPDIR
HOME="$TMP_ROOT/home"
GIT_CONFIG_NOSYSTEM=1
GIT_AUTHOR_NAME=t
GIT_AUTHOR_EMAIL=t@example.invalid
GIT_COMMITTER_NAME=t
GIT_COMMITTER_EMAIL=t@example.invalid
GIT_CEILING_DIRECTORIES="$TMP_ROOT"
export HOME GIT_CONFIG_NOSYSTEM GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_CEILING_DIRECTORIES
mkdir -p "$HOME"

# The fake tmux: logs each call, runs a split's last argument as the pane's command.
mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/tmux" <<'FAKE'
#!/bin/sh
echo "$*" >> "$FAKE_TMUX_LOG"
case $1 in
    split-window)
        for a in "$@"; do printf '%s\n' "$a"; done > "$FAKE_TMUX_DIR/split.args"
        if [ -n "${FAKE_SPLIT_ERR:-}" ]; then
            echo "$FAKE_SPLIT_ERR" >&2
            exit 1
        fi
        if [ -n "${FAKE_PANE_GONE:-}" ]; then
            echo %7
            exit 0
        fi
        for last in "$@"; do :; done
        sh -c "$last" < /dev/null > "$FAKE_TMUX_DIR/pane.out" 2>&1 &
        echo $! > "$FAKE_TMUX_DIR/pane.pid"
        n=0
        while [ ! -s "$FAKE_TMUX_DIR/pane.out" ] && [ "$n" -lt 20 ]; do
            sleep 0.1
            n=$((n + 1))
        done
        echo %7
        exit 0
        ;;
    kill-pane)
        if [ -n "${FAKE_PANE_GONE:-}" ]; then
            echo "can't find pane: %7" >&2
            exit 1
        fi
        exit 0
        ;;
    *)
        echo "fake tmux: unexpected $*" >&2
        exit 1
        ;;
esac
FAKE
chmod +x "$TMP_ROOT/fakebin/tmux"

# NOTMUX: the tools relay-plan needs, and no tmux.
NOTMUX="$TMP_ROOT/notmux"
mkdir -p "$NOTMUX"
for tool in dash sh git awk sed tail cat mkdir dirname basename mktemp rm; do
    ln -s "$(command -v "$tool")" "$NOTMUX/$tool"
done

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

assert_eq() { # description expected actual
    if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2], got [$3]"; fi
}
assert_contains() { # description needle haystack
    case $3 in
        *"$2"*) ok "$1" ;;
        *) bad "$1" "[$2] not in [$3]" ;;
    esac
}
assert_not_contains() { # description needle haystack
    case $3 in
        *"$2"*) bad "$1" "[$2] should not be in [$3]" ;;
        *) ok "$1" ;;
    esac
}

# new_repo: a repo on main under a new case folder, committed once. Sets CASE and MAIN.
new_repo() {
    CASE=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    MAIN="$CASE/proj"
    git init -q -b main "$MAIN"
    printf '# new_repo\n' > "$MAIN/.git/info/exclude"
    printf 'init\n' > "$MAIN/README"
    git -C "$MAIN" add README
    git -C "$MAIN" commit -q -m init
}

# files_plan <path> <line>...: writes a plan with one Files task under $MAIN.
files_plan() {
    path=$1
    shift
    mkdir -p "$(dirname "$MAIN/$path")"
    {
        printf '# Plan\n\n### Task 1: Files\n\n**Files:**\n'
        printf '%s\n' "$@"
    } > "$MAIN/$path"
}

# commit_all <message>: stages everything in $MAIN and commits.
commit_all() {
    git -C "$MAIN" add -A
    git -C "$MAIN" commit -q -m "$1"
}

# commit_in <checkout> <file> <text>: writes <file> there and commits it.
commit_in() {
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -- "$2"
    git -C "$1" commit -q -m "change $2"
}

# rp <dir> <arg>...: runs relay-plan from <dir>. Sets OUT, ERR and RC.
rp() {
    dir=$1
    shift
    (cd "$dir" && dash "$RP" "$@" < /dev/null > "$TMP_ROOT/out" 2> "$TMP_ROOT/err")
    RC=$?
    OUT=$(cat "$TMP_ROOT/out")
    ERR=$(cat "$TMP_ROOT/err")
}

exists() { if [ -e "$1" ]; then echo yes; else echo no; fi; }

# pane_env: the fake tmux's folder and log, and the environment rpt gives relay-plan.
pane_env() {
    FAKE_TMUX_DIR="$CASE/tmux"
    mkdir -p "$FAKE_TMUX_DIR" "$CASE/tmp"
    FAKE_TMUX_LOG="$FAKE_TMUX_DIR/log"
    : > "$FAKE_TMUX_LOG"
    export FAKE_TMUX_DIR FAKE_TMUX_LOG
    unset FAKE_SPLIT_ERR FAKE_PANE_GONE
    T_PATH="$TMP_ROOT/fakebin:$PATH"
    T_TMUX="$TMP_ROOT/tmux/fake,1,0"
    T_PANE=%3
}

# pane_case: a repo on the branch demo-plan holding the plan, and pane_env. Sets TIP and LOG.
pane_case() {
    new_repo
    files_plan "$P" '- Modify: `src/main.sh`'
    commit_all plan
    git -C "$MAIN" switch -q -c demo-plan
    TIP=$(git -C "$MAIN" rev-parse HEAD)
    LOG="$MAIN/.hyper-relay/runs/demo-plan/gates.log"
    pane_env
}

# rpt <dir> <arg>...: as rp, with the pane environment (a value of unset leaves it out).
rpt() {
    dir=$1
    shift
    (
        cd "$dir" || exit 2
        PATH=$T_PATH
        TMPDIR="$CASE/tmp"
        export PATH TMPDIR
        if [ "$T_TMUX" = unset ]; then unset TMUX; else TMUX=$T_TMUX; export TMUX; fi
        if [ "$T_PANE" = unset ]; then unset TMUX_PANE; else TMUX_PANE=$T_PANE; export TMUX_PANE; fi
        exec dash "$RP" "$@" < /dev/null > "$TMP_ROOT/out" 2> "$TMP_ROOT/err"
    )
    RC=$?
    OUT=$(cat "$TMP_ROOT/out")
    ERR=$(cat "$TMP_ROOT/err")
}

# rpt_bg <dir> <arg>...: as rpt, in the background; BG is relay-plan's pid.
rpt_bg() {
    dir=$1
    shift
    (
        cd "$dir" || exit 2
        PATH=$T_PATH
        TMPDIR="$CASE/tmp"
        export PATH TMPDIR
        if [ "$T_TMUX" = unset ]; then unset TMUX; else TMUX=$T_TMUX; export TMUX; fi
        if [ "$T_PANE" = unset ]; then unset TMUX_PANE; else TMUX_PANE=$T_PANE; export TMUX_PANE; fi
        exec dash "$RP" "$@" < /dev/null > "$CASE/bg.out" 2> "$CASE/bg.err"
    ) &
    BG=$!
}

# bg_wait: waits for BG; sets RC, OUT and ERR.
bg_wait() {
    wait "$BG"
    RC=$?
    OUT=$(cat "$CASE/bg.out")
    ERR=$(cat "$CASE/bg.err")
}

# wait_file <path>: 0 once the file is not empty (5 s at most), else 1.
wait_file() {
    n=0
    while [ ! -s "$1" ]; do
        [ "$n" -ge 50 ] && return 1
        sleep 0.1
        n=$((n + 1))
    done
    return 0
}

# gone_within <seconds> <pid>: GONE is gone once the pid is, else running.
gone_within() {
    n=0
    max=$(($1 * 10))
    GONE=running
    while [ "$n" -lt "$max" ]; do
        if ! kill -0 "$2" 2> /dev/null; then GONE=gone; return 0; fi
        sleep 0.1
        n=$((n + 1))
    done
    return 0
}

P=docs/superpowers/plans/2026-01-02-demo-plan.md

# fixture_repo [nocommit]: a new_repo holding the fixture plan at $P, the fixture spec at $S,
# the sibling at $SIB and two base plans. Sets P, S, SIB, BASE, OBASE. With an argument the
# plan is written after the commit and never committed.
fixture_repo() {
    new_repo
    P=docs/superpowers/plans/2026-01-02-demo-plan.md
    S=docs/superpowers/specs/2026-01-02-demo-design.md
    SIB=docs/superpowers/plans/2026-01-02-demo-sibling.md
    BASE=docs/superpowers/plans/2026-01-01-demo-base.md
    OBASE=docs/superpowers/plans/2026-01-01-other-base.md
    mkdir -p "$MAIN/docs/superpowers/plans" "$MAIN/docs/superpowers/specs"
    cp "$HERE/fixtures/spec.md" "$MAIN/$S"
    cp "$HERE/fixtures/sibling.md" "$MAIN/$SIB"
    printf '# Base\n' > "$MAIN/$BASE"
    printf '# Other base\n' > "$MAIN/$OBASE"
    if [ $# -eq 0 ]; then
        cp "$HERE/fixtures/plan.md" "$MAIN/$P"
        commit_all fixtures
    else
        commit_all fixtures
        cp "$HERE/fixtures/plan.md" "$MAIN/$P"
    fi
}

# fails_alone <name> <expected FAIL line> [<option>...]: check "$P" with the options (all of
# them when none): exit 1, exactly one FAIL line, and it is the expected one.
fails_alone() {
    fa_name=$1
    fa_want=$2
    shift 2
    if [ $# -eq 0 ]; then
        rp "$MAIN" check "$P" --spec "$S" --sibling "$SIB" --base "$BASE"
    else
        rp "$MAIN" check "$P" "$@"
    fi
    assert_eq "check: $fa_name: exit 1" 1 "$RC"
    assert_eq "check: $fa_name: one FAIL line" 1 "$(printf '%s\n' "$OUT" | grep -c '^FAIL ')"
    assert_eq "check: $fa_name: the line" "$fa_want" "$(printf '%s\n' "$OUT" | grep '^FAIL ')"
}

# variant <sed program>: rewrites $MAIN/$P as the fixture plan with the edit, and commits it.
variant() {
    sed "$1" "$HERE/fixtures/plan.md" > "$MAIN/$P"
    commit_all variant
}

echo '--- usage'
new_repo
rp "$MAIN"
assert_eq "no command: exit 2" 2 "$RC"
assert_contains "no command: the usage" "usage: relay-plan" "$ERR"
rp "$MAIN" frobnicate "$P"
assert_eq "an unknown command: exit 2" 2 "$RC"
rp "$MAIN" run-dir docs/nope.md
assert_eq "a missing plan: exit 2" 2 "$RC"
assert_contains "a missing plan: named" "no such file: docs/nope.md" "$ERR"
rp "$CASE" run-dir "$P"
assert_eq "outside a repo: exit 2" 2 "$RC"

echo '--- run-dir'
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: exit 0" 0 "$RC"
assert_eq "run-dir: prints the folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir: the folder exists" yes "$(exists "$MAIN/.hyper-relay/runs/demo-plan")"
assert_eq "run-dir: the exclude file gains the line" "# new_repo
.hyper-relay/runs/" "$(cat "$MAIN/.git/info/exclude")"
rp "$MAIN" run-dir "$MAIN/$P"
assert_eq "run-dir again, by an absolute path: the same folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir again: the line is there once" 1 "$(grep -c -x -F '.hyper-relay/runs/' "$MAIN/.git/info/exclude")"
: > "$MAIN/.hyper-relay/runs/demo-plan/executor.md"
assert_eq "run-dir: git status shows none of it" "" "$(git -C "$MAIN" status --porcelain --untracked-files=all)"
files_plan docs/superpowers/plans/odd.md '- Modify: `x`'
rp "$MAIN" run-dir docs/superpowers/plans/odd.md
assert_eq "run-dir: a name without a date" "$MAIN/.hyper-relay/runs/odd" "$OUT"

new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
printf '# kept' > "$MAIN/.git/info/exclude"
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: an exclude file without a last newline: the line on its own" "# kept
.hyper-relay/runs/" "$(cat "$MAIN/.git/info/exclude")"

new_repo
printf '.hyper-relay/\n' > "$MAIN/.gitignore"
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: already ignored: exit 0" 0 "$RC"
assert_eq "run-dir: already ignored: the exclude file is untouched" "# new_repo" "$(cat "$MAIN/.git/info/exclude")"

new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
git -C "$MAIN" worktree add -q "$CASE/wt" -b demo-plan
rp "$CASE/wt" run-dir "$P"
assert_eq "run-dir from a worktree: the main checkout's folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir from a worktree: the main repo's exclude file" 1 "$(grep -c -x -F '.hyper-relay/runs/' "$MAIN/.git/info/exclude")"
assert_eq "run-dir from a worktree: nothing in the worktree" no "$(exists "$CASE/wt/.hyper-relay")"

echo '--- gate'
new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
git -C "$MAIN" switch -q -c demo-plan
TIP=$(git -C "$MAIN" rev-parse HEAD)
SHORT=$(printf '%s' "$TIP" | cut -c1-7)
LOG="$MAIN/.hyper-relay/runs/demo-plan/gates.log"
rp "$MAIN" gate "$P" 'echo one; echo two'
assert_eq "gate: exit 0" 0 "$RC"
assert_eq "gate: the output, then EXIT" "one
two
EXIT 0" "$OUT"
assert_eq "gate: makes the folder and writes the block" "GATE $TIP echo one; echo two
one
two
EXIT 0" "$(cat "$LOG")"
rp "$MAIN" gate "$P" 'seq 7'
assert_eq "gate: only the last 5 lines" "3
4
5
6
7
EXIT 0" "$OUT"
rp "$MAIN" gate "$P" 'echo bad >&2; exit 3'
assert_eq "gate: exits with the command's code" 3 "$RC"
assert_eq "gate: stderr is part of the output" "bad
EXIT 3" "$OUT"
rp "$MAIN" gate "$P" "printf 'no newline'"
assert_eq "gate: EXIT on its own line" "no newline
EXIT 0" "$(tail -n 2 "$LOG")"
rp "$MAIN/docs" gate "$P" pwd
assert_eq "gate: from a subfolder, runs at the top" "$MAIN
EXIT 0" "$OUT"
rp "$MAIN" gate "$P" true
assert_eq "gate: no output" "EXIT 0" "$OUT"
rp "$MAIN" gate "$P" 'echo a
echo b'
assert_eq "gate: a command with a newline: exit 2" 2 "$RC"
assert_eq "gate: the log has one block per run" 6 "$(grep -c '^GATE ' "$LOG")"

echo '--- gates'
rp "$MAIN" gates "$P"
assert_eq "gates: exit 1 when one failed" 1 "$RC"
assert_eq "gates: each command's latest block, in order" "ok echo one; echo two: exit 0 at $SHORT: two
ok seq 7: exit 0 at $SHORT: 7
FAIL echo bad >&2; exit 3: exit 3 at $SHORT: bad
ok printf 'no newline': exit 0 at $SHORT: no newline
ok pwd: exit 0 at $SHORT: $MAIN
ok true: exit 0 at $SHORT: (no output)" "$OUT"
rp "$MAIN" gates "$P" true 'echo one; echo two'
assert_eq "gates: the commands named, in that order" "ok true: exit 0 at $SHORT: (no output)
ok echo one; echo two: exit 0 at $SHORT: two" "$OUT"
assert_eq "gates: all ok: exit 0" 0 "$RC"
rp "$MAIN" gates "$P" 'never ran'
assert_eq "gates: a command that never ran" "FAIL never ran: not in gates.log" "$OUT"
assert_eq "gates: a command that never ran: exit 1" 1 "$RC"
commit_in "$MAIN" src/fix.sh 'fixed'
NEW=$(git -C "$MAIN" rev-parse HEAD | cut -c1-7)
rp "$MAIN" gates "$P" 'echo one; echo two'
assert_eq "gates: a block older than the tip fails" "FAIL echo one; echo two: exit 0 at $SHORT: two" "$OUT"
rp "$MAIN" gate "$P" 'echo one; echo two'
rp "$MAIN" gates "$P" 'echo one; echo two'
assert_eq "gates: the latest block counts" "ok echo one; echo two: exit 0 at $NEW: two" "$OUT"
files_plan docs/superpowers/plans/2026-01-02-no-branch.md '- Modify: `x`'
rp "$MAIN" gates docs/superpowers/plans/2026-01-02-no-branch.md
assert_eq "gates: no branch: exit 2" 2 "$RC"
git -C "$MAIN" branch no-log
files_plan docs/superpowers/plans/2026-01-02-no-log.md '- Modify: `x`'
rp "$MAIN" gates docs/superpowers/plans/2026-01-02-no-log.md
assert_eq "gates: no log: exit 2" 2 "$RC"

echo '--- gate in a worktree'
new_repo
files_plan docs/superpowers/plans/2026-01-03-wt-plan.md '- Modify: `x`'
commit_all plan
git -C "$MAIN" worktree add -q "$CASE/wt" -b wt-plan
rp "$CASE/wt" gate docs/superpowers/plans/2026-01-03-wt-plan.md pwd
assert_eq "gate in a worktree: runs at the worktree's top" "$CASE/wt
EXIT 0" "$OUT"
assert_eq "gate in a worktree: the block, in the main checkout's run folder" "GATE $(git -C "$CASE/wt" rev-parse HEAD) pwd" \
    "$(head -n 1 "$MAIN/.hyper-relay/runs/wt-plan/gates.log")"
assert_eq "gate in a worktree: nothing in the worktree" no "$(exists "$CASE/wt/.hyper-relay")"
rp "$MAIN" gates docs/superpowers/plans/2026-01-03-wt-plan.md
assert_eq "gates from the main checkout reads the worktree's runs" 0 "$RC"

STEP4='- [ ] **Step 4 (`owner`; the orchestrator runs the command at the click-through): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git merge-tree --write-tree main demo-plan` | exit 0 |'
STEP5='- [ ] **Step 5 (`after merge`, last): The release.**

```bash
git -C /tmp/demo commit -m "chore: release v1.0.1"
```'

echo '--- steps'
fixture_repo
rp "$MAIN" steps "$P"
assert_eq "steps: the summary, then every step of the last task, nothing fenced or after it" \
  "$(printf 'tasks 3; acceptance task 3\n1\treviewer\tThe tool runs.\n2\tskill-test\tS1, the first scenario.\n3\tskill-test\tS2, the second scenario.\n4\towner\tThe branch merges cleanly.\n5\tafter merge\tThe release.')" "$OUT"
assert_eq "steps: exit 0" 0 "$RC"
rp "$MAIN" steps "$P" skill-test
assert_eq "steps: one who's" "$(printf 'tasks 3; acceptance task 3\n2\tskill-test\tS1, the first scenario.\n3\tskill-test\tS2, the second scenario.')" "$OUT"
rp "$MAIN" steps "$P" after-merge
assert_eq "steps: after-merge selects after merge" "$(printf 'tasks 3; acceptance task 3\n5\tafter merge\tThe release.')" "$OUT"
rp "$MAIN" steps "$P" owner
assert_eq "steps: a wrapped title, on one line" "$(printf 'tasks 3; acceptance task 3\n4\towner\tThe branch merges cleanly.')" "$OUT"
rp "$MAIN" steps "$P" nobody
assert_eq "steps: an unknown who: exit 2" 2 "$RC"
files_plan docs/superpowers/plans/2026-01-03-bare.md '- Modify: `x`'
rp "$MAIN" steps docs/superpowers/plans/2026-01-03-bare.md
assert_eq "steps: no step: the summary only" "tasks 1; acceptance task 1" "$OUT"
assert_eq "steps: no step: exit 1" 1 "$RC"

echo '--- step'
rp "$MAIN" step "$P" 4
assert_eq "step: its lines, to the next step" "$STEP4" "$OUT"
rp "$MAIN" step "$P" 5
assert_eq "step: the last one ends at the task's end" "$STEP5" "$OUT"
rp "$MAIN" step "$P" 6
assert_eq "step: not a step of the acceptance task: exit 1" 1 "$RC"

echo '--- scenarios'
rp "$MAIN" scenarios "$P" "$CASE/sc"
assert_eq "scenarios: one line per skill-test step" \
  "$(printf '2\t%s\tS1, the first scenario.\n3\t%s\tS2, the second scenario.' "$CASE/sc/step-2.txt" "$CASE/sc/step-3.txt")" "$OUT"
assert_eq "scenarios: exit 0" 0 "$RC"
cmp -s "$CASE/sc/step-2.txt" - <<'X' && ok "scenarios: step-2.txt is the fenced text" || bad "scenarios: step-2.txt is the fenced text" "differs"
You are the orchestrator.

The plan is done.
X
cmp -s "$CASE/sc/step-3.txt" - <<'X' && ok "scenarios: step-3.txt, a bold Situation label" || bad "scenarios: step-3.txt, a bold Situation label" "differs"
You are the executor.
X
variant '/^\*\*Situation:\*\*$/,/^GREEN must: commit/ { /^```/d; }'
rp "$MAIN" scenarios "$P" "$CASE/sc2"
assert_eq "scenarios: a situation without a fence" \
  "$(printf '2\t%s\tS1, the first scenario.\nFAIL 3: no fenced situation' "$CASE/sc2/step-2.txt")" "$OUT"
assert_eq "scenarios: without a fence: exit 1" 1 "$RC"
assert_eq "scenarios: without a fence: no file for it" no "$(exists "$CASE/sc2/step-3.txt")"
variant '/^\*\*Situation:\*\*$/,/^GREEN must: commit/ s/^```text$/```/'
rp "$MAIN" scenarios "$P" "$CASE/sc3"
assert_eq "scenarios: a fence without info still counts" 0 "$RC"
rp "$MAIN" scenarios docs/superpowers/plans/2026-01-03-bare.md "$CASE/sc4"
assert_eq "scenarios: no skill-test step: exit 1" 1 "$RC"

echo '--- check'
fixture_repo
rp "$MAIN" check "$P" --spec "$S" --sibling "$SIB" --base "$BASE"
assert_eq "check: the good plan passes every check, in order" "ok committed
ok card
ok trailers
ok acceptance
ok skill-tests
ok placeholders
ok coverage
ok contract
ok builds-on" "$OUT"
assert_eq "check: the good plan: exit 0" 0 "$RC"
rp "$MAIN" check "$P"
assert_eq "check: without options, the five that need none" "ok committed
ok trailers
ok acceptance
ok skill-tests
ok placeholders" "$OUT"
rp "$MAIN" check "$MAIN/$P" --spec "$MAIN/$S"
assert_eq "check: absolute paths read the same" 0 "$RC"
rp "$MAIN" check "$P" --spec docs/nope.md
assert_eq "check: a missing spec: exit 2" 2 "$RC"
rp "$MAIN" check "$P" --colour red
assert_eq "check: an unknown option: exit 2" 2 "$RC"

fixture_repo nocommit
fails_alone "committed" "FAIL committed: main has no commit of $P"
git -C "$MAIN" switch -q -c other
rp "$MAIN" check "$P"
assert_contains "check: committed on a branch run: the file existing is enough" "ok committed" "$OUT"

fixture_repo
variant '/^\*\*Spec:\*\*/d'
fails_alone "card" "FAIL card: the spec names a card, and the plan's header has no **Card:**, **Cards:** or **Spec:** line naming $S"
fixture_repo
grep -v '^\*\*Card:\*\*' "$HERE/fixtures/spec.md" > "$MAIN/$S"
variant '/^\*\*Spec:\*\*/d'
rp "$MAIN" check "$P" --spec "$S"
assert_contains "check: a spec without a card: ok card" "ok card" "$OUT"

fixture_repo
variant 's/\(feat: the tool.*demo-plan\.md#\)1/\12/'
fails_alone "trailers: a wrong number" "FAIL trailers: Task 1: Plan-Task $P#2 is not $P#1"
fixture_repo
variant 's/2026-01-02-demo-plan\.md#1"/2026-01-02-other-plan.md#1"/'
fails_alone "trailers: another plan's path" "FAIL trailers: Task 1: Plan-Task docs/superpowers/plans/2026-01-02-other-plan.md#1 is not $P#1"
fixture_repo
variant 's/ -m "Plan-Task: [^"]*#2"//'
fails_alone "trailers: none" "FAIL trailers: Task 2 commits without a Plan-Task trailer"
fixture_repo
variant '/^git commit -m "feat: the tool"/p'
fails_alone "trailers: two" "FAIL trailers: Task 1 carries 2 Plan-Task trailers"

fixture_repo
variant 's/(`owner`;/(`the owner`;/'
fails_alone "acceptance" 'FAIL acceptance: Step 4: "the owner" is not reviewer, owner, after merge or skill-test'
fixture_repo
variant '/^\*\*Situation:\*\*$/,/^GREEN must: commit/ s/^```text$/```/'
fails_alone "skill-tests: a fence without text" 'FAIL skill-tests: Step 3: no ```text fence after Situation:'
fixture_repo
variant '/^RED is expected to: skip it\.$/d'
fails_alone "skill-tests: no RED" "FAIL skill-tests: Step 2: no RED is expected to: line"
fixture_repo
variant '/^\*\*Goal:\*\*/a\
Fill this in: TBD.'
fails_alone "placeholders" "FAIL placeholders: line $(grep -n '^Fill this in' "$MAIN/$P" | cut -d: -f1): Fill this in: TBD."
fixture_repo
variant '/^| 2. Acceptance | 3 |$/d'
fails_alone "coverage" "FAIL coverage: not in the Spec coverage table: 2. Acceptance"
fixture_repo
sed 's/Both plans share this\./Both plans share that./' "$HERE/fixtures/sibling.md" > "$MAIN/$SIB"
commit_all "sibling differs"
fails_alone "contract" "FAIL contract: $SIB differs, first at: Both plans share that."
fixture_repo
fails_alone "builds-on" "FAIL builds-on: the header's **Builds on:** does not name $OBASE" \
    --spec "$S" --sibling "$SIB" --base "$OBASE"

echo '--- overlap'
fixture_repo
B=docs/superpowers/plans/2026-01-03-b.md
files_plan "$B" '- Modify: `src/main.sh`' '- Modify: `src/fenced.sh`' '- Create: `src/b.sh`'
commit_all b
rp "$MAIN" overlap "$P" "$B"
assert_eq "overlap: a shared file, without :lines; a fenced path is not the plan's" "shared src/main.sh ($B)" "$OUT"
assert_eq "overlap: found: exit 1" 1 "$RC"

M1=docs/superpowers/plans/2026-01-03-m1.md
M2=docs/superpowers/plans/2026-01-03-m2.md
files_plan "$M1" '- Create: `db/000097_orders.sql`' '- Create: `docs/2026-01-03-a.md`' '- Test: `tests/m1.sh`'
files_plan "$M2" '- Create: `db/000097_coupons.sql`' '- Create: `docs/2026-01-03-b.md`' '- Modify: `tests/m1.sh`'
commit_all m
rp "$MAIN" overlap "$M1" "$M2"
assert_eq "overlap: shared, then numbered; a date is not a number" "shared tests/m1.sh ($M2)
numbered db/000097 ($M2)" "$OUT"

C=docs/superpowers/plans/2026-01-03-c.md
files_plan "$C" '- Modify: `ui/x.sh`'
commit_all c
rp "$MAIN" overlap "$M1" "$C"
assert_eq "overlap: none: no output" "" "$OUT"
assert_eq "overlap: none: exit 0" 0 "$RC"
rp "$MAIN" overlap "$P" "$C" "$B"
assert_eq "overlap: several others, in the order given" "shared src/main.sh ($B)" "$OUT"

files_plan docs/superpowers/plans/2026-01-03-b-branch.md '- Modify: `ui/x.sh`'
commit_all 'the b-branch plan'
git -C "$MAIN" switch -q -c b-branch
commit_in "$MAIN" tests/m1.sh 'changed'
commit_in "$MAIN" db/000097_extra.sql 'added'
git -C "$MAIN" switch -q main
rp "$MAIN" overlap "$M1" b-branch
assert_eq "overlap: a branch's diff counts" "shared tests/m1.sh (b-branch)
numbered db/000097 (b-branch)" "$OUT"
rp "$MAIN" overlap "$C" b-branch
assert_eq "overlap: a branch's plan counts" "shared ui/x.sh (b-branch)" "$OUT"
rp "$MAIN" overlap "$M1" no-such-thing
assert_eq "overlap: neither a plan nor a branch: exit 2" 2 "$RC"

echo '--- gates: output that looks like an EXIT line'
new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
git -C "$MAIN" switch -q -c demo-plan
SHORT=$(git -C "$MAIN" rev-parse HEAD | cut -c1-7)
rp "$MAIN" gate "$P" 'echo "EXIT 0"; echo real; exit 3'
assert_eq "gate: its own output holds an EXIT line: the real code" 3 "$RC"
rp "$MAIN" gate "$P" 'echo real; echo "EXIT 0"'
rp "$MAIN" gates "$P" 'echo "EXIT 0"; echo real; exit 3'
assert_eq "gates: an EXIT line in the output does not hide the real code" "FAIL echo \"EXIT 0\"; echo real; exit 3: exit 3 at $SHORT: real" "$OUT"
assert_eq "gates: it fails: exit 1" 1 "$RC"
rp "$MAIN" gates "$P" 'echo real; echo "EXIT 0"'
assert_eq "gates: the last output line may itself look like an EXIT line" "ok echo real; echo \"EXIT 0\": exit 0 at $SHORT: EXIT 0" "$OUT"

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

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
