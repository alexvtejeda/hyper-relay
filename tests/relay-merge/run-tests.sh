#!/bin/sh
# POSIX tests for relay-merge. Real git, on temporary repos: a bare origin and a main
# checkout on main that tracks it. A fake `wt` goes first on PATH, and HOME is a
# temporary folder, so no git config, hook or state of this machine is used.
# Usage: sh tests/relay-merge/run-tests.sh   (RELAY_MERGE_BIN overrides the script under test)
# Expect: "107 passed, 0 failed"
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
RM_BIN="${RELAY_MERGE_BIN:-$HERE/../../bin/relay-merge}"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

# relay-merge's settings are environment variables: none may leak in from the caller,
# which can be a relay-merge running this suite as one of its gates.
unset PUSH KEEP SKIP_TESTS RELAY_MERGE_TRAILERS XDG_STATE_HOME GIT_DIR GIT_WORK_TREE FAKE_WT_LS
HOME="$TMP_ROOT/home"
GIT_CONFIG_NOSYSTEM=1
GIT_AUTHOR_NAME=t
GIT_AUTHOR_EMAIL=t@example.invalid
GIT_COMMITTER_NAME=t
GIT_COMMITTER_EMAIL=t@example.invalid
export HOME GIT_CONFIG_NOSYSTEM GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
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

mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/wt" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_WT_LOG"
if [ "${1:-}" = ls ]; then
    if [ -n "${FAKE_WT_LS:-}" ]; then printf '%s\n' "$FAKE_WT_LS"; else echo 'no wt stacks'; fi
fi
exit 0
EOF
chmod +x "$TMP_ROOT/fakebin/wt"

# The gates of most cases. Each writes what ran to $GATE_LOG; core/check.sh prints 25
# lines and fails once core/broken exists. The docs/ and . lines are the same command.
CONF='# prefix  kind   command
core/     build  echo core-build >> "$GATE_LOG"
core/     test   echo core-test >> "$GATE_LOG"; sh core/check.sh
ui/       test   echo ui-test >> "$GATE_LOG"
docs/     test   echo "any-test $(git rev-parse HEAD)" >> "$GATE_LOG"
.         test   echo "any-test $(git rev-parse HEAD)" >> "$GATE_LOG"

    # an indented comment, after a blank line'

