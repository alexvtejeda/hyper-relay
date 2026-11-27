# Quartz in the relay

Part of `orchestrating` (`SKILL.md` beside this file is the map). Quartz is the project board the relay keeps in step
with its specs, plans and commits. This file says when a repo uses it (§1), how a repo gets set up (§2), what ticks a
plan's tasks (§3), and the Quartz duties, with the status and decision notes that make the board the record of where
work stands (§4). `orchestrating` reads it once per session, at its first leg, and `hyper-relay:brainstorming` runs
§1 and §2 before its first message, before any other leg, and keeps §4's notes during the brainstorm.

## 1. Does this repo use Quartz?

Read it from files and git every time, never from memory: before `brainstorming`'s first message, and whenever
`orchestrating` starts or resumes a leg. Run the tests in this order; **the first match decides**:

| # | State | Test | Result |
|---|---|---|---|
| 1 | No CLI | `command -v quartz` fails | **No Quartz.** Plain Markdown and git; nothing is said or offered. |
| 2 | Declined | `git config --get hyper-relay.quartz` prints `off` | **No Quartz.** Nothing else is checked, offered or said, and no Quartz MCP tool is used, even when one is loaded. |
| 3 | Connected | the main checkout's `.mcp.json` has `mcpServers.quartz` with a non-empty `url` (the CLI's own test) | **Quartz.** §2's checks run. |
| 4 | Not connected | none of the above | **Setup** (§2), and no Quartz until it is connected. |

The main checkout is the parent of `git rev-parse --path-format=absolute --git-common-dir`. Run row 3's test without
printing the file, which may hold other servers' secrets. This succeeds exactly when the repo is connected:

```sh
jq -e '.mcpServers.quartz.url | strings | length > 0' <main checkout>/.mcp.json >/dev/null 2>&1
```

Without `jq`:

```sh
python3 -c 'import json,sys; u=json.load(open(sys.argv[1])).get("mcpServers",{}).get("quartz",{}).get("url"); sys.exit(not (isinstance(u,str) and u))' <main checkout>/.mcp.json 2>/dev/null
```

"Uses Quartz" means row 3, and only row 3. Every Quartz step in the relay (tick brain, card lines, `link-doc`,
`link-branch`, `quartz review`, status notes, proposed cards) runs only on that result; none has a check of its own.

`git config --get` reads every scope, so `git config --global hyper-relay.quartz off` declines every repo on the
machine. The undo is `--unset`, in the same scope: `git config --unset hyper-relay.quartz`, or
`git config --global --unset hyper-relay.quartz`.

## 2. Setup, without asking first

**Configured properly** means all four: the repo is connected and has a token; Quartz's git hooks are installed; the
work has a card; the spec and the plan carry its card line (a plan through its `**Spec:**` line). Do every step you
can, and ask the owner only for the steps only they can do.

### Not connected (§1, row 4)

Send this as a message of its own. **Setup never holds up a leg:** when the leg dispatches an agent (a planner, an
executor, a reviewer), dispatch it first, then send this while the agent works; the steps below run alongside it. At
`brainstorming`'s start, send it before brainstorming's first message.

> This repo isn't on a Quartz board yet, so I'll connect it. Three steps are yours, in Quartz's web app:
> 1. Create a project (or pick one), and add this repo to it by name.
> 2. Create a token, and put it in this repo's `.env` as `QUARTZ_TOKEN=<token>`. Not in the chat.
> 3. Tell me the repo name, and Quartz's MCP URL if it isn't `http://127.0.0.1:8083/mcp`.
>
> Or say "no Quartz here", and I won't offer this again in this repo.

- **A no:** run `git config hyper-relay.quartz off`, reply in one line that names the undo
  (`git config --unset hyper-relay.quartz`), and carry on with no Quartz.
- **Neither** (for example "not now", or a reply that does not answer it): carry on with no Quartz for this session.
  The offer comes again in the next session, not at the next leg.
- **A repo name:** the steps below, in the main checkout, without asking again.

1. `.mcp.json`: add this `quartz` server, with the owner's URL when they gave one, keeping any other servers; create
   the file when there is none.

   ```json
   { "mcpServers": { "quartz": {
       "type": "http",
       "url": "http://127.0.0.1:8083/mcp",
       "headers": {
         "Authorization": "Bearer ${QUARTZ_TOKEN}",
         "X-Quartz-Repo": "<repo name>"
   } } } }
   ```

