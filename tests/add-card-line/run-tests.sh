#!/bin/sh
# POSIX tests for add-card-line.sh. A fake `quartz` goes first on PATH, so these need
# neither the real CLI nor a running Quartz.
# Usage: sh run-tests.sh   (ADD_CARD_LINE_BIN overrides the script under test)
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
BIN="${ADD_CARD_LINE_BIN:-$HERE/../../skills/brainstorming/scripts/add-card-line.sh}"
DASH=$(command -v dash)
REAL_PATH=$PATH
TMP_ROOT=$(mktemp -d)
trap 'chmod -R u+rwx "$TMP_ROOT"; rm -rf "$TMP_ROOT"' EXIT INT TERM
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

ID1=db8d5ea8-7109-4d27-9d29-bec89763c33a
ID2=3d8d0c06-0000-4000-8000-000000000002
LINE1='**Card:** First card (`'$ID1'`)'
LINE2='**Cards:** First card (`'$ID1'`), Second card (`'$ID2'`)'
# Everything that could trip sed, awk, printf, echo or the shell.
NASTY='**Card:** a/b & c \1 \n \\ `tick` $HOME "dq" '"'"'sq'"'"' %s %d | * [x] (`'$ID1'`)'

FAKE_OUT=$TMP_ROOT/fake-out
FAKE_LOG=$TMP_ROOT/fake-log
export FAKE_OUT FAKE_LOG
mkdir -p "$TMP_ROOT/fakebin" "$TMP_ROOT/nothing" "$TMP_ROOT/elsewhere"
# Prints the line from a file, so a test's title meets no shell quoting on the way out.
cat > "$TMP_ROOT/fakebin/quartz" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "$PWD" "$*" >> "$FAKE_LOG"
if [ -n "${FAKE_RC:-}" ]; then
    printf 'card not found\n' >&2
    exit "$FAKE_RC"
fi
cat "$FAKE_OUT"
EOF
chmod +x "$TMP_ROOT/fakebin/quartz"
PATH=$TMP_ROOT/fakebin:$PATH

# broken_tool <name>: a directory whose <name> always fails, to go first on PATH.
broken_tool() {
    mkdir -p "$TMP_ROOT/broken-$1"
    printf '#!/bin/sh\nexit 1\n' > "$TMP_ROOT/broken-$1/$1"
    chmod +x "$TMP_ROOT/broken-$1/$1"
    printf '%s' "$TMP_ROOT/broken-$1"
}

# new_doc: fresh directory holding spec.md with stdin as its content, plus a snapshot.
new_doc() {
    DIR=$(mktemp -d "$TMP_ROOT/doc.XXXXXX")
    DOC=$DIR/spec.md
    cat > "$DOC"
    SNAP=$DIR.snap
    cp "$DOC" "$SNAP"
}
standard_doc() {
    printf '%s' "$STANDARD" > "$TMP_ROOT/standard"
    new_doc < "$TMP_ROOT/standard"
}
set_line() { printf '%s\n' "$1" > "$FAKE_OUT"; }
run() { # args for the script
    OUT=$("$DASH" "$BIN" "$@" 2>&1)
    RC=$?
}
# assert_doc <description>: the doc equals stdin, byte for byte.
assert_doc() {
    cat > "$TMP_ROOT/expected"
    if cmp -s "$TMP_ROOT/expected" "$DOC"; then
        ok "$1"
    else
        bad "$1" "$(diff "$TMP_ROOT/expected" "$DOC")"
    fi
}
# assert_failed <description>: non-zero exit, doc byte-identical, nothing left beside it.
assert_failed() {
    assert_eq "$1: exits non-zero" 1 "$RC"
    if cmp -s "$SNAP" "$DOC"; then ok "$1: doc unchanged"; else bad "$1: doc unchanged" "$(diff "$SNAP" "$DOC")"; fi
    assert_eq "$1: no temp file left" spec.md "$(ls -A "$DIR")"
}

STANDARD='# Title

**Date:** 2026-11-04
**Status:** approved
**Builds on:** other.md

---

## 1. Problem

Text.
'

# --- the script itself
if "$DASH" -n "$BIN" 2>/dev/null; then ok "dash -n passes"; else bad "dash -n passes" "syntax error or missing file: $BIN"; fi
if [ -x "$BIN" ]; then ok "script is executable"; else bad "script is executable" "$BIN"; fi

# --- inserting
set_line "$LINE1"
standard_doc
run "$DOC" "$ID1"
assert_eq "insert: exit 0" 0 "$RC"
assert_eq "insert: passes the id to quartz" "$DIR|card-line $ID1" "$(tail -n 1 "$FAKE_LOG")"
assert_doc "insert: goes straight after **Date:**" <<EOF
# Title

**Date:** 2026-11-04
$LINE1
**Status:** approved
**Builds on:** other.md

---

## 1. Problem

Text.
EOF

new_doc <<'EOF'
# Title

Intro.

## 1. Problem
EOF
run "$DOC" "$ID1"
assert_doc "insert: after the # heading when there is no date" <<EOF
# Title
$LINE1

