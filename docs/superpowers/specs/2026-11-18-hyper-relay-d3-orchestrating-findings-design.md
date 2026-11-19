# hyper-relay D.3: the orchestrating findings from D1 (design)

**Date:** 2026-11-18 · **Status:** design approved by the owner in chat on 2026-11-18
**Card:** orchestrating: findings from D1's review (`e014d2ed-116f-4a9d-9b5e-b6e2566b4cfd`)
**Initiative:** v0.1.0 · **Piece:** D.3 · **Depends on:** D1 (merged `fd0a928`), E.1 (merged `0f2a631`)
**Scope:** this repo: `skills/orchestrating/` (a new `quartz.md`; `SKILL.md`, `planning.md`, `dispatching.md`,
`reviewing.md`), `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, a new
`tests/orchestrating/run-tests.sh`, `README.md`, `CLAUDE.md`. No template changes, so no agent regeneration. One plan.

## Goal

D1's acceptance, its code review and two live probes left nine findings on card D.3. None blocked D1's merge, but
two of them broke the relay in a probe: the orchestrator half set up Quartz in a repo that was on no board (hooks, but
no card, so no `link-branch` and no ticks), and then stop 4 promised a Quartz tick that never came. The rest make a
resumed or a fresh orchestrator do the wrong thing, or the owner miss a question.

D.3 fixes them before D.2 starts, so D.2 builds on files that are right. Above all it defines, in one place, when a
repo uses Quartz, what "configured properly" means there, and what happens when part of that cannot be done.

## Decisions (owner, 2026-11-18)

| # | Question | Decision |
|---|---|---|
| D3.1 | Scope | **Findings 1–4 and 6–9.** Finding 5 (R6's wording) was fixed in `10d7b9f`. |
| D3.2 | The `quartz` CLI is present but the repo is not connected (no `quartz` server in its `.mcp.json`) | **Set it up, without asking first.** The agent does every step it can and asks the owner only for the steps only they can do (a project, the repo added by name, a token). The owner may answer "no Quartz here", and that **no is remembered**: the agent never offers again in that repo. This replaces the fix proposed in the card's note `a2f1eb71` ("ask before installing hooks"), as the owner's note `7d841618` says. |
| D3.3 | Where the no is remembered | **The repo's local git config:** `git config hyper-relay.quartz off`. Machine-local, like the connection itself (the token in `.env`, the wiring in `.mcp.json`); it works in any git repo, with or without `.hyper-relay/agents.md`, covers every worktree, and commits nothing. A facts-file key was rejected: the generator refuses unknown header keys, a repo with no facts file would need one, and it would apply to every clone. |
| D3.4 | Declined and connected at once | **Declined wins.** The check stops at `off`: nothing else is read, offered or said. A declined repo that the owner later connects by hand stays off until `git config --unset hyper-relay.quartz`. |
| D3.5 | How a stop asks (finding 6) | **Questions first, in text,** numbered, before any report; the report follows, short. No question dialog, so Claude Code and OpenCode behave the same. |
| D3.6 | Resuming partway through review (finding 1) | **Card status notes, else ask.** With Quartz, the orchestrator posts a status note on the plan's cards after each review leg; a resumed orchestrator reads it. Without Quartz, or with no note but fix commits on the branch, it asks the owner, naming the fix commits (§5). |
| D3.7 | Layout | **A new `skills/orchestrating/quartz.md`** holds the check, the setup, the ticks and the Quartz duties (moved from `SKILL.md`, which keeps a pointer). `brainstorming` points at it, because it runs before any other leg. |
| D3.8 | A guard for D1's gates (finding 3) | **`tests/orchestrating/run-tests.sh`,** which also guards finding 7: `quartz install-git-hook` is named only in `quartz.md`. |
| D3.9 | Two setup details (owner, at stop 3) | **Setup also excludes `.mcp.json` and `.envrc`** in `.git/info/exclude` when git does not track them, so they never show as `??` in a branch run's clean-tree checks (the planner's P3). **And setup prompts the owner for the token** that `.envrc` loads: when the token check still fails after setup writes its files, the closing message opens by asking the owner to create the token in Quartz's project settings and put it in `.env` as `QUARTZ_TOKEN=<token>`, in their editor, never in the chat (§2.2). |
| D3.10 | Two code-review fixes (owner, at stop 4) | **The `.envrc` line keeps the whole token** (`cut -d= -f2-`, not `-f2`), and **the exclude file is the one `git rev-parse --git-path info/exclude` prints** in the main checkout, not a hard-coded `.git/info/exclude`. Fixed on the branch in `aeb39e5`; §2.2 below follows it. |

## 1. What changes where

| File | Change | Findings |
|---|---|---|
| `skills/orchestrating/quartz.md` | **New.** §1 the check, §2 the setup, §3 ticks, §4 the duties (§2 of this spec) | 7, 8, 1 |
| `skills/orchestrating/SKILL.md` | The Quartz duties section becomes a pointer to `quartz.md`; the list of files beside `SKILL.md` names it; the stops rule (§3); two state-table rows (§5) | 6, 1, 2 |
| `skills/orchestrating/planning.md` | §1's prompt says whether the repo uses Quartz (§7); §2.1's branch-run check (§6); §3's stop-3 order (§3) | 6, 4, 7 |
| `skills/orchestrating/dispatching.md` | §2 and §6's step references become § references; §4's "Without Quartz" points at `quartz.md` §1 (§6, §7) | 4, 7 |
| `skills/orchestrating/reviewing.md` | §1 and §3 post status notes (§4); §2's fix verification (§6); §4's order, its wait for usage, its tick promise (§3, §4); §5's hand ticks (§2.3) | 1, 4, 6, 8, 9 |
| `skills/brainstorming/SKILL.md` | Checklist step 1 becomes the Quartz check, then tick brain; its Quartz conditions point at `quartz.md` §1; the anti-pattern's "a config change" (§6) | 7, 4 |
| `skills/writing-plans/SKILL.md` | The branch-run `quartz link-doc` line follows the dispatch prompt (§7) | 7 |
| `tests/orchestrating/run-tests.sh` | **New** (§8) | 3 |
| `README.md` | The relay diagram; two sentences on setup and declining (§6) | 4, 7 |
| `CLAUDE.md` | The `validate` row; a Checks row for the new test (§6, §8) | 4, 3 |

Every reference to a section of `quartz.md` uses the numbers in §2 below.

## 2. `skills/orchestrating/quartz.md`

### 2.1 §1: Does this repo use Quartz?

Read from files and git every time, never from memory: in `brainstorming`'s step 1, and whenever `orchestrating`
starts or resumes a leg. The tests run in this order, and **the first match decides**:

| # | State | Test | Result |
|---|---|---|---|
| 1 | No CLI | `command -v quartz` fails | **No Quartz.** Plain Markdown and git; nothing is said or offered. |
| 2 | Declined | `git config --get hyper-relay.quartz` prints `off` | **No Quartz.** Nothing else is checked, offered or said, and no Quartz MCP tool is used, even when one is loaded. |
| 3 | Connected | the main checkout's `.mcp.json` has `mcpServers.quartz` with a non-empty `url` (the CLI's own test). The main checkout is the parent of `git rev-parse --path-format=absolute --git-common-dir`. | **Quartz.** The §2 checks run. |
| 4 | Not connected | none of the above | **Setup** (§2), and no Quartz until it is connected. |

"Uses Quartz" means row 3, and only row 3. Every Quartz step in the relay (tick brain, card lines, `link-doc`,
`link-branch`, `quartz review`, status notes, proposed cards) runs only on that result; none has a check of its own.
The `git config` read covers every scope, so `git config --global hyper-relay.quartz off` declines every repo on the
machine. The undo, in either scope, is `--unset`; `quartz.md` gives it.

### 2.2 §2: Setup, without asking first

**Configured properly** means all four: the repo is connected and has a token; Quartz's git hooks are installed; the
work has a card; the spec and the plan carry its card line (a plan through its `**Spec:**` line, as today).

**Not connected (row 4).** One message of its own, which waits for the answer:

> This repo isn't on a Quartz board yet, so I'll connect it. Three steps are yours, in Quartz's web app:
> 1. Create a project (or pick one), and add this repo to it by name.
> 2. Create a token, and put it in this repo's `.env` as `QUARTZ_TOKEN=<token>`. Not in the chat.
> 3. Tell me the repo name, and Quartz's MCP URL if it isn't `http://127.0.0.1:8083/mcp`.
>
> Or say "no Quartz here", and I won't offer this again in this repo.

