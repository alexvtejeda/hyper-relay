# hyper-relay: a lighter orchestrator, the relay skills (plan 2 of 2), Implementation Plan

**Cards:** A lighter orchestrator context: clear any time, owner decisions on the board (`b43e3367-79eb-4289-a7dd-41edf35f95c2`), Suggest clearing context once a plan is fully written and there are no background subagents running (`6e189fac-9f3b-4f20-8fed-9a90c73c1478`)
**Spec:** `docs/superpowers/specs/2026-11-20-hyper-relay-lighter-orchestrator-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–6 are
> the executor's. Task 7 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** The relay's skills and role-agent templates make the board the record of where work stands (a status note at
every step, a decision note for every owner decision, no private state), run no check twice, have agents file
proposed cards and cap the fix rounds, and route the orchestrator by path: `relay-plan` answers its questions about a
plan, and agents write full reports to the plan's run folder and hand back short summaries.

**Architecture:** Skill and template text, plus checks in the relay guard. Task 1 changes `writing-plans` (fenced
whole situations, no `reviewer` gate step) and the plan reviewer's prompt. Task 2 changes `executing-plans` and the
executor template (gates through `relay-plan gate`, `executor.md`, the short summary, fix rounds, proposed cards).
Task 3 changes the two reviewer templates and `requesting-code-review` (the run folder, cards, short summaries).
Task 4 changes `orchestrating`'s `SKILL.md` and `quartz.md` (status and decision notes, finding where work stands,
read once per session, `relay-plan`) and `brainstorming` (decision notes). Task 5 changes `planning.md`,
`dispatching.md` and `parallel.md` (routing by path, the run folder, the hand-back check). Task 6 rewrites
`reviewing.md` (acceptance, the fix loop and its cap, the code review, the skill tests by file and judge, stop 4), adds
`fix-rounds` to the `agents` skill and the loop to `README.md`, and runs the full gates. Each task adds the guard checks
for its own text. Task 7 accepts it: four reviewer checks, fourteen RED/GREEN skill tests, the 0.2.7 release, the role
agents, the handoff memory retired, and a live probe.

**Tech Stack:** Markdown skills and agent templates; the relay guard (`tests/orchestrating/run-tests.sh`, POSIX shell
run by dash) and the generator's suites. Plan 1's `relay-plan` (on `main` and in the installed 0.2.6 before this plan
runs). For acceptance: Claude Code general-purpose subagents on Sonnet, `relay-plan`, the installed generator.

**How this was checked:** written against `main` at `8fd43cf`, by reading only (the spec, the files below, and the
newest plans for format); nothing was built, run, installed or generated. The spec flags no fact for re-check, so
none was re-checked. The plan makes no assumption: A1, written as one, was researched at stop 3 and is now a fact in
the spec's `## How it works` (`00b271c`).

---

## Execution notes (binding)

- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator
  are the installed plugin's (0.2.6). This plan rewrites the relay: follow your agent instructions and this plan, not
  the new text. Run your full gates as your installed skill says.
- **Plan 1 has landed first** (spec, The plans): `bin/relay-plan`, `docs/relay-plan.md` and the `fix-rounds` key are on
  `main`, released as 0.2.6. This plan's text names them; none of your tasks runs `relay-plan`. The two plans share no
  file.
- **Skill text is written exactly.** "Replace X with Y" means the Edit tool, X as `old_string`, Y as `new_string`.
  "Replace the lines from A through B with Y" means: read that range, then Edit with those exact lines as
  `old_string`. "Insert after (or before) the line L" means an Edit whose `old_string` is L. "Replace the file with
  exactly this content" means the Write tool, every line of the block, ending with one newline. A block's own fence
  lines are not part of the text; fences inside a four-backtick block are. Keep each line break as written: several
  checks grep for a phrase that must sit on one line. If an X or an anchor line is not found, read the range again; if
  it moved or differs slightly, adapt as little as possible and record a deviation; if it is gone, stop and report.
- **Do not run `bin/hyper-relay-agents` in this checkout.** It rewrites the gitignored `.claude/agents/` that this
  run's agents load. Its suite runs it in temporary repos; the real regeneration is Task 7's, after the release.
- **The guard is the contract, and this plan extends it.** `tests/orchestrating/run-tests.sh` keeps its thirteen
  checks and fifteen broken cases unchanged; each task adds the checks it names, after the last ones, in the file's
  style (a check is a subshell function taking a tree's top; `none` for "grep finds nothing"; a broken case is
  `broken "<what>"`, the mutation, `expect_fail <check>`). Both `tests/hyper-relay-agents/` suites change in nothing:
  needing to change one is a stop.
