#!/bin/sh
# superpowers-env.sh: builds a separate Claude Code config folder for G.2's superpowers baseline
# (docs/benchmarks/README.md, step 1). It refuses a folder that exists, and it only reads ~/.claude and
# ~/.claude.json.
#   superpowers-env.sh [<folder>]             ~/.claude-superpowers: the owner's setup without hyper-relay
#                                             or Quartz, plus upstream superpowers 5.1.0 or later
#   superpowers-env.sh --neutral [<folder>]   ~/.claude-neutral: the same with neither workflow, for the
#                                             blind review and the other headless steps
# Linked from ~/.claude, so nothing drifts: skills, agents, commands, rules, hooks, bin. Copied, then
# changed: settings.json (hyper-relay@hyper-relay and its marketplace out, `quartz hook flush` out of
# Stop and SubagentStop), CLAUDE.md (everything from "## Workflow: the relay" up to "## Code Quality"
# cut), and only the mcpServers block of ~/.claude.json. No projects/, so no auto-memory. Then, with
# CLAUDE_CONFIG_DIR set to the folder: the marketplaces and plugins the settings enable, and superpowers.
# Every check runs before the folder is created. Needs jq, and claude on PATH. POSIX shell, run by dash.
set -eu
umask 077

USAGE='usage: superpowers-env.sh [--neutral] [<folder>]'
SRC=$HOME/.claude
MIN_VERSION=5.1.0
SP_MARKETPLACE=obra/superpowers-marketplace
SP_ID=superpowers@superpowers-marketplace
OFFICIAL=claude-plugins-official
OFFICIAL_SOURCE=anthropics/claude-plugins-official

die() { printf 'superpowers-env: %s\n' "$*" >&2; exit 1; }
say() { printf 'superpowers-env: %s\n' "$*"; }

# version_ge <a> <b>: true when the dotted version a is b or later, compared number by number.
version_ge() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, x, "."); nb = split(b, y, ".")
        n = na > nb ? na : nb
        for (i = 1; i <= n; i++) {
            if (x[i] + 0 > y[i] + 0) exit 0
            if (x[i] + 0 < y[i] + 0) exit 1
        }
        exit 0
    }'
}

NEUTRAL=0
if [ "${1:-}" = --neutral ]; then
    NEUTRAL=1
    shift
