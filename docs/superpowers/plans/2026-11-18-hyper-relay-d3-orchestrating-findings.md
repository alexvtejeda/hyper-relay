# hyper-relay D.3: the orchestrating findings from D1 Implementation Plan

**Card:** orchestrating: findings from D1's review (`e014d2ed-116f-4a9d-9b5e-b6e2566b4cfd`)
**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-d3-orchestrating-findings-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–7 are
> the executor's. Task 8 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `owner` and
> `after merge` steps the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix D1's nine findings but the fifth: one definition of when a repo uses Quartz, with a setup that asks the
owner only for their own steps and remembers a no; stops that ask first; status notes that let a resumed orchestrator
find the review leg; and a guard test for D1's gates.

**Architecture:** A new `skills/orchestrating/quartz.md` holds the Quartz check (§1), the setup (§2), the ticks (§3)
and the Quartz duties moved out of `SKILL.md` (§4); `SKILL.md` keeps a pointer, gains the stops rule and two new
state-table rows. The three leg files, `brainstorming` and `writing-plans` change only where the spec says. A new POSIX
suite, `tests/orchestrating/run-tests.sh`, written first, guards D1's gates, the folder, the references and finding 7.

**Tech Stack:** Markdown skills; POSIX `sh` run by dash, with GNU `grep`, `sed` and `cp`; the existing suites as
regression checks; Claude Code 2.1.x and OpenCode; the `quartz` CLI and its MCP (described, never run by the executor).

**How this was checked:** written against `main` at `02cb1fd` by reading only, and revised at `396ad28` for the
owner's stop-3 answers (spec decision D3.9 and its two §2.2 bullets, read with `git show 396ad28`); nothing was built,
run, installed or generated. Read in this repo: `CLAUDE.md` (in full); the D.3 spec (in full); E.1's plan (in full, the newest plan and
this one's model); D1's plan (1–200 and 1366–1881: its header, notes, deviations, Task 9's gates, Task 10's probes and
its last-task record, which names the findings); `skills/orchestrating/SKILL.md`, `planning.md`, `dispatching.md`,
`reviewing.md`, `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, `README.md`,
`.hyper-relay/agents.md`, `tests/add-card-line/run-tests.sh` (all in full; that suite's checks counted by hand: 85);
`skills/executing-plans/SKILL.md` (60–94); `templates/agents/reviewer-commands.md` (28–42);
`tests/hyper-relay-agents/run-tests.sh` (1–60); `skills/voice-to-specs/scripts/.gitignore`. Read-only git: `git ls-files`
of `docs/superpowers/`, `skills/`, `templates/`, `tests/` (with `-o`, and `-o -i --exclude-standard`, for untracked and
ignored files under `skills/`, `templates/` and `tests/`: none); `git ls-files -s` of the four suites (all `100644`);
`git log` of the suites, the templates and the generator (nothing since D1's `a3425ed`); `git grep` for every Quartz
mention in `skills/` and `templates/`, for the Quartz MCP tool names, for `steps? [0-9]` in the relay skills, for the
D1 spec's R12, and D1's gates on `main` (all six silent; every `hyper-relay:<name>` and every `` `<file>.md` §N `` in
`skills/orchestrating/` resolves). Read outside the repo, as the dispatch allowed: Quartz's
`cli/internal/config/config.go`, `cli/internal/app/installgithook.go` and `cli/internal/app/plantick.go` (in full) and
its `README.md` (30–157). Not read: any `.mcp.json`, `.env` or `.envrc` (they may hold a token), and the Quartz MCP's
tool schemas (P13).

**External facts (re-verified 2026-11-18):**
- **Quartz: when a repo is configured** (`cli/internal/config/config.go`, `Find`). The main checkout is
  `filepath.Dir` of `git rev-parse --path-format=absolute --git-common-dir`; the CLI reads `<main checkout>/.mcp.json`,
  and a missing file, bad JSON, no `mcpServers.quartz` or an empty `url` all give `ErrNoServer` ("Hooks stay silent on
  it; link-doc and card-line report it"). The repo name is the `X-Quartz-Repo` header. **As spec §2.1, row 3.**
- **Quartz: the token** (`config.go`, `Token`). The first found of `QUARTZ_TOKEN=` in the main checkout's `.env`, a
  literal `export QUARTZ_TOKEN=` in its `.envrc`, the environment ("The repo's own files come first because the
  environment may hold another project's token"). A value counts only as a literal: quotes are stripped, ` #` comments
  cut, and a value with `$`, a backtick, a space or a tab is not found. **A difference, with no design change:** the
  README's `.envrc` line (`export QUARTZ_TOKEN=$(grep …)`) is never a token source for the CLI; it feeds direnv, and so
  the session's environment and the MCP's `${QUARTZ_TOKEN}`. The spec's token check (`.env`, or the environment) names
  the sources that matter; its `grep -q '^QUARTZ_TOKEN=.'` would also accept a non-literal value the CLI rejects, an
  edge this plan leaves alone.
- **Quartz: `install-git-hook`** (`cli/internal/app/installgithook.go`). It writes `post-merge` (`quartz hook merged ||
  true`) and `post-commit` (`quartz hook merge-commit || true`) under the git common dir's `hooks/`, "so one install
  covers every worktree"; it refuses before writing anything when `core.hooksPath` is set ("…; nothing was changed",
  exit 1); a hook that already has its line prints "already has the quartz line; nothing changed". It never reads
  `.mcp.json`, so it installs in any repo, which is how finding 7 happened. **As spec §2.2.**
- **Quartz: the post-commit tick** (`cli/internal/app/plantick.go`, `tickFromCommit`). It reads HEAD's `Plan-Task:`
  trailer; when `config.Find` fails it returns silently ("No quartz entry: no effect"); no card and no token are read
  on the way. It also needs the plan in the main checkout (otherwise a `quartz:` line says "tick task N by hand"), and
  queues the tick while the main checkout is on another branch ("ticks at the next drain"). **As spec §2.3.** That the
  `post-commit` line is what calls it was not read (the hook dispatcher is outside the four files); `installgithook.go`
  installs no other post-commit line.
- **Quartz: connecting a repo** (`README.md`, "Connect a repo's agent to the MCP"). The `.mcp.json` server, the `.envrc`
  lines and the `.env` line are the shapes spec §2.2 gives, and "Start `claude` from a shell inside the repo, so that
  it inherits the token". The README ignores `.env` with `echo .env >> .gitignore`; the spec uses `.git/info/exclude`
  instead (no tracked-file edit), deliberately. **As spec §2.2.**
