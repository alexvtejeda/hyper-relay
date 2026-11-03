#!/bin/sh
# Tests scripts/transcribe.sh in a sandbox: a copy of the script next to a stub setup.sh
# and a stub venv, with a PATH that has ffmpeg only when a case wants it. It needs no
# real venv, whisper or ffmpeg, and never touches the real scripts/venv.
# Run: sh tests/transcribe-sh.test.sh    Expect: "0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$HERE/../scripts/transcribe.sh"
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
passed=0
failed=0

check() { # description expected actual
    if [ "$2" = "$3" ]; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
    fi
}

# new_box builds one sandbox. Its directory name has a space on purpose.
new_box() {
    unset STUB_EXIT STUB_SETUP
    BOX=$(mktemp -d "$ROOT/box.XXXXXX")
    DIR="$BOX/my skill/scripts"
    export BOX DIR
    mkdir -p "$DIR" "$BOX/path" "$BOX/ffmpeg"
    cp "$SCRIPT" "$DIR/transcribe.sh"
    : >"$BOX/calls"
    for tool in sh bash dirname mkdir chmod rm cp; do
        ln -s "$(command -v "$tool")" "$BOX/path/$tool"
    done
    printf '#!/bin/sh\nexit 0\n' >"$BOX/ffmpeg/ffmpeg"
    chmod +x "$BOX/ffmpeg/ffmpeg"

    cat >"$BOX/python-stub" <<'EOF'
#!/bin/sh
printf python >>"$BOX/calls"
for arg in "$@"; do printf ' [%s]' "${arg##*/}" >>"$BOX/calls"; done
echo >>"$BOX/calls"
exit "${STUB_EXIT:-0}"
EOF
    cat >"$BOX/make-venv.sh" <<'EOF'
rm -rf "$DIR/venv"
mkdir -p "$DIR/venv/bin" "$DIR/venv/lib/python3.13/site-packages/whisper"
: >"$DIR/venv/lib/python3.13/site-packages/whisper/__init__.py"
cp "$BOX/python-stub" "$DIR/venv/bin/python"
chmod +x "$DIR/venv/bin/python"
EOF
    cat >"$DIR/setup.sh" <<'EOF'
echo setup >>"$BOX/calls"
[ "${STUB_SETUP:-ok}" = ok ] || exit 3
. "$BOX/make-venv.sh"
EOF
}

make_venv() { PATH="$BOX/path" /bin/sh "$BOX/make-venv.sh"; }

# run [--no-ffmpeg] args... sets STATUS, CALLS, ERR and ERR_LINES.
run() {
    use_path="$BOX/path:$BOX/ffmpeg"
    if [ "$1" = --no-ffmpeg ]; then
        use_path="$BOX/path"
        shift
    fi
    PATH="$use_path" /bin/sh "$DIR/transcribe.sh" "$@" >"$BOX/out" 2>"$BOX/err"
    STATUS=$?
    CALLS=$(cat "$BOX/calls")
    ERR=$(cat "$BOX/err")
    ERR_LINES=$(wc -l <"$BOX/err" | tr -d ' ')
}

NL='
'
PY="python [transcribe.py]"

# Healthy: no setup, one Python run, arguments intact.
new_box
make_venv
run "a b.m4a" --model base
check "healthy: exit 0" 0 "$STATUS"
check "healthy: only transcribe.py runs, once, with its arguments" "$PY [a b.m4a] [--model] [base]" "$CALLS"

# The exit status is transcribe.py's.
new_box
make_venv
STUB_EXIT=7
export STUB_EXIT
run x.m4a
check "transcribe.py's exit status passes through" 7 "$STATUS"

# Missing venv: setup, then transcribe.
new_box
run x.m4a
check "no venv: exit 0" 0 "$STATUS"
check "no venv: setup runs, then transcribe.py" "setup$NL$PY [x.m4a]" "$CALLS"

# Venv without whisper: setup, then transcribe.
new_box
make_venv
rm -rf "$DIR/venv/lib/python3.13/site-packages/whisper"
run x.m4a
check "no whisper: setup runs, then transcribe.py" "setup$NL$PY [x.m4a]" "$CALLS"

# Dangling venv python (the system Python moved): setup, then transcribe.
new_box
make_venv
rm "$DIR/venv/bin/python"
ln -s /nonexistent/python "$DIR/venv/bin/python"
run x.m4a
check "dangling python: setup runs, then transcribe.py" "setup$NL$PY [x.m4a]" "$CALLS"

# No ffmpeg: one message, nothing else runs.
new_box
make_venv
run --no-ffmpeg x.m4a
check "no ffmpeg: exit 1" 1 "$STATUS"
check "no ffmpeg: nothing runs" "" "$CALLS"
check "no ffmpeg: one line on stderr" 1 "$ERR_LINES"
check "no ffmpeg: the message says how to fix it" \
    "voice-to-specs: ffmpeg is not installed. Install it with: sudo apt install ffmpeg" "$ERR"

# No ffmpeg and no venv: no install before failing.
new_box
run --no-ffmpeg x.m4a
check "no ffmpeg, no venv: exit 1" 1 "$STATUS"
check "no ffmpeg, no venv: setup does not run" "" "$CALLS"

# Setup fails: one message of ours, no transcription.
new_box
STUB_SETUP=fail
export STUB_SETUP
run x.m4a
check "setup fails: exit 1" 1 "$STATUS"
check "setup fails: transcribe.py does not run" "setup" "$CALLS"
check "setup fails: one line on stderr" 1 "$ERR_LINES"
check "setup fails: the message says what to check" \
    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"

printf '%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
