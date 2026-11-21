#!/bin/sh
# POSIX tests for bin/hyper-relay-agents and hooks/hooks.json: the facts checks, the files it
# writes, refusing hand edits, --force, --check and the SessionStart check (--check --hook).
# Each case runs a copy of the plugin (bin, templates, and the manifest at version 1.0.0), so a
# test can change a template or the version, against a fresh git repo whose path has a space.
# Usage: sh tests/hyper-relay-agents/run-tests.sh      Expect: "173 passed, 0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(CDPATH= cd -- "$TMP_ROOT" && pwd -P)
unset CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT
GIT_CEILING_DIRECTORIES=$TMP_ROOT
export GIT_CEILING_DIRECTORIES
PASSED=0
FAILED=0
AG=.claude/agents
GD=.claude/hooks/hyper-relay-planner-guard.py
RESTART='Start a new session to use them: a running session keeps the agent definitions it loaded.'

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
assert_not_contains() { # description needle haystack
    case $3 in
        *"$2"*) bad "$1" "[$2] should not be in [$3]" ;;
        *) ok "$1" ;;
    esac
}
exists() { # path: prints yes or no
    if [ -e "$1" ]; then echo yes; else echo no; fi
}

# new_plugin: a copy of the generator, the templates and the manifest, at version 1.0.0.
# Sets PLUGIN and GEN.
new_plugin() {
    PLUGIN=$(mktemp -d "$TMP_ROOT/plugin.XXXXXX")
    mkdir -p "$PLUGIN/bin" "$PLUGIN/.claude-plugin"
    cp "$REPO/bin/hyper-relay-agents" "$PLUGIN/bin/hyper-relay-agents"
    cp -R "$REPO/templates" "$PLUGIN/templates"
    sed 's/"version": "[^"]*"/"version": "1.0.0"/' "$REPO/.claude-plugin/plugin.json" > "$PLUGIN/.claude-plugin/plugin.json"
    GEN="$PLUGIN/bin/hyper-relay-agents"
}

# A made-up repo's facts: commands reviewer, the executor's model overridden.
FACTS_OK='---
project: demo
reviewer: commands
model.executor: haiku
---
Notes for humans: the generator ignores this.

## planner/before-writing
- Before: read the demo notes.

## planner/plan-format
- Format: one extra header line.

## executor/gates
- Gates: `make check`.

## executor/setup
- Setup: nothing to install.

## reviewer/look-beyond
- Beyond: the demo screens.
'

# new_repo [facts]: a fresh repo, whose path has a space, holding a facts file. Sets R.
new_repo() {
    R="$(mktemp -d "$TMP_ROOT/case.XXXXXX")/my repo"
    git init -q -b main "$R"
    mkdir -p "$R/.hyper-relay"
    printf '%s' "${1-$FACTS_OK}" > "$R/.hyper-relay/agents.md"
}

# facts_sed <sed script>: the current repo's facts become FACTS_OK rewritten by the script.
facts_sed() {
    printf '%s' "$FACTS_OK" | sed "$1" > "$R/.hyper-relay/agents.md"
}

# facts_header <line>: the current repo's facts become FACTS_OK with one more header line, after project.
facts_header() {
    printf '%s' "$FACTS_OK" | awk -v l="$1" '{ print } $0 == "project: demo" { print l }' > "$R/.hyper-relay/agents.md"
}

# last_line: the last line of OUT.
last_line() {
    printf '%s\n' "$OUT" | tail -n 1
}

# gen <dir> [args...]: runs the generator in <dir>. Sets OUT (stdout and stderr) and RC.
gen() {
    gen_dir=$1
    shift
    OUT=$(cd "$gen_dir" && dash "$GEN" "$@" 2>&1)
    RC=$?
}

# hook_json <line>: what --check --hook prints for that line.
hook_json() {
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$1" "$1"
}

