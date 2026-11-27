#!/bin/sh
# Keeps every skills/*/SKILL.md under 20,000 bytes. After a compaction, Claude Code
# re-attaches each invoked skill cut at about 20,000 characters; bytes are stricter than
# characters, so a file under the limit in bytes is safe under any locale.
# skills/brainstorming/SKILL.md is excepted until card cf93197f trims it; its size is
# printed on every run, so the exception stays visible.
# Usage: sh tests/skill-size/run-tests.sh      Expect: "12 passed, 0 failed"
set -u
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0
LIMIT=20000
EXCEPTION=skills/brainstorming/SKILL.md
EXCEPTION_CARD=cf93197f

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

# skill_sizes <top>: prints each offender (and the exception's size), exits 1 when it
# printed an offender or found no SKILL.md.
skill_sizes() (
    cd "$1" || exit 2
    found=0
    rc=0
    for f in skills/*/SKILL.md; do
        [ -f "$f" ] || continue
        found=1
        size=$(wc -c < "$f" | tr -d ' ')
        if [ "$f" = "$EXCEPTION" ]; then
            echo "$f is $size bytes: excepted until card $EXCEPTION_CARD trims it"
        elif [ "$size" -ge "$LIMIT" ]; then
            echo "$f is $size bytes (limit: under $LIMIT)"
            rc=1
        fi
    done
    if [ "$found" -eq 0 ]; then
        echo "no skills/*/SKILL.md under $1"
        rc=1
    fi
    exit "$rc"
)

case_tree() {
    CASE=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    mkdir -p "$CASE/skills"
}

# skill_file <top> <path> <count> [<char>]: <count> copies of <char>, nothing else.
skill_file() {
    mkdir -p "$(dirname -- "$1/$2")"
    c=${4:-a}
    : > "$1/$2"
    n=0
    while [ "$n" -lt "$3" ]; do
        printf '%s' "$c"
        n=$((n + 1))
    done > "$1/$2"
}

# run <top>: sets OUT and RC.
run() {
    OUT=$(skill_sizes "$1" 2>&1)
    RC=$?
}

assert_rc() { # name expected
    if [ "$RC" -eq "$2" ]; then ok "$1"; else bad "$1" "expected exit $2, got $RC: $OUT"; fi
}
assert_contains() { # name needle
    case $OUT in
        *"$2"*) ok "$1" ;;
        *) bad "$1" "[$2] not in [$OUT]" ;;
    esac
}

# 1
run "$REPO"
if [ "$RC" -eq 0 ]; then
    ok "the repo's skills"
    printf '%s\n' "$OUT" | sed 's/^/       /'
else
    bad "the repo's skills" "$OUT"
fi

# 2
case_tree; skill_file "$CASE" skills/small/SKILL.md 19999
run "$CASE"; assert_rc "19,999 bytes passes" 0

# 3, 4
case_tree; skill_file "$CASE" skills/big/SKILL.md 20000
run "$CASE"; assert_rc "20,000 bytes fails" 1
assert_contains "20,000 bytes: named" "skills/big/SKILL.md is 20000 bytes (limit: under 20000)"

# 5, 6
case_tree; skill_file "$CASE" skills/brainstorming/SKILL.md 24202
run "$CASE"; assert_rc "brainstorming is excepted" 0
assert_contains "the exception shows its size" "skills/brainstorming/SKILL.md is 24202 bytes: excepted until card cf93197f trims it"

# 7
case_tree; skill_file "$CASE" skills/brainstorming-notes/SKILL.md 20000
run "$CASE"
case $OUT in
    *"skills/brainstorming-notes/SKILL.md is 20000 bytes"*)
        if [ "$RC" -eq 1 ]; then ok "the exception is one file"; else bad "the exception is one file" "expected exit 1, got $RC: $OUT"; fi ;;
    *) bad "the exception is one file" "not named: $OUT" ;;
esac

# 8
case_tree
skill_file "$CASE" skills/small/SKILL.md 100
skill_file "$CASE" skills/small/references/big.md 30000
skill_file "$CASE" skills/small/scripts/big.sh 30000
run "$CASE"; assert_rc "only SKILL.md counts" 0

# 9, 10
case_tree; skill_file "$CASE" skills/accents/SKILL.md 10000 é
run "$CASE"; assert_rc "bytes, not characters" 1
assert_contains "bytes, not characters: named" "skills/accents/SKILL.md is 20000 bytes"

# 11
case_tree
skill_file "$CASE" skills/a/SKILL.md 20000
skill_file "$CASE" skills/b/SKILL.md 21000
skill_file "$CASE" skills/c/SKILL.md 100
run "$CASE"
case $OUT in
    *"skills/a/SKILL.md is 20000 bytes"*"skills/b/SKILL.md is 21000 bytes"*)
        case $OUT in
            *skills/c/*) bad "every offender named" "skills/c/ named: $OUT" ;;
            *) ok "every offender named" ;;
        esac ;;
    *) bad "every offender named" "[$OUT]" ;;
esac

# 12
case_tree; skill_file "$CASE" skills/notes/README.md 100
run "$CASE"
case $OUT in
    *"no skills/*/SKILL.md under"*)
        if [ "$RC" -eq 1 ]; then ok "no SKILL.md fails"; else bad "no SKILL.md fails" "expected exit 1, got $RC: $OUT"; fi ;;
    *) bad "no SKILL.md fails" "not named: $OUT" ;;
esac

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
