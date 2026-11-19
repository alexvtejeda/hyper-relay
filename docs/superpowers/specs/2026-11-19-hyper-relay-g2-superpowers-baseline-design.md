# hyper-relay G.2: a superpowers baseline on SAT (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19
**Card:** Superpowers baseline on SAT: benchmark tooling and protocol (`276a2cbb-ac84-4463-b3ca-5ec87219e597`)
**Initiative:** v0.1.0 · **Piece:** G.2 · **Blocks:** G (the README card, `09078266-2def-4376-9c29-647ae7b69cdd`),
whose numbers come from this comparison
**Scope:** this repo: `scripts/benchmark/`, `tests/benchmark/`, `docs/benchmarks/`, `CLAUDE.md`. One plan. The runs
themselves happen on SAT (`~/sat.pentraze.com`) after it merges, by the runbook this plan writes.

## Goal

The README is to say how hyper-relay differs from superpowers, with measured token usage. Without a baseline, the
numbers show what each leg of the relay costs, not whether the relay is cheaper than upstream. The owner's decision
(card G's note, 2026-11-18): measure on SAT, not on a toy. One SAT feature is built with upstream superpowers' full
workflow, another comparable one with hyper-relay's relay, and the two are compared on token usage, time and bugs.
Nothing is built twice.

G.2 builds the tools to measure that fairly and fixes the protocol before either run starts.

## Decisions (owner, 2026-11-19)

| # | Question | Decision |
|---|---|---|
| G2.1 | Which pair? | **SAT Notifications C.1 and C.2.** C.1 (`1504e8f8-ddcf-474d-b7ef-978c4a069069`): notify `users:manage` holders when a registration waits for approval. C.2 (`df5a7bd8-da19-439a-af51-508ff3893984`): notify on an issue's new comment and status change. Both are small producers on the finished Notifications A+B foundation (registry, `Publish`, inbox), with no migration. C.3 (batched phishing activity) was ruled out: its batching is an open design problem several times C.2's size, which would swamp the workflow difference. |
| G2.2 | Which workflow builds which? | **C.1 with hyper-relay, C.2 with upstream superpowers.** C.2 is the easier of the two (its pattern, issue opened, sits next to it), so the bias favours superpowers and a hyper-relay win is conservative. |
| G2.3 | How is the superpowers run isolated? | **A separate config folder** (`CLAUDE_CONFIG_DIR=~/.claude-superpowers`), not a switch in place. The owner's normal setup keeps working meanwhile, and the run's transcripts land in their own folder. §2. |
| G2.4 | What counts as a bug? | **Two numbers, kept apart.** In-process catches (what the workflow's own reviewers found before merge) are reported as a count. Quality is scored by escaped defects on three yardsticks: the owner's click-through, a blind review, and a sealed pitfall list. No post-merge observation window. §4. |
| G2.5 | Order, and from which commit? | **C.1 first, to its merge; then C.2 from the new `main`.** No merge conflict for either. C.2 then has two examples to copy, which again favours superpowers. |
| G2.6 | How are tokens and time measured? | **A transcript reader of our own** (`run-usage.sh`), cross-checked against Claude Code's cost records. Not ccusage (no per-leg or phase split, no agent time, an outside dependency under a published number), not cost records alone (one total per session). §3. |
| G2.7 | Which card? | **A new card, G.2** (`276a2cbb-ac84-4463-b3ca-5ec87219e597`), so merging the tooling does not close the README card. G depends on G.2 and waits for the results. |

## 1. The protocol

**The two runs.**

- **C.1** goes through hyper-relay's relay as it stands on the day: `brainstorming`, then `orchestrating` with its
  planner, executor, acceptance reviewer and code reviewer.
- **C.2** goes through upstream superpowers as shipped: `brainstorming`, `writing-plans`,
  `subagent-driven-development` (its per-task spec and quality reviews), `requesting-code-review`,
  `finishing-a-development-branch`. Where superpowers offers a choice, the owner picks its full path:
  subagent-driven-development, not inline execution, and a worktree.

**Order.** C.1 runs to its merge first. C.2 then starts from the new `main`. Each run's start commit goes in its run
log.

**Start and end.** A run starts with the owner's first message in its first session. It ends at its merge commit on
SAT's `main`, made by `make merge` after the owner's click-through passes. Fixes after a failed click-through count
inside the run. The owner merges with `make merge` in both runs; for C.2 that means choosing "keep the branch" when
`finishing-a-development-branch` offers its options.

**The same bar to finish.** `make merge`'s gates pass (API build, vet and unit tests; web tsc, eslint and the full
suite), and the owner's click-through passes.

**The same conditions for both.**

- Opus 5.5 main session, default effort.
- Nothing else running on SAT while a run is going: the time measurement would blur, and SAT's web suite must never
  run twice at once.
- Each run starts in a fresh session. The session that brainstormed G.2 does not orchestrate C.1: it has discussed
  pitfalls of both features.
- The owner answers what the workflow asks, as they normally would, and volunteers no requirement they would
  otherwise leave out.

**No run is told it is being measured.** Nothing about the benchmark goes where a run's agents read: not SAT's
`CLAUDE.md`, not SAT's auto-memory, not C.1's card. C.2's card carries one note, that it is reserved for a build
outside the relay (added 2026-11-19), so nobody brainstorms it through the relay by mistake; the superpowers run does
not read the board.

**Before C.1 starts.** Refresh SAT's role agents (`hyper-relay-agents`; the session-start notice of 2026-11-19 said
`sat-executor` was out of date). Check the dev stack is healthy. Write and seal the pitfall list (§4). Build both config
folders (§2), so both runs start under the same day's environment.

