# hyper-relay D.2: several plans at once (design)

**Date:** 2026-11-18 · **Status:** design approved by the owner in chat on 2026-11-18
**Card:** Several plans at once: conflicts, stacking, the preview stack (`68fab05e-4083-41bf-820f-8c201a951c50`)
**Initiative:** v0.1.0 · **Piece:** D.2 · **Depends on:** D1 (merged `fd0a928`), E (merged `cbc143c`), D.3 (merged
`3faf926`)
**Plans:** 2
**Scope:** this repo: a new `bin/relay-merge` with its tests and docs (Plan 1); `skills/orchestrating/` (a new
`parallel.md`; `SKILL.md`, `planning.md`, `dispatching.md`, `reviewing.md`, `quartz.md`), `executing-plans`, the
executor template, `brainstorming`, `writing-plans`, the relay guard test and `README.md` (Plan 2); then the release of
0.2.0.

## Goal

D1's relay runs a spec's plans one after another, and a second plan runs only beside a branch run, where it cannot
merge until that run does (the card's note `620d8b8f`). D.2 lets several plans run at once: each in its own worktree,
after a conflict check, with a dependent plan stacked on the one it builds on, and every landing done by one merge
helper that gates the merged result. It also makes skill tests a standing leg of the relay, stops Quartz setup from
holding up a leg, and releases the result as 0.2.0, so later changes reach the owner by an update and a reload instead
of a reinstall.

## Decisions (owner, 2026-11-18)

| # | Question | Decision |
|---|---|---|
| D2.1 | Scope | **Several plans at once, with conflict checks, stacking and a merge helper.** The preview stack (several branches combined for one click-through) gets its own card. |
| D2.2 | Branch or worktree when plans run together | **All worktrees whenever more than one plan is in flight.** Branch is offered only for a plan that will run alone, so the main checkout stays on `main` and any finished run can merge. This answers the card's note `620d8b8f`. |
| D2.3 | Who merges | **Every relay merge goes through a new `bin/relay-merge`,** ported from the general parts of SAT's `merge-branches.sh`. |
| D2.4 | Overlapping plans | **They serialize, and the owner can override.** Shared files: the later plan waits, or is stacked if it builds on the earlier. Numbered names: the later plan's planner renumbers. An override is settled at the merge. |
| D2.5 | When a stacked plan starts | **After its base passes acceptance.** It is cut from the base's branch; its review legs wait for the base's merge. |
| D2.6 | Shape | **Approach A: two plans.** Plan 1 the helper, Plan 2 the skills, with a new `orchestrating/parallel.md` read only when more than one plan is in flight. Their contract is the helper's command line, exit codes and config. Rejected: `wt merge` with gates in `.wt.conf` (a repo with no stack would need one), and one plan spreading the parallel rules over every leg file. |
| D2.7 | Skill tests | **A standing relay leg** (owner, during D.3): `writing-skills`' RED/GREEN pressure tests, run by the orchestrator after acceptance, beside the code review, whenever the plan has `skill-test` steps. D.2's own run does it by hand, since Plan 2 adds the leg. |
| D2.8 | Quartz setup and the legs (D.3's probe (a), accepted by the owner) | **Setup never holds up a leg.** The leg's agent is dispatched first; the setup message follows while it works. Having no Quartz configured does not stop the work. |
| D2.9 | Where the exit codes are handled | **`reviewing.md` §4,** because a lone plan's merge needs them too. `parallel.md` §4 keeps the landing order. |
| D2.10 | D.2's own two plans (owner, at stop 2) | **Planners at once, executors in sequence.** Both planners run on `main`: they only read code and commit their own plans. Then Plan 1 runs, lands, and its tests pass on `main`; only then does Plan 2's executor start, from the new `main`. `CLAUDE.md` is all Plan 1's and `README.md` all Plan 2's. |
| D2.11 | Releases | **After both plans merge, the version goes to 0.2.0** (tag `v0.2.0`, pushed). From then on every merge that changes what the plugin ships raises the version, the patch number unless the owner names another (0.2.1 next; owner, at stop 2), so the owner updates with `claude plugin update` and `/reload-plugins` instead of reinstalling. This replaces the 2026-11-17 rule "0.1.0 until the initiative is finished". |

## The plans

1. **Plan 1, `relay-merge`:** `docs/superpowers/plans/2026-11-18-hyper-relay-d2-relay-merge.md`. Builds on nothing.
2. **Plan 2, the skills:** `docs/superpowers/plans/2026-11-18-hyper-relay-d2-parallel-skills.md`. Builds on nothing:
   it depends only on Plan 1's contract (§1), which this spec fixes. It executes after Plan 1 has landed (D2.10).

| Plan | Creates | Modifies |
|---|---|---|
| 1 | `bin/relay-merge`, `tests/relay-merge/run-tests.sh` (and its fake `wt`), `docs/relay-merge.md`, `.hyper-relay/merge.conf` | `CLAUDE.md`, `.hyper-relay/agents.md` |
| 2 | `skills/orchestrating/parallel.md` | `skills/orchestrating/{SKILL,planning,dispatching,reviewing,quartz}.md`, `skills/executing-plans/SKILL.md`, `templates/agents/executor.md`, `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, `tests/orchestrating/run-tests.sh`, `README.md` |

## 1. `bin/relay-merge` (Plan 1)

POSIX sh run by dash, like `wt`. **Usage:** `relay-merge <branch>...`, from the main checkout on `main`. It lands each
branch in the order given and stops at the first failure.

**For each branch:**

1. **Checks,** which refuse before anything changes:
   - it runs in the main checkout, not a worktree; that checkout is on `main`, with no merge in progress;
   - no uncommitted tracked changes under the paths the gates watch (anywhere, when the repo has no config);
   - the branch exists;
   - the branch's worktree, if it has one, is clean and has no `wt` stack up (`wt ls`, when `wt` is on `PATH`).
2. **Already in `main`:** skipped; it still counts as landed.
3. **Merge:** `git merge --no-ff`, so every landing leaves a merge commit naming its branch. The message is
   `Merge branch '<branch>'`, followed by the lines in `RELAY_MERGE_TRAILERS`, if set: the orchestrator passes its
   attribution lines there (SAT's script wrote a fixed session URL instead). On a conflict: `git merge --abort`, and
   `main` is unchanged.
4. **Gates on the merged result:** every config line whose path prefix matches a file the branch changed. Output goes
   to a log under `${XDG_STATE_HOME:-$HOME/.local/state}/relay-merge/`. A failed gate stops everything: the merge stays
   on `main`, unpushed, never reset, and the log's last 20 lines are printed.

**After every branch is in:**

- **Push:** `PUSH=1` pushes, `PUSH=0` does not, otherwise it asks on a terminal; with no terminal the answer is no.
- **Cleanup:** unless `KEEP=1`, `git worktree remove` and `git branch -d`, the forms git refuses for anything
  unmerged.

**Exit codes, the contract with Plan 2:**

| Code | Meaning |
|---|---|
| 0 | every branch landed |
| 1 | refused by a check; that branch did not change `main` |
| 2 | merge conflict; aborted, `main` unchanged for that branch |
| 3 | a gate failed; the merge is on `main`, unpushed |

Branches earlier in the list that landed stay landed. A failed push or cleanup only prints a warning.

**`.hyper-relay/merge.conf`,** committed per repo. One gate per line; `#` starts a comment:

```
# prefix  kind   command (run with sh -c from the repo's top)
api/      build  cd api && go build ./...
api/      test   cd api && go test ./...
.         test   sh tests/wt/run-tests.sh
```

`.` matches any change. `SKIP_TESTS=1` skips the `test` lines. The commands are read from `main`'s committed file, so
they are as trusted as `main`. With no config, it lands without gates and says so. This repo's own file maps its paths
to its suites (the Checks table in `CLAUDE.md`).

**What stays SAT's:** its repo-name check, its redeploy offer and its log folder. Switching SAT's `make merge` to call
`relay-merge` is SAT's own change, in SAT's own relay, not part of this spec.

**On `PATH`:** Claude Code puts the plugin's `bin/` on the Bash tool's `PATH`, so skills call it by name. In the
owner's shell (and OpenCode's), `~/.local/bin/relay-merge` is a symlink to this main checkout's `bin/relay-merge`, the
way `wt` has one.

**Tests:** `tests/relay-merge/run-tests.sh`, on temporary git repos with a fake `wt`: each exit code; the skip of an
already-merged branch; several branches, stopping at the first failure with the earlier ones landed; prefix matching
and `.`; `SKIP_TESTS`, `KEEP`, `PUSH=0`; no terminal means no push; a `--no-ff` merge commit carrying the
`RELAY_MERGE_TRAILERS` lines.

**Docs:** `docs/relay-merge.md`, the user reference (like `docs/wt.md`). `CLAUDE.md` gains `bin/relay-merge`,
`docs/relay-merge.md` and `tests/relay-merge/` in its Layout, and a Checks row: `sh tests/relay-merge/run-tests.sh`,
expect `0 failed`.

## 2. `parallel.md` §1: what runs at once (Plan 2)

`skills/orchestrating/parallel.md` is read at a handoff while another plan is still in flight (a branch or worktree
whose executor work has not merged), or when a spec has more than one plan. A single plan with nothing else running
never reads it, so that path does not change.

- **A spec's plans:** every plan without a `**Builds on:**` line can be dispatched at once, in the spec's order. A
  plan with one is stacked (§5 below).
- **Plans from different specs** run at once whenever the owner starts them.
- **All worktrees** (D2.2): when two or more plans would be in flight, each runs in a worktree. If a branch run is
  already active when a second plan starts, that plan runs in a worktree, and its stop 4 says "merges after
  `<branch>`".
- **No background agents** (a harness that waits for each subagent): every rule still holds; the plans run in turn.

## 3. `parallel.md` §2: the conflict check (Plan 2)

Before each dispatch that joins another plan in flight:

- **Shared files:** the plan's paths come from its tasks' `- Create:`, `- Modify:` and `- Test:` lines, without any
  `:lines` part. They are compared with each in-flight plan's paths and with what its branch has changed so far
  (`git diff --name-only main...<branch>`). A path in both is an overlap.
- **Numbered names:** two plans create files in the same folder whose names start with the same digits (`000097_*`).

**What happens.** "Later" means dispatched later, or later in the spec's order for a spec's own plans.

- With shared files, the later plan waits until the earlier one merges, or is stacked on it if it builds on it.
- With a numbered collision, the later plan goes back to its planner to renumber above the other plan's highest number
  before dispatch.
- Both kinds of overlap appear in the handoff question, one line each. The owner may say "run them at once anyway":
  the orchestrator records that as a deviation, and a conflict is settled at the merge (§6, exit 2).

## 4. Planning several plans (`parallel.md` §1, Plan 2)

A spec's planners all run at once, except a stacked plan's: it is dispatched once its base's plan is committed, and
plans against the files as the base plan leaves them. All of a spec's plans share one stop 3, with a handoff line per
plan. This replaces `planning.md` §4's "one after another, each after the last merges".

## 5. `parallel.md` §3: stacking (Plan 2)

A stacked plan's header carries `**Builds on:** <base plan path>`. A plan builds on exactly one plan; in a chain (C on
S on B) each link follows the same rules. A `**Builds on:**` line whose base has already merged changes nothing: the
plan runs from `main`.

