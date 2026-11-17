#!/bin/sh
# check-import.sh: piece A's proof that moving the skills into hyper-relay changed no
# behaviour (spec §4.1). For each of the 16 skills it copies the loose copy the skill came
# from, applies the spec §2 rename rule and voice-to-specs' venv move to that copy, and
# compares the result with skills/<skill>, files and executable bits. Any difference fails.
#
# Usage: sh scripts/check-import.sh        Expect: "16 skills match their loose copies"
#   LOOSE_SKILLS_DIR=<dir> compares against <dir> instead of ~/.claude/skills. Once the
#   loose copies are deleted (spec §3.5) there is nothing to compare, and it exits 2.
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOOSE=${LOOSE_SKILLS_DIR:-$HOME/.claude/skills}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
trap 'exit 1' INT TERM
status=0
checked=0

# <skill in skills/> <its loose copy>
SKILLS='brainstorming brainstorming
dispatching-parallel-agents dispatching-parallel-agents
executing-plans executing-plans
finishing-a-development-branch finishing-a-development-branch
receiving-code-review receiving-code-review
requesting-code-review requesting-code-review
subagent-driven-development subagent-driven-development
systematic-debugging systematic-debugging
test-driven-development test-driven-development
using-git-worktrees using-git-worktrees
using-hyper-relay using-superpowers
verification-before-completion verification-before-completion
visual-companion visual-companion
voice-to-specs voice-to-specs
writing-plans writing-plans
writing-skills writing-skills'

fail() {
    echo "check-import: $*" >&2
    status=1
}

# edit <file> <old line> <new text>: replace the one line of <file> that equals <old line>.
# awk reads both strings from the environment, so nothing in them is interpreted.
edit() {
    n=$(OLD=$2 awk '$0 == ENVIRON["OLD"] { n++ } END { print n + 0 }' "$1")
    if [ "$n" != 1 ]; then
        fail "${1#"$TMP"/}: expected exactly one line to replace, found $n: $2"
        return 0
    fi
    OLD=$2 NEW=$3 awk '$0 == ENVIRON["OLD"] { print ENVIRON["NEW"]; next } { print }' "$1" >"$TMP/edit.out"
    cat "$TMP/edit.out" >"$1"
}

# The rename rule's mechanical part, on every file under $1: the skill prefix,
# using-superpowers' new name, and prose naming the plugin. `docs/superpowers/`,
# `.superpowers/` and `~/.config/superpowers/` contain none of these strings, so they stay.
rename_rule() {
    find "$1" -type f -exec sed -i -e 's/superpowers:/hyper-relay:/g' \
        -e 's/using-superpowers/using-hyper-relay/g' -e 's/Superpowers/hyper-relay/g' {} +
}

# The rename rule's named lines: an absolute path to a skill's own files becomes
# ${CLAUDE_SKILL_DIR}, and the line also names the file relative to SKILL.md for OpenCode.
path_lines() { # <skill> <dir>
    case $1 in
    brainstorming)
        edit "$2/SKILL.md" \
            '- When the work has a Quartz card, run `~/.claude/skills/brainstorming/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.' \
            '- When the work has a Quartz card, run `${CLAUDE_SKILL_DIR}/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]` (`scripts/add-card-line.sh` beside this SKILL.md) straight after writing the spec. With no card, skip this. If the script fails, report the failure to the user and carry on: a script failure does not stop this skill.'
        ;;
    visual-companion)
        edit "$2/SKILL.md" \
            'skill'\''s directory:' \
            'skill'\''s directory (the script is `scripts/start-server.sh` beside this SKILL.md):'
        edit "$2/SKILL.md" \
            '~/.claude/skills/visual-companion/scripts/start-server.sh \' \
            '${CLAUDE_SKILL_DIR}/scripts/start-server.sh \'
        ;;
    voice-to-specs)
        edit "$2/SKILL.md" \
            'Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that.' \
            'Run this one command, with the longest Bash timeout available. Do not check the environment first and do not activate a venv: the script does that. The script is `scripts/transcribe.sh` beside this SKILL.md.'
        edit "$2/SKILL.md" \
            'sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base' \
            'sh ${CLAUDE_SKILL_DIR}/scripts/transcribe.sh <file_path> --model base'
        edit "$2/CLAUDE.md" \
            'sh ~/.claude/skills/voice-to-specs/scripts/transcribe.sh <file_path> --model base' \
            'sh scripts/transcribe.sh <file_path> --model base'
        edit "$2/CLAUDE.md" \
            '**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code loads at runtime, so an edit here is live at once, on any branch.' \
            '**Authoritative workflow:** `SKILL.md` (segmentation rules, templates, boundaries, example sessions). This file covers setup and the script interface. `SKILL.md` is what Claude Code and OpenCode load at runtime: an edit reaches Claude Code when the hyper-relay plugin updates, and OpenCode when it merges to the main checkout.'
        edit "$2/CLAUDE.md" \
            '`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses the script at `.claude/skills/voice-to-specs/scripts/transcribe.py`. Don'\''t conflate the two when editing.' \
            '`whisper-transcriptions/` also contains a standalone Python transcriber (`transcribe.py` + its own `whisperVenv/`). That predates the skill and is **not** the same code path — the skill uses `scripts/transcribe.py` in this folder. Don'\''t conflate the two when editing.'
        edit "$2/CLAUDE.md" \
            '- Markdown briefs always land in the **caller'\''s** working directory, never inside this repo. Don'\''t write transcription outputs into `.claude/skills/voice-to-specs/`.' \
            '- Markdown briefs always land in the **caller'\''s** working directory, never inside this repo. Don'\''t write transcription outputs into this skill'\''s folder.'
        ;;
    esac
}

