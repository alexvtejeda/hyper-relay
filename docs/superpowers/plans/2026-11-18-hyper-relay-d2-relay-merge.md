# hyper-relay D.2, Plan 1: `relay-merge` Implementation Plan

**Card:** Several plans at once: conflicts, stacking, the preview stack (`68fab05e-4083-41bf-820f-8c201a951c50`)
**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-d2-several-plans-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–5 are
> the executor's. Task 6 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `owner` and
> `after merge` steps the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `relay-merge`, the one merge helper every relay landing will go through: it lands branches on `main` one
at a time as `--no-ff` merge commits, gates each merged result with the repo's committed `.hyper-relay/merge.conf`,
and reports by exit code; plus its suite, its user reference, this repo's own gates, and the release rule (D2.11) in
`CLAUDE.md` and the planner's facts.

**Architecture:** One POSIX script, `bin/relay-merge`, run by dash like `bin/wt`: repo-wide checks, then per branch
the checks, the merge and the gates, then the push and the cleanup. A suite written first,
`tests/relay-merge/run-tests.sh`, drives it on temporary git repos (a bare origin and a main checkout that tracks it)
with a fake `wt`, on the model of `tests/wt/`. `.hyper-relay/merge.conf` maps this repo's paths to the suites in
`CLAUDE.md`'s Checks table. `docs/relay-merge.md` is the user reference. Plan 2 (the skills) calls the tool only
through the Contract below.

**Tech Stack:** POSIX `sh` run by dash; git (2.28 or later, as `tests/wt/` already needs for `init -b`), `awk`, `sed`,
`grep`, GNU coreutils; Markdown. No skill changes, so no `skill-test` steps.

