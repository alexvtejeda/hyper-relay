# hyper-relay: brainstorming from upstream's rebuilt SKILL.md (superpowers 7.0.2), Implementation Plan

**Card:** brainstorming: bring upstream's rebuilt SKILL.md (superpowers 7.0.2) into the relay (`a5a66906-5d01-4a18-956e-264e0c0123c1`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-brainstorming-v7-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–4 are
> the executor's. Task 5 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Brainstorming becomes upstream superpowers 7.0.2's rebuilt skill, word for word, with the relay's parts put
back at named places (the Quartz step before the first message, the off-ramp, the hand-over to `orchestrating` with a
short design's approval standing for stop 2, the spec's card line, `**Plans:**` line and commit rule, worktrees for
opt-outs and spikes, the builder check on Sonnet, the `visual-companion` skill); the spec-document reviewer and its
live test go; `orchestrating`, the relay guard and README follow.

**Architecture:** Skill text, plus one guard check. Task 1 adds a check to `tests/orchestrating/run-tests.sh` that no
`superpowers:<skill>` name is left under `skills/`. Task 2 shows the check catching upstream's raw text, then writes
`skills/brainstorming/SKILL.md` and `builder-check-prompt.md` in full and deletes the spec-document reviewer and its
live test. Task 3 rewords five `orchestrating` lines and two stops rows; Task 4 changes README's Design row and diagram
and runs the full gates. Task 5 accepts it: a diff against upstream's tag, eleven RED/GREEN skill tests, the 0.2.2
release and a live probe.