2. `.envrc`: when it has no `QUARTZ_TOKEN` line, append these two lines.

   ```sh
   watch_file .env
   export QUARTZ_TOKEN=$(grep '^QUARTZ_TOKEN=' .env 2>/dev/null | cut -d= -f2-)
   ```

3. `.env` ignored: `git check-ignore -q .env` succeeds, or add a `.env` line to the file `git rev-parse --git-path info/exclude` prints (run in the main checkout). Do the same for
   `.mcp.json` and `.envrc` when git does not track them, so they stay out of a branch run's clean-tree checks.
4. Run §1 again. It now gives row 3, so run the checks below (they install the hooks).
5. Then one message. When the token check (below) failed, it opens with the prompt for the token: create it in the
   project's settings in Quartz's web app, and put it in `<main checkout>/.env` as `QUARTZ_TOKEN=<token>`, in an
   editor, never in the chat; `.envrc` loads it from there. Then: run `direnv allow`, then restart the session from a
   shell in the repo, so the MCP server and its token load (in Claude Code, `claude --continue` keeps the
   conversation); without direnv, export `QUARTZ_TOKEN` before starting the session. Then each other check that
   failed, in one line ("A step that fails", below; until the restart, the MCP is one). `.mcp.json` and `.envrc` hold
   no secret and stay untracked: committing them is the owner's call.
6. Carry on meanwhile. The relay never waits for the token or the restart; the next check (§1) finishes the setup.

When `.mcp.json` or `.envrc` is tracked, its edit is a tracked-file edit: during a branch run it waits for the merge
(`dispatching.md` §6).

### Connected (§1, row 3)

Run each check below. One that cannot complete is a failure (below); the rest still run.

- **Hooks:** run `quartz install-git-hook`. It changes nothing when the hooks are already there.
- **Token:** found when the main checkout's `.env` has a `QUARTZ_TOKEN=` line with a value
  (`grep -q '^QUARTZ_TOKEN=.' <main checkout>/.env`), or `QUARTZ_TOKEN` is set in the environment
  (`[ -n "${QUARTZ_TOKEN:-}" ]`). Never print it.
- **MCP:** the Quartz MCP tools (in Claude Code, `mcp__quartz__…`) are among your tools or deferred tools; load a
  deferred one with ToolSearch before calling it. In OpenCode they also need the server in OpenCode's own config.
- **Card** (before `brainstorming`'s first message, with the MCP): the card the owner names; otherwise one in Needs
  brainstorming that matches the work (`list_tasks`); otherwise a new one through `add_tasks`, titled with the work's
  topic, kind `bug` or `change` when one fits, in the initiative the owner names, if any. Say so in one line, with its
  id. Then `tick_brain` with its id.
- **Card lines:** as `brainstorming` says under The Written Design. A card that arrives after its spec was written
  (the MCP loaded late) gets its line then, with brainstorming's script (§4); a spec already committed gets it in a
  commit of just the spec, while the main checkout is on `main`.

**A step that fails** (no token, no MCP in this session, `install-git-hook` refused because `core.hooksPath` is set,
an MCP call that errors): report it once in the session, in one line saying what the owner can do, and carry on.
Whatever needs the missing piece falls back to plain Markdown and git. The next check (§1) retries it. Quartz never
blocks the relay.

## 3. Ticks

Quartz's post-commit hook ticks a committed task (its `Plan-Task:` trailer) only in a **connected** repo (§1, row 3's
test) whose hooks are installed: `grep -q 'quartz hook merge-commit' "$(git rev-parse --git-path hooks)/post-commit"`
succeeds. It needs no card and no token.

In any other repo, nothing ticks a committed task. After the merge (`reviewing.md` §5), when you tick the acceptance
task by hand, tick every task that has a `Plan-Task:` commit in the same edit, and commit just the plan:
`docs: plan progress, tasks 1–M of M`. Stop 4 promises a Quartz tick only when this section says one will come.

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
| 8 | They are done (`reviewing.md` §3) | `code review done, C Critical (x fixed, y dropped), I Important, m Minor; plan steps P/Q PASS; skill tests G/S GREEN` | `stop 4`; for a chain's base, `cut <S> in this checkout`, and once `<S>` is cut, `the chain's stop 4, after <S>'s reviews` (`parallel.md` §3) |
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
