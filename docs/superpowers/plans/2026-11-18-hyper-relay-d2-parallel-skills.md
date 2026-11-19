# hyper-relay D.2, Plan 2: the parallel skills Implementation Plan

**Card:** Several plans at once: conflicts, stacking, the preview stack (`68fab05e-4083-41bf-820f-8c201a951c50`)
**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-d2-several-plans-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–8 are
> the executor's. Task 9 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `skill-test`
> steps the orchestrator's (by hand, as in D.3), its `owner` and `after merge` steps the owner's and the
> orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach the relay skills to run several plans at once (worktrees, a conflict check, stacking, one landing
order), to land every branch with Plan 1's `relay-merge` by its exit codes, to run skill tests as a standing leg, to
never hold a leg for Quartz setup, and to let an executor merge `main` into its own branch for a catch-up or conflict
round; then release 0.2.0.

**Architecture:** A new `skills/orchestrating/parallel.md` (§1 what runs at once, §2 the conflict check, §3 stacking,
§4 the landing order) is read only when more than one plan is in flight; the leg files point at it where a second
plan changes their step. `reviewing.md` §4 replaces `finishing-a-development-branch` with `relay-merge` and its
exit-code table, and its §3 gains the skill-test leg. `executing-plans` and the executor template allow one merge:
`main` into the executor's own branch. The guard test, changed first, pins the new folder and bans
`finishing-a-development-branch` from the orchestrating files.

**Tech Stack:** Markdown skills; POSIX `sh` run by dash, with GNU `grep`, `sed` and `cp` (the guard); git (worktrees,
`git archive`, merges); Plan 1's `relay-merge` (described here, never run by the executor); Claude Code 2.1.x and
OpenCode.