- **Claude Code `claude -c`** ([code.claude.com/docs/en/cli-reference](https://code.claude.com/docs/en/cli-reference),
  fetched 2026-11-18): "Continue most recent conversation in current directory". **As spec §2.2** (`claude --continue`
  keeps the conversation over a restart).
- **jq `-e`** ([jqlang.org/manual](https://jqlang.org/manual/), fetched 2026-11-18): "Sets the exit status of jq to 0
  if the last output value was neither `false` nor `null`, 1 if the last output value was either `false` or `null`, or
  4 if no valid result was ever produced"; `strings` selects "only inputs that are … strings". Used by P1.

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top unless they start with `~` or `/`. This plan is
  committed on `main`.
- **The skill you follow is not the one you write.** Your preloaded `executing-plans` and this run's orchestrator are
  the installed plugin's copies. This plan rewrites the repo's relay skills; follow your agent instructions and this
  plan, not the new text.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#<N>` followed, inside the
  same quoted paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and
  `Claude-Session:` with the URL from your dispatch prompt). The commands below write them as
  `<the line your instructions give>` and `<the URL your dispatch prompt gives>`: put the real lines there. Never tick
  the plan. Report every `quartz:` line a commit prints, verbatim.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly. If X is not found, read the
  range again; if the text moved or differs slightly, adapt as little as possible and record it as a deviation; if it
  is gone, stop and report. Text in code blocks is exact, down to its line breaks and spaces: transcribe it.
- **Quartz is described here, not run.** Never run a `quartz` command, `git config hyper-relay.quartz` or
  `git config --global …` in this repo, and never read or print `.env`, `.envrc` or `.mcp.json`: they hold this
  checkout's Quartz wiring and token. Your commits run Quartz's git hooks on their own, which is fine.
- **Never** start a live `claude -p` / `opencode run` session, install or uninstall a plugin, push, tag, or create
  anything on GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites (`tests/claude-code/`,
  `tests/explicit-skill-requests/`, `tests/skill-triggering/`): they start `claude -p`.
- **Outside your branch is not yours.** Never touch `main`, `~/.claude/`, `~/.config/opencode/`, `/tmp/hr-d3-*`, any
  other project's repo or the home directory's own repo. Task 8's `owner` and `after merge` steps do what is needed
  there, and they are not yours.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's scratch tracker (excluded in
  `.git/info/exclude`): never stage, edit, move or delete either. A "the tree is clean" check ignores them.
- **This repo is public.** Nothing you write into the repo or a commit message names another project or quotes its
  files.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs the new suite (`sh tests/orchestrating/run-tests.sh | tail -n 1`, or piped through
  `grep`) and its own `git grep` checks only. The full gates run once, in Task 7: the suites this plan touches (the
  Checks table in `CLAUDE.md`: the new suite, plus `tests/hyper-relay-agents/` and `tests/add-card-line/` as regression
  checks, as spec §9 lists), `dash -n` of the one script, and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 8. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`owner`** (at the click-through) or **`after merge`** (the owner and the orchestrator), with its command or action
  and the result that counts as PASS. After Task 7, report (gate results with counts, every deviation, any `quartz:`
  line, the suites not run and why), copy Task 8's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §2.1 row 3: "the CLI's own test", with no command | `quartz.md` §1 gives it as a command that prints nothing from `.mcp.json` (which may hold other servers' secrets): `jq -e '.mcpServers.quartz.url \| strings \| length > 0'`, true exactly when the url is a non-empty string, as in `config.go`; a `python3 -c` line when `jq` is missing. |
| P2 | §2.2, a repo name: the four file and hook steps, then a message, then "the next check (§1) finishes the setup"; §9 (b): the missing token and MCP "are each reported once" while brainstorming carries on | Setup's fourth step is "Run §1 again": it now gives row 3, so the connected checks run at once, and their Hooks check is the `quartz install-git-hook` the spec lists (it runs once, not twice). Setup's closing message then opens with the token prompt when the token check failed (D3.9), then the `direnv allow` and restart lines, then each other check that failed, in one line; its last step says the relay waits for neither the token nor the restart. That is how probe (b)'s reports happen during brainstorming. |
| P3 | §2.2: `.env` is ignored; "`.mcp.json` and `.envrc` … stay untracked" | **Decided by the owner (2026-11-18, stop 3): yes, now spec D3.9.** Setup also adds `.mcp.json` and `.envrc` to `.git/info/exclude` when git does not track them. An untracked, unignored file shows as `??` in `git status --short`, and on a branch run that stops the acceptance reviewer ("Before you start" step 2 in `templates/agents/reviewer-commands.md`: only untracked `docs/superpowers/` files may show) and `dispatching.md` §7's clean-tree check. The exclude line is local and commits nothing; committing the files stays the owner's call. Probe (b) checks it. |
| P4 | §2.2: a failed step is reported "once", and "the next check (§1) retries it" | Once per session: a retry that fails again says nothing more. |
| P5 | §5: the review status comes from the card (`get_task`), and without Quartz the orchestrator asks | Also asks when the repo uses Quartz but its MCP is not loaded in this session: the status cannot be read then. |
| P6 | §1 changes "The stops" in `SKILL.md` by adding a rule | Its table's rows 3 and 4 list the same items in the new order (questions first), so the table does not contradict the rule. |
| P7 | §7: `brainstorming`'s step 1 text reads "**Quartz:** run …"; its Quartz conditions point at `quartz.md` §1; "Steps 7 and the Documentation bullets keep their card conditions" | Step 1 keeps the checklist's own form (`1. **Quartz** — …`), with the spec's sentences. The card conditions are kept; the one Quartz condition in Documentation ("skip it without Quartz", for `link-doc`) points at step 1. Likewise `planning.md` §1's branch-run bullet gains "(when the repo uses Quartz)". `SKILL.md`'s "With Quartz, the card's column is a cross-check" and the bare `quartz review` / `link-doc` mentions in `dispatching.md` stay: `SKILL.md`'s new pointer ("Every Quartz step runs only when its §1 says the repo uses Quartz") governs them. |
| P8 | §2.3: ticks come only when the repo is connected and its "hooks are installed" | `quartz.md` §3 makes it checkable: `grep -q 'quartz hook merge-commit' "$(git rev-parse --git-path hooks)/post-commit"`, which reads the hooks git really runs (`core.hooksPath` included). |
| P9 | §2.4: the duties move "unchanged" | The card-line script is named relative to `quartz.md` only (`../brainstorming/scripts/add-card-line.sh` from this file), as the other leg files name theirs: Claude Code expands `${CLAUDE_SKILL_DIR}` only in a skill's `SKILL.md`, and a file read with the Read tool would show it unexpanded. The "Plan tasks tick themselves" bullet gains "(§3)". |
| P10 | §8: the guard's checks | Written as eleven checks, each with a case that breaks a copy of the tree (thirteen cases: check 1b and check 4b have two failure modes each, so two cases): `24 passed, 0 failed`. Checks 4a and 4b also fail when they find no reference at all, so they cannot pass vacuously; 4b's file-name pattern takes `-`, `_` and digits, so a hyphenated file outside the folder fails it. Check 5 requires the list to be exactly `skills/orchestrating/quartz.md`, so it also fails if `quartz.md` stops naming the command. The suite sets `LC_ALL=C` (byte-wise `ls` order and matching) and uses GNU `grep -r` and `sed -i`, as the other suites lean on GNU tools (`stat -c`). |
| P11 | §6: in README's diagram, "`writing-plans` becomes `plan` (a planner agent)", and a line under it shows `orchestrating` from the spec to the merge | The node is `plan`, annotated "(a planner agent)" in place of "(one plan per subsystem)"; the annotations are re-laid on two rows so each starts under its node; a fourth line, `└─── orchestrating ───┘`, spans `spec` to `merge` (Task 7 Step 1). |
| P12 | §9: the acceptance task's steps | It ends, as D1's did (its E16), with a last-task record appended to this plan after the probes, committed with Task 8's `Plan-Task:` trailer, which ticks Task 8 in this connected repo. |
| P13 | §2.2, §4, §5: the Quartz MCP's `list_tasks`, `add_tasks`, `tick_brain`, `get_task` (its current status and docs) and `add_note` (`status: true`, at most 500 characters) | **Not re-verified:** the dispatch limited the Quartz reads to four files, and no Quartz MCP tool is loaded in the planner's session. `tick_brain` and `add_tasks` are already in use; `add_note`'s `status` and `get_task`'s status and docs are new to the relay. Any call that errors is reported once and falls back (§2.2's failure rule), so a wrong name costs a line, not the relay. The orchestrator may confirm the two new ones before dispatch. |
| P14 | §1: two `CLAUDE.md` edits | Only those two: the Layout bullet that lists the `tests/` folders is left as it is. |
| P15 | §9: `claude plugin validate .` passes "with exactly §6's three warnings" | `PRIVACY_URL_MISSING` comes from the gitignored `.mcp.json`, so it appears in the main checkout only: a worktree run gives two warnings. Task 7 and Task 8 accept either, by where they run. |
| P16 | §9's three probes | In throwaway repos under `/tmp`, built as D1's were (the toy repo, its spec, its generated agents). Probes (a) and (b) need the `quartz` CLI on the owner's `PATH`, or they would meet row 1 and prove nothing. Probe (c)'s repo is declined with `git config hyper-relay.quartz off` (otherwise it would meet row 4 and offer setup first), and its plan, task commit and fix commit are made by hand. |
| P17 | §6: "The plan greps the four leg files for any other section reference written as 'step N'" | Read as `SKILL.md`, `planning.md`, `dispatching.md` and `reviewing.md`: only the two §6 names (`dispatching.md` lines 45 and 104). The new `quartz.md` says "`brainstorming`'s step 1", which names a checklist step, not a section. |
| P18 | §7: the planner template is not changed | Nor is any other template, so no agent is regenerated; Task 8 Step 11 checks `hyper-relay-agents --check` prints nothing. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–8 |
| Decisions (owner, 2026-11-18) | D3.1: 1–8 (finding 5 is not touched). D3.2, D3.3, D3.4: 2. D3.5: 3, 4, 5. D3.6: 3, 5. D3.7: 2, 6. D3.8: 1, 7. D3.9: 2; 8 (Steps 6, 9, 14b) |
| 1. What changes where | 1 (the test), 2 (`quartz.md`, `SKILL.md`'s pointer), 3 (`SKILL.md`'s stops and state table), 4 (`planning.md`, `dispatching.md`), 5 (`reviewing.md`), 6 (`brainstorming`, `writing-plans`), 7 (`README.md`, `CLAUDE.md`) |
| 2. `skills/orchestrating/quartz.md` | 2 (§2.1–§2.4); 5 (§2.3's hand ticks in `reviewing.md` §5); 8 (Steps 6, 14) |
| 3. The stops (finding 6) | 3 (the rule), 4 (stop 3), 5 (stop 4); 8 (Steps 7, 14a) |
| 4. The review leg (findings 9 and 1) | 5; 8 (Steps 5, 14a) |
| 5. Finding where work stands (findings 2 and 1) | 3; 8 (Steps 7, 14c) |
| 6. Wording fixes (finding 4) | 4 (`dispatching.md`, `planning.md` §2), 5 (`reviewing.md` §2), 6 (the anti-pattern), 7 (README, `CLAUDE.md`'s `validate` row) |
| 7. One definition, everywhere | 4, 5, 6 |
| 8. The guard test (finding 3) | 1; 7 (its Checks row) |
| 9. Acceptance | 8 |
| 10. Out of scope | Execution notes; 8 (Step 4: nothing else changes) |

## File structure

- **Create (Task 1):** `tests/orchestrating/run-tests.sh`, the guard.
- **Create (Task 2):** `skills/orchestrating/quartz.md`. **Modify (Tasks 2, 3):** `skills/orchestrating/SKILL.md`.
- **Modify (Task 4):** `skills/orchestrating/planning.md`, `skills/orchestrating/dispatching.md`.
- **Modify (Task 5):** `skills/orchestrating/reviewing.md`.
- **Modify (Task 6):** `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`.
- **Modify (Task 7):** `README.md`, `CLAUDE.md`.
- **Unchanged:** `templates/`, `bin/`, `hooks/`, the other skills and suites.
- **Task 8, outside the branch (owner and orchestrator):** the push, the installed plugin, throwaway repos under
  `/tmp/hr-d3-*`, and this plan's record on `main`.

---

### Task 1: The guard test, written first (spec §8; D3.8; P10)

**Files:**
- Create: `tests/orchestrating/run-tests.sh`

- [x] **Step 1: Write the suite.** Create `tests/orchestrating/run-tests.sh` with exactly this content:

```sh
#!/bin/sh
# POSIX guard for the relay skills (hyper-relay D.3): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, and `quartz install-git-hook`
# named only in quartz.md. It reads the working tree, not git's index, so an untracked
# new file counts and it runs the same in a worktree. Each check also runs on a copy of
# the tree broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "24 passed, 0 failed"
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

# --- 2. The folder holds exactly the map, the three leg files and quartz.md.
orchestrating_folder() (
    cd "$1/skills/orchestrating" || exit 2
    got=$(ls -A | tr '\n' ' ')
    want='SKILL.md dispatching.md planning.md quartz.md reviewing.md '
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

CHECKS='no_old_dispatching_pointer dispatching_pointers_name_orchestrating old_dispatching_gone
no_subagent_driven code_review_not_per_task brainstorming_never_invokes_writing_plans orchestrating_folder
no_machine_paths skill_names_resolve section_refs_resolve install_git_hook_only_in_quartz_md'

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

broken "a sixth file in skills/orchestrating"
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

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
```

- [x] **Step 2: Syntax.**

Run: `dash -n tests/orchestrating/run-tests.sh`
Expected: silent, exit 0.

- [x] **Step 3: Run it; exactly two checks fail, because `quartz.md` does not exist yet.**

Run: `sh tests/orchestrating/run-tests.sh | grep -A 1 -e '^FAIL' -e 'passed, '`
Expected, in this order:

```text
FAIL orchestrating_folder
       expected [SKILL.md dispatching.md planning.md quartz.md reviewing.md ], got [SKILL.md dispatching.md planning.md reviewing.md ]
FAIL install_git_hook_only_in_quartz_md
       expected only [skills/orchestrating/quartz.md], got [skills/orchestrating/SKILL.md]
22 passed, 2 failed
```

(with `--` lines between the groups, which are `grep`'s). Also run
`sh tests/orchestrating/run-tests.sh | grep -c '^ok   .* can fail: '`: expected `13`, so every broken copy fails its
check. If anything else fails, stop and report: the tree differs from the one this plan read.

- [x] **Step 4: Commit.**

```bash
git add tests/orchestrating/run-tests.sh
git commit -m "test: a guard for the relay skills: D1's gates, references, and who installs Quartz's hooks" -m "tests/orchestrating/run-tests.sh reads the working tree: D1's six gates, the orchestrating folder, no machine paths, hyper-relay:<name> and file §N references that resolve, and quartz install-git-hook named only in quartz.md. Each check also runs on a copy of the tree broken one way, where it must fail. Two checks fail until quartz.md exists." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: `quartz.md`, and `SKILL.md` points at it (spec §2, §7; D3.2–D3.4, D3.7, D3.9; findings 7, 8; P1–P4, P8, P9)

**Files:**
- Create: `skills/orchestrating/quartz.md`
- Modify: `skills/orchestrating/SKILL.md:23-27` (the leg files), `:63-81` (Quartz duties)

- [x] **Step 1: Create `skills/orchestrating/quartz.md`** with exactly this content:

````markdown
# Quartz in the relay

Part of `orchestrating` (`SKILL.md` beside this file is the map). Quartz is the project board the relay keeps in step
with its specs, plans and commits. This file says when a repo uses it (§1), how a repo gets set up (§2), what ticks a
plan's tasks (§3), and the Quartz duties (§4). `orchestrating` reads it at the start of every leg, and
`hyper-relay:brainstorming` runs §1 and §2 at its step 1, before any other leg.

## 1. Does this repo use Quartz?

Read it from files and git every time, never from memory: at `brainstorming`'s step 1, and whenever `orchestrating`
starts or resumes a leg. Run the tests in this order; **the first match decides**:

| # | State | Test | Result |
|---|---|---|---|
| 1 | No CLI | `command -v quartz` fails | **No Quartz.** Plain Markdown and git; nothing is said or offered. |
| 2 | Declined | `git config --get hyper-relay.quartz` prints `off` | **No Quartz.** Nothing else is checked, offered or said, and no Quartz MCP tool is used, even when one is loaded. |
| 3 | Connected | the main checkout's `.mcp.json` has `mcpServers.quartz` with a non-empty `url` (the CLI's own test) | **Quartz.** §2's checks run. |
| 4 | Not connected | none of the above | **Setup** (§2), and no Quartz until it is connected. |

The main checkout is the parent of `git rev-parse --path-format=absolute --git-common-dir`. Run row 3's test without
printing the file, which may hold other servers' secrets. This succeeds exactly when the repo is connected:

```sh
jq -e '.mcpServers.quartz.url | strings | length > 0' <main checkout>/.mcp.json >/dev/null 2>&1
```

Without `jq`:

```sh
python3 -c 'import json,sys; u=json.load(open(sys.argv[1])).get("mcpServers",{}).get("quartz",{}).get("url"); sys.exit(not (isinstance(u,str) and u))' <main checkout>/.mcp.json 2>/dev/null
```

"Uses Quartz" means row 3, and only row 3. Every Quartz step in the relay (tick brain, card lines, `link-doc`,
`link-branch`, `quartz review`, status notes, proposed cards) runs only on that result; none has a check of its own.

`git config --get` reads every scope, so `git config --global hyper-relay.quartz off` declines every repo on the
machine. The undo is `--unset`, in the same scope: `git config --unset hyper-relay.quartz`, or
`git config --global --unset hyper-relay.quartz`.

## 2. Setup, without asking first

**Configured properly** means all four: the repo is connected and has a token; Quartz's git hooks are installed; the
work has a card; the spec and the plan carry its card line (a plan through its `**Spec:**` line). Do every step you
can, and ask the owner only for the steps only they can do.

### Not connected (§1, row 4)

Send this as a message of its own, and wait for the answer:

> This repo isn't on a Quartz board yet, so I'll connect it. Three steps are yours, in Quartz's web app:
> 1. Create a project (or pick one), and add this repo to it by name.
> 2. Create a token, and put it in this repo's `.env` as `QUARTZ_TOKEN=<token>`. Not in the chat.
> 3. Tell me the repo name, and Quartz's MCP URL if it isn't `http://127.0.0.1:8083/mcp`.
>
> Or say "no Quartz here", and I won't offer this again in this repo.

- **A no:** run `git config hyper-relay.quartz off`, reply in one line that names the undo
  (`git config --unset hyper-relay.quartz`), and carry on with no Quartz.
- **Neither** (for example "not now"): carry on with no Quartz for this session. The offer comes again in the next
  session, not at the next leg.
- **A repo name:** the steps below, in the main checkout, without asking again.

1. `.mcp.json`: add this `quartz` server, with the owner's URL when they gave one, keeping any other servers; create
   the file when there is none.

   ```json
   { "mcpServers": { "quartz": {
       "type": "http",
       "url": "http://127.0.0.1:8083/mcp",
       "headers": {
         "Authorization": "Bearer ${QUARTZ_TOKEN}",
         "X-Quartz-Repo": "<repo name>"
   } } } }
   ```

2. `.envrc`: when it has no `QUARTZ_TOKEN` line, append these two lines.

   ```sh
   watch_file .env
   export QUARTZ_TOKEN=$(grep '^QUARTZ_TOKEN=' .env 2>/dev/null | cut -d= -f2)
   ```

3. `.env` ignored: `git check-ignore -q .env` succeeds, or add a `.env` line to `.git/info/exclude`. Do the same for
   `.mcp.json` and `.envrc` when git does not track them, so they stay out of a branch run's clean-tree checks.
4. Run §1 again. It now gives row 3, so run the checks below (they install the hooks).
5. Then one message. When the token check (below) failed, it opens with the prompt for the token: create it in the
   project's settings in Quartz's web app, and put it in `<main checkout>/.env` as `QUARTZ_TOKEN=<token>`, in an
   editor, never in the chat; `.envrc` loads it from there. Then: run `direnv allow`, then restart the session from a
   shell in the repo, so the MCP server and its token load (in Claude Code, `claude --continue` keeps the
   conversation); without direnv, export `QUARTZ_TOKEN` before starting the session. Then each other check that
   failed, in one line ("A step that fails", below; until the restart, the MCP is one). `.mcp.json` and `.envrc` hold
   no secret and stay untracked: committing them is the owner's call.
6. Carry on meanwhile. The relay never waits for the token or the restart; the next check (§1) finishes the setup.

When `.mcp.json` or `.envrc` is tracked, its edit is a tracked-file edit: during a branch run it waits for the merge
(`dispatching.md` §6).

### Connected (§1, row 3)

Run each check below. One that cannot complete is a failure (below); the rest still run.

- **Hooks:** run `quartz install-git-hook`. It changes nothing when the hooks are already there.
- **Token:** found when the main checkout's `.env` has a `QUARTZ_TOKEN=` line with a value
  (`grep -q '^QUARTZ_TOKEN=.' <main checkout>/.env`), or `QUARTZ_TOKEN` is set in the environment
  (`[ -n "${QUARTZ_TOKEN:-}" ]`). Never print it.
- **MCP:** the Quartz MCP tools (in Claude Code, `mcp__quartz__…`) are among your tools or deferred tools; load a
  deferred one with ToolSearch before calling it. In OpenCode they also need the server in OpenCode's own config.
- **Card** (at `brainstorming`'s step 1, with the MCP): the card the owner names; otherwise one in Needs brainstorming
  that matches the work (`list_tasks`); otherwise a new one through `add_tasks`, titled with the work's topic, kind
  `bug` or `change` when one fits, in the initiative the owner names, if any. Say so in one line, with its id. Then
  `tick_brain` with its id.
- **Card lines:** as `brainstorming`'s Documentation says. A card that arrives after its spec was written (the MCP
  loaded late) gets its line then, with brainstorming's script (§4); a spec already committed gets it in a commit of
  just the spec, while the main checkout is on `main`.

**A step that fails** (no token, no MCP in this session, `install-git-hook` refused because `core.hooksPath` is set,
an MCP call that errors): report it once in the session, in one line saying what the owner can do, and carry on.
Whatever needs the missing piece falls back to plain Markdown and git. The next check (§1) retries it. Quartz never
blocks the relay.

## 3. Ticks

Quartz's post-commit hook ticks a committed task (its `Plan-Task:` trailer) only in a **connected** repo (§1, row 3's
test) whose hooks are installed: `grep -q 'quartz hook merge-commit' "$(git rev-parse --git-path hooks)/post-commit"`
succeeds. It needs no card and no token.

In any other repo, nothing ticks a committed task. After the merge (`reviewing.md` §5), when you tick the acceptance
task by hand, tick every task that has a `Plan-Task:` commit in the same edit, and commit just the plan:
`docs: plan progress, tasks 1–M of M`. Stop 4 promises a Quartz tick only when this section says one will come.

## 4. The duties

Each runs only when §1 says the repo uses Quartz.

- Every spec and plan carries its card line in its header, above its first `---` or `## `:
  ``**Card:** <title> (`<uuid>`)``, or `**Cards:**` with several, comma-separated. Card ids are full UUIDs only.
  Write the line with brainstorming's script, `add-card-line.sh` (`../brainstorming/scripts/add-card-line.sh` from
  this file). A plan with no card line inherits its spec's cards through its `**Spec:**` line.
- A spec or plan is committed only while the main checkout is on `main`. During a branch run, `quartz link-doc <path>`
  puts it on its cards, and it is committed after the merge (`reviewing.md` §5).
- `quartz link-branch` at dispatch and `quartz review` after verifying the hand-back (`dispatching.md` §4 and §7).
- Plan tasks tick themselves (§3): a task's final commit carries its `Plan-Task:` trailer, and a hook ticks the task.
  Tick by hand only when a `quartz:` line says to, or when a task has no commit: tick its checkboxes on `main` and
  commit just the plan, with the message `docs: plan progress, task N of M`.
- A `quartz:` line printed by a commit is the only Quartz output to act on: do what it says.
- **Don't report what the board shows:** never list done tasks, tick counts or per-task commits. Report failures, gate
  results, deviations and the decisions the owner must make.
- After each review leg, a status note on each of the plan's cards (`reviewing.md` §2 and §3), which a resumed
  orchestrator reads (`SKILL.md`, Finding where work stands).
- The proposed cards the owner keeps are added through the Quartz MCP (`reviewing.md` §4).
````

- [x] **Step 2: `SKILL.md` names `quartz.md` among the files beside it (spec §2.4).** In
  `skills/orchestrating/SKILL.md`, replace:

```text
The three leg files are beside this SKILL.md. Read each one when the loop reaches its leg, not before:

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md).
```

with:

```text
The three leg files and `quartz.md` are beside this SKILL.md. Read each leg file when the loop reaches its leg, not
before, and `quartz.md` at the start of every leg (Quartz duties, below):

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/quartz.md` (`quartz.md` beside this SKILL.md).
```

- [x] **Step 3: The Quartz duties become a pointer (spec §2.4).** In `skills/orchestrating/SKILL.md`, replace the
  whole section, from its heading to the line before `## Fallbacks`:

```text
## Quartz duties

Each falls back to plain Markdown and git without Quartz.

- Every spec and plan carries its card line in its header, above its first `---` or `## `:
  ``**Card:** <title> (`<uuid>`)``, or `**Cards:**` with several, comma-separated. Card ids are full UUIDs only.
  Write the line with brainstorming's script, `${CLAUDE_SKILL_DIR}/../brainstorming/scripts/add-card-line.sh` (`../brainstorming/scripts/add-card-line.sh` from this SKILL.md).
  A plan with no card line inherits its spec's cards through its `**Spec:**` line.
- A spec or plan is committed only while the main checkout is on `main`. During a branch run, `quartz link-doc <path>`
  puts it on its cards, and it is committed after the merge (`reviewing.md` §5).
- `quartz link-branch` at dispatch and `quartz review` after verifying the hand-back (`dispatching.md` §4 and §7).
- Plan tasks tick themselves: a task's final commit carries its `Plan-Task:` trailer, and a hook ticks the task. Tick
  by hand only when a `quartz:` line says to, or when a task has no commit: tick its checkboxes on `main` and commit
  just the plan, with the message `docs: plan progress, task N of M`.
- In a repo new to Quartz, run `quartz install-git-hook` once.
- A `quartz:` line printed by a commit is the only Quartz output to act on: do what it says.
- **Don't report what the board shows:** never list done tasks, tick counts or per-task commits. Report failures, gate
  results, deviations and the decisions the owner must make.
- The proposed cards the owner keeps are added through the Quartz MCP (`reviewing.md` §4).
```

with:

```text
## Quartz duties

Read `quartz.md` beside this file (`${CLAUDE_SKILL_DIR}/quartz.md`) at the start of every leg. Every Quartz step runs
only when its §1 says the repo uses Quartz.
```

- [x] **Step 4: The guard passes now.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `git grep -n -F 'quartz install-git-hook' -- skills` | one line, in `skills/orchestrating/quartz.md` (the Hooks check) |
| `git grep -n -i 'without Quartz' -- skills/orchestrating/quartz.md skills/orchestrating/SKILL.md` | nothing |
| `git grep -c 'CLAUDE_SKILL_DIR' -- skills/orchestrating` | `skills/orchestrating/SKILL.md:5` only |

(`git grep` searches tracked files only, and `quartz.md` is new: run `git add skills/orchestrating/quartz.md` before
these greps.)

- [x] **Step 5: Commit.**

```bash
git add skills/orchestrating/quartz.md skills/orchestrating/SKILL.md
git commit -m "feat: orchestrating's quartz.md says when a repo uses Quartz, sets it up, and holds the duties" -m "One check, read from files and git each time: no CLI, declined (git config hyper-relay.quartz off), connected (.mcp.json has a quartz url), or not connected, which starts a setup that asks the owner only for their own steps and remembers a no. Setup keeps .mcp.json and .envrc out of git status, and its closing message opens with the token prompt when the token is missing; the connected checks install the hooks and report each missing piece once. Ticks come only in a connected repo with its hooks; elsewhere the orchestrator ticks by hand after the merge. SKILL.md's Quartz duties move here, without the unconditional install-git-hook, with status notes added; SKILL.md keeps a pointer." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: `SKILL.md`: the stops ask first; resuming finds the review leg (spec §3, §5; D3.5, D3.6; findings 6, 2, 1; P5, P6)

**Files:**
- Modify: `skills/orchestrating/SKILL.md` (The stops; Finding where work stands)

- [x] **Step 1: The stops rule, and rows 3 and 4 in the new order.** In `skills/orchestrating/SKILL.md`, replace:

```text
| 3. Plan ready | The hand-back check's result, the planner's deviations, the decisions the owner must make, the plan-review offer, the handoff question (`planning.md` §3) | execution, a plan review, or plan changes |
| 4. Ready to merge | Gate and acceptance results, fixes made, Critical findings fixed or dropped, proposed cards (`reviewing.md` §4) | the click-through and the merge |
```

with:

```text
| 3. Plan ready | Its questions first: the decisions the owner must make, the plan-review offer, the handoff question. Then the hand-back check's result and the planner's deviations (`planning.md` §3) | execution, a plan review, or plan changes |
| 4. Ready to merge | Its questions first: the proposed cards, the steps that are the owner's, where to click through. Then gate and acceptance results, fixes made, Critical findings fixed or dropped (`reviewing.md` §4) | the click-through and the merge |

A stop that asks anything opens with its questions, numbered, before any report: every question, and every decision
the owner must make. The report follows, short: one line per item, and nothing the board shows. No question comes
after the report.
```

The existing blank line and the paragraph "A stop ends the message: …" follow it unchanged.

- [x] **Step 2: A spec with no plan is offered, not assumed (finding 2).** Replace:

```text
| A spec that no plan's `**Spec:**` line names | The planner leg, once the owner has approved the spec: their asking to pick it up is that approval. Never brainstorm it again. |
```

with:

```text
| A spec that no plan's `**Spec:**` line names | **Offer** the planner leg: name the spec and ask whether to plan it; the owner's yes is the approval. When the owner asked to pick up that spec, the request is the yes. Never brainstorm it again. |
```

- [x] **Step 3: A branch with every executor task committed goes by its review status (finding 1).** Replace:

```text
| A plan's branch with all its executor tasks committed | `dispatching.md` §7 (verify), then `reviewing.md` |
```

with:

```text
| A plan's branch with all its executor tasks committed | By its review status (below) |
```

Then replace:

```text
The branch name comes from the plan's file name (`dispatching.md` §3). To read the state:
```

with:

```text
**A branch with all its executor tasks committed** goes by its review status. In a repo that uses Quartz, with its MCP
loaded (`quartz.md` §1 and §2), that is the current status note on the plan's cards (`get_task`), counted only when it
names this plan's path (`reviewing.md` §2 and §3 post it). Otherwise the last row applies.

| Review status | Leg |
|---|---|
| None, and no fix commits on the branch | `dispatching.md` §7 (verify), then `reviewing.md` §1 |
| "acceptance done" | `reviewing.md` §3 |
| "code review done" | Stop 4 (`reviewing.md` §4) |
| The repo does not use Quartz or its MCP is not loaded, or no status but fix commits | **Ask the owner** which review legs ran, naming the fix commits. Rerun nothing on your own. |

A fix commit is a commit on `main..<branch>` with no `Plan-Task:` trailer, after the branch's last `Plan-Task:`
commit: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>` lists the branch's commits, newest
first, and the fix commits are those above the newest one with a trailer.

The branch name comes from the plan's file name (`dispatching.md` §3). To read the state:
```

- [x] **Step 4: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `git grep -n -F 'No question comes' -- skills/orchestrating/SKILL.md` | one line |
| `git grep -n -F '**Offer** the planner leg' -- skills/orchestrating/SKILL.md` | one line |
| `git grep -n -e '"acceptance done"' -e '"code review done"' -e 'A fix commit is' -- skills/orchestrating/SKILL.md` | three lines |

- [x] **Step 5: Commit.**

```bash
git add skills/orchestrating/SKILL.md
git commit -m "feat: orchestrating's stops ask first; a resumed run finds the review leg or asks" -m "A stop that asks anything opens with its numbered questions, then a short report. A spec with no plan is offered, not assumed. A branch with every executor task committed goes by the review status note on its cards; without Quartz or its MCP, or with fix commits and no status, the orchestrator asks the owner which review legs ran." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `planning.md` and `dispatching.md` (spec §3, §6, §7; D3.5; findings 6, 4, 7; P7, P17)

**Files:**
- Modify: `skills/orchestrating/planning.md:25-29` (§1's prompt), `:36-37` (§2 check 1), `:55-70` (§3)
- Modify: `skills/orchestrating/dispatching.md:45` (§2), `:73` (§4), `:104` (§6)

- [x] **Step 1: The planner hears whether the repo uses Quartz (spec §7).** In `skills/orchestrating/planning.md`,
  replace:

```text
  - the Claude-Session URL, when your harness gives you one;
  - anything unusual;
  - **during a branch run:** read `main`'s code with `git show main:<path>`; the plan will not be committed (the
    planner's own check refuses), so the planner puts it on its cards with `quartz link-doc` and you commit it after
    the merge (`reviewing.md` §5).
```

with:

```text
  - the Claude-Session URL, when your harness gives you one;
  - whether the repo uses Quartz (`quartz.md` §1), and when it does not, "Run no `quartz` command.": a planner cannot
    run the check itself, and in a declined repo that is still connected its `quartz link-doc` would upload;
  - anything unusual;
  - **during a branch run:** read `main`'s code with `git show main:<path>`; the plan will not be committed (the
    planner's own check refuses), so the planner puts it on its cards with `quartz link-doc` (when the repo uses
    Quartz) and you commit it after the merge (`reviewing.md` §5).
```

- [x] **Step 2: The branch-run hand-back check (spec §6).** Replace:

```text
1. **Committed:** `git log -1 --format=%h main -- <plan>` prints a commit. During a branch run: the file exists, and
   the planner ran `quartz link-doc` on it (without Quartz, the file exists).
```

with:

```text
1. **Committed:** `git log -1 --format=%h main -- <plan>` prints a commit. During a branch run: the file exists, and
   the planner's report says it ran `quartz link-doc`; with the Quartz MCP, `get_task` on the card lists the plan
   among its docs. When the repo does not use Quartz (`quartz.md` §1), the file exists.
```

- [x] **Step 3: Stop 3 asks first (spec §3).** Replace:

```text
One message, which ends there:

- the plan paths and their task counts;
- the planner's deviations and ambiguities, with its resolutions;
- the external facts it re-verified, and any differences;
- the decisions the owner must make;
- then two questions: "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the
  spec." and the handoff question from `dispatching.md` §1, for the first plan to run.
```

with:

```text
One message, which ends there. It opens with its questions, numbered, in this order (`SKILL.md`, The stops):

- each decision the owner must make;
- "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the spec.";
- the handoff question from `dispatching.md` §1, with its warnings, for the first plan to run.

Then the report, short, one line per item:

- the plan paths and their task counts;
- the planner's deviations and ambiguities, with its resolutions;
- the external facts it re-verified, and any differences.
```

Then replace:

```text
  Then §2, and a short stop 3: what changed, and the handoff question again.
```

with:

```text
  Then §2, and a short stop 3 in the same order: any new decision and the handoff question again, then what
  changed.
```

- [x] **Step 4: `dispatching.md`'s section references and its Quartz condition (spec §6, §7).** In
  `skills/orchestrating/dispatching.md`, replace:

```text
  path, and step 4 never runs `quartz link-branch` for it: Quartz would link the main checkout's current branch,
```

with:

```text
  path, and §4 never runs `quartz link-branch` for it: Quartz would link the main checkout's current branch,
```

Replace:

```text
Without Quartz, skip this step.
```

with:

```text
When the repo does not use Quartz (`quartz.md` §1), skip this step.
```

Replace:

```text
- **A second plan runs only in a worktree** (step 1).
```

with:

```text
- **A second plan runs only in a worktree** (§1).
```

- [x] **Step 5: Check (P17).**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `git grep -n -i -E 'steps? [0-9]' -- skills/orchestrating/SKILL.md skills/orchestrating/planning.md skills/orchestrating/dispatching.md skills/orchestrating/reviewing.md` | nothing |
| `git grep -n -i 'without Quartz' -- skills/orchestrating/planning.md skills/orchestrating/dispatching.md` | nothing |
| `git grep -c -F 'quartz.md' -- skills/orchestrating/planning.md skills/orchestrating/dispatching.md` | `skills/orchestrating/dispatching.md:1` and `skills/orchestrating/planning.md:2` |
| `git grep -n -F 'Then the report, short' -- skills/orchestrating/planning.md` | one line, in §3 |

- [x] **Step 6: Commit.**

```bash
git add skills/orchestrating/planning.md skills/orchestrating/dispatching.md
git commit -m "fix: planning and dispatching: the planner hears whether the repo uses Quartz; stop 3 asks first" -m "The planner's prompt says whether the repo uses Quartz, and otherwise to run no quartz command. The branch-run hand-back check reads the planner's report and the card's docs. Stop 3 opens with its numbered questions, then a short report. dispatching.md's step references become section references, and its Quartz condition points at quartz.md." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `reviewing.md`: status notes, the fix check, stop 4, the hand ticks (spec §2.3, §3, §4, §6, §7; D3.5, D3.6; findings 1, 4, 6, 8, 9)

**Files:**
- Modify: `skills/orchestrating/reviewing.md:19` (§1), `:52-54` (§2), `:68` (§3), `:72-84` (§4), `:94-99` (§5)

- [x] **Step 1: §1: no `reviewer` steps still posts the status.** In `skills/orchestrating/reviewing.md`, replace:

```text
When the plan has no `reviewer` steps, skip the dispatch and say so at stop 4.
```

with:

```text
When the plan has no `reviewer` steps, skip the dispatch, say so at stop 4, and post §2's status note now, as
`` `<plan path>`: acceptance done, no reviewer steps. ``
```

- [x] **Step 2: §2: the fix check names its checks; the status note after the loop.** Replace:

```text
After a fix, verify it as `dispatching.md` §7 does: the gates, the new commits, a clean tree. Then the reviewer,
resumed or fresh, reruns only the steps that failed. A step that fails again after its second fix round goes to the
owner.
```

with:

```text
After a fix, verify it with `dispatching.md` §7's checks 1–4 (the gates, the new commits, a clean tree, the
deviations). `quartz review` does not run again: the cards are already In review. Then the reviewer, resumed or
fresh, reruns only the steps that failed. A step that fails again after its second fix round goes to the owner.

**The status note.** When the fix loop ends (every FAIL fixed, or made a card by the owner), and the repo uses Quartz
with its MCP loaded (`quartz.md` §1 and §2), post a status note on each of the plan's cards (its card line, or its
spec's): `add_note` with `status: true`, at most 500 characters:

`` `<plan path>`: acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds. ``

N of the M `reviewer` steps passed and K are NEEDS-HUMAN, after F fix rounds. A status replaces the card's previous
one, which is enough: the code review runs only after acceptance. A resumed orchestrator reads it (`SKILL.md`,
Finding where work stands). A note that fails is reported once, in one line (`quartz.md` §2).
```

- [x] **Step 3: §3: the status note after the code review.** Replace:

```text
- **Important and Minor:** proposed cards (§4).
```

with:

```text
- **Important and Minor:** proposed cards (§4).

When the code review and its Critical fixes are done, post the status note as §2 does:

`` `<plan path>`: code review done, C Critical (x fixed, y dropped), I Important, m Minor. At stop 4. ``
```

- [x] **Step 4: §4: wait for every leg's usage; questions first; the tick promise.** Replace:

```text
One report, which ends the message:

- the acceptance verdicts, with each NEEDS-HUMAN step listed as the owner's;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- the proposed cards, one line each (title, file, why), for the owner to keep or drop;
- the token counts of the acceptance reviewer and the code reviewer against the executor's, as your harness reports
  them, until the owner says they have seen enough;
- the plan's `owner` steps, which the owner runs at the click-through;
- where to click through (below).

The cards the owner keeps go to Needs brainstorming through the Quartz MCP, kind `bug` or `change`, in the plan's
initiative, each body naming the plan, the file and the evidence. Without Quartz, they stay listed in the report.
```

with:

```text
**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer. An agent's reply arrives
before the notification that carries its usage. Where the harness reports no usage, stop 4 says so.

One message, which ends there. It opens with its questions, numbered, in this order (`SKILL.md`, The stops):

- the proposed cards, one line each (title, file, why), for the owner to keep or drop;
- the NEEDS-HUMAN steps and the plan's `owner` steps, which the owner runs at the click-through;
- where to click through (below).

Then the report, short, one line per item:

- the acceptance verdicts;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- the token counts of the acceptance reviewer and the code reviewer against the executor's, as your harness reports
  them ("not reported" where it reports none), until the owner says they have seen enough.

Stop 4 promises a Quartz tick only where `quartz.md` §3 says one will come.

The cards the owner keeps go to Needs brainstorming through the Quartz MCP, kind `bug` or `change`, in the plan's
initiative, each body naming the plan, the file and the evidence. When the repo does not use Quartz (`quartz.md` §1),
they stay listed in stop 4.
```

- [x] **Step 5: §5: queued ticks only where hooks tick; the hand ticks.** Replace:

```text
upload them. Task ticks queued during the run drain at the next stop.

Then, in either mode, run the plan's `after merge` acceptance steps with the owner. When the spec has another plan,
its handoff follows (`planning.md` §4).
```

with:

```text
upload them. Where Quartz's hook ticks tasks (`quartz.md` §3), the ticks queued during the run drain at the next
stop.

Then, in either mode, run the plan's `after merge` acceptance steps with the owner. When they are done, tick the
acceptance task by hand if no commit ticked it; where nothing ticks a committed task (`quartz.md` §3), tick every task
with a `Plan-Task:` commit in the same edit. When the spec has another plan, its handoff follows (`planning.md` §4).
```

- [x] **Step 6: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `git grep -n -F 'acceptance done' -- skills/orchestrating/reviewing.md` | two lines (§1's note and §2's) |
| `git grep -n -F 'code review done' -- skills/orchestrating/reviewing.md` | one line |
| `git grep -n -e 'add_note' -e 'checks 1–4' -e 'Wait for every leg' -e 'promises a Quartz tick' -- skills/orchestrating/reviewing.md` | four lines |
| `git grep -n -i 'without Quartz' -- skills/orchestrating/reviewing.md` | nothing |

- [x] **Step 7: Commit.**

```bash
git add skills/orchestrating/reviewing.md
git commit -m "feat: reviewing posts status notes, waits for every leg's usage, and asks first at stop 4" -m "After acceptance and after the code review, a status note on the plan's cards tells a resumed orchestrator where review stands. A fix is checked with dispatching.md's checks 1-4, without a second quartz review. Stop 4 waits for every agent's notification, opens with its numbered questions, and promises a Quartz tick only where quartz.md says one will come. After the merge, a repo with no ticking hook gets every committed task ticked with the acceptance task." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: `brainstorming` starts with the Quartz check; `writing-plans` follows the prompt (spec §6, §7; D3.7; findings 7, 4; P7)

**Files:**
- Modify: `skills/brainstorming/SKILL.md:18` (the anti-pattern), `:28` (checklist step 1), `:121` (Documentation)
- Modify: `skills/writing-plans/SKILL.md:152`

- [x] **Step 1: Checklist step 1 (spec §7).** In `skills/brainstorming/SKILL.md`, replace:

```text
1. **Tick Brain** — when the work has a Quartz card, call the Quartz MCP's `tick_brain` with the card id. The tick moves the card to the brainstorming column. With no card, skip this. If it fails, report the failure and carry on
```

with:

```text
1. **Quartz** — run `hyper-relay:orchestrating`'s Quartz check (`${CLAUDE_SKILL_DIR}/../orchestrating/quartz.md`, §1 and §2; `../orchestrating/quartz.md` from this SKILL.md). When the repo uses Quartz and the work has a card, call `tick_brain` with its id. If it fails, report the failure and carry on
```

- [x] **Step 2: The anti-pattern no longer reads against the off-ramp (spec §6).** Replace:

```text
A todo list, a single-function utility, a config change — all of them.
```

with:

```text
A todo list, a single-function utility, a multi-line config change — all of them.
```

- [x] **Step 3: Documentation's `link-doc` condition (P7).** Replace:

```text
(it puts an uncommitted doc on its cards; skip it without Quartz)
```

with:

```text
(it puts an uncommitted doc on its cards; skip it when step 1 found that the repo does not use Quartz)
```

- [x] **Step 4: `writing-plans` (spec §7).** In `skills/writing-plans/SKILL.md`, replace:

```text
(it puts an uncommitted doc on its cards; skip it without Quartz)
```

with:

```text
(it puts an uncommitted doc on its cards; skip it when your dispatch prompt says the repo does not use Quartz)
```

- [x] **Step 5: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `git grep -n -F 'quartz.md' -- skills/brainstorming/SKILL.md` | one line, checklist step 1 |
| `git grep -n -e 'Tick Brain' -e 'a config change' -- skills/brainstorming` | nothing |
| `git grep -n -i 'without Quartz' -- skills/brainstorming skills/writing-plans` | nothing |
| `git grep -n -F 'your dispatch prompt says the repo does not use Quartz' -- skills/writing-plans/SKILL.md` | one line |

- [x] **Step 6: Commit.**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md
git commit -m "fix: brainstorming starts with the Quartz check; writing-plans' link-doc follows the dispatch prompt" -m "brainstorming's first step runs orchestrating's Quartz check (quartz.md, sections 1 and 2) and ticks the brain only when the repo uses Quartz and the work has a card. Its anti-pattern says a multi-line config change, so it no longer reads against the off-ramp. A planner skips quartz link-doc when its prompt says the repo does not use Quartz." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 7: README and `CLAUDE.md`; the full gates (spec §6, §8; findings 4, 7, 3; P11, P14, P15)

**Files:**
- Modify: `README.md:25-27` (the relay diagram), `:68-69` (the Quartz section)
- Modify: `CLAUDE.md:70` (the `validate` row), `:75` (after the `wt` row)

- [x] **Step 1: The relay diagram names legs, and shows `orchestrating` (P11).** In `README.md`, the code block under
  `## The relay` holds three lines (25–27). Replace those three lines whole (their spacing is as
  `sed -n '25,27p' README.md` prints it):

```text
 voice-to-specs ─▶ brainstorming ─▶ spec ─▶ writing-plans ─▶ execute ─▶ review ─▶ you ─▶ merge
   (optional)        (you + the        (committed)   (one plan per    (isolated)  (clicks,   (anchor
                      orchestrator)                    subsystem)                  not tests)   leg)
```

with these four lines, exactly (each annotation starts under its node; the last line runs from under `spec` to under
`merge`):

```text
 voice-to-specs ─▶ brainstorming ─▶ spec ─▶ plan ─▶ execute ─▶ review ─▶ you ─▶ merge
   (optional)      (you + the       (committed)     (isolated) (clicks,  (anchor leg)
                   orchestrator)            (a planner agent)  not tests)
                                    └──────────────── orchestrating ────────────────┘
```

The fences around the block and the relay table below it do not change.

- [x] **Step 2: Two sentences on setup and declining (spec §6).** In `README.md`, replace:

```text
Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown, and the skills work on their own. But
the board is half the point: it is what lets a long-running, multi-agent pipeline stay legible.
```

with:

```text
Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown, and the skills work on their own. But
the board is half the point: it is what lets a long-running, multi-agent pipeline stay legible.

When the `quartz` CLI is installed but a repo is not connected yet, the relay sets the repo up itself and asks you
only for the steps that are yours: a project, a token and the repo's name. `git config hyper-relay.quartz off` turns
that off in a repo, and `git config --unset hyper-relay.quartz` turns it back on.
```

- [x] **Step 3: `CLAUDE.md`'s Checks (spec §6, §8; P14).** In `CLAUDE.md`, replace:

```text
| Manifests and skills | `claude plugin validate .` | Passes. Its one warning is about this `CLAUDE.md` at the plugin root, which is for developing hyper-relay, not for users |
```

with:

```text
| Manifests and skills | `claude plugin validate .` | Passes, with three warnings: this `CLAUDE.md` at the plugin root (for developing hyper-relay, not for users), `ICON_MISSING`, and, in this checkout only, `PRIVACY_URL_MISSING`, which comes from the gitignored `.mcp.json` (Quartz's MCP server) |
```

Replace:

```text
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
```

with:

```text
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
| Relay skills | `sh tests/orchestrating/run-tests.sh` | `0 failed` |
```

- [x] **Step 4: Commit.**

```bash
git add README.md CLAUDE.md
git commit -m "docs: README's relay diagram names legs and orchestrating; Quartz setup and declining; the new check" -m "The diagram's writing-plans becomes plan (a planner agent), and a line under it shows orchestrating from the spec to the merge. The Quartz section says the relay sets a repo up and how to turn that off. CLAUDE.md's validate row names its three warnings, and the Checks table gains tests/orchestrating/run-tests.sh." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#7
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 5: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `dash -n tests/orchestrating/run-tests.sh` | silent |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` (untouched; a regression check) |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` (untouched) |
| `sh tests/add-card-line/run-tests.sh \| tail -n 1` | `85 passed, 0 failed` (untouched) |
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, P15) |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `git diff --name-only main...HEAD` | exactly the ten files of "File structure": `CLAUDE.md`, `README.md`, `skills/brainstorming/SKILL.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/planning.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/reviewing.md`, `skills/writing-plans/SKILL.md`, `tests/orchestrating/run-tests.sh` |
| `git grep -n -i -w -e sat -e pentraze -- skills/orchestrating tests/orchestrating README.md CLAUDE.md` | nothing |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Upstream's live suites are not run (report this): they start real `claude -p` sessions. Then report, copy Task 8's
checklist (Steps 1–16, each with its marker and its PASS) into your report, and stop: Task 8 is not yours.

### Task 8: Acceptance (spec §9; D3.9; P3, P12, P15, P16, P18). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-d3-orchestrating-findings`) its dispatch names, from the checkout's top. It runs Steps 1–8 only.
- **`owner`**: the owner, at the click-through (Steps 9–10).
- **`after merge`**: the orchestrator with the owner, once the owner has merged the branch into `main` and the main
  checkout `/home/noob_master/hyper-relay` is on `main` (Steps 11–16), one command per Bash call. The orchestrator runs
  the commands; the owner starts the live sessions.

**This plan's run follows the installed relay** (today's `orchestrating`, as D1's followed its design by hand, D1's
R12), not the text it writes: the new behaviour reaches a session only after the merge, the push and the owner's
reinstall (Step 12). The version stays 0.1.0.

- [ ] **Step 1 (`reviewer`): The guard.**

| Run | PASS |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| grep -c '^ok   .* can fail: '` | `13` |
| `dash -n tests/orchestrating/run-tests.sh` | silent, exit 0 |
| `git ls-files -s tests/orchestrating/run-tests.sh` | one line starting `100644` |

- [ ] **Step 2 (`reviewer`): The other suites, unchanged.**

| Run | PASS |
|---|---|
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` |
| `sh tests/add-card-line/run-tests.sh \| tail -n 1` | `85 passed, 0 failed` |
| `git diff --stat main...HEAD -- bin hooks templates tests/hyper-relay-agents tests/add-card-line skills/brainstorming/scripts` | nothing (P18) |

- [ ] **Step 3 (`reviewer`): The manifests and the skill count (P15).**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout (which holds the gitignored `.mcp.json`), `PRIVACY_URL_MISSING`; no other warning |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |

- [ ] **Step 4 (`reviewer`): Only the planned files changed (spec §1, §10).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `CLAUDE.md`, `README.md`, `skills/brainstorming/SKILL.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/planning.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/reviewing.md`, `skills/writing-plans/SKILL.md`, `tests/orchestrating/run-tests.sh` |
| `git log --format=%B main..HEAD \| grep -c -i -w -e sat -e pentraze` | `0` |

- [ ] **Step 5 (`reviewer`): One definition, and the wording fixes (spec §6, §7; P7, P17).**

| Run | PASS |
|---|---|
| `git grep -n -i 'without Quartz' -- skills/orchestrating skills/brainstorming skills/writing-plans` | nothing |
| `git grep -n -i -E 'steps? [0-9]' -- skills/orchestrating` | only lines in `skills/orchestrating/quartz.md`, each naming `brainstorming`'s step 1 |
| `git grep -n -F '§4 never runs' -- skills/orchestrating/dispatching.md` | one line, in §2 |
| `git grep -n -F 'A second plan runs only in a worktree** (§1).' -- skills/orchestrating/dispatching.md` | one line, in §6 |
| `git grep -n -F "§7's checks 1–4" -- skills/orchestrating/reviewing.md` | one line, in §2, followed by the sentence that `quartz review` does not run again |
| ``git grep -n -F 'Run no `quartz` command.' -- skills/orchestrating/planning.md`` | one line, in §1's prompt list |
| `git grep -n -F 'a multi-line config change' -- skills/brainstorming/SKILL.md` | one line, the anti-pattern |
| `git grep -n -F '../orchestrating/quartz.md' -- skills/brainstorming/SKILL.md` | one line, checklist step 1, which also names `${CLAUDE_SKILL_DIR}/../orchestrating/quartz.md` and calls `tick_brain` only when the repo uses Quartz and the work has a card |
| `git grep -n -F 'your dispatch prompt says the repo does not use Quartz' -- skills/writing-plans/SKILL.md` | one line |
| `git grep -n 'CLAUDE_SKILL_DIR' -- skills/orchestrating skills/brainstorming/SKILL.md` | seven lines: five in `skills/orchestrating/SKILL.md` and two in `skills/brainstorming/SKILL.md`, each naming on the same line the same file relative to its skill; none in `quartz.md` (P9) |
| `git grep -n -e 'Wait for every leg' -e 'promises a Quartz tick' -e 'add_note' -- skills/orchestrating/reviewing.md` | three lines: §2's `add_note`, then §4's wait and its tick promise |

- [ ] **Step 6 (`reviewer`): `quartz.md` against spec §2.** Read `skills/orchestrating/quartz.md` in full, the spec's
  §2 and its decision D3.9, and this plan's P1–P4, P8 and P9. Then `git diff main...HEAD -- skills/orchestrating/SKILL.md` for the duties
  that left `SKILL.md`. PASS, each point quoted:
  - §1's table has the spec's four rows in the spec's order, with its tests and results; "Uses Quartz" means row 3
    only; the undo is `--unset` in either scope; row 3's test is given as a command that prints nothing from the file.
  - §2 defines "configured properly" as the spec's four parts; the setup message is the spec's, word for word; the
    three answers (a no, neither, a repo name) do what spec §2.2 says; the repo-name steps write the spec's `.mcp.json`
    server and `.envrc` lines, ignore `.env` and, when git does not track them, `.mcp.json` and `.envrc` (D3.9),
    install the hooks through the connected checks (P2), and end with one message that, when the token check failed,
    opens with spec §2.2's token prompt (D3.9: the project's settings in Quartz's web app, `<main checkout>/.env`, an
    editor, never the chat, `.envrc` loads it), then the spec's restart lines, then each other failed check in one
    line; the relay waits for neither the token nor the restart; a tracked `.mcp.json` or `.envrc` waits for the
    merge during a branch run.
  - The connected checks are the spec's five (hooks, token, MCP, card, card lines), and "A step that fails" is the
    spec's rule (once per session, P4).
  - §3 says ticks come only in a connected repo whose hooks are installed (P8's test), and gives the hand-tick
    message `docs: plan progress, tasks 1–M of M`.
  - §4 holds every duty the diff removed from `SKILL.md` except `quartz install-git-hook`, says each runs only when §1
    says the repo uses Quartz, and adds the status notes.
  - Nothing in `quartz.md` contradicts the spec. List any sentence that does as a FAIL, with its line.

- [ ] **Step 7 (`reviewer`): The stops and resuming (spec §3, §4, §5; P5, P6).** Read
  `skills/orchestrating/SKILL.md` ("The stops", "Finding where work stands"), `planning.md` §3 and `reviewing.md`
  §1–§5. PASS:
  - "The stops" carries the spec's rule word for word, and rows 3 and 4 list the questions first;
  - stop 3 (`planning.md` §3) opens with its numbered questions in spec §3's order (the decisions, the plan-review
    offer, the handoff question with its warnings), then the short report; a short stop 3 keeps that order;
  - stop 4 (`reviewing.md` §4) opens with the wait for every agent's notification, then its numbered questions in spec
    §3's order (proposed cards, NEEDS-HUMAN and `owner` steps, where to click through), then the short report with
    "not reported" for a missing count, and promises a Quartz tick only where `quartz.md` §3 says;
  - `reviewing.md` posts the spec's two status notes, word for word (and the no-`reviewer`-steps one in §1);
  - the "A spec that no plan's `**Spec:**` line names" row offers the planner leg; the review-status table has the
    spec's four rows (with P5's MCP clause) and the fix-commit definition;
  - `reviewing.md` §5 ticks every committed task by hand where nothing else ticks them.

