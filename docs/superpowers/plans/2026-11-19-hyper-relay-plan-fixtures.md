# hyper-relay: test fixtures as signatures in plans, and `plan-usage.sh` to measure plans, Implementation Plan

**Card:** writing-plans: test fixtures as signatures, not bodies (`93e7a9dc-79ce-49e9-afe4-46f3434a801b`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-plan-fixtures-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–2 are
> the executor's. Task 3 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** A new `scripts/benchmark/plan-usage.sh` measures any plan after the fact (what the agents that wrote it
spent, from Claude Code's transcripts, and the plan's shape), and `writing-plans` gives a test fixture as its signature
and one sample of what it writes instead of its body, with the plan reviewer's prompt following.

**Architecture:** Task 1 writes `plan-usage.sh` and its jq test-first, in a section of `tests/benchmark/run-tests.sh`
on fixture transcripts and fixture plans, then its merge gate, its runbook section and its `CLAUDE.md` line. Task 2
changes four sentences of `writing-plans`' `SKILL.md` and one row of its reviewer prompt, and runs the full gates.
Task 3 accepts it: the tool on two real plans against the orchestrator's hand sums, four RED/GREEN skill tests, and
after the merge the baseline, its note on the card, the 0.2.3 release and the role agents.

**Tech Stack:** POSIX shell run by dash; jq 1.6 or later; POSIX awk (mawk runs it); git 2.31 or later
(`--path-format`); Markdown skills. For acceptance: Claude Code general-purpose subagents on Sonnet.

**How this was checked:** written against `main` at `3dfc222`, by reading only; nothing was built, run, installed or
generated.

---

## Execution notes (binding)

- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator
  are the installed plugin's (0.2.2). This plan changes `writing-plans`: follow your agent instructions and this plan,
  not the new text. Task 1's test step already follows the new fixture rule, which today's rule allows: its two new
  fixture helpers are given as a signature and a sample each, and its harness is the suite's own. Write them from those.
- **Skill and doc text is written exactly.** "Replace X with Y" means the Edit tool, X as `old_string`, Y as
  `new_string`; "Append exactly this" means every line of the block. The fence lines around a block are not part of
  the text; fences inside it are. Do not reflow, re-wrap or "fix" a word. If an X is not found, read the range again;
  if it moved or differs slightly, adapt as little as possible and record a deviation; if it is gone, stop and report.
- **The suite is the contract.** `tests/benchmark/run-tests.sh`'s 90 assertions stay as they are; its header changes
  only its description and its count. Needing to change an existing assertion is a stop.
- **`run-usage.sh`, `run-usage.jq`, `prices.tsv` and `superpowers-env.sh` are not touched:** `plan-usage.jq` copies
  the defs it needs from `run-usage.jq`.
- **Tests use fixtures only.** The suite's `HOME` is a temporary folder, and it unsets `CLAUDE_CONFIG_DIR` and
  `RUN_USAGE_PRICES`. Do not run `plan-usage.sh` on the real `~/.claude`: Task 3 Steps 2–3 do, as the acceptance
  reviewer's.
- **POSIX only.** `plan-usage.sh` is `#!/bin/sh`, run by dash (no `[[`, `local`, arrays or `$'…'`), committed
  executable (mode 100755, as `run-usage.sh` is); its awk uses POSIX awk only (no `gensub`, `strftime` or
  `IGNORECASE`).
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.2; Task 3 releases 0.2.3
  after the merge.
- The spec's project-wide values, verbatim:
  - "POSIX shell run by dash, with jq 1.6 or later, as `run-usage.sh`. It reads transcripts and the plan, and writes
    nothing but a temporary folder."
  - "Columns, in order: Plan · Agents · Model · API calls · Output · Cache write · Cache read · Uncached in · Final
    context · Tool uses · Duration · Cost · Plan lines · Spec lines · Test code · Other code · Text."
  - "Numbers are written with thousands separators (`156,741`), as the orchestrator's token log writes them; Cost in
    US dollars with two decimals (`$12.34`); Duration as `22m32s` (`1h05m09s` past an hour)."
  - "No such agent: exit 1, `plan-usage: no agent wrote <plan path> (transcripts under <config>/projects)`."
  - "`run-usage.sh`, `run-usage.jq`, `prices.tsv` and every other skill stay as they are."
  - PF5: "**Never into this repo,** which is public: SAT's plan names carry its internals. The script only prints;
    SAT rows go to `~/sat-benchmark/`, outside both repos."
- **The full gates** (Task 2 Step 5): `sh tests/benchmark/run-tests.sh`; `dash -n` on `scripts/benchmark/plan-usage.sh`,
  `run-usage.sh` and `superpowers-env.sh`; `sh tests/orchestrating/run-tests.sh`; `claude plugin validate .`. They are
  also `relay-merge`'s gates for this branch (`.hyper-relay/merge.conf`, Task 1's line included once merged).
- **Task 3 is not yours.** After Task 2, report, copy Task 3's checklist into your report, and stop.

## Review Focus

1. **An executed plan, every step ticked `- [x]`** (every plan the baseline measures): a block in a ticked step is
   classed as in an unticked one, or every merged plan would show no test code (P1). Plan A ticks its "Write the
   failing test" step, and its row asserts Test code `5` (Task 1 Step 1).
2. **A plan path relative to the checkout's top**, as the runbook's loop and Task 3's steps give it: the same row as
   the absolute path. Task 1 Step 1's `--no-header` test runs from the fixture repo's top.
3. **A transcript line cut short** (Claude Code killed mid-write): skipped, as `run-usage.sh` skips one, never an
   error. Agent a1's transcript holds one, and plan A's row is exact (Task 1 Step 1).
4. **The same plan file name written in another repo:** not counted; only the main checkout's path and its
   `.worktrees/<name>/` copies are. Agent c2 writes one, and plan C's row leaves it out (Task 1 Step 1).
