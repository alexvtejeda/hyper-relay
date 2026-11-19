# The planner leg

The planner leg of `orchestrating` (`SKILL.md` beside this file is the map). It starts when the owner approves the
written spec (stop 2) and ends at stop 3. You do not write the plan: a planner does, in its own context.

## 1. Dispatch

Straight after the owner approves the written spec, dispatch the planners in the background. The approval is the
go-ahead: do not ask again. Then tell the owner they are running, and carry on.

- **Plan paths.** You name them: `docs/superpowers/plans/<today>-<topic>.md`, where `<topic>` is the spec's file name
  without its date and `-design`. A spec with a `**Plans:** <n>` line gets n paths, each with the suffix the spec
  gives its part (`-api`, `-web`), in the spec's order. Each plan's branch is its file name without the date and
  `.md` (`dispatching.md` §3). For example, the spec `2026-11-18-billing-design.md`, with one plan, written on
  2026-11-19: `docs/superpowers/plans/2026-11-19-billing.md`, on the branch `billing`.
- **One planner per plan, in parallel:** the repo's `<project>-planner` (`.claude/agents/<project>-planner.md`).
  Without generated agents (`SKILL.md`, Fallbacks): a general-purpose agent whose first instruction is "Invoke the
  `hyper-relay:writing-plans` skill and follow it. You may only read code and write your plan file." (In OpenCode:
  the `general` subagent, told to load the `writing-plans` skill first.)
- **The prompt gives:**
  - the spec's path (absolute when the spec is not committed on `main`);
  - the plan's path and its branch;
  - with sibling plans: their paths and branches, and that the spec's contract between them binds;
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
   its steps says who runs it: `reviewer`, `owner` or `after merge`.
5. **Placeholders:** `grep -n -E 'TBD|TODO|implement later|fill in details|Similar to Task' <plan>` finds nothing
   outside quoted text.
6. **Spec coverage:** `grep -n '^## ' <spec>` lists the spec's sections. The plan's **Spec coverage** table maps every
   one of them to at least one task.
7. **Sibling plans:** their **Contract** sections are identical.

A failed check goes back to the planner before stop 3: resumed (`SKILL.md`, Fallbacks), or a fresh planner given the
list.

## 3. Stop 3

One message, which ends there. It opens with its questions, numbered, in this order (`SKILL.md`, The stops):

- each decision the owner must make;
- "Want a plan review before you read it? A fresh agent on Sonnet reads the plan against the spec.";
- the handoff question from `dispatching.md` §1, with its warnings, for the first plan to run.

Then the report, short, one line per item:

- the plan paths and their task counts;
- the planner's deviations and ambiguities, with its resolutions;
- the external facts it re-verified, and any differences.

The answer leads one of three ways:

- **Approve, with a mode:** `dispatching.md` §2. The answer is the go-ahead: do not ask again.
- **A plan review:** dispatch a general-purpose agent on Sonnet (`SKILL.md`, Fallbacks) with `writing-plans`'
  `plan-document-reviewer-prompt.md` (`../writing-plans/plan-document-reviewer-prompt.md` from this file), filled in
  with the plan's and the spec's paths. Its findings go to the planner, which revises the plan and commits it again.
  Then §2, and a short stop 3 in the same order: any new decision and the handoff question again, then what
  changed.
- **Changes:** the planner revises the plan (resumed, or fresh with the owner's list) and commits it again. Then §2
  and stop 3.

**Only the planner edits a plan.** When the spec's `**Plans:**` count is wrong, the planner reports it and stops. Ask
the owner; then update the spec's `**Plans:**` line yourself (add it for more than one plan, remove it for one),
commit just the spec while the main checkout is on `main` (`git add <spec>`, then `git commit -m "<message>" --
<spec>`), and dispatch the planners again. During a branch run, the edit itself waits for the merge
(`dispatching.md` §6).

## 4. Several plans

They run one after another, in the spec's order. After plan k merges (`reviewing.md` §5), plan k+1 gets its own
stop-3 handoff question, and its branch is cut from the new `main`. Running them at once is not part of this skill.