- [ ] **Step 8 (`reviewer`): README and `CLAUDE.md` (spec §6, §8; P11, P14).**

| Run | PASS |
|---|---|
| `sed -n '24,29p' README.md` | the opening fence, then the four lines of Task 7 Step 1, character for character, then the closing fence |
| `git grep -n -F 'hyper-relay.quartz' -- README.md` | two lines, in the Quartz section's new paragraph: `off` turns setup off, `--unset` turns it back on |
| `git grep -n -F 'PRIVACY_URL_MISSING' -- CLAUDE.md` | one line, the `validate` row, which names all three warnings |
| `git grep -n -F 'sh tests/orchestrating/run-tests.sh' -- CLAUDE.md` | one line, a Checks row expecting `0 failed` |
| `git diff --numstat main...HEAD -- CLAUDE.md` | `2	1	CLAUDE.md` |

- [ ] **Step 9 (`owner`): Read the setup.** Read
  `git -C /home/noob_master/hyper-relay show hyper-relay-d3-orchestrating-findings:skills/orchestrating/quartz.md`, §2.
  PASS: the owner agrees with the setup message, the steps and the closing message as written, including D3.9's
  exclude lines for `.mcp.json` and `.envrc` and its token prompt (if not, the orchestrator records the change and it
  goes to the executor as a finding).