- **A no:** run `git config hyper-relay.quartz off`, reply in one line that names the undo
  (`git config --unset hyper-relay.quartz`), and carry on with no Quartz.
- **Neither** (for example "not now"): carry on with no Quartz for this session. The offer comes again in the next
  session, not at the next leg.
- **A repo name:** in the main checkout, without asking again:
  - `.mcp.json`: add a `quartz` server (`"type": "http"`, the URL, and the headers
    `"Authorization": "Bearer ${QUARTZ_TOKEN}"` and `"X-Quartz-Repo": "<repo name>"`), keeping any other servers;
    create the file when there is none.
  - `.envrc`: when it has no `QUARTZ_TOKEN` line, append `watch_file .env` and
    `export QUARTZ_TOKEN=$(grep '^QUARTZ_TOKEN=' .env 2>/dev/null | cut -d= -f2-)` (D3.10).
  - `.env` ignored: `git check-ignore -q .env` succeeds, or add a `.env` line to the file `git rev-parse --git-path info/exclude`
    prints (D3.10). The same for
    `.mcp.json` and `.envrc` when git does not track them (D3.9).
  - `quartz install-git-hook`.
  - Then one message. When the token check (below) fails, it opens with the prompt for the token (D3.9): create it in
    the project's settings in Quartz's web app, and put it in `<main checkout>/.env` as `QUARTZ_TOKEN=<token>`, in an
    editor, never in the chat; `.envrc` loads it from there. Then: run `direnv allow`, then restart the session from
    a shell in the repo, so the MCP server and its token load (in Claude Code, `claude --continue` keeps the conversation); without direnv, export `QUARTZ_TOKEN`
    before starting the session. `.mcp.json` and `.envrc` hold no secret and stay untracked: committing them is the
    owner's call.
  - Carry on meanwhile. The relay never waits for the restart; the next check (§1) finishes the setup.
