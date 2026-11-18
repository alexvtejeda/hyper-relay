# hyper-relay C: our own executing-plans Implementation Plan

**Spec:** `docs/superpowers/specs/2026-11-17-hyper-relay-c-executing-plans-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: executing-plans (the relay-executor preloads it). Tasks 1–8 are the
> executor's, in `.worktrees/hyper-relay-c-executing-plans`. Task 9 is the orchestrator's, run with the owner after
> the merge. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `executing-plans` the owner's executor process, ship the orchestrator's half of the handoff beside it
(`dispatching.md`, with a second run mode: a branch in the main checkout), delete `subagent-driven-development`, and
bring B's templates, generator and facts in line.

**Architecture:** `skills/executing-plans/SKILL.md` becomes the dispatched executor's process (what
`<project>-executor` preloads); the new `skills/executing-plans/dispatching.md` is the orchestrator's: handoff,
preconditions, setup of a branch or a worktree, link, background dispatch, the hold-back rules of a branch run,
verifying the hand-back, review, merge. `writing-plans`, `brainstorming` and `using-git-worktrees` point at it and gain
the commit rule (C11). B's executor template shrinks to its slots, with the acceptance slot split by mode; the
generator learns the `execute:` header key, drops empty `### ` headings, and ends a run that wrote an agent with a
restart line (C12). `subagent-driven-development` goes, with its live suites.

**Tech Stack:** Markdown skills and agent templates; POSIX `sh` run by dash, awk (mawk or gawk: no gawk-only
features); bash for upstream's live-suite runners; Claude Code 2.1.x; OpenCode V2.

