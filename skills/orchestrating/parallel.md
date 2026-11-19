# Several plans at once

Part of `orchestrating` (`SKILL.md` beside this file is the map). Read it at a handoff while another plan is in
flight, and whenever a spec has more than one plan. A single plan with nothing else in flight never needs it: the leg
files run it alone, as before.

A plan is **in flight** from its dispatch until its branch merges: its branch, named after the plan
(`dispatching.md` §3), exists and is not yet in `main` (`git branch --no-merged main` lists it). It runs as a branch
run (the main checkout is on its branch) or in a worktree (`git worktree list` shows it).

This file says what runs at once (§1), the conflict check before each dispatch (§2), stacking a plan on the one it
builds on (§3), and the order the plans land in (§4). Each plan still goes through the leg files on its own: its
executor (`dispatching.md`), its review legs, its stop 4 and its merge (`reviewing.md`). The merge's exit codes are
`reviewing.md` §4's.

## 1. What runs at once

**Planning.** A spec's planners all run at once (`planning.md` §1), except a stacked plan's (§3): it is dispatched
once its base's plan is committed, and plans against the files as the base plan leaves them. All of a spec's plans
share one stop 3 (`planning.md` §3), with a line per plan in its handoff question.

**Executing.**

- **A spec's plans:** every plan without a `**Builds on:**` line can be dispatched at once, in the spec's order. A plan
  with one is stacked (§3).
- **Plans from different specs** run at once whenever the owner starts them.
- **All worktrees:** when two or more plans would be in flight, each runs in a worktree; Branch is offered only for a
  plan that will run alone (`dispatching.md` §1). If a branch run is already active when a second plan starts, that
  plan runs in a worktree, and its handoff line and its stop 4 say "merges after `<branch>`": the merge runs only from
  the main checkout on `main` (`reviewing.md` §4).
- **No background agents** (a harness that waits for each subagent): every rule still holds; the plans run in turn.

**The handoff question** (`dispatching.md` §1) for several plans, or for a plan that joins one in flight, is one
message: a line per plan, then a line per overlap the conflict check found (§2), leaving out the lines that do not
apply:

> Plans ready. They run at once, so each runs in its own **worktree**:
> 1. `<plan path>` (N tasks): starts now.
> 2. `<plan path>` (N tasks): stacked on plan 1; starts when plan 1 passes acceptance.
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
each of them. Run it before the handoff question (`planning.md` §2), and again just before a waiting plan is
dispatched.

- **Shared files.** A plan's paths are its tasks' `- Create:`, `- Modify:` and `- Test:` paths, without any `:lines`
  part:

  ```sh
  grep -E '^- (Create|Modify|Test): ' <plan> | grep -o '`[^`]*`' | tr -d '`' | grep -v '^:' | sed 's/:[0-9][0-9,-]*$//' | sort -u
  ```

  An in-flight plan's paths are its plan's, plus what its branch has changed so far:
  `git diff --name-only main...<branch>`. A path in both lists is an overlap.
- **Numbered names.** Two plans create files in the same folder whose names start with the same digits, such as
  migrations (`000097_orders.up.sql` and `000097_coupons.up.sql`). Compare the folder and leading digits of each
  plan's `- Create:` paths, and of the files the in-flight branch has added
  (`git diff --name-only --diff-filter=A main...<branch>`), as `sed -E -n 's#^(.*/)?([0-9]+)[^/]*$#\1\2#p'` prints
  them. A date (`2026-11-18-…`) is not a sequence number.

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

A stacked plan's header carries `**Builds on:** <base plan path>`. A plan builds on exactly one plan; in a chain (C on
S on B) each link follows the same rules. A `**Builds on:**` line whose base has already merged changes nothing: the
plan runs from `main`. The base has merged when `git log -1 --format=%h --grep='Plan-Task: <base plan path>' main`
prints a commit (`relay-merge` deletes the base's branch).

- **Cut.** When the base passes acceptance (its fix loop has ended, `reviewing.md` §2), cut the stacked plan's
  worktree from the base's branch: `git worktree add .worktrees/<S> -b <S> <B>`, or `wt new <S> --from <B>` in a repo
  with a `.wt.conf` (`dispatching.md` §3). Then dispatch its executor (`dispatching.md` §4 and §5). It runs while the
  base goes through its code review and stop 4.
- **Catch up.** The stacked plan's review legs (the hand-back check of `dispatching.md` §7, acceptance, the code
  review) wait until its base has merged: hold its executor's report until then. Then, when `main` has changes its
  branch lacks (`git diff --quiet <S>...main` fails: the base's code-review fixes, other plans' merges), its executor
  first gets a catch-up round, resumed or fresh as `dispatching.md` §5 says: "Catch-up round: your base `<B>` has
  merged. Merge `main` into your branch, rerun your full gates, and report." A catch-up round is not a fix round: it
  needs no finding and counts toward no fix-round limit. Then `dispatching.md` §7 and `reviewing.md`, as for any plan:
  acceptance and the code review see the plan on top of the final `main`, and the review range holds only its own
  work.
- **Base dropped or stuck.** If the owner drops the base, or its merge fails and is not recovered, the stacked plan
  stops and goes to the owner: it cannot land without its base.

## 4. Landing order

Every landing is `reviewing.md` §4's: `relay-merge` from the main checkout on `main`, read by its exit code.

- Each plan lands after its own stop 4; a stacked plan always after its base (§3 holds its review legs until then).
- When a second plan reaches stop 4 before the owner has answered the first's, one stop-4 message covers both, and on
  the owner's go-ahead `relay-merge <first> <second>` lands them in the order they arrived. It stops at the first
  failure; the branches before it stay landed.
- After each landing, plans still in flight do not catch up on their own: the conflict check kept their files apart,
  and their own `relay-merge` reruns the gates on the merged result. A plan stacked on the one that landed now starts
  its review legs (§3), and a plan waiting for it is dispatched (§2).
