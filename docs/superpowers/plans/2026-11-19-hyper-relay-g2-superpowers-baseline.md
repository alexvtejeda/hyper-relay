# hyper-relay G.2: a superpowers baseline on SAT, Implementation Plan

**Card:** Superpowers baseline on SAT: benchmark tooling and protocol (`276a2cbb-ac84-4463-b3ca-5ec87219e597`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–6 are
> the executor's. Task 7 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `owner` and
> `after merge` steps the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the tools and fix the protocol for comparing hyper-relay's relay with upstream superpowers on two SAT
features: a config-folder builder for the upstream run, a transcript reader that turns a run log into a usage table
(tokens, cost, time, the owner's messages, a cross-check against Claude Code's cost records), the fixed prompts of the
quality scoring, the run-log template and the runbook; then prove the reader on D1's real relay run.

**Architecture:** Two POSIX scripts run by dash under `scripts/benchmark/`. `superpowers-env.sh` validates everything it
copies before it creates the folder, links the owner's skills, agents, hooks and bin, copies `settings.json`,
`CLAUDE.md` and the `mcpServers` block with hyper-relay and Quartz cut out, then installs the enabled plugins and
superpowers with `CLAUDE_CONFIG_DIR` set to the new folder. `run-usage.sh` parses the run log's header, finds each
session's transcript and its subagents' transcripts with their `.meta.json`, and hands them to `run-usage.jq`, which
counts each API call once by `message.id`, prices it from `prices.tsv`, splits the main session at the spec and plan
commit times, unions every transcript's working time, and cross-checks the whole sessions against their last
`cost-state` record. One suite, written first, drives both with fixture transcripts, a fake home folder and a fake
`claude`. `docs/benchmarks/` holds the prompts, the template and the runbook.

**Tech Stack:** POSIX `sh` run by dash; jq 1.6 or later (`jq --version` says 1.7 on this machine; dpkg names its
package 1.7.1-3ubuntu0.24.04.2); `awk`, `sed`, `grep`, GNU coreutils; Markdown. Claude Code's transcript format as
2.1.327 wrote it (that is the transcripts' own `version` field; the installed CLI is 2.1.328) and its `claude plugin`
CLI. No skill, `bin/`, `templates/`, `hooks/` or
`.claude-plugin/` file changes: no release and no `skill-test` steps.

**How this was checked:** written against `main` at `ed3eb05` by reading only; nothing was built, run, installed or
generated. Read in this repo: `CLAUDE.md` (in full); the G.2 spec (in full); D.2 Plan 1's plan, the newest plan
that builds a tool, as this one's model (1–370, 640–680, 1250–1646); D.2 Plan 2's (1–145, 1290–1480); D1's plan
(its last-task record, 1830–1881, and its headings by `git grep`); `.hyper-relay/merge.conf` (in full);
`tests/orchestrating/run-tests.sh` (1–80: it greps `CLAUDE.md` for `subagent-driven` and `executing-plans…dispatching`);
`templates/agents/reviewer-commands.md` (in full: the reviewer has no Write tool and writes only its evidence folder);
`.gitignore`; `docs/wt.md` (its commands, by `git grep`). Read-only git: `git ls-files` of `docs/`, `scripts/`,
`tests/`, `templates/`, `.hyper-relay/`; `git ls-files -s` of `scripts/`, `bin/` and two suites (tools `100755`, suites
`100644`); `git grep` of every suite for `CLAUDE.md` and `merge.conf` (only the relay-skills guard reads `CLAUDE.md`;
none reads this repo's `merge.conf`); `git log` of D1's window (spec `9590bc8`, plan `f10be85` and `bca6dae`, merge
`fd0a928`, with their times) and `git show --stat ed3eb05` (README only). Read outside the repo, read-only: the owner's
`~/.claude/CLAUDE.md` (in full), `~/.claude/settings.json` (in full), `~/.claude/plugins/known_marketplaces.json` and
`installed_plugins.json` (in full); `~/.claude.json` by `git grep` for its `mcpServers` keys only; the auto-memory
`relay-token-measurements.md` (in full); the hyper-relay project's transcripts and `.meta.json` files under
`~/.claude/projects/-home-noob-master-hyper-relay/` by `git grep -o` of fields only (D1's session, its nine subagents,
two compacted sessions), and other projects' `.meta.json` files for nested subagents; jq's version from dpkg's status
file. SAT (`~/sat.pentraze.com`), for reference only: `git ls-files` of its Claude files, a `git grep` of its
`CLAUDE.md`/`AGENTS.md` for workflow words, its `Makefile` targets, and a `git grep` of its auto-memory for benchmark
words (none).

**External facts (re-verified 2026-11-19):**
- **Prices** ([platform.claude.com/docs/en/about-claude/pricing](https://platform.claude.com/docs/en/about-claude/pricing),
  "Model pricing", fetched 2026-11-19), per million tokens, input / 5m write / 1h write / cache hit / output: Opus 5.5
  $4 / $5 / $8 / $0.20 / $20; Sonnet 5.5 $2 / $2.50 / $4 / $0.10 / $10; Haiku 5.5 "for prompts up to 100,000 tokens"
  $0.10 / $0.125 / $0.20 / $0.01 / $0.50 and "over 100,000" $0.50 / $0.625 / $1 / $0.05 / $2.50; Opus 5 $5 / $6.25 /
  $10 / $0.50 / $25; Sonnet 5 $2 / $2.50 / $4 / $0.20 / $10; Haiku 4.5 $1 / $1.25 / $2 / $0.10 / $5. "Web search costs
  $10 USD per 1,000 searches". US-only `inference_geo` costs 1.1x; this machine's calls say `"inference_geo":"global"`.
  **Checked against a real cost record:** D1's session's last `cost-state` gives Sonnet 5.5 148 / 53,468 / 4,963,883 /
  573,334 (in / out / read / 5m write) at $2.4646993, Opus 5.5 at $34.8630094 and Haiku 5.5 at $0.0350127 (one web
  search included): each is these prices times its tokens, to the cent. `prices.tsv` (Task 2) holds them.
- **`CLAUDE_CONFIG_DIR` and `.claude.json`** ([code.claude.com/docs/en/claude-directory](https://code.claude.com/docs/en/claude-directory),
  fetched 2026-11-19): "If you set `CLAUDE_CONFIG_DIR`, every `~/.claude` path on this page lives under that directory
  instead. The same applies to `.claude.json`, which otherwise sits at `~/.claude.json`." It holds "account details,
  per-project trust decisions, your personal MCP servers, and UI toggles". **As spec §2**: the folder's own
  `.claude.json` carries its MCP servers.
- **Transcripts** (same page, "Application data"): `projects/<project>/<session>.jsonl` is the conversation transcript;
  `projects/<project>/<session>/subagents/` holds "Subagent transcripts in the same format as the session transcript";
  the sweep deletes them after `cleanupPeriodDays`, "The default is 30 days". **As spec §3**, plus the retention
  (P13). **On this machine** (Claude Code 2.1.327, the transcripts' `version` field): each subagent is
  `<session>/subagents/agent-<agentId>.jsonl` with `agent-<agentId>.meta.json` (`agentType`, `description`,
  `spawnDepth`); a nested subagent sits in the same folder with `spawnDepth: 2` and `parentAgentId` (seen in a quartz
  and two SAT sessions); a resumed subagent appends to its own file (D1's planner and its revision are one file). The
  older note's `tasks/<agentId>.output` no longer exists: no file under the temp folder's `tasks/` matches.
- **The transcript's records** (this machine, by `git grep -o`): an assistant API call is written once per content
  block, each record with the same `message.id`, `message.model`, `message.stop_reason` (`tool_use` or `end_turn`) and
  `message.usage` (`input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`,
  `cache_creation.ephemeral_5m_input_tokens` / `ephemeral_1h_input_tokens`). Summing unique ids reproduces the memory
  file's D1 code-reviewer row exactly (8 calls, 7,865 output, 82,022 written, 16 uncached in). A `<synthetic>` model's
  message has zero usage and `stop_reason` `stop_sequence`. The owner's prompts carry `"origin":{"kind":"human"}`
  (typed, queued and accepted suggestions, and a typed skill command); harness notices carry
  `"origin":{"kind":"task-notification",…}`, other sessions' messages `"kind":"peer"`; tool results and local commands
  carry none; an interruption is a user text "[Request interrupted by user for tool use]". After a turn ends, Claude Code
  writes `system` records (`stop_hook_summary`, `turn_duration`, sometimes `away_summary`). A compaction writes a
  `system` record `compact_boundary` and no assistant record for its own call.
- **`cost-state`** (this machine): `{"type":"cost-state","sessionId",…,"totalCostUSD",…,"startTime",…,"modelUsage":{<model>:
  {inputTokens, outputTokens, …, cacheCreationEphemeral5mInputTokens, cacheCreationEphemeral1hInputTokens,
  webSearchRequests, costUSD}}}`, with no timestamp, written when the process exits. It is cumulative per session
  across resumes (D1's session: $34.05 mid-file, $37.36 on its last line, the same `startTime`). It covers subagents
  (D1's session's Sonnet tokens equal the sum of its seven Sonnet subagents' rows in the memory file: 573,334 written,
  53,468 output) and calls no transcript holds (Haiku 5.5 side calls, there with the one web search: $0.035).
- **Side requests** ([code.claude.com/docs/en/interactive-mode](https://code.claude.com/docs/en/interactive-mode),
  "Prompt suggestions", fetched 2026-11-19): "Claude Code generates each of these next-prompt suggestions with a short
  background request to the same model your session is using. The request counts toward your plan's usage limits or
  your API costs. Because it reuses the conversation's prompt cache, it is mostly cache reads plus a few output
  tokens." "Session recap" also "generates in the background". Neither is in a transcript: this sets the cross-check's
  tolerance (P6).
- **Plugin CLI** ([code.claude.com/docs/en/plugins/cli-reference](https://code.claude.com/docs/en/plugins/cli-reference)
  and [/plugins/install](https://code.claude.com/docs/en/plugins/install), fetched 2026-11-19): `claude plugin
  marketplace add <source> [--scope …]` ("Defaults to `user`"; a repeat add prints "already on disk" and exits `0`);
  `claude plugin install <plugin>` (user scope by default; without a TTY a command-source plugin is refused, exit `1`);
  `claude plugin list --json` prints "an array with one object per installation" with `id`, `version`, `scope`,
  `enabled` and `installPath`; exit codes `0` and `1`. "On a machine where no one has opened an interactive Claude Code
  session yet, the official marketplace isn't registered, so a script that installs from it runs `claude plugin
  marketplace add anthropics/claude-plugins-official` before the install." **As spec §2.**
- **Superpowers** ([obra/superpowers-marketplace's marketplace.json](https://raw.githubusercontent.com/obra/superpowers-marketplace/main/.claude-plugin/marketplace.json)
  and [obra/superpowers' plugin.json](https://raw.githubusercontent.com/obra/superpowers/main/.claude-plugin/plugin.json),
  fetched 2026-11-19): the marketplace is named `superpowers-marketplace`, its plugin `superpowers` is at `7.0.2`, and
  the plugin's own `.claude-plugin/plugin.json` says `"version": "7.0.2"`. Its `skills/` holds `brainstorming`,
  `writing-plans`, `subagent-driven-development`, `requesting-code-review` and `finishing-a-development-branch`.
  **A difference:** 7.0.2's subagent-driven-development dispatches one task reviewer that gives "spec compliance AND
  task quality" together, where spec §3 and §4 name a spec reviewer and a quality reviewer (P9).
- **Headless flags** ([code.claude.com/docs/en/cli-reference](https://code.claude.com/docs/en/cli-reference) and
  [/permission-modes](https://code.claude.com/docs/en/permission-modes), fetched 2026-11-19): `--model`, `--add-dir`,
  `--allowedTools` (rule syntax such as `"Bash(git diff *)"`), `--no-session-persistence` ("Print mode only"),
  `--permission-mode` (`default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`). `claude -p` starts in
  Manual mode, where "Calls needing approval are denied unless you approve them with an allow rule"; `dontAsk`
  "auto-denies every tool call that would otherwise prompt you". The runbook's headless steps use these (P12).

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top unless they start with `~` or `/`. This plan is
  committed on `main`.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#<N>` followed, inside the
  same quoted paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and
  `Claude-Session:` with the URL from your dispatch prompt). The commands below write them as
  `<the line your instructions give>` and `<the URL your dispatch prompt gives>`: put the real lines there. Never tick
  the plan. Report every `quartz:` line a commit prints, verbatim.
- **New files are transcribed.** "Create X with exactly this content" means the Write tool, with the code block's text
  character for character, down to its spaces, blank lines and the `→` character. "Replace X with Y" means the Edit
  tool with X as `old_string`, exactly. If X is not found, read the range again; if the text moved or differs slightly,
  adapt as little as possible and record it as a deviation; if it is gone, stop and report. `prices.tsv` holds tabs: it
  is written by the `printf` command Task 2 gives, not by the Write tool.
- **dash, not bash.** The two scripts and the suite are `#!/bin/sh` scripts run by dash: no `[[`, `local`, arrays,
  `function`, `$'…'` or `pipefail`. Syntax-check each with `dash -n`.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|` (Markdown's escape inside a table): run
  `sh tests/benchmark/run-tests.sh | tail -n 1`, and `grep -c -E '^ok   (prices|usage|sessions):'`.
- **The suite is the contract.** If a test fails, fix the code (`run-usage.sh`, `run-usage.jq`,
  `superpowers-env.sh`), not the assertion. If you believe an assertion is wrong, stop and report it with the output: do
  not edit the assertion.
- **The tools run only inside the suite.** Never run `scripts/benchmark/superpowers-env.sh` yourself: with your real
  `HOME` it builds `~/.claude-superpowers` and installs plugins there. Never run `scripts/benchmark/run-usage.sh` on the
  real `~/.claude`: the acceptance reviewer does that. The suite runs both with `HOME` in a temporary folder and a fake
  `claude` first on `PATH`.
- **Never** push, tag, create anything on GitHub, install, update or uninstall a plugin, add a marketplace, start a
  live `claude` / `claude -p` / `opencode run` session, or read the owner's transcripts. `claude plugin validate .` is
  fine: it starts no session. Do not run upstream's live suites (`tests/claude-code/`, `tests/explicit-skill-requests/`,
  `tests/skill-triggering/`).
- **Outside your branch is not yours.** Never touch `main`, `~/.claude/`, `~/.claude.json`, `~/.claude-superpowers`,
  `~/.claude-neutral`, `~/sat-benchmark/`, SAT's repo (`~/sat.pentraze.com`), `~/.config/opencode/` or the home
  directory's own repo. Task 7's `owner` and `after merge` steps do what is needed there, and they are not yours.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's scratch tracker: never stage, edit,
  move or delete either. A "the tree is clean" check ignores them.
- **This repo is public.** The scripts and the suite name no other project; their fixtures use `example.invalid` and
  made-up names. `docs/benchmarks/` names SAT as the committed spec does, but no path for its checkout (P14: the
  owner sets `SAT`), and quotes none of its files. Nothing you write names a session id, host or person beyond what
  this plan's text holds.
- **No release.** Nothing under `skills/`, `bin/`, `templates/`, `hooks/` or `.claude-plugin/` changes, so `package.json`
  and `.claude-plugin/plugin.json` keep their version (`CLAUDE.md`, "How a change reaches the owner").
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs its own checks only; pipe a suite through `tail -n 1` or `grep`. The full gates run
  once, in Task 6: the suites this plan touches (the Checks table in `CLAUDE.md`: the new benchmark suite, and the
  relay-skills guard, which reads `CLAUDE.md`), `dash -n` of the three shell files, the new `merge.conf` commands once,
  and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 7. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`owner`** (at the click-through) or **`after merge`** (the owner and the orchestrator), with its command or action
  and the result that counts as PASS. After Task 6, report (gate results with counts, every deviation, any `quartz:`
  line, the suites not run and why), copy Task 7's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §3: role lines are "matched against subagent descriptions" | Matched against `<agentType>: <description>` (for example `sat-executor: Execute the C.1 plan on its branch`), first match wins, `other` when none. A pattern on description words still works; a relay role can also be keyed on its agent type (`^sat-planner:`), which the orchestrator does not reword from run to run. Tests: the fixture's executor line is keyed on its type and wins over a later description match. |
| P2 | §5: `run-usage.sh` and `prices.tsv` | Plus `scripts/benchmark/run-usage.jq`, the reader itself (about 200 lines of jq), which `run-usage.sh` runs with `jq -f`. One file per language keeps both readable; it adds no behaviour. |
| P3 | §3 Agent time: "after an assistant message that ends its turn … until the next record: that is waiting" | Until the next **user or assistant** record: Claude Code writes `system` records after a turn ends (stop-hook summary, turn duration, a recap when the owner is away), which would otherwise turn the owner's time into agent time. Also waiting: a pending `AskUserQuestion` call (the owner is answering) and an interruption ("[Request interrupted by user…]"), each until the next user or assistant record. A turn ends at any `stop_reason` but `tool_use` and `pause_turn`. A permission prompt's wait cannot be told apart and counts as agent time; both runs use the owner's `auto` permission mode, so it is rare in both. |
| P4 | §3: "the owner's own prompts, not tool results and not harness notifications" | User records with `origin.kind` `human`, in the run's main sessions, within the run's window. On 2.1.327 that is every typed, queued or accepted-suggestion prompt and a typed skill command; tool results, notifications (`task-notification`), other sessions' messages (`peer`), subagents' dispatch prompts and local commands carry no such origin. |
| P5 | §3 Rows: the phases run from the start to the merge | A call before the start or after the merge (by its own time, in a main session or a subagent) goes on its own "Outside the run" line, not in a row or the total. The cross-check compares whole sessions, since the cost records cover whole sessions. |
| P6 | §3 Cross-check: "The plan establishes what `cost-state` covers … and states the tolerance" | Covers: every call the session's processes made, main and subagents (Sonnet matched exactly on D1), across resumes; plus calls no transcript holds: side requests on the session's model (prompt suggestions, recaps: mostly cache reads), compaction summaries (no assistant record at a `compact_boundary`), Haiku side calls (titles, page summaries) and web searches. **Tolerance:** the transcripts' total is 0% to 10% below the cost records' (rounding allowance $0.005); above them, or more than 10% below, is OUTSIDE, and a session with no record makes it incomplete. The tool prints both totals, the gap, the gap's share, each model's cost and output tokens on both sides, and the compactions, so a gap can be explained. The acceptance measures D1's gap and a compacted session's (Task 7 Steps 6–7); a gap outside is for the owner, not a fix round, unless a model that only subagents used (Sonnet, there) differs. **Owner (2026-11-19, stop 3):** the 10% tolerance stands. |
| P7 | §3 Cost: "per model, the price per million tokens" | A row may name a prompt-size threshold (`over`), so Haiku 5.5's higher prices apply to a call whose input, cache reads and writes together pass 100,000 tokens. Global-routing prices. Rows for Opus 5, Sonnet 5 and Haiku 4.5 too. A model with no row is named on an "Unpriced models" line and counts $0, never silently. `<synthetic>` messages (no usage) are skipped. Web searches are not priced: Claude Code runs them in side calls no transcript holds. |
| P8 | §2: the script builds the folder, links, copies and installs | Also, each decided here: it drops `extraKnownMarketplaces.hyper-relay` beside the `enabledPlugins` entry (else `/plugin` still lists the hyper-relay marketplace, against §2's check); it refuses an MCP server whose name holds "quartz"; it installs the plugins the settings enable, since the folder has no `plugins/` of its own (the official marketplace by its documented source; any other from `extraKnownMarketplaces`, else it refuses); `umask 077`, since `.claude.json`'s MCP servers can hold keys; every check runs before the folder is created, and a failure after that leaves the half-built folder for the owner to remove (the script never deletes a folder); the folder's parent must exist. |
| P9 | §3 Rows and §4: superpowers' "spec reviewer and quality reviewer" | Superpowers 7.0.2 has one task reviewer giving both verdicts (header). The roles are whatever the run dispatches: the runbook's example role lines cover both shapes, and `catches-prompt.md` counts every per-task issue "whatever it calls the review". |
| P10 | §4: "one agent checks every item on both features", no prompt named | `docs/benchmarks/pitfall-check-prompt.md`, fixed before the runs like the other prompts, so the check runs the same on both features. |
| P11 | Scope: `scripts/benchmark/`, `tests/benchmark/`, `docs/benchmarks/`, `CLAUDE.md` | Also `.hyper-relay/merge.conf`: the new suite and the two scripts' syntax become gates, since `CLAUDE.md` says that file "maps its paths to the Checks table". Task 6 runs each new line once. |
| P12 | §4: the headless steps (pitfall writer, restater, blind review, verification, catch counter, checker) | Each runs `claude -p` in `~/.claude-neutral` with `--no-session-persistence`, `--permission-mode dontAsk`, `--allowedTools` and narrow `--add-dir`: the blind steps reach only their worktree and `~/sat-benchmark/blind/`, never the sealed list or the run logs; the pitfall writer leaves no transcript for anyone to open. |
| P13 | §1: the logs are copied at scoring | Claude Code deletes transcripts after 30 days by default, so the runbook runs `run-usage.sh` right after each merge and keeps its output, and scoring must finish within 30 days of C.1's start. D1's table, "the README's first rows", is committed after this merge (Task 7 Step 14): D1's transcripts expire around 2026-12-18. **Owner (2026-11-19, stop 3):** yes, commit D1's table, so there is persistent evidence. |
| P14 | (none) | This repo is public. **Owner (2026-11-19, stop 3): the runbook names no path for SAT's checkout.** Its `## Paths` block reads `SAT=${SAT:?set SAT to the path of the SAT main checkout first}`: the owner sets `SAT` before running the commands, and the line stops them when it is unset. Nothing in `docs/benchmarks/` holds `sat.pentraze` (Task 5 Step 2 checks it). The runbook still names SAT, its two cards' ids and its code folders (`api/`, `web/`, `mailer-worker/`), as the committed spec does; the tools and the suite name no project. The decision covers the runbook only: this plan's own mentions and the committed spec stay. |
| P15 | §1: "No run is told it is being measured"; "the superpowers run does not read the board" | SAT's tracked `CLAUDE.md` names the Quartz board and tells agents to run `quartz review` (its lines 7, 922, 931), and SAT's tracked `.hyper-relay/agents.md` is in C.2's worktree too; the superpowers run reads the first and may read the second. The plan changes nothing in SAT (spec §1); the runbook has C.2's log record any Quartz call the run makes. **Owner (2026-11-19, stop 3):** accepted as written. |
| P16 | §5: "The owner builds the two real folders"; §1: "Build both config folders … so both runs start under the same day's environment" | The owner builds them at this plan's click-through, from the branch's script (Task 7 Step 11); the runbook's step 1 says to move them aside and build again if C.1 starts later and the owner's settings, `CLAUDE.md` or MCP servers changed. |
| P17 | §1: "Opus 5.5 main session, default effort" | The owner's `settings.json` sets `effortLevel` `xhigh`, and the copy keeps it, so both runs share it. The runbook reads "default" as the owner's own and tells both runs to leave it. **Owner (2026-11-19, stop 3):** `xhigh` is fine. |
| P18 | §5: the acceptance runs on "D1's relay run" | D1's session also holds piece E's legs, planned and run beside D1: they come out as `other`. Its design phase covers that session only (the brainstorm began in an earlier one); its start is that session's first owner prompt. |
| P19 | §3 Input: "the run log's header" | The header is every `key: value` line before the first `## ` heading; times are UTC, `2026-11-20T14:03:00Z`; `spec:`, `plan:` and `merge:` are `<hash> <time>` (`-` for a hash when a workflow never commits it); `session:` and `role:` repeat; `workflow:`, `card:`, `start-commit:` and `pitfalls-sha256:` are for people. A duplicate session line counts once. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–6 (the tools and the fixed protocol); the runs and the results follow the runbook after the merge (Task 5) |
| Decisions (owner, 2026-11-19) | G2.1, G2.2, G2.5: 5 (the runbook's steps 4 and 5). G2.3: 3; 7 (Step 11). G2.4: 4 (the prompts), 5 (steps 2 and 6). G2.6: 1, 2; 7 (Steps 4–7). G2.7: the header's card line (no task) |
| 1. The protocol | 4 (`run-log-template.md`), 5 (the runbook's rules and steps 3–5) |
| 2. The superpowers config folder | 1 (its tests), 3 (`superpowers-env.sh`), 5 (step 1); 7 (Step 11, the owner's build, login and checks) |
| 3. The usage tool | 1 (its tests), 2 (`run-usage.sh`, `run-usage.jq`, `prices.tsv`); 7 (Steps 4–7, D1's run) |
| 4. Scoring quality | 4 (the six prompts), 5 (steps 2 and 6) |
| 5. What the plan builds | 1–6; 7 (D1's run, the owner's folders, D1's table) |
| Out of scope | Execution notes (none of it is here: no README, no skill, no stop-4 wiring, no second round) |

## File structure

- **Create (Task 1):** `tests/benchmark/run-tests.sh` (mode 644): both tools' suite, its fixtures and fake `claude`
  inside it.
- **Create (Task 2):** `scripts/benchmark/run-usage.sh` (755), `scripts/benchmark/run-usage.jq` (644),
  `scripts/benchmark/prices.tsv` (644).
- **Create (Task 3):** `scripts/benchmark/superpowers-env.sh` (755).
- **Create (Task 4):** `docs/benchmarks/run-log-template.md`, `pitfall-brief.md`, `restate-prompt.md`,
  `blind-review-prompt.md`, `verify-prompt.md`, `catches-prompt.md`, `pitfall-check-prompt.md`.
- **Create (Task 5):** `docs/benchmarks/README.md`, the runbook.
- **Modify (Task 6):** `CLAUDE.md` (Layout, Checks), `.hyper-relay/merge.conf` (gates).
- **Unchanged:** every skill, `bin/`, `templates/`, `hooks/`, `.claude-plugin/`, `package.json`, `README.md`, the other
  suites.
- **Task 7, outside the branch (owner and orchestrator):** `~/.claude-superpowers`, `~/.claude-neutral`, and on `main`
  `docs/benchmarks/runs/2026-11-18-d1-relay.md` and this plan's record.

---

### Task 1: The suite, written first (spec §5; P1–P8, P19)

**Files:**
- Create: `tests/benchmark/run-tests.sh`

- [x] **Step 1: Write the suite.** Create `tests/benchmark/run-tests.sh` with exactly this content:

```sh
#!/bin/sh
# POSIX tests for G.2's benchmark tools (docs/benchmarks/README.md): scripts/benchmark/run-usage.sh on
# small fixture transcripts priced by a test prices file, and scripts/benchmark/superpowers-env.sh with
# a fake home folder and a fake claude that records its calls. HOME is a temporary folder before either
# tool runs, so nothing here reads or writes the real ~/.claude, ~/.claude.json or a login.
# Usage: sh tests/benchmark/run-tests.sh      Expect: "90 passed, 0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
RU=$REPO/scripts/benchmark/run-usage.sh
SE=$REPO/scripts/benchmark/superpowers-env.sh
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

# The tools read these from the environment: none may leak in from the caller.
unset CLAUDE_CONFIG_DIR RUN_USAGE_PRICES FAKE_CLAUDE_LOG FAKE_SP_VERSION SP_VERSION
HOME=$TMP_ROOT/home
export HOME
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
yes_no() { # path: yes when it exists (a dangling link included), no when not
    if [ -e "$1" ] || [ -L "$1" ]; then echo yes; else echo no; fi
}

echo '--- prices.tsv'
PRICES=$REPO/scripts/benchmark/prices.tsv
assert_eq "prices: every row is a model, a threshold and five prices, all numbers" 0 \
    "$(if [ -f "$PRICES" ]; then awk -F '\t' '!/^#/ && NF { if (NF != 7) bad++; for (i = 2; i <= 7; i++) if ($i !~ /^[0-9]+(\.[0-9]+)?$/) bad++ } END { print bad + 0 }' "$PRICES"; else echo "no prices.tsv"; fi)"
assert_eq "prices: Opus, Sonnet and Haiku 5.5 have rows" 3 \
    "$(awk -F '\t' '!/^#/ && NF { print $1 }' "$PRICES" 2>/dev/null | sort -u | grep -c -E '^claude-(opus|sonnet|haiku)-5-5$')"
assert_contains "prices: the date they were taken, and where" \
    "2026-11-19 from https://platform.claude.com/docs/en/about-claude/pricing" "$(cat "$PRICES" 2>/dev/null)"

echo '--- run-usage: fixture transcripts'
printf '# test prices\ntest-big\t0\t1\t10\t0.1\t1.25\t2\ntest-small\t0\t0.5\t2\t0.05\t0.625\t1\ntest-small\t1000000\t1\t4\t0.1\t1.25\t2\n' \
    > "$TMP_ROOT/prices.tsv"

# Transcript records, one JSON object per line, as Claude Code writes them.
owner() { # time text: the owner's own prompt
    printf '{"type":"user","message":{"role":"user","content":"%s"},"origin":{"kind":"human"},"promptSource":"typed","timestamp":"%s"}\n' "$2" "$1"
}
prompt() { # time text: a user record with no origin, as a subagent's dispatch prompt is
    printf '{"type":"user","message":{"role":"user","content":"%s"},"timestamp":"%s"}\n' "$2" "$1"
}
result() { # time: a tool result
    printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t","content":"ok"}]},"toolUseResult":"ok","timestamp":"%s"}\n' "$1"
}
notice() { # time: the harness's notice that a background agent finished
    printf '{"type":"user","message":{"role":"user","content":"<task-notification>done</task-notification>"},"origin":{"kind":"task-notification"},"promptSource":"system","timestamp":"%s"}\n' "$1"
}
# call <time> <id> <model> <stop reason> <input> <5m write> <1h write> <read> <output> [<block>]:
# one content block of an API call, with usage.cache_creation; a text block unless one is given.
call() {
    block=${10:-}
    [ -n "$block" ] || block='{"type":"text","text":"x"}'
    printf '{"type":"assistant","message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":[%s],"stop_reason":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":%s,"ephemeral_1h_input_tokens":%s}}},"timestamp":"%s"}\n' \
        "$3" "$2" "$block" "$4" "$5" "$(($6 + $7))" "$8" "$9" "$6" "$7" "$1"
}
# old_call <time> <id> <model> <stop reason> <input> <write> <read> <output>: the same as an older
# Claude Code wrote it, with no usage.cache_creation, so its writes are 5-minute ones.
old_call() {
    printf '{"type":"assistant","message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":[{"type":"text","text":"x"}],"stop_reason":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}},"timestamp":"%s"}\n' \
        "$3" "$2" "$4" "$5" "$6" "$7" "$8" "$1"
}
TOOL='{"type":"tool_use","id":"t","name":"Bash","input":{}}'
ASK='{"type":"tool_use","id":"t","name":"AskUserQuestion","input":{}}'
THINK='{"type":"thinking","thinking":"x"}'

P=$HOME/cfg/projects/-proj
mkdir -p "$P/sess1/subagents" "$P/sess2/subagents"
D=2026-01-01T

# sess1: the run's first main session. A call before the start and one after the merge; a message
# written as two records; an open question; a line cut short; a compaction; two cost records.
{
    owner "${D}09:55:00.000Z" "before the run"
    call "${D}09:55:10.000Z" m0 test-big end_turn 1000000 0 0 0 0
    owner "${D}10:00:00.000Z" "start"
    call "${D}10:00:30.000Z" m1 test-big end_turn 2 0 1000000 0 100000 "$THINK"
    call "${D}10:00:31.000Z" m1 test-big end_turn 2 0 1000000 0 100000
    owner "${D}10:05:00.000Z" "an answer"
    call "${D}10:05:20.000Z" m2 test-big tool_use 2 0 0 1000000 50000 "$TOOL"
    result "${D}10:05:21.000Z"
    call "${D}10:05:30.000Z" m3 test-big end_turn 2 0 0 1000000 10000
    printf '%s\n' '{"type":"assistant","message":'
    notice "${D}10:15:00.000Z"
    call "${D}10:15:10.000Z" m4 test-big end_turn 2 0 0 2000000 20000
    owner "${D}10:25:00.000Z" "go"
    call "${D}10:25:10.000Z" m5 test-big tool_use 2 0 0 1000000 1000 "$ASK"
    result "${D}10:27:10.000Z"
    call "${D}10:27:20.000Z" m6 test-big end_turn 2 0 0 1000000 1000
    printf '{"type":"system","subtype":"compact_boundary","content":"Conversation compacted","timestamp":"%s"}\n' "${D}10:50:00.000Z"
    owner "${D}10:58:00.000Z" "merge it"
    call "${D}10:59:00.000Z" m7 test-big end_turn 2 0 0 1000000 1000
    owner "${D}11:05:00.000Z" "after"
    call "${D}11:05:30.000Z" m8 test-big end_turn 1000000 0 0 0 0
    printf '%s\n' '{"type":"cost-state","sessionId":"sess1","totalCostUSD":5,"modelUsage":{}}'
    printf '%s\n' '{"type":"cost-state","sessionId":"sess1","totalCostUSD":9.701039,"modelUsage":{"test-big":{"costUSD":9.370024,"outputTokens":302000},"test-small":{"costUSD":0.231015,"outputTokens":2000},"test-side":{"costUSD":0.1,"outputTokens":50}}}'
} > "$P/sess1.jsonl"
{
    prompt "${D}10:05:22.000Z" "write the plan"
    old_call "${D}10:05:40.000Z" p1 test-big tool_use 2 1000000 0 10000
    result "${D}10:06:00.000Z"
    call "${D}10:12:00.000Z" p2 test-big tool_use 2 0 0 1000000 100000 "$TOOL"
    result "${D}10:12:30.000Z"
    call "${D}10:14:50.000Z" p3 test-big tool_use 2 0 0 1000000 5000 "$TOOL"
    result "${D}10:14:51.000Z"
} > "$P/sess1/subagents/agent-a1.jsonl"
printf '%s\n' '{"agentType":"relay-planner","description":"Write the demo plan","spawnDepth":1}' \
    > "$P/sess1/subagents/agent-a1.meta.json"
{
    prompt "${D}10:30:00.000Z" "execute the plan"
    call "${D}10:30:10.000Z" e1 test-small tool_use 10 0 0 500000 1000 "$TOOL"
    result "${D}10:30:20.000Z"
    call "${D}10:39:00.000Z" e2 test-small tool_use 10 0 0 2000000 1000 "$TOOL"
    result "${D}10:39:01.000Z"
} > "$P/sess1/subagents/agent-a2.jsonl"
printf '%s\n' '{"agentType":"relay-executor","description":"Execute the demo plan","spawnDepth":1}' \
    > "$P/sess1/subagents/agent-a2.meta.json"
{
    prompt "${D}10:35:00.000Z" "review task 1"
    call "${D}10:35:30.000Z" r1 test-big tool_use 2 0 0 1000000 2000 "$TOOL"
    result "${D}10:35:31.000Z"
    call "${D}10:38:00.000Z" r2 test-big end_turn 2 0 0 1000000 2000 "$THINK"
    call "${D}10:38:01.000Z" r2 test-big end_turn 2 0 0 1000000 2000
} > "$P/sess1/subagents/agent-a3.jsonl"
printf '%s\n' '{"agentType":"general-purpose","description":"Review task 1 code","parentAgentId":"a2","spawnDepth":2}' \
    > "$P/sess1/subagents/agent-a3.meta.json"

# sess2: a second main session of the same run, with an Explore subagent no role line matches.
{
    owner "${D}10:40:00.000Z" "continue"
    call "${D}10:40:10.000Z" n1 test-big tool_use 2 0 0 1000000 1000 "$TOOL"
    result "${D}10:40:11.000Z"
    call "${D}10:40:20.000Z" n2 test-big end_turn 2 0 0 1000000 1000
    printf '%s\n' '{"type":"cost-state","sessionId":"sess2","totalCostUSD":0.220504,"modelUsage":{"test-big":{"costUSD":0.220004,"outputTokens":2000},"test-small":{"costUSD":0.0005,"outputTokens":200}}}'
} > "$P/sess2.jsonl"
{
    prompt "${D}10:40:12.000Z" "explore"
    call "${D}10:40:30.000Z" x1 test-small tool_use 100 0 0 0 100 "$TOOL"
    result "${D}10:41:00.000Z"
    call "${D}10:41:10.000Z" x2 test-small end_turn 100 0 0 0 100
} > "$P/sess2/subagents/agent-a4.jsonl"
printf '%s\n' '{"agentType":"Explore","description":"Explore the code","spawnDepth":1}' \
    > "$P/sess2/subagents/agent-a4.meta.json"

# sess3 has a model with no price and a cost record below its transcripts; sess4 has no cost record.
E=2026-01-02T
{
    owner "${E}10:00:00.000Z" "third"
    call "${E}10:00:10.000Z" q1 test-big end_turn 1000000 0 0 0 0
    owner "${E}10:00:20.000Z" "again"
    call "${E}10:00:30.000Z" q2 test-unknown end_turn 5000 0 0 0 10
    printf '%s\n' '{"type":"cost-state","sessionId":"sess3","totalCostUSD":0.5,"modelUsage":{"test-big":{"costUSD":0.5,"outputTokens":0}}}'
} > "$P/sess3.jsonl"
{
    owner "${E}10:01:00.000Z" "fourth"
    call "${E}10:01:10.000Z" q3 test-big end_turn 1000000 0 0 0 0
} > "$P/sess4.jsonl"

# ru <args>: run-usage.sh with the test prices. Sets OUT (stdout and stderr) and RC.
ru() {
    OUT=$(RUN_USAGE_PRICES="$TMP_ROOT/prices.tsv" dash "$RU" "$@" 2>&1)
    RC=$?
}

echo '--- run-usage: one run, two sessions'
cat > "$TMP_ROOT/run-a.md" <<'EOF'
# Run log: demo run

<!-- a comment line, which starts no key -->
workflow: test
config: ~/cfg
session: sess1
session: sess2
session: sess1
start: 2026-01-01T10:00:00Z
spec: aaaaaaa 2026-01-01T10:10:00Z
plan: bbbbbbb 2026-01-01T10:20:00Z
merge: ccccccc 2026-01-01T11:00:00Z
role: ^relay-executor: → executor
role: plan$ → planner
role: [Rr]eview → reviewer

## Notes

session: sess3
EOF
ru "$TMP_ROOT/run-a.md"
assert_eq "usage: exit 0" 0 "$RC"
assert_contains "usage: the title comes from the log's first heading" "# Usage: Run log: demo run" "$OUT"
assert_contains "usage: only the header's sessions, each once" "sessions sess1, sess2. The run:" "$OUT"
assert_contains "usage: the design phase, before the spec commit; 1-hour writes at the 1-hour price" \
    "| main: design | main |  |  | 3 | 6 | 0 | 1,000,000 | 2,000,000 | 160,000 | 3.80 |" "$OUT"
assert_contains "usage: the planning phase, from the spec commit to the plan commit" \
    "| main: planning | main |  |  | 1 | 2 | 0 | 0 | 2,000,000 | 20,000 | 0.40 |" "$OUT"
assert_contains "usage: execution and review, to the merge, in both sessions" \
    "| main: execution and review | main |  |  | 5 | 10 | 0 | 0 | 5,000,000 | 5,000 | 0.55 |" "$OUT"
assert_contains "usage: a subagent row from its meta file; an older usage's writes count as 5-minute ones" \
    "| agent a1 | planner | relay-planner | Write the demo plan | 3 | 6 | 1,000,000 | 0 | 2,000,000 | 115,000 | 2.60 |" "$OUT"
assert_contains "usage: a role line keyed on the agent type wins, being first; a long prompt pays the higher tier" \
    "| agent a2 | executor | relay-executor | Execute the demo plan | 2 | 20 | 0 | 0 | 2,500,000 | 2,000 | 0.23 |" "$OUT"
assert_contains "usage: a nested subagent, under its parent" \
    "| agent a3, under a2 | reviewer | general-purpose | Review task 1 code | 2 | 4 | 0 | 0 | 2,000,000 | 4,000 | 0.24 |" "$OUT"
assert_contains "usage: a subagent no role line matches is other" \
    "| agent a4 | other | Explore | Explore the code | 2 | 200 | 0 | 0 | 0 | 200 | 0.00 |" "$OUT"
assert_eq "usage: subagent rows in the order they started" "a1 a2 a3 a4 " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| agent \(a[0-9]\).*/\1/p' | tr '\n' ' ')"
assert_eq "usage: a subtotal per role, main first" "main planner executor reviewer other " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| subtotal: \([a-z]*\) |.*/\1/p' | tr '\n' ' ')"
assert_contains "usage: the main subtotal" \
    "| subtotal: main | main |  | 3 phases | 9 | 18 | 0 | 1,000,000 | 9,000,000 | 185,000 | 4.75 |" "$OUT"
assert_contains "usage: a role's subtotal" \
    "| subtotal: planner | planner |  | 1 agent | 3 | 6 | 1,000,000 | 0 | 2,000,000 | 115,000 | 2.60 |" "$OUT"
assert_contains "usage: the total counts a repeated message id once and skips a cut-short line" \
    "| total |  |  |  | 18 | 248 | 1,000,000 | 1,000,000 | 15,500,000 | 306,200 | 7.82 |" "$OUT"
assert_contains "usage: wall clock, from the start to the merge" "- **Wall clock:** 1h 00m 00s" "$OUT"
assert_contains "usage: agent time leaves out turn-end waits and an open question, and counts overlaps once" \
    "- **Agent time:** 0h 22m 02s" "$OUT"
assert_contains "usage: waiting on the owner is the rest" "- **Waiting on the owner:** 0h 37m 58s" "$OUT"
assert_contains "usage: the owner's messages, not tool results, notices or dispatch prompts" \
    "- **The owner's messages:** 5" "$OUT"
assert_contains "usage: compactions within the run" "- **Compactions:** 1 " "$OUT"
assert_contains "usage: calls before the start or after the merge stay out of the total" \
    '- **Outside the run:** 2 calls, $2.00' "$OUT"
assert_contains "usage: the cross-check against the last cost record of each session" \
    'whole: $9.82; the cost records (the last `cost-state` of each session): $9.92; difference $0.10 (1.01% of the cost records). Within the tolerance (0 to 10%).' "$OUT"
assert_contains "usage: both sides by model" \
    '- **By model**, cost records / transcripts: test-big $9.59, 304,000 output / $9.59, 304,000 output; test-side $0.10, 50 output / $0.00, 0 output; test-small $0.23, 2,200 output / $0.23, 2,200 output' "$OUT"
assert_not_contains "usage: no unpriced model" "Unpriced" "$OUT"

echo '--- run-usage: a cross-check outside, or incomplete'
printf '%s\n' '# Run log: outside' '' 'config: ~/cfg' 'session: sess3' 'start: 2026-01-02T10:00:00Z' \
    'spec: - 2026-01-02T10:00:05Z' 'plan: - 2026-01-02T10:00:06Z' 'merge: - 2026-01-02T10:02:00Z' > "$TMP_ROOT/run-c.md"
ru "$TMP_ROOT/run-c.md"
assert_eq "usage: a short run: exit 0" 0 "$RC"
assert_contains "usage: transcripts above the cost records are outside the tolerance" \
    'difference -$0.50 (-100.00% of the cost records). OUTSIDE the tolerance (0 to 10%): explain it in the results.' "$OUT"
assert_contains "usage: a model with no price is named, never priced silently" \
    '- **Unpriced models** (no row in the prices file; their calls count as $0): test-unknown (1 call)' "$OUT"
printf '%s\n' '# Run log: incomplete' '' 'config: ~/cfg' 'session: sess3' 'session: sess4' 'start: 2026-01-02T10:00:00Z' \
    'spec: - 2026-01-02T10:00:05Z' 'plan: - 2026-01-02T10:00:06Z' 'merge: - 2026-01-02T10:02:00Z' > "$TMP_ROOT/run-b.md"
ru "$TMP_ROOT/run-b.md"
assert_contains "usage: a session with no cost record makes the cross-check incomplete" \
    "Incomplete: no cost record in session sess4." "$OUT"

echo '--- run-usage: run logs it refuses'
sed '/^merge:/d' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-merge.md"
ru "$TMP_ROOT/bad-merge.md"
assert_eq "usage: no merge line: exit 1" 1 "$RC"
assert_contains "usage: no merge line: says so" "the run log has no 'merge:' line" "$OUT"
sed 's/^session: sess2$/session: nosuch/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-session.md"
ru "$TMP_ROOT/bad-session.md"
assert_eq "usage: an unknown session: exit 1" 1 "$RC"
assert_contains "usage: an unknown session: says so" "no transcript for session nosuch under" "$OUT"
sed 's/^role: plan\$ → planner$/role: plan -> planner/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-role.md"
ru "$TMP_ROOT/bad-role.md"
assert_eq "usage: a role line with no arrow: exit 1" 1 "$RC"
assert_contains "usage: a role line with no arrow: says so" "a role line needs" "$OUT"
sed 's/^start: .*/start: yesterday/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-time.md"
ru "$TMP_ROOT/bad-time.md"
assert_contains "usage: a time not in UTC form: says so" "not a UTC time like 2026-11-20T14:03:00Z: yesterday" "$OUT"
ru
assert_eq "usage: no argument: exit 1" 1 "$RC"

echo '--- run-usage --sessions'
ru --sessions "$HOME/cfg" 2026-01-01T10:39:00Z 2026-01-01T10:41:00Z
assert_eq "sessions: exit 0" 0 "$RC"
assert_contains "sessions: a session with a record in the window, with its first prompt" \
    "| sess2 | -proj | 2026-01-01T10:40:00Z | 2026-01-01T10:40:20Z | 2026-01-01T10:40:00Z continue |" "$OUT"
assert_not_contains "sessions: a session with no record in it is left out" "| sess1 |" "$OUT"
ru --sessions "~/cfg" 2026-01-01T00:00:00Z 2026-01-03T00:00:00Z
assert_eq "sessions: every session in a wide window, by its first record" "sess1 sess2 sess3 sess4 " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| \(sess[0-9]\) |.*/\1/p' | tr '\n' ' ')"
assert_contains "sessions: the first prompt is the owner's, at its own time" \
    "| sess1 | -proj | 2026-01-01T09:55:00Z | 2026-01-01T11:05:30Z | 2026-01-01T09:55:00Z before the run |" "$OUT"
ru --sessions "$HOME/cfg" 2026-02-01T00:00:00Z 2026-02-02T00:00:00Z
assert_contains "sessions: an empty window says so" \
    "No session has a record between 2026-02-01T00:00:00Z and 2026-02-02T00:00:00Z." "$OUT"
ru --sessions "$HOME/cfg" 2026-01-01 2026-01-02T00:00:00Z
assert_eq "sessions: a time not in UTC form: exit 1" 1 "$RC"

# A fake claude, first on PATH, that records each call as "<CLAUDE_CONFIG_DIR> | <arguments>".
mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/claude" <<'EOF'
#!/bin/sh
printf '%s | %s\n' "${CLAUDE_CONFIG_DIR:-unset}" "$*" >> "$FAKE_CLAUDE_LOG"
case "$*" in
    "plugin marketplace add "*) exit 0 ;;
    "plugin install superpowers@superpowers-marketplace")
        dir=$CLAUDE_CONFIG_DIR/plugins/cache/superpowers-marketplace/superpowers/$FAKE_SP_VERSION
        mkdir -p "$dir/.claude-plugin"
        printf '{"name":"superpowers","version":"%s"}\n' "$FAKE_SP_VERSION" > "$dir/.claude-plugin/plugin.json"
        printf '%s\n' "$dir" > "$CLAUDE_CONFIG_DIR/fake-superpowers"
        exit 0 ;;
    "plugin install "*) exit 0 ;;
    "plugin list --json")
        if [ -f "$CLAUDE_CONFIG_DIR/fake-superpowers" ]; then
            printf '[{"id":"superpowers@superpowers-marketplace","version":"%s","scope":"user","enabled":true,"installPath":"%s"}]\n' \
                "$FAKE_SP_VERSION" "$(cat "$CLAUDE_CONFIG_DIR/fake-superpowers")"
        else
            echo '[]'
        fi
        exit 0 ;;
esac
echo "fake claude: unexpected call: $*" >&2
exit 1
EOF
chmod +x "$TMP_ROOT/fakebin/claude"

SETTINGS='{"env":{"EXAMPLE":"1"},"model":"opus","hooks":{"PreToolUse":[{"matcher":"*","hooks":[{"type":"command","command":"~/.claude/bin/ccs hook PreToolUse","timeout":5}]}],"Stop":[{"matcher":"*","hooks":[{"type":"command","command":"~/.claude/bin/ccs hook Stop","timeout":5}]},{"matcher":"*","hooks":[{"type":"command","command":"/opt/quartz/bin/quartz hook flush","async":true}]}],"SubagentStop":[{"matcher":"*","hooks":[{"type":"command","command":"/opt/quartz/bin/quartz hook flush","async":true}]}]},"enabledPlugins":{"frontend-design@claude-plugins-official":true,"playwright@claude-plugins-official":false,"ui-ux-pro-max@ui-ux-pro-max-skill":true,"hyper-relay@hyper-relay":true},"extraKnownMarketplaces":{"ui-ux-pro-max-skill":{"source":{"source":"github","repo":"example/ui-ux-pro-max-skill"}},"hyper-relay":{"source":{"source":"github","repo":"example/hyper-relay"}}}}'
CLAUDE_JSON='{"oauthAccount":{"emailAddress":"someone@example.invalid"},"projects":{"/somewhere":{"mcpServers":{"local":{"command":"x"}}}},"mcpServers":{"context7":{"type":"http","url":"https://example.invalid/mcp"},"playwright":{"command":"npx"}}}'
CLAUDE_MD_OK=$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' \
    'All creative work runs through the hyper-relay relay.' '' '### Quartz' '' 'The board is live.' '' \
    '## Code Quality' '' '- Fix the root cause.' '' '## Design' '' '- Count, do not prescribe.')

# make_home [<CLAUDE.md>] [<.claude.json>]: a fresh fake home with ~/.claude (skills, agents, hooks,
# bin; no commands, no rules) and ~/.claude.json, and an empty claude log.
make_home() {
    HOME=$(mktemp -d "$TMP_ROOT/home.XXXXXX")
    export HOME
    mkdir -p "$HOME/.claude/skills/demo" "$HOME/.claude/agents" "$HOME/.claude/hooks" "$HOME/.claude/bin"
    printf 'demo\n' > "$HOME/.claude/skills/demo/SKILL.md"
    printf '%s\n' "${1:-$CLAUDE_MD_OK}" > "$HOME/.claude/CLAUDE.md"
    printf '%s\n' "$SETTINGS" > "$HOME/.claude/settings.json"
    printf '%s\n' "${2:-$CLAUDE_JSON}" > "$HOME/.claude.json"
    FAKE_CLAUDE_LOG=$HOME/claude.log
    export FAKE_CLAUDE_LOG
    : > "$FAKE_CLAUDE_LOG"
}

# se <args>: superpowers-env.sh with the fake claude first on PATH; superpowers is at SP_VERSION
# (7.0.2 unless set). Sets OUT and RC.
se() {
    OUT=$(PATH="$TMP_ROOT/fakebin:$PATH" FAKE_SP_VERSION="${SP_VERSION:-7.0.2}" dash "$SE" "$@" 2>&1)
    RC=$?
}

echo '--- superpowers-env: the default build'
make_home
SUM_BEFORE=$(cksum "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude.json")
se
T=$HOME/.claude-superpowers
assert_eq "env: exit 0" 0 "$RC"
assert_eq "env: skills, agents, hooks and bin link to the owner's" \
    "$HOME/.claude/skills $HOME/.claude/agents $HOME/.claude/hooks $HOME/.claude/bin" \
    "$(readlink "$T/skills") $(readlink "$T/agents") $(readlink "$T/hooks") $(readlink "$T/bin")"
assert_eq "env: commands and rules, which the owner has none of, are skipped" "no no" \
    "$(yes_no "$T/commands") $(yes_no "$T/rules")"
assert_contains "env: says what it skipped" "skipped commands: there is no" "$OUT"
assert_eq "env: CLAUDE.md loses the relay's section, its Quartz part included, and keeps the rest" \
    "$(printf '%s\n' '# Global Instructions' '' '## Code Quality' '' '- Fix the root cause.' '' '## Design' '' '- Count, do not prescribe.')" \
    "$(cat "$T/CLAUDE.md")"
assert_eq "env: settings.json enables the same plugins, without hyper-relay" \
    "frontend-design@claude-plugins-official=true playwright@claude-plugins-official=false ui-ux-pro-max@ui-ux-pro-max-skill=true" \
    "$(jq -r '.enabledPlugins | to_entries | map("\(.key)=\(.value)") | join(" ")' "$T/settings.json")"
assert_eq "env: settings.json drops the hyper-relay marketplace only" "ui-ux-pro-max-skill" \
    "$(jq -r '.extraKnownMarketplaces | keys | join(" ")' "$T/settings.json")"
assert_eq "env: Stop keeps its other hook, without quartz hook flush" "~/.claude/bin/ccs hook Stop" \
    "$(jq -r '[.hooks.Stop[].hooks[].command] | join(",")' "$T/settings.json")"
assert_eq "env: SubagentStop, left empty, is dropped" false "$(jq -r '.hooks | has("SubagentStop")' "$T/settings.json")"
assert_eq "env: every other hook and setting is the owner's" \
    "$(jq -c 'del(.hooks.Stop, .hooks.SubagentStop, .enabledPlugins, .extraKnownMarketplaces)' "$HOME/.claude/settings.json")" \
    "$(jq -c 'del(.hooks.Stop, .hooks.SubagentStop, .enabledPlugins, .extraKnownMarketplaces)' "$T/settings.json")"
assert_eq "env: .claude.json holds only the mcpServers block" '["mcpServers"]' "$(jq -c 'keys' "$T/.claude.json")"
assert_eq "env: with the owner's servers" "context7 playwright" "$(jq -r '.mcpServers | keys | join(" ")' "$T/.claude.json")"
assert_eq "env: .claude.json is readable by its owner only" "$T/.claude.json" "$(find "$T/.claude.json" -perm 600)"
assert_eq "env: no projects folder, so no auto-memory" no "$(yes_no "$T/projects")"
assert_eq "env: every claude call runs with CLAUDE_CONFIG_DIR set to the new folder" 0 \
    "$(grep -c -v -F "$T | " "$FAKE_CLAUDE_LOG")"
assert_eq "env: the marketplaces, the enabled plugins, then superpowers and its version" \
    "$(printf '%s\n' "$T | plugin marketplace add anthropics/claude-plugins-official" \
        "$T | plugin marketplace add example/ui-ux-pro-max-skill" \
        "$T | plugin install frontend-design@claude-plugins-official" \
        "$T | plugin install ui-ux-pro-max@ui-ux-pro-max-skill" \
        "$T | plugin marketplace add obra/superpowers-marketplace" \
        "$T | plugin install superpowers@superpowers-marketplace" \
        "$T | plugin list --json")" \
    "$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "env: prints the installed superpowers version" "superpowers 7.0.2, read from" "$OUT"
assert_eq "env: the owner's ~/.claude and ~/.claude.json are unchanged" "$SUM_BEFORE" \
    "$(cksum "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude.json")"

echo '--- superpowers-env: a folder that exists'
: > "$FAKE_CLAUDE_LOG"
se
assert_eq "env: a folder that exists: exit 1" 1 "$RC"
assert_contains "env: a folder that exists: refused" "already exists" "$OUT"
assert_eq "env: a folder that exists: claude is never called" "" "$(cat "$FAKE_CLAUDE_LOG")"

echo '--- superpowers-env: --neutral'
make_home
se --neutral
N=$HOME/.claude-neutral
assert_eq "env: --neutral: exit 0" 0 "$RC"
assert_eq "env: --neutral: builds ~/.claude-neutral" yes "$(yes_no "$N/settings.json")"
assert_eq "env: --neutral: installs neither workflow" 0 "$(grep -c -i -e superpowers -e hyper-relay "$FAKE_CLAUDE_LOG")"
assert_contains "env: --neutral: still installs the other plugins" \
    "$N | plugin install frontend-design@claude-plugins-official" "$(cat "$FAKE_CLAUDE_LOG")"
assert_eq "env: --neutral: its settings name neither workflow" 0 \
    "$(grep -c -i -e superpowers -e hyper-relay "$N/settings.json")"

echo '--- superpowers-env: a folder given, and the superpowers version'
SP_VERSION=4.3.1
se "$HOME/old"
assert_eq "env: superpowers 4.3.1: exit 1" 1 "$RC"
assert_contains "env: superpowers 4.3.1: refused, older than the fork point" "superpowers 4.3.1 is older than 5.1.0" "$OUT"
SP_VERSION=5.1.0
se "$HOME/exact"
assert_eq "env: superpowers 5.1.0 itself: exit 0" 0 "$RC"
assert_eq "env: a folder given: built there" yes "$(yes_no "$HOME/exact/settings.json")"
SP_VERSION=10.0.0
se "$HOME/ten"
assert_eq "env: superpowers 10.0.0, compared as numbers: exit 0" 0 "$RC"
unset SP_VERSION

echo '--- superpowers-env: a CLAUDE.md that changed shape'
make_home "$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' 'Use the relay.' '' '## Design')"
se
assert_eq "env: no Code Quality heading: exit 1" 1 "$RC"
assert_contains "env: no Code Quality heading: refused" "changed shape" "$OUT"
assert_eq "env: no Code Quality heading: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"
make_home "$(printf '%s\n' '# Global Instructions' '' '## Code Quality' '' '- Fix the root cause.')"
se
assert_eq "env: no Workflow heading: exit 1" 1 "$RC"
make_home "$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' 'Use the relay.' '' \
    '## Code Quality' '' '- Tick the Quartz card.')"
se
assert_eq "env: Quartz left after the cut: exit 1" 1 "$RC"
assert_contains "env: Quartz left after the cut: refused" "still names hyper-relay or Quartz" "$OUT"
assert_eq "env: Quartz left after the cut: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"

echo '--- superpowers-env: what it will not carry over'
make_home "" '{"mcpServers":{"Quartz":{"command":"quartz"}}}'
se
assert_eq "env: a Quartz MCP server: exit 1" 1 "$RC"
assert_contains "env: a Quartz MCP server: refused" "hold a Quartz server" "$OUT"
make_home
jq '.enabledPlugins["x@nowhere"] = true' "$HOME/.claude/settings.json" > "$HOME/settings.tmp"
mv "$HOME/settings.tmp" "$HOME/.claude/settings.json"
se
assert_eq "env: a marketplace with no source: exit 1" 1 "$RC"
assert_contains "env: a marketplace with no source: refused, naming it" "no source for the marketplace nowhere" "$OUT"
assert_eq "env: a marketplace with no source: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"
se --bogus
assert_eq "env: an option it does not know: exit 1" 1 "$RC"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
```

- [x] **Step 2: Syntax.**

Run: `dash -n tests/benchmark/run-tests.sh`
Expected: silent, exit 0.

- [x] **Step 3: Run it; it fails, because the tools do not exist yet.**

| Run | Expected |
|---|---|
| `sh tests/benchmark/run-tests.sh \| grep -c '^FAIL'` | a number above 0 |
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `<p> passed, <f> failed`, with `<f>` above 0 and `<p> + <f>` = 90 |

If the counts do not add up to 90, a case did not run to its assertions: stop and report the output. (jq prints
"Could not open file" lines while the tools are missing: that is expected.)

- [x] **Step 4: Commit.**

```bash
git add tests/benchmark/run-tests.sh
git commit -m "test: G.2's benchmark suite, written before the tools" -m "tests/benchmark/run-tests.sh drives scripts/benchmark/run-usage.sh on fixture transcripts with a test prices file (a repeated message id counted once, subagent rows from their meta files with a nested one, the role table and its other row, the phase split at the commit times, 5-minute and 1-hour writes priced apart, agent time with turn-end gaps and overlapping agents, the owner's messages, the cost-record cross-check, --sessions) and scripts/benchmark/superpowers-env.sh with a fake home folder and a fake claude that records its calls (a folder that exists refused, the CLAUDE.md cut and its failure checks, the settings edits, a version older than 5.1.0 refused, --neutral). It fails until the tools exist." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s tests/benchmark/run-tests.sh` must print a line starting `100644`.

### Task 2: `run-usage.sh`, `run-usage.jq` and `prices.tsv` (spec §3; P1–P7, P19)

**Files:**
- Create: `scripts/benchmark/prices.tsv`, `scripts/benchmark/run-usage.jq`, `scripts/benchmark/run-usage.sh`
- Test: `tests/benchmark/run-tests.sh`

- [x] **Step 1: The prices.** Run this from the checkout's top (it writes tabs, which the Write tool may not keep):

```sh
mkdir -p scripts/benchmark
{
printf '%s\n' \
    '# Published API prices for run-usage.sh, in US dollars per million tokens.' \
    '# Taken 2026-11-19 from https://platform.claude.com/docs/en/about-claude/pricing (Model pricing).' \
    '# Global routing: a US-only inference_geo costs 1.1x. Web searches ($10 per 1,000) are not here:' \
    '# Claude Code runs them in side calls that no transcript holds.' \
    '# Columns, tab-separated: model; over (the row prices a call whose prompt, its input, cache reads and' \
    '# cache writes together, is over this many tokens; 0 for every call); input; output; cache read;' \
    '# 5-minute cache write; 1-hour cache write.'
printf 'claude-opus-5-5\t0\t4\t20\t0.20\t5\t8\n'
printf 'claude-sonnet-5-5\t0\t2\t10\t0.10\t2.50\t4\n'
printf 'claude-haiku-5-5\t0\t0.10\t0.50\t0.01\t0.125\t0.20\n'
printf 'claude-haiku-5-5\t100000\t0.50\t2.50\t0.05\t0.625\t1\n'
printf 'claude-opus-5\t0\t5\t25\t0.50\t6.25\t10\n'
printf 'claude-sonnet-5\t0\t2\t10\t0.20\t2.50\t4\n'
printf 'claude-haiku-4-5\t0\t1\t5\t0.10\t1.25\t2\n'
} > scripts/benchmark/prices.tsv
```

Check: `awk -F '\t' '!/^#/ && NF { print NF }' scripts/benchmark/prices.tsv | sort -u` prints `7` alone.

- [x] **Step 2: The reader.** Create `scripts/benchmark/run-usage.jq` with exactly this content:

```jq
# run-usage.jq: the transcript reader behind run-usage.sh (hyper-relay G.2; docs/benchmarks/README.md).
# run-usage.sh runs it as `jq -n -r -R -f run-usage.jq <transcripts>`: each input is one line of a Claude
# Code transcript, input_filename names its file, and $ARGS.named holds the rest: "mode" (report or
# sessions) and that mode's arguments, which run-usage.sh names.

# A transcript's time (2026-11-18T05:03:42.217Z) or a run log's (2026-11-18T05:10:12Z), in seconds.
def ts:
    (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)
    + (((capture("\\.(?<f>[0-9]+)Z$") | .f) // "0") | "0." + . | tonumber);

def iso: floor | todate;
def pad2: if . < 10 then "0" + tostring else tostring end;
def hms: floor as $s | "\($s / 3600 | floor)h \(($s % 3600) / 60 | floor | pad2)m \($s % 60 | pad2)s";
def two:
    if . < 0 then "-" + ((0 - .) | two)
    else ((. * 100 + 0.5) | floor) as $c | "\(($c - $c % 100) / 100).\($c % 100 | pad2)" end;
def usd: if . < 0 then "-$" + ((0 - .) | two) else "$" + two end;
def commas:
    tostring as $s | ($s | length) as $n
    | [range(0; $n) | $s[.:. + 1] + (if . < $n - 1 and ($n - . - 1) % 3 == 0 then "," else "" end)]
    | join("");
def cell: tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");

# The text of a message's content: a string, or the text blocks of an array.
def text_of:
    if type == "string" then .
    elif type == "array" then [.[] | select(type == "object" and .type == "text") | .text] | join(" ")
    else "" end;

# One API call: an assistant record with an id and a usage, not a synthetic message. Claude Code writes
# a call once per content block, each time with the same id and usage.
def is_call:
    .type == "assistant" and (.message | type) == "object"
    and (.message.id | type) == "string" and (.message.usage | type) == "object"
    and (.message.model // "") != "<synthetic>";

def usage_of:
    .message.usage as $u | (($u.cache_creation | type) == "object") as $split
    | {in: ($u.input_tokens // 0),
       cw5: (if $split then ($u.cache_creation.ephemeral_5m_input_tokens // 0) else ($u.cache_creation_input_tokens // 0) end),
       cw1: (if $split then ($u.cache_creation.ephemeral_1h_input_tokens // 0) else 0 end),
       cr: ($u.cache_read_input_tokens // 0),
       out: ($u.output_tokens // 0)};

# A record after which its transcript waits on the owner, until its next user or assistant record: an
# assistant message that ends its turn (no tool call pending), an AskUserQuestion call, an interruption.
def waits:
    (.type == "assistant"
        and ((.message.stop_reason // "tool_use") as $s | ($s != "tool_use" and $s != "pause_turn")
            or any(.message.content[]?; type == "object" and .type == "tool_use" and .name == "AskUserQuestion")))
    or (.type == "user" and (.message.content | text_of | startswith("[Request interrupted by user")));

# The owner's own prompt: not a tool result, a harness notice, another session's message or a local command.
def is_owner: .type == "user" and ((.origin | if type == "object" then .kind else null end) == "human");

# What one transcript line gives: a call, a timed record, the owner's prompt, a compaction, or a cost
# record (cost-state, which Claude Code writes with no time).
def events($src):
    fromjson? // empty
    | select(type == "object")
    | if .type == "cost-state" then
        {k: "cost", src: $src, n: input_line_number, total: (.totalCostUSD // 0), models: (.modelUsage // {})}
      elif (.timestamp | type) == "string" then
        (.timestamp | ts) as $t
        | (if is_call then {k: "call", src: $src, id: .message.id, t: $t, model: .message.model} + usage_of else empty end),
          (if .type == "user" or .type == "assistant" then {k: "rec", src: $src, t: $t, wait: waits} else empty end),
          (if is_owner then {k: "owner", src: $src, t: $t} else empty end),
          (if .type == "system" and .subtype == "compact_boundary" then {k: "compact", src: $src, t: $t} else empty end)
      else empty end;

# The length of the union of [start, end] spans.
def union_len:
    sort_by(.[0])
    | reduce .[] as $iv ({cur: null, total: 0};
        if .cur == null then .cur = $iv
        elif $iv[0] <= .cur[1] then .cur[1] = ([.cur[1], $iv[1]] | max)
        else .total += (.cur[1] - .cur[0]) | .cur = $iv end)
    | .total + (if .cur == null then 0 else .cur[1] - .cur[0] end);

# One transcript's working spans: from each record to the next, unless the record leaves it waiting.
def working:
    sort_by(.t) | . as $r
    | [range(0; length - 1) | select($r[.].wait | not) | [$r[.].t, $r[. + 1].t]];

def price_table:
    split("\n")
    | map(select(length > 0 and (startswith("#") | not)) | split("\t")
        | {model: .[0], over: (.[1] | tonumber), input: (.[2] | tonumber), output: (.[3] | tonumber),
           cr: (.[4] | tonumber), cw5: (.[5] | tonumber), cw1: (.[6] | tonumber)});
def price($table):
    (.in + .cw5 + .cw1 + .cr) as $prompt | .model as $m
    | [$table[] | select(.model == $m and (.over == 0 or $prompt > .over))] | max_by(.over);
def cost($table):
    price($table) as $p
    | if $p == null then 0
      else (.in * $p.input + .out * $p.output + .cr * $p.cr + .cw5 * $p.cw5 + .cw1 * $p.cw1) / 1000000 end;
def sums($table):
    {calls: length, in: (map(.in) | add // 0), cw5: (map(.cw5) | add // 0), cw1: (map(.cw1) | add // 0),
     cr: (map(.cr) | add // 0), out: (map(.out) | add // 0), cost: (map(cost($table)) | add // 0)};
def addsums:
    reduce .[] as $s ({calls: 0, in: 0, cw5: 0, cw1: 0, cr: 0, out: 0, cost: 0};
        .calls += $s.calls | .in += $s.in | .cw5 += $s.cw5 | .cw1 += $s.cw1 | .cr += $s.cr
        | .out += $s.out | .cost += $s.cost);
def row($label; $role; $type; $desc):
    "| \($label) | \($role) | \($type) | \($desc | cell) | \(.calls | commas) | \(.in | commas) | \(.cw5 | commas) | \(.cw1 | commas) | \(.cr | commas) | \(.out | commas) | \(.cost | two) |";

# A subagent's role: the first role line whose regex matches "<agentType>: <description>", else other.
def role_for($roles):
    "\(.type): \(.desc)" as $d
    | ([$roles[] | . as $r | select($d | test($r.re)) | $r.role] | first) // "other";

def report:
    $ARGS.named as $a
    | ($a.prices | price_table) as $P
    | {start: ($a.start | ts), spec: ($a.spec | ts), plan: ($a.plan | ts), merge: ($a.merge | ts)} as $w
    | ($a.man | map({key: .file, value: .}) | from_entries) as $byfile
    | ($a.man | map({key: .src, value: .}) | from_entries) as $bysrc
    | [inputs as $line | $byfile[input_filename].src as $src | $line | events($src)] as $ev
    | ([$ev[] | select(.k == "call")] | group_by(.id) | map(min_by(.t))) as $calls
    | ($calls | map(. + {row: (
        if .t < $w.start or .t > $w.merge then "outside"
        elif (.src | startswith("main:") | not) then .src
        elif .t < $w.spec then "main:design"
        elif .t < $w.plan then "main:planning"
        else "main:execution" end)})) as $rowed
    | [$rowed[] | select(.row != "outside")] as $in
    | [$rowed[] | select(.row == "outside")] as $out
    | [(["main:design", "design"], ["main:planning", "planning"], ["main:execution", "execution and review"])
        | .[0] as $r | {label: .[1], s: ([$in[] | select(.row == $r)] | sums($P))}] as $main
    | ([$in[] | select(.row | startswith("agent:"))] | group_by(.row)
        | map(.[0].row as $r
            | {first: (map(.t) | min), s: sums($P)} + ($bysrc[$r] | {agent, type, desc, parent})
            | .role = role_for($a.roles))
        | sort_by(.first)) as $agents
    | (([$ev[] | select(.k == "rec")] | group_by(.src) | map(working) | add // [])
        | map([([.[0], $w.start] | max), ([.[1], $w.merge] | min)] | select(.[1] > .[0]))
        | union_len) as $agent_time
    | ([$ev[] | select(.k == "owner" and (.src | startswith("main:")) and .t >= $w.start and .t <= $w.merge)]
        | length) as $owner
    | ([$ev[] | select(.k == "compact" and .t >= $w.start and .t <= $w.merge)] | length) as $compactions
    | ([$ev[] | select(.k == "cost")] | group_by(.src) | map(max_by(.n))) as $records
    | ([$a.man[] | select(.kind == "main") | .src] - [$records[].src] | map(ltrimstr("main:"))) as $missing
    | ($calls | map(cost($P)) | add // 0) as $own
    | ($records | map(.total) | add // 0) as $rec
    | ($rec - $own) as $gap
    | ($records | map(.models | to_entries[]) | group_by(.key)
        | map({key: .[0].key, value: {cost: (map(.value.costUSD // 0) | add), out: (map(.value.outputTokens // 0) | add)}})
        | from_entries) as $rec_models
    | ($calls | group_by(.model)
        | map({key: .[0].model, value: {cost: (map(cost($P)) | add), out: (map(.out) | add)}})
        | from_entries) as $own_models
    | ([$calls[] | select(price($P) == null) | .model] | group_by(.) | map({model: .[0], n: length})) as $unpriced
    | "# Usage: \($a.title)",
      "",
      "Config `\($a.config)`; sessions \([$a.man[] | select(.kind == "main") | .session] | join(", ")). The run: \($a.start) to \($a.merge) (UTC); spec \($a.spec), plan \($a.plan).",
      "",
      "| Row | Role | Type | Description | Calls | Input | Cache write 5m | Cache write 1h | Cache read | Output | Cost (USD) |",
      "|---|---|---|---|---|---|---|---|---|---|---|",
      ($main[] | . as $m | $m.s | row("main: \($m.label)"; "main"; ""; "")),
      ($agents[] | . as $g | $g.s
        | row("agent \($g.agent)\(if $g.parent then ", under \($g.parent)" else "" end)"; $g.role; $g.type; $g.desc)),
      ([$main[].s] | addsums | row("subtotal: main"; "main"; ""; "3 phases")),
      (reduce $agents[].role as $x ([]; if index([$x]) then . else . + [$x] end)
        | .[] as $r | [$agents[] | select(.role == $r) | .s] | length as $n
        | addsums | row("subtotal: \($r)"; $r; ""; "\($n) agent\(if $n == 1 then "" else "s" end)")),
      ($in | sums($P) | row("total"; ""; ""; "")),
      "",
      "- **Wall clock:** \($w.merge - $w.start | hms), from the run's start to its merge commit",
      "- **Agent time:** \($agent_time | hms), the union of the time some transcript of the run was working",
      "- **Waiting on the owner:** \($w.merge - $w.start - $agent_time | hms), wall clock minus agent time, nights included; never a cost of either workflow",
      "- **The owner's messages:** \($owner)",
      "- **Compactions:** \($compactions) (a compaction's own call is in the cost records, in no transcript)",
      "- **Outside the run:** \($out | length | commas) calls, \($out | sums($P) | .cost | usd), before its start or after its merge; not in the total",
      "- **Cross-check:** the transcripts of these sessions, whole: \($own | usd); the cost records (the last `cost-state` of each session): \($rec | usd); difference \($gap | usd) (\(if $rec > 0 then $gap / $rec * 100 else 0 end | two)% of the cost records). \(if ($missing | length) > 0 then "Incomplete: no cost record in session \($missing | join(", "))." elif $gap >= -0.005 and $gap <= 0.10 * $rec then "Within the tolerance (0 to 10%)." else "OUTSIDE the tolerance (0 to 10%): explain it in the results." end)",
      "- **By model**, cost records / transcripts: \((($rec_models | keys) + ($own_models | keys)) | unique | map(. as $m | "\($m) \($rec_models[$m].cost // 0 | usd), \($rec_models[$m].out // 0 | commas) output / \($own_models[$m].cost // 0 | usd), \($own_models[$m].out // 0 | commas) output") | join("; "))",
      (if ($unpriced | length) > 0
       then "- **Unpriced models** (no row in the prices file; their calls count as $0): \($unpriced | map("\(.model) (\(.n) call\(if .n == 1 then "" else "s" end))") | join(", "))"
       else empty end);

# --sessions: every session file with a timed record in [from, to], with its first and last record and
# the owner's first prompt in it.
def sessions:
    $ARGS.named as $a | ($a.from | ts) as $from | ($a.to | ts) as $to
    | reduce (inputs as $line | input_filename as $f | $line | fromjson? // empty
        | select(type == "object" and (.timestamp | type) == "string")
        | {f: $f, t: (.timestamp | ts), p: (if is_owner then (.message.content | text_of) else null end)}) as $e
        ({}; .[$e.f] |= ((. // {first: $e.t, last: $e.t, win: false, prompt: null, pt: null})
            | .first = ([.first, $e.t] | min) | .last = ([.last, $e.t] | max)
            | .win = (.win or ($e.t >= $from and $e.t <= $to))
            | if .prompt == null and $e.p != null then .prompt = $e.p | .pt = $e.t else . end))
    | [to_entries[] | select(.value.win)] | sort_by(.value.first)
    | if length == 0 then "No session has a record between \($a.from) and \($a.to)."
      else "| Session | Project | First record | Last record | First prompt |",
        "|---|---|---|---|---|",
        (.[] | (.key | split("/")) as $p | .value as $v
          | "| \($p[-1] | rtrimstr(".jsonl")) | \($p[-2]) | \($v.first | iso) | \($v.last | iso) | \(if $v.prompt == null then "(none)" else "\($v.pt | iso) \($v.prompt | gsub("\\s+"; " ") | .[0:80] | cell)" end) |")
      end;

if $ARGS.named.mode == "sessions" then sessions else report end
```

- [x] **Step 3: The script.** Create `scripts/benchmark/run-usage.sh` with exactly this content:

```sh
#!/bin/sh
# run-usage.sh: the tokens, cost and time of one benchmark run, read from Claude Code's transcripts
# (hyper-relay G.2; docs/benchmarks/README.md is the runbook).
#   run-usage.sh <run-log>                          the run's usage table, in Markdown
#   run-usage.sh --sessions <config> <from> <to>    every session with a record in that window
# Times are UTC, written 2026-11-20T14:03:00Z. A run log's header is its "key: value" lines before its
# first "## " heading (docs/benchmarks/run-log-template.md). RUN_USAGE_PRICES names another prices file
# than prices.tsv. The reading itself is run-usage.jq. Needs jq 1.6 or later; reads transcripts and
# writes nothing but a temporary folder. POSIX shell, run by dash.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
PRICES=${RUN_USAGE_PRICES:-$HERE/prices.tsv}
PROG=$HERE/run-usage.jq
USAGE='usage: run-usage.sh <run-log> | run-usage.sh --sessions <config folder> <from> <to>'

die() { printf 'run-usage: %s\n' "$*" >&2; exit 1; }

command -v jq > /dev/null 2>&1 || die "needs jq"
[ -f "$PROG" ] || die "no $PROG"

# is_time <value>: true for a UTC time written 2026-11-20T14:03:00Z.
is_time() {
    case $1 in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) return 0 ;;
    esac
    return 1
}

# expand_home <path>: a leading ~/ becomes the home folder.
expand_home() {
    case $1 in
        "~/"*) printf '%s/%s\n' "$HOME" "${1#"~/"}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

if [ "${1:-}" = --sessions ]; then
    [ $# -eq 4 ] || die "$USAGE"
    CONFIG=$(expand_home "$2")
    FROM=$3
    TO=$4
    is_time "$FROM" || die "not a UTC time like 2026-11-20T14:03:00Z: $FROM"
    is_time "$TO" || die "not a UTC time like 2026-11-20T14:03:00Z: $TO"
    [ -d "$CONFIG/projects" ] || die "no projects folder in $CONFIG"
    set --
    for f in "$CONFIG"/projects/*/*.jsonl; do
        if [ -f "$f" ]; then
            set -- "$@" "$f"
        fi
    done
    [ $# -gt 0 ] || die "no session transcripts under $CONFIG/projects"
    exec jq -n -r -R --arg mode sessions --arg from "$FROM" --arg to "$TO" -f "$PROG" "$@"
fi

[ $# -eq 1 ] || die "$USAGE"
LOG=$1
case $LOG in -*) die "$USAGE" ;; esac
[ -f "$LOG" ] || die "no run log at $LOG"
[ -f "$PRICES" ] || die "no prices file at $PRICES"

# field <key>: each value of the run log's "key: value" lines, before its first "## " heading.
field() {
    awk -v k="$1: " '/^## / { exit } index($0, k) == 1 { print substr($0, length(k) + 1) }' "$LOG"
}

# one <key>: the key's one value; a missing or repeated key stops the run.
one() {
    v=$(field "$1")
    [ -n "$v" ] || die "the run log has no '$1:' line"
    [ "$(printf '%s\n' "$v" | wc -l)" -eq 1 ] || die "the run log has more than one '$1:' line"
    printf '%s\n' "$v"
}

TITLE=$(awk 'NR == 1 && /^# / { sub(/^# /, ""); print }' "$LOG")
[ -n "$TITLE" ] || TITLE=$(basename "$LOG")
CONFIG_RAW=$(one config)
CONFIG=$(expand_home "$CONFIG_RAW")
START=$(one start)
SPEC_LINE=$(one spec)
PLAN_LINE=$(one plan)
MERGE_LINE=$(one merge)
SPEC_T=${SPEC_LINE##* }
PLAN_T=${PLAN_LINE##* }
MERGE_T=${MERGE_LINE##* }
for t in "$START" "$SPEC_T" "$PLAN_T" "$MERGE_T"; do
    is_time "$t" || die "not a UTC time like 2026-11-20T14:03:00Z: $t (the start, spec, plan and merge lines end with one)"
done
awk -v a="$START" -v b="$SPEC_T" -v c="$PLAN_T" -v d="$MERGE_T" 'BEGIN { exit !(a <= b && b <= c && c <= d) }' \
    || die "the times must run start <= spec <= plan <= merge"
[ -d "$CONFIG/projects" ] || die "no projects folder in $CONFIG"
SESSIONS=$(field session | awk '!seen[$0]++')
[ -n "$SESSIONS" ] || die "the run log has no 'session:' line"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

# The role table: "<extended regex> → <role>" lines.
field role > "$TMP/roles"
while IFS= read -r line; do
    case $line in
        *" → "*) ;;
        *) die "a role line needs '<regex> → <role>': $line" ;;
    esac
done < "$TMP/roles"
ROLES=$(jq -R -s -c 'split("\n") | map(select(length > 0) | split(" → ") | {re: .[0], role: (.[1:] | join(" → "))})' "$TMP/roles")

# The manifest: each session's transcript, and its subagents' with their meta files.
: > "$TMP/manifest"
set --
for id in $SESSIONS; do
    main=
    for f in "$CONFIG"/projects/*/"$id".jsonl; do
        if [ -f "$f" ]; then
            [ -z "$main" ] || die "session $id has a transcript in more than one project folder"
            main=$f
        fi
    done
    [ -n "$main" ] || die "no transcript for session $id under $CONFIG/projects"
    jq -n -c --arg file "$main" --arg id "$id" \
        '{file: $file, src: ("main:" + $id), kind: "main", session: $id}' >> "$TMP/manifest"
    set -- "$@" "$main"
    for f in "${main%.jsonl}"/subagents/agent-*.jsonl; do
        if [ -f "$f" ]; then
            agent=${f##*/agent-}
            agent=${agent%.jsonl}
            meta=${f%.jsonl}.meta.json
            if [ -f "$meta" ]; then
                jq -c --arg file "$f" --arg id "$id" --arg agent "$agent" \
                    '{file: $file, src: ("agent:" + $agent), kind: "agent", session: $id, agent: $agent,
                      type: (.agentType // "?"), desc: (.description // "?"), parent: (.parentAgentId // null)}' \
                    "$meta" >> "$TMP/manifest"
            else
                jq -n -c --arg file "$f" --arg id "$id" --arg agent "$agent" \
                    '{file: $file, src: ("agent:" + $agent), kind: "agent", session: $id, agent: $agent,
                      type: "?", desc: "?", parent: null}' >> "$TMP/manifest"
            fi
            set -- "$@" "$f"
        fi
    done
done
MAN=$(jq -s -c . "$TMP/manifest")

jq -n -r -R --arg mode report --arg title "$TITLE" --arg config "$CONFIG_RAW" \
    --arg start "$START" --arg spec "$SPEC_T" --arg plan "$PLAN_T" --arg merge "$MERGE_T" \
    --arg prices "$(cat "$PRICES")" --argjson roles "$ROLES" --argjson man "$MAN" \
    -f "$PROG" "$@"
```

- [x] **Step 4: Mode and syntax.**

| Run | Expected |
|---|---|
| `chmod +x scripts/benchmark/run-usage.sh` | silent |
| `dash -n scripts/benchmark/run-usage.sh` | silent, exit 0 |

- [x] **Step 5: The usage tool's half of the suite passes.** (`superpowers-env.sh` comes in Task 3, so the `env:`
  assertions still fail.)

| Run | Expected |
|---|---|
| `sh tests/benchmark/run-tests.sh \| grep -c -E '^ok   (prices\|usage\|sessions):'` | `46` |
| `sh tests/benchmark/run-tests.sh \| grep -E '^FAIL (prices\|usage\|sessions):'` | nothing |

A failure here is a bug in `run-usage.sh` or `run-usage.jq` (a jq syntax error shows as `jq: error: … compile error`):
fix the code, never the suite.

- [x] **Step 6: Commit.**

```bash
git add scripts/benchmark/prices.tsv scripts/benchmark/run-usage.jq scripts/benchmark/run-usage.sh
git commit -m "feat: run-usage.sh, a benchmark run's tokens, cost and time from Claude Code's transcripts" -m "run-usage.sh reads a run log's header (config folder, sessions, start, spec, plan and merge times, role lines), finds each session's transcript and its subagents' with their meta files, nested ones included, and run-usage.jq counts each API call once by message.id, prices it from prices.tsv (Anthropic's prices of 2026-11-19, 5-minute and 1-hour writes apart, Haiku 5.5's long-prompt tier), splits the main session into design, planning, and execution and review at the commit times, gives a row and a role to each subagent (other when no line matches), sums per role, and adds wall clock, agent time (turn-end waits left out, overlapping agents counted once), the owner's messages, compactions, the calls outside the run, and a cross-check of the whole sessions against their last cost-state record (0 to 10%), by model. --sessions lists the sessions in a time window with their first prompts." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s scripts/benchmark` must print `100644` for `prices.tsv` and `run-usage.jq`, `100755` for
`run-usage.sh`.

### Task 3: `superpowers-env.sh` (spec §2; P8, P16, P17)

**Files:**
- Create: `scripts/benchmark/superpowers-env.sh`
- Test: `tests/benchmark/run-tests.sh`

- [x] **Step 1: Write the script.** Create `scripts/benchmark/superpowers-env.sh` with exactly this content:

```sh
#!/bin/sh
# superpowers-env.sh: builds a separate Claude Code config folder for G.2's superpowers baseline
# (docs/benchmarks/README.md, step 1). It refuses a folder that exists, and it only reads ~/.claude and
# ~/.claude.json.
#   superpowers-env.sh [<folder>]             ~/.claude-superpowers: the owner's setup without hyper-relay
#                                             or Quartz, plus upstream superpowers 5.1.0 or later
#   superpowers-env.sh --neutral [<folder>]   ~/.claude-neutral: the same with neither workflow, for the
#                                             blind review and the other headless steps
# Linked from ~/.claude, so nothing drifts: skills, agents, commands, rules, hooks, bin. Copied, then
# changed: settings.json (hyper-relay@hyper-relay and its marketplace out, `quartz hook flush` out of
# Stop and SubagentStop), CLAUDE.md (everything from "## Workflow: the relay" up to "## Code Quality"
# cut), and only the mcpServers block of ~/.claude.json. No projects/, so no auto-memory. Then, with
# CLAUDE_CONFIG_DIR set to the folder: the marketplaces and plugins the settings enable, and superpowers.
# Every check runs before the folder is created. Needs jq, and claude on PATH. POSIX shell, run by dash.
set -eu
umask 077

USAGE='usage: superpowers-env.sh [--neutral] [<folder>]'
SRC=$HOME/.claude
MIN_VERSION=5.1.0
SP_MARKETPLACE=obra/superpowers-marketplace
SP_ID=superpowers@superpowers-marketplace
OFFICIAL=claude-plugins-official
OFFICIAL_SOURCE=anthropics/claude-plugins-official

die() { printf 'superpowers-env: %s\n' "$*" >&2; exit 1; }
say() { printf 'superpowers-env: %s\n' "$*"; }

# version_ge <a> <b>: true when the dotted version a is b or later, compared number by number.
version_ge() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, x, "."); nb = split(b, y, ".")
        n = na > nb ? na : nb
        for (i = 1; i <= n; i++) {
            if (x[i] + 0 > y[i] + 0) exit 0
            if (x[i] + 0 < y[i] + 0) exit 1
        }
        exit 0
    }'
}

NEUTRAL=0
if [ "${1:-}" = --neutral ]; then
    NEUTRAL=1
    shift
fi
[ $# -le 1 ] || die "$USAGE"
case ${1:-} in -*) die "$USAGE" ;; esac
if [ $# -eq 1 ]; then
    TARGET=$1
elif [ "$NEUTRAL" -eq 1 ]; then
    TARGET=$HOME/.claude-neutral
else
    TARGET=$HOME/.claude-superpowers
fi
case $TARGET in /*) ;; *) TARGET=$(pwd)/$TARGET ;; esac

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    die "$TARGET already exists: remove it first, or name another folder"
fi
command -v jq > /dev/null 2>&1 || die "needs jq"
command -v claude > /dev/null 2>&1 || die "needs claude on PATH"
[ -f "$SRC/settings.json" ] || die "no $SRC/settings.json"
[ -f "$SRC/CLAUDE.md" ] || die "no $SRC/CLAUDE.md"
[ -f "$HOME/.claude.json" ] || die "no $HOME/.claude.json"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# CLAUDE.md without the relay's section: from "## Workflow: the relay" up to "## Code Quality".
if ! awk '
    $0 == "## Workflow: the relay" && !seen_start { cut = 1; seen_start = 1; next }
    cut && $0 == "## Code Quality" { cut = 0; seen_end = 1 }
    !cut { print }
    END { exit !(seen_start && seen_end) }
' "$SRC/CLAUDE.md" > "$WORK/CLAUDE.md"; then
    die "$SRC/CLAUDE.md has no '## Workflow: the relay' heading with '## Code Quality' after it: it changed shape, so nothing is cut by guesswork"
fi
if grep -n -e hyper-relay -e Quartz "$WORK/CLAUDE.md" >&2; then
    die "the cut CLAUDE.md still names hyper-relay or Quartz (the lines above): it changed shape, so nothing is cut by guesswork"
fi

# settings.json without hyper-relay, its marketplace, or the Quartz flush in Stop and SubagentStop.
if ! jq '
    del(.enabledPlugins["hyper-relay@hyper-relay"])
    | del(.extraKnownMarketplaces["hyper-relay"])
    | if (.hooks | type) == "object" then
        .hooks |= (with_entries(
            if .key == "Stop" or .key == "SubagentStop" then
                .value |= (map(.hooks = ((.hooks // []) | map(select((.command // "") | contains("quartz hook flush") | not))))
                           | map(select((.hooks | length) > 0)))
            else . end)
          | with_entries(select((.value | length) > 0)))
      else . end
' "$SRC/settings.json" > "$WORK/settings.json"; then
    die "cannot read $SRC/settings.json as JSON"
fi

# Only the MCP servers of ~/.claude.json: never the login, the history or the projects.
if ! jq '{mcpServers: (.mcpServers // {})}' "$HOME/.claude.json" > "$WORK/claude.json"; then
    die "cannot read $HOME/.claude.json as JSON"
fi
if jq -e '.mcpServers | keys | map(ascii_downcase) | any(contains("quartz"))' "$WORK/claude.json" > /dev/null; then
    die "the mcpServers of $HOME/.claude.json hold a Quartz server: the board must stay out of the run"
fi

# The plugins the settings enable, and the source of each one's marketplace.
jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$WORK/settings.json" > "$WORK/plugins"
: > "$WORK/marketplaces"
while IFS= read -r id; do
    market=${id##*@}
    if [ "$market" = "$OFFICIAL" ]; then
        msource=$OFFICIAL_SOURCE
    else
        msource=$(jq -r --arg m "$market" '.extraKnownMarketplaces[$m].source // empty
            | if .source == "github" then (.repo // empty) elif .source == "git" then (.url // empty) else empty end' \
            "$WORK/settings.json")
    fi
    [ -n "$msource" ] || die "no source for the marketplace $market of $id in settings.json's extraKnownMarketplaces"
    grep -q -x -F "$msource" "$WORK/marketplaces" || printf '%s\n' "$msource" >> "$WORK/marketplaces"
done < "$WORK/plugins"

# Every check passed: build the folder.
mkdir -- "$TARGET" || die "cannot create $TARGET"
for name in skills agents commands rules hooks bin; do
    if [ -e "$SRC/$name" ]; then
        ln -s -- "$SRC/$name" "$TARGET/$name"
        say "linked $name -> $SRC/$name"
    else
        say "skipped $name: there is no $SRC/$name"
    fi
done
cp -- "$WORK/settings.json" "$TARGET/settings.json"
cp -- "$WORK/CLAUDE.md" "$TARGET/CLAUDE.md"
cp -- "$WORK/claude.json" "$TARGET/.claude.json"
say "settings.json: hyper-relay@hyper-relay and its marketplace dropped, quartz hook flush out of Stop and SubagentStop"
say "CLAUDE.md: the relay's section cut"
say ".claude.json: the mcpServers block only ($(jq -r '.mcpServers | keys | join(", ")' "$TARGET/.claude.json"))"

CLAUDE_CONFIG_DIR=$TARGET
export CLAUDE_CONFIG_DIR
half_built() { die "$1 failed: $TARGET is left half-built; remove it, then run this again"; }
while IFS= read -r m; do
    say "claude plugin marketplace add $m"
    claude plugin marketplace add "$m" < /dev/null || half_built "claude plugin marketplace add $m"
done < "$WORK/marketplaces"
while IFS= read -r id; do
    say "claude plugin install $id"
    claude plugin install "$id" < /dev/null || half_built "claude plugin install $id"
done < "$WORK/plugins"

if [ "$NEUTRAL" -eq 1 ]; then
    say "built $TARGET, with neither workflow"
else
    say "claude plugin marketplace add $SP_MARKETPLACE"
    claude plugin marketplace add "$SP_MARKETPLACE" < /dev/null || half_built "claude plugin marketplace add $SP_MARKETPLACE"
    say "claude plugin install $SP_ID"
    claude plugin install "$SP_ID" < /dev/null || half_built "claude plugin install $SP_ID"
    claude plugin list --json < /dev/null > "$WORK/list.json" || half_built "claude plugin list --json"
    path=$(jq -r --arg id "$SP_ID" '[.[] | select(.id == $id) | .installPath] | first // empty' "$WORK/list.json") \
        || half_built "reading claude plugin list --json"
    [ -n "$path" ] && [ -f "$path/.claude-plugin/plugin.json" ] \
        || die "claude plugin list --json gives no installPath holding .claude-plugin/plugin.json for $SP_ID"
    version=$(jq -r '.version // empty' "$path/.claude-plugin/plugin.json")
    [ -n "$version" ] || die "$path/.claude-plugin/plugin.json has no version"
    version_ge "$version" "$MIN_VERSION" \
        || die "superpowers $version is older than $MIN_VERSION, the version hyper-relay forked from: not a fair baseline; remove $TARGET"
    say "superpowers $version, read from $path/.claude-plugin/plugin.json: record it in C.2's run log"
    say "built $TARGET"
fi
say "next (the owner): from a scratch folder, CLAUDE_CONFIG_DIR=$TARGET claude, then /login and the checks of docs/benchmarks/README.md, step 1"
```

- [x] **Step 2: Mode and syntax.**

| Run | Expected |
|---|---|
| `chmod +x scripts/benchmark/superpowers-env.sh` | silent |
| `dash -n scripts/benchmark/superpowers-env.sh` | silent, exit 0 |

- [x] **Step 3: The suite passes.**

Run: `sh tests/benchmark/run-tests.sh | tail -n 1`
Expected: `90 passed, 0 failed`

- [x] **Step 4: What the script never does.** Each must print nothing:

| Run | Expected |
|---|---|
| `grep -n -e 'rm -r' -e 'rm -f' -e '> "\$SRC' -e '>> "\$SRC' -e '> "\$HOME/.claude' scripts/benchmark/superpowers-env.sh \| grep -v -F "trap 'rm -rf \"\$WORK\"'"` | nothing: the only removal is its own temporary folder, and it never writes `~/.claude` or `~/.claude.json` |
| `grep -n -i -w -e sat -e pentraze scripts/benchmark/superpowers-env.sh scripts/benchmark/run-usage.sh scripts/benchmark/run-usage.jq tests/benchmark/run-tests.sh` | nothing |

- [x] **Step 5: Commit.**

```bash
git add scripts/benchmark/superpowers-env.sh
git commit -m "feat: superpowers-env.sh, a config folder for G.2's upstream superpowers run" -m "superpowers-env.sh builds ~/.claude-superpowers, or with --neutral ~/.claude-neutral, and refuses a folder that exists. It checks everything first: CLAUDE.md with its '## Workflow: the relay' section cut up to '## Code Quality' (it refuses when a heading is missing or hyper-relay or Quartz is left), settings.json without hyper-relay@hyper-relay, its marketplace or the quartz hook flush in Stop and SubagentStop, only the mcpServers block of ~/.claude.json (no Quartz server), and a source for each enabled plugin's marketplace. Then it links skills, agents, commands, rules, hooks and bin, copies the three files, and with CLAUDE_CONFIG_DIR set installs the enabled plugins and, unless --neutral, superpowers from obra/superpowers-marketplace, refusing a version older than 5.1.0." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s scripts/benchmark/superpowers-env.sh` must print a line starting `100755`.

### Task 4: The fixed prompts and the run-log template (spec §1, §4; P9, P10, P12, P19)

**Files:**
- Create: `docs/benchmarks/run-log-template.md`, `docs/benchmarks/pitfall-brief.md`, `docs/benchmarks/restate-prompt.md`,
  `docs/benchmarks/blind-review-prompt.md`, `docs/benchmarks/verify-prompt.md`, `docs/benchmarks/catches-prompt.md`,
  `docs/benchmarks/pitfall-check-prompt.md`

- [x] **Step 1: The run-log template.** Create `docs/benchmarks/run-log-template.md` with exactly this content:

````markdown
# Run log: <C.1 or C.2>, <the card's title>

<!--
The "key: value" lines below, up to the first "## " heading, are the header scripts/benchmark/run-usage.sh
reads; keep every line you fill in that form. Times are UTC, written 2026-11-20T14:03:00Z: a commit's
time as `TZ=UTC git -C <repo> log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h %cd' <commit>`
prints it, and the start as `run-usage.sh --sessions` prints the run's first prompt. Add one "session:"
line per session of the run. A "role:" line is "<extended regex> → <role>", matched against
"<agentType>: <description>" of each subagent; the first match wins, and a subagent no line matches is
reported as "other". "spec:", "plan:" and "merge:" are "<short hash> <time>", with "-" for the hash when
a workflow never commits one. During the runs this file lives in ~/sat-benchmark/, outside both repos.
-->

workflow: <hyper-relay x.y.z | superpowers x.y.z>
card: <title> (<card id>)
config: <~/.claude | ~/.claude-superpowers>
start-commit: <short hash of SAT's main when the run started>
session: <session id>
start: <time of the owner's first message>
spec: <short hash> <time>
plan: <short hash> <time>
merge: <short hash> <time>
pitfalls-sha256: <the sha256 of ~/sat-benchmark/pitfalls.md>
role: <extended regex> → <role>

## Roles

<Why each role line is there, and why any "other" row left in the usage table is not a role.>

## The owner's click-through

<Every defect the owner finds, from the first click-through on, as it is found.>

| # | Found (UTC) | Defect, one line | Severity (Critical / Important / Minor) | Fixed in |
|---|---|---|---|---|

## In-process catches

<Filled at scoring from the catch counter's list, as the owner confirmed it.>

| # | Reviewer (role) | Finding, one line | Outcome (fixed / dropped / disputed) |
|---|---|---|---|

## Notes

<Anything that ran differently from docs/benchmarks/README.md: where a workflow put its spec and plan, a
Quartz call the superpowers run made, a session resumed after a break, a compaction.>
````

- [x] **Step 2: The pitfall writer's brief.** Create `docs/benchmarks/pitfall-brief.md` with exactly this content:

````markdown
# Sealed pitfall list: the writer's brief

<!-- Fixed before either run starts. README.md in this folder, step 2, pipes this file and the two cards
to one headless session in the product's main checkout; nothing else goes into its prompt. -->

You are writing a sealed checklist. Two features of the product in your working directory will be built
after you finish, and your list will be used to check the merged code of each. Nobody reads it before
then, so write it for a checker who will have only the merged code and this list.

## What to read

- `CLAUDE.md` at the top of the working directory: the product's rules and conventions.
- The two feature cards at the end of this prompt, C.1 and C.2.
- The code of the notifications foundation both features build on: its registry, its `Publish` path and
  the inbox (what the pieces called Notifications A and Notifications B added). Find it with `grep`.

Read nothing else: not `docs/`, not git history, not another project. Do not run the app or its tests.

## What to write

For each feature, 6 to 10 pitfalls: mistakes a careful engineer could still make building that feature on
this foundation. For example: a recipient set that is too wide or too narrow, an event published twice or
not at all, a permission not checked, a tenant boundary crossed, a path the card names that no test
covers. Prefer what would matter to a user over matters of style.

Each pitfall is one yes/no check on the merged code, phrased so that **yes means the pitfall was
avoided**, with how to check it: a file to read, a `grep` to run, or a test to read. A checker must be
able to answer it without asking anyone.

Use exactly this form:

    # Sealed pitfalls

    ## C.1: <the card's title>

    1. **<the check, as a yes/no question>**
       How to check: <a file, a grep, or a test>.
       Yes when: <what the checker must see>.

    ## C.2: <the card's title>

    1. ...

## Where to save it

Write the list to `~/sat-benchmark/pitfalls.md` (with your home folder's full path) and nowhere else. Then
run `sha256sum` on it.

## What to report

Only two things: the file's path and the `sha256sum` line. Do not quote, summarize or count the pitfalls in
your reply: whoever reads it must not learn them before the scoring.

## The cards
````

- [x] **Step 3: The restating prompt.** Create `docs/benchmarks/restate-prompt.md` with exactly this content:

````markdown
# Requirements lists: the restating prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, pipes this file and the two
design documents' paths to one headless session, once, for both features. -->

Two design documents are named at the end of this prompt, one per feature. Each was written in its own
style, and that style must not reach the reviewer who will check the code against it. Restate each one as
a plain requirements list.

For each document:

- List every requirement a reviewer could check in the code: the behaviour, who it affects, when it
  happens, what is stored or sent, permissions, limits, errors and edge cases, and what the document puts
  out of scope.
- One requirement per numbered line, in plain present-tense sentences ("An approver receives ...").
  Keep the document's facts and drop everything else.
- Leave out how the work was organized: no plans, tasks, steps, phases, reviews, reviewers, agents,
  commits, branches, cards, boards, tools or process names, and no paths of documents. Do not quote the
  document, and do not copy its headings, numbering, tables or decision labels.
- Use the same plain style and the same order for both (behaviour, then data, then permissions, then
  errors and edge cases, then out of scope), so the two lists read alike.

Write them to `~/sat-benchmark/blind/requirements-c1.md` and `~/sat-benchmark/blind/requirements-c2.md`
(with your home folder's full path), each headed `# Requirements: <the feature, in plain words>`, and
nowhere else. Report only the two paths.

## The documents
````

- [x] **Step 4: The blind review prompt.** Create `docs/benchmarks/blind-review-prompt.md` with exactly this content:

````markdown
# The blind review

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <START> and <REQUIREMENTS>
and pipes this file to one headless session per feature, in a detached worktree at the feature's merge
commit. -->

You are reviewing one finished feature in the repository in your working directory, for defects that
reached its merged code. Review only the code change, against the requirements list.

**The change:** `git diff <START>..HEAD -- api web mailer-worker`. Read the changed files in full where you
need their context.

**The requirements:** `<REQUIREMENTS>`.

**Rules.**

- Do not read git history: no `git log`, `git show`, `git blame` or `git reflog`, and no commit messages.
  Do not read `docs/`, and read nothing outside this working directory except the requirements file.
- Do not run the app, its tests, a build or a container: read the code.
- Do not edit anything.

**What to look for:** a requirement not met, or met wrongly; a bug (a wrong condition, a missed case, a
race, an event sent twice or not at all); a permission or tenant-boundary hole; data reaching the wrong
person; an error swallowed; a path the requirements name that no test covers. Not style, not naming, not
suggestions.

**Grades.**

- **Critical:** a requirement is broken, data leaks or is lost, or there is a security hole.
- **Important:** a real defect a user or an operator would hit, or a requirement no test covers.
- **Minor:** anything else worth noting.

**Report** one entry per finding, worst first:

    ### <n>. <one-line title>
    Grade: <Critical | Important | Minor>
    Where: <file:line>
    Requirement: <its number in the requirements list, or "none">
    What is wrong: <what happens, and when>
    Evidence: <the lines of code, quoted, and the reasoning>

End with one line: `Findings: <c> Critical, <i> Important, <m> Minor`.
````

- [x] **Step 5: The verification prompt.** Create `docs/benchmarks/verify-prompt.md` with exactly this content:

````markdown
# The blind review's second pass

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <START> and <REQUIREMENTS>,
appends one feature's blind review below this file, and pipes both to a fresh headless session in the
same detached worktree. -->

Below is a code review of the change `git diff <START>..HEAD -- api web mailer-worker` in the repository in
your working directory, checked against `<REQUIREMENTS>`. Reviews make mistakes both ways. Check every
finding against the code itself, one by one.

For each finding:

- Read the code it names, and whatever decides whether it is true: its callers, its tests, the
  requirement it cites.
- Decide **CONFIRMED** (the defect is real and reachable in the merged code) or **REFUTED** (it is not:
  the case is handled elsewhere, the path cannot be reached, or the requirement does not ask for it).
  Unsure is REFUTED, with what would settle it.
- Give the grade it deserves, which may be lower than the review's, by the same definitions: Critical (a
  requirement broken, data leaked or lost, a security hole), Important (a real defect a user or an
  operator would hit, or a requirement no test covers), Minor (the rest).

The review's rules hold for you too: no git history (`git log`, `git show`, `git blame`, `git reflog`), no
`docs/`, nothing outside this working directory but the requirements file, nothing run, nothing edited.

**Report** one line per finding, in the review's order:

    <n>. CONFIRMED | REFUTED, <grade>: <one-line title>. Evidence: <file:line and the fact that decides it>.

End with one line: `Confirmed: <c> Critical, <i> Important, <m> Minor`. Only confirmed Critical and
Important findings count as escaped defects.

## The review
````

- [x] **Step 6: The catch counter's prompt.** Create `docs/benchmarks/catches-prompt.md` with exactly this content:

````markdown
# In-process catches: the counter's prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, pipes this file and the list of
both runs' transcripts to one headless session. The owner checks its list. -->

Two runs built one feature each, one through hyper-relay's relay and one through upstream superpowers. In
each, reviewers checked the work before it merged. List every finding those reviewers raised and what
became of it. Do not judge the findings: count them.

**The input** at the end of this prompt lists transcript files, one per line: `<run> <role> <path>`. The
reviewer roles are the relay's `acceptance reviewer` and `code reviewer`, and superpowers' per-task
reviewers (`task reviewer`, or `spec reviewer` and `quality reviewer`) and `final reviewer`. The other lines
(`main`, `executor`, `implementer`) are where you find the outcomes.

Transcripts are JSON Lines and large: never read one whole. Print the text of its assistant messages with

    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' <path>

and search that output with `grep -n`.

**What counts as a finding:**

- The relay: each acceptance step a reviewer marked FAIL or NEEDS-HUMAN, and each issue of a code review
  (Critical, Important or Minor).
- Superpowers: each issue a per-task review raised, whatever it calls the review (spec compliance,
  quality, or both at once), and each issue of the final review of the whole branch.
- Not a finding: an executor's or implementer's own failing test on its way to green (test-driven
  development's red step), praise, or a passing check.

A finding raised again in a later round is one finding, not two.

**The outcome** of each: **fixed** (a later commit or report shows the change), **dropped** (the main
session or the owner decided not to act, or nobody acted on it), or **disputed** (someone argued it was
wrong, and it was not fixed). Quote where the outcome shows.

**Report** one table per run:

    ## <run>
    | # | Reviewer (role, agent id) | Task or step | Finding, one line | Severity as given | Outcome | Where the outcome shows |
    |---|---|---|---|---|---|---|

Then one line per run: `<run>: <n> findings: <f> fixed, <d> dropped, <x> disputed`.

## The transcripts
````

- [x] **Step 7: The pitfall checker's prompt.** Create `docs/benchmarks/pitfall-check-prompt.md` with exactly this content:

````markdown
# Sealed pitfall list: the checker's prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <C1_MERGE> and <C2_MERGE>,
appends the sealed list below this file, and pipes both to one headless session in the product's main
checkout, after both features have merged. The owner confirms its answers. -->

Below is a checklist written before two features were built: section C.1's checks are for the first
feature, section C.2's for the second. Check every item on the merged code of its own feature: C.1's at
commit `<C1_MERGE>`, C.2's at commit `<C2_MERGE>`. Read a file at a commit with `git show <commit>:<path>`
and search with `git grep <pattern> <commit> -- <paths>`. Where an item says to run a test, read the test
and the code instead: do not run tests, builds or the app, and do not edit anything.

For each item answer **yes** (the pitfall was avoided), **no** (it was not) or **unclear**, with the
evidence: the file and lines, or the search and what it found.

**Report** one table per feature:

    ## C.1
    | # | Check | Answer | Evidence |
    |---|---|---|---|

Then one line per feature: `<feature>: <y> yes, <n> no, <u> unclear`.

## The checklist
````

- [x] **Step 8: Check the prompts.**

| Run | Expected |
|---|---|
| `grep -n -i -E 'relay\|superpowers\|hyper\|quartz' docs/benchmarks/pitfall-brief.md docs/benchmarks/restate-prompt.md docs/benchmarks/blind-review-prompt.md docs/benchmarks/verify-prompt.md docs/benchmarks/pitfall-check-prompt.md` | nothing: the prompts a blind step reads name neither workflow |
| `grep -c -F -e '<START>' -e '<REQUIREMENTS>' docs/benchmarks/blind-review-prompt.md docs/benchmarks/verify-prompt.md` | each file at least `2` |
| `grep -c -F -e '<C1_MERGE>' -e '<C2_MERGE>' docs/benchmarks/pitfall-check-prompt.md` | at least `2` |
| `grep -c -F ' → ' docs/benchmarks/run-log-template.md` | at least `2` (the comment and the `role:` line) |

- [x] **Step 9: Commit.**

```bash
git add docs/benchmarks/run-log-template.md docs/benchmarks/pitfall-brief.md docs/benchmarks/restate-prompt.md docs/benchmarks/blind-review-prompt.md docs/benchmarks/verify-prompt.md docs/benchmarks/catches-prompt.md docs/benchmarks/pitfall-check-prompt.md
git commit -m "docs: G.2's fixed prompts and run-log template" -m "docs/benchmarks/ gains the run-log template (the header run-usage.sh reads, the click-through defects, the in-process catches), the sealed pitfall list's brief and its checker's prompt, the prompt that restates both specs as plain requirements lists, the blind review and its verification pass, and the catch counter's prompt. The prompts a blind step reads name neither workflow." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: The runbook, `docs/benchmarks/README.md` (spec §1, §2, §4, §5; P12–P17)

**Files:**
- Create: `docs/benchmarks/README.md`

- [ ] **Step 1: Write the runbook.** Create `docs/benchmarks/README.md` with exactly this content:

````markdown
# G.2: a superpowers baseline on SAT

hyper-relay's README is to compare its relay with upstream superpowers on measured usage. This folder fixes
how that is measured, before either run starts (spec:
`docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md`). One SAT feature, C.1, is
built with hyper-relay's relay; a comparable one, C.2, with upstream superpowers' full workflow. The two are
compared on tokens, time and escaped defects. Nothing is built twice.

| File | What it is |
|---|---|
| `run-log-template.md` | One run's log; its header is what `run-usage.sh` reads |
| `pitfall-brief.md` | The brief of the agent that writes the sealed pitfall list (step 2) |
| `restate-prompt.md` | Restates both specs as plain requirements lists (step 6) |
| `blind-review-prompt.md` | The blind review of one feature's code (step 6) |
| `verify-prompt.md` | Its second pass, which confirms or refutes each finding (step 6) |
| `catches-prompt.md` | Lists both runs' in-process catches (step 6) |
| `pitfall-check-prompt.md` | Checks the sealed list on both merged features (step 6) |

The tools are in `scripts/benchmark/`: `superpowers-env.sh` builds the two config folders, and `run-usage.sh`
turns a run log into a usage table (`run-usage.sh --sessions` finds a run's sessions).

## The rules of both runs

- **No run is told it is being measured.** Nothing about this benchmark goes where a run's agents read: not
  SAT's `CLAUDE.md`, not SAT's auto-memory, not C.1's card. The run logs, the pitfall list and every other
  file of the benchmark stay in `~/sat-benchmark/`, outside both repos.
- **The same conditions.** An Opus 5.5 main session at the owner's usual effort (both config folders share
  the owner's `settings.json`, so change it in neither). Each run starts in a fresh session, and the session
  that brainstormed G.2 runs neither. Nothing else runs on SAT while a run is going: the time would blur,
  and SAT's web suite must never run twice at once.
- **The owner answers what the workflow asks, as usual,** and volunteers no requirement they would
  otherwise leave out.
- **The same bar to finish:** `make merge`'s gates pass and the owner's click-through passes. The owner
  merges with `make merge` in both runs. Fixes after a failed click-through count inside the run.
- **Transcripts expire.** Claude Code deletes transcripts older than `cleanupPeriodDays`, 30 days by
  default. Run `run-usage.sh` on a run's log as soon as it merges, keep its output beside the log, and
  finish scoring within 30 days of C.1's start.

## Paths

Every command below runs in the owner's own terminal, after these three lines. Set `SAT` to the path of SAT's main
checkout first (`export SAT=<its path>`): this repo names no path for it, and the second line stops when it is unset.

```sh
HR=~/hyper-relay           # this repo's main checkout, on main
SAT=${SAT:?set SAT to the path of the SAT main checkout first}
BENCH=~/sat-benchmark      # outside both repos
```

A commit's time goes into a log in UTC, as this prints it:

```sh
TZ=UTC git -C "$SAT" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h %cd' <commit>
```

## 1. The config folders

Build both on the day C.1 starts, so both runs start under the same day's environment:

```sh
"$HR/scripts/benchmark/superpowers-env.sh"
"$HR/scripts/benchmark/superpowers-env.sh" --neutral
```

Each prints what it linked, copied, changed and installed; the first also prints the superpowers version it
installed (5.1.0 or later), for C.2's log. A folder that exists is refused: if they were built earlier (at
G.2's acceptance) and `~/.claude/settings.json`, `~/.claude/CLAUDE.md` or the MCP servers of `~/.claude.json`
have changed since, move both aside (`mv ~/.claude-superpowers ~/.claude-superpowers.old`, the same for
`~/.claude-neutral`) and build them again.

Then log in to each and check it, from a scratch folder, so nothing about SAT lands in either:

```sh
mkdir -p /tmp/g2-check && cd /tmp/g2-check
CLAUDE_CONFIG_DIR=~/.claude-superpowers claude
```

In that session: `/login`; `/plugin` lists superpowers, frontend-design, gopls-lsp and ui-ux-pro-max as
installed, and no hyper-relay; typing `/` offers `superpowers:` skills and no `hyper-relay:` one; `/mcp`
lists codebase-memory-mcp, context7 and playwright, and no Quartz; `/memory` shows no auto-memory notes.
Then `/exit`, and the same with `CLAUDE_CONFIG_DIR=~/.claude-neutral claude`, which has neither superpowers
nor hyper-relay.

## 2. The sealed pitfall list

```sh
mkdir -p "$BENCH/blind"
```

In a session of the owner's normal setup that is neither run's (this repo's, say), have Claude copy from
Quartz the title and description of card C.1 (`1504e8f8-ddcf-474d-b7ef-978c4a069069`) under `## C.1` and of
card C.2 (`df5a7bd8-da19-439a-af51-508ff3893984`) under `## C.2`, verbatim and without their notes, into
`~/sat-benchmark/cards.md`. Then give the brief and the cards to one headless session in the neutral folder:
it never saw G.2's brainstorm, and it keeps no transcript.

```sh
cd "$SAT"
cat "$HR/docs/benchmarks/pitfall-brief.md" "$BENCH/cards.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH" \
      --allowedTools Read Write "Bash(grep *)" "Bash(sha256sum *)"
chmod a-w "$BENCH/pitfalls.md"
```

It replies with the path and a `sha256sum` line, nothing else. The hash goes in both run logs
(`pitfalls-sha256:`). Nobody opens `pitfalls.md` before step 6, the owner included: knowing it would shape
the brainstorming answers.

## 3. SAT, before C.1

```sh
cd "$SAT"
"$HR/bin/hyper-relay-agents"            # refreshes SAT's role agents
"$HR/bin/hyper-relay-agents" --check    # prints nothing
make ps                                 # every service up, healthy where it has a check
git status --short                      # nothing
grep -r -i -l -e benchmark -e baseline ~/.claude/projects/"$(printf '%s' "$SAT" | tr -c 'A-Za-z0-9' '-')"/memory   # nothing
```

## 4. C.1, with the relay

```sh
cp "$HR/docs/benchmarks/run-log-template.md" "$BENCH/run-log-c1.md"
git -C "$SAT" rev-parse --short main      # start-commit
claude plugin list --json | jq -r '.[] | select(.id == "hyper-relay@hyper-relay") | .version'
```

Fill `workflow: hyper-relay <that version>`, `card:`, `config: ~/.claude`, `start-commit:` and
`pitfalls-sha256:`. Then start a fresh session in SAT's main checkout, in the owner's normal setup, and ask
for card C.1 as the owner would ask for any card:

```sh
cd "$SAT" && claude
```

The relay runs as it stands on the day. At its stop 4, after the click-through passes, the owner merges
with `make merge BRANCH=<the branch>` and tells the orchestrator so. Log every click-through defect as it
is found. After the merge, fill the rest of the log:

- `spec:`, `plan:` and `merge:`: the commit that added C.1's spec, the commit of its approved plan, and the
  merge commit, each with its UTC time.
- `session:` and `start:`: list the sessions of the run's days and pick the run's (SAT's project folder,
  the run's first prompt); `start:` is the first one's first-prompt time.

  ```sh
  "$HR/scripts/benchmark/run-usage.sh" --sessions ~/.claude <the run's first day, 00:00:00Z> <the merge time>
  ```

- `role:` lines, for example:

  ```text
  role: ^sat-planner: → planner
  role: ^sat-executor: → executor
  role: ^sat-reviewer: → acceptance reviewer
  role: [Cc]ode review → code reviewer
  role: [Pp]lan review|[Rr]eview the .* plan → plan reviewer
  ```

Then:

```sh
"$HR/scripts/benchmark/run-usage.sh" "$BENCH/run-log-c1.md" > "$BENCH/usage-c1.md"
```

Give every `other` row a role line, or a reason under the log's Roles, and run it again.

## 5. C.2, with upstream superpowers

From the new `main`, after C.1's merge:

```sh
cd "$SAT"
git status --short                   # nothing
git rev-parse --short main           # start-commit
wt new feat/notify-issue-activity
cp "$HR/docs/benchmarks/run-log-template.md" "$BENCH/run-log-c2.md"
cd "$SAT/.worktrees/notify-issue-activity"
CLAUDE_CONFIG_DIR=~/.claude-superpowers claude
```

Fill `workflow: superpowers <the version step 1 printed>`, `card:`, `config: ~/.claude-superpowers`,
`start-commit:` and `pitfalls-sha256:`. The worktree has none of SAT's gitignored `.claude/` (its role
agents, which point at hyper-relay's skills, and the planner guard) and no `.mcp.json` (Quartz), so neither
reaches the run. The superpowers run does not read the board: the owner's first message asks to build the
feature and pastes card C.2's title and description. Where superpowers offers a choice, take its full path:
subagent-driven development rather than inline execution, and the worktree it is in. At
`finishing-a-development-branch`, choose to keep the branch; after the click-through passes, merge from the
main checkout:

```sh
cd "$SAT" && make merge BRANCH=feat/notify-issue-activity
```

Fill the rest as in step 4, with `~/.claude-superpowers` for `--sessions`. Superpowers commits its spec and
plan on the branch: `spec:` and `plan:` are those commits
(`git -C "$SAT" log --diff-filter=A --format=%h -- <the file's path>`). If it never commits one, write `-`
and the time of the owner's message approving it, and say so under Notes. Note there too where it put its
spec and plan, and any Quartz call it made (SAT's `CLAUDE.md` names the board). Example role lines for its
subagent-driven development (its version 7 has one task reviewer, giving the spec-compliance and the
quality verdicts together):

```text
role: [Ii]mplement → implementer
role: [Ss]pec (compliance )?review → spec reviewer
role: [Qq]uality review → quality reviewer
role: [Tt]ask review|[Rr]eview [Tt]ask → task reviewer
role: [Ff]inal|[Ww]hole[- ]branch → final reviewer
```

```sh
"$HR/scripts/benchmark/run-usage.sh" "$BENCH/run-log-c2.md" > "$BENCH/usage-c2.md"
```

## 6. Scoring

After both merges. The `<…>` values are in the run logs.

**a. The seal.** `sha256sum "$BENCH/pitfalls.md"` prints the hash both logs hold. If it does not, the
list does not count, and the results say so.

**b. Usage.** `usage-c1.md` and `usage-c2.md`, each from its final log. Read each one's Cross-check line: a
gap outside its tolerance is explained in the results, never ignored.

**c. In-process catches.** Write `$BENCH/catches-input.md`, one line per transcript, `<run> <role> <path>`:
every reviewer role's subagent transcripts, the executor's or implementers', and each run's main sessions
(role `main`). A row `agent <id>` of session `<session>` is the file
`<config>/projects/*/<session>/subagents/agent-<id>.jsonl`; a main session is
`<config>/projects/*/<session>.jsonl`. Then:

```sh
cd "$BENCH"
cat "$HR/docs/benchmarks/catches-prompt.md" "$BENCH/catches-input.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir ~/.claude/projects --add-dir ~/.claude-superpowers/projects \
      --allowedTools Read "Bash(jq *)" "Bash(grep *)" > "$BENCH/catches.md"
```

The owner checks `catches.md` and copies each run's confirmed list into its log's In-process catches.

**d. The requirements lists.** One session restates both specs (their paths as merged in SAT):

```sh
printf 'C.1: %s\nC.2: %s\n' <C.1's spec path> <C.2's spec path> > "$BENCH/restate-input.md"
cd "$SAT"
cat "$HR/docs/benchmarks/restate-prompt.md" "$BENCH/restate-input.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" --allowedTools Read Write
```

It writes `$BENCH/blind/requirements-c1.md` and `$BENCH/blind/requirements-c2.md`.

**e. The blind review and its verification**, for each feature; C.1 shown, C.2 the same with its own
commits and `c2`:

```sh
git -C "$SAT" worktree add --detach "$BENCH/review-c1" <C.1 merge>
cd "$BENCH/review-c1"
sed -e 's/<START>/<C.1 start-commit>/g' -e "s|<REQUIREMENTS>|$BENCH/blind/requirements-c1.md|g" \
    "$HR/docs/benchmarks/blind-review-prompt.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" \
      --allowedTools Read "Bash(git diff *)" "Bash(grep *)" > "$BENCH/blind-c1.md"
{ sed -e 's/<START>/<C.1 start-commit>/g' -e "s|<REQUIREMENTS>|$BENCH/blind/requirements-c1.md|g" \
      "$HR/docs/benchmarks/verify-prompt.md"; cat "$BENCH/blind-c1.md"; } \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" \
      --allowedTools Read "Bash(git diff *)" "Bash(grep *)" > "$BENCH/verified-c1.md"
cd "$BENCH" && git -C "$SAT" worktree remove "$BENCH/review-c1"
```

Each session reaches only its worktree and `$BENCH/blind/`: the sealed list and the run logs are out of its
reach. Its prompt tells it not to read git history, so the review is blind to the label but not provably
blind, and the results say so. Only confirmed Critical and Important findings count.

**f. The sealed list**, on both merged features:

```sh
cd "$SAT"
{ sed -e 's/<C1_MERGE>/<C.1 merge>/g' -e 's/<C2_MERGE>/<C.2 merge>/g' "$HR/docs/benchmarks/pitfall-check-prompt.md"; \
  cat "$BENCH/pitfalls.md"; } \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --allowedTools Read "Bash(git show *)" "Bash(git grep *)" > "$BENCH/pitfall-check.md"
```

The owner confirms each answer.

**g. Diff sizes**, over the same paths as the blind review:

```sh
git -C "$SAT" diff --shortstat <C.1 start-commit>..<C.1 merge> -- api web mailer-worker
git -C "$SAT" diff --shortstat <C.2 start-commit>..<C.2 merge> -- api web mailer-worker
```

## 7. The results

Write `docs/benchmarks/<date>-superpowers-baseline.md` in this repo, with:

- both usage tables, with each run's wall clock, agent time, waiting time and the owner's message count;
  the waiting time is time spent on the owner, nights included, and never a cost of either workflow;
- each run's cross-check, and the explanation of any gap outside its tolerance;
- each run's in-process catches, counted, not scored;
- the escaped defects per yardstick, as raw counts: the click-through's defects, the blind review's
  confirmed Critical and Important findings, and the sealed list's answers; beside each feature's diff size
  (files and changed lines);
- the superpowers version, and both start commits;
- the caveats: one pair, so n = 1, which is evidence about these two runs and not a general rate; C.2 ran
  second, with C.1 and an older producer beside it to copy, which favours superpowers; the blind review is
  blind to the label, not provably blind; and whatever the logs' Notes record.

Copy `run-log-c1.md`, `run-log-c2.md`, `usage-c1.md` and `usage-c2.md` to `docs/benchmarks/runs/` and commit
them with it. Card G takes its numbers from it. This repo is public: the results and the logs carry
numbers, one-line findings and commit hashes, never SAT's code, data or secrets.
````

- [ ] **Step 2: The runbook names what exists.**

| Run | Expected |
|---|---|
| `grep -c -E '^## [1-7]\. ' docs/benchmarks/README.md` | `7` |
| `grep -o -h -E 'docs/benchmarks/[a-z-]+\.md' docs/benchmarks/README.md \| sort -u` | each of the seven files of Task 4 and this one exist (`test -f` each) |
| `grep -o -h -E 'scripts/benchmark/[a-z-]+\.sh' docs/benchmarks/README.md \| sort -u` | `scripts/benchmark/run-usage.sh` and `scripts/benchmark/superpowers-env.sh`, both present |
| `grep -c -F 'SAT=${SAT:?' docs/benchmarks/README.md` | `1` (P14: the owner supplies the path) |
| `grep -r -n -F 'sat.pentraze' docs/benchmarks` | nothing (P14: no path for SAT's checkout anywhere in `docs/benchmarks/`) |

- [ ] **Step 3: Commit.**

```bash
git add docs/benchmarks/README.md
git commit -m "docs: G.2's runbook, from the config folders to the results" -m "docs/benchmarks/README.md fixes the protocol before either run starts: the rules both runs share, the two config folders and the owner's checks, the sealed pitfall list, SAT before C.1, C.1 through the relay and C.2 through upstream superpowers with their run logs and usage tables, the scoring (the seal, usage, in-process catches, the requirements lists, the blind review and its verification, the sealed list, diff sizes) and the results document, each with exact commands." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: `CLAUDE.md`, `merge.conf`, and the full gates (spec §5; P11)

**Files:**
- Modify: `CLAUDE.md:32-33` (Layout), `:89` (Checks)
- Modify: `.hyper-relay/merge.conf:45-47` (gates)

- [ ] **Step 1: The Layout line.** In `CLAUDE.md`, replace:

```text
- `scripts/check-import.sh`: piece A's proof that moving the skills in changed nothing. It compares against the loose
  copies in `~/.claude/skills/`, so it stops working once those are deleted. `scripts/bump-version.sh`: version bumps.
```

with:

```text
- `scripts/check-import.sh`: piece A's proof that moving the skills in changed nothing. It compares against the loose
  copies in `~/.claude/skills/`, so it stops working once those are deleted. `scripts/bump-version.sh`: version bumps.
- `scripts/benchmark/`: piece G.2's tools for a baseline against upstream superpowers. `superpowers-env.sh` builds a
  separate Claude Code config folder for the upstream run, and `run-usage.sh` (with `run-usage.jq` and `prices.tsv`)
  reads a run's transcripts into a usage table. `tests/benchmark/` tests both, with a fake `claude` and fixture
  transcripts. `docs/benchmarks/` holds the protocol's fixed prompts, its run-log template and its runbook.
```

- [ ] **Step 2: The Checks row.** In `CLAUDE.md`, replace:

```text
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
```

with:

```text
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
| benchmark | `sh tests/benchmark/run-tests.sh` | `0 failed` |
```

- [ ] **Step 3: The gates.** In `.hyper-relay/merge.conf`, replace:

```text
# relay-merge.
bin/relay-merge                 test   sh tests/relay-merge/run-tests.sh
tests/relay-merge/              test   sh tests/relay-merge/run-tests.sh
```

with:

```text
# relay-merge.
bin/relay-merge                 test   sh tests/relay-merge/run-tests.sh
tests/relay-merge/              test   sh tests/relay-merge/run-tests.sh

# The G.2 benchmark tools: their syntax, and their suite.
scripts/benchmark/              build  dash -n scripts/benchmark/superpowers-env.sh
scripts/benchmark/              build  dash -n scripts/benchmark/run-usage.sh
scripts/benchmark/              test   sh tests/benchmark/run-tests.sh
tests/benchmark/                test   sh tests/benchmark/run-tests.sh
```

- [ ] **Step 4: Check the edits.**

| Run | Expected |
|---|---|
| `grep -n -F -e 'scripts/benchmark/' -e 'tests/benchmark/' -e 'docs/benchmarks/' CLAUDE.md` | the new Layout bullet, and the Checks row |
| `grep -n -i -F 'subagent-driven' CLAUDE.md` | nothing (the relay-skills guard bans it there) |
| `awk '$1 ~ /benchmark/ { print ((NF >= 3) ? "ok" : "short") }' .hyper-relay/merge.conf \| sort \| uniq -c` | one line: `4 ok` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` (it reads `CLAUDE.md`) |

- [ ] **Step 5: Each new gate passes once.** From the checkout's top, run each command of the four new `merge.conf`
  lines:

| Run | Expected |
|---|---|
| `dash -n scripts/benchmark/superpowers-env.sh; echo $?` | `0` |
| `dash -n scripts/benchmark/run-usage.sh; echo $?` | `0` |
| `sh tests/benchmark/run-tests.sh > /dev/null; echo $?` | `0` |

- [ ] **Step 6: Commit.**

```bash
git add CLAUDE.md .hyper-relay/merge.conf
git commit -m "docs: CLAUDE.md and the merge gates name G.2's benchmark tools" -m "CLAUDE.md's Layout gains scripts/benchmark/, tests/benchmark/ and docs/benchmarks/, and its Checks table the benchmark suite. .hyper-relay/merge.conf gates scripts/benchmark/ with dash -n of its two scripts and the suite, and tests/benchmark/ with the suite." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 7: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `90 passed, 0 failed` |
| `dash -n scripts/benchmark/superpowers-env.sh`, then `dash -n scripts/benchmark/run-usage.sh`, then `dash -n tests/benchmark/run-tests.sh` | silent |
| `git ls-files -s scripts/benchmark tests/benchmark` | `100644` `prices.tsv`, `100644` `run-usage.jq`, `100755` `run-usage.sh`, `100755` `superpowers-env.sh`, `100644` `tests/benchmark/run-tests.sh` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git diff --name-only main...HEAD` | exactly these 15: `.hyper-relay/merge.conf`, `CLAUDE.md`, `docs/benchmarks/README.md`, `docs/benchmarks/blind-review-prompt.md`, `docs/benchmarks/catches-prompt.md`, `docs/benchmarks/pitfall-brief.md`, `docs/benchmarks/pitfall-check-prompt.md`, `docs/benchmarks/restate-prompt.md`, `docs/benchmarks/run-log-template.md`, `docs/benchmarks/verify-prompt.md`, `scripts/benchmark/prices.tsv`, `scripts/benchmark/run-usage.jq`, `scripts/benchmark/run-usage.sh`, `scripts/benchmark/superpowers-env.sh`, `tests/benchmark/run-tests.sh` |
| `git log --format=%B main..HEAD \| grep -v '^Claude-Session: ' \| grep -c -E 'https?://'` | `0`: no message names a host, beside its session trailer |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

The other suites are untouched and not run (report this), and upstream's live suites are not run: they start real
`claude -p` sessions. Then report, copy Task 7's checklist (Steps 1–15, each with its marker and its PASS) into your
report, and stop: Task 7 is not yours.

### Task 7: Acceptance (spec §5; G2.3, G2.6; P6, P13–P16, P18). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-g2-superpowers-baseline`) its dispatch names, from the checkout's top. It runs Steps 1–9 only. It
  reads the owner's transcripts (Steps 4–7) and writes only in its evidence folder (`<evidence folder>` below).
- **`owner`**: the owner, at the click-through (Steps 10–12).
- **`after merge`**: the orchestrator with the owner, once the owner has merged the branch into `main` and the main
  checkout `/home/noob_master/hyper-relay` is on `main` (Steps 13–15), one command per Bash call.

**No release:** nothing the plugin loads changes, so the version stays and there is no plugin update.

- [ ] **Step 1 (`reviewer`): The suite, the syntax and the modes.**

| Run | PASS |
|---|---|
| `sha256sum ~/.claude/settings.json ~/.claude/CLAUDE.md > <evidence folder>/01a-before.sha256`, then `ls -d ~/.claude-superpowers ~/.claude-neutral` | the second prints "No such file or directory" for both |
| `sh tests/benchmark/run-tests.sh \| tail -n 1` | `90 passed, 0 failed` |
| `sha256sum -c <evidence folder>/01a-before.sha256`, then `ls -d ~/.claude-superpowers ~/.claude-neutral` | both `OK`; still no such folders: the suite never touched the real home |
| `dash -n scripts/benchmark/superpowers-env.sh`, `dash -n scripts/benchmark/run-usage.sh`, `dash -n tests/benchmark/run-tests.sh` | silent, exit 0 each |
| `git ls-files -s scripts/benchmark tests/benchmark` | `100755` for the two `.sh` tools, `100644` for `prices.tsv`, `run-usage.jq` and the suite |
| `git grep -n -i -w -e sat -e pentraze -- scripts/benchmark tests/benchmark` | nothing |

- [ ] **Step 2 (`reviewer`): The tools against spec §2 and §3.** Read `scripts/benchmark/superpowers-env.sh`,
  `run-usage.sh` and `run-usage.jq` in full, spec §2 and §3, and P1–P8 and P19. PASS, each point quoted with its line:
  - `superpowers-env.sh` is `#!/bin/sh` with `set -eu` and `umask 077`; it refuses an existing folder before
    anything else; every check (the `CLAUDE.md` cut and its two refusals, the settings edits, the `mcpServers` copy
    and its Quartz refusal, each marketplace's source) runs before `mkdir`; it links `skills`, `agents`, `commands`,
    `rules`, `hooks`, `bin`; it never writes under `$SRC` or `~/.claude.json` and removes nothing but its temporary
    folder; every `claude` call runs with `CLAUDE_CONFIG_DIR` set to the new folder and stdin from `/dev/null`;
    `--neutral` skips superpowers; the version comes from the installed plugin's own `.claude-plugin/plugin.json` and
    under 5.1.0 is refused;
  - `run-usage.sh` reads only `key: value` lines before the first `## `; finds `<config>/projects/*/<id>.jsonl` and
    `<id>/subagents/agent-*.jsonl` with their `.meta.json`; `run-usage.jq` counts calls by `message.id`, prices 5m and
    1h writes apart (from `usage.cache_creation` when present), splits the main sessions at the spec and plan times,
    gives each subagent a row and a role (`other` when none), sums per role, computes wall clock, agent time as a
    union with P3's waits, the owner's messages per P4, and the cross-check of P6 against each session's last
    `cost-state`. Nothing contradicts spec §2 or §3 beyond the P-notes; list any line that does as a FAIL.

- [ ] **Step 3 (`reviewer`): The runbook against spec §1 and §4.** Read `docs/benchmarks/README.md` and the seven
  files beside it in full.

| Run | PASS |
|---|---|
| `git ls-files docs/benchmarks` | the eight files of Tasks 4 and 5 |
| `git grep -n -i -E 'relay\|superpowers\|hyper\|quartz' -- docs/benchmarks/pitfall-brief.md docs/benchmarks/restate-prompt.md docs/benchmarks/blind-review-prompt.md docs/benchmarks/verify-prompt.md docs/benchmarks/pitfall-check-prompt.md` | nothing |
| Reading | the runbook covers spec §5's seven steps in order with commands; every headless step uses `~/.claude-neutral`, `--no-session-persistence` and `--permission-mode dontAsk`; the blind review and its verification reach only their worktree and `~/sat-benchmark/blind/` (P12); the pitfall writer works from SAT's `CLAUDE.md`, the two cards and the Notifications A and B code only, and reports only a path and a hash; the blind review is limited to `api/`, `web/` and `mailer-worker/` from the run's start commit, with no `docs/` and no git history; the catch counter's findings and non-findings match spec §4; list any claim that contradicts the spec as a FAIL |

- [ ] **Step 4 (`reviewer`): D1's session, found rather than assumed (P18).** `run-usage.sh --sessions` reads every
  session under `~/.claude/projects` (about 1.5 GB, 137 sessions, when this plan was reviewed): give that command, here
  and in Step 7, a long timeout (5 minutes; it takes about one).

| Run | PASS |
|---|---|
| `grep -l -E '"description":"[^"]*\bD1\b' ~/.claude/projects/-home-noob-master-hyper-relay/*/subagents/*.meta.json` | five files, all in one `<session id>/subagents/` folder: note that id, `<SESSION>` (if they span more sessions, note each; every one goes on a `session:` line below) |
| `grep -h -o -E '"description":"[^"]*"' <the five files>` | D1's planner, plan reviewer, executor, acceptance reviewer and code reviewer |
| `TZ=UTC git log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h %cd' 9590bc8`, the same for `bca6dae` and `fd0a928` | `9590bc8 2026-11-18T04:19:31Z`, `bca6dae 2026-11-18T04:52:27Z`, `fd0a928 2026-11-18T05:10:12Z` (D1's spec, its plan as approved, its merge) |
| `sh scripts/benchmark/run-usage.sh --sessions ~/.claude 2026-11-18T04:19:31Z 2026-11-18T05:10:12Z > <evidence folder>/04-sessions.md` | exit 0; a row for `<SESSION>` in project `-home-noob-master-hyper-relay`, whose First prompt is the owner's (note its time, `<START>`, which is before 04:19:31Z) |

- [ ] **Step 5 (`reviewer`): D1's rows line up with its recorded legs.** Write the log, then run the tool:

```bash
printf '%s\n' '# Run log: D1, the orchestrator (G.2 acceptance)' '' 'workflow: hyper-relay (the relay, 2026-11-18)' 'config: ~/.claude' 'session: <SESSION>' 'start: <START>' 'spec: 9590bc8 2026-11-18T04:19:31Z' 'plan: bca6dae 2026-11-18T04:52:27Z' 'merge: fd0a928 2026-11-18T05:10:12Z' 'role: Write the D1 → planner' 'role: Review the D1 plan → plan reviewer' 'role: Execute the D1 → executor' 'role: Acceptance-check D1 → acceptance reviewer' 'role: Code review of D1 → code reviewer' > <evidence folder>/d1-run-log.md
sh scripts/benchmark/run-usage.sh <evidence folder>/d1-run-log.md > <evidence folder>/05-d1-usage.md; echo "exit $?"
```

PASS: `exit 0`, and these subtotal rows of `05-d1-usage.md` equal the per-leg numbers the orchestrator recorded for D1
(`~/.claude/projects/-home-noob-master-hyper-relay/memory/relay-token-measurements.md`, summed by unique message id;
the stop-4 report in D1's plan's last-task record gives the executor's, the acceptance reviewer's and the code
reviewer's output and cache reads), with "cache write" the row's 5m and 1h columns added:

| Subtotal row | Calls | Input | Cache write (5m + 1h) | Cache read | Output |
|---|---|---|---|---|---|
| `subtotal: planner` | 48 | 98 | 783,056 | 7,437,906 | 179,266 |
| `subtotal: plan reviewer` | 14 | 28 | 129,865 | 1,354,189 | 11,974 |
| `subtotal: executor` | 20 | 40 | 96,120 | 1,451,790 | 10,696 |
| `subtotal: acceptance reviewer` | 7 | 14 | 50,263 | 337,072 | 4,867 |
| `subtotal: code reviewer` | 8 | 16 | 82,022 | 529,145 | 7,865 |

Also: each of those roles shows `1 agent`; `subtotal: other` is piece E's four legs, run beside D1 in the same session
(P18); the three `main:` rows and the time lines are present. A differing number is a FAIL: quote both.

- [ ] **Step 6 (`reviewer`): D1's cross-check (P6).** From `05-d1-usage.md`:

| Check | PASS |
|---|---|
| the By model line's `claude-sonnet-5-5` entry | the cost records' and the transcripts' sides equal: `$2.46, 53,468 output / $2.46, 53,468 output` (in that session Sonnet ran only subagents, so this proves the subagents are counted whole) |
| the Cross-check line | ends `Within the tolerance (0 to 10%).`; record the difference and its share |

Outside the tolerance with the Sonnet entry equal: report it with the By model line, for the owner (P6), not as a
tool defect. The Sonnet entry unequal: a FAIL.

- [ ] **Step 7 (`reviewer`): A session with a compaction (P6).** The `--sessions` command below takes about a minute:
  run it with a 5-minute timeout, as in Step 4.

| Run | PASS |
|---|---|
| `grep -l -F '"subtype":"compact_boundary"' ~/.claude/projects/-home-noob-master-hyper-relay/*.jsonl` | at least one file; take the first whose last line is a cost record (`tail -n 1 <file> \| grep -c '"type":"cost-state"'` prints `1`: the session has ended): its name without `.jsonl` is `<CSESSION>` |
| `sh scripts/benchmark/run-usage.sh --sessions ~/.claude 2026-11-01T00:00:00Z 2026-12-31T00:00:00Z > <evidence folder>/07-sessions.md` | a row for `<CSESSION>`: note its First record `<CFIRST>` and Last record `<CLAST>` |

Then write `<evidence folder>/c-run-log.md` with `printf '%s\n'` as in Step 5, with `config: ~/.claude`,
`session: <CSESSION>`, `start: <CFIRST>`, `spec: - <CFIRST>`, `plan: - <CFIRST>`, `merge: - <one minute after
CLAST, in the same form>`, and no role lines, and run `sh scripts/benchmark/run-usage.sh <evidence folder>/c-run-log.md >
<evidence folder>/07-compacted-usage.md; echo "exit $?"`. PASS: `exit 0`; `Compactions:` at least `1`; the
Cross-check line ends `Within the tolerance (0 to 10%).`; record the difference and its share. Outside: report it with
the By model line, for the owner (P6).

- [ ] **Step 8 (`reviewer`): `CLAUDE.md`, `merge.conf`, and only the planned files (spec §5; P11).**

| Run | PASS |
|---|---|
| `git diff main...HEAD -- CLAUDE.md` | one added Layout bullet (`scripts/benchmark/`, `tests/benchmark/`, `docs/benchmarks/`) and one Checks row (`benchmark`, `sh tests/benchmark/run-tests.sh`, `0 failed`); nothing else |
| `git diff main...HEAD -- .hyper-relay/merge.conf` | one added block of four lines: two `build` lines (`dash -n` of each script) and two `test` lines (the suite) under `scripts/benchmark/` and `tests/benchmark/` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `26 passed, 0 failed` |
| `claude plugin validate .` | passes (exit 0); its warnings exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only in the main checkout, `PRIVACY_URL_MISSING` |
| `git diff --name-only main...HEAD` | exactly the 15 files of Task 6 Step 7 |
| `git log --format=%B main..HEAD \| grep -v '^Claude-Session: ' \| grep -c -E 'https?://'` | `0` |

- [ ] **Step 9 (`reviewer`): Nothing names more than the spec does.** Read the 15 changed files and the branch's
  commit messages (`git log --format=%B main..HEAD`). PASS: the scripts, the suite, `CLAUDE.md` and `merge.conf` name
  no other project; `docs/benchmarks/` names SAT, its two cards and its code folders, as the spec does, but no path
  for SAT's checkout (P14: `git grep -n -F 'sat.pentraze' -- docs/benchmarks` prints nothing), and quotes none of
  SAT's files; no file or message holds a session id, a person's name or a host other than the documentation URLs in
  `prices.tsv` and the commit trailers.

- [ ] **Step 10 (`owner`): Read the protocol.** Read
  `git -C /home/noob_master/hyper-relay show hyper-relay-g2-superpowers-baseline:docs/benchmarks/README.md` and the
  prompts beside it. PASS: the owner agrees they fix the protocol as decided (P14 and P15 were decided at stop 3). A
  change goes to the executor as a finding.

- [ ] **Step 11 (`owner`): The two real folders, the login and the checks (spec §2, §5; P16).** The orchestrator runs
  the first two commands and the last; the owner runs the builds and the sessions in their own terminal:

```bash
git -C /home/noob_master/hyper-relay show hyper-relay-g2-superpowers-baseline:scripts/benchmark/superpowers-env.sh > /tmp/g2-superpowers-env.sh
sha256sum /home/noob_master/.claude/settings.json /home/noob_master/.claude/CLAUDE.md > /tmp/g2-before.sha256
sh /tmp/g2-superpowers-env.sh
sh /tmp/g2-superpowers-env.sh --neutral
sha256sum -c /tmp/g2-before.sha256
```

| Check | PASS |
|---|---|
| each build | exit 0; it lists the links (`skills`, `agents`, `hooks`, `bin`; `commands` and `rules` skipped if absent), the settings edits, the cut, the `.claude.json` servers (codebase-memory-mcp, context7, playwright), and each `claude plugin` call; the first ends with `superpowers <x.y.z>, read from …`, `<x.y.z>` at least 5.1.0: record it for C.2's log |
| `sha256sum -c` | both `OK`: the owner's files are unchanged |
| `mkdir -p /tmp/g2-check && cd /tmp/g2-check && CLAUDE_CONFIG_DIR=~/.claude-superpowers claude`, then `/login` | logged in |
| in that session: `/plugin` | installed: superpowers, frontend-design, gopls-lsp, ui-ux-pro-max; no hyper-relay; no hyper-relay marketplace |
| typing `/` | `superpowers:` skills offered; no `hyper-relay:` skill |
| `/mcp` | codebase-memory-mcp, context7, playwright; no quartz |
| `/memory` | no auto-memory notes |
| `/exit`, then the same with `CLAUDE_CONFIG_DIR=~/.claude-neutral claude` | the same, except that superpowers is absent too |

A failure is a finding for the executor. If C.1 starts on a later day, the runbook's step 1 says when to rebuild.

- [ ] **Step 12 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-g2-superpowers-baseline` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging.

- [ ] **Step 13 (`after merge`): The suites on the merged `main`.**

| Run | PASS |
|---|---|
| `sh /home/noob_master/hyper-relay/tests/benchmark/run-tests.sh` (last line) | `90 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `26 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes, with its three warnings |
| `git -C /home/noob_master/hyper-relay diff --stat HEAD^1 HEAD -- .claude-plugin package.json` | nothing: no release |
| `git -C /home/noob_master/hyper-relay status --short` | nothing |

- [ ] **Step 14 (`after merge`): D1's table, kept before its transcripts expire (P13).** In the main checkout on
  `main` (`git -C /home/noob_master/hyper-relay branch --show-current` prints `main`; no `MERGE_HEAD`), with the
  reviewer's `d1-run-log.md` from Step 5:

```bash
mkdir -p /home/noob_master/hyper-relay/docs/benchmarks/runs
sh /home/noob_master/hyper-relay/scripts/benchmark/run-usage.sh <evidence folder>/d1-run-log.md > /home/noob_master/hyper-relay/docs/benchmarks/runs/2026-11-18-d1-relay.md
printf '\n## The run log it read\n\n```text\n' >> /home/noob_master/hyper-relay/docs/benchmarks/runs/2026-11-18-d1-relay.md
cat <evidence folder>/d1-run-log.md >> /home/noob_master/hyper-relay/docs/benchmarks/runs/2026-11-18-d1-relay.md
printf '```\n' >> /home/noob_master/hyper-relay/docs/benchmarks/runs/2026-11-18-d1-relay.md
git -C /home/noob_master/hyper-relay add docs/benchmarks/runs/2026-11-18-d1-relay.md
git -C /home/noob_master/hyper-relay commit -m "docs: G.2, D1's usage table from its transcripts" -m "The first rows card G asked for: D1's relay run of 2026-11-18 read by scripts/benchmark/run-usage.sh, kept before Claude Code's 30-day sweep deletes its transcripts." -m "<the committing session's attribution lines>" -- docs/benchmarks/runs/2026-11-18-d1-relay.md
```

| Run | PASS |
|---|---|
| `grep -c -E '^[\|] subtotal: (planner\|plan reviewer\|executor\|acceptance reviewer\|code reviewer) ' /home/noob_master/hyper-relay/docs/benchmarks/runs/2026-11-18-d1-relay.md` | `5`, with Step 5's numbers |
| `git -C /home/noob_master/hyper-relay log -1 --format=%s` | `docs: G.2, D1's usage table from its transcripts` |

Push it with the next push of `main` (the owner's call).

- [ ] **Step 15 (`after merge`): Record.** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 7)

- **Before the merge:** acceptance reviewer <verdict line>; D1's rows <equal / which differ>; D1's cross-check
  <difference, share, within or not>; the compacted session's <difference, share, compactions>; fix rounds <n, what
  each changed>; code review: Critical <fixed / dropped, why>, proposed cards <kept / dropped>; token counts: executor
  <n>, acceptance reviewer <n>, code reviewer <n>.
- **Owner steps:** Step 10 <agreed / what changed>; Step 11
  <superpowers version; checks passed / what failed>; Step 12 <merge-tree exit>. Merged in <hash>.
- **After merge:** suites on `main` <counts>; D1's table committed in <hash>; `main` pushed <yes/no>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 7 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md
git -C /home/noob_master/hyper-relay commit -m "docs: G.2 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md#7
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-19-hyper-relay-g2-superpowers-baseline.md
```

Then the runbook (`docs/benchmarks/README.md`) takes over: its runs are not this plan's.