- Do not run `claude -p` or upstream's live suites (`tests/claude-code/`, `tests/explicit-skill-requests/`,
  `tests/skill-triggering/`).
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at `main`'s version (0.2.6);
  Task 7 releases 0.2.7 after the merge.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|`.
- The spec's project-wide values, verbatim:
  - "**The label.** A card filed by the relay without the owner asking for it carries the label `proposed`."
  - "`add_note` takes a body of at most 2000 characters, or 500 with `status: true`; a status replaces the card's
    previous status."
  - "`fix-rounds: <n>`, a whole number from 1 to 9; absent means 2."
  - "Each agent writes its full report to its file (Contract) and hands back only a short summary, at most about 15
    lines"
  - The judge's line: "`<id>: GREEN pass|fail, RED fails|does not fail: <reason, at most 15 words>`".
  - Anti-goals: "an agent writes anywhere but its own checkout, the plan's run folder and (for proposed cards) the
    board"; "the relay stops working in a repo without Quartz: every Quartz step keeps a plain-file fallback."
  - `CLAUDE.md`, Rules: no machine paths in skills; the guard's `no_machine_paths` forbids `/home/`, `~/`, `/Users/`
    and `/tmp/` under `skills/orchestrating/`.
- **The full gates** (Task 6 Step 6): `sh tests/orchestrating/run-tests.sh`, `sh tests/hyper-relay-agents/run-tests.sh`,
  `sh tests/hyper-relay-agents/guard-test.sh` and `claude plugin validate .`. `relay-merge`'s gates for this branch
  (`.hyper-relay/merge.conf`) are the `skills/`, `templates/`, `README.md` and `tests/orchestrating/` lines.
- **Task 7 is not yours.** After Task 6, report and stop.

## Review Focus

1. **A repo without Quartz, or with Quartz declined:** every new board step has its file (the plan's line in the run
   folder's `status`, decisions in `decisions.md` or the topic's `brainstorm.md`, cards in `cards.md`), and every
   dispatch prompt says "Run no Quartz command and use no Quartz tool." Task 4 Step 4 and Task 5 Step 4 assert the
   sentences.
2. **Two plans on one card** (a spec with `**Plans:** 2`, like this one): the status note reads the card's status
   first and keeps the other plan's line, within 500 characters. Task 4 Step 4.
3. **The check after a fix round, a catch-up or a conflict round:** `relay-plan gates` names the commands that round
   ran; naming none would fail on the full gates' older blocks. Task 5 Step 4 and Task 6 Step 5.
4. **A plan written before the fence rule, still in flight at the release:** `relay-plan scenarios` exits 1, and the
   orchestrator tells the owner instead of reading the steps. Task 6 Step 5.
5. **OpenCode, or a shell without `relay-plan`:** an agent's id in the status is its `sessionID`; `relay-plan`
   missing stops the orchestrator with a message. Task 4 Step 4.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §3, §12: "the exact form of the status line within the 500 characters" is the builder's | `quartz.md` §4 pins it: `` `<plan path>`: <where it stands>; next: <what>; agents: <id> (<role>), … ``, with a table giving the words for each of the ten moments. `agents:` lists only agents whose report has not come back; the skill-test runs go by their number. A brainstorm's status is `brainstorm: <where it stands>; next: <what>`. A decision note is `Decision (<where>): <what was decided>. Why: <the reason given>.` |
| P2 | §3: without Quartz, decisions go "to the plan's run folder in a later leg"; the Contract's table names no file for them | `decisions.md` in the run folder, appended; before the folder exists, the topic's `brainstorm.md`. The Contract is copied unchanged: `relay-plan` reads neither file. **The owner may rename it at stop 3.** |
| P3 | Contract: "A brainstorm without Quartz keeps its decisions in `<main checkout>/.hyper-relay/runs/<topic>/brainstorm.md`" | Before its first write, the exclude step `relay-plan run-dir` does (`git check-ignore -q .hyper-relay/runs/`, else a line in the local exclude file), written in `quartz.md` §4: no plan exists yet for `run-dir`. |
| P4 | Contract: "A fresh executor (not a fix round) writes `executor.md` anew; a fix round appends its section" | Read as "not a round": catch-up and conflict rounds append `## Catch-up round` or `## Conflict round`; the reviewer's rerun appends `## Rerun after fix round <k>` to `acceptance/report.md`. So §3's "an agent whose report is not in the run folder" is decidable for a round: its section. |
| P5 | §5: the hand-back check "runs `relay-plan gates <plan>`"; Contract: the orchestrator passes the summary's text to `relay-plan gates` | Each check names the commands the summary gives: the full gates at the hand-back and after a catch-up or conflict round, the round's tests after a fix round. Naming none would fail, after a catch-up, on an earlier fix round's older blocks. |
| P6 | Contract: `relay-plan gate <plan> <command>` | The skills quote the command as one argument (`'<command>'`): `relay-plan gates` matches each command, as one argument, by its exact text. |
| P7 | §8: `writing-plans` requires "a `skill-test` situation in a ```` ```text ```` fence" | Also: the situation is written whole in its fence, with no placeholder for text written elsewhere (`relay-plan scenarios` copies the fence alone), and the labels are `Situation:`, `GREEN must:` and `RED is expected to:`, the ones `relay-plan check` looks for. This plan's own situations each repeat their context. |
| P8 | §9 S4: "The acceptance reviewer, in a repo with Quartz, finds a POLISH issue" | The skill-test runs see only `skills/`, not `templates/`, so S4's agent is the fallback reviewer with `reviewing.md` §1's standing brief, which gains the same card rule. The templates' text is checked by Steps 2 and 3. |
| P9 | §6: the cap applies to "a finding (an acceptance FAIL, a Critical, a GREEN that failed)" | Counted per finding; a real Critical's and a failed GREEN's fix rounds count as acceptance's do. The owner's "one more round" at stop 4 runs one round past the cap, then a short stop 4. A catch-up or conflict round counts toward no cap. The cap's card is kind `bug`. |
| P10 | §3: the stop's last line, "the board is current, so this is a good moment to clear" | Exactly "The board is current, so this is a good moment to clear."; without Quartz, "Everything is written down, so this is a good moment to clear." |
| P11 | §4: the orchestrator creates the run folder "at the handoff" | Also at stop 3 when the owner asks for a plan review, since `plan-review.md` lives there; `run-dir` only creates, so the handoff's call changes nothing. |
| P12 | §6: the orchestrator files the cards an agent put in `cards.md` "in one `add_tasks` call" | Then it deletes `cards.md`, so a fresh session never files them twice. Each card there is a `## <title>` section with its kind, the file, the evidence and why. |
| P13 | §5: the hand-back check reads the gates' log | A `FAIL` line, or counts that differ from the summary, is a failure for the owner, as a failed rerun is today. |
| P14 | §7: the skill tests run on `relay-plan scenarios`; the judge "reads each step's GREEN and RED from the plan" | When `scenarios` exits 1 (a plan written before the fence rule), the orchestrator tells the owner and stops the skill tests. The judge reads each step through `relay-plan step`. |
| P15 | §8: "`tests/orchestrating/run-tests.sh`: checks for what can be checked by text (the builder picks which)" | Nine checks with eleven broken cases, each added by the task that writes its text: from 28 to 48 passed. |
| P16 | §8: `README.md` "where it describes the relay's loop or its stops" | A paragraph after the loop's description (reports in the run folder, `relay-plan`, one gate run, the cap); two bullets in "Quartz: the board" (state, proposed cards); the no-Quartz sentence names the run folder. |
| P17 | §5, L2: no check runs twice | This plan's acceptance task has no gate step (S12 applied to itself), and no rerun of the gates on `main` after the merge: `relay-merge` runs them on the merged result. This run follows the installed relay (0.2.6), whose hand-back check still reruns them. |
| P18 | `.hyper-relay/agents.md`, Releases: the release steps come "last"; §10, §11 | After the release (Step 21) and the owner's update (Step 22): the agents regenerated with the installed generator, so their marker matches 0.2.7 (Step 23); the handoff memory retired with the owner's OK (Step 24), before the probe, so the fresh sessions cannot lean on it; the live probe last (Step 25), since it needs all of them. The acceptance task is ticked after the probe. |
| P19 | §8: the executor template gains "the run folder, the cards, the short summary" | One sentence in its intro and its description: `executing-plans` holds the rules, as it holds the other rounds'. |
| P20 | §9: the situations | The shop repo, its plans, cards, ids, outputs and paths are made up. |
| A1 | Checked (spec, How it works: "`run-dir` and `steps` need only the plan file, not a branch", `00b271c`) | `relay-plan run-dir` and `relay-plan steps` work on a committed plan before the handoff too (stop 3's task count and plan review): Plan 1's `run-dir` checks only that the plan file exists, and `steps` reads only the plan file; only `gates` needs the branch. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–6; 7 (Steps 5–18, 25) |
| Decisions (owner, 2026-11-20) | L1: 4, 5, 6; 7 (S1, S2, S10, S13). L2: 1, 2, 5, 6; 7 (S3, S7, S11, S12). L3: 2, 3, 6; 7 (S4, S5, S14). L4: 6; 7 (S6). L5: 1, 2, 3, 4. L6: 1, 4, 5, 6; 7 (S8, S9). L7: no task. L8: this plan is Plan 2 |
| How it works | Execution notes; 7 (Step 25: the agents' Quartz write, the measurements) |
| Approaches | No task: A, chosen; this is its Plan 2 |
| The plans | Execution notes (Plan 1 first; no shared file) |
| Contract | Contract (below); 2, 3, 5, 6 |
| 1. `bin/relay-plan` (Plan 1) | No task: Plan 1's. Tasks 1, 2, 4, 5, 6 name its commands; 7 (Step 4) runs them on this plan |
| 2. `fix-rounds` (Plan 1) | 6 (the `agents` skill's header row, which §2 gives Plan 2) |
| 3. The board holds the state (Plan 2) | 4; 5 and 6 (each leg's moments); 7 (S1, S2, S10, S13) |
| 4. The run folder and short hand-backs (Plan 2) | 1, 2, 3, 4, 5, 6; 7 (S4, S11, S14) |
| 5. No check runs twice (Plan 2) | 1, 2, 5, 6; 7 (S3, S7, S11, S12) |
| 6. The owner's decisions on the board (Plan 2) | 2, 3, 6; 7 (S4, S5, S6, S14) |
| 7. Routing by path (Plan 2) | 4, 5, 6; 7 (S8, S9) |
| 8. The other files (Plan 2) | 1–6 |
| 9. Pressure scenarios (Plan 2's skill tests) | 7 (Steps 5–18) |
| 10. Testing and acceptance | 6 (the full gates); 7 |
| 11. Releases | 7 (Steps 21–24) |
| 12. Out of scope, and left to the builder | No task; P1, P15 (the builder's calls); 7 (Step 1) |

## Contract

Both plans carry this section, identical.

**The run folder.** One per plan: `<main checkout>/.hyper-relay/runs/<branch>/`, where the main checkout is the parent
of `git rev-parse --path-format=absolute --git-common-dir`, and `<branch>` is the plan's file name without its
`YYYY-MM-DD-` prefix and `.md` (`dispatching.md` §3's rule). Git ignores `.hyper-relay/runs/`. It holds:

| Path | Written by | What |
|---|---|---|
| `executor.md` | the executor | its full report; each fix round appends a `## Fix round <k>` section |
| `gates.log` | `relay-plan gate` | every gate run, in blocks (below) |
| `acceptance/` | the acceptance reviewer | its evidence files, and `report.md`, its full report |
| `code-review.md` | the code reviewer | its full review |
| `plan-review.md` | the plan reviewer | its full findings |
| `skill-tests/` | the orchestrator, the test runs, the judge | `red/`, `green/`, `step-<id>.txt`, `step-<id>-green.md`, `step-<id>-red.md`, `verdicts.md` |
| `status` | the orchestrator | without Quartz only: the plan's one-line status |
| `cards.md` | any agent | without Quartz only: proposed cards, one `## ` section each |

A brainstorm without Quartz keeps its decisions in `<main checkout>/.hyper-relay/runs/<topic>/brainstorm.md`.

**`gates.log`.** Blocks, appended. Each starts with a line `GATE <full sha> <command>` (the checkout's `HEAD` when the
gate ran), then the command's stdout and stderr, then a line `EXIT <code>`. It is only ever appended to: a command
is known by its exact text, so the executor's summary names each gate by the text it gave `relay-plan gate`, and the
orchestrator passes the same text to `relay-plan gates`.

**Files over time.** `relay-plan run-dir` only creates; it never clears anything. A fresh executor (not a fix round)
writes `executor.md` anew; a fix round appends its section. Older blocks in `gates.log` stay and are judged by their
sha.

**`relay-plan`.** POSIX shell, run by dash, at `bin/relay-plan`; Claude Code puts it on `PATH` as it does
`relay-merge`. A `<plan>` is a path relative to the repo's top, or absolute. Output is short by design: one line per
item, and any detail under a FAIL at most 5 lines. Exit 0 means all ok, 1 a check failed or nothing was found, 2 a
usage error or a missing file.

| Command | Does | Prints |
|---|---|---|
| `relay-plan run-dir <plan>` | creates the plan's run folder; when `git check-ignore -q .hyper-relay/runs/` fails in the main checkout, adds a `.hyper-relay/runs/` line to the file `git rev-parse --git-path info/exclude` prints there | the folder's absolute path |
| `relay-plan check <plan> [--spec <spec>] [--sibling <plan>]… [--base <plan>]` | `planning.md` §2's checks that need no MCP: `committed` (on `main`; during a branch run, that the file exists), `card` (with `--spec`: when the spec names a card, the plan's header has a `**Card:**`/`**Cards:**` line or a `**Spec:**` line naming the spec), `trailers` (each task that commits carries `Plan-Task: <plan path>#<N>` once, its own N and path), `acceptance` (the last task's steps each name a who from the four), `skill-tests` (each `skill-test` step has `Situation:` with a ```` ```text ```` fence, `GREEN must:` and `RED is expected to:`), `placeholders` (`planning.md` §2's pattern, outside fences and inline code), `coverage` (with `--spec`: every `## ` heading of the spec is in the Spec coverage table), `contract` (with `--sibling`: identical `## Contract` sections), `builds-on` (with `--base`: the header's `**Builds on:**` names it) | `ok <check>` or `FAIL <check>: <detail>`, one per check run |
| `relay-plan overlap <plan> <other>…` | `parallel.md` §2's conflict check; an `<other>` is a plan path or an in-flight branch (its plan's paths plus `git diff --name-only main...<branch>`) | `shared <path> (<other>)` and `numbered <folder><digits> (<other>)`, one per overlap |
| `relay-plan steps <plan> [reviewer\|owner\|after-merge\|skill-test]` | lists the acceptance task's steps, all or one who's (the argument `after-merge` selects the plan's `after merge` steps) | first `tasks <N>; acceptance task <M>`, then `<id>`, tab, `<who>` as the plan writes it (`after merge` with its space), tab, `<title>` per step |
| `relay-plan step <plan> <id>` | one acceptance step's full text, from its `- [ ] **Step` line to the next step or the task's end | the step |
| `relay-plan scenarios <plan> <dir>` | writes each `skill-test` step's situation (its fenced text, without the fence) to `<dir>/step-<id>.txt`; exit 1 when a `skill-test` step has no fenced situation | `<id>`, tab, `<file>`, tab, `<title>` per scenario |
| `relay-plan gate <plan> <command>` | runs `<command>` with `sh -c` from the top of the current checkout (the main checkout or a worktree), appends its block to the plan's run folder's `gates.log` (found through the main checkout, as `run-dir` finds it), and exits with the command's code | the output's last 5 lines, then `EXIT <code>` |
| `relay-plan gates <plan> [<command>…]` | for each command in `gates.log` (or each one named, matched by exact text), takes its latest block; FAIL when its exit is not 0, or its sha is not `git rev-parse refs/heads/<branch>`; exit 2 when the branch or the log does not exist. With no command named after a fix round, the full gates' blocks are older than the tip and FAIL: that is by design, and the check after a fix round names its commands | `ok\|FAIL <command>: exit <code> at <short sha>: <last non-empty output line>` per command |

**`fix-rounds`.** An optional key in `.hyper-relay/agents.md`'s header: `fix-rounds: <n>`, a whole number from 1 to 9;
absent means 2. The generator accepts it and changes no generated file for it; any other value is refused with
`fix-rounds must be a whole number from 1 to 9`. The orchestrator reads it from `main`'s facts file, as it reads
`execute:`.

**The label.** A card filed by the relay without the owner asking for it carries the label `proposed`.

## File structure

- **Modify (Task 1):** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.
- **Modify (Task 2):** `skills/executing-plans/SKILL.md`, `templates/agents/executor.md`.
- **Modify (Task 3):** `templates/agents/reviewer-commands.md`, `templates/agents/reviewer-browser.md`,
  `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`.
- **Modify (Task 4):** `skills/orchestrating/SKILL.md`, `skills/orchestrating/quartz.md`, `skills/brainstorming/SKILL.md`.
- **Modify (Task 5):** `skills/orchestrating/planning.md`, `skills/orchestrating/dispatching.md`,
  `skills/orchestrating/parallel.md`.
- **Modify (Task 6):** `skills/orchestrating/reviewing.md` (rewritten whole), `skills/agents/SKILL.md`, `README.md`.
- **Modify (Tasks 1–6):** `tests/orchestrating/run-tests.sh` (each task's checks).
- **Unchanged:** `templates/agents/planner.md`, `templates/hooks/`, `bin/`, `hooks/`, `.claude-plugin/`,
  `package.json`, `.hyper-relay/`, `CLAUDE.md`, every other skill, every other suite.

---

### Task 1: `writing-plans`: whole situations in a text fence, and no reviewer step reruns the gates (spec §5, §8; P7)

**Files:**
- Modify: `skills/writing-plans/SKILL.md:102` (a bullet after it), `:108-112` (Skill tests)
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md:6`, `:12-16`, `:49-53`
- Test: `tests/orchestrating/run-tests.sh`

- [x] **Step 1: Write the failing check.** In `tests/orchestrating/run-tests.sh`, a section
  `# --- 8. Skill-test situations are whole and fenced, and no reviewer step reruns the gates.` with
  `skill_test_situations_fenced`: from the tree's top, it passes when `skills/writing-plans/SKILL.md` has a line
  holding the fixed string ```` ```text ```` and a line holding the fixed string ``No `reviewer` step reruns the full
  gates``, and prints what is missing otherwise. Add it to `CHECKS`. Its broken case, after the last one:
  `broken "writing-plans without the fence rule"`; delete every line holding ```` ```text ```` from
  `$CASE/skills/writing-plans/SKILL.md` (`sed -i '/```text/d'`); `expect_fail skill_test_situations_fenced`. The
  header comment names the new check, and its `Expect:` becomes `"30 passed, 0 failed"`.

- [x] **Step 2: Run it to verify it fails**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 4`
Expected: `FAIL skill_test_situations_fenced` above, and the last line `29 passed, 1 failed`.

- [x] **Step 3: The text.** In `skills/writing-plans/SKILL.md`, insert after the line that begins
  `- The plan ends with its acceptance task.` (line 102) this line:

```text
- No `reviewer` step reruns the full gates. They run once on the branch, as the executor's last task, which saves their output to the run folder's `gates.log`; the orchestrator's hand-back check reads that log, and `relay-merge` runs them again on the merged result. A `reviewer` step runs what only an independent check can: a live run in a scratch repo, a check of which files the branch changed, a reading of the new text against the spec.
```

Then replace:

```text
- **Situation:** everything a fresh agent needs, in full, since it sees only the skills and this text: who it is (the orchestrator, an executor, a planner), the repo's state, what has just happened, and what it is asked to answer.
- **GREEN:** what an agent reading the branch's skills must do, concretely enough to judge from its answer (the commands it would run and its next message).
- **RED:** what an agent reading `main`'s skills (or none, for a new skill) is expected to do instead.

The orchestrator runs each scenario on both, after acceptance and beside the code review (`hyper-relay:orchestrating`'s `reviewing.md`).
```

with:

````text
- **`Situation:`** everything a fresh agent needs, in full, since it sees only the skills and this text: who it is (the orchestrator, an executor, a planner), the repo's state, what has just happened, what each command or tool it would use would show, and what it is asked to answer. Write it whole, in a ```` ```text ```` fence of its own under the `Situation:` line. `relay-plan scenarios` copies the fence alone into a file for the test run, so a placeholder for text written elsewhere in the plan reaches the run unfilled: repeat shared context in each situation instead.
- **`GREEN must:`** what an agent reading the branch's skills must do, concretely enough to judge from its answer (the commands it would run and its next message).
- **`RED is expected to:`** what an agent reading `main`'s skills (or none, for a new skill) is expected to do instead.

The orchestrator runs each scenario on both, after acceptance and beside the code review, and a judge reads both answers against the step's `GREEN must:` and `RED is expected to:` (`hyper-relay:orchestrating`'s `reviewing.md`).
````

In `skills/writing-plans/plan-document-reviewer-prompt.md`, replace:

```text
**Purpose:** Check a plan against its spec and the plan format before the owner reads it. The reviewer only reads.
```

with:

```text
**Purpose:** Check a plan against its spec and the plan format before the owner reads it. The reviewer only reads,
and writes its findings to one file in the plan's run folder (`relay-plan run-dir <plan>` prints the folder).
```

Replace:

```text
    You are a plan document reviewer. You only read: never edit, write, commit or run
    anything that changes a file. Read the plan and its spec in full.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]
```

with:

```text
    You are a plan document reviewer. You only read, except for one file: write your
    review, in the Output Format below, to `plan-review.md` in the run folder. Never
    edit, write, commit or run anything else that changes a file. Read the plan and its
    spec in full.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]
    **Run folder:** [RUN_DIR]
```

Replace:

````text
    - [Task X, Step Y]: [the suggestion]
```

**Reviewer returns:** the status, the blocking issues and the advisory ones. The orchestrator gives them to the
planner, which revises the plan and commits it again.
````

with:

````text
    - [Task X, Step Y]: [the suggestion]

    Once `plan-review.md` is written, reply with only three lines: the status, the
    number of blocking and of advisory issues, and the path of `plan-review.md`.
```

**Reviewer returns:** the status, the counts and the path of `plan-review.md`. The orchestrator gives the planner
that path, not the text; the planner revises the plan and commits it again.
````

- [x] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F '```text' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'step reruns the full gates' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F -e 'GREEN must:' -e 'RED is expected to:' skills/writing-plans/SKILL.md` | `3` |
| `grep -c -E '^- \*\*(GREEN\|RED):\*\*' skills/writing-plans/SKILL.md` | `0` |
| `grep -c -F -e '[RUN_DIR]' -e 'reply with only three lines' skills/writing-plans/plan-document-reviewer-prompt.md` | `2` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `30 passed, 0 failed` |

- [x] **Step 5: Commit.**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md tests/orchestrating/run-tests.sh
git commit -m "feat: whole skill-test situations in a text fence, and no reviewer step reruns the gates" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: the executor runs its gates through `relay-plan` and hands back a short summary (spec §4, §5, §6; P4, P6, P19)

**Files:**
- Modify: `skills/executing-plans/SKILL.md:22` (two bullets after it), `:55-66`, `:75-76`, `:82` (two sections before it),
  `:106`
- Modify: `templates/agents/executor.md:7-8`, `:17-20`
- Test: `tests/orchestrating/run-tests.sh`

- [x] **Step 1: Write the failing check.** A section `# --- 9. The executor's gates go through relay-plan, and it
  copies no checklist.` with `executor_gates_through_relay_plan`: it passes when `skills/executing-plans/SKILL.md` has
  a line holding the fixed string `relay-plan gate <plan>`, and `none -i -F 'acceptance checklist'
  skills/executing-plans`. Add it to `CHECKS`. Its broken case: `broken "the executor copying the acceptance checklist
  again"`; append `\nThen copy the acceptance checklist into your report.\n` to
  `$CASE/skills/executing-plans/SKILL.md`; `expect_fail executor_gates_through_relay_plan`. `Expect:` becomes
  `"32 passed, 0 failed"`.

- [x] **Step 2: Run it to verify it fails**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 4`
Expected: `FAIL executor_gates_through_relay_plan` above, and the last line `31 passed, 1 failed`.

- [x] **Step 3: The text, in `skills/executing-plans/SKILL.md`.** Insert after the line
  `- the checkout's path and the branch;` (line 22):

```text
- the plan's **run folder**, `.hyper-relay/runs/<branch>/` in the repo's main checkout, which git ignores: your full
  report and your gates' output go there;
- when the repo uses Quartz, the plan's cards and its initiative, for the cards you file (Proposed cards, below);
  otherwise "Run no Quartz command and use no Quartz tool.";
```

Replace the lines from `5. **Full gates, once,** after your last task:` through
`   - anything left for the owner: a task that is theirs, a step you stopped at.` with:

```text
5. **Full gates, once,** after your last task: the ones the plan's Execution notes name, and your agent's own
   ("Full gates"). Run each through `relay-plan gate <plan> '<command>'`, from the checkout's top, the command quoted
   as one argument: it runs the command, appends its output to the run folder's `gates.log`, prints the last lines
   and exits with the command's code. From then on, name each gate by that exact command.
6. **Acceptance:** follow your agent's acceptance steps for your mode, under "In a worktree" or "On a branch", when
   it has them. The plan's acceptance task is not yours: do not copy it into your report.
7. **Report, then stop.** Write your full report to `executor.md` in the run folder, as a new file (replace one an
   earlier run left):
   - tasks done (n/N), each with its commit hash;
   - each gate, by its command, with its pass/fail counts;
   - every deviation from the plan, and why;
   - the calls you made where the plan left a choice open, one line each;
   - every `quartz:` line, verbatim;
   - the acceptance output: URLs, logins, anything left running;
   - anything left for the owner: a task that is theirs, a step you stopped at;
   - the cards you filed (Proposed cards, below).

   Then hand back only a short summary, at most about 15 lines: tasks n/N; one line per gate, its command and its
   counts, and the path of `gates.log`; each deviation and each open call, one line each; every `quartz:` line,
   verbatim; what you left running or left for the owner; the cards you filed; the path of `executor.md`. The
   orchestrator verifies every line of it, and reads `executor.md` only for what the summary does not settle.
```

Replace:

```text
- Touch anything outside your checkout: `~/.claude/`, `~/.config/opencode/`, other repos, other worktrees. A task
  marked as the owner's or the orchestrator's is not yours, even when it gives commands.
```

with:

```text
- Touch anything outside your checkout: `~/.claude/`, `~/.config/opencode/`, other repos, other worktrees. The one
  exception is your run folder, from any checkout: `executor.md` and `cards.md`, and `gates.log` through
  `relay-plan gate`. A task marked as the owner's or the orchestrator's is not yours, even when it gives commands.
```

Insert before the line `## Catch-up and conflict rounds` (line 82):

```text
## Fix rounds

After your tasks, the orchestrator may resume you, or dispatch a fresh executor with the plan, for fix round `<k>`:
findings from the acceptance check, the code review or the skill tests, each named by its evidence path in the run
folder. In your checkout and on your branch (process step 1):

1. Fix root causes. Commit each fix staging named files only, with the attribution lines your instructions give, in
   one final paragraph, and no `Plan-Task:` trailer.
2. Rerun only the tests that pin the fix, not the full gates: each through `relay-plan gate <plan> '<command>'`, as
   in process step 5.
3. Append a `## Fix round <k>` section to `executor.md`: each fix with its commit, each test with its counts, any
   deviation. Then hand back the short summary (process step 7), naming the tests by their commands.

## Proposed cards

An issue you notice outside your plan (a bug in code the plan does not touch, a doc that says something the repo no
longer does) is not yours to fix: file it as a proposed card. When the prompt gives the plan's initiative, call
`add_tasks` with the card: the label `proposed`, kind `bug` or `change`, that initiative, and a body naming the plan,
the file and the evidence (the file and line, or a path in the run folder). When `add_tasks` fails, or the prompt
says to use no Quartz tool, append the card to the run folder's `cards.md` instead, as a `## <title>` section with
its kind, the file, the evidence and why. Your summary lists the cards' ids, or says they are in `cards.md`.

```

Replace:

```text
4. Report: the merge commit's hash, each conflict and how you resolved it, and the gates with their counts.
```

with:

```text
4. Append a `## Catch-up round` or `## Conflict round` section to `executor.md`: the merge commit's hash, each
   conflict and how you resolved it, and the gates with their counts. Then hand back the short summary (process
   step 7).
```

- [x] **Step 4: The text, in `templates/agents/executor.md`.** Replace:

```text
  conflict round merges main into its own branch. The dispatch prompt names the plan, the mode, the checkout and
  branch, which tasks are the executor's, and anything unusual.
```

with:

```text
  conflict round merges main into its own branch. The dispatch prompt names the plan, the mode, the checkout and
  branch, which tasks are the executor's, the plan's run folder, and anything unusual.
```

Replace:

```text
You execute one implementation plan for the {{project}} repo by the preloaded `hyper-relay:executing-plans` skill:
its process, its "never" list, its catch-up and conflict rounds and its report are yours. The dispatch prompt gives
the plan, the mode (`branch` or `worktree`), the checkout and the branch, and which tasks are yours. Below is only
what is particular to {{project}}.
```

with:

```text
You execute one implementation plan for the {{project}} repo by the preloaded `hyper-relay:executing-plans` skill:
its process, its "never" list, its fix, catch-up and conflict rounds, its proposed cards and its report are yours.
The dispatch prompt gives the plan, the mode (`branch` or `worktree`), the checkout and the branch, which tasks are
yours, and the plan's run folder: your full report goes to its `executor.md` and your gates' output, through
`relay-plan gate`, to its `gates.log`, and you hand back only the short summary. Below is only what is particular to
{{project}}.
```

- [x] **Step 5: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'relay-plan gate <plan>' skills/executing-plans/SKILL.md` | `2` |
| `grep -c -i 'acceptance checklist' skills/executing-plans/SKILL.md` | `0` |
| `grep -c -F -e '## Fix round <k>' -e '## Catch-up round' skills/executing-plans/SKILL.md` | `2` |
| `grep -c -F 'run folder' templates/agents/executor.md` | `2` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `32 passed, 0 failed` |

- [x] **Step 6: Commit.**

```bash
git add skills/executing-plans/SKILL.md templates/agents/executor.md tests/orchestrating/run-tests.sh
git commit -m "feat: the executor runs its gates through relay-plan and hands back a short summary" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: reviewers write to the run folder, file proposed cards and hand back short summaries (spec §4, §6; P12)

**Files:**
- Modify: `templates/agents/reviewer-commands.md:4-9`, `:18-19`, `:68-71`, `:74-76`, `:83-91`
- Modify: `templates/agents/reviewer-browser.md:4-9`, `:18-19`, `:87-90`, `:93-94`, `:105`, `:114`
- Modify: `skills/requesting-code-review/code-reviewer.md:38` (a section before it), `:143` (two lines after it), `:145`
- Modify: `skills/requesting-code-review/SKILL.md:39` (two lines after it), `:41-44`, `:54-70`, `:77`
- Test: `tests/orchestrating/run-tests.sh`

- [x] **Step 1: Write the failing checks.** A section `# --- 10. Every agent that reports writes to the run folder.`
  with `agents_write_to_the_run_folder`: it passes when each of `skills/executing-plans/SKILL.md`,
  `templates/agents/executor.md`, `templates/agents/reviewer-commands.md`, `templates/agents/reviewer-browser.md`,
  `skills/requesting-code-review/code-reviewer.md` and `skills/writing-plans/plan-document-reviewer-prompt.md` has a
  line holding the fixed string `run folder`, and prints each file that has none. A section
  `# --- 11. The agent that finds an issue files it as a proposed card.` with `proposed_cards_filed_by_finders`: it
  passes when each of `skills/executing-plans/SKILL.md`, `templates/agents/reviewer-commands.md`,
  `templates/agents/reviewer-browser.md` and `skills/requesting-code-review/code-reviewer.md` has a line holding
  `add_tasks` and a line holding ``` `proposed` ``` (with its backticks), and prints each file that misses one. Add
  both to `CHECKS`. Their broken cases: `broken "a reviewer template that names no run folder"`; delete every line
  holding `run folder` from `$CASE/templates/agents/reviewer-browser.md`; `expect_fail agents_write_to_the_run_folder`.
  `broken "a code reviewer that files no card"`; delete every line holding `add_tasks` from
  `$CASE/skills/requesting-code-review/code-reviewer.md`; `expect_fail proposed_cards_filed_by_finders`. `Expect:`
  becomes `"36 passed, 0 failed"`.

- [x] **Step 2: Run them to verify they fail**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 12`
Expected: `FAIL agents_write_to_the_run_folder` (naming the two reviewer templates and `code-reviewer.md`) and
`FAIL proposed_cards_filed_by_finders`, and the last line `34 passed, 2 failed`.

- [x] **Step 3: The text, in `templates/agents/reviewer-commands.md`.** Replace:

```text
  they name) and reports PASS / FAIL / NEEDS-HUMAN per step plus everything that looked off. Report-only: never edits
  code or docs, never ticks, merges or pushes, never installs anything or changes the owner's setup. The dispatch
  prompt names the plan and its acceptance task, the steps to run, the checkout (the main checkout or a worktree),
  and the evidence folder.
```

with:

```text
  they name) and reports PASS / FAIL / NEEDS-HUMAN per step plus everything that looked off. Report-only: never edits
  code or docs, never ticks, merges or pushes, never installs anything or changes the owner's setup; its one write
  to the board is a proposed card. The dispatch prompt names the plan and its acceptance task, the steps to run, the
  checkout (the main checkout or a worktree), and the plan's run folder, whose `acceptance/` is the evidence folder.
```

Replace:

```text
left behind, instructions that contradict each other. The dispatch prompt gives the plan path and its acceptance
task, the checkout (the main checkout or a worktree) and the folder for evidence. Everything below is standing.
```

with:

```text
left behind, instructions that contradict each other. The dispatch prompt gives the plan path and its acceptance
task, the checkout (the main checkout or a worktree), the plan's run folder, whose `acceptance/` is your evidence
folder, and, when the repo uses Quartz, the plan's initiative. Everything below is standing.
```

Replace:

```text
- **PRE-EXISTING:** caused by an earlier piece or by upstream. Name it if you can.
- **POLISH:** works, but could be better.
```

with:

```text
- **PRE-EXISTING:** caused by an earlier piece or by upstream. Name it if you can.
- **POLISH:** works, but could be better.

**Proposed cards.** File each PRE-EXISTING and POLISH finding as a card, for the owner to prune on the board:
`add_tasks` with the label `proposed`, kind `bug` or `change`, the initiative the dispatch gives, and a body naming
the plan, the file and the evidence (its path in the run folder). That is your only write to the board. When
`add_tasks` fails, or the dispatch says to use no Quartz tool, append the card to the run folder's `cards.md`
instead, as a `## <title>` section with its kind, the file, the evidence and why. A BLOCKING finding is never a card:
it goes in your report.
```

Replace:

```text
- Report-only. Never create, edit or delete a file in any checkout or worktree; the evidence folder is the
  only place you write. Never run git write commands, push, tag, install or uninstall a plugin, add a
  marketplace, or edit `~/.claude/`, `~/.config/opencode/` or any other config.
```

with:

```text
- Report-only. Never create, edit or delete a file in any checkout or worktree; the evidence folder and the run
  folder's `cards.md` are the only places you write, and a proposed card your only write to the board. Never run
  git write commands, push, tag, install or uninstall a plugin, add a marketplace, or edit `~/.claude/`,
  `~/.config/opencode/` or any other config.
```

Replace:

```text
2. Report, concisely:
   - **Verdict line:** "all N steps PASS" or "X FAIL / Y NEEDS-HUMAN", and whether anything blocks a merge.
   - **Per step:** PASS / FAIL / NEEDS-HUMAN, what you ran and what you saw (quoted), and any setup change.
   - **For each FAIL:** exact reproduction steps, and whether it is a product bug or a setup issue.
   - **Findings:** BLOCKING / PRE-EXISTING / POLISH, each with the file or command and its evidence file.
   - **Live sessions:** which ones you ran, and why.
   - **Evidence:** every path.
```

with:

```text
2. Write your full report, concisely, to `report.md` in the evidence folder (a rerun after a fix round appends a
   `## Rerun after fix round <k>` section to it):
   - **Verdict line:** "all N steps PASS" or "X FAIL / Y NEEDS-HUMAN", and whether anything blocks a merge.
   - **Per step:** PASS / FAIL / NEEDS-HUMAN, what you ran and what you saw (quoted), and any setup change.
   - **For each FAIL:** exact reproduction steps, and whether it is a product bug or a setup issue.
   - **Findings:** BLOCKING / PRE-EXISTING / POLISH, each with the file or command and its evidence file.
   - **Cards:** the id of each card you filed, or that it is in `cards.md`.
   - **Live sessions:** which ones you ran, and why.
   - **Evidence:** every path.
3. Hand back only a short summary, at most about 15 lines: the verdict line; one line per step (PASS / FAIL /
   NEEDS-HUMAN); each BLOCKING finding in one line, with its evidence path; the cards you filed; the path of
   `report.md`.
```

- [x] **Step 4: The text, in `templates/agents/reviewer-browser.md`.** Replace:

```text
  Report-only: never edits code or docs, never ticks, merges, pushes or takes a stack down. The dispatch prompt
  names the plan and its click-through task, the steps to run, the stack name and URLs, any extra logins, and the
  evidence folder.
```

with:

```text
  Report-only: never edits code or docs, never ticks, merges, pushes or takes a stack down; its one write to the
  board is a proposed card. The dispatch prompt names the plan and its click-through task, the steps to run, the
  stack name and URLs, any extra logins, and the plan's run folder, whose `acceptance/` is the evidence folder.
```

Replace:

```text
translations that are missing. The dispatch prompt gives the plan path and its click-through task, the stack,
and the folder for screenshots. Everything below is standing.
```

with:

```text
translations that are missing. The dispatch prompt gives the plan path and its click-through task, the stack,
the plan's run folder, whose `acceptance/` is your evidence folder for screenshots, and, when the repo uses Quartz,
the plan's initiative. Everything below is standing.
```

Replace:

```text
- **PRE-EXISTING:** caused by an earlier piece. Name it if you can.
- **POLISH:** works, but could be better.
```

with:

```text
- **PRE-EXISTING:** caused by an earlier piece. Name it if you can.
- **POLISH:** works, but could be better.

**Proposed cards.** File each PRE-EXISTING and POLISH finding as a card, for the owner to prune on the board:
`add_tasks` with the label `proposed`, kind `bug` or `change`, the initiative the dispatch gives, and a body naming
the plan, the file and the evidence (its path in the run folder). That is your only write to the board. When
`add_tasks` fails, or the dispatch says to use no Quartz tool, append the card to the run folder's `cards.md`
instead, as a `## <title>` section with its kind, the file, the evidence and why. A BLOCKING finding is never a card:
it goes in your report.
```

Replace:

```text
- Report-only. Never create, edit or delete a file in any checkout or worktree; the evidence folder is the only
  place you write. Never run git write commands, and never start, stop or restart a stack or its containers.
```

with:

```text
- Report-only. Never create, edit or delete a file in any checkout or worktree; the evidence folder and the run
  folder's `cards.md` are the only places you write, and a proposed card your only write to the board. Never run git
  write commands, and never start, stop or restart a stack or its containers.
```

Replace `3. Report, concisely:` with:

```text
3. Write your full report, concisely, to `report.md` in the evidence folder (a rerun after a fix round appends a
   `## Rerun after fix round <k>` section to it):
```

Replace `   - **Screenshots:** every path.` with:

```text
   - **Cards:** the id of each card you filed, or that it is in `cards.md`.
   - **Screenshots:** every path.
4. Hand back only a short summary, at most about 15 lines: the verdict line; one line per step (PASS / FAIL /
   NEEDS-HUMAN); each BLOCKING finding in one line, with its screenshot's path; the cards you filed; the path of
   `report.md`.
```

- [x] **Step 5: The text, in `skills/requesting-code-review/code-reviewer.md`.** Insert before the line
  `    ## What to Check` (line 38):

```text
    ## Where Your Review Goes

    **Run folder:** {RUN_DIR}
    **Initiative:** {INITIATIVE}

    Write your full review, in the Output Format below, to `code-review.md` in the
    run folder. File each Important and Minor issue as a proposed card: `add_tasks`
    with the label `proposed`, kind `bug` or `change`, the initiative above, and a
    body naming the plan, the file and line, and `code-review.md`. A Critical issue
    is never a card: it is fixed before the merge. When `add_tasks` fails, or the
    initiative is "none", append the card to the run folder's `cards.md` instead, as
    a `## <title>` section with its kind, the file, the evidence and why. Change no
    other file.

    Then reply with only a short summary: Ready to merge (Yes / No / With fixes); the
    number of Critical, Important and Minor issues; each Critical issue in one line,
    with its file and line; the cards you filed (their ids, or that they are in
    `cards.md`); and the path of `code-review.md`.

    When the run folder is "none" (a review outside the relay), file no cards, write
    no file, and reply with the whole review instead.

```

Insert after the line ``- `{HEAD_SHA}` — ending commit: the branch's head`` (line 143):

```text
- `{RUN_DIR}` — the plan's run folder, which `hyper-relay:orchestrating` names (for ad hoc work: "none")
- `{INITIATIVE}` — the plan's initiative, for the cards the reviewer files ("none" when the repo does not use Quartz)
```

Replace:

```text
**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
```

with:

```text
**Reviewer returns:** a short summary: the verdict, the counts, each Critical issue, the cards it filed and the path
of `code-review.md`, which holds the full review (Strengths, Issues (Critical / Important / Minor), Recommendations,
Assessment). With no run folder, the whole review.
```

- [x] **Step 6: The text, in `skills/requesting-code-review/SKILL.md`.** Insert after the line
  ``- `{HEAD_SHA}` - Ending commit`` (line 39):

```text
- `{RUN_DIR}` - The plan's run folder, where the review goes ("none" outside the relay)
- `{INITIATIVE}` - The plan's initiative, for the cards the reviewer files ("none" without Quartz)
```

Replace:

```text
**3. Act on feedback:**
- **Critical:** fixed before the merge. In the relay, the executor fixes it, after the orchestrator checks it against the code with `hyper-relay:receiving-code-review`.
- **Important and Minor:** proposed cards for the owner to keep or drop, or noted in the report. They do not block the merge.
```

with:

```text
**3. Act on feedback:**

In the relay, the reviewer writes its full review to the run folder's `code-review.md` and hands back a short summary.
- **Critical:** fixed before the merge. In the relay, the executor fixes it, after the orchestrator checks it against the code with `hyper-relay:receiving-code-review`.
- **Important and Minor:** in the relay, the reviewer files each as a proposed card, labelled `proposed`, which the owner prunes on the board; outside it, noted in the review. They do not block the merge.
```

Replace:

```text
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Critical: repairIndex() deletes entries it cannot parse (data loss)
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: With fixes

You: [Check the Critical issue against the code: it is real, so the executor fixes it]
[Important and Minor: proposed cards]
```

with:

```text
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  RUN_DIR: <main checkout>/.hyper-relay/runs/index-repair/
  INITIATIVE: v1

[Subagent writes code-review.md in the run folder, files the Important and Minor issues as proposed cards, and returns]:
  Ready to merge: With fixes. Critical 1, Important 1, Minor 1.
  Critical: repairIndex() deletes entries it cannot parse (data loss), src/repair.ts:88
  Cards: 3f2a9c10, 8b7e6d54
  Review: <main checkout>/.hyper-relay/runs/index-repair/code-review.md

You: [Read the Critical issue in code-review.md and check it against the code: it is real, so the executor fixes it]
[Important and Minor: already on the board as proposed cards]
```

Replace `- Critical goes to the executor; Important and Minor become proposed cards` with:

```text
- Critical goes to the executor; the reviewer files Important and Minor as proposed cards, labelled `proposed`
```

- [x] **Step 7: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'add_tasks' templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md` | `templates/agents/reviewer-commands.md:2` and `templates/agents/reviewer-browser.md:2` |
| `grep -c -F 'evidence folder is the' templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md` | `:0` for each |
| `grep -c -F -e '{RUN_DIR}' -e '{INITIATIVE}' skills/requesting-code-review/code-reviewer.md` | `4` |
| `grep -c -F 'keep or drop' skills/requesting-code-review/SKILL.md` | `0` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `36 passed, 0 failed` |

- [x] **Step 8: Commit.**

```bash
git add templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md skills/requesting-code-review/code-reviewer.md skills/requesting-code-review/SKILL.md tests/orchestrating/run-tests.sh
git commit -m "feat: reviewers write to the run folder, file proposed cards and hand back short summaries" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: the board holds the state: status and decision notes, no private state, read once (spec §3, §4, §7; P1–P3, P10)

**Files:**
- Modify: `skills/orchestrating/SKILL.md:23-25`, `:40`, `:46-48`, `:50-86`, `:87-91`, `:99-101`
- Modify: `skills/orchestrating/quartz.md:3-6`, `:133-152`
- Modify: `skills/brainstorming/SKILL.md:63` (a paragraph after it)
- Test: `tests/orchestrating/run-tests.sh`

**Interfaces:**
- Produces: `quartz.md` §4's status note and its moments 1–10, which Tasks 5 and 6 cite as
  "(`quartz.md` §4, moment N)"; `SKILL.md`'s new section "Plans and reports by path", cited as
  "(`SKILL.md`, Plans and reports by path)"; the stop's last line, cited as "(`SKILL.md`, The stops)".

- [x] **Step 1: Write the failing check.** A section `# --- 12. The card and the run folder are the record: no
  private state, and the leg files are read once.` with `no_private_state`: it passes when
  `skills/orchestrating/SKILL.md` has a line holding the fixed string `never keep relay state in a memory file`, and
  `none -F 'at the start of every leg' skills/orchestrating`. Add it to `CHECKS`. Two broken cases:
  `broken "no record rule"`; delete every line holding `never keep relay state in a memory file` from
  `$CASE/skills/orchestrating/SKILL.md`; `expect_fail no_private_state`. `broken "quartz.md read at every leg again"`;
  append `\nRead quartz.md at the start of every leg.\n` to `$CASE/skills/orchestrating/SKILL.md`;
  `expect_fail no_private_state`. `Expect:` becomes `"39 passed, 0 failed"`.

- [x] **Step 2: Run it to verify it fails**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 6`
Expected: `FAIL no_private_state` above, and the last line `38 passed, 1 failed`.

- [x] **Step 3: The text.** In `skills/orchestrating/SKILL.md`, replace:

```text
The three leg files, `parallel.md` and `quartz.md` are beside this SKILL.md. Read each leg file when the loop reaches
its leg, not before; `parallel.md` whenever a second plan would be in flight or a spec has several plans; and
`quartz.md` at the start of every leg (Quartz duties, below):
```

with:

```text
The three leg files, `parallel.md` and `quartz.md` are beside this SKILL.md. Read each of them once per session, when
the loop first needs it, and not again: a leg file when the loop reaches its leg; `parallel.md` when a second plan
would be in flight or a spec has several plans; `quartz.md` at the session's first leg (Quartz duties, below). A
cleared conversation is a new session:
```

Replace the table row that begins `| 4. Ready to merge |` with:

```text
| 4. Ready to merge | Its questions first: each finding that reached the fix-round cap (merge with its card open, hold the branch, or one more round), the steps that are the owner's, where to click through. Then gate, acceptance and skill-test results, fixes made, Critical findings fixed or dropped, and the number of proposed cards filed (`reviewing.md` §4) | the click-through and the merge |
```

Replace:

```text
A stop ends the message: the next leg never starts in the message that reaches a stop. Between stop 3 and stop 4 the
loop runs on its own, except for a gap in the spec or plan and a second failed fix round, which go to the owner
(`reviewing.md` §2).
```

with:

```text
A stop ends the message: the next leg never starts in the message that reaches a stop. Between stop 3 and stop 4 the
loop runs on its own, except for a gap in the spec or plan, which goes to the owner at once (`reviewing.md` §2). A
finding that still fails after the repo's fix-round cap gets no further round: it becomes a card, the loop carries
on, and stop 4 opens with it.

Before sending stop 3 or stop 4, post the status note (`quartz.md` §4). The stop's report then ends with one line:
"The board is current, so this is a good moment to clear." Without Quartz, the line is "Everything is written down,
so this is a good moment to clear."
```

Replace the lines from `## Finding where work stands` through the blank line before `## Quartz duties` with:

```text
## Finding where work stands

After a `/clear` or in a new session, find the leg from the card and the run folder first, then from files and git,
never from memory. In a repo that uses Quartz, with its MCP loaded (`quartz.md` §1 and §2), the card's status
(`get_task`) holds a line for each of its plans in flight: where it stands, what comes next and the agents still
running (`quartz.md` §4). Without Quartz, the plan's run folder holds that line in its `status` file. A plan's run
folder is `.hyper-relay/runs/<branch>/` in the main checkout (`dispatching.md` §3).

- **A notice from an agent this conversation did not dispatch:** find its id in the status, and carry on from that
  agent's leg with its reply: for an executor, `dispatching.md` §7, from its summary and `executor.md`.
- **The status names an agent whose report is not in the run folder** (its file, or for a round, that round's
  section): tell the owner, in one line, that if they only cleared, the agent is still running and its notice will
  arrive here, and that if Claude Code was restarted, it stopped and will be dispatched again. Wait for their answer.
- **Otherwise,** carry on at the plan's `next:`.

Without a status line that has `next:` for a plan, the files and git decide:

| State | Leg |
|---|---|
| A spec that no plan's `**Spec:**` line names | **Offer** the planner leg: name the spec and ask whether to plan it; the owner's yes is the approval. When the owner asked to pick up that spec, the request is the yes. Never brainstorm it again. |
| A plan with no branch of its name, and no `Plan-Task:` commits for it on `main` | Stop 3 (the owner has not approved it yet) or the handoff, by what the owner says |
| A plan's branch with some of its tasks committed, and no executor report in this session | **Ask the owner** whether its executor is still running elsewhere. Two executors on one branch collide. |
| A stacked plan's branch (its plan's header has `**Builds on:**`) with all its executor tasks committed, whose base has not merged | It waits for its base (`parallel.md` §3): no review leg until the base merges |
| A plan's branch with all its executor tasks committed | By its review status (below) |
| The branch merged, with an `after merge` step of the plan's acceptance task left (that task is not ticked) | `reviewing.md` §5 |

**A branch with all its executor tasks committed** goes by its review status: a status line on the plan's cards
written before `next:` existed, counted only when it names this plan's path, or none.

| Review status | Leg |
|---|---|
| None, and no fix commits on the branch | `dispatching.md` §7 (verify), then `reviewing.md` §1 |
| "acceptance done" | `reviewing.md` §3 |
| "code review done" | Stop 4 (`reviewing.md` §4) |
| None, but fix commits (no Quartz and no `status` file) | **Ask the owner** which review legs ran, naming the fix commits. Rerun nothing on your own. |

A fix commit is a commit on `main..<branch>` with no `Plan-Task:` trailer, after the branch's last `Plan-Task:`
commit: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>` lists the branch's commits, newest
first, and the fix commits are those above the newest one with a trailer.

The branch name comes from the plan's file name (`dispatching.md` §3). To read the state:
`git grep -l -F '<spec file name>' -- docs/superpowers/plans` finds the spec's plans; `git branch --list <branch>`
finds the branch; `git log --format=%h --grep='Plan-Task: <plan path>' main..<branch>` lists the branch's task
commits, and the same with `main` in place of `main..<branch>` lists the merged ones.

**A branch run is active exactly when the main checkout is not on `main`.** While one is, `dispatching.md` §6's
hold-back rules bind you, in every leg.

**No private state.** The card and the run folder are the record of where work stands, and nothing else is:
you never keep relay state in a memory file or a handoff note of your own. When the owner says they are about to
clear, post any status note you owe, then say in one line that the board (without Quartz, the run folder) is
current and nothing needs writing.

```

Replace the lines from `## Quartz duties` through the blank line before `## Fallbacks` with:

```text
## Plans and reports by path

You never read a plan whole. `relay-plan`, a command beside `relay-merge` (hyper-relay's `docs/relay-plan.md`),
answers your questions about a plan: its checks, its overlaps with plans in flight, its task count, its acceptance
steps by who runs them, one step's text, its skill-test situations and its gates' runs. Claude Code puts it on
`PATH`; elsewhere the owner links it. When `command -v relay-plan` finds nothing, tell the owner and stop.

Each agent writes its full report to the plan's run folder and hands back a short summary, and findings pass between
agents by their paths there. Open a report only for a line its summary does not settle.

## Quartz duties

Read `quartz.md` beside this file (`${CLAUDE_SKILL_DIR}/quartz.md`) at the session's first leg. Every Quartz step runs
only when its §1 says the repo uses Quartz, and each has a plain-file fallback.

```

Replace:

```text
- **Models:** the generated agents carry their own. The plan reviewer, the code reviewer and the skill-test runs
  (`reviewing.md` §3) run on Sonnet: in Claude Code, `model: sonnet` on the dispatch; in OpenCode, which sets a model
  per agent and not per dispatch, the `general` subagent's configured model.
```

with:

```text
- **Models:** the generated agents carry their own. The plan reviewer, the code reviewer, the skill-test runs and
  their judge (`reviewing.md` §3) run on Sonnet: in Claude Code, `model: sonnet` on the dispatch; in OpenCode, which
  sets a model per agent and not per dispatch, the `general` subagent's configured model.
```

In `skills/orchestrating/quartz.md`, replace:

```text
plan's tasks (§3), and the Quartz duties (§4). `orchestrating` reads it at the start of every leg, and
`hyper-relay:brainstorming` runs §1 and §2 before its first message, before any other leg.
```

with:

```text
plan's tasks (§3), and the Quartz duties, with the status and decision notes that make the board the record of where
work stands (§4). `orchestrating` reads it once per session, at its first leg, and `hyper-relay:brainstorming` runs
§1 and §2 before its first message, before any other leg, and keeps §4's notes during the brainstorm.
```

Replace the lines from `## 4. The duties` through the end of the file with:

```text
## 4. The duties

Each runs only when §1 says the repo uses Quartz. Without it, the status and the decisions go to files instead (the
end of this section).

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
- **The status note,** at every step of the relay (below). A fresh session reads it (`SKILL.md`, Finding where work
  stands), so the owner never has to ask for notes before a clear.
- **A decision note** whenever the owner decides something, at a stop or in a brainstorm: at once, an ordinary note on
  the card (`add_note` without `status`), `Decision (<where>): <what was decided>. Why: <the reason given>.`, where
  `<where>` is the stop, `brainstorm` or the leg. When the owner gives no reason, write "no reason given".
- **Proposed cards** are filed by the agent that found the issue, with the label `proposed` (`reviewing.md` §2). The
  owner prunes them on the board, and stop 4 gives only their number.

**The status note** is one `add_note` with `status: true` on each of the plan's cards (its card line, or its spec's),
at most 500 characters; it replaces the card's previous status. It holds one line for each of the card's plans in
flight:

`` `<plan path>`: <where it stands>; next: <what>; agents: <id> (<role>), <id> (<role>) ``

`agents:` names each agent dispatched for that plan whose report has not come back, by its id (in OpenCode, its
`sessionID`), and is left out when none is running. The skill-test runs go by their number, as in
`agents: 28 skill-test runs`, since their answer files say which are done. With several plans on one card, read the
card's status first (`get_task`) and keep the other plans' lines. During a brainstorm, before any plan, the status is
one line: `brainstorm: <where it stands>; next: <what>`.

Post it at each of these moments, where the leg file says:

| # | Moment | `<where it stands>` | `next:` |
|---|---|---|---|
| 1 | The planners are dispatched (`planning.md` §1) | `planning` | `stop 3` |
| 2 | Stop 3 is sent, and the owner answers it (`planning.md` §3) | `at stop 3`; then `approved, <mode>`, `plan review`, `changes` or `research` | `the owner's answer`; then `the handoff` or `stop 3` |
| 3 | The executor is dispatched (`dispatching.md` §5) | `executing on <branch> (<mode>)` | `verify the hand-back` |
| 4 | The hand-back is verified (`dispatching.md` §7) | `hand-back verified` | `acceptance` |
| 5 | The acceptance reviewer is dispatched, and each fix round (`reviewing.md` §1 and §2) | `acceptance`; `fix round <k> of <cap>: <step ids or findings>` | `the fix loop`; `verify the fix` |
| 6 | The fix loop ends (`reviewing.md` §2) | `acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds` | `the code review and the skill tests` |
| 7 | The code review and the skill tests are dispatched (`reviewing.md` §3) | `code review and skill tests` | `stop 4` |
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN` | `stop 4` |
| 9 | Stop 4 is sent, and the owner answers it (`reviewing.md` §4) | `at stop 4`; then `merge approved`, `held` or `one more round` | `the owner's answer`; then `the merge`, `the owner` or `verify the fix` |
| 10 | The branch has merged, and the acceptance task is ticked (`reviewing.md` §5) | `merged in <short sha>`; then `done` | `after merge steps <ids>`; then `nothing` |

A note that fails is reported once, in one line (§2), and the leg carries on.

**Without Quartz,** the record is kept in files in the main checkout, never in a memory file:

- the plan's line goes to its run folder's `status`, replacing what is there, from when the folder exists
  (`dispatching.md` §3); before that, the files and git say where the plan stands;
- the owner's decisions go to the run folder's `decisions.md`, one line each, appended; before the folder exists, to
  the topic's `brainstorm.md` (next);
- a brainstorm keeps its decisions and its status in `.hyper-relay/runs/<topic>/brainstorm.md`, appended, where
  `<topic>` is the spec's file name without its date and `-design`. When `git check-ignore -q .hyper-relay/runs/`
  fails in the main checkout, first add a `.hyper-relay/runs/` line to the file
  `git rev-parse --git-path info/exclude` prints there.
```

In `skills/brainstorming/SKILL.md`, insert after the line `message, like anything else they pointed at.` (line 63),
which ends the **Quartz.** paragraph:

```text

**Decisions go on the card as they happen.** Whenever your human partner
decides something (an answer that changes the design, the approach they
pick, a part of the playback they confirm), add a note on the card in
that turn, with the decision and the reason they gave, and update the
card's status to say where the brainstorm stands and what comes next.
The forms, and where both go without Quartz, are in the same
`quartz.md`, §4. Your human partner never has to ask for notes.
```

- [x] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -n -F 'never keep relay state in a memory file' skills/orchestrating/SKILL.md` | one line |
| `grep -c -F 'command -v relay-plan' skills/orchestrating/SKILL.md` | `1` (Review Focus 5) |
| `grep -c -F 'a good moment to clear' skills/orchestrating/SKILL.md` | `2` |
| `grep -c -F -e 'keep the other plans' -e 'sessionID' -e '500 characters' skills/orchestrating/quartz.md` | `3` (Review Focus 2, 5) |
| `grep -c -E '^\| (10\|[1-9]) \|' skills/orchestrating/quartz.md` | `14` (§1's four rows and §4's ten moments) |
| `grep -c -F -e 'decisions.md' -e 'brainstorm.md' skills/orchestrating/quartz.md` | `3` (Review Focus 1) |
| `grep -c -F 'Decisions go on the card as they happen' skills/brainstorming/SKILL.md` | `1` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `39 passed, 0 failed` |

- [x] **Step 5: Commit.**

```bash
git add skills/orchestrating/SKILL.md skills/orchestrating/quartz.md skills/brainstorming/SKILL.md tests/orchestrating/run-tests.sh
git commit -m "feat: the board holds the relay's state: status and decision notes, no private state" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: planning, the handoff and the conflict check ask `relay-plan` (spec §3, §4, §5, §7; P5, P11, P13, A1)

**Files:**
- Modify: `skills/orchestrating/planning.md:10-12`, `:40-65` (§2), `:66-92` (§3 through the plan review bullet)
- Modify: `skills/orchestrating/dispatching.md:15-17`, `:70` (a paragraph after it), `:89-99`, `:115-132`
- Modify: `skills/orchestrating/parallel.md:52-72`
- Test: `tests/orchestrating/run-tests.sh`

**Interfaces:**
- Consumes: Task 4's moments and section names (its Interfaces block).

- [x] **Step 1: Write the failing check.** A section `# --- 13. The orchestrator asks relay-plan instead of grepping
  the plan.` with `no_plan_greps`: it passes when `none -F -e "'^### Task'" -e '^- (Create|Modify|Test)' -e "grep -n
  -o 'Plan-Task:" skills/orchestrating`. Add it to `CHECKS`. Its broken case: `broken "the acceptance grep back in
  planning.md"`; append a line holding exactly
  ``\`grep -n '^### Task' <plan> | tail -n 1\` names the last task.`` to `$CASE/skills/orchestrating/planning.md`;
  `expect_fail no_plan_greps`. `Expect:` becomes `"41 passed, 0 failed"`.

- [x] **Step 2: Run it to verify it fails**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 8`
Expected: `FAIL no_plan_greps` above (naming lines of `planning.md` and `parallel.md`), and the last line
`40 passed, 1 failed`.

- [x] **Step 3: The text.** In `skills/orchestrating/planning.md`, replace:

```text
the owner approved, dispatch the planners in the background. The approval is the go-ahead: do not ask again. Then tell
the owner they are running, and carry on.
```

with:

```text
the owner approved, dispatch the planners in the background. The approval is the go-ahead: do not ask again. Then add
a decision note for the approval and post the status note, naming each planner by its id (`quartz.md` §4, moment 1),
tell the owner they are running, and carry on.
```

Replace the lines from `## 2. Check the hand-back` through the blank line before `## 3. Stop 3` with:

```text
## 2. Check the hand-back

With `relay-plan` (`SKILL.md`, Plans and reports by path), before the owner sees anything: you never read the plan
whole. For each plan, in the main checkout, run `relay-plan check <plan> --spec <spec>`, adding `--sibling <plan>`
for each sibling plan and `--base <base plan>` for a stacked one. It prints one line per check, `ok <check>` or
`FAIL <check>: <detail>`: the plan is committed (during a branch run, the file exists); it has its card line, when
the spec names a card; each task that commits carries its own `Plan-Task:` trailer once; each acceptance step names
who runs it; each `skill-test` step has its situation in a fence, `GREEN must:` and `RED is expected to:`; no
placeholders; the Spec coverage table maps every section of the spec; sibling plans' Contract sections are
identical; a stacked plan names its base in `**Builds on:**`. Then:

- **During a branch run:** the planner's report says it ran `quartz link-doc`, and with the Quartz MCP, `get_task` on
  the card lists the plan among its docs. When the repo does not use Quartz (`quartz.md` §1), the file is enough.
- **Several plans, or one joining a plan in flight:** `relay-plan overlap <plan> <other>…`, `parallel.md` §2's
  conflict check. A numbered collision goes back to the later plan's planner, like a failed check; shared files
  become lines in the handoff question.

A `FAIL` line goes back to the planner before stop 3, verbatim: resumed (`SKILL.md`, Fallbacks), or a fresh planner
given the lines.

```

Replace the lines from `## 3. Stop 3` through the line `  changed.` that ends the **A plan review:** bullet with:

```text
## 3. Stop 3

Post the status note first (`quartz.md` §4, moment 2). Then one message, which ends there. It opens with its
questions, numbered, in this order (`SKILL.md`, The stops):

- each decision the owner must make;
- each assumption the planner made where the spec was silent, which the owner can accept, correct, or answer with
  "research it" (below);
- "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the spec.";
- the handoff question from `dispatching.md` §1, with its warnings: for several plans, or a plan joining one in
  flight, a line per plan and a line per overlap (`parallel.md` §1 and §2).

Then the report, short, one line per item:

- the plan paths and their task counts (the first line `relay-plan steps <plan>` prints);
- a line per plan, "plan N lines for an M-line spec", from `wc -l` on the plan and on its spec;
- the planner's deviations and ambiguities, with its resolutions;
- the facts it re-checked (those the spec flagged), and any differences;
- last, the line that says this is a good moment to clear (`SKILL.md`, The stops).

When the owner answers, add a decision note for each thing they decide, and post the status note again (moment 2).
The answer leads one of four ways:

- **Approve, with a mode:** `dispatching.md` §2, for each plan that starts now (`parallel.md` §1 says when the others
  start). The answer is the go-ahead: do not ask again.
- **A plan review:** create the plan's run folder with `relay-plan run-dir <plan>` (`dispatching.md` §3), and
  dispatch a general-purpose agent on Sonnet (`SKILL.md`, Fallbacks) with `writing-plans`'
  `plan-document-reviewer-prompt.md` (`../writing-plans/plan-document-reviewer-prompt.md` from this file), filled in
  with the plan's and the spec's paths and the run folder. It writes its findings to `plan-review.md` there and
  replies with its verdict and counts. The planner gets that file's path, not its text, revises the plan and commits
  it again. Then §2, and a short stop 3 in the same order: any new decision and the handoff question again, then what
  changed.
```

In `skills/orchestrating/dispatching.md`, replace:

```text
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one.
```

with:

```text
the header of `main`'s facts file (`git show main:.hyper-relay/agents.md`, between its first two `---` lines), if the
repo has one. N below, the plan's task count, is in the first line `relay-plan steps <plan>` prints:
`tasks <N>; acceptance task <M>`.
```

Insert after the line ``  that outlives one command. Run commands there as `(cd <worktree> && …)` or `git -C <worktree> …`.``
(line 70), the last line of §3:

```text

Then, in either mode, create the plan's run folder: `relay-plan run-dir <plan>`, in the main checkout. It prints the
folder's absolute path, `<main checkout>/.hyper-relay/runs/<branch>/`, which git ignores (it adds the line to the
repo's local exclude file when needed); it never clears what an earlier leg left there. Every dispatch prompt from
here on names it: each agent writes its full report there (`SKILL.md`, Plans and reports by path), and its
`acceptance/` is the acceptance reviewer's evidence folder.
```

Replace the lines from ``The prompt gives what `hyper-relay:executing-plans` lists`` through
`background, the dispatch waits for it; every rule below still holds.` with:

```text
The prompt gives what `hyper-relay:executing-plans` lists under "The dispatch prompt gives":
- the plan's path (absolute when it is not committed on `main`), and which tasks are the executor's: every task
  before the acceptance task that the first line of `relay-plan steps <plan>` names, e.g. "Tasks 1–8; Task 9 is the
  orchestrator's" for `tasks 9; acceptance task 9`;
- the mode, `branch` or `worktree`;
- the checkout's absolute path (the main checkout, or the worktree) and the branch;
- the run folder (§3);
- when the repo uses Quartz, the plan's card ids and its initiative; otherwise "Run no Quartz command and use no
  Quartz tool.";
- the Claude-Session URL for its commit trailers, when your harness gives you one;
- for a stacked plan: that its branch was cut from its base's branch, `<base branch>`, which has not merged yet;
- anything unusual: `main` moved since the plan was written, a plan read by absolute path, a step you know is stale.

Then post the status note, with the executor's id (`quartz.md` §4, moment 3), tell the owner it is running, and carry
on with other work. Where the harness cannot run a subagent in the background, the dispatch waits for it; every rule
below still holds.
```

Replace the lines from `## 7. Verify the hand-back` through the end of the file with:

```text
## 7. Verify the hand-back

The executor hands back a short summary; its full report is the run folder's `executor.md`, which you open only for
what the summary does not settle. Before relaying anything, where the branch is checked out (for a stacked plan, only
once its base has merged and any catch-up round is done: `parallel.md` §3):

1. **The gates, from `gates.log`:** `relay-plan gates <plan>`, then each gate's command as the summary names it,
   each quoted as one argument. Every line must be `ok`, which means that gate's latest run passed at the branch's
   tip, and its last output must match the counts the summary gives. You rerun no gate yourself: `relay-merge`
   runs them again on the merged result. A `FAIL` line, or counts that do not match, is a failure for the owner.
2. Check the commits: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>`. Each of the executor's
   tasks ends in a commit carrying its `Plan-Task:` trailer.
3. Check the tree is clean: `GIT_OPTIONAL_LOCKS=0 git status --short` prints nothing but, on a branch run, your
   held-back docs (`??` under `docs/superpowers/`).
4. Weigh every deviation the summary lists, and every call the executor made where the plan left a choice open:
   accept each, or tell the owner why not.
5. Act on every `quartz:` line the summary quotes, and file any cards it says are in `cards.md` (`reviewing.md` §2).

Then run `quartz review` there (the cards move to In review); if it fails, move the cards by hand through the Quartz
MCP. Post the status note (`quartz.md` §4, moment 4). Tell the owner only failures, gate results, deviations and the
decisions you need: the board shows the rest.

Then continue with `reviewing.md`.
```

In `skills/orchestrating/parallel.md`, replace the lines from `## 2. The conflict check` through the blank line
before `**What happens.**` with:

```text
## 2. The conflict check

Before each dispatch that joins another plan in flight, or a plan approved to run beside it, compare the plan with
each of them: `relay-plan overlap <plan> <other>…`, where each `<other>` is a plan's path or an in-flight plan's
branch. Run it before the handoff question (`planning.md` §2), and again just before a waiting plan is dispatched. It
prints one line per overlap, and nothing when there is none:

- **`shared <path> (<other>)`:** both change the file. A plan's paths are its tasks' `- Create:`, `- Modify:` and
  `- Test:` paths; an in-flight branch's are its plan's, plus what the branch has changed so far.
- **`numbered <folder><digits> (<other>)`:** both create files in the same folder whose names start with the same
  digits, followed by `_` or `.`, such as migrations (`000097_orders.up.sql` and `000097_coupons.up.sql`); a date
  (`2026-11-18-…`) is not a sequence number.

```

- [x] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'relay-plan check <plan> --spec <spec>' skills/orchestrating/planning.md` | `1` |
| `grep -c -F 'relay-plan run-dir <plan>' skills/orchestrating/planning.md skills/orchestrating/dispatching.md` | `skills/orchestrating/planning.md:1` and `skills/orchestrating/dispatching.md:1` |
| `grep -c -F "each gate's command as the summary names it" skills/orchestrating/dispatching.md` | `1` (Review Focus 3) |
| `grep -c -F 'Run no Quartz command and use no' skills/orchestrating/dispatching.md` | `1` (Review Focus 1) |
| `grep -c -i 'rerun the gates' skills/orchestrating/dispatching.md` | `0` |
| `grep -c -F 'relay-plan overlap' skills/orchestrating/parallel.md` | `1` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `41 passed, 0 failed` |

- [x] **Step 5: Commit.**

```bash
git add skills/orchestrating/planning.md skills/orchestrating/dispatching.md skills/orchestrating/parallel.md tests/orchestrating/run-tests.sh
git commit -m "feat: planning, the handoff and the conflict check ask relay-plan, never read the plan whole" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: the review leg by path, the fix-round cap, the `agents` skill and `README.md`; the full gates (spec §2, §3, §5, §6, §7, §8; P4, P5, P8, P9, P12, P14, P16)

**Files:**
- Modify: `skills/orchestrating/reviewing.md` (rewritten whole)
- Modify: `skills/agents/SKILL.md:60` (a row after it)
- Modify: `README.md:62-64`, `:96` (two bullets after it), `:98-99`
- Test: `tests/orchestrating/run-tests.sh`

**Interfaces:**
- Consumes: Task 4's moments and section names; Task 5's §7 check 1 (`dispatching.md`), which §2 below reuses.

- [ ] **Step 1: Write the failing checks.** Three sections:
  - `# --- 14. The orchestrator routes by path.` with `relay_plan_routes_the_plan`: for each of the fixed strings
    `relay-plan run-dir`, `relay-plan check`, `relay-plan overlap`, `relay-plan steps`, `relay-plan step <`,
    `relay-plan scenarios` and `relay-plan gates`, some file under `skills/orchestrating` holds it
    (`grep -r -q -F`); it prints each one missing.
  - `# --- 15. No check runs twice.` with `no_gate_reruns`: `none -i -F 'rerun the gates' skills/orchestrating`.
  - `# --- 16. The fix-round cap.` with `fix_cap`: `skills/orchestrating/reviewing.md` and `skills/agents/SKILL.md`
    each have a line holding `fix-rounds`, and `none -i -E 'second (failed )?fix round' skills/orchestrating`.

  Add the three to `CHECKS`. Their broken cases: `broken "no relay-plan scenarios"`; delete every line holding
  `relay-plan scenarios` from each `$CASE/skills/orchestrating/*.md`; `expect_fail relay_plan_routes_the_plan`.
  `broken "the hand-back rerunning the gates"`; append `\nRerun the gates the report names.\n` to
  `$CASE/skills/orchestrating/dispatching.md`; `expect_fail no_gate_reruns`. `broken "a second fix round going to the
  owner"`; append `\nA step that fails again after its second fix round goes to the owner.\n` to
  `$CASE/skills/orchestrating/reviewing.md`; `expect_fail fix_cap`. `broken "the agents skill without fix-rounds"`;
  delete every line holding `fix-rounds` from `$CASE/skills/agents/SKILL.md`; `expect_fail fix_cap`. `Expect:` becomes
  `"48 passed, 0 failed"`.

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/orchestrating/run-tests.sh | tail -n 14`
Expected: `FAIL relay_plan_routes_the_plan` (naming `relay-plan step <` and `relay-plan scenarios`),
`FAIL no_gate_reruns` (naming `reviewing.md`) and `FAIL fix_cap`, and the last line `45 passed, 3 failed`.

- [ ] **Step 3: `reviewing.md`.** Replace `skills/orchestrating/reviewing.md` with exactly this content:

```text
# The review leg, the click-through and the merge

The last leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when `dispatching.md` §7 has
verified the executor's hand-back and run `quartz review`, and it runs on its own until stop 4, except for a gap in
the spec or plan, which goes to the owner at once. You review nothing yourself: the acceptance reviewer, the code
reviewer and the skill-test judge do, each in its own context. Each writes its full report to the plan's run folder
(`dispatching.md` §3) and hands back a short summary; you open a report only for a line the summary does not settle.

## 1. Acceptance

Dispatch the repo's `<project>-reviewer` (`.claude/agents/<project>-reviewer.md`) in the background. The prompt
gives:

- the plan's path and its acceptance task (its last task);
- **the step numbers marked `reviewer`**, which are the only ones it runs: `relay-plan steps <plan> reviewer` lists
  them;
- the checkout and the branch;
- what the executor's summary says it left running (URLs, logins);
- the run folder, whose `acceptance/` is its evidence folder and holds its full report, `report.md`;
- when the repo uses Quartz, the plan's initiative, for the cards it files; otherwise "Run no Quartz command and use
  no Quartz tool."

Then post the status note (`quartz.md` §4, moment 5). When the plan has no `reviewer` steps, skip the dispatch, say
so at stop 4, and post moment 6's status now, as `acceptance done, no reviewer steps`.

**Without a generated reviewer** (`SKILL.md`, Fallbacks), dispatch a general-purpose agent (in OpenCode, the
`general` subagent) with the same prompt and this standing brief:

> You are report-only. Run each named step exactly as the plan writes it. For each, give PASS, FAIL or NEEDS-HUMAN,
> with the command, the lines that decide it and the exit code, quoted. Save each step's output in the evidence
> folder, and write your full report to its `report.md`. Classify each finding as BLOCKING (this plan's work is
> wrong, or a step fails), PRE-EXISTING (caused by earlier work) or POLISH (works, but could be better). File each
> PRE-EXISTING and POLISH finding as a proposed card: `add_tasks` with the label `proposed`, kind `bug` or `change`,
> the initiative this prompt gives, and a body naming the plan, the file and the evidence path. When `add_tasks`
> fails, or this prompt says to use no Quartz tool, append the card to the run folder's `cards.md` instead, as a
> `## <title>` section with its kind, the file, the evidence and why. Write nowhere else. Never edit, commit, install
> anything or change any config. Hand back only a short summary: the verdict line, one line per step, each BLOCKING
> finding in one line with its evidence path, the cards you filed, and the path of `report.md`.

**Verify the summary:**

- every named step has a verdict;
- each PASS has its evidence file in `acceptance/`; a PASS without one counts as not run: it goes back to the
  reviewer;
- rerun one FAIL yourself, where its command is read-only, to confirm it is real (`relay-plan step <plan> <id>` gives
  the step's text).

## 2. The fix loop

Sort each FAIL and each BLOCKING finding:

| Kind | Goes to |
|---|---|
| An execution bug: the code does not do what the plan says | A fix round: the executor that ran the plan, resumed with its context (`SKILL.md`, Fallbacks). When it cannot be resumed, a fresh executor, dispatched as `dispatching.md` §5 says, with the plan and the findings. |
| A gap in the spec or the plan | The owner, at once, who decides: fix it on this branch (it goes to the executor as a finding, and you record it as a deviation), or a new card |

PRE-EXISTING and POLISH findings are not in the loop: the reviewer has filed them as proposed cards (below).

The executor's fix prompt gives:

- fix round `<k>` of the cap, and the findings, each as its verdict line and its evidence path in the run folder;
- the plan, the mode, the checkout, the branch and the run folder;
- fix root causes;
- commit each fix staging named files only, with the attribution lines and **no** `Plan-Task:` trailer;
- rerun only the tests that pin the fix, each through `relay-plan gate <plan> '<command>'`, not the full gates;
- append a `## Fix round <k>` section to `executor.md`, and hand back the short summary, naming those tests by their
  commands.

Post the status note when you send it (moment 5). After the fix, verify it with `dispatching.md` §7's checks, where
check 1 is `relay-plan gates <plan>` followed by the commands the round names: the full gates' earlier runs are older
than the new tip, so naming no command would fail by design. `quartz review` does not run again: the cards are
already In review. Then the reviewer, resumed or fresh, reruns only the steps that failed, and appends a
`## Rerun after fix round <k>` section to `report.md`.

**The fix-round cap.** Read `fix-rounds:` from the header of `main`'s facts file, as `dispatching.md` §1 reads
`execute:`; without it, the cap is 2. A finding (an acceptance FAIL, a Critical, a GREEN that failed) that still fails
after that many rounds gets no further round. File a card for it: `add_tasks` with the label `proposed`, kind `bug`,
the plan's initiative, and a body naming the plan, the step or finding, its evidence paths and "fix cap reached after
<n> rounds" (without Quartz, a section in `cards.md`). Then carry on with the rest of the loop; stop 4 opens with it
(§4). A gap in the spec or the plan is not capped: it goes to the owner at once.

**Proposed cards.** The agent that finds an issue files it: the acceptance reviewer its PRE-EXISTING and POLISH
findings, the code reviewer its Important and Minor ones (§3), the executor an issue it noticed outside its plan.
Each is an `add_tasks` card with the label `proposed`, kind `bug` or `change`, the plan's initiative, and a body
naming the plan, the file and the evidence (a path in the run folder); the agent's summary lists the card ids. When a
summary says the cards went to the run folder's `cards.md` instead (its `add_tasks` failed), file them yourself in one
`add_tasks` call, then delete `cards.md`. Without Quartz, `cards.md` keeps them for stop 4.

When the fix loop ends (every FAIL fixed, capped, or made a card by the owner), post the status note (moment 6):
`acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds`, where N of the M `reviewer` steps passed and K are
NEEDS-HUMAN, after F fix rounds, with `; step <id> capped, card <card id>` for each capped step. A note that fails is
reported once, in one line (`quartz.md` §2).

When the fix loop ends and a plan is stacked on this one, cut and dispatch it now (`parallel.md` §3).

## 3. The code review, last

When every acceptance FAIL is fixed, capped, or turned into a card by the owner (NEEDS-HUMAN steps may remain), run
one code review of the whole branch, as `hyper-relay:requesting-code-review` says: a general-purpose agent on Sonnet
(`SKILL.md`, Fallbacks), given that skill's `code-reviewer.md` (`../requesting-code-review/code-reviewer.md` from
this file) with the range `$(git merge-base main <branch>)..<branch>`, the plan, the spec, the run folder and the
plan's initiative ("none" without Quartz). It writes its review to the run folder's `code-review.md`, files its
Important and Minor findings as proposed cards (§2), and hands back a short summary. It runs once per branch, after
acceptance and its fixes, so it reads the final diff.

**A Critical** finding: check each one against the code first (`hyper-relay:receiving-code-review`), from its lines
in `code-review.md`. A wrong one is dropped, with the reason, in the stop-4 report. A real one is a fix round (§2),
and counts toward the cap. Then resume the code reviewer to check only the fix commits (when it cannot be resumed,
read that diff yourself), and have the acceptance reviewer rerun the steps the fix touches (all its steps, when that
is unclear).

**The skill tests** run when the plan's acceptance task has `skill-test` steps (`relay-plan steps <plan> skill-test`
lists them; `hyper-relay:writing-plans` requires them in a plan that creates or changes a file in a skill's folder),
at the same time as the code review. They are `hyper-relay:writing-skills`' RED/GREEN pressure tests. You never read
the steps yourself: `relay-plan` hands their situations to the runs, and a judge reads the rest. `<run>` is the run
folder:

1. Put the skills from `main` and from the branch in `<run>/skill-tests/red/` and `<run>/skill-tests/green/`:
   `mkdir -p <run>/skill-tests/red <run>/skill-tests/green`, then
   `git cat-file -e main:<skills> 2>/dev/null && git archive main <skills> | tar -x -C <run>/skill-tests/red` and
   `git archive <branch> <skills> | tar -x -C <run>/skill-tests/green`. `<skills>` is the folder that holds the
   repo's skill folders (`skills` in a plugin, `.claude/skills` in a project). When `main` has no such folder, the
   `cat-file` check fails, nothing is copied and `red/` stays empty: RED then reads no skill at all, as it should
   for a new skill.
2. `relay-plan scenarios <plan> <run>/skill-tests` writes each step's situation to `step-<id>.txt` there, and prints
   one line per step: its id, the file and its title. When it exits 1 (a step's situation is not in a fence, as in a
   plan written before that rule), tell the owner and stop the skill tests: you do not read the steps yourself.
3. Dispatch two runs per step, in the background, each to a general-purpose agent on Sonnet (`SKILL.md`,
   Fallbacks): GREEN given `<run>/skill-tests/green`, RED given `<run>/skill-tests/red`. Each prompt is this
   preamble, filled in, and nothing else:

   > You are taking part in a test of written skills. Your situation is in `<run>/skill-tests/step-<id>.txt`, and the
   > skills are in `<the folder>`. Read the situation, then the skills it needs, from those two places only, and
   > nothing else on this machine. Run no command. Act as the agent the situation names. Write your answer to
   > `<run>/skill-tests/step-<id>-<green or red>.md`: the commands you would run, in order, and the next message you
   > would send, verbatim. Change no other file, and reply `done`.

4. When every run has replied, dispatch one judge, a general-purpose agent on Sonnet, with this prompt, filled in:

   > You judge a test of written skills. The acceptance task of the plan `<plan>` has the `skill-test` steps `<ids>`;
   > `relay-plan step <plan> <id>` prints one, with what GREEN must do and what RED is expected to do. In
   > `<run>/skill-tests/`, `step-<id>-green.md` answers that step's situation from the branch's skills, and
   > `step-<id>-red.md` from `main`'s. For each step, judge whether the GREEN answer does what GREEN must, and whether
   > the RED answer fails as RED is expected to: a RED that already does what GREEN must does not fail. Write
   > `verdicts.md` in that folder: for each step, its verdict and the lines of each answer that decide it, quoted.
   > Change no other file. Reply with one line per step, and nothing else:
   > `<id>: GREEN pass|fail, RED fails|does not fail: <reason, at most 15 words>`.

5. A GREEN that fails is a fix round (§2), with the step's id and the path of `verdicts.md` as its finding. After the
   fix, put a fresh copy of the branch's skills in `green/`, rerun that step's GREEN, and have the judge, resumed or
   fresh, judge that step again. A RED that does not fail means the scenario does not test the change: stop 4 says
   so, and it blocks nothing.

Post the status note when you dispatch the code review and the skill-test runs (moment 7), and when the code review,
its Critical fixes and the skill tests are done (moment 8):

`code review done, C Critical (x fixed, y dropped), I Important, m Minor; skill tests G/S GREEN`

The skill tests' part counts the S scenarios and the G whose GREEN passed; a plan without skill tests leaves out
"; skill tests G/S GREEN".

## 4. Stop 4, the click-through and the merge

**Wait for every leg's usage first.** Before writing stop 4, wait for the completion notification of every agent this
run dispatched: the executor and its fix rounds, the acceptance reviewer, the code reviewer, each skill-test run and
the judge. An agent's reply arrives before the notification that carries its usage. Where the harness reports no
usage, stop 4 says so.

Post the status note first (moment 9). Then one message, which ends there. It opens with its questions, numbered, in
this order (`SKILL.md`, The stops):

- for each finding that reached the fix-round cap (§2): "Step <id> still fails after <n> fix rounds (card
  `<card id>`): merge with it open, hold the branch, or one more round?";
- the NEEDS-HUMAN steps and the plan's `owner` steps, which the owner runs at the click-through:
  `relay-plan steps <plan> owner` lists them, and `relay-plan step <plan> <id>` gives the text of one you show or
  run;
- where to click through (below).

Then the report, short, one line per item:

- the acceptance verdicts;
- the skill-test verdicts, the judge's line for each scenario, naming each RED that did not fail;
- each fix round, and what it changed;
- the Critical findings fixed, and those dropped with why;
- the proposed cards filed during the run, as their number (the owner prunes them on the board); without Quartz,
  each card in `cards.md` instead, one line each (title, file, why), for the owner to keep or drop;
- each deviation recorded on the way, such as an overlap the owner chose to run at once (`parallel.md` §2);
- the token counts of the acceptance reviewer, the code reviewer and the skill-test runs against the executor's, as
  your harness reports them ("not reported" where it reports none), until the owner says they have seen enough;
- last, the line that says this is a good moment to clear (`SKILL.md`, The stops).

Stop 4 promises a Quartz tick only where `quartz.md` §3 says one will come.

When the owner answers, add a decision note for each thing they decide, and post the status note again (moment 9).
"One more round" for a capped finding is a fix round (§2), then a short stop 4 again. Without Quartz, the cards the
owner keeps stay listed in stop 4.

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
(`git switch <branch>`): an executor works only where its branch is checked out. Verify the round as §2 does, with
check 1 naming the full gates the round reran; it counts toward no fix-round cap. Then a short stop 4 again, since
the code changed after review: the conflict, how it was resolved, the gates. On the owner's go-ahead, the merge again.

**A failed gate** (exit 3): stop, and bring the owner the log's tail that `relay-merge` printed, at once, in a message
of its own. Nothing else lands until the owner decides:

- **Undo the unpushed merge:** check that `git log -1 --format=%s main` prints `Merge branch '<branch>'` and
  `git branch -r --contains main` prints nothing, then run `git reset --keep HEAD^1` in the main checkout on `main`.
  The branch and its worktree are still there: the failure goes to its executor as a fix round (§2; after a branch
  run, `git switch <branch>` first), then a short stop 4 again.
- **Fix forward:** on a new branch, as the owner says.

Plans in flight keep executing in their worktrees meanwhile.

## 5. After the merge

After a branch merge, the main checkout is back on `main`. Make the edits that waited, and commit the specs and plans
you held back, each staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks
upload them. Where Quartz's hook ticks tasks (`quartz.md` §3), the ticks queued during the run drain at the next
stop.

Post the status note (moment 10), naming the `after merge` steps left. Then, in either mode, run them with the
owner: `relay-plan steps <plan> after-merge` lists them, and `relay-plan step <plan> <id>` gives each one's text as
you reach it. When they are done, tick the acceptance task by hand if no commit ticked it; where nothing ticks a
committed task (`quartz.md` §3), tick every task with a `Plan-Task:` commit in the same edit. Post the status note
once more, as `done`. A plan stacked on this one, or waiting for it, goes on now (`parallel.md` §4).
```

- [ ] **Step 4: The `agents` skill and `README.md`.** In `skills/agents/SKILL.md`, insert after the table row that
  begins ``| `execute` |`` (line 60):

```text
| `fix-rounds` | A whole number from 1 to 9: how many fix rounds a finding that keeps failing gets before the orchestrator files it as a card and stops working on it (`hyper-relay:orchestrating`'s `reviewing.md`). Without it, 2. The generator only checks the value. |
```

In `README.md`, replace:

```text
`orchestrating` runs the legs from an approved spec to the merge: it dispatches the planner, the executor and the
reviewers, checks what each hands back, and stops for you at four points (the design, the spec, the plan and the
merge).
```

with:

```text
`orchestrating` runs the legs from an approved spec to the merge: it dispatches the planner, the executor and the
reviewers, checks what each hands back, and stops for you at four points (the design, the spec, the plan and the
merge). Each agent writes its full report to the plan's run folder (`.hyper-relay/runs/<branch>/`, ignored by git) and
hands back a short summary, and the orchestrator reads a plan through `relay-plan`, never whole. No check runs twice
before the merge: the executor's gates are saved to a log the orchestrator reads, and `relay-merge` runs them once
more on the merged result. A finding that still fails after the repo's fix-round cap (two rounds unless
`.hyper-relay/agents.md` sets `fix-rounds`) becomes a card instead of another round.
```

Insert after the line `  merged (a git hook).` (line 96):

```text
- **The board holds the state.** Each card's status says where each of its plans stands, what comes next and which
  agents are running, and your decisions go on it as notes as you make them. You can clear the conversation at any
  moment without asking for notes first: a fresh session picks up from the board.
- **Issues found on the way become proposed cards,** labelled `proposed` and filed by the agent that found them, for
  you to prune on the board.
```

Replace:

```text
Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown, and the skills work on their own. But
the board is half the point: it is what lets a long-running, multi-agent pipeline stay legible.
```

with:

```text
Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown and files (a plan's status and its
proposed cards go to its run folder), and the skills work on their own. But the board is half the point: it is what
lets a long-running, multi-agent pipeline stay legible.
```

- [ ] **Step 5: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'followed by the commands the round names' skills/orchestrating/reviewing.md` | `1` (Review Focus 3) |
| `grep -c -F 'tell the owner and stop the skill tests' skills/orchestrating/reviewing.md` | `1` (Review Focus 4) |
| `grep -c -F -e 'scratchpad' -e 'mktemp' skills/orchestrating/reviewing.md` | `0` |
| `grep -c -F 'Run no Quartz command and use' skills/orchestrating/reviewing.md` | `1` (Review Focus 1) |
| `grep -c -E '^## [1-5]\. ' skills/orchestrating/reviewing.md` | `5` |
| `grep -c -F 'fix-rounds' skills/agents/SKILL.md` | `1` |
| `grep -c -F 'Issues found on the way become proposed cards' README.md` | `1` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `48 passed, 0 failed` |

- [ ] **Step 6: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `48 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | ends `0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout) |
| `git diff --name-only main...HEAD` | exactly `README.md`, `skills/agents/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/executing-plans/SKILL.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/dispatching.md`, `skills/orchestrating/parallel.md`, `skills/orchestrating/planning.md`, `skills/orchestrating/quartz.md`, `skills/orchestrating/reviewing.md`, `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `templates/agents/executor.md`, `templates/agents/reviewer-browser.md`, `templates/agents/reviewer-commands.md`, `tests/orchestrating/run-tests.sh` |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

- [ ] **Step 7: Commit.**

```bash
git add skills/orchestrating/reviewing.md skills/agents/SKILL.md README.md tests/orchestrating/run-tests.sh
git commit -m "feat: the review leg by path, scenario files and a judge, and the fix-round cap" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 7: Acceptance (spec §9, §10, §11; P8, P17, P18, P20). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, from the top of the checkout on the branch
  (`hyper-relay-lighter-orchestrator-skills`) its dispatch names (Steps 1–4). No step reruns the gates (P17).
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the installed relay's skill-test
  leg (`reviewing.md` §3): its `red/` and `green/` folders hold `main`'s and the branch's `skills/`. Steps 5–18 are
  S1–S14; each situation is whole in its fence (P7).
- **`owner`**: the owner, at the click-through (Steps 19–20); the orchestrator runs the commands.
- **`after merge`**: the orchestrator with the owner, once the branch is merged and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 21–25). The orchestrator runs the commands; the owner runs the
  plugin update, the reload and the live probe's clears.

In a command inside a table cell, `\|` is a plain `|`. **This plan's run follows the installed relay**, not the text
it writes: the new behaviour reaches a session only after the release and the owner's update (Steps 21–22).

- [ ] **Step 1 (`reviewer`): Only the planned files (spec §8, §12; P17).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the eighteen files of Task 6 Step 6 |
| `git diff main...HEAD -- skills templates README.md \| grep -c -E '^\+.*(/home/\|/tmp/\|/Users/)'` | `0` |
| `git diff --stat main...HEAD -- package.json .claude-plugin bin hooks templates/hooks templates/agents/planner.md .hyper-relay CLAUDE.md` | nothing |

- [ ] **Step 2 (`reviewer`): The text against the plan and the spec (spec §3–§8, §10).** Read
  `git diff main...HEAD -- skills templates README.md`. PASS: each hunk is one of Tasks 1–6's text edits, with its new
  text word for word, and `skills/orchestrating/reviewing.md` is Task 6 Step 3's content exactly; nothing else
  differs. Then read the spec (`docs/superpowers/specs/2026-11-20-hyper-relay-lighter-orchestrator-design.md`) §3–§8
  against the new text. PASS when each point below is said where the table puts it, and no sentence contradicts the
  spec beyond the P-notes; a contradiction is a FAIL, with its line.

| Spec point | Where |
|---|---|
| §3 the ten moments, the form, several plans on a card | `quartz.md` §4; each moment in its leg file (`planning.md` §1, §3; `dispatching.md` §5, §7; `reviewing.md` §1–§5) |
| §3 decision notes; brainstorming's few lines | `quartz.md` §4; `planning.md` §1, §3; `reviewing.md` §4; `brainstorming/SKILL.md` |
| §3 a fresh session, no private state, the clear line | `orchestrating/SKILL.md` (Finding where work stands, The stops) |
| §4 the run folder at the handoff and in every prompt; the short hand-backs; the two exceptions; read once | `dispatching.md` §3, §5; `reviewing.md` §1, §3; `executing-plans`; the three templates; `code-reviewer.md`; `plan-document-reviewer-prompt.md`; `orchestrating/SKILL.md`; `quartz.md` intro |
| §5 gates once, the hand-back check, no reviewer gate step, a fix round's tests | `executing-plans` step 5; `dispatching.md` §7; `writing-plans`; `reviewing.md` §2 |
| §6 proposed cards and their fallback; stop 4's one line; the cap | `executing-plans`; the reviewer templates; `code-reviewer.md`; `reviewing.md` §1, §2, §4; `orchestrating/SKILL.md` stops; `agents/SKILL.md` |
| §7 the routing table, `relay-plan` missing, the skill tests 1–5 | `planning.md` §2; `parallel.md` §2; `dispatching.md` §1, §5; `reviewing.md` §1, §3, §4, §5; `orchestrating/SKILL.md` |
| §8 `README.md` | its relay paragraph and its Quartz section |

- [ ] **Step 3 (`reviewer`): The generated agents carry the new text (spec §4, §6).** In a scratch repo inside the
  evidence folder, with this checkout's generator and templates; `<checkout>` is the checkout's absolute path. One
  command per run, in order.

| Run | PASS |
|---|---|
| `rm -rf <evidence folder>/agents-check` | exit 0 |
| `git init -q -b main <evidence folder>/agents-check` | exit 0 |
| `mkdir -p <evidence folder>/agents-check/.hyper-relay` | exit 0 |
| `cp .hyper-relay/agents.md <evidence folder>/agents-check/.hyper-relay/agents.md` | exit 0 |
| `cd <evidence folder>/agents-check && dash <checkout>/bin/hyper-relay-agents` | four `written` lines, exit 0 |
| `grep -c -F 'add_tasks' <evidence folder>/agents-check/.claude/agents/relay-reviewer.md` | `2` |
| `grep -c -F 'acceptance/' <evidence folder>/agents-check/.claude/agents/relay-reviewer.md` | `2` |
| `grep -c -F 'run folder' <evidence folder>/agents-check/.claude/agents/relay-executor.md` | `2` |
| `grep -l -F '{{' <evidence folder>/agents-check/.claude/agents/relay-planner.md <evidence folder>/agents-check/.claude/agents/relay-executor.md <evidence folder>/agents-check/.claude/agents/relay-reviewer.md` | nothing |
| `rm -rf <evidence folder>/agents-check` | exit 0 |

- [ ] **Step 4 (`reviewer`): `relay-plan` reads this plan (spec §7, §9; P7).** From the checkout's top.

| Run | PASS |
|---|---|
| `relay-plan check docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md --spec docs/superpowers/specs/2026-11-20-hyper-relay-lighter-orchestrator-design.md --sibling docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md` | every line `ok`, among them `ok contract` and `ok skill-tests`; exit 0 |
| `relay-plan steps docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md skill-test` | first `tasks 7; acceptance task 7`, then fourteen lines, ids 5 to 18 |
| `relay-plan scenarios docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md <evidence folder>/scenarios` | fourteen lines; exit 0 |
| `grep -l -x -E '<[A-Z][A-Z ]*>' <evidence folder>/scenarios/step-*.txt` | nothing (no placeholder line) |

- [ ] **Step 5 (`skill-test`): S1, the status at the executor's dispatch (§9 S1; §3).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

The owner approved P at stop 3 with "worktree". You have just set it up: `wt new coupon-codes --from main` made the
worktree; `relay-plan run-dir docs/superpowers/plans/2026-11-24-coupon-codes.md` printed the run folder's path; and
`quartz link-branch docs/superpowers/plans/2026-11-24-coupon-codes.md`, run in the worktree, moved the card to In
progress. Then you dispatched `shop-executor` in the background for P, and the Agent tool returned the id
`a3f9c2e1b7d04e6f`.

Give your commands and tool calls from here, in order, and your next message to the owner, verbatim.
```

GREEN must: before or with its message to the owner, call `add_note` with `status: true` on the card
`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, with one line that names P's path, says it is executing on `coupon-codes`
(worktree), gives `next: verify the hand-back` and names `a3f9c2e1b7d04e6f` as the executor, within 500 characters;
then tell the owner, briefly, that the executor is running.

RED is expected to: tell the owner the executor is running and post no status note (its text posts one only after
acceptance).

- [ ] **Step 6 (`skill-test`): S2, a notice after a `/clear` (§9 S2; §3).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

This conversation began with `/clear` a few minutes ago: nothing from before it is visible to you, and the owner has
not written since. A completion notice now arrives from a background agent with the id `a3f9c2e1b7d04e6f`, which
this conversation did not dispatch. Its reply reads:

  Tasks 6/6.
  Gates (/home/user/shop/.hyper-relay/runs/coupon-codes/gates.log): `npm test`: 212 passed, 0 failed;
  `npm run lint`: 0 problems.
  Deviations: none. Calls: Task 3 upper-cases a coupon code before the lookup.
  quartz: ticked task 6 of 7
  Left running: nothing. Cards: none.
  Report: /home/user/shop/.hyper-relay/runs/coupon-codes/executor.md

What you would find, if you looked:
- `git worktree list` shows `/home/user/shop/.worktrees/coupon-codes` on the branch `coupon-codes`, whose plan is
  `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P): 7 tasks, Task 7 its acceptance task. P's header
  has `**Card:** Coupon codes at checkout (7d1e2f30-5b6c-4d8e-9f01-23456789abcd)`.
- `get_task` on that card shows its status:
  `docs/superpowers/plans/2026-11-24-coupon-codes.md`: executing on coupon-codes (worktree); next: verify the
  hand-back; agents: a3f9c2e1b7d04e6f (executor)
- `/home/user/shop/.hyper-relay/runs/coupon-codes/` holds `executor.md` and `gates.log`.
- In the worktree, `relay-plan gates docs/superpowers/plans/2026-11-24-coupon-codes.md 'npm test' 'npm run lint'`
  prints `ok npm test: exit 0 at 4be81c0: 212 passed, 0 failed` and `ok npm run lint: exit 0 at 4be81c0: 0
  problems`; `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..coupon-codes` lists six commits, each with
  its `Plan-Task: docs/superpowers/plans/2026-11-24-coupon-codes.md#<n>`, 1 to 6; `git status --short` prints
  nothing; `quartz review` moves the card to In review.

Give your commands and tool calls, in order, and your next message to the owner, verbatim.
```

GREEN must: look up the card's status (`get_task`), recognize `a3f9c2e1b7d04e6f` as P's executor, and run the
hand-back check from its summary without asking the owner what the agent was: `relay-plan gates` on P (naming the two
commands, or none), the commits, the clean tree, then `quartz review` and a status note with acceptance next; it runs
no `npm test` or `npm run lint` of its own.

RED is expected to: not know what the agent was for (ask the owner, or do nothing with it), or verify it by rerunning
`npm test` and `npm run lint` itself.

- [ ] **Step 7 (`skill-test`): S3, the gates from the log (§9 S3; §5).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

Earlier in this conversation you dispatched `shop-executor` for P; its id is `a3f9c2e1b7d04e6f`. Its reply has just
arrived:

  Tasks 6/6.
  Gates (/home/user/shop/.hyper-relay/runs/coupon-codes/gates.log): `npm test`: 212 passed, 0 failed;
  `npm run lint`: 0 problems.
  Deviations: none. Calls: Task 3 upper-cases a coupon code before the lookup.
  quartz: ticked task 6 of 7
  Left running: nothing. Cards: none.
  Report: /home/user/shop/.hyper-relay/runs/coupon-codes/executor.md

What you would find, if you looked: in the worktree,
`relay-plan gates docs/superpowers/plans/2026-11-24-coupon-codes.md 'npm test' 'npm run lint'` prints
`ok npm test: exit 0 at 4be81c0: 212 passed, 0 failed` and `ok npm run lint: exit 0 at 4be81c0: 0 problems`;
`npm test` would take six minutes and end `212 passed, 0 failed`; `git log --format='%h %s%n%(trailers:key=Plan-Task)'
main..coupon-codes` lists six commits, each with its `Plan-Task: docs/superpowers/plans/2026-11-24-coupon-codes.md#<n>`,
1 to 6; `git status --short` prints nothing; `quartz review` moves the card to In review.

Give your commands, in order, up to your next message to the owner, and that message, verbatim.
```

GREEN must: check the gates with `relay-plan gates docs/superpowers/plans/2026-11-24-coupon-codes.md` (naming
`'npm test'` and `'npm run lint'`, or none) and compare its last lines with the summary's counts; run neither
`npm test` nor `npm run lint`, nor any other suite; then the commits and the tree.

RED is expected to: rerun `npm test` and `npm run lint` in the worktree and compare their counts with the report's.

- [ ] **Step 8 (`skill-test`): S4, the acceptance reviewer files a POLISH card (§9 S4; §6; P8).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. You are an acceptance reviewer: a general-purpose
agent the orchestrator dispatched because the repo has no generated reviewer agent. The orchestrator follows the
skill `hyper-relay:orchestrating` (the folder `orchestrating` in your skills folder); your instructions are the
standing brief in its file `reviewing.md`, section 1, under "Without a generated reviewer", together with the
dispatch prompt below. Read them. Your tools include Read, Grep, Glob, Bash, Write and the Quartz MCP tools
(`add_tasks` among them). In this test you cannot read files other than the skills, run commands or call tools: list
each among your commands, in order, and take what it would show from the facts below. Today is 2026-11-25.

The dispatch prompt said: the plan `docs/superpowers/plans/2026-11-24-coupon-codes.md`, its acceptance task, Task 7;
run its steps 1 and 2, the ones marked `reviewer`. The checkout is `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`. The evidence folder is `/home/user/shop/.hyper-relay/runs/coupon-codes/acceptance`. The run
folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`, and the plan's initiative is `v2`.

You have run both steps. Step 1, `npm run e2e -- coupons`, passed: 14 passed, exit 0; you saved its output as
`01a-e2e.txt` in the evidence folder. Step 2, `curl -s localhost:3101/api/coupons/SUMMER10`, passed: it printed
`{"code":"SUMMER10","percent":10}`, exit 0; saved as `02a-curl.txt`. While doing step 2 you also noticed that
`curl -s localhost:3101/api/coupons/summer10`, in lower case, answers 404 with `{"error":"not found"}`: the plan's
Task 3 upper-cases codes at checkout, but the API route in `src/api/coupons.ts` does not. Checkout works, which is
all the plan covers, so it is POLISH; you saved it as `02b-lowercase.txt`. If you call `add_tasks`, it returns the
card id `c0ffee00-1111-4222-8333-444455556666`.

Give your commands and tool calls, in order, each file you write (its path and one line on what it holds), and the
reply you hand back to the orchestrator, verbatim.
```

GREEN must: write its full report to `report.md` in the evidence folder; file the POLISH finding through `add_tasks`
with the label `proposed`, kind `bug` or `change`, initiative `v2` and a body naming the plan, `src/api/coupons.ts` and
the evidence `02b-lowercase.txt`; and hand back a short summary: the verdict line, one line per step, the card id
`c0ffee00-1111-4222-8333-444455556666` and the path of `report.md`, not the full report.

RED is expected to: report the finding only, in a full report handed back inline, with no card filed.

- [ ] **Step 9 (`skill-test`): S5, stop 4 counts the proposed cards (§9 S5; §6).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

P's review legs are done, and every agent's completion notice has arrived. The acceptance reviewer's summary: "all 2
steps PASS; nothing blocks a merge", with one proposed card filed, `c0ffee00-1111-4222-8333-444455556666` (POLISH:
lower-case coupon codes answer 404 on `/api/coupons/<code>`). The code reviewer's summary: "Ready to merge: Yes.
Critical 0, Important 1, Minor 1", with two proposed cards filed, `b1a2c3d4-0000-4000-8000-000000000002`
(Important: no rate limit on coupon lookups, `src/api/coupons.ts:12`) and `d4e5f6a7-0000-4000-8000-000000000003`
(Minor: the magic number 10 in `src/checkout/discount.ts:40`). P has no `skill-test` steps. No fix round ran, and no
finding reached a cap; no step was NEEDS-HUMAN. At the hand-back, `npm test` had 212 passed, 0 failed and
`npm run lint` 0 problems. Your harness reported tokens: executor 1.9M, acceptance reviewer 410k, code reviewer
380k. The worktree's `wt` stack is up at http://localhost:3101. `relay-plan steps
docs/superpowers/plans/2026-11-24-coupon-codes.md owner` prints `tasks 7; acceptance task 7`, then step 3, `owner`,
titled "Try a coupon in the browser".

Write stop 4: give your commands and tool calls, in order, and the stop-4 message, verbatim.
```

GREEN must: post the card's status before the message (at stop 4); ask nothing about the three cards (its questions
are only step 3 and where to click through); give the cards in the report as one line with their number, 3; and end
the message with the line that this is a good moment to clear.

RED is expected to: list the three cards among its questions, one line each, for the owner to keep or drop.

- [ ] **Step 10 (`skill-test`): S6, the fix-round cap (§9 S6; §6; P9).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

P is in its fix loop. Acceptance step 2 (`curl -s -X POST localhost:3101/api/checkout -d @fixtures/expired-coupon.json`
must answer 422 with `{"error":"coupon expired"}`) failed: it answered 500. Fix round 1 changed
`src/checkout/apply.ts`, and the reviewer's rerun failed again. Fix round 2 changed `src/checkout/validate.ts`; the
resumed reviewer has just handed back: "Step 2 FAIL: answers 500, {"error":"internal"}; evidence
acceptance/02c-rerun2.txt." Step 1 passes. P says exactly what step 2 must answer: no gap in the spec or the plan is
involved. If you call `add_tasks`, it returns the id `5ca1ab1e-0000-4000-8000-000000000004`. P has no `skill-test`
steps. If you dispatch the code review, take its summary to be: "Ready to merge: With fixes. Critical 0, Important 0,
Minor 0. Cards: none. Review: /home/user/shop/.hyper-relay/runs/coupon-codes/code-review.md". By the time you would
write stop 4, every agent's completion notice has arrived; your harness reported tokens: executor 2.3M, acceptance
reviewer 520k, code reviewer 300k. `relay-plan steps docs/superpowers/plans/2026-11-24-coupon-codes.md owner` prints
step 3, `owner`, titled "Try a coupon in the browser". The `wt` stack is up at http://localhost:3101.

Give your commands and tool calls, in order, up to and including your next message to the owner, verbatim.
```

GREEN must: read the cap from the facts header (no `fix-rounds`, so 2) and run no third fix round; file a card for
step 2 through `add_tasks` (label `proposed`, kind `bug`, the evidence path, "fix cap reached after 2 rounds"); carry
on with the code review; and send stop 4, whose first question names step 2, its 2 rounds and card
`5ca1ab1e-0000-4000-8000-000000000004`, and asks whether to merge with it open, hold the branch, or run one more
round.

RED is expected to: take step 2 to the owner at once, before any code review, because a step that fails again after
its second fix round goes to the owner.

- [ ] **Step 11 (`skill-test`): S7, a fix round reruns only its tests (§9 S7; §5).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

Acceptance of P has come back: step 1 PASS; step 2 FAIL (`curl -s -X POST localhost:3101/api/checkout -d
@fixtures/expired-coupon.json` answers 500 instead of 422; evidence `acceptance/02a-expired.txt` in the run folder).
You reran step 2's command yourself: it still answers 500. It is an execution bug: P's Task 4 says an expired coupon
answers 422 with `{"error":"coupon expired"}`. P's executor, `a3f9c2e1b7d04e6f`, can be resumed with SendMessage.
P's full gates are `npm test` and `npm run lint`; the tests for coupon expiry are in `src/checkout/validate.test.ts`,
run alone as `npm test -- src/checkout/validate.test.ts`. No fix round has run yet.

Give your commands and tool calls, in order, with the fix prompt you send the executor, verbatim.
```

GREEN must: send a fix prompt for fix round 1 (of 2) that names the finding with its evidence path, and tells the
executor to rerun only the tests that pin the fix (such as `npm test -- src/checkout/validate.test.ts`), each through
`relay-plan gate`, not the full gates, and to append a `## Fix round 1` section to `executor.md`; and post the status
note for the round.

RED is expected to: tell the executor to "rerun the gates, and report".

- [ ] **Step 12 (`skill-test`): S8, the skill tests by file and judge (§9 S8; §7; P14).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-checkout-copy.md` (call it P2) changes the project skill
`.claude/skills/checkout-copy/SKILL.md`; the repo keeps its skills in `.claude/skills`. P2 has 4 tasks; Task 4, its
acceptance task, has Steps 1–4 (`reviewer`) and Steps 5–9 (`skill-test`). P2 runs in the worktree
`/home/user/shop/.worktrees/checkout-copy`, on the branch `checkout-copy`; its run folder is
`/home/user/shop/.hyper-relay/runs/checkout-copy`. Its acceptance passed with no fix round, you posted its status,
and you have just dispatched its code review. Now come its skill tests.

What you would find, if you looked:
- `relay-plan steps docs/superpowers/plans/2026-11-24-checkout-copy.md skill-test` prints `tasks 4; acceptance task
  4`, then steps 5 to 9, each `skill-test`, titled "S1, a refund line", "S2, a coupon line", "S3, a gift card line",
  "S4, a partial refund" and "S5, a currency line".
- `relay-plan scenarios docs/superpowers/plans/2026-11-24-checkout-copy.md
  /home/user/shop/.hyper-relay/runs/checkout-copy/skill-tests` writes `step-5.txt` to `step-9.txt` in that folder and
  prints one line for each, exit 0.
- `git cat-file -e main:.claude/skills` succeeds.

Give your commands and tool calls for the skill tests, in order, up to the moment you have every verdict. Give the
prompt of one GREEN run and the judge's prompt, verbatim, and say how the other runs' prompts differ.
```

GREEN must: copy `main`'s and the branch's `.claude/skills` into the run folder's `skill-tests/red/` and
`skill-tests/green/`; run `relay-plan scenarios` into `skill-tests`; dispatch ten runs on Sonnet (GREEN and RED for
steps 5–9), each told to read its `step-<id>.txt` and its skills folder only, write its answer to `step-<id>-green.md`
or `step-<id>-red.md`, and reply `done`; then one judge on Sonnet, given P2's path, the ids 5–9 and the folder, which
writes `verdicts.md` and replies one line per scenario. It reads none of P2's steps itself: no Read of P2 and no
`relay-plan step` of its own.

RED is expected to: read P2's Steps 5–9 itself and paste each situation into the runs' prompts, then judge the
answers itself.

- [ ] **Step 13 (`skill-test`): S9, the plan check by `relay-plan` (§9 S9; §7).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The owner approved the spec `docs/superpowers/specs/2026-11-24-coupon-codes-design.md` (call it Q), which names the
card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`) and has one plan. You dispatched
`shop-planner` and posted the card's status naming it. The main checkout is on `main`, and no other plan is in
flight. The planner's report has just arrived: the plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it
P), 7 tasks, committed on `main` in `9e8d7c6`; one deviation, D1: the coupon table gets a `max_uses` column, which
the spec left open (the planner's call); no assumptions; no facts re-checked.

What you would find, if you looked:
- `relay-plan check docs/superpowers/plans/2026-11-24-coupon-codes.md --spec
  docs/superpowers/specs/2026-11-24-coupon-codes-design.md` prints `ok committed`, `ok card`, `ok trailers`,
  `ok acceptance`, `ok skill-tests`, `ok placeholders` and `ok coverage`, exit 0.
- `relay-plan steps docs/superpowers/plans/2026-11-24-coupon-codes.md` prints first `tasks 7; acceptance task 7`.
- `wc -l` gives 412 lines for P and 160 for Q.

Give your commands and tool calls, in order, up to your next message to the owner, and that message, verbatim.
```

GREEN must: check P with `relay-plan check` on P with `--spec` and Q, without reading P and without grepping it; post
the card's status (at stop 3); then send stop 3: its questions first (D1 if it asks the owner anything, the
plan-review offer, the handoff question), then the short report, ending with the line that this is a good moment to
clear.

RED is expected to: check P with `planning.md` §2's greps (`git log -1 … -- P`, `grep -n -o 'Plan-Task: …'`,
`grep -n '^### Task'`, the placeholder grep, `grep -n '^## '` on Q), or by reading P.

- [ ] **Step 14 (`skill-test`): S10, a decision note in the brainstorm (§9 S10; §3).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory, on
`main`. You are the agent your human partner talks to, in Claude Code, and you follow the skill
`hyper-relay:brainstorming`, the folder `brainstorming` in your skills folder: read it, and any file of another skill
it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's `.mcp.json` names the Quartz
server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`, `tick_brain`) are loaded. Your tools
include Read, Grep, Glob, Bash, Write and Edit. In this test you cannot read files other than the skills, run
commands or call tools: list each among your commands, in order, and take what it would show from the facts below.
Today is 2026-11-25.

The work's card is "Gift wrapping at checkout" (`9a8b7c6d-0000-4000-8000-000000000005`, initiative `v2`); you called
`tick_brain` on it at the start. Its status reads `brainstorm: the why, confirmed; next: the approaches`. Earlier in
this conversation you echoed the request back, your human partner told you why they want it (gift orders are a fifth
of December's orders), and you laid out three approaches in a message of their own: A, one checkbox per order; B,
wrapping chosen per item, with a gift note; C, a separate gift checkout. You recommended B.

Your human partner now writes: "B. Most of our gift orders mix gifts with things people buy for themselves, so per
item matters more than one box for the whole order."

Give your commands and tool calls, in order, and your next message, verbatim.
```

GREEN must: in this turn, add a note on the card with the decision (approach B) and the reason (orders mix gifts with
things people buy for themselves), and post the card's status anew (approach B picked, and what comes next); then
carry on with the brainstorm in its message.

RED is expected to: write nothing on the card, and only carry on with the brainstorm.

- [ ] **Step 15 (`skill-test`): S11, the executor's gates and short summary (§9 S11; §4, §5).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. You are an executor: the agent `shop-executor`,
dispatched to run one plan, and you follow the skill `hyper-relay:executing-plans`, the folder `executing-plans` in
your skills folder: read it. Your agent file adds only this: its "Full gates" are `npm test` and `npm run lint`, and
it has no acceptance steps. Your tools include Read, Grep, Glob, Bash, Write, Edit and the Quartz MCP tools
(`add_tasks` among them). Commands on your PATH include `relay-plan`. In this test you cannot read files other than
the skills, run commands or call tools: list each among your commands, in order, and take what it would show from
the facts below. Today is 2026-11-25.

Your dispatch prompt gave: the plan `docs/superpowers/plans/2026-11-24-coupon-codes.md`, Tasks 1–6 yours and Task 7
the orchestrator's; the mode `worktree`; the checkout `/home/user/shop/.worktrees/coupon-codes`, on the branch
`coupon-codes`; the run folder `/home/user/shop/.hyper-relay/runs/coupon-codes`; the card
`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative `v2`; the Claude-Session URL `https://claude.ai/code/session_x`.
The plan's Execution notes name the full gates `npm test` and `npm run lint`. Its Task 7 has Steps 1–2 (`reviewer`:
an end-to-end run and a curl check), Step 3 (`owner`: try a coupon in the browser) and Steps 4–5 (`after merge`: the
deploy and a smoke test).