- [ ] **Step 10 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-d3-orchestrating-findings` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging.

- [ ] **Step 11 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `24 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check` | nothing, exit 0: no template changed, so no agent is regenerated (P18) |
| `git -C /home/noob_master/hyper-relay status --short` | nothing |

- [ ] **Step 12 (`after merge`): Push, then the owner reinstalls.** The version stays 0.1.0.

```bash
git -C /home/noob_master/hyper-relay push origin main
```

Then the owner runs `/plugin install hyper-relay@hyper-relay` **in a Claude Code session**, and starts a new session
for the probes: a running session keeps the copy it loaded.

| Run | PASS |
|---|---|
| `git -C /home/noob_master/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD`, then `git -C /home/noob_master/hyper-relay rev-parse main` | the same SHA |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/orchestrating/quartz.md && echo quartz` | `quartz` |
| `grep -c -F 'quartz install-git-hook' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/orchestrating/SKILL.md` | `0` |
| `git -C /home/noob_master/hyper-relay show main:.claude-plugin/plugin.json` | `"version": "0.1.0"` |

If a check fails, stop and tell the owner; do not delete or uninstall anything.

- [ ] **Step 13 (`after merge`): Build the probe repos (P16).** Precondition: `command -v quartz` in the owner's shell
  prints a path; if it prints nothing, probes (a) and (b) would meet §1's row 1 and prove nothing: stop and tell the
  owner. For each `<dir>` of `/tmp/hr-d3-probe-declined`, `/tmp/hr-d3-probe-setup` and `/tmp/hr-d3-probe-resume`:

```bash
git init -q -b main <dir>
```

With the Write tool, these seven files in each `<dir>`. `CLAUDE.md`:

```markdown
# Toy

A throwaway repo for probing hyper-relay's orchestrating skill. POSIX sh. Test: `sh test.sh`.
```

`README.md`:

```markdown
# Toy

`greet.sh NAME` prints the greeting. Scripts receive one argument.
```

`greet.sh`:

```sh
#!/bin/sh
# greet.sh NAME: prints a greeting.
printf 'Hello, %s!\n' "$1"
```

`test.sh`:

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

`.gitignore`:

```text
.claude/
.worktrees/
```

`.hyper-relay/agents.md`:

```markdown
---
project: toy
reviewer: commands
execute: branch
---
A throwaway repo's facts, for probing hyper-relay.

## executor/gates
- `sh test.sh`: its last line ends `0 failed`.
```

`docs/superpowers/specs/2026-11-18-toy-bye-design.md`:

```markdown
# Toy bye (design)

**Status:** approved by the owner.

## Goal

A `bye.sh NAME` script that prints `Bye, NAME!`, beside `greet.sh`.

## Design

- `bye.sh`: POSIX sh, one line of output: `printf 'Bye, %s!\n' "$1"`.
- `test.sh` gains one check for it.

## Testing and acceptance

- `sh test.sh` prints `2 passed, 0 failed`.
- `sh bye.sh Ada` prints `Bye, Ada!`.

Both are `reviewer` steps. Nothing is left for after the merge.
```

