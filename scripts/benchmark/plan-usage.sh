#!/bin/sh
# plan-usage.sh: the usage of the agents that wrote one implementation plan, and the plan's shape, read from
# Claude Code's transcripts (hyper-relay; docs/benchmarks/README.md, "Measuring one plan").
#   plan-usage.sh [--config <folder>] [--no-header] <plan file>
# It finds every subagent whose transcript wrote the plan (a Write, Edit or MultiEdit of its path in the
# repo's main checkout or in a .worktrees/ copy of it) and prints a Markdown table of one row: their types,
# models, calls, tokens, final context, tool uses, active time and cost, then the plan's lines, its spec's
# lines and its code blocks' lines as test code, other code and text. The config folder is --config, else
# CLAUDE_CONFIG_DIR, else ~/.claude. RUN_USAGE_PRICES names another prices file than prices.tsv. The reading
# itself is plan-usage.jq. Needs jq 1.6 or later; reads transcripts and the plan and writes nothing but a
# temporary folder. POSIX shell, run by dash.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
PRICES=${RUN_USAGE_PRICES:-$HERE/prices.tsv}
PROG=$HERE/plan-usage.jq
USAGE='usage: plan-usage.sh [--config <folder>] [--no-header] <plan file>'

die() { printf 'plan-usage: %s\n' "$*" >&2; exit 1; }
usage() { printf '%s\n' "$USAGE" >&2; exit 1; }

# expand_home <path>: a leading ~/ becomes the home folder.
expand_home() {
    case $1 in
        "~/"*) printf '%s/%s\n' "$HOME" "${1#"~/"}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

CONFIG=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
HEADER=1
PLAN=
while [ $# -gt 0 ]; do
    case $1 in
        --config)
            [ $# -ge 2 ] || usage
            CONFIG=$2
            shift 2 ;;
        --no-header) HEADER=0; shift ;;
        -*) usage ;;
        *)
            [ -z "$PLAN" ] || usage
            PLAN=$1
            shift ;;
    esac
done
[ -n "$PLAN" ] || usage
CONFIG=$(expand_home "$CONFIG")

command -v jq > /dev/null 2>&1 || die "needs jq"
[ -f "$PROG" ] || die "no $PROG"
[ -f "$PLAN" ] || die "no plan file at $PLAN"
PDIR=$(dirname -- "$PLAN")
TOP=$(git -C "$PDIR" rev-parse --show-toplevel 2> /dev/null) || die "not in a git repo: $PLAN"
PREFIX=$(git -C "$PDIR" rev-parse --show-prefix)
RP=$PREFIX$(basename -- "$PLAN")
MAIN=$(dirname -- "$(git -C "$PDIR" rev-parse --path-format=absolute --git-common-dir)")
[ -d "$CONFIG/projects" ] || die "no projects folder in $CONFIG"
[ -f "$PRICES" ] || die "no prices file at $PRICES"

# The candidates: the subagent transcripts whose text holds the plan's repo path.
set --
for f in "$CONFIG"/projects/*/*/subagents/agent-*.jsonl; do
    if [ -f "$f" ]; then
        set -- "$@" "$f"
    fi
