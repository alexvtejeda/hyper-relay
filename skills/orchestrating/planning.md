# The planner leg

The planner leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when the owner approves the
written spec (stop 2), or when `brainstorming` hands over a spec written from a short design the owner approved in its
first message, which stands for stop 2. It ends at stop 3. You do not write the plan: a planner does, in its own
context.

## 1. Dispatch

Straight after the owner approves the written spec, or `brainstorming` hands over a spec written from a short design
the owner approved, dispatch the planners in the background. The approval is the go-ahead: do not ask again. Then tell
the owner they are running, and carry on.

- **Plan paths.** You name them: `docs/superpowers/plans/<today>-<topic>.md`, where `<topic>` is the spec's file name
  without its date and `-design`. A spec with a `**Plans:** <n>` line gets n paths, each with the suffix the spec
  gives its part (`-api`, `-web`), in the spec's order. Each plan's branch is its file name without the date and
  `.md` (`dispatching.md` §3). For example, the spec `2026-11-18-billing-design.md`, with one plan, written on
  2026-11-19: `docs/superpowers/plans/2026-11-19-billing.md`, on the branch `billing`.
- **One planner per plan, in parallel:** the repo's `<project>-planner` (`.claude/agents/<project>-planner.md`),
  except a stacked plan's (the spec's plans list says it builds on another): it is dispatched once its base's plan is
  committed (`parallel.md` §1).
  Without generated agents (`SKILL.md`, Fallbacks): a general-purpose agent whose first instruction is "Invoke the
  `hyper-relay:writing-plans` skill and follow it. You may only read code and write your plan file." (In OpenCode:
  the `general` subagent, told to load the `writing-plans` skill first.)
- **The prompt gives:**
  - the spec's path (absolute when the spec is not committed on `main`);
  - the plan's path and its branch;
  - with sibling plans: their paths and branches, and that the spec's contract between them binds;
  - for a stacked plan: its base plan's path, which its header names in a `**Builds on:**` line, and that it plans
    against the files as the base plan leaves them;
  - the commit message for the plan, and the attribution lines your harness gives you, in one final paragraph;
  - the Claude-Session URL, when your harness gives you one;
  - whether the repo uses Quartz (`quartz.md` §1), and when it does not, "Run no `quartz` command.": a planner cannot
    run the check itself, and in a declined repo that is still connected its `quartz link-doc` would upload;
  - anything unusual;
  - **during a branch run:** read `main`'s code with `git show main:<path>`; the plan will not be committed (the
    planner's own check refuses), so the planner puts it on its cards with `quartz link-doc` (when the repo uses
    Quartz) and you commit it after the merge (`reviewing.md` §5).

## 2. Check the hand-back

Inline, with git and grep, before the owner sees anything. You do not read the whole plan line by line. For each
plan:

1. **Committed:** `git log -1 --format=%h main -- <plan>` prints a commit. During a branch run: the file exists, and
   the planner's report says it ran `quartz link-doc`; with the Quartz MCP, `get_task` on the card lists the plan
   among its docs. When the repo does not use Quartz (`quartz.md` §1), the file exists.
2. **Card line:** when the spec names a card, the plan's header (above its first `---` or `## `) has a `**Card:**` or
   `**Cards:**` line, or a `**Spec:**` line naming the spec, through which it inherits the spec's cards.
3. **Trailers:** `grep -n -o 'Plan-Task: [^ "]*' <plan>` lists them. Each task with a commit step carries
   `Plan-Task: <plan path>#<N>` once, with its own number and the plan's own path.
4. **Acceptance:** `grep -n '^### Task' <plan> | tail -n 1` names the last task, which is the acceptance task; each of
   its steps says who runs it: `reviewer`, `owner`, `after merge` or `skill-test`.
5. **Placeholders:** `grep -n -E 'TBD|TODO|implement later|fill in details|Similar to Task' <plan>` finds nothing
   outside quoted text.
6. **Spec coverage:** `grep -n '^## ' <spec>` lists the spec's sections. The plan's **Spec coverage** table maps every
   one of them to at least one task.
7. **Sibling plans:** their **Contract** sections are identical.
8. **Stacked:** a plan the spec says builds on another has `**Builds on:** <base plan path>` in its header.
9. **Several plans, or one joining a plan in flight:** `parallel.md` §2's conflict check. A numbered collision goes
   back to the later plan's planner, like a failed check; shared files become lines in the handoff question.

A failed check goes back to the planner before stop 3: resumed (`SKILL.md`, Fallbacks), or a fresh planner given the
list.

## 3. Stop 3

One message, which ends there. It opens with its questions, numbered, in this order (`SKILL.md`, The stops):

- each decision the owner must make;
- each assumption the planner made where the spec was silent, which the owner can accept, correct, or answer with
  "research it" (below);
- "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the spec.";
- the handoff question from `dispatching.md` §1, with its warnings: for several plans, or a plan joining one in
  flight, a line per plan and a line per overlap (`parallel.md` §1 and §2).

Then the report, short, one line per item:

- the plan paths and their task counts;
- a line per plan, "plan N lines for an M-line spec", from `wc -l` on the plan and on its spec;
- the planner's deviations and ambiguities, with its resolutions;
- the facts it re-checked (those the spec flagged), and any differences.

The answer leads one of four ways:

- **Approve, with a mode:** `dispatching.md` §2, for each plan that starts now (`parallel.md` §1 says when the others
  start). The answer is the go-ahead: do not ask again.
- **A plan review:** dispatch a general-purpose agent on Sonnet (`SKILL.md`, Fallbacks) with `writing-plans`'
  `plan-document-reviewer-prompt.md` (`../writing-plans/plan-document-reviewer-prompt.md` from this file), filled in
  with the plan's and the spec's paths. Its findings go to the planner, which revises the plan and commits it again.
  Then §2, and a short stop 3 in the same order: any new decision and the handoff question again, then what
  changed.
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

**Only the planner edits a plan.** When the spec's `**Plans:**` count is wrong, the planner reports it and stops. Ask
the owner; then update the spec's `**Plans:**` line yourself (add it for more than one plan, remove it for one),
commit just the spec while the main checkout is on `main` (`git add <spec>`, then `git commit -m "<message>" --
<spec>`), and dispatch the planners again. During a branch run, the edit itself waits for the merge
(`dispatching.md` §6).

## 4. Several plans

A spec with several plans, or a plan that would run beside another in flight, runs by `parallel.md`: the planners
and the one stop 3 (`parallel.md` §1), the conflict check before each dispatch (`parallel.md` §2), a plan stacked on
the one it builds on (`parallel.md` §3), and the order they land in (`parallel.md` §4).