- When `.mcp.json` or `.envrc` is tracked, its edit is a tracked-file edit: during a branch run it waits for the merge
  (`dispatching.md` §6).

**Connected (row 3).** Each check below that cannot complete is a failure (below); the rest still run.

- **Hooks:** run `quartz install-git-hook`. It changes nothing when the hooks are already there.
- **Token:** found when `.env` has a `QUARTZ_TOKEN=` line with a value (`grep -q '^QUARTZ_TOKEN=.' .env`), or
  `QUARTZ_TOKEN` is set in the environment. Never print it.
- **MCP:** the Quartz MCP tools are among the session's tools or deferred tools. In OpenCode they also need the
  server in OpenCode's own config.
- **Card** (`brainstorming`'s step 1, with the MCP): the card the owner names; otherwise one in Needs brainstorming
  that matches the work (`list_tasks`); otherwise a new one through `add_tasks`, titled with the work's topic, kind
  `bug` or `change` when one fits, in the initiative the owner names, if any. Say so in one line, with its id. Then
  `tick_brain`.
- **Card lines:** as `brainstorming`'s Documentation says. A card that arrives after its spec was written (the MCP
  loaded late) gets its line then, with `add-card-line.sh`; a spec already committed gets it in a commit of just the
  spec, while the main checkout is on `main`.

**A step that fails** (no token, no MCP in this session, `install-git-hook` refused because `core.hooksPath` is set,
an MCP call that errors): report it once, in one line saying what the owner can do, and carry on. Whatever needs the
missing piece falls back to plain Markdown and git. The next check (§1) retries it. Quartz never blocks the relay.

