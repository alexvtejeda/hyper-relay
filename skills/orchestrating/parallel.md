# Several plans at once

Part of `orchestrating` (`SKILL.md` beside this file is the map). Read it at a handoff while another plan is in
flight, and whenever a spec has more than one plan. A single plan with nothing else in flight never needs it: the leg
files run it alone, as before.

A plan is **in flight** from its dispatch until its branch merges: its branch, named after the plan
(`dispatching.md` §3), exists and is not yet in `main` (`git branch --no-merged main` lists it). It runs as a branch
run (the main checkout is on its branch) or in a worktree (`git worktree list` shows it).

This file says what runs at once (§1), the conflict check before each dispatch (§2), stacking a plan on the one it
builds on (§3), and the order the plans land in (§4). Each plan still goes through the leg files on its own: its
executor (`dispatching.md`), its review legs, its stop 4 and its merge (`reviewing.md`), except that a chain of
stacked plans shares one checkout, one stop 4 and one merge (§3). The merge's exit codes are `reviewing.md` §4's.

## 1. What runs at once

**Planning.** A spec's planners all run at once (`planning.md` §1), except a stacked plan's (§3): it is dispatched
once its base's plan is committed, and plans against the files as the base plan leaves them. All of a spec's plans
share one stop 3 (`planning.md` §3), with a line per plan in its handoff question.

**Executing.**

- **A spec's plans:** every plan without a `**Builds on:**` line can be dispatched at once, in the spec's order. A plan
  with one is stacked (§3).
- **Plans from different specs** run at once whenever the owner starts them.
- **All worktrees:** when two or more plans would be in flight, each runs in a worktree; Branch is offered only for a
  plan that will run alone (`dispatching.md` §1). A chain of stacked plans (§3) counts as one plan: its plans run one
  after another in one checkout, the base's. If a branch run is already active when a second plan starts, that plan
  runs in a worktree, and its handoff line and its stop 4 say "merges after `<branch>`": the merge runs only from the
  main checkout on `main` (`reviewing.md` §4).
- **No background agents** (a harness that waits for each subagent): every rule still holds; the plans run in turn.

**The handoff question** (`dispatching.md` §1) for several plans, or for a plan that joins one in flight, is one
message: a line per plan, then a line per overlap the conflict check found (§2), leaving out the lines that do not
apply:

> Plans ready. They run at once, so each runs in its own **worktree**, and a stacked plan in its base's:
> 1. `<plan path>` (N tasks): starts now.
> 2. `<plan path>` (N tasks): stacked on plan 1; starts in plan 1's checkout once plan 1's reviews are done.
> 3. `<plan path>` (N tasks): waits for `<branch>` to merge.
>
> - Shared files: plan 3 and `<branch>` both change `<path>`. Plan 3 waits for it to merge; say "run them at once
>   anyway" to start it now.
> - Numbered names: plan 2 and `<branch>` both created `<folder>/000097_*`; plan 2's planner renumbered its files to
>   `000098_*`.
>
> OK?

The owner's "OK" is the go-ahead for every plan it covers, each when its line says: `dispatching.md` §2 to §5 for a
plan that starts now, and the same later for a stacked plan (§3) or a waiting one (§2), without asking again.

## 2. The conflict check

Before each dispatch that joins another plan in flight, or a plan approved to run beside it, compare the plan with
each of them: `relay-plan overlap <plan> <other>…`, where each `<other>` is a plan's path or an in-flight plan's
branch. Run it before the handoff question (`planning.md` §2), and again just before a waiting plan is dispatched. It
prints one line per overlap, and nothing when there is none:

- **`shared <path> (<other>)`:** both change the file. A plan's paths are its tasks' `- Create:`, `- Modify:` and
  `- Test:` paths; an in-flight branch's are its plan's, plus what the branch has changed so far.
- **`numbered <folder><digits> (<other>)`:** both create files in the same folder whose names start with the same
  digits, followed by `_` or `.`, such as migrations (`000097_orders.up.sql` and `000097_coupons.up.sql`); a date
  (`2026-11-18-…`) is not a sequence number.

**What happens.** "Later" means dispatched later, or later in the spec's order for a spec's own plans.

- **Shared files:** the later plan waits until the earlier one merges, or is stacked on it if it builds on it (§3).
  When the earlier one merges, run this check again, then dispatch the waiting plan.
- **A numbered collision:** before the handoff question, the later plan goes back to its planner, resumed or fresh
  with the plan (`planning.md` §2), to renumber above the other plan's highest number in that folder and commit the
  plan again.
- **Both kinds appear in the handoff question,** one line each (§1). The owner may say "run them at once anyway":
  record that as a deviation, and name it at both plans' stop 4. A conflict is then settled at the merge
  (`reviewing.md` §4, exit 2).

## 3. Stacking