**How this was checked:** written against `main` at `7dfd91f` by reading only; nothing was built, run, installed or
generated. Read in this repo: `CLAUDE.md` (in full); the D.2 spec (in full); D.3's plan (in full: the newest plan and
this one's model, with its last-task record); `skills/orchestrating/SKILL.md`, `planning.md`, `dispatching.md`,
`reviewing.md`, `quartz.md`; `skills/executing-plans/SKILL.md`; `skills/brainstorming/SKILL.md`;
`skills/writing-plans/SKILL.md` and `plan-document-reviewer-prompt.md`; `templates/agents/executor.md` and
`planner.md`; `tests/orchestrating/run-tests.sh`; `README.md`; `.hyper-relay/agents.md`; `scripts/bump-version.sh`
(all in full); `templates/agents/reviewer-commands.md` (20–49); `tests/hyper-relay-agents/run-tests.sh` (47–59,
195–234, 340–409); `bin/hyper-relay-agents` (382–404, 425–504); `docs/wt.md` (39–108). With `git show main:`:
`.gitignore`, `.version-bump.json`, `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
Read-only git: `git ls-files` of the plans, the touched skills, `templates/`, `tests/orchestrating/`,
`tests/hyper-relay-agents/`, `.claude-plugin/`, `bin/`, `scripts/`, `.hyper-relay/` and every `skills/*/SKILL.md`
(17); `git log --oneline -25`; `git for-each-ref refs/tags` and `git cat-file -p v0.1.0` (an annotated tag,
"hyper-relay 0.1.0: the fork's home"); `git grep` for the step kinds (`after merge`), for
`finishing-a-development-branch`, for the role-agent suite's executor assertions (none on the template's prose), and
for other project names in the files this plan touches (none). Not read: Plan 1's plan, written beside this one (this
plan relies on Plan 1 only through the Contract below); any `.mcp.json`, `.env` or `.envrc`.

**External facts (re-verified 2026-11-18):**
- **Claude Code: the plugin cache** ([code.claude.com/docs/en/plugins/loading](https://code.claude.com/docs/en/plugins/loading),
  fetched 2026-11-18). "`cache/<marketplace>/<plugin>/<version>/` | One directory per installed version of a
  marketplace plugin"; "Changes to settings or to disk don't reach this layer until you run `/reload-plugins` or start
  a new session. That is why `claude plugin update` ends with `Restart to apply changes.`"; "a manifest that pins
  `"version": "1.0.0"` keeps every user on the cached copy until its author changes the string"; an old version
  directory gets an `.orphaned_at` marker and is removed 14 days later, "so a session that already loaded the old
  version keeps running". **As spec §9 and §10** (the 0.2.0 folder; a reload or a new session).
- **Claude Code: `claude plugin update` and `/reload-plugins`**
  ([code.claude.com/docs/en/plugins/cli-reference](https://code.claude.com/docs/en/plugins/cli-reference), fetched
  2026-11-18). "Update a plugin to the latest version its marketplace offers. The new version loads in your next
  session, or after you run `/reload-plugins` in a running one."; with nothing newer it prints
  "`formatter is already at the latest version (1.0.0).`". `/reload-plugins`: "Apply pending plugin changes to the
  running session without restarting it", printing `Reloaded: N plugins · N skills · N agents · …`. **A difference,
  with no design change:** the page does not say whether `claude plugin update` refreshes the marketplace clone first
  (`claude plugin marketplace update [name]` does that); Task 9 Step 22 handles an "already at the latest version
  (0.1.0)" answer (P22).
- **Claude Code: a plugin's `bin/`** ([code.claude.com/docs/en/plugins-reference](https://code.claude.com/docs/en/plugins-reference),
  fetched 2026-11-18): "Files here are on the Bash tool's `PATH` while the plugin is enabled, so Claude runs them as
  bare commands"; and `${CLAUDE_PLUGIN_ROOT}` and the like "aren't present in the environment of commands Claude runs
  through the Bash tool". **As the Contract's "On `PATH`"**: skills call `relay-merge` by name.
- **git diff, three dots** ([git-scm.com/docs/git-diff](https://git-scm.com/docs/git-diff), fetched 2026-11-18):
  "`git diff A...B` is equivalent to `git diff $(git merge-base A B) B`"; `--quiet` "Implies `--exit-code`", which
  "exits with 1 if there were differences and 0 means no differences". Used by P3.
- **git merge `-m`** ([git-scm.com/docs/git-merge](https://git-scm.com/docs/git-merge), fetched 2026-11-18): "Set the
  commit message to be used for the merge commit (in case one is created)"; after a conflict, "Use `git commit` or
  `git merge --continue` to seal the deal". The page does not say whether the `-m` message survives a conflict, so
  `executing-plans` commits a resolved merge with an explicit `-m` (P15).

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
- **Plan 1 has landed first (spec D2.10).** This plan runs only after Plan 1
  (`docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md`) has merged and its suites pass on `main`. Before
  Task 1, `test -f bin/relay-merge && test -f docs/relay-merge.md && test -f .hyper-relay/merge.conf && echo plan1`
  must print `plan1`; if not, stop and report. Plan 1's files are not yours: never edit `CLAUDE.md`,
  `.hyper-relay/agents.md`, `bin/relay-merge`, `tests/relay-merge/`, `docs/relay-merge.md` or
  `.hyper-relay/merge.conf`. This plan relies on Plan 1 only through the Contract above.
- **The skill you follow is not the one you write.** Your preloaded `executing-plans` and this run's orchestrator are
  the installed plugin's copies (0.1.0). This plan rewrites the repo's relay skills, your own `executing-plans`
  included; follow your agent instructions and this plan, not the new text.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#<N>` followed, inside the same
  quoted paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and
  `Claude-Session:` with the URL from your dispatch prompt). The commands below write them as
  `<the line your instructions give>` and `<the URL your dispatch prompt gives>`: put the real lines there. Never tick
  the plan. Report every `quartz:` line a commit prints, verbatim.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly. If X is not found, read the
  range again; if the text moved or differs slightly, adapt as little as possible and record it as a deviation; if it
  is gone, stop and report. Text in code blocks is exact, down to its line breaks and spaces: transcribe it.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|` (Markdown's escape for a table): run
  `sh tests/orchestrating/run-tests.sh | tail -n 1`, and `grep -c -F -e '| 0 |' …`.
- **Described here, never run:** `relay-merge` (it merges into `main`), `wt`, `scripts/bump-version.sh`, and any
  `quartz` command, `git config hyper-relay.quartz` or `git config --global …`. Never read or print `.env`, `.envrc` or
  `.mcp.json`: they hold this checkout's Quartz wiring and token. Your commits run Quartz's git hooks on their own,
  which is fine.
- **Never** start a live `claude -p` / `opencode run` session, install, update or uninstall a plugin, push, tag, or
  create anything on GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites
  (`tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`): they start `claude -p`.
- **Outside your branch is not yours.** Never touch `main`, `~/.claude/`, `~/.config/opencode/`, `/tmp/hr-d2-*`, any
  other project's repo or the home directory's own repo. Task 9's `skill-test`, `owner` and `after merge` steps do
  what is needed there, and they are not yours.
- **No machine paths in skills** (`CLAUDE.md`, Rules). The guard fails on `/home/`, `~/`, `/Users/` or `/tmp/` in
  `skills/orchestrating/`; keep the other skills' new text free of them too.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's scratch tracker: never stage,
  edit, move or delete either. A "the tree is clean" check ignores them.
- **This repo is public.** Nothing you write into the repo or a commit message names another project or quotes its
  files.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs the guard (`sh tests/orchestrating/run-tests.sh | tail -n 1`, or piped through
  `grep`) and its own `grep` checks only. `grep` reads the working tree, so a new file needs no `git add` first. The
  full gates run once, in Task 8: the suites this plan touches (the Checks table in `CLAUDE.md`: the guard and the
  two role-agent suites), `dash -n` of the one script, and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 9. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`skill-test`** (the orchestrator, after acceptance, beside the code review), **`owner`** (at the click-through)
  or **`after merge`** (the owner and the orchestrator), with its command or action and the result that counts as
  PASS. After Task 8, report (gate results with counts, every deviation, any `quartz:` line, the suites not run and
  why), copy Task 9's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §3: the conflict check runs "before each dispatch that joins another plan in flight"; a numbered collision goes back to the planner "before dispatch"; "both kinds of overlap appear in the handoff question" | It runs before the handoff question (a new check 9 in `planning.md` §2), and again just before a waiting plan is dispatched. A numbered collision is a failed hand-back check: the plan is renumbered before stop 3, and the handoff names the collision and the renumbering in one line. |
| P2 | §2: "in flight" is "a branch or worktree whose executor work has not merged" | `parallel.md` defines it as a branch named after a plan (`dispatching.md` §3) that `git branch --no-merged main` lists, run as a branch run or in a worktree. |
| P3 | §5: the catch-up round runs "if `main` has commits its branch lacks" | Read as changes: `git diff --quiet <S>...main` fails. The base's own `--no-ff` merge commit always is a commit the stacked branch lacks, but when nothing else landed its tree equals the base's, so it alone triggers no round. |
| P4 | §5: "a `**Builds on:**` line whose base has already merged" | The base has merged when `git log -1 --format=%h --grep='Plan-Task: <base plan path>' main` prints a commit: `relay-merge` deletes the base's branch, so the branch's absence proves nothing. |
| P5 | §3: numbered names "start with the same digits" | As the spec, with one exclusion: a date prefix (`2026-11-18-…`) is not a sequence number. A `sed` line gives each created file's folder and leading digits. |
| P6 | §3: a plan's paths come from its `- Create:`, `- Modify:` and `- Test:` lines, "without any `:lines` part" | `parallel.md` §2 gives the pipeline: every backticked token on those lines, a token starting with `:` dropped (`` `:63-81` ``), a trailing `:<digits>` cut. |
| P7 | §6, exit 3: the owner decides "undo the unpushed merge, or fix forward on a new branch" | `reviewing.md` §4 gives the undo: check that `main`'s last commit is `Merge branch '<branch>'` and unpushed (`git branch -r --contains main` prints nothing), then `git reset --keep HEAD^1` in the main checkout on `main`; the failure then goes to the branch's executor as a fix round. Fix forward is "on a new branch, as the owner says". |
| P8 | §6, exit 2: the conflict round goes to "the branch's executor" | After a branch run the orchestrator has switched the main checkout to `main`, and an executor never switches branches, so the orchestrator runs `git switch <branch>` first (also before an exit-3 fix round). |
| P9 | §6, exit 1: the orchestrator fixes "the cause when it is its own (a `wt` stack still up)" | Also when the main checkout is not on `main`; then it runs `relay-merge` again. |
| P10 | Contract, "On `PATH`": a symlink in the owner's shell | The skills name no machine path (the guard refuses `~/` in `skills/orchestrating/`), so `reviewing.md` says "Claude Code puts it on `PATH`; elsewhere the owner links it", and when `command -v relay-merge` finds nothing, it tells the owner and stops. |
| P11 | §7, §8: `reviewing.md` gains "the skill-test leg" | It goes inside `reviewing.md` §3 ("The skill tests"), because a new section would renumber §4 and §5, which every leg file references. Scratch copies come from `git archive <ref> <skills> \| tar -x`, where `<skills>` is the repo's skills folder. The code-review status note gains "; skill tests G/S GREEN" and is posted once both legs are done, so a resumed orchestrator at "code review done" has the skill-test verdicts. |
| P12 | §8: "a GREEN that fails is a fix round" | After the fix, that GREEN reruns on a fresh copy of the branch's skills. |
| P13 | §3: an override is "recorded as a deviation" | Stop 4's report gains a line for the deviations recorded on the way; both plans' stop 4 name the override. |
| P14 | §7 and D2.8: the leg's agent is dispatched first; setup follows | At `brainstorming`'s step 1, which dispatches no agent, the setup message comes before brainstorming's first question (D.3's probe (b) behaviour). Since the message no longer waits, "Neither" also covers a reply that does not answer it. |
| P15 | §7: the executor "merges `main` (or its base) into its own branch and reruns its gates" | `executing-plans` gives the commands: `git merge -m "Merge branch 'main' into <branch>"` with the attribution lines and no `Plan-Task:` trailer; a resolved conflict is committed with the same explicit `-m` (git's docs do not say `-m` survives a conflict); when both sides cannot hold, `git merge --abort` and stop. "Or its base" is "or the branch the prompt names". Its Integration bullet now says the orchestrator lands the branch with `relay-merge`. |
| P16 | §7: the executor template's ban | The front matter's description says "never pushes, and never merges its branch into anything: a catch-up or conflict round merges main into its own branch"; the body names the rounds among what the skill gives. |
| P17 | §7: `writing-plans/SKILL.md` adds `skill-test` steps | **Also** `skills/writing-plans/plan-document-reviewer-prompt.md` (not in the spec's file list), one table cell: its acceptance-task check lists `reviewer`, `owner` or `after merge`, so a plan review would call every `skill-test` step a blocking issue. And `planning.md` §2's check 4 gains `skill-test`. The owner may drop the prompt's change (Task 7 Step 4). |
| P18 | §7 lists the files that change | Not changed: `templates/agents/planner.md` and the two reviewer templates, which also name `reviewer`, `owner` and `after merge`. A planner preloads `writing-plans`, which now adds `skill-test`; a reviewer runs only the step numbers its dispatch names. |
| P19 | §7: a spec "lists its plans in order, each with its subject and the plan it builds on" | `brainstorming` puts them under `## The plans`, each with its subject, the suffix of its plan's file name (`-api`, `-web`; `planning.md` §1 reads it) and its base, if any. |
| P20 | §7: README's changes | The status line says 0.2.0 already, since the release commit holds only the two manifests (§9); the roadmap's B, C, D1, D2 and E rows say `0.2.0`; D2's row drops "one preview stack" and says it is a card of its own. `bump-version.sh`'s audit then lists `README.md` among the files that contain `0.2.0`: expected. |
| P21 | §9: "tag `v0.2.0`" | Annotated, like `v0.1.0`: `git tag -a v0.2.0 -m "hyper-relay 0.2.0: several plans at once"`. |
| P22 | §10: the owner's `claude plugin update hyper-relay@hyper-relay` | If it answers "already at the latest version (0.1.0)", the marketplace clone was not refreshed: `claude plugin marketplace update hyper-relay`, then the update again, and the record says so (README's update line would then need a fix). |
| P23 | §10: probes (a) and (b) on toy repos | (a)'s toy keeps each script's checks in `tests/<script>.sh`, sourced by an unchanging `test.sh`, so plans 1 and 2 share no file. (b)'s first plan is in flight by hand (a worktree with one task commit) and its second plan is pre-written, so the probe spends no planner or executor. If (b)'s session first asks whether the first plan's executor is still running, the owner says yes. |
| P24 | §11: Plan 2's own merge | Under the installed 0.1.0 skills, which merge with `finishing-a-development-branch`; `relay-merge` is on `main` by then, and the owner may choose `PUSH=0 relay-merge hyper-relay-d2-parallel-skills` instead (Task 9 Step 19). |
| P25 | §10: "a reloaded session's orchestrating skill reads from the `0.2.0` folder" | Checked in the orchestrator's own session: after the owner's `/reload-plugins`, the Skill tool's "Base directory for this skill:" line for `hyper-relay:orchestrating` ends `hyper-relay/0.2.0/skills/orchestrating`. |
| P26 | §7: `SKILL.md`'s state table gains the stacked row | It sits before the "all its executor tasks committed" row, which it overrides. `reviewing.md` §2 also says to cut a stacked plan when its base's fix loop ends, the moment "passes acceptance" names. |
| P27 | §7: `dispatching.md` §1, "Branch is offered only for a plan that will run alone" | Its "While a branch run is active, Branch is not offered" warning goes: that case is no longer a plan that runs alone. `parallel.md` §1 holds the handoff question for several plans. |
| P28 | §10's S1–S9 | Their situations use made-up repos (`/work/toy`, `/work/shop`) and plans, so a fresh agent needs nothing else. S7 may not discriminate (D.3's probe (a)); a RED that does not fail is reported, not fixed. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–9 |
| Decisions (owner, 2026-11-18) | D2.1: 2, 3, 4. D2.2: 2, 3. D2.3: 4 (through the Contract). D2.4: 2, 3. D2.5: 2, 3, 4, 6. D2.6: 2 (`parallel.md`, read only when more than one plan is in flight). D2.7: 4, 7; 9 (Steps 9–17). D2.8: 5. D2.9: 4. D2.10: Execution notes; 9 (Step 20). D2.11: 8 (README); 9 (Steps 21–22) |
| The plans | Header, Contract, File structure; Plan 2's row: 1–8 (and P17's one extra file) |
| 1. `bin/relay-merge` (Plan 1) | Plan 1's. Used here only through the Contract: 4 (`reviewing.md` §4), 8 (README); 9 (Steps 2, 20, 25) |
| 2. `parallel.md` §1: what runs at once (Plan 2) | 2; 3 (`dispatching.md` §1) |
| 3. `parallel.md` §2: the conflict check (Plan 2) | 2; 3 (`planning.md` §2, check 9) |
| 4. Planning several plans (`parallel.md` §1, Plan 2) | 2; 3 (`planning.md` §1, §3, §4) |
| 5. `parallel.md` §3: stacking (Plan 2) | 2; 3 (`dispatching.md` §2, §3, §5, §7); 4 (`reviewing.md` §2); 6 (the catch-up round) |
| 6. Landing: `parallel.md` §4 and `reviewing.md` §4 (Plan 2) | 2 (§4); 4 (`reviewing.md` §4, §5) |
| 7. The other files (Plan 2) | 1 (the guard), 2 (`SKILL.md`), 3, 4, 5, 6, 7, 8 (README) |
| 8. The standing skill-test leg (Plan 2, `reviewing.md`) | 4 (`reviewing.md` §3, §4), 2 (`SKILL.md`'s models), 7 (`writing-plans`, `brainstorming`); 9 (Steps 9–17) |
| 9. The release (D2.11) | 8 (README's update line); 9 (Steps 21–22) |
| 10. Testing and acceptance | 8 (the gates); 9 |
| 11. Running D.2 itself | Execution notes; 9 (Steps 9–17 by hand, Steps 19–20) |
| 12. Out of scope | Execution notes; 9 (Step 4: nothing else changes) |

## File structure

- **Modify (Task 1):** `tests/orchestrating/run-tests.sh`, the guard: the folder holds `parallel.md`, and no
  orchestrating file names `finishing-a-development-branch`.
- **Create (Task 2):** `skills/orchestrating/parallel.md`. **Modify (Task 2):** `skills/orchestrating/SKILL.md`.
- **Modify (Task 3):** `skills/orchestrating/planning.md`, `skills/orchestrating/dispatching.md`.
- **Modify (Task 4):** `skills/orchestrating/reviewing.md`.
- **Modify (Task 5):** `skills/orchestrating/quartz.md`.
- **Modify (Task 6):** `skills/executing-plans/SKILL.md`, `templates/agents/executor.md`.
- **Modify (Task 7):** `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`,
  `skills/writing-plans/plan-document-reviewer-prompt.md` (P17).
- **Modify (Task 8):** `README.md`.
- **Unchanged:** Plan 1's files, `bin/`, `hooks/`, the other templates (P18), the other skills and suites;
  `finishing-a-development-branch` stays for work outside the relay.
- **Task 9, outside the branch (owner and orchestrator):** the skill-test runs, the release (`package.json`,
  `.claude-plugin/plugin.json`, the tag, the push), the installed plugin, this repo's generated agents, throwaway repos
  under `/tmp/hr-d2-*`, and this plan's record on `main`.

---

### Task 1: The guard expects `parallel.md` and bans `finishing-a-development-branch` (spec §7)

**Files:**
- Modify: `tests/orchestrating/run-tests.sh:2-7` (header), `:81-86` (the folder check), `:153-155` (the check list),
  `:211` and `:231-233` (the broken cases)

- [x] **Step 0: Plan 1 is on `main`.** Run
  `test -f bin/relay-merge && test -f docs/relay-merge.md && test -f .hyper-relay/merge.conf && echo plan1`. Expected:
  `plan1`. Otherwise stop and report (Execution notes).

- [x] **Step 1: The header.** In `tests/orchestrating/run-tests.sh`, replace:

```text
# POSIX guard for the relay skills (hyper-relay D.3): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, and `quartz install-git-hook`
# named only in quartz.md. It reads the working tree, not git's index, so an untracked
# new file counts and it runs the same in a worktree. Each check also runs on a copy of
# the tree broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "24 passed, 0 failed"
```

with:

```text
# POSIX guard for the relay skills (hyper-relay D.3, D.2): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, `quartz install-git-hook`
# named only in quartz.md, and no orchestrating file naming finishing-a-development-branch
# (the relay lands branches with relay-merge). It reads the working tree, not git's index,
# so an untracked new file counts and it runs the same in a worktree. Each check also runs
# on a copy of the tree broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "26 passed, 0 failed"
```

- [x] **Step 2: The folder holds `parallel.md`.** Replace:

```text
# --- 2. The folder holds exactly the map, the three leg files and quartz.md.
orchestrating_folder() (
    cd "$1/skills/orchestrating" || exit 2
    got=$(ls -A | tr '\n' ' ')
    want='SKILL.md dispatching.md planning.md quartz.md reviewing.md '
```

with:

```text
# --- 2. The folder holds exactly the map, the three leg files, parallel.md and quartz.md.
orchestrating_folder() (
    cd "$1/skills/orchestrating" || exit 2
    got=$(ls -A | tr '\n' ' ')
    want='SKILL.md dispatching.md parallel.md planning.md quartz.md reviewing.md '
```

- [x] **Step 3: The new check.** Replace:

```text
CHECKS='no_old_dispatching_pointer dispatching_pointers_name_orchestrating old_dispatching_gone
no_subagent_driven code_review_not_per_task brainstorming_never_invokes_writing_plans orchestrating_folder
no_machine_paths skill_names_resolve section_refs_resolve install_git_hook_only_in_quartz_md'
```

with:

```text
# --- 6. The relay lands branches with relay-merge: no orchestrating file names
# finishing-a-development-branch, which stays for work outside the relay.
no_finishing_branch_in_orchestrating() (
    cd "$1" || exit 2
    none -F 'finishing-a-development-branch' skills/orchestrating
)

CHECKS='no_old_dispatching_pointer dispatching_pointers_name_orchestrating old_dispatching_gone
no_subagent_driven code_review_not_per_task brainstorming_never_invokes_writing_plans orchestrating_folder
no_machine_paths skill_names_resolve section_refs_resolve install_git_hook_only_in_quartz_md
no_finishing_branch_in_orchestrating'
```

- [x] **Step 4: The broken cases.** Replace:

```text
broken "a sixth file in skills/orchestrating"
```

with:

```text
broken "a seventh file in skills/orchestrating"
```

Then replace:

```text
broken "quartz install-git-hook outside quartz.md"
printf '\nRun `quartz install-git-hook` once.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail install_git_hook_only_in_quartz_md
```

with:

```text
broken "quartz install-git-hook outside quartz.md"
printf '\nRun `quartz install-git-hook` once.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail install_git_hook_only_in_quartz_md

broken "finishing-a-development-branch in skills/orchestrating"
printf '\nMerge with `hyper-relay:finishing-a-development-branch`.\n' >> "$CASE/skills/orchestrating/reviewing.md"
expect_fail no_finishing_branch_in_orchestrating
```

- [x] **Step 5: Syntax.**

Run: `dash -n tests/orchestrating/run-tests.sh`
Expected: silent, exit 0.

- [x] **Step 6: Run it; exactly two checks fail, because `parallel.md` does not exist yet and `reviewing.md` still
  merges through `finishing-a-development-branch`.**

Run: `sh tests/orchestrating/run-tests.sh | grep -A 1 -e '^FAIL' -e 'passed, '`
Expected, in this order (with `--` lines between the groups, which are `grep`'s):

```text
FAIL orchestrating_folder
       expected [SKILL.md dispatching.md parallel.md planning.md quartz.md reviewing.md ], got [SKILL.md dispatching.md planning.md quartz.md reviewing.md ]
FAIL no_finishing_branch_in_orchestrating
       skills/orchestrating/reviewing.md:113:`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
24 passed, 2 failed
```

Also run `sh tests/orchestrating/run-tests.sh | grep -c '^ok   .* can fail: '`: expected `14`. If anything else
fails, stop and report: the tree differs from the one this plan read.

- [x] **Step 7: Commit.**

```bash
git add tests/orchestrating/run-tests.sh
git commit -m "test: the relay guard expects parallel.md and no finishing-a-development-branch in orchestrating" -m "The orchestrating folder now holds parallel.md beside the leg files and quartz.md, and a new check fails when any orchestrating file names finishing-a-development-branch: the relay lands branches with relay-merge. Two checks fail until parallel.md exists and reviewing.md merges with relay-merge." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: `parallel.md`, and `SKILL.md` lists it (spec §2–§6, §7; D2.1, D2.2, D2.4–D2.6; P1–P6, P26, P27)

**Files:**
- Create: `skills/orchestrating/parallel.md`
- Modify: `skills/orchestrating/SKILL.md:23-29` (the files beside it), `:38` (stop 4's row), `:58` (the state table),
  `:96-98` (Fallbacks, Models)

- [ ] **Step 1: Create `skills/orchestrating/parallel.md`** with exactly this content:

````markdown
# Several plans at once

Part of `orchestrating` (`SKILL.md` beside this file is the map). Read it at a handoff while another plan is in
flight, and whenever a spec has more than one plan. A single plan with nothing else in flight never needs it: the leg
files run it alone, as before.

A plan is **in flight** from its dispatch until its branch merges: its branch, named after the plan
(`dispatching.md` §3), exists and is not yet in `main` (`git branch --no-merged main` lists it). It runs as a branch
run (the main checkout is on its branch) or in a worktree (`git worktree list` shows it).

This file says what runs at once (§1), the conflict check before each dispatch (§2), stacking a plan on the one it
builds on (§3), and the order the plans land in (§4). Each plan still goes through the leg files on its own: its
executor (`dispatching.md`), its review legs, its stop 4 and its merge (`reviewing.md`). The merge's exit codes are
`reviewing.md` §4's.

## 1. What runs at once

**Planning.** A spec's planners all run at once (`planning.md` §1), except a stacked plan's (§3): it is dispatched
once its base's plan is committed, and plans against the files as the base plan leaves them. All of a spec's plans
share one stop 3 (`planning.md` §3), with a line per plan in its handoff question.

**Executing.**

- **A spec's plans:** every plan without a `**Builds on:**` line can be dispatched at once, in the spec's order. A plan
  with one is stacked (§3).
- **Plans from different specs** run at once whenever the owner starts them.
- **All worktrees:** when two or more plans would be in flight, each runs in a worktree; Branch is offered only for a
  plan that will run alone (`dispatching.md` §1). If a branch run is already active when a second plan starts, that
  plan runs in a worktree, and its handoff line and its stop 4 say "merges after `<branch>`": the merge runs only from
  the main checkout on `main` (`reviewing.md` §4).
- **No background agents** (a harness that waits for each subagent): every rule still holds; the plans run in turn.

**The handoff question** (`dispatching.md` §1) for several plans, or for a plan that joins one in flight, is one
message: a line per plan, then a line per overlap the conflict check found (§2), leaving out the lines that do not
apply:

> Plans ready. They run at once, so each runs in its own **worktree**:
> 1. `<plan path>` (N tasks): starts now.
> 2. `<plan path>` (N tasks): stacked on plan 1; starts when plan 1 passes acceptance.
> 3. `<plan path>` (N tasks): waits for `<branch>` to merge.
>
> - Shared files: plan 3 and `<branch>` both change `<path>`. Plan 3 waits for it to merge; say "run them at once
>   anyway" to start it now.
> - Numbered names: plan 2 and `<branch>` both created `<folder>/000097_*`; plan 2's planner renumbered its files to
>   `000098_*`.
>
> OK?

The owner's "OK" is the go-ahead for every plan it covers, each when its line says: `dispatching.md` §2 to §5 for a
plan that starts now, and the same later for a stacked plan (§3) or a waiting one (§2), without asking again.

## 2. The conflict check

Before each dispatch that joins another plan in flight, or a plan approved to run beside it, compare the plan with
each of them. Run it before the handoff question (`planning.md` §2), and again just before a waiting plan is
dispatched.

- **Shared files.** A plan's paths are its tasks' `- Create:`, `- Modify:` and `- Test:` paths, without any `:lines`
  part:

  ```sh
  grep -E '^- (Create|Modify|Test): ' <plan> | grep -o '`[^`]*`' | tr -d '`' | grep -v '^:' | sed 's/:[0-9][0-9,-]*$//' | sort -u
  ```

  An in-flight plan's paths are its plan's, plus what its branch has changed so far:
  `git diff --name-only main...<branch>`. A path in both lists is an overlap.
- **Numbered names.** Two plans create files in the same folder whose names start with the same digits, such as
  migrations (`000097_orders.up.sql` and `000097_coupons.up.sql`). Compare the folder and leading digits of each
  plan's `- Create:` paths, and of the files the in-flight branch has added
  (`git diff --name-only --diff-filter=A main...<branch>`), as `sed -E -n 's#^(.*/)?([0-9]+)[^/]*$#\1\2#p'` prints
  them. A date (`2026-11-18-…`) is not a sequence number.

