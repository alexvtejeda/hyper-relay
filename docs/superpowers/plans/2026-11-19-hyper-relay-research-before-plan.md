# hyper-relay: research in brainstorming, so the planner builds on settled facts, Implementation Plan

**Card:** Research before the plan: settle how the system works with the owner, not in the planner (`d16b46da-3640-47dd-a474-bd8ad907b272`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-research-before-plan-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–4 are
> the executor's. Task 5 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Brainstorming finds out how the outside systems a design depends on work, explains it to the owner and
writes the settled facts into the spec's `## How it works`; the planner builds on them, re-checks only what the spec
flags, and turns a gap into a stated assumption, which the owner can answer at stop 3 with "research it".

**Architecture:** Skill and template text only. Task 1 changes brainstorming (a research paragraph before the
approaches, the spec's `## How it works` and its flags, the builder check's fourth pile, a Red Flags row), creates
`research-prompt.md` and adds one ask to the builder check's prompt. Task 2 adds `writing-plans`' "Facts about outside
systems" section and rewrites the plan reviewer's External facts row. Task 3 points the planner template and this
repo's facts at that section. Task 4 gives stop 3 its assumptions and the "research it" answer, and runs the full
gates. Task 5 accepts it: the checks, eight RED/GREEN skill tests, the release and the role agents.

**Tech Stack:** Markdown skills and agent templates; the relay guard (`tests/orchestrating/run-tests.sh`, POSIX shell
run by dash) and the generator's suites as the contract. For acceptance: Claude Code general-purpose subagents on
Sonnet.

**How this was checked:** written against `main` at `0e210fb`, by reading only; nothing was built, run, installed or
generated. The spec flags no fact for re-check, so none was re-checked, and the plan assumes no outside fact.

---

## Execution notes (binding)

- **The skills you follow are not the ones you write.** Your preloaded `executing-plans` and this run's orchestrator
  are the installed plugin's. This plan rewrites parts of `brainstorming`, `writing-plans` and `orchestrating`'s
  `planning.md`: follow your agent instructions and this plan, not the new text.
- **Plan-fixtures lands first** (spec §11). Its plan changes `skills/writing-plans/SKILL.md` ("What a Step Contains",
  "Self-Review") and `skills/writing-plans/plan-document-reviewer-prompt.md` (its "Step contents" row) before this
  branch is cut, or beside it. This plan's edits in those two files are anchored on text plan-fixtures leaves alone
  (the `## Stacked plans` heading, the "External facts" row): find them by their text, never by a line number.
- **Skill text is written exactly.** "Create X with exactly this content" means the Write tool, with every line of the
  block, ending with one newline; "Replace X with Y" means the Edit tool, X as `old_string`, Y as `new_string`. Fence
  lines (three or four backticks) are not part of the text. Keep each line break as written: several checks grep for
  a phrase that must sit on one line. If an X is not found, read the range again; if it moved or differs slightly,
  adapt as little as possible and record a deviation; if it is gone, stop and report.
- **Do not run `bin/hyper-relay-agents` in this checkout.** It rewrites the gitignored `.claude/agents/` that this
  run's agents load. The suite runs it in temporary repos; the real regeneration is Task 5's, after the release.
- **The guard is the contract.** `tests/orchestrating/run-tests.sh` and both `tests/hyper-relay-agents/` suites
  change in nothing; needing to change one is a stop.
- Do not run `claude -p` or upstream's live suites (`tests/claude-code/`, `tests/explicit-skill-requests/`,
  `tests/skill-triggering/`).
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at `main`'s version; Task 5
  releases after the merge.
- **Tables of checks.** In a command inside a table cell, `\|` is a plain `|`: run `... | tail -n 1`, and
  `grep -E 'a|b'` (alternation).
- The spec's project-wide values, verbatim:
  - "After the change, "re-verify" appears nowhere in the relay's skills (`brainstorming`, `writing-plans`,
    `orchestrating`), `templates/` or `.hyper-relay/`: the word is "re-check", and it applies only to facts a spec
    flags. `writing-skills` keeps its own "re-verify", which belongs to its TDD cycle for skills and has nothing to do
    with outside facts."
  - "Every other skill, template and script stays as it is."
  - The spec's section is titled `## How it works`; the research agent runs on Sonnet.
  - A skill reaches its own files as `${CLAUDE_SKILL_DIR}/...` and also names them relative to its `SKILL.md`
    (`CLAUDE.md`, Rules).
- **The full gates** (Task 4): `sh tests/orchestrating/run-tests.sh`, `sh tests/hyper-relay-agents/run-tests.sh`,
  `sh tests/hyper-relay-agents/guard-test.sh` and `claude plugin validate .`. The first, second and last are
  `relay-merge`'s gates for this branch (`.hyper-relay/merge.conf`).
- **Task 5 is not yours.** After Task 4, report, copy Task 5's checklist into your report, and stop.

## Review Focus

1. **OpenCode reads the skills.** OpenCode does not expand `${CLAUDE_SKILL_DIR}`: brainstorming must also name
   `research-prompt.md` relative to its `SKILL.md`, and `planning.md`'s `../brainstorming/research-prompt.md` must
   resolve from `skills/orchestrating/`. Task 1 Step 7 and Task 4 Step 5 assert both.
2. **A spec written before this rule** (no `## How it works`; its facts under "External facts", perhaps with a list
   to re-verify): the planner reads those facts as settled and re-checks only what the spec asks (P5), and "research
   it" adds the missing section (P9). Task 2 Step 3 and Task 4 Step 5 assert both sentences.
3. **"Research it" during a branch run:** the orchestrator neither edits nor commits the spec (the edit waits for the
   merge), and the planner gets the facts in its prompt. Task 4 Step 5 asserts the sentence.
4. **A finding that raises a decision:** the orchestrator asks it and that message ends, before any spec edit or
   planner dispatch. Task 4 Step 5 asserts the sentence.
5. **A short design approved in brainstorming's first message, with a flagged fact:** the message lists the flagged
   fact, so the approval covers it. Task 1 Step 7 asserts the sentence.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §2: find out "before laying out the approaches" | Also before the short design in brainstorming's first message, which lays out the approach too: "find out before you lay out the approaches, or before the short design in your first message". |