Intro.

## 1. Problem
EOF

new_doc <<'EOF'
# Title
**Date:** 2026-11-04
EOF
run "$DOC" "$ID1"
assert_doc "insert: a doc with no --- or ## is all header" <<EOF
# Title
**Date:** 2026-11-04
$LINE1
EOF

# --- replacing
new_doc <<'EOF'
# Title

**Date:** 2026-11-04
**Status:** approved
**Card:** Old title (`3d8d0c06`)
**Builds on:** other.md

---
EOF
run "$DOC" "$ID1"
assert_doc "replace: **Card:** in place, not moved to the date" <<EOF
# Title

**Date:** 2026-11-04
**Status:** approved
$LINE1
**Builds on:** other.md

---
EOF

new_doc <<'EOF'
# Title
**Date:** 2026-11-04
**Cards:** A (`aaaaaaaa`), B (`bbbbbbbb`)

---
EOF
run "$DOC" "$ID1"
assert_doc "replace: **Cards:** becomes **Card:**" <<EOF
# Title
**Date:** 2026-11-04
$LINE1

---
EOF

set_line "$LINE2"
new_doc <<'EOF'
# Title
**Date:** 2026-11-04
**Card:** A (`aaaaaaaa`)

---
EOF
run "$DOC" "$ID1" "$ID2"
assert_eq "several: passes every id" "$DIR|card-line $ID1 $ID2" "$(tail -n 1 "$FAKE_LOG")"
assert_doc "several: **Card:** becomes **Cards:**" <<EOF
# Title
**Date:** 2026-11-04
$LINE2

---
EOF

set_line "$LINE1"
new_doc <<'EOF'
# Title
**Card:** A (`aaaaaaaa`)
**Date:** 2026-11-04
**Cards:** B (`bbbbbbbb`)

---
EOF
run "$DOC" "$ID1"
assert_doc "replace: a second card line in the header goes, so no stale card stays" <<EOF
# Title
$LINE1
**Date:** 2026-11-04

---
EOF

# --- the header boundary
new_doc <<'EOF'
# Title
**Date:** 2026-11-04

---

**Card:** Example in the body (`aaaaaaaa`)
**Cards:** Another (`bbbbbbbb`)
EOF
run "$DOC" "$ID1"
assert_doc "boundary: --- protects a body **Card:** line" <<EOF
# Title
**Date:** 2026-11-04
$LINE1

---

