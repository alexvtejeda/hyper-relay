#!/bin/sh
# Usage: add-card-line.sh <doc-path> <card-id> [<card-id>...]
#
# Writes the line from `quartz card-line` into the doc's header: the lines before
# the first `---` or `## `. It replaces an existing **Card:** or **Cards:** line
# there, otherwise it inserts after **Date:**, otherwise after the first `# ` heading.
# On any failure the doc is unchanged.
#
# POSIX shell, run by dash. The line can hold any character, so it reaches awk only
# through ENVIRON, which does no escape processing, and never through echo, sed or -v.
set -u

fail() {
    printf 'add-card-line: %s\n' "$1" >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    printf 'usage: add-card-line.sh <doc-path> <card-id> [<card-id>...]\n' >&2
    exit 2
fi

doc=$1
shift
# A leading ./ stops awk reading a name like a=b.md as a variable assignment.
case $doc in
    /*) ;;
    *) doc=./$doc ;;
esac

# Renaming over a symlink or a read-only file would change what they protect.
if [ -L "$doc" ] || [ ! -f "$doc" ]; then
    fail "$doc: not a regular file"
fi
if [ ! -r "$doc" ] || [ ! -w "$doc" ]; then
    fail "$doc: needs read and write permission"
fi
if ! command -v quartz >/dev/null 2>&1; then
    fail "quartz is not installed or not on PATH (go install from cli/ in the Quartz repo); $doc unchanged"
fi

dir=$(dirname "$doc") || fail "$doc: cannot find its directory"

# quartz finds its configuration from the working directory's git repo, and that
# must be the doc's repo, not wherever the caller happens to be.
line=$(cd "$dir" && quartz card-line "$@") || fail "quartz card-line failed; $doc unchanged"

nl='
'
case $line in
    *"$nl"*) fail "quartz card-line printed more than one line; $doc unchanged" ;;
    '**Card:** '* | '**Cards:** '*) ;;
    *) fail "quartz card-line printed no card line; $doc unchanged" ;;
esac

header_end=$(LC_ALL=C awk '
    /^---[ \t\r]*$/ || /^## / { print NR - 1; found = 1; exit }
    END { if (!found) print NR }
' "$doc") || fail "$doc: cannot read its header"

tmp=
trap 'if [ -n "$tmp" ]; then rm -f "$tmp"; fi' EXIT
trap 'exit 1' HUP INT TERM

tmp=$(mktemp "$dir/.add-card-line.XXXXXX") || fail "cannot create a temp file in $dir; $doc unchanged"
# Copies the mode onto the temp file. The writes below truncate it and keep the mode.
cp -p "$doc" "$tmp" || fail "cannot copy $doc; $doc unchanged"

# The header goes through awk. The rest is copied by tail, so it stays byte-identical.
CARD_LINE=$line LC_ALL=C awk -v last="$header_end" '
    NR > last { exit }
    { h[NR] = $0 }
    !card && /^\*\*Cards?:\*\*/ { card = NR }
    !date && /^\*\*Date:\*\*/ { date = NR }
    !heading && /^# / { heading = NR }
    END {
        at = card ? card : (date ? date : heading)
        if (!at) exit 3
        for (i = 1; i <= last; i++) {
            if (h[i] !~ /^\*\*Cards?:\*\*/) print h[i]
            if (i == at) print ENVIRON["CARD_LINE"]
        }
    }
' "$doc" > "$tmp"
case $? in
    0) ;;
    3) fail "$doc: its header has no **Date:** line and no # heading; $doc unchanged" ;;
    *) fail "cannot rewrite the header of $doc; $doc unchanged" ;;
esac

tail -n +"$((header_end + 1))" "$doc" >> "$tmp" || fail "cannot copy the body of $doc; $doc unchanged"
mv -f "$tmp" "$doc" || fail "cannot replace $doc; $doc unchanged"
tmp=