### 2.3 §3: Ticks

Quartz's post-commit hook ticks a committed task (`Plan-Task:` trailer) only in a **connected** repo whose hooks are
installed. It needs no card and no token.

In any other repo, nothing ticks a committed task. After the merge (`reviewing.md` §5), when the orchestrator ticks
the acceptance task by hand, it ticks every task that has a `Plan-Task:` commit in the same edit, and commits just the
plan: `docs: plan progress, tasks 1–M of M`. Stop 4 says a Quartz tick will come only when this section says it will.

### 2.4 §4: The duties

`SKILL.md`'s Quartz duties, moved here unchanged except:

- "In a repo new to Quartz, run `quartz install-git-hook` once" is gone: §2 replaces it.
- "Each falls back to plain Markdown and git without Quartz" becomes: each runs only when §1 says the repo uses
  Quartz.
- The status notes (§4 of this spec) join the list.

`SKILL.md` keeps, in place of the section: "Quartz: read `quartz.md` beside this file (`${CLAUDE_SKILL_DIR}/quartz.md`)
at the start of every leg. Every Quartz step runs only when its §1 says the repo uses Quartz." Its leg-file list names
`quartz.md` beside the other three.

## 3. The stops (finding 6)

`SKILL.md`'s "The stops" gains a rule:

> A stop that asks anything opens with its questions, numbered, before any report: every question, and every
> decision the owner must make. The report follows, short: one line per item, and nothing the board shows. No
> question comes after the report.

- **Stop 3** (`planning.md` §3), in this order: the decisions the owner must make; "Want a plan review before you read
  it? …"; the handoff question (`dispatching.md` §1, with its warnings). Then the report: the plan paths and task
  counts, the deviations with their resolutions, the re-verified external facts and any differences. A short stop 3
  (after a plan review or changes) keeps the same order.
- **Stop 4** (`reviewing.md` §4), in this order: the proposed cards to keep or drop, one line each, numbered; the
  NEEDS-HUMAN steps and the plan's `owner` steps; where to click through. Then the report: the acceptance verdicts,
  each fix round, the Critical findings fixed or dropped with why, and the token counts.
- Stops 1 and 2 are `brainstorming`'s and already ask one question each: unchanged.

## 4. The review leg (findings 9 and 1)

**Wait for every leg's usage (9).** `reviewing.md` §4 opens with: before writing stop 4, wait for the completion
notification of every agent this run dispatched (the executor and its fix rounds, the acceptance reviewer, the code
reviewer). Its reply arrives before the notification that carries its usage. Where the harness reports no usage,
stop 4 says so.

**Status notes (1).** When the repo uses Quartz and the MCP is loaded, the orchestrator posts a status note
(`add_note`, `status: true`, at most 500 characters) on each of the plan's cards (its card line, or its spec's):

- after `reviewing.md` §2's fix loop ends: `` `<plan path>`: acceptance done, N/M PASS, K NEEDS-HUMAN, F fix rounds. ``
  When the plan has no `reviewer` steps (§1 skips the dispatch), it is posted at that point as
  `` `<plan path>`: acceptance done, no reviewer steps. ``
- after §3's code review and its Critical fixes: `` `<plan path>`: code review done, C Critical (x fixed, y dropped),
  I Important, m Minor. At stop 4. ``