You have just committed Task 6, the last of yours, as `4be81c0`; Tasks 1–5 are `1a2b3c4`, `2b3c4d5`, `3c4d5e6`,
`4d5e6f7` and `5e6f7a8`. You made no deviation, and one call: Task 3 upper-cases a coupon code before the lookup.
Each commit printed `quartz: ticked task <n> of 7`. Run either way, `npm test` ends `212 passed, 0 failed` and
`npm run lint` prints `0 problems`, each exit 0; through `relay-plan gate`, each prints its last lines, then
`EXIT 0`.

Give your commands, in order, each file you write (its path and one line on what it holds), and the reply you hand
back, verbatim.
```

GREEN must: run `npm test` and `npm run lint` each through
`relay-plan gate docs/superpowers/plans/2026-11-24-coupon-codes.md '<command>'` from the worktree's top; write its full
report to `executor.md` in the run folder; and hand back a short summary (tasks 6/6, one line per gate with its counts
and `gates.log`, the call, the `quartz:` lines, nothing left running, the path of `executor.md`) that does not copy
Task 7's steps.

RED is expected to: run `npm test` and `npm run lint` directly, and hand back its whole report with Task 7's checklist
copied into it.

- [ ] **Step 16 (`skill-test`): S12, the planner's acceptance task (§9 S12; §5; P7).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. You are a planner: a general-purpose agent whose first
instruction was "Invoke the `hyper-relay:writing-plans` skill and follow it. You may only read code and write your
plan file." The skill is the folder `writing-plans` in your skills folder: read it. In this test you cannot read
other files or run commands: take what you need from the facts below. Today is 2026-11-25.

The spec `docs/superpowers/specs/2026-11-24-checkout-copy-design.md` changes the project skill
`.claude/skills/checkout-copy/SKILL.md`, which tells the shop's support agent how to word a receipt line. Its
change: a refund line for an order paid partly with a coupon names the coupon. It names one pressure scenario, S1: a
customer asks for a refund of an order paid partly with the coupon `SUMMER10`; GREEN: the receipt line the agent
writes names `SUMMER10`; RED: it gives only the amount. Its acceptance: the gates pass; a live run,
`node scripts/receipt.js --refund fixtures/coupon-order.json`, prints a line holding `SUMMER10`; the skill test S1.
The repo's full gates are `npm test`, `npm run lint` and `sh .claude/skills/checkout-copy/test.sh`. You have written
the plan's Tasks 1–3, in `docs/superpowers/plans/2026-11-25-checkout-copy.md`; Task 3 ends with the full gates.

Write the plan's acceptance task, Task 4, in full, verbatim, as it goes into the plan.
```

