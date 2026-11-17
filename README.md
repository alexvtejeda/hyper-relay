# hyper-relay

<p align="center">
  <img src="assets/hyper-relay.jpg" width="500" alt="Two robots sprint down a floodlit stadium track; the white one hands a glowing baton to the red-and-black one under a HYPER-RELAY banner.">
</p>

**A relay for coding agents: one idea, handed cleanly from brainstorm to merge.**

hyper-relay is a set of skills for [Claude Code](https://code.claude.com) and [OpenCode](https://opencode.ai) that
turns "build me X" into a disciplined pipeline. It covers brainstorming, a written spec, an implementation plan,
execution in isolation, a review by clicking through the running app, and a merge you decide on. Each stage hands a
written artefact to the next, the way a relay team hands over the baton. Nothing is carried in anyone's head, and the
last leg is always yours.

It is a hard fork of [obra/superpowers](https://github.com/obra/superpowers) (v5.1.0), reshaped around one way of
working: an orchestrating session that you talk to, role agents that do the legwork, and a board that knows where
everything stands.

> **Status: 0.1.0.** This release moves the skills into a versioned plugin with **no behaviour change**. Later releases
> add the role agents, per-repo configuration and the orchestrator (see [Roadmap](#roadmap)).

## The relay

```
 voice-to-specs ─▶ brainstorming ─▶ spec ─▶ writing-plans ─▶ execute ─▶ review ─▶ you ─▶ merge
   (optional)        (you + the        (committed)   (one plan per    (isolated)  (clicks,   (anchor
                      orchestrator)                    subsystem)                  not tests)   leg)
```

| Leg | Skill | Hands over |
|---|---|---|
| Capture | `voice-to-specs` | Briefs or board cards from a recording. It stops there and never writes specs, plans or code. |
| Design | `brainstorming` (+ `visual-companion` for mockups) | An approved design, written as a spec in `docs/superpowers/specs/` |
| Plan | `writing-plans` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`: every task with full code, tests and a binding contract between plans |
| Execute | `executing-plans`, `subagent-driven-development`, `using-git-worktrees`, `test-driven-development` | Commits, one per task, in their own worktree |
| Review | `verification-before-completion`, `requesting-code-review`, `receiving-code-review` | Evidence that it works: tests, then a click-through of the running app |
| Finish | `finishing-a-development-branch` | A merge, on your call |

Also in the box: `systematic-debugging` (root cause before any fix), `dispatching-parallel-agents`, `writing-skills`
and `using-hyper-relay` (how to find and use the skills).

### The rules of the relay

- **A gate between every leg.** Each phase ends with your approval, and the next one never starts in the same breath.
- **Hand-offs are files, not memory.** A spec, a plan, a commit or a report. If it isn't written down, it wasn't handed
  over.
- **Acceptance is by clicking.** A green test suite is necessary, not sufficient.
- **Root causes only.** No band-aids, and no "it passes when run alone".

## Quartz: the board

hyper-relay is designed to run alongside Quartz, a project board built for exactly this pipeline (not public yet).

With Quartz connected:

- **Every spec and plan names its card(s)** in its header (`**Card:**` / `**Cards:**`), and committing the file uploads
  it to them.
- **Plan tasks tick themselves.** The commit that finishes a task carries a `Plan-Task: <plan>#<n>` trailer, and a git
  hook ticks that task on the board.
- **Cards move with the work:** brainstorming, In progress (`quartz link-branch`), In review (`quartz review`), and
  merged (a git hook).

Without Quartz, nothing breaks. Every Quartz step falls back to plain Markdown, and the skills work on their own. But
the board is half the point: it is what lets a long-running, multi-agent pipeline stay legible.

## Install

### Claude Code

```text
/plugin marketplace add alexvtejeda/hyper-relay
/plugin install hyper-relay@hyper-relay
```

Skills appear as `hyper-relay:<skill>`, for example `hyper-relay:brainstorming`.

- **The repo is private,** so Claude Code clones it with your own git credentials. For background updates to work too,
  give git a credential helper: `gh auth login`, then `gh auth setup-git`.
- **Updates follow the version.** `plugin.json` pins it, so an installed copy changes only when a release raises it.
  Claude Code checks a marketplace that is not Anthropic's in the background only if you turn on auto-update for it
  (`/plugin`, then **Marketplaces**); otherwise run `claude plugin update hyper-relay@hyper-relay`.
- **Install from GitHub, not from a local clone.** A local-directory marketplace loads files in place, gitignored ones
  included, so a developer's local `.mcp.json` would load as the plugin's own MCP servers.

### OpenCode

Clone the repo, then point OpenCode's `skills` setting at its `skills/` folder in `~/.config/opencode/opencode.json`:

```json
{
  "skills": ["/path/to/hyper-relay/skills"]
}
```

Use an absolute path: OpenCode resolves a relative one from its working directory. Skills from an explicit `skills`
entry take precedence over same-named skills OpenCode finds elsewhere (it also reads `~/.claude/skills/`). Update with
`git pull` on the clone's `main`.

### voice-to-specs

It needs Python 3.10+ and ffmpeg. The first transcription runs its `scripts/setup.sh`, which builds a Python venv with
whisper under `${XDG_DATA_HOME:-~/.local/share}/hyper-relay/voice-to-specs/`, outside the plugin, so updates never
delete it.

## Roadmap

| Piece | What | Status |
|---|---|---|
| A | **The fork's home:** the skills as a versioned plugin for Claude Code and OpenCode, with no behaviour change | 0.1.0 |
| B | **Per-repo config and generic role agents:** a planner, an executor and a reviewer that read one small config file per repo (how to start a test stack, how to merge, which checks to run, which model each role uses) | planned |
| C | **Our own executing-plans:** executes in the worktree it is given (or on a branch, per repo), commits per task with `Plan-Task` trailers, runs the full checks once, and stops before merging | planned |
| D | **The orchestrator:** dispatches the legs, verifies every hand-back, stacks dependent plans, checks for migration and shared-file conflicts, and hands you the stack to click through | planned |

## Credits

hyper-relay stands on [superpowers](https://github.com/obra/superpowers) by Jesse Vincent and contributors. Most of
its skills began there, and its design philosophy (skills as tested, composable process) is theirs. obra's repo stays
this one's `upstream`, and fixes from it are ported by hand.

## License

MIT. See [LICENSE](LICENSE), which keeps the original superpowers copyright notice.
