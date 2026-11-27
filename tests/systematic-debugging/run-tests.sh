#!/bin/sh
# Runs systematic-debugging's find-polluter.sh by its path (its bash shebang) on a toy
# project with a stub npm.
# Usage: sh tests/systematic-debugging/run-tests.sh      Expect: "9 passed, 0 failed"
set -u
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
SCRIPT=$REPO/skills/systematic-debugging/find-polluter.sh
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0

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

# toy_project <dir>: two test files and a stub npm that creates pollution.marker.
toy_project() {
    mkdir -p "$1/src/feature" "$1/bin"
    echo "test('top')" > "$1/src/top.test.ts"
    echo "test('nested')" > "$1/src/feature/nested.test.ts"
    printf '#!/bin/sh\ntouch pollution.marker\n' > "$1/bin/npm"
    chmod 755 "$1/bin/npm"
}

# polluter <dir> <pattern>: runs the script from <dir>; sets OUT and RC.
polluter() {
    rm -f "$1/pollution.marker"
    OUT=$(cd "$1" && PATH="$1/bin:$PATH" "$SCRIPT" pollution.marker "$2" 2>&1)
    RC=$?
}

P=$TMP_ROOT/project
toy_project "$P"

# 1
if [ -x "$SCRIPT" ]; then ok "find-polluter.sh is executable"; else bad "find-polluter.sh is executable" "$SCRIPT"; fi

# 2-5
polluter "$P" 'src/**/*.test.ts'
assert_contains "documented pattern: finds the polluter" "FOUND POLLUTER" "$OUT"
assert_eq "documented pattern: exits 1" 1 "$RC"
assert_contains "documented pattern: names the first test run" "Test: ./src/feature/nested.test.ts" "$OUT"
assert_contains "top-level and nested files" "Found 2 test files" "$OUT"

# 6
polluter "$P" './src/**/*.test.ts'
assert_contains "a ./ prefix: the same files" "Found 2 test files" "$OUT"

# 7-9
polluter "$P" 'nomatch/**/*.test.ts'
assert_contains "no match: an honest zero" "Found 0 test files" "$OUT"
assert_contains "no match: the clean path" "No polluter found" "$OUT"
assert_eq "no match: exits 0" 0 "$RC"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