**What happens.** "Later" means dispatched later, or later in the spec's order for a spec's own plans.

- **Shared files:** the later plan waits until the earlier one merges, or is stacked on it if it builds on it (§3).
  When the earlier one merges, run this check again, then dispatch the waiting plan.
- **A numbered collision:** before the handoff question, the later plan goes back to its planner, resumed or fresh
  with the plan (`planning.md` §2), to renumber above the other plan's highest number in that folder and commit the
  plan again.
- **Both kinds appear in the handoff question,** one line each (§1). The owner may say "run them at once anyway":
  record that as a deviation, and name it at both plans' stop 4. A conflict is then settled at the merge
  (`reviewing.md` §4, exit 2).

## 3. Stacking

A stacked plan's header carries `**Builds on:** <base plan path>`. A plan builds on exactly one plan; in a chain (C on
S on B) each link follows the same rules. A `**Builds on:**` line whose base has already merged changes nothing: the
plan runs from `main`. The base has merged when `git log -1 --format=%h --grep='Plan-Task: <base plan path>' main`
prints a commit (`relay-merge` deletes the base's branch).

- **Cut.** When the base passes acceptance (its fix loop has ended, `reviewing.md` §2), cut the stacked plan's
  worktree from the base's branch: `git worktree add .worktrees/<S> -b <S> <B>`, or `wt new <S> --from <B>` in a repo
  with a `.wt.conf` (`dispatching.md` §3). Then dispatch its executor (`dispatching.md` §4 and §5). It runs while the
  base goes through its code review and stop 4.
- **Catch up.** The stacked plan's review legs (the hand-back check of `dispatching.md` §7, acceptance, the code
  review) wait until its base has merged: hold its executor's report until then. Then, when `main` has changes its
  branch lacks (`git diff --quiet <S>...main` fails: the base's code-review fixes, other plans' merges), its executor
  first gets a catch-up round, resumed or fresh as `dispatching.md` §5 says: "Catch-up round: your base `<B>` has
  merged. Merge `main` into your branch, rerun your full gates, and report." A catch-up round is not a fix round: it
  needs no finding and counts toward no fix-round limit. Then `dispatching.md` §7 and `reviewing.md`, as for any plan:
  acceptance and the code review see the plan on top of the final `main`, and the review range holds only its own
  work.
- **Base dropped or stuck.** If the owner drops the base, or its merge fails and is not recovered, the stacked plan
  stops and goes to the owner: it cannot land without its base.

## 4. Landing order

Every landing is `reviewing.md` §4's: `relay-merge` from the main checkout on `main`, read by its exit code.

- Each plan lands after its own stop 4; a stacked plan always after its base (§3 holds its review legs until then).
- When a second plan reaches stop 4 before the owner has answered the first's, one stop-4 message covers both, and on
  the owner's go-ahead `relay-merge <first> <second>` lands them in the order they arrived. It stops at the first
  failure; the branches before it stay landed.
- After each landing, plans still in flight do not catch up on their own: the conflict check kept their files apart,
  and their own `relay-merge` reruns the gates on the merged result. A plan stacked on the one that landed now starts
  its review legs (§3), and a plan waiting for it is dispatched (§2).
````

- [ ] **Step 2: `SKILL.md` lists `parallel.md` beside the leg files (spec §7).** In `skills/orchestrating/SKILL.md`,
  replace:

```text
The three leg files and `quartz.md` are beside this SKILL.md. Read each leg file when the loop reaches its leg, not
before, and `quartz.md` at the start of every leg (Quartz duties, below):

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/quartz.md` (`quartz.md` beside this SKILL.md).
```

with:

```text
The three leg files, `parallel.md` and `quartz.md` are beside this SKILL.md. Read each leg file when the loop reaches
its leg, not before; `parallel.md` whenever a second plan would be in flight or a spec has several plans; and
`quartz.md` at the start of every leg (Quartz duties, below):

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/parallel.md` (`parallel.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/quartz.md` (`quartz.md` beside this SKILL.md).
```

- [ ] **Step 3: Stop 4 reports the skill tests (spec §8).** Replace:

```text
| 4. Ready to merge | Its questions first: the proposed cards, the steps that are the owner's, where to click through. Then gate and acceptance results, fixes made, Critical findings fixed or dropped (`reviewing.md` §4) | the click-through and the merge |
```

with:

```text
| 4. Ready to merge | Its questions first: the proposed cards, the steps that are the owner's, where to click through. Then gate, acceptance and skill-test results, fixes made, Critical findings fixed or dropped (`reviewing.md` §4) | the click-through and the merge |
```

- [ ] **Step 4: The stacked row (spec §7; P26).** Replace:

```text
| A plan's branch with all its executor tasks committed | By its review status (below) |
```

with:

```text
| A stacked plan's branch (its plan's header has `**Builds on:**`) with all its executor tasks committed, whose base has not merged | It waits for its base (`parallel.md` §3): no review leg until the base merges |
| A plan's branch with all its executor tasks committed | By its review status (below) |
```

- [ ] **Step 5: The skill-test runs are on Sonnet (spec §8).** Replace:

```text
- **Models:** the generated agents carry their own. The plan reviewer and the code reviewer run on Sonnet: in Claude
  Code, `model: sonnet` on the dispatch; in OpenCode, which sets a model per agent and not per dispatch, the
  `general` subagent's configured model.
```

with:

```text
- **Models:** the generated agents carry their own. The plan reviewer, the code reviewer and the skill-test runs
  (`reviewing.md` §3) run on Sonnet: in Claude Code, `model: sonnet` on the dispatch; in OpenCode, which sets a model
  per agent and not per dispatch, the `general` subagent's configured model.
```

- [ ] **Step 6: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| grep -A 1 -e '^FAIL' -e 'passed, '` | `FAIL no_finishing_branch_in_orchestrating`, its `skills/orchestrating/reviewing.md:113:` line, then `25 passed, 1 failed` (reviewing.md changes in Task 4) |
| `grep -c '^## [1-4]\. ' skills/orchestrating/parallel.md` | `4` |
| `grep -c 'CLAUDE_SKILL_DIR' skills/orchestrating/SKILL.md` | `6` |
| `grep -c -e 'CLAUDE_SKILL_DIR' -e '~/' -e '/home/' skills/orchestrating/parallel.md` | `0` |
| `grep -n -F '**Builds on:**' skills/orchestrating/SKILL.md` | one line, the state table's new row |
| `grep -n -F 'skill-test' skills/orchestrating/SKILL.md` | two lines: stop 4's row and the Models fallback |

- [ ] **Step 7: Commit.**

```bash
git add skills/orchestrating/parallel.md skills/orchestrating/SKILL.md
git commit -m "feat: orchestrating's parallel.md runs several plans at once: conflict check, stacking, landing order" -m "parallel.md is read only when more than one plan is in flight. Every plan without a Builds on line runs at once, each in a worktree; a plan that shares files with one in flight waits for it, and a numbered-name collision goes back to the later plan's planner. A stacked plan is cut from its base's branch when the base passes acceptance, and its review legs wait for the base's merge and a catch-up round. Plans land after their own stop 4, through relay-merge, in the order they arrived. SKILL.md lists the file, gains the stacked row, and puts the skill-test runs on Sonnet." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: `planning.md` and `dispatching.md` (spec §4, §5, §7; D2.2, D2.4, D2.5; D3.10; P1, P17, P27)

**Files:**
- Modify: `skills/orchestrating/planning.md:16` (§1, the planners), `:23` (§1, the prompt), `:46` (§2, check 4),
  `:51` (§2, after check 7), `:62` and `:72` (§3), `:87-90` (§4)
- Modify: `skills/orchestrating/dispatching.md:15-17` and `:31-36` (§1), `:42` (§2), `:56-60` (§3), `:86-87` (§5),
  `:109` (§7)

- [ ] **Step 1: `planning.md` §1, a stacked plan's planner waits for its base's plan (spec §4).** In
  `skills/orchestrating/planning.md`, replace:

```text
- **One planner per plan, in parallel:** the repo's `<project>-planner` (`.claude/agents/<project>-planner.md`).
```

with:

```text
- **One planner per plan, in parallel:** the repo's `<project>-planner` (`.claude/agents/<project>-planner.md`),
  except a stacked plan's (the spec's plans list says it builds on another): it is dispatched once its base's plan is
  committed (`parallel.md` §1).
```

Then replace:

```text
  - with sibling plans: their paths and branches, and that the spec's contract between them binds;
```

with:

```text
  - with sibling plans: their paths and branches, and that the spec's contract between them binds;
  - for a stacked plan: its base plan's path, which its header names in a `**Builds on:**` line, and that it plans
    against the files as the base plan leaves them;
```

- [ ] **Step 2: `planning.md` §2, the step kinds and two new checks (spec §3, §5, §8; P1, P17).** Replace:

```text
   its steps says who runs it: `reviewer`, `owner` or `after merge`.
```

with:

```text
   its steps says who runs it: `reviewer`, `owner`, `after merge` or `skill-test`.
```

Then replace:

```text
7. **Sibling plans:** their **Contract** sections are identical.
```

with:

```text
7. **Sibling plans:** their **Contract** sections are identical.
8. **Stacked:** a plan the spec says builds on another has `**Builds on:** <base plan path>` in its header.
9. **Several plans, or one joining a plan in flight:** `parallel.md` §2's conflict check. A numbered collision goes
   back to the later plan's planner, like a failed check; shared files become lines in the handoff question.
```

- [ ] **Step 3: `planning.md` §3, one stop 3 for several plans (spec §4).** Replace:

```text
- the handoff question from `dispatching.md` §1, with its warnings, for the first plan to run.
```

with:

```text
- the handoff question from `dispatching.md` §1, with its warnings: for several plans, or a plan joining one in
  flight, a line per plan and a line per overlap (`parallel.md` §1 and §2).
```

Then replace:

```text
- **Approve, with a mode:** `dispatching.md` §2. The answer is the go-ahead: do not ask again.
```

with:

```text
- **Approve, with a mode:** `dispatching.md` §2, for each plan that starts now (`parallel.md` §1 says when the others
  start). The answer is the go-ahead: do not ask again.
```

- [ ] **Step 4: `planning.md` §4 points to `parallel.md` (spec §4, §7).** Replace:

```text
They run one after another, in the spec's order. After plan k merges (`reviewing.md` §5), plan k+1 gets its own
stop-3 handoff question, and its branch is cut from the new `main`. Running them at once is not part of this skill.
```

with:

```text
A spec with several plans, or a plan that would run beside another in flight, runs by `parallel.md`: the planners
and the one stop 3 (`parallel.md` §1), the conflict check before each dispatch (`parallel.md` §2), a plan stacked on
the one it builds on (`parallel.md` §3), and the order they land in (`parallel.md` §4).
```

- [ ] **Step 5: `dispatching.md` §1, Branch only for a plan that runs alone (spec §7; D2.2; P27).** In
  `skills/orchestrating/dispatching.md`, replace:

```text
This is the phase gate between plan and execution: stop for the owner's answer. First read the `execute:` line from
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one.
```

with:

```text
This is the phase gate between plan and execution: stop for the owner's answer. First read the `execute:` line from
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one.

**Branch is offered only for a plan that will run alone:** no other plan is in flight and none is approved to run
beside it (`parallel.md` says what in flight means). Otherwise every plan runs in a worktree, and the question is
`parallel.md` §1's: a line per plan, then a line per overlap its conflict check found. The forms below are for a plan
that runs alone.
```

Then replace:

```text
- **While a branch run is active, Branch is not offered.** Say that one is active, and offer Worktree.

The owner's answer is the go-ahead to dispatch this plan; do not ask again.
```

with:

```text
The owner's answer is the go-ahead to dispatch the plan, or each plan the question names when `parallel.md` says it
starts; do not ask again.
```

- [ ] **Step 6: `dispatching.md` §2 and §3, a worktree cut from `main` or the base's branch, `wt new`, and the exclude
  file git names (spec §7; D3.10).** Replace:

```text
- **Worktree:** the new worktree is cut from `main`. The main checkout may be on a branch run.
```

with:

```text
- **Worktree:** the new worktree is cut from `main`, or from its base's branch for a stacked plan (`parallel.md` §3).
  The main checkout may be on a branch run.
```

Then replace:

```text
  (`git add .gitignore`, then `git commit -m "chore: ignore .worktrees/" -- .gitignore`); during a branch run, add
  the line to `.git/info/exclude` instead, which is not tracked. Then
  `git worktree add .worktrees/<branch> -b <branch> main`.
```

with:

```text
  (`git add .gitignore`, then `git commit -m "chore: ignore .worktrees/" -- .gitignore`); during a branch run, add
  the line to the file `git rev-parse --git-path info/exclude` prints instead, which is not tracked. Then cut the
  worktree from `<base>`, which is `main`, or the base's branch for a stacked plan (`parallel.md` §3):
  `git worktree add .worktrees/<branch> -b <branch> <base>`; in a repo with a `.wt.conf`,
  `wt new <branch> --from <base>`, which makes the same worktree and runs the repo's worktree setup.
```

- [ ] **Step 7: `dispatching.md` §5 and §7, a stacked plan's dispatch and its hand-back (spec §5).** Replace:

```text
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.
```

with:

```text
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- for a stacked plan: that its branch was cut from its base's branch, `<base branch>`, which has not merged yet;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.
```

Then replace:

```text
Before relaying anything, where the branch is checked out:
```

with:

```text
Before relaying anything, where the branch is checked out (for a stacked plan, only once its base has merged and any
catch-up round is done: `parallel.md` §3):
```