echo '--- facts problems: each stops the run with nothing written'
new_plugin
new_repo
rm "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "no facts file: exit 1" 1 "$RC"
assert_contains "no facts file: names the file" "no .hyper-relay/agents.md in $R" "$OUT"
assert_eq "no facts file: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed 's/^model.executor: haiku$/colour: red/'
gen "$R"
assert_eq "unknown header key: exit 1" 1 "$RC"
assert_contains "unknown header key: named" "unknown header key colour" "$OUT"
assert_contains "unknown header key: the keys are listed, execute among them" "(the keys are project, reviewer, execute, fix-rounds, model.planner, model.executor and model.reviewer)" "$OUT"
assert_eq "unknown header key: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed 's/^project: demo$/project: Demo_Project/'
gen "$R"
assert_eq "bad project: exit 1" 1 "$RC"
assert_contains "bad project: named" 'project "Demo_Project" must be lowercase letters, digits and -' "$OUT"
assert_eq "bad project: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed 's/^reviewer: commands$/reviewer: clicks/'
gen "$R"
assert_eq "bad reviewer kind: exit 1" 1 "$RC"
assert_contains "bad reviewer kind: named" 'reviewer must be browser or commands, not "clicks"' "$OUT"
assert_eq "bad reviewer kind: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed '/^## executor\/gates$/,/^- Gates/d'
gen "$R"
assert_eq "missing required slot: exit 1" 1 "$RC"
assert_contains "missing required slot: named" "section ## executor/gates is required" "$OUT"
assert_eq "missing required slot: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed 's/^## planner\/before-writing$/## planner\/befor-writing/'
gen "$R"
assert_eq "section matching no slot: exit 1" 1 "$RC"
assert_contains "section matching no slot: named" "section ## planner/befor-writing matches no slot in the templates; is it a typo?" "$OUT"
assert_eq "section matching no slot: nothing written" no "$(exists "$R/.claude")"

new_repo
facts_sed 's/^model.executor: haiku$/model.executor: two words/'
gen "$R"
assert_contains "bad model: named" 'model.executor "two words" is not a model name' "$OUT"

new_repo
facts_sed '1d'
gen "$R"
assert_contains "no header: named" "must start with a --- line" "$OUT"

new_repo
facts_sed 's/^model.executor: haiku$/colour: red/; s/^reviewer: commands$/reviewer: clicks/'
gen "$R"
assert_contains "every problem is listed: the key" "unknown header key colour" "$OUT"
assert_contains "every problem is listed: the kind" 'not "clicks"' "$OUT"
assert_contains "every problem is listed: the count" "2 problems in .hyper-relay/agents.md; nothing was written" "$OUT"
assert_eq "every problem is listed: nothing written" no "$(exists "$R/.claude")"

echo '--- writing, refusing, --force'
new_plugin
new_repo
gen "$R"
assert_eq "first run: exit 0" 0 "$RC"
assert_contains "first run: planner written" "written $AG/demo-planner.md" "$OUT"
assert_contains "first run: executor written" "written $AG/demo-executor.md" "$OUT"
assert_contains "first run: reviewer written" "written $AG/demo-reviewer.md" "$OUT"
assert_contains "first run: guard written" "written $GD" "$OUT"
assert_eq "first run: wrote agents, so the restart line ends the output" "$RESTART" "$(last_line)"
assert_eq "first run: the restart line, once" 1 "$(printf '%s\n' "$OUT" | grep -c 'Start a new session')"
assert_eq "the guard copy is executable" yes "$(if [ -x "$R/$GD" ]; then echo yes; else echo no; fi)"

P=$(cat "$R/$AG/demo-planner.md")
assert_contains "planner: name" "name: demo-planner" "$P"
assert_contains "planner: default model" "model: opus" "$P"
assert_contains "planner: a facts section in its slot" "- Before: read the demo notes." "$P"
assert_contains "planner: {{root}} is the main checkout" "git -C $R branch --show-current" "$P"
assert_contains "planner: the guard hook blocks on failure" "onFailure: block" "$P"
assert_not_contains "planner: no placeholder left" "{{" "$P"
assert_eq "planner: the marker is the first line after the front matter" \
    "<!-- generated by hyper-relay-agents 1.0.0 from .hyper-relay/agents.md;" \
    "$(awk '$0 == "---" && ++n == 2 { getline; sub(/ edit that file.*/, ""); print; exit }' "$R/$AG/demo-planner.md")"