5. **A block after a task's heading and before its first step:** in no step, so Other code, not in the previous
   task's last step (P2). Plan A's Task 2 opens with one, after a step whose first path is a test file (Task 1 Step 1).

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §2.6: "the nearest `- [ ] **Step` line before it" | Executed plans tick their steps (`- [x]`), and the baseline measures merged plans. A step line is `- [ ] **Step`, `- [x] **Step` or `- [X] **Step`, after any leading spaces. |
| P2 | §2.6: a block's step is "the text from the nearest … line before it, up to the block" | A line starting with `#` outside a block ends the step: a block between a task's heading and its first step is in no step, so Other code. Otherwise it would take the class of the previous task's last step. |
| P3 | §2.6: the step's "bold title … contains "test", and does not begin with "Run" or "Verify"" | The title is the first `**…**` on the step line, less everything up to its first `:` (with no `:`, less its leading `Step <n>` and the punctuation after it); when that leaves nothing (the `**Step 1:** Write …` form), it is the rest of the line after the bold. "Contains" and "begins" compare in lower case, on the trimmed title. So an acceptance step titled "Step 7 (skill-test): S1, …" reads "S1, …", not a test step. |
| P4 | §2.6: "whose first backticked path is in a test folder … or named like a test file" | A backticked path is a single-backtick span with no space in it that holds a `/` or a `.`. The first one is looked for in the step's text: its step line and the lines after it outside blocks, up to the block (an earlier block's own lines are not searched). In a test folder: one of its `/`-separated parts is `tests`, `test`, `spec` or `__tests__`. |
| P5 | §2.4 Duration: "to the last record before the next prompt" | A record is a user or assistant record with a `timestamp`, as `run-usage.jq` times its records; a line that is not JSON is none. Pieces follow the transcript's line order. A `<synthetic>` assistant record is a record here. The sum is floored to whole seconds. |
| P6 | §2.4 Model: "`<synthetic>` left out" | A `<synthetic>` record is no call at all, as `run-usage.jq`'s `is_call` has it: not counted, not priced (it has no price, so it would otherwise refuse), not in Model. |
| P7 | §2.3, §2.4: Agents and Model, comma-separated | `, `-separated, in order of first appearance (a type by its first agent's first record, a model by its first call), not sorted: the spec's own example is `sat-planner, general-purpose`. A count is ` ×<n>` after the type. An agent with no meta file, or no `agentType` in it, is `?`, as `run-usage.sh` names one. |
| P8 | §2.1: the refusals and "a `usage:` line" | Pinned in Task 1 Step 3: `usage: plan-usage.sh [--config <folder>] [--no-header] <plan file>`, with no `plan-usage:` before it; options and the plan in any order; a second plan, an unknown option or a bare `--config` is wrong arguments. The messages: `no plan file at <plan file>`, `not in a git repo: <plan file>`, `no projects folder in <config>` (`run-usage.sh`'s words), `no price for <model> in <prices file>`, and two the spec does not list, `needs jq` and `no prices file at <prices file>`. `<plan path>` in `no agent wrote` is the plan's path in its repo. |
| P9 | §2.2: Duration as `22m32s` | Below a minute, `0m20s`: minutes always, seconds two digits. |
| P10 | §6: the loop "after one header" | The runbook's loop prints the header from the first plan it can measure (`${h:+--no-header}`), so a plan no agent wrote, or whose transcript expired, adds nothing to the table; its `plan-usage:` line goes to stderr. |
| P11 | §4: check 5 gains "and fixture helpers with their signature and a sample" | It also gains "(a test file is never one)" after "Text steps do not count against the plan here": S3's RED keeps a test file because that sentence exempts text steps, and the new "never a text step" sentence sits in another section. **The owner may drop it at stop 3.** |
| P12 | §5: the row "also flags a fixture helper written out instead of its signature and sample, and a test file given as a text step" | The row keeps the skill's exception, "(unless its exact bytes are what the test checks)", so a reviewer does not flag S2's cut-short line, and names the text step's form, ("Create X with exactly this content"). |
| P13 | §7 S3: "a 120-line test file in its draft" | The situation describes the file's 120 lines part by part (harness, three fixture writers, five tests, the count) instead of pasting them; the step's form, "Create … with exactly this content", is given in full. |
| P14 | §8, and `.hyper-relay/agents.md`: the release steps come "last" | The baseline (Step 13) and its card note (Step 14) need no release and come first; then the release and the update (Steps 15–16), the role agents, which need the installed 0.2.3 generator (Step 17), and the record (Step 18), as brainstorming v7's P13 had it. |
| P15 | §8: the note's "test-code lines … SAT and this repo apart" | This repo's figures leave out this plan, which already gives its fixtures as signatures; SAT's take every plan measured. |
| P16 | §8: regenerate the role agents "in SAT" | SAT's checkout is `/home/noob_master/sat.pentraze.com`, as earlier plans name it. Not while a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: the orchestrator asks the owner first then. |
| P17 | §3: "Each asserts exact values" | Each row is asserted whole, every cell at once, and each refusal's exit code and message in one assertion (`"$RC $OUT"`). |
| P18 | §2.5: a block "closes at the next line with the same backticks alone" | "Alone" allows spaces around them; a block never closed runs to the end of the file. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1, 2; 3 (Steps 2, 13–14) |
| Decisions (owner, 2026-11-19) | PF1: 3 (Steps 6–9, 13–14). PF2: 1. PF3: 1. PF4: 2, 3 (Steps 6–9). PF5: 1 (Step 6), 3 (Steps 13–14, 18). PF6: 1 then 2. PF7: 3 (Step 13). PF8: 1 (Duration, the test-code rule), 2 (the reviewer's row) |
| 1. What changes where | 1, 2; 3 (Step 4) |
| 2. `scripts/benchmark/plan-usage.sh` | 1; 3 (Steps 1–3) |
| 3. Tests | 1 |
| 4. `skills/writing-plans/SKILL.md` | 2; 3 (Steps 5–8) |
| 5. `skills/writing-plans/plan-document-reviewer-prompt.md` | 2; 3 (Steps 5, 9) |
| 6. `docs/benchmarks/README.md` | 1 (Step 6) |
| 7. Pressure scenarios | 3 (Steps 6–9) |
| 8. Acceptance, baseline and release | 2 (the full gates); 3 |
| 9. Out of scope | No task; 3 (Step 4: only §1's files) |

## File structure

- **Create (Task 1):** `scripts/benchmark/plan-usage.sh` (mode 100755), `scripts/benchmark/plan-usage.jq`.
- **Modify (Task 1):** `tests/benchmark/run-tests.sh`, `.hyper-relay/merge.conf`, `docs/benchmarks/README.md`,
  `CLAUDE.md`.
- **Modify (Task 2):** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.
- **Unchanged:** `scripts/benchmark/run-usage.sh`, `run-usage.jq`, `prices.tsv`, `superpowers-env.sh`, every other
  skill, `templates/`, `bin/`, `hooks/`, `.claude-plugin/`, `package.json`, every other suite.

---

### Task 1: `plan-usage.sh`, its tests, its gate and its docs (spec §1–§3, §6; PF2, PF3, PF5, PF8; P1–P10, P17, P18)

**Files:**
- Create: `scripts/benchmark/plan-usage.sh`, `scripts/benchmark/plan-usage.jq`
- Modify: `tests/benchmark/run-tests.sh:2-6` (header), after `:303` (a new section)
- Modify: `.hyper-relay/merge.conf:51`, `docs/benchmarks/README.md` (a section after `:323`), `CLAUDE.md:34-37`

- [x] **Step 1: Write the failing tests** in `tests/benchmark/run-tests.sh`.

First its header. Replace:

```text
# POSIX tests for G.2's benchmark tools (docs/benchmarks/README.md): scripts/benchmark/run-usage.sh on
# small fixture transcripts priced by a test prices file, and scripts/benchmark/superpowers-env.sh with
# a fake home folder and a fake claude that records its calls. HOME is a temporary folder before either
# tool runs, so nothing here reads or writes the real ~/.claude, ~/.claude.json or a login.
# Usage: sh tests/benchmark/run-tests.sh      Expect: "90 passed, 0 failed"
```

with:

```text
# POSIX tests for G.2's benchmark tools (docs/benchmarks/README.md): scripts/benchmark/run-usage.sh and
# scripts/benchmark/plan-usage.sh on small fixture transcripts priced by a test prices file (plan-usage.sh
# also on fixture plans in a temporary git repo), and scripts/benchmark/superpowers-env.sh with a fake
# home folder and a fake claude that records its calls. HOME is a temporary folder before any tool runs,
# so nothing here reads or writes the real ~/.claude, ~/.claude.json or a login.
# Usage: sh tests/benchmark/run-tests.sh      Expect: "110 passed, 0 failed"
```

Then a new section, after the `run-usage --sessions` tests' last line
(`assert_eq "sessions: a time not in UTC form: exit 1" 1 "$RC"`) and before `# A fake claude, first on PATH, …`. It
uses the run-usage section's fixtures (`prompt`, `result`, `call`, `old_call`, `TOOL`, `THINK` and
`$TMP_ROOT/prices.tsv`) and adds three helpers:

- `file_tool <tool> <path>`: prints one `tool_use` content block, for `call`'s last argument, naming that tool on that
  file: `{"type":"tool_use","id":"t","name":"Write","input":{"file_path":"/tmp/x/pu-repo/docs/superpowers/plans/2026-01-01-pu-a.md"}}`
- `agent_meta <transcript> <agent type>`: writes the transcript's meta file, its path with `.jsonl` replaced by
  `.meta.json`: `{"agentType":"relay-planner","description":"x","spawnDepth":1}`
- `pu <args>`: as `ru`, running `plan-usage.sh` with the test prices, and with `GIT_CEILING_DIRECTORIES=$TMP_ROOT`
  added to its environment so that no git repo above the temporary folder counts. Sets `OUT` (stdout and stderr) and
  `RC`.

The setup and the assertions:

```sh
echo '--- plan-usage: fixture plans and transcripts'
PU=$REPO/scripts/benchmark/plan-usage.sh
G=2026-01-03T
PR=$TMP_ROOT/pu-repo
PP=$PR/docs/superpowers/plans
PA=$PP/2026-01-01-pu-a.md
PB=$PP/2026-01-01-pu-b.md
PC=$PP/2026-01-01-pu-c.md
PD=$PP/2026-01-01-pu-d.md
PE=$PP/2026-01-01-pu-e.md
git init -q "$PR"
mkdir -p "$PP" "$PR/docs/superpowers/specs"
printf '%s\n' '# Demo spec' '' '## Goal' 'A demo.' > "$PR/docs/superpowers/specs/2026-01-01-pu-design.md"
<here: plan A, the 56 lines of the block after this one, written to "$PA" by a quoted heredoc (cat > "$PA" <<'EOF')>
printf '%s\n' '# Plan B' '' '- [ ] **Step 1: Write the failing test**' > "$PB"
printf '%s\n' '# Plan C' '' '**Spec:** `docs/superpowers/specs/nosuch-design.md`' > "$PC"
printf '%s\n' '# Plan D' > "$PD"
printf '%s\n' '# Plan E' > "$PE"

PS=$HOME/.claude/projects/-pu
mkdir -p "$PS/s1/subagents" "$PS/s2/subagents" "$PS/s3/subagents" "$HOME/pu-other/projects/-x/s9/subagents"
# a1, plan A's planner, resumed an hour later: a call written as two records, an older record with no
# cache_creation, a line cut short, a <synthetic> record.
{
    prompt "${G}10:00:00.000Z" "write plan A"
    call "${G}10:01:00.000Z" A1 test-big tool_use 10 1000000 0 0 10000 "$TOOL"
    result "${G}10:01:01.000Z"
    call "${G}10:02:00.000Z" A2 test-big tool_use 10 0 1000000 1000000 20000 "$THINK"
    call "${G}10:02:01.000Z" A2 test-big tool_use 10 0 1000000 1000000 20000 "$(file_tool Write "$PA")"
    result "${G}10:02:02.000Z"
    old_call "${G}10:03:00.000Z" A3 test-big end_turn 10 1000000 2000000 30000
    printf '%s\n' '{"type":"assistant","message":'
    call "${G}10:03:05.000Z" A0 '<synthetic>' end_turn 0 0 0 0 0
    prompt "${G}11:03:05.000Z" "revise plan A"
    call "${G}11:04:00.000Z" A4 test-big tool_use 10 0 0 3000000 45000 "$(file_tool Edit "$PA")"
    result "${G}11:04:01.000Z"
    call "${G}11:05:10.000Z" A5 test-big end_turn 20 100000 0 3000000 60000
} > "$PS/s1/subagents/agent-a1.jsonl"
agent_meta "$PS/s1/subagents/agent-a1.jsonl" relay-planner
# b1 and b2, two planners of plan B; b3, of another type, also edited it; b4 only read it.
{
    prompt "${G}12:00:00.000Z" "write plan B"
    call "${G}12:50:00.000Z" B1 test-small tool_use 100 0 0 2000000 10000 "$(file_tool Write "$PB")"
} > "$PS/s2/subagents/agent-b1.jsonl"
agent_meta "$PS/s2/subagents/agent-b1.jsonl" relay-planner
{
    prompt "${G}13:00:00.000Z" "revise plan B"
    call "${G}13:20:00.000Z" B2 test-big tool_use 100 500000 0 0 20000 "$(file_tool Edit "$PB")"
} > "$PS/s2/subagents/agent-b2.jsonl"
agent_meta "$PS/s2/subagents/agent-b2.jsonl" relay-planner
{
    prompt "${G}13:30:00.000Z" "fix plan B"
    call "${G}13:30:30.000Z" B3 test-small tool_use 100 0 0 100000 5000 "$(file_tool MultiEdit "$PB")"
} > "$PS/s2/subagents/agent-b3.jsonl"
agent_meta "$PS/s2/subagents/agent-b3.jsonl" general-purpose
{
    prompt "${G}13:40:00.000Z" "read plan B"
    call "${G}13:40:10.000Z" B4 test-big tool_use 0 0 0 0 1000000 "$(file_tool Read "$PB")"
} > "$PS/s2/subagents/agent-b4.jsonl"
agent_meta "$PS/s2/subagents/agent-b4.jsonl" Explore
# c1 wrote plan C in a worktree; c2 wrote a file of the same name in another repo; e1 wrote plan E on a model
# with no price.
{
    prompt "${G}14:00:00.000Z" "write plan C"
    call "${G}14:01:00.000Z" C1 test-big tool_use 1 0 0 0 1000 "$(file_tool Write "$PR/.worktrees/w1/docs/superpowers/plans/2026-01-01-pu-c.md")"
} > "$PS/s3/subagents/agent-c1.jsonl"
agent_meta "$PS/s3/subagents/agent-c1.jsonl" relay-planner
{
    prompt "${G}14:10:00.000Z" "write another repo's plan"
    call "${G}14:10:30.000Z" C2 test-big tool_use 0 0 0 0 1000000 "$(file_tool Write "$TMP_ROOT/elsewhere/docs/superpowers/plans/2026-01-01-pu-c.md")"
} > "$PS/s3/subagents/agent-c2.jsonl"
agent_meta "$PS/s3/subagents/agent-c2.jsonl" relay-planner
{
    prompt "${G}16:00:00.000Z" "write plan E"
    call "${G}16:00:10.000Z" E1 test-unknown tool_use 1 0 0 0 1 "$(file_tool Write "$PE")"
} > "$PS/s3/subagents/agent-e1.jsonl"
agent_meta "$PS/s3/subagents/agent-e1.jsonl" relay-planner
# z1, in another config folder, wrote plan D.
{
    prompt "${G}15:00:00.000Z" "write plan D"
    call "${G}15:00:20.000Z" D1 test-big tool_use 0 0 0 0 100 "$(file_tool Write "$PD")"
} > "$HOME/pu-other/projects/-x/s9/subagents/agent-z1.jsonl"
agent_meta "$HOME/pu-other/projects/-x/s9/subagents/agent-z1.jsonl" general-purpose

PU_HEAD='| Plan | Agents | Model | API calls | Output | Cache write | Cache read | Uncached in | Final context | Tool uses | Duration | Cost | Plan lines | Spec lines | Test code | Other code | Text |'
PU_SEP='|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|'
ROW_A='| 2026-01-01-pu-a.md | relay-planner | test-big | 5 | 165,000 | 3,100,000 | 9,000,000 | 60 | 3,100,020 | 3 | 5m10s | $7.18 | 56 | 4 | 5 | 3 | 7 |'
ROW_B='| 2026-01-01-pu-b.md | relay-planner ×2, general-purpose | test-small, test-big | 3 | 35,000 | 500,000 | 2,100,000 | 300 | 100,100 | 3 | 1h10m30s | $1.08 | 3 | - | 0 | 0 | 0 |'
ROW_C='| 2026-01-01-pu-c.md | relay-planner | test-big | 1 | 1,000 | 0 | 0 | 1 | 1 | 1 | 1m00s | $0.01 | 3 | - | 0 | 0 | 0 |'
ROW_D='| 2026-01-01-pu-d.md | general-purpose | test-big | 1 | 100 | 0 | 0 | 0 | 0 | 1 | 0m20s | $0.00 | 1 | - | 0 | 0 | 0 |'
PU_USAGE='usage: plan-usage.sh [--config <folder>] [--no-header] <plan file>'

echo '--- plan-usage: rows'
pu "$PA"
assert_eq "plan-usage: the header names the columns, in order" "$PU_HEAD" "$(printf '%s\n' "$OUT" | sed -n 1p)"
assert_eq "plan-usage: the separator" "$PU_SEP" "$(printf '%s\n' "$OUT" | sed -n 2p)"
assert_eq "plan-usage: a resumed planner: one call per message id, no <synthetic> call or model, 5-minute and 1-hour writes priced apart, an older record's writes as 5-minute ones, the hour between its prompts left out, a cut-short line skipped; the plan's shape and its spec's lines" \
    "$ROW_A" "$(printf '%s\n' "$OUT" | sed -n 3p)"
assert_eq "plan-usage: three lines in all" 3 "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')"
cd "$PR" || exit 1
pu --no-header docs/superpowers/plans/2026-01-01-pu-a.md
cd - > /dev/null || exit 1
assert_eq "plan-usage --no-header: the row alone, for a plan path relative to the checkout's top" "$ROW_A" "$OUT"
pu --no-header "$PB"
assert_eq "plan-usage: two planners and an agent of another type that edited the plan are summed, one that only read it is not; no Spec line" \
    "$ROW_B" "$OUT"
pu --no-header "$PC"
assert_eq "plan-usage: a plan written in a worktree; the same file name in another repo does not count; a Spec line naming no file" \
    "$ROW_C" "$OUT"
git -C "$PR" add docs
git -C "$PR" -c core.hooksPath=/dev/null -c commit.gpgsign=false -c user.name=test -c user.email=test@example.invalid commit -q -m fixtures
git -C "$PR" -c core.hooksPath=/dev/null worktree add -q "$PR/.worktrees/w2"
pu --no-header "$PR/.worktrees/w2/docs/superpowers/plans/2026-01-01-pu-a.md"
assert_eq "plan-usage: a plan given by its path in a worktree is measured as the main checkout's" "$ROW_A" "$OUT"

echo '--- plan-usage: the config folder'
pu --no-header --config "~/pu-other" "$PD"
assert_eq "plan-usage --config: a leading ~/ is the home folder, and only that folder's transcripts count" "$ROW_D" "$OUT"
CLAUDE_CONFIG_DIR=$HOME/pu-other
export CLAUDE_CONFIG_DIR
pu --no-header "$PD"
assert_eq "plan-usage: CLAUDE_CONFIG_DIR is the default config folder" "$ROW_D" "$OUT"
pu --no-header --config "$HOME/.claude" "$PA"
assert_eq "plan-usage: --config wins over CLAUDE_CONFIG_DIR" "$ROW_A" "$OUT"
unset CLAUDE_CONFIG_DIR

echo '--- plan-usage: what it refuses'
pu "$PP/2026-01-01-nosuch.md"
assert_eq "plan-usage: no plan file: exit 1, says so" "1 plan-usage: no plan file at $PP/2026-01-01-nosuch.md" "$RC $OUT"
mkdir -p "$TMP_ROOT/norepo"
printf '# x\n' > "$TMP_ROOT/norepo/plan.md"
pu "$TMP_ROOT/norepo/plan.md"
assert_eq "plan-usage: a plan outside a git repo: exit 1, says so" "1 plan-usage: not in a git repo: $TMP_ROOT/norepo/plan.md" "$RC $OUT"
mkdir -p "$TMP_ROOT/empty-cfg"
pu --config "$TMP_ROOT/empty-cfg" "$PA"
assert_eq "plan-usage: a config folder with no projects folder: exit 1, says so" "1 plan-usage: no projects folder in $TMP_ROOT/empty-cfg" "$RC $OUT"
pu "$PD"
assert_eq "plan-usage: a plan no agent wrote: exit 1, says so" \
    "1 plan-usage: no agent wrote docs/superpowers/plans/2026-01-01-pu-d.md (transcripts under $HOME/.claude/projects)" "$RC $OUT"
pu "$PE"
assert_eq "plan-usage: a model with no price: exit 1, says so" "1 plan-usage: no price for test-unknown in $TMP_ROOT/prices.tsv" "$RC $OUT"
pu
assert_eq "plan-usage: no argument: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu --bogus "$PA"
assert_eq "plan-usage: an option it does not know: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu "$PA" "$PB"
assert_eq "plan-usage: two plans: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu --config
assert_eq "plan-usage: --config with no folder: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
```

Plan A, the fixture plan whose exact lines the shape assertions count (56 lines, a test-code block in a ticked
step and in a step naming a test file first, other code in no step, in a "Run" step and after a heading, text as
`markdown`, as a ```` block holding a ``` block, and with no language):

`````markdown
# Plan A

**Spec:** `docs/superpowers/specs/2026-01-01-pu-design.md`

```sh
echo in no step
```

### Task 1: The tool

- [x] **Step 1: Write the failing test**

```sh
assert_eq one 1 "$x"
assert_eq two 2 "$y"
```

- [ ] **Step 2: Run test to verify it fails**

  ```sh
  sh tests/x/run-tests.sh
  ```

- [ ] **Step 3: The fixtures,** in `tests/x/run-tests.sh`:

```sh
fixture a
fixture b
fixture c
```

### Task 2: The docs

```sh
echo after a heading
```

- [ ] **Step 1: The doc**

```markdown
# Doc
Some text.
```

- [ ] **Step 2: The skill text**

````markdown
Intro.
```sh
inner
```
````

```
plain
```
`````

The rows' figures, for checking: plan A's planner makes five calls (A0 is `<synthetic>`; A2's two records are one
call), priced $1.35001 + $2.30001 + $1.75001 + $0.75001 + $1.02502 = $7.17506; its pieces are 3m05s and 2m05s. Plan B's
B1 prompt is over 1,000,000, so `test-small`'s upper row prices it ($0.2401 + $0.8251 + $0.01505 = $1.08025); its
pieces are 50m00s, 20m00s and 0m30s. Plan A's blocks: Test code 2 + 3, Other code 1 + 1 + 1, Text 2 + 4 + 1.

- [x] **Step 2: Run test to verify it fails**

Run: `sh tests/benchmark/run-tests.sh | tail -n 1`
Expected: `90 passed, 20 failed` (dash cannot open the missing `plan-usage.sh`, so every new assertion fails).

- [x] **Step 3: Implement `plan-usage.sh [--config <folder>] [--no-header] <plan file>` in
  `scripts/benchmark/plan-usage.sh`, and its reader, `scripts/benchmark/plan-usage.jq`**

`plan-usage.sh`: `#!/bin/sh`, `set -eu`, a header comment in `run-usage.sh`'s style (what it prints and from what,
`RUN_USAGE_PRICES`, jq 1.6 or later, POSIX shell run by dash); `chmod +x`.

- **Arguments** (P8): `--config <folder>`, `--no-header` and one plan file, in any order. A missing or second plan, an
  unknown option, or `--config` with nothing after it: `usage: plan-usage.sh [--config <folder>] [--no-header] <plan
  file>` on stderr, exit 1.
- **Refusals**, each one line `plan-usage: <message>` on stderr and exit 1, checked in this order: `needs jq`;
  `no plan file at <plan file>`; `not in a git repo: <plan file>`; `no projects folder in <config>`;
  `no prices file at <prices file>`; then the two the jq finds, `no agent wrote <repo path> (transcripts under
  <config>/projects)` and `no price for <model> in <prices file>` (the first unpriced model, by its first call).
  `<plan file>` is as given, `<config>` after `~/` expansion, `<prices file>` is `RUN_USAGE_PRICES`, else `prices.tsv`
  beside the script. However the jq signals its two, the script's stderr is that one line and its exit is 1.
- **Paths** (spec §2.3): the checkout is `git -C <plan's folder> rev-parse --show-toplevel`; the plan's repo path is
  `git -C <plan's folder> rev-parse --show-prefix` followed by its file name; the main checkout is the parent of
  `git -C <plan's folder> rev-parse --path-format=absolute --git-common-dir`.
- **Config:** `--config`, else `$CLAUDE_CONFIG_DIR`, else `$HOME/.claude`; a leading `~/` is `$HOME/`, as
  `run-usage.sh`'s `expand_home` has it.
- **Candidates:** of `<config>/projects/*/*/subagents/agent-*.jsonl`, those whose text holds the plan's repo path
  (`grep -l -F`), so the jq reads a handful of files rather than every transcript on the machine. Each goes to the jq
  with its `agent-<id>.meta.json`'s `agentType` (`?` without one), in a manifest as `run-usage.sh` builds its own. No
  candidate: the `no agent wrote` refusal.
- **Plan lines:** the plan's `wc -l`. **Spec lines:** the first line starting `**Spec:**`, its first backticked span
  read as a path from the checkout's top; that file's `wc -l`, or `-` when the line or the file is missing.
- **The shape,** `plan_shape <plan file>`, printing `<test code> <other code> <text>`, in POSIX awk (spec §2.5–§2.6,
  with P1–P4 and P18):
  - A block opens at a line whose first non-space characters are three or more backticks; its info string is the
    first word after them, in lower case. Inside it nothing opens; it closes at the first later line that is, spaces
    aside, exactly as many backticks; never closed, it runs to the end of the file. Its lines are those between its
    fences.
  - Outside blocks, a step line's first non-space characters are `- [ ] **Step`, `- [x] **Step` or `- [X] **Step`; a
    line starting with `#` ends the step. A block's step is the one open at its opening fence, if any. The step's text
    is its step line and the lines outside blocks after it, up to this block.
  - The step's title: the first `**…**` on its step line, less everything up to its first `:` (with no `:`, less its
    leading `Step <n>` and the punctuation after it), trimmed; when that is empty, the rest of the step line after the
    bold. Its first backticked path: the first single-backtick span in the step's text with no space in it and a `/`
    or a `.`.
  - **Text:** info string `markdown`, `md`, `text`, `txt` or empty. **Test code:** any other, in a step whose title,
    in lower case, contains `test` and does not begin with `run` or `verify`, or whose first backticked path has a
    `/`-separated part `tests`, `test`, `spec` or `__tests__`, or a file name `test_*`, `*_test.*` or `*.test.*`.
    **Other code:** every other block.
- The jq prints the header line and the separator (unless `--no-header`), then the row.

`plan-usage.jq`, run as `run-usage.jq` is (`jq -n -r -R -f`, the candidates as its inputs, `input_filename` naming
each line's file, everything else as `--arg` and `--argjson`):

- `ts`, `pad2`, `two`, `commas`, `is_call`, `usage_of`, `price_table` and `price` are copied from `run-usage.jq` word
  for word. A line that is not JSON is skipped (`fromjson? // empty`).
- **Who counts:** an agent wrote the plan when an assistant record of its transcript has a `tool_use` block named
  `Write`, `Edit` or `MultiEdit` whose `input.file_path` is `<main checkout>/<repo path>`, or
  `<main checkout>/.worktrees/<one folder>/<repo path>`. Everything below counts only those agents; none is the
  `no agent wrote` refusal.
- **Calls:** `is_call` records, one per `message.id`, its earliest record standing for it, as `run-usage.jq` keeps
  them; a `<synthetic>` record is no call (P6). **Output, Cache write, Cache read, Uncached in:** the calls' sums of
  `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens` and `input_tokens`. **Cost:** each call at
  `price`, on `usage_of`'s split of 5-minute and 1-hour writes, summed and written `"$" + two`; a call `price` cannot
  price is the refusal.
- **Model:** each call's model once, by first call, `, `-joined. **Agents:** each type once, by its first agent's
  first record, with ` ×<n>` when more than one agent has it, `, `-joined (P7).
- **Final context:** the latest call's `input_tokens + cache_creation_input_tokens + cache_read_input_tokens`.
  **Tool uses:** the `tool_use` blocks in the counted agents' assistant records.
- **Duration** (P5, P9): per agent, its user and assistant records that have a `timestamp`, in line order. A prompt is
  a user record with no `tool_result` block in its `message.content`; a piece runs from a prompt to the last record
  before the next prompt, or to the agent's last record. The pieces' sum over all the agents, floored to seconds, is
  `<m>m<ss>s` under an hour and `<h>h<mm>m<ss>s` from an hour.
- Every number with `commas`; the row is `| <cell> | … |`, its cells in spec §2.2's order, as `ROW_A` shows.

- [x] **Step 4: Run the tests to verify they pass**

| Run | Expected |
|---|---|
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `110 passed, 0 failed` |
| `sh tests/benchmark/run-tests.sh \| grep -c '^ok   plan-usage'` | `20` |
| `dash -n scripts/benchmark/plan-usage.sh` | silent, exit 0 |
| `test -x scripts/benchmark/plan-usage.sh && echo x` | `x` |

- [x] **Step 5: The merge gate.** In `.hyper-relay/merge.conf`, replace:

```text
scripts/benchmark/              build  dash -n scripts/benchmark/run-usage.sh
```

with:

```text
scripts/benchmark/              build  dash -n scripts/benchmark/run-usage.sh
scripts/benchmark/              build  dash -n scripts/benchmark/plan-usage.sh
```

- [x] **Step 6: The runbook's section (spec §6).** Append to `docs/benchmarks/README.md`, after its last line
  (`numbers, one-line findings and commit hashes, never SAT's code, data or secrets.`), one blank line and then exactly
  this:

````markdown
## Measuring one plan

`scripts/benchmark/plan-usage.sh` measures one implementation plan after the fact, from Claude Code's transcripts, at
no cost. It finds every subagent whose transcript wrote the plan (a `Write`, `Edit` or `MultiEdit` of its path in the
repo's main checkout, or in a worktree under `.worktrees/`) and prints a Markdown table of one row:

- **What those agents spent:** their types (`relay-planner ×2` when a fresh planner revised the plan; a planner
  resumed for a revision is one agent), their models, API calls, output, cache writes, cache reads and uncached input;
  the final context, the last call's whole prompt, which a task notification reports as `subagent_tokens`; their tool
  uses; their active time, from each prompt an agent was given to its last record before the next one, so a planner
  waiting at stop 3 is not charged the wait; and the cost, priced from `prices.tsv` as `run-usage.sh` prices a run.
- **The plan's shape:** its lines, its spec's lines (the file its `**Spec:**` line names), and its code blocks' lines
  in three classes: test code (a block in a step about writing a test, or whose first file is a test file), other
  code, and text (`markdown`, `text` or no language).

From a repo's top (`$HR` as in Paths):

```sh
"$HR/scripts/benchmark/plan-usage.sh" docs/superpowers/plans/<plan>.md
```

`--config <folder>` reads another config folder than `$CLAUDE_CONFIG_DIR` (or `~/.claude`). `--no-header` prints the
row alone, so a loop builds one table; in this one, the first plan it can measure prints the header:

```sh
h=
for p in docs/superpowers/plans/*.md; do
    "$HR/scripts/benchmark/plan-usage.sh" ${h:+--no-header} "$p" && h=1
done
```

- **It measures only plans an agent wrote.** For a plan written in the main session it prints
  `plan-usage: no agent wrote …` and exits 1. Upstream superpowers writes its plans in the main session:
  `run-usage.sh` measures that run instead.
- **Transcripts expire after 30 days** (`cleanupPeriodDays`), and a plan's row with them: measure a plan within 30
  days of its writing.
- **SAT's rows stay in `~/sat-benchmark/`,** never in this repo or SAT's: SAT's plan names carry its internals. Run
  the loop from `"$SAT"`, with its output in `"$BENCH/plan-usage-<date>.md"`.
````

- [x] **Step 7: `CLAUDE.md`'s layout line.** Replace:

```text
- `scripts/benchmark/`: piece G.2's tools for a baseline against upstream superpowers. `superpowers-env.sh` builds a
  separate Claude Code config folder for the upstream run, and `run-usage.sh` (with `run-usage.jq` and `prices.tsv`)
  reads a run's transcripts into a usage table. `tests/benchmark/` tests both, with a fake `claude` and fixture
  transcripts. `docs/benchmarks/` holds the protocol's fixed prompts, its run-log template and its runbook.
```

with:

```text
- `scripts/benchmark/`: piece G.2's tools for a baseline against upstream superpowers. `superpowers-env.sh` builds a
  separate Claude Code config folder for the upstream run, and `run-usage.sh` (with `run-usage.jq` and `prices.tsv`)
  reads a run's transcripts into a usage table. `plan-usage.sh` (with `plan-usage.jq`) measures one plan: its
  planner's usage, from the transcripts of the agents that wrote it, and the plan's shape. `tests/benchmark/` tests
  all three, with a fake `claude`, fixture transcripts and fixture plans. `docs/benchmarks/` holds the protocol's fixed
  prompts, its run-log template and its runbook.
```

- [x] **Step 8: Commit**

```bash
git add scripts/benchmark/plan-usage.sh scripts/benchmark/plan-usage.jq tests/benchmark/run-tests.sh .hyper-relay/merge.conf docs/benchmarks/README.md CLAUDE.md
git commit -m "feat: plan-usage.sh measures one plan from the transcripts of the agents that wrote it" -m "It finds every subagent whose transcript wrote the plan (a Write, Edit or MultiEdit of its path in the main checkout or a .worktrees/ copy) and prints one Markdown row: their calls, tokens, final context, tool uses, active time and cost, counted and priced as run-usage.sh counts, then the plan's lines, its spec's lines and its code-block lines as test code, other code and text. Its suite runs on fixture transcripts and fixture plans in a temporary git repo; relay-merge checks its syntax; the G.2 runbook says how to measure a plan and keeps SAT's rows out of both repos." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-plan-fixtures.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Expected: `git ls-files -s scripts/benchmark/plan-usage.sh | cut -c 1-6` prints `100755`.

### Task 2: `writing-plans` gives a fixture as its signature and a sample (spec §4, §5; PF4, PF8; P11, P12)

**Files:**
- Modify: `skills/writing-plans/SKILL.md:156` (the test step), `:158` (the text step), `:170` (check 2), `:176`
  (check 5)
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md:23` (the Step contents row)

- [x] **Step 1: `SKILL.md`, "What a Step Contains" and "Self-Review".** Replace each X with its Y.

X1:

```text
- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them.
```

Y1:

```text
- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them, and the setup its assertions depend on: which fixtures it calls, with which values.
- **A fixture:** a helper that writes test data is given as its signature (its name and arguments) and one sample of what it writes, as data, not as the code that writes it: for a record format, one record with every field the tested code reads, nested as the real format nests it, showing where each argument goes. The executor writes the helper. The test harness (pass and fail counters, assert helpers) is named by the existing suite whose harness to follow, not written out. A fixture is written in full only when its exact bytes are what the test checks: a cut-off line, an escape, a malformed record.
```

X2:

```text
"Create X with exactly this content" and "Replace X with Y" are the forms for these.
```

Y2:

```text
"Create X with exactly this content" and "Replace X with Y" are the forms for these. A test file is never a text step: "Create X with exactly this content" is for files whose words are the product.
```

X3:

```text
**2. Step scan:** Every step lets the executor write exactly one reasonable thing, and carries no more than that. A line that decides nothing is a gap; a body the signature and the tests already determine is a transcript. Fix both. Text steps keep their text in full.
```

Y3:

```text
**2. Step scan:** Every step lets the executor write exactly one reasonable thing, and carries no more than that. A line that decides nothing is a gap; a body the signature and the tests already determine is a transcript. Fix both. A fixture helper's body that its signature and sample already determine is a transcript; replace it. Text steps keep their text in full.
```

X4:

```text
**5. Proportion:** Compare the plan's length with the spec's. When code blocks are most of the plan, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous. Text steps do not count against the plan here.
```

Y4 (P11):

```text
**5. Proportion:** Compare the plan's length with the spec's. When code blocks are most of the plan, replace bodies with signatures, test names and assertions, and fixture helpers with their signature and a sample, and check that each step is still unambiguous. Text steps do not count against the plan here (a test file is never one).
```

- [x] **Step 2: The reviewer's "Step contents" row (P12).** In `skills/writing-plans/plan-document-reviewer-prompt.md`
  (the line sits inside the prompt's block, indented by four spaces: keep them), replace:

```text
| Step contents | A step that decides nothing ("TBD", "TODO", "implement later", "fill in details", "handle edge cases", "Similar to Task N", a name no task defines); a code body that the step's signature and tests already determine; a text step (a skill, a doc, a message) that does not give its text in full. |
```

with:

```text
| Step contents | A step that decides nothing ("TBD", "TODO", "implement later", "fill in details", "handle edge cases", "Similar to Task N", a name no task defines); a code body that the step's signature and tests already determine; a fixture helper written out instead of its signature and one sample of what it writes (unless its exact bytes are what the test checks); a test file given as a text step ("Create X with exactly this content"); a text step (a skill, a doc, a message) that does not give its text in full. |
```

- [x] **Step 3: Check it**

| Run | Expected |
|---|---|
| `git diff --numstat -- skills/writing-plans` | two lines: `5	4	skills/writing-plans/SKILL.md` and `1	1	skills/writing-plans/plan-document-reviewer-prompt.md` |
| `grep -c -F '**A fixture:**' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'A test file is never a text step' skills/writing-plans/SKILL.md` | `1` |
| `grep -c -F 'fixture helper' skills/writing-plans/SKILL.md` | `2` (checks 2 and 5) |
| `grep -c -F 'a test file given as a text step' skills/writing-plans/plan-document-reviewer-prompt.md` | `1` |
| `grep -n -E '/home/\|~/\|/Users/\|/tmp/' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md` | nothing |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [x] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: writing-plans gives a test fixture as its signature and one sample" -m "A test step now carries the setup its assertions depend on. A helper that writes test data is its signature and one sample of what it writes, as data; the harness is named by the suite to follow; a fixture is written in full only when its exact bytes are what the test checks. A test file is never a text step, and self-review checks 2 and 5 catch a helper written out. The plan reviewer flags both." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-plan-fixtures.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [x] **Step 5: The full gates, once**

| Run | Expected |
|---|---|
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `110 passed, 0 failed` |
| `dash -n scripts/benchmark/plan-usage.sh`, `dash -n scripts/benchmark/run-usage.sh`, `dash -n scripts/benchmark/superpowers-env.sh` | silent, exit 0 each |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/merge.conf`, `CLAUDE.md`, `docs/benchmarks/README.md`, `scripts/benchmark/plan-usage.jq`, `scripts/benchmark/plan-usage.sh`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `tests/benchmark/run-tests.sh` |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Then report, copy Task 3's checklist (Steps 1–18, each with its marker and its PASS) into your report, and stop: Task
3 is not yours.

### Task 3: Acceptance (spec §7, §8; P11–P16). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-plan-fixtures`) its dispatch names, from the checkout's top (Steps 1–5). Steps 2–3 read the owner's
  transcripts under `~/.claude/projects`, read-only. Run them before 2026-12-19, when Step 2's transcripts start to
  expire.
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the standing leg (`reviewing.md`
  §3, the installed relay's). Steps 6–9 are S1–S4: each is dispatched twice, on Sonnet, in the background, with the
  leg's standing preamble and then the step's situation, verbatim, each line `<TOY FACTS>`, `<TOY SPEC>` or
  `<CUT-SHORT>` replaced by the block of that name below, verbatim.
- **`owner`**: the owner, at the click-through (Steps 10–11).
- **`after merge`**: the orchestrator with the owner, once the branch is merged into `main` and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 12–18). The orchestrator runs the commands; the owner runs the
  plugin update and the reload.

In a command inside a table cell, `\|` is a plain `|`.

**This plan's run follows the installed relay** (0.2.2's `writing-plans` and `orchestrating`), not the text it writes:
the new rule reaches a planner only after the release and the owner's update (Steps 15–16).

**`<TOY FACTS>`:**

```text
The repo is /work/toy, a small POSIX shell project with no app. Its CLAUDE.md says: scripts are POSIX sh run by dash
(`dash -n` must be silent); each suite prints "<n> passed, <m> failed" and must end "0 failed". Its one suite today,
`tests/wt/run-tests.sh`, opens with the harness every suite here follows: `set -u`, a temporary folder removed on
exit, `PASSED` and `FAILED` counters, `ok` and `bad`, and `assert_eq <description> <expected> <actual>` and
`assert_contains <description> <needle> <haystack>`; it ends by printing "<n> passed, <m> failed" and exiting
non-zero when anything failed.
```

**`<TOY SPEC>`:**

```text
The approved spec, docs/superpowers/specs/2026-11-19-toy-session-cost-design.md, says in full:

  # toy: the cost of one session (design)
  ## Goal
  The owner sees what one Claude Code session cost, from its transcript.
  ## The tool
  `scripts/session-cost.sh <transcript>` is POSIX shell run by dash, with jq 1.6 or later. A transcript is a JSON
  Lines file, one record per line, as Claude Code writes it. An API call is an assistant record (`"type":"assistant"`)
  whose `message` has an `id`, a `model` and a `usage`; Claude Code may write one call as several records with the
  same `message.id`, and the tool counts each `message.id` once. It prices each call's `usage.input_tokens`,
  `usage.output_tokens` and `usage.cache_read_input_tokens` at its model's row in `scripts/prices.tsv`
  (tab-separated: the model, then its input, output and cache-read prices in US dollars per million tokens;
  `SESSION_COST_PRICES` names another file), prints `cost: $<dollars, two decimals>` and exits 0. For a call whose
  model has no row, it prints `session-cost: no price for <model>` on stderr and exits 1.
  ## Tests
  `tests/session-cost/run-tests.sh`, on fixture transcripts it writes in its temporary folder, priced by its own
  prices file of one row: `claude-opus-5-5`, 4, 20, 0.20. These results are fixed:
  - one call of 1,000,000 input and 100,000 output tokens: `cost: $6.00`;
  - the same call written as two records with the same `message.id`: `cost: $6.00`;
  - that call and a second of 50,000 output tokens and 2,000,000 cache reads: `cost: $7.40`;
  - a call on `claude-test-9`: `session-cost: no price for claude-test-9`, exit 1.
```

**`<CUT-SHORT>`:**

```text
The spec's Tests section has a fifth case: "a transcript whose last line was cut short (Claude Code was writing it
when the session died), after one whole call of 1,000,000 input and 100,000 output tokens: the cut line is skipped,
`cost: $6.00`."
```

- [x] **Step 1 (`reviewer`): The suites and the manifest (spec §8 step 1).**

| Run | PASS |
|---|---|
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `110 passed, 0 failed` |
| `dash -n scripts/benchmark/plan-usage.sh` | silent, exit 0 |
| `git ls-files -s scripts/benchmark/plan-usage.sh \| cut -c 1-6` | `100755` |
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout, `PRIVACY_URL_MISSING`; no other warning |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `git show HEAD:.claude-plugin/plugin.json \| grep -F '"version"'` | `"version": "0.2.2",` (the release is after the merge) |

- [x] **Step 2 (`reviewer`): Real data (spec §8 step 2).** From the checkout's top, one command per run:

| Run | PASS |
|---|---|
| `scripts/benchmark/plan-usage.sh --no-header --config ~/.claude docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md; echo "exit $?"` | one row, then `exit 0`. Its Agents cell is `relay-planner`; its API calls, Output, Cache write, Cache read and Uncached in cells are `40`, `156,741`, `295,461`, `6,319,438` and `80` |
| `scripts/benchmark/plan-usage.sh --no-header --config ~/.claude docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md; echo "exit $?"` | one row, then `exit 0`. Its Agents cell is `relay-planner` (its planner and the same planner resumed, 106 + 15 calls); its API calls, Output, Cache write, Cache read and Uncached in cells are `121`, `376,191`, `3,248,467`, `36,474,785` and `244` |

  The other cells are not compared (the token log took durations from task notifications). Quote both rows in the
  verdict. A cell that differs is a FAIL, with both rows: the orchestrator settles with the owner whether the tool or
  the hand sum is wrong before a fix round.

- [x] **Step 3 (`reviewer`): No agent (spec §8 step 3).**

| Run | PASS |
|---|---|
| `scripts/benchmark/plan-usage.sh --config ~/.claude docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md; echo "exit $?"` | exactly `plan-usage: no agent wrote docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md (transcripts under /home/noob_master/.claude/projects)`, then `exit 1` |

- [x] **Step 4 (`reviewer`): Only the planned files (spec §1, §9).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the eight files of Task 2 Step 5 |
| `git diff --stat main...HEAD -- scripts/benchmark/run-usage.sh scripts/benchmark/run-usage.jq scripts/benchmark/prices.tsv scripts/benchmark/superpowers-env.sh` | nothing |
| `git diff main...HEAD -- tests/benchmark/run-tests.sh \| grep -c '^-[^-]'` | `5`: only the header's five old lines are removed; every existing assertion stays |
| `git diff main...HEAD -- skills \| grep -c -E '^\+.*(/home/\|~/\|/tmp/\|/Users/)'` | `0` |

- [x] **Step 5 (`reviewer`): The skill text against spec §4 and §5 (P11, P12).** Read
  `git diff main...HEAD -- skills/writing-plans`. PASS: exactly Task 2's five replacements, word for word: the test
  step gains the setup its assertions depend on; the fixture bullet follows it with every element of §4 (signature and
  one sample, as data; for a record format, one record with every field the tested code reads, nested, showing where
  each argument goes; the executor writes the helper; the harness named by the suite to follow; in full only when its
  exact bytes are what the test checks, with the three examples); the text step's new sentence; check 2's fixture
  sentence; check 5's clause and P11's parenthesis; the reviewer row's two new cases with P12's exception. Review
  Focus, Interfaces, the text step's other words, the acceptance task and Skill tests are unchanged (§4's
  "Unchanged"). A sentence that contradicts the spec beyond the P-notes is a FAIL, with its line.

- [x] **Step 6 (`skill-test`): S1, a planner writes tests that need fixture transcripts (§7 S1).**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it).

<TOY FACTS>

<TOY SPEC>

Write the plan's Task 1, which builds `tests/session-cost/run-tests.sh` and `scripts/session-cost.sh`, exactly as it
would appear in the plan: its heading, its Files block, and every step in full, with whatever code blocks the steps
need.
```

GREEN must: give the four tests, each with its name, its setup (the fixture helper it calls and its values: 1000000
and 100000; the same `message.id` twice; 50000 and 2000000; `claude-test-9`) and its assertions with the spec's values
(`cost: $6.00`, `cost: $6.00`, `cost: $7.40`, the no-price line and exit 1); give each fixture helper as its
signature (for example `call <id> <model> <input> <output> <cache read>`) and one sample JSON record holding `type`,
`message.id`, `message.model` and `message.usage`'s `input_tokens`, `output_tokens` and `cache_read_input_tokens`,
nested as the transcript nests them; name the harness by reference to `tests/wt/run-tests.sh`'s; and give no "Create
`tests/session-cost/run-tests.sh` with exactly this content" and no helper's `printf` body.

RED is expected to: write the whole suite in full, the harness and the helpers' `printf` bodies included, often as
"Create `tests/session-cost/run-tests.sh` with exactly this content".

- [x] **Step 7 (`skill-test`): S2, the same spec plus a cut-short line (§7 S2). A guard on the cut line.**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it).

<TOY FACTS>

<TOY SPEC>

<CUT-SHORT>

Write the plan's Task 1, which builds `tests/session-cost/run-tests.sh` and `scripts/session-cost.sh`, exactly as it
would appear in the plan: its heading, its Files block, and every step in full, with whatever code blocks the steps
need.
```

GREEN must: give the cut line's exact bytes in full, verbatim (for example `{"type":"assistant","message":{"id":"m2",`),
written after a whole call made with the helper, with its test's name and `cost: $6.00`; and give the ordinary records
as S1's GREEN does, as the helper's signature and one sample, with no "Create … with exactly this content" for the
suite.

RED is expected to: write everything in full, the cut line included. The cut line in full is expected on both: a
GREEN that gives it only as a signature is a fix round.

- [x] **Step 8 (`skill-test`): S3, the self-review finds a test file given as a text step (§7 S3; P11, P13).**

Situation:

```text
You are a planner: you write ONE implementation plan from an approved spec, following the `writing-plans` skill (its
SKILL.md and the files beside it).

<TOY FACTS>

<TOY SPEC>

<CUT-SHORT>

You have written a draft of the plan and are running the `writing-plans` self-review on it. The draft's Task 1, in
full except for its suite's 120 lines, which are described in brackets:

  ### Task 1: `session-cost.sh` and its suite

  **Files:**
  - Create: `scripts/session-cost.sh`
  - Create: `tests/session-cost/run-tests.sh`

  - [ ] **Step 1: The suite.** Create `tests/session-cost/run-tests.sh` with exactly this content:

    [A sh block of 120 lines. Lines 1–25: the harness, as `tests/wt/run-tests.sh` has it. Lines 26–58: three
    fixture writers, each a `printf` of a transcript record: `call <id> <model> <input> <output> <cache read>` (an
    assistant record with `type`, `message.id`, `message.model` and `message.usage`'s three token fields),
    `prices_file` (the test prices row) and `cut_line` (prints `{"type":"assistant","message":{"id":"m2",`). Lines
    59–112: the five tests, each its fixture calls with the spec's values, a run of the tool, and `assert_eq` lines
    with `cost: $6.00`, `cost: $6.00`, `cost: $7.40`, the no-price line and exit 1, and the cut-short case's
    `cost: $6.00`. Lines 113–120: the closing count.]

  - [ ] **Step 2: Run it to make sure it fails.** Run: `sh tests/session-cost/run-tests.sh | tail -n 1`. Expected:
    `0 passed, 6 failed`.
  - [ ] **Step 3: Implement `session-cost.sh <transcript>` in `scripts/session-cost.sh`.** One jq program keeps the
    first record of each `message.id` and prices it from the prices file.
  - [ ] **Step 4: Run it to make sure it passes.** Expected: `6 passed, 0 failed`; `dash -n scripts/session-cost.sh`
    is silent.
  - [ ] **Step 5: Commit.** `git add scripts/session-cost.sh tests/session-cost/run-tests.sh`, then commit with the
    `Plan-Task:` trailer.

The rest of the draft is 60 lines (header, Execution notes, Review Focus, Spec coverage, an acceptance task), and the
spec is 30 lines.

Run the self-review on this draft. Say which checks find something, and what; then give Task 1 as it will stand in the
plan you commit, in full.
```

GREEN must: say that check 2 (a fixture helper's body its signature and sample determine) or check 5 (code blocks are
most of the plan; a test file is never a text step) finds Step 1; and give Task 1 rewritten: the five tests, each with
its name, setup values and assertions (the spec's costs, the no-price line and exit 1); `call` as its signature and one
sample record; the harness by reference to `tests/wt/run-tests.sh`'s; the cut line in full; and no "Create
`tests/session-cost/run-tests.sh` with exactly this content".

RED is expected to: keep Step 1 as it stands: "Create … with exactly this content" makes it a text step, which check 5
does not count.

- [x] **Step 9 (`skill-test`): S4, the plan reviewer meets a test file given as a text step (§7 S4; P12).**

Situation:

````text
You are a plan document reviewer at the relay's stop 3. The orchestrator dispatched you with the prompt in the
`writing-plans` skill's `plan-document-reviewer-prompt.md` (read it in the skills folder: the prompt inside it is your
instructions), with [PLAN_FILE_PATH] docs/superpowers/plans/2026-11-19-toy-session-cost.md and [SPEC_FILE_PATH]
docs/superpowers/specs/2026-11-19-toy-session-cost-design.md. You cannot open the repo's files: both are given below in
full; take any length the prompt asks for from them.

<TOY FACTS>

<TOY SPEC>

The plan, docs/superpowers/plans/2026-11-19-toy-session-cost.md, says in full:

  # toy: the cost of one session, Implementation Plan

  **Spec:** `docs/superpowers/specs/2026-11-19-toy-session-cost-design.md`

  > **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans. Steps use checkbox (`- [ ]`) syntax.

  **Goal:** `scripts/session-cost.sh` prints one session's cost from its transcript.

  **Architecture:** One POSIX shell script with one jq program, and a suite on fixture transcripts.

  **Tech Stack:** POSIX sh (dash), jq 1.6 or later.

  ---

  ## Execution notes

  - POSIX shell run by dash, with jq 1.6 or later; `dash -n scripts/session-cost.sh` must be silent.
  - The full gates: `sh tests/session-cost/run-tests.sh` (`0 failed`) and `dash -n scripts/session-cost.sh`.

  ## Review Focus

  1. An empty transcript (no record at all): `cost: $0.00`, exit 0. Task 1 Step 1 tests it.

  ## Spec coverage

  | Spec section | Tasks |
  |---|---|
  | Goal | 1 |
  | The tool | 1 |
  | Tests | 1, 2 |

  ### Task 1: `session-cost.sh` and its suite

  **Files:**
  - Create: `scripts/session-cost.sh`
  - Create: `tests/session-cost/run-tests.sh`

  - [ ] **Step 1: The suite.** Create `tests/session-cost/run-tests.sh` with exactly this content:

  ```sh
  #!/bin/sh
  # Tests for scripts/session-cost.sh, on fixture transcripts.
  set -u
  HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
  SC=$HERE/../../scripts/session-cost.sh
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT INT TERM
  PASSED=0
  FAILED=0
  ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
  bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }
  assert_eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2], got [$3]"; fi; }
  printf 'claude-opus-5-5\t4\t20\t0.20\n' > "$TMP/prices.tsv"
  # call <id> <model> <input> <output> <cache read>: one assistant record of a call.
  call() {
      printf '{"type":"assistant","message":{"id":"%s","model":"%s","usage":{"input_tokens":%s,"output_tokens":%s,"cache_read_input_tokens":%s}}}\n' \
          "$1" "$2" "$3" "$4" "$5"
  }
  # sc <transcript>: runs the tool with the test prices; sets OUT and RC.
  sc() { OUT=$(SESSION_COST_PRICES="$TMP/prices.tsv" dash "$SC" "$1" 2>&1); RC=$?; }

  call m1 claude-opus-5-5 1000000 100000 0 > "$TMP/one.jsonl"
  sc "$TMP/one.jsonl"
  assert_eq "one call" 'cost: $6.00' "$OUT"
  { call m1 claude-opus-5-5 1000000 100000 0; call m1 claude-opus-5-5 1000000 100000 0; } > "$TMP/twice.jsonl"
  sc "$TMP/twice.jsonl"
  assert_eq "one call written twice counts once" 'cost: $6.00' "$OUT"
  { call m1 claude-opus-5-5 1000000 100000 0; call m2 claude-opus-5-5 0 50000 2000000; } > "$TMP/two.jsonl"
  sc "$TMP/two.jsonl"
  assert_eq "two calls" 'cost: $7.40' "$OUT"
  call m1 claude-test-9 1 1 0 > "$TMP/unpriced.jsonl"
  sc "$TMP/unpriced.jsonl"
  assert_eq "a model with no price: exit 1" 1 "$RC"
  assert_eq "a model with no price: says so" 'session-cost: no price for claude-test-9' "$OUT"
  : > "$TMP/empty.jsonl"
  sc "$TMP/empty.jsonl"
  assert_eq "an empty transcript" 'cost: $0.00' "$OUT"

  printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
  [ "$FAILED" -eq 0 ]
  ```

  - [ ] **Step 2: Run it to make sure it fails.** Run: `sh tests/session-cost/run-tests.sh | tail -n 1`. Expected:
    `0 passed, 6 failed` (there is no script yet).

  - [ ] **Step 3: Implement `session-cost.sh <transcript>` in `scripts/session-cost.sh`.** One jq program keeps the
    first record of each `message.id` and prices it from `SESSION_COST_PRICES`, else `prices.tsv` beside the script.

  - [ ] **Step 4: Run it to make sure it passes.** Run: `sh tests/session-cost/run-tests.sh | tail -n 1`. Expected:
    `6 passed, 0 failed`. Then `dash -n scripts/session-cost.sh`: silent.

  - [ ] **Step 5: Commit.**

  ```bash
  git add scripts/session-cost.sh tests/session-cost/run-tests.sh
  git commit -m "feat: session-cost.sh prints a session's cost" -m "Plan-Task: docs/superpowers/plans/2026-11-19-toy-session-cost.md#1"
  ```

  ### Task 2: Acceptance

  - [ ] **Step 1 (`reviewer`): The suite.** Run: `sh tests/session-cost/run-tests.sh | tail -n 1`. PASS:
    `6 passed, 0 failed`.
  - [ ] **Step 2 (`reviewer`): The syntax.** Run: `dash -n scripts/session-cost.sh`. PASS: silent, exit 0.

Give your review, in the prompt's output format.
````

GREEN must: give **Status:** Blocking issues found, with Task 1 Step 1 among the blocking issues under Step contents:
the suite given as a text step ("Create … with exactly this content"), and its `call` helper written out instead of
its signature and one sample (the harness written out instead of named may be flagged too).

RED is expected to: give **Status:** Ready, with at most an advisory note on the plan's proportion.

- [x] **Step 10 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-plan-fixtures -- skills/writing-plans`, with stop 4's
  skill-test results, Step 2's two rows and the P-notes, P11 and P12 above all. PASS: the owner agrees with them as
  written. A change goes to the executor as a finding.

- [x] **Step 11 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-plan-fixtures` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging. The merge runs as the installed relay says:
`relay-merge` from the main checkout on `main`.

- [x] **Step 12 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/benchmark/run-tests.sh` (last line) | `110 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `28 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |

- [x] **Step 13 (`after merge`): The baseline (spec §8, PF5, PF7).** One command per line, in order:

```bash
E=$(mktemp -d)
cd /home/noob_master/hyper-relay && h= && for p in docs/superpowers/plans/*.md; do scripts/benchmark/plan-usage.sh ${h:+--no-header} "$p" && h=1; done > "$E/hyper-relay.md"
mkdir -p /home/noob_master/sat-benchmark
cd /home/noob_master/sat.pentraze.com && h= && for p in docs/superpowers/plans/*.md; do /home/noob_master/hyper-relay/scripts/benchmark/plan-usage.sh ${h:+--no-header} "$p" && h=1; done > /home/noob_master/sat-benchmark/plan-usage-baseline.md
```

  The loops print a `plan-usage:` line on stderr for each plan they cannot measure (no agent wrote it, or its
  transcript expired): expected, and not in the tables.

| Run | PASS |
|---|---|
| `head -n 2 "$E/hyper-relay.md"` and `head -n 2 /home/noob_master/sat-benchmark/plan-usage-baseline.md` | the header line and the separator, in each |
| `tail -n +3 "$E/hyper-relay.md" \| wc -l` and the same on SAT's file | at least `1` each |
| `git -C /home/noob_master/hyper-relay status --porcelain` and `git -C /home/noob_master/sat.pentraze.com status --porcelain` | the same as before the loops: nothing written in either repo |

  Then the orchestrator copies the rows of `$E/hyper-relay.md` into its token log, outside the repo. SAT's rows stay
  in `~/sat-benchmark/plan-usage-baseline.md`, never in a repo, a commit, the token log or this plan (PF5).

- [x] **Step 14 (`after merge`): The note on card `93e7a9dc` (spec §8; P15).** The baseline's test-code lines per plan,
  each repo apart. One command per line:

```bash
stats() { grep '^| ' "$1" | grep -v '^| Plan |' | grep -v -F '2026-11-19-hyper-relay-plan-fixtures.md' | cut -d '|' -f 16 | tr -d ' ,' | sort -n | awk '{ v[NR] = $1; s += $1 } END { if (NR == 0) { print "no plans"; exit } m = (NR % 2) ? v[(NR + 1) / 2] : (v[NR / 2] + v[NR / 2 + 1]) / 2; printf "%d plans, test-code lines: total %d, median %s, largest %d\n", NR, s, m, v[NR] }'; }
stats "$E/hyper-relay.md"
stats /home/noob_master/sat-benchmark/plan-usage-baseline.md
```

  (Field 16 of a row split on `|` is its Test code cell; the filter leaves out this plan, which no SAT file holds.)
  Then add a note on card `93e7a9dc-79ce-49e9-afe4-46f3434a801b` through the Quartz MCP (when it is not loaded, give
  the owner the text), with each `<…>` from the two lines above:

```text
Plan-shape baseline (plan-usage.sh, <date>), before the fixture rule: test-code lines per plan, from every plan whose
planner transcript still existed. hyper-relay: <n> plans, total <t>, median <m>, largest <l> (this card's own plan
left out). SAT: <n> plans, total <t>, median <m>, largest <l>. The proof (PF1) is the next SAT plan's Test code
against SAT's figures, recorded on this card when that plan lands.
```

  PASS: the note is on the card, and it names no SAT plan.

- [x] **Step 15 (`after merge`): The release, 0.2.3 (spec §8; `.hyper-relay/agents.md`, Releases, (1) and (2)).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (this spec and plan among them),
  which is expected. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | `All declared files are in sync at 0.2.2` (if `main` is at another version, the release is that version's patch number plus one, and the commands below change with it) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh 0.2.3` | exit 0; `package.json` and `.claude-plugin/plugin.json` from `0.2.2` to `0.2.3` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | `All declared files are in sync at 0.2.3` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v0.2.3" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v0.2.3
git -C /home/noob_master/hyper-relay push origin main v0.2.3
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v0.2.3` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v0.2.3` | one line |

- [x] **Step 16 (`after merge`): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3 && echo cached` | `cached` |
| `grep -c -F '**A fixture:**' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3/skills/writing-plans/SKILL.md` | `1` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again, and the record says so. If a check still fails, stop and tell the owner; delete or uninstall
nothing.

- [x] **Step 17 (`after merge`): The role agents, regenerated here and in SAT (spec §8; P16).** With the installed
  0.2.3 generator, so the agents' version marker matches the installed plugin:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3/bin/hyper-relay-agents --check` | nothing, exit 0 |

Then SAT, unless a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: then ask the
owner first (P16).

| Run | PASS |
|---|---|
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.3/bin/hyper-relay-agents --check` | nothing, exit 0 |

A `refused` line (a hand-edited agent) stops the step: tell the owner. The new agents load in a new session. SAT's
`.hyper-relay/agents.md` is left alone.

- [x] **Step 18 (`after merge`, last): Record.** Append to this plan, in the main checkout (on `main`), with no SAT
  figure or SAT plan name in it (PF5):

```markdown
## Last-task record (Task 3)

- **Before the merge:** acceptance reviewer <verdict line>; real data (Step 2) <both rows matched / which cell
  differed, and what was settled>; fix rounds <n, what each changed>; code review: Critical <fixed / dropped, why>,
  proposed cards <kept / dropped>; skill tests GREEN <n>/4, RED failed in <which>, non-discriminating <which>; token
  counts: executor <n>, acceptance reviewer <n>, code reviewer <n>, skill tests <n> over 8 runs.
- **Owner steps:** Step 10 <agreed / what changed, P11 and P12 among it>; Step 11 <merge-tree exit>. Merged in <hash>.
- **After merge:** suites on `main` <counts>; baseline <n> rows here (in the token log) and SAT's in
  `~/sat-benchmark/`; card note <posted>, this repo's line <n plans, total, median, largest>; released v0.2.3 in
  <hash>, tagged, pushed; the owner's update <0.2.3 in the cache>; agents regenerated here <files> and in SAT
  <files / asked first>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 3 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-19-hyper-relay-plan-fixtures.md
git -C /home/noob_master/hyper-relay commit -m "docs: plan fixtures last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-plan-fixtures.md#3
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-19-hyper-relay-plan-fixtures.md
```

Push it with the next push of `main` (the owner's call).

## Last-task record (Task 3)

- **Before the merge:** acceptance reviewer 4/5 PASS, then 5/5. Step 3's expected refusal rested on a wrong spec
  premise: `2026-11-17-hyper-relay-a-forks-home.md` has a real `relay-planner` transcript (so does every plan in this
  repo), so Step 3 ran against `docs/plans/2025-11-22-opencode-support-design.md` instead (exit 1, the no-agent line),
  a deviation the owner accepted. Real data (Step 2): both rows matched in every compared cell. Fix rounds: 0. Code
  review: Ready, 0 Critical, 0 Important, 4 Minor, made into proposed cards and kept (plus a third card from the
  baseline: `claude-opus-4-8` has no row in `prices.tsv`). Skill tests GREEN 4/4; RED failed in S2 and S4;
  non-discriminating S1 and S3 (today's text already gave the helpers as signatures, and its check 2 already caught
  the pasted test file); in S4 both runs also flagged the toy plan's missing prices file, a flaw in the scenario. Token
  counts: executor 110,528, acceptance reviewer 71,566, code reviewer 80,745, skill tests 485,803 over 8 runs.
- **Owner steps:** Step 10 agreed, P11 and P12 kept as written; Step 11 `merge-tree` exit 0. Merged in `a09f5cd`.
- **After merge:** suites on `main` 110/0 and 28/0, validate passes; baseline 14 rows here (in the token log) and
  SAT's in `~/sat-benchmark/`; card note posted, this repo's line 13 plans, total 1773, median 16, largest 519 (some
  SAT plans were refused for that missing price row, as the card note says); released v0.2.3 in `865d62f`, tagged,
  pushed; the owner's update put 0.2.3 in the cache; agents regenerated here (all four files unchanged), and in SAT
  `--check` was already silent, so nothing was rewritten there while a SAT plan is in flight in a worktree.