Then, in each `<dir>`:

```bash
git -C <dir> add CLAUDE.md README.md greet.sh test.sh .gitignore .hyper-relay/agents.md docs/superpowers/specs/2026-11-18-toy-bye-design.md
git -C <dir> commit -q -m "chore: toy repo and its spec"
cd <dir> && /home/noob_master/hyper-relay/bin/hyper-relay-agents
```

PASS (the generator, in each): `written .claude/agents/toy-planner.md`, `written .claude/agents/toy-executor.md`,
`written .claude/agents/toy-reviewer.md`, `written .claude/hooks/hyper-relay-planner-guard.py`, the restart line last;
exit 0. And `test -e <dir>/.mcp.json || echo none` prints `none` in each.

**`/tmp/hr-d3-probe-resume` only** (probe (c): declined, with a plan, a task commit and a fix commit on its branch).
Write the toy plan with this command, as it stands: its lines are quoted arguments, so none of them starts with
`### Task` or `- [ ]` in this plan, where the hand-back check (`grep '^### Task'`) and Quartz's task ticks would read
them as this plan's own.

```bash
mkdir -p /tmp/hr-d3-probe-resume/docs/superpowers/plans
printf '%s\n' \
    '# Toy bye Implementation Plan' \
    '' \
    '**Spec:** `docs/superpowers/specs/2026-11-18-toy-bye-design.md`' \
    '' \
    '> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans. Task 1 is for the executor. Task 2' \
    '> is the acceptance task: both its steps are `reviewer` steps.' \
    '' \
    '**Goal:** `bye.sh NAME` prints `Bye, NAME!`.' \
    '' \
    '## Spec coverage' \
    '' \
    '| Spec section | Tasks |' \
    '|---|---|' \
    '| Goal | 1 |' \
    '| Design | 1 |' \
    '| Testing and acceptance | 1, 2 |' \
    '' \
    '### Task 1: bye.sh' \
    '' \
    '- [ ] **Step 1:** Create `bye.sh` printing `Bye, NAME!`, and add its check to `test.sh`.' \
    '- [ ] **Step 2:** `sh test.sh` prints `2 passed, 0 failed`. Commit, with the trailer' \
    '  `Plan-Task: docs/superpowers/plans/2026-11-18-toy-bye.md#1`.' \
    '' \
    '### Task 2: Acceptance' \
    '' \
    '- [ ] **Step 1 (`reviewer`):** `sh test.sh` prints `2 passed, 0 failed`.' \
    '- [ ] **Step 2 (`reviewer`):** `sh bye.sh Ada` prints `Bye, Ada!`.' \
    > /tmp/hr-d3-probe-resume/docs/superpowers/plans/2026-11-18-toy-bye.md
