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
- how the outside systems it depends on work (see Find out how it
  works): each fact with its source (a URL, a command, a file) and the
  date you checked it
- approaches (above)
- the parts of the how they decided, as they decided them
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
until the check is back. Sort what the builder asks into three piles,
and the outside facts it lists into a fourth:

- **Answered already** by the conversation or the project: put the answer
  in the document.
- **Minor:** a sensible builder could settle it without changing what gets
  built. Settle it yourself and mark it in the document as your call.
- **Theirs:** only your human partner can answer it, and the answer changes
  what gets built.
- **Outside facts** it would have to look up or guess: research to do
  (see Find out how it works). Put what you find in `## How it works`,
  and any decision it raises joins the "theirs" pile.

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
| "The planner can look that up" | A planner can't run code and isn't in this conversation. Find out now, and explain it to your human partner. |

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