# new_repo [<merge.conf text>]: a bare origin and a main checkout on main that tracks
# it, with core/, ui/ and docs/ and, when given, the text as a committed merge.conf.
# Sets CASE_DIR, MAIN, ORIGIN, GATE_LOG and FAKE_WT_LOG.
new_repo() {
    CASE_DIR=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    MAIN="$CASE_DIR/proj"
    ORIGIN="$CASE_DIR/origin.git"
    GATE_LOG="$CASE_DIR/gates.log"
    FAKE_WT_LOG="$CASE_DIR/wt.log"
    export GATE_LOG FAKE_WT_LOG
    unset FAKE_WT_LS
    : > "$GATE_LOG"
    : > "$FAKE_WT_LOG"
    git init -q --bare -b main "$ORIGIN"
    git init -q -b main "$MAIN"
    mkdir -p "$MAIN/core" "$MAIN/ui" "$MAIN/docs"
    printf 'core\n' > "$MAIN/core/main.txt"
    printf 'ui\n' > "$MAIN/ui/main.txt"
    printf 'docs\n' > "$MAIN/docs/readme.txt"
    printf '/.worktrees/\n' > "$MAIN/.gitignore"
    printf '%s\n' 'i=1' 'while [ "$i" -le 25 ]; do echo "check line $i"; i=$((i + 1)); done' \
        '[ ! -e core/broken ]' > "$MAIN/core/check.sh"
    if [ $# -gt 0 ]; then
        mkdir -p "$MAIN/.hyper-relay"
        printf '%s\n' "$1" > "$MAIN/.hyper-relay/merge.conf"
    fi
    git -C "$MAIN" add .
    git -C "$MAIN" commit -q -m init
    git -C "$MAIN" remote add origin "$ORIGIN"
    git -C "$MAIN" push -q -u origin main > /dev/null 2>&1
}

# commit_in <checkout> <file> <text>: writes <file> there and commits it.
commit_in() {
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -- "$2"
    git -C "$1" commit -q -m "change $2"
}

# new_branch <branch> <file> [<text>]: a branch from main with no worktree, whose one
# commit writes <file>. The main checkout stays on main.
new_branch() {
    git -C "$MAIN" switch -q -c "$1" main
    commit_in "$MAIN" "$2" "${3:-$1}"
    git -C "$MAIN" switch -q main
}

# new_worktree <branch> <file>: the same, in a worktree under .worktrees/. Sets WT.
new_worktree() {
    WT="$MAIN/.worktrees/$(printf '%s' "$1" | tr '/' '-')"
    git -C "$MAIN" worktree add -q -b "$1" "$WT" main
    commit_in "$WT" "$2" "$1"
}

# run_rm <dir> <"NAME=value ..." or ""> [<arg>...]: relay-merge, run from <dir> with no
# terminal on stdin and the fake wt first on PATH. Sets OUT and RC.
run_rm() {
    rm_dir=$1
    rm_env=$2
    shift 2
    OUT=$(cd "$rm_dir" && env $rm_env PATH="$TMP_ROOT/fakebin:$PATH" dash "$RM_BIN" "$@" 2>&1 < /dev/null)
    RC=$?
}

sha_of() { git -C "$1" rev-parse "$2"; } # checkout rev
has_branch() { # branch: prints 0 when the main checkout has it, 1 when not
    git -C "$MAIN" show-ref --verify --quiet "refs/heads/$1"
    echo $?
}

echo '--- one branch lands'
new_repo "$CONF"
new_branch feat/ui ui/new.txt
PRE=$(sha_of "$MAIN" HEAD)
TIP=$(sha_of "$MAIN" feat/ui)
RELAY_MERGE_TRAILERS='Co-Authored-By: Someone <someone@example.invalid>
Claude-Session: https://example.invalid/session'
export RELAY_MERGE_TRAILERS
run_rm "$MAIN" "PUSH=0" feat/ui
unset RELAY_MERGE_TRAILERS
MERGE=$(sha_of "$MAIN" HEAD)
assert_eq "lands: exit 0" 0 "$RC"
assert_eq "lands: --no-ff makes a merge commit where a fast-forward would do" "$PRE $TIP" \
    "$(git -C "$MAIN" log -1 --format=%P)"
assert_eq "lands: the message names the branch" "Merge branch 'feat/ui'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "lands: RELAY_MERGE_TRAILERS end the message, as its trailers" \
    "Co-Authored-By: Someone <someone@example.invalid>
Claude-Session: https://example.invalid/session" \
    "$(git -C "$MAIN" log -1 --format='%(trailers:only,unfold)' | sed '/^$/d')"
assert_eq "lands: the branch is deleted" 1 "$(has_branch feat/ui)"
assert_eq "lands: PUSH=0 does not push" "$PRE" "$(sha_of "$ORIGIN" main)"
assert_contains "lands: says what landed" "landed: feat/ui" "$OUT"
GATES=$(cat "$GATE_LOG")
assert_contains "prefix: ui/ runs its gate" "ui-test" "$GATES"
assert_not_contains "prefix: core/ does not run for a ui/ change" "core-" "$GATES"
assert_contains "prefix: . runs, on the merged result" "any-test $MERGE" "$GATES"
assert_eq "the log: under HOME/.local/state/relay-merge, named for the repo and the branch" 1 \
    "$(ls "$HOME/.local/state/relay-merge" | grep -c '^proj-[0-9-]*-feat-ui\.log$')"

echo '--- one run per command'
new_repo "$CONF"
new_branch feat/docs docs/guide.txt
run_rm "$MAIN" "" feat/docs
assert_eq "docs/: exit 0" 0 "$RC"
assert_eq "docs/: its gate is the . gate's command, and runs once" "any-test $(sha_of "$MAIN" HEAD)" "$(cat "$GATE_LOG")"
assert_contains "no terminal: the push is not asked" "No terminal to ask on, so: no" "$OUT"
assert_eq "no terminal: not pushed" "$(sha_of "$MAIN" HEAD^1)" "$(sha_of "$ORIGIN" main)"
assert_eq "no RELAY_MERGE_TRAILERS: the message is the subject alone" "Merge branch 'feat/docs'" \
    "$(git -C "$MAIN" log -1 --format=%B)"

echo '--- build and test gates, SKIP_TESTS'
new_repo "$CONF"
new_branch feat/core core/new.txt
run_rm "$MAIN" "" feat/core
assert_eq "core/: exit 0" 0 "$RC"
assert_eq "core/: every matching gate, in the file's order" "core-build
core-test
any-test $(sha_of "$MAIN" HEAD)" "$(cat "$GATE_LOG")"

new_repo "$CONF"
new_branch feat/core core/new.txt
run_rm "$MAIN" "SKIP_TESTS=1" feat/core
assert_eq "SKIP_TESTS=1: exit 0" 0 "$RC"
assert_eq "SKIP_TESTS=1: the build gate runs, no test gate" "core-build" "$(cat "$GATE_LOG")"
assert_contains "SKIP_TESTS=1: says what it skipped" "skipped (SKIP_TESTS=1): echo core-test" "$OUT"

echo '--- a gate fails: exit 3'
new_repo "$CONF"
new_branch feat/broken core/broken
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "PUSH=1" feat/broken
assert_eq "gate fails: exit 3" 3 "$RC"
assert_eq "gate fails: the merge stays on main" "$PRE $(sha_of "$MAIN" feat/broken)" "$(git -C "$MAIN" log -1 --format=%P)"
assert_eq "gate fails: not pushed, even with PUSH=1" "$PRE" "$(sha_of "$ORIGIN" main)"
assert_eq "gate fails: the branch is kept" 0 "$(has_branch feat/broken)"
assert_contains "gate fails: the log's last line is printed" "check line 25" "$OUT"
assert_contains "gate fails: and its 20th line from the end" "check line 6" "$OUT"
assert_not_contains "gate fails: but not its 21st" "check line 5" "$OUT"
assert_not_contains "gate fails: the later gates do not run" "any-test" "$(cat "$GATE_LOG")"
assert_contains "gate fails: names where main was" "main was $(git -C "$MAIN" rev-parse --short "$PRE")" "$OUT"
assert_eq "gate fails: the main checkout is clean" "" "$(git -C "$MAIN" status --porcelain)"

echo '--- a conflict: exit 2'
new_repo "$CONF"
new_branch feat/clash core/main.txt clash
commit_in "$MAIN" core/main.txt "main moved on"
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/clash
assert_eq "conflict: exit 2" 2 "$RC"
assert_eq "conflict: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_eq "conflict: the merge is aborted" 1 "$(git -C "$MAIN" rev-parse -q --verify MERGE_HEAD > /dev/null; echo $?)"
assert_eq "conflict: the main checkout is clean" "" "$(git -C "$MAIN" status --porcelain)"
assert_eq "conflict: no gate runs" "" "$(cat "$GATE_LOG")"
assert_contains "conflict: says to resolve it on the branch" "Merge main into feat/clash" "$OUT"
assert_eq "conflict: the branch is kept" 0 "$(has_branch feat/clash)"

echo '--- several branches'
new_repo "$CONF"
new_branch feat/one ui/one.txt
new_branch feat/two docs/two.txt
run_rm "$MAIN" "" feat/one feat/two
assert_eq "several: exit 0" 0 "$RC"
assert_eq "several: they land in the order given" "Merge branch 'feat/two'
Merge branch 'feat/one'
init" "$(git -C "$MAIN" log --first-parent --format=%s)"
assert_eq "several: each is gated on its own changes" "ui-test
any-test
any-test" "$(sed 's/ .*//' "$GATE_LOG")"
assert_contains "several: says both landed" "landed: feat/one feat/two" "$OUT"

new_repo "$CONF"
new_branch feat/one ui/one.txt
new_branch feat/clash core/main.txt clash
new_branch feat/three docs/three.txt
commit_in "$MAIN" core/main.txt "main moved on"
git -C "$MAIN" push -q origin main > /dev/null 2>&1
PUSHED=$(sha_of "$ORIGIN" main)
run_rm "$MAIN" "PUSH=1" feat/one feat/clash feat/three
assert_eq "stops at the first failure: exit 2" 2 "$RC"
assert_eq "stops: the branch before it stays landed" "Merge branch 'feat/one'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "stops: the branch after it is not merged" 1 \
    "$(git -C "$MAIN" merge-base --is-ancestor feat/three HEAD; echo $?)"
assert_eq "stops: nothing is pushed" "$PUSHED" "$(sha_of "$ORIGIN" main)"
assert_eq "stops: nothing is cleaned up" 0 "$(has_branch feat/one)"
assert_contains "stops: names what landed before it" "landed before this: feat/one" "$OUT"

new_repo "$CONF"
new_branch feat/one ui/one.txt
run_rm "$MAIN" "" feat/one feat/missing
assert_eq "a refusal after a landing: exit 1" 1 "$RC"
assert_contains "a refusal after a landing: names the branch" "no branch named feat/missing" "$OUT"
assert_eq "a refusal after a landing: the earlier branch stays landed" "Merge branch 'feat/one'" \
    "$(git -C "$MAIN" log -1 --format=%s)"

echo '--- already in main'
new_repo "$CONF"
new_branch feat/old docs/old.txt
git -C "$MAIN" merge -q --no-ff --no-edit -m 'merged by hand' feat/old
git -C "$MAIN" push -q origin main > /dev/null 2>&1
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "PUSH=1" feat/old
assert_eq "already in main: exit 0" 0 "$RC"
assert_eq "already in main: no new commit" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_contains "already in main: says so" "already in main" "$OUT"
assert_eq "already in main: no gate runs" "" "$(cat "$GATE_LOG")"
assert_eq "already in main: it counts as landed, so it is cleaned up" 1 "$(has_branch feat/old)"
assert_contains "level with origin: nothing to push" "nothing to push" "$OUT"

echo '--- push'
new_repo "$CONF"
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "PUSH=1" feat/ui
assert_eq "PUSH=1: exit 0" 0 "$RC"
assert_eq "PUSH=1: origin's main is the merge" "$(sha_of "$MAIN" HEAD)" "$(sha_of "$ORIGIN" main)"

new_repo "$CONF"
new_branch feat/ui ui/new.txt
mv "$ORIGIN" "$ORIGIN.gone"
run_rm "$MAIN" "PUSH=1" feat/ui
assert_eq "a failed push: still exit 0" 0 "$RC"
assert_contains "a failed push: a warning" "warning: the push failed" "$OUT"

echo '--- worktrees and the cleanup'
new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
run_rm "$MAIN" "" feat/wt
assert_eq "worktree: exit 0" 0 "$RC"
assert_eq "worktree: removed" 1 "$([ -e "$WT" ]; echo $?)"
assert_eq "worktree: the branch is deleted" 1 "$(has_branch feat/wt)"
assert_eq "worktree: wt ls was asked about its stack" "ls" "$(cat "$FAKE_WT_LOG")"

new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
run_rm "$MAIN" "KEEP=1" feat/wt
assert_eq "KEEP=1: exit 0" 0 "$RC"
assert_eq "KEEP=1: the branch landed" "Merge branch 'feat/wt'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "KEEP=1: the worktree is kept" 0 "$([ -d "$WT" ]; echo $?)"
assert_eq "KEEP=1: the branch is kept" 0 "$(has_branch feat/wt)"

new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
git -C "$MAIN" worktree lock "$WT"
run_rm "$MAIN" "" feat/wt
assert_eq "a cleanup git refuses: still exit 0" 0 "$RC"
assert_contains "a cleanup git refuses: a warning for the worktree" "could not remove the worktree" "$OUT"
assert_contains "a cleanup git refuses: a warning for the branch" "kept the branch feat/wt" "$OUT"

echo '--- refusals: exit 1, main unchanged'
new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
PRE=$(sha_of "$MAIN" HEAD)

run_rm "$MAIN" ""
assert_eq "no branch: exit 1" 1 "$RC"
assert_contains "no branch: the usage" "usage: relay-merge <branch>" "$OUT"

run_rm "$MAIN" "" --push feat/wt
assert_eq "an option: exit 1" 1 "$RC"

run_rm "$WT" "" feat/wt
assert_eq "from a worktree: exit 1" 1 "$RC"
assert_contains "from a worktree: says where to run it" "run relay-merge from the main checkout" "$OUT"

git -C "$MAIN" switch -q -c side
run_rm "$MAIN" "" feat/wt
assert_eq "main checkout not on main: exit 1" 1 "$RC"
assert_contains "main checkout not on main: says so" "not on main" "$OUT"
git -C "$MAIN" switch -q main

run_rm "$MAIN" "" main
assert_eq "main itself: exit 1" 1 "$RC"

run_rm "$MAIN" "" feat/nope
assert_eq "no such branch: exit 1" 1 "$RC"

printf 'more\n' >> "$WT/ui/wt.txt"
run_rm "$MAIN" "" feat/wt
assert_eq "a dirty worktree: exit 1" 1 "$RC"
assert_contains "a dirty worktree: says so" "has uncommitted changes" "$OUT"
git -C "$WT" checkout -q -- ui/wt.txt

printf 'more\n' >> "$MAIN/core/main.txt"
run_rm "$MAIN" "" feat/wt
assert_eq "an uncommitted change under a watched path: exit 1" 1 "$RC"
assert_contains "an uncommitted change: the file is named" "core/main.txt" "$OUT"
git -C "$MAIN" checkout -q -- core/main.txt

FAKE_WT_LS="proj-wt-feat-wt  2 running  $WT"
export FAKE_WT_LS
run_rm "$MAIN" "" feat/wt
assert_eq "a wt stack up: exit 1" 1 "$RC"
assert_contains "a wt stack up: says to take it down" "run wt down in $WT first" "$OUT"

assert_eq "the refusals left main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_eq "the refusals ran no gate" "" "$(cat "$GATE_LOG")"

FAKE_WT_LS="proj-wt-other  1 running  $WT-other
  web              http://localhost:30104"
run_rm "$MAIN" "" feat/wt
assert_eq "another worktree's stack, on a longer path, does not block" 0 "$RC"
unset FAKE_WT_LS

new_repo "$CONF"
new_branch feat/clash core/main.txt clash
commit_in "$MAIN" core/main.txt "main moved on"
new_branch feat/ui ui/new.txt
git -C "$MAIN" merge -q --no-edit feat/clash > /dev/null 2>&1
run_rm "$MAIN" "" feat/ui
assert_eq "a merge in progress: exit 1" 1 "$RC"
assert_contains "a merge in progress: says so" "a merge is in progress" "$OUT"
git -C "$MAIN" merge --abort

new_repo "$CONF"
new_branch feat/docs docs/new.txt
printf 'untracked\n' > "$MAIN/docs/new.txt"
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/docs
assert_eq "git refuses to start the merge: exit 1" 1 "$RC"
assert_eq "git refuses to start the merge: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_contains "git refuses to start the merge: says so" "git refused to merge feat/docs" "$OUT"

echo '--- no merge.conf'
new_repo
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "no config: exit 0" 0 "$RC"
assert_contains "no config: says it lands without gates" "landed without gates" "$OUT"

new_repo
new_branch feat/ui ui/new.txt
printf 'more\n' >> "$MAIN/docs/readme.txt"
run_rm "$MAIN" "" feat/ui
assert_eq "no config: an uncommitted change anywhere refuses" 1 "$RC"

echo "--- main's committed merge.conf"
NARROW='core/ test echo core-test >> "$GATE_LOG"'
new_repo "$NARROW"
new_branch feat/ui ui/new.txt
printf 'more\n' >> "$MAIN/docs/readme.txt"
run_rm "$MAIN" "" feat/ui
assert_eq "an uncommitted change no gate watches: exit 0" 0 "$RC"
assert_contains "a change no gate matches: says so" "no gate matches its changes" "$OUT"

new_repo "$NARROW"
new_branch feat/conf .hyper-relay/merge.conf '. test exit 1'
run_rm "$MAIN" "" feat/conf
assert_eq "a branch's own merge.conf does not gate it" 0 "$RC"

new_repo "$NARROW"
new_branch feat/ui ui/new.txt
printf '%s\n' '. test exit 1' >> "$MAIN/.hyper-relay/merge.conf"
run_rm "$MAIN" "" feat/ui
assert_eq "an uncommitted merge.conf is not read" 0 "$RC"

echo '--- a bad merge.conf: exit 1, before anything changes'
new_repo 'core/ deploy echo x'
new_branch feat/ui ui/new.txt
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/ui
assert_eq "an unknown kind: exit 1" 1 "$RC"
assert_contains "an unknown kind: the line is named" ".hyper-relay/merge.conf line 1" "$OUT"
assert_eq "an unknown kind: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"

new_repo 'core/ test'
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "a line with no command: exit 1" 1 "$RC"

new_repo './core/ test echo x'
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "a prefix with a leading ./: exit 1" 1 "$RC"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
