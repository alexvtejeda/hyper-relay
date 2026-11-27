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

The three leg files, `parallel.md` and `quartz.md` are beside this SKILL.md. Read each of them once per session, when
the loop first needs it, and not again: a leg file when the loop reaches its leg; `parallel.md` when a second plan
would be in flight or a spec has several plans; `quartz.md` at the session's first leg (Quartz duties, below). A
cleared conversation is a new session:

- `${CLAUDE_SKILL_DIR}/planning.md` (`planning.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/dispatching.md` (`dispatching.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/reviewing.md` (`reviewing.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/parallel.md` (`parallel.md` beside this SKILL.md);
- `${CLAUDE_SKILL_DIR}/quartz.md` (`quartz.md` beside this SKILL.md).

## The stops

| Stop | What the owner gets | The owner's answer starts |
|---|---|---|
| 1. Design | The approaches, then the design played back part by part (`brainstorming`) | the spec |
| 2. Spec | The written spec (`brainstorming`); skipped when the owner approved a short design in brainstorming's first message, which covers stops 1 and 2 | the planner leg: approval is the go-ahead, no second ask |
| 3. Plan ready | Its questions first: the decisions the owner must make, the assumptions the planner made where the spec was silent, the plan-review offer, the handoff question. Then the hand-back check's result and the planner's deviations (`planning.md` §3) | execution, a plan review, plan changes, or "research it" |
| 4. Ready to merge | Its questions first: each finding that reached the fix-round cap (merge with its card open, hold the branch, or one more round), the steps that are the owner's, where to click through. Then gate, acceptance, `code-review` step and skill-test results, fixes made, Critical findings and `code-review` FAILs fixed or dropped, and the number of proposed cards filed (`reviewing.md` §4) | the click-through and the merge |

A stop that asks anything opens with its questions, numbered, before any report: every question, and every decision
the owner must make. The report follows, short: one line per item, and nothing the board shows. No question comes
after the report.

A stop ends the message: the next leg never starts in the message that reaches a stop. Between stop 3 and stop 4 the
loop runs on its own, except for a gap in the spec or plan, which goes to the owner at once (`reviewing.md` §2). A
finding that still fails after the repo's fix-round cap gets no further round: it becomes a card, the loop carries
on, and stop 4 opens with it.

Before sending stop 3 or stop 4, post the status note (`quartz.md` §4). The stop's report then ends with one line:
"The board is current, so this is a good moment to clear." Without Quartz, the line is "Everything is written down,
so this is a good moment to clear."

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
| A stacked plan's branch (its plan's header has `**Builds on:**`) with all its executor tasks committed, whose base has not merged | By its review status (below), with `<base branch>..<branch>` for `main..<branch>`; a second plan on the same base, in a worktree of its own, waits for its base to merge (`parallel.md` §3) |
| A plan's branch with all its executor tasks committed | By its review status (below) |
| The branch merged, with an `after merge` step of the plan's acceptance task left (that task is not ticked) | `reviewing.md` §5 |

**A branch with all its executor tasks committed** goes by its review status: a status line on the plan's cards
written before `next:` existed, counted only when it names this plan's path, or none.

| Review status | Leg |
|---|---|
| None, and no fix commits on the branch | `dispatching.md` §7 (verify), then `reviewing.md` §1 |
| "acceptance done" | `reviewing.md` §3 |
| "code review done" | Stop 4 (`reviewing.md` §4). For a chain's base (another plan's `**Builds on:**` names it): the cut while the stacked plan has no branch, and once it has one, the chain's one stop 4 after the stacked plan's reviews (`parallel.md` §3) |
| None, but fix commits (no Quartz and no `status` file) | **Ask the owner** which review legs ran, naming the fix commits. Rerun nothing on your own. |

A fix commit is a commit on `main..<branch>` with no `Plan-Task:` trailer, after the branch's last `Plan-Task:`
commit: `git log --format='%h %s%n%(trailers:key=Plan-Task)' main..<branch>` lists the branch's commits, newest
first, and the fix commits are those above the newest one with a trailer. For a stacked branch whose base has not
merged, read `<base branch>..<branch>` for `main..<branch>`, here and below.

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

## Fallbacks

- **No generated agents** (`.claude/agents/<project>-planner.md` and the rest; in OpenCode, `.opencode/agents/`):
  offer `hyper-relay:agents` once. If the owner declines, each leg dispatches a general-purpose agent told to invoke
  its skill: `hyper-relay:writing-plans` for the planner, `hyper-relay:executing-plans` for the executor (in OpenCode,
  the `general` subagent, told to load the skill first). The acceptance reviewer, which has no skill, gets the
  standing brief in `reviewing.md` §1.
- **Models:** the generated agents carry their own. The plan reviewer, the code reviewer, the skill-test runs and
  their judge (`reviewing.md` §3) run on Sonnet: in Claude Code, `model: sonnet` on the dispatch; in OpenCode, which
  sets a model per agent and not per dispatch, the `general` subagent's configured model.
- **Resuming an agent** with its context: in Claude Code, `SendMessage` to the agent's ID or name; in OpenCode, the
  `subagent` tool given the child's `sessionID`. Otherwise, or when the agent is gone, a fresh agent gets what it needs
  in its prompt.
- **No background agents** (a harness that waits for a subagent): every rule still holds; the owner just cannot work
  meanwhile.
