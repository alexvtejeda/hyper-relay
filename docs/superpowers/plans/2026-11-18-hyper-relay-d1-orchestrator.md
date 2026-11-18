# hyper-relay D1: the orchestrator's relay loop Implementation Plan

**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-d1-orchestrator-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the relay-executor preloads it). Tasks
> 1–9 are the executor's. Task 10 is the acceptance task: each of its steps is marked `reviewer` (the acceptance
> reviewer, before the merge), `owner` (at the click-through) or `after merge` (the orchestrator with the owner).
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the plugin carry the whole relay for one spec: a new `orchestrating` skill takes the session the owner
talks to from an approved spec through the planner, the plan check, the handoff, the executor, acceptance and one code
review to the owner's click-through and the merge, with four stops; the role skills and templates become
single-purpose to match.

**Architecture:** `skills/orchestrating/SKILL.md` is the map: the legs, the four stops, finding where work stands, the
Quartz duties and the fallbacks. One file per leg sits beside it: `planning.md` (new), `dispatching.md` (moved with
`git mv` from `executing-plans`, its §8–9 handed on) and `reviewing.md` (new: acceptance, the fix loop, the code
review, stop 4, the merge). `brainstorming` hands the approved spec to it and gains the off-ramp; `writing-plans`,
`executing-plans` and `requesting-code-review` become the planner's, the executor's and the code reviewer's; the
planner and reviewer templates learn the Spec coverage table and who runs each acceptance step.

**Tech Stack:** Markdown skills and agent templates; the POSIX `sh` suites of `tests/hyper-relay-agents/` and
`tests/add-card-line/` (unchanged; regression checks); Claude Code 2.1.x; OpenCode V2.

**How this was checked:** written against `main` at `283ab22` by reading only; nothing was built, run, installed or
generated. Read in this repo: `CLAUDE.md` (in full); the spec (in full); C's plan
`docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md` (1–991 and 1447–1987, for its format and its
Task 9); C's spec (its section list and decisions C10–C12); `skills/executing-plans/dispatching.md`,
`skills/executing-plans/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`,
`skills/brainstorming/SKILL.md`, `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`,
`skills/agents/opencode.md`, `templates/agents/planner.md`, `templates/agents/reviewer-commands.md`,
`templates/agents/reviewer-browser.md`, `.hyper-relay/agents.md`, `README.md` (all in full);
`skills/using-git-worktrees/SKILL.md` (1–20); `skills/agents/SKILL.md` (50–69); `skills/receiving-code-review/SKILL.md`
(1–15); `skills/finishing-a-development-branch/SKILL.md` (1–30); `.claude-plugin/plugin.json`;
`tests/hyper-relay-agents/run-tests.sh` (56–115, 384–428, and every `assert_*` line by `git grep`);
`tests/hyper-relay-agents/guard-test.sh` and `tests/add-card-line/run-tests.sh` (their expected counts, by `git grep`);
`templates/hooks/planner-guard.py` (what it allows, by `git grep`); `scripts/check-import.sh`, `docs/testing.md`,
`.claude-plugin/marketplace.json` (by `git grep`, for skill counts); upstream's live prompts for `writing-plans`,
`executing-plans` and `requesting-code-review` and `tests/claude-code/test-requesting-code-review.sh` (by `git grep`);
`git ls-files` of `skills/`, `templates/`, `tests/`, `docs/superpowers/`; `git grep` for every pointer to
`dispatching.md`, `executing-plans`, `writing-plans`, `subagent-driven`, and the old brainstorming wording; `git log`
for the commit that created `dispatching.md` (`6579c81`). Read outside the repo: `~/.claude/CLAUDE.md` (in full); the
hyper-relay handoff memory and SAT's `orchestrator-workflow` memory (in full).

**Tests that assert template text:** none of `tests/hyper-relay-agents/run-tests.sh`'s assertions (nor its inline
fixture, `FACTS_OK`) touch the wording §7 changes: they check the headings `## Report (concise)`,
`# demo reviewer (acceptance)`, `# demo reviewer (click-through)`, `## Look beyond the checklist`, `## Seed facts`,
`- **360 px:**` and the Committing line `git -C <root> branch --show-current`, all kept. So the suite is not edited;
Task 8 runs it, and its count stays `153 passed, 0 failed`.

