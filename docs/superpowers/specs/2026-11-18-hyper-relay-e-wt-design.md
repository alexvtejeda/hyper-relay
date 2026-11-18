# hyper-relay E: `wt` moves into hyper-relay (design)

**Date:** 2026-11-18 · **Status:** design approved by the owner in chat on 2026-11-18
**Card:** Move wt into hyper-relay (`81c5c257-4ce9-40ee-8dac-c2b6cb84907e`)
**Initiative:** hyper-relay · **Piece:** E · **Depends on:** A (the plugin layout)
**Scope:** this repo (`bin/wt`, `tests/wt/`, a new `docs/wt.md`, README and `CLAUDE.md`); after the merge, the
owner's `~/.local/bin/wt` symlink, the home repo's copy, and a pointer in the Quartz repo's `wt` spec. One plan.

## Goal

`wt` gives each git worktree a disposable Docker Compose stack (its own containers, database, ports and seed data), so
a branch can be clicked through without touching the owner's real stack. Today it lives at `~/.claude/bin/wt`, tracked
in the home repo, with its suite in `~/.claude/tests/wt/` and its design spec in the Quartz repo. hyper-relay's
skills already call it by name (`dispatching.md`, SAT's generated agents), and D2's preview stack will rest on it, so
a public plugin cannot depend on a file only this machine has.

E moves `wt` into the plugin with no behaviour change. Claude Code's Bash tool then finds it on any machine with
hyper-relay installed, and D2 can build on it.

## Decisions (owner, 2026-11-18)

| # | Question | Decision |
|---|---|---|
| E1 | What does E deliver? | **The straight move.** `wt`, its suite and a user reference come into the repo with no behaviour change. A generic `wt preview`, a merge helper, and `wt new` at the handoff are D2's to design (card `68fab05e-4083-41bf-820f-8c201a951c50`), when the orchestrator's needs are known. |
| E2 | How does the owner's shell reach `wt`? | **`~/.local/bin/wt` points at the main checkout's `~/hyper-relay/bin/wt`,** as OpenCode reads `~/hyper-relay/skills`. The path survives version bumps and there is one copy on the machine. During a hyper-relay branch run, the shell runs that branch's `wt`, as OpenCode reads its skills. |
| E3 | `wt`'s history | **Copy, and cite it.** One commit adds the files; its message names the four home-repo commits (`30c7fa2`, `3100b02`, `de70253`, `8f1f556`), which stay there as the record. Nothing from the home repo reaches the public repo but the code. |
| E4 | The repo is public | **Nothing names another project.** `docs/wt.md` is written fresh from the Quartz-repo spec without Quartz's or SAT's internals, and the suite's two fixtures and the names it quotes are made generic (§3). |
| E5 | Sequencing with D1 | Both edit `README.md` and `CLAUDE.md`, on different lines. E's plan runs after D1 merges, or in a worktree beside D1's branch run, asked at E's handoff. |

## 1. What changes where

| Where | Change |
|---|---|
| `bin/wt` | New: `~/.claude/bin/wt`, with two edits (§2). |
| `tests/wt/run-tests.sh`, `tests/wt/fixtures/` | New: `~/.claude/tests/wt/`, with its names made generic (§3). |
| `docs/wt.md` | New: the user's reference (§4). |
| `README.md`, `CLAUDE.md` | Say the repo ships `wt` (§5). |
| `~/.local/bin/wt`, the home repo, the Quartz repo's `wt` spec | After the merge, with the owner (§6.3). |

Every skill and template is unchanged: they already call `wt` by name.

## 2. `bin/wt`

A copy of `~/.claude/bin/wt` (444 lines, POSIX shell run by dash), executable, with exactly two edits:

1. **The header's design pointer** (lines 3–4, "Design: docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md
   in the Quartz repo.") names `docs/wt.md` in hyper-relay instead. These are the only lines of the tool that name
   another project.
2. **The missing-`.wt.conf` error** (line 64, "see the wt design spec for what to put in it") says "see hyper-relay's
   docs/wt.md for what to put in it", which a public user can find.

If the suite asserts either text, its assertion changes with it and says so in the plan.

## 3. `tests/wt/`

A copy of `~/.claude/tests/wt/`. `run-tests.sh` finds the tool at `$HERE/../../bin/wt`, which resolves to `bin/wt` in
this layout too, so its lookup is unchanged. Its baseline on 2026-11-18 is `118 passed, 0 failed`.

**Generic names.** The fixtures are snapshots of two projects' compose services: `quartz.json` and `sat.json`, quoted
by 23 lines of `run-tests.sh`. Their service names are already generic (`api`, `web`, `db`, `redis`, `seed`, …); what
identifies the projects is the fixture names, the project names the suite passes (`new_case quartz …`) and the image
prefixes (`quartz-api:local`, `sat-web:local`). Those are renamed for the case each fixture exercises:

- `quartz.json` → **`app.json`** (host-bound ports, a seed profile), project name `app`, images `app-*`;
- `sat.json` → **`pinned-net.json`** (a pinned subnet and fixed addresses), project name `pinned`, images `pinned-*`.

Service names and public images (`postgres:16`, `redis:7`, `mailhog/mailhog`) stay. **Only names change:** each
assertion still checks what it checked (`quartz-api:wt-feat-add-thing` becomes `app-api:wt-feat-add-thing`), the
fixtures keep their shapes (ports, `host_ip`, profiles, subnets, fixed addresses), and the count stays 118.

## 4. `docs/wt.md`

The user's reference, written from the Quartz-repo spec (`~/quartz/docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md`)
and the tool itself, naming no other project:

- what `wt` is for, and why a worktree cannot simply run the project's own compose stack (shared container names,
  image tags, ports, `.env`, values that depend on ports);
