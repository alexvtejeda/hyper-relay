# hyper-relay: test fixtures as signatures in plans, and `plan-usage.sh` to measure plans (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19
**Card:** writing-plans: test fixtures as signatures, not bodies (`93e7a9dc-79ce-49e9-afe4-46f3434a801b`)
**Initiative:** v0.1.0
**Scope:** this repo: `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, a new
`scripts/benchmark/plan-usage.sh` (with its jq), `tests/benchmark/run-tests.sh`, `.hyper-relay/merge.conf`,
`docs/benchmarks/README.md`, `CLAUDE.md`. One plan. Released as the next patch (0.2.3).

## Goal

Lean plans (0.2.1) dropped script bodies, but test code is now the largest block a plan still writes out. The G.2
re-plan probe came out at 1,747 lines: about 650 of them test code and 530 doc text. Most of the test code is one step,
"create `tests/benchmark/run-tests.sh` with exactly this content" (318 lines): about 25 lines of pass/fail harness that
the repo's other suites already have, about 95 lines of fixture writers (`printf`s of transcript JSON records), and about
130 lines of tests (setup values and assertions). Today's rule says only "a test step: the test's name and its
assertions, as code", so the planner treated the whole test file as the test step. Upstream's 7.0.2 has the same
sentence and no fixture rule.

This spec makes a fixture a signature and a sample record, keeps what decides something in full, and adds a tool that
measures any plan after the fact (its planner's tokens, cost and time, and the plan's shape), so the change is judged on
real plans: a baseline now, then the next SAT plan against it.

## Decisions (owner, 2026-11-19)

| # | Question | Decision |
|---|---|---|
| PF1 | How is the change proven? | **Skill tests, then the next SAT plan, measured against a baseline** (not another G.2 re-plan probe, and not skill tests alone). SAT is where planner cost is: about half of all subagent tokens in the week to 2026-11-19. |
| PF2 | How is a plan measured? | **After the fact, one plan at a time,** from Claude Code's transcripts, at no cost. Not a head-to-head benchmark that runs planners. |
| PF3 | A new script, or a mode of `run-usage.sh`? | **A new `scripts/benchmark/plan-usage.sh`** with a small jq of its own, reusing `prices.tsv` and `run-usage.sh`'s counting rules. `run-usage.sh`'s jq is built around a run log's sessions and phases, which one plan does not have. |
| PF4 | What does a fixture look like in a plan? | **Its signature and one sample of what it writes, as data** (§4). The harness is named by reference. Test names, setup values and assertions stay in full, and so does a fixture whose exact bytes are what the test checks. |
| PF5 | Where do SAT's numbers go? | **Never into this repo,** which is public: SAT's plan names carry its internals. The script only prints; SAT rows go to `~/sat-benchmark/`, outside both repos (the G.2 runbook's rule). |
| PF6 | One plan or two? | **One plan:** the script first, then the skill text. |
| PF7 | The baseline? | **After the merge, the script runs on every plan whose planner transcript still exists** (Claude Code keeps transcripts 30 days). |
| PF8 | Calls made by the orchestrator, not the owner (the owner did not object) | Duration is active time per prompt (§2.4); test code is spotted by the step's title or the first file it names (§2.6); the plan reviewer's prompt changes with the skill (§5). |

## 1. What changes where

| File | Change |
|---|---|
| `scripts/benchmark/plan-usage.sh` (+ its jq, e.g. `plan-usage.jq`) | New (§2) |
| `tests/benchmark/run-tests.sh` | plan-usage tests on fixture transcripts (§3) |
| `skills/writing-plans/SKILL.md` | The fixture rule and two self-review checks (§4) |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Its "Step contents" row (§5) |
| `.hyper-relay/merge.conf` | `scripts/benchmark/  build  dash -n scripts/benchmark/plan-usage.sh` beside the two existing lines |
| `docs/benchmarks/README.md` | A short section, "Measuring one plan" (§6) |
| `CLAUDE.md` | The `scripts/benchmark/` line names `plan-usage.sh`; the `tests/benchmark/` sentence says it tests it too |

`run-usage.sh`, `run-usage.jq`, `prices.tsv` and every other skill stay as they are.

## 2. `scripts/benchmark/plan-usage.sh`

POSIX shell run by dash, with jq 1.6 or later, as `run-usage.sh`. It reads transcripts and the plan, and writes
nothing but a temporary folder.

### 2.1 Interface

`plan-usage.sh [--config <folder>] [--no-header] <plan file>`

- `--config` names Claude Code's config folder; the default is `$CLAUDE_CONFIG_DIR`, or `~/.claude` when that is unset.
  A leading `~/` expands to the home folder.
- It prints a Markdown table: its header line, its separator and one row. `--no-header` prints the row alone, so a shell
  loop over `docs/superpowers/plans/*.md` builds one table.
- Exit 0 with the row; exit 1 with one `plan-usage: …` line on stderr when: there is no plan file; the plan is not in a
  git repo; the config folder has no `projects/` folder; no agent wrote the plan; a call's model has no row in the
  prices file. Wrong arguments print a `usage:` line and exit 1. `RUN_USAGE_PRICES` names another prices file, as for
  `run-usage.sh`.

### 2.2 The row

Columns, in order: Plan · Agents · Model · API calls · Output · Cache write · Cache read · Uncached in · Final context ·
Tool uses · Duration · Cost · Plan lines · Spec lines · Test code · Other code · Text.

Plan is the plan's file name. Numbers are written with thousands separators (`156,741`), as the orchestrator's token log
writes them; Cost in US dollars with two decimals (`$12.34`); Duration as `22m32s` (`1h05m09s` past an hour).

### 2.3 Finding the agents

- The plan's checkout is `git -C <plan's folder> rev-parse --show-toplevel`; its path in the repo is its path below
  that. The repo's main checkout is the parent of `git rev-parse --path-format=absolute --git-common-dir`.
- An agent wrote the plan when its transcript (`<config>/projects/*/*/subagents/agent-*.jsonl`) holds a `Write`, `Edit`
  or `MultiEdit` tool call whose `input.file_path` is the plan's path in the main checkout, or the same path inside one
  of the main checkout's `.worktrees/*`. A plan written during a branch run, or in a worktree, is found the same way.
  A tool call that only reads the plan does not count.
- Every such agent is counted, summed: a resumed planner is one transcript; a fresh planner sent to revise the plan is a
  second one. The Agents column names each agent's type from its `agent-<id>.meta.json` (`agentType`), with a count
  when there is more than one: `relay-planner`, `relay-planner ×2`, `sat-planner, general-purpose`.
- No such agent: exit 1, `plan-usage: no agent wrote <plan path> (transcripts under <config>/projects)`.

### 2.4 Counting

The same rules as `run-usage.sh` (`run-usage.jq`), over the agents' transcripts:

- **Calls:** assistant records with `message.usage`, counted once per `message.id` (Claude Code writes one record per
  content block, each repeating the call's usage).
- **Output, Cache read, Uncached in:** the sums of `output_tokens`, `cache_read_input_tokens` and `input_tokens`.
- **Cache write:** the sum of `cache_creation_input_tokens`; for pricing, split into 5-minute and 1-hour writes from
  `usage.cache_creation`, all 5-minute when a record has no `cache_creation` object.
- **Model:** the calls' `message.model` values, `<synthetic>` left out, comma-separated when there are several.
- **Final context:** the last call's input, cache write and cache read added together (the last call of the agent whose
  last call is the latest). It is the number a task notification reports as `subagent_tokens`.
- **Tool uses:** the `tool_use` blocks in the agents' assistant records.
- **Duration:** active time. An agent's transcript is cut at each prompt it was given: a user record that carries no
  `tool_result` (its dispatch, and each resume). A piece runs from its prompt to the last record before the next prompt,
  or to the transcript's end. Duration is the sum of the pieces, over all the agents. A planner that waited at stop 3
  is not charged the wait.
- **Cost:** each call priced from `prices.tsv` as `run-usage.sh` prices it (its model's row with the largest `over` its
  prompt exceeds; input, 5-minute writes, 1-hour writes, reads and output each at their column), summed.

### 2.5 The plan's shape

- **Plan lines:** the plan file's lines.
- **Spec lines:** the lines of the file the plan's `**Spec:**` header line names (its first backticked path, from the
  plan's checkout); `-` when the line or the file is missing.
- **Code-block lines:** the lines inside fenced blocks, fences excluded. A block opens at a line whose first non-space
  characters are three or more backticks and closes at the next line with the same backticks alone; a ```` block that
  holds ``` blocks counts once, as the outer block.

### 2.6 The three classes

Each block, by its opening fence's info string and the step it sits in (the text from the nearest `- [ ] **Step` line
before it, up to the block):

- **Text:** the info string is `markdown`, `md`, `text` or `txt`, or empty.
- **Test code:** any other info string, in a step whose bold title is about writing a test (it contains "test", and
  does not begin with "Run" or "Verify"), or whose first backticked path is in a test folder (a path segment `tests`,
  `test`, `spec` or `__tests__`) or named like a test file (`test_*`, `*_test.*`, `*.test.*`).
- **Other code:** every other block: script bodies, commands, and blocks in no step.

## 3. Tests

`tests/benchmark/run-tests.sh` gains plan-usage tests in its own section, on fixture transcripts and fixture plans the
suite writes in a temporary config folder and a temporary git repo, with the suite's test prices. Each asserts exact
values:

- a planner that wrote the plan: its row's calls, tokens, final context, tool uses and cost; a repeated `message.id`
  counted once; `<synthetic>` left out of Model;
- a resumed planner: two prompts with an hour's gap between them; the gap is not in Duration;
- a second agent of the same type that edited the plan (both summed; Agents `<type> ×2`), an agent of another type that
  wrote it (Agents names both types), and one that only read it (not counted);
- a plan written inside `.worktrees/<name>/`;
- cache writes split 5-minute and 1-hour, and a record with no `cache_creation` object priced as 5-minute;
- the shape: a fixture plan whose blocks are one of each class (a `sh` block in "Write the failing test", a `sh` block
  in a step whose first path is `tests/x/run-tests.sh`, a `sh` block in "Run test to verify it fails", a `markdown`
  block, a ```` block holding a ``` block), with exact counts; Spec lines from its `**Spec:**` line, and `-` without
  one;
- `--no-header`; `--config`;
- refusals, each with its `plan-usage:` line and exit 1: no plan file, a plan outside a git repo, no `projects/`, no
  agent wrote the plan, a model with no price; and the `usage:` line for wrong arguments.

## 4. `skills/writing-plans/SKILL.md`

"What a Step Contains":

- **A test step** keeps its sentence and gains the setup its assertions depend on: which fixtures it calls, with which
  values.
- **A fixture** is a new bullet. A helper that writes test data is given as its signature (name and arguments) and one
  sample of what it writes, as data, not as the code that writes it: for a record format, one record with every field
  the tested code reads, nested as the real format nests it, showing where each argument goes. The executor writes the
  helper. The test harness (pass and fail counters, assert helpers) is named by the existing suite whose harness to
  follow, not written out. A fixture is written in full only when its exact bytes are what the test checks: a cut-off
  line, an escape, a malformed record.
- **A text step** gains one sentence: a test file is never a text step; "Create X with exactly this content" is for
  files whose words are the product.

"Self-Review":

- **Check 2, step scan:** a fixture helper's body that its signature and sample already determine is a transcript;
  replace it.
- **Check 5, proportion:** "replace bodies with signatures, test names and assertions" adds "and fixture helpers with
  their signature and a sample".

Unchanged: Review Focus (each line's assertions in the owning task's test step), Interfaces, text steps for skills and
docs (LP2), the acceptance task, skill tests.

The plan writes the new sentences in full.

## 5. `skills/writing-plans/plan-document-reviewer-prompt.md`

Its "Step contents" row also flags a fixture helper written out instead of its signature and sample, and a test file
given as a text step. Without it, stop 3's optional plan reviewer would ask for what the planner was told to leave out.

## 6. `docs/benchmarks/README.md`

A section, "Measuring one plan": what `plan-usage.sh` prints and from what; the command; a loop for a table
(`for p in docs/superpowers/plans/*.md; do plan-usage.sh --no-header "$p"; done`, after one header); that it measures
only plans written by an agent (upstream superpowers writes its plans in the main session: `run-usage.sh` measures that
run); that transcripts expire after 30 days; that SAT's rows stay in `~/sat-benchmark/`.

## 7. Pressure scenarios

Each runs on `main`'s skills (RED) and the branch's (GREEN), on Sonnet, as a `skill-test` step.

| # | Situation | The new text must | Today's text does |
|---|---|---|---|
| S1 | A planner, given a spec for a POSIX shell tool that reads JSONL transcripts; its tests need fixture transcripts, and the spec pins the costs the tool must report | Test steps carry each test's name, its setup values and its assertions, with the spec's costs in them; each fixture helper is its signature and one sample JSON record holding every field the tool reads; the harness is "follow `tests/wt/run-tests.sh`'s"; no "Create `tests/…` with exactly this content" | Writes the whole test file in full, the helpers' `printf` bodies included |
| S2 | The same spec, plus a test that a cut-off last line is skipped | That fixture's exact bytes, the cut-off line, in full; the ordinary records still a signature and a sample | Writes everything in full (a guard against over-applying the rule: the cut-off line is expected in full on both) |
| S3 | A planner's self-review finds a 120-line test file in its draft as "Create … with exactly this content" | Check 2 or 5 catches it, and the planner rewrites it as test steps and fixtures | Keeps it: the "exactly this content" form makes it a text step, which the proportion check exempts |
| S4 | A plan reviewer (stop 3's optional review) reads a plan that gives a test file as a text step | Flags it under "Step contents" | Approves it |

## 8. Acceptance, baseline and release

The reviewer's steps, on the branch:

1. `sh tests/benchmark/run-tests.sh`: `0 failed`. `dash -n scripts/benchmark/plan-usage.sh`: silent.
   `claude plugin validate .`: passes, with the three known warnings. `sh tests/orchestrating/run-tests.sh`: `0 failed`.
2. **Real data.** `plan-usage.sh` on two of this repo's plans matches what the orchestrator summed by hand with the same
   rules (calls, output, cache write, cache read, uncached in), Agents `relay-planner`:

   | Plan | Calls | Output | Cache write | Cache read | Uncached in |
   |---|---|---|---|---|---|
   | `docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md` | 40 | 156,741 | 295,461 | 6,319,438 | 80 |
   | `docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md` | 121 | 376,191 | 3,248,467 | 36,474,785 | 244 |

   The G.2 row is its planner and the same planner resumed for the revision (106 + 15 calls). Durations are not
   compared: the token log took them from task notifications. These transcripts expire on or after 2026-12-19.
3. **No agent.** `plan-usage.sh docs/superpowers/plans/2026-11-17-hyper-relay-a-forks-home.md` exits 1 with its
   `plan-usage: no agent wrote …` line (that planner's transcript predates the `subagents/` layout).
4. `git diff --name-only main...HEAD`: exactly §1's files.
5. Skill tests S1–S4 (§7), RED and GREEN: all GREEN; RED recorded.

After the merge:

- Release the next patch (0.2.3, unless `main` holds another version): `scripts/bump-version.sh`, a commit of just
  `package.json` and `.claude-plugin/plugin.json`, `chore: release v<x.y.z>`, the tag, push `main` and the tag. The owner
  runs `claude plugin update hyper-relay@hyper-relay` and `/reload-plugins`; the orchestrator regenerates the role
  agents here and in SAT.
- **Baseline.** The orchestrator runs `plan-usage.sh` on every plan under this repo's and SAT's
  `docs/superpowers/plans/` whose planner transcript still exists (exit 0). This repo's rows go into the orchestrator's
  token log, outside the repo. SAT's go to `~/sat-benchmark/plan-usage-baseline.md`, never into a repo.
- **A note on card `93e7a9dc`:** the baseline's test-code lines (its total, median and largest per plan, SAT and this
  repo apart), with no SAT plan names. The proof (PF1) is the next SAT plan's row against that note, recorded when that
  plan lands: it is not an acceptance step, so this plan does not wait on SAT.

## 9. Out of scope

`run-usage.sh` and the G.2 runbook's run-level measurement; measuring plans written in the main session; executors' or
reviewers' efficiency; text steps for skills and docs (LP2 stays: the 530 lines of doc text in the probe are by
design); comparing plans automatically against the baseline.