- **Cut:** when the base passes acceptance, the stacked plan's worktree is cut from the base's branch:
  `git worktree add .worktrees/<S> -b <S> <B>`, or `wt new <S> --from <B>` in a repo with `.wt.conf`. Then its executor
  starts; it runs while the base goes through its code review and stop 4.
- **Catch up:** the stacked plan's review legs (the hand-back check, acceptance, code review) wait until its base has
  merged. Then, if `main` has commits its branch lacks (the base's code-review fixes, other plans' merges), its
  executor first merges `main` in and reruns its gates: a catch-up round, which is not a fix round. Acceptance and the
  code review then see the plan on top of the final `main`, and the review range holds only its own work.
- **Base dropped or stuck:** if the owner drops the base, or its merge fails and is not recovered, the stacked plan
  stops and goes to the owner. It cannot land without its base.

## 6. Landing: `parallel.md` §4 and `reviewing.md` §4 (Plan 2)

Every merge runs `relay-merge` from the main checkout on `main`, with `PUSH=0` (pushing stays the owner's call) and
`RELAY_MERGE_TRAILERS` set to the orchestrator's attribution lines. After a branch run, the orchestrator first switches
the main checkout back with `git switch main`. When the worktree has a `wt` stack up, it runs
`(cd <worktree> && wt down)` first.

**Exit codes** (`reviewing.md` §4, D2.9):

| Exit | The orchestrator |
|---|---|
| 0 | goes to `reviewing.md` §5 for each plan that landed |
| 1 | fixes the cause when it is its own (a `wt` stack still up); otherwise brings the owner the check's message |
| 2 | sends the branch's executor a conflict round: merge `main` in, resolve, rerun the gates, as a fix round. Then a short stop 4 again (the conflict, how it was resolved, the gates), since the code changed after review |
| 3 | stops and brings the owner the log's tail at once. Nothing else lands until the owner decides: undo the unpushed merge, or fix forward on a new branch. Plans in flight keep executing in their worktrees |

**Order** (`parallel.md` §4):

- Each plan lands after its own stop 4; a stacked plan always after its base (§5 guarantees it).
- When a second plan reaches stop 4 before the owner has answered the first's, one stop-4 message covers both, and
  `relay-merge A B` lands them in the order they arrived.
- After each landing, plans still in flight do not catch up on their own: the conflict check kept their files apart,
  and their own `relay-merge` reruns the gates on the merged result. A plan stacked on the one that landed now starts
  its review legs (§5).

## 7. The other files (Plan 2)

- **`orchestrating/SKILL.md`:** lists `parallel.md` beside the leg files, read whenever a second plan would be in
  flight or a spec has several plans; its state table gains a row: a stacked plan's branch whose base has not merged
  waits for it (`parallel.md` §3).
- **`planning.md` §4 "Several plans":** points to `parallel.md` for running them (§4 above).
- **`dispatching.md`:**
  - §1: Branch is offered only for a plan that will run alone; the conflict check's overlap lines go into the handoff
    question.
  - §3: a worktree is cut from `main`, or from the base's branch for a stacked plan; in a repo with `.wt.conf`, with
    `wt new <branch> --from <base>`. The hard-coded `.git/info/exclude` becomes the file
    `git rev-parse --git-path info/exclude` prints (D.3's D3.10 fix, here too).
- **`reviewing.md`:** §4's merge runs `relay-merge` instead of `finishing-a-development-branch`, with the exit-code
  table (§6); the skill-test leg (§8), and stop 4 waits for its notifications too.
- **`quartz.md` §2** (D2.8): the setup message no longer waits for its answer before the leg goes on. The leg's agent
  is dispatched first, and setup runs with the owner while it works.
- **`executing-plans/SKILL.md` and `templates/agents/executor.md`:** the executor still never merges its branch into
  anything; when the dispatch asks for a catch-up or conflict round, it merges `main` (or its base) into its own
  branch and reruns its gates. Today both ban every merge.
- **`brainstorming/SKILL.md`:** a spec with `**Plans:** n` lists its plans in order, each with its subject and the
  plan it builds on, if any (as this spec's "The plans" does). A spec that changes a skill names its pressure
  scenarios.
- **`writing-plans/SKILL.md`:** writes `**Builds on:** <base plan path>` when the spec says so, and plans against the
  files as the base plan leaves them; renumbers when sent back for a numbered-name collision; a plan that creates or
  changes a file in a skill's folder adds `skill-test` steps to its acceptance task.
- **`tests/orchestrating/run-tests.sh`:** the folder holds `parallel.md` too, and no orchestrating file names
  `finishing-a-development-branch`.
- **`README.md`:** `relay-merge` and its doc; the relay section gains `parallel.md` and the skill-test leg; updating
  the plugin is `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` (D2.11).
- **Unchanged:** `finishing-a-development-branch` stays for work outside the relay.

## 8. The standing skill-test leg (Plan 2, `reviewing.md`)

- **When:** the plan's acceptance task has `skill-test` steps. `writing-plans` requires them in any plan that creates
  or changes a file in a skill's folder (a `SKILL.md`, or a file beside it that agents read).
- **A step** gives a situation, what GREEN must do, and what RED is expected to do, from the spec's scenarios.
- **Run:** after acceptance passes, at the same time as the code review. The orchestrator puts the skills from `main`
  and from the branch in two scratch folders and dispatches each scenario twice, on Sonnet in the background, with a
  standing preamble: read only that folder's skills, run no command, answer with the commands you would run and the
  next message, verbatim. RED reads `main`'s text, or no skill at all when the skill is new.
- **Verdicts:** a GREEN that fails is a fix round. A RED that does not fail means the scenario does not test the change:
  stop 4 says so, and it does not block. Stop 4 adds the verdicts and the runs' token counts.

## 9. The release (D2.11)

- **0.2.0:** once both plans have merged, on `main`: `scripts/bump-version.sh 0.2.0` (it sets `package.json` and
  `.claude-plugin/plugin.json`), a commit of just those two files, `chore: release v0.2.0`; tag `v0.2.0`; push `main`
  and the tag.
- **The owner updates** with `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in a running
  session (or starts a new one), instead of uninstalling and reinstalling.
- **From then on** (Plan 1, in `CLAUDE.md`'s "How a change reaches the owner" and the planner's facts in
  `.hyper-relay/agents.md`): every hyper-relay plan that changes what the plugin ships (anything outside `docs/` and
  `tests/`) ends its acceptance task with `after merge` steps that raise the version (the patch number unless the
  owner names another) with `scripts/bump-version.sh`, commit, tag and push it, then the owner's update and reload.

## 10. Testing and acceptance

**Plan 1 (executor gates):** `dash -n bin/relay-merge` silent; `sh tests/relay-merge/run-tests.sh` prints `0 failed`.
**`reviewer` steps,** on a scratch clone of this repo with its `merge.conf`: a branch touching `tests/wt/` lands with
exit 0, only the `wt` suite's gate runs, and the merge commit carries the trailers; a gate broken on purpose gives exit
3, with the merge left on `main`, unpushed. **After merge (the owner):** the `~/.local/bin/relay-merge` symlink;
`command -v relay-merge` prints it.

**Plan 2 (executor gates):** the guard test, the role-agent suites, `claude plugin validate .` (its three warnings).

**Plan 2's skill tests** (`skill-test` steps, run by hand by the orchestrator as in D.3; RED on `main`'s text, GREEN
on the branch's):

| # | Situation | GREEN |
|---|---|---|
| S1 | A spec's two independent plans are approved | both are dispatched at once, each in a worktree; Branch is not offered |
| S2 | A second plan shares `greet.sh` with one in flight | the handoff names the overlap, the plan waits, the override is offered |
| S3 | Two plans both create `000097_*` migrations | the later plan goes back to its planner to renumber |
| S4 | A stacked plan's base passes acceptance | its worktree is cut from the base's branch; its review legs wait for the base's merge |
| S5 | `relay-merge` exits 2 | the executor gets a conflict round, then a short stop 4 again |
| S6 | `relay-merge` exits 3 | it stops with the log's tail and asks: undo or fix forward; nothing else lands |
| S7 | Quartz is not connected when a spec is approved | the planner is dispatched first, the setup message follows |
| S8 | An executor gets a catch-up round | it merges `main` into its branch and reruns its gates |
| S9 | A planner gets a spec whose plan 2 builds on plan 1 and changes a skill | `**Builds on:**` in its header, `skill-test` steps in its acceptance task |

S7 may not discriminate: D.3's probe (a) showed `main`'s text already dispatching first. A RED that does not fail is
reported, not fixed.

**After both merges** (Plan 2's acceptance task, in order):

1. The release (§9), then the owner's `claude plugin update hyper-relay@hyper-relay` and `/reload-plugins`. PASS: the
   cache holds `hyper-relay/0.2.0/skills/orchestrating/parallel.md`, and a reloaded session's orchestrating skill reads
   from the `0.2.0` folder. If the reload does not load it, record that, and the owner starts a new session.
2. This repo's agents regenerated (`hyper-relay-agents`), for the executor template.
3. **Live probes,** in new sessions, on toy repos declined for Quartz (`git config hyper-relay.quartz off`), each with a
   `.hyper-relay/merge.conf` running its tests:
   - **(a) Parallel and stacked:** a spec with `**Plans:** 3`: `bye.sh`; an independent `shout.sh`; `bye.sh --loud`,
     which builds on plan 1. PASS: one stop 3; plans 1 and 2 run at once in worktrees; plan 3 is cut from plan 1's
     branch after plan 1's acceptance; each merge is a `--no-ff` commit made by `relay-merge`, plan 1 before plan 3;
     `main` passes its tests and the worktrees are gone.
   - **(b) Conflict:** a second spec whose plan edits `greet.sh` while a first plan that edits it is in flight. PASS:
     the handoff names the overlap and offers to wait. It ends there.
4. The record, as D.3's.

## 11. Running D.2 itself

Under today's skills (D2.10): both planners at once, on `main`; one stop 3 for both plans. Then Plan 1's executor,
review legs and merge, as today's skills run them, and the suites on the merged `main`. Only when they pass, Plan 2's
handoff, from the new `main`. Plan 2's after-merge steps (§10) follow its own merge.

## 12. Out of scope

- **The preview stack** (several branches combined for one click-through): its own card.
- **Merging a worktree without the main checkout** (`git merge-tree` + `update-ref`, from the card's note): not needed
  once every run beside another is a worktree (D2.2).
- **SAT switching to `relay-merge`:** SAT's own relay.
- **Automatic catch-up** of independent plans after each landing: their own `relay-merge` gates the merged result.
