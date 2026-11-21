#!/bin/sh
# POSIX guard for the relay skills (hyper-relay D.3, D.2): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, `quartz install-git-hook`
# named only in quartz.md, no orchestrating file naming finishing-a-development-branch
# (the relay lands branches with relay-merge), and no upstream `superpowers:<skill>` name
# under skills/. It reads the working tree, not git's index, so an untracked new file
# counts and it runs the same in a worktree. Each check also runs on a copy of the tree
# broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "36 passed, 0 failed"
set -u
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

# none <grep options and patterns> <paths>: passes when grep finds nothing, and prints
# what it finds. A grep error, such as a missing path, fails too.
none() {
    grep -r -n -I "$@"
    [ $? -eq 1 ]
}

# Each check takes a tree's top, runs in a subshell from there, prints what is wrong,
# and exits non-zero when the tree fails it.

# --- 1. D1's gates

# Nothing points at executing-plans' old dispatching.md.
no_old_dispatching_pointer() (
    cd "$1" || exit 2
    none -E 'executing-plans.{0,6}dispatching' skills templates README.md CLAUDE.md
)

# Every line outside skills/orchestrating/ that names dispatching.md also names
# orchestrating, and at least one such line exists.
dispatching_pointers_name_orchestrating() (
    cd "$1" || exit 2
    lines=$(grep -r -n -I -F 'dispatching.md' skills templates | grep -v '^skills/orchestrating/')
    if [ -z "$lines" ]; then
        echo "no line outside skills/orchestrating/ names dispatching.md"
        exit 1
    fi
    ! printf '%s\n' "$lines" | grep -v -F orchestrating
)

# The old file is gone.
old_dispatching_gone() (
    cd "$1" || exit 2
    if [ -e skills/executing-plans/dispatching.md ]; then
        echo "skills/executing-plans/dispatching.md exists"
        exit 1
    fi
)

# No subagent-driven flow is named, in any case.
no_subagent_driven() (
    cd "$1" || exit 2
    none -i -F 'subagent-driven' skills templates README.md CLAUDE.md
)

# requesting-code-review is one review per branch, never per task.
code_review_not_per_task() (
    cd "$1" || exit 2
    none -i -e 'each task' -e 'per.task' -e 'next task' -e 'task [0-9]' -e 'completing tasks' \
        skills/requesting-code-review
)

# brainstorming hands over to orchestrating, never to writing-plans.
brainstorming_never_invokes_writing_plans() (
    cd "$1" || exit 2
    none -i -F -e 'invoke writing-plans' -e 'invoke the writing-plans' -e 'invoking writing-plans' \
        -e 'writing-plans is the next step' skills/brainstorming
)

# --- 2. The folder holds exactly the map, the three leg files, parallel.md and quartz.md.
orchestrating_folder() (
    cd "$1/skills/orchestrating" || exit 2
    got=$(ls -A | tr '\n' ' ')
    want='SKILL.md dispatching.md parallel.md planning.md quartz.md reviewing.md '
    if [ "$got" != "$want" ]; then
        echo "expected [$want], got [$got]"
        exit 1
    fi
)

# --- 3. No path on this machine.
no_machine_paths() (
    cd "$1" || exit 2
    none -F -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' skills/orchestrating
)

# --- 4. References resolve.