| P2 | §2: a small check brainstorming runs itself; a bigger one goes to a Sonnet agent | One sentence more, as the builder check has: "Without a subagent tool, do it yourself." **The owner may drop it at stop 3.** |
| P3 | §2: the builder check's sorting "gains a fourth case" | "Sort what the builder asks into three piles, and the outside facts it lists into a fourth:", then a fourth bullet, **Outside facts**: the three piles sort questions, and the facts come from the prompt's separate list (§4). |
| P4 | §4: the prompt "gains one ask, beside 'the questions you'd still need answered'"; "Its other instructions stay" | A paragraph of its own straight after the questions' paragraph, with its own empty answer ("no outside facts to look up"), so "nothing important left" keeps meaning the questions. Nothing else in the prompt changes. |
| P5 | §5 and §6 speak of the spec's `## How it works`; §12 leaves specs already written alone | A spec written before this rule (this repo's older ones, and SAT's not yet planned) keeps its facts under another heading, often "External facts", sometimes with a list to re-verify. `writing-plans` gets one sentence: "they are settled the same way, and those it asks you to re-check count as flagged"; the reviewer's row says "(in an older spec, its External facts)". **The owner may drop both at stop 3**; without them, such a spec's facts read as unsettled, and each becomes an assumption. |
| P6 | §8: the template's bullet "points to `writing-plans`' new section and states it in a line" | Today's bullet also says "quote only what decides something" (leaner plans, LP6). That clause moves into `writing-plans`' section, so every planner, the fallback one included, keeps it. |
| P7 | §5: "list it in the deviations table as an assumption" | `writing-plans` names no deviations table (the generated planner's template does). The section says "the plan's table of spec ambiguities and deviations, marked **Assumption**". |
| P8 | §6: "The row is not advisory, so a failure blocks" | The Calibration already blocks on any row not marked advisory. The row adds "This blocks: a wrong outside fact builds the wrong thing.", so S8's reviewer cannot read it as advisory. |
| P9 | §7 step 3: "Add each fact to the spec's `## How it works`" | "(adding the section when the spec has none)": a spec written before this rule has none. |
| P10 | §1: exactly these eight files | `skills/orchestrating/SKILL.md`'s stops table says stop 3 asks "the decisions the owner must make" and its answer starts "execution, a plan review, or plan changes". It stays: an assumption is among the decisions, and "research it" ends in plan changes. **The owner may add it at stop 3** (a ninth file, and Task 5 Step 3's list grows). |
| P11 | §1: "Every other skill … stays as it is" | `skills/agents/SKILL.md` describes the `planner/before-writing` slot as "which external facts specs usually cite". It still fits the new line, and stays. |
| P12 | §9: situations "given in full" | The skill-test preamble (`reviewing.md` §3) forbids commands, so each situation gives what its reads, fetches and subagents would show. Shared text is in three blocks (`<CONTEXT>`, `<USAGE DESIGN>`, `<HOW IT WORKS>`), pasted verbatim. The transcript facts in S1, S5, S7 and S8 are the ones plan-fixtures' spec settles (§2.3, §2.4); Chatter (S3, `docs.chatter.example`) is made up, and so is what the `gh` pages show (S2, S6). S5 and S6's planner is the fallback general-purpose planner told to follow `writing-plans`: the folders the runs read hold only `skills/`, not the generated planner's template, and that planner is why the rule goes in `writing-plans` (spec, How it works). |
| P13 | `.hyper-relay/agents.md`, Releases: the release steps come "last" | SAT's line (Step 16) comes before the release; the agents' regeneration (Step 19) after the owner's update (Step 18), because it uses the installed generator, so the agents' version marker matches the installed plugin. Neither changes a file this plugin loads. |
| P14 | §10: "the orchestrator regenerates the role agents here and in SAT" | SAT's checkout is `/home/noob_master/sat.pentraze.com` (its project is `sat`; the line is its `.hyper-relay/agents.md:13`). SAT's agents are regenerated after the owner's SAT line, and not while a SAT plan runs (its agents would change under it): then the orchestrator asks the owner first. |
| P15 | §10: "0.2.4, unless `main` holds another version" | Step 17 reads `main`'s version first and raises its patch number by one: 0.2.4 when plan-fixtures' 0.2.3 is on `main`. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–4; 5 (Steps 5–12) |
| Decisions (owner, 2026-11-19) | RB1: 1, 5 (S1). RB2: 1 (the explanation), 5 (S1). RB3: 1, 5 (S1–S4). RB4: 2, 3, 4, 5 (S5–S8). RB5: 5 (Step 4: no `effort:`). RB6: 5 (Steps 5–12) |
| How it works | 3 (the guard's limits it records stay as they are); 5 (Step 2: every place it lists for "re-verify") |
| 1. What changes where | 1–4; 5 (Step 3) |
| 2. `skills/brainstorming/SKILL.md` | 1; 5 (Steps 4, 5–7) |
| 3. `skills/brainstorming/research-prompt.md` (new) | 1; 5 (Steps 4, 5) |
| 4. `skills/brainstorming/builder-check-prompt.md` | 1; 5 (Step 8) |
| 5. `skills/writing-plans/SKILL.md` | 2; 5 (Steps 9, 10) |
| 6. `skills/writing-plans/plan-document-reviewer-prompt.md` | 2; 5 (Step 12) |
| 7. `skills/orchestrating/planning.md` | 4; 5 (Step 11) |
| 8. `templates/agents/planner.md` and `.hyper-relay/agents.md` | 3; 5 (Steps 16, 19) |
| 9. Pressure scenarios | 5 (Steps 5–12) |
| 10. Acceptance and release | 4 (the full gates); 5 |
| 11. Order with plan-fixtures | Execution notes; 2 (anchors); 5 (Steps 14, 17) |
| 12. Out of scope | No task; 5 (Step 3: only the planned files; Step 4: no `effort:`) |

## File structure

- **Modify (Task 1):** `skills/brainstorming/SKILL.md`, `skills/brainstorming/builder-check-prompt.md`. **Create:**
  `skills/brainstorming/research-prompt.md`.
- **Modify (Task 2):** `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`.
- **Modify (Task 3):** `templates/agents/planner.md`, `.hyper-relay/agents.md`.
- **Modify (Task 4):** `skills/orchestrating/planning.md`.
- **Unchanged:** every other skill (`orchestrating`'s `SKILL.md`, `agents`, `writing-skills` among them),
  `templates/hooks/`, `bin/`, `hooks/`, `.claude-plugin/`, `package.json`, every suite under `tests/`, `README.md`.

---

### Task 1: brainstorming finds out how outside systems work (spec §2, §3, §4; RB1–RB3; P1–P4)

**Files:**
- Modify: `skills/brainstorming/SKILL.md:182-184` (Do recon, two paragraphs after it), `:273-280` (the Cover list,
  a paragraph after it), `:328-336` (the builder check's piles), `:377` (a Red Flags row after it)
- Create: `skills/brainstorming/research-prompt.md`
- Modify: `skills/brainstorming/builder-check-prompt.md:14-17`

**Interfaces:**
- Produces: `skills/brainstorming/research-prompt.md`, which Task 4's `planning.md` names as
  `../brainstorming/research-prompt.md`.

- [x] **Step 1: The research paragraph, in The Conversation (§2; P1, P2).** In `skills/brainstorming/SKILL.md`,
  replace:

```text
**Do recon.** Once you have a bit of grounding and looking further
would help, go look: deeper into their codebase or project, their own
files and data, or the web. Say what you looked for and what you found.
```

with:

```text
**Do recon.** Once you have a bit of grounding and looking further
would help, go look: deeper into their codebase or project, their own
files and data, or the web. Say what you looked for and what you found.

**Find out how it works.** When the design depends on how something
outside the project's own code works (a file format the work reads,
how a command-line tool behaves, a third-party API, outside docs, data
on this machine), find out before you lay out the approaches, or before
the short design in your first message. Never leave it to the planner:
a planner can't run code and isn't in this conversation. Reading the
project's own code stays as Look Before You Ask and Do recon say. Run a
small check yourself: a command or two, or a single docs page. A bigger
investigation goes to a fresh subagent, on Sonnet, with
`${CLAUDE_SKILL_DIR}/research-prompt.md`
(`research-prompt.md` beside this SKILL.md), filled in with the
questions the design hinges on and where to look. Without a subagent
tool, do it yourself.

Then explain what you found to your human partner, so they understand
how the system works and not only your conclusion: how it works, what
you found, and the evidence for it. Each decision it raises comes as
its own question, one at a time. What you found goes in the design,
each fact with its source (see The Written Design).
```

- [x] **Step 2: The Written Design: the Cover line and the facts' paragraph (§2).** Replace:

```text
- constraints
- approaches (above)
```

with:

```text
- constraints
- how the outside systems it depends on work (see Find out how it
  works): each fact with its source (a URL, a command, a file) and the
  date you checked it
- approaches (above)
```

Then replace:

```text
- what's left to the builder

For a small change, the short design covers the same points in a line
```

with:

```text
- what's left to the builder

In the full design, those facts go in a section titled
`## How it works`; in a short design, a line or two each. They are
settled: the planner builds on them and does not look them up again.
The exception is a fact that may change before the plan runs (a docs
page in flux, a version, a beta API): flag it there for the planner to
re-check, with your reason. Most designs flag none. Never write down a
fact for the planner to find out: find it out now. When you hand the
design over (stop 2, or the short design in your first message), list
the flagged facts, if any, so your human partner sees them before
approving.

For a small change, the short design covers the same points in a line
```

- [x] **Step 3: The builder check's fourth pile (§2; P3).** Replace:

```text
until the check is back. Sort what the builder asks into three piles:
```

with:

```text
until the check is back. Sort what the builder asks into three piles,
and the outside facts it lists into a fourth:
```

Then replace:

```text
- **Theirs:** only your human partner can answer it, and the answer changes
  what gets built.
```

with:

```text
- **Theirs:** only your human partner can answer it, and the answer changes
  what gets built.
- **Outside facts** it would have to look up or guess: research to do
  (see Find out how it works). Put what you find in `## How it works`,
  and any decision it raises joins the "theirs" pile.
```

- [x] **Step 4: The Red Flags row (§2).** Replace:

```text
| "The spike works, I'll keep building on it" | Keeping it is a new request. Back through the gate. |
```

with:

```text
| "The spike works, I'll keep building on it" | Keeping it is a new request. Back through the gate. |
| "The planner can look that up" | A planner can't run code and isn't in this conversation. Find out now, and explain it to your human partner. |
```

- [x] **Step 5: The research agent's prompt (§3).** Create `skills/brainstorming/research-prompt.md` with exactly this
  content:

````markdown
# Research Prompt

Dispatch a fresh general-purpose subagent on Sonnet with this prompt when a
design depends on how something outside the project works and finding out
takes more than a command or two (in OpenCode, the `general` subagent).
Fill in the domain, the questions and where to look.

```
You are a careful researcher who knows [DOMAIN, e.g. "Claude Code's
session files", "the GitHub CLI", "a bakery's ordering system"]. A design
is being worked out, and it depends on how something outside the project
works. Find out, and explain it.

The questions the design hinges on:
[QUESTIONS, numbered]

Where to look:
[WHERE TO LOOK: paths, URLs, commands]

You only read. You may run commands that read, such as `jq` over files,
`<tool> --help`, `git log`, or fetching a docs page. Never write, edit,
install, or change a setting, and never run anything that sends,
publishes or spends usage: no `claude -p`, no live API calls.

For each question, give:
- the answer;
- the evidence: the command and the lines of its output that decide it,
  a file and line, or a URL and a short quote;
- the date you checked it.

Then give:
- a short explanation of how the parts fit, which someone new to the
  system could follow;
- what you could not settle, and why;
- anything you saw that may bear on the design and that you were not
  asked.

Quote only what decides something, and keep quotes short. Do not paste
whole files.
```
````

- [x] **Step 6: The builder check's prompt asks for outside facts (§4; P4).** In
  `skills/brainstorming/builder-check-prompt.md`, replace:

```text
Rank them by importance.

Skip anything the document explicitly leaves to the builder, and anything
```

with:

```text
Rank them by importance.

Also list, separately, each fact about an outside system (a file format,
a command-line tool, an API, docs) that you would have to look up or
guess to plan this, and that the document does not state with a source.
For each, say what you would need to know. If there are none, say "no
outside facts to look up".

Skip anything the document explicitly leaves to the builder, and anything
```

- [x] **Step 7: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F 'CLAUDE_SKILL_DIR' skills/brainstorming/SKILL.md` | `4` (three before) |
| `grep -c -E '(beside\|from) this SKILL\.md' skills/brainstorming/SKILL.md` | `4`: each of those files is also named relative to `SKILL.md` (Review Focus 1) |
| `grep -n -F 'research-prompt.md' skills/brainstorming/SKILL.md` | two consecutive lines, `` `${CLAUDE_SKILL_DIR}/research-prompt.md` `` then `` (`research-prompt.md` beside this SKILL.md), filled in with the `` |
| `grep -c -F '**Find out how it works.**' skills/brainstorming/SKILL.md` | `1` |
| `grep -c -F '## How it works' skills/brainstorming/SKILL.md` | `2` |
| `grep -c -F 'stop 2, or the short design in your first message' skills/brainstorming/SKILL.md` | `1` (Review Focus 5) |
| `grep -c -F -e 'into a fourth:' -e '**Outside facts**' -e '"The planner can look that up"' skills/brainstorming/SKILL.md` | `3` |
| `git diff -- skills/brainstorming/SKILL.md \| grep -c '^-[^-]'` | `1` (the "three piles:" line; everything else is added) |
| `git diff --stat -- skills/brainstorming/builder-check-prompt.md` | `1 file changed, 6 insertions(+)` |
| `grep -c '^```$' skills/brainstorming/research-prompt.md` | `2` |
| `grep -c -i 're-verif' skills/brainstorming/SKILL.md skills/brainstorming/research-prompt.md skills/brainstorming/builder-check-prompt.md` | `0` for each |
| `grep -r -n -F -e '/home/' -e '~/' -e '/Users/' -e '/tmp/' skills/brainstorming` | nothing |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [x] **Step 8: Commit.**

```bash
git add skills/brainstorming/SKILL.md skills/brainstorming/research-prompt.md skills/brainstorming/builder-check-prompt.md
git commit -m "feat: brainstorming finds out how outside systems work before the approaches" -m "When a design depends on something outside the project's own code (a file format, a CLI, an API, docs, data on the machine), brainstorming finds out before the approaches: a small check itself, a bigger one through a Sonnet agent with the new research-prompt.md. It explains what it found to the human partner, and the spec records each fact with its source and date under ## How it works; only a fact that may change before the plan runs is flagged for the planner to re-check, and the hand-over lists it. The builder check also lists the outside facts it would have to look up, which become research; a Red Flags row answers 'the planner can look that up'." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-research-before-plan.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 2: writing-plans builds on the spec's facts; the plan reviewer checks for unsourced ones (spec §5, §6; RB4; P5–P8)

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (a new section before `## Stacked plans`; no line numbers: plan-fixtures
  changes this file first)
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md` (its "External facts" row)

**Interfaces:**
- Produces: the section heading `## Facts about outside systems`, which Task 3's template names as
  `hyper-relay:writing-plans`' "Facts about outside systems".

- [x] **Step 1: The new section (§5; P5–P7).** In `skills/writing-plans/SKILL.md`, replace:

```text
## Stacked plans
```

with:

```text
## Facts about outside systems

The spec's `## How it works` section holds the facts about outside systems that its design rests on (a file format, a CLI, an API, docs, data on the machine), each with its source and the date it was checked. They are settled: build on them. Do not work them out again or re-check them, except the facts the section flags for re-check: check each of those with WebFetch or WebSearch, cite its URL and the date in the plan, quote only what decides something, and list a difference as a deviation, never a silent design change. A spec written before this rule may keep such facts under another heading, such as External facts: they are settled the same way, and those it asks you to re-check count as flagged.

Reading the repo's own code is your job, as always.

When the plan needs a fact about an outside system that the spec does not settle, read at most one file or one page to confirm a detail. Do not investigate: no series of searches, no digging through data, no working out a format from samples. Write the plan on a stated assumption, list it in the plan's table of spec ambiguities and deviations, marked **Assumption**, and put it in your report among what the owner must decide. The owner accepts it, corrects it, or has it researched and sends you back with the facts (`hyper-relay:orchestrating`'s `planning.md`).

Your report names the facts you re-checked (those the spec flagged) and any differences, and the assumptions you made where the spec was silent.

## Stacked plans
```

- [x] **Step 2: The reviewer's External facts row (§6; P5, P8).** In
  `skills/writing-plans/plan-document-reviewer-prompt.md`, replace this line (four leading spaces, as in the file):

```text
    | External facts | Each fact the spec asks to re-verify is cited with its URL and the date it was checked; a difference is listed as a deviation. |
```

with:

```text
    | External facts | Each fact the spec flags for re-check is cited with its URL and the date it was checked, and a difference is listed as a deviation. A fact about an outside system (a file format, a CLI, an API, docs) that the plan states as settled, and that neither the spec's `## How it works` (in an older spec, its External facts) nor a cited re-check gives, is flagged: it should be an assumption in the plan's deviations table and a question for the owner. This blocks: a wrong outside fact builds the wrong thing. |
```

- [x] **Step 3: Check it.**

| Run | Expected |
|---|---|
| `grep '^## ' skills/writing-plans/SKILL.md` | `## Facts about outside systems` straight after `## The spec's plan count` and before `## Stacked plans` |
| `grep -c -F -e '## How it works' -e '**Assumption**' -e 'count as flagged' skills/writing-plans/SKILL.md` | `2`: the first paragraph (the section's name and P5's sentence) and the third (Review Focus 2) |
| `grep -c -F '\| External facts \|' skills/writing-plans/plan-document-reviewer-prompt.md` | `1` |
| `grep -c -F 'This blocks: a wrong outside fact builds the wrong thing.' skills/writing-plans/plan-document-reviewer-prompt.md` | `1` |
| `grep -c -i 're-verif' skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md` | `0` for each |
| `git diff -- skills/writing-plans \| grep -c '^-[^-]'` | `1` (the old row) |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [x] **Step 4: Commit.**

```bash
git add skills/writing-plans/SKILL.md skills/writing-plans/plan-document-reviewer-prompt.md
git commit -m "feat: writing-plans builds on the spec's facts, and a gap is an assumption" -m "A new section, Facts about outside systems: the spec's ## How it works is settled; the planner re-checks only the facts it flags (URL, date, quoting only what decides something); where the spec is silent it reads at most one file or page, writes the plan on a stated assumption marked in its deviations table, and reports it for the owner. An older spec's External facts read the same way. The plan reviewer's External facts row now blocks on an outside fact the plan states as settled that neither the spec nor a cited re-check gives." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-research-before-plan.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: the planner template and this repo's facts (spec §8; RB4, RB5; P6)

**Files:**
- Modify: `templates/agents/planner.md:52-53` (the External facts bullet), `:77-78` (the report)
- Modify: `.hyper-relay/agents.md:14`

**Interfaces:**
- Consumes: Task 2's section heading, `## Facts about outside systems`.

- [ ] **Step 1: The template's bullet.** In `templates/agents/planner.md`, replace:

```text
- **External facts** the spec says to re-verify: check them with WebFetch/WebSearch, cite URL + date in the plan,
  quote only what decides something, and list any difference as a deviation, never a silent design change.
```

with:

```text
- **Facts about outside systems:** as `hyper-relay:writing-plans`' "Facts about outside systems" says. The spec's
  `## How it works` is settled; re-check only the facts it flags; a gap is a stated assumption, not an investigation.
```

- [ ] **Step 2: The template's report.** Replace:

```text
Commit hash (or why not committed); task count per plan; every spec ambiguity/deviation and your resolution;
external facts re-verified and any differences; what the owner must decide before execution.
```

with:

```text
Commit hash (or why not committed); task count per plan; every spec ambiguity/deviation and your resolution;
facts re-checked (those the spec flagged) and any differences; assumptions made where the spec was silent; what the
owner must decide before execution.
```

- [ ] **Step 3: This repo's facts.** In `.hyper-relay/agents.md`, replace:

```text
- External facts to re-verify are usually Claude Code's, OpenCode's or GitHub's.
```

with:

```text
- The outside systems this repo's specs depend on are usually Claude Code, OpenCode and GitHub.
```

- [ ] **Step 4: Check it.**

| Run | Expected |
|---|---|
| `grep -c -i 're-verif' templates/agents/planner.md .hyper-relay/agents.md` | `0` for each |
| `grep -c -F -e '"Facts about outside systems" says' -e 'assumptions made where the spec was silent' templates/agents/planner.md` | `2` |
| `grep -c -F "The outside systems this repo's specs depend on" .hyper-relay/agents.md` | `1` |
| `git diff -- templates/agents/planner.md \| grep -c -F 'effort:'` | `0` (RB5: the planner's effort stays inherited) |
| `git diff --stat -- templates .hyper-relay` | two files: `templates/agents/planner.md` and `.hyper-relay/agents.md` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [ ] **Step 5: Commit.**

```bash
git add templates/agents/planner.md .hyper-relay/agents.md
git commit -m "feat: the planner template points at writing-plans' facts rule" -m "The generated planner's External facts bullet becomes Facts about outside systems, pointing at writing-plans' new section: the spec's ## How it works is settled, only flagged facts are re-checked, and a gap is a stated assumption. Its report names the facts re-checked and the assumptions made. This repo's planner/before-writing line names the outside systems its specs depend on." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-research-before-plan.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 4: stop 3 asks about assumptions and takes "research it"; the full gates (spec §7; RB4; P9, P10)

**Files:**
- Modify: `skills/orchestrating/planning.md:70` (the questions), `:80` (the report), `:82` (the answers), `:91-92`
  (a fourth answer after it)

**Interfaces:**
- Consumes: Task 1's `skills/brainstorming/research-prompt.md`.

- [ ] **Step 1: The questions (§7).** In `skills/orchestrating/planning.md`, replace:

```text
- each decision the owner must make;
```

with:

```text
- each decision the owner must make;
- each assumption the planner made where the spec was silent, which the owner can accept, correct, or answer with
  "research it" (below);
```

- [ ] **Step 2: The report line (§7).** Replace:

```text
- the external facts it re-verified, and any differences.
```

with:

```text
- the facts it re-checked (those the spec flagged), and any differences.
```

- [ ] **Step 3: Four answers (§7).** Replace:

```text
The answer leads one of three ways:
```

with:

```text
The answer leads one of four ways:
```

- [ ] **Step 4: The "research it" answer (§7; P9).** Replace:

```text
- **Changes:** the planner revises the plan (resumed, or fresh with the owner's list) and commits it again. Then §2
  and stop 3.
```

with:

```text
- **Changes:** the planner revises the plan (resumed, or fresh with the owner's list) and commits it again. Then §2
  and stop 3.
- **Research it** (an assumption): find out as `hyper-relay:brainstorming` does before its approaches, then send the
  planner back with the facts.
  1. Run a small check yourself (a command or two, a single docs page). A bigger one goes to a fresh general-purpose
     agent on Sonnet (`SKILL.md`, Fallbacks) with `brainstorming`'s `research-prompt.md`
     (`../brainstorming/research-prompt.md` from this file), filled in with the questions and where to look.
  2. Explain what you found to the owner, as brainstorming does: how it works, what you found and the evidence for it.
     When it raises a decision, ask it, and that message ends there.
  3. Add each fact to the spec's `## How it works` (adding the section when the spec has none), with its source and
     the date you checked it, and commit just the spec while the main checkout is on `main` (`git add <spec>`, then
     `git commit -m "<message>" -- <spec>`). During a branch run, the spec edit waits for the merge
     (`dispatching.md` §6), and the planner gets the facts in its prompt instead.
  4. The planner revises the plan (resumed, or fresh with the facts) and commits it again. Then §2, and a short stop 3
     in the same order as after a plan review.
```

- [ ] **Step 5: Check it.**

| Run | Expected |
|---|---|
| `grep -c -F -e 'one of four ways' -e '**Research it**' -e '"research it" (below)' skills/orchestrating/planning.md` | `3` |
| `grep -c -F 'one of three ways' skills/orchestrating/planning.md` | `0` |
| `grep -n -F '../brainstorming/research-prompt.md' skills/orchestrating/planning.md` | one line |
| `test -f skills/orchestrating/../brainstorming/research-prompt.md && echo resolves` | `resolves` (Review Focus 1) |
| `grep -c -F -e 'adding the section when the spec has none' -e 'the spec edit waits for the merge' -e 'that message ends there' skills/orchestrating/planning.md` | `3` (Review Focus 2, 3, 4) |
| `grep -c -E 'dispatching\.md. §6' skills/orchestrating/planning.md` | `2`: each reference sits on one line, so the guard's section check sees both |
| `grep -c -i 're-verif' skills/orchestrating/planning.md` | `0` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |

- [ ] **Step 6: Commit.**

```bash
git add skills/orchestrating/planning.md
git commit -m "feat: stop 3 asks about the planner's assumptions and takes 'research it'" -m "Stop 3's questions list each assumption the planner made where the spec was silent, for the owner to accept, correct or answer with 'research it'; its report names the facts re-checked (those the spec flagged). On 'research it' the orchestrator finds out as brainstorming does (a small check itself, a bigger one through a Sonnet agent with brainstorming's research-prompt.md), explains it to the owner, adds each fact to the spec's ## How it works in a commit of just the spec (or, during a branch run, gives it to the planner in its prompt), and sends the planner back." -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-research-before-plan.md#4
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

- [ ] **Step 7: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | ends `0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout, which holds the gitignored `.mcp.json`) |
| `git grep -n -i 're-verif' -- skills/brainstorming skills/writing-plans skills/orchestrating templates .hyper-relay` | nothing |
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/agents.md`, `skills/brainstorming/SKILL.md`, `skills/brainstorming/builder-check-prompt.md`, `skills/brainstorming/research-prompt.md`, `skills/orchestrating/planning.md`, `skills/writing-plans/SKILL.md`, `skills/writing-plans/plan-document-reviewer-prompt.md`, `templates/agents/planner.md` |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Then report, copy Task 5's checklist (Steps 1–19, each with its marker and its PASS) into your report, and stop: Task 5
is not yours.

### Task 5: Acceptance (spec §9, §10; P12–P15). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, in the checkout and on the branch
  (`hyper-relay-research-before-plan`) its dispatch names, from the checkout's top (Steps 1–4).
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the standing leg
  (`reviewing.md` §3, the installed relay's): its `red/` and `green/` folders hold `main`'s and the branch's `skills/`.
  Steps 5–12 are S1–S8: each is dispatched twice, on Sonnet, in the background, with the leg's standing preamble and
  then the step's situation, verbatim, with each placeholder line (`<CONTEXT>`, `<USAGE DESIGN>`, `<HOW IT WORKS>`)
  replaced by its block below, verbatim. S2 is a guard: GREEN and RED are both expected to pass it.
- **`owner`**: the owner, at the click-through (Steps 13–14).
- **`after merge`**: the orchestrator with the owner, once the branch is merged into `main` and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 15–19). The orchestrator runs the commands; the owner runs the
  plugin update, the reload and SAT's edit.

In a command inside a table cell, `\|` is a plain `|`, as in the Execution notes.

**This plan's run follows the installed relay**, not the text it writes: the new behaviour reaches a session only after
the release and the owner's update (Steps 17–18).

**`<CONTEXT>`** (P12):

```text
This test is set in the hyper-relay repo: a Claude Code and OpenCode plugin made of Markdown skills and POSIX shell
tools (run by dash), with their tests. Its main checkout is /home/noob_master/hyper-relay, your working directory. A
skill named `hyper-relay:<name>` is the folder `<name>` in your skills folder: follow the skill or prompt your role
names, and read any other skill or file in that folder it sends you to. Your tools include Read, Grep, Glob, Bash,
WebFetch, WebSearch, Write, Edit, the Skill tool (to invoke a skill: say which), the Agent tool (it dispatches a
subagent and takes a `model`: `sonnet` or `opus`) and SendMessage (it resumes an agent you dispatched, by its ID). In
this test you cannot read the repo's files, run commands, fetch pages or dispatch agents: list each read, command,
fetch and dispatch among your commands, in order, and take what it would show from the facts the situation gives.
Today is 2026-11-20.
```

**`<USAGE DESIGN>`**:

```text
# hyper-relay: a token report per subagent (design)

## Goal

The owner wants to see which leg of the relay (planner, executor, reviewers) costs most, one plan at a time, without
a benchmark run.

## Decisions

- A new script, `scripts/benchmark/agent-usage.sh <session id>`: POSIX shell run by dash, with jq 1.6 or later.
- It reads the session's Claude Code transcripts and prints a Markdown table: one row per subagent, with the agent's
  type, its model calls, output tokens, cache reads, cache writes, uncached input and cost.
- Cost uses `scripts/benchmark/prices.tsv`, as `run-usage.sh` prices a call.
- It writes nothing. With no transcript for the session, it exits 1 with one `agent-usage:` line on stderr.

## Approaches

(a) A new script, picked: it needs no run log. (b) A mode of `run-usage.sh`: its jq is built around a run log's
sessions and phases. (c) Claude Code's `/cost`: one number for the whole session.

## Left to the builder

The jq's layout, and the test fixtures.
```

**`<HOW IT WORKS>`**:

```text
## How it works

- A session's transcript is `<config>/projects/<project folder>/<session id>.jsonl`, and each of its subagents' is
  `<config>/projects/<project folder>/<session id>/subagents/agent-<id>.jsonl`. `<config>` is `$CLAUDE_CONFIG_DIR`,
  or `~/.claude` when that is unset. Source: `ls` in this machine's config folder, checked 2026-11-20.
- One JSON record per line. A model call's record has `"type": "assistant"`, `message.id`, `message.model` and
  `message.usage`, with `input_tokens`, `output_tokens`, `cache_creation_input_tokens` and
  `cache_read_input_tokens`. Claude Code writes one record per content block, each repeating its call's `usage`, so
  each `message.id` is counted once. Source: `jq` over one transcript's assistant records, checked 2026-11-20.

No fact here is flagged for re-check.
```

- [ ] **Step 1 (`reviewer`): The suites and the manifest (spec §10 step 1).**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only when run in the main checkout, `PRIVACY_URL_MISSING`; no other warning |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | ends `0 failed` |
| `git diff --stat main...HEAD -- package.json .claude-plugin` | nothing (the release is after the merge) |

- [ ] **Step 2 (`reviewer`): "re-verify" is gone from the relay (spec §10 step 2, §1).**

| Run | PASS |
|---|---|
| `git grep -n -i 're-verif' -- skills/brainstorming skills/writing-plans skills/orchestrating templates .hyper-relay` | nothing |
| `git grep -c -i 're-verif' -- skills/writing-skills` | `skills/writing-skills/SKILL.md:1` and `skills/writing-skills/testing-skills-with-subagents.md:3`, as on `main` (its own TDD cycle, untouched) |

- [ ] **Step 3 (`reviewer`): Only the planned files (spec §10 step 3, §1, §12).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly the eight files of Task 4 Step 7 |
| `git diff main...HEAD -- skills templates .hyper-relay \| grep -c -E '^\+.*(/home/\|~/\|/tmp/\|/Users/)'` | `0` |

- [ ] **Step 4 (`reviewer`): The text against the plan (spec §2–§8; P1–P9).** Run `git diff main...HEAD` and read
  every hunk. PASS: each hunk is one of Tasks 1–4's "Replace X with Y" edits, with Y word for word (Task 2's in
  `skills/writing-plans/`, whatever plan-fixtures changed beside them), and `research-prompt.md` is Task 1 Step 5's
  content; nothing else differs. Also:

| Run | PASS |
|---|---|
| `grep -n -F 'CLAUDE_SKILL_DIR' skills/brainstorming/SKILL.md` | four lines, each followed on its next line by the same file named relative to `SKILL.md` (`from this SKILL.md` or `beside this SKILL.md`) |
| `test -f skills/orchestrating/../brainstorming/research-prompt.md && echo resolves` | `resolves` |
| `git diff main...HEAD -- templates/agents/planner.md \| grep -c -E '^[-+](model\|effort):'` | `0` (RB5: no `effort:`, the model unchanged) |

  A sentence that contradicts the spec beyond the P-notes is a FAIL, with its line.

- [ ] **Step 5 (`skill-test`): S1, research before the approaches (§9 S1; §2, §3; RB1, RB2).**

Situation:

```text
<CONTEXT>

You are the agent your human partner talks to, in Claude Code, and you follow `hyper-relay:brainstorming`. The main
checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Earlier in this conversation, your human partner typed: "/hyper-relay:brainstorming I want a script that reads my
Claude Code session transcripts and tells me how many tokens each subagent in a session used, and what it cost." You
read `scripts/benchmark/`: `run-usage.sh` totals a whole benchmark run from a run log, and `prices.tsv` holds each
model's price per million tokens. You echoed the request back, and they told you why: "I want to see which leg of the
relay costs most, planner, executor or reviewers, one plan at a time, without a benchmark run." You played that back
and they confirmed it. Nobody in this conversation has looked at a transcript, and no file in the repo describes one.
Your next step would be to lay out the approaches.

Part 1. Give the commands and tool calls you make, in order, and your next message, verbatim. If you look at
transcripts yourself, or dispatch a subagent to, take what comes back to be this report, verbatim:

  1. Where they are: one file per session, `~/.claude/projects/<project folder>/<session id>.jsonl`. A subagent's is
     `<session id>/subagents/agent-<id>.jsonl` in the same folder, with `agent-<id>.meta.json` beside it, whose
     `agentType` names the agent (`relay-planner`). Evidence: `ls` of the project folder and of one session's
     `subagents/`. Checked 2026-11-20.
  2. What a model call looks like: one JSON record per line; a call's record has `"type": "assistant"`, `message.id`,
     `message.model` and `message.usage`, with `input_tokens`, `output_tokens`, `cache_creation_input_tokens` and
     `cache_read_input_tokens`. Evidence: `jq -c 'select(.type=="assistant") | .message.usage' <file> | head -n 3`.
     Checked 2026-11-20.
  3. Counting: Claude Code writes one record per content block, each repeating its call's `usage`, so each
     `message.id` must be counted once, or the totals come out two to four times too high. Evidence:
     `jq -r 'select(.type=="assistant") | .message.id' <file> | sort | uniq -c | sort -rn | head -n 3` shows ids with
     counts of 2 to 4. Checked 2026-11-20.
  How the parts fit: the session's own file holds only the main conversation's calls. Each subagent's calls are in its
  own file, so a per-subagent total reads the `subagents/` folder, names each file's agent from its meta file, and
  sums its calls once per `message.id`.
  Not settled: nothing the questions asked.
  Not asked, but it may bear on the design: `run-usage.jq` already counts once per `message.id`.

Part 2. Later in the conversation: your human partner said the explanation was clear. You laid out the approaches, and
they picked a new script, `scripts/benchmark/agent-usage.sh`. You played back each part, they confirmed each, and you
said it is a project. You are writing the spec now. Give its section headings, in order, and every part of it that
says how the transcripts work, verbatim.
```

GREEN must: in Part 1, before any approach, dispatch a fresh subagent with `model: sonnet` and `research-prompt.md`'s
prompt, its domain, its questions (where the transcripts are, what a call's usage looks like, how a subagent's calls
are told apart) and where to look filled in; then send a message that explains to the human partner, in plain words,
how the transcripts work (the three findings, with their evidence) and lays out no approaches (they come in a message
of their own), with at most one question, raised by a finding. In Part 2: a `## How it works` section holding the
three facts, each with its source (the command or the path) and 2026-11-20, none flagged for re-check, and nothing
left for the planner to find out.

RED is expected to: lay out the approaches next, with no research agent (a look of its own at most); in Part 2, a spec
that names a transcript reader without saying, with sources and dates, how a transcript is laid out.

- [ ] **Step 6 (`skill-test`): S2, a one-command check needs no agent (§9 S2; §2). Expected to pass on both.**

Situation:

```text
<CONTEXT>

You are the agent your human partner talks to, in Claude Code, and you follow `hyper-relay:brainstorming`. The main
checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`.

Earlier in this conversation, your human partner typed "/hyper-relay:brainstorming relay-merge should open a pull
request instead of merging, when I ask it to." You read `bin/relay-merge` and `docs/relay-merge.md`, and they told you
why: "On shared repos I want a reviewer to see the branch on GitHub before it lands." One thing decides between the two
ways you have in mind: whether `gh pr create` can open the pull request as a draft from the command line. If it can,
`relay-merge` opens a draft and your human partner marks it ready; if not, it opens a normal one with a "do not merge"
label. `gh` is installed. Nothing else is open.

If you run `gh pr create --help`, take its output to include this line:
  -d, --draft    Mark pull request as a draft
If you dispatch a subagent to find out, take its report to be: "`gh pr create --draft` opens a draft pull request
(`gh pr create --help`, 2026-11-20)."

Give the commands and tool calls you make, in order, and your next message, verbatim.
```

GREEN must: run `gh pr create --help` itself, with no subagent dispatched, and say in its next message what it found
(the `--draft` line), then move the work on (the approaches, or its next question).

RED is expected to: do the same (the guard against sending a one-command check to an agent).

- [ ] **Step 7 (`skill-test`): S3, a fact that may change is flagged (§9 S3; §2).**

Situation:

```text
<CONTEXT>

You are the agent your human partner talks to, in Claude Code, and you follow `hyper-relay:brainstorming`. The main
checkout is on `main` and clean (`git branch --show-current` there prints `main`). `git config --get
hyper-relay.quartz` prints `off`.

Earlier in this conversation (it began with "/hyper-relay:brainstorming"), you and your human partner worked out this
design, and they confirmed each part:
- Why: they want the team's chat to show each branch `relay-merge` lands, so nobody asks "is it in yet?".
- What: after each branch lands, `relay-merge` posts one line to the team's Chatter channel (Chatter is the chat
  service the team uses): the branch, the merge commit, and the gates that ran. All the branches of one run go in one
  thread. The webhook's URL is in `RELAY_MERGE_CHATTER_URL`; with it unset, nothing is posted.
