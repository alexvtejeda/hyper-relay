# hyper-relay: a lighter orchestrator (design)

**Date:** 2026-11-20 · **Status:** written from the owner's brainstorm of 2026-11-20, waiting on the owner's review
**Cards:** A lighter orchestrator context: clear any time, owner decisions on the board (`b43e3367-79eb-4289-a7dd-41edf35f95c2`), Suggest clearing context once a plan is fully written and there are no background subagents running (`6e189fac-9f3b-4f20-8fed-9a90c73c1478`)
**Initiative:** v0.1.0
**Plans:** 2
**Scope:** this repo: a new `bin/relay-plan` with its tests and docs, and a `fix-rounds` key in the facts header
(Plan 1); the relay skills and the role-agent templates (Plan 2); then a release after each merge.

## Goal

The session the owner talks to (the orchestrator) grows to 280k–540k tokens in a relay session. The owner clears or
compacts at every stop, and before each clear has to warn the orchestrator and ask it to write Quartz notes by hand.
The orchestrator also reruns checks that the executor and the repo's own commands already ran, which costs time and
context.

This work makes a clear free at any moment, and makes the session grow slowly:

- **The board holds the state.** The orchestrator keeps each card current as things happen, so a clear needs no
  warning and no request for notes, and a fresh session finds where everything stands.
- **No check runs twice** before the merge.
- **The owner decides proposed cards on the board,** not in the session, and a finding that keeps failing becomes a
  card instead of another round in the session.
- **The orchestrator routes by path, not by content:** it never reads a plan whole, and agents hand back short
  summaries with their full reports in files.

**Non-goals:** shrinking the brainstorm conversation itself (it must stay with the owner); changing what the planner
reports at stop 3; running legs in headless or separate Claude sessions.

**Anti-goals** (failures even if everything else works):

- a defect a leg would have caught slips through: each leg keeps its own independent check (the reviewer's steps, the
  code review, the skill tests, the merge's gates);
- a fresh session guesses where work stands instead of asking, when the card and the run folder do not settle it;
- an agent writes anywhere but its own checkout, the plan's run folder and (for proposed cards) the board;
- the relay stops working in a repo without Quartz: every Quartz step keeps a plain-file fallback.

## Decisions (owner, 2026-11-20)

| # | Decision |
|---|---|
| L1 | The board is kept current automatically: a status at every step of the relay, each dispatched agent named by its id, and a decision note whenever the owner decides something, in a brainstorm or at a stop. The owner never has to ask for notes. The orchestrator's own handoff memory stops. |
| L2 | No check runs twice: the executor saves its gate output to a log, and the orchestrator reads it instead of rerunning; plans give the acceptance reviewer no step that reruns the gates; a fix round reruns only the tests that pin its fix; the merge's run (`relay-merge`) stays the one independent full run. |
| L3 | Proposed cards go straight onto the board, labelled, filed by the agent that found the issue; stop 4 no longer asks about them. |
| L4 | A fix-round cap, settable per repo (default 2, as today): a finding that still fails after the cap becomes a card, the loop stops working on it, and stop 4 shows the step as failed with its card; the merge decision stays the owner's. |
| L5 | Smaller inflows: agents hand back short summaries and write full reports to a file; the orchestrator reads the relay's instruction files once per session, not at every leg. |
| L6 | Route by path, not content: a command beside `relay-merge` answers the orchestrator's questions about a plan (the hand-back checks as pass/fail lines, the acceptance steps by who runs them, one step's text only when needed); agents' reports go to a git-ignored run folder per branch, and findings pass between agents by path; skill-test scenarios are extracted to files, and one judge agent returns the verdicts. No hook blocks the orchestrator from reading plans. |
| L7 | Out: a separate or headless spec writer. |
| L8 | Approach A: one spec, two plans (below). |

## How it works

Facts the design rests on. Checked 2026-11-20 on this machine, Claude Code 2.1.330, unless a line says otherwise.

