# hyper-relay: brainstorming from upstream's rebuilt SKILL.md (superpowers 7.0.2) (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19
**Card:** brainstorming: bring upstream's rebuilt SKILL.md (superpowers 7.0.2) into the relay (`a5a66906-5d01-4a18-956e-264e0c0123c1`)
**Initiative:** v0.1.0
**Scope:** this repo: `skills/brainstorming/` (`SKILL.md`, a new `builder-check-prompt.md`, the old reviewer prompt
deleted), three files of `skills/orchestrating/` (`quartz.md`, `SKILL.md`, `planning.md`), `tests/orchestrating/run-tests.sh`,
`tests/claude-code/test-document-review-system.sh` (deleted), `README.md`. One plan. Released as 0.2.2.

## Goal

Upstream rebuilt brainstorming from scratch in 7.0.0 (#2463) and tuned it in 7.0.1 (#2560, #2571) and 7.0.2 (#2644),
164 → 316 lines. The rebuilt skill reads the project and what it was pointed at before its first message, asks why
first and openly, asks a question only when the answer changes what gets built, plays the design back in chunks, sizes
the work, and has a fresh agent read the written design as its builder. Upstream's blind-graded evals: filler questions
41 → 23 against 7.0.1 (34 for 6.4.2), the why drawn out before any approach in 33 of 33 conversations (19 of 33 for
6.4.2), nothing built before approval.

Ours is v5.1.0's text plus the relay's parts. This spec brings upstream's v7.0.2 text in as the base and puts the
relay's parts back in at the places they belong, so brainstorming in the relay behaves like upstream's and still
hands over to `orchestrating`.

## Decisions (2026-11-19)

| # | Question | Decision |
|---|---|---|
| BR1 | How is the text built? (owner) | **Upstream's v7.0.2 `SKILL.md` is the base, word for word, with the edits of §2 at named sections.** Upstream's tuned wording, the wording their evals measured, survives, and the next upstream change diffs section by section. Not ours rewritten with upstream's behaviours (loses the wording, every later port a hand merge); not upstream's file plus a side file (upstream's own text says "do it", "invoke writing-plans" and "read visual-companion.md here", and a side file cannot reliably overrule the SKILL.md the agent reads first). |
| BR2 | What does a yes to upstream's opt-out ("Or if you'd rather I just dive in, say so") do? (owner) | **Upstream's behaviour: the skill is done and there is no spec or plan, for work of any size.** Your human partner's "just do it" is their own off-ramp. The agent states any significant how-it-gets-made choice in one plain line first. While a plan runs on a branch in the main checkout, the work goes in a worktree of its own (§2.4). |
| BR3 | When the first message is already a short design (nothing open) and it is approved, is there still a stop 2? (owner) | **No. That approval covers stops 1 and 2:** the spec is written as approved, committed, and handed to `orchestrating` in the message that gives its path. For a skill change the short design names its pressure scenarios, so the spec holds nothing they did not see. |
| BR4 | Does `builder-check-prompt.md` come? | **Yes, and the spec-document reviewer goes.** Our `SKILL.md` never dispatched `spec-document-reviewer-prompt.md` (D1's spec already called it orphaned); only upstream's live test `tests/claude-code/test-document-review-system.sh` reads it. Upstream deleted both; so do we. Our inline spec self-review goes too, as upstream's did: for a project the builder check covers it. |
| BR5 | How does upstream's sizing meet the off-ramp? | **The off-ramp replaces upstream's "quick, clear task: do it", and still asks first.** Both of upstream's sizes go to the relay: the size decides only the spec's form (a short one, or the full one with a builder check). The off-ramp and an opt-out (BR2) are the only ways to skip the spec. |
| BR6 | The visual-companion offer? | **Upstream's: just in time, in its own message, in upstream's words, with no token-cost warning.** Our `visual-companion` skill and its display-only rules stay; "throwaway prototypes they can click" goes. |
| BR7 | Spikes? | **Kept, as upstream has them** (only after a yes, throwaway, no plan or review), **built in a worktree of their own and never merged.** Keeping one is a new request through the gate. |
| BR8 | The Quartz step? | **Before the first message**, under Look Before You Ask. `quartz.md`'s four pointers to "brainstorming's step 1" say "before brainstorming's first message". |
| BR9 | Calls made by the orchestrator, not the owner (the owner did not object) | Our frontmatter `description` stays (upstream's adds "a talk, a business, a renovation", which does not fit a relay that ends in a code plan). Upstream's "your human partner" throughout the file, including the parts moved from ours, so diffs against upstream stay clean. The builder check runs on Sonnet, like the relay's other reviewers. README's Design row names the builder check and its diagram shows the short-design skip. |
| BR10 | How is it accepted and released? | Diff against upstream, the relay guard, S1–S11 skill tests (§7, §8). Release 0.2.2 after the merge. A live probe on the next real brainstorm (card `6ad2f229`), judged by the owner; a miss there is a new card, not a blocker. |

## 1. What changes where

| File | Change |
|---|---|
| `skills/brainstorming/SKILL.md` | Upstream's v7.0.2 text with the edits of §2 |
| `skills/brainstorming/builder-check-prompt.md` | New: upstream's v7.0.2 file, with one edit (§3) |
| `skills/brainstorming/spec-document-reviewer-prompt.md` | Deleted (BR4) |
| `tests/claude-code/test-document-review-system.sh` | Deleted: it only tests the deleted prompt (BR4) |
| `skills/orchestrating/quartz.md` | Four pointers reworded (§4) |
| `skills/orchestrating/SKILL.md` | Stops table, stops 1 and 2 (§4) |
| `skills/orchestrating/planning.md` | Its opening and §1's first sentence allow the short-design approval (§4) |
| `tests/orchestrating/run-tests.sh` | One new check, one broken case (§5) |
| `README.md` | The Design row and the relay diagram (§6) |

Nothing else changes: the off-ramp's five cases, `scripts/add-card-line.sh`, the `visual-companion` skill, every other
skill, the role-agent templates.

## 2. `skills/brainstorming/SKILL.md`

Start from `git show v7.0.2:skills/brainstorming/SKILL.md`. Every line not named below stays word for word. Line
numbers are upstream's, for orientation. Text this section quotes as "from today" is copied from today's
`skills/brainstorming/SKILL.md`, with "the owner" and "the user" read as "your human partner" (BR9). Every
`superpowers:<skill>` name becomes `hyper-relay:<skill>`; no `superpowers:` skill name remains (§5).

The plan writes the full text of the new file (the relay's rule for skill text).

### 2.1 Frontmatter

`name: brainstorming` and today's `description` (BR9):
"You MUST use this before any creative work - creating features, building components, adding functionality, or
modifying behavior. Explores user intent, requirements and design before implementation."

### 2.2 First: What Do You Actually Know? (lines 15–40)

- The bullet "**Everything that matters is in the request** ("make the icon cornflower blue"). This is a quick, clear
  task. Do it, and say what you did." becomes a bullet for the off-ramp: the request is one of the off-ramp's cases,
  so ask as the off-ramp says (below). The second bullet ("Something non-trivial is missing") stays.
- After the bullets, today's off-ramp paragraph comes in as a subsection, **The off-ramp (experiment)**, word for word
  from today except: its first sentence also allows an opt-out ("A request may skip the relay (no design, spec or
  plan) only when it is one of: …, or when your human partner opts out of the questions (see Your First Message)"),
  and "the owner" reads "your human partner". The five cases, the ask in a message of its own with its quoted
  wording, "Skip the relay only on a yes", "Anything not on the list, or any doubt, goes through the relay without
  asking" and "If the work turns out bigger than one change, stop and take it through the relay" stay as they are.
- Step 4 ("Invoke the superpowers:writing-plans skill.") becomes: invoke `hyper-relay:orchestrating`, whose planner
  leg writes the plan.
- "Two things aren't implementing: …" becomes three: a spike they said yes to, doing what they asked once they've
  opted out of the questions, and an off-ramp case they said yes to.

### 2.3 Look Before You Ask (lines 42–51)

Opens with a **Quartz** paragraph, before upstream's text: before your first message, run
`hyper-relay:orchestrating`'s Quartz check (`${CLAUDE_SKILL_DIR}/../orchestrating/quartz.md`, §1 and §2;
`../orchestrating/quartz.md` from this SKILL.md). When the repo uses Quartz and the work has a card, call `tick_brain`
with its id; a failure is reported and the skill carries on. The card's body and its notes are context your human
partner gave you: read them before your first message, like anything else they pointed at.

### 2.4 Your First Message (lines 53–102)

- Line 76, "write the short design doc as approved and go on to the plan", becomes: write the short design doc as
  approved and commit it (The Written Design), then invoke `hyper-relay:orchestrating` in the message that gives its
  path. Their approval covers both the design and the written doc, so there is no second ask (BR3). For a skill
  change, the short design names its pressure scenarios (The Written Design), so the doc holds nothing they did not
  see.
- Line 95, "then do what they asked through the normal workflow", becomes: then do what they asked directly, with no
  spec or plan, as on the off-ramp (BR2). When the main checkout is on a branch other than `main`, a plan is running
  there: do the work in a worktree of its own (`hyper-relay:using-git-worktrees`), never in the main checkout, and
  land it after that branch has merged.

### 2.5 The Conversation (lines 104–188)

- Lines 179–180, "Once they've accepted, use it for mockups to react to, side-by-side options, and throwaway
  prototypes they can click.", lose the prototypes: "Once they've accepted, use it for mockups to react to and
  side-by-side options." (BR6).
- **Spike to feel things out** gains one sentence (BR7): build a spike in a worktree of its own
  (`hyper-relay:using-git-worktrees`), never in the main checkout, and never merge it.

### 2.6 Play It Back (lines 190–208)

Unchanged.

### 2.7 Size the Work (lines 210–230)

After the table and the Approaches paragraph, one paragraph (BR5): either size goes to the relay (the design doc, then
`hyper-relay:orchestrating`); only the off-ramp and an opt-out skip it. After "If this is really several independent
projects …", one sentence: one project that needs more than one plan (an API plan and a web plan) stays one design
doc, with a `**Plans:**` line (The Written Design).

### 2.8 The Written Design (lines 232–268)

- **Where it goes** keeps upstream's sentences and gains today's Documentation rules, moved in word for word (with
  "step 1" read as "the Quartz step"):
  - the card line: run `${CLAUDE_SKILL_DIR}/scripts/add-card-line.sh <spec-path> <card-id> [<card-id>...]`
    (`scripts/add-card-line.sh` beside this SKILL.md) straight after writing the doc; with no card, skip it; a script
    failure is reported and does not stop the skill;
  - the `**Plans:** <n>` line and `## The plans`, as today;
  - pressure scenarios for a skill change, as today;
  - the commit rule: commit only while the repo's main checkout is on `main`, staging the doc by its path; otherwise
    `quartz link-doc <spec-path>` (skipped when the Quartz step found no Quartz) and the commit waits for that branch's
    merge (`hyper-relay:orchestrating`'s `reviewing.md`, §5).
- **Builder check**, line 251: the prompt is `${CLAUDE_SKILL_DIR}/builder-check-prompt.md`
  (`builder-check-prompt.md` beside this SKILL.md), and the fresh subagent runs on Sonnet (BR9).
- After "then hand it over with a short list of the calls you made so they can check those while reading": commit it
  before handing it over (the commit rule above). That hand-over is stop 2. Their approval is the go-ahead: invoke
  `hyper-relay:orchestrating`, with no second ask. Changes they ask for are made, committed, and handed over again.
- The small change's short design (lines 242–244) still goes straight to your human partner without the builder
  check: that hand-over is stop 2 as well, except when the short design was already approved in the first message
  (§2.4).

### 2.9 HARD-GATE (lines 270–283)

- "Two exceptions." becomes three: the opt-out and the spike as upstream has them, and an off-ramp case your human
  partner said yes to.
- Lines 281–282 become: after the design doc is approved, the next step is the plan: invoke
  `hyper-relay:orchestrating`, whose planner leg dispatches a planner to write it, and no other skill. Never write the
  plan yourself, and never invoke `writing-plans`.

### 2.10 Red Flags (lines 285–294)

Unchanged.

### 2.11 Visual Companion (lines 296–316)

Upstream's section, with its offer wording and no token warning (BR6), except line 315: "If they accept, read
`visual-companion.md` in this directory before starting the server." becomes: if they accept, invoke the
`visual-companion` skill, followed by these paragraphs from today, word for word:

- "**Brainstorming does not implement it** — the `visual-companion` skill owns …", adapted to open with "If they
  accept" instead of "On the first visual question", and keeping "Brainstorming ships none" and the stale-copy line;
- "**The browser is display-only.** …";
- "**Old screens are not a spec.** …".

### 2.12 Removed from today's file

The numbered checklist and its tasks, the process graph, "Anti-Pattern: This Is Too Simple To Need A Design", Key
Principles, Spec Self-Review, the User Review Gate's wording ("Spec written to `<path>`. Please review it …"), and
today's offer wording with its token warning. Everything else of today's that the relay needs is moved in by §2.2 to
§2.11.

## 3. `skills/brainstorming/builder-check-prompt.md`

Upstream's v7.0.2 file, word for word, except its first instruction: "Dispatch a fresh general-purpose subagent with
this prompt once the written design exists." says "on Sonnet" as well. The prompt itself (the builder who cannot talk
to the writer, report only the questions that change the plan, ranked; skip what the document leaves to the builder;
"nothing important left") is unchanged.

## 4. `orchestrating`

- **`quartz.md`**, four pointers, nothing else:
  - line 6, "runs §1 and §2 at its step 1, before any other leg" → "runs §1 and §2 before its first message, before
    any other leg";
  - line 10, "at `brainstorming`'s step 1" → "before `brainstorming`'s first message";
  - line 50, "At `brainstorming`'s step 1, send it before brainstorming's first question." → "At `brainstorming`'s
    start, send it before brainstorming's first message.";
  - line 110, "(at `brainstorming`'s step 1, with the MCP)" → "(before `brainstorming`'s first message, with the MCP)".
- **`SKILL.md`**, the stops table:
  - stop 1's "What the owner gets": "The approaches, then the design played back part by part (`brainstorming`)";
  - stop 2's "What the owner gets": "The written spec (`brainstorming`); skipped when the owner approved a short design
    in brainstorming's first message, which covers stops 1 and 2".
- **`planning.md`**: line 4's "It starts when the owner approves the written spec (stop 2)" and §1's "Straight after
  the owner approves the written spec" both also allow the short-design approval that stands for stop 2 (BR3).

## 5. Tests

- **`tests/orchestrating/run-tests.sh`** gains one check: no `superpowers:<skill>` name anywhere under `skills/`
  (`superpowers:` followed by a letter; `docs/superpowers/` paths do not match). Nothing matches today. Its broken
  case appends "Invoke the superpowers:writing-plans skill." to a copy of `skills/brainstorming/SKILL.md` and must
  fail. The existing `brainstorming_never_invokes_writing_plans` check stays as it is. The header's expected count
  rises by two.
- **`tests/claude-code/test-document-review-system.sh`** is deleted (BR4). After the change, nothing outside `docs/`
  names it or `spec-document-reviewer-prompt.md`.

## 6. `README.md`

- The Design row of the relay table: "An approved design, written as a spec in `docs/superpowers/specs/`, read first
  by a builder check".
- The relay diagram: a dashed edge from `spec` to `planner`, labelled "short design approved", beside the path through
  `stop2`, so a reader sees that approving a short design covers stop 2.

## 7. Pressure scenarios

Each runs on today's `skills/brainstorming/` (RED) and the branch's (GREEN), on Sonnet, as a `skill-test` step. The
situations are described to the agent; the repo is this one, and the commands named exist. S6 is a guard: it is
expected to pass on both texts.

| # | Situation | The new text must | Today's text does |
|---|---|---|---|
| S1 | Your human partner invokes brainstorming by name: "add a `--json` flag to `wt ls`". No why given. | Read `bin/wt` and `docs/wt.md` before replying. One message of about 200 words: the request echoed, what it found, ending with one open question about why, with no options to pick from and no opt-out offer. | Asks a clarifying question, often multiple choice, about the what. |
| S2 | A card gives the what and the why: `relay-merge --version` prints the plugin version from `.claude-plugin/plugin.json`, so the owner can tell which `relay-merge` is on PATH. One sensible way; not an off-ramp case. | The first message ends with the short design (the approach, a line on why the others don't fit, the design in a few lines) and asks for approval. | Asks clarifying questions first. |
| S3 | Transcript: S2, and your human partner approved the short design. | Write the short spec as approved, commit it (the main checkout is on `main`), invoke `hyper-relay:orchestrating` in the message that gives the path. No "please review". | Self-reviews, then "Spec written to `<path>`. Please review it …". |
| S4 | "Sort `wt ls` by age." Brainstorming was not asked for (it started from the global rule). | The first message ends with a light one-line offer to just get going. | No such offer. |
| S5 | Transcript: S4, then "just do it". The main checkout is on `hyper-relay-x`, a plan's branch. | One plain line on any significant how; build it directly, with no spec or plan, in a worktree of its own, not in the main checkout. | Takes it through the relay anyway (not on the off-ramp list). |
| S6 | "Fix the typo 'recieve' in `docs/wt.md`." | Ask the off-ramp question, in a message of its own, before changing anything. | The same (guard against upstream's "do it, and say what you did"). |
| S7 | Transcript: a project-size design for a new skill, the approach picked, every part played back. | Write the spec; dispatch a fresh subagent on Sonnet with `builder-check-prompt.md`; sort what it asks into answered already / minor (marked as its own call) / theirs; bring the "theirs" pile in one message; then hand over with the list of its calls. | Inline self-review, then "Spec written … Please review it". |
| S8 | "Add a `--quiet` flag to `relay-merge`." The why is given. Open: what `--quiet` hides (changes what gets built), whether it is POSIX shell (the file answers it), where the spec goes (a process call). | Ask only what `--quiet` hides, with the choices sketched and a pick; state the shell and the spec's place as calls, without asking. | Asks clarifying questions one at a time, including the ones the project or process answers. |
| S9 | A new tmux status-bar line for `wt`, showing each worktree's stack. The look is your human partner's to decide. | No visual-companion offer in the first message. When the look comes up, the offer in its own message, in upstream's words, with no token-cost warning. | Offers up front, with the token-cost warning. |
| S10 | Your human partner doubts tmux can refresh a status line every second without lag, and that decides the design. | Offer a spike. On a yes, build it in a worktree of its own, with no plan, never merged; bring what it taught back to the conversation. | Builds nothing before an approved design. |
| S11 | Transcript: the approach picked for a two-line change to `docs/relay-merge.md`'s exit-code table. | Say in plain words that it is a small change; write a short spec with no builder check; hand it over (stop 2); on approval, `hyper-relay:orchestrating`. | No sizing; the full process. |

## 8. Acceptance and release

The reviewer's steps, on the branch:

1. `claude plugin validate .` passes, with the three known warnings.
2. `sh tests/orchestrating/run-tests.sh`: `0 failed`, with the new check and its broken case among them.
3. `diff <(git show v7.0.2:skills/brainstorming/SKILL.md) skills/brainstorming/SKILL.md`: every hunk is one of
   §2's edits, and nothing else differs. `diff <(git show v7.0.2:skills/brainstorming/builder-check-prompt.md)
   skills/brainstorming/builder-check-prompt.md`: only §3's edit.
4. `skills/brainstorming/spec-document-reviewer-prompt.md` and `tests/claude-code/test-document-review-system.sh` are
   gone, and outside `docs/` nothing names either.
5. `skills/orchestrating/quartz.md` no longer points at a "step 1" of brainstorming's; nothing under `skills/brainstorming/`
   names a path on this machine (its own files as `${CLAUDE_SKILL_DIR}/...` and relative to `SKILL.md`).
6. Skill tests S1–S11 (§7), RED and GREEN: all GREEN; the RED results recorded, and a scenario that does not tell the
   two texts apart is noted, not failed.

After the merge: release 0.2.2 (`scripts/bump-version.sh 0.2.2`, a commit of just `package.json` and
`.claude-plugin/plugin.json`, `chore: release v0.2.2`, tag `v0.2.2`, push `main` and the tag); the owner runs
`claude plugin update hyper-relay@hyper-relay` and `/reload-plugins`; the orchestrator regenerates the role agents in
this repo and in SAT (their marker carries the version).

**Live probe:** the next real brainstorm, card `6ad2f229` (upstream small fixes), in a fresh session on 0.2.2. The
owner judges: it read before asking; its first message was about 200 words and echoed the request with what it
found; it asked why or gave a short design; a project-size design got a builder check. The result goes in the plan's
record. A miss is a new card; it does not block this merge.

## 9. Out of scope

Upstream's brainstorm-server scripts and `visual-companion.md` (card `e3303d7a`); the other upstream fixes (`6ad2f229`,
`5441ce1c`); any change to how `orchestrating` runs a small change; the off-ramp's list of cases; Quartz itself.
