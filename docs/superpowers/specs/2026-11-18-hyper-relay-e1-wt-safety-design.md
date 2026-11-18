# hyper-relay E.1: `wt`'s safety notes, and the base-file check (design)

**Date:** 2026-11-18 · **Status:** design approved by the owner in chat on 2026-11-18
**Card:** docs/wt.md: safety notes and platform (`7211f935-aec9-49c1-bc64-5a58326ad08d`)
**Initiative:** v0.1.0 · **Piece:** E.1 · **Depends on:** E (`wt` in hyper-relay, merged `cbc143c`)
**Scope:** this repo: `bin/wt`, `tests/wt/run-tests.sh`, `docs/wt.md`. One plan.

## Goal

E's code review (2026-11-18, Sonnet) found that `docs/wt.md` claims more safety than `wt` gives:

- It says `wt` "sources [`.wt.conf`] as shell", but never says what follows: every line of that file runs with your
  privileges, so `wt` in an untrusted branch runs that branch's code.
- Its Safety section promises "a stack holds no real secrets", but `wt` copies whatever `WT_ENV_BASE` names, even a
  gitignored `.env` or a file outside the repo.
- Its Requirements say Linux without saying macOS is unsupported.
- It says `WT_STATE_DIR` is "outside every repo", which holds only while nobody sets it inside one.

E.1 makes the doc true, and makes the secrets promise a guarantee by having `wt up` enforce it.

## Decisions (owner, 2026-11-18)

| # | Question | Decision |
|---|---|---|
| E1.1 | Docs only, or also code? | **Docs plus one check.** `wt up` refuses a `WT_ENV_BASE` that git does not track, so the Safety bullet about `.env` becomes a guarantee like the others in that list, not a condition. |
| E1.2 | Where do the notes go? | **Each claim is fixed where it stands,** plus one new Safety bullet saying `wt` trusts the branch. No separate "Trust and secrets" section: a reader of any one section sees its caveat there. |
| E1.3 | How wide is the trust note? | **Per branch, not per repo.** `wt up` and `wt new` source the whole `.wt.conf`, not only `WT_SETUP` and `WT_NEW_SETUP`; `wt up` also builds and starts the branch's compose file and Dockerfiles; and `wt new <existing branch>` runs that branch's copy straight away. |

## 1. `bin/wt`: the base-file check

In `write_base_env`, straight after the existing line
`[ -f "$ROOT/$ENV_BASE" ] || die "WT_ENV_BASE file not found: $ENV_BASE"`, one new check:

```sh
git -C "$ROOT" ls-files --error-unmatch -- "$ENV_BASE" >/dev/null 2>&1 ||
    die "WT_ENV_BASE must be a file git tracks: $ENV_BASE"
```

- **What it turns away:** a gitignored file (a real `.env`), any untracked file, and any path outside the repo, given
  absolutely or with `../`. `git ls-files --error-unmatch` exits 1 for the first two and 128 for the third (§5).
- **When it fails:** at the same point as today's not-found error, after the stack has taken its slot and before
  `.env` is written or `WT_SETUP` runs. A refused `wt up` leaves the slot taken, as a missing base file does today;
  fixing `.wt.conf` and running `wt up` again reuses it, and `wt down` frees it.
- **Not checked:** whether a tracked file holds secrets, or has uncommitted local edits. A tracked file's content is
  already in the repo; the doc says to keep it secret-free (§3).
- Nothing else in `bin/wt` changes, including its header comment, which makes none of these claims.

## 2. `tests/wt/run-tests.sh`: two cases

In the refusals section, beside the existing `.wt.conf` refusals, each on a fresh `new_case`:

1. **An untracked base file.** The worktree holds an untracked `.env.local`; `.wt.conf` sets
   `WT_ENV_BASE=.env.local`. `wt up` exits 1, its output names `.env.local`, the fake docker log is empty, and no
   `.env` exists in the worktree.
2. **A base file outside the repo.** A file outside the main checkout and the worktree (in the case's own temp
   folder); `.wt.conf` sets `WT_ENV_BASE` to its path with `../`. Same four assertions, naming that path.

The existing cases pass unchanged: `new_case` commits `.env.example` in every fixture repo.

## 3. `docs/wt.md`

