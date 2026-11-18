# hyper-relay E: `wt` moves into hyper-relay Implementation Plan

**Card:** Move wt into hyper-relay (`81c5c257-4ce9-40ee-8dac-c2b6cb84907e`)
**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-e-wt-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–3 are
> the executor's. Task 4 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `owner` and
> `after merge` steps the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `wt` (a disposable Docker Compose stack for each git worktree) into the plugin as `bin/wt`, with its
suite in `tests/wt/` and a user reference in `docs/wt.md`, with no change to what `wt` does.

**Architecture:** One commit copies the tool and its suite from the home repo, with the tool's two pointers at the
Quartz-repo spec re-aimed at `docs/wt.md` and the suite's project-specific names made generic, and cites the four
home-repo commits that hold its history. A second adds `docs/wt.md`, written fresh from the tool and the Quartz-repo
spec. A third makes `README.md` and `CLAUDE.md` say the repo ships `wt`. After the merge, the owner's
`~/.local/bin/wt` points at the main checkout's `bin/wt`, the home repo's copy goes, and the Quartz-repo spec gains a
pointer.

**Tech Stack:** POSIX `sh` run by dash; `jq`; git; Docker Compose (faked in the suite); Markdown.

**How this was checked:** written against `main` at `0f8c700` by reading only; nothing was copied, built, run or
installed. Read in this repo: `CLAUDE.md`, the E spec and the D1 spec (all in full: D1's §7 for this plan's format,
its §8 for the README and `CLAUDE.md` lines D1's plan edits); plan C
(`docs/superpowers/plans/2026-11-17-hyper-relay-c-executing-plans.md`, lines 1–991 and 1447–1776, for format);
`README.md`, `.gitignore`, `.gitattributes`, `.hyper-relay/agents.md`, `.git/config` (the `origin` remote) and the
generated `.claude/agents/relay-reviewer.md` (its hard rules shape the `reviewer` steps), all in full;
D1's plan as committed in `f10be85` (`git grep` of its `README.md` and `CLAUDE.md` lines, and its Task 9, lines
1366–1435, which hold all its edits to both); `git ls-files` of `docs/superpowers/`, `bin/`, `tests/add-card-line/`
and `docs/testing.md`; `git grep` for `wt` in
`skills/`, `templates/`, `hooks/`, `.hyper-relay/`, `README.md` and `CLAUDE.md` (only `dispatching.md` names it, by
name) and for test runners (none globs `tests/*`). Read outside the repo: `~/.claude/bin/wt` (444 lines),
`~/.claude/tests/wt/run-tests.sh` and all six fixtures (in full); in the home repo, `git log` of `wt`'s paths (the
four commits), `git ls-files -s .claude/bin/wt` (`100755`), `git ls-files`, `git status --short` (`wt`'s files clean;
`CLAUDE.md` untracked; `.gitignore` modified by the owner), `.git/config` (no remote) and `CLAUDE.md` lines 1–25;
`git grep --no-index` of the owner's shell and Claude config for the old paths (none); the Quartz-repo spec (in full),
Quartz's `CLAUDE.md` (lines 1–15: it calls `wt` by name only) and that spec's git state (tracked, clean, Quartz on
`main`). Not re-verified here: `~/.local/bin/wt`'s current target and the PATH order of spec §7 (the planner's guard
refuses `readlink`); Task 4 Step 14 checks both.

**External facts (re-verified 2026-11-18):**
- Claude Code plugins reference, [code.claude.com/docs/en/plugins-reference](https://code.claude.com/docs/en/plugins-reference),
  "Standard layout": "Executables | `bin/` | Files here are on the Bash tool's `PATH` while the plugin is enabled, so
  Claude runs them as bare commands." As spec §7 says. The same row says claude.ai and Cowork don't install a plugin
  that has `bin/`; that is already so with `bin/hyper-relay-agents`, so E changes nothing there.
- Docker Compose's `!override` tag: "requires: Docker Compose 2.24.4 and later" (Docker docs' data file
  [data/summary.yaml](https://raw.githubusercontent.com/docker/docs/main/data/summary.yaml), entry "Compose replace
  file", shown under "Replace value" on [docs.docker.com/reference/compose-file/merge/](https://docs.docker.com/reference/compose-file/merge/)).
  **The spec (§4) says 2.24: `docs/wt.md` and the README say 2.24.4** (D4).

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top unless they start with `~`.
- **The sources outside your checkout are read-only.** You may READ `~/.claude/bin/wt` and `~/.claude/tests/wt/` to
  copy them (Task 1) and to compare against them. Never write, move or delete anything there, or anywhere outside
  your checkout.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md#<N>` followed, inside the same quoted
  paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and `Claude-Session:`
  with the URL from your dispatch prompt). The commands below write them as `<the line your instructions give>` and
  `<the URL your dispatch prompt gives>`: put the real lines there. Never tick the plan. Report every `quartz:` line a
  commit prints, verbatim.
- **Task 1 is one commit** (spec E3): `bin/wt` and all of `tests/wt/` arrive together, already edited, so the public
  history never holds the home copy's project names.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly; "replace every X" means
  `replace_all`. If X is not found, read the range again; if the text moved or differs slightly, adapt as little as
  possible and record it as a deviation; if it is gone, stop and report. Text in code blocks is exact: transcribe it.
- **`main` may have moved.** D1's plan edits other lines of `README.md` (the relay table, a line under it, the
  status blockquote, the D1 roadmap row) and of `CLAUDE.md` (the skill count). This plan's anchors avoid those lines.
  If D1 merged before your branch was cut, your copy already has its changes; the anchors still hold.
- **This repo is public.** Nothing you write into `bin/wt`, `tests/wt/`, `docs/wt.md`, `README.md`, `CLAUDE.md` or a
  commit message names SAT or Quartz (beyond what `README.md` and `CLAUDE.md` already say about the Quartz board), or
  quotes any project's `.wt.conf`.
- **Never** run a real `wt` or `docker` command (the suite runs `wt` on its own fake `docker` and `ss`, which is
  fine), start a live `claude -p` / `opencode run` session, install a plugin, push, tag, or create anything on
  GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites (`tests/claude-code/`,
  `tests/explicit-skill-requests/`, `tests/skill-triggering/`).