**Card:** Example in the body (\`aaaaaaaa\`)
**Cards:** Another (\`bbbbbbbb\`)
EOF

new_doc <<'EOF'
# Title
**Date:** 2026-11-04

## 1. Section

**Card:** Example in the body (`aaaaaaaa`)
EOF
run "$DOC" "$ID1"
assert_doc "boundary: ## protects a body **Card:** line" <<EOF
# Title
**Date:** 2026-11-04
$LINE1

## 1. Section

**Card:** Example in the body (\`aaaaaaaa\`)
EOF

new_doc <<'EOF'
# Title
**Card:** Header card (`aaaaaaaa`)

---

**Card:** Example in the body (`bbbbbbbb`)
EOF
run "$DOC" "$ID1"
assert_doc "boundary: replaces the header line and only that one" <<EOF
# Title
$LINE1

---

**Card:** Example in the body (\`bbbbbbbb\`)
EOF

printf '# Title\n**Date:** 2026-11-04\n--- \n**Card:** Body (`bbbbbbbb`)\n' > "$TMP_ROOT/spaced"
new_doc < "$TMP_ROOT/spaced"
run "$DOC" "$ID1"
assert_contains "boundary: --- with a trailing space still ends the header" '**Card:** Body (`bbbbbbbb`)' "$(cat "$DOC")"

new_doc <<'EOF'
Some text.

---

# Title in the body
**Date:** 2026-11-04
EOF
run "$DOC" "$ID1"
assert_failed "boundary: a date and heading in the body are no anchor"
assert_contains "boundary: says what is missing" "no **Date:** line and no # heading" "$OUT"

new_doc <<'EOF'
---
name: frontmatter
---
# Title
EOF
run "$DOC" "$ID1"
assert_failed "boundary: --- on line 1 leaves an empty header"

# --- titles with special characters
set_line "$NASTY"
standard_doc
run "$DOC" "$ID1"
assert_eq "special characters: insert exits 0" 0 "$RC"
assert_eq "special characters: insert is byte-exact" "$NASTY" "$(sed -n 4p "$DOC")"

new_doc <<'EOF'
# Title
**Card:** Old (`aaaaaaaa`)

---
EOF
run "$DOC" "$ID1"
assert_eq "special characters: replace is byte-exact" "$NASTY" "$(sed -n 2p "$DOC")"

# --- bytes outside the line
set_line "$LINE1"
printf '# Title\n**Date:** 2026-11-04\n\n---\n\nlast line, no newline' > "$TMP_ROOT/nonl"
new_doc < "$TMP_ROOT/nonl"
run "$DOC" "$ID1"
printf '# Title\n**Date:** 2026-11-04\n%s\n\n---\n\nlast line, no newline' "$LINE1" > "$TMP_ROOT/nonl-want"
if cmp -s "$TMP_ROOT/nonl-want" "$DOC"; then ok "body: no final newline stays that way"; else bad "body: no final newline stays that way" "$(od -c "$DOC" | tail -n 3)"; fi

# --- running twice
for line in "$LINE1" "$LINE2" "$NASTY"; do
    set_line "$line"
    standard_doc
    run "$DOC" "$ID1"
    cp "$DOC" "$TMP_ROOT/first"
    run "$DOC" "$ID1"
    if cmp -s "$TMP_ROOT/first" "$DOC"; then ok "twice: same file for [$line]"; else bad "twice: same file for [$line]" "$(diff "$TMP_ROOT/first" "$DOC")"; fi
done
set_line "$LINE1"

# --- mode
for mode in 600 640 664 755; do
    standard_doc
    chmod "$mode" "$DOC"
    run "$DOC" "$ID1"
    assert_eq "mode: $mode kept" "$mode" "$(stat -c %a "$DOC")"
done

# --- where quartz runs
standard_doc
(cd "$TMP_ROOT/elsewhere" && "$DASH" "$BIN" "$DOC" "$ID1")
assert_eq "cwd: quartz runs in the doc's directory, for an absolute path" "$DIR|card-line $ID1" "$(tail -n 1 "$FAKE_LOG")"
standard_doc
(cd "$TMP_ROOT" && "$DASH" "$BIN" "${DIR##*/}/spec.md" "$ID1")
assert_eq "cwd: quartz runs in the doc's directory, for a relative path" "$DIR|card-line $ID1" "$(tail -n 1 "$FAKE_LOG")"
if grep -qF "$LINE1" "$DOC"; then ok "cwd: relative path is written"; else bad "cwd: relative path is written" "$(cat "$DOC")"; fi

# --- awkward paths
mkdir -p "$TMP_ROOT/with space"
printf '%s' "$STANDARD" > "$TMP_ROOT/with space/a=b.md"
(cd "$TMP_ROOT/with space" && "$DASH" "$BIN" a=b.md "$ID1")
if grep -qF "$LINE1" "$TMP_ROOT/with space/a=b.md"; then ok "path: space in the directory and = in the name"; else bad "path: space in the directory and = in the name" "not written"; fi

# --- failures: quartz
standard_doc
OUT=$(PATH=$TMP_ROOT/nothing "$DASH" "$BIN" "$DOC" "$ID1" 2>&1)
RC=$?
assert_failed "quartz missing"
assert_contains "quartz missing: says so" "quartz is not installed" "$OUT"

standard_doc
FAKE_RC=3 run "$DOC" "$ID1"
assert_failed "quartz fails"
assert_contains "quartz fails: its own reason is shown" "card not found" "$OUT"
assert_contains "quartz fails: says what failed" "quartz card-line failed" "$OUT"

: > "$FAKE_OUT"
standard_doc
run "$DOC" "$ID1"
assert_failed "quartz prints nothing and exits 0"

printf '%s\n%s\n' "$LINE1" "$LINE1" > "$FAKE_OUT"
standard_doc
run "$DOC" "$ID1"
assert_failed "quartz prints two lines"

set_line 'Error: something else'
standard_doc
run "$DOC" "$ID1"
assert_failed "quartz prints something that is not a card line"
set_line "$LINE1"

# --- failures: the write
for tool in mktemp cp awk tail mv; do
    standard_doc
    broken=$(broken_tool "$tool")
    OUT=$(PATH=$broken:$PATH "$DASH" "$BIN" "$DOC" "$ID1" 2>&1)
    RC=$?
    assert_failed "$tool fails"
done

standard_doc
chmod 555 "$DIR"
run "$DOC" "$ID1"
chmod 755 "$DIR"
assert_failed "read-only directory"

# --- failures: arguments and the doc
standard_doc
run "$DOC"
assert_eq "usage: no card id exits 2" 2 "$RC"
assert_contains "usage: is printed" "usage:" "$OUT"
if cmp -s "$SNAP" "$DOC"; then ok "usage: doc unchanged"; else bad "usage: doc unchanged" "changed"; fi

run "$TMP_ROOT/no-such-file.md" "$ID1"
assert_eq "missing doc: exits 1" 1 "$RC"
assert_contains "missing doc: says so" "not a regular file" "$OUT"

standard_doc
chmod 444 "$DOC"
run "$DOC" "$ID1"
assert_failed "read-only doc"
assert_eq "read-only doc: mode kept" 444 "$(stat -c %a "$DOC")"

standard_doc
ln -s "$DOC" "$DIR/link.md"
run "$DIR/link.md" "$ID1"
assert_eq "symlink: exits 1" 1 "$RC"
if [ -L "$DIR/link.md" ] && cmp -s "$SNAP" "$DOC"; then ok "symlink: link and target unchanged"; else bad "symlink: link and target unchanged" "changed"; fi

PATH=$REAL_PATH
printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