done
NOAGENT="no agent wrote $RP (transcripts under $CONFIG/projects)"
[ $# -gt 0 ] || die "$NOAGENT"
CAND=$(grep -l -F -e "$RP" -- "$@" || true)
[ -n "$CAND" ] || die "$NOAGENT"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

# The manifest: each candidate's agent type, from its meta file.
: > "$TMP/manifest"
set --
for f in $CAND; do
    meta=${f%.jsonl}.meta.json
    type=?
    if [ -f "$meta" ]; then
        type=$(jq -r '.agentType // "?"' "$meta" 2> /dev/null) || type=?
    fi
    jq -n -c --arg f "$f" --arg t "$type" '{($f): $t}' >> "$TMP/manifest"
    set -- "$@" "$f"
done
TYPES=$(jq -s -c 'add' "$TMP/manifest")

# plan_shape <plan file>: "<test code> <other code> <text>", the lines of the plan's code blocks by class.
plan_shape() {
    awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function title_of(l,    a, r, b, t, c, rest) {
        a = index(l, "**"); r = substr(l, a + 2); b = index(r, "**")
        t = substr(r, 1, b - 1); rest = substr(r, b + 2)
        c = index(t, ":")
        if (c) t = substr(t, c + 1)
        else sub(/^Step *[0-9]+[^A-Za-z0-9]*/, "", t)
        t = trim(t)
        if (t == "") t = trim(rest)
        return tolower(t)
    }
    function add_text(l,    n, parts, i, p) {
        stext = stext "\n" l
        if (spath != "") return
        n = split(l, parts, "`")
        for (i = 2; i < n; i += 2) {
            p = parts[i]
            if (p !~ / / && (index(p, "/") || index(p, "."))) { spath = p; return }
        }
    }
    function path_is_test(p,    n, parts, i, f) {
        n = split(p, parts, "/")
        for (i = 1; i <= n; i++)
            if (parts[i] == "tests" || parts[i] == "test" || parts[i] == "spec" || parts[i] == "__tests__") return 1
        f = parts[n]
        return (f ~ /^test_/ || f ~ /_test\./ || f ~ /\.test\./)
    }
    BEGIN { tot["test"] = 0; tot["other"] = 0; tot["text"] = 0 }
    {
        if (inb) {
            t = trim($0)
            if (t == closer) { tot[cls] += cnt; inb = 0 } else cnt++
            next
        }
        s = $0; sub(/^ +/, "", s)
        if (s ~ /^```+/) {
            match(s, /^`+/); flen = RLENGTH
            closer = ""; for (i = 0; i < flen; i++) closer = closer "`"
            info = substr(s, flen + 1); info = trim(info); sub(/[ \t].*$/, "", info); info = tolower(info)
            if (info == "" || info == "markdown" || info == "md" || info == "text" || info == "txt") cls = "text"
            else if (!step) cls = "other"
            else if ((index(title, "test") && title !~ /^(run|verify)/) || (spath != "" && path_is_test(spath))) cls = "test"
            else cls = "other"
            inb = 1; cnt = 0
            next
        }
        if (s ~ /^- \[[ xX]\] \*\*Step/) {
            step = 1; stext = ""; spath = ""
            title = title_of(s)
            add_text(s)
            next
        }
        if ($0 ~ /^#/) { step = 0; next }
        if (step) add_text($0)
    }
    END {
        if (inb) tot[cls] += cnt
        print tot["test"], tot["other"], tot["text"]
    }' "$1"
}

SHAPE=$(plan_shape "$PLAN")
PLAN_LINES=$(wc -l < "$PLAN" | tr -d ' ')
SPEC_LINES=-
SPEC_PATH=$(grep -m 1 '^\*\*Spec:\*\*' "$PLAN" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p' || true)
if [ -n "$SPEC_PATH" ] && [ -f "$TOP/$SPEC_PATH" ]; then
    SPEC_LINES=$(wc -l < "$TOP/$SPEC_PATH" | tr -d ' ')
fi
set -- $SHAPE

OUT=$(jq -n -r -R --arg plan "$(basename -- "$PLAN")" --arg rp "$RP" --arg main "$MAIN" \
    --arg config "$CONFIG" --arg pricesfile "$PRICES" --arg prices "$(cat "$PRICES")" \
    --argjson types "$TYPES" --arg planlines "$PLAN_LINES" --arg speclines "$SPEC_LINES" \
    --arg test "$1" --arg other "$2" --arg text "$3" --arg header "$HEADER" \
    -f "$PROG" $CAND) || die "could not read the transcripts"
case $OUT in
    '!!'*) die "${OUT#!!}" ;;
esac
printf '%s\n' "$OUT"
