#!/bin/sh
# POSIX tests for templates/hooks/planner-guard.py, the planner's PreToolUse guard: what it
# lets through (exit 0) and what it refuses (exit 2, with a "planner guard:" reason on stderr),
# fed the JSON Claude Code sends a PreToolUse hook. Its rules are those of the guard it was copied from.
# Usage: sh tests/hyper-relay-agents/guard-test.sh   (GUARD overrides the script under test)
# Expect: "51 passed, 0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
GUARD="${GUARD:-$HERE/../../templates/hooks/planner-guard.py}"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

json_escape() { # text
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# run_guard <tool> <input field> <value>: runs the guard in $TMP_ROOT. Sets RC and ERR.
run_guard() {
    printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$1" "$2" "$(json_escape "$3")" > "$TMP_ROOT/in.json"
    ERR=$(cd "$TMP_ROOT" && python3 "$GUARD" < "$TMP_ROOT/in.json" 2>&1 >/dev/null)
    RC=$?
}

lets() { # description tool field value
    run_guard "$2" "$3" "$4"
    if [ "$RC" = 0 ]; then ok "lets through: $1"; else bad "lets through: $1" "exit $RC: $ERR"; fi
}
stops() { # description tool field value
    run_guard "$2" "$3" "$4"
    case "$RC:$ERR" in
        "2:planner guard: "*) ok "refuses: $1" ;;
        *) bad "refuses: $1" "exit $RC: $ERR" ;;
    esac
}

PLAN=docs/superpowers/plans/2026-01-01-x.md

echo '--- Bash: read-only git, plan commits, quartz link-doc'
lets "git status" Bash command 'git status --short'
lets "git -C <path> log" Bash command 'git -C /srv/repo log --oneline -5'
lets "git --no-pager diff" Bash command 'git --no-pager diff main...HEAD'
lets "git show <branch>:<path>" Bash command 'git show main:CLAUDE.md'
lets "git grep --no-index" Bash command 'git grep --no-index -n pattern /srv'
lets "git ls-files -o" Bash command 'git ls-files -o'
lets "git diff --no-index --stat" Bash command 'git diff --no-index --stat a b'
lets "git rev-parse MERGE_HEAD" Bash command 'git rev-parse -q --verify MERGE_HEAD'
lets "bare git branch" Bash command 'git branch'
lets "git branch --show-current" Bash command 'git branch --show-current'
lets "git branch -a --contains" Bash command 'git branch -a --contains abc123'
lets "git worktree list" Bash command 'git worktree list'
lets "git add <plan>" Bash command "git add $PLAN"
lets "git commit -m ... -- <plan>" Bash command "git commit -m \"docs: a plan\" -- $PLAN"
lets "quartz link-doc <plan>" Bash command "quartz link-doc $PLAN"

echo '--- Bash: everything else'
stops "ls" Bash command 'ls /tmp'
stops "shell grep" Bash command 'grep -rn x .'
stops "&&" Bash command 'git status && rm -rf x'
stops "a pipe" Bash command 'git log | head'
stops "backticks" Bash command 'git show `id`'
stops "\$(...)" Bash command 'git show $(id)'
stops "git -c" Bash command 'git -c core.pager=less log'
stops "git push" Bash command 'git push origin main'
stops "git checkout" Bash command 'git checkout -b x'
stops "git branch <new>" Bash command 'git branch new-branch'
stops "git branch -D" Bash command 'git branch -D old'
stops "git worktree add" Bash command 'git worktree add ../x'
stops "git add <code>" Bash command 'git add src/app.go'
stops "git add -A" Bash command 'git add -A'
stops "git add <plan> <code>" Bash command "git add $PLAN src/app.go"
stops "git commit without --" Bash command 'git commit -m x'
stops "git commit -a" Bash command "git commit -a -m x -- $PLAN"
stops "git commit --amend" Bash command "git commit --amend -m x -- $PLAN"
stops "git commit <plan> <code>" Bash command "git commit -m x -- $PLAN src/app.go"
stops "git commit <spec>" Bash command 'git commit -m x -- docs/superpowers/specs/x.md'
stops "git diff --output" Bash command 'git diff --output=/tmp/x'
stops "quartz link-doc <not a plan>" Bash command 'quartz link-doc src/x.md'
stops "quartz review" Bash command 'quartz review'
stops "git with no subcommand" Bash command 'git'
stops "an empty command" Bash command ''
case $ERR in
    *"may write only /docs/superpowers/plans/*.md"*) ok "the reason restates the rules" ;;
    *) bad "the reason restates the rules" "$ERR" ;;
esac
case $ERR in
    "planner guard:"*) ok "the reason starts with planner guard:" ;;
    *) bad "the reason starts with planner guard:" "$ERR" ;;
esac

echo '--- Write, Edit, MultiEdit, NotebookEdit'
lets "Write a plan (relative)" Write file_path "$PLAN"
lets "Edit a plan (absolute)" Edit file_path "$TMP_ROOT/repo/docs/superpowers/plans/y.md"
lets "MultiEdit a plan" MultiEdit file_path "$PLAN"
stops "Write code" Write file_path 'src/x.go'
stops "Write a plan that is not .md" Write file_path 'docs/superpowers/plans/x.txt'
stops "Write a spec" Write file_path 'docs/superpowers/specs/x.md'
stops "Edit through .. out of the plans folder" Edit file_path 'docs/superpowers/plans/../../../etc/passwd.md'
stops "NotebookEdit" NotebookEdit notebook_path 'notes.ipynb'
lets "other tools (Read)" Read file_path '/etc/hostname'

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
