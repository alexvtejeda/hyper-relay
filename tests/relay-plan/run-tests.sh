#!/bin/sh
# POSIX tests for relay-plan. Real git, on temporary repos; HOME is a temporary folder,
# so no git config, hook or state of this machine is used. Nothing here touches the
# repo this suite lives in.
# Usage: sh tests/relay-plan/run-tests.sh   (RELAY_PLAN_BIN overrides the script under test)
# Expect: "112 passed, 0 failed"
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
RP="${RELAY_PLAN_BIN:-$HERE/../../bin/relay-plan}"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

unset GIT_DIR GIT_WORK_TREE
HOME="$TMP_ROOT/home"
GIT_CONFIG_NOSYSTEM=1
GIT_AUTHOR_NAME=t
GIT_AUTHOR_EMAIL=t@example.invalid
GIT_COMMITTER_NAME=t
GIT_COMMITTER_EMAIL=t@example.invalid
GIT_CEILING_DIRECTORIES="$TMP_ROOT"
export HOME GIT_CONFIG_NOSYSTEM GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_CEILING_DIRECTORIES
mkdir -p "$HOME"

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

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
