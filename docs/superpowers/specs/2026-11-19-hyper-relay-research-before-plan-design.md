# hyper-relay: research in brainstorming, so the planner builds on settled facts (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19
**Card:** Research before the plan: settle how the system works with the owner, not in the planner (`d16b46da-3640-47dd-a474-bd8ad907b272`)
**Initiative:** v0.1.0
**Scope:** this repo: `skills/brainstorming/SKILL.md`, a new `skills/brainstorming/research-prompt.md`,
`skills/brainstorming/builder-check-prompt.md`, `skills/writing-plans/SKILL.md`,
`skills/writing-plans/plan-document-reviewer-prompt.md`, `skills/orchestrating/planning.md`,
`templates/agents/planner.md`, `.hyper-relay/agents.md`. One plan. Released as the next patch (0.2.4, after
plan-fixtures' 0.2.3).

## Goal

Research means decisions and understanding how a system works. Today the relay leaves it to the planner, which cannot
run code and sits outside the owner's conversation, so it is both the most expensive place to do it and the blindest.
In the G.2 probe the planner spent 32.5 of its 41m52s researching before it wrote a line (How it works, below).

This change moves the research into brainstorming, before the approaches, done with the owner: brainstorming finds out
how the outside systems a design depends on work, explains it to the owner, and writes the settled facts into the spec
with their sources. The planner builds on them and no longer investigates: a gap becomes a stated assumption and a
question for the owner at stop 3.

The research is for the owner's own understanding as much as for cost (card note `bc3cdc55`): "some features are better
implemented if the human understands what's going on." What brainstorming brings back is written for the owner to learn
from (how the system works, what was found, which decisions it raises), not only as planner input.

The owner accepts the cost: brainstorming and stop 3 take longer, and the owner learns more from them.

## Decisions (owner, 2026-11-19)

| # | Question | Decision |
|---|---|---|
| RB1 | When does research happen? | **Inside brainstorming, before the approaches** (a). Not a separate step after the spec is approved (b), which adds a stop and reopens an approved spec whenever a fact changes the design. Facts shape decisions: in plan-fixtures, knowing how `run-usage.jq` is built decided PF3. |
| RB2 | Who is the research for? | **The owner as much as the planner** (card note `bc3cdc55`). |
| RB3 | Research in brainstorming (when, who, what the owner gets, where it goes, re-check flags, the builder check's net) | **As played back** (§2–§4). |
| RB4 | The planner's side (trusts the spec's facts; a gap is an assumption, not an investigation; "research it" at stop 3; the rule in `writing-plans`; the wording elsewhere) | **As played back** (§5–§8). |
| RB5 | Planner reasoning effort | **Out of scope, and no card of its own.** Planners stay at `xhigh`, which they inherit today: "if the reasoning effort takes more time, it's a trade-off I am willing to accept." (Card note `49291f0d`.) |
| RB6 | Pressure scenarios | **S1–S8 as played back** (§9). |

Calls made by the orchestrator, which the owner did not object to: the section's name (`## How it works`); a prompt file
for the research agent beside the builder check's (§3); the research agent is a general-purpose agent on Sonnet, read-only
by instruction; the new `writing-plans` section's name and place (§5); the plan reviewer's row blocks (§6); a Red Flags
row in brainstorming (§2).

## How it works

The facts this design rests on, each with its source and the date it was checked. This section is also the first
example of the format §2 asks for.

- **The planner cannot run code.** The generated planner's guard lets Bash run only read-only git,
  `git add`/`git commit -- <plan>` and `quartz link-doc`, and lets Write/Edit touch only `docs/superpowers/plans/*.md`;
  it keeps Read, Grep, Glob, WebFetch and WebSearch. Source: `templates/agents/planner.md` (frontmatter, "How you
  work") and `templates/hooks/planner-guard.py`, at `3dfc222`, 2026-11-19.
- **A fallback planner has no template and no guard.** Without generated agents, the orchestrator dispatches a
  general-purpose agent told to follow `hyper-relay:writing-plans` (`skills/orchestrating/SKILL.md`, Fallbacks). The G.2
  probe's planner was one. So a rule that must bind every planner goes in `writing-plans`, not only the template.
  Source: `skills/orchestrating/SKILL.md` at `3dfc222`; the token log's G.2 probe row, 2026-11-19.
- **Where the G.2 probe's time went.** 111 calls, 264,165 output tokens, 41m52s: research 32.5 min, writing 6 min,
  review 3 min. About 45 of its 75 shell commands read `~/.claude/projects` transcripts to work out Claude Code's
  record format, usage fields and subagent metadata; 17 web fetches re-checked docs. Source: the owner's token log
  (memory `relay-token-measurements`) and card `ce88b594`'s stop-4 record, 2026-11-19.
- **G.2's spec never asked the planner to re-check anything.** It decided "a transcript reader of our own
  (`run-usage.sh`)" (G2.6) and did not describe a transcript. The cost came from a fact the spec left unsettled, not
  from a re-check list. Source: `docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md`
  line 29, at `3dfc222`.
- **The first planner given settled facts researched little.** Brainstorming v7's planner (writing-plans 0.2.1):
  22m32s, one external fact checked, no re-check list. Source: the token log, 2026-11-19. Plan-fixtures' spec
  (`8580355`) is the first written with its facts settled in brainstorming; its planner was running when this spec was
  written.
- **Where "re-verify" lives today.** `templates/agents/planner.md` ("External facts the spec says to re-verify", and
  its report), `skills/orchestrating/planning.md` §3 (stop 3's report), `skills/writing-plans/plan-document-reviewer-prompt.md`
  (its "External facts" row), and `.hyper-relay/agents.md` here and in SAT (`planner/before-writing`). Brainstorming and
  `writing-plans/SKILL.md` say nothing about facts. `skills/writing-skills/` also says "re-verify" (lines in `SKILL.md`
  and `testing-skills-with-subagents.md`), about re-testing a skill after a refactor, which is unrelated. Source:
  `git grep -i 're-verif'` at `3dfc222`, and in `~/sat.pentraze.com`, 2026-11-19.
- **Effort (out of scope, RB5).** An agent file's `effort:` field (`low` to `max`) overrides the session's level; without
  one, a subagent on the session's model inherits the session's level, so this machine's Opus planners run at `xhigh`.
  Source: https://code.claude.com/docs/en/sub-agents, 2026-11-19.

## 1. What changes where

| File | Change |
|---|---|
| `skills/brainstorming/SKILL.md` | Research before the approaches; the spec's `## How it works`; re-check flags at stop 2; a Red Flags row (§2) |
| `skills/brainstorming/research-prompt.md` | New: the research agent's prompt (§3) |
| `skills/brainstorming/builder-check-prompt.md` | Also asks for outside facts it would have to look up (§4) |
| `skills/writing-plans/SKILL.md` | A new section on facts about outside systems (§5) |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | Its "External facts" row (§6) |
| `skills/orchestrating/planning.md` | Stop 3's questions, its report line, and a "research it" answer (§7) |
| `templates/agents/planner.md` | Its "External facts" bullet and its report line (§8) |
| `.hyper-relay/agents.md` | Its `planner/before-writing` line (§8) |

Every other skill, template and script stays as it is. After the change, "re-verify" appears nowhere in the relay's
skills (`brainstorming`, `writing-plans`, `orchestrating`), `templates/` or `.hyper-relay/`: the word is "re-check",
and it applies only to facts a spec flags. `writing-skills` keeps its own "re-verify", which belongs to its TDD cycle
for skills and has nothing to do with outside facts.

## 2. `skills/brainstorming/SKILL.md`

**A new paragraph in The Conversation,** after "Do recon." and before "Lay out the approaches." Its substance:

- When the design depends on how something outside the repo's own code works (a file format the work reads, how a CLI
  behaves, a third-party API, external docs, data on this machine), find out before laying out the approaches. Never
  leave it to the planner: a planner cannot run code and is not in this conversation. Reading the repo's own code stays
  what Look Before You Ask and Do recon already say.
- By size: a small check (a command or two, a single docs page) brainstorming runs itself. A bigger investigation goes
  to a fresh agent on Sonnet with `research-prompt.md` (§3), named as `${CLAUDE_SKILL_DIR}/research-prompt.md` and as
  `research-prompt.md` beside the SKILL.md, as the builder check's prompt is.
- What comes back to the human partner is an explanation, written so they understand how the system works and not only
  the conclusion: how it works, what was found and the evidence for it. Each decision it raises then comes as an
  ordinary question, one at a time, as The Conversation says.

**The Written Design.** The "Cover:" list gains a line: how the outside systems the work depends on work, each fact with
its source (a URL, a command, a file) and the date it was checked. In the full design these go in a section titled
`## How it works`; in a short design, a line or two each. Then, beside it:

- A fact that may change before the plan runs (a docs page in flux, a version, a beta API) is flagged in that section
  for the planner to re-check, with its reason. Every other fact is settled, and the planner builds on it. Most specs
  flag none. A fact the spec hands the planner to discover is never written.
- The hand-over (stop 2, or the first message's short design) lists the flagged facts, if any, so the human partner
  sees them before approving.

**Builder check.** Its sorting gains a fourth case: an outside fact the builder says it would have to look up or guess
(§4) is research to do, the paragraph above's way. Its result goes into `## How it works`, and any decision it raises
joins the "theirs" pile.

**Red Flags** gains a row: "The planner can look that up" | "A planner can't run code and isn't in this conversation.
Find out now, and explain it to your human partner."

The plan writes the new sentences in full.

## 3. `skills/brainstorming/research-prompt.md` (new)

Modelled on `builder-check-prompt.md`: one line on when to use it (dispatch a fresh general-purpose agent on Sonnet; in
OpenCode, the `general` subagent), then the prompt in a code block, with placeholders brainstorming fills in: the domain,
the questions the design hinges on, and where to look (paths, URLs, commands).

The prompt tells the agent:

- **It only reads.** It may run commands that read (`jq` over files, `--help`, `git log`, fetching docs). It never
  writes, edits, installs, changes config, or runs anything that sends, publishes or spends usage (no `claude -p`, no
  live API calls).
- **For each question:** the answer; the evidence (the command and the lines of its output that decide it, a file and
  line, a URL and a short quote); the date checked.
- **Then:** a short explanation of how the parts fit, which someone new to the system could follow; what it could not
  settle, and why; anything it saw that may bear on the design and that it was not asked.
- Quotes short, only what decides something; no file dumps.

## 4. `skills/brainstorming/builder-check-prompt.md`

The prompt gains one ask, beside "the questions you'd still need answered": also list each fact about an outside system
(a file format, a CLI, an API, docs) that you would have to look up or guess to plan this, and that the document does
not state with a source. Its other instructions stay. Brainstorming handles that list as §2 says.

## 5. `skills/writing-plans/SKILL.md`

A new section, **Facts about outside systems**, after "The spec's plan count" (its place and name are the planner's to
adjust; its substance is not):

- The spec's `## How it works` section is settled: build on it. Do not work it out again or re-check it, except the
  facts it flags for re-check. Check those with WebFetch or WebSearch, cite the URL and the date, and list a difference
  as a deviation, never a silent design change.
- Reading the repo's own code is the planner's job, as always.
- When the plan needs a fact about an outside system that the spec does not settle, read at most one file or one page
  to confirm a detail. Do not investigate: no series of searches, no digging through data, no working out a format from
  samples. Write the plan on a stated assumption, list it in the deviations table as an assumption, and put it in the
  report among what the owner must decide.
- The report names the facts re-checked (those the spec flagged) and any differences, and the assumptions made where
  the spec was silent.

The plan writes the section in full.

## 6. `skills/writing-plans/plan-document-reviewer-prompt.md`

Its "External facts" row becomes: each fact the spec flags for re-check is cited with its URL and the date it was
checked, and a difference is listed as a deviation; a fact about an outside system that the plan states as settled, and
that neither the spec's `## How it works` nor a cited re-check gives, is flagged: it should be an assumption in the
deviations table and a question for the owner. The row is not advisory, so a failure blocks: a wrong outside fact builds
the wrong thing.

## 7. `skills/orchestrating/planning.md`

**§3, stop 3.**

- The questions gain, after "each decision the owner must make": each assumption the planner made where the spec was
  silent, which the owner can accept, correct, or answer with "research it".
- The report's "the external facts it re-verified, and any differences" becomes "the facts it re-checked (those the
  spec flagged), and any differences".

**A fourth answer, "research it",** beside approve, a plan review and changes:

1. Research as brainstorming does (§2): a small check yourself, a bigger one through a Sonnet agent with
   `../brainstorming/research-prompt.md` (from `planning.md`).
2. Explain what was found to the owner, as brainstorming does. When it raises a decision, ask it, and that message ends
   there.
3. Add each fact to the spec's `## How it works` with its source and date, and commit just the spec while the main
   checkout is on `main`, as for the `**Plans:**` line (`git add <spec>`, then `git commit -m "<message>" -- <spec>`).
   During a branch run the spec edit waits for the merge (`dispatching.md` §6), and the planner gets the facts in its
   prompt instead.
4. The planner revises the plan (resumed, or fresh with the facts) and commits it again. Then §2 and a short stop 3,
   in the same order as after a plan review.

## 8. `templates/agents/planner.md` and `.hyper-relay/agents.md`

- **The template's "How you work":** the "External facts the spec says to re-verify" bullet is replaced by one that
  points to `hyper-relay:writing-plans`' new section (§5) and states it in a line: the spec's `## How it works` is
  settled; re-check only what it flags; a gap is a stated assumption, not an investigation.
- **The template's "Report":** "external facts re-verified and any differences" becomes "facts re-checked (those the
  spec flagged) and any differences; assumptions made where the spec was silent".
- **This repo's `.hyper-relay/agents.md`,** `planner/before-writing`: "External facts to re-verify are usually Claude
  Code's, OpenCode's or GitHub's." becomes "The outside systems this repo's specs depend on are usually Claude Code,
  OpenCode and GitHub."
- **SAT's `.hyper-relay/agents.md`** has the same kind of line ("External facts to re-verify are usually Microsoft's,
  Cloudflare's, DNS or library APIs."). It is in SAT's repo, so its change is the owner's call: an `after merge` step
  with the exact replacement, "The outside systems SAT's specs depend on are usually Microsoft's, Cloudflare's, DNS and
  library APIs."

## 9. Pressure scenarios

Each runs on `main`'s skills (RED) and the branch's (GREEN), on Sonnet, as a `skill-test` step: written as
`hyper-relay:writing-plans`' "Skill tests" section says (a situation given in full, including what has just happened
and any reply the owner gave, then what GREEN must do and what RED is expected to do), and run by the orchestrator after
acceptance, beside the code review (`hyper-relay:orchestrating`'s `reviewing.md` §3). Nothing for them is committed
under `tests/`.

| # | Situation | The new text must | Today's text does |
|---|---|---|---|
| S1 | Brainstorming: the owner wants a tool that reads Claude Code's session transcripts and reports token usage (G.2's shape); the transcripts are many JSONL files the design depends on | Find out the format before the approaches, through a Sonnet agent with `research-prompt.md` and a read-only brief; explain it to the owner; the spec gets `## How it works` with sources and dates | Goes to the approaches; the spec names "a transcript reader" and never describes a transcript |
| S2 | Brainstorming: the design depends on one CLI flag's behaviour | Runs `<cli> --help` itself, with no agent | A guard against over-applying the rule: no agent for a one-command check, on both |
| S3 | Brainstorming: one fact comes from a beta docs page that may change before the plan runs; the others are settled | Flags that fact in `## How it works` for re-check, with its reason, and lists it at the hand-over; leaves the others unflagged | No flag, or every fact sent to the planner to re-verify |
| S4 | The builder check reads a spec that relies on the transcript format without describing it | Names it among the outside facts it would have to look up | May pass it |
| S5 | A planner's spec settles the transcript format in `## How it works` | Builds on it; reads no transcripts to confirm it | Works the format out again from transcripts |
| S6 | A planner's spec is silent on a CLI's output format that the plan's parser needs | At most one lookup, then an assumption in the deviations table and in the report's owner decisions | Investigates at length |
| S7 | The orchestrator at stop 3: the planner reported an assumption, and the owner answers "research it" | Researches it, explains it to the owner, adds the fact to the spec's `## How it works` in a commit of just the spec, and sends the planner back | Sends the planner back to investigate it |
| S8 | A plan reviewer reads a plan that states an outside fact as settled, with no source, which the spec does not have | Flags it under "External facts" as blocking | Approves it: its row checks only facts the spec asked to re-verify |