- Approaches you laid out: (a) `relay-merge` posts with `curl`; (b) a git `post-merge` hook; (c) a separate script
  your human partner runs after. They picked (a): `relay-merge` already knows each branch's gates.
- Not wanted: a message for a refused branch; anything posted when the URL is unset.
- It is a project, and you said so.

You found these facts earlier in the conversation and explained them; take them as true:
1. Chatter's incoming webhook takes a POST of JSON `{"text": "<message>"}` and answers 200 with no body.
   (https://docs.chatter.example/webhooks, read 2026-11-20.)
2. A message's `text` is at most 4,000 characters; a longer one is refused with 400. (The same page, "Limits",
   2026-11-20.)
3. A `thread_key` field puts messages with the same key in one thread. (https://docs.chatter.example/webhooks/threads,
   read 2026-11-20. That page is headed "Beta: this field may change or be removed before general availability.")
4. This machine's `curl` (7.81) takes `--json <data>`, which posts the data with a JSON content type.
   (`curl --help all`, 2026-11-20.)

You have told your human partner you are writing it up and that a reviewer reads it first. The builder check you
dispatched reported: "nothing important left; no outside facts to look up".

Give the commands and tool calls you make, in order, the part of the spec that holds the four facts above, verbatim,
and your next message, verbatim.
```

GREEN must: write `docs/superpowers/specs/2026-11-20-<topic>-design.md` with a `## How it works` section holding the
four facts, each with its source and date; flag fact 3 (`thread_key`) for the planner to re-check, with its reason (a
beta page that may change before the plan runs), and leave facts 1, 2 and 4 unflagged; commit just that file on
`main`; and hand it over in a message that lists the flagged fact, so the human partner sees it before approving.