GREEN must: hold no `reviewer` step that runs `npm test`, `npm run lint` or `test.sh`; hold the live run as a
`reviewer` step with its PASS; and hold S1 as a `skill-test` step with a `Situation:` line, then the whole situation
in a fence marked `text`, with nothing in it standing for text elsewhere, then its GREEN and RED lines under the
labels `writing-plans` gives.

RED is expected to: hold a `reviewer` step that runs the gates, or a situation outside a fence marked `text`. A RED
whose only difference is its labels is recorded as not failing.

- [ ] **Step 17 (`skill-test`): S13, "I'm about to clear" (§9 S13; §3).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. Its main checkout is your working directory. You are
the orchestrator: the Claude Code session your human partner (the owner) talks to. You follow the skill
`hyper-relay:orchestrating`, the folder `orchestrating` in your skills folder: read the files of it that the
situation needs, and any skill it sends you to. The repo uses Quartz: `quartz` is installed, the main checkout's
`.mcp.json` names the Quartz server, and its MCP tools (`get_task`, `add_note`, `add_tasks`, `list_tasks`) are
loaded. `git show main:.hyper-relay/agents.md` shows a header of `project: shop`, `reviewer: browser` and
`execute: worktree`, and no other key; the repo's generated agents are `shop-planner`, `shop-executor` and
`shop-reviewer`. Commands on your PATH include `quartz`, `wt`, `relay-merge` and `relay-plan`. Your tools include
Read, Grep, Glob, Bash, Write, Edit, the Agent tool (it dispatches a subagent in the background and returns its id)
and SendMessage (it resumes an agent by its id). In this test you cannot read files, run commands, call tools or
dispatch agents: list each among your commands, in order, and take what it would show from the facts below. Today is
2026-11-25.