- **`/clear` keeps background work, and its notices arrive.** A live test, in a throwaway Haiku session in a scratch
  folder driven through tmux: a background Bash command and a background agent were each running when `/clear` ran;
  both kept running, and both completion notices reached the cleared conversation. The cleared conversation did not
  know what the agent was for, so it did nothing with its report. Changelog 2.1.72 ("Fixed `/clear` killing
  background agent/bash tasks — only foreground tasks are now cleared") and 2.1.319 agree.
- **`/compact` keeps background work too,** and delivers its notices: code.claude.com/docs/en/context-window.md, "What
  survives compaction".
- **Exiting Claude Code stops background work** (code.claude.com/docs/en/interactive-mode.md), so a new session never
  receives the old session's notices.
- **Agent names reset on `/clear`** (code.claude.com/docs/en/sub-agents.md: the name check "is scoped to the current
  conversation and resets on `/clear`"). Whether `SendMessage` reaches an agent by its id after a `/clear` is
  untested; the relay already falls back to a fresh agent when one cannot be resumed (`orchestrating` SKILL.md,
  Fallbacks).
- **The context window is not the limit.** On 1M-window models, auto-compact runs at about 967K tokens
  (code.claude.com/docs/en/model-config.md). Measured over this repo's last four relay sessions (transcripts
  `ecfdb799`, `170d5f13`, `e183d2b7`, `496a3e16` in `~/.claude/projects/-home-noob-master-hyper-relay/`): each started
  at about 62k tokens and ended at 280k–540k, with no compaction. The cost is per-turn cache reads and attention, not
  running out.
- **What fills it,** measured in two of those sessions (`ecfdb799`, `170d5f13`) by summing tool-result and message
  sizes with `jq`: Bash output 171k and 221k characters (gate reruns, git logs, the relay's leg files re-read at each
  leg); agents' hand-backs and notices 72k and over 250k characters (5–23k each); the orchestrator's own dispatch
  prompts 35k and 78k. Plan text reached the orchestrator at 27k–161k characters per session (all four), through the
  hand-back greps, the skill-test steps it pastes into test agents and judges, and the owner's and after-merge steps.
  Writing a spec costs about 21k characters (about 5k tokens).
- **Background agents get the Quartz MCP tools.** A background general-purpose Haiku agent listed all 17
  `mcp__quartz__*` tools as deferred, loaded `list_tasks` with ToolSearch and called it. The generated
  `relay-executor` and `relay-reviewer` restrict tools with `disallowedTools` (`Agent`; `Agent, Edit, Write,
  NotebookEdit, Workflow`), so they inherit the MCP tools; `relay-planner` has an explicit `tools:` list without them
  (`.claude/agents/relay-*.md` frontmatter). That the two generated agents see them is inferred from that frontmatter,
  not tested: the after-merge probe (§10) confirms it.
- **Quartz's MCP** (its tool schemas): `add_note` takes a body of at most 2000 characters, or 500 with `status: true`;
  a status replaces the card's previous status. `add_tasks` adds 1–20 cards to Needs brainstorming, each with `kind`
  (`bug` or `change`), `initiative` and `labels`. `get_task` returns the card's status and current notes.
- **The facts header rejects unknown keys:** `bin/hyper-relay-agents` lines 185–191 accept only `project`,
  `reviewer`, `execute` and `model.*`, and refuse anything else.
- **Plans' acceptance steps** are written `- [ ] **Step <n> (`<who>` …): <title>**`, with `<who>` one of `reviewer`,
  `owner`, `after merge`, `skill-test` (`writing-plans` SKILL.md lines 102–112). A `skill-test` step gives
  `Situation:`, `GREEN must:` and `RED is expected to:`; the situation sits in a ```` ```text ```` fence in practice
  (`docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md`, Task 7 Steps 5–9), but `writing-plans` does
  not require the fence today.
- **A git-ignored folder under `.hyper-relay/` has a precedent:** the visual companion keeps its sessions in
  `.hyper-relay/companion/` and adds that line to the repo's local exclude file when git does not ignore it
  (`skills/visual-companion/scripts/start-server.sh` lines 209–211).
- **Agents may not write outside their checkout today:** `executing-plans` SKILL.md's Never list ("Touch anything
  outside your checkout"); the reviewer templates ("Never create, edit or delete a file in any checkout or worktree;
  the evidence folder is the only …", `templates/agents/reviewer-commands.md` line 74, `reviewer-browser.md` line 93).
  The executor copies the plan's acceptance checklist into its report (`executing-plans` SKILL.md line 58).
- **The full gates run up to four times per branch today:** the executor's last task (`executing-plans` step 5),
  the orchestrator's hand-back check (`dispatching.md` §7, check 1, "Rerun the gates"), a `reviewer` acceptance step
  that runs them (e.g. the companion-hardening plan's Task 7 Step 1, "The gates"), and `relay-merge` on the merged
  result. Each fix round reruns them again (`reviewing.md` §2, "rerun the gates, and report").
- **Git ignores a folder that does not exist yet, by its trailing slash** (git 2.43.0, a scratch repo): with
  `.hyper-relay/runs/` in `.git/info/exclude`, `git check-ignore -q .hyper-relay/runs/` exits 0 before the folder
  exists, while `.hyper-relay/runs` without the slash exits 1. In a linked worktree, `git rev-parse
  --path-format=absolute --git-path info/exclude` prints the main repo's `.git/info/exclude`, and the check exits 0
  there too. Files under the folder never show in `git status --short --untracked-files=all`.
- **Agents' shells find the plugin's commands:** a background Haiku agent's `PATH` holds
  `~/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.5/bin`, as the main session's does.
- **Quartz labels are free text:** `add_tasks` passes `labels` (an array of strings) through `cleanLabels`, which only
  trims them, drops duplicates and limits their count and length; no label is created beforehand
  (`~/quartz/mcp/internal/tools/add.go` line 18, `~/quartz/api/internal/application/card_fields.go` lines 36–45).
- **Permissions:** the owner's `~/.claude/settings.json` runs in `auto` mode with no rule for the Quartz tools; the
  orchestrator's own `add_tasks` and `add_note` calls pass. A background agent's Quartz read passed; a background
  agent's Quartz *write* is untested, so §6 gives it a fallback, and the after-merge probe (§10) confirms it.
- **`run-dir` and `steps` need only the plan file, not a branch** (checked 2026-11-20, at stop 3; Plan 2's A1). In
  Plan 1 as committed at `5e2ccd7`, `run-dir <plan>` checks that the file exists and names the folder from the plan's
  file name (P8), and `steps <plan>` reads the plan file alone (Task 2 Step 3, Task 3 Step 3). Only `gates` needs
  the branch (`git rev-parse -q --verify refs/heads/<branch>`). So both work on a committed plan at stop 3, before
  any branch exists.

No fact here is flagged for the planner to re-check.

## Approaches

- **A. One spec, two plans (chosen).** Plan 1 is `bin/relay-plan` with its tests and the `fix-rounds` header key:
  mechanical and fully testable alone. Plan 2 is every instruction change, and uses Plan 1's command. The command is
  the only part that stands alone; the instruction changes cross the same files (`reviewing.md`, `dispatching.md`,
  `quartz.md`), so they belong in one plan. Costs a longer wait before anything ships.
- **B. Two specs by theme** (the board as state and decisions on the board; then the lighter inflows). The first
  could ship sooner, but both rewrite the same files, would run one after the other anyway, and the status notes of
  the first would be rewritten when the second moves reports into the run folder.
- **C. One spec, one plan.** A very large plan with a long run; one failing piece holds up the rest.

## The plans

1. **`-relay-plan`:** `bin/relay-plan`, `tests/relay-plan/`, `docs/relay-plan.md`, the `fix-rounds` key in
   `bin/hyper-relay-agents` and its tests, `.hyper-relay/merge.conf` lines, `CLAUDE.md`'s Layout and Checks. Builds on
   nothing.
2. **`-skills`:** the relay skills (`orchestrating`, `brainstorming`, `executing-plans`, `writing-plans`,
   `requesting-code-review`, `agents`), the role-agent templates, the relay guard test and `README.md`. Builds on
   nothing: it plans against the Contract below.

**Order (my call, after D.2's D2.10):** both planners run at once on `main`; the executors run in sequence. Plan 1
runs, lands and is released; then Plan 2 runs from the new `main`, so its executor and its orchestrator can use
`relay-plan` for real. The plans share no file.

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

## 1. `bin/relay-plan` (Plan 1)

The Contract's command. `check` and `overlap` keep the meaning of `planning.md` §2's and `parallel.md` §2's checks as
they read today (the same rules, not the same output); `check` adds one new check, `skill-tests`. A plan written
before that rule may fail `skill-tests` alone; `check` runs on newly written plans, so that is expected. This repo's
companion-hardening plan passes every check (its situations are fenced). With:

- `tests/relay-plan/run-tests.sh` (POSIX, `0 failed`), on temporary git repos and fixture plans: a good plan that
  passes every check, and one fixture broken for each check (it must fail that check alone); `steps`, `step` and
  `scenarios` against a plan modelled on the companion-hardening plan's acceptance task; `gate` and `gates` with a
  passing gate, a failing one, and one whose latest block is at an older commit than the branch tip; `run-dir` in a
  repo where `.hyper-relay/runs/` is not ignored (the exclude line is added once, never twice) and one where it is;
  `overlap` with a shared file and a numbered collision, and with a branch.
- `docs/relay-plan.md`: its user reference, as `docs/relay-merge.md` is `relay-merge`'s.
- `.hyper-relay/merge.conf`: `bin/relay-plan` gets a `dash -n` build line and the suite as a test line;
  `tests/relay-plan/` gets the suite.
- `CLAUDE.md`: the Layout entry and the Checks row.

## 2. `fix-rounds` (Plan 1)

`bin/hyper-relay-agents` accepts the Contract's `fix-rounds` key, and its refusal message for an unknown key lists it.
`tests/hyper-relay-agents/run-tests.sh` gains a case for an accepted value, for each kind of refused value (`0`, `10`,
`two`), and for the generated files being the same with and without the key. The `agents` skill's text about the
header is Plan 2's (it is a skill file).

## 3. The board holds the state (Plan 2)

**Status notes at every step** (`quartz.md` §4, which lists the moments; each leg file says it at its own moment).
The card's status note names each of the card's plans in flight, one line each, in at most 500 characters:
`` `<plan path>`: <where it stands>; next: <what>; agents: <id> (<role>)… ``. The orchestrator writes it when it:

1. dispatches the planners;
2. sends stop 3, and when the owner answers it;
3. dispatches the executor (with the mode and branch);
4. has verified the hand-back;
5. dispatches the acceptance reviewer, and each fix round (round k of the cap);
6. ends the fix loop (acceptance done: today's note, now in this form);
7. dispatches the code review and the skill tests;
8. has the code review and skill tests done (today's note, in this form);
9. sends stop 4, and when the owner answers it;
10. has merged (with the `after merge` steps left), and when the acceptance task is ticked.

With several plans on one card, it reads the current status first (`get_task`) and keeps the other plans' lines.
Without Quartz, it writes the plan's line to the run folder's `status` instead.

**Decision notes.** Whenever the owner decides something, at a stop or in a brainstorm, the orchestrator adds an
ordinary note on the card at once, with the decision and the reason given: what the owner today asks for by hand.
`brainstorming` does the same during a brainstorm (each answer that changes the design, the approach picked, each
part of the playback confirmed) and keeps the card's status saying where the brainstorm stands and what comes next;
its own text grows by a few lines only, and points at `quartz.md` §4 for the rest. Without Quartz, the decisions go to
the topic's `brainstorm.md`, or the plan's run folder in a later leg.

**A fresh session** (after a `/clear` or in a new session) finds where work stands from the card and the run folder
(`orchestrating` SKILL.md, Finding where work stands), and the owner never has to warn the orchestrator before a
clear. New rules there:

- **A notice from an agent this conversation did not dispatch:** find its id in the card's status, and carry on from
  that leg (for an executor, `dispatching.md` §7 from `executor.md`).
- **The status names an agent whose report is not in the run folder:** tell the owner, in one line, that if they only
  cleared, the agent is still running and its notice will arrive here, and that if Claude Code was restarted, it
  stopped and will be dispatched again; wait for their answer. This replaces today's question "is its executor still
  running elsewhere?" for a plan whose status names its executor.
- Today's rows for a branch with all its executor tasks committed keep working; the status note now exists at every
  step, so the last row ("ask the owner which review legs ran") applies only without Quartz and without a `status`
  file.

**No private state.** `orchestrating` says that the card and the run folder are the record of where work stands, and
that the orchestrator never keeps relay state in a memory file or a handoff note of its own.

**Suggest a clear (my call, card `6e189fac`).** At stop 3 and stop 4, once the status note is written, the stop's
report ends with one line: the board is current, so this is a good moment to clear.

## 4. The run folder and short hand-backs (Plan 2)

The orchestrator creates the run folder with `relay-plan run-dir <plan>` at the handoff (`dispatching.md` §3), and
every dispatch prompt from then on names it, with the card's id and initiative when the repo uses Quartz ("Run no
Quartz command and use no Quartz tool" when it does not). The run folder replaces the scratchpad evidence folder
(`reviewing.md` §1, §3).

Each agent writes its full report to its file (Contract) and hands back only a short summary, at most about 15
lines:

| Agent | Hands back |
|---|---|
| Executor | tasks n/N; one line per gate with its counts, and `gates.log`; each deviation and each open call it made, one line each; every `quartz:` line, verbatim; what it left running or left for the owner; the path of `executor.md`. It no longer copies the acceptance checklist. |
| Acceptance reviewer | the verdict line; one line per step (PASS / FAIL / NEEDS-HUMAN); each BLOCKING finding in one line with its evidence path; the cards it filed; the path of `acceptance/report.md` |
| Code reviewer | Ready (yes / no / with fixes); the counts per severity; each Critical in one line with its file and line; the cards it filed; the path of `code-review.md` |
| Plan reviewer | its verdict, the counts, and the path of `plan-review.md`; the planner gets that path, not the text |
| Skill-test run | `done` (its answer is in its file) |
| Judge | one line per scenario (§7) |

The planner is unchanged: its report is what stop 3 relays.

The agents' rules gain one narrow exception each: the executor may write its run folder's files (and `gates.log`
through `relay-plan gate`), from any checkout; the acceptance reviewer's evidence folder is the run folder's
`acceptance/`. Nothing else outside their checkout changes.

**Read once per session.** `orchestrating` SKILL.md drops "read `quartz.md` at the start of every leg": the orchestrator
reads each of its files once per session, when the loop first needs it. A cleared conversation is a new session.

## 5. No check runs twice (Plan 2)

- **The executor** runs its full gates once, after its last task (as today), each through `relay-plan gate`, so they
  land in `gates.log`.
- **The hand-back check** (`dispatching.md` §7, check 1) runs `relay-plan gates <plan>` instead of rerunning the gates:
  every gate's latest run is at the branch tip and passed, and its last lines match the counts the summary gives.
- **Plans** give the acceptance reviewer no step that reruns the gates: `writing-plans` says the gates are the
  executor's last task and the hand-back check's. Other command steps (a live run in a scratch repo, a diff-scope
  check) stay with the reviewer, as independent checks.
- **A fix round** reruns only the tests that pin its fix, through `relay-plan gate`; the fix prompt says so
  (`reviewing.md` §2), and the check after it is `relay-plan gates <plan> <those commands>`.
- **The merge** runs the repo's gates on the merged result (`relay-merge`, unchanged): the one independent full run.
- **A catch-up or conflict round** still reruns the full gates (`executing-plans`, unchanged): merging `main` in
  changes too much to pin.
- The orchestrator's rerun of one FAIL to confirm it (`reviewing.md` §1) stays: it is one targeted command.

## 6. The owner's decisions on the board (Plan 2)

**Proposed cards.** The agent that finds an issue files it: the acceptance reviewer its PRE-EXISTING and POLISH
findings, the code reviewer its Important and Minor findings, and the executor an issue it notices outside its plan.
Each card goes through `add_tasks` with the label `proposed`, kind `bug` or `change`, the plan's initiative, and a
body naming the plan, the file and the evidence (a path in the run folder). The agent's summary lists the card ids.
The relay-reviewer templates allow exactly this Quartz write, and no other. When `add_tasks` fails (a permission
refusal, an error), the agent appends the card to the run folder's `cards.md` instead and says so in its summary; the
orchestrator files those in one `add_tasks` call. Without Quartz, the agent appends the
card to the run folder's `cards.md`, and stop 4 lists them as today. Stop 4 no longer asks about cards on the board:
its report gives one line, the number filed. The owner prunes them on the board.

**The fix-round cap.** A finding (an acceptance FAIL, a Critical, a GREEN that failed) that still fails after
`fix-rounds` rounds (default 2) gets no further round. The orchestrator files a card for it (`proposed`, kind `bug`,
the evidence paths, "fix cap reached after n rounds"), and the rest of the loop carries on. Stop 4 then opens with a
question for it: the step failed after n rounds, card `<id>`; merge with it open, hold the branch, or one more round.
This replaces "a step that fails again after its second fix round goes to the owner" (`reviewing.md` §2, `SKILL.md`'s
stops). A gap in the spec or the plan still goes to the owner at once, as today.

## 7. Routing by path (Plan 2)

The orchestrator never reads a plan whole. It asks `relay-plan`:

| Where | Today | Now |
|---|---|---|
| `planning.md` §2 | nine greps | `relay-plan check <plan> --spec <spec>` (plus `--sibling` and `--base` as they apply), and the MCP half of check 1 (`get_task` lists the plan) |
| `parallel.md` §2 | the paths and digits pipelines | `relay-plan overlap` |
| `dispatching.md` §1, §5 | reading the task count and which tasks are the executor's | `relay-plan steps <plan>`'s first line |
| `reviewing.md` §1 | the `reviewer` step numbers | `relay-plan steps <plan> reviewer` |
| `reviewing.md` §4, §5 | the `owner` and `after merge` steps | `relay-plan steps` to list them, `relay-plan step` for the text of the ones it shows the owner or runs |

**When `relay-plan` is missing** (`command -v relay-plan` finds nothing), the orchestrator tells the owner and stops,
as it does for `relay-merge`.

**The skill tests** (`reviewing.md` §3) become:

1. The red and green skill folders go to the run folder's `skill-tests/red/` and `green/`, as today.
2. `relay-plan scenarios <plan> <run>/skill-tests` writes each scenario's situation to a file.
3. Two Sonnet runs per scenario, as today, with the standing preamble changed: the situation is in
   `step-<id>.txt`, read it and the skills folder only; write the answer to `step-<id>-green.md` (or `-red.md`), change
   no other file, and reply `done`.
4. One judge, a general-purpose agent on Sonnet, given the plan's path, the `skill-test` step ids and the folder: it
   reads each step's GREEN and RED from the plan, judges both answers, writes `verdicts.md`, and hands back one line
   per scenario: `<id>: GREEN pass|fail, RED fails|does not fail: <reason, at most 15 words>`.
5. A GREEN that fails is a fix round with the step id and the verdict file's path; a RED that does not fail is a line
   at stop 4, as today.

## 8. The other files (Plan 2)

- `skills/orchestrating/SKILL.md`: the stops table and the loop line (the fix cap); Finding where work stands (§3);
  the record rule; read once per session; `relay-plan` missing; a stop's last line (§3).
- `skills/orchestrating/planning.md`, `dispatching.md`, `reviewing.md`, `parallel.md`, `quartz.md`: as above.
- `skills/brainstorming/SKILL.md`: the decision notes (§3), a few lines.
- `skills/executing-plans/SKILL.md`: gates through `relay-plan gate`; the short summary and `executor.md`; no copied
  checklist; the run-folder exception; a fix round's targeted tests; proposed cards (§6).
- `skills/writing-plans/SKILL.md`: a `skill-test` situation in a ```` ```text ```` fence; no `reviewer` step that
  reruns the gates. `plan-document-reviewer-prompt.md`: findings to `plan-review.md`, a short reply.
- `skills/requesting-code-review/` (`code-reviewer.md`, and its `SKILL.md` where it describes the output): the review
  to `code-review.md`, Important and Minor filed as cards, a short reply.
- `skills/agents/`: the `fix-rounds` key where the header's keys are described.
- `templates/agents/executor.md`, `reviewer-commands.md`, `reviewer-browser.md`: the run folder, the cards, the short
  summary.
- `tests/orchestrating/run-tests.sh`: checks for what can be checked by text (the builder picks which), each with its
  broken copy, as the suite does today.
- `README.md`: where it describes the relay's loop or its stops, if it does.

## 9. Pressure scenarios (Plan 2's skill tests)

Each is a situation, what an agent with the branch's text must do (GREEN), and what one with `main`'s text does
instead (RED). The planner writes each in full. The runs are text only, as today: an agent answers with the commands
it would run and its next message, so `relay-plan` need not exist where they run; the situations give whatever its
output would be.

| # | Situation | GREEN | RED |
|---|---|---|---|
| S1 | The orchestrator has just dispatched the executor for plan P (card C, Quartz connected), and gets its agent id. | Posts C's status: P, the executor's id, the branch, next "verify the hand-back". | Posts nothing until the review legs. |
| S2 | A conversation that began with `/clear` receives an agent's completion notice; C's status names that id as P's executor; `executor.md` is in the run folder. | Reads C's status, recognizes P's executor, and runs the hand-back check from `executor.md` (`relay-plan gates`). | Does not know what the agent was, or asks the owner. |
| S3 | The executor's summary gives its gates' counts and `gates.log`. | Runs `relay-plan gates <plan>`; reruns no suite. | Reruns the gates. |
| S4 | The acceptance reviewer, in a repo with Quartz, finds a POLISH issue. | Files a `proposed` card through `add_tasks`, with kind, initiative and evidence path, and lists its id in a short summary. | Reports it only. |
| S5 | The orchestrator writes stop 4; the reviewers filed three `proposed` cards. | Asks nothing about them; one line with the count. | Asks the owner to keep or drop each. |
| S6 | An acceptance step fails again after its second fix round; the facts header has no `fix-rounds`. | Files a card, runs no third round, finishes the loop, and opens stop 4 with the merge-or-hold question naming the card. | Takes it to the owner at once, mid-loop. |
| S7 | The orchestrator writes the executor's fix prompt for one FAIL. | Tells it to rerun only the tests that pin the fix, through `relay-plan gate`. | "Rerun the gates." |
| S8 | The orchestrator reaches the skill tests of a plan whose Steps 5–9 are `skill-test`. | Runs `relay-plan scenarios`, dispatches the runs on the files with answer files, then one judge; never reads the plan's steps itself. | Reads the plan's steps and pastes each situation. |
| S9 | A planner has committed plan P for spec Q. | Runs `relay-plan check P --spec Q`. | Runs the nine greps. |
| S10 | In a brainstorm with card C, the owner picks approach B and gives a reason. | Adds a decision note on C with B and the reason, and updates C's status, with its next message. | Adds nothing until the spec. |
| S11 | The executor has finished its last task. | Runs each gate through `relay-plan gate`, writes `executor.md`, hands back the short summary without the checklist. | Runs the gates directly and copies the acceptance checklist into its report. |
| S12 | A planner writes the acceptance task of a plan that changes a skill. | No `reviewer` step that reruns the gates; each situation in a ```` ```text ```` fence. | A `reviewer` "the gates" step; situations unfenced or fenced at will. |
| S13 | Mid-run, the owner writes "I'm about to clear." | Says the board is current and nothing needs writing. | Writes a handoff note or memory. |
| S14 | The code reviewer finishes a review with 1 Critical, 2 Important and 3 Minor. | Writes `code-review.md`, files the five non-Critical findings as `proposed` cards, hands back the short summary. | Returns the whole review inline. |

## 10. Testing and acceptance

- **Plan 1:** its suite and the generator's suite at `0 failed`, `dash -n bin/relay-plan` silent, `claude plugin
  validate .` with its known warnings, run by the executor; the acceptance reviewer runs `relay-plan` against this
  repo's own merged plans (e.g. `check` and `steps` on the companion-hardening plan) and reports what it prints.
  After the merge: the release (§11).
- **Plan 2:** the relay guard at `0 failed`; the skill tests S1–S14; the acceptance reviewer reads the changed text
  against §3–§8. After the merge: the release, the agents regenerated here and in SAT, and a **live probe**: the next
  real relay run in this repo is run with the new skills. The owner clears once while an agent is running and once at
  a stop, without warning; PASS when the fresh session picks up from the board each time without being told, a
  `proposed` card is filed by a reviewer, no full gate is rerun before the merge, and the orchestrator reads no plan
  whole. Its transcript is then measured as in How it works, and the numbers are reported against the baselines
  there; they are not a gate.

## 11. Releases

Each plan's merge changes files the plugin loads, so each is released (`CLAUDE.md`, How a change reaches the owner):
Plan 1 as 0.2.6, Plan 2 as 0.2.7, unless the owner names another. After Plan 2: the role agents regenerated here and in
SAT (the templates change); the owner runs `claude plugin update hyper-relay@hyper-relay` and `/reload-plugins`; and
the orchestrator's handoff memory (`hyper-relay-handoff-2026-11-17`) is retired, with the owner's OK, since the board
holds that state now.

## 12. Out of scope, and left to the builder

**Out of scope:** a separate or headless spec writer (L7); a hook that blocks plan reads (L6); the other suggestions
of the SAT run report (card `f7b71482`: a "lands with" relation, a suite lock, test cadence per task, second-language
walks, the Quartz hook's repo prefix); terminal prompts for repeated questions (the other half of card `dd964aa3`); how
the planner reports.

**Left to the builder:** `relay-plan`'s internals and its exact detail lines; the wording of every instruction; which
text checks the relay guard gains; the exact form of the status line within the 500 characters; how `relay-plan
check` detects "a task that commits".