X=$(cat "$R/$AG/demo-executor.md")
assert_contains "executor: the model from the facts header" "model: haiku" "$X"
assert_contains "executor: the required gates" "- Gates: \`make check\`." "$X"
assert_not_contains "executor: no placeholder left" "{{" "$X"

V=$(cat "$R/$AG/demo-reviewer.md")
assert_contains "reviewer: the commands kind" "# demo reviewer (acceptance)" "$V"
assert_contains "reviewer: default model" "model: sonnet" "$V"
assert_contains "reviewer: its look-beyond facts" "- Beyond: the demo screens." "$V"
assert_not_contains "reviewer: a heading left empty is dropped" "## Seed facts" "$V"
assert_contains "reviewer: a heading with content stays" "## Look beyond the checklist" "$V"
assert_not_contains "reviewer: no placeholder left" "{{" "$V"
assert_contains "guard: the marker on line 2" "# generated by hyper-relay-agents 1.0.0" "$(sed -n 2p "$R/$GD")"

# The planner's hook command, run the way Claude Code runs it (sh -c, CLAUDE_PROJECT_DIR set),
# finds the guard copy: it refuses ls and lets git status through.
CMD=$(sed -n "s/^ *command: '\\(.*\\)'\$/\\1/p" "$R/$AG/demo-planner.md")
assert_eq "planner: the hook command" '"${CLAUDE_PROJECT_DIR}"/.claude/hooks/hyper-relay-planner-guard.py' "$CMD"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls"}}' > "$TMP_ROOT/ls.json"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git status"}}' > "$TMP_ROOT/status.json"
HERR=$(cd / && CLAUDE_PROJECT_DIR="$R" sh -c "$CMD" < "$TMP_ROOT/ls.json" 2>&1 >/dev/null)
assert_eq "hook command: refuses ls through the copy" 2 "$?"
assert_contains "hook command: the copy's reason" 'planner guard: `ls` is not allowed' "$HERR"
(cd / && CLAUDE_PROJECT_DIR="$R" sh -c "$CMD" < "$TMP_ROOT/status.json" >/dev/null 2>&1)
assert_eq "hook command: lets git status through" 0 "$?"

SUM=$(cat "$R/$AG/demo-planner.md" "$R/$AG/demo-executor.md" "$R/$AG/demo-reviewer.md" "$R/$GD" | sha256sum)
gen "$R"
assert_eq "second run: exit 0" 0 "$RC"
assert_eq "second run: all four unchanged" 4 "$(printf '%s\n' "$OUT" | grep -c '^unchanged ')"
assert_not_contains "second run: wrote nothing, so no restart line" "Start a new session" "$OUT"
assert_eq "second run: the files are identical" "$SUM" \
    "$(cat "$R/$AG/demo-planner.md" "$R/$AG/demo-executor.md" "$R/$AG/demo-reviewer.md" "$R/$GD" | sha256sum)"

printf '%s\n' '- Beyond: also the logs.' >> "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "facts change: exit 0" 0 "$RC"
assert_contains "facts change: the reviewer is rewritten" "written $AG/demo-reviewer.md" "$OUT"
assert_contains "facts change: the planner is not" "unchanged $AG/demo-planner.md" "$OUT"
assert_contains "facts change: the new line is in" "- Beyond: also the logs." "$(cat "$R/$AG/demo-reviewer.md")"
assert_eq "facts change: wrote an agent, so the restart line ends the output" "$RESTART" "$(last_line)"

