#!/bin/sh
# Tests scripts/setup.sh in a sandbox: a copy of the script, with a stub python3 whose
# `-m venv` makes a stub venv whose python and pip only record their calls. It downloads
# nothing and never touches the real venv: XDG_DATA_HOME points into the sandbox.
# Run: sh tests/setup-sh.test.sh    Expect: "0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$HERE/../scripts/setup.sh"
BASH_BIN=$(command -v bash)
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
    unset STUB_WHISPER STUB_PIP_FAIL
    BOX=$(mktemp -d "$ROOT/box.XXXXXX")
    DIR="$BOX/my skill/scripts"
    XDG_DATA_HOME="$BOX/data"
    VENV="$XDG_DATA_HOME/hyper-relay/voice-to-specs/venv"
    export BOX DIR XDG_DATA_HOME VENV
    mkdir -p "$DIR" "$BOX/path"
    cp "$SCRIPT" "$DIR/setup.sh"
    : >"$BOX/calls"
    for tool in dirname mkdir chmod cp; do
        ln -s "$(command -v "$tool")" "$BOX/path/$tool"
    done

    # The venv's python: `-c "import whisper"` succeeds only when STUB_WHISPER=0.
    cat >"$BOX/python-stub" <<'EOF'
#!/bin/sh
echo "python $*" >>"$BOX/calls"
exit "${STUB_WHISPER:-1}"
EOF
    # The venv's pip: fails for the torch install when STUB_PIP_FAIL=torch.
    cat >"$BOX/pip-stub" <<'EOF'
#!/bin/sh
echo "pip $*" >>"$BOX/calls"
case "$*" in *torch*) [ "${STUB_PIP_FAIL:-}" = torch ] && exit 1 ;; esac
exit 0
EOF
    # System python3: only `-m venv <dir>`, which writes the stub venv.
    cat >"$BOX/path/python3" <<'EOF'
#!/bin/sh
[ "$1 $2" = "-m venv" ] || exit 9
echo venv >>"$BOX/calls"
mkdir -p "$3/bin"
cp "$BOX/python-stub" "$3/bin/python"
cp "$BOX/pip-stub" "$3/bin/pip"
chmod +x "$3/bin/python" "$3/bin/pip"
{ printf 'PATH="'; printf '%s' "$3/bin"; printf ':$PATH"\n'; } >"$3/bin/activate"
EOF
    chmod +x "$BOX/path/python3"
}

# run sets STATUS and CALLS.
run() {
    PATH="$BOX/path" "$BASH_BIN" "$DIR/setup.sh" >"$BOX/out" 2>"$BOX/err"
    STATUS=$?
    CALLS=$(cat "$BOX/calls")
}

NL='
'
WHISPER_CHECK="python -c import whisper"
TORCH="pip install torch --index-url https://download.pytorch.org/whl/cpu"
WHISPER="pip install openai-whisper"

# Fresh: venv created under XDG_DATA_HOME, then CPU-only torch BEFORE whisper. Whisper alone
# would pull PyPI's default CUDA torch, whose GPU check segfaults under WSL.
new_box
run
check "fresh: exit 0" 0 "$STATUS"
check "fresh: venv, check, CPU-only torch, then whisper" \
    "venv$NL$WHISPER_CHECK$NL$TORCH$NL$WHISPER" "$CALLS"
check "fresh: the venv is under XDG_DATA_HOME" yes "$([ -f "$VENV/bin/activate" ] && echo yes)"

# Whisper already installed: nothing is installed.
new_box
PATH="$BOX/path" python3 -m venv "$VENV"
: >"$BOX/calls"
STUB_WHISPER=0
export STUB_WHISPER
run
check "installed: exit 0" 0 "$STATUS"
check "installed: only the check runs" "$WHISPER_CHECK" "$CALLS"

# The torch install fails: setup stops, whisper is not installed.
new_box
STUB_PIP_FAIL=torch
export STUB_PIP_FAIL
run
check "torch fails: setup fails" 1 "$([ "$STATUS" -ne 0 ] && echo 1)"
check "torch fails: whisper is not installed" "venv$NL$WHISPER_CHECK$NL$TORCH" "$CALLS"

printf '%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