```

```bash
git -C /tmp/hr-d3-probe-resume config hyper-relay.quartz off
git -C /tmp/hr-d3-probe-resume add docs/superpowers/plans/2026-11-18-toy-bye.md
git -C /tmp/hr-d3-probe-resume commit -q -m "docs: toy bye plan"
git -C /tmp/hr-d3-probe-resume switch -q -c toy-bye
```

With the Write tool, `bye.sh`:

```sh
#!/bin/sh
printf 'Bye, %s!\n' "$1"
```

and `test.sh` again, now with the bye check:

```sh
#!/bin/sh
# test.sh: the toy's tests.
p=0
f=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then p=$((p + 1)); else f=$((f + 1)); printf 'FAIL %s: [%s]\n' "$1" "$3"; fi
}
check greet "Hello, Ada!" "$(sh greet.sh Ada)"
check bye "Bye, Ada!" "$(sh bye.sh Ada)"
printf '%d passed, %d failed\n' "$p" "$f"
[ "$f" -eq 0 ]
```

```bash
git -C /tmp/hr-d3-probe-resume add bye.sh test.sh
git -C /tmp/hr-d3-probe-resume commit -q -m "feat: bye.sh" -m "Plan-Task: docs/superpowers/plans/2026-11-18-toy-bye.md#1"
```

Then `bye.sh` again, the fix:

```sh
#!/bin/sh
# bye.sh NAME: prints a farewell.
printf 'Bye, %s!\n' "$1"
```

```bash
git -C /tmp/hr-d3-probe-resume add bye.sh
git -C /tmp/hr-d3-probe-resume commit -q -m "fix: bye.sh names its argument"
```

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d3-probe-resume branch --show-current` | `toy-bye` (the main checkout stays on the branch, as after a branch run) |
| `git -C /tmp/hr-d3-probe-resume log --format='%s%n%(trailers:key=Plan-Task)' main..toy-bye` | `fix: bye.sh names its argument` first, then `feat: bye.sh` with its `Plan-Task:` trailer |
| `git -C /tmp/hr-d3-probe-resume config --get hyper-relay.quartz` | `off` |