RED is expected to: flag nothing (the facts in the spec, or some of them, with no flag), or send every fact to the
planner to re-verify.

- [ ] **Step 8 (`skill-test`): S4, the builder check names an unsourced outside fact (§9 S4; §4).**

Situation:

```text
<CONTEXT>

You are the builder check: a fresh subagent that `hyper-relay:brainstorming` dispatched with the prompt in
`brainstorming/builder-check-prompt.md` (the block in its code fence), with [DOMAIN] "software engineer" and
[DOCUMENT_PATH] `docs/superpowers/specs/2026-11-20-hyper-relay-agent-usage-design.md`. Read that prompt from your
skills folder and follow it. The document is written and not yet approved. It reads, in full:

<USAGE DESIGN>

Give your report, verbatim.
```

GREEN must: list, among the outside facts it would have to look up or guess (the prompt's separate list), how Claude
Code's transcripts are laid out: where a session's and its subagents' transcripts are, how a model call's usage is
recorded, or where a subagent's type is recorded (naming at least one of these), as facts the document does not state
with a source.

RED is expected to: pass over the transcript format, or raise it only as an ordinary question (recorded either way).

- [ ] **Step 9 (`skill-test`): S5, the planner builds on settled facts (§9 S5; §5).**

Situation:

```text
<CONTEXT>

You are a planner: a general-purpose agent whose first instruction was "Invoke the `hyper-relay:writing-plans` skill
and follow it. You may only read code and write your plan file." The orchestrator dispatched you to write
`docs/superpowers/plans/2026-11-20-hyper-relay-agent-usage.md`, on the branch `hyper-relay-agent-usage`, from the spec
`docs/superpowers/specs/2026-11-20-hyper-relay-agent-usage-design.md`, committed on `main` and approved by the owner.

The spec reads, in full: the document below, with the section after it placed after its Decisions, and with this
third bullet at the end of that section's list: "- Beside each `agent-<id>.jsonl` is `agent-<id>.meta.json`, whose
`agentType` names the agent (`relay-planner`, say). Source: `cat` of one, checked 2026-11-20."

<USAGE DESIGN>

<HOW IT WORKS>

The repo holds `scripts/benchmark/run-usage.sh` and `scripts/benchmark/run-usage.jq` (which already count each
`message.id` once), `scripts/benchmark/prices.tsv`, and `tests/benchmark/run-tests.sh`, which tests them on fixture
transcripts it writes.

Give the commands and tool calls you make before you write the plan, in order; then one sample record the plan gives
for its transcript fixture, verbatim; then your report's lines on outside facts and assumptions.
```

GREEN must: read the repo's own code (`run-usage.sh`, `run-usage.jq`, `tests/benchmark/run-tests.sh`, `prices.tsv`)
and no transcript (nothing under `~/.claude/projects` or `$CLAUDE_CONFIG_DIR`), and fetch no page about the transcript
format; give a sample record built from the spec's `## How it works`; report that the spec flags no fact, so none was
re-checked, and that it made no assumption about the format.

RED is expected to: work the format out again before writing (`ls`, `head` or `jq` on real transcripts, or docs
fetched to confirm it).

- [ ] **Step 10 (`skill-test`): S6, a gap becomes an assumption, not an investigation (§9 S6; §5).**

Situation:

```text
<CONTEXT>

You are a planner: a general-purpose agent whose first instruction was "Invoke the `hyper-relay:writing-plans` skill
and follow it. You may only read code and write your plan file." The orchestrator dispatched you to write
`docs/superpowers/plans/2026-11-20-hyper-relay-pr-status.md`, on the branch `hyper-relay-pr-status`, from the spec
`docs/superpowers/specs/2026-11-20-hyper-relay-pr-status-design.md`, committed on `main` and approved by the owner.

The spec decides: a new `scripts/pr-status.sh`, POSIX shell run by dash with jq, prints one line per open pull request
of the current repo: its number, its title, and `pass`, `fail` or `pending` for its checks, from `gh pr list --json`.
Its tests use a fake `gh` that prints canned JSON. The spec has no `## How it works` section, and nothing in it says
what `gh pr list --json` prints or which field holds the checks. The repo has no other script that calls `gh`;
`tests/wt/run-tests.sh` shows how this repo's suites put a fake tool on PATH.

If you fetch https://cli.github.com/manual/gh_pr_list, take it to show: `--json <fields>`, "Output JSON with the
specified fields", and a list of JSON fields that includes `number`, `title` and `statusCheckRollup`; the page does
not say what `statusCheckRollup` holds. If you run `gh`, search, or fetch anything else, take each to show nothing new.

Give the commands and tool calls you make before you write the plan, in order; then the plan's table of spec
ambiguities and deviations, verbatim; then your report's lines on outside facts, assumptions and what the owner must
decide.
```

GREEN must: make at most one lookup about `gh` (that page, or one file), run no `gh` command and make no further
search; write the fake `gh`'s JSON and the parser on a stated assumption about what `statusCheckRollup` holds, as a row
marked **Assumption** in the deviations table; and list that assumption in its report among what the owner must decide,
with no fact re-checked (the spec flags none).

RED is expected to: investigate at length (several searches or fetches, `gh pr list --json statusCheckRollup` run on a
repo, `gh`'s source read), or state the shape as fact, with no assumption marked.

- [ ] **Step 11 (`skill-test`): S7, the owner answers "research it" at stop 3 (§9 S7; §7).**

Situation:

```text
<CONTEXT>

You are the orchestrator: the agent your human partner talks to, following `hyper-relay:orchestrating`. The main
checkout is on `main` and clean. `git config --get hyper-relay.quartz` prints `off`. This repo has no generated
agents, so the planner was a general-purpose agent (`orchestrating`'s Fallbacks); its agent ID is `a7f3`, and it can
be resumed.

The planner wrote `docs/superpowers/plans/2026-11-20-hyper-relay-agent-usage.md` from
`docs/superpowers/specs/2026-11-20-hyper-relay-agent-usage-design.md` and committed it on `main`. The spec reads, in
full: the document below, with the section after it placed after its Decisions.

<USAGE DESIGN>

<HOW IT WORKS>

The planner's report listed one assumption, for the owner to decide: "A1: a subagent's type is the `agentType` field
of the first record in its `agent-<id>.jsonl`; the plan's reader takes it from there." You checked the hand-back and
sent stop 3. Its first question was: "1. The planner assumed A1: a subagent's type is the `agentType` field of the
first record in its transcript. Accept it, correct it, or say "research it"." Your human partner answers: "1: research
it."

If you look yourself, take these results: `ls` of one session's `subagents/` folder shows `agent-a91c.jsonl` and
`agent-a91c.meta.json`; `cat` of `agent-a91c.meta.json` prints `{"agentType":"relay-planner"}`; `head -n 1
agent-a91c.jsonl | jq 'has("agentType")'` prints `false`. If you dispatch a subagent instead, take its report to say
the same, with those commands as evidence, checked 2026-11-20.

Give the commands and tool calls you make, in order, and your next message, verbatim, up to where you wait for the
planner.
```

GREEN must: find out itself (those two or three reads) or through a fresh subagent on Sonnet with
`brainstorming/research-prompt.md`; explain to the human partner what it found (the type is in `agent-<id>.meta.json`
beside the transcript, not in its records), with the evidence, in plain words; with no decision raised, add the fact
to the spec's `## How it works` with its source and date and commit just the spec on `main` (`git add <spec>`, then
`git commit -m "<message>" -- <spec>`); then send the planner back (`SendMessage` to `a7f3`, or a fresh planner given
the fact) to revise the plan on the found fact and commit it again, and say a short stop 3 follows once the plan is
back. It does not ask the planner to investigate.

RED is expected to: send the planner back to investigate A1, or treat the answer as plan changes and leave the spec as
it is.

- [ ] **Step 12 (`skill-test`): S8, the plan reviewer blocks on an unsourced outside fact (§9 S8; §6).**

Situation:

```text
<CONTEXT>

You are the plan reviewer: a fresh agent the orchestrator dispatched, at the owner's request, with the prompt in
`writing-plans/plan-document-reviewer-prompt.md` (the block in its code fence), with [PLAN_FILE_PATH]
`docs/superpowers/plans/2026-11-20-hyper-relay-agent-usage.md` and [SPEC_FILE_PATH]
`docs/superpowers/specs/2026-11-20-hyper-relay-agent-usage-design.md`. Read that prompt from your skills folder and
follow it.

The spec reads, in full: the document below, with the section after it placed after its Decisions.

<USAGE DESIGN>

<HOW IT WORKS>

The plan reads, in full:

  # hyper-relay: a token report per subagent, Implementation Plan

  **Spec:** `docs/superpowers/specs/2026-11-20-hyper-relay-agent-usage-design.md`

  > **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans. Task 1 is the executor's; Task 2 is
  > the acceptance task.

  **Goal:** `scripts/benchmark/agent-usage.sh <session id>` prints one row per subagent of a session: its type,
  calls, tokens and cost.
  **Architecture:** One POSIX script and a jq file, tested on fixture transcripts.
  **Tech Stack:** POSIX shell run by dash; jq 1.6.
  **How this was checked:** written against `main` at `1a2b3c4`, by reading only.

  ---

  ## Execution notes
  - The full gates: `sh tests/benchmark/run-tests.sh` and `dash -n scripts/benchmark/agent-usage.sh`.

  ## Review Focus
  1. A session with no subagents: the header and no rows, exit 0. Task 1 Step 1 asserts it.

  ## Spec ambiguities and deviations
  None.

  ## Spec coverage
  | Spec section | Tasks |
  |---|---|
  | Goal | 1, 2 |
  | Decisions | 1 |
  | How it works | 1 |
  | Approaches | 1 |
  | Left to the builder | 1 |

  ### Task 1: `agent-usage.sh` and its tests
  **Files:** Create `scripts/benchmark/agent-usage.sh` and `scripts/benchmark/agent-usage.jq`; modify
  `tests/benchmark/run-tests.sh`.
  - Step 1: Write the failing tests, in `tests/benchmark/run-tests.sh`'s harness. A fixture
    `write_agent <session> <id> <type> <call>...` writes `<session>/subagents/agent-<id>.jsonl`: its first record
    is `{"type":"user","agentType":"<type>"}`, then one assistant record per call, as the spec's `## How it works`
    gives them. Tests: two agents of two types (their rows, with exact tokens and cost); one `message.id` in three
    records, counted once; a session with no subagents (the header only, exit 0); no transcript (exit 1,
    `agent-usage: no transcript for <session id>`).
  - Step 2: Run them: they fail (no script).
  - Step 3: `agent-usage.sh [--config <folder>] <session id>` finds
    `<config>/projects/*/<session id>/subagents/`; for each `agent-<id>.jsonl` it takes the agent's type from the
    `agentType` field of the file's first record, then sums its calls once per `message.id` with `agent-usage.jq`,
    priced from `prices.tsv`.
  - Step 4: Run the tests: `0 failed`.
  - Step 5: Commit, with this task's trailer (this plan's path and `#1`).

  ### Task 2: Acceptance
  - Step 1 (`reviewer`): `sh tests/benchmark/run-tests.sh` prints `0 failed`.
  - Step 2 (`after merge`): the owner runs it on today's session. PASS: one row per subagent, each with its type.