- [ ] **Step 8: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `25 passed, 1 failed` (the one is `no_finishing_branch_in_orchestrating`, until Task 4) |
| `grep -n -F 'one after another' skills/orchestrating/planning.md` | nothing |
| `grep -n -E 'after merge. or .skill-test' skills/orchestrating/planning.md` | one line, §2's check 4 |
| `grep -c -E '^[89]\. \*\*' skills/orchestrating/planning.md` | `2` |
| `grep -n -F 'While a branch run is active, Branch is not offered' skills/orchestrating/dispatching.md` | nothing |
| `grep -n -F 'Branch is offered only for a plan that will run alone' skills/orchestrating/dispatching.md` | one line, in §1 |
| `grep -n -F '.git/info/exclude' skills/orchestrating/dispatching.md` | nothing |
| `grep -n -F 'git rev-parse --git-path info/exclude' skills/orchestrating/dispatching.md` | one line, in §3 |
| `grep -n -F 'wt new <branch> --from <base>' skills/orchestrating/dispatching.md` | one line, in §3 |

- [ ] **Step 9: Commit.**

```bash
git add skills/orchestrating/planning.md skills/orchestrating/dispatching.md
git commit -m "feat: planning and dispatching hand several plans to worktrees, after the conflict check" -m "A stacked plan's planner starts once its base's plan is committed and plans against it; the hand-back check knows skill-test steps, the Builds on line and the conflict check; one stop 3 covers a spec's plans, and planning.md's section 4 points to parallel.md. Branch is offered only for a plan that runs alone. A worktree is cut from main or, for a stacked plan, its base's branch, with wt new in a repo with .wt.conf, and the exclude file is the one git names. A stacked plan's hand-back waits for its base's merge." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `reviewing.md`: `relay-merge` by its exit codes, and the skill-test leg (spec §6, §8; D2.3, D2.7, D2.9; P7–P13, P26)

**Files:**
- Modify: `skills/orchestrating/reviewing.md:63-65` (§2), `:79-83` (§3), `:87-89` and `:99-103` (§4's wait and
  report), `:111-115` (§4's merge), `:126` (§5)

- [ ] **Step 1: §2, cut a stacked plan when its base's fix loop ends (P26).** In
  `skills/orchestrating/reviewing.md`, replace:

```text
N of the M `reviewer` steps passed and K are NEEDS-HUMAN, after F fix rounds. A status replaces the card's previous
one, which is enough: the code review runs only after acceptance. A resumed orchestrator reads it (`SKILL.md`,
Finding where work stands). A note that fails is reported once, in one line (`quartz.md` §2).
```

with:

```text
N of the M `reviewer` steps passed and K are NEEDS-HUMAN, after F fix rounds. A status replaces the card's previous
one, which is enough: the code review runs only after acceptance. A resumed orchestrator reads it (`SKILL.md`,
Finding where work stands). A note that fails is reported once, in one line (`quartz.md` §2).

When the fix loop ends and a plan is stacked on this one, cut and dispatch it now (`parallel.md` §3).
```

- [ ] **Step 2: §3, the skill tests beside the code review (spec §8; P11, P12).** Replace:

```text
- **Important and Minor:** proposed cards (§4).

When the code review and its Critical fixes are done, post the status note as §2 does:

`` `<plan path>`: code review done, C Critical (x fixed, y dropped), I Important, m Minor. At stop 4. ``
```

with:

```text
- **Important and Minor:** proposed cards (§4).

**The skill tests** run when the plan's acceptance task has `skill-test` steps (`hyper-relay:writing-plans` requires
them in a plan that creates or changes a file in a skill's folder), at the same time as the code review. They are
`hyper-relay:writing-skills`' RED/GREEN pressure tests:

1. Put the skills from `main` and from the branch in two scratch folders, inside an evidence folder as §1's:
   `mkdir -p <folder>/red <folder>/green`, then
   `git archive main <skills> | tar -x -C <folder>/red` and
   `git archive <branch> <skills> | tar -x -C <folder>/green`. `<skills>` is the folder that holds the repo's skill
   folders (`skills` in a plugin, `.claude/skills` in a project). When `main` has no such folder, `red/` stays empty:
   RED then reads no skill at all, as it should for a new skill.
2. Dispatch each step's scenario twice, in the background, each time to a general-purpose agent on Sonnet
   (`SKILL.md`, Fallbacks): GREEN given the `green/` folder, RED given the `red/` folder. Each prompt is this standing
   preamble, then the step's situation, verbatim:

   > You are taking part in a test of written skills. The skills are in `<the folder>`: read the ones the situation
   > needs, from that folder only, and nothing else on this machine. Run no command and change no file. Act as the
   > agent the situation names. Answer with the commands you would run, in order, and the next message you would
   > send, verbatim.

3. Judge each answer against its step. A GREEN that does not do what the step says GREEN must do is a fix round (§2),
   with the step, the scenario and the answer as its finding; after the fix, rerun that GREEN on a fresh copy of the
   branch's skills. A RED that does not fail (it already does what GREEN must) means the scenario does not test the
   change: stop 4 says so, and it blocks nothing.

When the code review, its Critical fixes and the skill tests are done, post the status note as §2 does:

`` `<plan path>`: code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN. At stop 4. ``

The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without skill tests leaves out
"; skill tests G/S GREEN".
```

- [ ] **Step 3: §4, stop 4 waits for the skill-test runs and reports them (spec §8; P13).** Replace:

```text
**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer. An agent's reply arrives
before the notification that carries its usage. Where the harness reports no usage, stop 4 says so.
```

with:

```text
**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer, each skill-test run. An
agent's reply arrives before the notification that carries its usage. Where the harness reports no usage, stop 4 says
so.
```

Then replace:

```text
- the acceptance verdicts;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- the token counts of the acceptance reviewer and the code reviewer against the executor's, as your harness reports
  them ("not reported" where it reports none), until the owner says they have seen enough.
```

with:

```text
- the acceptance verdicts;
- the skill-test verdicts, GREEN and RED for each scenario, naming each RED that did not fail;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- each deviation recorded on the way, such as an overlap the owner chose to run at once (`parallel.md` §2);
- the token counts of the acceptance reviewer, the code reviewer and the skill-test runs against the executor's, as
  your harness reports them ("not reported" where it reports none), until the owner says they have seen enough.
```

- [ ] **Step 4: §4, the merge is `relay-merge`, read by its exit code (spec §6; D2.3, D2.9; P7–P10).** Replace:

```text
The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).
```

with:

```text
The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge. While a branch run is
active, a worktree plan's stop 4 says it "merges after `<branch>`": the merge runs only from the main checkout on
`main`.

**The merge** lands the branch with `relay-merge`: a `--no-ff` merge into `main`, the gates the repo's
`.hyper-relay/merge.conf` names run on the merged result, then the branch and its worktree removed (hyper-relay's
`docs/relay-merge.md`). Claude Code puts it on `PATH`; elsewhere the owner links it. When `command -v relay-merge`
finds nothing, tell the owner and stop. On the owner's go-ahead, in the main checkout:

1. After a branch run, `git switch main`. When the worktree has a `wt` stack up, `(cd <worktree> && wt down)`.
2. `PUSH=0 RELAY_MERGE_TRAILERS='<your attribution lines, one per line>' relay-merge <branch>`, with several branches
   in the order `parallel.md` §4 gives. `PUSH=0`: pushing stays the owner's call.
3. Read its exit code. Branches before the one that failed have landed, and stay landed: §5 runs for each of them.

| Exit | `relay-merge` | You |
|---|---|---|
| 0 | every branch landed | §5, for each plan that landed |
| 1 | refused by a check; that branch did not change `main` | Fix the cause when it is your own (a `wt` stack still up, the main checkout not on `main`), and run it again; otherwise bring the owner the check's message |
| 2 | a merge conflict; aborted, `main` unchanged for that branch | A conflict round (below), then a short stop 4 again |
| 3 | a gate failed; the merge is on `main`, unpushed | Stop at once (below) |

**A conflict round** is a fix round (§2) for the branch's executor, with this finding: "`relay-merge` could not merge
`<branch>` into `main`: a conflict in `<files>`. Merge `main` into your branch, resolve the conflict, rerun your full
gates, and report." (`hyper-relay:executing-plans` says how.) After a branch run, switch the main checkout back first
(`git switch <branch>`): an executor works only where its branch is checked out. Verify the round as §2 does. Then a
short stop 4 again, since the code changed after review: the conflict, how it was resolved, the gates. On the owner's
go-ahead, the merge again.

**A failed gate** (exit 3): stop, and bring the owner the log's tail that `relay-merge` printed, at once, in a message
of its own. Nothing else lands until the owner decides:

- **Undo the unpushed merge:** check that `git log -1 --format=%s main` prints `Merge branch '<branch>'` and
  `git branch -r --contains main` prints nothing, then run `git reset --keep HEAD^1` in the main checkout on `main`.
  The branch and its worktree are still there: the failure goes to its executor as a fix round (§2; after a branch
  run, `git switch <branch>` first), then a short stop 4 again.
- **Fix forward:** on a new branch, as the owner says.

Plans in flight keep executing in their worktrees meanwhile.
```

- [ ] **Step 5: §5, what follows a landing (spec §6).** Replace:

```text
with a `Plan-Task:` commit in the same edit. When the spec has another plan, its handoff follows (`planning.md` §4).
```

with:

```text
with a `Plan-Task:` commit in the same edit. A plan stacked on this one, or waiting for it, goes on now
(`parallel.md` §4).
```

- [ ] **Step 6: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| grep -c '^ok   .* can fail: '` | `14` |
| `grep -n -F 'finishing-a-development-branch' skills/orchestrating/reviewing.md` | nothing |
| `grep -n -F 'PUSH=0 RELAY_MERGE_TRAILERS=' skills/orchestrating/reviewing.md` | one line, §4's step 2 |
| `grep -c -F -e '\| 0 \|' -e '\| 1 \|' -e '\| 2 \|' -e '\| 3 \|' skills/orchestrating/reviewing.md` | `4` (the exit-code rows) |
| `grep -n -F 'git reset --keep HEAD^1' skills/orchestrating/reviewing.md` | one line |
| `grep -c -F 'git archive' skills/orchestrating/reviewing.md` | `2` |
| `grep -n -F 'skill tests G/S GREEN' skills/orchestrating/reviewing.md` | two lines: the status note and the sentence after it |
| `grep -n -F 'each skill-test run' skills/orchestrating/reviewing.md` | one line, §4's wait |

- [ ] **Step 7: Commit.**

```bash
git add skills/orchestrating/reviewing.md
git commit -m "feat: reviewing lands every branch with relay-merge, by its exit code, and runs the skill tests" -m "The merge runs relay-merge from the main checkout on main, with PUSH=0 and the orchestrator's attribution lines as RELAY_MERGE_TRAILERS, after switching back from a branch run and stopping any wt stack. Exit 1 is fixed when the cause is the orchestrator's own, exit 2 sends the executor a conflict round and a short stop 4, and exit 3 stops for the owner: undo the unpushed merge or fix forward, with nothing else landing meanwhile. The skill tests run each skill-test scenario on Sonnet against main's skills and the branch's, beside the code review; a failing GREEN is a fix round, and stop 4 waits for the runs and reports their verdicts and tokens. A stacked plan is cut when its base's fix loop ends." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `quartz.md`: setup never holds up a leg (spec §7; D2.8; P14)

**Files:**
- Modify: `skills/orchestrating/quartz.md:48` (the setup message's lead-in), `:59-60` (Neither)

- [ ] **Step 1: The setup message no longer waits.** In `skills/orchestrating/quartz.md`, replace:

```text
Send this as a message of its own, and wait for the answer:
```

with:

```text
Send this as a message of its own. **Setup never holds up a leg:** when the leg dispatches an agent (a planner, an
executor, a reviewer), dispatch it first, then send this while the agent works; the steps below run alongside it. At
`brainstorming`'s step 1, send it before brainstorming's first question.
```

- [ ] **Step 2: A reply that ignores it counts as neither.** Replace:

```text
- **Neither** (for example "not now"): carry on with no Quartz for this session. The offer comes again in the next
  session, not at the next leg.
```

with:

```text
- **Neither** (for example "not now", or a reply that does not answer it): carry on with no Quartz for this session.
  The offer comes again in the next session, not at the next leg.
```

- [ ] **Step 3: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `grep -n -F 'wait for the answer' skills/orchestrating/quartz.md` | nothing |
| `grep -n -F 'Setup never holds up a leg' skills/orchestrating/quartz.md` | one line, in §2 |
| `grep -n -F 'or a reply that does not answer it' skills/orchestrating/quartz.md` | one line |

- [ ] **Step 4: Commit.**

```bash
git add skills/orchestrating/quartz.md
git commit -m "fix: quartz.md's setup never holds up a leg" -m "When a leg dispatches an agent, the agent goes first and the setup message follows while it works; at brainstorming's first step the message comes before the first question. A reply that does not answer the offer counts as not now." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: The executor merges `main` into its own branch for a catch-up or conflict round (spec §7; D2.5; P15, P16)

**Files:**
- Modify: `skills/executing-plans/SKILL.md:66-67` (Never), `:77` (a new section before "Branch mode adds"), `:93`
  (Integration)
- Modify: `templates/agents/executor.md:5-7` (description), `:16-19` (the opening paragraph)

- [ ] **Step 1: The "never" list allows one merge.** In `skills/executing-plans/SKILL.md`, replace:

```text
- Switch branches, stash, reset, rebase, merge, push or tag. Tick the plan. Invoke
  `hyper-relay:finishing-a-development-branch`: the owner decides the merge.
```

with:

```text
- Switch branches, stash, reset, rebase, push or tag. Merge your branch into anything: the orchestrator lands it. Your
  one merge is a catch-up or conflict round's, of `main` into your own branch (below). Tick the plan. Invoke
  `hyper-relay:finishing-a-development-branch`: the owner decides the merge.
```

- [ ] **Step 2: The rounds.** Replace:

```text
## Branch mode adds
```

with:

````text
## Catch-up and conflict rounds

After your tasks, the orchestrator may resume you, or dispatch a fresh executor with the plan, for one of two rounds:

- **Catch-up:** your plan was stacked on another plan's branch; that branch has merged, and `main` has changes your
  branch lacks.
- **Conflict:** `relay-merge` could not merge your branch into `main` because of a conflict, and left `main` unchanged.

Either way, in your checkout and on your branch (process step 1):

1. Merge `main`, or the branch the prompt names, into your branch. The merge commit carries the attribution lines your
   instructions give, in one final paragraph, and no `Plan-Task:` trailer:

   ```bash
   git merge -m "Merge branch 'main' into <branch>" -m "Co-Authored-By: <the line your instructions give>
   Claude-Session: <the URL the dispatch prompt gives>" main
   ```

   "Already up to date." means there is nothing to merge: say so in your report.
2. On a conflict, resolve each conflicted file so that both sides' changes hold, and stage each by name
   (`git add <file>`). Then commit the merge with the same two messages:
   `git commit -m "Merge branch 'main' into <branch>" -m "<the same attribution lines>"`. When the two sides cannot
   both hold, run `git merge --abort`, then stop and report the files and why.