## 10. Acceptance and release

The reviewer's steps, on the branch:

1. `claude plugin validate .`: passes, with the three known warnings. `sh tests/orchestrating/run-tests.sh`: `0 failed`.
   `sh tests/hyper-relay-agents/run-tests.sh` and `sh tests/hyper-relay-agents/guard-test.sh`: `0 failed` each.
2. `git grep -n -i 're-verif' -- skills/brainstorming skills/writing-plans skills/orchestrating templates .hyper-relay`:
   finds nothing.
3. `git diff --name-only main...HEAD`: exactly §1's files.
4. `skill-test`, run by the orchestrator (§9): S1–S8, RED and GREEN: all GREEN; RED recorded.

After the merge:

- Release the next patch (0.2.4, unless `main` holds another version), as this repo's `.hyper-relay/agents.md`
  (`planner/execution-notes`, Releases) says. The owner runs `claude plugin update hyper-relay@hyper-relay` and
  `/reload-plugins`; the orchestrator regenerates the role agents here and in SAT.
- SAT's `.hyper-relay/agents.md` line (§8): the owner's call, with the exact text.
- The proof is in use, not an acceptance step: the next spec that depends on an outside system carries
  `## How it works`, and its planner's row (`plan-usage.sh`, from plan-fixtures) goes into the token log beside the G.2
  probe's.

## 11. Order with plan-fixtures

Plan-fixtures (`2026-11-19-hyper-relay-plan-fixtures-design.md`) also changes `skills/writing-plans/SKILL.md` and
`plan-document-reviewer-prompt.md`, in other sections ("What a Step Contains", "Self-Review", the "Step contents" row).
This plan runs after plan-fixtures merges, or beside it under `parallel.md`'s conflict check; the orchestrator decides at
the handoff. Its release follows plan-fixtures' 0.2.3.

The next SAT plan will carry both changes. Plan-fixtures' proof is that plan's test-code lines, which this change does
not touch, so it stays readable; the planner's time and tokens will reflect both.

## 12. Out of scope

Reasoning effort for any agent (RB5); a separate research step after the spec (RB1's (b)); the executor's and the
reviewers' research; measuring research automatically; changing specs already written. Research into the repo's own
code stays the planner's.