**External facts (re-verified 2026-11-18):**
- **Claude Code sub-agents,** [code.claude.com/docs/en/sub-agents.md](https://code.claude.com/docs/en/sub-agents.md):
  the model order starts with "The per-invocation `model` parameter, which Claude can pass when it starts the subagent.
  On an Agent tool call, the parameter takes a model alias, not a full model ID or `inherit`", ahead of the definition's
  `model`; "While `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is on, … Claude can't pass a model when it starts a subagent".
  "Claude uses the `SendMessage` tool with the agent's ID or name as the `to` field to resume it. `SendMessage` doesn't
  require agent teams to be enabled"; "When Claude sends a completed subagent a message with the `SendMessage` tool, the
  subagent resumes in the background"; "Resumed subagents retain their full conversation history". The built-in Explore
  and Plan agents return no agent ID and cannot be resumed; `general-purpose` and custom agents can. **As spec §11 says.**
  `model: sonnet` is an alias, so it is accepted (E4).
- **OpenCode agents,** [opencode.ai/docs/agents/](https://opencode.ai/docs/agents/): "A subagent uses its configured
  model, or inherits the parent session's model when none is configured." No per-dispatch model is documented. "They
  always run in the background"; "the parent receives a report when a child goes idle, and again after each later round
  of work."
- **OpenCode's `subagent` tool,** [opencode.ai/docs/tools/](https://opencode.ai/docs/tools/): it takes the agent ID, a
  short `description` and a complete `prompt`, returns a `sessionID` at once, and "Pass the returned `sessionID` to
  continue that same child conversation"; a follow-up to a running child joins its current run. No model parameter.
  **Difference from spec §9** ("not documented here"): continuing a child session is documented, though the page does
  not say outright that it works once the child has finished. No design change: `SKILL.md`'s resume fallback names it
  (E3), and the fallbacks of spec §2.5 hold either way.
- The other facts of spec §11 (a running session keeps the agent definitions it loaded; no session-start primer; the
  cache refreshes only from the in-session `/plugin install`; Quartz's `add_tasks`) were checked by the spec's author
  today and are not re-verified here; Task 10 Steps 11 and 12 observe the first and third again.

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or its own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top. This plan is committed on `main`.
- **The skill you follow is not the one you write.** Your preloaded `executing-plans` is the installed plugin's copy.
  This plan rewrites the repo's skills, `executing-plans` among them; follow your agent instructions and this plan, not
  the new text.
- **Commits.** Commit after every task, staging named paths only (never `git add -A` / `git add .`; Task 1's `git mv`
  of the named file is fine). Put the trailers in ONE final paragraph, so git reads them all as trailers: each task's
  final commit is `git commit -m "<subject>" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#<N>`
  followed, inside the same quoted paragraph, by the `Co-Authored-By:` line your instructions give and
  `Claude-Session:` with the URL from your dispatch prompt. The commands below show where they go. Never tick the
  plan: the hooks do.
- **A `quartz:` line printed by a commit:** report it, verbatim.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly. If X is not found, read the
  range again; if the text moved or differs slightly, adapt as little as possible and record it as a deviation; if it
  is gone, stop and report. Text in code blocks is exact: transcribe it.
- **Never** start a live `claude -p` / `opencode run` session, install or uninstall a plugin, add a marketplace, push,
  tag, or create anything on GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites
  (`tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`): they start `claude -p`.
- **Outside the executor's branch is not the executor's.** Never touch `main`, `~/.claude/`, `~/.config/opencode/`,
  SAT's repo or the home directory's own repo. Task 10 is not yours: its `reviewer` steps are the acceptance
  reviewer's, its `owner` steps the owner's, its `after merge` steps the orchestrator's with the owner.
- **The orchestrator keeps working in the main checkout meanwhile** (it is brainstorming piece E). Untracked files under
  `docs/superpowers/` that you did not create are its held-back specs and plans, and `tasks/` is the owner's untracked
  scratch tracker: never stage, edit, move or delete either. A "the tree is clean" check ignores them.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs its targeted check only. The full gates run once, in Task 9: the suites this plan
  touches (the Checks table in `CLAUDE.md`), plus `claude plugin validate .`. No shell script is touched, so there is
  no `dash -n` / `bash -n` to run.
- **This repo is public.** Nothing you write into the repo may name another project or carry its facts. (Task 10 names
  SAT's path; it is not yours.)
- After Task 9: report (gate results with counts, every deviation, any `quartz:` line, the suites not run and why) and
  copy Task 10's checklist into the report. Stop.

## Spec ambiguities and deviations (each decided here)

| # | Question | Decision |
|---|---|---|
| E1 | README's roadmap (§8): `283ab22` already split D into D1 and D2 and added E and F | §8's roadmap change reduces to D1's status, `in progress` → `on \`main\`` (Task 9). The relay table, the line under it and the status blockquote are this plan's. |
| E2 | Section numbers in the new files | Each file numbers its own sections: `planning.md` §1–§4 are spec §3.1–§3.4, `reviewing.md` §1–§5 are spec §5.1–§5.5, and `dispatching.md` keeps §1–§7. Skill text refers to the file's numbers (spec "§5.5" is `reviewing.md` §5). |
| E3 | External: OpenCode documents continuing a child session (`subagent` tool, given the returned `sessionID`); spec §9 says undocumented | `SKILL.md`'s resume fallback names both harnesses' way (Task 3). No design change. A per-dispatch model is not documented in OpenCode, as §2.5 assumed. |
| E4 | External: Claude Code's per-invocation `model` takes an alias only, and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` disables it | `model: sonnet` is an alias: nothing changes. Noted for the owner. |
| E5 | §2.4 omits two Quartz duties the owner's global section carries: tick a task by hand when a `quartz:` line says to or it has no commit; `quartz install-git-hook` once in a new repo | `SKILL.md`'s Quartz duties carry both (Task 3), so Task 10 Step 13 drops the owner's Quartz duties without losing them. **Owner: confirmed 2026-11-18.** |
| E6 | A committed spec may still await stop 2 (`brainstorming` commits it before the owner reviews it), yet reads as "a spec that no plan names" | The state row says: the planner leg, once the owner has approved the spec, and the owner asking to pick it up is that approval. Probe (c) is unaffected. |
| E7 | §6.2 does not give `writing-plans` the new plan format, but a fallback planner (no generated agents, §2.5) sees only `writing-plans`, never the template, and would fail §3.2 checks 4 and 6 every time | Task 5 Step 4 adds a short section on the Spec coverage table and the acceptance task's markers to `writing-plans` (the template carries the same, per §7). **Owner: confirmed 2026-11-18.** |
| E8 | `writing-plans`' "Committing the plan" still has the planner commit "a spec you updated" and handle a committed spec's `**Plans:**` line during a branch run | With §6.2 (the planner never edits a spec) those clauses go (Task 5 Step 3). |
| E9 | §7: "wait a second and retry once" on `index.lock` | The planner's guard refuses `sleep`; the template says to run the same command once more, the new tool call being the wait (Task 8). |
| E10 | §10.1's "`brainstorming` has no 'invoke writing-plans'" vs §6.1's required sentence "do not invoke `writing-plans`" | The gate greps the old instructions' wording (`invoke writing-plans`, `invoke the writing-plans`, `invoking writing-plans`, `writing-plans is the next step`, case-insensitive), which the new backticked sentence does not match. |
| E11 | §10.1's "`requesting-code-review` has no per-task wording" | Made a grep: `each task`, `per.task`, `next task`, `task [0-9]`, `completing tasks`, case-insensitive, over the skill's folder. |
| E12 | §10.1's "every line … also names `orchestrating`" | Written as `git grep -e 'dispatching\.md' --and --not -e orchestrating` (no output), plus a check that the plain grep prints lines, so the first is not vacuous. |
| E13 | Upstream's "Task tool (general-purpose)" in the two prompt templates | Rewritten as "Agent tool (general-purpose, model: sonnet)": the tool's current name and §2.5's model. |
| E14 | README beyond §8 | The Review row keeps `verification-before-completion` beside §8's three names. The intro and the ASCII diagram are left alone. |
| E15 | Left alone, though they name the old flow: `skills/dispatching-parallel-agents/SKILL.md`'s description ("use executing-plans instead", which now redirects an orchestrator); `skills/voice-to-specs/CLAUDE.md` line 54 (a diagram); `scripts/check-import.sh` (A's proof, already unrunnable; it would also refuse the new skill); upstream's live prompt `tests/skill-triggering/prompts/writing-plans.txt`, which pastes a spec and expects `writing-plans` to load, now the planner's only (not run) | **Owner: confirmed 2026-11-18.** This plan leaves all four alone; the orchestrator adds a card for the live prompt. |
| E16 | The acceptance task's last step appends a record to this plan after the merge (as C's Task 9 did), and its commit's `Plan-Task: …#10` ticks Task 10, which is how `SKILL.md`'s state table sees after-merge work left. §3.3's "only the planner edits a plan" governs revisions before execution | Kept as Task 10 Step 17. **Owner: confirmed 2026-11-18.** |
| E17 | The main checkout holds the owner's untracked `tasks/`. On this branch run, `dispatching.md` §7's clean-tree check and the commands reviewer's "Before you start" step 2 accept only untracked `docs/superpowers/` files, so `?? tasks/` stops them | **Resolved 2026-11-18:** `tasks/` excluded locally. The orchestrator added `tasks/` to `.git/info/exclude`, so `git status --short` in the main checkout prints nothing. |
| E18 | The probes run with the owner's new `~/.claude/CLAUDE.md` (Step 13 comes before Step 14, as §10.3 orders) | The off-ramp fires only when `brainstorming` loads; the drafted Workflow text sends any change to files through it. A FAIL in probe (b) is the experiment's answer (R7), reported, not a plan bug. |
| E19 | §10.3 step 2: how to see the agents are out of date before regenerating | `hyper-relay-agents --check` (no live session; C used `claude -p`). Expected out of date: the planner and the reviewer in both repos. |
| E20 | Card line | None: the plan inherits D's card (`342aada1-4c49-41fc-bd7d-abceda538efe`) through its `**Spec:**` line. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–10 |
| Decisions (owner, 2026-11-17 and 2026-11-18), R1–R12 | 1–10 (each task's heading names its decisions) |
| 1. What changes where | 1–9; 10 for its last row |
| 2. The map (`skills/orchestrating/SKILL.md`) | 3 |
| 3. The planner leg (`skills/orchestrating/planning.md`) | 2 |
| 4. The handoff (`skills/orchestrating/dispatching.md`) | 1 |
| 5. The review leg (`skills/orchestrating/reviewing.md`) | 1 |
| 6. Changes to other skills | 4 (§6.1), 5 (§6.2), 6 (§6.3, §6.5), 7 (§6.4) |
| 7. Templates | 8 |
| 8. Docs | 9 |
| 9. OpenCode | 3 (Fallbacks), 10 (Step 14, probe d) |
| 10. Testing and acceptance | 9 (§10.1), 10 (§10.2, §10.3) |
| 11. External facts (checked 2026-11-18) | 3 (Fallbacks), 10 (Steps 11 and 12); re-verified in this header |
| 12. Out of scope | 1–10: none adds any of it |
| 13. Plans | 10 (§10.3 is its last task) |

## File structure

- **Move and modify (Task 1):** `skills/executing-plans/dispatching.md` → `skills/orchestrating/dispatching.md`.
- **Create (Tasks 1–3):** `skills/orchestrating/reviewing.md`, `skills/orchestrating/planning.md`,
  `skills/orchestrating/SKILL.md`.
- **Modify (Task 4):** `skills/brainstorming/SKILL.md`.
- **Modify / rewrite (Task 5):** `skills/writing-plans/SKILL.md`; `skills/writing-plans/plan-document-reviewer-prompt.md`
  (rewritten).
- **Modify (Task 6):** `skills/executing-plans/SKILL.md`, `skills/using-git-worktrees/SKILL.md`, `skills/agents/SKILL.md`.
- **Rewrite (Task 7):** `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`.
- **Modify (Task 8):** `templates/agents/planner.md`, `templates/agents/reviewer-commands.md`,
  `templates/agents/reviewer-browser.md`.
- **Modify (Task 9):** `README.md`, `CLAUDE.md`.
- **Unchanged:** `bin/hyper-relay-agents`, `templates/agents/executor.md`, `tests/` (see "Tests that assert template
  text" above), `receiving-code-review`, `verification-before-completion`, `finishing-a-development-branch`,
  `using-hyper-relay`.
- **Task 10 (not the executor's):** the installed plugin; `/home/noob_master/hyper-relay/.claude/agents/` and
  `/home/noob_master/sat.pentraze.com/.claude/agents/` (generated, ignored); `/home/noob_master/.claude/CLAUDE.md` (the
  owner's, untracked); two memory files under `/home/noob_master/.claude/projects/`; throwaway repos under `/tmp/`; this
  plan's record.

---

### Task 1: `orchestrating` takes the handoff and the review leg (spec §4, §5; R4, R5, R6, R11)

**Files:**
- Move and modify: `skills/executing-plans/dispatching.md` → `skills/orchestrating/dispatching.md`
- Create: `skills/orchestrating/reviewing.md`

- [x] **Step 1: Move the file, so its history follows.**

```bash
mkdir -p skills/orchestrating
git mv skills/executing-plans/dispatching.md skills/orchestrating/dispatching.md
```

Run: `git status --short -- skills/executing-plans skills/orchestrating`
Expected: `R  skills/executing-plans/dispatching.md -> skills/orchestrating/dispatching.md`

- [x] **Step 2: The opening (spec §4, first bullet).** In `skills/orchestrating/dispatching.md`, replace:
```text
The orchestrator's half of `executing-plans`. You are the session the owner talks to. You hand ONE approved plan to
ONE executor, keep working while it runs, verify what it hands back, and see the plan through review and merge. You
never execute a plan yourself: a fresh executor, in its own context, works better than a window full of decisions
and explanations. (`SKILL.md`, beside this file, is the executor's process.)
```
with:
```text
The handoff leg of `orchestrating` (`SKILL.md` beside this file is the map), reached from stop 3 (`planning.md` §3).
You are the session the owner talks to. You hand ONE approved plan to ONE executor, keep working while it runs, and
verify what it hands back; `reviewing.md` sees the plan through review and merge. You never execute a plan yourself:
a fresh executor, in its own context, works better than a window full of decisions and explanations. The executor's
process is the `hyper-relay:executing-plans` skill.
```

- [x] **Step 3: §5 points at the executor's skill (spec §4, last bullet).** Replace:
```text
The prompt gives what the executor's `SKILL.md` lists under "The dispatch prompt gives":
```
with:
```text
The prompt gives what `hyper-relay:executing-plans` lists under "The dispatch prompt gives":
```

- [x] **Step 4: §7 hands on to `reviewing.md`; §8 and §9 leave (spec §4, second and third bullets).** Replace:
```text
MCP. Tell the owner only failures, gate results, deviations and the decisions you need: the board shows the rest.

## 8. Click-through and merge

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).

## 9. After a branch merge

The main checkout is back on `main`. Make the edits that waited, and commit the specs and plans you held back, each
staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks upload them. Task
ticks queued during the run drain at the next stop.
```
with:
```text
MCP. Tell the owner only failures, gate results, deviations and the decisions you need: the board shows the rest.

Then continue with `reviewing.md`.
```

- [x] **Step 5: The review leg.** Write `skills/orchestrating/reviewing.md` with exactly:

````markdown
# The review leg, the click-through and the merge

The last leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when `dispatching.md` §7 has
verified the executor's hand-back and run `quartz review`, and it runs on its own until stop 4, except for a gap in
the spec or plan and a second failed fix round, which go to the owner. You review nothing yourself: the acceptance
reviewer and the code reviewer do, each in its own context.

## 1. Acceptance

Dispatch the repo's `<project>-reviewer` (`.claude/agents/<project>-reviewer.md`) in the background. The prompt
gives:

- the plan's path and its acceptance task (its last task);
- **the step numbers marked `reviewer`**, which are the only ones it runs;
- the checkout and the branch;
- what the executor's report says it left running (URLs, logins);
- an evidence folder outside the checkout: your harness's scratchpad when it has one, otherwise a new `mktemp -d`.

When the plan has no `reviewer` steps, skip the dispatch and say so at stop 4.

**Without a generated reviewer** (`SKILL.md`, Fallbacks), dispatch a general-purpose agent (in OpenCode, the
`general` subagent) with the same prompt and this standing brief:

> You are report-only. Run each named step exactly as the plan writes it. For each, give PASS, FAIL or NEEDS-HUMAN,
> with the command, the lines that decide it and the exit code, quoted. Save each step's output in the evidence
> folder. Never edit, commit, install anything or change any config.

**Verify the report:**

- every named step has a verdict;
- a PASS without quoted evidence counts as not run: it goes back to the reviewer;
- rerun one FAIL yourself, where its command is read-only, to confirm it is real.

## 2. The fix loop

Sort each FAIL and each BLOCKING finding:

| Kind | Goes to |
|---|---|
| An execution bug: the code does not do what the plan says | The executor that ran the plan, resumed with its context (`SKILL.md`, Fallbacks). When it cannot be resumed, a fresh executor, dispatched as `dispatching.md` §5 says, with the plan and the findings. |
| A gap in the spec or the plan | The owner, who decides: fix it on this branch (it goes to the executor as a finding, and you record it as a deviation), or a new card |
| PRE-EXISTING, or POLISH | A proposed card (§4) |

The executor's fix prompt gives:

- the findings with their evidence, verbatim;
- the plan, the mode, the checkout and the branch;
- fix root causes;
- commit each fix staging named files only, with the attribution lines and **no** `Plan-Task:` trailer;
- rerun the gates, and report.

After a fix, verify it as `dispatching.md` §7 does: the gates, the new commits, a clean tree. Then the reviewer,
resumed or fresh, reruns only the steps that failed. A step that fails again after its second fix round goes to the
owner.

## 3. The code review, last

When every acceptance FAIL is fixed, or turned into a card by the owner (NEEDS-HUMAN steps may remain), run one code
review of the whole branch, as `hyper-relay:requesting-code-review` says: a general-purpose agent on Sonnet
(`SKILL.md`, Fallbacks), given that skill's `code-reviewer.md` (`../requesting-code-review/code-reviewer.md` from
this file) with the range `$(git merge-base main <branch>)..<branch>`, the plan and the spec. It runs once per
branch, after acceptance and its fixes, so it reads the final diff.

- **Critical:** check each one against the code first (`hyper-relay:receiving-code-review`). A wrong one is dropped,
  with the reason, in the stop-4 report. A real one goes to the executor as in §2. Then resume the code reviewer to
  check only the fix commits (when it cannot be resumed, read that diff yourself), and have the acceptance reviewer
  rerun the steps the fix touches (all its steps, when that is unclear).
- **Important and Minor:** proposed cards (§4).

## 4. Stop 4, the click-through and the merge

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

The owner clicks through: after a branch run, on the normal stack, once the executor's "On a branch" acceptance steps
have run; after a worktree run, on the worktree's `wt` stack. The owner decides the merge, through
`hyper-relay:finishing-a-development-branch`, which handles both: for a branch, it checks out `main`, merges and
deletes the branch; for a worktree, it merges, then removes the worktree. When the worktree has a `wt` stack, stop
it first (`(cd <worktree> && wt down)`).

## 5. After the merge

After a branch merge, the main checkout is back on `main`. Make the edits that waited, and commit the specs and plans
you held back, each staged by its path (`git add <path>`, then `git commit -m "<message>" -- <path>…`), so the hooks
upload them. Task ticks queued during the run drain at the next stop.

Then, in either mode, run the plan's `after merge` acceptance steps with the owner. When the spec has another plan,
its handoff follows (`planning.md` §4).
````

- [x] **Step 6: Check.**

| Run | Expected |
|---|---|
| `grep -n '^## ' skills/orchestrating/dispatching.md` | seven lines, `## 1. Handoff: always a stop` through `## 7. Verify the hand-back` |
| `grep -n '^## ' skills/orchestrating/reviewing.md` | five lines, `## 1. Acceptance` through `## 5. After the merge` |
| `tail -n 1 skills/orchestrating/dispatching.md` | ``Then continue with `reviewing.md`.`` |
| `grep -n -e 'Click-through and merge' -e 'After a branch merge' -e 'beside this file, is the executor' skills/orchestrating/dispatching.md` | no output |

- [x] **Step 7: Commit.**

```bash
git add skills/orchestrating/dispatching.md skills/orchestrating/reviewing.md
git commit -m "feat: orchestrating takes over the handoff (dispatching.md, moved) and adds the review leg" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```
Then `git show --stat -M --format= HEAD` must show `skills/{executing-plans => orchestrating}/dispatching.md` (a
rename) and `skills/orchestrating/reviewing.md`.

### Task 2: `planning.md`, the planner leg (spec §3; R3, R10, R11)

**Files:**
- Create: `skills/orchestrating/planning.md`

- [x] **Step 1: The planner leg.** Write `skills/orchestrating/planning.md` with exactly:

````markdown
# The planner leg

The planner leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when the owner approves the
written spec (stop 2) and ends at stop 3. You do not write the plan: a planner does, in its own context.

## 1. Dispatch

Straight after the owner approves the written spec, dispatch the planners in the background. The approval is the
go-ahead: do not ask again. Then tell the owner they are running, and carry on.

- **Plan paths.** You name them: `docs/superpowers/plans/<today>-<topic>.md`, where `<topic>` is the spec's file name
  without its date and `-design`. A spec with a `**Plans:** <n>` line gets n paths, each with the suffix the spec
  gives its part (`-api`, `-web`), in the spec's order. Each plan's branch is its file name without the date and
  `.md` (`dispatching.md` §3). For example, the spec `2026-11-18-billing-design.md`, with one plan, written on
  2026-11-19: `docs/superpowers/plans/2026-11-19-billing.md`, on the branch `billing`.
- **One planner per plan, in parallel:** the repo's `<project>-planner` (`.claude/agents/<project>-planner.md`).
  Without generated agents (`SKILL.md`, Fallbacks): a general-purpose agent whose first instruction is "Invoke the
  `hyper-relay:writing-plans` skill and follow it. You may only read code and write your plan file." (In OpenCode:
  the `general` subagent, told to load the `writing-plans` skill first.)
- **The prompt gives:**
  - the spec's path (absolute when the spec is not committed on `main`);
  - the plan's path and its branch;
  - with sibling plans: their paths and branches, and that the spec's contract between them binds;
  - the commit message for the plan, and the attribution lines your harness gives you, in one final paragraph;
  - the Claude-Session URL, when your harness gives you one;
  - anything unusual;
  - **during a branch run:** read `main`'s code with `git show main:<path>`; the plan will not be committed (the
    planner's own check refuses), so the planner puts it on its cards with `quartz link-doc` and you commit it after
    the merge (`reviewing.md` §5).

## 2. Check the hand-back

Inline, with git and grep, before the owner sees anything. You do not read the whole plan line by line. For each
plan:

1. **Committed:** `git log -1 --format=%h main -- <plan>` prints a commit. During a branch run: the file exists, and
   the planner ran `quartz link-doc` on it (without Quartz, the file exists).
2. **Card line:** when the spec names a card, the plan's header (above its first `---` or `## `) has a `**Card:**` or
   `**Cards:**` line, or a `**Spec:**` line naming the spec, through which it inherits the spec's cards.
3. **Trailers:** `grep -n -o 'Plan-Task: [^ "]*' <plan>` lists them. Each task with a commit step carries
   `Plan-Task: <plan path>#<N>` once, with its own number and the plan's own path.
4. **Acceptance:** `grep -n '^### Task' <plan> | tail -n 1` names the last task, which is the acceptance task; each of
   its steps says who runs it: `reviewer`, `owner` or `after merge`.
5. **Placeholders:** `grep -n -E 'TBD|TODO|implement later|fill in details|Similar to Task' <plan>` finds nothing
   outside quoted text.
6. **Spec coverage:** `grep -n '^## ' <spec>` lists the spec's sections. The plan's **Spec coverage** table maps every
   one of them to at least one task.
7. **Sibling plans:** their **Contract** sections are identical.

A failed check goes back to the planner before stop 3: resumed (`SKILL.md`, Fallbacks), or a fresh planner given the
list.

## 3. Stop 3

One message, which ends there:

- the plan paths and their task counts;
- the planner's deviations and ambiguities, with its resolutions;
- the external facts it re-verified, and any differences;
- the decisions the owner must make;
- then two questions: "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the
  spec." and the handoff question from `dispatching.md` §1, for the first plan to run.

The answer leads one of three ways:

- **Approve, with a mode:** `dispatching.md` §2. The answer is the go-ahead: do not ask again.
- **A plan review:** dispatch a general-purpose agent on Sonnet (`SKILL.md`, Fallbacks) with `writing-plans`'
  `plan-document-reviewer-prompt.md` (`../writing-plans/plan-document-reviewer-prompt.md` from this file), filled in
  with the plan's and the spec's paths. Its findings go to the planner, which revises the plan and commits it again.
  Then §2, and a short stop 3: what changed, and the handoff question again.
- **Changes:** the planner revises the plan (resumed, or fresh with the owner's list) and commits it again. Then §2
  and stop 3.

**Only the planner edits a plan.** When the spec's `**Plans:**` count is wrong, the planner reports it and stops. Ask
the owner; then update the spec's `**Plans:**` line yourself (add it for more than one plan, remove it for one),
commit just the spec while the main checkout is on `main` (`git add <spec>`, then `git commit -m "<message>" --
<spec>`), and dispatch the planners again. During a branch run, the edit itself waits for the merge
(`dispatching.md` §6).

## 4. Several plans

They run one after another, in the spec's order. After plan k merges (`reviewing.md` §5), plan k+1 gets its own
stop-3 handoff question, and its branch is cut from the new `main`. Running them at once is not part of this skill.
````

- [x] **Step 2: Check.**

Run: `grep -n '^## ' skills/orchestrating/planning.md`
Expected: four lines: `## 1. Dispatch`, `## 2. Check the hand-back`, `## 3. Stop 3`, `## 4. Several plans`.

- [x] **Step 3: Commit.**

```bash
git add skills/orchestrating/planning.md
git commit -m "feat: orchestrating's planner leg: dispatch, the hand-back check, stop 3" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: `SKILL.md`, the map (spec §2, §9, §11; R1, R2, R8, R9, R11; E3, E5, E6)

**Files:**
- Create: `skills/orchestrating/SKILL.md`

- [x] **Step 1: The map.** Write `skills/orchestrating/SKILL.md` with exactly:

````markdown
---
name: orchestrating
description: Use in the session the owner talks to when a spec has just been approved, when a spec or plan with unfinished work turns up (after a /clear or in a new session), when a plan is ready to hand off, or when a planner, executor or reviewer reports back. Runs the relay from approved spec to merge, with a fresh agent for each leg and four stops for the owner. A dispatched planner, executor or reviewer never uses this skill.
---

# Orchestrating the relay

You are the orchestrator: the session the owner talks to. You run the relay for one approved spec, from the spec to
the merge. You never write a plan, execute one or review one yourself: a fresh agent, in its own context, does each
leg. You dispatch it, check what it hands back, and stop for the owner where this skill says.

**Announce at start:** "I'm using the orchestrating skill to run the relay."

## The legs

| Leg | File | Ends in |
|---|---|---|
| Design and spec | `hyper-relay:brainstorming` | stops 1 and 2 |
| Planner | `planning.md` | stop 3 |
| Handoff and executor | `dispatching.md` | a verified hand-back (no stop) |
| Review, click-through, merge | `reviewing.md` | stop 4, then the merge |

The three leg files are beside this SKILL.md. Read each one when the loop reaches its leg, not before:

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md).

## The stops

| Stop | What the owner gets | The owner's answer starts |
|---|---|---|
| 1. Design | The design, section by section (`brainstorming`) | the spec |
| 2. Spec | The written spec (`brainstorming`) | the planner leg: approval is the go-ahead, no second ask |
| 3. Plan ready | The hand-back check's result, the planner's deviations, the decisions the owner must make, the plan-review offer, the handoff question (`planning.md` §3) | execution, a plan review, or plan changes |
| 4. Ready to merge | Gate and acceptance results, fixes made, Critical findings fixed or dropped, proposed cards (`reviewing.md` §4) | the click-through and the merge |

A stop ends the message: the next leg never starts in the message that reaches a stop. Between stop 3 and stop 4 the
loop runs on its own, except for a gap in the spec or plan and a second failed fix round, which go to the owner
(`reviewing.md` §2).

## Finding where work stands

After a `/clear` or in a new session, find the leg from files and git, never from memory. With Quartz, the card's
column is a cross-check.

| State | Leg |
|---|---|
| A spec that no plan's `**Spec:**` line names | The planner leg, once the owner has approved the spec: their asking to pick it up is that approval. Never brainstorm it again. |
| A plan with no branch of its name, and no `Plan-Task:` commits for it on `main` | Stop 3 (the owner has not approved it yet) or the handoff, by what the owner says |
| A plan's branch with some of its tasks committed, and no executor report in this session | **Ask the owner** whether its executor is still running elsewhere. Two executors on one branch collide. |
| A plan's branch with all its executor tasks committed | `dispatching.md` §7 (verify), then `reviewing.md` |
| The branch merged, with an `after merge` step of the plan's acceptance task left (that task is not ticked) | `reviewing.md` §5 |

The branch name comes from the plan's file name (`dispatching.md` §3). To read the state:
`git grep -l -F '<spec file name>' -- docs/superpowers/plans` finds the spec's plans; `git branch --list <branch>`
finds the branch; `git log --format=%h --grep='Plan-Task: <plan path>' main..<branch>` lists the branch's task
commits, and the same with `main` in place of `main..<branch>` lists the merged ones.

**A branch run is active exactly when the main checkout is not on `main`.** While one is, `dispatching.md` §6's
hold-back rules bind you, in every leg.

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

## Fallbacks

- **No generated agents** (`.claude/agents/<project>-planner.md` and the rest; in OpenCode, `.opencode/agents/`):
  offer `hyper-relay:agents` once. If the owner declines, each leg dispatches a general-purpose agent told to invoke
  its skill: `hyper-relay:writing-plans` for the planner, `hyper-relay:executing-plans` for the executor (in OpenCode,
  the `general` subagent, told to load the skill first). The acceptance reviewer, which has no skill, gets the
  standing brief in `reviewing.md` §1.
- **Models:** the generated agents carry their own. The plan reviewer and the code reviewer run on Sonnet: in Claude
  Code, `model: sonnet` on the dispatch; in OpenCode, which sets a model per agent and not per dispatch, the
  `general` subagent's configured model.
- **Resuming an agent** with its context: in Claude Code, `SendMessage` to the agent's ID or name; in OpenCode, the
  `subagent` tool given the child's `sessionID`. Otherwise, or when the agent is gone, a fresh agent gets what it needs
  in its prompt.
- **No background agents** (a harness that waits for a subagent): every rule still holds; the owner just cannot work
  meanwhile.
````

- [x] **Step 2: Check.**

| Run | Expected |
|---|---|
| `claude plugin validate .` | passes (the new skill's front matter parses); warnings only the root `CLAUDE.md` one and, at most, `ICON_MISSING` |
| `grep -n 'CLAUDE_SKILL_DIR' skills/orchestrating/SKILL.md` | four lines; each also names the same file relative to this SKILL.md (`beside this SKILL.md`, or `from this SKILL.md`) |
| `ls -A skills/orchestrating` | `SKILL.md`, `dispatching.md`, `planning.md`, `reviewing.md`, nothing else |

- [x] **Step 3: Commit.**

```bash
git add skills/orchestrating/SKILL.md
git commit -m "feat: the orchestrating skill's map: legs, stops, where work stands, Quartz duties, fallbacks" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: `brainstorming` hands the approved spec to `orchestrating`; the off-ramp (spec §6.1; R2, R7; E10)

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [x] **Step 1: The HARD-GATE.** Replace:
```text
This applies to EVERY project regardless of perceived simplicity.
```
with:
```text
This applies to EVERY project regardless of perceived simplicity, except an off-ramp case (below).
```

- [x] **Step 2: "This Is Too Simple", and the off-ramp section after it.** Replace:
```text
Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.
```
with:
```text
Every project goes through this process, except an off-ramp case (below). A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## The Off-Ramp (Experiment)

A request may skip the relay (no design, spec or plan) only when it is one of: a typo; a one-line config change; a rename; a single obvious bugfix; a question that changes no files. For any of them except the question, say which case it matches and ask, in a message of its own: "This looks like an off-ramp case (*a one-line config change*). I'd do it directly, with no spec or plan. OK?" Skip the relay only on a yes. When the owner already said to just do it, that is the yes. Anything not on the list, or any doubt, goes through the relay without asking. If the work turns out bigger than one change, stop and take it through the relay.
```

- [x] **Step 3: Checklist item 10.** Replace:
```text
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```
with:
```text
10. **Hand over to the relay** — invoke `hyper-relay:orchestrating`: its planner leg dispatches a planner, which writes the plan. Do not write the plan, and do not invoke `writing-plans`.
```

- [x] **Step 4: The flow diagram's end node.** Replace:
```text
    "Invoke writing-plans skill" [shape=doublecircle];
```
with:
```text
    "Invoke orchestrating skill" [shape=doublecircle];
```

Replace:
```text
    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
```
with:
```text
    "User reviews spec?" -> "Invoke orchestrating skill" [label="approved"];
```

- [x] **Step 5: The terminal state.** Replace:
```text
**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is writing-plans.
```
with:
```text
**The terminal state is invoking `hyper-relay:orchestrating`.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is `orchestrating`, whose planner leg writes the plan.
```

- [x] **Step 6: The held-back spec's pointer.** Replace:
```text
and leave the commit for after that branch merges (`hyper-relay:executing-plans`' `dispatching.md`, step 9).
```
with:
```text
and leave the commit for after that branch merges (`hyper-relay:orchestrating`'s `reviewing.md`, §5).
```

- [x] **Step 7: "Implementation".** Replace:
```text
- Invoke the writing-plans skill to create a detailed implementation plan
- Do NOT invoke any other skill. writing-plans is the next step.
```
with:
```text
- Once the user approves the written spec, invoke `hyper-relay:orchestrating`: its planner leg dispatches a planner, which writes the plan. The approval is the go-ahead; do not ask again.
- Do not write the plan yourself, and do not invoke `writing-plans`. Do NOT invoke any other skill: `orchestrating` is the next step.
```

- [x] **Step 8: Check.**

| Run | Expected |
|---|---|
| `git grep -n -i -e 'invoke writing-plans' -e 'invoke the writing-plans' -e 'invoking writing-plans' -e 'writing-plans is the next step' -e 'executing-plans' -- skills/brainstorming` | no output |
| `git grep -c 'hyper-relay:orchestrating' -- skills/brainstorming/SKILL.md` | `skills/brainstorming/SKILL.md:4` |
| `git grep -c 'except an off-ramp case (below)' -- skills/brainstorming/SKILL.md` | `skills/brainstorming/SKILL.md:2` |
| `git grep -n '^## The Off-Ramp (Experiment)$' -- skills/brainstorming/SKILL.md` | one line, just before `## Checklist` |

- [x] **Step 9: Commit.**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: brainstorming hands the approved spec to orchestrating; the off-ramp asks first" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 5: `writing-plans` is the planner's; the plan reviewer checks this format (spec §6.2; R3, R8, R11; E7, E8, E13)

**Files:**
- Modify: `skills/writing-plans/SKILL.md`
- Rewrite: `skills/writing-plans/plan-document-reviewer-prompt.md`

- [x] **Step 1: The description and the Context line.** In `skills/writing-plans/SKILL.md`, replace:
```text
description: Use when you have a spec or requirements for a multi-step task, before touching code
```
with:
```text
description: Use when dispatched as a planner to write an implementation plan from an approved spec (the planner agents preload it). An orchestrator with an approved spec uses orchestrating instead, which dispatches the planner.
```

Replace:
```text
The orchestrator sets up a branch or a worktree at the handoff (`hyper-relay:executing-plans`' `dispatching.md`), and the dispatch prompt tells the executor where it is.
```
with:
```text
The orchestrator sets up a branch or a worktree at the handoff (`hyper-relay:orchestrating`'s `dispatching.md`), and the dispatch prompt tells the executor where it is.
```

- [x] **Step 2: The spec's plan count, and the Quartz pointer.** Replace:
```text
If they differ, stop and ask the user before writing any plan. Once they approve a different number, update the spec's `**Plans:**` line to it, adding the line for more than one plan and removing it for one, and commit the spec as "Committing the plan" below says. The hooks upload the changed spec, which updates the card's expected count.
```
with:
```text
If they differ, stop before writing any plan and report the mismatch to the orchestrator: the number you would write, and why. It asks the owner, updates the spec's `**Plans:**` line itself (`hyper-relay:orchestrating`'s `planning.md`), and dispatches you again. Never edit the spec: you write plans only.
```

Replace:
```text
the orchestrator runs both, at dispatch and after verifying the executor's report (`hyper-relay:executing-plans`' `dispatching.md`).
```
with:
```text
the orchestrator runs both, at dispatch and after verifying the executor's report (`hyper-relay:orchestrating`'s `dispatching.md`).
```

- [x] **Step 3: Committing, and after saving (E8).** Replace:
```text
Commit a plan, or a spec you updated, only while the repo's main checkout is on `main`:
```
with:
```text
Commit a plan only while the repo's main checkout is on `main`:
```

Replace:
```text
When the main checkout is on another branch, a plan is running there (a branch run). Do not commit, and do not edit a file that is already committed:
- a new plan, or a spec you created during the run: run `quartz link-doc <path>` (it puts an uncommitted doc on its cards; skip it without Quartz), and report that it is held back. The orchestrator commits it after that branch merges (`dispatching.md`, step 9);
- a committed spec whose `**Plans:**` line must change: report the change; it is made after the merge.
```
with:
```text
When the main checkout is on another branch, a plan is running there (a branch run). Do not commit, and do not edit a file that is already committed. Run `quartz link-doc <path>` on your new plan (it puts an uncommitted doc on its cards; skip it without Quartz), and report that it is held back. The orchestrator commits it after that branch merges (`hyper-relay:orchestrating`'s `reviewing.md`, §5).
```

Replace:
```text
Commit it (above), report its path and task count, and stop. Do not offer ways to execute it and do not start executing: once the owner approves the plan, the orchestrator runs the handoff in `hyper-relay:executing-plans`' `dispatching.md`.
```
with:
```text
Commit it (above), report its path and task count to the orchestrator, and stop. Do not offer ways to execute it and do not start executing: the orchestrator checks the plan, stops for the owner, and runs the handoff (`hyper-relay:orchestrating`'s `planning.md` and `dispatching.md`).
```

- [x] **Step 4: The plan format the orchestrator checks (E7, confirmed by the owner 2026-11-18).**
  Replace:
```text
## Task Structure
```
with:
```text
## Spec coverage and the acceptance task

- After the header, a **Spec coverage** table maps each `## ` section of the spec to the task numbers that implement it. With sibling plans, each plan has a **Contract** section, identical in each.
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), with its command or action and the result that counts as PASS.

## Task Structure
```

- [x] **Step 5: The plan reviewer's prompt.** Write `skills/writing-plans/plan-document-reviewer-prompt.md` with
  exactly:

````markdown
# Plan Document Reviewer Prompt Template

Use this template when the owner, at stop 3, asks for a plan review (`hyper-relay:orchestrating`'s `planning.md`).
Dispatch a general-purpose agent: in Claude Code with `model: sonnet`; in OpenCode, the `general` subagent.

**Purpose:** Check a plan against its spec and the plan format before the owner reads it. The reviewer only reads.

```
Agent tool (general-purpose, model: sonnet):
  description: "Review plan document"
  prompt: |
    You are a plan document reviewer. You only read: never edit, write, commit or run
    anything that changes a file. Read the plan and its spec in full.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Check | What to look for |
    |---|---|
    | Spec coverage | Every requirement in the spec has a task that implements it. The plan's **Spec coverage** table maps every `## ` section of the spec to at least one task, and those tasks do that section's work. |
    | Placeholders | "TBD", "TODO", "implement later", "fill in details", "Similar to Task N", or a step that says what to do without the code or text to do it. |
    | Consistent names | A file, function, flag, heading or section named one way in one task and another way in a later one. |
    | `Plan-Task:` trailers | Each task with a commit step: its final commit carries `Plan-Task: <this plan's path>#<N>` once, with its own task number and this plan's own path. |
    | The acceptance task | It is the last task. Each of its steps says who runs it (`reviewer`, `owner` or `after merge`), with its command or action and the result that counts as PASS. |
    | Execution notes | Present: how to commit, what is not the executor's, the full gates. |
    | External facts | Each fact the spec asks to re-verify is cited with its URL and the date it was checked; a difference is listed as a deviation. |
    | Buildability | Could an executor follow every step without getting stuck or guessing? |

    ## Calibration

    An issue **blocks execution** when an executor would build the wrong thing or get
    stuck, or when a check above fails. Wording, style and "nice to have" are advisory.

    ## Output Format

    ## Plan Review

    **Status:** Ready | Blocking issues found

    **Blocking issues (must be fixed before execution):**
    - [Task X, Step Y]: [the issue] - [why it blocks execution]

    **Advisory (does not block):**
    - [Task X, Step Y]: [the suggestion]
```

**Reviewer returns:** the status, the blocking issues and the advisory ones. The orchestrator gives them to the
planner, which revises the plan and commits it again.
````

- [x] **Step 6: Check.**

| Run | Expected |
|---|---|
| `git grep -n -e 'executing-plans' -e 'step 9' -e 'ask the user' -e 'a spec you' -- skills/writing-plans/SKILL.md` | exactly one line: the header template's `REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it)` |
| `git grep -c 'hyper-relay:orchestrating' -- skills/writing-plans/SKILL.md` | `skills/writing-plans/SKILL.md:5` |
| `sed -n '1,4p' skills/writing-plans/SKILL.md` | the front matter, `name: writing-plans` and the new one-line description |
| `git grep -n -e 'Task tool' -e 'Approved' -- skills/writing-plans/plan-document-reviewer-prompt.md` | no output |

- [x] **Step 7: Commit.**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: writing-plans is the planner's skill; the plan reviewer checks this plan format" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#5
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 6: `executing-plans`, `using-git-worktrees` and `agents` point at `orchestrating` (spec §6.3, §6.5; R8)

**Files:**
- Modify: `skills/executing-plans/SKILL.md`, `skills/using-git-worktrees/SKILL.md`, `skills/agents/SKILL.md`

- [ ] **Step 1: `executing-plans`' description and first body line.** In `skills/executing-plans/SKILL.md`, replace:
```text
description: Use when an approved implementation plan is to be executed. The executor dispatched to run one plan follows this file; an orchestrator handing a plan off at the plan-to-execute handoff reads dispatching.md beside it instead, and never executes the plan itself.
```
with:
```text
description: Use when an approved implementation plan is to be executed. The executor dispatched to run one plan follows this file; an orchestrator handing a plan off uses orchestrating instead, and never executes the plan itself.
```

Replace:
```text
**Handing a plan off, as the orchestrator?** Read `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this
SKILL.md) and follow it instead of this file. You never execute a plan yourself.
```
with:
```text
**Handing a plan off, as the orchestrator?** Invoke `hyper-relay:orchestrating` and follow it instead of this file.
You never execute a plan yourself.
```

- [ ] **Step 2: `executing-plans`' Integration.** Replace:
```text
- `hyper-relay:writing-plans` writes the plan; `dispatching.md` hands it to you.
```
with:
```text
- `hyper-relay:orchestrating` hands you the plan (its `dispatching.md`) and owns the review and the merge.
- `hyper-relay:writing-plans` is the planner's: a planner wrote the plan you run.
```

- [ ] **Step 3: `using-git-worktrees`' description.** In `skills/using-git-worktrees/SKILL.md`, replace:
```text
whose executor's worktree is set up (and never entered) by executing-plans' dispatching.md.
```
with:
```text
whose executor's worktree is set up (and never entered) by orchestrating's dispatching.md.
```

- [ ] **Step 4: `agents`' header table.** In `skills/agents/SKILL.md`, replace:
```text
The handoff in `hyper-relay:executing-plans`' `dispatching.md` offers it as this repo's default;
```
with:
```text
The handoff in `hyper-relay:orchestrating`'s `dispatching.md` offers it as this repo's default;
```

- [ ] **Step 5: Check.** Tasks 4–6 together leave no old pointer.

| Run | Expected |
|---|---|
| `git grep -n -E 'executing-plans.{0,6}dispatching' -- skills templates README.md CLAUDE.md` | no output |
| `git grep -n -e 'dispatching\.md' --and --not -e orchestrating -- skills templates ':!skills/orchestrating'` | no output |
| `git grep -n 'dispatching\.md' -- skills templates ':!skills/orchestrating'` | six lines (executing-plans 1, writing-plans 3, using-git-worktrees 1, agents 1), each naming `orchestrating` |
| `git grep -n 'CLAUDE_SKILL_DIR' -- skills/executing-plans` | no output |

- [ ] **Step 6: Commit.**

```bash
git add skills/executing-plans/SKILL.md skills/using-git-worktrees/SKILL.md skills/agents/SKILL.md
git commit -m "docs: executing-plans, using-git-worktrees and agents point at orchestrating" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#6
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 7: `requesting-code-review`: one review per branch, graded (spec §6.4; R4, R5, R11; E11, E13)

**Files:**
- Rewrite: `skills/requesting-code-review/SKILL.md`, `skills/requesting-code-review/code-reviewer.md`

- [ ] **Step 1: The skill.** Write `skills/requesting-code-review/SKILL.md` with exactly:

````markdown
---
name: requesting-code-review
description: Use for a branch's code review before it merges (in the relay, once per branch and last, run by orchestrating's reviewing.md), or ad hoc when stuck, before a refactor, or after a complex bug fix
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they merge. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** one review of the whole branch, last, against its plan and its spec.

## When to Request Review

**Mandatory:**
- Once per branch, after its acceptance check and the fixes it led to, before the merge

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base main <branch>)
HEAD_SHA=$(git rev-parse <branch>)
```

**2. Dispatch code reviewer subagent:**

A general-purpose agent, with `model: sonnet` in Claude Code (in OpenCode, the `general` subagent), given the template at `code-reviewer.md` with its placeholders filled in.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - The plan's path, or what it should do
- `{SPEC}` - The spec's path
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- **Critical:** fixed before the merge. In the relay, the executor fixes it, after the orchestrator checks it against the code with `hyper-relay:receiving-code-review`.
- **Important and Minor:** proposed cards for the owner to keep or drop, or noted in the report. They do not block the merge.
- Push back if the reviewer is wrong (with reasoning).

## Example

```
[Acceptance passed on the branch index-repair; the fixes it led to are committed]

BASE_SHA=$(git merge-base main index-repair)
HEAD_SHA=$(git rev-parse index-repair)

[Dispatch code reviewer subagent, model: sonnet]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: docs/superpowers/plans/2026-11-18-index-repair.md
  SPEC: docs/superpowers/specs/2026-11-18-index-repair-design.md
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

## Integration with Workflows

**In the relay:**
- `hyper-relay:orchestrating`'s `reviewing.md` runs it once per branch, last: after the acceptance check and its fixes, so it reads the final diff
- Critical goes to the executor; Important and Minor become proposed cards

**Ad hoc:**
- Before a merge outside the relay
- When stuck, before refactoring, after a complex bug fix

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Merge with an unfixed Critical issue
- Drop a finding without recording it
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md
````

- [ ] **Step 2: The reviewer's template.** Write `skills/requesting-code-review/code-reviewer.md` with exactly:

````markdown
# Code Reviewer Prompt Template

Use this template when dispatching a code reviewer subagent: a general-purpose agent, with `model: sonnet` in Claude
Code (in OpenCode, the `general` subagent).

**Purpose:** Review a branch's whole diff against its plan, its spec and code quality standards, before it merges.

```
Agent tool (general-purpose, model: sonnet):
  description: "Review code changes"
  prompt: |
    You are a Senior Code Reviewer with expertise in software architecture,
    design patterns, and best practices. Your job is to review completed work
    against its plan and its spec, and identify issues before it merges.

    ## What Was Implemented

    {DESCRIPTION}

    ## Requirements / Plan

    {PLAN_OR_REQUIREMENTS}

    ## Spec

    {SPEC}

    ## Git Range to Review

    **Base:** {BASE_SHA}
    **Head:** {HEAD_SHA}

    ```bash
    git diff --stat {BASE_SHA}..{HEAD_SHA}
    git diff {BASE_SHA}..{HEAD_SHA}
    ```

    ## What to Check

    **Plan and spec alignment:**
    - Does the implementation match the plan / requirements?
    - Is every requirement of the spec met?
    - Are deviations justified improvements, or problematic departures?
    - Is all planned functionality present?

    **Code quality:**
    - Clean separation of concerns?
    - Proper error handling?
    - Type safety where applicable?
    - DRY without premature abstraction?
    - Edge cases handled?

    **Architecture:**
    - Sound design decisions?
    - Reasonable scalability and performance?
    - Security concerns?
    - Integrates cleanly with surrounding code?

    **Testing:**
    - Tests verify real behavior, not mocks?
    - Edge cases covered?
    - Integration tests where they matter?
    - All tests passing?

    **Production readiness:**
    - Migration strategy if schema changed?
    - Backward compatibility considered?
    - Documentation complete?
    - No obvious bugs?

    ## Grades

    - **Critical:** must be fixed before the merge. A bug, a security hole,
      data loss, or a requirement of the spec that is missing.
    - **Important:** should be fixed, but can wait for a card. Architecture
      problems, poor error handling, test gaps.
    - **Minor:** polish. Code style, optimization opportunities, documentation.

    ## Calibration

    Grade issues by actual severity. Not everything is Critical.
    Acknowledge what was done well before listing issues — accurate praise
    helps the implementer trust the rest of the feedback.

    If you find significant deviations from the plan, flag them specifically
    so the implementer can confirm whether the deviation was intentional.
    If you find issues with the plan or the spec itself rather than the
    implementation, say so.

    ## Output Format

    ### Strengths
    [What's well done? Be specific.]

    ### Issues

    #### Critical (Must Fix Before the Merge)
    [Bugs, security holes, data loss, missing spec requirements]

    #### Important (Should Fix, Can Wait for a Card)
    [Architecture problems, poor error handling, test gaps]

    #### Minor (Polish)
    [Code style, optimization opportunities, documentation polish]

    For each issue:
    - File:line reference
    - What's wrong
    - Why it matters
    - How to fix (if not obvious)

    ### Recommendations
    [Improvements for code quality, architecture, or process]

    ### Assessment

    **Ready to merge?** [Yes | No | With fixes]

    **Reasoning:** [1-2 sentence technical assessment]

    ## Critical Rules

    **DO:**
    - Grade by actual severity
    - Be specific (file:line, not vague)
    - Explain WHY each issue matters
    - Acknowledge strengths
    - Give a clear verdict

    **DON'T:**
    - Say "looks good" without checking
    - Mark nitpicks as Critical
    - Give feedback on code you didn't actually read
    - Be vague ("improve error handling")
    - Avoid giving a clear verdict
```

**Placeholders:**
- `{DESCRIPTION}` — brief summary of what was built
- `{PLAN_OR_REQUIREMENTS}` — the plan's path, or what it should do
- `{SPEC}` — the spec's path (for ad hoc work without one: "none")
- `{BASE_SHA}` — starting commit: for a branch, `git merge-base main <branch>`
- `{HEAD_SHA}` — ending commit: the branch's head

**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment

## Example Output

```
### Strengths
- Clean database schema with proper migrations (db.ts:15-42)
- Comprehensive test coverage (18 tests, all edge cases)
- Good error handling with fallbacks (summarizer.ts:85-92)

### Issues

#### Important
1. **Missing help text in CLI wrapper**
   - File: index-conversations:1-31
   - Issue: No --help flag, users won't discover --concurrency
   - Fix: Add --help case with usage examples

2. **Date validation missing**
   - File: search.ts:25-27
   - Issue: Invalid dates silently return no results
   - Fix: Validate ISO format, throw error with example

#### Minor
1. **Progress indicators**
   - File: indexer.ts:130
   - Issue: No "X of Y" counter for long operations
   - Impact: Users don't know how long to wait

### Recommendations
- Add progress reporting for user experience
- Consider config file for excluded projects (portability)

### Assessment

**Ready to merge: Yes**

**Reasoning:** No Critical issues. The two Important ones (help text, date validation) can wait for cards; neither affects core functionality.
```
````

- [ ] **Step 3: Check.**

| Run | Expected |
|---|---|
| `git grep -n -i -e 'each task' -e 'per.task' -e 'next task' -e 'task [0-9]' -e 'completing tasks' -e 'subagent-driven' -- skills/requesting-code-review` | no output |
| `git grep -c '{SPEC}' -- skills/requesting-code-review` | `skills/requesting-code-review/SKILL.md:1` and `skills/requesting-code-review/code-reviewer.md:2` |
| `git grep -n -e 'Merge with an unfixed Critical issue' -e 'Drop a finding without recording it' -- skills/requesting-code-review/SKILL.md` | two lines |
| `sed -n '1,4p' skills/requesting-code-review/SKILL.md` | the front matter, `name: requesting-code-review` and the new description |

- [ ] **Step 4: Commit.**

```bash
git add skills/requesting-code-review/SKILL.md skills/requesting-code-review/code-reviewer.md
git commit -m "feat: requesting-code-review is one review per branch, graded Critical, Important, Minor" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#7
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 8: The planner and reviewer templates (spec §7; E9)

**Files:**
- Modify: `templates/agents/planner.md`, `templates/agents/reviewer-commands.md`, `templates/agents/reviewer-browser.md`
- Test (unchanged, run): `tests/hyper-relay-agents/run-tests.sh`

- [ ] **Step 1: The planner's plan format.** In `templates/agents/planner.md`, replace:
```text
  **Execution notes**, tasks with FULL code, and a **Spec ambiguities / deviations** table. Mirror the newest plans
  in `docs/superpowers/plans/` for format.
```
with:
```text
  **Execution notes**, tasks with FULL code, and a **Spec ambiguities / deviations** table. Mirror the newest plans
  in `docs/superpowers/plans/` for format.
- Also in the plan: a **Spec coverage** table mapping each `## ` section of the spec to the task numbers that
  implement it; with sibling plans, a **Contract** section, identical in each.
```

- [ ] **Step 2: The planner's acceptance bullet.** Replace:
```text
- A plan ends with its acceptance task. The checklist gives, for each step, the command or action and the result
  that counts as PASS, so the reviewer or the owner can run it as written.
```
with:
```text
- A plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by
  the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the
  orchestrator: live sessions, reinstalls, edits outside the repo); and it gives its command or action and the
  result that counts as PASS, so it can be run as written.
```

- [ ] **Step 3: The planner's Committing (E9).** Replace:
```text
4. If the commit prints a `quartz:` warning: `quartz link-doc <plan path>`.
```
with:
```text
4. If `git add` or `git commit` fails on `index.lock` ("Unable to create '…/index.lock': File exists"), a sibling
   planner is committing beside you: run the same command once more. (The guard refuses `sleep`; the new call is
   the wait.)
5. If the commit prints a `quartz:` warning: `quartz link-doc <plan path>`.
```

- [ ] **Step 4: The commands reviewer.** In `templates/agents/reviewer-commands.md`, replace:
```text
  Performs the acceptance check for ONE {{project}} plan ({{root}}) on its branch: runs the plan's acceptance
  checklist as written (commands, test suites, and any live session or screen it names) and reports PASS / FAIL /
  NEEDS-HUMAN per step plus everything that looked off. Report-only: never edits code or docs, never ticks, merges
  or pushes, never installs anything or changes the owner's setup. The dispatch prompt names the plan and its
  acceptance task, the checkout (the main checkout or a worktree), and the evidence folder.
```
with:
```text
  Performs the acceptance check for ONE {{project}} plan ({{root}}) on its branch: runs only the acceptance steps
  the dispatch names, the plan's `reviewer` steps, as written (commands, test suites, and any live session or screen
  they name) and reports PASS / FAIL / NEEDS-HUMAN per step plus everything that looked off. Report-only: never edits
  code or docs, never ticks, merges or pushes, never installs anything or changes the owner's setup. The dispatch
  prompt names the plan and its acceptance task, the steps to run, the checkout (the main checkout or a worktree),
  and the evidence folder.
```

Replace:
```text
1. Read the plan's acceptance task in full (the dispatch names it). Read only what you need from `CLAUDE.md`.
```
with:
```text
1. Read the plan's acceptance task in full (the dispatch names it). You run only the steps the dispatch names, the
   plan's `reviewer` steps; its `owner` and `after merge` steps are not yours. Read only what you need from
   `CLAUDE.md`.
```

- [ ] **Step 5: The browser reviewer.** In `templates/agents/reviewer-browser.md`, replace:
```text
  Performs the owner's click-through (acceptance by clicking) for ONE {{project}} plan ({{root}}) on an
  already-running stack, with the Playwright MCP browser, and reports PASS / FAIL / NEEDS-HUMAN per checklist step
  plus everything that looked off. Report-only: never edits code or docs, never ticks, merges, pushes or takes a
  stack down. The dispatch prompt names the plan and its click-through task, the stack name and URLs, any extra
  logins, and the evidence folder.
```
with:
```text
  Performs the owner's click-through (acceptance by clicking) for ONE {{project}} plan ({{root}}) on an
  already-running stack, with the Playwright MCP browser: runs only the acceptance steps the dispatch names, the
  plan's `reviewer` steps, and reports PASS / FAIL / NEEDS-HUMAN per step plus everything that looked off.
  Report-only: never edits code or docs, never ticks, merges, pushes or takes a stack down. The dispatch prompt
  names the plan and its click-through task, the steps to run, the stack name and URLs, any extra logins, and the
  evidence folder.
```

Replace:
```text
1. Read the plan's click-through task in full (the dispatch names it). Read only what you need from
   `CLAUDE.md`.
```
with:
```text
1. Read the plan's click-through task in full (the dispatch names it). You run only the steps the dispatch names,
   the plan's `reviewer` steps; its `owner` and `after merge` steps are not yours. Read only what you need from
   `CLAUDE.md`.
```

- [ ] **Step 6: Check.**

| Run | Expected |
|---|---|
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` (unchanged: no assertion touches this wording) |
| `git grep -c -F 'reviewer`' -- templates/agents` | `templates/agents/planner.md:1`, `templates/agents/reviewer-browser.md:2`, `templates/agents/reviewer-commands.md:2` |
| `git grep -n -e 'index.lock' -e 'Spec coverage' -- templates/agents/planner.md` | two lines |

- [ ] **Step 7: Commit.**

```bash
git add templates/agents/planner.md templates/agents/reviewer-commands.md templates/agents/reviewer-browser.md
git commit -m "feat: the planner writes spec coverage and who runs each acceptance step; reviewers run only theirs" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#8
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 9: README and `CLAUDE.md` say what the repo now does; the full gates (spec §8, §10.1; E1, E14)

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: README's status.** Replace:
```text
> **Status: 0.1.0.** This release moves the skills into a versioned plugin with **no behaviour change**. Later releases
> add the role agents, per-repo configuration and the orchestrator (see [Roadmap](#roadmap)).
```
with:
```text
> **Status: 0.1.0.** The skills, the role agents, per-repo configuration and the orchestrator are in. Still to come:
> several plans at once, a disposable stack per worktree and the docs' own folder (see [Roadmap](#roadmap)).
```

- [ ] **Step 2: README's relay table, and the line under it.** Replace:
```text
| Plan | `writing-plans` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with full code, tests and a binding contract between plans |
```
with:
```text
| Plan | `writing-plans`, run by a planner agent | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with full code, tests and a binding contract between plans |
```

Replace:
```text
| Review | `verification-before-completion`, `requesting-code-review`, `receiving-code-review` | Evidence that it works: tests, then a click-through of the running app |
```
with:
```text
| Review | the acceptance reviewer agent, `requesting-code-review` (one review per branch), `receiving-code-review`, `verification-before-completion` | Evidence that it works: the plan's acceptance steps, one code review of the whole branch, then your click-through |
```

Replace:
```text
| Finish | `finishing-a-development-branch` | A merge, on your call |

Also in the box:
```
with:
```text
| Finish | `finishing-a-development-branch` | A merge, on your call |

`orchestrating` runs the legs from an approved spec to the merge: it dispatches the planner, the executor and the
reviewers, checks what each hands back, and stops for you at four points (the design, the spec, the plan and the
merge).

Also in the box:
```

- [ ] **Step 3: README's roadmap (E1).** Replace:
```text
and stops for you at four points | in progress |
```
with:
```text
and stops for you at four points | on `main` |
```

- [ ] **Step 4: `CLAUDE.md`.** Replace:
```text
- `skills/<name>/`: the 16 skills.
```
with:
```text
- `skills/<name>/`: the 17 skills.
```

- [ ] **Step 5: Commit.**

```bash
git add README.md CLAUDE.md
git commit -m "docs: README and CLAUDE.md say the plugin carries the relay" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#9
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 6: The full gates, once (spec §10.1).**

| Run | Expected |
|---|---|
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one and, at most, `ICON_MISSING`) |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `153 passed, 0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | `51 passed, 0 failed` (untouched; a regression check) |
| `sh tests/add-card-line/run-tests.sh \| tail -n 1` | `… passed, 0 failed` (untouched; a regression check) |
| `git grep -n -E 'executing-plans.{0,6}dispatching' -- skills templates README.md CLAUDE.md` | no output |
| `git grep -n -e 'dispatching\.md' --and --not -e orchestrating -- skills templates ':!skills/orchestrating'` | no output |
| `test -e skills/executing-plans/dispatching.md \|\| echo gone` | `gone` |
| `git grep -n -i 'subagent-driven' -- skills templates README.md CLAUDE.md` | no output |
| `git grep -n -i -e 'each task' -e 'per.task' -e 'next task' -e 'task [0-9]' -e 'completing tasks' -- skills/requesting-code-review` | no output |
| `git grep -n -i -e 'invoke writing-plans' -e 'invoke the writing-plans' -e 'invoking writing-plans' -e 'writing-plans is the next step' -- skills/brainstorming` | no output |
| `git ls-files skills/orchestrating` | exactly `skills/orchestrating/SKILL.md`, `dispatching.md`, `planning.md`, `reviewing.md` |
| `git grep -n -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' -- skills/orchestrating` | no output |
| `git grep -n -i -w -e sat -e pentraze -- skills/orchestrating templates README.md CLAUDE.md` | no output |
| `git status --short` | nothing but `?? tasks/` and untracked files under `docs/superpowers/` that you did not create |

Upstream's live suites are not run (report this): they start real `claude -p` sessions. Then report and stop: Task 10
is not yours. Copy its checklist (Steps 1–17, each with its marker and its PASS) into your report.

### Task 10: Acceptance (spec §10.2, §10.3; R12; E16–E19). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: `relay-reviewer`, before the merge, in the checkout and on the branch (`hyper-relay-d1-orchestrator`)
  its dispatch names, from the checkout's top. It runs Steps 1–7 only.
- **`owner`**: the owner, at the click-through (Steps 8–9).
- **`after merge`**: the orchestrator with the owner, once the owner has merged the branch into `main` and the main
  checkout `/home/noob_master/hyper-relay` is on `main` (Steps 10–17). The orchestrator runs the commands; the owner
  starts the live sessions.

**This plan's run follows the design by hand (R12):** after the `reviewer` steps and their fixes, the orchestrator runs
one code review of the branch on Sonnet (`requesting-code-review`'s template, range
`$(git merge-base main hyper-relay-d1-orchestrator)..hyper-relay-d1-orchestrator`, this plan and the spec), and its
stop-4 report gives the acceptance reviewer's and the code reviewer's token counts against the executor's.

- [ ] **Step 1 (`reviewer`): The manifests and the skill count.**
  - Run `claude plugin validate .`. PASS: it passes (exit 0), and its warnings are the root `CLAUDE.md` one and, at
    most, `ICON_MISSING`.
  - Run `git ls-files 'skills/*/SKILL.md' | wc -l`. PASS: `17`.

- [ ] **Step 2 (`reviewer`): The suites.**
  - Run `sh tests/hyper-relay-agents/run-tests.sh | tail -n 1`. PASS: `153 passed, 0 failed`.
  - Run `sh tests/hyper-relay-agents/guard-test.sh | tail -n 1`. PASS: `51 passed, 0 failed`.
  - Run `sh tests/add-card-line/run-tests.sh | tail -n 1`. PASS: the line ends `0 failed`.

- [ ] **Step 3 (`reviewer`): The pointers, and the move.**
  - Run `git grep -n -E 'executing-plans.{0,6}dispatching' -- skills templates README.md CLAUDE.md`. PASS: no output.
  - Run `git grep -n -e 'dispatching\.md' --and --not -e orchestrating -- skills templates ':!skills/orchestrating'`.
    PASS: no output.
  - Run `git grep -n 'dispatching\.md' -- skills templates ':!skills/orchestrating'`. PASS: at least one line, each
    naming `orchestrating` (so the previous check was not vacuous).
  - Run `test -e skills/executing-plans/dispatching.md || echo gone`. PASS: `gone`.
  - Run `git log --follow --format=%h -- skills/orchestrating/dispatching.md | tail -n 1`. PASS: `6579c81`, or a longer
    prefix of it (the file's history followed the `git mv`).

- [ ] **Step 4 (`reviewer`): The old wording is gone.**
  - Run `git grep -n -i 'subagent-driven' -- skills templates README.md CLAUDE.md`. PASS: no output.
  - Run `git grep -n -i -e 'each task' -e 'per.task' -e 'next task' -e 'task [0-9]' -e 'completing tasks' -- skills/requesting-code-review`.
    PASS: no output.
  - Run `git grep -n -i -e 'invoke writing-plans' -e 'invoke the writing-plans' -e 'invoking writing-plans' -e 'writing-plans is the next step' -- skills/brainstorming`.
    PASS: no output.

- [ ] **Step 5 (`reviewer`): The new skill's folder.**
  - Run `ls -A skills/orchestrating`. PASS: exactly `SKILL.md`, `dispatching.md`, `planning.md`, `reviewing.md`.
  - Run `git ls-files skills/orchestrating`. PASS: the same four, under `skills/orchestrating/`.
  - Run `git grep -n -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' -- skills/orchestrating`. PASS: no output (no path on
    this machine).

- [ ] **Step 6 (`reviewer`): Every reference in the new files resolves.** Read `skills/orchestrating/SKILL.md`,
  `planning.md`, `reviewing.md` and `dispatching.md` in full. Then:
  - Run `git grep -h -o -E 'hyper-relay:[a-z-]+' -- skills/orchestrating | sort -u`. PASS: for each
    `hyper-relay:<name>` it prints, `skills/<name>/SKILL.md` is in `git ls-files 'skills/*/SKILL.md'`.
  - Run `ls skills/writing-plans/plan-document-reviewer-prompt.md skills/requesting-code-review/code-reviewer.md skills/brainstorming/scripts/add-card-line.sh`.
    PASS: three paths, no error (the files the new skill names by `../` paths exist).
  - Run `git grep -n '^## ' -- skills/orchestrating`. PASS: `dispatching.md` has §1–§7, `planning.md` §1–§4,
    `reviewing.md` §1–§5, and every "`<file>` §N" reference in the four files names a section with that number whose
    heading fits the sentence. List any reference that does not resolve as a FAIL, with its line.

- [ ] **Step 7 (`reviewer`): `${CLAUDE_SKILL_DIR}` references in the skills this plan touches.** Run
  `git grep -n 'CLAUDE_SKILL_DIR' -- skills/orchestrating skills/brainstorming skills/executing-plans skills/writing-plans skills/requesting-code-review`.
  PASS: five lines, four in `skills/orchestrating/SKILL.md` and one in `skills/brainstorming/SKILL.md`, and each also
  names, on the same line, the same file relative to its skill (for example "(`planning.md` beside this SKILL.md)" or
  "(`../brainstorming/scripts/add-card-line.sh` from this SKILL.md)"). (Other skills' references, in
  `visual-companion` and `voice-to-specs`, predate this plan and name their files in a nearby sentence.)

- [ ] **Step 8 (`owner`): The map.** Read it on the branch:
  `git -C /home/noob_master/hyper-relay show hyper-relay-d1-orchestrator:skills/orchestrating/SKILL.md`. PASS: the
  legs, the four stops and the "Finding where work stands" table read as the approved design; the owner says so.

- [ ] **Step 9 (`owner`): The off-ramp.** Read the "The Off-Ramp (Experiment)" section in
  `git -C /home/noob_master/hyper-relay show hyper-relay-d1-orchestrator:skills/brainstorming/SKILL.md`. PASS: the
  owner agrees with it as written (spec §6.1's text).

- [ ] **Step 10 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh` (last line) | `153 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/guard-test.sh` (last line) | `51 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/add-card-line/run-tests.sh` (last line) | ends `0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings only the root `CLAUDE.md` one and, at most, `ICON_MISSING` |
| `git -C /home/noob_master/hyper-relay status --short` | nothing but the owner's untracked `tasks/` |

- [ ] **Step 11 (`after merge`): Push, then the owner reinstalls.** The version stays 0.1.0.

```bash
git -C /home/noob_master/hyper-relay push origin main
```
Then the owner runs `/plugin install hyper-relay@hyper-relay` **in a Claude Code session** (the shell's
`claude plugin install` moves only the marketplace clone, not the cache: spec §11). Then:

| Run | PASS |
|---|---|
| `git -C /home/noob_master/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD` and `git -C /home/noob_master/hyper-relay rev-parse main` | the same SHA |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/orchestrating/SKILL.md && echo orchestrating` | `orchestrating` |
| `test -e /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/skills/executing-plans/dispatching.md \|\| echo gone` | `gone` |
| `git -C /home/noob_master/hyper-relay show main:.claude-plugin/plugin.json` | `"version": "0.1.0"` |

If a check fails, stop and tell the owner; do not delete or uninstall anything. Sessions started before the reinstall
keep the old copy.

- [ ] **Step 12 (`after merge`): Regenerate both repos' agents (§10.3 step 2; E19).**

Before:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check` | exactly `relay-planner: out of date` and `relay-reviewer: out of date`; exit 1 |
| `cd /home/noob_master/sat.pentraze.com && /home/noob_master/hyper-relay/bin/hyper-relay-agents --check` | exactly `sat-planner: out of date` and `sat-reviewer: out of date`; exit 1 |

Back up the current agents:
```bash
mkdir -p /tmp/hr-d1-agents-before/hyper-relay /tmp/hr-d1-agents-before/sat
cp /home/noob_master/hyper-relay/.claude/agents/relay-planner.md /home/noob_master/hyper-relay/.claude/agents/relay-reviewer.md /tmp/hr-d1-agents-before/hyper-relay/
cp /home/noob_master/sat.pentraze.com/.claude/agents/sat-planner.md /home/noob_master/sat.pentraze.com/.claude/agents/sat-reviewer.md /tmp/hr-d1-agents-before/sat/
```

Regenerate, and show the owner each diff:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents` | `written .claude/agents/relay-planner.md`, `unchanged .claude/agents/relay-executor.md`, `written .claude/agents/relay-reviewer.md`, `unchanged .claude/hooks/hyper-relay-planner-guard.py`, and the last line `Start a new session to use them: a running session keeps the agent definitions it loaded.`; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && /home/noob_master/hyper-relay/bin/hyper-relay-agents` | `written .claude/agents/sat-planner.md`, `unchanged .claude/agents/sat-executor.md`, `written .claude/agents/sat-reviewer.md`, `unchanged .claude/hooks/hyper-relay-planner-guard.py`, the restart line last; exit 0 |
| `git diff --no-index /tmp/hr-d1-agents-before/hyper-relay/relay-planner.md /home/noob_master/hyper-relay/.claude/agents/relay-planner.md`, then the same for `relay-reviewer.md`, and for SAT's `sat-planner.md` and `sat-reviewer.md` | the planner gains the Spec coverage / Contract bullet, the acceptance bullet naming `reviewer`, `owner` and `after merge`, and the `index.lock` step (Committing renumbered to 5 steps); the reviewer's description and "Before you start" step 1 name the `reviewer` steps; the marker line's hash changes; nothing else; the owner agrees |
| `cd /home/noob_master/hyper-relay && bin/hyper-relay-agents --check`, then the same in SAT | nothing, exit 0, from each |

Then the owner starts a new session: this one keeps the agent definitions it loaded (spec §11).

- [ ] **Step 13 (`after merge`): The owner's `~/.claude/CLAUDE.md` (§10.3 step 3; E5).** The file is not tracked
  (`git -C /home/noob_master ls-files .claude/CLAUDE.md` prints nothing), so there is nothing to commit. **Show the
  owner this text before editing, and edit only on the owner's OK.** In `/home/noob_master/.claude/CLAUDE.md`, replace
  everything from the line `## Workflow: Brainstorm → Spec → Plan → Execute` up to, not including, the line
  `## Code Quality` with:

```markdown
## Workflow: the relay

All creative work — new features, new components, new functionality, behaviour changes
— runs through hyper-relay's relay. Start any change to files with `hyper-relay:brainstorming`:
it designs the work and writes the spec with me, or, for an off-ramp case, asks me first.
Once I approve a spec, `hyper-relay:orchestrating` runs the rest: the planner, the plan
check, the handoff, the executor, the reviews and the merge, with its stops for me. It also
finds where work stands after a `/clear` or in a new session, and carries the Quartz duties.
Invoking these skills is mandatory, not a judgment call. A dispatched planner, executor or
reviewer follows its own skill instead.

My habits on top of it:

- **Off-ramp work** that runs to more than a couple of steps: track it in `tasks/todo.md` as
  a plain checklist and close with a short review section. `tasks/todo.md` is a scratch
  tracker **only**: never a plan, never a spec.
- Give me a high-level explanation of what changed as you go.
- Keep each change as small and simple as it can be while still being correct. Touch as
  little code as possible. Simplicity over cleverness.
- Outside of plan execution, 2+ genuinely independent problems (unrelated failing test
  files, several separate bugs, parallel research questions) → `hyper-relay:dispatching-parallel-agents`.

### Quartz

The board is live. Git hooks keep it in step with every commit, and I watch it in the web
app. What to do about it is `hyper-relay:orchestrating`'s (its Quartz duties). On this
machine, brainstorming's card-line script is
`~/hyper-relay/skills/brainstorming/scripts/add-card-line.sh`.

```

(The block ends with one blank line, so `## Code Quality` stays separated.)

| Run | PASS |
|---|---|
| `git -C /home/noob_master grep --no-index -n -e "dispatching.md" -e "executing-plans" -e "Phase gates" -e "skip all four phases" -e "link-branch" -- .claude/CLAUDE.md` | no output |
| `git -C /home/noob_master grep --no-index -c "hyper-relay:orchestrating" -- .claude/CLAUDE.md` | `.claude/CLAUDE.md:2` |
| `git -C /home/noob_master grep --no-index -n "^##" -- .claude/CLAUDE.md` | exactly `## Workflow: the relay`, `### Quartz`, `## Code Quality`, `## Engineering Patterns`, `## Design` |

Record any wording the owner changed.

- [ ] **Step 14 (`after merge`): Live probes (§10.3 step 4; E18).** In throwaway repos without Quartz, each session new
  and started after Steps 11–13. **Setup (the orchestrator),** for each `<dir>` of `/tmp/hr-d1-probe-loop`,
  `/tmp/hr-d1-probe-offramp`, `/tmp/hr-d1-probe-resume` and `/tmp/hr-d1-probe-opencode`:

```bash
git init -q -b main <dir>
```

With the Write tool, these seven files in `<dir>`. `CLAUDE.md`:
```markdown
# Toy

A throwaway repo for probing hyper-relay's orchestrating skill. POSIX sh. Test: `sh test.sh`.
```
`README.md`:
```markdown
# Toy

`greet.sh NAME` prints teh greeting. Scripts recieve one argument.
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
PASS (the generator): `written .claude/agents/toy-planner.md`, `written .claude/agents/toy-executor.md`,
`written .claude/agents/toy-reviewer.md`, `written .claude/hooks/hyper-relay-planner-guard.py`, the restart line last;
exit 0.

**(a) The loop.** The owner starts `cd /tmp/hr-d1-probe-loop && claude` (accepting the trust prompt) and sends:

> The spec docs/superpowers/specs/2026-11-18-toy-bye-design.md is approved.

PASS, in order (the owner watches; the orchestrator checks the git rows):
1. It loads `hyper-relay:orchestrating` and dispatches `toy-planner` in the background; it writes no plan itself.
   `git -C /tmp/hr-d1-probe-loop log --format=%s -- docs/superpowers/plans` prints one commit, made by the planner.
2. Stop 3: one message with the hand-back check's result, the offer "Want a plan review before you read it? …" and
   the handoff question with `branch` as this repo's default. Nothing runs until the owner answers. The owner answers
   `OK, branch`.
3. It runs `git switch -c toy-bye` and dispatches `toy-executor` in the background.
4. After the hand-back: `toy-reviewer` is dispatched with only the plan's `reviewer` step numbers; then a
   general-purpose code review whose Agent call shows `model: sonnet`.
5. Stop 4: one report with the acceptance verdicts and the token counts of the reviewer and the code reviewer against
   the executor's.
6. The owner sends `merge it`, picks the merge-locally option, and, when its `git pull` fails (the repo has no remote),
   tells it to carry on without pulling.

| Run | PASS |
|---|---|
| `git -C /tmp/hr-d1-probe-loop branch --show-current` | `main` |
| `git -C /tmp/hr-d1-probe-loop branch --list toy-bye` | nothing |
| `git -C /tmp/hr-d1-probe-loop log --format='%s%n%(trailers:key=Plan-Task)' main` | the plan's task commits, each with its `Plan-Task:` trailer, after the plan's own commit |
| `cd /tmp/hr-d1-probe-loop && sh test.sh` | `2 passed, 0 failed` |

**(b) The off-ramp.** In `/tmp/hr-d1-probe-offramp`, three new sessions, one message each:
- b1: `Fix the typo 'teh' in README.md`. PASS: it names the off-ramp case (a typo) and asks before editing, in a
  message of its own; `git -C /tmp/hr-d1-probe-offramp status --short` prints nothing at that point. The owner answers
  `no` and ends the session.
- b2: `Just fix the typo 'recieve' in README.md`. PASS: it edits without asking;
  `git -C /tmp/hr-d1-probe-offramp diff -- README.md` shows `recieve` becoming `receive` and nothing else.
- b3: ``Add a `--loud` flag to greet``. PASS: it starts `hyper-relay:brainstorming` (explores, then asks a clarifying
  question) with no off-ramp question; `git -C /tmp/hr-d1-probe-offramp status --short` shows no change to `greet.sh`.
  The owner ends the session.

**(c) Resuming.** In `/tmp/hr-d1-probe-resume` (a committed spec, no plan), a new session: `Pick up the probe spec.`
PASS: it goes to the planner leg (dispatches `toy-planner` in the background) with no brainstorming questions. The
owner may end the session once the planner is dispatched.

**(d) OpenCode (the owner, with a model they pick).** In `/tmp/hr-d1-probe-opencode`, in OpenCode:

> The spec docs/superpowers/specs/2026-11-18-toy-bye-design.md is approved. Load the orchestrating skill and follow it.

PASS: it reaches stop 3: `git -C /tmp/hr-d1-probe-opencode log --format=%s -- docs/superpowers/plans` prints one
commit, made by a subagent, and one message carries the check, the plan-review offer and the handoff question.
**Record** (no pass or fail): whether it offered `hyper-relay:agents` (OpenCode has no `.opencode/agents/` here), and
which subagent it dispatched.

The fix loop is not forced in a probe; it is recorded the first time it runs for real.

- [ ] **Step 15 (`after merge`): The memories (§10.3 step 5).**

(a) SAT's `/home/noob_master/.claude/projects/-home-noob-master-sat-pentraze-com/memory/orchestrator-workflow.md`.
Replace its `description:` line with:
```text
description: "SAT delivery workflow — the main session runs hyper-relay:orchestrating (the relay from approved spec to merge); what is particular to SAT"
```
Replace everything from the line beginning `The main session is the user's interface and orchestrator.` up to and
including the line ending `` worktree back to `main` with `hyper-relay:finishing-a-development-branch`. `` with:
```text
The main session is the user's interface and orchestrator. Since hyper-relay D1 (2026-11-18) the relay
it runs is the `hyper-relay:orchestrating` skill: brainstorm and spec with the owner, then planners
(`sat-planner`, one per plan, in parallel), the plan check and stop 3, the handoff and `sat-executor`
(SAT's `execute:` default is `worktree`), the acceptance reviewer (`sat-reviewer`), one code review
per branch on Sonnet, stop 4, and the owner's merge. Follow the skill; this memory keeps only what
is particular to SAT.
```
Replace everything from the line beginning `**How to apply:**` up to and including the line ending
`the browser walk is part of "done" before the merge step.` with:
```text
**How to apply:** for every new SAT feature, invoke `hyper-relay:orchestrating` once the owner
approves the spec, and follow it. Dispatch prompts still name the shared-machine constraints (which
ports / dev DB an agent must not touch). The project's "acceptance is by clicking" rule still holds —
the click-through is part of "done" before the merge.
```
PASS: `git -C /home/noob_master grep --no-index -c "hyper-relay:orchestrating" -- .claude/projects/-home-noob-master-sat-pentraze-com/memory/orchestrator-workflow.md`
prints `…:3`, and the file's other paragraphs (Worktrees, Custom agents, Click-through reviewer) are unchanged.

(b) This repo's `/home/noob_master/.claude/projects/-home-noob-master-hyper-relay/memory/hyper-relay-handoff-2026-11-17.md`:
replace the sentence ``Next: owner approves spec -> dispatch `relay-planner` (D1's run follows the design by hand).``
with (filling in the merge commit and the date):
```text
**D1 DONE <date>:** merged `<merge commit>`; the relay is now `hyper-relay:orchestrating` (SKILL.md map + planning.md,
dispatching.md moved from executing-plans, reviewing.md); the owner's global CLAUDE.md Workflow is a pointer plus
habits; both repos' agents regenerated. Next: E (`wt`), then D2.
```
and, in that folder's `MEMORY.md`, the handoff line's summary `A,B,C done; D1 brainstorm Q2 open (restart first); F
rename card; read first` with `A, B, C, D1 done; next E (wt), then D2; F rename card; read first`.

- [ ] **Step 16 (`after merge`): Clean up; anything failed?**

```bash
rm -rf /tmp/hr-d1-probe-loop /tmp/hr-d1-probe-offramp /tmp/hr-d1-probe-resume /tmp/hr-d1-agents-before
```
Remove `/tmp/hr-d1-probe-opencode` once the owner has closed OpenCode there. A failed step: fix it on a branch through
the usual spec and plan, merge, push, reinstall (Step 11), and repeat the step. To roll an agent back meanwhile, copy
it from `/tmp/hr-d1-agents-before/` before cleaning up.

- [ ] **Step 17 (`after merge`): Record (E16).** Append to this plan, in the main checkout (on `main`):

```markdown
## Last-task record (Task 10)

- **Before the merge:** relay-reviewer <verdict line>; fix rounds <n, what each changed>; code review on Sonnet:
  Critical <fixed / dropped, why>, proposed cards <kept / dropped>; token counts: executor <n>, acceptance reviewer
  <n>, code reviewer <n>.
- **Owner steps:** <agreed / what changed>.
- **Reinstall, <date>:** marketplace clone at <SHA>; `orchestrating` in the 0.1.0 cache: <yes/no>; the old
  `executing-plans/dispatching.md` gone from it: <yes/no>.
- **Regeneration:** hyper-relay <written / unchanged per agent>; SAT <the same>; diffs agreed <yes/no, changes>.
- **Owner's CLAUDE.md:** replaced <date>; any wording the owner changed.
- **Probes:** (a) <pass/fail, anything it did differently>; (b) b1 <>, b2 <>, b3 <>; (c) <>; (d) OpenCode <pass/fail,
  the model, whether it offered hyper-relay:agents, which subagent it dispatched>.
- **Memories:** SAT's `orchestrator-workflow` and the hyper-relay handoff updated <date>.
```

Commit it, with this task's trailer:
```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md
git -C /home/noob_master/hyper-relay commit -m "docs: piece D1 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md#10
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-18-hyper-relay-d1-orchestrator.md
```
Push it with the next change of `main` (the owner's call).