The plan `docs/superpowers/plans/2026-11-24-coupon-codes.md` (call it P) has 7 tasks; Task 7 is its acceptance
task. Its header names the card "Coupon codes at checkout" (`7d1e2f30-5b6c-4d8e-9f01-23456789abcd`, initiative
`v2`), and P is the only plan on that card. P runs in the worktree `/home/user/shop/.worktrees/coupon-codes`, on the
branch `coupon-codes`, and its run folder is `/home/user/shop/.hyper-relay/runs/coupon-codes`.

Twenty minutes ago you dispatched P's executor, `a3f9c2e1b7d04e6f`, and posted the card's status:
`docs/superpowers/plans/2026-11-24-coupon-codes.md`: executing on coupon-codes (worktree); next: verify the
hand-back; agents: a3f9c2e1b7d04e6f (executor)
Nothing has happened since. Claude Code's auto-memory is on: you may write files in the project's memory folder,
`/home/user/.claude/projects/-home-user-shop/memory/`, whose `MEMORY.md` is read at the start of every session.

Your human partner now writes: "I'm about to clear."

Give your commands and tool calls, in order, and your next message, verbatim.
```

GREEN must: write no handoff note, memory file or extra card note; answer in a line or two that the board is current
(the card's status names the executor and what comes next) and nothing needs writing, so they can clear now.

RED is expected to: write down where things stand first (a memory or handoff file, or a note on the card) before
saying they can clear.

- [ ] **Step 18 (`skill-test`): S14, the code reviewer's cards and short reply (§9 S14; §4, §6).**

Situation:

```text
This test is set in a git repo at /home/user/shop, a web shop. You are a code reviewer: a general-purpose agent on
Sonnet, dispatched with the prompt template in the skill `hyper-relay:requesting-code-review`, its file
`code-reviewer.md` (the folder `requesting-code-review` in your skills folder: read it), with its placeholders filled
in: DESCRIPTION, coupon codes at checkout; PLAN_OR_REQUIREMENTS, `docs/superpowers/plans/2026-11-24-coupon-codes.md`;
SPEC, `docs/superpowers/specs/2026-11-24-coupon-codes-design.md`; BASE_SHA, `0a1b2c3`; HEAD_SHA, `4be81c0`; RUN_DIR,
`/home/user/shop/.hyper-relay/runs/coupon-codes`; INITIATIVE, `v2`. A placeholder your template does not have is
unused. Your tools include Read, Grep, Glob, Bash, Write and the Quartz MCP tools (`add_tasks` among them). In this
test you cannot read files other than the skills, run commands or call tools: list each among your commands, in
order, and take what it would show from the facts below. Today is 2026-11-25.