3. Rerun the full gates (process step 5).
4. Report: the merge commit's hash, each conflict and how you resolved it, and the gates with their counts.

Never merge your branch into `main` or any other branch: the orchestrator lands it with `relay-merge`.

## Branch mode adds
````

- [ ] **Step 3: Integration.** Replace:

```text
- `hyper-relay:finishing-a-development-branch` belongs to the owner and the orchestrator, after the click-through.
```

with:

```text
- The orchestrator lands your branch with `relay-merge`, after the click-through.
  `hyper-relay:finishing-a-development-branch` is for work outside the relay.
```

- [ ] **Step 4: The executor template.** In `templates/agents/executor.md`, replace:

```text
  hyper-relay:executing-plans skill, on the branch it is given, in the main checkout or its own worktree. Never
  nests subagents, never ticks the plan, never merges or pushes. The dispatch prompt names the plan, the mode, the
  checkout and branch, which tasks are the executor's, and anything unusual.
```

with:

```text
  hyper-relay:executing-plans skill, on the branch it is given, in the main checkout or its own worktree. Never
  nests subagents, never ticks the plan, never pushes, and never merges its branch into anything: a catch-up or
  conflict round merges main into its own branch. The dispatch prompt names the plan, the mode, the checkout and
  branch, which tasks are the executor's, and anything unusual.
```

Then replace:

```text
You execute one implementation plan for the {{project}} repo by the preloaded `hyper-relay:executing-plans` skill:
its process, its "never" list and its report are yours. The dispatch prompt gives the plan, the mode (`branch` or
`worktree`), the checkout and the branch, and which tasks are yours. Below is only what is particular to
{{project}}.
```

with:

```text
You execute one implementation plan for the {{project}} repo by the preloaded `hyper-relay:executing-plans` skill:
its process, its "never" list, its catch-up and conflict rounds and its report are yours. The dispatch prompt gives
the plan, the mode (`branch` or `worktree`), the checkout and the branch, and which tasks are yours. Below is only
what is particular to {{project}}.
```

- [ ] **Step 5: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `grep -n -F 'rebase, merge, push' skills/executing-plans/SKILL.md` | nothing |
| `grep -n -F '## Catch-up and conflict rounds' skills/executing-plans/SKILL.md` | one line |
| `grep -c -F "Merge branch 'main' into <branch>" skills/executing-plans/SKILL.md` | `2` |
| `grep -n -F 'never merges or pushes' templates/agents/executor.md` | nothing |
| `grep -n -F 'never merges its branch into anything' templates/agents/executor.md` | one line, in the front matter |
| `sed -n '13p' templates/agents/executor.md` | `---`: the front matter, one line longer, now closes on line 13 |

- [ ] **Step 6: Commit.**

```bash
git add skills/executing-plans/SKILL.md templates/agents/executor.md
git commit -m "feat: an executor merges main into its own branch for a catch-up or conflict round" -m "executing-plans still forbids merging the branch into anything, and now gives the one merge an executor makes: main, or the branch the prompt names, into its own branch, with its attribution lines and no Plan-Task trailer, resolving a conflict or aborting and reporting, then rerunning its gates. Its integration notes say the orchestrator lands the branch with relay-merge. The executor template's description and opening say the same." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 7: `brainstorming` and `writing-plans`: plans in order, pressure scenarios, `**Builds on:**`, renumbering, skill tests (spec §7, §8; P17, P19)

**Files:**
- Modify: `skills/brainstorming/SKILL.md:119` (the Plans bullet), `:120` (a new bullet before it)
- Modify: `skills/writing-plans/SKILL.md:27` (after the plan count), `:74` (the acceptance bullet, and a new section)
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md:26` (P17)

- [ ] **Step 1: `brainstorming` lists a spec's plans in order (spec §7; P19).** In `skills/brainstorming/SKILL.md`,
  replace:

```text
Quartz reads it, and keeps the card open until that many plans have merged.
```

with:

```text
Quartz reads it, and keeps the card open until that many plans have merged. Such a spec also lists its plans in order, under `## The plans`: each with its subject, the suffix of its plan's file name (`-api`, `-web`), and the plan it builds on, if any. A plan builds on another when it needs that plan's unmerged work, and on one plan at most; plans that build on nothing run at once (`hyper-relay:orchestrating`'s `parallel.md`).
```

- [ ] **Step 2: `brainstorming`, a spec that changes a skill names its pressure scenarios (spec §7).** Replace:

```text
- Use elements-of-style:writing-clearly-and-concisely skill if available
```

with:

```text
- When the work creates or changes a skill (a `SKILL.md`, or a file beside it that agents read), the spec names its pressure scenarios: for each behaviour it changes, a situation, what an agent with the new text must do, and what one with today's text does instead. The plan turns each into a `skill-test` step, which the orchestrator runs on both texts.
- Use elements-of-style:writing-clearly-and-concisely skill if available
```

- [ ] **Step 3: `writing-plans`, stacked plans and renumbering (spec §7).** In `skills/writing-plans/SKILL.md`,
  replace:

```text
It asks the owner, updates the spec's `**Plans:**` line itself (`hyper-relay:orchestrating`'s `planning.md`), and dispatches you again. Never edit the spec: you write plans only.
```

with:

```text
It asks the owner, updates the spec's `**Plans:**` line itself (`hyper-relay:orchestrating`'s `planning.md`), and dispatches you again. Never edit the spec: you write plans only.

## Stacked plans

When the spec's list of plans says your plan builds on another, your plan's header carries `**Builds on:** <base plan path>`, beside its `**Spec:**` line, above its first `---`. The orchestrator dispatches you once the base plan is committed: read it, and plan against the files as the base plan leaves them (its tasks' code), not as `main` has them. A plan builds on exactly one plan. Its branch is cut from the base's branch (`hyper-relay:orchestrating`'s `parallel.md`).

## Sent back to renumber

When the orchestrator sends your plan back because another plan in flight creates files with the same leading number in the same folder (`000097_*` migrations, say), renumber yours above the highest number its prompt names, everywhere the plan names them (paths, code, commands), and commit the plan again.
```

- [ ] **Step 4: `writing-plans`, the `skill-test` step kind (spec §7, §8).** Replace:

```text
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), with its command or action and the result that counts as PASS.
```

with:

```text
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer), **`owner`** (at the click-through), **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), or **`skill-test`** (below), with its command or action and the result that counts as PASS.

## Skill tests

A plan that creates or changes a file in a skill's folder (its `SKILL.md`, or a file beside it that agents read) adds `skill-test` steps to its acceptance task: one per pressure scenario the spec names. When the spec names none, write them from the behaviour it changes, and list that among your deviations. Each step gives:

- **Situation:** everything a fresh agent needs, in full, since it sees only the skills and this text: who it is (the orchestrator, an executor, a planner), the repo's state, what has just happened, and what it is asked to answer.
- **GREEN:** what an agent reading the branch's skills must do, concretely enough to judge from its answer (the commands it would run and its next message).
- **RED:** what an agent reading `main`'s skills (or none, for a new skill) is expected to do instead.

The orchestrator runs each scenario on both, after acceptance and beside the code review (`hyper-relay:orchestrating`'s `reviewing.md`).
```

Then, in `skills/writing-plans/plan-document-reviewer-prompt.md` (P17), replace:

```text
    | The acceptance task | It is the last task. Each of its steps says who runs it (`reviewer`, `owner` or `after merge`), with its command or action and the result that counts as PASS. |
```

with:

```text
    | The acceptance task | It is the last task. Each of its steps says who runs it (`reviewer`, `owner`, `after merge` or `skill-test`), with its command or action and the result that counts as PASS; a `skill-test` step gives a situation, what GREEN must do and what RED is expected to do. |
```

- [ ] **Step 5: Check.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `grep -n -F '## The plans' skills/brainstorming/SKILL.md` | one line, the Plans bullet |
| `grep -n -F 'pressure scenarios' skills/brainstorming/SKILL.md` | one line, the new bullet |
| `grep -n -e '^## Stacked plans' -e '^## Sent back to renumber' -e '^## Skill tests' skills/writing-plans/SKILL.md` | three lines, in that order |
| `grep -n -F '**Builds on:** <base plan path>' skills/writing-plans/SKILL.md` | one line |
| `grep -n -E 'or \*\*.skill-test.\*\*' skills/writing-plans/SKILL.md` | one line, the acceptance bullet |
| `grep -n -E 'after merge. or .skill-test' skills/writing-plans/plan-document-reviewer-prompt.md` | one line |
| `grep -n -i -F 'invoke writing-plans' skills/brainstorming/SKILL.md` | nothing |

- [ ] **Step 6: Commit.**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: brainstorming names a spec's plans and pressure scenarios; writing-plans stacks, renumbers and adds skill tests" -m "A spec with several plans lists them in order under The plans, each with its subject, its suffix and the plan it builds on; a spec that changes a skill names its pressure scenarios. A planner writes Builds on in a stacked plan's header and plans against its base, renumbers when sent back for a numbered-name collision, and adds skill-test steps to the acceptance task of a plan that changes a skill. The plan reviewer's prompt accepts the new step kind." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#7
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 8: README; the full gates (spec §7, §9, §10; D2.11; P20)

**Files:**
- Modify: `README.md:19-20` (status), `:37-38` (the relay table), `:40-42` (after it), `:88-90` (updating),
  `:126-127` (after `wt`), `:134-138` (the roadmap)

- [ ] **Step 1: The status line (P20).** In `README.md`, replace:

```text
> **Status: 0.1.0.** The skills, the role agents, per-repo configuration, the orchestrator and `wt` are in. Still to
> come: several plans at once and the docs' own folder (see [Roadmap](#roadmap)).
```

with:

```text
> **Status: 0.2.0.** The skills, the role agents, per-repo configuration, the orchestrator (several plans at once
> included), `wt` and `relay-merge` are in. Still to come: the preview stack and the docs' own folder (see
> [Roadmap](#roadmap)).
```

- [ ] **Step 2: The relay table gains the skill tests and `relay-merge` (spec §7).** Replace:

```text
| Review | the acceptance reviewer agent, `requesting-code-review` (one review per branch), `receiving-code-review`, `verification-before-completion` | Evidence that it works: the plan's acceptance steps, one code review of the whole branch, then your click-through |
| Finish | `finishing-a-development-branch` | A merge, on your call |
```

with:

```text
| Review | the acceptance reviewer agent, `requesting-code-review` (one review per branch), `receiving-code-review`, `verification-before-completion`, and the skill tests (`writing-skills`' RED/GREEN runs) | Evidence that it works: the plan's acceptance steps, one code review of the whole branch, each skill test when a plan changes a skill, then your click-through |
| Finish | `relay-merge`, run by the orchestrator (`finishing-a-development-branch` for work outside the relay) | A `--no-ff` merge into `main`, gated by the repo's `.hyper-relay/merge.conf`, on your call |
```

- [ ] **Step 3: Several plans and the skill tests, under the table (spec §7).** Replace:

```text
`orchestrating` runs the legs from an approved spec to the merge: it dispatches the planner, the executor and the
reviewers, checks what each hands back, and stops for you at four points (the design, the spec, the plan and the
merge).
```

with:

```text
`orchestrating` runs the legs from an approved spec to the merge: it dispatches the planner, the executor and the
reviewers, checks what each hands back, and stops for you at four points (the design, the spec, the plan and the
merge).

Several plans can be in flight at once, each in its own worktree. Before each dispatch, the orchestrator's
`parallel.md` checks them for shared files and clashing numbered names: a plan that shares files with another waits
for it, and one whose migration number clashes is renumbered. A plan that builds on another is stacked on its branch,
and every branch lands through `relay-merge`. When a plan changes a skill, the orchestrator also runs its skill tests
beside the code review: each pressure scenario on `main`'s skills (RED) and on the branch's (GREEN), as
`writing-skills` teaches.
```

- [ ] **Step 4: Updating is an update and a reload (D2.11).** Replace:

```text
- **Updates follow the version.** `plugin.json` pins it, so `claude plugin update hyper-relay@hyper-relay` brings a new
  copy only when a release raises it. Claude Code checks a marketplace that is not Anthropic's in the background only
  if you turn on auto-update for it (`/plugin`, then **Marketplaces**).
```

with:

```text
- **Updating:** `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in a running session (or start
  a new one). `plugin.json` pins the version, and every change to what the plugin ships raises it, so an update brings
  each change and nothing half-done. Claude Code checks a marketplace that is not Anthropic's in the background only
  if you turn on auto-update for it (`/plugin`, then **Marketplaces**).
```

- [ ] **Step 5: `relay-merge` and its doc (spec §7).** Replace:

```text
Each project that uses it commits a short `.wt.conf`. [docs/wt.md](docs/wt.md) says what to put in it, what `wt`
needs (dash, Docker Compose 2.24.4 or later, `jq`, `ss`) and what each command does.
```

with:

````text
Each project that uses it commits a short `.wt.conf`. [docs/wt.md](docs/wt.md) says what to put in it, what `wt`
needs (dash, Docker Compose 2.24.4 or later, `jq`, `ss`) and what each command does.

### relay-merge

`relay-merge` (`bin/relay-merge`) is how the relay lands a branch: it merges each branch it is given into `main` with
`--no-ff`, runs the gates the repo's `.hyper-relay/merge.conf` names on the merged result, and removes the branch and
its worktree. Claude Code's Bash tool finds it by name, as it finds `wt`. For your own shell, symlink it the same way:

```sh
ln -sfn /path/to/hyper-relay/bin/relay-merge ~/.local/bin/relay-merge
```

[docs/relay-merge.md](docs/relay-merge.md) says what goes in `merge.conf` and what each exit code means.
````

- [ ] **Step 6: The roadmap (P20).** Replace:

```text
| B | **Role agents generated per repo:** a planner, an executor and a reviewer built from hyper-relay's templates and one small committed facts file per repo (`.hyper-relay/agents.md`), with a session-start notice when they fall out of date | on `main` |
| C | **Our own executing-plans:** executes in the worktree it is given (or on a branch, per repo), commits per task with `Plan-Task` trailers, runs the full checks once, and stops before merging | on `main` |
| D1 | **The orchestrator, one spec at a time:** a new `orchestrating` skill runs the relay from an approved spec to the merge. It dispatches the planner, the executor and the reviewers, checks every hand-back, runs an acceptance check and one code review per branch, and stops for you at four points | on `main` |
| D2 | **Several plans at once:** runs a spec's plans side by side, checks them for migration and shared-file conflicts before dispatch, stacks a dependent plan on an unmerged branch, and hands you one preview stack to click through | planned, after E |
| E | **`wt`:** a disposable Docker Compose stack for each worktree (its own containers, database, ports and seed data), so a branch can be clicked through without touching your real stack. Each repo adds a short `.wt.conf` | on `main` |
```

with:

```text
| B | **Role agents generated per repo:** a planner, an executor and a reviewer built from hyper-relay's templates and one small committed facts file per repo (`.hyper-relay/agents.md`), with a session-start notice when they fall out of date | 0.2.0 |
| C | **Our own executing-plans:** executes in the worktree it is given (or on a branch, per repo), commits per task with `Plan-Task` trailers, runs the full checks once, and stops before merging | 0.2.0 |
| D1 | **The orchestrator, one spec at a time:** a new `orchestrating` skill runs the relay from an approved spec to the merge. It dispatches the planner, the executor and the reviewers, checks every hand-back, runs an acceptance check and one code review per branch, and stops for you at four points | 0.2.0 |
| D2 | **Several plans at once:** runs plans side by side, each in its own worktree, after checking them for shared files and clashing numbered names (migrations); stacks a dependent plan on its base's unmerged branch; lands every branch through `relay-merge`, which gates the merged result; and runs skill tests whenever a plan changes a skill. The preview stack (several branches in one click-through) is a card of its own | 0.2.0 |
| E | **`wt`:** a disposable Docker Compose stack for each worktree (its own containers, database, ports and seed data), so a branch can be clicked through without touching your real stack. Each repo adds a short `.wt.conf` | 0.2.0 |
```

- [ ] **Step 7: README checks.**

| Run | Expected |
|---|---|
| `grep -n -F 'Status: 0.2.0' README.md` | one line |
| `grep -n -F 'claude plugin update hyper-relay@hyper-relay' README.md` | one line, the Updating bullet, which also names `/reload-plugins` |
| `grep -n -F '### relay-merge' README.md` | one line |
| `grep -n -F '](docs/relay-merge.md)' README.md` | one line |
| `grep -c -F 'parallel.md' README.md` | `1` |
| `grep -c -F '\| 0.2.0 \|' README.md` | `5` |
| `grep -n -F 'Updates follow the version' README.md` | nothing |

- [ ] **Step 8: Commit.**

```bash
git add README.md
git commit -m "docs: README: several plans at once, relay-merge, the skill tests, and updating by version" -m "The status is 0.2.0. The relay table gains the skill tests and relay-merge, with finishing-a-development-branch for work outside the relay, and a paragraph says how parallel.md runs several plans and when the skill tests run. Updating is claude plugin update, then /reload-plugins. relay-merge gets its own install section, pointing at docs/relay-merge.md, and the roadmap marks B to E as 0.2.0, with the preview stack as a card of its own." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#8
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 9: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `dash -n tests/orchestrating/run-tests.sh` | silent |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` (untouched; a regression check) |
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `git diff --name-only main...HEAD` | exactly the thirteen files of "File structure": `README.md`, `skills/brainstorming/SKILL.md`, `skills/executing-plans/SKILL.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/parallel.md`, `skills/orchestrating/planning.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/reviewing.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `templates/agents/executor.md`, `tests/orchestrating/run-tests.sh` |
| `git grep -n -i -w -e sat -e pentraze -- README.md skills templates/agents/executor.md tests/orchestrating` | nothing |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Upstream's live suites are not run (report this): they start real `claude -p` sessions. Then report, copy Task 9's
checklist (Steps 1–27, each with its marker and its PASS) into your report, and stop: Task 9 is not yours.

### Task 9: Acceptance (spec §8, §9, §10; D2.7, D2.10, D2.11; P21–P25, P28). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-d2-parallel-skills`) its dispatch names, from the checkout's top. It runs Steps 1–8 only.
- **`skill-test`**: the orchestrator, by hand as in D.3 (the installed relay has no skill-test leg yet), after
  acceptance passes and beside the code review (Steps 9–17). It puts `main`'s `skills/` and the branch's in two
  scratch folders (`git archive main skills | tar -x -C <folder>/red`, and the same with
  `hyper-relay-d2-parallel-skills` into `<folder>/green`) and dispatches each scenario twice, on Sonnet, in the
  background, with the standing preamble of this branch's `reviewing.md` §3 followed by the step's situation, verbatim.
  PASS for each step: GREEN does everything its "GREEN must" says. RED's answer is recorded: a RED that does not do what
  its "RED is expected to" says is reported at stop 4, and blocks nothing (P28). A GREEN that fails is a fix round.
- **`owner`**: the owner, at the click-through (Steps 18–19).
- **`after merge`**: the orchestrator with the owner, once the branch is merged into `main` and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 20–27), one command per Bash call. The orchestrator runs the
  commands; the owner starts the live sessions and runs the plugin update.

**This plan's run follows the installed relay** (0.1.0's `orchestrating`), not the text it writes: the new behaviour
reaches a session only after the release and the owner's update (Steps 21–22).