**Tech Stack:** Markdown skills; POSIX shell run by dash (the guard); upstream's tag `v7.0.2` (local, read-only);
Mermaid (README's diagram). For acceptance: Claude Code general-purpose subagents on Sonnet.

**How this was checked:** written against `main` at `520c891`, by reading only; nothing was built, run, installed or
generated.

---

## Execution notes (binding)

- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator
  are the installed plugin's (0.2.1). This plan rewrites `brainstorming` and three `orchestrating` files: follow your
  agent instructions and this plan, not the new text.
- **Skill text is written exactly.** "Create X with exactly this content" means the Write tool, with every line of the
  block, ending with one newline; "Replace X with Y" means the Edit tool, X as `old_string`, Y as `new_string`. Fence
  lines (three or four backticks) are not part of the text. Do not reflow, re-wrap or "fix" a word: most of the new
  `SKILL.md` is upstream's text, kept word for word on purpose (spec BR1). If an X is not found, read the range again;
  if it moved or differs slightly, adapt as little as possible and record a deviation; if it is gone, stop and report.
- **Upstream's base** is the tag `v7.0.2`, already in this repo (remote `upstream`): read it with
  `git show v7.0.2:<path>`. Never fetch, pull or merge `upstream`.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|`: run `... | tail -n 1`, and
  `grep -E 'a|b'` (alternation).
- **The guard is the contract.** `tests/orchestrating/run-tests.sh` gains one check and one broken case (Task 1); no
  existing check or case changes. Needing to change one is a stop.
- **Deleting a test is the spec's** (BR4): `tests/claude-code/test-document-review-system.sh` goes, unrun. Do not run
  any of upstream's live suites (`tests/claude-code/`, `tests/explicit-skill-requests/`, `tests/skill-triggering/`).
- Leave `RELEASE-NOTES.md` alone: it is upstream's dated history (P3).
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.1; Task 5 releases 0.2.2
  after the merge.
- The spec's project-wide values, verbatim:
  - "Every `superpowers:<skill>` name becomes `hyper-relay:<skill>`; no `superpowers:` skill name remains."
  - "Text this section quotes as "from today" is copied from today's `skills/brainstorming/SKILL.md`, with "the
    owner" and "the user" read as "your human partner"."
  - "The builder check runs on Sonnet, like the relay's other reviewers."
  - A skill reaches its own files as `${CLAUDE_SKILL_DIR}/...` and also names them relative to its `SKILL.md`
    (`CLAUDE.md`, Rules).
- **The full gates** (Task 4): `sh tests/orchestrating/run-tests.sh`, `dash -n tests/orchestrating/run-tests.sh` and
  `claude plugin validate .`. Those are also `relay-merge`'s gates for this branch (`.hyper-relay/merge.conf`).
- **Task 5 is not yours.** After Task 4, report, copy Task 5's checklist into your report, and stop.

## Review Focus

1. **OpenCode reads the skill.** OpenCode does not expand `${CLAUDE_SKILL_DIR}`, so each of the three files
   brainstorming reaches by it (`quartz.md`, `add-card-line.sh`, `builder-check-prompt.md`) must also be named
   relative to its `SKILL.md`. Task 2 Step 5 asserts it.
2. **A short design approved while a plan runs on a branch in the main checkout.** The doc is written but not
   committed (`quartz link-doc` when the repo uses Quartz), and `orchestrating` gets its path: the short-design
   sentence must point at The Written Design's commit rule, and that rule must keep its branch-run sentence. Task 2
   Step 5 asserts both.
3. **A repo without Quartz** (no CLI, or declined): no `tick_brain`, no card line, no `quartz link-doc`, and nothing
   fails. Task 2 Step 5 asserts each skip is written.
4. **A pointer elsewhere to a part of brainstorming that is gone** (its step 1, its Documentation, its checklist)
   sends an agent nowhere. Task 3 Step 4 asserts none is left under `skills/`.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §6: "a dashed edge from `spec` to `planner`, labelled "short design approved"" | Mermaid ignores a subgraph's `direction` when one of its nodes links outside it ([mermaid.js.org/syntax/flowchart.html](https://mermaid.js.org/syntax/flowchart.html), fetched 2026-11-19: "If any of a subgraph's nodes are linked to the outside, subgraph direction will be ignored"). `spec` and `planner` sit in different subgraphs, so the literal edge would lay both out left to right, thirteen nodes in a row. **Decision:** the edge stays inside `brainstorming`: `stop2` leads to a new node, `handover` ("on to the planner"), and a dashed edge labelled "short design approved" runs from `spec` to it, beside the path through `stop2`. **The owner may choose the literal edge at stop 3**, accepting the flattened layout. |
| P2 | §4: `quartz.md`, "four pointers, nothing else" | `quartz.md:114`, "**Card lines:** as `brainstorming`'s Documentation says", points at a section the new text no longer has. Task 3 rewords it to "as `brainstorming` says under The Written Design" (a fifth line). **The owner may drop it at stop 3.** |
| P3 | §5, §8 step 4: "nothing outside `docs/` names" the deleted prompt or test | `RELEASE-NOTES.md`, upstream's dated history at the repo's root (unchanged since v5.1.0), names both, as upstream's own 7.0.2 copy still does ("preserved as dated artifacts"). It is left alone; the check excludes it. |
| P4 | §2.2: the off-ramp "comes in as a subsection, **The off-ramp (experiment)**" after the bullets | A bold-lead paragraph, `**The off-ramp (experiment).**`, straight after the bullets: upstream's form for a subsection inside a section (The Conversation's), so upstream's paragraphs after it stay under "First: What Do You Actually Know?" and not under an off-ramp heading. |
| P5 | §2.2: the first bullet "becomes a bullet for the off-ramp" | Its example becomes "fix the typo in the README": upstream's ("make the icon cornflower blue") is not one of the off-ramp's cases. |
| P6 | §2.8: after "…while reading": commit, "That hand-over is stop 2", approval is the go-ahead | Those sentences go in a paragraph of their own after the builder-check paragraph, so "That's the only round of questions the check produces" stays beside the check, and the paragraph serves both sizes. The small change's sentence points to it ("as the full design's is (below)"). |
| P7 | §2.11: line 315 becomes "if they accept, invoke the `visual-companion` skill", followed by today's "**Brainstorming does not implement it** …" paragraph "adapted to open with "If they accept"" | One paragraph: today's "REQUIRED SUB-SKILL" paragraph opening "If they accept" (which already says to invoke the skill by name), with today's "**Brainstorming does not implement it** — … the screen loop." after "Invoke it by name.", and "Brainstorming ships none" and the stale-copy line kept. Today's "Two things belong to brainstorming and are covered here: getting consent, and deciding per question." is dropped: upstream's section covers both above it. Then the display-only and old-screens paragraphs, word for word. |
| P8 | §2.12: "Everything else of today's that the relay needs is moved in by §2.2 to §2.11" | So today's "The Process" (Understanding the idea, Exploring approaches, Presenting the design, Design for isolation and clarity, Working in existing codebases), "Write the validated design (spec) to …" and "Use elements-of-style:writing-clearly-and-concisely skill if available" go too: §2.2–§2.11 move none of them. Named here so the owner sees it. |
| P9 | §2.8: today's Documentation rules "moved in word for word (with "step 1" read as "the Quartz step")" | Word for word, so "straight after writing the spec" keeps "the spec" (the spec's own summary says "the doc"). Only "the owner"/"the user" and "step 1" are rewritten. |
| P10 | §7 S2: GREEN is the short design asking for approval | §2.3's Quartz step has no scenario of its own, so S2 and S3 run with Quartz connected: S2's GREEN also has `tick_brain` with the card's id before the first message, and S3's the card-line script. |
| P11 | §7: "The situations are described to the agent" | The skill-test preamble (`reviewing.md` §3) forbids commands, so each situation gives what the files hold, and a read is judged from the commands listed. S6's typo is set by the situation (`docs/wt.md` has none today). S7, S9, S10 and S11 have two parts, so the behaviour after a reply is judged in one run. |
| P12 | §8 step 6: skill tests among "the reviewer's steps" | They are `skill-test` steps (Steps 7–17), run by the orchestrator's standing leg (`reviewing.md` §3) beside the code review, as `writing-plans` requires. |
| P13 | `.hyper-relay/agents.md`, Releases: the release steps come "last"; §8: the live probe runs "in a fresh session on 0.2.2" | The release (Steps 21–22) comes before the agents (Step 23), the live probe (Step 24) and the record (Step 25): the probe needs 0.2.2 installed, and those three change no file the plugin loads. The probe is an `owner` step run after the update, not at the click-through, and a miss does not block the merge (BR10). The record waits for it, so the acceptance task stays open until then. |
| P14 | §8: regenerate the role agents "in SAT" | SAT's checkout is `/home/noob_master/sat.pentraze.com`, as this repo's earlier plans name it. Not while a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: the orchestrator asks the owner first then. |
| P15 | §2: section ranges "lines 15–40", "42–51", "53–102", "104–188", "190–208", "210–230", "232–268", "270–283", "285–294", "296–316" | Upstream's are 17–40, 42–50, 52–97, 99–188, 190–207, 209–227, 229–267, 269–283, 285–294, 296–316 (`git grep -n "" v7.0.2 -- skills/brainstorming/SKILL.md`). §2.8's "lines 242–244" are 241–243. Each edit is named by its quoted text, which decides; this plan uses the actual numbers. The other line references (76, 95, 179–180, 251, 281–282, 315) are right. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 2; 5 (Steps 7–17, 24) |
| Decisions (2026-11-19) | BR1: 2, 5 (Step 3). BR2: 2 (Your First Message), 5 (S4, S5). BR3: 2, 3, 5 (S2, S3). BR4: 2. BR5: 2, 5 (S11). BR6: 2, 5 (S9). BR7: 2, 5 (S10). BR8: 2, 3. BR9: 2, 4. BR10: 5 |
| 1. What changes where | 1–4; 5 (Step 2) |
| 2. `skills/brainstorming/SKILL.md` | 2; 5 (Steps 3, 7–17) |
| 3. `skills/brainstorming/builder-check-prompt.md` | 2; 5 (Step 4) |
| 4. `orchestrating` | 3; 5 (Step 6) |
| 5. Tests | 1; 2 (the deletion); 5 (Steps 1, 5) |
| 6. `README.md` | 4; 5 (Step 6) |
| 7. Pressure scenarios | 5 (Steps 7–17) |
| 8. Acceptance and release | 4 (the full gates); 5 |
| 9. Out of scope | No task; 5 (Step 2: only the planned files) |

## File structure

- **Modify (Task 1):** `tests/orchestrating/run-tests.sh`.
- **Rewrite (Task 2):** `skills/brainstorming/SKILL.md`. **Create:** `skills/brainstorming/builder-check-prompt.md`.
  **Delete:** `skills/brainstorming/spec-document-reviewer-prompt.md`, `tests/claude-code/test-document-review-system.sh`.
- **Modify (Task 3):** `skills/orchestrating/quartz.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/planning.md`.
- **Modify (Task 4):** `README.md`.
- **Unchanged:** `skills/brainstorming/scripts/`, every other skill, `templates/`, `bin/`, `hooks/`, `.claude-plugin/`,
  `package.json`, `RELEASE-NOTES.md`, every other suite.

---

### Task 1: The guard: no `superpowers:<skill>` name under `skills/` (spec §5)

**Files:**
- Modify: `tests/orchestrating/run-tests.sh:2-8` (header), `:156-159` (a new check after it), `:164` (`CHECKS`),
  `:246` (a new broken case after it)

- [ ] **Step 1: The header.** Replace:

```text
# POSIX guard for the relay skills (hyper-relay D.3, D.2): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, `quartz install-git-hook`
# named only in quartz.md, and no orchestrating file naming finishing-a-development-branch
# (the relay lands branches with relay-merge). It reads the working tree, not git's index,
# so an untracked new file counts and it runs the same in a worktree. Each check also runs
# on a copy of the tree broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "26 passed, 0 failed"
```

with:

```text
# POSIX guard for the relay skills (hyper-relay D.3, D.2): D1's gates, the orchestrating
# folder, no machine paths in it, references that resolve, `quartz install-git-hook`
# named only in quartz.md, no orchestrating file naming finishing-a-development-branch
# (the relay lands branches with relay-merge), and no upstream `superpowers:<skill>` name
# under skills/. It reads the working tree, not git's index, so an untracked new file
# counts and it runs the same in a worktree. Each check also runs on a copy of the tree
# broken on purpose, where it must fail.
# Usage: sh tests/orchestrating/run-tests.sh      Expect: "28 passed, 0 failed"
```

- [ ] **Step 2: The check.** Replace:

```sh
no_finishing_branch_in_orchestrating() (
    cd "$1" || exit 2
    none -F 'finishing-a-development-branch' skills/orchestrating
)
```

with:

```sh
no_finishing_branch_in_orchestrating() (
    cd "$1" || exit 2
    none -F 'finishing-a-development-branch' skills/orchestrating
)

# --- 7. Every skill is named hyper-relay:<name>: no upstream superpowers:<skill> name is
# left under skills/ (docs/superpowers/ paths do not match).
no_superpowers_skill_names() (
    cd "$1" || exit 2
    none -E 'superpowers:[A-Za-z]' skills
)
```

Then, in `CHECKS`, replace `no_finishing_branch_in_orchestrating'` with
`no_finishing_branch_in_orchestrating no_superpowers_skill_names'`.

- [ ] **Step 3: Its broken case.** Replace:

```sh
expect_fail no_finishing_branch_in_orchestrating
```

with:

```sh
expect_fail no_finishing_branch_in_orchestrating

broken "brainstorming invoking superpowers:writing-plans"
printf '\nInvoke the superpowers:writing-plans skill.\n' >> "$CASE/skills/brainstorming/SKILL.md"
expect_fail no_superpowers_skill_names
```

- [ ] **Step 4: Run it.**

| Run | Expected |
|---|---|
| `dash -n tests/orchestrating/run-tests.sh` | silent, exit 0 |
| `sh tests/orchestrating/run-tests.sh \| grep -F no_superpowers_skill_names` | `ok   no_superpowers_skill_names` and `ok   no_superpowers_skill_names can fail: brainstorming invoking superpowers:writing-plans` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` (today's tree has no such name; Task 2 Step 1 shows the check failing on upstream's text) |

- [ ] **Step 5: Commit.**

```bash
git add tests/orchestrating/run-tests.sh
git commit -m "test: the relay guard refuses an upstream superpowers:<skill> name under skills/" -m "Upstream's skills name each other superpowers:<skill>; ours are hyper-relay:<skill>. The new check greps skills/ for superpowers: followed by a letter (docs/superpowers/ paths do not match), and its broken case appends upstream's 'Invoke the superpowers:writing-plans skill.' to brainstorming, which the existing writing-plans check does not catch." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: brainstorming from upstream 7.0.2, with the relay's parts (spec §2, §3, §5; BR1–BR9; P3–P9)

**Files:**
- Rewrite: `skills/brainstorming/SKILL.md` (the whole file)
- Create: `skills/brainstorming/builder-check-prompt.md`
- Delete: `skills/brainstorming/spec-document-reviewer-prompt.md`, `tests/claude-code/test-document-review-system.sh`
- Test: `tests/orchestrating/run-tests.sh` (Task 1's check)

- [ ] **Step 1: The check fails on upstream's raw text.** One command per line:

```bash
git show v7.0.2:skills/brainstorming/SKILL.md > skills/brainstorming/SKILL.md
sh tests/orchestrating/run-tests.sh | grep -A 2 '^FAIL'
sh tests/orchestrating/run-tests.sh | tail -n 1
```

Expected: `FAIL no_superpowers_skill_names`, followed by `skills/brainstorming/SKILL.md:32:4. Invoke the
superpowers:writing-plans skill.` and `skills/brainstorming/SKILL.md:282:superpowers:writing-plans and no other
skill.`; then `27 passed, 1 failed`. (Step 2 overwrites the file.)

- [ ] **Step 2: The new `SKILL.md`.** Create `skills/brainstorming/SKILL.md` with exactly this content:

````markdown
---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

You are very good at building. You build what you believe your human
partner wants, and that belief is usually thinner than it feels. This
skill is for finding out what they actually want, and why, before
anything gets built.

People often haven't finished working out what they want. Good questions
help them think it through. When you understand the why, you make the
hundred decisions they never mention the way they would have made them.

## First: What Do You Actually Know?

Before you reply, ask yourself: what do I know about what they want, and
why?

- **The request is one of the off-ramp's cases** ("fix the typo in the
  README"). Ask as the off-ramp says (below).
- **Something non-trivial is missing.** Start the conversation.

**The off-ramp (experiment).** A request may skip the relay (no design,
spec or plan) only when it is one of: a typo; a one-line config change;
a rename; a single obvious bugfix; a question that changes no files, or
when your human partner opts out of the questions (see Your First
Message). For any of them except the question, say which case it
matches and ask, in a message of its own: "This looks like an off-ramp
case (*a one-line config change*). I'd do it directly, with no spec or
plan. OK?" Skip the relay only on a yes. When your human partner already
said to just do it, that is the yes. Anything not on the list, or any
doubt, goes through the relay without asking. If the work turns out
bigger than one change, stop and take it through the relay.

Before you start implementing, you must, in order:

1. Lay out the approaches in a message of their own, and have your
   human partner pick one (see Lay out the approaches).
2. Write the design doc, short or full (see Size the Work).
3. Get their approval of that doc.
4. Invoke the `hyper-relay:orchestrating` skill, whose planner leg
   writes the plan.

If nothing is open when you write your first message and there's one
sensible way, steps 1 to 3 happen in that message (see Your First
Message).

Three things aren't implementing: a spike they said yes to (see Spike to
feel things out), doing what they asked once they've opted out of the
questions, and an off-ramp case they said yes to.

## Look Before You Ask

**Quartz.** Before your first message, run `hyper-relay:orchestrating`'s
Quartz check (`${CLAUDE_SKILL_DIR}/../orchestrating/quartz.md`, §1 and
§2; `../orchestrating/quartz.md` from this SKILL.md). When the repo uses
Quartz and the work has a card, call `tick_brain` with its id; if it
fails, report the failure and carry on. The card's body and its notes
are context your human partner gave you: read them before your first
message, like anything else they pointed at.

In an existing project, or when they've given you context (a spec, a plan,
a handoff, files they pointed at, earlier conversation), dig in before your
first message. Read what they referred to and the code or material it
connects to, and keep reading until you can explain how the relevant
parts work today and what this change would touch. Never ask what the
project or their context already answers, or reopen what they've
already decided.

