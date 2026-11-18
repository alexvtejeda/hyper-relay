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