A stacked plan's header carries `**Builds on:** <base plan path>`. A plan builds on exactly one plan. A **chain** is a
base plan and the plan stacked on it; in a longer chain (C on S on B) each link follows the same rules, on its own
base. A `**Builds on:**` line whose base has already merged changes nothing: the plan runs from `main`. The base has
merged when `git log -1 --format=%h --grep='Plan-Task: <base plan path>' main` prints a commit (`relay-merge` deletes
the base's branch).

A chain's plans run one after another in one checkout, `<checkout>`: the base's worktree in worktree mode, the main
checkout in branch mode. Below, `<B>` is the base's branch and `<S>` the stacked plan's. The folder keeps the base's
name, and both branches are kept, since Quartz and `relay-merge` read them per plan. One executor works there at a
time.

- **When.** The stacked plan starts when the base's review legs are done (`reviewing.md` §3, moment 8): its
  acceptance and fix loop, its code review with every Critical and `code-review` FAIL fixed or dropped, and its skill
  tests. A finding capped on the base still becomes a card, and the cut goes ahead. The base does not go to stop 4 on
  its own: its stop 4 is the chain's (below).
- **The cut,** from the main checkout, while no executor works in `<checkout>`:
  1. `git -C <checkout> branch --show-current` prints `<B>`, `git -C <checkout> rev-parse -q --verify MERGE_HEAD`
     prints nothing, and `git -C <checkout> status --porcelain` prints nothing (in branch mode, with
     `--untracked-files=no`, so that your held-back docs may stay).
  2. When a `wt` stack is up for it, `(cd <checkout> && wt down)`, while `<B>` is still checked out: `wt down` acts on
     the checked-out branch's stack, and removes the `.env` that would stop the next `wt up`.
  3. `git -C <checkout> switch -c <S>`: the stacked branch, from `<B>`'s tip. No `wt new` and no
     `git worktree add`, which would make a second folder: the folder's install stays.
  4. `relay-plan run-dir <S plan>` makes `<S>`'s run folder; `dispatching.md` §4 links it in `<checkout>`, and §5
     dispatches its executor with the checkout `<checkout>` and the branch `<S>`, cut from `<B>`, which has not
     merged. In the status note (moment 3), the base's line's `next:` becomes `the chain's stop 4, after <S>'s
     reviews`. The executor's own `wt up` builds `<S>`'s stack, which it leaves up for the click-through.
- **The stacked plan's reviews** run as soon as its executor hands back, with no wait for the base to merge and no
  catch-up round: `dispatching.md` §7, then `reviewing.md` §1 to §3, in `<checkout>`, with `<B>..<S>` as the branch's
  range while `<B>` has not merged. A defect in the base's work that they find is the base's to fix (below), not a fix
  round on `<S>`.
- **One stop 4 for the chain,** once the last link's review legs are done, and one merge, base first:
  `relay-merge <B> <S>` (`reviewing.md` §4).
- **A fix to the base after the cut** (the owner asks for one at stop 4, "one more round" for a capped base finding,
  or a base defect the stacked plan's reviews found), only while no executor works in `<checkout>`:
  1. When `<S>`'s stack is up, `(cd <checkout> && wt down)`; then `git -C <checkout> switch <B>`.
  2. The fix round goes to the base's executor, and is verified, as `reviewing.md` §2 says. The base's reviewers rerun
     the steps the fix touches (all of them, when that is unclear), and its code reviewer, resumed, checks the fix
     commits.
  3. `git -C <checkout> switch <S>`, and `<S>`'s executor gets a catch-up round, resumed or fresh as
     `dispatching.md` §5 says: "Catch-up round: your base `<B>` changed (`<commits>`). Merge `<B>` into your branch,
     rerun your full gates, and report." A catch-up round is not a fix round: it needs no finding and counts toward
     no fix-round limit. In a longer chain, each later link then catches up in turn on its own base.
  4. `<S>`'s reviewers rerun the steps the base's fix touches (all of them, when that is unclear), and its code
     reviewer checks the merge. Then a short stop 4 again.
- **A longer chain** (C on S on B) repeats the cut link by link: `<C>` is cut in the same folder, from `<S>`'s tip,
  once `<S>`'s review legs are done, and its range is `<S>..<C>`. The one stop 4 covers every link, and the merge is
  one call, in chain order: `relay-merge <B> <S> <C>`.
- **A second plan on the same base** (S1 and S2 both on B) makes a tree, not a chain. The first in the spec's order
  shares the base's checkout; each other one gets a worktree of its own, cut from the main checkout at the same
  moment: `git worktree add .worktrees/<S2> -b <S2> <B>`, or `wt new <S2> --from <B>` in a repo with a `.wt.conf`
  (`dispatching.md` §3), which work whatever the shared folder has checked out. Its review legs (the hand-back check
  of `dispatching.md` §7, acceptance, the code review) wait until `<B>` has merged: hold its executor's report until
  then. Then, when `main` has changes its branch lacks (`git diff --quiet <S2>...main` fails), its executor first gets
  a catch-up round, resumed or fresh as `dispatching.md` §5 says: "Catch-up round: your base `<B>` has merged. Merge
  `main` into your branch, rerun your full gates, and report." Then `dispatching.md` §7 and `reviewing.md`, as for
  any plan, with a stop 4 of its own: the review range holds only its own work.
- **Base dropped or stuck.** If the owner drops the base, or its merge fails and is not recovered, the stacked plan
  stops and goes to the owner: it cannot land without its base.

## 4. Landing order

Every landing is `reviewing.md` §4's: `relay-merge` from the main checkout on `main`, read by its exit code.

- Each plan lands after its own stop 4, and a chain after its one stop 4, in one call, base first:
  `relay-merge <B> <S>` (§3). A second plan on the same base, in a worktree of its own, lands after its base (§3
  holds its review legs until then).
- When a second plan reaches stop 4 before the owner has answered the first's, one stop-4 message covers both, and on
  the owner's go-ahead `relay-merge <first> <second>` lands them in the order they arrived. It stops at the first
  failure; the branches before it stay landed.
- After each landing, plans still in flight do not catch up on their own: the conflict check kept their files apart,
  and their own `relay-merge` reruns the gates on the merged result. A second plan stacked on the one that landed, in
  a worktree of its own, now starts its review legs (§3), and a plan waiting for it is dispatched (§2).