**A run log per run,** from `docs/benchmarks/run-log-template.md`, kept in `~/sat-benchmark/` beside the pitfall list
during the runs, outside both repos, so no agent in either run reads it. At scoring the logs are copied to
`docs/benchmarks/runs/` and committed with the results. It records the workflow,
the card, the config folder, the session ids, the start, spec, plan and merge commits with their times, the role table
(§3), the pitfall list's sha256, the owner's click-through findings, and the in-process catches.

## 2. The superpowers config folder

**`scripts/benchmark/superpowers-env.sh`** (POSIX sh, run by dash) builds `~/.claude-superpowers`, and refuses when
that folder already exists. `--neutral` builds `~/.claude-neutral` the same way but installs neither workflow; the
blind review (§4) runs there. A different target folder can be given, for the tests.

**The same as the owner's setup, by link**, so nothing drifts during the runs: `~/.claude/skills`, `agents`,
`commands`, `rules`, `hooks` and `bin`. `wt` and `relay-merge` stay reachable through `~/.local/bin`: SAT's
`CLAUDE.md` tells agents to use `wt up`, so the superpowers run may too.

**Copied, then changed on purpose:**

- `settings.json`: `hyper-relay@hyper-relay` removed from `enabledPlugins`; `quartz hook flush` removed from `Stop`
  and `SubagentStop`. Every other hook stays (ccs, the codebase-memory gate, the migration guards).
- MCP servers: only the `mcpServers` block of `~/.claude.json` (codebase-memory-mcp, context7, playwright), into the
  folder's own `.claude.json`. Nothing else from that file, which holds the owner's login and history. The plan
  confirms that Claude Code reads `.claude.json` from inside `CLAUDE_CONFIG_DIR` before relying on it.
- `CLAUDE.md`: copied with the `## Workflow: the relay` section cut, its `### Quartz` subsection included (everything
  from that heading up to `## Code Quality`). The script fails when the result still contains `hyper-relay` or
  `Quartz`, or when either heading is missing (the file changed shape; cut nothing by guesswork).
- Other plugins: the same ones enabled (frontend-design, gopls-lsp, ui-ux-pro-max), playwright still off.
- Memory: none. The folder's `projects/` starts empty, so the SAT memory (which carries relay habits: executors on
  Sonnet, one plan at a time, the owner merges, the executor briefing lessons) never loads.

**Superpowers itself.** The script adds `obra/superpowers-marketplace` fresh in the new folder (the local clone in
`~/.claude/plugins/marketplaces/` is from 2026-02-25 and lists 4.3.1, older than the fork point) and installs
`superpowers`. It prints the installed version from the plugin's own `plugin.json` and refuses anything older than
5.1.0, the version hyper-relay forked from. The version goes in C.2's run log.

**The owner's one step.** Start `CLAUDE_CONFIG_DIR=~/.claude-superpowers claude`, run `/login`, and check: `/plugins`
lists superpowers and no hyper-relay; the skill list holds nothing from hyper-relay; there is no auto-memory. The same
for `~/.claude-neutral`, with neither workflow.