printf '%s\n' '- A lesson typed into the agent.' >> "$R/$AG/demo-planner.md"
gen "$R"
assert_eq "hand edit: exit 1" 1 "$RC"
assert_contains "hand edit: refused" "refused $AG/demo-planner.md: edited by hand" "$OUT"
assert_contains "hand edit: names the facts section" 'under "## Report (concise)" probably belongs in .hyper-relay/agents.md, section ## planner/report' "$OUT"
assert_contains "hand edit: the edit is kept" "- A lesson typed into the agent." "$(cat "$R/$AG/demo-planner.md")"
assert_contains "hand edit: the other files still run" "unchanged $AG/demo-executor.md" "$OUT"

awk '{ print } $0 == "## Full gates (once, at the end)" { print "- Hand-added." }' "$R/$AG/demo-executor.md" > "$TMP_ROOT/x.md"
cp "$TMP_ROOT/x.md" "$R/$AG/demo-executor.md"
gen "$R"
assert_contains "hand edit mid-file: names that heading's section" 'under "## Full gates (once, at the end)" probably belongs in .hyper-relay/agents.md, section ## executor/gates' "$OUT"

sed -i 's/^model: sonnet$/model: opus/' "$R/$AG/demo-reviewer.md"
gen "$R"
assert_contains "hand edit above the first heading: points at the header" "a model belongs in the facts header (model.reviewer)" "$OUT"

gen "$R" --force
assert_eq "--force: exit 0" 0 "$RC"
assert_contains "--force: replaces the hand-edited planner" "written $AG/demo-planner.md (--force: replaced a hand-edited file)" "$OUT"
assert_not_contains "--force: the hand edit is gone" "- A lesson typed into the agent." "$(cat "$R/$AG/demo-planner.md")"
assert_eq "--force: wrote agents, so the restart line ends the output" "$RESTART" "$(last_line)"
gen "$R"
assert_eq "after --force: a plain run is clean" 0 "$RC"
assert_not_contains "after --force: wrote nothing, so no restart line" "Start a new session" "$OUT"

printf '%s\n' '# a local tweak' >> "$R/$GD"
gen "$R"
assert_contains "edited guard: refused, pointing at the template" "refused $GD: edited by hand; the guard comes from hyper-relay's templates/hooks/planner-guard.py" "$OUT"
gen "$R" --force
assert_contains "--force over the edited guard: the guard is written" "written $GD (--force: replaced a hand-edited file)" "$OUT"
assert_not_contains "only the guard was written: no restart line" "Start a new session" "$OUT"

echo '--- a hand-written agent (no marker)'
new_repo
mkdir -p "$R/$AG"
printf '%s\n' '---' 'name: demo-executor' 'description: written by hand' '---' '' 'Hand-written.' > "$R/$AG/demo-executor.md"
gen "$R"
assert_eq "hand-written: exit 1" 1 "$RC"
assert_contains "hand-written: refused" "refused $AG/demo-executor.md: no hyper-relay-agents marker" "$OUT"
assert_contains "hand-written: the others are written" "written $AG/demo-planner.md" "$OUT"
assert_eq "hand-written: the others were written, so the restart line ends the output" "$RESTART" "$(last_line)"
assert_eq "hand-written: kept" "Hand-written." "$(sed -n 6p "$R/$AG/demo-executor.md")"
gen "$R" --force
assert_eq "--force over a hand-written file: exit 0" 0 "$RC"
assert_contains "--force over a hand-written file: written" "written $AG/demo-executor.md (--force: replaced a hand-written file)" "$OUT"
assert_contains "--force over a hand-written file: now generated" "# demo executor" "$(cat "$R/$AG/demo-executor.md")"

echo '--- a worktree'
new_plugin
new_repo
git -C "$R" add .hyper-relay/agents.md
git -C "$R" -c user.email=t@example.invalid -c user.name=t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -q -m facts
WTD="$(dirname "$R")/wt"
git -C "$R" worktree add -q -b wt-test "$WTD"
gen "$WTD"
assert_eq "worktree: exit 0" 0 "$RC"
assert_contains "worktree: {{root}} is still the main checkout" "git -C $R branch --show-current" "$(cat "$WTD/$AG/demo-planner.md")"
assert_eq "worktree: nothing written into the main checkout" no "$(exists "$R/.claude")"