- requirements: dash, Docker Compose 2.24 or later (`!override`), `jq`, `ss`;
- the commands: `wt new <branch> [--from <base>]`, `wt up`, `wt ls`, `wt down [name]`;
- what `wt up` does, step by step (refuse a main checkout, name the stack, take a slot, `.env`, `WT_SETUP` once, read
  the compose file, allocate ports, apply `WT_ENV`, write the override, build and start, seed once, print URLs);
- `.wt.conf`: every key `wt` reads (`WT_ENV_BASE`, `WT_ENV` and its `{service}` / `{ip:service}` placeholders,
  `WT_SEED_PROFILE`, `WT_SETUP`, `WT_NEW_SETUP`), the rule that a `WT_ENV` key missing from the base file is an
  error, and one generic example;
- where state lives (`~/.local/state/wt/<stack>/`, `WT_STATE_DIR`), the limit (`WT_MAX_STACKS`, default 3) and the
  wait (`WT_WAIT_SECONDS`);
- the safety rules: refuses a main checkout; `.env` comes from `.env.example`, never the real `.env`; seed data only.

## 5. `README.md` and `CLAUDE.md`

- **README:** the roadmap's E row becomes `on \`main\``. A `### wt` subsection under Install says Claude Code's Bash
  tool finds `wt` once the plugin is installed; for your own shell (or a Makefile that calls `wt`), symlink `bin/wt`
  from a clone into a directory on your `PATH`; it links `docs/wt.md` for `.wt.conf`.
- **`CLAUDE.md`:** its Layout names `bin/wt`, `tests/wt/` and `docs/wt.md`; its Checks table gains a `wt` row,
  `sh tests/wt/run-tests.sh`, expecting `0 failed`. `dash -n bin/wt` falls under the existing shell-syntax row.

## 6. Testing and acceptance

### 6.1 The executor's gates

- `sh tests/wt/run-tests.sh`: `118 passed, 0 failed`.
- `dash -n bin/wt` is silent, and `test -x bin/wt` succeeds.
- `diff ~/.claude/bin/wt bin/wt` shows only §2's two edits.
- `git grep -n -i -w -E 'sat|quartz' -- bin/wt tests/wt docs/wt.md` finds nothing.
- `claude plugin validate .` passes with its known warnings.
- The commit that adds `bin/wt` and `tests/wt/` names the four home-repo commits.

### 6.2 `reviewer` steps, before the merge

Rerun §6.1. Check that `docs/wt.md` documents exactly the keys `wt` reads (`load_config`'s `unset` line, and
`WT_NEW_SETUP` in `wt new`), and that README's link to `docs/wt.md` resolves.

### 6.3 `after merge` steps, the orchestrator with the owner

1. Push `main`; the owner reinstalls (`/plugin install hyper-relay@hyper-relay`, checked in the cache, not the
   message), so the plugin's `bin/wt` reaches Claude's Bash tool. The version stays 0.1.0.
2. **The owner repoints the symlink** (it is the owner's shell setup): `ln -sfn ~/hyper-relay/bin/wt ~/.local/bin/wt`.
   PASS: `readlink ~/.local/bin/wt` prints the absolute path of `~/hyper-relay/bin/wt`; `wt ls` exits 0 from SAT's main
   checkout; `sh tests/wt/run-tests.sh` passes from `~/hyper-relay`.
3. **Retire the home repo's copy, only after step 2** (before it, the symlink would dangle). One home-repo commit,
   staged by path: `git rm` `.claude/bin/wt` and `.claude/tests/wt/`, and the home `CLAUDE.md`'s two `wt` rows go.
   PASS: `git -C ~ ls-files | grep -w wt` prints nothing.
4. **The Quartz repo's `wt` spec** gains one line under its title: `wt` now lives in hyper-relay (`bin/wt`,
   `docs/wt.md`). The orchestrator shows the line to the owner first, then commits it there by its path.
5. Update this repo's handoff memory.

No step starts a live session or real Docker: the suite runs on its fake docker.

## 7. External facts (checked 2026-11-18)

- **Claude Code puts the plugin's `bin/` on the Bash tool's PATH:** this session's PATH holds
  `~/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/bin`, and `command -v hyper-relay-agents` resolves there. The
  path carries the version, so it changes with each release.
- **`~/.local/bin` comes first on PATH**, in the owner's shell and in the Bash tool, so `~/.local/bin/wt` wins over the
  plugin's copy. It is a symlink to `~/.claude/bin/wt` today.
- **The home repo has no remote** (`git -C ~ remote -v` prints nothing): `wt`'s history exists only on this machine.
- **The suite** (`sh ~/.claude/tests/wt/run-tests.sh`) prints `118 passed, 0 failed`; it reads `WT_BIN`, default
  `$HERE/../../bin/wt`.
- **Other projects' names in `wt`:** only lines 3–4 of the tool; 23 lines of the suite; both fixtures' names and
  image prefixes. The fixtures' service names are generic.
- **`wt`'s users:** SAT and Quartz each commit a `.wt.conf`; SAT's `make preview` (`scripts/preview-branches.sh`) and
  its `CLAUDE.md` call `wt` by name, as do Quartz's `CLAUDE.md` and hyper-relay's `dispatching.md`.

## 8. Out of scope

A generic `wt preview` or merge helper, and using `wt new` at the handoff (D2); any change to what `wt` does; SAT's
`preview-branches.sh` and `merge-branches.sh`; `ccs`, which stays in the home repo; a wrapper that finds the newest
plugin cache.

## 9. Plans

One plan, `docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md`, on the branch `hyper-relay-e-wt`. §6.3 is its last
task, run by the orchestrator with the owner after the merge.