# Every hyper-relay:<name> names a skill.
skill_names_resolve() (
    cd "$1" || exit 2
    names=$(grep -r -h -o -I -E 'hyper-relay:[a-z0-9-]+' skills/orchestrating | sort -u)
    if [ -z "$names" ]; then
        echo "no hyper-relay:<name> in skills/orchestrating"
        exit 1
    fi
    rc=0
    for name in $names; do
        skill=${name#hyper-relay:}
        if [ ! -f "skills/$skill/SKILL.md" ]; then
            echo "$name: there is no skills/$skill/SKILL.md"
            rc=1
        fi
    done
    exit "$rc"
)

# Every `<file>.md` §N names a file of the folder that has a "## N." heading.
section_refs_resolve() (
    cd "$1/skills/orchestrating" || exit 2
    pairs=$(grep -h -o -E '`[A-Za-z0-9_-]+\.md` §[0-9]+' ./*.md | sort -u |
        sed 's/^`\([A-Za-z0-9_-]*\.md\)` §\([0-9]*\)$/\1 \2/')
    if [ -z "$pairs" ]; then
        echo "no \`<file>.md\` §N reference in skills/orchestrating"
        exit 1
    fi
    rc=0
    while read -r file n; do
        if [ ! -f "$file" ]; then
            echo "\`$file\` §$n: $file is not in skills/orchestrating/"
            rc=1
        elif ! grep -q "^## $n\. " "$file"; then
            echo "\`$file\` §$n: $file has no '## $n.' heading"
            rc=1
        fi
    done <<EOF
$pairs
EOF
    exit "$rc"
)

# --- 5. Finding 7: only quartz.md's setup installs Quartz's git hooks.
install_git_hook_only_in_quartz_md() (
    cd "$1" || exit 2
    got=$(grep -r -l -I -F 'quartz install-git-hook' skills)
    if [ "$got" != skills/orchestrating/quartz.md ]; then
        echo "expected only [skills/orchestrating/quartz.md], got [$got]"
        exit 1
    fi
)

# --- 6. The relay lands branches with relay-merge: no orchestrating file names
# finishing-a-development-branch, which stays for work outside the relay.
no_finishing_branch_in_orchestrating() (
    cd "$1" || exit 2
    none -F 'finishing-a-development-branch' skills/orchestrating
)

# --- 7. Every skill is named hyper-relay:<name>: no upstream superpowers:<skill> name is
# left under skills/ (docs/superpowers/ paths do not match).
no_superpowers_skill_names() (
    cd "$1" || exit 2
    none -E 'superpowers:[A-Za-z]' skills
)

# --- 8. Skill-test situations are whole and fenced, and no reviewer step reruns the gates.
skill_test_situations_fenced() (
    cd "$1" || exit 2
    f=skills/writing-plans/SKILL.md
    rc=0
    if ! grep -q -F '```text' "$f"; then
        echo "$f has no line holding a text fence"
        rc=1
    fi
    if ! grep -q -F 'No `reviewer` step reruns the full gates' "$f"; then
        echo "$f has no line holding: No \`reviewer\` step reruns the full gates"
        rc=1
    fi
    exit "$rc"
)

# --- 9. The executor's gates go through relay-plan, and it copies no checklist.
executor_gates_through_relay_plan() (
    cd "$1" || exit 2
    if ! grep -q -F 'relay-plan gate <plan>' skills/executing-plans/SKILL.md; then
        echo "skills/executing-plans/SKILL.md has no line holding: relay-plan gate <plan>"
        exit 1
    fi
    none -i -F 'acceptance checklist' skills/executing-plans
)

# --- 10. Every agent that reports writes to the run folder.
agents_write_to_the_run_folder() (
    cd "$1" || exit 2
    rc=0
    for f in skills/executing-plans/SKILL.md templates/agents/executor.md \
        templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md \
        skills/requesting-code-review/code-reviewer.md \
        skills/writing-plans/plan-document-reviewer-prompt.md; do
        if ! grep -q -F 'run folder' "$f"; then
            echo "$f names no run folder"
            rc=1
        fi
    done
    exit "$rc"
)

# --- 11. The agent that finds an issue files it as a proposed card.
proposed_cards_filed_by_finders() (
    cd "$1" || exit 2
    rc=0
    for f in skills/executing-plans/SKILL.md templates/agents/reviewer-commands.md \
        templates/agents/reviewer-browser.md skills/requesting-code-review/code-reviewer.md; do
        if ! grep -q -F 'add_tasks' "$f"; then
            echo "$f has no line holding add_tasks"
            rc=1
        fi
        if ! grep -q -F '`proposed`' "$f"; then
            echo "$f has no line holding \`proposed\`"
            rc=1
        fi
    done
    exit "$rc"
)

CHECKS='no_old_dispatching_pointer dispatching_pointers_name_orchestrating old_dispatching_gone
no_subagent_driven code_review_not_per_task brainstorming_never_invokes_writing_plans orchestrating_folder
no_machine_paths skill_names_resolve section_refs_resolve install_git_hook_only_in_quartz_md
no_finishing_branch_in_orchestrating no_superpowers_skill_names skill_test_situations_fenced
executor_gates_through_relay_plan
agents_write_to_the_run_folder proposed_cards_filed_by_finders'

# --- the repo's tree passes every check
for check in $CHECKS; do
    if out=$("$check" "$REPO" 2>&1); then ok "$check"; else bad "$check" "$out"; fi
done

# --- each check can fail: a copy of the tree, broken one way per case
mkdir "$TMP_ROOT/base"
cp -R "$REPO/skills" "$REPO/templates" "$REPO/README.md" "$REPO/CLAUDE.md" "$TMP_ROOT/base/"

# broken <what>: a fresh copy of the tree in $CASE, for the caller to break.
broken() {
    CASE=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    cp -R "$TMP_ROOT/base/." "$CASE/"
    WHAT=$1
}
# expect_fail <check>: the check fails on $CASE.
expect_fail() {
    if out=$("$1" "$CASE" 2>&1); then
        bad "$1 can fail: $WHAT" "it passed on a tree with $WHAT"
    else
        ok "$1 can fail: $WHAT"
    fi
}

broken "a pointer to executing-plans/dispatching.md"
printf '\nRead executing-plans/dispatching.md first.\n' >> "$CASE/skills/writing-plans/SKILL.md"
expect_fail no_old_dispatching_pointer

broken "a dispatching.md pointer that does not name orchestrating"
printf '\nSee `dispatching.md`.\n' >> "$CASE/templates/agents/executor.md"
expect_fail dispatching_pointers_name_orchestrating

broken "no dispatching.md pointer outside skills/orchestrating"
for f in $(cd "$CASE" && grep -r -l -F 'dispatching.md' skills templates | grep -v '^skills/orchestrating/'); do
    sed -i '/dispatching\.md/d' "$CASE/$f"
done
expect_fail dispatching_pointers_name_orchestrating

broken "skills/executing-plans/dispatching.md back"
printf '# old\n' > "$CASE/skills/executing-plans/dispatching.md"
expect_fail old_dispatching_gone

broken "Subagent-Driven in README.md"
printf '\nUse Subagent-Driven Development.\n' >> "$CASE/README.md"
expect_fail no_subagent_driven

broken "a review after each task"
printf '\nRequest a review after each task.\n' >> "$CASE/skills/requesting-code-review/SKILL.md"
expect_fail code_review_not_per_task

broken "brainstorming invoking writing-plans"
printf '\nThen invoke writing-plans.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail brainstorming_never_invokes_writing_plans

broken "a seventh file in skills/orchestrating"
printf '# notes\n' > "$CASE/skills/orchestrating/notes.md"
expect_fail orchestrating_folder

broken "a home path in skills/orchestrating"
printf '\nRun ~/bin/tool.\n' >> "$CASE/skills/orchestrating/planning.md"
expect_fail no_machine_paths

broken "a skill that does not exist"
printf '\nUse `hyper-relay:no-such-skill`.\n' >> "$CASE/skills/orchestrating/SKILL.md"
expect_fail skill_names_resolve

broken "a section that does not exist"
printf '\nSee `reviewing.md` §9.\n' >> "$CASE/skills/orchestrating/planning.md"
expect_fail section_refs_resolve

broken "a section of a file outside the folder"
printf '\nSee `code-reviewer.md` §1.\n' >> "$CASE/skills/orchestrating/reviewing.md"
expect_fail section_refs_resolve

broken "quartz install-git-hook outside quartz.md"
printf '\nRun `quartz install-git-hook` once.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail install_git_hook_only_in_quartz_md

broken "finishing-a-development-branch in skills/orchestrating"
printf '\nMerge with `hyper-relay:finishing-a-development-branch`.\n' >> "$CASE/skills/orchestrating/reviewing.md"
expect_fail no_finishing_branch_in_orchestrating

broken "brainstorming invoking superpowers:writing-plans"
printf '\nInvoke the superpowers:writing-plans skill.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail no_superpowers_skill_names

broken "writing-plans without the fence rule"
sed -i '/```text/d' "$CASE/skills/writing-plans/SKILL.md"
expect_fail skill_test_situations_fenced

broken "the executor copying the acceptance checklist again"
printf '\nThen copy the acceptance checklist into your report.\n' >> "$CASE/skills/executing-plans/SKILL.md"
expect_fail executor_gates_through_relay_plan

broken "a reviewer template that names no run folder"
sed -i '/run folder/d' "$CASE/templates/agents/reviewer-browser.md"
expect_fail agents_write_to_the_run_folder

broken "a code reviewer that files no card"
sed -i '/add_tasks/d' "$CASE/skills/requesting-code-review/code-reviewer.md"
expect_fail proposed_cards_filed_by_finders

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
