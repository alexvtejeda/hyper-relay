#!/bin/sh
# run-usage.sh: the tokens, cost and time of one benchmark run, read from Claude Code's transcripts
# (hyper-relay G.2; docs/benchmarks/README.md is the runbook).
#   run-usage.sh <run-log>                          the run's usage table, in Markdown
#   run-usage.sh --sessions <config> <from> <to>    every session with a record in that window
# Times are UTC, written 2026-11-20T14:03:00Z. A run log's header is its "key: value" lines before its
# first "## " heading (docs/benchmarks/run-log-template.md). RUN_USAGE_PRICES names another prices file
# than prices.tsv. The reading itself is run-usage.jq. Needs jq 1.6 or later; reads transcripts and
# writes nothing but a temporary folder. POSIX shell, run by dash.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
PRICES=${RUN_USAGE_PRICES:-$HERE/prices.tsv}
PROG=$HERE/run-usage.jq
USAGE='usage: run-usage.sh <run-log> | run-usage.sh --sessions <config folder> <from> <to>'

die() { printf 'run-usage: %s\n' "$*" >&2; exit 1; }

command -v jq > /dev/null 2>&1 || die "needs jq"
[ -f "$PROG" ] || die "no $PROG"

# is_time <value>: true for a UTC time written 2026-11-20T14:03:00Z.
is_time() {
    case $1 in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) return 0 ;;
    esac
    return 1
}

# expand_home <path>: a leading ~/ becomes the home folder.
expand_home() {
    case $1 in
        "~/"*) printf '%s/%s\n' "$HOME" "${1#"~/"}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

if [ "${1:-}" = --sessions ]; then
    [ $# -eq 4 ] || die "$USAGE"
    CONFIG=$(expand_home "$2")
    FROM=$3
    TO=$4
    is_time "$FROM" || die "not a UTC time like 2026-11-20T14:03:00Z: $FROM"
    is_time "$TO" || die "not a UTC time like 2026-11-20T14:03:00Z: $TO"
    [ -d "$CONFIG/projects" ] || die "no projects folder in $CONFIG"
    set --
    for f in "$CONFIG"/projects/*/*.jsonl; do
        if [ -f "$f" ]; then
            set -- "$@" "$f"
        fi
    done
    [ $# -gt 0 ] || die "no session transcripts under $CONFIG/projects"
    exec jq -n -r -R --arg mode sessions --arg from "$FROM" --arg to "$TO" -f "$PROG" "$@"
fi

[ $# -eq 1 ] || die "$USAGE"
LOG=$1
case $LOG in -*) die "$USAGE" ;; esac
[ -f "$LOG" ] || die "no run log at $LOG"
[ -f "$PRICES" ] || die "no prices file at $PRICES"

# field <key>: each value of the run log's "key: value" lines, before its first "## " heading.
field() {
    awk -v k="$1: " '/^## / { exit } index($0, k) == 1 { print substr($0, length(k) + 1) }' "$LOG"
}

# one <key>: the key's one value; a missing or repeated key stops the run.
one() {
    v=$(field "$1")
    [ -n "$v" ] || die "the run log has no '$1:' line"
    [ "$(printf '%s\n' "$v" | wc -l)" -eq 1 ] || die "the run log has more than one '$1:' line"
    printf '%s\n' "$v"
}

TITLE=$(awk 'NR == 1 && /^# / { sub(/^# /, ""); print }' "$LOG")
[ -n "$TITLE" ] || TITLE=$(basename "$LOG")
CONFIG_RAW=$(one config)
CONFIG=$(expand_home "$CONFIG_RAW")
START=$(one start)
SPEC_LINE=$(one spec)
PLAN_LINE=$(one plan)
MERGE_LINE=$(one merge)
SPEC_T=${SPEC_LINE##* }
PLAN_T=${PLAN_LINE##* }
MERGE_T=${MERGE_LINE##* }
for t in "$START" "$SPEC_T" "$PLAN_T" "$MERGE_T"; do
    is_time "$t" || die "not a UTC time like 2026-11-20T14:03:00Z: $t (the start, spec, plan and merge lines end with one)"
done
awk -v a="$START" -v b="$SPEC_T" -v c="$PLAN_T" -v d="$MERGE_T" 'BEGIN { exit !(a <= b && b <= c && c <= d) }' \
    || die "the times must run start <= spec <= plan <= merge"
[ -d "$CONFIG/projects" ] || die "no projects folder in $CONFIG"
SESSIONS=$(field session | awk '!seen[$0]++')
[ -n "$SESSIONS" ] || die "the run log has no 'session:' line"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

# The role table: "<extended regex> → <role>" lines.
field role > "$TMP/roles"
while IFS= read -r line; do
    case $line in
        *" → "*) ;;
        *) die "a role line needs '<regex> → <role>': $line" ;;
    esac
done < "$TMP/roles"
ROLES=$(jq -R -s -c 'split("\n") | map(select(length > 0) | split(" → ") | {re: .[0], role: (.[1:] | join(" → "))})' "$TMP/roles")

# The manifest: each session's transcript, and its subagents' with their meta files.
: > "$TMP/manifest"
set --
for id in $SESSIONS; do
    main=
    for f in "$CONFIG"/projects/*/"$id".jsonl; do
        if [ -f "$f" ]; then
            [ -z "$main" ] || die "session $id has a transcript in more than one project folder"
            main=$f
        fi
    done
    [ -n "$main" ] || die "no transcript for session $id under $CONFIG/projects"
    jq -n -c --arg file "$main" --arg id "$id" \
        '{file: $file, src: ("main:" + $id), kind: "main", session: $id}' >> "$TMP/manifest"
    set -- "$@" "$main"
    for f in "${main%.jsonl}"/subagents/agent-*.jsonl; do
        if [ -f "$f" ]; then
            agent=${f##*/agent-}
            agent=${agent%.jsonl}
            meta=${f%.jsonl}.meta.json
            if [ -f "$meta" ]; then
                jq -c --arg file "$f" --arg id "$id" --arg agent "$agent" \
                    '{file: $file, src: ("agent:" + $agent), kind: "agent", session: $id, agent: $agent,
                      type: (.agentType // "?"), desc: (.description // "?"), parent: (.parentAgentId // null)}' \
                    "$meta" >> "$TMP/manifest"
            else
                jq -n -c --arg file "$f" --arg id "$id" --arg agent "$agent" \
                    '{file: $file, src: ("agent:" + $agent), kind: "agent", session: $id, agent: $agent,
                      type: "?", desc: "?", parent: null}' >> "$TMP/manifest"
            fi
            set -- "$@" "$f"
        fi
    done
done
MAN=$(jq -s -c . "$TMP/manifest")

jq -n -r -R --arg mode report --arg title "$TITLE" --arg config "$CONFIG_RAW" \
    --arg start "$START" --arg spec "$SPEC_T" --arg plan "$PLAN_T" --arg merge "$MERGE_T" \
    --arg prices "$(cat "$PRICES")" --argjson roles "$ROLES" --argjson man "$MAN" \
    -f "$PROG" "$@"
