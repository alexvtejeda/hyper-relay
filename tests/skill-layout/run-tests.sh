#!/bin/sh
# Keeps a CREATION-LOG.md or a test-*.md out of every skill's folder. Agents read and
# grep those folders during normal work, and a pressure scenario opens with lines like
# "You must choose and act" that an agent can take as its own instructions. Such files
# live under tests/<skill>/.
# Usage: sh tests/skill-layout/run-tests.sh      Expect: "10 passed, 0 failed"
set -u
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

# no_dev_files <top>: prints each CREATION-LOG.md or test-*.md under <top>/skills/, sorted;
# exits 1 when it printed one or when <top>/skills is not a folder.
no_dev_files() (
    cd "$1" || exit 2
    if [ ! -d skills ]; then
        echo "no skills/ folder under $1"
        exit 1
    fi
    list=$(find skills -type f \( -name 'CREATION-LOG.md' -o -name 'test-*.md' \) | sort)
    [ -z "$list" ] && exit 0
    printf '%s\n' "$list" | while IFS= read -r f; do
        echo "$f is skill-development material in a skill's folder"
    done
    exit 1
)

case_tree() {
    CASE=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    mkdir -p "$CASE/skills"
}

touch_file() { # top path
    mkdir -p "$(dirname -- "$1/$2")"
    : > "$1/$2"
}

run() {
    OUT=$(no_dev_files "$1" 2>&1)
    RC=$?
}

assert_rc() { # name expected
    if [ "$RC" -eq "$2" ]; then ok "$1"; else bad "$1" "expected exit $2, got $RC: $OUT"; fi
}
assert_contains() { # name needle...
    name=$1; shift
    for needle in "$@"; do
        case $OUT in
            *"$needle"*) ;;
            *) bad "$name" "[$needle] not in [$OUT]"; return ;;
        esac
    done
    ok "$name"
}

# 1
run "$REPO"
if [ "$RC" -eq 0 ]; then ok "the repo's skills"; else bad "the repo's skills" "$OUT"; fi

# 2, 3
case_tree; touch_file "$CASE" skills/x/CREATION-LOG.md
run "$CASE"; assert_rc "CREATION-LOG.md fails" 1
assert_contains "CREATION-LOG.md: named" "skills/x/CREATION-LOG.md is skill-development material in a skill's folder"

# 4, 5
case_tree; touch_file "$CASE" skills/x/test-pressure-1.md
run "$CASE"; assert_rc "test-*.md fails" 1
assert_contains "test-*.md: named" "skills/x/test-pressure-1.md is skill-development material"

# 6
case_tree; touch_file "$CASE" skills/x/sub/deeper/test-academic.md
run "$CASE"
if [ "$RC" -eq 1 ]; then
    assert_contains "a nested test-*.md fails" "skills/x/sub/deeper/test-academic.md"
else
    bad "a nested test-*.md fails" "expected exit 1, got $RC: $OUT"
fi

# 7
case_tree
touch_file "$CASE" skills/voice-to-specs/tests/transcribe-sh.test.sh
touch_file "$CASE" skills/voice-to-specs/tests/setup-sh.test.sh
touch_file "$CASE" skills/visual-companion/scripts/test-server.cjs
touch_file "$CASE" skills/visual-companion/scripts/test-helper.cjs
touch_file "$CASE" skills/visual-companion/scripts/run-tests.sh
run "$CASE"; assert_rc "in-skill test code passes" 0

# 8
case_tree
touch_file "$CASE" skills/writing-skills/references/testing-skills-with-subagents.md
touch_file "$CASE" skills/x/my-test-notes.md
touch_file "$CASE" skills/x/CREATION-LOG.txt
touch_file "$CASE" skills/x/test-helpers.sh
run "$CASE"; assert_rc "lookalikes pass" 0

# 9
case_tree; touch_file "$CASE" skills/a/test-one.md; touch_file "$CASE" skills/b/CREATION-LOG.md
run "$CASE"; assert_contains "every file named" "skills/a/test-one.md" "skills/b/CREATION-LOG.md"

# 10
case_tree; rmdir "$CASE/skills"
run "$CASE"; assert_rc "a missing skills/ fails" 1

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