echo '--- the browser reviewer'
new_plugin
new_repo
facts_sed 's/^reviewer: commands$/reviewer: browser/'
printf '%s\n' '' '## reviewer/seed-facts' '- Seed: admin / secret.' >> "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "browser kind: exit 0" 0 "$RC"
B=$(cat "$R/$AG/demo-reviewer.md")
assert_contains "browser kind: the click-through template" "# demo reviewer (click-through)" "$B"
assert_contains "browser kind: seed facts under their heading" "## Seed facts
- Seed: admin / secret." "$B"
assert_not_contains "browser kind: an empty gotchas heading is dropped" "## Gotchas that look like bugs" "$B"
assert_contains "browser kind: the helpers' own lines stay" "- **360 px:**" "$B"
assert_not_contains "browser kind: no placeholder left" "{{" "$B"

echo '--- the execute key'
new_plugin
new_repo
facts_header 'execute: branch'
gen "$R"
assert_eq "execute: branch is accepted" 0 "$RC"
new_repo
facts_header 'execute: worktree'
gen "$R"
assert_eq "execute: worktree is accepted" 0 "$RC"
new_repo
facts_header 'execute: solo'
gen "$R"
assert_eq "execute: another value: exit 1" 1 "$RC"
assert_contains "execute: another value: named" 'execute must be branch or worktree, not "solo"' "$OUT"
assert_eq "execute: another value: nothing written" no "$(exists "$R/.claude")"

echo '--- the fix-rounds key'
new_plugin
new_repo
gen "$R"
FRC="$TMP_ROOT/fr-copy"
mkdir -p "$FRC"
for f in "$AG/demo-planner.md" "$AG/demo-executor.md" "$AG/demo-reviewer.md" "$GD"; do cp "$R/$f" "$FRC/$(basename "$f")"; done
facts_header 'fix-rounds: 3'
gen "$R"
assert_eq "fix-rounds: 3 is accepted" 0 "$RC"
assert_eq "fix-rounds: nothing is rewritten" "unchanged .claude/agents/demo-planner.md
unchanged .claude/agents/demo-executor.md
unchanged .claude/agents/demo-reviewer.md
unchanged .claude/hooks/hyper-relay-planner-guard.py" "$OUT"
for f in "$AG/demo-planner.md" "$AG/demo-executor.md" "$AG/demo-reviewer.md" "$GD"; do
    assert_eq "fix-rounds: $f is the same, byte for byte" yes "$(if cmp -s "$FRC/$(basename "$f")" "$R/$f"; then echo yes; else echo no; fi)"
done
for v in 1 9; do
    new_repo
    facts_header "fix-rounds: $v"
    gen "$R"
    assert_eq "fix-rounds: $v is accepted" 0 "$RC"
done
for v in 0 10 two ''; do
    new_repo
    facts_header "fix-rounds: $v"
    gen "$R"
    assert_eq "fix-rounds: \"$v\" is refused: exit 1" 1 "$RC"
    assert_contains "fix-rounds: \"$v\" is refused: the message" "fix-rounds must be a whole number from 1 to 9" "$OUT"
    assert_eq "fix-rounds: \"$v\" is refused: nothing written" no "$(exists "$R/.claude")"
done

echo '--- the acceptance slots'
new_repo
printf '%s\n' '' '## executor/acceptance' '- Start the stack.' >> "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "the old executor/acceptance: exit 1" 1 "$RC"
assert_contains "the old executor/acceptance: matches no slot" "section ## executor/acceptance matches no slot in the templates" "$OUT"

new_repo
printf '%s\n' '' '## executor/acceptance-worktree' '- Worktree: run the stack.' '' '## executor/acceptance-branch' '- Branch: restart the dev server.' >> "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "both acceptance slots: exit 0" 0 "$RC"
X=$(cat "$R/$AG/demo-executor.md")
assert_contains "both: the worktree facts under their heading" "### In a worktree
- Worktree: run the stack." "$X"
assert_contains "both: the branch facts under their heading" "### On a branch
- Branch: restart the dev server." "$X"
assert_contains "both: ## Acceptance stays" "## Acceptance" "$X"