You have read the diff and finished your review. Strengths: the coupon rules live in one module, and each has a
test. Critical: `src/checkout/apply.ts:57` applies a coupon a second time when the page is refreshed, so an order's
total can fall below cost. Important: `src/api/coupons.ts:12` has no rate limit on lookups;
`src/checkout/validate.ts:30` reports a database error as "coupon not found". Minor: the magic number 10 in
`src/checkout/discount.ts:40`; `README.md` does not mention coupons; the test name "works" in
`src/checkout/apply.test.ts:8`. Ready to merge: With fixes. Each `add_tasks` call returns a new id, in order
`11111111-0000-4000-8000-000000000001` to `55555555-0000-4000-8000-000000000005`.

Give your commands and tool calls, in order, each file you write (its path and one line on what it holds), and your
reply, verbatim.
```

GREEN must: write the whole review to `code-review.md` in the run folder; file the two Important and the three Minor
findings as five cards through `add_tasks`, each with the label `proposed`, a kind, initiative `v2` and a body naming
the plan, the file and line, and `code-review.md`; file no card for the Critical; and reply with only a short summary:
With fixes, the counts 1, 2 and 3, the Critical in one line with `src/checkout/apply.ts:57`, the five card ids, and the
path of `code-review.md`.

RED is expected to: reply with the whole review inline (Strengths, Issues, Recommendations, Assessment) and file no
card.

- [ ] **Step 19 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-lighter-orchestrator-skills`, with stop 4's
  skill-test results and the P-notes, P1, P2, P4, P9 and P18 above all. PASS: the owner agrees with them as written.
  A change goes to the executor as a finding.