Give your review, verbatim.
```

GREEN must: report "Blocking issues found", with, under its External facts check (or naming it), the plan's claim that
a subagent's type is the `agentType` field of its transcript's first record: stated as settled, in neither the spec's
`## How it works` nor a cited re-check, so it should be an assumption in the deviations table and a question for the
owner.

RED is expected to: pass the External facts check (the spec asks nothing re-checked) and not block on the claim
(Ready, or the claim at most advisory). A RED that blocks on it under Buildability is recorded as not failing.

- [ ] **Step 13 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-research-before-plan`, with stop 4's skill-test results
  and the P-notes, P2, P5 and P10 above all. PASS: the owner agrees with them as written. A change goes to the
  executor as a finding.

- [ ] **Step 14 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-research-before-plan` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files (with plan-fixtures, `skills/writing-plans/` is where they would be): tell the
owner before merging. The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`.

- [ ] **Step 15 (`after merge`): Re-check on `main`.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/orchestrating/run-tests.sh \| tail -n 1` | `28 passed, 0 failed` |
| `sh /home/noob_master/hyper-relay/tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay grep -n -i 're-verif' -- skills/brainstorming skills/writing-plans skills/orchestrating templates .hyper-relay` | nothing |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |

- [ ] **Step 16 (`after merge`, the owner's call): SAT's facts line (spec §8; P14).** SAT's repo is not this branch's,
  so the owner decides, and commits it as SAT's own rules say. In `/home/noob_master/sat.pentraze.com/.hyper-relay/agents.md`
  (line 13), replace:

```text
- External facts to re-verify are usually Microsoft's, Cloudflare's, DNS or library APIs.
```

with:

```text
- The outside systems SAT's specs depend on are usually Microsoft's, Cloudflare's, DNS and library APIs.
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/sat.pentraze.com grep -n -i 're-verif' -- .hyper-relay/agents.md` | nothing (or the owner declined: Step 19 then regenerates SAT's agents with the old line, which the record says) |

- [ ] **Step 17 (`after merge`): The release (spec §10; `.hyper-relay/agents.md`, Releases, (1) and (2); P15).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (this spec and plan among them),
  which is expected. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with `<x.y.z>` the
  version `--check` shows with its patch number raised by one (`0.2.4` from `0.2.3`):

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.3` once plan-fixtures has released) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh <x.y.z>` | exit 0; `package.json` and `.claude-plugin/plugin.json` raised to `<x.y.z>` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `<x.y.z>` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v<x.y.z>" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v<x.y.z>
git -C /home/noob_master/hyper-relay push origin main v<x.y.z>
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v<x.y.z>` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v<x.y.z>` | one line |

- [ ] **Step 18 (`after merge`): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z> && echo cached` | `cached` |
| `test -f /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/brainstorming/research-prompt.md && echo yes` | `yes` |
| `grep -c -F '## Facts about outside systems' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/writing-plans/SKILL.md` | `1` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If a check still fails, stop and tell the owner; delete or uninstall nothing.

- [ ] **Step 19 (`after merge`): The role agents, regenerated here and in SAT (spec §10; P13, P14).** With the
  installed generator, so the agents' version marker matches the installed plugin:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/hyper-relay && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -i 're-verif' /home/noob_master/hyper-relay/.claude/agents/relay-planner.md` | `0` |

Then SAT, unless a SAT plan is between its dispatch and its merge: then ask the owner first (P14).

| Run | PASS |
|---|---|
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents` | each file `written` or `unchanged`; no `refused` line; exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/hyper-relay-agents --check` | nothing, exit 0 |
| `grep -c -F 'Facts about outside systems' /home/noob_master/sat.pentraze.com/.claude/agents/sat-planner.md` | `1` |

A `refused` line (a hand-edited agent) stops the step: tell the owner. The new agents load in a new session. Then tick
the acceptance task as `reviewing.md` §5 says.