- [ ] **Step 14 (`after merge`): The live probes (spec §9).** Each is a new Claude Code session, started by the owner
  after Step 12, in its repo. Quartz's own session hooks may print a warning about a token in probe (b): not a FAIL.

**(a) Declined, through the loop.** The owner runs `cd /tmp/hr-d3-probe-declined && claude` (accepting the trust
prompt) and sends:

> The spec docs/superpowers/specs/2026-11-18-toy-bye-design.md is approved.

PASS, in order (the owner watches; the orchestrator checks the git rows):
1. Before any planner is dispatched, the setup message of `quartz.md` §2 arrives as a message of its own. The owner
   answers `no Quartz here`. The reply is one line that names `git config --unset hyper-relay.quartz`.
2. Stop 3 opens with its numbered questions (any decisions, the plan-review offer, the handoff question with `branch`
   as this repo's default), and the report comes after them. The owner answers `OK, branch`.
3. Stop 4 comes only after the notifications of every agent dispatched (executor, acceptance reviewer, code
   reviewer). It opens with its numbered questions; its report gives each token count, or "not reported"; it promises
   no Quartz tick.
4. The owner sends `merge it`, picks the merge-locally option, and, when its `git pull` fails (the repo has no remote),
   tells it to carry on without pulling.

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d3-probe-declined config --get hyper-relay.quartz` | `off` |
| `grep -r -l quartz /tmp/hr-d3-probe-declined/.git/hooks` | nothing: no `post-commit` or `post-merge` with a `quartz` line |
| `git -C /tmp/hr-d3-probe-declined branch --show-current` | `main` |
| `cd /tmp/hr-d3-probe-declined && sh test.sh` | `2 passed, 0 failed` |
| `git -C /tmp/hr-d3-probe-declined log -1 --format=%s -- docs/superpowers/plans` | `docs: plan progress, tasks 1–N of N`, N being the plan's task count (a hyphen for the dash is fine): every committed task ticked by hand, in the acceptance tick's commit |
| `grep -c -F -- '- [ ]' /tmp/hr-d3-probe-declined/docs/superpowers/plans/*.md` | `0` |

**(b) Setup that fails partway.** The owner runs `cd /tmp/hr-d3-probe-setup && claude` and sends:

> Add a `--loud` flag to greet

PASS, in order:
1. Before any brainstorming question, the setup message arrives as a message of its own. The owner answers
   `The repo name is toy-probe.` and puts no token anywhere.
2. The next message opens with the token prompt (D3.9): create the token in the project's settings in Quartz's web
   app, and put it in this repo's `.env` (`/tmp/hr-d3-probe-setup/.env`) as `QUARTZ_TOKEN=<token>`, in an editor,
   never in the chat, since `.envrc` loads it from there. Then `direnv allow` and the restart, then the missing MCP in
   one line. Brainstorming then carries on without waiting for the token (it explores or asks its next question), and
   later messages do not report the token or the MCP again. The owner ends the session after brainstorming's next
   question.

| Run | PASS |
|---|---|
| `jq -c '.mcpServers.quartz' /tmp/hr-d3-probe-setup/.mcp.json` | an object with `"type":"http"`, `"url":"http://127.0.0.1:8083/mcp"` and `"headers"` holding `"Authorization":"Bearer ${QUARTZ_TOKEN}"` and `"X-Quartz-Repo":"toy-probe"` (key order may differ) |
| `cat /tmp/hr-d3-probe-setup/.envrc` | exactly the two lines `watch_file .env` and `export QUARTZ_TOKEN=$(grep '^QUARTZ_TOKEN=' .env 2>/dev/null \| cut -d= -f2)` |
| `git -C /tmp/hr-d3-probe-setup check-ignore -q .env && echo ignored` | `ignored` |
| `grep -c -F 'quartz hook' /tmp/hr-d3-probe-setup/.git/hooks/post-commit /tmp/hr-d3-probe-setup/.git/hooks/post-merge` | `…/post-commit:1` and `…/post-merge:1` |
| `git -C /tmp/hr-d3-probe-setup status --short` | nothing: `.mcp.json` and `.envrc` are excluded (P3, D3.9) |
| `git -C /tmp/hr-d3-probe-setup config --get hyper-relay.quartz` | nothing (exit 1) |

**(c) Resume without Quartz.** The owner runs `cd /tmp/hr-d3-probe-resume && claude` and sends:

> Pick up the toy bye work.

PASS: no setup message (the repo is declined); it asks which review legs ran, naming the fix commit (its hash or
`fix: bye.sh names its argument`), and dispatches no agent and runs no gate before the owner answers. The owner ends the
session there.

- [ ] **Step 15 (`after merge`): Clean up; anything failed?**

```bash
rm -rf /tmp/hr-d3-probe-declined /tmp/hr-d3-probe-setup /tmp/hr-d3-probe-resume
```

A failed step: fix it on a branch through the usual spec and plan, merge, push, reinstall (Step 12), and repeat the
step.

- [ ] **Step 16 (`after merge`): Record (P12).** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 8)

- **Before the merge:** acceptance reviewer <verdict line>; fix rounds <n, what each changed>; code review: Critical
  <fixed / dropped, why>, proposed cards <kept / dropped>; token counts: executor <n>, acceptance reviewer <n>, code
  reviewer <n>.
- **Owner steps:** Step 9 <agreed / what changed>.
- **Reinstall, <date>:** marketplace clone at <SHA>; `quartz.md` in the 0.1.0 cache: <yes/no>.
- **Probes:** (a) <pass/fail, anything it did differently>; (b) <>; (c) <>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 8 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece D.3 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md#8
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-18-hyper-relay-d3-orchestrating-findings.md
```

Push it with the next change of `main` (the owner's call).

## Last-task record (Task 8)

- **Before the merge:** acceptance reviewer 8/8 PASS, 0 blocking, 2 polish (stop rows against leg lists, wording);
  fix rounds 1: at stop 4 the owner had proposed card b fixed on the branch instead of carded (`aeb39e5`: the `.envrc`
  line keeps the whole token with `cut -d= -f2-`, and the exclude file is the one `git rev-parse --git-path
  info/exclude` prints; spec D3.10, `f2fa96e`); code review: Ready, 0 Critical, 0 Important, 5 Minor; proposed cards:
  b fixed on the branch, a and c dropped (owner: fix them later if they become a problem); token counts (output /
  final context): executor 12,184 / 95,060, acceptance reviewer 8,536 / 87,686, code reviewer 4,788 / 83,365.
  **Deviation (owner's addition):** `writing-skills` RED/GREEN pressure tests by the orchestrator, 6 scenarios on
  `main`'s and the branch's skill text (12 Sonnet runs, 32,003 output): GREEN 6/6 PASS; RED failed as expected in 5,
  while S6 (an old spec is offered, not planned) and S4's wait and tick parts did not discriminate. 0 fix rounds.
- **Owner steps:** Step 9 agreed (the owner read `quartz.md` §2 after the fix: "Looks perfect"); Step 10 merge-tree
  exit 0. Merged in `3faf926`.
- **Reinstall, 2026-11-18:** marketplace clone at `f2fa96e`; `quartz.md` in the 0.1.0 cache: yes, with both D3.10
  fixes.
- **Probes:** (a) FAIL at its item 1, accepted by the owner: the session dispatched the planner before sending the
  setup message, then sent it. The owner: having no Quartz configured shouldn't stop the work; setup can run with
  the orchestrator while the agent works. D.2's skills plan changes `quartz.md` §2 to say so (setup never holds up a
  leg). Items 2–4 passed (stop 3 and stop 4 questions first, stop 4 after every notification with the token counts
  and no tick promise, the merge carried on without pulling; it fast-forwarded). Git rows 1–5 PASS; row 6 printed
  `1`, the plan template's own header line ("checkbox (`- [ ]`) syntax"), a defect in the row, not the probe: every
  step box was ticked. (b) PASS on every item and row; the `.envrc` row matched `cut -d= -f2-` (D3.10), not the
  `-f2` written above. (c) PASS.