- [ ] **Step 20 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-lighter-orchestrator-skills` | exit 0, one line (a tree id) |

The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`; its gates
(`.hyper-relay/merge.conf`) run on the merged result.

- [ ] **Step 21 (`after merge`): The release, 0.2.7 (spec §11; `.hyper-relay/agents.md`, Releases, (1) and (2)).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits, which is expected. In the main
  checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with `<x.y.z>` the version `--check` shows with its
  patch number raised by one (`0.2.7` from `0.2.6`):

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.6`, Plan 1's release) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh <x.y.z>` | exit 0; `package.json` and `.claude-plugin/plugin.json` raised to `<x.y.z>` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `<x.y.z>` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v<x.y.z>" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v<x.y.z>
git -C /home/noob_master/hyper-relay push origin main v<x.y.z>
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v<x.y.z>` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v<x.y.z>` | one line |

- [ ] **Step 22 (`after merge`): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z> && echo cached` | `cached` |
| `grep -c -F 'relay-plan scenarios' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/orchestrating/reviewing.md` | `1` or more |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If a check still fails, stop and tell the owner; delete or uninstall nothing.

- [ ] **Step 23 (`after merge`): The role agents, regenerated here and in SAT (spec §10, §11; P18).** With the
  installed generator, so the agents' version marker matches the installed plugin:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents` | `relay-executor.md` and `relay-reviewer.md` `written`, the others `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -F 'add_tasks' /home/noob_master/hyper-relay/.claude/agents/relay-reviewer.md` | `2` |