new_repo
printf '%s\n' '' '## executor/acceptance-worktree' '- Worktree: run the stack.' >> "$R/.hyper-relay/agents.md"
gen "$R"
X=$(cat "$R/$AG/demo-executor.md")
assert_contains "worktree facts only: their heading stays" "### In a worktree" "$X"
assert_not_contains "worktree facts only: no empty On a branch" "### On a branch" "$X"

new_repo
printf '%s\n' '' '## executor/acceptance-branch' '- Branch: restart the dev server.' >> "$R/.hyper-relay/agents.md"
gen "$R"
X=$(cat "$R/$AG/demo-executor.md")
assert_contains "branch facts only: their heading stays" "### On a branch" "$X"
assert_not_contains "branch facts only: no empty In a worktree" "### In a worktree" "$X"
assert_contains "branch facts only: ## Acceptance stays" "## Acceptance" "$X"

new_repo
gen "$R"
X=$(cat "$R/$AG/demo-executor.md")
assert_not_contains "no acceptance facts: no ## Acceptance" "## Acceptance" "$X"
assert_not_contains "no acceptance facts: no ### heading" "### " "$X"

echo "--- hyper-relay's own facts file"
new_repo
cp "$REPO/.hyper-relay/agents.md" "$R/.hyper-relay/agents.md"
gen "$R"
assert_eq "hyper-relay's facts: exit 0" 0 "$RC"
assert_contains "hyper-relay's facts: its executor is written" "written $AG/relay-executor.md" "$OUT"
gen "$R" --check
assert_eq "hyper-relay's facts: --check after generating: exit 0" 0 "$RC"
assert_eq "hyper-relay's facts: --check after generating: silent" "" "$OUT"

echo '--- --check'
new_plugin
new_repo
gen "$R"
gen "$R" --check
assert_eq "check, current: exit 0" 0 "$RC"
assert_eq "check, current: silent" "" "$OUT"
sed -i 's/"version": "1.0.0"/"version": "1.0.1"/' "$PLUGIN/.claude-plugin/plugin.json"
gen "$R" --check
assert_eq "check, version-only change: exit 0" 0 "$RC"
assert_eq "check, version-only change: silent" "" "$OUT"
printf '%s\n' 'One more general rule.' >> "$PLUGIN/templates/agents/executor.md"
gen "$R" --check
assert_eq "check, template change: exit 1" 1 "$RC"
assert_eq "check, template change: one line, with both versions" "demo-executor: out of date (hyper-relay 1.0.0 → 1.0.1)" "$OUT"

new_plugin
new_repo
gen "$R"
SUM=$(sha256sum < "$R/$AG/demo-reviewer.md")
printf '%s\n' '- Beyond: also the logs.' >> "$R/.hyper-relay/agents.md"
gen "$R" --check
assert_eq "check, facts change: exit 1" 1 "$RC"
assert_eq "check, facts change: names the agent, no versions" "demo-reviewer: out of date" "$OUT"
assert_eq "check writes nothing" "$SUM" "$(sha256sum < "$R/$AG/demo-reviewer.md")"
printf '%s\n' '- typed in' >> "$R/$AG/demo-planner.md"
rm "$R/$AG/demo-executor.md"
gen "$R" --check
assert_eq "check, several: exit 1" 1 "$RC"
assert_eq "check, several: one line each, in order" "demo-planner: edited by hand
demo-executor: missing
demo-reviewer: out of date" "$OUT"
printf '%s\n' '---' 'name: demo-executor' '---' 'by hand' > "$R/$AG/demo-executor.md"
gen "$R" --check
assert_contains "check, hand-written: named" "demo-executor: written by hand (no marker)" "$OUT"