A status replaces the card's previous one, which is enough: the code review runs only after acceptance. A note that
fails is reported once, in one line (§2.2's failure rule).

## 5. Finding where work stands (findings 2 and 1)

Two rows of `SKILL.md`'s state table change.

**"A spec that no plan's `**Spec:**` line names"** (2): the planner leg is **offered**, not assumed. Name the spec and
ask whether to plan it; the owner's yes is the approval. When the owner asked to pick up that spec, the request is the
yes. Never brainstorm it again. (Old specs match the row: B's plan is gitignored, so no committed plan names B's spec.)

**"A plan's branch with all its executor tasks committed"** (1) splits on the card's current status (`get_task`),
counting it only when it names this plan's path:

| Status | Leg |
|---|---|
| None, and no fix commits on the branch | `dispatching.md` §7, then `reviewing.md` §1 |
| "acceptance done" | `reviewing.md` §3 |
| "code review done" | Stop 4 (`reviewing.md` §4) |
| The repo does not use Quartz, or no status but fix commits exist | **Ask the owner** which review legs ran, naming the fix commits |

A fix commit is a commit on `main..<branch>` with no `Plan-Task:` trailer, after the branch's last `Plan-Task:`
commit.

## 6. Wording fixes (finding 4)

- `dispatching.md` §2: "step 4 never runs `quartz link-branch`" becomes "§4 never runs …"; §6: "(step 1)" becomes
  "(§1)". The plan greps the four leg files for any other section reference written as "step N".
- `reviewing.md` §2: "verify it as `dispatching.md` §7 does" becomes "verify it with `dispatching.md` §7's checks 1–4
  (the gates, the new commits, a clean tree, the deviations). `quartz review` does not run again: the cards are
  already In review."
- `planning.md` §2.1, during a branch run: the file exists, and the planner's report says it ran `quartz link-doc`;
  with the Quartz MCP, `get_task` on the card lists the plan among its docs. Without Quartz, the file exists.
- `README.md`'s relay diagram names legs, not skills: `writing-plans` becomes `plan` (a planner agent), and a line
  under the diagram shows `orchestrating` running from the spec to the merge. Its Quartz section gains two sentences:
  in a repo the CLI can see but that is not connected, the relay sets it up and asks the owner only for their steps;
  `git config hyper-relay.quartz off` turns that off, and `--unset` turns it back on.
- `brainstorming`'s anti-pattern: "a config change" becomes "a multi-line config change", so it no longer reads
  against the off-ramp's "a one-line config change".
- `CLAUDE.md`'s `validate` row: passes with three warnings: this `CLAUDE.md` at the plugin root (for developing
  hyper-relay, not for users), `ICON_MISSING`, and, in this checkout only, `PRIVACY_URL_MISSING`, which comes from the
  gitignored `.mcp.json` (Quartz's MCP server).

## 7. One definition, everywhere

Every "with Quartz", "without Quartz" or "when the work has a Quartz card" in the relay's skills means `quartz.md` §1:

- `brainstorming`: step 1 becomes "**Quartz:** run `hyper-relay:orchestrating`'s Quartz check
  (`${CLAUDE_SKILL_DIR}/../orchestrating/quartz.md`, §1 and §2; `../orchestrating/quartz.md` from this SKILL.md). When
  the repo uses Quartz and the work has a card, call `tick_brain` with its id. If it fails, report the failure and
  carry on." Steps 7 and the Documentation bullets keep their card conditions, read through §1.
- `dispatching.md` §4: "Without Quartz, skip this step" becomes "When the repo does not use Quartz (`quartz.md` §1),
  skip this step."
- `planning.md` §1: the planner's prompt gains one item: whether the repo uses Quartz, and when it does not, "run no
  `quartz` command". Planners cannot run the check themselves, and in a declined repo that is still connected their
  `quartz link-doc` would upload.
- `planning.md` §2.1 and `reviewing.md` §4: their "Without Quartz" point at §1.
- `writing-plans`: the branch-run line's "skip it without Quartz" becomes "skip it when your dispatch prompt says the
  repo does not use Quartz".

The planner template (`templates/agents/planner.md`, "If the commit prints a `quartz:` warning: `quartz link-doc`") is
not changed: a declined repo's docs carry no card line, so nothing uploads, and the prompt item above covers the rest.

## 8. The guard test (finding 3)

`tests/orchestrating/run-tests.sh`: POSIX shell run by dash, ending in `N passed, M failed`, exit 1 on any failure,
like the other suites. It reads the working tree (not `git grep`), so an untracked new file counts and it runs in a
worktree. From the repo's top:

1. **D1's gates:**
   - no `executing-plans` followed within six characters by `dispatching` in `skills`, `templates`, `README.md`,
     `CLAUDE.md`;
   - every line naming `dispatching.md` in `skills` and `templates`, outside `skills/orchestrating/`, also names
     `orchestrating`, and at least one such line exists;
   - `skills/executing-plans/dispatching.md` does not exist;
   - no `subagent-driven` (any case) in `skills`, `templates`, `README.md`, `CLAUDE.md`;
   - none of `each task`, `per.task`, `next task`, `task [0-9]`, `completing tasks` (any case) in
     `skills/requesting-code-review`;
   - none of `invoke writing-plans`, `invoke the writing-plans`, `invoking writing-plans`,
     `writing-plans is the next step` (any case) in `skills/brainstorming`.
2. **The folder:** `skills/orchestrating/` holds exactly `SKILL.md`, `dispatching.md`, `planning.md`, `quartz.md`,
   `reviewing.md`.
3. **No machine paths** (`/home/`, `~/`, `/Users/`, `/tmp/`) in `skills/orchestrating/`.
4. **References resolve:** every `hyper-relay:<name>` in `skills/orchestrating/` names a `skills/<name>/SKILL.md`, and
   every "`` `<file>.md` §N ``" in the five files names a file of the folder with a `## N.` heading. Whether the
   heading fits the sentence is left to a reader.
5. **Finding 7's guard:** `quartz install-git-hook` appears in `skills/` only in `skills/orchestrating/quartz.md`.

Each check has a case that proves it can fail: the suite builds a broken copy of the tree in a temp directory and
expects the check to fail there. `CLAUDE.md`'s Checks table gains a row: `sh tests/orchestrating/run-tests.sh`,
expect `0 failed`.

## 9. Acceptance

The plan's last task, its steps marked as D1's are:

- **`reviewer`:** `sh tests/orchestrating/run-tests.sh` (`0 failed`); `sh tests/hyper-relay-agents/run-tests.sh` and
  `guard-test.sh` and `sh tests/add-card-line/run-tests.sh` (unchanged counts, `0 failed`); `claude plugin validate .`
  (passes, with exactly §6's three warnings); `dash -n tests/orchestrating/run-tests.sh` (silent);
  `git ls-files 'skills/*/SKILL.md' | wc -l` (`17`); and a read of `quartz.md` against §2 of this spec.
- **`after merge`** (the orchestrator, with the owner): push `main`; the owner reinstalls; then live probes, each a new
  session in a throwaway repo under `/tmp` with no `.mcp.json`:
  - **(a) Declined, through the loop.** The setup message arrives as a message of its own. The owner answers "no
    Quartz here": `git config --get hyper-relay.quartz` prints `off`, and `.git/hooks/` has no `post-commit` or
    `post-merge` with a `quartz` line. Stop 3 opens with its numbered questions. Stop 4 opens with its questions, comes
    after every leg's notification (with each token count, or "not reported"), and promises no Quartz tick. After the
    merge, every committed task is ticked by hand in the acceptance tick's commit.
  - **(b) Setup that fails partway.** The owner answers with a repo name and no token. The agent writes `.mcp.json`
    and `.envrc`, `.env` is ignored, and the hooks are installed; the missing token and the missing MCP are each
    reported once, in one line, and brainstorming carries on.
  - **(c) Resume without Quartz.** A plan's branch with all its tasks committed and one fix commit after them. A new
    session, asked to pick up the work, asks which review legs ran, naming that commit, and reruns nothing on its
    own.
- The connected path with a real board project is not probed: it would need a project made for the probe. D.3's own
  relay, and every relay after it in this repo, runs it.

## 10. Out of scope

- D.2 (several plans at once).
- `voice-to-specs`' card path: it is not part of the relay and keeps its own test (the MCP tool is loaded).
- Writing OpenCode's MCP config during setup; committing `.mcp.json` or `.envrc`; the machine-wide `quartz install`.
- Probing the connected setup path with a real project (§9).