## Your First Message

Move the work forward, with one of these:

- **They've already said what they want** (a spec, a plan, a detailed
  request): aim for about 200 words for the whole message. Echo their
  request back in your own words, so they can see whether you've got its
  shape: what they want, who it's for, and why, as far as they've said.
  Add what you found that bears on it: how the relevant parts work today
  and what the change would touch. If you found something they may not
  have considered that would change what they're asking for or how it
  has to be built, like a constraint, a conflict, or a cheaper path, say
  so plainly. How to build it comes later, once you understand what they
  want (see Lay out the approaches). End with one line inviting
  corrections. Then, if they haven't told you why they want it, even if
  you can guess, ask about that: one open question in their own terms,
  with nothing to pick from. If they have told you, and their request
  and the project leave open something whose answer would change what
  gets built, ask about the one that would change it most; when its
  choices can be named, sketch each concretely, with what it trades off
  and which you'd pick. If nothing like that is open, there's one
  sensible way: end with the short design itself (the approach, a line on
  why the others don't fit, and the design in a few lines) and ask them
  to approve it. Their approval covers the approach and the design: write
  the short design doc as approved and commit it (see The Written
  Design), then invoke `hyper-relay:orchestrating` in the message that
  gives its path. That approval also covers the written doc, so there is
  no second ask. For a skill change, the short design names its pressure
  scenarios (see The Written Design), so the doc holds nothing they did
  not see.
  Specs are often incomplete, so confirm before you build on one.
- **They haven't:** one open question, in their own terms, about the
  biggest thing their request leaves unsettled. Say why you're asking:
  what the answer would change about what you build. For "a website for
  my bakery": "If it's mostly for people deciding whether to stop by,
  I'd lead with hours and what's in the case today; taking orders is a
  different site. What do you want someone to do when they land on it?"

How the message ends depends on whether their message asked for
brainstorming:

- **They asked for it** (by name, by invoking it, or by asking for a
  design discussion): end there. They want this conversation.
- **They didn't:** they may not want a conversation at all. End with a
  light, one-line offer to just get going instead, like
  "Or if you'd rather I just dive in, say so." If they take you up on
  it, this skill is done: state any significant how-it-gets-made choice
  (platform, language, medium) in one plain line, then do what they
  asked directly, with no spec or plan, as on the off-ramp. When the
  main checkout is on a branch other than `main`, a plan is running
  there: do the work in a worktree of its own
  (`hyper-relay:using-git-worktrees`), never in the main checkout, and
  land it after that branch has merged.

That's the whole message.

## The Conversation

Ask a question only when the answer would change what gets built and
neither the request nor the project answers it. Otherwise, state your
call and your reason as a proposal they can correct, and move the work
forward. Process steps are always your calls: writing things up, where
files go, looking further, how to show something. Do them and say so.
Ask one at a time. Use plain language, pitched just a little above where
your human partner is. Match their vocabulary; never use process jargon.
You never need to quote this skill to your human partner.

Be clear and concise. Lead with what matters. Avoid jargon. When you
report what you found, give them the most important findings and offer
the rest.

**Get them describing.** Until you know why they want it, ask open
questions, with no example answers attached. Their own words carry
intent that your options can't. Once you know why, when a decision has
choices you can name, sketch each concretely, with what it trades off
and which you'd pick. When they say "just guess" or "what do you think?",
propose something concrete.

**How it gets made.** Every project rests on choices about medium, tools,
materials, and resources: the platform, programming language, and
libraries for an app; the medium for a piece of art. Read from how they
talk which of those choices they want to make. Someone who raises the how
or asks about trade-offs wants the options with your pick. Someone who
talks about outcomes is handing you the how: make those calls and state
each in a line. When there's existing work, build on what it already
uses. Any choice you make goes in the design as your call, never as
something they agreed to.

**Ground to cover.** This is territory, not a script. Never read these
out as questions:

- what kind of thing this is, and what makes it special
- why now, and what success looks like to them
- goals, non-goals, and anti-goals (what would make this a failure even
  if it technically works)
- prior art: what they've seen elsewhere, loved or hated
- current state: what exists now, what they've tried
- the details they care about

**Make every question specific** to their project and what they've told
you. Ask Socratically, the way a sharp colleague would: build each
question on their last answer or on something you found, so it helps
them think through a consequence or a case they may have missed
("Voting closes before the meeting, and two members joined this month.
Does someone who joins mid-round get a vote?"). When the reason isn't
already plain, say what you're hoping to learn or what the answer would
change. A proposal they can correct, plus your reason for it, often
beats a question.

**Do recon.** Once you have a bit of grounding and looking further
would help, go look: deeper into their codebase or project, their own
files and data, or the web. Say what you looked for and what you found.

**Lay out the approaches.** Once you understand what they want, and
before you write anything up, put the ways of building it in a message
of its own. Come up with several real alternatives and drop the weak
ones, including any that work against why they want it and any the
existing work rules out. Sketch the two or three that remain concretely
enough to picture, grounded in what the project actually does, with what
each trades off. Recommend one and say why, then ask which way they want
to go; if they've handed you the how, say you'll go with your pick
instead. When there's genuinely one sensible way, say so in that
message and explain why the others don't fit; the design comes in the
next one. This is for how it gets built; for what they want, get them
describing first.

**Show, don't tell.** Whenever seeing would help more than reading,
sketch it in text: a few lines of what they'd see. Offer the visual
companion (below) when the look itself is theirs to decide:

- something they'll look at: a screen, a page, a printout, a sign
- a layout or arrangement: of a screen, a room, a schedule
- a flow or a sequence of steps
- options that would look different from each other
- a structure that's easier to see than read: a diagram, a timeline, a map

Once they've accepted, use it for mockups to react to and side-by-side
options.

**Spike to feel things out.** Agentic work is waterfall, but very, very
fast. A quick throwaway build is often the cheapest way to learn what
they want or whether something works. Offer one when it would help.
When they just want to spike, get out of the way. Spikes get no tests
or minimal ones, aren't bulletproof, and skip the plan, implementation,
and review process. Build a spike in a worktree of its own
(`hyper-relay:using-git-worktrees`), never in the main checkout, and
never merge it. Bring what the spike taught you back into the
conversation.

## Play It Back

Play back as you go. As soon as you understand one part well enough to
describe it (what it's for and who it serves, say, or how one piece
behaves), describe that part back in about 200-300 words, then return to
questions about the next part. Playback and questions alternate through
the whole conversation; the last chunk covers whatever is left.

Only what they said goes in as theirs. Anything you filled in goes in
as your proposal, with your reason. End each chunk by asking what's wrong
or missing.

Before you send a chunk, check it: does it describe something they'll
look at, like a page, a screen, a schedule, or a printout? If so, put a
text sketch next to the description. If the look itself is theirs to
decide and they haven't seen the visual companion offer yet, send the
offer instead (its own message, below) and hold the chunk for the next
message. Once they've accepted, put a mockup next to the description.

## Size the Work

Once you understand what they want and they've picked an approach, say
how big the work is in plain words. They can override it.

| Size | The design doc |
|------|----------------|
| A small change | a short one: what you already covered together, written down |
| A project | the full written design (below) |

Short or full, the design doc has an **Approaches** part: the two or
three ways you considered building it, what each trades off, which one
they picked, and why. They pick in the conversation, before you write
the doc.

Either size goes to the relay: the design doc, then
`hyper-relay:orchestrating`. Only the off-ramp and an opt-out skip it.

If it grows mid-task, stop, say so, and step up a size.

If this is really several independent projects, say so, agree on an
order, and brainstorm them one at a time.

One project that needs more than one plan (an API plan and a web plan,
say) stays one design doc, with a `**Plans:**` line (see The Written
Design).

## The Written Design

Write a plain document a talented builder in the domain could plan
from without going back to your human partner. Cover:

- intent and the why
- goals, non-goals, anti-goals
- constraints
- approaches (above)
- the parts of the how they decided, as they decided them
- what's left to the builder

For a small change, the short design covers the same points in a line
or two each and goes straight to your human partner, without the
builder check. That hand-over is stop 2, as the full design's is
(below), unless they approved the short design in your first message
(see Your First Message): that approval already covered it.

**Where it goes:** in a software repo,
`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, committed.
Otherwise, pick a sensible place and say where. Your human partner's
preferences override both.

- When the work has a Quartz card, run
  `${CLAUDE_SKILL_DIR}/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]`
  (`scripts/add-card-line.sh` beside this SKILL.md) straight after
  writing the spec. With no card, skip this. If the script fails, report
  the failure to your human partner and carry on: a script failure does
  not stop this skill.
- When the work needs more than one implementation plan, for example an
  API plan and a web plan, add a `**Plans:** <n>` line to the spec's
  header, before its first `---` or `## `, with `<n>` from 1 to 9. If
  the design does not make the number clear, ask your human partner how
  many plans it needs. With one plan, leave the line out. Quartz reads
  it, and keeps the card open until that many plans have merged. Such a
  spec also lists its plans in order, under `## The plans`: each with
  its subject, the suffix of its plan's file name (`-api`, `-web`), and
  the plan it builds on, if any. A plan builds on another when it needs
  that plan's unmerged work, and on one plan at most; plans that build
  on nothing run at once (`hyper-relay:orchestrating`'s `parallel.md`).
- When the work creates or changes a skill (a `SKILL.md`, or a file
  beside it that agents read), the spec names its pressure scenarios:
  for each behaviour it changes, a situation, what an agent with the new
  text must do, and what one with today's text does instead. The plan
  turns each into a `skill-test` step, which the orchestrator runs on
  both texts.
- Commit the design document to git, only while the repo's main
  checkout is on `main` (`git branch --show-current` there prints
  `main`), staging it by its path. When the main checkout is on another
  branch, a plan is running there: do not commit. Run
  `quartz link-doc <spec-path>` instead (it puts an uncommitted doc on
  its cards; skip it when the Quartz step found that the repo does not
  use Quartz), and leave the commit for after that branch merges
  (`hyper-relay:orchestrating`'s `reviewing.md`, §5).

**Builder check** (for a project): dispatch a fresh subagent, on Sonnet,
with `${CLAUDE_SKILL_DIR}/builder-check-prompt.md`
(`builder-check-prompt.md` beside this SKILL.md). When you tell your human
partner you're writing it up, say a reviewer will read it first and you
may come back once with a few questions. Don't hand over the document
until the check is back. Sort what the builder asks into three piles:

- **Answered already** by the conversation or the project: put the answer
  in the document.
- **Minor:** a sensible builder could settle it without changing what gets
  built. Settle it yourself and mark it in the document as your call.
- **Theirs:** only your human partner can answer it, and the answer changes
  what gets built.

Bring the "theirs" pile in one message, most important first. Update the
document with their answers, then hand it over with a short list of the
calls you made so they can check those while reading. That's the only
round of questions the check produces. Without a subagent tool, read the
document as that builder yourself.

Commit the document before you hand it over (the commit rule above).
That hand-over is stop 2: their approval is the go-ahead, so invoke
`hyper-relay:orchestrating`, with no second ask. Make the changes they
ask for, commit them, and hand it over again.

<HARD-GATE>
Nothing gets built until your human partner approves the design doc:
the short one for a small change, the full one for a project.
Building includes writing product code, scaffolding, installing
dependencies, creating projects, and invoking an implementation skill.
Reading and exploring are fine.

Three exceptions. If they opted out of the questions, the skill is done
and the gate goes with it. A spike they said yes to may be built; it
stays labeled throwaway, and keeping what it produced is a new request
that comes back through this gate. An off-ramp case they said yes to is
done directly, with no design doc (see First: What Do You Actually
Know?).

After the design doc is approved, the next step is the plan: invoke
`hyper-relay:orchestrating`, whose planner leg dispatches a planner to
write it, and no other skill. Never write the plan yourself, and never
invoke `writing-plans`.
</HARD-GATE>

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll offer a menu of what they might want" | Options steer. Ask them to describe it first. |
| "I'll fill in sensible defaults" | Good. Say them out loud. A default they never heard is one they couldn't reject. |
| "I've answered their questions, so I'll write the doc" | Lay out the approaches first, in a message of their own (or, when nothing was open from the start, in your first message's short design). |
| "I should explain the process first" | Ask your question. The process shows itself. |
| "They said 'sounds good' to the idea" | Approval covers what you showed them. A design doc you haven't written isn't approved. |
| "The spike works, I'll keep building on it" | Keeping it is a new request. Back through the gate. |

## Visual Companion

A browser tab for showing mockups, diagrams, and prototypes. It's a
tool, not a mode: accepting it doesn't send every question to the
browser.

**Offer it just-in-time.** Offer it the first time one of the moments
above comes up, never upfront. The offer is its own message with nothing
else in it:

> "This might be easier if I show you. Want me to open a browser tab with some mockups?"

If they decline, stay in text and don't offer again unless they raise it.

**Per question, ask: would they understand this better by seeing it?**
Mockups, layouts, diagrams, and side-by-side designs go in the browser.
Requirements, scope, tradeoffs, and conceptual choices stay in text. A
question about a UI topic isn't automatically a visual question.

**If they accept — REQUIRED SUB-SKILL: use the `visual-companion`
skill.** Invoke it by name. **Brainstorming does not implement it** —
the `visual-companion` skill owns the server, the frame template and the
screen loop. That skill owns starting the session, writing screens, the
CSS classes available to your content, and cleanup — do not start a
server yourself, and do not look for companion scripts under this
skill. **Brainstorming ships none.** If you find yourself reading a
`visual-companion.md` inside `skills/brainstorming/`, it is a stale copy
from before this split: delete it and use the skill.

**The browser is display-only.** Your human partner looks at the screen
and **answers in the terminal**. There are no clicks to record and no
event file to read — their next terminal message is the answer. Do not
add click handlers, and do not ask your human partner to "click to
select".

**Old screens are not a spec.** A project's `.superpowers/brainstorm/`
may hold screens written
`<div class="option" data-choice="a" onclick="toggleSelect(this)">`, and
server logs holding real captured clicks. Those are artifacts of the
retired fork, not evidence of how this works now. Do not copy their
markup and do not conclude from them that click capture is "what is
deployed here". The `visual-companion` skill is the only implementation.
````

- [ ] **Step 3: The builder check's prompt (§3).** Create `skills/brainstorming/builder-check-prompt.md` with exactly
  this content:

````markdown
# Builder Check Prompt

Dispatch a fresh general-purpose subagent on Sonnet with this prompt once the
written design exists. Fill in the domain and the document path.

```
You are a talented [DOMAIN, e.g. "software engineer", "event planner",
"bakery consultant"]. You've been handed a design document and asked to
put together a plan to build what it describes. You will not be able to
talk to the person who wrote it.

Read [DOCUMENT_PATH].

Report only the questions you'd still need answered before you could plan
this well: places where you'd have to guess and a wrong guess would
matter. For each, give the question and why the answer changes the plan.
Rank them by importance.

Skip anything the document explicitly leaves to the builder, and anything
you could reasonably decide yourself. Skip nitpicks about wording.

If nothing important is left, say "nothing important left".
```
````

- [ ] **Step 4: The spec-document reviewer and its live test go (BR4).**

```bash
git rm skills/brainstorming/spec-document-reviewer-prompt.md tests/claude-code/test-document-review-system.sh
```

- [ ] **Step 5: Check it.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `grep -c -F 'superpowers:' skills/brainstorming/SKILL.md skills/brainstorming/builder-check-prompt.md` | `0` for each |
| `grep -n '^## ' skills/brainstorming/SKILL.md` | nine, in order: First: What Do You Actually Know?, Look Before You Ask, Your First Message, The Conversation, Play It Back, Size the Work, The Written Design, Red Flags, Visual Companion |
| `diff <(git show v7.0.2:skills/brainstorming/SKILL.md) skills/brainstorming/SKILL.md \| grep -E '^[0-9]'` | one line per hunk; each hunk's left-hand lines fall within the places Task 5 Step 3 lists (an inserted hunk may sit one line off, at a blank line) |
| `diff <(git show v7.0.2:skills/brainstorming/builder-check-prompt.md) skills/brainstorming/builder-check-prompt.md` | one hunk, `3c3`: the line gains "on Sonnet" |
| `grep -c -F 'CLAUDE_SKILL_DIR' skills/brainstorming/SKILL.md` | `3` (Review Focus 1) |
| `grep -c -E '(beside\|from) this SKILL\.md' skills/brainstorming/SKILL.md` | `3`: each of those files is also named relative to `SKILL.md` (Review Focus 1) |
| `grep -c -F -e 'commit it (see The Written' -e 'When the main checkout is on another' skills/brainstorming/SKILL.md` | `2` (Review Focus 2) |
| `grep -c -F -e 'With no card, skip this.' -e 'skip it when the Quartz step found' -e 'When the repo uses' skills/brainstorming/SKILL.md` | `3` (Review Focus 3) |
| `grep -c -i -E 'self-review\|Please review it\|token-intensive\|prototypes they can click\|in this directory\|normal workflow\|go on to the plan' skills/brainstorming/SKILL.md` | `0` |
| `grep -r -n -F -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' skills/brainstorming` | nothing |
| `git grep -n -e spec-document-reviewer-prompt -e test-document-review-system -- . ':!docs' ':!RELEASE-NOTES.md'` | nothing (P3) |

- [ ] **Step 6: Commit.**

```bash
git add skills/brainstorming/SKILL.md skills/brainstorming/builder-check-prompt.md
git commit -m "feat: brainstorming from upstream superpowers 7.0.2, with the relay's parts" -m "Upstream's rebuilt skill is the base, word for word: it reads before its first message, asks why first and openly, asks only what changes what gets built, plays the design back in chunks, sizes the work and has a builder check read the written design. The relay's parts are put back at named places: the Quartz step before the first message, the off-ramp (an opt-out is its own), worktrees for opt-outs during a branch run and for spikes, the card line, Plans line, pressure scenarios and commit rule under Where it goes, the builder check on Sonnet, the hand-over to orchestrating (a short design approved in the first message stands for stop 2), and the visual-companion skill. The spec-document reviewer, which nothing dispatched, and its live test go." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

(The two deletions were staged by Step 4's `git rm`, and go in this commit.)

### Task 3: `orchestrating` follows (spec §4; BR3, BR8; P2)

**Files:**
- Modify: `skills/orchestrating/quartz.md:6`, `:10-11`, `:50`, `:110-113`, `:114-116`
- Modify: `skills/orchestrating/SKILL.md:37-38` (the stops table)
- Modify: `skills/orchestrating/planning.md:3-4`, `:8-9`

- [ ] **Step 1: `quartz.md`, the four pointers and P2's line.** Replace each X with its Y.

X1:

```text
`hyper-relay:brainstorming` runs §1 and §2 at its step 1, before any other leg.
```

Y1:

```text
`hyper-relay:brainstorming` runs §1 and §2 before its first message, before any other leg.
```

X2:

```text
Read it from files and git every time, never from memory: at `brainstorming`'s step 1, and whenever `orchestrating`
starts or resumes a leg. Run the tests in this order; **the first match decides**:
```

Y2:

```text
Read it from files and git every time, never from memory: before `brainstorming`'s first message, and whenever
`orchestrating` starts or resumes a leg. Run the tests in this order; **the first match decides**:
```

X3:

```text
`brainstorming`'s step 1, send it before brainstorming's first question.
```

Y3:

```text
`brainstorming`'s start, send it before brainstorming's first message.
```

X4:

```text
- **Card** (at `brainstorming`'s step 1, with the MCP): the card the owner names; otherwise one in Needs brainstorming
  that matches the work (`list_tasks`); otherwise a new one through `add_tasks`, titled with the work's topic, kind
  `bug` or `change` when one fits, in the initiative the owner names, if any. Say so in one line, with its id. Then
  `tick_brain` with its id.
```

Y4:

```text
- **Card** (before `brainstorming`'s first message, with the MCP): the card the owner names; otherwise one in Needs
  brainstorming that matches the work (`list_tasks`); otherwise a new one through `add_tasks`, titled with the work's
  topic, kind `bug` or `change` when one fits, in the initiative the owner names, if any. Say so in one line, with its
  id. Then `tick_brain` with its id.
```

X5 (P2):

```text
- **Card lines:** as `brainstorming`'s Documentation says. A card that arrives after its spec was written (the MCP
  loaded late) gets its line then, with brainstorming's script (§4); a spec already committed gets it in a commit of
  just the spec, while the main checkout is on `main`.
```

Y5:

```text
- **Card lines:** as `brainstorming` says under The Written Design. A card that arrives after its spec was written
  (the MCP loaded late) gets its line then, with brainstorming's script (§4); a spec already committed gets it in a
  commit of just the spec, while the main checkout is on `main`.
```

- [ ] **Step 2: `SKILL.md`, the stops table.** Replace:

```text
| 1. Design | The design, section by section (`brainstorming`) | the spec |
| 2. Spec | The written spec (`brainstorming`) | the planner leg: approval is the go-ahead, no second ask |
```

with:

```text
| 1. Design | The approaches, then the design played back part by part (`brainstorming`) | the spec |
| 2. Spec | The written spec (`brainstorming`); skipped when the owner approved a short design in brainstorming's first message, which covers stops 1 and 2 | the planner leg: approval is the go-ahead, no second ask |
```

- [ ] **Step 3: `planning.md`, its opening and §1.** Replace:

```text
The planner leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when the owner approves the
written spec (stop 2) and ends at stop 3. You do not write the plan: a planner does, in its own context.
```

with:

```text
The planner leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when the owner approves the
written spec (stop 2), or when `brainstorming` hands over a spec written from a short design the owner approved in its
first message, which stands for stop 2. It ends at stop 3. You do not write the plan: a planner does, in its own
context.
```

Then replace:

```text
Straight after the owner approves the written spec, dispatch the planners in the background. The approval is the
go-ahead: do not ask again. Then tell the owner they are running, and carry on.
```

with:

```text
Straight after the owner approves the written spec, or `brainstorming` hands over a spec written from a short design
the owner approved, dispatch the planners in the background. The approval is the go-ahead: do not ask again. Then tell
the owner they are running, and carry on.
```

- [ ] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'step 1' skills/orchestrating/quartz.md` | `0` |
| `grep -c -F 'Documentation' skills/orchestrating/quartz.md` | `0` (P2) |
| `grep -c -F 'first message' skills/orchestrating/quartz.md` | `4` (lines 6, 10, 50, 110) |
| `grep -r -n -i -E 'brainstorming.{0,2}s (step [0-9]\|Documentation\|checklist)' skills` | nothing (Review Focus 4) |
| `grep -c -F 'short design' skills/orchestrating/SKILL.md skills/orchestrating/planning.md` | `skills/orchestrating/SKILL.md:1`, `skills/orchestrating/planning.md:2` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [ ] **Step 5: Commit.**

```bash
git add skills/orchestrating/quartz.md skills/orchestrating/SKILL.md skills/orchestrating/planning.md
git commit -m "feat: orchestrating follows the new brainstorming" -m "quartz.md's pointers to brainstorming's step 1 now say before its first message, and its card-line pointer names The Written Design. The stops table says what stop 1 shows now, and that a short design approved in brainstorming's first message covers stops 1 and 2; the planner leg starts on either approval." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: README's Design row and diagram, and the full gates (spec §6; BR9; P1)

**Files:**
- Modify: `README.md:33` (a diagram line, two lines after it), `:56` (the Design row)

- [ ] **Step 1: The diagram (P1).** Replace:

```text
        spec --> stop2{{"<b>Stop 2</b><br>you approve<br>the spec"}}
```

with:

```text
        spec --> stop2{{"<b>Stop 2</b><br>you approve<br>the spec"}}
        stop2 --> handover(["on to the<br>planner"])
        spec -. short design approved .-> handover
```

- [ ] **Step 2: The Design row.** Replace:

```text
| Design | `brainstorming` (+ `visual-companion` for mockups) | An approved design, written as a spec in `docs/superpowers/specs/` |
```

with:

```text
| Design | `brainstorming` (+ `visual-companion` for mockups) | An approved design, written as a spec in `docs/superpowers/specs/`, read first by a builder check |
```

- [ ] **Step 3: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'read first by a builder check' README.md` | `1` |
| `grep -c -F -e 'stop2 --> handover' -e 'spec -. short design approved .-> handover' README.md` | `2` |
| `grep -c -F -e '-> planner' README.md` | `0`: no edge, solid or dashed, runs from a node in `brainstorming` to `planner` (P1) |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [ ] **Step 4: Commit.**

```bash
git add README.md
git commit -m "docs: README's Design row names the builder check; the diagram shows the short-design skip" -m "Approving a short design in brainstorming's first message covers stop 2: a dashed edge from the spec to the hand-over, beside the path through stop 2, inside brainstorming's box so both boxes keep their top-to-bottom layout." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 5: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `dash -n tests/orchestrating/run-tests.sh` | silent, exit 0 |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git diff --name-only main...HEAD` | exactly `README.md`, `skills/brainstorming/SKILL.md`, `skills/brainstorming/builder-check-prompt.md`, `skills/brainstorming/spec-document-reviewer-prompt.md`, `skills/orchestrating/SKILL.md`, `skills/orchestrating/planning.md`, `skills/orchestrating/quartz.md`, `tests/claude-code/test-document-review-system.sh`, `tests/orchestrating/run-tests.sh` |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Upstream's live suites are not run (report this). Then report, copy Task 5's checklist (Steps 1–25, each with its
marker and its PASS) into your report, and stop: Task 5 is not yours.

### Task 5: Acceptance (spec §7, §8; P10–P14). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-brainstorming-v7`) its dispatch names, from the checkout's top (Steps 1–6). Commands run in bash
  (`<(…)` is process substitution).
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the standing leg
  (`reviewing.md` §3, the installed relay's): `<E>` is that leg's evidence folder, whose `red/` and `green/` hold
  `main`'s and the branch's `skills/`. Steps 7–17 are S1–S11: each is dispatched twice, on Sonnet, in the
  background, with the leg's standing preamble and then the step's situation, verbatim, with its `<CONTEXT>` line
  replaced by the Context block below, verbatim. S6 is a guard: GREEN and RED are both expected to pass it.
- **`owner`**: the owner (Steps 18–19 at the click-through; Step 24 after the update).
- **`after merge`**: the orchestrator with the owner, once the branch is merged into `main` and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 20–23, 25). The orchestrator runs the commands; the owner runs
  the plugin update and the reload.

In a command inside a table cell, `\|` is a plain `|`, as in the Execution notes.

**This plan's run follows the installed relay** (0.2.1's `orchestrating` and `brainstorming`), not the text it
writes: the new behaviour reaches a session only after the release and the owner's update (Steps 21–22).

**The Context block** (P11), for every situation's `<CONTEXT>` line:

```text
You are the agent your human partner talks to, in Claude Code, in the hyper-relay repo: a Claude Code and OpenCode
plugin made of Markdown skills and POSIX shell tools (run by dash), with their tests. Its main checkout is
/home/noob_master/hyper-relay, your working directory. Your human partner's global instructions say: "All creative
work (new features, new components, new functionality, behaviour changes) runs through hyper-relay's relay. Start any
change to files with `hyper-relay:brainstorming`. Once I approve a spec, `hyper-relay:orchestrating` runs the rest."
A skill named `hyper-relay:<name>` is the folder `<name>` in your skills folder: follow `brainstorming` (its SKILL.md
and the files beside it), and read any other skill it sends you to. Your tools include the Skill tool (to invoke a
skill: say which) and the Agent tool (it dispatches a subagent and takes a `model`: `sonnet` or `opus`). In this test
you cannot read the repo's files: list each read among your commands, and take what it would show from the facts the
situation gives.
```

- [ ] **Step 1 (`reviewer`): The suites and the manifest (spec §8 steps 1–2).**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout, `PRIVACY_URL_MISSING`; no other warning |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `sh tests/orchestrating/run-tests.sh \| grep -c -F no_superpowers_skill_names` | `2`: the check and its broken case, both `ok` |
| `git ls-files 'skills/*/SKILL.md' \| wc -l` | `17` |
| `git show HEAD:.claude-plugin/plugin.json \| grep -F '"version"'` | `"version": "0.2.1",` (the release is after the merge) |

- [ ] **Step 2 (`reviewer`): Only the planned files (spec §1, §9).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the nine files of Task 4 Step 5 |
| `git diff main...HEAD -- skills README.md \| grep -c -E '^\+.*(/home/\|~/\|/tmp/\|/Users/)'` | `0` |
| `git diff --stat main...HEAD -- skills/brainstorming/scripts skills/visual-companion templates bin hooks .claude-plugin` | nothing |

- [ ] **Step 3 (`reviewer`): `SKILL.md` against upstream (spec §8 step 3, §2; P4–P9).** Run
  `diff <(git show v7.0.2:skills/brainstorming/SKILL.md) skills/brainstorming/SKILL.md` and read every hunk. PASS:
  each hunk is one of these, by upstream's line numbers (an inserted hunk may sit one line off, at a blank line), and
  says what the plan's Task 2 Step 2 text says; nothing else differs:

| Upstream lines | §2 edit |
|---|---|
| 3 | §2.1: today's `description` |
| 22–23 | §2.2: the first bullet sends an off-ramp case to the off-ramp (P5) |
| after 25 | §2.2: the off-ramp paragraph, today's words, plus the opt-out (P4) |
| 32 | §2.2: step 4 invokes `hyper-relay:orchestrating` |
| 38–40 | §2.2: three things aren't implementing |
| after 43 | §2.3: the Quartz paragraph |
| 76 | §2.4: the approved short design is written, committed and handed to `orchestrating`; no second ask; a skill change's short design names its pressure scenarios |
| 95 | §2.4: an opt-out is done directly, with no spec or plan; in a worktree of its own while a plan runs on a branch |
| 179–180 | §2.5: no "throwaway prototypes they can click" |
| 187 | §2.5: a spike is built in a worktree of its own and never merged |
| after 223 | §2.7: either size goes to the relay |
| after 228 | §2.7: one project with several plans stays one design doc, with a `**Plans:**` line |
| 243 | §2.8: the small change's hand-over is stop 2, unless approved in the first message (P6) |
| after 249, 250–251 | §2.8: Where it goes gains today's four rules (P9); the builder check's prompt by `${CLAUDE_SKILL_DIR}` and relative path, on Sonnet |
| after 268 | §2.8: commit before the hand-over; the hand-over is stop 2; changes are committed and handed over again (P6) |
| 276 | §2.9: three exceptions |
| 279 | §2.9: the off-ramp exception |
| 282 | §2.9: `hyper-relay:orchestrating`, never write the plan, never invoke `writing-plans` |
| 315–316 | §2.11: the `visual-companion` skill, then today's three paragraphs (P7) |

  Also: no `superpowers:` skill name; "your human partner", not "the owner" or "the user", in every moved line
  (`grep -n -E 'the owner|the user' skills/brainstorming/SKILL.md` prints nothing); and §2.12's removed parts are gone
  (no checklist, process graph, "This Is Too Simple", Key Principles, Spec Self-Review, "Spec written to", or the
  token-cost offer). A sentence that contradicts the spec beyond the P-notes is a FAIL, with its line.

- [ ] **Step 4 (`reviewer`): `builder-check-prompt.md` against upstream (spec §8 step 3, §3).**

| Run | PASS |
|---|---|
| `diff <(git show v7.0.2:skills/brainstorming/builder-check-prompt.md) skills/brainstorming/builder-check-prompt.md` | one hunk, `3c3`: `Dispatch a fresh general-purpose subagent on Sonnet with this prompt once the` |

- [ ] **Step 5 (`reviewer`): The deleted files (spec §8 step 4, BR4; P3).**

| Run | PASS |
|---|---|
| `test -e skills/brainstorming/spec-document-reviewer-prompt.md; echo $?` | `1` |
| `test -e tests/claude-code/test-document-review-system.sh; echo $?` | `1` |
| `git grep -n -e spec-document-reviewer-prompt -e test-document-review-system -- . ':!docs' ':!RELEASE-NOTES.md'` | nothing |
| `git diff --stat main...HEAD -- RELEASE-NOTES.md` | nothing (upstream's dated history, untouched) |

- [ ] **Step 6 (`reviewer`): `orchestrating`, the machine paths and README (spec §8 step 5, §4, §6; P1, P2).**

| Run | PASS |
|---|---|
| `grep -c -F 'step 1' skills/orchestrating/quartz.md` | `0` |
| `git diff main...HEAD -- skills/orchestrating` | exactly Task 3's changes: quartz.md's lines 6, 10–11, 50, 110–113 and 114–116; SKILL.md's stops rows 1 and 2; planning.md's opening and §1's first sentence |
| `grep -r -n -F -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' skills/brainstorming` | nothing |
| `grep -n -F 'CLAUDE_SKILL_DIR' skills/brainstorming/SKILL.md` | three lines, each followed on its next line by the same file named relative to `SKILL.md` (`from this SKILL.md` or `beside this SKILL.md`) |
| `git diff main...HEAD -- README.md` | the Design row's new cell (§6) and the two diagram lines (P1); nothing else |

  Read the README's mermaid block. PASS: no edge joins a node inside one subgraph to a node inside the other (P1:
  both keep `direction TB`), and the dashed "short design approved" edge runs from `spec` to `handover`, beside
  `stop2 --> handover`.

- [ ] **Step 7 (`skill-test`): S1, invoked by name, no why given (§7 S1; §2.2–§2.4).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Your human partner types: "/hyper-relay:brainstorming add a `--json` flag to `wt ls`"

What the repo holds, as you would find on reading it:
- `bin/wt` is POSIX shell run by dash. `wt ls` lists every `wt` stack on this machine, one line per stack: its name,
  how many of its containers run, its worktree, and then its URLs. A stack whose worktree is gone is marked stale,
  with the `wt down <name>` that clears it. No `wt` command takes `--json` today.
- `docs/wt.md` documents `wt ls` in those words, in its "`wt ls` and `wt down`" section.
- `tests/wt/run-tests.sh` tests `wt` with a fake `docker` and `ss`; it ends "0 failed".

Give the commands you run, in order, and your next message, verbatim.
```

GREEN must: list reads of `bin/wt` and `docs/wt.md` before the message; send one message of about 200 words that
echoes the request in its own words, says what it found (how `wt ls` works today, that nothing takes `--json`), and
ends with one open question about why they want it (who or what will read the JSON), with no options to pick from;
no "just dive in" offer (they invoked it by name) and no visual-companion offer.

RED is expected to: ask a clarifying question about the what (which fields, which format), often multiple choice.

- [ ] **Step 8 (`skill-test`): S2, a card with the what and the why (§7 S2; §2.3, §2.4; P10).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. The repo uses Quartz: its Quartz check (`orchestrating`'s `quartz.md` §1
and §2) passes every test (connected, hooks installed, token found), and the Quartz MCP tools (`mcp__quartz__…`) are
loaded.

Your human partner types: "/hyper-relay:brainstorming card 7c1e0b2a-4f3d-4c8e-9a51-2d6b8e0f1a93"

The card, as the Quartz MCP's `get_task` returns it: title "relay-merge --version"; body: "`relay-merge --version`
prints the plugin's version from `.claude-plugin/plugin.json`, so I can tell which `relay-merge` is on my PATH: the
main checkout's symlink, or a plugin cache's copy." No notes.

What the repo holds, as you would find on reading it:
- `bin/relay-merge` is POSIX shell run by dash. It sits in the plugin's `bin/`, beside `.claude-plugin/`, whose
  `plugin.json` has `"version": "0.2.2"`.
- `docs/relay-merge.md` says it "takes no options: its settings are environment variables" (`PUSH`, `KEEP`,
  `SKIP_TESTS`, `RELAY_MERGE_TRAILERS`, `XDG_STATE_HOME`); its arguments are the branches to land.
- `bin/hyper-relay-agents` already reads that `"version"` from the `plugin.json` beside its own folder, with one `sed`.
- `tests/relay-merge/run-tests.sh` tests `relay-merge` on temporary git repos; it ends "0 failed".

Give the commands and tool calls you make, in order, and your next message, verbatim.
```

GREEN must: before the message, list the Quartz check, `tick_brain` with `7c1e0b2a-4f3d-4c8e-9a51-2d6b8e0f1a93` (P10),
and reads of `bin/relay-merge` and `docs/relay-merge.md`; send a first message (about 200 words) that echoes the
request and what it found, then ends with the short design (the approach, a line on why the others don't fit, the
design in a few lines) and asks for approval; ask no clarifying question, and make no "just dive in" offer.

RED is expected to: ask clarifying questions first, with no short design.

- [ ] **Step 9 (`skill-test`): S3, the short design approved (§7 S3; §2.4, §2.8; BR3; P10).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean (`git branch --show-current` there prints `main`). The repo uses Quartz:
every check of its Quartz check passes and the Quartz MCP tools are loaded. Today is 2026-11-19.

Earlier in this conversation, your human partner typed "/hyper-relay:brainstorming card
7c1e0b2a-4f3d-4c8e-9a51-2d6b8e0f1a93". You ran the Quartz check, called `tick_brain` with that id, read the card
(title "relay-merge --version"; body: "`relay-merge --version` prints the plugin's version from
`.claude-plugin/plugin.json`, so I can tell which `relay-merge` is on my PATH: the main checkout's symlink, or a plugin
cache's copy."), read `bin/relay-merge`, `docs/relay-merge.md` and `bin/hyper-relay-agents`, and sent this message:

  You want `relay-merge --version` to print the plugin's version, read from `.claude-plugin/plugin.json`, so you can
  tell which `relay-merge` is on your PATH: the main checkout's symlink or a plugin cache's copy.

  What I found: `relay-merge` takes no options today (its settings are environment variables), so `--version` would
  be its first flag. `bin/hyper-relay-agents` already reads that version from the `plugin.json` beside its own
  folder, with one `sed` line.

  There's one sensible way, so here is the short design. `relay-merge --version` finds its own file (following the
  symlink), reads `"version"` from the `.claude-plugin/plugin.json` beside its `bin/` folder with the generator's
  `sed`, prints `relay-merge 0.2.2` and exits 0, before any check runs. An environment variable doesn't fit a
  question you ask once, and a separate script would put a second name on your PATH. `docs/relay-merge.md` gains the
  flag under Usage, and `tests/relay-merge/run-tests.sh` a test with its own `plugin.json`. It's a small change.

  Does that look right? If you approve it, I'll write it up and hand it to the planner.

Your human partner replies: "Approved."

Give the commands and tool calls you make, in order, and your next message, verbatim.
```

GREEN must: write `docs/superpowers/specs/2026-11-19-<topic>-design.md` holding the short design as approved (a line
or two per point, with its Approaches part); run brainstorming's `add-card-line.sh` on it with
`7c1e0b2a-4f3d-4c8e-9a51-2d6b8e0f1a93`; commit just that file (staged by its path) on `main`; invoke
`hyper-relay:orchestrating`; and send a message that gives the spec's path and says the planner leg is starting. No
"Please review it", no second ask for approval, no self-review step.

RED is expected to: self-review the spec, then "Spec written to `<path>`. Please review it …".

- [ ] **Step 10 (`skill-test`): S4, not asked for brainstorming (§7 S4; §2.4).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Your human partner types: "Sort `wt ls` by age." They did not ask for brainstorming: you started it because their
global instructions say to start any change to files with it.

What the repo holds, as you would find on reading it:
- `docs/wt.md`: "`wt ls` prints one line per stack: its name, how many of its containers run, its worktree, and then
  its URLs. A stack whose worktree is gone is marked stale, with the `wt down <name>` that clears it." It names no
  order.
- `bin/wt` (POSIX shell, run by dash): `wt ls` walks the stacks' state folders under `~/.local/state/wt/` in the
  shell's glob order, which is by stack name. A stack's state folder holds a `slot` file, written once when the stack
  first comes up, and files that each `wt up` rewrites. Nothing records a creation time.

Give the commands you run, in order, and your next message, verbatim.
```

GREEN must: read before replying; send a first message that echoes the request with what it found and ends with a
light, one-line offer to just get going instead (like "Or if you'd rather I just dive in, say so.").

RED is expected to: make no such offer.

- [ ] **Step 11 (`skill-test`): S5, "just do it" while a plan runs on a branch (§7 S5; §2.4; BR2).**

Situation:

```text
<CONTEXT>

`git -C /home/noob_master/hyper-relay branch --show-current` prints `hyper-relay-x`: a plan's executor is working on
that branch, in the main checkout. `git config --get hyper-relay.quartz` prints `off`.

Earlier in this conversation, your human partner typed "Sort `wt ls` by age." They did not ask for brainstorming: you
started it from their global instructions. You read `bin/wt` and `docs/wt.md` and sent:

  You'd like `wt ls` to list the stacks by age instead of by name.

  What I found: `wt ls` prints one line per stack (its name, how many containers run, its worktree, its URLs), in the
  order of the stacks' state folders under `~/.local/state/wt/`, which is by name. Nothing records when a stack was
  made: its folder holds a `slot` file written when the stack first came up, and files that each `wt up` rewrites.
  So "age" could mean since its first `wt up` or since its last one, and the two orders differ for a stack you
  restart often.

  What do you want the order to help you see?

  Or if you'd rather I just dive in, say so.

Your human partner replies: "just do it"

The repo's `wt` suite is `tests/wt/run-tests.sh` (it ends "0 failed"); `.worktrees/` is gitignored.

Give the commands you run, in order, and your next message, verbatim.
```

GREEN must: state any significant how in one plain line (for example, oldest first by the `slot` file's time); build
it directly, with no spec, plan or `orchestrating`: create a worktree of its own from `main` (by
`hyper-relay:using-git-worktrees`, for example `git worktree add .worktrees/<name> -b <branch> main`), and edit,
test (`dash -n bin/wt`, `sh tests/wt/run-tests.sh`) and commit there; change nothing in the main checkout (no edit,
switch, stash or commit there) and merge nothing into `main` while `hyper-relay-x` runs.

RED is expected to: take it through the relay anyway (a design or spec), since sorting `wt ls` is not an off-ramp case.

- [ ] **Step 12 (`skill-test`): S6, a typo, the off-ramp guard (§7 S6; §2.2). Expected to pass on both.**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Your human partner types: "Fix the typo 'recieve' in docs/wt.md." They did not ask for brainstorming: you started it
because their global instructions say to start any change to files with it.

`docs/wt.md` has that word once, in its "State and limits" section.

Give the commands you run, in order, and your next message, verbatim.
```

GREEN must: change nothing, and send the off-ramp question in a message of its own, naming the case: "This looks like
an off-ramp case (*a typo*). I'd do it directly, with no spec or plan. OK?" (or very close).

RED is expected to: do the same (the guard against upstream's "Do it, and say what you did").

- [ ] **Step 13 (`skill-test`): S7, a project-size design and its builder check (§7 S7; §2.8, §3; BR4, BR9; P11).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`. Today is 2026-11-19.

Earlier in this conversation (it began with "/hyper-relay:brainstorming"), you and your human partner worked out a new
skill, `changelog`. All of this was said and confirmed:
- Why: people who update the plugin should see what changed, in plain words, without reading commits.
- What: at each release, the orchestrator writes the new version's entry at the top of a new `CHANGELOG.md`: a
  heading `## v<x.y.z> (<date>)`, then one bullet per change a user of the plugin would notice, from the plans merged
  since the previous tag (each plan's Goal line, and its spec's Goal). A plan that changed no file the plugin loads
  gets no bullet.
- When: in the release, after `scripts/bump-version.sh` and before the release commit.
- Approaches you laid out: (a) a skill the orchestrator follows at release; (b) a script, `scripts/changelog.sh`, that
  pastes the plans' Goal lines; (c) GitHub's generated release notes. They picked (a): the entry needs judgement
  about what a user notices, and the orchestrator already runs the release.
- Not wanted: an entry for every commit; anything about the relay's own agents.
- You played back each part (what it reads, what it writes, when it runs), and they confirmed each. You said it is a
  project, not a small change, and they agreed.

Part 1. Give the commands and tool calls you make, in order, and every message you send, up to the point where you
wait for your human partner. When a subagent you dispatch reports, take its report to be this, verbatim:

  1. Is `CHANGELOG.md` committed in the release commit, which the repo's rules say holds only `package.json` and
     `.claude-plugin/plugin.json`, or in a commit of its own before it? This changes the release steps and a rule the
     owner set.
  2. Does a plan that changed only docs or tests get a bullet? This changes what the skill reads.
  3. Is the date in the heading the release commit's date or the merge's? Either works; the plan needs one.
  4. Should the skill also publish the entry as a GitHub release? That needs `gh` and credentials, and a step after
     the push.

Part 2. Your human partner answers: "1: in the release commit, so it holds three files. 4: no, not now." Give the
commands you run, in order, and your next message, verbatim.
```

GREEN must: in Part 1, say it is writing it up and that a reviewer reads it first and it may come back once with a few
questions; write `docs/superpowers/specs/2026-11-19-<topic>-design.md` as a full design (intent and why, goals,
non-goals and anti-goals, constraints, approaches, the decided how, what's left to the builder, and pressure
scenarios, since it is a new skill); dispatch a fresh subagent with `model: sonnet` and `builder-check-prompt.md`'s
prompt, its domain and the doc's path filled in, before handing anything over; put question 2's answer in the doc
without asking (agreed: no bullet for a plan that changed no file the plugin loads); settle question 3 itself and mark
it in the doc as its call, without asking; send questions 1 and 4 in one message, 1 first. In Part 2: update the doc
with the answers, commit just that file, and hand it over in a message that gives its path and a short list of the
calls it made (question 3's date among them), with no further questions. No self-review step anywhere, and not
today's "Spec written to `<path>`. Please review it and let me know if you want to make any changes before we start
writing out the implementation plan."

RED is expected to: write the doc, review it inline, then "Spec written to `<path>`. Please review it …", with no
builder check.

- [ ] **Step 14 (`skill-test`): S8, only the question that changes what gets built (§7 S8; §2.4, §2.5).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Your human partner types: "/hyper-relay:brainstorming Add a `--quiet` flag to `relay-merge`. When the orchestrator
runs it, everything it prints lands in the agent's context, and most of it is noise there."

What the repo holds, as you would find on reading it:
- `bin/relay-merge` is POSIX shell run by dash (`#!/bin/sh`); the repo's rule is that it stays so.
- `docs/relay-merge.md`: it "takes no options: its settings are environment variables" (`PUSH`, `KEEP`,
  `SKIP_TESTS`, `RELAY_MERGE_TRAILERS`, `XDG_STATE_HOME`). For each branch it prints one line per gate; the gates'
  own output goes to a log. When a gate fails, it prints the log's last 20 lines, the log's path and the commit `main`
  was on before the merge. A failed push or cleanup prints a warning.

Give the commands you run, in order, and your next message, verbatim.
```

GREEN must: read `bin/relay-merge` and `docs/relay-merge.md` first; send one message (about 200 words) that echoes the
request and what it found and asks exactly one question, what `--quiet` hides, with the choices sketched concretely
(for example: only the per-gate lines; also the push and cleanup lines; everything but a failure's report), each with
what it trades off, and its pick; state as its own calls, without asking, that it stays POSIX shell run by dash and
where the spec goes (`docs/superpowers/specs/…`); make no "just dive in" offer.

RED is expected to: ask clarifying questions one at a time, among them ones the project or the process answers (the
shell, where the spec goes), often as a list to pick from without its pick.

- [ ] **Step 15 (`skill-test`): S9, the visual-companion offer, just in time (§7 S9; §2.11; BR6; P11).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Part 1. Your human partner types: "/hyper-relay:brainstorming I want a tmux status-bar line for `wt`: each worktree's
stack, at a glance. I keep losing track of which stacks are up. How it looks on the bar is my call."

What the repo holds, as you would find on reading it: `wt ls` prints one line per stack (its name, how many of its
containers run, its worktree, its URLs), and marks a stack whose worktree is gone as stale. No `wt` command prints a
line shaped for tmux. The repo has no tmux file.

Give the commands you run, in order, and your next message, verbatim.

Part 2. Later in the conversation: the why is settled (they want to see, from any tmux pane, which stacks are up and
which are stale), and the approach is picked (a `wt status` command that prints one short line, which tmux's
`status-right` runs). Two parts have been played back and confirmed. The next part to play back is what the line looks
like: which stacks it shows, in what order, with which marks and colours. That look is theirs to decide. They have not
been offered the visual companion yet.

Give your next message, verbatim.
```

GREEN must: in Part 1, make no visual-companion offer; in Part 2, send the offer alone, in upstream's words ("This
might be easier if I show you. Want me to open a browser tab with some mockups?", or very close), with nothing else in
the message and no warning about tokens or cost, holding the chunk for the next message.

RED is expected to: offer the companion up front, in a message of its own, with the token-cost warning ("This feature
is still new and can be token-intensive").

- [ ] **Step 16 (`skill-test`): S10, a spike in a worktree of its own (§7 S10; §2.5; BR7; P11).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`. `.worktrees/` is
gitignored.

Earlier in this conversation (it began with "/hyper-relay:brainstorming"), your human partner asked for a tmux
status-bar line for `wt`, showing each worktree's stack, and you played back what it is for. They now say: "My worry
is that tmux can't refresh a status line every second without lag when the line runs a shell command each time. If it
can't, I'd rather have a line that only changes when I run `wt up` or `wt down`. That decides the design."

Part 1. Give your next message, verbatim.

Part 2. They reply: "Yes, try it." Give the commands you run, in order, and the message you send when you are done,
verbatim. Where a command would print something you cannot know, say what you would look for in it.
```

GREEN must: in Part 1, offer a spike (a quick throwaway build to see whether a one-second refresh lags); in Part 2,
create a worktree of its own (by `hyper-relay:using-git-worktrees`, for example
`git worktree add .worktrees/<name> -b <branch>`) and build the throwaway there (a script that prints a line, tmux
with `status-interval 1`, a timing check), with no spec, no plan and no tests or minimal ones; change nothing in the
main checkout; merge nothing (no `git merge`, no `relay-merge`, no commit on `main`); and its message brings what the
spike showed back to the design question, labelled throwaway.

RED is expected to: build nothing before an approved design (reasoning or research instead, or a design to approve
first).

- [ ] **Step 17 (`skill-test`): S11, a small change sized and handed over (§7 S11; §2.7, §2.8; BR5; P11).**

Situation:

```text
<CONTEXT>

The main checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`. Today is 2026-11-19.

Earlier in this conversation (it began with "/hyper-relay:brainstorming"), your human partner asked that
`docs/relay-merge.md`'s exit-code table say that the branches before the one that failed stay landed. Its rows for
`1` and `2` read today:

  | `1` | A check refused a branch; that branch did not change `main`. |
  | `2` | A merge conflict; it was aborted, and `main` is unchanged for that branch. |

The why is settled (they misread the table once, and undid a branch that had landed). You laid out two approaches:
(a) add "The branches before it stay landed." to rows `1` and `2`; (b) a sentence under the table. They picked (a).
Nothing else is open.

Part 1. Give the commands you run, in order, and your next message, verbatim.

Part 2. They reply "Approved." to that message. Give the commands and tool calls you make, in order, and your next
message, verbatim.
```

GREEN must: say in plain words that this is a small change; write a short design doc
(`docs/superpowers/specs/2026-11-19-<topic>-design.md`, a line or two per point, with its Approaches part) with no
builder check and no self-review; commit just that file; hand it over in a message of its own (stop 2); and invoke
`hyper-relay:orchestrating` only after "Approved." answers that hand-over, with no second ask. (When Part 1 only
states the size, Part 2 writes, commits and hands over the doc, and does not invoke `orchestrating` yet: also GREEN.)

RED is expected to: give no size; take the full process (the design presented in sections, then the spec, an inline
self-review and "Spec written to `<path>`. Please review it …").

- [ ] **Step 18 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay show hyper-relay-brainstorming-v7:skills/brainstorming/SKILL.md` and
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-brainstorming-v7 -- skills/orchestrating README.md`,
  with stop 4's skill-test results and the P-notes, P1 and P2 above all. PASS: the owner agrees with them as written.
  A change goes to the executor as a finding.

- [ ] **Step 19 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-brainstorming-v7` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging. The merge runs as the installed relay says:
`relay-merge` from the main checkout on `main`.

- [ ] **Step 20 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh` (last line) | `28 passed, 0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |

- [ ] **Step 21 (`after merge`): The release, 0.2.2 (spec §8; `.hyper-relay/agents.md`, Releases, (1) and (2)).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (this spec and plan among them),
  which is expected. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `0.2.1`, no drift (if `main` is at another version, the release is that version's patch number plus one, and the commands below change with it) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh 0.2.2` | exit 0; `package.json` and `.claude-plugin/plugin.json` from `0.2.1` to `0.2.2` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `0.2.2` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v0.2.2" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v0.2.2
git -C /home/noob_master/hyper-relay push origin main v0.2.2
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v0.2.2` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v0.2.2` | one line |

- [ ] **Step 22 (`after merge`): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2 && echo cached` | `cached` |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/skills/brainstorming/builder-check-prompt.md && echo yes` | `yes` |
| `test -e /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/skills/brainstorming/spec-document-reviewer-prompt.md; echo $?` | `1` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again, and the record says so. If a check still fails, stop and tell the owner; delete or uninstall
nothing.

- [ ] **Step 23 (`after merge`): The role agents, regenerated here and in SAT (spec §8; P14).** With the installed
  0.2.2 generator, so the agents' version marker matches the installed plugin:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/bin/hyper-relay-agents --check` | nothing, exit 0 |

Then SAT, unless a SAT benchmark run (the G.2 runbook's C.1 or C.2) is between its start and its merge: then ask the
owner first (P14).

| Run | PASS |
|---|---|
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/0.2.2/bin/hyper-relay-agents --check` | nothing, exit 0 |

A `refused` line (a hand-edited agent) stops the step: tell the owner. The new agents load in a new session. SAT's
`.hyper-relay/agents.md` is left alone.

- [ ] **Step 24 (`owner`, after Step 22): The live probe (spec §8, BR10; P13).** The next real brainstorm, card
  `6ad2f229` (upstream small fixes), in a fresh Claude Code session on 0.2.2. The owner judges, from that session:
  (1) it read the project and the card before asking; (2) its first message was about 200 words and echoed the
  request with what it found; (3) it asked why, or gave a short design; (4) a project-size design got a builder check
  (when the work reaches one). PASS: the owner's verdict, which goes into the record (Step 25). A miss is a new card
  (Needs brainstorming, through the Quartz MCP), not a blocker: this branch has merged by then.

- [ ] **Step 25 (`after merge`, once Step 24 is judged): Record.** Append to this plan, in the main checkout (on
  `main`):

```markdown
## Last-task record (Task 5)

- **Before the merge:** acceptance reviewer <verdict line>; fix rounds <n, what each changed>; code review: Critical
  <fixed / dropped, why>, proposed cards <kept / dropped>; skill tests GREEN <n>/11, RED failed in <which>,
  non-discriminating <which> (S6 by design); token counts: executor <n>, acceptance reviewer <n>, code reviewer <n>,
  skill tests <n> over 22 runs.
- **Owner steps:** Step 18 <agreed / what changed, P1 and P2 among it>; Step 19 <merge-tree exit>. Merged in <hash>.
- **After merge:** suites on `main` <counts>; released v0.2.2 in <hash>, tagged, pushed; the owner's update <0.2.2 in
  the cache>; agents regenerated here <files> and in SAT <files / asked first>.
- **Live probe** (card `6ad2f229`, <date>): read before asking <yes / no>; first message about 200 words, echoing the
  request with what it found <yes / no>; asked why or gave a short design <which>; builder check on a project-size
  design <yes / no / not reached>; the owner's verdict <…>; a miss became card <id / none>.
```

Commit it, with this task's trailer (the post-commit hook ticks Task 5 in this connected repo):

```bash
git -C /home/noob_master/hyper-relay add docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md
git -C /home/noob_master/hyper-relay commit -m "docs: brainstorming v7 last-task record" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md#5
<the committing session's attribution lines>" -- docs/superpowers/plans/2026-11-19-hyper-relay-brainstorming-v7.md
```

Push it with the next push of `main` (the owner's call).