**Where C.2's sessions start.** `wt new feat/notify-issue-activity`, then, inside `.worktrees/notify-issue-activity`,
`CLAUDE_CONFIG_DIR=~/.claude-superpowers claude`. The worktree has none of SAT's gitignored `.claude/` (the `sat-*`
agents, which tell themselves to use `hyper-relay:executing-plans`, and the planner guard) and no `.mcp.json` (Quartz),
which keeps them out of the run without touching the main checkout. Superpowers then commits its spec and plan on that
branch, not on `main`: its shipped behaviour when started from a worktree, recorded in the run log.

## 3. The usage tool

**`scripts/benchmark/run-usage.sh <run-log>`** (POSIX sh and jq) prints one Markdown table for a run.

**Input.** The run log's header: the config folder, the session ids, the run's start time, the spec, plan and merge
commits with their times, and a role table, lines of `<extended regex> → <role>` matched against subagent
descriptions (for example `implement|Task [0-9]` → `implementer`). Each session id is found as
`<config>/projects/*/<id>.jsonl`; its subagents are `<config>/projects/*/<id>/subagents/agent-*.jsonl`, each with a
`.meta.json` giving `agentType` and `description`. Nested subagents are included.

**Finding the sessions.** `run-usage.sh --sessions <config> <from> <to>` lists every session in a time window with its
first prompt, for the owner to confirm before the ids go in the log.

**Counting.**

- **Tokens.** A transcript writes an API call once per content block, with the same usage each time, so a call is
  counted once, by `message.id`. Per call: input, cache write (5-minute and 1-hour apart, from
  `usage.cache_creation` when present), cache read, output; per model.
- **Cost.** From `scripts/benchmark/prices.tsv`: per model, the price per million tokens of input, output, cache read,
  and 5-minute and 1-hour cache writes, from Anthropic's published prices, with the date they were taken.
- **Cross-check.** Beside its own total the tool prints the summed `totalCostUSD` of the last `cost-state` record of
  each of the run's sessions, and the difference. The plan establishes what `cost-state` covers (whether it includes
  subagents, compaction and web search) and states the tolerance. A gap outside it is explained in the results, never
  ignored.

**Rows.**

- The main session, split into three phases at the spec and plan commit times: design, planning, execution and review.
  This split is what makes the two main sessions comparable: superpowers writes its plan in the main session, the
  relay hands it to a planner agent.
- One row per subagent: its role from the role table (`other` when no pattern matches, so nothing is dropped silently),
  type and description.
- Subtotals per role: for superpowers every implementer, spec reviewer and quality reviewer summed; for the relay the
  planner, the executor and its fix rounds, the acceptance reviewer and the code reviewer.
- A totals line: tokens by category, cost, and:
  - **Wall clock:** the run's start to the merge commit.
  - **Agent time:** the union, over every transcript of the run, of the time some agent was working. In one
    transcript, the time between two consecutive records is working time, except after an assistant message that ends
    its turn (no tool call pending), until the next record: that is waiting. Overlapping agents count once.
  - **The owner's messages:** the owner's own prompts, not tool results and not harness notifications.

Wall clock minus agent time is time waiting on the owner, nights included; the results report it as such and never
as a cost of either workflow.

## 4. Scoring quality

**In-process catches (counted, not scored).** After both runs, one agent with one fixed prompt
(`docs/benchmarks/catches-prompt.md`) reads each run's reviewer transcripts and lists every finding and its outcome
(fixed, dropped, disputed); the owner checks the list. For the relay: the acceptance reviewer's FAILs and the code
review's findings. For superpowers: every per-task spec-review and quality-review issue, and the final code review's.
The executor's own TDD red-to-green steps are not catches.

**Escaped defects (the quality score), three yardsticks.**

1. **The owner's click-through.** Every defect the owner finds, from the first click-through on, goes in the run log
   with one line and a severity. The fixes happen inside the run, so they also cost that workflow tokens and time.