**How this was checked:** written against `main` at `7dfd91f` by reading only; nothing was built, run, installed or
generated. Read in this repo: `CLAUDE.md` (in full); the D.2 spec (in full); D.3's plan, the newest and this one's
model for format (1–884, 1144–1463, 1655–1701); E's plan, which brought `bin/wt` in (1–345, 541–840); `bin/wt`,
`docs/wt.md`, `scripts/bump-version.sh`, `.version-bump.json`, `.hyper-relay/agents.md`, `templates/agents/planner.md`,
`skills/visual-companion/scripts/run-tests.sh`, `.gitignore`, `.gitattributes` (all in full);
`tests/wt/run-tests.sh` (1–200, 290–404, and its section markers by `git grep`);
`tests/hyper-relay-agents/run-tests.sh` (1–60, 374–393, and by `git grep` every repo file it reads: `bin/`,
`templates/`, `.claude-plugin/plugin.json`, `hooks/hooks.json`, `.hyper-relay/agents.md`);
`tests/hyper-relay-agents/guard-test.sh` (1–30). Read-only git: `git ls-files` of `bin/`, `tests/`, `scripts/`,
`docs/superpowers/`, `.hyper-relay/`, `hooks/`, `templates/`, `.claude-plugin/` and the skills' script folders;
`git ls-files -s` of `bin/` and two suites (tools `100755`, suites `100644`); `git grep` of the shebang and exit line of
every suite in the Checks table (each exits non-zero on a failure; the voice-to-specs and add-card-line suites and the
generator's read the scripts the merge.conf lines below name); `git grep` of `skills/orchestrating/reviewing.md`'s merge
lines (§4 still merges with `finishing-a-development-branch`); `git grep` of `README.md` for install and version lines
(it is Plan 2's); `git log` of `tests/`, `bin/`, `templates/`, `.hyper-relay/` and `CLAUDE.md` (nothing since D.3's
`07a0479`, so the suite counts D.3 recorded hold: role agents 153 and 51, relay skills 24). Read outside the repo, as
the dispatch allowed: one private project's merge script, for its general mechanics. This plan names and quotes none
of it, and nothing in it reaches the repo.

**External facts (re-verified 2026-11-18):**
- **A plugin's `bin/` is on the Bash tool's `PATH`**
  ([code.claude.com/docs/en/plugins-reference](https://code.claude.com/docs/en/plugins-reference), "Standard layout"):
  "Files here are on the Bash tool's `PATH` while the plugin is enabled, so Claude runs them as bare commands." **As
  spec §1** ("On `PATH`").
- **`claude plugin validate` exits 0 with warnings**
  ([code.claude.com/docs/en/plugins/cli-reference.md](https://code.claude.com/docs/en/plugins/cli-reference.md),
  "plugin validate", "Output and exit codes"): exit `0` for "`Validation passed` or `Validation passed with warnings`",
  `1` for "`Validation failed`" (or a warning under `--strict`), `2` for an unexpected error. So it can be a gate
  without `--strict`, despite its three known warnings (P12).
- **`claude plugin update` and `/reload-plugins`** (same page, "plugin update"): "Update a plugin to the latest version
  its marketplace offers. The new version loads in your next session, or after you run `/reload-plugins` in a running
  one." **As spec D2.11 and §9**, which `CLAUDE.md` and the planner's facts now say (Task 5).
- **`git merge`** ([git-scm.com/docs/git-merge](https://git-scm.com/docs/git-merge)): `--no-ff` creates "a merge commit
  in all cases, even when the merge could instead be resolved as a fast-forward"; scripts "will see an editor opened
  when they run `git merge`", hence `--no-edit` beside `-m` (P2); on a conflict "The `MERGE_HEAD` ref is set", and
  `--abort` "tr[ies] to reconstruct the pre-merge state"; and git "will also abort if there are any changes registered
  in the index relative to the `HEAD` commit" (before any `MERGE_HEAD`: P6).
- **`git worktree remove`** ([git-scm.com/docs/git-worktree](https://git-scm.com/docs/git-worktree)): "Only clean
  worktrees (no untracked files and no modification in tracked files) can be removed"; "To remove a locked worktree,
  specify `--force` twice." The porcelain list gives `worktree <path>` first, then `branch refs/heads/<name>`.
- **`git branch -d`** ([git-scm.com/docs/git-branch](https://git-scm.com/docs/git-branch)): "The branch must be fully
  merged in its upstream branch, or in `HEAD` if no upstream was set." **A difference, with no design change:** the
  page does not say that `-d` refuses a branch checked out in a worktree; git does ("cannot delete branch … used by
  worktree"), and test 72 relies on it, so the suite shows it on the executor's git.

---

## Contract (identical in both D.2 plans)

- **Command:** `relay-merge <branch>...`, run from the main checkout on `main`. It lands each branch in the order
  given and stops at the first failure; branches that already landed stay landed.
- **Exit codes:** `0` every branch landed; `1` refused by a check, that branch did not change `main`; `2` merge
  conflict, aborted, `main` unchanged for that branch; `3` a gate failed, the merge is on `main`, unpushed.
- **Environment:** `PUSH=1` pushes, `PUSH=0` does not, unset asks on a terminal (no terminal: no); `KEEP=1` skips the
  cleanup (`git worktree remove`, `git branch -d`); `SKIP_TESTS=1` skips the `test` gates; `RELAY_MERGE_TRAILERS`
  holds lines appended to the merge message `Merge branch '<branch>'`.
- **Config:** `.hyper-relay/merge.conf`, read from `main`'s committed file: one gate per line,
  `<prefix> <build|test> <command>`, `#` starts a comment, the prefix `.` matches any change; each command runs with
  `sh -c` from the repo's top. No config: it lands without gates and says so.
- **On `PATH`:** Claude Code puts the plugin's `bin/` there; in the owner's shell, `~/.local/bin/relay-merge`, a
  symlink to the main checkout's `bin/relay-merge`.

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top unless they start with `~` or `/`. This plan is
  committed on `main`.
- **This plan runs first and alone** (spec D2.10): Plan 2's executor starts only after this plan has merged and its
  suites pass on `main` (Task 6, Step 11). Plan 1 does not release: the version stays 0.1.0 (Plan 2 releases 0.2.0).
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#<N>` followed, inside the same
  quoted paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and
  `Claude-Session:` with the URL from your dispatch prompt). The commands below write them as
  `<the line your instructions give>` and `<the URL your dispatch prompt gives>`: put the real lines there. Never tick
  the plan. Report every `quartz:` line a commit prints, verbatim.
- **New files are transcribed.** "Create X with exactly this content" means the Write tool, with the code block's text
  character for character, down to its spaces and blank lines. "Replace X with Y" means the Edit tool with X as
  `old_string`, exactly. If X is not found, read the range again; if the text moved or differs slightly, adapt as
  little as possible and record it as a deviation; if it is gone, stop and report.
- **dash, not bash.** `bin/relay-merge` and the suite are `#!/bin/sh` scripts run by dash: no `[[`, `local`, arrays,
  `function`, `$'…'` or `pipefail`. Syntax-check each with `dash -n`.
- **The suite is the contract.** If a test fails, fix the code, not the assertion. If you believe an assertion is wrong
  (for example, your git behaves differently from what the header's external facts say), stop and report it with the
  output: do not edit the assertion.
- **`relay-merge` runs only on the suite's temporary repos.** Never run `bin/relay-merge` in this checkout, the main
  checkout or any real repo, and never against a real branch. Task 3's loop runs the suites, which is fine.
- **Never** push, tag, create anything on GitHub, install or uninstall a plugin, start a live `claude -p` /
  `opencode run` session, or create `~/.local/bin/relay-merge`. `claude plugin validate .` is fine: it starts no
  session. Do not run upstream's live suites (`tests/claude-code/`, `tests/explicit-skill-requests/`,
  `tests/skill-triggering/`).
- **Outside your branch is not yours.** Never touch `main`, `~/.local/bin/`, `~/.claude/`, `~/.config/opencode/`, any
  other project's repo or the home directory's own repo. Task 6's `owner` and `after merge` steps do what is needed
  there, and they are not yours.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's scratch tracker: never stage, edit,
  move or delete either. A "the tree is clean" check ignores them.
- **This repo is public.** Everything you need is in this plan: read no other project's files. Nothing you write into
  the repo or a commit message names another project or quotes its files.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs its own checks only; pipe a suite through `tail -n 1` or `grep`. Task 3 runs every
  `merge.conf` command once (it is how the file is proved). The full gates run once, in Task 5: the suites this plan
  touches (the Checks table in `CLAUDE.md`: `relay-merge`'s, the role-agent suites for `.hyper-relay/agents.md`, the
  relay-skills guard, which reads `CLAUDE.md`), `dash -n` of the two scripts, and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 6. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`owner`** (at the click-through) or **`after merge`** (the owner and the orchestrator), with its command or action
  and the result that counts as PASS. After Task 5, report (gate results with counts, every deviation, any `quartz:`
  line, the suites not run and why), copy Task 6's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §1, Contract: the config is "read from `main`'s committed file" | Read once, when `relay-merge` starts, from `HEAD:.hyper-relay/merge.conf`, after the check that `HEAD` is `main`. The working tree's copy is never read, and a branch's own change to the file gates neither that branch nor later ones in the same run: it applies from the next run. Tests 101 and 102. |
| P2 | §1 step 3: the message is `Merge branch '<branch>'`, "followed by the lines in `RELAY_MERGE_TRAILERS`" | Followed by a blank line and then those lines, so git reads them as the message's trailers (test 4 reads them back with `%(trailers)`). The merge runs `git merge --no-ff --no-edit -m <message>`: `--no-edit` so no editor opens when it runs on a terminal (header). |
| P3 | §1: "`#` starts a comment"; "`.` matches any change" | A line whose first word starts with `#` is a comment, and blank lines are skipped; a `#` later in a command reaches `sh -c`, where ` #` starts a shell comment anyway. A prefix matches a changed path that starts with it, as text (`bin/wt` also matches `bin/wt-x`). A line with a kind other than `build`/`test`, no command, or a prefix starting with `/` or `./` (which could never match git's paths) refuses with exit 1, naming the line, before anything changes (tests 103–107). |
| P4 | §1 step 4: "every config line whose path prefix matches" | Each command runs **once per branch**, however many matching lines name it (compared as exact text). Not in the spec: this repo's `merge.conf` names one suite under several prefixes. Test 13. |
| P5 | §1: the checks run "for each branch" | The repo-wide ones (the main checkout, on `main`, no merge in progress) and the config's validity are checked once, at the start: nothing between two landings changes them. Three checks are added, each exit 1: an argument starting with `-` (there are no options), the branch `main` itself, and a branch worktree whose folder is gone. |
| P6 | §1: exit 1 is "refused by a check; that branch did not change `main`" | Also when git itself refuses to start the merge (a staged change on `main`, an untracked file the branch would overwrite): no `MERGE_HEAD` is written and `main` is unchanged. A merge that stops with `MERGE_HEAD` (a conflict) is aborted: exit 2. Tests 93–95 and 32–38. |
| P7 | §1: "`PUSH=1` pushes, `PUSH=0` does not, otherwise it asks on a terminal" | It pushes `main` to `main`'s configured remote, else `origin`. When `main` is level with its upstream, nothing is pushed or asked. A `PUSH` other than `1` or `0` acts as unset. Before asking, it drops what was typed on the terminal while the gates ran, so a stray Enter cannot answer (a mechanic of the script the spec ports from, which met that bug). |
| P8 | §1 checks: "no uncommitted tracked changes under the paths the gates watch"; the worktree "is clean" | On `main`: `git diff --name-only --no-renames HEAD` (staged and unstaged, both sides of a rename) filtered by the gates' prefixes; untracked files do not count. In the branch's worktree: `git status --porcelain` empty, untracked files included, because `git worktree remove` refuses them and the cleanup would fail. |
| P9 | §1 checks: "no `wt` stack up (`wt ls`, when `wt` is on `PATH`)" | A `wt ls` line that names exactly the worktree's path, its stack running or not. A stack on a longer path does not match (test 90). |
| P10 | §1 step 4: output goes "to a log under `${XDG_STATE_HOME:-$HOME/.local/state}/relay-merge/`" | One log per branch and run: `<repo folder>-<YYYYmmdd-HHMMSS>-<branch, with / as ->.log`. A failure also prints the log's path and the short hash `main` was on before the merge, the point an undo goes back to (the tool never undoes). |
| P11 | §1: push and cleanup come "after every branch is in" | After a failure (exit 1, 2 or 3) nothing is pushed or cleaned up, and the message names the branches that landed before it (tests 43–48). |
| P12 | §1: "This repo's own file maps its paths to its suites (the Checks table in `CLAUDE.md`)" | No `.` line, so a branch that touches only `tests/wt/` runs only the `wt` suite, as spec §10's reviewer probe needs. `build` lines: `claude plugin validate .` (exit 0 with its warnings, header) under `.claude-plugin/`, `skills/` and `hooks/`, and `dash -n` of the three tools in `bin/`. `test` lines: each Checks-table suite under the paths it reads. Paths no suite reads (`docs/`, `scripts/`, `package.json`, `.gitignore`, …) have no gate. Task 3 runs every command once and requires exit 0. |
| P13 | §1 Docs and §9: the `CLAUDE.md` edits | Also a `relay-merge` bullet under "How a change reaches the owner", beside `wt`'s (spec §1, "On `PATH`"). The first bullet there ("merge to `main`") is unchanged: the relay's merge moves to `relay-merge` in Plan 2's `reviewing.md` §4. |
| P14 | §9: every plan "that changes what the plugin ships (anything outside `docs/` and `tests/`)" releases | Kept literal in `CLAUDE.md` and the planner's facts, so a change to `CLAUDE.md`, `README.md` or `.hyper-relay/` alone also releases. **For the owner (Task 6 Step 9):** keep it, or narrow it. The rule starts once `main`'s `.claude-plugin/plugin.json` is at 0.2.0 or later, a test a planner can run, and the new version is `main`'s at the time with its patch raised, so two plans in flight never pick the same number. |
| P15 | §10: "**After merge (the owner):** the `~/.local/bin/relay-merge` symlink; `command -v relay-merge` prints it" | Also, in Task 6: the suites on the merged `main` before Plan 2's executor starts (D2.10, §11); the suite once more through the symlink; this repo's agents regenerated, since `.hyper-relay/agents.md` changed; `main` pushed only if the owner says so (otherwise 0.2.0's release pushes it); and the last-task record, as D.3's. |
| P16 | §1 Tests: "on temporary git repos with a fake `wt`" | Hermetic as well: `HOME` is a temporary folder (no global git config or hook; the default log folder is tested under it), `GIT_CONFIG_NOSYSTEM=1`, and the identity comes from the environment. The caller's `PUSH`, `KEEP`, `SKIP_TESTS`, `RELAY_MERGE_TRAILERS` and `XDG_STATE_HOME` are unset first, since this repo's `relay-merge` runs the suite as a gate. "`wt` not on `PATH`" is not tested: a `PATH` without the owner's `~/.local/bin/wt` would have to be built tool by tool, for one `command -v` line. |
| P17 | §1 Docs: `docs/relay-merge.md` "like `docs/wt.md`" | `README.md` is Plan 2's, so the symlink command is in `docs/relay-merge.md` itself, not in the README's Install section as `wt`'s is. §1's example config is not reused: the doc's example names no project's folders. |
| P18 | §11: Plan 1's merge runs "as today's skills run them" | Plan 1 merges with `finishing-a-development-branch`, not with its own `relay-merge`; its `merge.conf` gates the merges after it. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–5 (the merge helper and the release rule); the rest is Plan 2's |
| Decisions (owner, 2026-11-18) | D2.3: 1–4. D2.6: the Contract; 2. D2.9: the Contract's exit codes, implemented in 2 (their handling is Plan 2's). D2.10: Execution notes; 6 (Step 11). D2.11: 5; 6 (Step 9). D2.1, D2.2, D2.4, D2.5, D2.7, D2.8: Plan 2's |
| The plans | File structure; 1–5 |
| 1. `bin/relay-merge` (Plan 1) | 1 (the tests), 2 (the tool), 3 (this repo's `merge.conf`), 4 (`docs/relay-merge.md`), 5 (`CLAUDE.md`'s Layout and Checks row); 6 (Step 12, the symlink) |
| 2. `parallel.md` §1: what runs at once (Plan 2) | Plan 2's; none here |
| 3. `parallel.md` §2: the conflict check (Plan 2) | Plan 2's; none here |
| 4. Planning several plans (`parallel.md` §1, Plan 2) | Plan 2's; none here |
| 5. `parallel.md` §3: stacking (Plan 2) | Plan 2's; none here |
| 6. Landing: `parallel.md` §4 and `reviewing.md` §4 (Plan 2) | Plan 2's: it calls `relay-merge` only through the Contract, whose exit codes Task 2 implements and tests 1–107 cover |
| 7. The other files (Plan 2) | Plan 2's; none here (`README.md` included) |
| 8. The standing skill-test leg (Plan 2, `reviewing.md`) | Plan 2's; none here (this plan changes no skill, so it has no `skill-test` steps) |
| 9. The release (D2.11) | 5 (the rule in `CLAUDE.md` and `.hyper-relay/agents.md`); the 0.2.0 release itself is Plan 2's |
| 10. Testing and acceptance | Plan 1's executor gates: 2, 5. Its `reviewer` steps: 6 (Steps 3–5). Its after-merge steps: 6 (Step 12). Plan 2's parts: Plan 2's |
| 11. Running D.2 itself | Execution notes; 6 (Step 11, the suites on the merged `main` before Plan 2's handoff) |
| 12. Out of scope | Execution notes (none of it is here) |

## File structure

- **Create (Task 1):** `tests/relay-merge/run-tests.sh` (mode 644), the suite, with its fake `wt` inside it.
- **Create (Task 2):** `bin/relay-merge` (mode 755).
- **Create (Task 3):** `.hyper-relay/merge.conf`, this repo's gates.
- **Create (Task 4):** `docs/relay-merge.md`, the user reference.
- **Modify (Task 5):** `CLAUDE.md` (Layout, "How a change reaches the owner", Checks), `.hyper-relay/agents.md`
  (`## planner/execution-notes`).
- **Unchanged:** `README.md` (Plan 2's), every skill, `templates/`, `hooks/`, `bin/wt`, `bin/hyper-relay-agents`, the
  other suites, `package.json` and `.claude-plugin/` (no release).
- **Task 6, outside the branch (owner and orchestrator):** `~/.local/bin/relay-merge`, this repo's generated agents
  under `.claude/`, the push of `main`, and this plan's record on `main`.

---

### Task 1: The suite, written first (spec §1 Tests; P16)

**Files:**
- Create: `tests/relay-merge/run-tests.sh`

- [ ] **Step 1: Write the suite.** Create `tests/relay-merge/run-tests.sh` with exactly this content:

```sh
#!/bin/sh
# POSIX tests for relay-merge. Real git, on temporary repos: a bare origin and a main
# checkout on main that tracks it. A fake `wt` goes first on PATH, and HOME is a
# temporary folder, so no git config, hook or state of this machine is used.
# Usage: sh tests/relay-merge/run-tests.sh   (RELAY_MERGE_BIN overrides the script under test)
# Expect: "107 passed, 0 failed"
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
RM_BIN="${RELAY_MERGE_BIN:-$HERE/../../bin/relay-merge}"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

# relay-merge's settings are environment variables: none may leak in from the caller,
# which can be a relay-merge running this suite as one of its gates.
unset PUSH KEEP SKIP_TESTS RELAY_MERGE_TRAILERS XDG_STATE_HOME GIT_DIR GIT_WORK_TREE FAKE_WT_LS
HOME="$TMP_ROOT/home"
GIT_CONFIG_NOSYSTEM=1
GIT_AUTHOR_NAME=t
GIT_AUTHOR_EMAIL=t@example.invalid
GIT_COMMITTER_NAME=t
GIT_COMMITTER_EMAIL=t@example.invalid
export HOME GIT_CONFIG_NOSYSTEM GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
mkdir -p "$HOME"

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

mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/wt" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_WT_LOG"
if [ "${1:-}" = ls ]; then
    if [ -n "${FAKE_WT_LS:-}" ]; then printf '%s\n' "$FAKE_WT_LS"; else echo 'no wt stacks'; fi
fi
exit 0
EOF
chmod +x "$TMP_ROOT/fakebin/wt"

# The gates of most cases. Each writes what ran to $GATE_LOG; core/check.sh prints 25
# lines and fails once core/broken exists. The docs/ and . lines are the same command.
CONF='# prefix  kind   command
core/     build  echo core-build >> "$GATE_LOG"
core/     test   echo core-test >> "$GATE_LOG"; sh core/check.sh
ui/       test   echo ui-test >> "$GATE_LOG"
docs/     test   echo "any-test $(git rev-parse HEAD)" >> "$GATE_LOG"
.         test   echo "any-test $(git rev-parse HEAD)" >> "$GATE_LOG"

    # an indented comment, after a blank line'

# new_repo [<merge.conf text>]: a bare origin and a main checkout on main that tracks
# it, with core/, ui/ and docs/ and, when given, the text as a committed merge.conf.
# Sets CASE_DIR, MAIN, ORIGIN, GATE_LOG and FAKE_WT_LOG.
new_repo() {
    CASE_DIR=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    MAIN="$CASE_DIR/proj"
    ORIGIN="$CASE_DIR/origin.git"
    GATE_LOG="$CASE_DIR/gates.log"
    FAKE_WT_LOG="$CASE_DIR/wt.log"
    export GATE_LOG FAKE_WT_LOG
    unset FAKE_WT_LS
    : > "$GATE_LOG"
    : > "$FAKE_WT_LOG"
    git init -q --bare -b main "$ORIGIN"
    git init -q -b main "$MAIN"
    mkdir -p "$MAIN/core" "$MAIN/ui" "$MAIN/docs"
    printf 'core\n' > "$MAIN/core/main.txt"
    printf 'ui\n' > "$MAIN/ui/main.txt"
    printf 'docs\n' > "$MAIN/docs/readme.txt"
    printf '/.worktrees/\n' > "$MAIN/.gitignore"
    printf '%s\n' 'i=1' 'while [ "$i" -le 25 ]; do echo "check line $i"; i=$((i + 1)); done' \
        '[ ! -e core/broken ]' > "$MAIN/core/check.sh"
    if [ $# -gt 0 ]; then
        mkdir -p "$MAIN/.hyper-relay"
        printf '%s\n' "$1" > "$MAIN/.hyper-relay/merge.conf"
    fi
    git -C "$MAIN" add .
    git -C "$MAIN" commit -q -m init
    git -C "$MAIN" remote add origin "$ORIGIN"
    git -C "$MAIN" push -q -u origin main > /dev/null 2>&1
}

# commit_in <checkout> <file> <text>: writes <file> there and commits it.
commit_in() {
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -- "$2"
    git -C "$1" commit -q -m "change $2"
}

# new_branch <branch> <file> [<text>]: a branch from main with no worktree, whose one
# commit writes <file>. The main checkout stays on main.
new_branch() {
    git -C "$MAIN" switch -q -c "$1" main
    commit_in "$MAIN" "$2" "${3:-$1}"
    git -C "$MAIN" switch -q main
}

# new_worktree <branch> <file>: the same, in a worktree under .worktrees/. Sets WT.
new_worktree() {
    WT="$MAIN/.worktrees/$(printf '%s' "$1" | tr '/' '-')"
    git -C "$MAIN" worktree add -q -b "$1" "$WT" main
    commit_in "$WT" "$2" "$1"
}

# run_rm <dir> <"NAME=value ..." or ""> [<arg>...]: relay-merge, run from <dir> with no
# terminal on stdin and the fake wt first on PATH. Sets OUT and RC.
run_rm() {
    rm_dir=$1
    rm_env=$2
    shift 2
    OUT=$(cd "$rm_dir" && env $rm_env PATH="$TMP_ROOT/fakebin:$PATH" dash "$RM_BIN" "$@" 2>&1 < /dev/null)
    RC=$?
}

sha_of() { git -C "$1" rev-parse "$2"; } # checkout rev
has_branch() { # branch: prints 0 when the main checkout has it, 1 when not
    git -C "$MAIN" show-ref --verify --quiet "refs/heads/$1"
    echo $?
}

echo '--- one branch lands'
new_repo "$CONF"
new_branch feat/ui ui/new.txt
PRE=$(sha_of "$MAIN" HEAD)
TIP=$(sha_of "$MAIN" feat/ui)
RELAY_MERGE_TRAILERS='Co-Authored-By: Someone <someone@example.invalid>
Claude-Session: https://example.invalid/session'
export RELAY_MERGE_TRAILERS
run_rm "$MAIN" "PUSH=0" feat/ui
unset RELAY_MERGE_TRAILERS
MERGE=$(sha_of "$MAIN" HEAD)
assert_eq "lands: exit 0" 0 "$RC"
assert_eq "lands: --no-ff makes a merge commit where a fast-forward would do" "$PRE $TIP" \
    "$(git -C "$MAIN" log -1 --format=%P)"
assert_eq "lands: the message names the branch" "Merge branch 'feat/ui'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "lands: RELAY_MERGE_TRAILERS end the message, as its trailers" \
    "Co-Authored-By: Someone <someone@example.invalid>
Claude-Session: https://example.invalid/session" \
    "$(git -C "$MAIN" log -1 --format='%(trailers:only,unfold)' | sed '/^$/d')"
assert_eq "lands: the branch is deleted" 1 "$(has_branch feat/ui)"
assert_eq "lands: PUSH=0 does not push" "$PRE" "$(sha_of "$ORIGIN" main)"
assert_contains "lands: says what landed" "landed: feat/ui" "$OUT"
GATES=$(cat "$GATE_LOG")
assert_contains "prefix: ui/ runs its gate" "ui-test" "$GATES"
assert_not_contains "prefix: core/ does not run for a ui/ change" "core-" "$GATES"
assert_contains "prefix: . runs, on the merged result" "any-test $MERGE" "$GATES"
assert_eq "the log: under HOME/.local/state/relay-merge, named for the repo and the branch" 1 \
    "$(ls "$HOME/.local/state/relay-merge" | grep -c '^proj-[0-9-]*-feat-ui\.log$')"

echo '--- one run per command'
new_repo "$CONF"
new_branch feat/docs docs/guide.txt
run_rm "$MAIN" "" feat/docs
assert_eq "docs/: exit 0" 0 "$RC"
assert_eq "docs/: its gate is the . gate's command, and runs once" "any-test $(sha_of "$MAIN" HEAD)" "$(cat "$GATE_LOG")"
assert_contains "no terminal: the push is not asked" "No terminal to ask on, so: no" "$OUT"
assert_eq "no terminal: not pushed" "$(sha_of "$MAIN" HEAD^1)" "$(sha_of "$ORIGIN" main)"
assert_eq "no RELAY_MERGE_TRAILERS: the message is the subject alone" "Merge branch 'feat/docs'" \
    "$(git -C "$MAIN" log -1 --format=%B)"

echo '--- build and test gates, SKIP_TESTS'
new_repo "$CONF"
new_branch feat/core core/new.txt
run_rm "$MAIN" "" feat/core
assert_eq "core/: exit 0" 0 "$RC"
assert_eq "core/: every matching gate, in the file's order" "core-build
core-test
any-test $(sha_of "$MAIN" HEAD)" "$(cat "$GATE_LOG")"

new_repo "$CONF"
new_branch feat/core core/new.txt
run_rm "$MAIN" "SKIP_TESTS=1" feat/core
assert_eq "SKIP_TESTS=1: exit 0" 0 "$RC"
assert_eq "SKIP_TESTS=1: the build gate runs, no test gate" "core-build" "$(cat "$GATE_LOG")"
assert_contains "SKIP_TESTS=1: says what it skipped" "skipped (SKIP_TESTS=1): echo core-test" "$OUT"

echo '--- a gate fails: exit 3'
new_repo "$CONF"
new_branch feat/broken core/broken
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "PUSH=1" feat/broken
assert_eq "gate fails: exit 3" 3 "$RC"
assert_eq "gate fails: the merge stays on main" "$PRE $(sha_of "$MAIN" feat/broken)" "$(git -C "$MAIN" log -1 --format=%P)"
assert_eq "gate fails: not pushed, even with PUSH=1" "$PRE" "$(sha_of "$ORIGIN" main)"
assert_eq "gate fails: the branch is kept" 0 "$(has_branch feat/broken)"
assert_contains "gate fails: the log's last line is printed" "check line 25" "$OUT"
assert_contains "gate fails: and its 20th line from the end" "check line 6" "$OUT"
assert_not_contains "gate fails: but not its 21st" "check line 5" "$OUT"
assert_not_contains "gate fails: the later gates do not run" "any-test" "$(cat "$GATE_LOG")"
assert_contains "gate fails: names where main was" "main was $(git -C "$MAIN" rev-parse --short "$PRE")" "$OUT"
assert_eq "gate fails: the main checkout is clean" "" "$(git -C "$MAIN" status --porcelain)"

echo '--- a conflict: exit 2'
new_repo "$CONF"
new_branch feat/clash core/main.txt clash
commit_in "$MAIN" core/main.txt "main moved on"
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/clash
assert_eq "conflict: exit 2" 2 "$RC"
assert_eq "conflict: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_eq "conflict: the merge is aborted" 1 "$(git -C "$MAIN" rev-parse -q --verify MERGE_HEAD > /dev/null; echo $?)"
assert_eq "conflict: the main checkout is clean" "" "$(git -C "$MAIN" status --porcelain)"
assert_eq "conflict: no gate runs" "" "$(cat "$GATE_LOG")"
assert_contains "conflict: says to resolve it on the branch" "Merge main into feat/clash" "$OUT"
assert_eq "conflict: the branch is kept" 0 "$(has_branch feat/clash)"

echo '--- several branches'
new_repo "$CONF"
new_branch feat/one ui/one.txt
new_branch feat/two docs/two.txt
run_rm "$MAIN" "" feat/one feat/two
assert_eq "several: exit 0" 0 "$RC"
assert_eq "several: they land in the order given" "Merge branch 'feat/two'
Merge branch 'feat/one'
init" "$(git -C "$MAIN" log --first-parent --format=%s)"
assert_eq "several: each is gated on its own changes" "ui-test
any-test
any-test" "$(sed 's/ .*//' "$GATE_LOG")"
assert_contains "several: says both landed" "landed: feat/one feat/two" "$OUT"

new_repo "$CONF"
new_branch feat/one ui/one.txt
new_branch feat/clash core/main.txt clash
new_branch feat/three docs/three.txt
commit_in "$MAIN" core/main.txt "main moved on"
git -C "$MAIN" push -q origin main > /dev/null 2>&1
PUSHED=$(sha_of "$ORIGIN" main)
run_rm "$MAIN" "PUSH=1" feat/one feat/clash feat/three
assert_eq "stops at the first failure: exit 2" 2 "$RC"
assert_eq "stops: the branch before it stays landed" "Merge branch 'feat/one'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "stops: the branch after it is not merged" 1 \
    "$(git -C "$MAIN" merge-base --is-ancestor feat/three HEAD; echo $?)"
assert_eq "stops: nothing is pushed" "$PUSHED" "$(sha_of "$ORIGIN" main)"
assert_eq "stops: nothing is cleaned up" 0 "$(has_branch feat/one)"
assert_contains "stops: names what landed before it" "landed before this: feat/one" "$OUT"

new_repo "$CONF"
new_branch feat/one ui/one.txt
run_rm "$MAIN" "" feat/one feat/missing
assert_eq "a refusal after a landing: exit 1" 1 "$RC"
assert_contains "a refusal after a landing: names the branch" "no branch named feat/missing" "$OUT"
assert_eq "a refusal after a landing: the earlier branch stays landed" "Merge branch 'feat/one'" \
    "$(git -C "$MAIN" log -1 --format=%s)"

echo '--- already in main'
new_repo "$CONF"
new_branch feat/old docs/old.txt
git -C "$MAIN" merge -q --no-ff --no-edit -m 'merged by hand' feat/old
git -C "$MAIN" push -q origin main > /dev/null 2>&1
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "PUSH=1" feat/old
assert_eq "already in main: exit 0" 0 "$RC"
assert_eq "already in main: no new commit" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_contains "already in main: says so" "already in main" "$OUT"
assert_eq "already in main: no gate runs" "" "$(cat "$GATE_LOG")"
assert_eq "already in main: it counts as landed, so it is cleaned up" 1 "$(has_branch feat/old)"
assert_contains "level with origin: nothing to push" "nothing to push" "$OUT"

echo '--- push'
new_repo "$CONF"
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "PUSH=1" feat/ui
assert_eq "PUSH=1: exit 0" 0 "$RC"
assert_eq "PUSH=1: origin's main is the merge" "$(sha_of "$MAIN" HEAD)" "$(sha_of "$ORIGIN" main)"

new_repo "$CONF"
new_branch feat/ui ui/new.txt
mv "$ORIGIN" "$ORIGIN.gone"
run_rm "$MAIN" "PUSH=1" feat/ui
assert_eq "a failed push: still exit 0" 0 "$RC"
assert_contains "a failed push: a warning" "warning: the push failed" "$OUT"

echo '--- worktrees and the cleanup'
new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
run_rm "$MAIN" "" feat/wt
assert_eq "worktree: exit 0" 0 "$RC"
assert_eq "worktree: removed" 1 "$([ -e "$WT" ]; echo $?)"
assert_eq "worktree: the branch is deleted" 1 "$(has_branch feat/wt)"
assert_eq "worktree: wt ls was asked about its stack" "ls" "$(cat "$FAKE_WT_LOG")"

new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
run_rm "$MAIN" "KEEP=1" feat/wt
assert_eq "KEEP=1: exit 0" 0 "$RC"
assert_eq "KEEP=1: the branch landed" "Merge branch 'feat/wt'" "$(git -C "$MAIN" log -1 --format=%s)"
assert_eq "KEEP=1: the worktree is kept" 0 "$([ -d "$WT" ]; echo $?)"
assert_eq "KEEP=1: the branch is kept" 0 "$(has_branch feat/wt)"

new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
git -C "$MAIN" worktree lock "$WT"
run_rm "$MAIN" "" feat/wt
assert_eq "a cleanup git refuses: still exit 0" 0 "$RC"
assert_contains "a cleanup git refuses: a warning for the worktree" "could not remove the worktree" "$OUT"
assert_contains "a cleanup git refuses: a warning for the branch" "kept the branch feat/wt" "$OUT"

echo '--- refusals: exit 1, main unchanged'
new_repo "$CONF"
new_worktree feat/wt ui/wt.txt
PRE=$(sha_of "$MAIN" HEAD)

run_rm "$MAIN" ""
assert_eq "no branch: exit 1" 1 "$RC"
assert_contains "no branch: the usage" "usage: relay-merge <branch>" "$OUT"

run_rm "$MAIN" "" --push feat/wt
assert_eq "an option: exit 1" 1 "$RC"

run_rm "$WT" "" feat/wt
assert_eq "from a worktree: exit 1" 1 "$RC"
assert_contains "from a worktree: says where to run it" "run relay-merge from the main checkout" "$OUT"

git -C "$MAIN" switch -q -c side
run_rm "$MAIN" "" feat/wt
assert_eq "main checkout not on main: exit 1" 1 "$RC"
assert_contains "main checkout not on main: says so" "not on main" "$OUT"
git -C "$MAIN" switch -q main

run_rm "$MAIN" "" main
assert_eq "main itself: exit 1" 1 "$RC"

run_rm "$MAIN" "" feat/nope
assert_eq "no such branch: exit 1" 1 "$RC"

printf 'more\n' >> "$WT/ui/wt.txt"
run_rm "$MAIN" "" feat/wt
assert_eq "a dirty worktree: exit 1" 1 "$RC"
assert_contains "a dirty worktree: says so" "has uncommitted changes" "$OUT"
git -C "$WT" checkout -q -- ui/wt.txt

printf 'more\n' >> "$MAIN/core/main.txt"
run_rm "$MAIN" "" feat/wt
assert_eq "an uncommitted change under a watched path: exit 1" 1 "$RC"
assert_contains "an uncommitted change: the file is named" "core/main.txt" "$OUT"
git -C "$MAIN" checkout -q -- core/main.txt

FAKE_WT_LS="proj-wt-feat-wt  2 running  $WT"
export FAKE_WT_LS
run_rm "$MAIN" "" feat/wt
assert_eq "a wt stack up: exit 1" 1 "$RC"
assert_contains "a wt stack up: says to take it down" "run wt down in $WT first" "$OUT"

assert_eq "the refusals left main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_eq "the refusals ran no gate" "" "$(cat "$GATE_LOG")"

FAKE_WT_LS="proj-wt-other  1 running  $WT-other
  web              http://localhost:30104"
run_rm "$MAIN" "" feat/wt
assert_eq "another worktree's stack, on a longer path, does not block" 0 "$RC"
unset FAKE_WT_LS

new_repo "$CONF"
new_branch feat/clash core/main.txt clash
commit_in "$MAIN" core/main.txt "main moved on"
new_branch feat/ui ui/new.txt
git -C "$MAIN" merge -q --no-edit feat/clash > /dev/null 2>&1
run_rm "$MAIN" "" feat/ui
assert_eq "a merge in progress: exit 1" 1 "$RC"
assert_contains "a merge in progress: says so" "a merge is in progress" "$OUT"
git -C "$MAIN" merge --abort

new_repo "$CONF"
new_branch feat/docs docs/new.txt
printf 'untracked\n' > "$MAIN/docs/new.txt"
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/docs
assert_eq "git refuses to start the merge: exit 1" 1 "$RC"
assert_eq "git refuses to start the merge: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"
assert_contains "git refuses to start the merge: says so" "git refused to merge feat/docs" "$OUT"

echo '--- no merge.conf'
new_repo
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "no config: exit 0" 0 "$RC"
assert_contains "no config: says it lands without gates" "landed without gates" "$OUT"

new_repo
new_branch feat/ui ui/new.txt
printf 'more\n' >> "$MAIN/docs/readme.txt"
run_rm "$MAIN" "" feat/ui
assert_eq "no config: an uncommitted change anywhere refuses" 1 "$RC"

echo "--- main's committed merge.conf"
NARROW='core/ test echo core-test >> "$GATE_LOG"'
new_repo "$NARROW"
new_branch feat/ui ui/new.txt
printf 'more\n' >> "$MAIN/docs/readme.txt"
run_rm "$MAIN" "" feat/ui
assert_eq "an uncommitted change no gate watches: exit 0" 0 "$RC"
assert_contains "a change no gate matches: says so" "no gate matches its changes" "$OUT"

new_repo "$NARROW"
new_branch feat/conf .hyper-relay/merge.conf '. test exit 1'
run_rm "$MAIN" "" feat/conf
assert_eq "a branch's own merge.conf does not gate it" 0 "$RC"

new_repo "$NARROW"
new_branch feat/ui ui/new.txt
printf '%s\n' '. test exit 1' >> "$MAIN/.hyper-relay/merge.conf"
run_rm "$MAIN" "" feat/ui
assert_eq "an uncommitted merge.conf is not read" 0 "$RC"

echo '--- a bad merge.conf: exit 1, before anything changes'
new_repo 'core/ deploy echo x'
new_branch feat/ui ui/new.txt
PRE=$(sha_of "$MAIN" HEAD)
run_rm "$MAIN" "" feat/ui
assert_eq "an unknown kind: exit 1" 1 "$RC"
assert_contains "an unknown kind: the line is named" ".hyper-relay/merge.conf line 1" "$OUT"
assert_eq "an unknown kind: main unchanged" "$PRE" "$(sha_of "$MAIN" HEAD)"

new_repo 'core/ test'
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "a line with no command: exit 1" 1 "$RC"

new_repo './core/ test echo x'
new_branch feat/ui ui/new.txt
run_rm "$MAIN" "" feat/ui
assert_eq "a prefix with a leading ./: exit 1" 1 "$RC"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
```

- [ ] **Step 2: Syntax.**

Run: `dash -n tests/relay-merge/run-tests.sh`
Expected: silent, exit 0.

- [ ] **Step 3: Run it; it fails, because `bin/relay-merge` does not exist yet.**

| Run | Expected |
|---|---|
| `sh tests/relay-merge/run-tests.sh \| grep -m 1 -e '^ok' -e '^FAIL'` | `FAIL lands: exit 0` |
| `sh tests/relay-merge/run-tests.sh \| tail -n 1` | `<p> passed, <f> failed`, with `<f>` above 0 and `<p> + <f>` = 107 |

If the counts do not add up to 107, a case did not run to its assertions: stop and report the output.

- [ ] **Step 4: Commit.**

```bash
git add tests/relay-merge/run-tests.sh
git commit -m "test: relay-merge's suite, written before the tool" -m "tests/relay-merge/run-tests.sh runs relay-merge on temporary git repos, a bare origin and a main checkout that tracks it, with a fake wt first on PATH and HOME in a temporary folder: each exit code and check, the skip of a branch already in main, several branches stopping at the first failure, prefix matching with '.', one run per command, SKIP_TESTS, KEEP, PUSH and no terminal, the cleanup, and a --no-ff merge commit that ends in RELAY_MERGE_TRAILERS. It fails until bin/relay-merge exists." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s tests/relay-merge/run-tests.sh` must print a line starting `100644`.

### Task 2: `bin/relay-merge` (spec §1; the Contract; P1–P11)

**Files:**
- Create: `bin/relay-merge`
- Test: `tests/relay-merge/run-tests.sh`

- [ ] **Step 1: Write the tool.** Create `bin/relay-merge` with exactly this content:

```sh
#!/bin/sh
# relay-merge: land branches on main one at a time, gating each merged result.
# POSIX shell, run by dash. How to use it, and what to put in .hyper-relay/merge.conf:
# docs/relay-merge.md in hyper-relay.
#
#   relay-merge <branch>...    in the main checkout, on main
#
# Each branch, in the order given, stopping at the first failure: the checks, then
# git merge --no-ff, then the gates of main's committed .hyper-relay/merge.conf whose
# path prefix matches a file the branch changed, run on the merged result. Once every
# branch is in: the push, then the cleanup of each branch and its worktree.
#
# Exit: 0 every branch landed; 1 refused by a check, that branch did not change main;
#       2 a merge conflict, aborted, main unchanged for that branch;
#       3 a gate failed, the merge is on main, unpushed.
# Environment: PUSH=1 pushes, PUSH=0 does not, unset asks on a terminal (no terminal:
#       no); KEEP=1 skips the cleanup; SKIP_TESTS=1 skips the test gates;
#       RELAY_MERGE_TRAILERS holds lines for the end of each merge message.
set -eu

CONF_PATH=.hyper-relay/merge.conf
LOG_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/relay-merge"
USAGE="usage: relay-merge <branch>... (in the main checkout, on main; settings are environment variables: docs/relay-merge.md)"
LANDED=

say() { printf 'relay-merge: %s\n' "$*"; }
warn() { printf 'relay-merge: warning: %s\n' "$*" >&2; }

# stop <code> <message>: says why, and what landed before it, then exits with <code>.
stop() {
    code=$1
    shift
    printf 'relay-merge: %s\n' "$*" >&2
    if [ -n "$LANDED" ]; then
        printf 'relay-merge: landed before this:%s (nothing was pushed or cleaned up)\n' "$LANDED" >&2
    fi
    exit "$code"
}

# under <prefixes>: the paths on stdin, one per line, that start with one of the
# newline-separated prefixes. The prefix "." matches every path.
under() {
    PREFIXES=$1 awk 'BEGIN { n = split(ENVIRON["PREFIXES"], p, "\n") }
        { for (i = 1; i <= n; i++) if (p[i] == "." || (p[i] != "" && index($0, p[i]) == 1)) { print; next } }'
}

# worktree_of <branch>: the path of the worktree that has <branch> checked out, if any.
worktree_of() {
    git worktree list --porcelain | awk -v ref="refs/heads/$1" '
        /^worktree / { path = substr($0, 10) }
        $0 == "branch " ref { print path; exit }'
}

# stack_up <worktree>: wt ls lists a stack for exactly that worktree. False when wt is
# not on PATH.
stack_up() {
    command -v wt > /dev/null 2>&1 || return 1
    wt ls 2> /dev/null | sed -n 's/^[^ ]*  [0-9]* running  //p' | sed 's/ \[stale: .*\]$//' |
        grep -q -x -F -e "$1"
}

# drain_input: drops what was typed on the terminal while the gates ran, so an Enter
# pressed then cannot answer the push question.
drain_input() {
    tty_state=$(stty -g 2> /dev/null) || return 0
    stty -icanon min 0 time 0 2> /dev/null || return 0
    while IFS= read -r junk; do :; done
    stty "$tty_state" 2> /dev/null || true
}

# want_push <question>: PUSH=1 is yes and PUSH=0 no. Otherwise the answer comes from a
# terminal, and with no terminal it is no.
want_push() {
    case ${PUSH:-} in
        1) return 0 ;;
        0) return 1 ;;
    esac
    if [ ! -t 0 ]; then
        say "$1 No terminal to ask on, so: no (PUSH=1 pushes)."
        return 1
    fi
    drain_input
    printf 'relay-merge: %s [y/N] ' "$1"
    answer=
    read -r answer || true
    case $(printf '%s' "$answer" | tr -d ' \t\r') in
        y | Y | yes | Yes | YES) return 0 ;;
    esac
    return 1
}

# run_gates: on the merged result, each gate whose prefix matches a file $branch
# changed, once per command, in the file's order. A failed gate stops everything.
run_gates() {
    if [ "$HAVE_CONF" = 0 ]; then
        say "  no $CONF_PATH on main: landed without gates"
        return 0
    fi
    log="$LOG_ROOT/$REPO_NAME-$STAMP-$(printf '%s' "$branch" | tr '/' '-').log"
    seen=
    ran=0
    while read -r prefix kind cmd; do
        case $prefix in '' | '#'*) continue ;; esac
        [ -n "$(printf '%s\n' "$changed" | under "$prefix")" ] || continue
        if printf '%s\n' "$seen" | grep -q -x -F -e "$cmd"; then
            continue
        fi
        seen="$seen
$cmd"
        if [ "$kind" = test ] && [ "${SKIP_TESTS:-0}" = 1 ]; then
            say "  skipped (SKIP_TESTS=1): $cmd"
            continue
        fi
        printf '\n$ %s\n' "$cmd" >> "$log"
        printf 'relay-merge:   %-5s  %s ... ' "$kind" "$cmd"
        if sh -c "$cmd" < /dev/null >> "$log" 2>&1; then
            echo ok
            ran=$((ran + 1))
        else
            echo FAILED
            tail -n 20 "$log" | sed 's/^/    /' >&2
            stop 3 "a gate failed on the merged result of $branch. The merge is on main, NOT pushed; main was $before before it. Fix forward, or undo it yourself. Log: $log"
        fi
    done << EOF
$CONF
EOF
    if [ -z "$seen" ]; then
        say "  no gate matches its changes"
    elif [ "$ran" -gt 0 ]; then
        say "  $ran gate(s) passed; log: $log"
    fi
}

# --- the repo-wide checks, before anything changes
for arg in "$@"; do
    case $arg in
        -*) stop 1 "$USAGE" ;;
    esac
done
[ $# -gt 0 ] || stop 1 "$USAGE"
TOP=$(git rev-parse --show-toplevel 2> /dev/null) || stop 1 "not inside a git repository"
cd "$TOP"
git_dir=$(cd "$(git rev-parse --git-dir)" && pwd -P)
git_common=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
[ "$git_dir" = "$git_common" ] || stop 1 "this is a worktree; run relay-merge from the main checkout"
[ "$(git branch --show-current)" = main ] || stop 1 "the main checkout is not on main; switch it to main first"
if git rev-parse -q --verify MERGE_HEAD > /dev/null; then
    stop 1 "a merge is in progress in the main checkout; finish or abort it first"
fi

# --- main's committed merge.conf: checked line by line, and the prefixes it watches
HAVE_CONF=0
CONF=
WATCH=.
if git cat-file -e "HEAD:$CONF_PATH" 2> /dev/null; then
    HAVE_CONF=1
    CONF=$(git show "HEAD:$CONF_PATH")
    WATCH=
    n=0
    while read -r prefix kind cmd; do
        n=$((n + 1))
        case $prefix in
            '' | '#'*) continue ;;
            /* | ./*) stop 1 "$CONF_PATH line $n: the prefix $prefix must be a path from the repo's top, with no leading / or ./" ;;
        esac
        case $kind in
            build | test) ;;
            *) stop 1 "$CONF_PATH line $n: the kind is build or test, not '$kind'" ;;
        esac
        [ -n "$cmd" ] || stop 1 "$CONF_PATH line $n: no command"
        WATCH="$WATCH
$prefix"
    done << EOF
$CONF
EOF
    mkdir -p "$LOG_ROOT" || stop 1 "cannot create the log folder $LOG_ROOT"
fi
REPO_NAME=$(basename "$TOP")
STAMP=$(date +%Y%m%d-%H%M%S)

# --- each branch: the checks, the merge, the gates
for branch in "$@"; do
    say "landing $branch"
    [ "$branch" != main ] || stop 1 "main cannot land on itself"
    dirt=$(git -c core.quotePath=false diff --name-only --no-renames HEAD -- | under "$WATCH")
    if [ -n "$dirt" ]; then
        printf '%s\n' "$dirt" | sed 's/^/    /' >&2
        stop 1 "uncommitted changes on main under the paths the gates watch (above); commit or stash them first"
    fi
    git rev-parse -q --verify "refs/heads/$branch" > /dev/null || stop 1 "no branch named $branch"
    wt=$(worktree_of "$branch")
    if [ -n "$wt" ]; then
        [ -d "$wt" ] || stop 1 "$branch's worktree $wt is missing; git worktree prune forgets it"
        [ -z "$(git -C "$wt" status --porcelain)" ] || stop 1 "$branch's worktree $wt has uncommitted changes"
        if stack_up "$wt"; then
            stop 1 "$branch's worktree has a wt stack up; run wt down in $wt first"
        fi
    fi
    if git merge-base --is-ancestor "$branch" HEAD; then
        say "  already in main; nothing to merge"
        LANDED="$LANDED $branch"
        continue
    fi

    changed=$(git -c core.quotePath=false diff --name-only --no-renames "HEAD...$branch" --)
    before=$(git rev-parse --short HEAD)
    msg="Merge branch '$branch'"
    if [ -n "${RELAY_MERGE_TRAILERS:-}" ]; then
        msg="$msg

$RELAY_MERGE_TRAILERS"
    fi
    if ! git merge --no-ff --no-edit -m "$msg" "$branch"; then
        if git rev-parse -q --verify MERGE_HEAD > /dev/null; then
            git merge --abort || warn "git merge --abort failed; look at the main checkout before anything else"
            stop 2 "merging $branch conflicted, so it was aborted and main is unchanged. Merge main into $branch and resolve it there"
        fi
        stop 1 "git refused to merge $branch (above); main is unchanged"
    fi
    say "  merged as $(git rev-parse --short HEAD)"
    run_gates
    LANDED="$LANDED $branch"
done

# --- every branch is in: the push, then the cleanup
remote=$(git config --get branch.main.remote || echo origin)
ahead=$(git rev-list --count '@{upstream}..HEAD' 2> /dev/null) || ahead=
if [ "$ahead" = 0 ]; then
    say "main is level with its upstream: nothing to push"
elif want_push "Push main to $remote${ahead:+ ($ahead commit(s) ahead)}?"; then
    if git push "$remote" main; then
        say "pushed main to $remote"
    else
        warn "the push failed; main has landed here, not on $remote"
    fi
else
    say "main is not pushed"
fi

if [ "${KEEP:-0}" = 1 ]; then
    say "kept the branches and their worktrees (KEEP=1)"
else
    for branch in $LANDED; do
        wt=$(worktree_of "$branch")
        if [ -n "$wt" ]; then
            if git worktree remove "$wt"; then
                say "removed the worktree $wt"
            else
                warn "could not remove the worktree $wt; it is left as it is"
            fi
        fi
        if git branch -d "$branch" > /dev/null 2>&1; then
            say "deleted the branch $branch"
        else
            warn "kept the branch $branch (git branch -d refused it)"
        fi
    done
fi
say "landed:$LANDED"
```

- [ ] **Step 2: Mode and syntax.**

```bash
chmod 755 bin/relay-merge
```

| Run | Expected |
|---|---|
| `dash -n bin/relay-merge` | silent, exit 0 |
| `test -x bin/relay-merge && echo executable` | `executable` |

- [ ] **Step 3: The suite passes.**

Run: `sh tests/relay-merge/run-tests.sh | tail -n 1`
Expected: `107 passed, 0 failed`

If anything fails, run `sh tests/relay-merge/run-tests.sh | grep -A 1 '^FAIL'`, fix `bin/relay-merge` (never the
suite), and run it again.

- [ ] **Step 4: What the tool must never do, and what it may read.**

| Run | Expected |
|---|---|
| `git grep --untracked -n -E -e '--force\|reset\|branch -D\|push -f\|--hard' -- bin/relay-merge` | nothing |
| `git grep --untracked -h -o -E '\$\{[A-Z_]+:-' -- bin/relay-merge \| sort -u` | five lines: `${KEEP:-`, `${PUSH:-`, `${RELAY_MERGE_TRAILERS:-`, `${SKIP_TESTS:-`, `${XDG_STATE_HOME:-` |
| `git grep --untracked -n -E '\[\[\|^ *local \|function ' -- bin/relay-merge tests/relay-merge` | nothing |

(`git grep --untracked` reads the new file before its commit.)

- [ ] **Step 5: Commit.**

```bash
git add bin/relay-merge
git commit -m "feat: relay-merge lands branches on main one at a time, gating each merged result" -m "relay-merge <branch>... runs in the main checkout, on main. Each branch, in order: the checks (main checkout, on main, no merge in progress, no uncommitted change under the watched paths, the branch exists, its worktree clean with no wt stack up), a skip when it is already in main, git merge --no-ff with RELAY_MERGE_TRAILERS at the end of the message, then the gates of main's committed .hyper-relay/merge.conf whose prefix matches a file it changed, run once per command on the merged result with a log under XDG_STATE_HOME. Then the push (PUSH, or a terminal's answer) and the cleanup (unless KEEP). Exit 1 a refusal, 2 a conflict (aborted), 3 a failed gate (the merge stays, unpushed)." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s bin/relay-merge` must print a line starting `100755`.

### Task 3: This repo's gates, `.hyper-relay/merge.conf` (spec §1; P12)

**Files:**
- Create: `.hyper-relay/merge.conf`

- [ ] **Step 1: Write the gates.** Create `.hyper-relay/merge.conf` with exactly this content:

```text
# hyper-relay's merge gates, for bin/relay-merge (docs/relay-merge.md). relay-merge reads
# this file from main's last commit and, for each branch it lands, runs every line whose
# path prefix matches a file the branch changed: once per command, in this order, with
# sh -c from the repo's top. SKIP_TESTS=1 skips the test lines. The suites are CLAUDE.md's
# Checks table. No line has the prefix ".", so a branch that touches one tool runs its gates.
#
# prefix                        kind   command

# Manifests and skills: it passes with its known warnings.
.claude-plugin/                 build  claude plugin validate .
skills/                         build  claude plugin validate .
hooks/                          build  claude plugin validate .

# Shell syntax of the tools in bin/.
bin/hyper-relay-agents          build  dash -n bin/hyper-relay-agents
bin/wt                          build  dash -n bin/wt
bin/relay-merge                 build  dash -n bin/relay-merge

# add-card-line, brainstorming's script.
skills/brainstorming/scripts/   test   sh tests/add-card-line/run-tests.sh
tests/add-card-line/            test   sh tests/add-card-line/run-tests.sh

# voice-to-specs.
skills/voice-to-specs/          test   sh skills/voice-to-specs/tests/transcribe-sh.test.sh
skills/voice-to-specs/          test   sh skills/voice-to-specs/tests/setup-sh.test.sh

# visual-companion.
skills/visual-companion/        test   bash skills/visual-companion/scripts/run-tests.sh

# Role agents: the generator's suite reads its templates, the hook, the plugin's version and
# this repo's facts; the guard's reads templates/hooks/.
bin/hyper-relay-agents          test   sh tests/hyper-relay-agents/run-tests.sh
templates/                      test   sh tests/hyper-relay-agents/run-tests.sh
hooks/                          test   sh tests/hyper-relay-agents/run-tests.sh
.claude-plugin/                 test   sh tests/hyper-relay-agents/run-tests.sh
.hyper-relay/agents.md          test   sh tests/hyper-relay-agents/run-tests.sh
tests/hyper-relay-agents/       test   sh tests/hyper-relay-agents/run-tests.sh
templates/hooks/                test   sh tests/hyper-relay-agents/guard-test.sh
tests/hyper-relay-agents/       test   sh tests/hyper-relay-agents/guard-test.sh

# wt.
bin/wt                          test   sh tests/wt/run-tests.sh
tests/wt/                       test   sh tests/wt/run-tests.sh

# relay-merge.
bin/relay-merge                 test   sh tests/relay-merge/run-tests.sh
tests/relay-merge/              test   sh tests/relay-merge/run-tests.sh

# Relay skills: the guard reads skills/, templates/, README.md and CLAUDE.md.
skills/                         test   sh tests/orchestrating/run-tests.sh
templates/                      test   sh tests/orchestrating/run-tests.sh
README.md                       test   sh tests/orchestrating/run-tests.sh
CLAUDE.md                       test   sh tests/orchestrating/run-tests.sh
tests/orchestrating/            test   sh tests/orchestrating/run-tests.sh
```

- [ ] **Step 2: Which gates a change runs.** Each row prints the lines whose prefix starts the path, as `relay-merge`
  matches them.

| Run | Expected |
|---|---|
| `awk '$1 == "."' .hyper-relay/merge.conf` | nothing |
| `awk -v f=tests/wt/probe.txt 'NF >= 3 && $1 !~ /^#/ && index(f, $1) == 1' .hyper-relay/merge.conf` | one line, the `tests/wt/` one |
| `awk -v f=bin/relay-merge 'NF >= 3 && $1 !~ /^#/ && index(f, $1) == 1' .hyper-relay/merge.conf` | two lines: its `dash -n` (build) and its suite (test) |
| `awk -v f=skills/orchestrating/SKILL.md 'NF >= 3 && $1 !~ /^#/ && index(f, $1) == 1' .hyper-relay/merge.conf` | two lines: `claude plugin validate .` (build) and `sh tests/orchestrating/run-tests.sh` (test) |
| `awk -v f=docs/relay-merge.md 'NF >= 3 && $1 !~ /^#/ && index(f, $1) == 1' .hyper-relay/merge.conf` | nothing |

- [ ] **Step 3: Every command passes on this branch.** Run, from the checkout's top:

```sh
grep -v -E '^[[:space:]]*(#|$)' .hyper-relay/merge.conf | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); print }' | LC_ALL=C sort -u | while IFS= read -r cmd; do sh -c "$cmd" < /dev/null > /dev/null 2>&1; echo "$? $cmd"; done
```

Expected, exactly these 13 lines:

```text
0 bash skills/visual-companion/scripts/run-tests.sh
0 claude plugin validate .
0 dash -n bin/hyper-relay-agents
0 dash -n bin/relay-merge
0 dash -n bin/wt
0 sh skills/voice-to-specs/tests/setup-sh.test.sh
0 sh skills/voice-to-specs/tests/transcribe-sh.test.sh
0 sh tests/add-card-line/run-tests.sh
0 sh tests/hyper-relay-agents/guard-test.sh
0 sh tests/hyper-relay-agents/run-tests.sh
0 sh tests/orchestrating/run-tests.sh
0 sh tests/relay-merge/run-tests.sh
0 sh tests/wt/run-tests.sh
```

A line that does not start with `0 ` is a command that fails here: run it alone, and report its output. Do not change
`merge.conf` to make it pass.

- [ ] **Step 4: Commit.**

```bash
git add .hyper-relay/merge.conf
git commit -m "feat: hyper-relay's own merge gates, in .hyper-relay/merge.conf" -m "relay-merge reads it from main's last commit. Build gates: claude plugin validate . for the manifests and skills, dash -n for the three tools in bin/. Test gates: each suite of CLAUDE.md's Checks table, under the paths it reads. No '.' line, so a branch that touches one tool runs only its gates." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `docs/relay-merge.md`, the user reference (spec §1 Docs; P17)

**Files:**
- Create: `docs/relay-merge.md`

- [ ] **Step 1: Write the reference.** Create `docs/relay-merge.md` with exactly this content:

````markdown
# relay-merge: land branches on main, gated

`relay-merge` lands finished branches on `main`, one at a time. Each lands as a merge commit, and the checks you name
for the files it changed run on the merged result before the next branch starts. It stops at the first branch that
fails.

It ships with hyper-relay as `bin/relay-merge`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `relay-merge` by name. For your own shell (and OpenCode's), symlink it from a
clone into a directory on your `PATH`:

```sh
ln -sfn /path/to/hyper-relay/bin/relay-merge ~/.local/bin/relay-merge
```

## Requirements

- A POSIX shell: `relay-merge` is written for dash and runs as `#!/bin/sh`.
- git and `awk`, and whatever your gates run.
- Optionally `wt` ([docs/wt.md](wt.md)): when it is on `PATH`, a branch whose worktree has a `wt` stack up is refused.

## Usage

```sh
relay-merge feat/login fix/typo
```

Run it in the repo's main checkout, on `main`. It lands the branches in the order given and stops at the first one
that fails; the branches before it stay landed. It takes no options: its settings are environment variables (below).

### Each branch

1. **The checks,** which refuse before anything changes (exit 1):
   - it runs in the main checkout, not in a worktree; that checkout is on `main`, with no merge in progress;
   - `main` has no uncommitted changes to tracked files under the paths the gates watch, or anywhere when there is no
     `merge.conf` (untracked files do not count);
   - the branch exists, and is not `main`;
   - when the branch is checked out in a worktree, that worktree has no uncommitted or untracked files, and `wt ls`
     lists no stack for it.
2. **Already in `main`:** a branch whose commits are all in `main` is skipped. It still counts as landed, so the
   cleanup removes it.
3. **The merge:** `git merge --no-ff`, so every landing leaves a merge commit named for its branch: the message is
   `Merge branch '<branch>'`, then, when `RELAY_MERGE_TRAILERS` is set, a blank line and its lines. If the merge
   conflicts, `relay-merge` runs `git merge --abort`, so `main` is unchanged, and stops (exit 2): merge `main` into
   the branch, resolve the conflict there, and run `relay-merge` again. If git refuses to start the merge (a staged
   change on `main`, or an untracked file the branch would overwrite), `main` is unchanged too (exit 1).
4. **The gates,** on the merged result: each line of `.hyper-relay/merge.conf` whose prefix matches a file the branch
   changed (below). Their output goes to a log, and the terminal shows one line per gate. When one fails, everything
   stops (exit 3): the merge stays on `main`, not pushed and not undone, and `relay-merge` prints the log's last 20
   lines, the log's path and the commit `main` was on before the merge. Fix forward on a new branch, or undo the merge
   yourself.

### Once every branch is in

- **The push:** `PUSH=1` pushes `main` to its remote and `PUSH=0` does not. Otherwise `relay-merge` asks on the
  terminal, after dropping anything typed while the gates ran, so a stray Enter cannot answer for you. With no
  terminal (piped, or run by an agent) the answer is no. When `main` is level with its upstream, there is nothing to
  push and nothing is asked.
- **The cleanup:** unless `KEEP=1`, each landed branch's worktree goes with `git worktree remove`, then the branch with
  `git branch -d`: the forms git refuses for an unclean worktree or an unmerged branch, so the cleanup cannot lose
  work.

A failed push or cleanup prints a warning and does not change the exit code. After a failure, nothing is pushed or
cleaned up.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Every branch landed. |
| `1` | A check refused a branch; that branch did not change `main`. |
| `2` | A merge conflict; it was aborted, and `main` is unchanged for that branch. |
| `3` | A gate failed; the merge is on `main`, not pushed. |

Whatever the code, the branches before the one that stopped it stay landed, and `relay-merge` names them.

## Environment

| Variable | Effect |
|---|---|
| `PUSH` | `1` pushes `main` without asking; `0` never pushes. Unset, or any other value: asks on a terminal, and with no terminal does not push. |
| `KEEP` | `1` keeps the landed branches and their worktrees. |
| `SKIP_TESTS` | `1` skips the `test` gates; the `build` gates still run. |
| `RELAY_MERGE_TRAILERS` | Lines added to the end of every merge message, after a blank line, so git reads them as its trailers: for example `Co-Authored-By:` lines. |
| `XDG_STATE_HOME` | The logs go to `$XDG_STATE_HOME/relay-merge/`, or to `~/.local/state/relay-merge/` when it is unset. |

## `.hyper-relay/merge.conf`

Commit a `.hyper-relay/merge.conf` in the repo, with one gate per line:

```
<prefix> <kind> <command>
```

- **prefix:** a path from the repo's top, with no leading `/` or `./`. The gate runs when the branch added, changed,
  deleted or renamed a file whose path starts with it, as text: `core/` matches `core/a.c`, and `bin/tool` matches
  both `bin/tool` and `bin/tool-extra`. The prefix `.` matches any change.
- **kind:** `build` or `test`. `SKIP_TESTS=1` skips the `test` lines.
- **command:** the rest of the line, run with `sh -c` from the repo's top, with no terminal input. It passes when it
  exits 0.

A line whose first word starts with `#` is a comment, and blank lines are skipped. Any other kind, a line with no
command, or a prefix that starts with `/` or `./` stops `relay-merge` before anything changes, naming the line.

The gates run in the file's order, each command once per branch however many matching lines name it, so put the quick
checks first. Their output is appended to a log named for the repo, the time and the branch.

```
# prefix   kind   command
core/      build  make -C core
core/      test   make -C core test
ui/        test   npm --prefix ui test
.          test   sh tests/smoke.sh
```

**The file is read from `main`'s last commit** when `relay-merge` starts: not from the working tree, and not from a
branch being landed. A branch cannot change its own gates, and the commands are as trusted as `main` is. A change to
`merge.conf` gates the branches landed after it, in a later run.

**Without a `merge.conf`,** `relay-merge` lands with no gates and says so, and refuses an uncommitted change to any
tracked file on `main`.

## Safety

- **It never undoes a merge.** After a failed gate the merge stays, for you to fix forward or undo.
- **It never pushes unasked.** Without `PUSH=1` or a yes on a terminal, `main` stays local.
- **It never forces.** The cleanup uses only the forms git refuses for unclean worktrees and unmerged branches, and a
  refusal is only a warning.
- **The gates run the merged code.** The gate commands come from `main`, but they run the branch's code with your
  privileges: land only branches whose code you would run.
````

- [ ] **Step 2: The reference says what the tool does.** (`git grep --untracked` reads the new file before its
  commit.)

| Run | Expected |
|---|---|
| ``git grep --untracked -c -E '^\| `(PUSH\|KEEP\|SKIP_TESTS\|RELAY_MERGE_TRAILERS\|XDG_STATE_HOME)` \|' -- docs/relay-merge.md`` | `docs/relay-merge.md:5`: the five variables of Task 2 Step 4, one row each |
| ``git grep --untracked -c -E '^\| `[0-3]` \|' -- docs/relay-merge.md`` | `docs/relay-merge.md:4`: the Contract's four exit codes |
| `git grep --untracked -n -F '](wt.md)' -- docs/relay-merge.md`, then `test -f docs/wt.md && echo found` | one line, then `found` |
| `git grep --untracked -n -E 'https?://\|session_' -- docs/relay-merge.md bin/relay-merge .hyper-relay/merge.conf` | nothing: no host or session is named |

- [ ] **Step 3: Commit.**

```bash
git add docs/relay-merge.md
git commit -m "docs: relay-merge's user reference" -m "docs/relay-merge.md: what relay-merge does for each branch and after the last one, its exit codes and environment variables, the format of .hyper-relay/merge.conf and where it is read from, and what it never does. It also gives the symlink for a shell's PATH." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `CLAUDE.md` and the planner's facts, the release rule; the full gates (spec §1 Docs, §9; D2.11; P13, P14)

**Files:**
- Modify: `CLAUDE.md:19-23` (Layout), `:52-64` (How a change reaches the owner), `:75` (Checks)
- Modify: `.hyper-relay/agents.md:20-23` (`## planner/execution-notes`)

- [ ] **Step 1: `CLAUDE.md`'s Layout names the tool, its doc, its suite and the gates.** In `CLAUDE.md`, replace:

```text
- `bin/wt`: `wt`, a disposable Docker Compose stack for each git worktree (POSIX shell, run by dash). `docs/wt.md` is
  its user reference. Claude Code puts the plugin's `bin/` on the Bash tool's `PATH`, so skills call it by name.
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts. `tests/hyper-relay-agents/` tests the
  generator, its hook and the guard. `tests/wt/` tests `wt`, with a fake `docker` and `ss`.
```

with:

```text
- `bin/wt`: `wt`, a disposable Docker Compose stack for each git worktree (POSIX shell, run by dash). `docs/wt.md` is
  its user reference. Claude Code puts the plugin's `bin/` on the Bash tool's `PATH`, so skills call it by name.
- `bin/relay-merge`: `relay-merge`, which lands branches on `main` one at a time, each as a merge commit whose merged
  result must pass the repo's gates (POSIX shell, run by dash). `docs/relay-merge.md` is its user reference. This
  repo's gates are `.hyper-relay/merge.conf`, which maps its paths to the Checks table below.
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts. `tests/hyper-relay-agents/` tests the
  generator, its hook and the guard. `tests/wt/` tests `wt`, with a fake `docker` and `ss`. `tests/relay-merge/`
  tests `relay-merge`, on temporary git repos with a fake `wt`.
```

- [ ] **Step 2: The release rule replaces "0.1.0 until the initiative is finished" (D2.11, spec §9; P14).** In
  `CLAUDE.md`, replace:

```text
- **Claude Code** installs from GitHub (`alexvtejeda/hyper-relay`), never from a local path: a local-directory
  marketplace loads gitignored files too, and this checkout's `.mcp.json` would load as the plugin's own MCP server.
  `plugin.json` pins `version`, so `claude plugin update` and auto-update change nothing until the version does. The
  version stays 0.1.0 until the hyper-relay initiative is finished (owner, 2026-11-17). Meanwhile: merge, push
  `main`, and reinstall with `claude plugin install hyper-relay@hyper-relay`, which refreshes the installed copy from
  `main`'s HEAD on GitHub (seen 2026-11-17); a new session loads it. A release raises the version with
  `scripts/bump-version.sh <x.y.z>`, then merge, push `main`, and tag `v<x.y.z>`.
```

with:

```text
- **Claude Code** installs from GitHub (`alexvtejeda/hyper-relay`), never from a local path: a local-directory
  marketplace loads gitignored files too, and this checkout's `.mcp.json` would load as the plugin's own MCP server.
  `plugin.json` pins `version`, so `claude plugin update` and auto-update change nothing until the version does.
- **Every merge that changes what the plugin ships is released** (owner, 2026-11-18; this replaces the 2026-11-17
  rule "0.1.0 until the initiative is finished"). The first release is 0.2.0, once both of piece D.2's plans have
  merged; until then, a merge reaches Claude Code by pushing `main` and reinstalling with
  `claude plugin install hyper-relay@hyper-relay`, which refreshes the installed copy from `main`'s HEAD on GitHub
  (seen 2026-11-17). From 0.2.0 on, a merge that changes anything outside `docs/` and `tests/` raises the version:
  the patch number (0.2.1 next), unless the owner names another. A release, on `main` after the merge:
  `scripts/bump-version.sh <x.y.z>` (it sets `package.json` and `.claude-plugin/plugin.json`), a commit of just
  those two files, `chore: release v<x.y.z>`, the tag `v<x.y.z>`, then push `main` and the tag. A plan that ships
  such a change ends its acceptance task with these as `after merge` steps.
- **The owner updates** with `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in a running
  session (or a new session), instead of uninstalling and reinstalling.
```

Then replace:

```text
- **`wt`** in the owner's shell is `~/.local/bin/wt`, a symlink to this main checkout's `bin/wt`: a change reaches it
  as soon as it merges, and during a branch run the shell runs that branch's `wt`.
```

with:

```text
- **`wt`** in the owner's shell is `~/.local/bin/wt`, a symlink to this main checkout's `bin/wt`: a change reaches it
  as soon as it merges, and during a branch run the shell runs that branch's `wt`.
- **`relay-merge`** in the owner's shell is `~/.local/bin/relay-merge`, a symlink to this main checkout's
  `bin/relay-merge`, as `wt`'s is: a change reaches it as soon as it merges.
```

- [ ] **Step 3: The Checks row.** In `CLAUDE.md`, replace:

```text
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
```

with:

```text
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
```

- [ ] **Step 4: The planner's facts gain the release steps (spec §9).** In `.hyper-relay/agents.md`, replace:

```text
- Also the owner's or the orchestrator's: anything that touches `~/.claude/`, `~/.config/opencode/` or the home
  directory's own repo, and installing or uninstalling a plugin.
```

with:

```text
- Also the owner's or the orchestrator's: anything that touches `~/.claude/`, `~/.config/opencode/` or the home
  directory's own repo, and installing or uninstalling a plugin.
- **Releases** (`CLAUDE.md`, "How a change reaches the owner"): once `main`'s `.claude-plugin/plugin.json` is at
  0.2.0 or later, a plan that changes anything outside `docs/` and `tests/` ends its acceptance task with these
  `after merge` steps, last, on `main` in the main checkout. (1) `scripts/bump-version.sh <x.y.z>`, where `<x.y.z>`
  is `main`'s version then (`scripts/bump-version.sh --check`) with its patch number raised by one, unless the
  owner names another; PASS: `--check` shows both files at `<x.y.z>`. (2) A commit of just `package.json` and
  `.claude-plugin/plugin.json`, `chore: release v<x.y.z>`, with the attribution lines; `git tag v<x.y.z>`;
  `git push origin main v<x.y.z>`. (3) The owner's `claude plugin update hyper-relay@hyper-relay`, then
  `/reload-plugins` in a running session (or a new session); PASS: the cache holds
  `~/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/`.
```

- [ ] **Step 5: Check the edits.**

| Run | Expected |
|---|---|
| `git grep -n -F 'stays 0.1.0' -- CLAUDE.md` | nothing |
| `git grep -n -F '0.2.1 next' -- CLAUDE.md` | one line, in "How a change reaches the owner" |
| `git grep -n -F '/reload-plugins' -- CLAUDE.md .hyper-relay/agents.md` | one line in each |
| `git grep -n -F -e 'bin/relay-merge' -e 'docs/relay-merge.md' -e 'tests/relay-merge/' -- CLAUDE.md` | the Layout names all three, and the `relay-merge` bullet names `bin/relay-merge` |
| `git grep -n -F 'sh tests/relay-merge/run-tests.sh' -- CLAUDE.md` | one line, the Checks row expecting `0 failed` |
| `git grep -n -F 'bump-version.sh' -- .hyper-relay/agents.md` | lines in the `**Releases**` bullet only, under `## planner/execution-notes` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` (it generates agents from this repo's facts file) |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` (it reads `CLAUDE.md`) |

- [ ] **Step 6: Commit.**

```bash
git add CLAUDE.md .hyper-relay/agents.md
git commit -m "docs: CLAUDE.md names relay-merge and the release rule; the planner's facts gain the release steps" -m "CLAUDE.md's Layout gains bin/relay-merge, docs/relay-merge.md, .hyper-relay/merge.conf and tests/relay-merge/, and its Checks table the relay-merge suite. Under 'How a change reaches the owner', the 2026-11-17 rule (0.1.0 until the initiative is finished) gives way to the owner's 2026-11-18 one: the first release is 0.2.0, after piece D.2's two plans; then every merge that changes anything outside docs/ and tests/ raises the version, the patch unless the owner names another, and the owner updates with claude plugin update and /reload-plugins. The relay-merge symlink sits beside wt's. .hyper-relay/agents.md gives the planner the release's after-merge steps." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 7: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/relay-merge/run-tests.sh \| tail -n 1` | `107 passed, 0 failed` |
| `dash -n bin/relay-merge`, then `dash -n tests/relay-merge/run-tests.sh` | silent |
| `git ls-files -s bin/relay-merge tests/relay-merge/run-tests.sh` | the first line starts `100755`, the second `100644` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `24 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/agents.md`, `.hyper-relay/merge.conf`, `CLAUDE.md`, `bin/relay-merge`, `docs/relay-merge.md`, `tests/relay-merge/run-tests.sh` |
| `git grep -n -E 'https?://\|session_' -- bin/relay-merge docs/relay-merge.md .hyper-relay/merge.conf` | nothing |
| `git log --format=%B main..HEAD \| grep -v '^Claude-Session: ' \| grep -c -E 'https?://'` | `0`: no message names a host, beside its session trailer |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

The other suites ran once in Task 3 Step 3; upstream's live suites are not run (report this): they start real
`claude -p` sessions. Then report, copy Task 6's checklist (Steps 1–15, each with its marker and its PASS) into your
report, and stop: Task 6 is not yours.

### Task 6: Acceptance (spec §10, §11; D2.10, D2.11; P12, P14, P15). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-d2-relay-merge`) its dispatch names, from the checkout's top. It runs Steps 1–8 only, and writes only
  in its evidence folder (`<evidence folder>` below).
- **`owner`**: the owner, at the click-through (Steps 9–10).
- **`after merge`**: the orchestrator with the owner, once the owner has merged the branch into `main` and the main
  checkout `/home/noob_master/hyper-relay` is on `main` (Steps 11–15), one command per Bash call. Plan 2's executor
  starts only after Step 11 passes (D2.10).

**This plan's run follows the installed relay** (today's `orchestrating`): it merges with
`finishing-a-development-branch` (P18), and the version stays 0.1.0.

- [ ] **Step 1 (`reviewer`): The suite, the syntax and the modes.**

| Run | PASS |
|---|---|
| `sh tests/relay-merge/run-tests.sh \| tail -n 1` | `107 passed, 0 failed` |
| `dash -n bin/relay-merge`, then `dash -n tests/relay-merge/run-tests.sh` | silent, exit 0 |
| `git ls-files -s bin/relay-merge tests/relay-merge/run-tests.sh` | `100755` for the tool, `100644` for the suite |
| `git grep -n -E -e '--force\|reset\|branch -D\|push -f\|--hard' -- bin/relay-merge` | nothing |

- [ ] **Step 2 (`reviewer`): The tool against spec §1 and the Contract.** Read `bin/relay-merge` in full, spec §1 and
  this plan's Contract and P1–P11. PASS, each point quoted with its line:
  - it is `#!/bin/sh` with `set -eu`, and uses no `[[`, `local`, arrays or `function`;
  - before any `git merge`, it refuses with exit 1: options, no branch, not the main checkout, not on `main`, a merge in
    progress, a bad `merge.conf` line; then per branch: `main` itself, uncommitted changes under the watched paths
    (all paths without a config), a missing branch, a worktree that is missing, unclean or has a `wt` stack up;
  - a branch already in `main` is skipped and added to the landed list;
  - the merge is `git merge --no-ff --no-edit -m` with `Merge branch '<branch>'` and, when set, a blank line and
    `RELAY_MERGE_TRAILERS`; a stop with `MERGE_HEAD` runs `git merge --abort` and exits 2; any other refusal exits 1;
  - the config is read once, from `HEAD:.hyper-relay/merge.conf` after the on-`main` check; gates match by prefix
    (`.` any) against `git diff HEAD...<branch>`, in the file's order, once per command, `test` lines skipped under
    `SKIP_TESTS=1`, with output to a log under `${XDG_STATE_HOME:-$HOME/.local/state}/relay-merge/`; a failure prints
    the log's last 20 lines and exits 3 with nothing undone;
  - only after the loop: the push (`PUSH`, else a terminal's answer, else no) and, unless `KEEP=1`,
    `git worktree remove` and `git branch -d` with no force; a failed push or cleanup only warns;
  - the exit codes are the Contract's. Nothing contradicts spec §1; list any line that does as a FAIL.

- [ ] **Step 3 (`reviewer`): A scratch clone of this repo, with its `merge.conf` on `main`.** Run, from the
  checkout's top:

```bash
git clone -q -b hyper-relay-d2-relay-merge "$(git rev-parse --path-format=absolute --git-common-dir)" <evidence folder>/clone
git -C <evidence folder>/clone switch -q -C main
git clone -q --bare <evidence folder>/clone <evidence folder>/origin.git
git -C <evidence folder>/clone remote set-url origin <evidence folder>/origin.git
git -C <evidence folder>/clone fetch -q origin
git -C <evidence folder>/clone branch -q --set-upstream-to=origin/main main
```

| Run | PASS |
|---|---|
| `git -C <evidence folder>/clone rev-parse main`, then `git rev-parse HEAD` | the same hash: the clone's `main` is this branch's tip (note it: `<PRE>`) |
| `git -C <evidence folder>/clone show main:.hyper-relay/merge.conf \| head -n 1` | `# hyper-relay's merge gates, for bin/relay-merge (docs/relay-merge.md). relay-merge reads` |
| `git -C <evidence folder>/clone status --short` | nothing |

- [ ] **Step 4 (`reviewer`): A branch touching `tests/wt/` lands with exit 0, only the `wt` suite's gate runs, and
  the merge commit carries the trailers (spec §10).**

```bash
git -C <evidence folder>/clone switch -q -c probe/wt main
printf 'probe\n' > <evidence folder>/clone/tests/wt/probe.txt
git -C <evidence folder>/clone add tests/wt/probe.txt
git -C <evidence folder>/clone commit -q -m 'probe: a file under tests/wt'
git -C <evidence folder>/clone switch -q main
cd <evidence folder>/clone && PUSH=0 XDG_STATE_HOME=<evidence folder>/state RELAY_MERGE_TRAILERS='Co-Authored-By: Probe <probe@example.invalid>' sh bin/relay-merge probe/wt; echo "exit $?"
```

| Check | PASS |
|---|---|
| the run's last line | `exit 0` |
| the run's lines ending in ` ... ok` | exactly one: `relay-merge:   test   sh tests/wt/run-tests.sh ... ok` |
| `git -C <evidence folder>/clone log -1 --format=%B` | `Merge branch 'probe/wt'`, a blank line, `Co-Authored-By: Probe <probe@example.invalid>` |
| `git -C <evidence folder>/clone log -1 --format=%P` | two hashes, the first `<PRE>` |
| `git -C <evidence folder>/origin.git rev-parse main` | `<PRE>`: not pushed (`PUSH=0`) |
| `git -C <evidence folder>/clone show-ref --verify --quiet refs/heads/probe/wt; echo $?` | `1`: cleaned up |

- [ ] **Step 5 (`reviewer`): A gate broken on purpose gives exit 3, with the merge left on `main`, unpushed (spec
  §10).**

```bash
git -C <evidence folder>/clone switch -q -c probe/broken main
printf 'exit 1\n' >> <evidence folder>/clone/tests/wt/run-tests.sh
git -C <evidence folder>/clone commit -q -a -m 'probe: the wt suite fails'
git -C <evidence folder>/clone switch -q main
git -C <evidence folder>/clone rev-parse --short main
cd <evidence folder>/clone && PUSH=1 XDG_STATE_HOME=<evidence folder>/state sh bin/relay-merge probe/broken; echo "exit $?"
```

Note the short hash the fifth command prints: `<BEFORE>`.

| Check | PASS |
|---|---|
| the run's last line | `exit 3` |
| the run's output | `relay-merge:   test   sh tests/wt/run-tests.sh ... FAILED`, then at most 20 lines indented by four spaces whose last is the `wt` suite's summary (`… passed, 0 failed`), then a line saying the merge is on main, NOT pushed, with `main was <BEFORE> before it` and the log's path |
| `git -C <evidence folder>/clone log -1 --format=%s` | `Merge branch 'probe/broken'` |
| `git -C <evidence folder>/origin.git rev-parse main` | `<PRE>`, as in Step 4: not pushed, although `PUSH=1` |
| `git -C <evidence folder>/clone status --short` | nothing |
| `git -C <evidence folder>/clone show-ref --verify --quiet refs/heads/probe/broken; echo $?` | `0`: kept |
| `ls <evidence folder>/state/relay-merge` | two logs: `clone-<stamp>-probe-wt.log` and `clone-<stamp>-probe-broken.log` |

- [ ] **Step 6 (`reviewer`): This repo's `merge.conf` maps its paths to its suites (P12).** Read
  `.hyper-relay/merge.conf` beside `CLAUDE.md`'s Checks table.

| Run | PASS |
|---|---|
| `awk '$1 == "."' .hyper-relay/merge.conf` | nothing |
| Task 3 Step 3's loop | its 13 lines, each starting `0 ` |
| Reading both files | every suite row of the Checks table (add-card-line, voice-to-specs ×2, role agents ×2, visual-companion, wt, relay-merge, relay skills) is a `test` gate under the paths that suite reads; `claude plugin validate .` is a `build` gate under `.claude-plugin/`, `skills/` and `hooks/`; each tool in `bin/` has a `dash -n` `build` gate |

- [ ] **Step 7 (`reviewer`): `docs/relay-merge.md` says what the tool does (spec §1 Docs; P17).**

| Run | PASS |
|---|---|
| `git grep -h -o -E '\$\{[A-Z_]+:-' -- bin/relay-merge \| sort -u` | five: `${KEEP:-`, `${PUSH:-`, `${RELAY_MERGE_TRAILERS:-`, `${SKIP_TESTS:-`, `${XDG_STATE_HOME:-` |
| ``git grep -c -E '^\| `(PUSH\|KEEP\|SKIP_TESTS\|RELAY_MERGE_TRAILERS\|XDG_STATE_HOME)` \|' -- docs/relay-merge.md`` | `docs/relay-merge.md:5` |
| ``git grep -c -E '^\| `[0-3]` \|' -- docs/relay-merge.md`` | `docs/relay-merge.md:4`, each row the Contract's meaning |
| `git grep -n -F '](wt.md)' -- docs/relay-merge.md`, then `test -f docs/wt.md && echo found` | one line, then `found` |
| Read `docs/relay-merge.md` in full | each claim matches `bin/relay-merge` as Step 2 read it; list any that does not as a FAIL |

- [ ] **Step 8 (`reviewer`): `CLAUDE.md`, the planner's facts, the manifests, and only the planned files (spec §1
  Docs, §9).**

| Run | PASS |
|---|---|
| `git diff main...HEAD -- CLAUDE.md` | the Layout gains the `bin/relay-merge` bullet and the `tests/relay-merge/` sentence; "How a change reaches the owner" loses "stays 0.1.0 until the hyper-relay initiative is finished" and gains the release bullet (0.2.0 first, then the patch, 0.2.1 next, unless the owner names another; `scripts/bump-version.sh`, `chore: release v<x.y.z>`, the tag, the push), the owner's `claude plugin update` and `/reload-plugins`, and the `relay-merge` symlink bullet; the Checks table gains the `relay-merge` row; nothing else |
| `git diff main...HEAD -- .hyper-relay/agents.md` | one added bullet, `**Releases**`, under `## planner/execution-notes`, with spec §9's steps |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1`, then `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1`, then `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `153 passed, 0 failed`, `51 passed, 0 failed`, `24 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only in the main checkout, `PRIVACY_URL_MISSING` |
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/agents.md`, `.hyper-relay/merge.conf`, `CLAUDE.md`, `bin/relay-merge`, `docs/relay-merge.md`, `tests/relay-merge/run-tests.sh` |
| `git grep -n -E 'https?://\|session_' -- bin/relay-merge docs/relay-merge.md .hyper-relay/merge.conf`, then `git log --format=%B main..HEAD \| grep -v '^Claude-Session: ' \| grep -c -E 'https?://'` | nothing, then `0` |
| Read the six changed files and the branch's commit messages (`git log --format=%B main..HEAD`) | none names another project, or its folders, hosts or sessions (this repo is public) |

- [ ] **Step 9 (`owner`): Read what users and planners will read.** `git -C /home/noob_master/hyper-relay show
  hyper-relay-d2-relay-merge:docs/relay-merge.md`, and the "How a change reaches the owner" section of
  `git -C /home/noob_master/hyper-relay show hyper-relay-d2-relay-merge:CLAUDE.md`. PASS: the owner agrees that they
  describe `relay-merge` as it works and the release rule as decided, and answers P14 (keep "anything outside `docs/`
  and `tests/`" literal, or narrow it). A change goes to the executor as a finding.

- [ ] **Step 10 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-d2-relay-merge` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging.

- [ ] **Step 11 (`after merge`): The suites pass on the merged `main` (D2.10, spec §11).** Plan 2's executor starts
  only after this step passes.

| Run | PASS |
|---|---|
| `sh /home/noob_master/hyper-relay/tests/relay-merge/run-tests.sh` (last line) | `107 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh` (last line) | `153 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/guard-test.sh` (last line) | `51 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `24 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay show main:.claude-plugin/plugin.json` | `"version": "0.1.0"`: Plan 1 does not release |
| `git -C /home/noob_master/hyper-relay status --short` | nothing |

- [ ] **Step 12 (`after merge`; the owner runs the `ln`, which is the owner's shell setup): The symlink (spec §10).**
  First, `test -e /home/noob_master/.local/bin/relay-merge || test -L /home/noob_master/.local/bin/relay-merge; echo $?`
  must print `1` (nothing there yet); if it prints `0`, stop and ask the owner. Then the owner runs:

```bash
ln -sfn /home/noob_master/hyper-relay/bin/relay-merge /home/noob_master/.local/bin/relay-merge
```

| Run | PASS |
|---|---|
| `readlink /home/noob_master/.local/bin/relay-merge` | `/home/noob_master/hyper-relay/bin/relay-merge` |
| `command -v relay-merge`, in the owner's shell | `/home/noob_master/.local/bin/relay-merge` |
| `relay-merge; echo "exit $?"`, in the owner's shell | the `usage: relay-merge <branch>...` line, then `exit 1` |
| `RELAY_MERGE_BIN=/home/noob_master/.local/bin/relay-merge sh /home/noob_master/hyper-relay/tests/relay-merge/run-tests.sh` (last line) | `107 passed, 0 failed` |

- [ ] **Step 13 (`after merge`): This repo's agents, regenerated for the planner's new facts (P15).**

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents` | `written .claude/agents/relay-planner.md`; the other agents and the guard unchanged |
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -F 'bump-version.sh' /home/noob_master/hyper-relay/.claude/agents/relay-planner.md` | at least `1` |

A running session keeps the agent definitions it loaded: the next planner dispatched from a new session gets them.

- [ ] **Step 14 (`after merge`, only when the owner says so at stop 4): Push `main`.** Otherwise 0.2.0's release, in
  Plan 2's after-merge steps, pushes it.

```bash
git -C /home/noob_master/hyper-relay push origin main
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay rev-parse origin/main`, then `git -C /home/noob_master/hyper-relay rev-parse main` | the same hash |

- [ ] **Step 15 (`after merge`): Record.** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 6)

- **Before the merge:** acceptance reviewer <verdict line>; fix rounds <n, what each changed>; code review: Critical
  <fixed / dropped, why>, proposed cards <kept / dropped>; token counts: executor <n>, acceptance reviewer <n>, code
  reviewer <n>.
- **Owner steps:** Step 9 <agreed / what changed; P14: kept or narrowed>; Step 10 <merge-tree exit>. Merged in
  <hash>.
- **After merge:** suites on `main` <counts>; symlink <readlink, command -v>; agents regenerated <yes/no>; `main`
  pushed <yes/no>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 6 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece D.2 plan 1 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md#6
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md
```

Then Plan 2's handoff, from the new `main` (spec §11).