Then SAT, unless a SAT plan is between its dispatch and its merge: then ask the owner first (its agents would change
under it).

| Run | PASS |
|---|---|
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents` | `sat-executor.md` and `sat-reviewer.md` `written`; no `refused` line; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -F 'run folder' /home/noob_master/sat.pentraze.com/.claude/agents/sat-executor.md` | `2` or more |

A `refused` line (a hand-edited agent) stops the step: tell the owner. The new agents load in a new session.

- [ ] **Step 24 (`after merge`, the owner's OK first): The handoff memory is retired (spec §11; P18).** Ask the owner,
  in one line: "The board now holds the relay's state; may I delete the handoff memory
  `hyper-relay-handoff-2026-11-17` and its line in `MEMORY.md`?" On a yes, delete
  `/home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/hyper-relay-handoff-2026-11-17.md`, and
  remove the one line of `/home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/MEMORY.md` that
  links it (with the Edit tool); nothing else in the memory folder changes. On a no, record that, and skip the checks.

| Run | PASS |
|---|---|
| `test -e /home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/hyper-relay-handoff-2026-11-17.md \|\| echo gone` | `gone` |
| `grep -c -F 'hyper-relay-handoff-2026-11-17' /home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/MEMORY.md` | `0` |

- [ ] **Step 25 (`after merge`, last): The live probe (spec §10; How it works).** The next real relay run in this repo,
  from a new session on 0.2.7 with the regenerated agents, is the probe. During it, the owner runs `/clear` once while
  an agent (the executor or a reviewer) is running and once at a stop (3 or 4), each time without warning the
  orchestrator. PASS when all four hold:
  1. Each time, the fresh conversation finds where the work stands from the card (`get_task`) and the run folder,
     without being told, and carries on: the running agent's notice, arriving after the clear, is taken up as that
     agent's leg.
  2. A reviewer (acceptance or code) files a `proposed` card through its own `add_tasks`, not through `cards.md`: this
     confirms the generated agents' Quartz write, which How it works leaves untested.
  3. No full gate is rerun before the merge: the executor's run through `relay-plan gate` (in `gates.log`) and
     `relay-merge`'s are the only full runs; the orchestrator's hand-back check is `relay-plan gates`.
  4. The orchestrator reads no plan whole: its transcript holds no Read of a plan file without a line range, and no
     `cat` of one; plan text reaches it only through `relay-plan`'s output.

  Then measure that run's orchestrator transcript (in `/home/noob_master/.claude/projects/-home-noob-master-hyper-relay/`)
  as How it works measured its baselines (`jq` sums of tool-result and message sizes by kind, and the tokens at the
  start and the end), and report the numbers against them (start about 62k tokens, end 280k–540k; Bash output 171k and
  221k characters; hand-backs 72k and over 250k; plan text 27k–161k). The numbers are not a gate. Then tick the
  acceptance task as `reviewing.md` §5 says. A failed point goes to the owner as a new card.