- [ ] **Step 1 (`reviewer`): The guard.**

| Run | PASS |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| grep -c '^ok   .* can fail: '` | `14` |
| `dash -n tests/orchestrating/run-tests.sh` | silent, exit 0 |
| `git ls-files -s tests/orchestrating/run-tests.sh` | one line starting `100644` |

- [ ] **Step 2 (`reviewer`): The other suites, and Plan 1's files untouched.**

| Run | PASS |
|---|---|
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` |
| `sh tests/relay-merge/run-tests.sh \| tail -n 1` | ends `0 failed` (Plan 1's suite, a regression check) |
| `git diff --stat main...HEAD -- CLAUDE.md .hyper-relay bin hooks docs/relay-merge.md tests/relay-merge tests/hyper-relay-agents tests/add-card-line templates/agents/planner.md templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md` | nothing |

- [ ] **Step 3 (`reviewer`): The manifests and the skill count.**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout, `PRIVACY_URL_MISSING`; no other warning |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `git show HEAD:.claude-plugin/plugin.json \| grep -F '"version"'` | `"version": "0.1.0",` (the release is after the merge) |

- [ ] **Step 4 (`reviewer`): Only the planned files changed.**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the thirteen files of Task 8 Step 9 |
| `git log --format=%B main..HEAD \| grep -c -i -w -e sat -e pentraze` | `0` |

- [ ] **Step 5 (`reviewer`): The wording, by grep.**

| Run | PASS |
|---|---|
| `git grep -n -F 'finishing-a-development-branch' -- skills/orchestrating` | nothing |
| `git grep -n 'CLAUDE_SKILL_DIR' -- skills/orchestrating` | six lines, all in `skills/orchestrating/SKILL.md`, each naming on the same line the same file relative to that SKILL.md (one is `parallel.md`) |
| `git grep -n -F '.git/info/exclude' -- skills/orchestrating` | nothing |
| `git grep -n -F 'PUSH=0 RELAY_MERGE_TRAILERS=' -- skills` | one line, in `skills/orchestrating/reviewing.md` |
| `git grep -l -F '**Builds on:**' -- skills` | exactly `skills/orchestrating/SKILL.md`, `skills/orchestrating/parallel.md`, `skills/orchestrating/planning.md`, `skills/writing-plans/SKILL.md` |
| `git grep -n -F 'one after another' -- skills/orchestrating` | nothing |
| `git grep -n -F 'wait for the answer' -- skills/orchestrating/quartz.md` | nothing |
| `git grep -n -F 'rebase, merge, push' -- skills/executing-plans/SKILL.md` | nothing |
| `git grep -n -F 'never merges or pushes' -- templates/agents/executor.md` | nothing |
| `git grep -n -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' -- skills/orchestrating skills/brainstorming/SKILL.md skills/writing-plans` | nothing |
| `git diff main...HEAD -- skills/executing-plans/SKILL.md \| grep -c -e '^+.*~/' -e '^+.*/home/' -e '^+.*/tmp/'` | `0` (its never list already names `~/.claude/`, unchanged) |

- [ ] **Step 6 (`reviewer`): `parallel.md` against the spec (§2–§6).** Read `skills/orchestrating/parallel.md` in
  full, the spec's §2–§6 and decisions D2.2, D2.4, D2.5, and this plan's P1–P6 and P27. PASS, each point quoted:
  - it is read only when another plan is in flight or a spec has several plans, and it defines "in flight";
  - §1 has the spec's §2 rules (a spec's plans without `**Builds on:**` at once, in the spec's order; plans from
    different specs; all worktrees, Branch only for a plan that runs alone, and "merges after `<branch>`" beside an
    active branch run; no background agents) and §4's (the planners at once, a stacked plan's once its base's plan is
    committed and planned against the base's files; one stop 3 with a line per plan);
  - §2 takes a plan's paths from its `- Create:`, `- Modify:` and `- Test:` lines without `:lines`, adds an in-flight
    branch's `git diff --name-only main...<branch>`, defines numbered names and "later", makes the later plan wait or
    stack, sends a numbered collision back to the planner to renumber above the other's highest number, puts both
    kinds in the handoff question one line each, and records "run them at once anyway" as a deviation settled at the
    merge (exit 2);
  - §3: the header line; exactly one base; chains; a merged base changes nothing; the cut on the base's acceptance
    with `git worktree add .worktrees/<S> -b <S> <B>` or `wt new <S> --from <B>`; the review legs wait for the base's
    merge, then a catch-up round (merge `main`, rerun the gates; not a fix round); a dropped or stuck base goes to
    the owner;
  - §4: each plan after its own stop 4, a stacked one after its base; one stop 4 for two plans and
    `relay-merge <first> <second>` in arrival order; no automatic catch-up; a stacked plan's review legs start after
    its base lands;
  - nothing in `parallel.md` contradicts the spec. List any sentence that does as a FAIL, with its line.