**How this was checked:** written against `main` at `ef61395` (the spec as amended with C12) by reading only; nothing
was built, run, installed or generated. Read in this repo: `CLAUDE.md` (`git show main:CLAUDE.md`); the spec (in full,
both `bbb3d86` and `ef61395`); B's gitignored plan `docs/superpowers/plans/2026-11-17-hyper-relay-b-generated-agents.md`
(1–158, 2345–2644, 2797–2808 and 2840–2852, for its format, its D6/D8 and the header of SAT's facts file);
`skills/executing-plans/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/brainstorming/SKILL.md`,
`skills/using-git-worktrees/SKILL.md`, `skills/finishing-a-development-branch/SKILL.md`, `skills/agents/SKILL.md`,
`skills/agents/opencode.md` (all in full); `skills/dispatching-parallel-agents/SKILL.md` (1–12);
`skills/requesting-code-review/SKILL.md` (1–40); `skills/voice-to-specs/SKILL.md` (270–289);
`skills/voice-to-specs/CLAUDE.md`; `skills/writing-skills/render-graphs.js` (85–104); `templates/agents/executor.md`,
`templates/agents/planner.md`, `templates/agents/reviewer-commands.md` (in full), `templates/agents/reviewer-browser.md`
(1–50); `bin/hyper-relay-agents`, `tests/hyper-relay-agents/run-tests.sh`, `.hyper-relay/agents.md`, `.gitignore`,
`README.md`, `docs/testing.md`, `tests/claude-code/README.md`, `tests/claude-code/run-skill-tests.sh`,
`tests/explicit-skill-requests/run-all.sh` and `run-test.sh` (in full); `run-multiturn-test.sh` (1–30),
`run-extended-multiturn-test.sh` (1–30, 60–113), `run-haiku-test.sh` (1–30, 95–144), `run-claude-describes-sdd.sh`
(1–20) and every file in `tests/explicit-skill-requests/prompts/`; `tests/skill-triggering/run-all.sh` and
`prompts/executing-plans.txt`; `tests/add-card-line/run-tests.sh` (1–15); `git ls-files`; `git grep` for
`subagent-driven`, `link-branch`, `quartz review`, handoff words, `^###` and `{{slot` in `templates/`, and the
expected counts of the three test suites; `git diff --stat main` of every file this plan edits (none differs from
`main`). Read outside the repo: `~/.claude/CLAUDE.md` (in full), `~/.claude/bin/wt` (1–40 and its usage lines),
`~/.gitconfig` (no global hooks path, so a fresh repo has no Quartz hooks).

**External facts (re-verified 2026-11-17):**
- Claude Code sub-agents, [code.claude.com/docs/en/sub-agents.md](https://code.claude.com/docs/en/sub-agents.md):
  "Background subagents run concurrently while you continue working"; "With nothing configured, a subagent that
  Claude spawns from your main conversation starts in the background"; "A background subagent's results reach Claude
  as a completion notification in a later turn"; a background subagent's permission prompts surface in the main
  session; `AskUserQuestion` is not in a subagent's tools (so an executor has no partner to ask, as §2.2 says). As the
  spec assumes (C3).
- OpenCode agents, [opencode.ai/docs/agents/](https://opencode.ai/docs/agents/): subagents "always run in the
  background: the parent receives a report when a child goes idle", launched through the `subagent` tool. **The spec
  (§6) says this is not documented: it now is** (E13). No design change; Task 9 Step 7 still records what happens.
- The Quartz, `wt`, git and `finishing-a-development-branch` facts of spec §8 were checked by the spec's author today;
  `wt`'s usage lines (`wt up`, `wt down [name]`, the main-checkout refusal at line 37) were re-read here.

---

## Execution notes (binding)

- **Where.** Work only in `/home/noob_master/hyper-relay/.worktrees/hyper-relay-c-executing-plans` on branch
  `hyper-relay-c-executing-plans` (already created from `main`). The shell does not keep its directory between Bash
  calls: start every call with `cd /home/noob_master/hyper-relay/.worktrees/hyper-relay-c-executing-plans && `.
  Paths below are relative to that root unless absolute. This plan is committed on `main` and is in the worktree; if
  it is not, read it at `/home/noob_master/hyper-relay/docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md`
  and report that.
- **The skill you follow is not the one you write.** Your preloaded `executing-plans` is the installed plugin's old
  copy. This plan rewrites the repo's copy; follow your agent instructions and this plan, not the new text.
- **Commits.** Commit after every task, staging named paths only (never `git add -A` / `git add .`; `git rm` of named
  paths is fine). Put the trailers in ONE final paragraph, so git reads them all as trailers: each task's final commit
  is `git commit -m "<subject>" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#<N>`
  followed, inside the same quoted paragraph, by the two attribution lines your instructions give
  (`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and `Claude-Session:` with the URL from your dispatch
  prompt). The commands below show them; put the dispatch prompt's URL where they say
  `<the URL your dispatch prompt gives>`. Never tick the plan: the hooks do.
- **A `quartz:` line printed by a commit:** report it, verbatim.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly. If X is not found, read
  the range again; if the text moved or differs slightly, adapt as little as possible and record it as a deviation;
  if it is gone, stop and report. Text in code blocks is exact: transcribe it.
- **Never** start a live `claude -p` / `opencode run` session, install a plugin, add a marketplace, push, tag, or
  create anything on GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites
  (`tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`): they start `claude -p`.
- **Never touch** `~/.claude/`, `~/.config/opencode/`, SAT's repo, the home repo or the main checkout. Task 9 does
  those, and it is not yours.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs its targeted check only. The full gates run once, in Task 8. Syntax-check every
  script you touch (`dash -n` for `#!/bin/sh`, `bash -n` for bash, `node --check` for `.js`).
- `sed -i` below is GNU sed (this is Linux).
- **This repo is public.** Nothing you write into the repo may name SAT or carry its facts; test fixtures use the
  made-up project `demo`.
- Task 9 is not yours. After Task 8, run `quartz review`, report and stop.

## Spec ambiguities and deviations (each decided here)

| # | Question | Decision |
|---|---|---|
| E1 | §1 lists `skills/agents/SKILL.md` only for the restart line (C12) | Task 2 also updates its header-key table (`execute`), its slot table (the two acceptance slots; `executor/setup` now lands under "Setup"), its empty-heading sentence (`###` too) and its example. The generator's "matches no slot" error sends the owner to that table, so it must match the templates. |
| E2 | `templates/agents/reviewer-commands.md` is not in §1, but it says "in its worktree", and its clean-tree check (`git status --short` prints nothing) stops on the held-back docs of a branch run. hyper-relay is `execute: branch` with a commands reviewer, so C9 would break it. | **Task 3 Step 2** says "the checkout" and lets the check ignore untracked `docs/superpowers/` files. The browser reviewer (SAT) needs nothing. **Owner: confirm, or drop Task 3 Step 2** (then Task 9 expects `relay-planner, relay-executor` out of date, not `relay-reviewer`). **Owner: confirmed 2026-11-17.** |
| E3 | §4.4 drops only "or picks the worktree option at a plan-to-execute handoff" from `using-git-worktrees`' description | It also drops "or before executing an implementation plan" and says it is not for running a plan: otherwise "worktree" or "keep my checkout free" at the handoff still triggers `EnterWorktree`, which §3.1 step 3 forbids. **Owner: confirm.** **Owner: confirmed 2026-11-17.** |
| E4 | C12's restart line vs B's `Created .claude/agents/. Restart Claude Code …` line | B's line is removed: a run that creates the folder writes agents, so the restart line already says it, and the output ends with exactly one restart line. The B tests that checked for "Restart Claude Code" now check the new line, both ways. |
| E5 | B's test "hand edit mid-file" edits under `## Constraints`, which the `demo` executor no longer has (§5.1 leaves only a slot there, and `demo` fills none) | It edits under `## Full gates (once, at the end)`, which names `## executor/gates`. Same behaviour tested. |
| E6 | Dropping the last `###` heading leaves a trailing blank line at the end of the executor | Accepted (cosmetic); B's blank-line handling is otherwise unchanged. |
| E7 | §4.1: "a runner left with nothing to run is deleted" | Neither is: `run-skill-tests.sh` keeps `test-requesting-code-review.sh` (integration) with no fast test, and `explicit-skill-requests/run-all.sh` keeps two tests. The runner's loop becomes `${tests[@]+"${tests[@]}"}`, so its empty default list survives `set -u` in bash 3.2. |
| E8 | `tests/skill-triggering/prompts/executing-plans.txt` ("please implement it") | Kept: it should still load `executing-plans`, whose description now sends an orchestrator to `dispatching.md`. |
| E9 | `writing-plans`' spec update (the `**Plans:**` line) during a branch run, when the spec is already committed | Editing a tracked file is held back too (§3.2): the skill says to report it and make it after the merge. |
| E10 | §3.1 step 3: "check that `.worktrees/` is gitignored" | `mkdir -p .worktrees` first (a `.worktrees/` pattern matches only an existing directory). A missing ignore line is committed on `main`, or, during a branch run, put in `.git/info/exclude`. Not in the spec. |
| E11 | The owner's `CLAUDE.md` also says "Committing a doc puts it on its cards … There is no `quartz link-doc` step", which contradicts C11 | Task 9 Step 4 rewrites that bullet too, and the Workflow table's Execute row. **Owner: confirm.** **Owner: confirmed 2026-11-17.** |
| E12 | C3 rules out `main` partly because OpenCode reads `skills/` live from the main checkout; a hyper-relay branch run (C9) puts that checkout on the branch | OpenCode then sees the branch's skills until the merge. `CLAUDE.md` says so (Task 8). **Owner: note**; C9 stands. |
| E13 | External: OpenCode's docs now say subagents always run in the background (§6: "not documented") | No design change; Task 9 Step 7 records what happens. |
| E14 | SAT's `executor/acceptance` text (B's Task 7) may tell the executor to run `quartz review`, which the orchestrator now runs (C10) | Task 9 Step 3 checks with `git grep` and rewords it with the owner. This plan does not carry SAT's text. |
| E15 | Card line | None: the plan inherits the spec's card through its `**Spec:**` line. |
| E16 | `README.md` beyond §4.1 | Roadmap row C's status becomes "on `main`". The intro's "execution in isolation" and the diagram's "(isolated)" are left alone. |
| E17 | A reinstall may leave deleted files in the plugin cache | Task 9 Step 2 checks `subagent-driven-development` is gone from the cache; if not, it stops and tells the owner. |
| E18 | §5.2 removes the `cd` prefix from plans, but a subagent's shell may not keep its directory | The executor's process (Task 4) says to start every shell command with `cd <checkout> && `. |

## File structure

- **Modify (Task 1):** `templates/agents/executor.md` (rewritten), `bin/hyper-relay-agents`,
  `tests/hyper-relay-agents/run-tests.sh`, `.hyper-relay/agents.md`.
- **Modify (Task 2):** `skills/agents/SKILL.md`.
- **Modify (Task 3):** `templates/agents/planner.md`, `templates/agents/reviewer-commands.md`.
- **Create / rewrite (Task 4):** `skills/executing-plans/SKILL.md` (rewritten), `skills/executing-plans/dispatching.md`.
- **Modify (Task 5):** `skills/writing-plans/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/using-git-worktrees/SKILL.md`.
- **Delete / modify (Task 6):** `skills/subagent-driven-development/` (4 files); `skills/dispatching-parallel-agents/SKILL.md`,
  `skills/requesting-code-review/SKILL.md`, `skills/voice-to-specs/SKILL.md`, `skills/writing-skills/render-graphs.js`.
- **Delete / modify (Task 7):** 20 files of upstream's live suites (listed there); `tests/claude-code/run-skill-tests.sh`,
  `tests/claude-code/README.md`, `tests/explicit-skill-requests/run-all.sh` (rewritten),
  `tests/explicit-skill-requests/run-test.sh`, `docs/testing.md`.
- **Modify (Task 8):** `README.md`, `CLAUDE.md`.
- **Task 9 (orchestrator, outside the worktree):** the installed plugin; `/home/noob_master/hyper-relay/.claude/agents/`
  and `/home/noob_master/sat.pentraze.com/.claude/agents/` (generated, ignored);
  `/home/noob_master/sat.pentraze.com/.hyper-relay/agents.md` (committed in SAT); `/home/noob_master/.claude/CLAUDE.md`
  (the owner's, untracked); throwaway repos under `/tmp/`; this plan's record.

---

### Task 1: The executor template, the generator and their tests (spec §5.1, §5.3, §5.4 first bullet, C12)

**Files:**
- Modify: `templates/agents/executor.md` (rewritten), `bin/hyper-relay-agents`, `tests/hyper-relay-agents/run-tests.sh`,
  `.hyper-relay/agents.md`

- [x] **Step 1: Link the branch.** In the worktree, run
  `quartz link-branch docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md`. If it fails, report the
  failure and carry on.

- [x] **Step 2: The failing tests.** Make these edits to `tests/hyper-relay-agents/run-tests.sh`.

Replace:
```text
# Usage: sh tests/hyper-relay-agents/run-tests.sh      Expect: "124 passed, 0 failed"
```
with:
```text
# Usage: sh tests/hyper-relay-agents/run-tests.sh      Expect: "153 passed, 0 failed"
```

Replace:
```text
GD=.claude/hooks/hyper-relay-planner-guard.py
```
with:
```text
GD=.claude/hooks/hyper-relay-planner-guard.py
RESTART='Start a new session to use them: a running session keeps the agent definitions it loaded.'
```

Replace:
```text
facts_sed() {
    printf '%s' "$FACTS_OK" | sed "$1" > "$R/.hyper-relay/agents.md"
}
```
with:
```text
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
```

Replace:
```text
assert_contains "unknown header key: named" "unknown header key colour" "$OUT"
```
with:
```text
assert_contains "unknown header key: named" "unknown header key colour" "$OUT"
assert_contains "unknown header key: the keys are listed, execute among them" "(the keys are project, reviewer, execute, model.planner, model.executor and model.reviewer)" "$OUT"
```

Replace:
```text
assert_contains "first run: it created .claude/agents/, so: restart" "Restart Claude Code" "$OUT"
```
with:
```text
assert_eq "first run: wrote agents, so the restart line ends the output" "$RESTART" "$(last_line)"
assert_eq "first run: the restart line, once" 1 "$(printf '%s\n' "$OUT" | grep -c 'Start a new session')"
```

Replace:
```text
assert_not_contains "second run: no restart message" "Restart Claude Code" "$OUT"
```
with:
```text
assert_not_contains "second run: wrote nothing, so no restart line" "Start a new session" "$OUT"
```

Replace:
```text
assert_contains "facts change: the new line is in" "- Beyond: also the logs." "$(cat "$R/$AG/demo-reviewer.md")"
```
with:
```text
assert_contains "facts change: the new line is in" "- Beyond: also the logs." "$(cat "$R/$AG/demo-reviewer.md")"
assert_eq "facts change: wrote an agent, so the restart line ends the output" "$RESTART" "$(last_line)"
```

Replace:
```text
awk '{ print } $0 == "## Constraints" { print "- Hand-added." }' "$R/$AG/demo-executor.md" > "$TMP_ROOT/x.md"
cp "$TMP_ROOT/x.md" "$R/$AG/demo-executor.md"
gen "$R"
assert_contains "hand edit mid-file: names that heading's section" 'under "## Constraints" probably belongs in .hyper-relay/agents.md, section ## executor/constraints' "$OUT"
```
with:
```text
awk '{ print } $0 == "## Full gates (once, at the end)" { print "- Hand-added." }' "$R/$AG/demo-executor.md" > "$TMP_ROOT/x.md"
cp "$TMP_ROOT/x.md" "$R/$AG/demo-executor.md"
gen "$R"
assert_contains "hand edit mid-file: names that heading's section" 'under "## Full gates (once, at the end)" probably belongs in .hyper-relay/agents.md, section ## executor/gates' "$OUT"
```

Replace:
```text
assert_not_contains "--force: the hand edit is gone" "- A lesson typed into the agent." "$(cat "$R/$AG/demo-planner.md")"
```
with:
```text
assert_not_contains "--force: the hand edit is gone" "- A lesson typed into the agent." "$(cat "$R/$AG/demo-planner.md")"
assert_eq "--force: wrote agents, so the restart line ends the output" "$RESTART" "$(last_line)"
```

Replace:
```text
assert_eq "after --force: a plain run is clean" 0 "$RC"
```
with:
```text
assert_eq "after --force: a plain run is clean" 0 "$RC"
assert_not_contains "after --force: wrote nothing, so no restart line" "Start a new session" "$OUT"
```

Replace:
```text
assert_contains "edited guard: refused, pointing at the template" "refused $GD: edited by hand; the guard comes from hyper-relay's templates/hooks/planner-guard.py" "$OUT"
gen "$R" --force
```
with:
```text
assert_contains "edited guard: refused, pointing at the template" "refused $GD: edited by hand; the guard comes from hyper-relay's templates/hooks/planner-guard.py" "$OUT"
gen "$R" --force
assert_contains "--force over the edited guard: the guard is written" "written $GD (--force: replaced a hand-edited file)" "$OUT"
assert_not_contains "only the guard was written: no restart line" "Start a new session" "$OUT"
```

Replace:
```text
assert_not_contains "the agents folder existed: no restart message" "Restart Claude Code" "$OUT"
```
with:
```text
assert_eq "hand-written: the others were written, so the restart line ends the output" "$RESTART" "$(last_line)"
```

Replace (the line is `echo '--- --check'` exactly, not the later `echo '--- --check --hook'`):
```text
echo '--- --check'
```
with:
```text
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
```

- [x] **Step 3: Run the tests; they fail.**

Run: `sh tests/hyper-relay-agents/run-tests.sh | grep -e '^FAIL' -e 'passed, '`
Expected: a non-zero failed count on the last line, with failures including `FAIL execute: branch is accepted`,
`FAIL first run: wrote agents, so the restart line ends the output` and `FAIL both acceptance slots: exit 0`.

- [x] **Step 4: The executor template.** Write `templates/agents/executor.md` with exactly:

```markdown
---
name: {{project}}-executor
description: >-
  Executes ONE approved implementation plan for the {{project}} repo ({{root}}) with the
  hyper-relay:executing-plans skill, on the branch it is given, in the main checkout or its own worktree. Never
  nests subagents, never ticks the plan, never merges or pushes. The dispatch prompt names the plan, the mode, the
  checkout and branch, which tasks are the executor's, and anything unusual.
model: {{model}}
disallowedTools: Agent
skills:
  - hyper-relay:executing-plans
---

# {{project}} executor

You execute one implementation plan for the {{project}} repo by the preloaded `hyper-relay:executing-plans` skill:
its process, its "never" list and its report are yours. The dispatch prompt gives the plan, the mode (`branch` or
`worktree`), the checkout and the branch, and which tasks are yours. Below is only what is particular to
{{project}}.

## Setup
{{slot executor/setup}}

## Full gates (once, at the end)
{{slot! executor/gates}}

## Constraints
{{slot executor/constraints}}

## Acceptance

### In a worktree
{{slot executor/acceptance-worktree}}

### On a branch
{{slot executor/acceptance-branch}}
```

- [x] **Step 5: The generator.** Four edits to `bin/hyper-relay-agents`.

(a) Replace:
```text
REFUSED=0
```
with:
```text
REFUSED=0
WROTE_AGENT=0
```

(b) Replace:
```text
            *) problem "unknown header key $key (the keys are project, reviewer, model.planner, model.executor and model.reviewer)" ;;
```
with:
```text
            execute)
                case $val in
                    branch|worktree) ;;
                    *) problem "execute must be branch or worktree, not \"$val\"" ;;
                esac
                ;;
            *) problem "unknown header key $key (the keys are project, reviewer, execute, model.planner, model.executor and model.reviewer)" ;;
```

(c) Replace:
```text
    # A "## " heading left with nothing under it (its only slot was missing) is dropped.
    awk '
        /^## / { held = $0; blanks = 0; holding = 1; next }
        holding && /^[ \t]*$/ { blanks++; next }
        holding {
            print held
            for (i = 0; i < blanks; i++) print ""
            holding = 0
        }
        { print }
    ' "$WORK/out/$1.raw" > "$WORK/out/$1.body" || die "cannot render the $1 agent"
```
with:
```text
    # A "## " or "### " heading left with nothing under it (its slots were missing) is dropped,
    # with the blank lines after it. A "## " heading whose "### " headings were all dropped goes too.
    awk '
        /^## / { h2 = $0; b2 = 0; hold2 = 1; hold3 = 0; next }
        /^### / { h3 = $0; b3 = 0; hold3 = 1; next }
        hold3 && /^[ \t]*$/ { b3++; next }
        hold2 && /^[ \t]*$/ { b2++; next }
        {
            if (hold2) {
                print h2
                for (i = 0; i < b2; i++) print ""
                hold2 = 0
            }
            if (hold3) {
                print h3
                for (i = 0; i < b3; i++) print ""
                hold3 = 0
            }
            print
        }
    ' "$WORK/out/$1.raw" > "$WORK/out/$1.body" || die "cannot render the $1 agent"
```

(d) Replace:
```text
    if [ "$1" = guard ]; then
        chmod 755 "$2" || die "cannot make $2 executable"
    fi
    return 0
}

write_all() {
    made_dir=0
    [ -d "$TOP/.claude/agents" ] || made_dir=1
    mkdir -p "$TOP/.claude/agents" "$TOP/.claude/hooks" || die "cannot create .claude/agents and .claude/hooks in $TOP"
```
with:
```text
    if [ "$1" = guard ]; then
        chmod 755 "$2" || die "cannot make $2 executable"
    else
        WROTE_AGENT=1
    fi
    return 0
}

write_all() {
    mkdir -p "$TOP/.claude/agents" "$TOP/.claude/hooks" || die "cannot create .claude/agents and .claude/hooks in $TOP"
```

and replace:
```text
    if [ "$made_dir" = 1 ]; then
        printf '%s\n' "Created .claude/agents/. Restart Claude Code before dispatching these agents: a running session only watches agents folders that existed when it started."
    fi
    return 0
}
```
with:
```text
    # A running session keeps the agent definitions it loaded, even for a file rewritten here.
    if [ "$WROTE_AGENT" = 1 ]; then
        printf '%s\n' "Start a new session to use them: a running session keeps the agent definitions it loaded."
    fi
    return 0
}
```

- [x] **Step 6: hyper-relay's facts (C9).** In `.hyper-relay/agents.md`, replace:
```text
project: relay
reviewer: commands
---
```
with:
```text
project: relay
reviewer: commands
execute: branch
---
```

- [x] **Step 7: Run the tests; they pass.**

| Run | Expected |
|---|---|
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `dash -n bin/hyper-relay-agents`, then `dash -n tests/hyper-relay-agents/run-tests.sh` | silent |
| `git ls-files -s bin/hyper-relay-agents` | mode `100755` (unchanged) |

- [x] **Step 8: Commit.**

```bash
git add templates/agents/executor.md bin/hyper-relay-agents tests/hyper-relay-agents/run-tests.sh .hyper-relay/agents.md
git commit -m "feat: executor template per mode; the generator learns execute:, ### headings and the restart line" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#1
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: The `agents` skill says what the generator now does (spec §5.3, C12; E1)

**Files:**
- Modify: `skills/agents/SKILL.md`

- [x] **Step 1: The command table.** Replace:
```text
| `hyper-relay-agents` | Writes the four files, one line each: `written`, `unchanged`, or `refused` with the reason. Exit 1 if any is refused or the facts file has a problem; then nothing is half-written. |
```
with:
```text
| `hyper-relay-agents` | Writes the four files, one line each: `written`, `unchanged`, or `refused` with the reason. When it wrote an agent, a last line says to start a new session. Exit 1 if any is refused or the facts file has a problem; then nothing is half-written. |
```

- [x] **Step 2: The example and the header table.** Replace:
```text
project: myapp
reviewer: browser
model.executor: sonnet
```
with:
```text
project: myapp
reviewer: browser
execute: worktree
model.executor: sonnet
```

Replace:
```text
| `reviewer` (required) | `browser` (a click-through of a running app) or `commands` (acceptance by running commands and live CLI sessions). |
```
with:
```text
| `reviewer` (required) | `browser` (a click-through of a running app) or `commands` (acceptance by running commands and live CLI sessions). |
| `execute` | `branch` (an executor runs a plan on a new branch in the main checkout) or `worktree` (in its own worktree). The handoff in `hyper-relay:executing-plans`' `dispatching.md` offers it as this repo's default; without it, the handoff asks. The generator only checks the value. |
```

- [x] **Step 3: Empty headings.** Replace:
```text
a section is left out, and so is a heading left with nothing under it.
```
with:
```text
a section is left out, and so is a `## ` or `### ` heading left with nothing under it.
```

- [x] **Step 4: The slot table.** Replace:
```text
| `executor/setup` | executor, "Where" | an install step a worktree needs |
```
with:
```text
| `executor/setup` | executor, "Setup" | an install step a worktree needs |
```

Replace:
```text
| `executor/acceptance` | executor, "A plan that ends with an acceptance task" | start the stack, leave it up, report its URLs and logins |
```
with:
```text
| `executor/acceptance-worktree` | executor, "Acceptance", "In a worktree" | start the worktree's stack, leave it up, report its URLs and logins |
| `executor/acceptance-branch` | executor, "Acceptance", "On a branch" | restart the owner's normal dev server on the branch, report its URLs |
```

- [x] **Step 5: The restart line (C12).** Replace:
```text
Run `hyper-relay-agents` and tell the owner what changed, file by file. If it printed `Created .claude/agents/`, say
that the session must be restarted before any of these agents is dispatched: Claude Code watches only agent folders
that existed when the session started.
```
with:
```text
Run `hyper-relay-agents` and tell the owner what changed, file by file. When it wrote an agent, its last line is
"Start a new session to use them: a running session keeps the agent definitions it loaded." Say so: this session
still dispatches the definitions it loaded, even for a file it has just rewritten, so the new agents are dispatched
only from a session started after this run.
```

- [x] **Step 6: Check.**

Run: `git grep -n -e "executor/acceptance" -e "Created .claude/agents" -e "Restart Claude Code" -- skills/agents`
Expected: exactly two lines, the `executor/acceptance-worktree` and `executor/acceptance-branch` rows.

- [x] **Step 7: Commit.**

```bash
git add skills/agents/SKILL.md
git commit -m "docs: the agents skill lists execute:, the two acceptance slots and the restart line" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#2
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: The planner's Execution notes, and the reviewer's checkout (spec §5.2; E2)

**Files:**
- Modify: `templates/agents/planner.md`, `templates/agents/reviewer-commands.md`

- [x] **Step 1: The planner (§5.2).** In `templates/agents/planner.md`, replace:
```text
- Work in `.worktrees/<branch>` on the named branch. When the plan or its spec names a Quartz card, the first task
  starts with `quartz link-branch <plan path>`.
```
with:
```text
- The executor works where its dispatch prompt says: a branch in the main checkout or its own worktree, chosen at
  the handoff. A plan names no mode, no checkout path and no `cd` prefix, and carries no Quartz step: the
  orchestrator runs `quartz link-branch` and `quartz review`.
```

Replace:
```text
- **Outside the worktree is not the executor's.** Anything that touches the main checkout, another repo, the
  owner's own config, or GitHub (push, tag, repo settings), or that needs real credentials, a real third-party API
  or a live Claude Code or OpenCode session, is an owner/orchestrator task: mark it so, with exact commands and
  exact text. Tests use fakes.
- A plan ends with its acceptance task. The executor runs `quartz review` after its last task (when the repo uses
  Quartz; if it fails, it reports the failure and carries on). The checklist gives, for each step, the command or
  action and the result that counts as PASS, so the reviewer or the owner can run it as written.
```
with:
```text
- **Outside the executor's branch is not the executor's.** Anything that touches `main`, another repo, the owner's
  own config, or GitHub (push, tag, repo settings), or that needs real credentials, a real third-party API or a live
  Claude Code or OpenCode session, is an owner/orchestrator task: mark it so, with exact commands and exact text.
  Tests use fakes.
- A plan ends with its acceptance task. The checklist gives, for each step, the command or action and the result
  that counts as PASS, so the reviewer or the owner can run it as written.
```

- [x] **Step 2: The commands reviewer (E2; drop this step if the owner did not confirm E2).** In
  `templates/agents/reviewer-commands.md`, replace:
```text
  Performs the acceptance check for ONE {{project}} plan ({{root}}) in its worktree: runs the plan's acceptance
```
with:
```text
  Performs the acceptance check for ONE {{project}} plan ({{root}}) on its branch: runs the plan's acceptance
```

Replace:
```text
  acceptance task, the worktree, and the evidence folder.
```
with:
```text
  acceptance task, the checkout (the main checkout or a worktree), and the evidence folder.
```

Replace:
```text
task, the worktree, and the folder for evidence. Everything below is standing.
```
with:
```text
task, the checkout (the main checkout or a worktree) and the folder for evidence. Everything below is standing.
```

Replace:
```text
2. In the worktree, `git branch --show-current` must print the plan's branch and `git status --short` must
   print nothing. If not, stop and report. Don't fix it.
```
with:
```text
2. In the checkout, `git branch --show-current` must print the plan's branch and `git status --short` must
   print nothing, or only untracked files under `docs/superpowers/` (the orchestrator's held-back specs and
   plans, on a branch run). If not, stop and report. Don't fix it.
```

- [x] **Step 3: Check.**

| Run | Expected |
|---|---|
| `git grep -n -e "link-branch" -e "quartz review" -e "worktrees/<branch>" -- templates/agents/planner.md` | one line: the new first bullet (`orchestrator runs \`quartz link-branch\` and \`quartz review\``) |
| `git grep -n "worktree" -- templates/agents/reviewer-commands.md` | only lines saying "the main checkout or a worktree" and the Hard rules' "any checkout or worktree" |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |

- [x] **Step 4: Commit.**

```bash
git add templates/agents/planner.md templates/agents/reviewer-commands.md
git commit -m "feat: plans name no mode or Quartz step; the commands reviewer works in the checkout it is given" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#3
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `executing-plans`: the executor's process and the orchestrator's half (spec §2, §3, C1, C6, C7; E10, E18)

**Files:**
- Rewrite: `skills/executing-plans/SKILL.md`
- Create: `skills/executing-plans/dispatching.md`

- [x] **Step 1: The executor's process.** Write `skills/executing-plans/SKILL.md` with exactly:

````markdown
---
name: executing-plans
description: Use when an approved implementation plan is to be executed. The executor dispatched to run one plan follows this file; an orchestrator handing a plan off at the plan-to-execute handoff reads dispatching.md beside it instead, and never executes the plan itself.
---

# Executing Plans

**Handing a plan off, as the orchestrator?** Read `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this
SKILL.md) and follow it instead of this file. You never execute a plan yourself.

This file is for the **executor**: the agent dispatched, in a fresh context, to run ONE approved plan. You run every
task that is yours, in order, yourself; then you report and stop. There is no partner to ask: the orchestrator reads
your report. Your agent file (`<project>-executor`, when the repo has one) adds what is particular to the repo: its
setup, its full gates, its constraints and its acceptance steps.

**Announce at start:** "I'm using the executing-plans skill to execute this plan."

## The dispatch prompt gives

- the plan's path (absolute when the plan is not committed on `main`), and which of its tasks are yours;
- the **mode**: `branch` (a new branch in the repo's main checkout) or `worktree` (the branch's own worktree);
- the checkout's path and the branch;
- the Claude-Session URL for your commit trailers;
- anything unusual, for example `main` having moved since the plan was written.

## The process

1. **Check where you are.** In the checkout the prompt names, `git rev-parse --show-toplevel` must print that
   checkout and `git branch --show-current` the branch. If not, stop and report: never switch branches. Work only
   there: start every shell command with `cd <checkout> && ` (your shell may not keep its directory between
   calls); the plan's paths are relative to the checkout's top. Read `CLAUDE.md` at the top. The plan's Execution
   notes are binding.
2. **No review gate.** The plan is approved: do not re-plan it or ask about it. A step that is unclear or impossible
   means stop and report, never guess.
3. **Each task, in order:**
   - Follow its steps exactly, transcribing the plan's code.
   - Run only that task's checks.
   - Commit at its end, staging named files only (never `git add -A` / `git add .`). The task's final commit carries
     `Plan-Task: <plan path>#<N>` and the attribution lines your instructions give (in Claude Code, a
     `Co-Authored-By:` line and `Claude-Session:` with the URL from the dispatch prompt), all in ONE final
     paragraph, so git reads them all as trailers:

     ```bash
     git commit -m "<subject>" -m "Plan-Task: <plan path>#<N>
     Co-Authored-By: <the line your instructions give>
     Claude-Session: <the URL the dispatch prompt gives>"
     ```

   - Report every `quartz:` line a commit prints, verbatim. Never tick the plan: its hooks or the orchestrator do.
4. **When the code is not what the plan expects** (an expected line differs, a file moved): adapt as little as
   possible, and record it as a deviation with the reason. A step that fails twice the same way: stop and report.
5. **Full gates, once,** after your last task: the ones the plan's Execution notes name, and your agent's own
   ("Full gates").
6. **Acceptance:** follow your agent's acceptance steps for your mode, under "In a worktree" or "On a branch", when
   it has them. Then copy the plan's acceptance checklist (its last task) into your report.
7. **Report, then stop.** The orchestrator verifies every line of it:
   - tasks done (n/N), each with its commit hash;
   - each gate, with its pass/fail counts;
   - every deviation from the plan, and why;
   - every `quartz:` line, verbatim;
   - the acceptance output: URLs, logins, anything left running;
   - anything left for the owner: a task that is theirs, a step you stopped at.

## Never, in either mode

- Switch branches, stash, reset, rebase, merge, push or tag. Tick the plan. Invoke
  `hyper-relay:finishing-a-development-branch`: the owner decides the merge.
- Start a live `claude -p` or `opencode run` session, install or uninstall a plugin, or add a marketplace.
- Call a real third-party API or use real credentials: tests use fakes.
- Touch anything outside your checkout: `~/.claude/`, `~/.config/opencode/`, other repos, other worktrees. A task
  marked as the owner's or the orchestrator's is not yours, even when it gives commands.
- Wait with a self-matching `pgrep`, or `pkill -f` a pattern that appears in your own command line. Stop a server
  you started by its PID.

Read files in targeted ranges, and pipe long output through `tail` or `grep`: the owner rations usage.

## Branch mode adds

You share the repo's main checkout with the orchestrator, who keeps working while you run.

- Untracked files under `docs/superpowers/` that you did not create are the orchestrator's held-back specs and plans:
  never stage, edit, move or delete them. A "the tree is clean" check ignores them.
- If a git command fails on `index.lock` ("Unable to create '…/index.lock': File exists"), wait a second and retry
  once.
- A commit may print that a task "ticks at the next drain", because the main checkout is on your branch. That is
  expected: report it like any `quartz:` line.

## Integration

- `hyper-relay:writing-plans` writes the plan; `dispatching.md` hands it to you.
- `hyper-relay:test-driven-development`: when a task writes a test first, watch it fail before you make it pass.
- `hyper-relay:finishing-a-development-branch` belongs to the owner and the orchestrator, after the click-through.
````

- [x] **Step 2: The orchestrator's half.** Write `skills/executing-plans/dispatching.md` with exactly:

````markdown
# Handing a plan to an executor

The orchestrator's half of `executing-plans`. You are the session the owner talks to. You hand ONE approved plan to
ONE executor, keep working while it runs, verify what it hands back, and see the plan through review and merge. You
never execute a plan yourself: a fresh executor, in its own context, works better than a window full of decisions
and explanations. (`SKILL.md`, beside this file, is the executor's process.)

**A branch run is active exactly when the repo's main checkout is not on `main`:**
`GIT_OPTIONAL_LOCKS=0 git -C <main checkout> branch --show-current` prints another branch. Nothing else needs
remembering, so this holds after a `/clear` or in a new session.

## 1. Handoff: always a stop

This is the phase gate between plan and execution: stop for the owner's answer. First read the `execute:` line from
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one.

- **`execute: branch`:** "Plan ready at `<path>` (N tasks). Running it on a **branch** (this repo's default). OK, or
  worktree?"
- **`execute: worktree`:** "Plan ready at `<path>` (N tasks). Running it in a **worktree** (this repo's default). OK,
  or branch?"
- **No key, or no facts file:**

  > Plan ready at `<path>` (N tasks). Where should the executor run?
  > 1. **Branch**: this checkout, a new branch; you click through on your normal stack; new specs and plans stay
  >    uncommitted until it merges.
  > 2. **Worktree**: its own worktree; nothing held back, can run beside a branch run; worktree setup, and a `wt`
  >    stack for an app.

Add each warning that applies:
- Branch: task ticks arrive at the merge, not live.
- Branch, in a repo with a `.wt.conf`: it runs on the owner's normal stack and database.
- **While a branch run is active, Branch is not offered.** Say that one is active, and offer Worktree.

The owner's answer is the go-ahead to dispatch this plan; do not ask again.

## 2. Preconditions

- **Branch:** the main checkout is on `main`; `git rev-parse -q --verify MERGE_HEAD` prints nothing; and
  `git status --porcelain --untracked-files=no` prints nothing (untracked files are fine).
- **Worktree:** the new worktree is cut from `main`. The main checkout may be on a branch run.
- **The plan is committed on `main`:** `git log -1 --format=%h main -- <plan path>` prints a commit. A plan that is
  not (it is gitignored, or it was written during a branch run and held back) goes to the executor by its absolute
  path, and step 4 never runs `quartz link-branch` for it: Quartz would link the main checkout's current branch,
  which during a branch run is the other plan's. Move its cards by hand.

If a precondition fails, tell the owner which one, and stop.

## 3. Setup

The branch is the plan's file name without its date and `.md`:
`2026-11-17-hyper-relay-c-executing-plans.md` → `hyper-relay-c-executing-plans`.

- **Branch:** in the main checkout, `git switch -c <branch>`.
- **Worktree:** in the main checkout, `mkdir -p .worktrees`; then `git check-ignore -q .worktrees` must succeed.
  If it fails, `.worktrees/` is not ignored yet: add a `.worktrees/` line to `.gitignore` and commit just that file
  (`git add .gitignore`, then `git commit -m "chore: ignore .worktrees/" -- .gitignore`); during a branch run, add
  the line to `.git/info/exclude` instead, which is not tracked. Then
  `git worktree add .worktrees/<branch> -b <branch> main`.

  Never enter the worktree: no `EnterWorktree` (so not `hyper-relay:using-git-worktrees`, which uses it), and no `cd`
  that outlives one command. Run commands there as `(cd <worktree> && …)` or `git -C <worktree> …`.

## 4. Link (when the plan or its spec names a Quartz card)

- **A plan committed on `main`:** `quartz link-branch <plan path>`, run where the branch is checked out, with the
  plan's path inside that checkout: in the main checkout for a branch run,
  `(cd <worktree> && quartz link-branch <plan path>)` for a worktree run. Its cards move to In progress.
- **A plan that is not committed, or a link that fails:** move the cards to In progress through the Quartz MCP, and
  say so.

Without Quartz, skip this step.

## 5. Dispatch

Dispatch ONE executor, in the background:
- the repo's `<project>-executor`, when it has generated agents (`.claude/agents/<project>-executor.md`);
- otherwise a general-purpose agent whose first instruction is "Invoke the `hyper-relay:executing-plans` skill and
  follow it." (In OpenCode: the `general` subagent, told to load the `executing-plans` skill first.)

The prompt gives what the executor's `SKILL.md` lists under "The dispatch prompt gives":
- the plan's path (absolute when it is not committed on `main`), and which tasks are the executor's, e.g. "Tasks 1–8;
  Task 9 is the orchestrator's";
- the mode, `branch` or `worktree`;
- the checkout's absolute path (the main checkout, or the worktree) and the branch;
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.

Then tell the owner it is running, and carry on with other work. Where the harness cannot run a subagent in the
background, the dispatch waits for it; every rule below still holds.

## 6. While a branch run is active: the hold-back rules

Until the branch merges, you share the main checkout's working tree with the executor. Keep working (brainstorm,
write specs and plans) by these rules:

- **Create new files only.** Do not edit a tracked file: the edit would land in the executor's working tree, and it
  can block the later `git switch main`. An edit waits for the merge.
- **Write specs and plans; do not commit them.** `quartz link-doc <path>` puts one on its cards meanwhile.
  `hyper-relay:brainstorming` and `hyper-relay:writing-plans` keep to this themselves.
- **No git writes:** no `switch`, `checkout`, `stash`, `reset`, `add`, `commit` or `merge`. Run read-only git as
  `GIT_OPTIONAL_LOCKS=0 git …`, so a `git status` never holds `index.lock` while the executor commits.
- **A second plan runs only in a worktree** (step 1).
- **Code you read meanwhile may be the branch's half-finished work.** Read `main`'s with `git show main:<path>`.

## 7. Verify the hand-back

Before relaying anything, where the branch is checked out:

1. Rerun the gates the report names. Their counts must match the report's.
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`. Each of the executor's
   tasks ends in a commit carrying its `Plan-Task:` trailer.
3. Check the tree is clean: `GIT_OPTIONAL_LOCKS=0 git status --short` prints nothing but, on a branch run, your
   held-back docs (`??` under `docs/superpowers/`).
4. Weigh every deviation the report lists: accept it, or tell the owner why not.
5. Act on every `quartz:` line the report quotes.

Then run `quartz review` there (the cards move to In review); if it fails, move the cards by hand through the Quartz
MCP. Tell the owner only failures, gate results, deviations and the decisions you need: the board shows the rest.

## 8. Click-through and merge

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).

## 9. After a branch merge

The main checkout is back on `main`. Make the edits that waited, and commit the specs and plans you held back, each
staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks upload them. Task
ticks queued during the run drain at the next stop.
````

- [x] **Step 3: Check.**

| Run | Expected |
|---|---|
| `git grep -n -i -e "human partner" -e "subagent-driven" -e "TodoWrite" -- skills/executing-plans` | no output |
| `git grep -n -F 'CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this' -- skills/executing-plans/SKILL.md` | one line, line 8 |
| `sed -n '1,4p' skills/executing-plans/SKILL.md` | the front matter: `name: executing-plans` and the one-line description |

- [x] **Step 4: Commit.**

```bash
git add skills/executing-plans/SKILL.md skills/executing-plans/dispatching.md
git commit -m "feat: executing-plans is the dispatched executor's process; dispatching.md is the orchestrator's half" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#4
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `writing-plans`, `brainstorming` and `using-git-worktrees` point at the handoff (spec §4.2–§4.4, C10, C11; E3, E9)

**Files:**
- Modify: `skills/writing-plans/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/using-git-worktrees/SKILL.md`

- [x] **Step 1: `writing-plans`, context and plan count.** Replace:
```text
**Context:** If working in an isolated worktree, it should have been created via the `hyper-relay:using-git-worktrees` skill at execution time.
```
with:
```text
**Context:** A plan names neither where it runs nor a path to run it in: no worktree path, no `cd` prefix. The orchestrator sets up a branch or a worktree at the handoff (`hyper-relay:executing-plans`' `dispatching.md`), and the dispatch prompt tells the executor where it is.
```

Replace:
```text
and commit the spec. The hooks upload the changed spec, which updates the card's expected count.
```
with:
```text
and commit the spec as "Committing the plan" below says. The hooks upload the changed spec, which updates the card's expected count.
```

- [x] **Step 2: `writing-plans`, the header line.** Replace:
```text
> **For agentic workers:** REQUIRED SUB-SKILL: Use hyper-relay:subagent-driven-development (recommended) or hyper-relay:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
```
with:
```text
> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Steps use checkbox (`- [ ]`) syntax for tracking.
```

- [x] **Step 3: `writing-plans`, the Quartz steps (C10).** Replace:
```text
## Linking the plan's branch

When the plan or its spec names a Quartz card (a `**Card:**` or `**Cards:**` line in the plan, or one in the spec on its `**Spec:**` line), the plan's first task opens with this required step, with the plan's own path filled in:

> After creating your branch, run `quartz link-branch <this plan's path>`. If it fails, report the failure and carry on.

With no card, there is no step.

## Before a click-through

When a plan has a step that asks the owner to click through a change, usually with the URL that `wt up` printed, that step first runs `quartz review` in the worktree, just before asking. If it fails, report the failure and carry on.
```
with:
```text
## No Quartz steps in a plan

A plan carries no `quartz link-branch` step and no `quartz review` step: the orchestrator runs both, at dispatch and after verifying the executor's report (`hyper-relay:executing-plans`' `dispatching.md`).
```

- [x] **Step 4: `writing-plans`, committing and the handoff (C11).** Replace everything from the line
  `## Execution Handoff` to the end of the file (the last line is `- Batch execution with checkpoints for review`)
  with:
```text
## Committing the plan

Commit a plan, or a spec you updated, only while the repo's main checkout is on `main`: there, `git branch --show-current` prints `main` and `git rev-parse -q --verify MERGE_HEAD` prints nothing. Stage each file by its path and commit just those: `git add <path>`, then `git commit -m "<message>" -- <path> [<path>...]`. If the commit prints a `quartz:` line, do what it says.

When the main checkout is on another branch, a plan is running there (a branch run). Do not commit, and do not edit a file that is already committed:
- a new plan, or a spec you created during the run: run `quartz link-doc <path>` (it puts an uncommitted doc on its cards; skip it without Quartz), and report that it is held back. The orchestrator commits it after that branch merges (`dispatching.md`, step 9);
- a committed spec whose `**Plans:**` line must change: report the change; it is made after the merge.

## After saving the plan

Commit it (above), report its path and task count, and stop. Do not offer ways to execute it and do not start executing: once the owner approves the plan, the orchestrator runs the handoff in `hyper-relay:executing-plans`' `dispatching.md`.
```

- [x] **Step 5: `brainstorming` (§4.3).** In `skills/brainstorming/SKILL.md`, replace:
```text
7. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, add its Quartz card line if the work has a card, and commit
```
with:
```text
7. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, add its Quartz card line if the work has a card, and commit it while the main checkout is on `main` (during a branch run, `quartz link-doc` it instead; see Documentation)
```

Replace:
```text
- Commit the design document to git
```
with:
```text
- Commit the design document to git, only while the repo's main checkout is on `main` (`git branch --show-current` there prints `main`), staging it by its path. When the main checkout is on another branch, a plan is running there: do not commit. Run `quartz link-doc <spec-path>` instead (it puts an uncommitted doc on its cards; skip it without Quartz), and leave the commit for after that branch merges (`hyper-relay:executing-plans`' `dispatching.md`, step 9).
```

Replace:
```text
> "Spec written and committed to `<path>`. Please review it
```
with:
```text
> "Spec written to `<path>`. Please review it
```

- [x] **Step 6: `using-git-worktrees` (§4.4; E3).** In `skills/using-git-worktrees/SKILL.md`, replace the line:
```text
description: Use when starting feature work that needs isolation from the current workspace, or before executing an implementation plan. REQUIRED whenever the user says "worktree", "isolate this", "keep my checkout free", "work on something else while this runs", or picks the worktree option at a plan-to-execute handoff. Ensures an isolated workspace exists via native tools (EnterWorktree) or git worktree fallback.
```
with:
```text
description: Use when starting feature work of your own that needs isolation from the current workspace. REQUIRED whenever the user says "worktree", "isolate this", "keep my checkout free" or "work on something else while this runs" about such work. Not for running an implementation plan, whose executor's worktree is set up (and never entered) by executing-plans' dispatching.md. Ensures an isolated workspace exists via native tools (EnterWorktree) or git worktree fallback.
```

- [x] **Step 7: Check.**

| Run | Expected |
|---|---|
| `git grep -n -e "link-branch" -e "Two execution options" -e "Subagent-Driven" -e "subagent-driven" -- skills/writing-plans/SKILL.md` | one line: the new "No Quartz steps in a plan" sentence |
| `git grep -n -e "written and committed" -e "plan-to-execute handoff" -- skills/brainstorming skills/using-git-worktrees` | no output |
| `git grep -c "dispatching.md" -- skills/writing-plans/SKILL.md skills/brainstorming/SKILL.md skills/using-git-worktrees/SKILL.md` | `skills/brainstorming/SKILL.md:1`, `skills/using-git-worktrees/SKILL.md:1`, `skills/writing-plans/SKILL.md:4` |

- [x] **Step 8: Commit.**

```bash
git add skills/writing-plans/SKILL.md skills/brainstorming/SKILL.md skills/using-git-worktrees/SKILL.md
git commit -m "feat: writing-plans and brainstorming commit only on main and hand off to dispatching.md" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#5
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: Delete `subagent-driven-development`; re-point the skills that name it (spec §4.1, C2)

**Files:**
- Delete: `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/code-quality-reviewer-prompt.md`,
  `skills/subagent-driven-development/implementer-prompt.md`, `skills/subagent-driven-development/spec-reviewer-prompt.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`, `skills/requesting-code-review/SKILL.md`,
  `skills/voice-to-specs/SKILL.md`, `skills/writing-skills/render-graphs.js`

- [x] **Step 1: Delete the skill.**

```bash
git rm -q skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/code-quality-reviewer-prompt.md skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/spec-reviewer-prompt.md
```

- [x] **Step 2: `dispatching-parallel-agents`.** Replace:
```text
For executing an approved plan, use subagent-driven-development instead.
```
with:
```text
For executing an approved plan, use executing-plans instead.
```

- [x] **Step 3: `requesting-code-review`.** Replace:
```text
**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
```
with:
```text
**Mandatory:**
- After completing major feature
```

- [x] **Step 4: `voice-to-specs`.** Replace:
```text
- Execute plans or make code changes (that is the subagent-driven-development skill's job)
```
with:
```text
- Execute plans or make code changes (that is the executing-plans skill's job)
```

- [x] **Step 5: `render-graphs.js`.** Replace, both occurrences (Edit with `replace_all`):
```text
../subagent-driven-development
```
with:
```text
../brainstorming
```

- [x] **Step 6: Check.**

| Run | Expected |
|---|---|
| `git grep -n subagent-driven -- skills` | no output |
| `node --check skills/writing-skills/render-graphs.js` | silent |
| `git ls-files skills \| cut -d/ -f2 \| sort -u \| wc -l` | `16` |

- [x] **Step 7: Commit.**

```bash
git add skills/dispatching-parallel-agents/SKILL.md skills/requesting-code-review/SKILL.md skills/voice-to-specs/SKILL.md skills/writing-skills/render-graphs.js
git commit -m "feat: delete subagent-driven-development; executing-plans runs approved plans" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#6
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```
(The four deletions are already staged by Step 1's `git rm`; this commit includes them.)

### Task 7: Delete its live suites; the runners and testing docs stop naming it (spec §4.1; E7, E8)

**Files:**
- Delete (20): `tests/subagent-driven-dev/run-test.sh`, `tests/subagent-driven-dev/go-fractals/design.md`,
  `tests/subagent-driven-dev/go-fractals/plan.md`, `tests/subagent-driven-dev/go-fractals/scaffold.sh`,
  `tests/subagent-driven-dev/svelte-todo/design.md`, `tests/subagent-driven-dev/svelte-todo/plan.md`,
  `tests/subagent-driven-dev/svelte-todo/scaffold.sh`; `tests/claude-code/test-subagent-driven-development.sh`,
  `tests/claude-code/test-subagent-driven-development-integration.sh`; in `tests/explicit-skill-requests/prompts/`:
  `action-oriented.txt`, `after-planning-flow.txt`, `claude-suggested-it.txt`, `i-know-what-sdd-means.txt`,
  `mid-conversation-execute-plan.txt`, `skip-formalities.txt`, `subagent-driven-development-please.txt`; in
  `tests/explicit-skill-requests/`: `run-claude-describes-sdd.sh`, `run-extended-multiturn-test.sh`,
  `run-haiku-test.sh`, `run-multiturn-test.sh` (each of these four multi-turn scripts asserts only that
  `subagent-driven-development` was triggered)
- Keep: `tests/explicit-skill-requests/prompts/please-use-brainstorming.txt`, `use-systematic-debugging.txt`;
  `tests/skill-triggering/` entirely (E8); `tests/claude-code/test-helpers.sh`, `test-requesting-code-review.sh`,
  `test-document-review-system.sh`, `test-worktree-native-preference.sh`, `analyze-token-usage.py`
- Modify: `tests/claude-code/run-skill-tests.sh`, `tests/claude-code/README.md`, `tests/explicit-skill-requests/run-test.sh`,
  `docs/testing.md`
- Rewrite: `tests/explicit-skill-requests/run-all.sh`

- [ ] **Step 1: Delete.**

```bash
git rm -q tests/subagent-driven-dev/run-test.sh tests/subagent-driven-dev/go-fractals/design.md tests/subagent-driven-dev/go-fractals/plan.md tests/subagent-driven-dev/go-fractals/scaffold.sh tests/subagent-driven-dev/svelte-todo/design.md tests/subagent-driven-dev/svelte-todo/plan.md tests/subagent-driven-dev/svelte-todo/scaffold.sh
git rm -q tests/claude-code/test-subagent-driven-development.sh tests/claude-code/test-subagent-driven-development-integration.sh
git rm -q tests/explicit-skill-requests/prompts/action-oriented.txt tests/explicit-skill-requests/prompts/after-planning-flow.txt tests/explicit-skill-requests/prompts/claude-suggested-it.txt tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt tests/explicit-skill-requests/prompts/mid-conversation-execute-plan.txt tests/explicit-skill-requests/prompts/skip-formalities.txt tests/explicit-skill-requests/prompts/subagent-driven-development-please.txt
git rm -q tests/explicit-skill-requests/run-claude-describes-sdd.sh tests/explicit-skill-requests/run-extended-multiturn-test.sh tests/explicit-skill-requests/run-haiku-test.sh tests/explicit-skill-requests/run-multiturn-test.sh
```

- [ ] **Step 2: `tests/claude-code/run-skill-tests.sh`.** Replace:
```text
            echo "Tests:"
            echo "  test-subagent-driven-development.sh  Test skill loading and requirements"
            echo ""
            echo "Integration Tests (use --integration):"
            echo "  test-subagent-driven-development-integration.sh  Full workflow execution"
```
with:
```text
            echo "Tests:"
            echo "  (none at present)"
            echo ""
            echo "Integration Tests (use --integration):"
            echo "  test-requesting-code-review.sh  The code reviewer catches planted bugs"
```

Replace:
```text
# List of skill tests to run (fast unit tests)
tests=(
    "test-subagent-driven-development.sh"
)

# Integration tests (slow, full execution)
integration_tests=(
    "test-subagent-driven-development-integration.sh"
    "test-requesting-code-review.sh"
)
```
with:
```text
# List of skill tests to run (fast unit tests); none at present
tests=()

# Integration tests (slow, full execution)
integration_tests=(
    "test-requesting-code-review.sh"
)
```

Replace:
```text
for test in "${tests[@]}"; do
```
with:
```text
# ${tests[@]+...}: an empty list expands to nothing, even under set -u in bash 3.2.
for test in ${tests[@]+"${tests[@]}"}; do
```

- [ ] **Step 3: `tests/explicit-skill-requests/run-all.sh`.** Write it with exactly:

```bash
#!/usr/bin/env bash
# Run all explicit skill request tests
# Usage: ./run-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

echo "=== Running All Explicit Skill Request Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=""

# Test: use systematic-debugging
echo ">>> Test 1: use-systematic-debugging"
if "$SCRIPT_DIR/run-test.sh" "systematic-debugging" "$PROMPTS_DIR/use-systematic-debugging.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: use-systematic-debugging"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: use-systematic-debugging"
fi
echo ""

# Test: please use brainstorming
echo ">>> Test 2: please-use-brainstorming"
if "$SCRIPT_DIR/run-test.sh" "brainstorming" "$PROMPTS_DIR/please-use-brainstorming.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: please-use-brainstorming"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: please-use-brainstorming"
fi
echo ""

echo "=== Summary ==="
echo -e "$RESULTS"
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
```

- [ ] **Step 4: `tests/explicit-skill-requests/run-test.sh`.** Replace:
```text
    echo "Example: $0 subagent-driven-development ./prompts/subagent-driven-development-please.txt"
```
with:
```text
    echo "Example: $0 systematic-debugging ./prompts/use-systematic-debugging.txt"
```

- [ ] **Step 5: `tests/claude-code/README.md`.** First check the range, then delete it:

Run: `sed -n '83p;85p;117p;118p' tests/claude-code/README.md`
Expected, exactly four lines: `### Fast Tests (run by default)`, `#### test-subagent-driven-development.sh`, an empty
line, `#### test-requesting-code-review.sh`. (If not, stop and report.)

Run: `sed -i '85,117d' tests/claude-code/README.md`

Then replace:
```text
### Fast Tests (run by default)

#### test-requesting-code-review.sh
```
with:
```text
### Fast Tests (run by default)

None at present.

### Integration Tests (use --integration flag)

#### test-requesting-code-review.sh
```

Then replace, both remaining occurrences (Edit with `replace_all`):
```text
test-subagent-driven-development.sh
```
with:
```text
test-requesting-code-review.sh
```

- [ ] **Step 6: `docs/testing.md`.** First check, then delete its first 136 lines (the subagent-driven-development
  introduction, structure, run instructions and its whole integration-test section):

Run: `sed -n '137p' docs/testing.md`
Expected: `## Token Analysis Tool` (if not, stop and report).

Run: `sed -i '1,136d' docs/testing.md`

Then replace (now at the top of the file):
```text
## Token Analysis Tool

### Usage
```
with:
````text
# Testing Superpowers Skills

This document describes how to test Superpowers skills with integration tests that run real Claude Code sessions.

## Overview

Testing skills that involve subagents, workflows, and complex interactions requires running actual Claude Code sessions in headless mode and verifying their behavior through session transcripts.

## Test Structure

```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── test-requesting-code-review.sh     # The code reviewer catches planted bugs
│   ├── analyze-token-usage.py             # Token analysis tool
│   └── run-skill-tests.sh                 # Test runner
```

## Running Tests

### Integration Tests

Integration tests execute real Claude Code sessions with actual skills:

```bash
cd tests/claude-code
./run-skill-tests.sh --integration
```

**Note:** Integration tests take minutes and spend real usage.

### Requirements

- Must run from the **superpowers plugin directory** (not from temp directories)
- Claude Code must be installed and available as `claude` command
- Local dev marketplace must be enabled: `"superpowers@superpowers-dev": true` in `~/.claude/settings.json`

## Token Analysis Tool

### Usage
````

- [ ] **Step 7: Check.**

| Run | Expected |
|---|---|
| `git grep -l subagent-driven -- tests docs/testing.md` | no output |
| `bash -n tests/claude-code/run-skill-tests.sh`, then `bash -n tests/explicit-skill-requests/run-all.sh`, then `bash -n tests/explicit-skill-requests/run-test.sh` | silent |
| `git ls-files tests/explicit-skill-requests` | `prompts/please-use-brainstorming.txt`, `prompts/use-systematic-debugging.txt`, `run-all.sh`, `run-test.sh` (with their path prefix) |
| `git ls-files -s tests/explicit-skill-requests/run-all.sh tests/explicit-skill-requests/run-test.sh tests/claude-code/run-skill-tests.sh` | all three `100755`, as before (if the rewrite lost the bit, `git update-index --chmod=+x tests/explicit-skill-requests/run-all.sh`) |
| `sed -n '1p' docs/testing.md` | `# Testing Superpowers Skills` |

- [ ] **Step 8: Commit.**

```bash
git add tests/claude-code/run-skill-tests.sh tests/claude-code/README.md tests/explicit-skill-requests/run-all.sh tests/explicit-skill-requests/run-test.sh docs/testing.md
git commit -m "test: delete subagent-driven-development's live suites; the runners and testing docs stop naming it" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#7
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```
(Step 1's 20 deletions are already staged; this commit includes them.)

### Task 8: The docs say what the repo now does; the full gates; In review (spec §4.1, §6, §7.1; E12, E16)

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: `README.md`.** Replace:
```text
| Execute | `executing-plans`, `subagent-driven-development`, `using-git-worktrees`, `test-driven-development` | Commits, one per task, in their own worktree |
```
with:
```text
| Execute | `executing-plans`, `using-git-worktrees`, `test-driven-development` | Commits, one per task, on a branch or in a worktree |
```

Replace:
```text
runs the full checks once, and stops before merging | planned |
```
with:
```text
runs the full checks once, and stops before merging | on `main` |
```

- [ ] **Step 2: `CLAUDE.md`.** Replace:
```text
- `skills/<name>/`: the 17 skills. Claude Code names them `hyper-relay:<name>`; OpenCode uses the bare name.
```
with:
```text
- `skills/<name>/`: the 16 skills. Claude Code names them `hyper-relay:<name>`; OpenCode uses the bare name.
```

Replace:
```text
- `tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`, `tests/subagent-driven-dev/`:
```
with:
```text
- `tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`:
```

Replace:
```text
- Develop on a branch in a worktree under `.worktrees/`, and merge to `main`.
```
with:
```text
- Develop on a branch, in the main checkout or in a worktree under `.worktrees/` (this repo's `execute:` default is
  `branch`), and merge to `main`.
```

Replace:
```text
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges.
```
with:
```text
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges, and during a branch
  run it sees that branch's skills.
```

- [ ] **Step 3: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` (untouched; a regression check) |
| `sh tests/add-card-line/run-tests.sh \| tail -n 1` | `… 0 failed` (untouched; a regression check) |
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one and `ICON_MISSING`) |
| `dash -n bin/hyper-relay-agents`, then `dash -n tests/hyper-relay-agents/run-tests.sh` | silent |
| `bash -n tests/claude-code/run-skill-tests.sh`, `bash -n tests/explicit-skill-requests/run-all.sh`, `bash -n tests/explicit-skill-requests/run-test.sh` | silent |
| `node --check skills/writing-skills/render-graphs.js` | silent |
| `git ls-files skills \| cut -d/ -f2 \| sort -u \| wc -l` | `16` |
| `git grep -l subagent-driven -- . ':!RELEASE-NOTES.md' ':!docs/upstream' ':!docs/plans' ':!docs/superpowers' ':!scripts/check-import.sh'` | no output |
| `git grep -l subagent-driven -- docs/superpowers` | exactly A's spec and plan, C's spec and this plan (four files) |
| `git grep -n -i -w -e sat -e pentraze -- skills/executing-plans skills/agents templates bin tests/hyper-relay-agents .hyper-relay README.md CLAUDE.md` | no output |

Upstream's live suites are not run (report this): they start real `claude -p` sessions.

- [ ] **Step 4: Commit.**

```bash
git add README.md CLAUDE.md
git commit -m "docs: README and CLAUDE.md say how plans run now" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#8
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: <the URL your dispatch prompt gives>"
```
Then `git status --short` must print nothing.

- [ ] **Step 5: In review.** Run `quartz review` in the worktree. If it fails, report the failure and carry on. Then
  report (gate results with counts, every deviation, any `quartz:` line, the suites not run and why) and copy Task
  9's acceptance checklist (its Steps 1–7, with each step's PASS output) into the report. Stop: Task 9 is not yours.

### Task 9: The last task, after the merge (spec §7.2). The orchestrator runs it with the owner; NOT the executor

**Precondition:** the orchestrator has verified Task 8's report, and **the owner has merged**
`hyper-relay-c-executing-plans` into `main`. B's Task 7 is done: SAT's facts file is committed in SAT, and both repos'
agents were generated by B's generator. No planner, executor or reviewer is running in hyper-relay or SAT. The main
checkout `/home/noob_master/hyper-relay` is on `main`.

**Files (outside any worktree):** the installed plugin; `/home/noob_master/hyper-relay/.claude/agents/` and
`/home/noob_master/sat.pentraze.com/.claude/agents/` (generated, ignored); backups in `/tmp/hr-c-agents-before/`;
`/home/noob_master/sat.pentraze.com/.hyper-relay/agents.md` (committed in SAT); `/home/noob_master/.claude/CLAUDE.md`
(the owner's; untracked, nothing to commit); throwaway repos `/tmp/hr-c-probe-branch`, `/tmp/hr-c-probe-worktree`,
`/tmp/hr-c-probe-opencode`; this plan's record.

Each step gives its command and what counts as PASS. The orchestrator runs one command per Bash call.

- [ ] **Step 1: Re-check on `main` (§7.1).**

| Run | PASS |
|---|---|
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh` (last line) | `153 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/guard-test.sh` (last line) | `51 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/add-card-line/run-tests.sh` (last line) | `… 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings only the root `CLAUDE.md` one and `ICON_MISSING` |
| `git -C /home/noob_master/hyper-relay status --short` | nothing but the owner's untracked local files (`tasks/`) |

- [ ] **Step 2: Push, then the owner reinstalls.** The version stays 0.1.0.

```bash
git -C /home/noob_master/hyper-relay push origin main
claude plugin install hyper-relay@hyper-relay
```
(The owner may run the second in a session instead: `/plugin install hyper-relay@hyper-relay`.) Then:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD` and `git -C /home/noob_master/hyper-relay rev-parse main` | the same SHA |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/executing-plans/dispatching.md && echo dispatching` | `dispatching` |
| `test -e /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/subagent-driven-development || echo gone` | `gone` (E17) |

If any check fails, stop and tell the owner; do not delete or uninstall anything. Sessions started before the
reinstall keep the old copy: every later step that starts Claude Code uses a new session.

- [ ] **Step 3: The session-start notice, for real; regenerate both repos (§7.2 step 2; C12; E14).**

The notice before regenerating, from new sessions:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && claude -p "Quote verbatim every line of your context that starts with 'hyper-relay:', or reply with the single word NONE. Do nothing else."` | `hyper-relay: relay-planner, relay-executor, relay-reviewer are out of date; run hyper-relay-agents (see the hyper-relay:agents skill).` (without `relay-reviewer` if Task 3 Step 2 was dropped) |
| `cd /home/noob_master/sat.pentraze.com && claude -p "<the same prompt>"` | `hyper-relay: agents check failed: section ## executor/acceptance matches no slot in the templates; is it a typo? (the hyper-relay:agents skill lists the slots)` |

Back up the current agents:
```bash
mkdir -p /tmp/hr-c-agents-before/hyper-relay /tmp/hr-c-agents-before/sat
cp /home/noob_master/hyper-relay/.claude/agents/relay-planner.md /home/noob_master/hyper-relay/.claude/agents/relay-executor.md /home/noob_master/hyper-relay/.claude/agents/relay-reviewer.md /tmp/hr-c-agents-before/hyper-relay/
cp /home/noob_master/sat.pentraze.com/.claude/agents/sat-planner.md /home/noob_master/sat.pentraze.com/.claude/agents/sat-executor.md /home/noob_master/sat.pentraze.com/.claude/agents/sat-reviewer.md /tmp/hr-c-agents-before/sat/
```

**hyper-relay.** Run `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents`. PASS: `written .claude/agents/relay-planner.md`,
`written .claude/agents/relay-executor.md`, `written .claude/agents/relay-reviewer.md` (or `unchanged`, if Task 3
Step 2 was dropped), `unchanged .claude/hooks/hyper-relay-planner-guard.py`, and the last line
`Start a new session to use them: a running session keeps the agent definitions it loaded.`; exit 0.

Show the owner the diffs:
```bash
git diff --no-index /tmp/hr-c-agents-before/hyper-relay/relay-executor.md /home/noob_master/hyper-relay/.claude/agents/relay-executor.md
git diff --no-index /tmp/hr-c-agents-before/hyper-relay/relay-planner.md /home/noob_master/hyper-relay/.claude/agents/relay-planner.md
git diff --no-index /tmp/hr-c-agents-before/hyper-relay/relay-reviewer.md /home/noob_master/hyper-relay/.claude/agents/relay-reviewer.md
```
PASS: the executor lost "Where", "Token budget", the general Constraints bullets, "A plan that ends with an
acceptance task" and "Report" (all now in `executing-plans`' SKILL.md) and has no `## Acceptance` (hyper-relay has no
acceptance facts); the planner's Execution-notes bullets read as Task 3 Step 1 wrote them; the reviewer says "the
checkout"; the owner agrees.

**SAT.** SAT's own rules apply (its `CLAUDE.md`: named files only, from SAT's root).

| Run | PASS |
|---|---|
| `git -C /home/noob_master/sat.pentraze.com branch --show-current` | `main` |
| `git -C /home/noob_master/sat.pentraze.com diff --cached --name-only` | nothing (else stop and ask the owner) |
| `git -C /home/noob_master/sat.pentraze.com rev-parse -q --verify MERGE_HEAD` | nothing |
| `git -C /home/noob_master/sat.pentraze.com status --short` | note the output: the baseline for the last row below |

Edit `/home/noob_master/sat.pentraze.com/.hyper-relay/agents.md`, two operations (§5.4):
1. With the Edit tool, replace the header line `reviewer: browser` with the two lines `reviewer: browser` and
   `execute: worktree`.
2. `sed -i 's|^## executor/acceptance$|## executor/acceptance-worktree|' /home/noob_master/sat.pentraze.com/.hyper-relay/agents.md`

Then:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/sat.pentraze.com grep -n "quartz review" -- .hyper-relay/agents.md` | nothing. If it prints a line, that facts line still has the executor run `quartz review`, which the orchestrator now runs (C10): reword it with the owner so it no longer does, then run this check again |
| `git -C /home/noob_master/sat.pentraze.com diff -- .hyper-relay/agents.md` | `+execute: worktree`, the heading renamed, and only a rewording the owner agreed to |
| `cd /home/noob_master/sat.pentraze.com && /home/noob_master/hyper-relay/bin/hyper-relay-agents` | `written .claude/agents/sat-planner.md`, `written .claude/agents/sat-executor.md`, `unchanged .claude/agents/sat-reviewer.md`, `unchanged .claude/hooks/hyper-relay-planner-guard.py`, the restart line last; exit 0; no problems listed |
| `git diff --no-index /tmp/hr-c-agents-before/sat/sat-executor.md /home/noob_master/sat.pentraze.com/.claude/agents/sat-executor.md`, then the same for `sat-planner.md` | the executor's acceptance facts now sit under `## Acceptance` / `### In a worktree`, with no `### On a branch`; the general rules went as in hyper-relay; the owner agrees |
| `cd /home/noob_master/sat.pentraze.com && /home/noob_master/hyper-relay/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check` | nothing, exit 0 |
| `git -C /home/noob_master/sat.pentraze.com status --short` | the baseline plus ` M .hyper-relay/agents.md`, nothing else |

Commit only the facts file:
```bash
git -C /home/noob_master/sat.pentraze.com add .hyper-relay/agents.md
git -C /home/noob_master/sat.pentraze.com commit -m "chore: execute: worktree, and the acceptance-worktree slot (hyper-relay C)" -m "<the committing session's attribution lines>" -- .hyper-relay/agents.md
```
Pushing SAT's `main` follows SAT's usual flow (the owner's call).

The notice is gone, from new sessions:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && claude -p "<the prompt above>"` | `NONE` |
| `cd /home/noob_master/sat.pentraze.com && claude -p "<the prompt above>"` | `NONE` |

Per the restart line (C12), the regenerated agents are dispatched only from sessions started after this step; tell
the owner.

- [ ] **Step 4: The owner's `~/.claude/CLAUDE.md` (§7.2 step 3; E11).** Show the owner each change, and make it once
  the owner agrees. The file is not tracked (`git -C /home/noob_master ls-files .claude/CLAUDE.md` prints nothing), so
  there is nothing to commit.

(a) Replace the line:
```text
| 4 | Execute | chosen at the handoff below | code + tests |
```
with:
```text
| 4 | Execute | `hyper-relay:executing-plans`, run by a dispatched executor (below) | code + tests |
```

(b) Replace everything from the line `### The Plan → Execute handoff (always stop here)` up to and including the line
`files, several separate bugs, parallel research questions) → \`hyper-relay:dispatching-parallel-agents\`.` with:
```text
### The Plan → Execute handoff (always stop here)

Once the plan file is written and approved, STOP. The handoff, the setup, the dispatch, the rules while a plan
runs, verifying the hand-back, the review and the merge are in `hyper-relay:executing-plans`' `dispatching.md`:
invoke `hyper-relay:executing-plans` and follow `dispatching.md`. In short:

- One fresh executor runs the whole plan, in the background: the repo's `<project>-executor` when it has
  generated agents, otherwise a general-purpose agent told to invoke `hyper-relay:executing-plans`. You never
  execute a plan yourself.
- It runs on a **branch** in this checkout or in its own **worktree**, by the repo's `execute:` key in
  `.hyper-relay/agents.md`. I confirm or override at the handoff; with no key, you ask me.
- My answer is a standing request to use the Agent tool for that plan: you already have my permission. Don't
  re-ask, and don't fall back to executing it yourself because it "looks small."
- The executor stops before `hyper-relay:finishing-a-development-branch`. Verify its report, then I decide how
  it merges.

Outside of plan execution, 2+ genuinely independent problems (unrelated failing test
files, several separate bugs, parallel research questions) → `hyper-relay:dispatching-parallel-agents`.
```

(c) Replace:
```text
- **Committing a doc puts it on its cards** (`post-commit`). There is no `quartz link-doc` step. A
  slow upload is queued and retried at the next commit or when the session stops.
```
with:
```text
- **Committing a doc puts it on its cards** (`post-commit`). A slow upload is queued and retried at
  the next commit or when the session stops. A spec or plan is committed only while the main
  checkout is on `main`. During a branch run, write it, put it on its cards with
  `quartz link-doc <path>`, and commit it after the merge.
```

(d) Replace:
```text
- **Cards move on their own, with two exceptions.** A merge marks them merged (`post-merge`). Two
  steps stay manual, and the plans carry them: `quartz link-branch <plan>` when execution starts
  (In progress), and `quartz review` at the click-through (In review). In a new repo, run
  `quartz install-git-hook` once.
```
with:
```text
- **Cards move on their own, with two exceptions.** A merge marks them merged (`post-merge`). Two
  steps stay manual, and the orchestrator runs them (`dispatching.md`), not the plans:
  `quartz link-branch <plan>` when it dispatches the executor (In progress), and `quartz review`
  once it has verified the hand-back (In review). In a new repo, run `quartz install-git-hook` once.
```

(e) Replace everything from the line `### Worktrees` up to and including the line
`- When execution finishes → \`hyper-relay:finishing-a-development-branch\`.` with:
```text
### Branch runs and worktrees

- An executor runs on a **branch** in the main checkout or in its own **worktree**, by the repo's
  `execute:` key (`branch` or `worktree`); `dispatching.md` sets up either. Never on `main` itself.
- An executor's worktree is `.worktrees/<branch>` at the project root, made with `git worktree add`
  and never entered; `.worktrees/` must be gitignored first. `hyper-relay:using-git-worktrees` is
  for when you need an isolated workspace yourself.
- **While a branch run is active** (the main checkout is not on `main`), keep taking work, such as
  brainstorming other cards, by `dispatching.md`'s hold-back rules: create new files only, write
  specs and plans without committing them, no git writes. A second plan runs in a worktree.
- When execution finishes → `hyper-relay:finishing-a-development-branch`, on my call.
```

PASS: `git -C /home/noob_master grep --no-index -n -e "subagent-driven" -e "Solo" -e "the plans carry them" -e "There is no \`quartz link-doc\` step" -- .claude/CLAUDE.md`
prints nothing, and `git -C /home/noob_master grep --no-index -c "dispatching.md" -- .claude/CLAUDE.md` prints `.claude/CLAUDE.md:5`.

- [ ] **Step 5: Live probe, Branch mode, in a throwaway repo without Quartz (§7.2 step 4).** Two sessions take part:
  the **probe session** (a new interactive `claude` the owner starts in the throwaway repo; it plays the orchestrator)
  and **the orchestrator** (this hyper-relay session, which sets up and checks, read-only).

Setup (the orchestrator):
```bash
git init -q -b main /tmp/hr-c-probe-branch
```
With the Write tool, `/tmp/hr-c-probe-branch/CLAUDE.md`:
```markdown
# Toy

A throwaway repo for probing hyper-relay's executing-plans. POSIX sh. Test: `sh test.sh`.
```
and `/tmp/hr-c-probe-branch/docs/superpowers/plans/2026-11-17-toy-greet.md`, the toy plan. (Its tasks are headed
"Toy task" and its steps have no checkboxes, so that Quartz never reads them as tasks of this plan, which quotes it.)

````markdown
# Toy greet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it).

**Goal:** `greet.sh` and `bye.sh`, each with a test.

**Architecture:** Two POSIX shell scripts and one test script, `test.sh`.

**Tech Stack:** POSIX sh.

## Execution notes

- Commit after every task, staging named files only. The final commit of each task carries
  `Plan-Task: docs/superpowers/plans/2026-11-17-toy-greet.md#<N>`.
- The full gate: `sh test.sh` prints `2 passed, 0 failed`.

---

### Toy task 1: greet

**Files:**
- Create: `greet.sh`, `test.sh`

- **Step 1: Create `greet.sh`**

```sh
#!/bin/sh
# greet.sh NAME: prints a greeting.
printf 'Hello, %s!\n' "$1"
```

- **Step 2: Create `test.sh`**

```sh
#!/bin/sh
# test.sh: the toy's tests.
p=0
f=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then p=$((p + 1)); else f=$((f + 1)); printf 'FAIL %s: [%s]\n' "$1" "$3"; fi
}
check greet "Hello, Ada!" "$(sh greet.sh Ada)"
printf '%d passed, %d failed\n' "$p" "$f"
[ "$f" -eq 0 ]
```

- **Step 3: Run `sh test.sh`.** Expected: `1 passed, 0 failed`.

- **Step 4: Commit**

```bash
git add greet.sh test.sh
git commit -m "feat: greet" -m "Plan-Task: docs/superpowers/plans/2026-11-17-toy-greet.md#1"
```

### Toy task 2: bye

**Files:**
- Create: `bye.sh`
- Modify: `test.sh`

- **Step 1: Create `bye.sh`**

```sh
#!/bin/sh
# bye.sh NAME: prints a farewell.
printf 'Bye, %s!\n' "$1"
```

- **Step 2: In `test.sh`, after the line `check greet "Hello, Ada!" "$(sh greet.sh Ada)"`, add:**

```sh
check bye "Bye, Ada!" "$(sh bye.sh Ada)"
```

- **Step 3: Run `sh test.sh`.** Expected: `2 passed, 0 failed`.

- **Step 4: Commit**

```bash
git add bye.sh test.sh
git commit -m "feat: bye" -m "Plan-Task: docs/superpowers/plans/2026-11-17-toy-greet.md#2"
```
````

Then:
```bash
git -C /tmp/hr-c-probe-branch add CLAUDE.md docs/superpowers/plans/2026-11-17-toy-greet.md
git -C /tmp/hr-c-probe-branch commit -q -m "chore: toy plan" -- CLAUDE.md docs/superpowers/plans/2026-11-17-toy-greet.md
```

The owner starts the probe session: `cd /tmp/hr-c-probe-branch && claude` (accept the trust prompt), and sends:

> **M1:** The plan docs/superpowers/plans/2026-11-17-toy-greet.md is written and approved. Hand it off to an executor.

PASS: it loads `hyper-relay:executing-plans`, reads `dispatching.md`, and asks where the executor should run with the
two options, Branch and Worktree (no facts file, so no default); nothing is executed yet. The owner answers `1`.
PASS: it runs `git switch -c toy-greet`, runs no Quartz step (the toy plan names no card), dispatches ONE
general-purpose agent in the background told to invoke `hyper-relay:executing-plans`, and says it is running. Straight away the owner
sends:

> **M2:** While it runs, write a spec at docs/superpowers/specs/2026-11-17-probe-design.md with exactly these two lines: "# Probe" and "A spec written during a branch run." Then tell me whether you committed it, and why.

PASS: it writes the file and does not commit it, because a branch run is active (the hold-back rules). The
orchestrator then records `sha256sum /tmp/hr-c-probe-branch/docs/superpowers/specs/2026-11-17-probe-design.md`.

When the probe session has verified the hand-back and relayed it, the orchestrator checks:

| Run | PASS |
|---|---|
| `git -C /tmp/hr-c-probe-branch branch --show-current` | `toy-greet` |
| `git -C /tmp/hr-c-probe-branch log --format=%s main` | only `chore: toy plan` |
| `git -C /tmp/hr-c-probe-branch log --format='%s%n%(trailers:key=Plan-Task)' main..toy-greet` | `feat: bye` with `Plan-Task: docs/superpowers/plans/2026-11-17-toy-greet.md#2`, then `feat: greet` with `…#1` |
| `git -C /tmp/hr-c-probe-branch status --short` | only `?? docs/superpowers/specs/` |
| `sha256sum /tmp/hr-c-probe-branch/docs/superpowers/specs/2026-11-17-probe-design.md` | the hash recorded after M2 (the executor never touched it) |
| `git -C /tmp/hr-c-probe-branch log --all --format=%s -- docs/superpowers/specs` | nothing (committed nowhere) |

Then the owner sends **M3:** `Merge it.` The probe session uses `hyper-relay:finishing-a-development-branch`; the owner
picks option 1. Its `git pull` fails because the repo has no remote: expected; the owner tells it to carry on without
pulling. PASS, after it reports:

| Run | PASS |
|---|---|
| `git -C /tmp/hr-c-probe-branch branch --show-current` | `main` |
| `git -C /tmp/hr-c-probe-branch branch --list toy-greet` | nothing |
| `git -C /tmp/hr-c-probe-branch show --stat --format=%s HEAD` | a commit whose only file is `docs/superpowers/specs/2026-11-17-probe-design.md` (step 9: the held-back spec, committed after the merge) |
| `git -C /tmp/hr-c-probe-branch log --format=%s -3` | that commit, then `feat: bye`, then `feat: greet` |
| `git -C /tmp/hr-c-probe-branch status --short` | nothing |

- [ ] **Step 6: Live probe, Worktree mode.** Same setup in `/tmp/hr-c-probe-worktree` (the same `git init`, the same
  two files with the Write tool, the same `add` and `commit`, with `/tmp/hr-c-probe-worktree` for
  `/tmp/hr-c-probe-branch`). There is no `.gitignore`, so `dispatching.md` step 3 must add `.worktrees/` itself.
  The owner starts a new probe session there (`cd /tmp/hr-c-probe-worktree && claude`), sends M1, answers `2`, then
  sends M2 (the same text).

PASS on the way: it runs `mkdir -p .worktrees`, finds `.worktrees` not ignored, commits a `.gitignore` holding
`.worktrees/` on `main`, runs `git worktree add .worktrees/toy-greet -b toy-greet main` without entering the worktree,
and dispatches in the background. After M2 it commits the spec on `main` straight away (no branch run is active).

After the hand-back, before the merge:

| Run | PASS |
|---|---|
| `git -C /tmp/hr-c-probe-worktree branch --show-current` | `main` |
| `git -C /tmp/hr-c-probe-worktree reflog --format=%gs` | no line starts with `checkout:` (the main checkout never left `main`) |
| `git -C /tmp/hr-c-probe-worktree worktree list` | two lines; the second is `/tmp/hr-c-probe-worktree/.worktrees/toy-greet … [toy-greet]` |
| `git -C /tmp/hr-c-probe-worktree log --format='%s%n%(trailers:key=Plan-Task)' main..toy-greet` | `feat: bye` with `…#2`, then `feat: greet` with `…#1` |
| `git -C /tmp/hr-c-probe-worktree show main:.gitignore` | `.worktrees/` |
| `git -C /tmp/hr-c-probe-worktree log --format=%s main -- docs/superpowers/specs/2026-11-17-probe-design.md` | one commit |

M3 (`Merge it.`, option 1, carry on past the failing `git pull`). PASS: `git -C /tmp/hr-c-probe-worktree worktree list`
is one line, `git -C /tmp/hr-c-probe-worktree branch --list toy-greet` prints nothing, and
`git -C /tmp/hr-c-probe-worktree branch --show-current` prints `main`. (The reflog is not checked after the merge:
`finishing-a-development-branch` runs `git checkout main` there, which may log `checkout: moving from main to main`.)

- [ ] **Step 7: OpenCode, the owner (§7.2 step 5; E13).** Same setup in `/tmp/hr-c-probe-opencode`. In OpenCode in
  that folder (a model with credit), the owner sends:

> The plan docs/superpowers/plans/2026-11-17-toy-greet.md is written and approved. Load the executing-plans skill and hand it off as its dispatching.md says, on a branch.

PASS: `git -C /tmp/hr-c-probe-opencode log --format='%s%n%(trailers:key=Plan-Task)' main..toy-greet` shows the two
commits with their trailers, and `git -C /tmp/hr-c-probe-opencode log --format=%s main` only `chore: toy plan`.
**Record** (no pass or fail): did OpenCode give control back while the executor ran (could the owner send another
message and get an answer before the report came), or did it wait?

- [ ] **Step 8: Clean up; anything failed?**

```bash
rm -rf /tmp/hr-c-probe-branch /tmp/hr-c-probe-worktree /tmp/hr-c-probe-opencode /tmp/hr-c-agents-before
```
A failed step: fix it on a branch through the usual spec and plan, merge, push, reinstall (Step 2), and repeat the
step. To roll an agent back meanwhile, copy it from `/tmp/hr-c-agents-before/` before cleaning up.

- [ ] **Step 9: Record.** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 9)

- **Reinstall, <date>:** marketplace clone at <SHA>; `dispatching.md` in the 0.1.0 cache: <yes/no>;
  `subagent-driven-development` gone from it: <yes/no>.
- **Notice and regeneration:** hyper-relay <the -p line>; SAT <the -p line>; diffs agreed <yes/no, changes>; SAT's
  facts committed in SAT as <SHA>; `quartz review` reworded in SAT's facts: <yes/no>.
- **Owner's CLAUDE.md:** edits (a)–(e) made <date>; any wording the owner changed.
- **Branch probe:** <pass/fail per table; anything the probe session did differently>.
- **Worktree probe:** <pass/fail per table>.
- **OpenCode:** <pass/fail>; ran in the background: <yes/no, what the owner saw>.
```

Commit it, with this task's trailer:
```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece C last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md#9
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md
```
Push it with the next change of `main` (the owner's call).