# voice-to-specs' venv moves out of the skill (spec §2): setup.sh and transcribe.sh read
# ${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv, and the docs and test follow.
venv_lines() { # <dir>
    for f in scripts/setup.sh scripts/transcribe.sh; do
        edit "$1/$f" 'VENV_DIR="$SCRIPT_DIR/venv"' \
            'VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyper-relay/voice-to-specs/venv"'
    done
    edit "$1/CLAUDE.md" \
        'Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `scripts/venv/` with the `openai-whisper` package installed.' \
        'Nothing to run by hand: `scripts/transcribe.sh` runs `scripts/setup.sh` when the venv or whisper is missing. That creates a Python venv at `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/venv` with the `openai-whisper` package installed, outside the plugin, so that a plugin update does not delete it.'
    edit "$1/CLAUDE.md" \
        '- Python venvs under `scripts/venv/` and `whisperVenv/` are gitignored by convention — do not commit them.' \
        '- The venv lives outside the repo (see Setup). `scripts/.gitignore` still ignores a stray `scripts/venv/`, and `whisperVenv/` is gitignored by convention — do not commit either.'
    t=$1/tests/transcribe-sh.test.sh
    edit "$t" \
        '# real venv, whisper or ffmpeg, and never touches the real scripts/venv.' \
        '# real venv, whisper or ffmpeg, and never touches the real venv: XDG_DATA_HOME points into the sandbox.'
    edit "$t" '    export BOX DIR' \
        '    XDG_DATA_HOME="$BOX/data"
    VENV="$XDG_DATA_HOME/hyper-relay/voice-to-specs/venv"
    export BOX DIR XDG_DATA_HOME VENV'
    sed -i 's|\$DIR/venv|$VENV|g' "$t"
    edit "$t" \
        '    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"' \
        '    "voice-to-specs: setup.sh failed, see the output above. It needs Python 3.10+ (python3 --version)." "$ERR"

# No XDG_DATA_HOME: the venv is under $HOME/.local/share.
new_box
unset XDG_DATA_HOME
HOME="$BOX/home"
VENV="$HOME/.local/share/hyper-relay/voice-to-specs/venv"
export HOME VENV
make_venv
run x.m4a
check "no XDG_DATA_HOME: the venv under HOME/.local/share is used" "$PY [x.m4a]" "$CALLS"'
}

if [ ! -d "$LOOSE" ]; then
    echo "check-import: no loose copies at $LOOSE (deleted after spec §3.5?), nothing to compare" >&2
    exit 2
fi

# Every folder in skills/ must be one of the 16.
for d in "$ROOT"/skills/*/; do
    name=${d%/}
    name=${name##*/}
    case "
$SKILLS
" in
    *"
$name "*) ;;
    *) fail "skills/$name was not imported from a loose copy" ;;
    esac
done

while read -r name src; do
    if [ ! -d "$LOOSE/$src" ]; then
        fail "$LOOSE/$src is missing"
        continue
    fi
    if [ ! -d "$ROOT/skills/$name" ]; then
        fail "skills/$name is missing"
        continue
    fi
    work=$TMP/$name
    mkdir -p "$work"
    # The mirror's exclusions: voice-to-specs' own .git and venv, and a stray .zip.
    tar -C "$LOOSE/$src" --exclude=./.git --exclude=./scripts/venv --exclude=./.zip -cf - . |
        tar -C "$work" -xf -
    rename_rule "$work"
    path_lines "$name" "$work"
    if [ "$name" = voice-to-specs ]; then
        venv_lines "$work"
    fi
    if ! diff -r "$work" "$ROOT/skills/$name"; then
        fail "skills/$name differs from $LOOSE/$src after the rename rule and the venv move (diff above)"
    fi
    a=$(cd "$work" && find . -type f -perm -u+x | sort)
    b=$(cd "$ROOT/skills/$name" && find . -type f -perm -u+x | sort)
    if [ "$a" != "$b" ]; then
        fail "skills/$name: executable files differ from $LOOSE/$src"
    fi
    checked=$((checked + 1))
done <<EOF
$SKILLS
EOF

if [ "$status" -eq 0 ]; then
    echo "$checked skills match their loose copies"
fi
exit "$status"