- **Outside your branch is not yours.** Never touch `main`, `~/.local/bin/wt`, the home repo (`~`), the Quartz repo,
  SAT's repo, `~/.claude/` (beyond reading the two sources above) or `~/.config/opencode/`. Task 4's `owner` and
  `after merge` steps do those, and they are not yours.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Each task runs its targeted check only; pipe the suite through `tail` or `grep`. The full gates
  run once, in Task 3: the `wt` suite (the only suite this plan touches, per the Checks table in `CLAUDE.md`),
  `dash -n` of both scripts, and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 4. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`owner`** (at the click-through) or **`after merge`** (the owner and the orchestrator), with its command or action
  and the result that counts as PASS. After Task 3, copy Task 4's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| D1 | §3: the renamed fixtures' "project name `app`" and "project name `pinned`" | `run-tests.sh`'s `new_case` uses its first argument only as the fixture's base name (`FAKE_CONFIG="$FIXTURES/$1.json"`); the project directory is always `$CASE_DIR/myproj`, so every stack name stays `myproj-wt-…` and no assertion quotes a project name. The suite therefore passes `new_case app …` and `new_case pinned-net …` (the fixture file names). The image prefixes become `app-` and `pinned-`, as the spec says, and give the image names the renamed assertions quote (`app-api:wt-feat-add-thing`, `app-api:wt-feat-one`). The "real project name" that `wt down` must refuse becomes `app`, and its unknown stack `app-wt-missing` (still a valid stack name, still with no state). |