| Where | Change |
|---|---|
| Requirements, the Linux bullet | Linux only. Add: macOS is not supported, because `wt` checks ports with `ss`, from Linux's iproute2. No claim about WSL2, where `wt up` has not yet run. |
| `.wt.conf`, the paragraph that says `wt` "sources it as shell" | Add that `.wt.conf` is code. `wt up` and `wt new` source it, so every line runs with your privileges, not only `WT_SETUP` and `WT_NEW_SETUP`; and `wt up` builds and starts the branch's compose file and Dockerfiles. Review `.wt.conf` like a build script, and run `wt` only on branches whose code you would run yourself: `wt new` on someone else's branch runs that branch's copy straight away. |
| `.wt.conf` key table, the `WT_ENV_BASE` row | The file must be one git tracks (`wt up` refuses any other) and must hold no secrets. |
| `.wt.conf` key table, the `WT_ENV` row | Real credentials never go here: `.wt.conf` is committed. |
| State and limits, the `WT_STATE_DIR` row | "Outside every repo." becomes a rule with its reason: keep it outside every repo, because inside one, `git clean` or removing a worktree can delete a running stack's state, and `wt down` refuses a stack it holds no state for. |
| When something fails | A new row: `WT_ENV_BASE` names a file git does not track (gitignored, untracked, or outside the repo) → stops before writing `.env`, and names it. |
| Safety, the `.env` bullet | Rests on the check: `.env` comes from a file git tracks, never from your real `.env`, because `wt up` refuses any other base file. Keep that file secret-free and real credentials out of `WT_ENV`, since both are committed; then a stack holds no real secrets and cannot use them to reach a real outside service. |
| Safety, a new last bullet | `wt` is no sandbox: it runs the branch's code (`.wt.conf`, the compose file, the Dockerfiles), so use it only on branches you trust. |

Nothing else in `docs/wt.md` changes. The README's `### wt` section stays as it is: it points at `docs/wt.md` and
makes none of these claims.

## 4. Testing and acceptance

### 4.1 The executor's gates

- `sh tests/wt/run-tests.sh` ends `0 failed`, with the two new cases among the passes.
- `dash -n bin/wt` is silent.

### 4.2 `reviewer` steps, before the merge

- The suite and `dash -n`, as in §4.1.
- `git diff main -- bin/wt` adds only the check in `write_base_env`.
- Each row of §3's table is in `docs/wt.md`, checked by `git grep`: `macOS`, `build script`, `git tracks`,
  `Real credentials`, `git clean`, and the new failure-table row and Safety bullet.
- The two claims E's review flagged are gone: `git grep -F 'Outside every repo.' -- docs/wt.md` prints nothing, and
  the Safety bullet that says a stack "holds no real secrets" also says `wt up` refuses a base file git does not
  track.
- Only `bin/wt`, `tests/wt/run-tests.sh` and `docs/wt.md` differ from `main`.

### 4.3 `after merge` steps, the orchestrator with the owner

- Push `main`; the owner reinstalls (`/plugin install hyper-relay@hyper-relay`, in a Claude Code session), so agents'
  `wt` gets the check. The owner's shell already runs the main checkout's `bin/wt` (E2), so it has it on merge.
- SAT still passes the check: `git -C /home/noob_master/sat.pentraze.com ls-files --error-unmatch -- .env.example`
  exits 0 (SAT's `.wt.conf` leaves `WT_ENV_BASE` at its default).

## 5. External facts (checked 2026-11-18)

- `git ls-files --error-unmatch -- <path>`, run with `-C <worktree>` on git 2.43.0: exit 0 for a tracked file (given
  as `.env.example`, `./.env.example`, or its absolute path inside the worktree); exit 1 for a gitignored `.env` and an
  untracked `.env.local`; exit 128 for `../outside` and for an absolute path outside the repo.
- macOS ships no `ss`; it is part of Linux's iproute2.

## 6. Out of scope

- Enforcing anything about a tracked base file's content.
- Refusing a `WT_STATE_DIR` inside a repo: documented, not enforced.
- WSL2 support claims, until `wt up` has run there.
- `wt`'s behaviour otherwise, and the README.

## 7. Plans

One plan: `docs/superpowers/plans/2026-11-18-hyper-relay-e1-wt-safety.md`, branch `hyper-relay-e1-wt-safety`.