2. **The blind review, after both features merge.** In `~/.claude-neutral` (§2), headless `claude -p` on Opus 5.5,
   once per feature with the same prompt (`docs/benchmarks/blind-review-prompt.md`), in a detached worktree at the
   feature's merge commit. It reviews the code diff from the run's start commit, limited to `api/`, `web/` and
   `mailer-worker/`: no `docs/` and no commit messages, since the relay's `Plan-Task:` trailers name the workflow.
   It checks against a plain requirements list restated from each spec by one agent with one prompt
   (`docs/benchmarks/restate-prompt.md`), so the specs' styles cannot hint at their workflow. A second pass
   (`docs/benchmarks/verify-prompt.md`) confirms or refutes each finding with evidence; only confirmed Critical and
   Important findings count. The review is blind to the label, not provably blind: its prompt says not to read git
   history, and the results say so.
3. **The sealed pitfall list.** Before C.1 starts, a fresh agent (`docs/benchmarks/pitfall-brief.md`) that never saw
   G.2's brainstorm writes 6 to 10 pitfalls per feature, working only from SAT's `CLAUDE.md`, the two cards and the
   Notifications A and B code. Each pitfall is a yes/no check on merged code, with how to check it (a file, a grep, a
   test). The file lives at `~/sat-benchmark/pitfalls.md`, outside both repos; the agent reports only its path and
   sha256, which go in both run logs. Nobody opens it before scoring, the owner included, since knowing it would shape
   the brainstorming answers. At scoring its hash is checked first; then one agent checks every item on both features
   and the owner confirms.

**Reporting.** Raw counts per yardstick, beside each feature's diff size (files and changed lines). With one pair,
n = 1: the results doc says it is evidence about these two runs, not a general rate.

## 5. What the plan builds

- `scripts/benchmark/superpowers-env.sh` (§2), with `--neutral`.
- `scripts/benchmark/run-usage.sh` and `scripts/benchmark/prices.tsv` (§3).
- `tests/benchmark/run-tests.sh` (`0 failed`), with small fixture transcripts. Usage tool: a repeated message id
  counted once; subagent rows from their meta files, nested ones included; the role table and its `other` row; the
  phase split at the commit times; 5-minute and 1-hour cache writes priced apart; agent time with turn-end gaps and
  overlapping agents; the owner's message count excluding tool results and notifications; the cost-record
  cross-check; `--sessions`. Setup script, with a fake home folder and a fake `claude` that records its calls: an
  existing folder refused; the `CLAUDE.md` cut, and its two failure checks; the settings edits; a version older than
  5.1.0 refused; `--neutral` installs neither workflow.
- `docs/benchmarks/`: `pitfall-brief.md`, `restate-prompt.md`, `blind-review-prompt.md`, `verify-prompt.md`,
  `catches-prompt.md`, `run-log-template.md`, all fixed before any run starts; and `README.md`, the runbook below with
  exact commands.
- `CLAUDE.md`: one Checks row (`sh tests/benchmark/run-tests.sh` → `0 failed`; `dash -n` on the two scripts is
  already covered by the Shell syntax row) and one Layout line.

**The plan's acceptance runs on a real past run.** `run-usage.sh` on D1's relay run (this repo's
`2026-11-18-hyper-relay-d1-orchestrator` plan): its total matches the cost records within the stated tolerance, and its
rows line up with D1's stop-4 token report. Those are also the README's first rows, which card G asked for. The owner
builds the two real folders, logs in, and makes the checks of §2.

**The runbook (`docs/benchmarks/README.md`), after the merge:**

1. Build `~/.claude-superpowers` and `~/.claude-neutral`; the owner logs in to each and checks them.
2. Dispatch the pitfall writer; record the sha256.
3. Refresh SAT's role agents; check the dev stack.
4. Run C.1 (§1), fill its run log.
5. Run C.2 (§1), fill its run log.
6. Score: `run-usage.sh` on both logs; the catch counter; the restating agent, the blind review and its verification;
   the pitfall check.
7. Write `docs/benchmarks/<date>-superpowers-baseline.md`: both usage tables, time, the owner's message counts, the
   in-process catches, the escaped defects per yardstick, diff sizes, the superpowers version, the start commits, and
   the caveats (n = 1; the order and copy-the-neighbour bias towards superpowers; the blind review's limit). Commit it
   with the run logs. Card G then takes its numbers from it.

## Out of scope

- Writing the README (card G).
- Wiring `run-usage.sh` into `orchestrating`'s stop 4, to fill its "not reported" token lines. A card of its own, if
  wanted after this.
- A second round with the workflows swapped (for example C.3 and C.6), to cancel out feature difficulty.
- Any change to a skill. G.2 changes no behaviour of the relay, so it has no pressure scenarios.