- [ ] **Step 7 (`reviewer`): `reviewing.md` against the spec (§6, §8) and the Contract.** Read
  `skills/orchestrating/reviewing.md` §2–§5 and `git diff main...HEAD -- skills/orchestrating/reviewing.md`. PASS:
  - §4's merge runs `relay-merge` from the main checkout on `main` with `PUSH=0` and `RELAY_MERGE_TRAILERS`, after
    `git switch main` following a branch run and `wt down` when a stack is up, and names no
    `finishing-a-development-branch`;
  - its exit table has the Contract's four codes with spec §6's actions: exit 1 fixed when the cause is the
    orchestrator's own; exit 2 a conflict round as a fix round, then a short stop 4 (the conflict, its resolution, the
    gates); exit 3 stops at once with the log's tail, nothing else lands until the owner decides undo or fix forward
    (P7's commands), and plans in flight keep executing;
  - §3's skill tests match spec §8: when they run, the two scratch folders from `main` and the branch, each scenario
    twice on Sonnet in the background, the standing preamble (only that folder's skills, no command, the commands and
    the next message verbatim), RED with no skill for a new one, a failing GREEN as a fix round, a RED that does not
    fail reported and not blocking;
  - §4 waits for every skill-test run's notification and reports the verdicts and the runs' token counts;
  - §5 ends pointing at `parallel.md` §4, and §2 cuts a stacked plan when the fix loop ends.

- [ ] **Step 8 (`reviewer`): The other files against spec §7.** Read
  `git diff main...HEAD -- skills/orchestrating/SKILL.md skills/orchestrating/planning.md skills/orchestrating/dispatching.md skills/orchestrating/quartz.md skills/executing-plans/SKILL.md templates/agents/executor.md skills/brainstorming/SKILL.md skills/writing-plans README.md`.
  PASS, each point quoted:
  - `SKILL.md` lists `parallel.md` beside the leg files, read when a second plan would be in flight or a spec has
    several plans, and has the stacked row;
  - `planning.md` §4 points to `parallel.md`; §1 dispatches a stacked plan's planner after its base's plan; §2 has
    checks 8 and 9 and `skill-test` in check 4;
  - `dispatching.md` §1 offers Branch only for a plan that runs alone and puts the overlap lines in the handoff
    question; §3 cuts from `main` or the base's branch, with `wt new <branch> --from <base>` in a repo with `.wt.conf`,
    and names the exclude file `git rev-parse --git-path info/exclude` prints;
  - `quartz.md` §2 dispatches the leg's agent first and sends the setup message while it works (D2.8);
  - `executing-plans` and the executor template still forbid merging the branch into anything, and allow `main` into
    its own branch for a catch-up or conflict round, rerunning the gates;
  - `brainstorming` lists a spec's plans in order with their subject and base, and names pressure scenarios for a
    skill change; `writing-plans` writes `**Builds on:**`, plans against the base's files, renumbers when sent back,
    and adds `skill-test` steps (P17's prompt cell too);
  - README names `relay-merge` and its doc, `parallel.md` and the skill tests, and updating by
    `claude plugin update hyper-relay@hyper-relay` then `/reload-plugins`.

- [ ] **Step 9 (`skill-test`): S1, a spec's two independent plans are approved.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy, a small POSIX shell project. Its main checkout is on `main` and clean; no other branch or
worktree exists, so no plan is in flight. `git show main:.hyper-relay/agents.md` has `execute: branch` in its header.
There is no `.wt.conf`, and `.worktrees/` is already gitignored. `git config --get hyper-relay.quartz` prints `off`.
The owner approved the spec docs/superpowers/specs/2026-11-18-toy-farewells-design.md, which has `**Plans:** 2` and
lists: 1. `bye.sh` (suffix `-bye`), builds on nothing; 2. `shout.sh` (suffix `-shout`), builds on nothing. Both
planners have reported and committed their plans on `main`:
docs/superpowers/plans/2026-11-18-toy-farewells-bye.md (3 tasks; its Files lines: `- Create: `bye.sh``,
`- Create: `tests/bye.sh``) and docs/superpowers/plans/2026-11-18-toy-farewells-shout.md (3 tasks;
`- Create: `shout.sh``, `- Create: `tests/shout.sh``). Every hand-back check passed; there are no deviations and no
decisions for the owner. Write your stop-3 message. Then the owner answers "OK": give the commands you run and the
agents you dispatch, in order.
```

GREEN must: send one stop 3 covering both plans, whose handoff question runs both in worktrees (a line per plan), names
no overlap, and offers no Branch, although the repo's default is `branch`; after "OK", create both worktrees from
`main` (`git worktree add .worktrees/toy-farewells-bye -b toy-farewells-bye main` and the same for
`toy-farewells-shout`) and dispatch two executors in the background, one per plan, without waiting for the first.

RED is expected to: hand off one plan at a time ("one after another"): a handoff question for the first plan only,
offering Branch as the repo's default, with the second plan waiting for the first to merge.

- [ ] **Step 10 (`skill-test`): S2, a second plan shares `greet.sh` with one in flight.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main` and clean; `execute: branch`; no `.wt.conf`;
`git config --get hyper-relay.quartz` prints `off`. One plan is in flight, from another spec:
docs/superpowers/plans/2026-11-18-toy-greet-polite.md, running in the worktree .worktrees/toy-greet-polite on the
branch `toy-greet-polite`; its executor is still working. Its Files lines are `- Modify: `greet.sh`` and
`- Modify: `tests/greet.sh``, and `git diff --name-only main...toy-greet-polite` prints `greet.sh`. The owner has
just approved a new spec, docs/superpowers/specs/2026-11-18-toy-greet-loud-design.md (one plan), and its planner
committed docs/superpowers/plans/2026-11-18-toy-greet-loud.md (2 tasks; Files lines `- Modify: `greet.sh:3`` and
`- Create: `tests/greet-loud.sh``; no `**Builds on:**` line). Every hand-back check passed; there are no deviations
and no decisions for the owner. Write your stop-3 message.
```

GREEN must: name the overlap in a line of its own (`greet.sh`, shared with `toy-greet-polite`, in flight); say the
loud plan waits until `toy-greet-polite` merges (a worktree when it runs); offer "run them at once anyway"; offer no
Branch; create no branch or worktree and dispatch nothing.

RED is expected to: offer to run the loud plan now (Branch as the repo's default, or a worktree), with no shared file
named.

- [ ] **Step 11 (`skill-test`): S3, two plans both create `000097_*` migrations.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/shop. Its main checkout is on `main` and clean; `execute: worktree`;
`git config --get hyper-relay.quartz` prints `off`. One plan is in flight, from another spec:
docs/superpowers/plans/2026-11-18-shop-orders.md, in the worktree .worktrees/shop-orders; its Files lines include
`- Create: `db/migrations/000097_orders.up.sql`` and `- Create: `db/migrations/000097_orders.down.sql``, and its
branch has added both files. A new plan was just committed by its planner (the agent `shop-planner`, which you can
resume): docs/superpowers/plans/2026-11-18-shop-coupons.md (4 tasks), whose Files lines are
`- Create: `db/migrations/000097_coupons.up.sql``, `- Create: `db/migrations/000097_coupons.down.sql``,
`- Create: `api/coupons.go`` and `- Modify: `api/routes.go``. The orders plan touches no `api/` file. Every other
hand-back check passed. What do you do next, before any message to the owner? Give the commands you run, and the
prompt of any agent you dispatch or resume.
```

GREEN must: treat the shared `000097_` prefix in `db/migrations/` as a numbered-name collision and send the coupons
plan back to its planner (resumed or fresh) to renumber its migrations above `000097` (to `000098_*`) and commit the
plan again, before stop 3 and before any dispatch.

RED is expected to: find no shared path and go straight to stop 3, offering to run the coupons plan as it is.

- [ ] **Step 12 (`skill-test`): S4, a stacked plan's base passes acceptance.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main`; `git config --get hyper-relay.quartz` prints `off`; no
`.wt.conf`; `.worktrees/` is gitignored. The spec docs/superpowers/specs/2026-11-18-toy-farewells-design.md has two
plans: docs/superpowers/plans/2026-11-18-toy-farewells-bye.md (plan 1) and
docs/superpowers/plans/2026-11-18-toy-farewells-loud.md (plan 2), whose header has
`**Builds on:** docs/superpowers/plans/2026-11-18-toy-farewells-bye.md`. At stop 3 the owner answered "OK" to: plan 1
now, in a worktree; plan 2 stacked on plan 1. Plan 1 runs in .worktrees/toy-farewells-bye on the branch
`toy-farewells-bye`; you verified its executor's hand-back, and its acceptance reviewer has just reported 2/2 PASS
with quoted evidence; there is nothing to fix. (1) What do you do now, for plan 1 and for plan 2? Give the commands
and the dispatches. (2) Later, plan 2's executor reports all its tasks done while plan 1's code review is still
running and plan 1 has not merged. What do you do with plan 2's report?
```

GREEN must: (1) start plan 1's code review, cut plan 2's worktree from plan 1's branch
(`git worktree add .worktrees/toy-farewells-loud -b toy-farewells-loud toy-farewells-bye`) and dispatch plan 2's
executor, telling it its branch was cut from `toy-farewells-bye`; (2) hold plan 2's review legs (hand-back check,
acceptance, code review) until plan 1 has merged, then give plan 2's executor a catch-up round first when `main` has
changes its branch lacks.

RED is expected to: not stack: plan 2 waits for plan 1's merge and is then cut from `main`; or, if cut early, its
review starts at once.

- [ ] **Step 13 (`skill-test`): S5, `relay-merge` exits 2.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main`; `git config --get hyper-relay.quartz` prints `off`. The plan
docs/superpowers/plans/2026-11-18-toy-greet-loud.md ran in the worktree .worktrees/toy-greet-loud, on the branch
`toy-greet-loud`, with no `wt` stack; its executor is the agent `toy-executor`, which you can resume. At stop 4 the
owner said "merge it". You ran, in the main checkout,
`PUSH=0 RELAY_MERGE_TRAILERS='Co-Authored-By: Claude <noreply@anthropic.com>' relay-merge toy-greet-loud`. It
reported a merge conflict in `greet.sh`, said it aborted the merge and left `main` unchanged, and exited 2.
(`relay-merge` is the relay's merge helper. Its exit codes: 0 every branch landed; 1 refused by a check; 2 merge
conflict, aborted, `main` unchanged for that branch; 3 a gate failed, the merge is on `main`, unpushed.) What do you
do next? Give the commands, the prompt of any agent you resume or dispatch, and your next message to the owner.
```

GREEN must: give `toy-greet-loud`'s executor (resumed, or fresh) a conflict round as a fix round: merge `main` into
its branch, resolve the conflict in `greet.sh`, rerun its full gates and report; verify the round; then send a short
stop 4 (the conflict, how it was resolved, the gates) before running `relay-merge` again. It does not resolve or merge
anything itself in the main checkout.

RED is expected to: give no conflict round: resolve the conflict itself, merge another way, or ask the owner how to
go on.

- [ ] **Step 14 (`skill-test`): S6, `relay-merge` exits 3.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main`; nothing has been pushed; `git config --get hyper-relay.quartz`
prints `off`. Two plans reached stop 4 together and the owner said "merge both". You ran, in the main checkout,
`PUSH=0 RELAY_MERGE_TRAILERS='Co-Authored-By: Claude <noreply@anthropic.com>' relay-merge toy-farewells-bye toy-farewells-shout`.
`toy-farewells-bye` landed. `toy-farewells-shout` merged, but its gate `sh test.sh` failed: `relay-merge` printed the
log's last lines, ending `FAIL shout: [HEY, Ada]` and `3 passed, 1 failed`, and exited 3. (Its exit codes: 0 every
branch landed; 1 refused by a check; 2 merge conflict, aborted, `main` unchanged for that branch; 3 a gate failed,
the merge is on `main`, unpushed.) A third plan, `toy-greet-polite`, finished its code review a minute ago and is
ready for its stop 4. A fourth, `toy-farewells-loud`, is still executing in its worktree. What do you do next? Give
the commands and your next message to the owner.
```

GREEN must: stop at once and send the owner the log's tail in a message of its own, asking whether to undo the
unpushed merge or fix forward on a new branch; land nothing else meanwhile (no merge for `toy-greet-polite`); leave
`toy-farewells-loud` executing; reset, revert, push or fix nothing on its own.

RED is expected to: handle it without the owner: dispatch a fix to the shout executor, reset or revert `main`
itself, or carry on with `toy-greet-polite`'s stop 4 and merge.

- [ ] **Step 15 (`skill-test`): S7, Quartz is not connected when a spec is approved.**

Situation:

```text
You are the orchestrator of the relay: you follow the `orchestrating` skill (its SKILL.md and the files beside it).
The repo is /work/toy. Its main checkout is on `main` and clean. `command -v quartz` prints /usr/local/bin/quartz;
`git config --get hyper-relay.quartz` prints nothing; the main checkout has no `.mcp.json`. Nothing about Quartz has
been said in this session. The generated agents exist (.claude/agents/toy-planner.md and the rest). The owner has
just approved the written spec docs/superpowers/specs/2026-11-18-toy-bye-design.md (one plan, no `**Plans:**` line),
committed on `main`. What do you do next, in order? Give the commands, the dispatches and your next message,
verbatim.
```

GREEN must: dispatch the planner (`toy-planner`) in the background first, its prompt saying the repo does not use
Quartz ("Run no `quartz` command."), and only then send the setup message of `quartz.md` §2 as a message of its own,
while the planner works.

RED is expected to: send the setup message first and wait for the answer before dispatching the planner. (It may not
discriminate: D.3's probe (a) saw `main`'s text dispatch first.)

- [ ] **Step 16 (`skill-test`): S8, an executor gets a catch-up round.**

Situation:

```text
You are an executor: you follow the `executing-plans` skill. Your agent file adds: the full gates are `sh test.sh`,
whose last line must end `0 failed`. Your attribution lines are `Co-Authored-By: Claude <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_X`. You ran the plan
docs/superpowers/plans/2026-11-18-toy-farewells-loud.md in the mode `worktree`, in the checkout
/work/toy/.worktrees/toy-farewells-loud, on the branch `toy-farewells-loud`, and reported all its tasks done. The
orchestrator now resumes you with: "Catch-up round: your base `toy-farewells-bye` has merged into `main`, and `main`
has changes your branch lacks (another plan's merge). Merge `main` into your branch, rerun your full gates, and
report." What do you do? Give the commands, in order, and your report.
```

GREEN must: in its checkout on its branch, merge `main` into `toy-farewells-loud` with a message and its attribution
lines and no `Plan-Task:` trailer, resolve any conflict (or abort and report when both sides cannot hold), rerun
`sh test.sh`, and report the merge commit, the conflicts and the gate counts; merge nothing into `main` and push
nothing.

RED is expected to: refuse: `executing-plans` forbids every merge ("Switch branches, stash, reset, rebase, merge, push
or tag"), so it stops and reports that it may not merge.

- [ ] **Step 17 (`skill-test`): S9, a planner gets a spec whose plan 2 builds on plan 1 and changes a skill.**

Situation:

```text
You are a planner: you follow the `writing-plans` skill. The dispatch: write plan 2 of the spec
docs/superpowers/specs/2026-11-18-toy-counter-design.md, at docs/superpowers/plans/2026-11-18-toy-counter-text.md,
on the branch `toy-counter-text`. Plan 1, docs/superpowers/plans/2026-11-18-toy-counter-script.md, is committed on
`main`; it adds the script skills/counter/scripts/count.sh. The spec has `**Plans:** 2`, and its plans list says:
"1. Plan 1, the script (`-script`): builds on nothing. 2. Plan 2, the skill text (`-text`): builds on plan 1; it
changes skills/counter/SKILL.md so that an agent asked how many lines a file has runs scripts/count.sh instead of
`wc -l`." Its pressure scenario P1: "An agent with the new text, asked 'how many lines does notes.txt have?', runs
skills/counter/scripts/count.sh notes.txt; with today's text it runs `wc -l notes.txt`." Write only the plan's header,
down to its first `---`, and the list of its acceptance task's steps, one line each, with each step's marker and what
it checks.
```

GREEN must: put `**Builds on:** docs/superpowers/plans/2026-11-18-toy-counter-script.md` in the header (with its
`**Spec:**` line), and give the acceptance task a `skill-test` step for P1 with its situation, what GREEN must do (run
`count.sh`) and what RED is expected to do (`wc -l`).

RED is expected to: write neither: no `**Builds on:**` line, and only `reviewer`, `owner` and `after merge` steps.

- [ ] **Step 18 (`owner`): Read the parallel rules and the merge.** Read
  `git -C /home/noob_master/hyper-relay show hyper-relay-d2-parallel-skills:skills/orchestrating/parallel.md`, and §4
  of the same branch's `skills/orchestrating/reviewing.md` (the merge and its exit codes). PASS: the owner agrees with
  them as written, including P7's undo commands (if not, the orchestrator records the change and it goes to the
  executor as a finding).

- [ ] **Step 19 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-d2-parallel-skills` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging. The merge itself runs as the installed relay
says (P24); the owner may choose `relay-merge` instead, from the main checkout on `main`:
`PUSH=0 RELAY_MERGE_TRAILERS='<the committing session's attribution lines>' relay-merge hyper-relay-d2-parallel-skills`.

- [ ] **Step 20 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `26 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh` (last line) | `153 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/relay-merge/run-tests.sh` (last line) | ends `0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |

- [ ] **Step 21 (`after merge`): The release, 0.2.0 (spec §9; D2.11; P21).** The owner has approved this push. In
  order, one command per Bash call:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay show main:.claude-plugin/plugin.json` | holds `"version": "0.1.0"` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh 0.2.0` | exit 0; the lines `package.json (version) … 0.1.0 -> 0.2.0` and `.claude-plugin/plugin.json (version) … 0.1.0 -> 0.2.0`, then its audit (an "UNDECLARED files containing '0.2.0'" list naming `README.md` and files under `docs/superpowers/` is expected, P20) |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v0.2.0" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag -a v0.2.0 -m "hyper-relay 0.2.0: several plans at once"
git -C /home/noob_master/hyper-relay push origin main
git -C /home/noob_master/hyper-relay push origin v0.2.0
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v0.2.0` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v0.2.0` | one line |

- [ ] **Step 22 (`after merge`): The owner updates and reloads (spec §10 item 1; P22, P25).** The owner runs, in a
  shell:

```bash
claude plugin update hyper-relay@hyper-relay
```

PASS: it updates hyper-relay to 0.2.0. If it prints `hyper-relay is already at the latest version (0.1.0).`, the
owner runs `claude plugin marketplace update hyper-relay`, then the update again, and the record says so (README's
update line then needs a fix: a proposed card).

Then the owner runs `/reload-plugins` in the orchestrator's running session. PASS: a `Reloaded: …` summary line. Then
the orchestrator invokes `hyper-relay:orchestrating` with the Skill tool. PASS: its "Base directory for this skill:"
line ends `hyper-relay/0.2.0/skills/orchestrating`. If it still names `0.1.0`, record that; the owner starts a new
session, where the same check must pass.

| Run | PASS |
|---|---|
| `git -C /home/noob_master/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD`, then `git -C /home/noob_master/hyper-relay rev-parse main` | the same SHA |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.0/skills/orchestrating/parallel.md && echo parallel` | `parallel` |
| `test -x /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.0/bin/relay-merge && echo relay-merge` | `relay-merge` |
| `grep -c -F 'finishing-a-development-branch' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.0/skills/orchestrating/reviewing.md` | `0` |

If a check fails, stop and tell the owner; do not delete or uninstall anything.

- [ ] **Step 23 (`after merge`): This repo's agents, regenerated (spec §10 item 2).**

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents` | `written .claude/agents/relay-executor.md` (the template changed); each other file `written` or `unchanged`; the restart line last; exit 0 |
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check` | nothing, exit 0 |

The new executor definition loads in a new session.

- [ ] **Step 24 (`after merge`): Build the probe repos (spec §10 item 3; P23).** For each `<dir>` of
  `/tmp/hr-d2-probe-parallel` and `/tmp/hr-d2-probe-conflict`:

```bash
git init -q -b main <dir>
```

With the Write tool, these eight files in each `<dir>`. `CLAUDE.md`:

```markdown
# Toy

A throwaway repo for probing hyper-relay's orchestrating skill. POSIX sh. Test: `sh test.sh`, which runs the checks
in every `tests/*.sh`. Each script's checks live in their own file, `tests/<script>.sh`; `test.sh` itself never
changes.
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
# test.sh: the toy's tests. Each tests/<script>.sh adds its checks with check().
p=0
f=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then p=$((p + 1)); else f=$((f + 1)); printf 'FAIL %s: [%s]\n' "$1" "$3"; fi
}
for t in tests/*.sh; do
    . "./$t"
done
printf '%d passed, %d failed\n' "$p" "$f"
[ "$f" -eq 0 ]
```

`tests/greet.sh`:

```sh
# tests/greet.sh: greet.sh's checks, sourced by test.sh.
check greet "Hello, Ada!" "$(sh greet.sh Ada)"
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

`.hyper-relay/merge.conf`:

```text
# prefix  kind  command (run with sh -c from the repo's top)
.         test  sh test.sh
```

**`/tmp/hr-d2-probe-parallel` only** (probe (a)), with the Write tool,
`docs/superpowers/specs/2026-11-18-toy-farewells-design.md`:

```markdown
# Toy farewells (design)

**Status:** approved by the owner.
**Plans:** 3

## Goal

Two new scripts beside `greet.sh`, and a flag for one of them.

## The plans

1. **Plan 1, `bye.sh`** (suffix `-bye`): builds on nothing.
2. **Plan 2, `shout.sh`** (suffix `-shout`): builds on nothing.
3. **Plan 3, `bye.sh --loud`** (suffix `-loud`): builds on plan 1.

## Design

- **Plan 1:** `bye.sh NAME` prints `Bye, NAME!` (`printf 'Bye, %s!\n' "$1"`). Its check goes in a new `tests/bye.sh`.
- **Plan 2:** `shout.sh NAME` prints `HEY, NAME!` (`printf 'HEY, %s!\n' "$1"`). Its check goes in a new
  `tests/shout.sh`.
- **Plan 3:** `bye.sh --loud NAME` prints `BYE, NAME!` (the name as given); without the flag, `bye.sh` is unchanged.
  Its check goes in `tests/bye.sh`.
- `test.sh` does not change: it runs every `tests/*.sh`.

## Testing and acceptance

- After each plan, `sh test.sh` ends `0 failed`; once all three have merged it prints `4 passed, 0 failed`.
- `sh bye.sh Ada` prints `Bye, Ada!`; `sh shout.sh Ada` prints `HEY, Ada!`; `sh bye.sh --loud Ada` prints
  `BYE, Ada!`.

Each plan's checks are `reviewer` steps of its acceptance task. Nothing is left for after the merge.
```

**`/tmp/hr-d2-probe-conflict` only** (probe (b)), with the Write tool,
`docs/superpowers/specs/2026-11-18-toy-greet-polite-design.md`:

```markdown
# Toy greet polite (design)

**Status:** approved by the owner.

## Goal

`greet.sh NAME` prints `Good day, NAME!` instead of `Hello, NAME!`.

## Testing and acceptance

`sh test.sh` prints `1 passed, 0 failed`, with `tests/greet.sh` expecting `Good day, Ada!`. A `reviewer` step.
```

and `docs/superpowers/specs/2026-11-18-toy-greet-loud-design.md`:

```markdown
# Toy greet loud (design)

**Status:** approved by the owner.

## Goal

`greet.sh --loud NAME` prints the greeting in capitals; without the flag, `greet.sh` is unchanged.

## Testing and acceptance

`sh greet.sh --loud Ada` prints `HELLO, ADA!`, checked by a new `tests/greet-loud.sh`. A `reviewer` step.
```

Then, in each `<dir>` (with its own spec files):

```bash
git -C <dir> add CLAUDE.md README.md greet.sh test.sh tests/greet.sh .gitignore .hyper-relay/agents.md .hyper-relay/merge.conf docs/superpowers/specs
git -C <dir> commit -q -m "chore: toy repo and its spec"
git -C <dir> config hyper-relay.quartz off
cd <dir> && /home/noob_master/hyper-relay/bin/hyper-relay-agents
```

PASS (the generator, in each): `written .claude/agents/toy-planner.md`, `written .claude/agents/toy-executor.md`,
`written .claude/agents/toy-reviewer.md`, `written .claude/hooks/hyper-relay-planner-guard.py`, the restart line last;
exit 0. And `cd <dir> && sh test.sh` prints `1 passed, 0 failed` in each.

**`/tmp/hr-d2-probe-conflict` only: the two plans, and the first one in flight.** Write the plans with these commands,
as they stand: their lines are quoted arguments, so none of them starts with `### Task` or `- [ ]` in this plan, where
the hand-back check and Quartz's ticks would read them as this plan's own.

```bash
mkdir -p /tmp/hr-d2-probe-conflict/docs/superpowers/plans
printf '%s\n' \
    '# Toy greet polite Implementation Plan' \
    '' \
    '**Spec:** `docs/superpowers/specs/2026-11-18-toy-greet-polite-design.md`' \
    '' \
    '> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans. Tasks 1 and 2 are the executor'"'"'s.' \
    '> Task 3 is the acceptance task: its step is a `reviewer` step.' \
    '' \
    '**Goal:** `greet.sh NAME` prints `Good day, NAME!`.' \
    '' \
    '## Spec coverage' \
    '' \
    '| Spec section | Tasks |' \
    '|---|---|' \
    '| Goal | 1, 2 |' \
    '| Testing and acceptance | 2, 3 |' \
    '' \
    '### Task 1: greet.sh' \
    '' \
    '**Files:**' \
    '- Modify: `greet.sh`' \
    '' \
    '- [ ] **Step 1:** In `greet.sh`, print `Good day, %s!` instead of `Hello, %s!`. Commit, with the trailer' \
    '  `Plan-Task: docs/superpowers/plans/2026-11-18-toy-greet-polite.md#1`.' \
    '' \
    '### Task 2: its check' \
    '' \
    '**Files:**' \
    '- Modify: `tests/greet.sh`' \
    '' \
    '- [ ] **Step 1:** In `tests/greet.sh`, expect `Good day, Ada!`. `sh test.sh` prints `1 passed, 0 failed`. Commit,' \
    '  with the trailer `Plan-Task: docs/superpowers/plans/2026-11-18-toy-greet-polite.md#2`.' \
    '' \
    '### Task 3: Acceptance' \
    '' \
    '- [ ] **Step 1 (`reviewer`):** `sh test.sh` prints `1 passed, 0 failed`.' \
    > /tmp/hr-d2-probe-conflict/docs/superpowers/plans/2026-11-18-toy-greet-polite.md
```

```bash
printf '%s\n' \
    '# Toy greet loud Implementation Plan' \
    '' \
    '**Spec:** `docs/superpowers/specs/2026-11-18-toy-greet-loud-design.md`' \
    '' \
    '> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans. Task 1 is the executor'"'"'s. Task 2' \
    '> is the acceptance task: its step is a `reviewer` step.' \
    '' \
    '**Goal:** `greet.sh --loud NAME` prints the greeting in capitals.' \
    '' \
    '## Spec coverage' \
    '' \
    '| Spec section | Tasks |' \
    '|---|---|' \
    '| Goal | 1 |' \
    '| Testing and acceptance | 1, 2 |' \
    '' \
    '### Task 1: greet.sh --loud' \
    '' \
    '**Files:**' \
    '- Modify: `greet.sh`' \
    '- Create: `tests/greet-loud.sh`' \
    '' \
    '- [ ] **Step 1:** `greet.sh --loud NAME` prints `HELLO, NAME!` in capitals; `tests/greet-loud.sh` checks' \
    '  `sh greet.sh --loud Ada`. Commit, with the trailer `Plan-Task: docs/superpowers/plans/2026-11-18-toy-greet-loud.md#1`.' \
    '' \
    '### Task 2: Acceptance' \
    '' \
    '- [ ] **Step 1 (`reviewer`):** `sh greet.sh --loud Ada` prints `HELLO, ADA!`.' \
    > /tmp/hr-d2-probe-conflict/docs/superpowers/plans/2026-11-18-toy-greet-loud.md
```

```bash
git -C /tmp/hr-d2-probe-conflict add docs/superpowers/plans/2026-11-18-toy-greet-polite.md docs/superpowers/plans/2026-11-18-toy-greet-loud.md
git -C /tmp/hr-d2-probe-conflict commit -q -m "docs: toy greet plans"
git -C /tmp/hr-d2-probe-conflict worktree add -q .worktrees/toy-greet-polite -b toy-greet-polite main
```

With the Write tool, `/tmp/hr-d2-probe-conflict/.worktrees/toy-greet-polite/greet.sh`:

```sh
#!/bin/sh
# greet.sh NAME: prints a greeting.
printf 'Good day, %s!\n' "$1"
```

```bash
git -C /tmp/hr-d2-probe-conflict/.worktrees/toy-greet-polite add greet.sh
git -C /tmp/hr-d2-probe-conflict/.worktrees/toy-greet-polite commit -q -m "feat: greet.sh says good day" -m "Plan-Task: docs/superpowers/plans/2026-11-18-toy-greet-polite.md#1"
```

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d2-probe-conflict worktree list` | two lines: the main checkout on `[main]`, `.worktrees/toy-greet-polite` on `[toy-greet-polite]` |
| `git -C /tmp/hr-d2-probe-conflict diff --name-only main...toy-greet-polite` | `greet.sh` |
| `git -C /tmp/hr-d2-probe-conflict branch --show-current` | `main` |
| `git -C /tmp/hr-d2-probe-parallel config --get hyper-relay.quartz` and the same for `/tmp/hr-d2-probe-conflict` | `off`, twice |

- [ ] **Step 25 (`after merge`): The live probes (spec §10 item 3).** Each is a new Claude Code session, started by the
  owner after Step 22, in its repo, accepting the trust prompt. The owner watches the session; the orchestrator runs
  the git rows afterwards.

**(a) Parallel and stacked.** The owner runs `cd /tmp/hr-d2-probe-parallel && claude` and sends:

> The spec docs/superpowers/specs/2026-11-18-toy-farewells-design.md is approved.

PASS, in order:
1. No Quartz setup message (the repo is declined). The planners of plans 1 and 2 are dispatched together; plan 3's
   planner only once plan 1's plan is committed.
2. One stop 3 for all three plans, questions first; its handoff question has a line per plan, all in worktrees (no
   Branch offer, although the toy's default is `branch`), plan 3 stacked on plan 1, and no overlap line. The owner
   answers `OK`.
3. Plans 1 and 2 start at once: while their executors run, `git -C /tmp/hr-d2-probe-parallel worktree list` shows
   `.worktrees/toy-farewells-bye` and `.worktrees/toy-farewells-shout` beside the main checkout.
4. Plan 3's worktree appears only after plan 1's acceptance has passed, cut from `toy-farewells-bye`; plan 3's review
   legs start only after plan 1 has merged.
5. At each stop 4 the owner answers `merge` (or `merge both`, when one stop 4 covers two plans). Each merge is a Bash
   call to `relay-merge` with `PUSH=0`; no merge runs before its plan's stop 4 is answered.
6. After plan 3's merge, the owner ends the session.

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d2-probe-parallel branch --show-current` | `main` |
| `cd /tmp/hr-d2-probe-parallel && sh test.sh` | `4 passed, 0 failed` |
| `cd /tmp/hr-d2-probe-parallel && sh bye.sh --loud Ada` | `BYE, Ada!` |
| `git -C /tmp/hr-d2-probe-parallel log --first-parent --merges --format=%s main` | three lines, newest first: `Merge branch 'toy-farewells-loud'` above `Merge branch 'toy-farewells-bye'`, and `Merge branch 'toy-farewells-shout'` anywhere |
| `git -C /tmp/hr-d2-probe-parallel log --first-parent --merges --format='%h %(trailers:key=Co-Authored-By,valueonly,separator=%x2C)' main` | three lines, each with a value after its hash (the orchestrator's `RELAY_MERGE_TRAILERS`) |
| `git -C /tmp/hr-d2-probe-parallel log --first-parent --merges --format=%h --grep=toy-farewells-loud main` | one hash, below called `<M>` |
| `git -C /tmp/hr-d2-probe-parallel log --first-parent --format='%(trailers:key=Plan-Task,valueonly)' <M>^2` | the `-toy-farewells-loud.md#` trailers, then, below them, `-toy-farewells-bye.md#` ones: plan 3's branch was cut from plan 1's |
| `git -C /tmp/hr-d2-probe-parallel worktree list` | one line, the main checkout |
| `git -C /tmp/hr-d2-probe-parallel branch --list 'toy-farewells-*'` | nothing |
| `grep -c -E '^- \[ \]' /tmp/hr-d2-probe-parallel/docs/superpowers/plans/*.md` | `:0` for each of the three plans (D.3's hand ticks in a declined repo; the pattern skips the header's "checkbox (`- [ ]`)" line, the lesson of D.3's record) |

**(b) Conflict.** The owner runs `cd /tmp/hr-d2-probe-conflict && claude` and sends:

> The plan docs/superpowers/plans/2026-11-18-toy-greet-loud.md is approved. Hand it off.

If the session first asks whether `toy-greet-polite`'s executor is still running, the owner answers
`Yes, it is still running in its worktree.` PASS: the handoff question names `greet.sh` as shared with
`toy-greet-polite`, which is in flight; says the loud plan waits for it to merge; offers "run them at once anyway";
and offers no Branch. The owner ends the session there.

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d2-probe-conflict worktree list` | still the two lines of Step 24 |
| `git -C /tmp/hr-d2-probe-conflict branch --list toy-greet-loud` | nothing |

- [ ] **Step 26 (`after merge`): Clean up; anything failed?**

```bash
rm -rf /tmp/hr-d2-probe-parallel /tmp/hr-d2-probe-conflict
```

A failed step: fix it on a branch through the usual spec and plan, merge, release the next patch version (D2.11),
update, and repeat the step.

- [ ] **Step 27 (`after merge`): Record.** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 9)

- **Before the merge:** acceptance reviewer <verdict line>; fix rounds <n, what each changed>; code review: Critical
  <fixed / dropped, why>, proposed cards <kept / dropped>; token counts: executor <n>, acceptance reviewer <n>, code
  reviewer <n>.
- **Skill tests (by hand):** GREEN <n>/9 PASS; RED failed as expected in <n>; each RED that did not fail: <which>;
  the runs' output tokens <n>; fix rounds <n>.
- **Owner steps:** Step 18 <agreed / what changed>; Step 19 merge-tree <exit>. Merged in <hash>, by <the installed
  relay's merge / relay-merge>.
- **Release, <date>:** `chore: release v0.2.0` at <hash>; tag `v0.2.0` pushed: <yes/no>.
- **Update, <date>:** `claude plugin update` said <its line>; <marketplace refresh needed: yes/no>; `/reload-plugins`
  <loaded 0.2.0 / needed a new session>; marketplace clone at <SHA>; `parallel.md` and `bin/relay-merge` in the 0.2.0
  cache: <yes/no>.
- **Agents:** <the generator's lines>.
- **Probes:** (a) <pass/fail, anything it did differently, its agents' tokens>; (b) <pass/fail>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 9 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece D.2 plan 2 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md#9
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md
```

Push it with the next change of `main` (the owner's call).