| D2 | §3, §7: 23 lines of `run-tests.sh` name the projects | 23 by `git grep -i -w`, but the variable `QUARTZ_CONF` (its definition and 11 uses) names Quartz too, and `-w` misses it because `_` is a word character. It becomes `APP_CONF`, so 35 lines change. Task 3 and Task 4 add a gate without `-w` (`git grep -i quartz`). The section headers `--- up on Quartz` and `--- SAT shape` become `--- up on app` and `--- pinned-net shape`, and the check `SAT shape succeeds` becomes `pinned-net shape succeeds`: names only. The count stays 118. **Owner: confirmed 2026-11-18.** |
| D3 | §2: "If the suite asserts either text, its assertion changes with it" | It asserts neither: the only related check, `up needs .wt.conf: message`, looks for `.wt.conf`, which the new error still contains. No assertion changes for §2. The new header stays two lines, so the tool stays 444 lines and the error stays on line 64. |
| D4 | §4: "Docker Compose 2.24 or later (`!override`)" | 2.24.4 or later, per Docker's docs (header). `docs/wt.md` and the README say 2.24.4. |
| D5 | §5: `CLAUDE.md`'s Layout names `bin/wt`, `tests/wt/` and `docs/wt.md`, and its Checks table gains a `wt` row | Done, and one more bullet under "How a change reaches the owner", beside the OpenCode one: the owner's `wt` is a symlink to this main checkout's `bin/wt`, so a branch run changes the `wt` the owner's shell runs (E2's consequence). **Owner: confirmed 2026-11-18.** |
| D6 | §6.3 step 3: one home-repo commit, with the home `CLAUDE.md`'s two `wt` rows | The home `CLAUDE.md` is untracked (`git -C ~ status` shows `?? CLAUDE.md`). The commit holds only the two `git rm` paths; the two rows go by an edit that is not committed. The home `.gitignore` carries an uncommitted change of the owner's; the path-limited commit leaves it alone. |
| D7 | §6.3 step 4: one line under the Quartz-repo spec's title | Exact text in Task 4 Step 16: one blockquote line, with a blank line after it so it stays its own paragraph. **Owner: confirmed 2026-11-18.** |
| D8 | §6.3 step 2: `sh tests/wt/run-tests.sh` passes from `~/hyper-relay` | It runs with `WT_BIN=$HOME/.local/bin/wt`, so it also proves the symlink works. Before the merge, reviewer Step 2 does the same through a symlink in its evidence folder. |
| D9 | §6.2: README's link to `docs/wt.md` resolves | `docs/wt.md` also links back to the README's `### wt` section (`../README.md#wt`); Task 4 Step 8 checks both. |
| D10 | §6.1: `git grep … -- bin/wt tests/wt docs/wt.md` finds nothing | `git grep` reads tracked files only, so Tasks 1 and 2 check with `git grep --untracked` before their commits; Task 3 and Task 4 run it as written. |
| D11 | §6.3 step 2: `wt ls` exits 0 "from SAT's main checkout" | This plan is public, so it does not print SAT's path; the orchestrator runs the command there. |
| D12 | §6.3 step 1: the owner reinstalls with `/plugin install hyper-relay@hyper-relay` | As written (in a session). `CLAUDE.md` says the shell's `claude plugin install` also refreshes the copy; D1's spec (§11) says it does not. Either way Step 13 checks the cache, not the message. |
| D13 | E5: E runs after D1 merges, or in a worktree beside D1's run | The plan names no mode. Its README anchors are the E roadmap row and the end of the Install section; its `CLAUDE.md` anchors the Layout's `.hyper-relay/agents.md` and tests bullets, the OpenCode bullet and the Checks table's visual-companion row. D1's committed plan (`f10be85`, Task 9) edits README's status blockquote, the relay table's Plan, Review and Finish rows with a new line under the table, and the D1 row, and `CLAUDE.md`'s skill count: none of E's lines, and not the D2 row that sits between the D1 and E rows, so the two branches should merge cleanly in either order. Task 4 Step 12 checks the merge before it happens. **Owner: decided 2026-11-18:** E runs in a worktree, beside D1's branch run in the main checkout. |
| D14 | Card line | Included, from the spec. |
| D15 | §4: "one generic example" `.wt.conf` | Written fresh, with keys no project here uses (`PUBLIC_API_URL`, `ALLOWED_ORIGIN`) and a `WT_NEW_SETUP` of `npm ci`. It quotes no project's file. |
| D16 | §4's list for `docs/wt.md` | Covered in full. It also says `wt` needs Linux (`ss` is iproute2's) and which compose file names `wt` looks for, and carries a failures table taken from the Quartz-repo spec's "Failure handling", re-checked against the tool (a failed `WT_SETUP` starts nothing, unlike a failed build or seed, which leaves the stack up). |
| D17 | §5: README says the repo ships `wt` (the E row, the `### wt` subsection) | D1's plan (`f10be85`, Task 9 Step 1) rewrites README's status blockquote to list "a disposable stack per worktree" as still to come. This plan leaves that line alone (D1 edits it), so once both are on `main` it is stale. Task 4 Step 18 fixes it on `main`, after both have merged. **Owner: confirmed 2026-11-18.** |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1, 2, 3 |
| Decisions (owner, 2026-11-18) | E1: 1 (Step 7 proves the tool's diff is §2's two edits), 2, 3. E2: 3 (README, `CLAUDE.md`), 4 (Step 14). E3: 1 (Step 8's message), 4 (Steps 6, 15). E4: 1 (Steps 3, 5), 2, 4 (Step 5). E5: Execution notes, 4 (Step 12) |
| 1. What changes where | 1, 2, 3, 4 |
| 2. `bin/wt` | 1 |
| 3. `tests/wt/` | 1 |
| 4. `docs/wt.md` | 2 |
| 5. `README.md` and `CLAUDE.md` | 3; 4 (Step 18, the status line once D1 is in) |
| 6. Testing and acceptance | 6.1: 1, 3. 6.2: 4 (Steps 1–10). 6.3: 4 (Steps 13–18) |
| 7. External facts (checked 2026-11-18) | header (re-verified), 1 (the suite's baseline), 4 (Steps 13, 14) |
| 8. Out of scope | 1 (Step 7: nothing in what `wt` does changes), Execution notes |
| 9. Plans | this plan; 4 (its §6.3 steps, after the merge) |

## File structure

- **Create (Task 1):** `bin/wt` (mode 755), `tests/wt/run-tests.sh`, `tests/wt/fixtures/app.json`,
  `tests/wt/fixtures/pinned-net.json`, `tests/wt/fixtures/ps-ok.json`, `tests/wt/fixtures/ps-seed-failed.json`,
  `tests/wt/fixtures/ps-seed-running.json`, `tests/wt/fixtures/ps-starting.json`.
- **Create (Task 2):** `docs/wt.md`.
- **Modify (Task 3):** `README.md`, `CLAUDE.md`.
- **Task 4, outside the branch (owner and orchestrator):** the installed plugin; `~/.local/bin/wt`; the home repo's
  `.claude/bin/wt`, `.claude/tests/wt/` and its untracked `~/CLAUDE.md`; the Quartz repo's
  `docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md`; this repo's handoff memory.

---

### Task 1: `bin/wt` and `tests/wt/` come in, with generic names (spec §2, §3; E1, E3, E4; D1–D3, D10)

**Files:**
- Create: `bin/wt`, `tests/wt/run-tests.sh`, `tests/wt/fixtures/app.json`, `tests/wt/fixtures/pinned-net.json`,
  `tests/wt/fixtures/ps-ok.json`, `tests/wt/fixtures/ps-seed-failed.json`, `tests/wt/fixtures/ps-seed-running.json`,
  `tests/wt/fixtures/ps-starting.json`

- [x] **Step 1: The sources are the ones this plan read.**

| Run | Expected |
|---|---|
| `git -C ~ status --short -- .claude/bin/wt .claude/tests/wt` | nothing |
| `git -C ~ log -1 --format=%h -- .claude/bin/wt .claude/tests/wt` | `8f1f556` |
| `wc -l < ~/.claude/bin/wt` | `444` |

If any differs, stop and report: the tool changed after this plan was written.

- [x] **Step 2: Copy the tool, the suite and the four `ps-*` fixtures.**

```bash
mkdir -p tests/wt/fixtures
cp ~/.claude/bin/wt bin/wt
chmod 755 bin/wt
cp ~/.claude/tests/wt/run-tests.sh tests/wt/run-tests.sh
cp ~/.claude/tests/wt/fixtures/ps-ok.json ~/.claude/tests/wt/fixtures/ps-seed-failed.json ~/.claude/tests/wt/fixtures/ps-seed-running.json ~/.claude/tests/wt/fixtures/ps-starting.json tests/wt/fixtures/
```

The two compose fixtures come in Step 5, under their new names. `run-tests.sh` finds the tool at
`$HERE/../../bin/wt`, which is `bin/wt` here too: its lookup does not change.

- [x] **Step 3: The suite's names become generic (35 lines; D1, D2).** Ten edits to `tests/wt/run-tests.sh`.

(a) Replace:
```text
QUARTZ_CONF="WT_SEED_PROFILE=seed
```
with:
```text
APP_CONF="WT_SEED_PROFILE=seed
```

(b) Replace every `"$QUARTZ_CONF` (11 occurrences) with `"$APP_CONF`.

(c) Replace every `new_case quartz ` (15 occurrences, one of them indented inside `new_repo`; note the trailing space)
with `new_case app `.

(d) Replace:
```text
run_wt "$WT" down quartz
assert_eq "down refuses a real project name" 1 "$RC"
```
with:
```text
run_wt "$WT" down app
assert_eq "down refuses a real project name" 1 "$RC"
```

(e) Replace:
```text
run_wt "$WT" down quartz-wt-missing
```
with:
```text
run_wt "$WT" down app-wt-missing
```

(f) Replace:
```text
echo '--- up on Quartz'
```
with:
```text
echo '--- up on app'
```

(g) Replace:
```text
assert_contains "api gets its own image tag" 'image: quartz-api:wt-feat-add-thing' "$OV"
```
with:
```text
assert_contains "api gets its own image tag" 'image: app-api:wt-feat-add-thing' "$OV"
```

(h) Replace:
```text
echo '--- SAT shape'
new_case sat feat/one
```
with:
```text
echo '--- pinned-net shape'
new_case pinned-net feat/one
```

(i) Replace:
```text
assert_eq "SAT shape succeeds" 0 "$RC"
```
with:
```text
assert_eq "pinned-net shape succeeds" 0 "$RC"
```

(j) Replace:
```text
assert_contains "down removes its own image" "image rm quartz-api:wt-feat-one" "$(cat "$FAKE_LOG")"
```
with:
```text
assert_contains "down removes its own image" "image rm app-api:wt-feat-one" "$(cat "$FAKE_LOG")"
```

Check:

| Run | Expected |
|---|---|
| `git diff --no-index --numstat ~/.claude/tests/wt/run-tests.sh tests/wt/run-tests.sh` | `35	35	…` (35 lines removed, 35 added) |
| `grep -c -i quartz tests/wt/run-tests.sh` | `0` |
| `grep -c -i -w sat tests/wt/run-tests.sh` | `0` |

- [x] **Step 4: Run the suite; it fails.** The suite now asks for `app.json` and `pinned-net.json`, which do not exist
  yet.

Run: `sh tests/wt/run-tests.sh | grep -e '^FAIL' -e 'passed, '`
Expected: a non-zero failed count on the last line, with failures including `FAIL up succeeds` and
`FAIL pinned-net shape succeeds`.

- [x] **Step 5: The two compose fixtures, under their new names.**

```bash
cp ~/.claude/tests/wt/fixtures/quartz.json tests/wt/fixtures/app.json
cp ~/.claude/tests/wt/fixtures/sat.json tests/wt/fixtures/pinned-net.json
```

In `tests/wt/fixtures/app.json`, replace every `"image":"quartz-` (5 occurrences) with `"image":"app-`.

In `tests/wt/fixtures/pinned-net.json`, replace every `"image":"sat-` (7 occurrences) with `"image":"pinned-`.

Nothing else in either file changes: service names, public images, ports, `host_ip`, profiles, the subnet and the
fixed address keep their values (spec §3).

| Run | Expected |
|---|---|
| `git diff --no-index --numstat ~/.claude/tests/wt/fixtures/quartz.json tests/wt/fixtures/app.json` | `5	5	…` |
| `git diff --no-index --numstat ~/.claude/tests/wt/fixtures/sat.json tests/wt/fixtures/pinned-net.json` | `7	7	…` |
| `grep -c -i -e quartz -e '"sat-' tests/wt/fixtures/app.json tests/wt/fixtures/pinned-net.json` | `tests/wt/fixtures/app.json:0` and `tests/wt/fixtures/pinned-net.json:0` |

- [x] **Step 6: Run the suite; it passes.**

Run: `sh tests/wt/run-tests.sh | tail -n 1`
Expected: `118 passed, 0 failed`

- [x] **Step 7: The tool's two edits (spec §2; D3).** In `bin/wt`:

(a) Replace:
```text
# POSIX shell, run by dash. Design: docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md
# in the Quartz repo.
```
with:
```text
# POSIX shell, run by dash. How to use it, and what to put in .wt.conf:
# docs/wt.md in hyper-relay.
```

(b) Replace:
```text
    [ -f "$ROOT/.wt.conf" ] || die "no .wt.conf in $ROOT; see the wt design spec for what to put in it"
```
with:
```text
    [ -f "$ROOT/.wt.conf" ] || die "no .wt.conf in $ROOT; see hyper-relay's docs/wt.md for what to put in it"
```

Check:

| Run | Expected |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent |
| `test -x bin/wt && echo executable` | `executable` |
| `git diff --no-index --numstat ~/.claude/bin/wt bin/wt` | `3	3	…`: lines 3, 4 and 64, nothing else |
| `for f in ps-ok ps-seed-failed ps-seed-running ps-starting; do cmp ~/.claude/tests/wt/fixtures/$f.json tests/wt/fixtures/$f.json; done` | silent |
| `git grep --untracked -n -i -w -E 'sat\|quartz' -- bin/wt tests/wt` | nothing |
| `git grep --untracked -n -i quartz -- bin/wt tests/wt` | nothing |

- [x] **Step 8: Commit, once, citing the four home-repo commits (E3).**

```bash
git add bin/wt tests/wt/run-tests.sh tests/wt/fixtures/app.json tests/wt/fixtures/pinned-net.json tests/wt/fixtures/ps-ok.json tests/wt/fixtures/ps-seed-failed.json tests/wt/fixtures/ps-seed-running.json tests/wt/fixtures/ps-starting.json
git commit -m "feat: wt, a disposable Docker Compose stack for each worktree, moves into hyper-relay" -m "Copied from the home repo's .claude/bin/wt and .claude/tests/wt/, whose history stays there as the record: 30c7fa2 (the suite, with a fake docker), 3100b02 (a disposable stack for each worktree), de70253 (wait for a seed to finish before marking it done) and 8f1f556 (wt new <branch> [--from <base>]). Two edits to the tool: its header and its missing-.wt.conf error point at docs/wt.md. The suite's two compose fixtures and the names it quotes are generic (app.json, pinned-net.json). What wt does is unchanged, and the suite still runs 118 checks." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s bin/wt` must print a line starting `100755`.

### Task 2: `docs/wt.md`, the user's reference (spec §4; E4; D4, D9, D15, D16)

**Files:**
- Create: `docs/wt.md`

- [x] **Step 1: Write `docs/wt.md`** with exactly:

````markdown
# wt: a disposable stack for each worktree

`wt` gives a git worktree a Docker Compose stack of its own: its own containers, network, database, image tags, ports
and seed data. You can start a branch, click through it and throw it away, while your real stack, run from the main
checkout, keeps running untouched.

It ships with hyper-relay as `bin/wt`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `wt` by name. For your own shell, symlink it from a clone (the
[README's Install section](../README.md#wt) shows how).

## Why a worktree can't simply run the project's stack

Making the worktree is quick (`git worktree add`). Running the project's own `docker compose up` from it is the
problem:

- **Container names.** A compose file that pins its project `name:` makes every checkout the same compose project, so
  `up` from a worktree acts on the real containers and the real database.
- **Image tags.** A tag such as `myapp-api:local` is shared: a worktree's build changes what the real stack starts
  from next time.
- **Ports.** The real stack already holds the default host ports.
- **`.env`.** It is gitignored, so a new worktree has none, and compose needs it.
- **Values that depend on ports.** An API URL or an allowed origin in `.env` names a port, and the worktree's ports
  are different.
- **Pinned networks.** A compose file that pins a subnet and fixed addresses clashes with the real stack's network.

`wt` handles each of these in an override file that it writes outside the repo. The project's own compose file does
not change.

## Requirements

- Linux, with a POSIX shell: `wt` is written for dash and runs as `#!/bin/sh`.
- git.
- Docker Compose 2.24.4 or later, for the `!override` YAML tag.
- `jq`, and `ss` (from iproute2).
- A compose file at the project's root (`compose.yaml`, `compose.yml`, `docker-compose.yaml` or
  `docker-compose.yml`), and a committed `.wt.conf` beside it (below).

## Commands

| Command | What it does |
|---|---|
| `wt new <branch> [--from <base>]` | Creates a worktree for `<branch>` under the main checkout. No containers. |
| `wt up` | In a worktree: builds and starts its stack, seeds it the first time, and prints its URLs. |
| `wt ls` | Lists every `wt` stack on this machine. |
| `wt down [name]` | Stops a stack and deletes its containers, database, images and state. |

### `wt new`

`wt new feat/add-login` creates the worktree `.worktrees/add-login` under the main checkout, wherever you run it from:
the folder is the branch with everything up to its first `/` dropped and any later `/` turned into `-`
(`fix/api/v2` gives `.worktrees/api-v2`). `.worktrees/` must be gitignored, or `wt new` refuses.

- A new branch starts from `<base>`, `main` by default.
- An existing branch is checked out as it is, and `--from` is ignored (`wt new` says so).
- Then it runs `WT_NEW_SETUP` from the new worktree's own `.wt.conf`, inside the new worktree. If that fails, the
  worktree stays, and `wt new` says so.

### What `wt up` does

1. **Refuses a main checkout.** In a worktree, git's directory differs from the repo's common one; in a main checkout
   they are the same. This is the check that keeps your real stack safe.
2. **Names the stack** `<project>-wt-<slug>`. `<project>` is the main checkout's folder name and `<slug>` the branch
   (the worktree's folder name, on a detached HEAD), each lowercased, with every run of other characters turned into
   `-`, and cut to 30 characters. Branch `Feat/Add_Thing` of `~/src/myapp` gives `myapp-wt-feat-add-thing`.
3. **Takes a slot.** A stack keeps the slot it has. A new one takes the lowest free number, and is refused when
   `WT_MAX_STACKS` stacks exist already; the refusal lists them, so you can choose one to `wt down`.
4. **Writes `.env`**, a copy of the `WT_ENV_BASE` file (`.env.example` by default), because compose needs one to read
   its config. A `.env` that `wt` did not create is never overwritten: `wt up` stops and asks you to move it away.
5. **Runs `WT_SETUP` once** per stack, from the worktree's root, and records that it succeeded. A later `wt up` does
   not run it again, so a setup step that generates keys never replaces the ones the running stack uses.
6. **Reads the compose file** with `docker compose config --format json`: its services, published ports, images,
   pinned subnets and fixed addresses.
7. **Allocates ports.** The stack's published ports, in order of service name, get `30000 + slot × 100 + n`, bound to
   `127.0.0.1`. A port something already listens on is skipped. A stack keeps its ports from one `wt up` to the next.
8. **Applies `WT_ENV`** to `.env`, filling in its placeholders.
9. **Writes the override**, in the stack's state folder:
   - `ports: !override` for each service that publishes ports, with the allocated ones;
   - `image: <repo>:wt-<slug>` for each service with both `build` and `image`, so the stack's builds never retag your
     real images;
   - when a network pins a subnet (at most one may), `10.77.<slot>.0/24` instead, with each fixed address on it moved
     into the new subnet, keeping its last number: `192.168.50.10` becomes `10.77.1.10` in slot 1.
10. **Builds and starts** the stack (`docker compose up --build -d`, with the override), then waits until every
    service is running, and healthy where it has a health check, and every one-off service (a migration, say) has
    exited 0. A container that exits non-zero fails `wt up` and is named; so is a wait longer than
    `WT_WAIT_SECONDS`.
11. **Seeds once.** When `WT_SEED_PROFILE` is set, and until a seed has succeeded, `wt up` also runs that compose
    profile and waits for its services to finish. Then it records the seed, so it never runs again over the stack's
    data.
12. **Prints the URLs**: `http://localhost:<port>` for each published port, by service.

Running `wt up` again rebuilds the same stack on the same ports and keeps its database. Each run writes `.env` afresh
from the base file and `WT_ENV` (steps 4 and 8): change those, not `.env`.

### `wt ls` and `wt down`

`wt ls` prints one line per stack: its name, how many of its containers run, its worktree, and then its URLs. A stack
whose worktree is gone is marked stale, with the `wt down <name>` that clears it.

`wt down` without a name acts on the current worktree's stack; with a name, it can clean up a stack whose worktree is
gone. It runs `docker compose down -v --remove-orphans` for the stack (so its database goes, and so do the seed
profile's containers), removes the stack's own `wt-` image tags, removes the `.env` that `wt up` wrote, and deletes
the stack's state.

## `.wt.conf`

Commit a `.wt.conf` at the project's root. `wt` sources it as shell from the root of the worktree it works on, so each
branch reads its own copy. These are the only keys it reads:

| Key | Default | Meaning |
|---|---|---|
| `WT_ENV_BASE` | `.env.example` | The file `.env` is copied from. |
| `WT_ENV` | none | `KEY=VALUE` pairs, separated by spaces or newlines, set in `.env`. A value cannot contain a space. |
| `WT_SEED_PROFILE` | none | The compose profile to run once, on a new stack. |
| `WT_SETUP` | none | A command `wt up` runs once per stack, from the worktree's root, before the build. |
| `WT_NEW_SETUP` | none | A command `wt new` runs in the new worktree, after creating it. |

**Placeholders.** In a `WT_ENV` value, `{web}` is the host port the stack gives the `web` service's first published
port, and `{ip:web}` is the `web` service's fixed address, after its move into the stack's subnet. Any service name
works in place of `web`.

**A `WT_ENV` key that is not in the base file is an error,** and so is an unknown placeholder: `wt up` names it and
stops before it builds anything. Otherwise a typo such as `CORS_ALLOWD_ORIGINS` would add a variable nothing reads,
and the failure would show up much later, as a request the browser blocks.

An example, for a project whose compose file has `api` and `web` services and a `seed` profile:

```sh
# .env starts as a copy of .env.example (the default, so this line could go).
WT_ENV_BASE=.env.example
# Run the seed profile once, on a new stack.
WT_SEED_PROFILE=seed
# In a new worktree: install the dependencies.
WT_NEW_SETUP='npm ci'
# Point the app at this stack's ports. Each key must already be in .env.example.
WT_ENV='PUBLIC_API_URL=http://localhost:{api}
ALLOWED_ORIGIN=http://localhost:{web}'
```

## State and limits

Three environment variables, read when `wt` runs (they are not `.wt.conf` keys):

| Variable | Default | Meaning |
|---|---|---|
| `WT_STATE_DIR` | `~/.local/state/wt` | Where each stack keeps its state, in `<stack>/`: its slot, its worktree's path, its ports, the override, its images, and whether its setup and seed have run. Outside every repo. |
| `WT_MAX_STACKS` | `3` | How many stacks may exist at once. |
| `WT_WAIT_SECONDS` | `300` | How long `wt up` waits for the services to be ready. |

## When something fails

| Failure | What `wt` does |
|---|---|
| No `.wt.conf` | Stops, before touching anything. |
| A bad `WT_ENV` key or placeholder | Stops before building, and names it. |
| The stack limit is reached | Stops, and lists the stacks. |
| The stack's name belongs to another worktree | Stops, and names that worktree. |
| `WT_SETUP` fails | Stops before building, and says so. It runs again on the next `wt up`. |
| The build, a migration or the seed fails | Exits non-zero and gives the logs command. The stack stays up for you to look at. A failed seed is not recorded, so the next `wt up` runs it again; when a half-done seed makes that unsafe, `wt down` then `wt up` starts clean. |
| A port is taken between allocation and start | Says so; the next `wt up` allocates new ports. |
| A worktree is removed while its stack runs | `wt ls` marks the stack stale. `wt` never removes a stack on its own. |

## Safety

- **It refuses a main checkout,** so it never touches the stack you run from there.
- **`.env` comes from the base file, never from your real `.env`,** so a stack holds no real secrets and cannot use
  them to reach a real outside service.
- **Seed data only.** It never copies a real database.
- **Ports bind to `127.0.0.1`.**
- **`wt down` refuses any name that is not a `wt` stack's (`<project>-wt-<slug>`), and any stack it holds no state
  for,** so it cannot act on a real stack. It removes only the stack's own `wt-` image tags, never shared images such
  as `postgres:16`.
````

- [x] **Step 2: Check.**

| Run | Expected |
|---|---|
| `git grep --untracked -n -i -w -E 'sat\|quartz' -- docs/wt.md` | nothing |
| `git grep --untracked -n -i quartz -- docs/wt.md` | nothing |
| `git grep -h -o -E 'WT_[A-Z_]+' -- bin/wt \| sort -u` | eight names: `WT_ENV`, `WT_ENV_BASE`, `WT_MAX_STACKS`, `WT_NEW_SETUP`, `WT_SEED_PROFILE`, `WT_SETUP`, `WT_STATE_DIR`, `WT_WAIT_SECONDS` |
| `git grep --untracked -h -o -E 'WT_[A-Z_]+' -- docs/wt.md \| sort -u` | the same eight names, nothing else |

- [x] **Step 3: Commit.**

```bash
git add docs/wt.md
git commit -m "docs: wt's user reference, docs/wt.md" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

### Task 3: README and `CLAUDE.md` say the repo ships `wt`; the full gates (spec §5, §6.1; E2; D4, D5, D13)

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: `README.md`.** Two edits, on lines D1's plan does not edit.

(a) The Install section gains a `### wt` subsection, after `### voice-to-specs`. Replace:
```text
under WSL.

## Roadmap
```
with:
````text
under WSL.

### wt

`wt` (`bin/wt`) gives each git worktree a disposable Docker Compose stack, so a branch can be clicked through beside
your real stack. Once the plugin is installed, Claude Code's Bash tool finds it by name: a plugin's `bin/` is on that
tool's `PATH`. For your own shell, or a Makefile that calls `wt`, symlink it from a clone into a directory on your
`PATH`:

```sh
ln -sfn /path/to/hyper-relay/bin/wt ~/.local/bin/wt
```

Each project that uses it commits a short `.wt.conf`. [docs/wt.md](docs/wt.md) says what to put in it, what `wt`
needs (dash, Docker Compose 2.24.4 or later, `jq`, `ss`) and what each command does.

## Roadmap
````

(b) The roadmap's E row. Replace:
```text
Each repo adds a short `.wt.conf` | brainstorming |
```
with:
```text
Each repo adds a short `.wt.conf` | on `main` |
```

- [ ] **Step 2: `CLAUDE.md`.** Three edits, none on line 9 (the skill count, which D1's plan edits).

(a) Layout. Replace:
```text
- `.hyper-relay/agents.md`: this repo's own facts, for its `relay-*` agents.
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts. `tests/hyper-relay-agents/` tests the
  generator, its hook and the guard.
```
with:
```text
- `.hyper-relay/agents.md`: this repo's own facts, for its `relay-*` agents.
- `bin/wt`: `wt`, a disposable Docker Compose stack for each git worktree (POSIX shell, run by dash). `docs/wt.md` is
  its user reference. Claude Code puts the plugin's `bin/` on the Bash tool's `PATH`, so skills call it by name.
- `tests/add-card-line/` tests brainstorming's `scripts/add-card-line.sh`. `skills/voice-to-specs/tests/` and
  `skills/visual-companion/scripts/run-tests.sh` test those skills' scripts. `tests/hyper-relay-agents/` tests the
  generator, its hook and the guard. `tests/wt/` tests `wt`, with a fake `docker` and `ss`.
```

(b) How a change reaches the owner (D5). Replace:
```text
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges, and during a branch
  run it sees that branch's skills.
```
with:
```text
- **OpenCode** reads `skills/` in this main checkout, so it sees a change as soon as it merges, and during a branch
  run it sees that branch's skills.
- **`wt`** in the owner's shell is `~/.local/bin/wt`, a symlink to this main checkout's `bin/wt`: a change reaches it
  as soon as it merges, and during a branch run the shell runs that branch's `wt`.
```

(c) Checks. Replace:
```text
| visual-companion | `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, exit 0 |
```
with:
```text
| visual-companion | `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, exit 0 |
| wt | `sh tests/wt/run-tests.sh` | `0 failed` |
```

- [ ] **Step 3: Check the docs.**

| Run | Expected |
|---|---|
| `git grep -n -F '](docs/wt.md)' -- README.md` | one line, in the `### wt` subsection |
| `git grep -n -x -F '### wt' -- README.md` | one line |
| `git grep -n -F '\| brainstorming \|' -- README.md` | nothing |
| `git grep -n -F 'sh tests/wt/run-tests.sh' -- CLAUDE.md` | one line: the Checks row |
| `git diff -- README.md CLAUDE.md \| grep '^+' \| grep -c -i -w -E 'sat\|quartz'` | `0` |

- [ ] **Step 4: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent |
| `git ls-files -s bin/wt` | a line starting `100755` |
| `git diff --no-index --numstat ~/.claude/bin/wt bin/wt` | `3	3	…` |
| `git grep -n -i -w -E 'sat\|quartz' -- bin/wt tests/wt docs/wt.md` | nothing |
| `git grep -n -i quartz -- bin/wt tests/wt docs/wt.md` | nothing |
| `git log --diff-filter=A --format=%h main..HEAD -- bin/wt tests/wt \| wc -l` | `1` (one commit added them) |
| `git log --diff-filter=A --format=%B main..HEAD -- bin/wt tests/wt \| grep -o -E '30c7fa2\|3100b02\|de70253\|8f1f556' \| sort -u \| wc -l` | `4` |
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one, and `ICON_MISSING` if it appears) |

Upstream's live suites are not run (report this): they start real `claude -p` sessions.

- [ ] **Step 5: Commit.**

```bash
git add README.md CLAUDE.md
git commit -m "docs: README and CLAUDE.md say the repo ships wt" -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md#3
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git status --short` must print nothing (on a branch run, nothing but the orchestrator's untracked files under
`docs/superpowers/`). Report, copy Task 4's checklist into the report, and stop: Task 4 is not yours.

### Task 4: Acceptance (spec §6.2, §6.3). NOT the executor's

Each step says who runs it. **`reviewer`** steps (1–10) run before the merge, in the plan's checkout on the branch
`hyper-relay-e-wt`, by the acceptance reviewer, which writes only in its evidence folder. **`owner`** steps (11–12)
run at the click-through. **`after merge`** steps (13–18) are the owner's and the orchestrator's, one command per Bash
call; their commits carry no `Plan-Task:` trailer, so the orchestrator ticks this task by hand when Step 18 is done
(commit just the plan: `docs: plan progress, task 4 of 4`). No step starts a live session or real
Docker: the suite runs on its fake `docker`.

- [ ] **Step 1 (`reviewer`): The suite.**

| Run | PASS |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |

- [ ] **Step 2 (`reviewer`): Through a symlink, as the owner's shell will run it (D8).**

| Run | PASS |
|---|---|
| `ln -s "$(pwd)/bin/wt" <evidence folder>/wt`, then `WT_BIN=<evidence folder>/wt sh tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |

- [ ] **Step 3 (`reviewer`): Syntax and mode.**

| Run | PASS |
|---|---|
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent, exit 0 |
| `test -x bin/wt && echo executable` | `executable` |
| `git ls-files -s bin/wt` | a line starting `100755` |

- [ ] **Step 4 (`reviewer`): Only names changed (spec §2, §3).**

| Run | PASS |
|---|---|
| `git diff --no-index ~/.claude/bin/wt bin/wt` | two hunks only: lines 3–4 become `# POSIX shell, run by dash. How to use it, and what to put in .wt.conf:` and `# docs/wt.md in hyper-relay.`, and line 64's error ends `see hyper-relay's docs/wt.md for what to put in it"` |
| `git diff --no-index --numstat ~/.claude/tests/wt/run-tests.sh tests/wt/run-tests.sh` | `35	35	…`, and every changed line differs only by a rename from D1/D2 of this plan |
| `git diff --no-index ~/.claude/tests/wt/fixtures/quartz.json tests/wt/fixtures/app.json` | 5 changed lines, each changing only an `"image"` prefix to `app-` |
| `git diff --no-index ~/.claude/tests/wt/fixtures/sat.json tests/wt/fixtures/pinned-net.json` | 7 changed lines, each changing only an `"image"` prefix to `pinned-` |
| `for f in ps-ok ps-seed-failed ps-seed-running ps-starting; do cmp ~/.claude/tests/wt/fixtures/$f.json tests/wt/fixtures/$f.json; done` | silent |

- [ ] **Step 5 (`reviewer`): No other project's name (E4).**

| Run | PASS |
|---|---|
| `git grep -n -i -w -E 'sat\|quartz' -- bin/wt tests/wt docs/wt.md` | nothing |
| `git grep -n -i quartz -- bin/wt tests/wt docs/wt.md` | nothing |
| `git log --format=%B main..HEAD \| grep -c -i -w -E 'sat\|quartz'` | `0` |
| `git diff main...HEAD -- README.md CLAUDE.md \| grep '^+' \| grep -c -i -w -E 'sat\|quartz'` | `0` |

- [ ] **Step 6 (`reviewer`): One commit adds the files and cites the history (E3).**

| Run | PASS |
|---|---|
| `git log --diff-filter=A --format=%h main..HEAD -- bin/wt tests/wt` | exactly one hash |
| `git log --diff-filter=A --format=%B main..HEAD -- bin/wt tests/wt` | names `30c7fa2`, `3100b02`, `de70253` and `8f1f556` |

- [ ] **Step 7 (`reviewer`): `docs/wt.md` documents exactly the keys `wt` reads (spec §6.2).**

| Run | PASS |
|---|---|
| `git grep -n -e 'unset WT_ENV' -e 'unset WT_NEW_SETUP' -- bin/wt` | two lines: `unset WT_ENV WT_ENV_BASE WT_SEED_PROFILE WT_SETUP` (in `load_config`) and `unset WT_NEW_SETUP` (in `cmd_new`) |
| Read the `.wt.conf` table in `docs/wt.md` | exactly five rows: those five keys, no other |
| `git grep -h -o -E 'WT_[A-Z_]+' -- bin/wt \| sort -u`, then `git grep -h -o -E 'WT_[A-Z_]+' -- docs/wt.md \| sort -u` | the same eight names from each |

- [ ] **Step 8 (`reviewer`): The links resolve (spec §6.2; D9).**

| Run | PASS |
|---|---|
| `git grep -n -F '](docs/wt.md)' -- README.md`, then `test -f docs/wt.md && echo found` | one line, then `found` |
| `git grep -n -F '](../README.md#wt)' -- docs/wt.md`, then `git grep -n -x -F '### wt' -- README.md` | one line each |

- [ ] **Step 9 (`reviewer`): README and `CLAUDE.md` say the repo ships `wt` (spec §5).**

| Run | PASS |
|---|---|
| ``git grep -n -F 'Each repo adds a short `.wt.conf` \| on `main` \|' -- README.md`` | one line: the roadmap's E row |
| `git grep -n -F -e 'bin/wt' -e 'tests/wt/' -e 'docs/wt.md' -- CLAUDE.md` | the Layout names all three, and the Checks table has the row ``\| wt \| `sh tests/wt/run-tests.sh` \| `0 failed` \|`` |

- [ ] **Step 10 (`reviewer`): The manifests.**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes; its only warnings are the root `CLAUDE.md` one and, if it appears, `ICON_MISSING` |

- [ ] **Step 11 (`owner`): Read what users will read.** `git show hyper-relay-e-wt:docs/wt.md`, and the README's
  `### wt` subsection (`git show hyper-relay-e-wt:README.md`). PASS: the owner agrees they describe `wt` as it works,
  and name no other project.

- [ ] **Step 12 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly (D13).**

| Run | PASS |
|---|---|
| `git -C ~/hyper-relay merge-tree --write-tree main hyper-relay-e-wt` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner, and in the merge keep both sides' lines (E's: the E row, the
`### wt` subsection, the Layout, "How a change reaches the owner" and Checks lines; D1's: everything else).

- [ ] **Step 13 (`after merge`): Push, then the owner reinstalls.** Precondition: the owner has merged
  `hyper-relay-e-wt` into `main`, and the main checkout is on `main`. The version stays 0.1.0.

```bash
git -C ~/hyper-relay push origin main
```

Then the owner, in a Claude Code session: `/plugin install hyper-relay@hyper-relay`.

| Run | PASS |
|---|---|
| `git -C ~/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD`, then `git -C ~/hyper-relay rev-parse main` | the same SHA |
| `test -x ~/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/bin/wt && echo plugin-wt` | `plugin-wt` |

If either fails, stop and tell the owner; do not delete or uninstall anything.

- [ ] **Step 14 (`after merge`; the owner runs the `ln`, which is the owner's shell setup): Repoint the symlink.**

First, `readlink ~/.local/bin/wt` must print `/home/noob_master/.claude/bin/wt`; if it prints anything else, stop and
ask the owner. Then the owner runs:

```bash
ln -sfn ~/hyper-relay/bin/wt ~/.local/bin/wt
```

| Run | PASS |
|---|---|
| `readlink ~/.local/bin/wt` | `/home/noob_master/hyper-relay/bin/wt` |
| `command -v wt` | `/home/noob_master/.local/bin/wt` |
| `wt ls`, run in SAT's main checkout | exit 0 (it lists the stacks, or prints `no wt stacks`) |
| `WT_BIN=$HOME/.local/bin/wt sh ~/hyper-relay/tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |

- [ ] **Step 15 (`after merge`; only once Step 14 passes, or the symlink would dangle): Retire the home repo's copy
  (D6).** The home repo's own rules apply: stage named paths only, never `git add -A`.

| Run | PASS |
|---|---|
| `git -C ~ branch --show-current` | `main` |
| `git -C ~ diff --cached --name-only` | nothing (else stop and ask the owner) |
| `git -C ~ status --short -- .claude/bin/wt .claude/tests/wt` | nothing |
| `git -C ~ status --short -- .gitignore CLAUDE.md` | note it: the baseline for the last row below |

```bash
git -C ~ rm -r -q -- .claude/bin/wt .claude/tests/wt
git -C ~ commit -m "chore: wt moved to hyper-relay" -m "wt now lives in hyper-relay (bin/wt, tests/wt/, docs/wt.md), and ~/.local/bin/wt points at the hyper-relay checkout. Its history stays here: 30c7fa2, 3100b02, de70253, 8f1f556." -m "<the committing session's attribution lines>" -- .claude/bin/wt .claude/tests/wt
```

Then, in `~/CLAUDE.md` (untracked, so not committed), with the Edit tool, replace:
```text
| `.claude/tests/ccs/` | its test suite and benchmark |
| `.claude/bin/wt` | a disposable Docker Compose stack for each worktree |
| `.claude/tests/wt/` | its test suite |
```
with:
```text
| `.claude/tests/ccs/` | its test suite and benchmark |
```

| Run | PASS |
|---|---|
| `git -C ~ ls-files \| grep -w wt` | nothing |
| `git -C ~ show --stat --format=%s HEAD` | `chore: wt moved to hyper-relay`, deleting `.claude/bin/wt` and the 7 files under `.claude/tests/wt/`, nothing else |
| `git -C ~ grep --no-index -n -w wt -- CLAUDE.md` | nothing |
| `readlink -e ~/.local/bin/wt` | `/home/noob_master/hyper-relay/bin/wt` (the symlink resolves) |
| `git -C ~ status --short -- .gitignore CLAUDE.md` | the same as the baseline: the owner's `.gitignore` change untouched, `CLAUDE.md` still untracked |

- [ ] **Step 16 (`after merge`): The Quartz-repo spec points at hyper-relay (D7).** The owner confirmed the line
  below on 2026-11-18. Quartz's own rules apply.

| Run | PASS |
|---|---|
| `git -C ~/quartz branch --show-current` | `main` |
| `git -C ~/quartz diff --cached --name-only` | nothing (else stop and ask the owner) |
| `git -C ~/quartz status --short -- docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md` | nothing |

In `~/quartz/docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md`, with the Edit tool, replace:
```text
# wt: a disposable stack for each worktree

**Status:** design approved in chat, 2026-11-03. Spec awaiting review.
```
with:
```text
# wt: a disposable stack for each worktree

> **Moved, 2026-11-18:** `wt` now lives in hyper-relay (`bin/wt`, `docs/wt.md`). This spec stays as its design record.

**Status:** design approved in chat, 2026-11-03. Spec awaiting review.
```

```bash
git -C ~/quartz add docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md
git -C ~/quartz commit -m "docs: the wt spec points at hyper-relay, where wt now lives" -m "<the committing session's attribution lines>" -- docs/superpowers/specs/2026-11-03-wt-worktree-stacks-design.md
```

| Run | PASS |
|---|---|
| `git -C ~/quartz show --stat --format=%s HEAD` | that subject, one file, 2 insertions |

Act on any `quartz:` line the commit prints. Pushing Quartz follows its usual flow (the owner's call).

- [ ] **Step 17 (`after merge`): The handoff memory.** Update this repo's handoff memory (in
  `~/.claude/projects/-home-noob-master-hyper-relay/memory/`): E is merged; `wt` lives in `bin/wt`; `~/.local/bin/wt`
  points at the main checkout's copy; the home repo's copy is retired; and, if D1 is not merged yet, Step 18 waits for
  it. PASS: the memory says so.

- [ ] **Step 18 (`after merge`; once both D1 and E are on `main`, so after whichever merges second): README's status
  line (D17).** Precondition: the main checkout is on `main` (no branch run active), and
  `git -C ~/hyper-relay status --short -- README.md` prints nothing.

| Run | PASS |
|---|---|
| `git -C ~/hyper-relay grep -n -F 'a disposable stack per worktree' -- README.md` | one line, in the status blockquote (D1's text). If it prints nothing, D1's status text is not on `main`: stop and check whether D1 has merged |

In `~/hyper-relay/README.md`, with the Edit tool, replace:
```text
> **Status: 0.1.0.** The skills, the role agents, per-repo configuration and the orchestrator are in. Still to come:
> several plans at once, a disposable stack per worktree and the docs' own folder (see [Roadmap](#roadmap)).
```
with:
```text
> **Status: 0.1.0.** The skills, the role agents, per-repo configuration, the orchestrator and `wt` are in. Still to
> come: several plans at once and the docs' own folder (see [Roadmap](#roadmap)).
```

```bash
git -C ~/hyper-relay add README.md
git -C ~/hyper-relay commit -m "docs: README status, wt is in" -m "<the committing session's attribution lines>" -- README.md
```

| Run | PASS |
|---|---|
| `git -C ~/hyper-relay grep -n -F 'a disposable stack per worktree' -- README.md` | nothing |
| `git -C ~/hyper-relay show --stat --format=%s HEAD` | `docs: README status, wt is in`, `README.md` only, 2 insertions and 2 deletions |

Then push `main` with the owner's go-ahead, as in Step 13 (no reinstall is needed for a README change).