echo '--- --check --hook'
new_plugin
new_repo
gen "$R"
gen "$R" --check --hook
assert_eq "hook, current: exit 0" 0 "$RC"
assert_eq "hook, current: silent" "" "$OUT"
OUT=$(cd / && CLAUDE_PROJECT_DIR="$R" dash "$GEN" --check --hook 2>&1)
assert_eq "hook, current, found through CLAUDE_PROJECT_DIR: silent" "" "$OUT"

rm "$R/$AG/demo-executor.md"
gen "$R" --check --hook
assert_eq "hook, one file: exit 0" 0 "$RC"
assert_eq "hook, one file: one line" \
    "$(hook_json 'hyper-relay: demo-executor is out of date; run hyper-relay-agents (see the hyper-relay:agents skill).')" "$OUT"
printf '%s\n' '- Beyond: also the logs.' >> "$R/.hyper-relay/agents.md"
OUT=$(cd / && CLAUDE_PROJECT_DIR="$R" dash "$GEN" --check --hook 2>&1)
RC=$?
assert_eq "hook, two files, through CLAUDE_PROJECT_DIR: exit 0" 0 "$RC"
assert_eq "hook, two files: one line naming both" \
    "$(hook_json 'hyper-relay: demo-executor, demo-reviewer are out of date; run hyper-relay-agents (see the hyper-relay:agents skill).')" "$OUT"
printf '%s' "$OUT" | python3 -c 'import json, sys; json.load(sys.stdin)'
assert_eq "hook: the line is valid JSON" 0 "$?"

new_repo
rm "$R/.hyper-relay/agents.md"
gen "$R" --check --hook
assert_eq "hook, no facts file: exit 0" 0 "$RC"
assert_eq "hook, no facts file: silent" "" "$OUT"
NOGIT=$(mktemp -d "$TMP_ROOT/nogit.XXXXXX")
gen "$NOGIT" --check --hook
assert_eq "hook, outside git: exit 0" 0 "$RC"
assert_eq "hook, outside git: silent" "" "$OUT"

new_plugin
new_repo
gen "$R"
rm "$PLUGIN/templates/agents/executor.md"
gen "$R" --check --hook
assert_eq "hook, internal error: exit 0" 0 "$RC"
assert_eq "hook, internal error: one line" 1 "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')"
assert_contains "hook, internal error: says so" '"systemMessage":"hyper-relay: agents check failed: template missing: ' "$OUT"

new_plugin
new_repo
facts_sed 's/^reviewer: commands$/reviewer: clicks/'
gen "$R" --check --hook
assert_eq "hook, facts problem: exit 0" 0 "$RC"
assert_contains "hook, facts problem: one failure line" 'hyper-relay: agents check failed: reviewer must be browser or commands, not \"clicks\"' "$OUT"
gen "$R" --bogus
assert_eq "unknown option: exit 1" 1 "$RC"
assert_contains "unknown option: the usage" "usage: hyper-relay-agents" "$OUT"
gen "$R" --check --force
assert_eq "--check with --force: exit 1" 1 "$RC"

echo '--- hooks/hooks.json'
HJ=$(python3 -c 'import json, sys
d = json.load(open(sys.argv[1]))
g = d["hooks"]["SessionStart"]
h = g[0]["hooks"]
print(len(g), len(h), h[0]["type"], h[0]["command"])' "$REPO/hooks/hooks.json")
assert_eq "hooks.json: one SessionStart command hook" '1 1 command "${CLAUDE_PLUGIN_ROOT}"/bin/hyper-relay-agents --check --hook' "$HJ"
new_plugin
new_repo
gen "$R"
rm "$R/$AG/demo-reviewer.md"
HCMD=${HJ#1 1 command }
OUT=$(cd / && CLAUDE_PLUGIN_ROOT="$PLUGIN" CLAUDE_PROJECT_DIR="$R" sh -c "$HCMD" 2>&1)
assert_eq "hooks.json: its command runs the plugin's check: exit 0" 0 "$?"
assert_eq "hooks.json: its command prints the notice" \
    "$(hook_json 'hyper-relay: demo-reviewer is out of date; run hyper-relay-agents (see the hyper-relay:agents skill).')" "$OUT"

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