fi
[ $# -le 1 ] || die "$USAGE"
case ${1:-} in -*) die "$USAGE" ;; esac
if [ $# -eq 1 ]; then
    TARGET=$1
elif [ "$NEUTRAL" -eq 1 ]; then
    TARGET=$HOME/.claude-neutral
else
    TARGET=$HOME/.claude-superpowers
fi
case $TARGET in /*) ;; *) TARGET=$(pwd)/$TARGET ;; esac

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    die "$TARGET already exists: remove it first, or name another folder"
fi
command -v jq > /dev/null 2>&1 || die "needs jq"
command -v claude > /dev/null 2>&1 || die "needs claude on PATH"
[ -f "$SRC/settings.json" ] || die "no $SRC/settings.json"
[ -f "$SRC/CLAUDE.md" ] || die "no $SRC/CLAUDE.md"
[ -f "$HOME/.claude.json" ] || die "no $HOME/.claude.json"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# CLAUDE.md without the relay's section: from "## Workflow: the relay" up to "## Code Quality".
if ! awk '
    $0 == "## Workflow: the relay" && !seen_start { cut = 1; seen_start = 1; next }
    cut && $0 == "## Code Quality" { cut = 0; seen_end = 1 }
    !cut { print }
    END { exit !(seen_start && seen_end) }
' "$SRC/CLAUDE.md" > "$WORK/CLAUDE.md"; then
    die "$SRC/CLAUDE.md has no '## Workflow: the relay' heading with '## Code Quality' after it: it changed shape, so nothing is cut by guesswork"
fi
if grep -n -e hyper-relay -e Quartz "$WORK/CLAUDE.md" >&2; then
    die "the cut CLAUDE.md still names hyper-relay or Quartz (the lines above): it changed shape, so nothing is cut by guesswork"
fi

# settings.json without hyper-relay, its marketplace, or the Quartz flush in Stop and SubagentStop.
if ! jq '
    del(.enabledPlugins["hyper-relay@hyper-relay"])
    | del(.extraKnownMarketplaces["hyper-relay"])
    | if (.hooks | type) == "object" then
        .hooks |= (with_entries(
            if .key == "Stop" or .key == "SubagentStop" then
                .value |= (map(.hooks = ((.hooks // []) | map(select((.command // "") | contains("quartz hook flush") | not))))
                           | map(select((.hooks | length) > 0)))
            else . end)
          | with_entries(select((.value | length) > 0)))
      else . end
' "$SRC/settings.json" > "$WORK/settings.json"; then
    die "cannot read $SRC/settings.json as JSON"
fi

# Only the MCP servers of ~/.claude.json: never the login, the history or the projects.
if ! jq '{mcpServers: (.mcpServers // {})}' "$HOME/.claude.json" > "$WORK/claude.json"; then
    die "cannot read $HOME/.claude.json as JSON"
fi
if jq -e '.mcpServers | keys | map(ascii_downcase) | any(contains("quartz"))' "$WORK/claude.json" > /dev/null; then
    die "the mcpServers of $HOME/.claude.json hold a Quartz server: the board must stay out of the run"
fi

# The plugins the settings enable, and the source of each one's marketplace.
jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$WORK/settings.json" > "$WORK/plugins"
: > "$WORK/marketplaces"
while IFS= read -r id; do
    market=${id##*@}
    if [ "$market" = "$OFFICIAL" ]; then
        msource=$OFFICIAL_SOURCE
    else
        msource=$(jq -r --arg m "$market" '.extraKnownMarketplaces[$m].source // empty
            | if .source == "github" then (.repo // empty) elif .source == "git" then (.url // empty) else empty end' \
            "$WORK/settings.json")
    fi
    [ -n "$msource" ] || die "no source for the marketplace $market of $id in settings.json's extraKnownMarketplaces"
    grep -q -x -F "$msource" "$WORK/marketplaces" || printf '%s\n' "$msource" >> "$WORK/marketplaces"
done < "$WORK/plugins"

# Every check passed: build the folder.
mkdir -- "$TARGET" || die "cannot create $TARGET"
for name in skills agents commands rules hooks bin; do
    if [ -e "$SRC/$name" ]; then
        ln -s -- "$SRC/$name" "$TARGET/$name"
        say "linked $name -> $SRC/$name"
    else
        say "skipped $name: there is no $SRC/$name"
    fi
done
cp -- "$WORK/settings.json" "$TARGET/settings.json"
cp -- "$WORK/CLAUDE.md" "$TARGET/CLAUDE.md"
cp -- "$WORK/claude.json" "$TARGET/.claude.json"
say "settings.json: hyper-relay@hyper-relay and its marketplace dropped, quartz hook flush out of Stop and SubagentStop"
say "CLAUDE.md: the relay's section cut"
say ".claude.json: the mcpServers block only ($(jq -r '.mcpServers | keys | join(", ")' "$TARGET/.claude.json"))"

CLAUDE_CONFIG_DIR=$TARGET
export CLAUDE_CONFIG_DIR
half_built() { die "$1 failed: $TARGET is left half-built; remove it, then run this again"; }
while IFS= read -r m; do
    say "claude plugin marketplace add $m"
    claude plugin marketplace add "$m" < /dev/null || half_built "claude plugin marketplace add $m"
done < "$WORK/marketplaces"
while IFS= read -r id; do
    say "claude plugin install $id"
    claude plugin install "$id" < /dev/null || half_built "claude plugin install $id"
done < "$WORK/plugins"

if [ "$NEUTRAL" -eq 1 ]; then
    say "built $TARGET, with neither workflow"
else
    say "claude plugin marketplace add $SP_MARKETPLACE"
    claude plugin marketplace add "$SP_MARKETPLACE" < /dev/null || half_built "claude plugin marketplace add $SP_MARKETPLACE"
    say "claude plugin install $SP_ID"
    claude plugin install "$SP_ID" < /dev/null || half_built "claude plugin install $SP_ID"
    claude plugin list --json < /dev/null > "$WORK/list.json" || half_built "claude plugin list --json"
    path=$(jq -r --arg id "$SP_ID" '[.[] | select(.id == $id) | .installPath] | first // empty' "$WORK/list.json") \
        || half_built "reading claude plugin list --json"
    [ -n "$path" ] && [ -f "$path/.claude-plugin/plugin.json" ] \
        || die "claude plugin list --json gives no installPath holding .claude-plugin/plugin.json for $SP_ID"
    version=$(jq -r '.version // empty' "$path/.claude-plugin/plugin.json")
    [ -n "$version" ] || die "$path/.claude-plugin/plugin.json has no version"
    version_ge "$version" "$MIN_VERSION" \
        || die "superpowers $version is older than $MIN_VERSION, the version hyper-relay forked from: not a fair baseline; remove $TARGET"
    say "superpowers $version, read from $path/.claude-plugin/plugin.json: record it in C.2's run log"
    say "built $TARGET"
fi
say "next (the owner): from a scratch folder, CLAUDE_CONFIG_DIR=$TARGET claude, then /login and the checks of docs/benchmarks/README.md, step 1"
