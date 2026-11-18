# hyper-relay E.1: `wt`'s safety notes, and the base-file check Implementation Plan

**Card:** docs/wt.md: safety notes and platform (`7211f935-aec9-49c1-bc64-5a58326ad08d`)
**Spec:** `docs/superpowers/specs/2026-11-18-hyper-relay-e1-wt-safety-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–2 are
> the executor's. Task 3 is the acceptance task: its `reviewer` steps are the acceptance reviewer's, its `owner` and
> `after merge` steps the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `docs/wt.md` claim no more safety than `wt` gives, and make its secrets promise a guarantee by having
`wt up` refuse a `WT_ENV_BASE` that git does not track, or that is a symlink.

**Architecture:** One commit adds two checks (three lines) to `write_base_env` in `bin/wt`, straight after the
existing not-found check, written test-first with three refusal cases in `tests/wt/run-tests.sh`. A second commit edits
`docs/wt.md` in eight places: each claim is fixed where it stands, and the Safety list gains a last bullet saying `wt`
runs the branch's code. Nothing else in the repo changes.

**Tech Stack:** POSIX `sh` run by dash; git; the `wt` suite (real git, a fake `docker` and `ss`); Markdown.

**How this was checked:** written against `main` at `95d5c54` by reading only, and revised at `96d2976` for the
spec's amendment (E1.4, read with `git show 96d2976`); nothing was built, run or installed.
Read in this repo: `CLAUDE.md` (in full); the E.1 spec (in full); E's plan
`docs/superpowers/plans/2026-11-18-hyper-relay-e-wt.md` (in full: the nearest precedent, and the source of this plan's
format); D1's plan (lines 1–130, for the header and Execution notes); `bin/wt` (444 lines), `tests/wt/run-tests.sh`
(375 lines; its `assert_*` calls counted by hand: 118, as E's plan records) and `docs/wt.md` (171 lines), all in full;
`.hyper-relay/agents.md` and the generated `.claude/agents/relay-reviewer.md` and `relay-executor.md` (in full);
`git ls-files` of `docs/superpowers/`, `bin/`, `tests/wt/`, `.claude/` and `.hyper-relay/`; `git log` of `bin/wt`,
`tests/wt/` and `docs/wt.md` (none has changed since E merged, `cbc143c`). Read-only git, run in this
repo: `git ls-files --error-unmatch` of `.env`, `../outside.env`, `/tmp/outside.env`, `./README.md`, and
`git ls-files -s --error-unmatch -- AGENTS.md` (results under External facts). Read outside the repo: in SAT's checkout,
`git ls-files --error-unmatch -- .env.example .wt.conf` (both tracked), `git ls-files -s` of `.env.example` (`100644`,
not a symlink) and `git grep -n WT_ENV_BASE -- .wt.conf` (nothing: the default, as spec §4.3 says); one more of the
owner's repos commits a `.wt.conf`, also at the default with a tracked `.env.example` (`100644`) (named to the
orchestrator, not here: D6). Not re-read: git's version (the planner's
guard refuses `git --version`; spec §5 says 2.43.0).

**External facts (re-verified 2026-11-18):**
- **`git ls-files --error-unmatch`.** [git-scm.com/docs/git-ls-files](https://git-scm.com/docs/git-ls-files): "If any
  <file> does not appear in the index, treat this as an error (return 1)." Observed in this repo today: the gitignored
  `.env` exits 1 (`error: pathspec '.env' did not match any file(s) known to git`); `../outside.env` and
  `/tmp/outside.env` exit 128 (`fatal: … is outside repository at …`); `./README.md` exits 0; the tracked symlink
  `AGENTS.md` exits 0 (`120000 … AGENTS.md`). **As spec §5 says** (amended: a tracked symlink passes `ls-files`, which
  is why E1.4 adds the `-L` check). §5's case of a file inside a tracked symlinked directory (exit 1, `-L` false) was
  checked by the spec's author at stop 3 and is not re-run here.
- **`ss` on macOS.** macOS does not ship `ss`; it is iproute2's, which is Linux's. A third-party port exists:
  [github.com/brona/iproute2mac](https://github.com/brona/iproute2mac) (fetched 2026-11-18) wraps "`ip`, `bridge` and
  `ss` commands", documents no filter expressions (`wt` runs `ss -ltn "sport = :<port>"`), and says "Provided
  functionality is limited and command output is not fully compatible with" iproute2. **As spec §5 says**; the doc's
  "macOS is not supported" stays true (D10).

---

## Execution notes (binding)

- **Where.** You work where your dispatch prompt says: a branch in the main checkout or your own worktree, chosen at
  the handoff. Paths below are relative to the checkout's top unless they start with `~` or `/`. This plan is
  committed on `main`.
- **Commits.** Commit after every task, staging named files only (never `git add -A` / `git add .`). Put the trailers
  in ONE final paragraph, so git reads them all as trailers: each task's final commit ends with
  `-m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e1-wt-safety.md#<N>` followed, inside the same quoted
  paragraph, by the two attribution lines your instructions give (a `Co-Authored-By:` line, and `Claude-Session:`
  with the URL from your dispatch prompt). The commands below write them as `<the line your instructions give>` and
  `<the URL your dispatch prompt gives>`: put the real lines there. Never tick the plan. Report every `quartz:` line a
  commit prints, verbatim.
- **Replacements.** "Replace X with Y" means the Edit tool with X as `old_string`, exactly. If X is not found, read the
  range again; if the text moved or differs slightly, adapt as little as possible and record it as a deviation; if it
  is gone, stop and report. Text in code blocks is exact, down to its line breaks: transcribe it. Task 3's line
  numbers and counts assume it.
- **This repo is public.** Nothing you write into `bin/wt`, `tests/wt/run-tests.sh`, `docs/wt.md` or a commit message
  names another project or quotes its files.
- **Never** run a real `wt` or `docker` command (the suite runs `wt` on its own fake `docker` and `ss`, which is
  fine), start a live `claude -p` / `opencode run` session, install or uninstall a plugin, push, tag, or create
  anything on GitHub. `claude plugin validate .` is fine. Do not run upstream's live suites (`tests/claude-code/`,
  `tests/explicit-skill-requests/`, `tests/skill-triggering/`): they start `claude -p`.
- **Outside your branch is not yours.** Never touch `main`, `~/.local/bin/wt`, `~/.claude/`, `~/.config/opencode/`,
  SAT's repo or any other project's, or the home directory's own repo. Task 3's `owner` and `after merge` steps do
  what is needed there, and they are not yours.
- **The orchestrator may keep working in the main checkout meanwhile.** Untracked files under `docs/superpowers/` that
  you did not create are its held-back specs and plans, and `tasks/` is the owner's untracked scratch tracker: never
  stage, edit, move or delete either. A "the tree is clean" check ignores them.
- Never wait with a self-matching `pgrep`; never `pkill -f` a pattern in your own command line.
- **Token budget.** Task 1 runs the `wt` suite only, piped through `tail` or `grep`. The full gates run once, in
  Task 2: the `wt` suite (the only suite this plan touches, per the Checks table in `CLAUDE.md`), `dash -n` of both
  scripts you touched, and `claude plugin validate .`.
- **Acceptance.** The plan ends with Task 3. Each of its steps says who runs it: **`reviewer`** (before the merge),
  **`owner`** (at the click-through) or **`after merge`** (the owner and the orchestrator), with its command or action
  and the result that counts as PASS. After Task 2, report (gate results with counts, every deviation, any `quartz:`
  line, the suites not run and why), copy Task 3's checklist into your report, and stop.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| D1 | §2: "its output names `.env.local`" (and the outside path) | The test looks for `git tracks: .env.local` and `git tracks: ../outside.env`, the end of §1's message. A bare path would also match today's `WT_ENV_BASE file not found: …`, so a fixture that lost its file would pass for the wrong reason. Still four assertions per case. The symlink case looks for `must not be a symlink: link.env`, as §2 asks. |
| D2 | §1: the checks turn away a path outside the repo "given absolutely or with `../`" | The amended §1 now says it too: an absolute path never reaches the new checks, because the existing `[ -f "$ROOT/$ENV_BASE" ]` looks for `$ROOT//abs/path`, which never exists, and stops first with `WT_ENV_BASE file not found: /abs/path`. No code change; the test covers `../`, as §2 says. |
| D3 | The planner's finding: a tracked symlink passes `ls-files` | **Closed by spec E1.4** (owner, stop 3): Task 1 adds the `-L` check and the third case, and Task 2's text names it. Still not acted on: `ls-files` reads `$ENV_BASE` as a pathspec, so glob characters in it would match other files; only a file literally named so gets past `[ -f ]`, and `.wt.conf` is code anyway. |
| D4 | §4.2: "`git diff main -- bin/wt` adds only the two checks" | Written `git diff main...HEAD -- bin/wt` (the branch's own changes, even if `main` has moved since the branch was cut). Likewise for the other diffs in Task 3. |
| D5 | §3: add to "the paragraph that says `wt` 'sources it as shell'" | The note is its own paragraph, set between that paragraph's first two sentences and its last ("These are the only keys it reads:"), which becomes its own one-line paragraph, kept beside its table. Its "it" becomes `` `wt` ``, since "it" would now read as `.wt.conf`. And §3's "runs that branch's copy" is written "runs that branch's `.wt.conf`", to say which copy. |
| D6 | §4.3: "SAT still passes the check" | Task 3 Step 13 also runs the same check in any other repo of the owner's that commits a `.wt.conf`, without naming it in this public plan. The planner found one more by reading; it passes both checks today (the report names it to the orchestrator). Step 13 reads the file's mode with `ls-files -s`, so it covers the symlink check (E1.4) too. |
| D7 | §1: a refused `wt up` keeps its slot; §3's failure row does not mention it | The row is written as §3 gives it. `docs/wt.md` says nothing of the slot after a missing base file today either. |
| D8 | §3: "A new row" in "When something fails" | Placed straight after the bad-`WT_ENV` row, the other `.wt.conf` mistake. |
| D9 | §3: "Linux only" | The bullet keeps its POSIX-shell clause: "Linux only, with a POSIX shell: …", then the macOS sentence. Nothing about WSL2. |
| D10 | §5: "macOS ships no `ss`" | True. A third-party `ss` (iproute2mac) exists but documents no filter expressions, which `wt` uses (header). The doc says macOS is not supported, which stays true; it does not mention the port. |
| D11 | §4.1: the executor's gates are the suite and `dash -n bin/wt` | Also `dash -n tests/wt/run-tests.sh` (a script this plan touches) and `claude plugin validate .` (this repo's standing gates). |
| D12 | §2: "In the refusals section, beside the existing `.wt.conf` refusals" | Between the unknown-placeholder case and the existing-`.env` case. The `wt down` refusals after that keep running on the existing-`.env` case's worktree and fake log, unchanged. |
| D13 | Card line | Included, from the spec, with a `**Spec:**` line. |
| D14 | §1: two new checks | Task 1 adds them one at a time, with a suite run between: after the `ls-files` check alone, the symlink case's four checks still fail (`126 passed, 4 failed`), which shows on this machine that a tracked symlink gets past `ls-files` (§5, E1.4); the `-L` check then makes the suite pass. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1, 2 |
| Decisions (owner, 2026-11-18) | E1.1: 1 (the `ls-files` check), 2 (the Safety `.env` bullet rests on it). E1.2: 2 (each claim fixed where it stands, plus one Safety bullet). E1.3: 2 (the `.wt.conf` paragraph, the last Safety bullet). E1.4: 1 (the `-L` check, the symlink case), 2 (edits (c), (f), (g)) |
| 1. `bin/wt`: the base-file check | 1; 3 (Step 3) |
| 2. `tests/wt/run-tests.sh`: three cases | 1; 3 (Steps 1, 4) |
| 3. `docs/wt.md` | 2; 3 (Steps 5–7, 10) |
| 4. Testing and acceptance | 4.1: 1 (Step 7), 2 (Step 3). 4.2: 3 (Steps 1–9). 4.3: 3 (Steps 12–13) |
| 5. External facts (checked 2026-11-18) | header (re-verified); 1 (Steps 3, 5, 7: the suite exercises exit 1, exit 128 and a tracked symlink's exit 0) |
| 6. Out of scope | Execution notes; 3 (Steps 3, 7, 8: nothing else changes) |
| 7. Plans | this plan |

## File structure

- **Modify (Task 1):** `bin/wt` (three lines added in `write_base_env`), `tests/wt/run-tests.sh` (three cases,
  30 lines, in the refusals section).
- **Modify (Task 2):** `docs/wt.md` (eight edits).
- **Task 3, outside the branch (owner and orchestrator):** the push; the installed plugin; read-only checks in SAT's
  repo and any other repo with a `.wt.conf`.

---

### Task 1: `wt up` refuses a base file git does not track, or a symlink (spec §1, §2; E1.1, E1.4; D1, D2, D12, D14)

**Files:**
- Modify: `bin/wt:104` (in `write_base_env`)
- Test: `tests/wt/run-tests.sh:118` (the refusals section)

- [x] **Step 1: The baseline is the one this plan read.**

| Run | Expected |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `118 passed, 0 failed` |
| `git grep -n -F 'WT_ENV_BASE file not found' -- bin/wt` | one line: `bin/wt:104:    [ -f "$ROOT/$ENV_BASE" ] \|\| die "WT_ENV_BASE file not found: $ENV_BASE"` |

If either differs, stop and report: `wt` or its suite changed after this plan was written.

- [x] **Step 2: Write the three failing cases.** In `tests/wt/run-tests.sh`, replace:

```text
assert_not_contains "an unknown placeholder builds nothing" "up --build" "$(cat "$FAKE_LOG")"
```

with:

```sh
assert_not_contains "an unknown placeholder builds nothing" "up --build" "$(cat "$FAKE_LOG")"

new_case app feat/one
printf 'REAL=secret\n' > "$WT/.env.local"
conf "WT_ENV_BASE=.env.local"
run_wt "$WT" up
assert_eq "an untracked base file is refused: exit" 1 "$RC"
assert_contains "an untracked base file is named" "git tracks: .env.local" "$OUT"
assert_eq "an untracked base file never reaches docker" "" "$(cat "$FAKE_LOG")"
assert_eq "an untracked base file writes no .env" 1 "$([ -e "$WT/.env" ]; echo $?)"

new_case app feat/one
printf 'REAL=secret\n' > "$CASE_DIR/outside.env"
conf "WT_ENV_BASE=../outside.env"
run_wt "$WT" up
assert_eq "a base file outside the repo is refused: exit" 1 "$RC"
assert_contains "a base file outside the repo is named" "git tracks: ../outside.env" "$OUT"
assert_eq "a base file outside the repo never reaches docker" "" "$(cat "$FAKE_LOG")"
assert_eq "a base file outside the repo writes no .env" 1 "$([ -e "$WT/.env" ]; echo $?)"

new_case app feat/one
printf 'REAL=secret\n' > "$CASE_DIR/outside.env"
ln -s ../outside.env "$WT/link.env"
git -C "$WT" add link.env
git -C "$WT" commit -qm link
conf "WT_ENV_BASE=link.env"
run_wt "$WT" up
assert_eq "a symlinked base file is refused: exit" 1 "$RC"
assert_contains "a symlinked base file is named" "must not be a symlink: link.env" "$OUT"
assert_eq "a symlinked base file never reaches docker" "" "$(cat "$FAKE_LOG")"
assert_eq "a symlinked base file writes no .env" 1 "$([ -e "$WT/.env" ]; echo $?)"
```

Why these fixtures hold: `new_case` commits only `.env.example`, `docker-compose.yml` and `.gitignore` (which ignores
`.env` alone), so `.env.local` in the worktree is untracked, not ignored. The worktree is `$CASE_DIR/wt`, so from its
root `../outside.env` is `$CASE_DIR/outside.env`: a real file, outside both the main checkout (`$CASE_DIR/myproj`)
and the worktree, so today's not-found check lets it through (D2). In the third case the worktree's branch,
`feat/one`, commits `link.env`, a symlink to that same outside file (relative to the link, `../outside.env`), so git
tracks the link and `[ -f ]` follows it; the commit uses the identity `new_case` set in the repo's shared config, as
`new_repo` already does from a worktree.

- [x] **Step 3: Run the suite; the twelve new checks fail.**

Run: `sh tests/wt/run-tests.sh | grep -e '^FAIL' -e 'passed, '`
Expected: twelve `FAIL` lines, each naming one of the checks above (all contain `base file`), then
`118 passed, 12 failed`. Today `wt up` copies each file (through the link, in the third case) to `.env` and starts
the stack on the fake `docker`.

- [x] **Step 4: Add the `ls-files` check.** In `bin/wt`, replace:

```text
    [ -f "$ROOT/$ENV_BASE" ] || die "WT_ENV_BASE file not found: $ENV_BASE"
```

with:

```sh
    [ -f "$ROOT/$ENV_BASE" ] || die "WT_ENV_BASE file not found: $ENV_BASE"
    git -C "$ROOT" ls-files --error-unmatch -- "$ENV_BASE" >/dev/null 2>&1 ||
        die "WT_ENV_BASE must be a file git tracks: $ENV_BASE"
```

It runs after `take_slot` and before `.env` is touched or `WT_SETUP` runs, the same point as the not-found error, so a
refused `wt up` keeps its slot as a missing base file does today (spec §1).

- [x] **Step 5: Run the suite; only the symlink case still fails (D14).**

Run: `sh tests/wt/run-tests.sh | grep -e '^FAIL' -e 'passed, '`
Expected: four `FAIL` lines, all `a symlinked base file …`, then `126 passed, 4 failed`: git tracks the link, so
`ls-files` accepts it (spec §5).

- [x] **Step 6: Add the symlink check (spec E1.4).** In `bin/wt`, replace:

```text
        die "WT_ENV_BASE must be a file git tracks: $ENV_BASE"
```

with:

```sh
        die "WT_ENV_BASE must be a file git tracks: $ENV_BASE"
    [ ! -L "$ROOT/$ENV_BASE" ] || die "WT_ENV_BASE must not be a symlink: $ENV_BASE"
```

So `write_base_env` now opens with the not-found line and the two checks, in that order, then the existing `.env`
check. Nothing else in `bin/wt` changes, its header comment included.

- [x] **Step 7: Run the suite; it passes.**

| Run | Expected |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `130 passed, 0 failed` |
| `sh tests/wt/run-tests.sh \| grep -F 'base file'` | twelve lines, each starting `ok` |
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent |
| `git diff --numstat -- bin/wt tests/wt/run-tests.sh` | `3	0	bin/wt` and `30	0	tests/wt/run-tests.sh` |

- [x] **Step 8: Commit.**

```bash
git add bin/wt tests/wt/run-tests.sh
git commit -m "feat: wt up refuses a WT_ENV_BASE that git does not track, or a symlink" -m "A gitignored file such as a real .env, an untracked file, a path outside the repo, or a symlink, even a tracked one, can no longer become a stack's .env: wt up stops before writing .env, and names the file. Three suite cases cover an untracked file, a ../ path and a tracked symlink; the suite now runs 130 checks." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e1-wt-safety.md#1
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git ls-files -s bin/wt` must still print a line starting `100755`.

### Task 2: `docs/wt.md` claims only what `wt` gives; the full gates (spec §3, §4.1; E1.1–E1.4; D5, D7–D9, D11)

**Files:**
- Modify: `docs/wt.md` (lines 31, 106–107, 111, 112, 145, 154, 165–166, 170–171 of today's file)

- [x] **Step 1: Eight edits to `docs/wt.md`.**

(a) Requirements, the Linux bullet. Replace:
```text
- Linux, with a POSIX shell: `wt` is written for dash and runs as `#!/bin/sh`.
```
with:
```text
- Linux only, with a POSIX shell: `wt` is written for dash and runs as `#!/bin/sh`. macOS is not supported, because
  `wt` checks ports with `ss`, from Linux's iproute2.
```

(b) `.wt.conf`, the paragraph that says `wt` sources it as shell (D5). Replace:
```text
Commit a `.wt.conf` at the project's root. `wt` sources it as shell from the root of the worktree it works on, so each
branch reads its own copy. These are the only keys it reads:
```
with:
```text
Commit a `.wt.conf` at the project's root. `wt` sources it as shell from the root of the worktree it works on, so each
branch reads its own copy.

**`.wt.conf` is code.** `wt up` and `wt new` source it, so every line in it runs with your privileges, not only
`WT_SETUP` and `WT_NEW_SETUP`; and `wt up` builds and starts the branch's compose file and Dockerfiles. Review
`.wt.conf` like a build script, and run `wt` only on branches whose code you would run yourself: `wt new` on someone
else's branch runs that branch's `.wt.conf` straight away.

These are the only keys `wt` reads:
```

(c) The key table, the `WT_ENV_BASE` row. Replace:
```text
| `WT_ENV_BASE` | `.env.example` | The file `.env` is copied from. |
```
with:
```text
| `WT_ENV_BASE` | `.env.example` | The file `.env` is copied from. It must be a file git tracks, and not a symlink (`wt up` refuses any other), and hold no secrets. |
```

(d) The key table, the `WT_ENV` row. Replace:
```text
| `WT_ENV` | none | `KEY=VALUE` pairs, separated by spaces or newlines, set in `.env`. A value cannot contain a space. |
```
with:
```text
| `WT_ENV` | none | `KEY=VALUE` pairs, separated by spaces or newlines, set in `.env`. A value cannot contain a space. Real credentials never go here: `.wt.conf` is committed. |
```

(e) State and limits, the `WT_STATE_DIR` row. Replace:
```text
whether its setup and seed have run. Outside every repo. |
```
with:
```text
whether its setup and seed have run. Keep it outside every repo: inside one, `git clean` or removing a worktree can delete a running stack's state, and `wt down` refuses a stack it holds no state for. |
```

(f) When something fails, a new row after the bad-`WT_ENV` one (D7, D8). Replace:
```text
| A bad `WT_ENV` key or placeholder | Stops before building, and names it. |
```
with:
```text
| A bad `WT_ENV` key or placeholder | Stops before building, and names it. |
| `WT_ENV_BASE` names a file git does not track (gitignored, untracked, or outside the repo), or a symlink | Stops before writing `.env`, and names it. |
```

(g) Safety, the `.env` bullet. Replace:
```text
- **`.env` comes from the base file, never from your real `.env`,** so a stack holds no real secrets and cannot use
  them to reach a real outside service.
```
with:
```text
- **`.env` comes from a file git tracks, never from your real `.env`,** because `wt up` refuses any other base file,
  and any symlink. Keep that file secret-free and real credentials out of `WT_ENV`, since both are committed: then a
  stack holds no real secrets and cannot use them to reach a real outside service.
```

(h) Safety, a new last bullet. Replace:
```text
  for,** so it cannot act on a real stack. It removes only the stack's own `wt-` image tags, never shared images such
  as `postgres:16`.
```
with:
```text
  for,** so it cannot act on a real stack. It removes only the stack's own `wt-` image tags, never shared images such
  as `postgres:16`.
- **`wt` is no sandbox.** It runs the branch's code (`.wt.conf`, the compose file, the Dockerfiles), so use it only on
  branches you trust.
```

Nothing else in `docs/wt.md` changes, and `README.md` does not change (spec §3).

- [x] **Step 2: Check the doc.**

| Run | Expected |
|---|---|
| `git diff --numstat -- docs/wt.md` | `19	7	docs/wt.md` |
| `git grep -n -F 'Outside every repo.' -- docs/wt.md` | nothing |
| `git grep -n -F 'comes from the base file' -- docs/wt.md` | nothing |
| `git grep -c -F 'git tracks' -- docs/wt.md` | `docs/wt.md:2` (the `WT_ENV_BASE` row and the Safety bullet) |
| `git grep -n -w -F symlink -- docs/wt.md` | four lines: 8 (the intro's "symlink it from a clone", unchanged), 119, 163 and 175 |
| `git grep -n -e macOS -e 'build script' -e 'Real credentials' -e 'git clean' -e 'names a file git does not track' -e 'is no sandbox' -- docs/wt.md` | six lines: 31, 112, 120, 153, 163 and 182 |
| `wc -l < docs/wt.md` | `183` |

- [x] **Step 3: The full gates, once.**

| Run | Expected |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `130 passed, 0 failed` |
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent |
| `git ls-files -s bin/wt` | a line starting `100755` |
| `git diff --name-only main...HEAD`, then `git diff --name-only` | together: `bin/wt`, `docs/wt.md`, `tests/wt/run-tests.sh`, nothing else |
| `git grep -n -i -w -E 'sat\|quartz' -- bin/wt tests/wt docs/wt.md` | nothing |
| `claude plugin validate .` | passes; report every warning verbatim (expected: the root `CLAUDE.md` one, and `ICON_MISSING` if it appears) |

Upstream's live suites are not run (report this): they start real `claude -p` sessions.

- [x] **Step 4: Commit.**

```bash
git add docs/wt.md
git commit -m "docs: wt.md says what wt trusts and what it refuses" -m "Linux only: macOS has no ss. .wt.conf is code, so wt runs only on branches you trust. WT_ENV_BASE must be a file git tracks, not a symlink, and WT_ENV holds no real credentials. WT_STATE_DIR stays outside every repo, with the reason. A failure row for an untracked or symlinked base file, and two Safety bullets: the .env one rests on the new checks, and wt is no sandbox." -m "Plan-Task: docs/superpowers/plans/2026-11-18-hyper-relay-e1-wt-safety.md#2
Co-Authored-By: <the line your instructions give>
Claude-Session: <the URL your dispatch prompt gives>"
```

Then `git status --short` must print nothing (on a branch run, nothing but the orchestrator's untracked files under
`docs/superpowers/` and the owner's `tasks/`). Report, copy Task 3's checklist into the report, and stop: Task 3 is
not yours.

### Task 3: Acceptance (spec §4.2, §4.3). NOT the executor's

Each step says who runs it. **`reviewer`** steps (1–9) run before the merge, in the plan's checkout on the branch
`hyper-relay-e1-wt-safety`, by the acceptance reviewer, which writes only in its evidence folder. **`owner`** steps
(10–11) run at the click-through. **`after merge`** steps (12–13) are the owner's and the orchestrator's, one command
per Bash call; they make no commit with a `Plan-Task:` trailer, so the orchestrator ticks this task by hand when
Step 13 is done (commit just the plan: `docs: plan progress, task 3 of 3`). No step starts a live session or real
Docker: the suite runs on its fake `docker`.

- [ ] **Step 1 (`reviewer`): The suite, with the three new cases (spec §4.1, §2).**

| Run | PASS |
|---|---|
| `sh tests/wt/run-tests.sh \| tail -n 1` | `130 passed, 0 failed` |
| `sh tests/wt/run-tests.sh \| grep -F 'base file'` | twelve lines, each starting `ok`: four for `an untracked base file …`, four for `a base file outside the repo …`, four for `a symlinked base file …` |

- [ ] **Step 2 (`reviewer`): Syntax and mode.**

| Run | PASS |
|---|---|
| `dash -n bin/wt`, then `dash -n tests/wt/run-tests.sh` | silent, exit 0 |
| `git ls-files -s bin/wt` | a line starting `100755` |

- [ ] **Step 3 (`reviewer`): `bin/wt` adds only the two checks (spec §1, §4.2; E1.4; D4).**

| Run | PASS |
|---|---|
| `git diff --numstat main...HEAD -- bin/wt` | `3	0	bin/wt` |
| `git diff main...HEAD -- bin/wt` | one hunk, in `write_base_env`, adding exactly `    git -C "$ROOT" ls-files --error-unmatch -- "$ENV_BASE" >/dev/null 2>&1 \|\|`, `        die "WT_ENV_BASE must be a file git tracks: $ENV_BASE"` and `    [ ! -L "$ROOT/$ENV_BASE" ] \|\| die "WT_ENV_BASE must not be a symlink: $ENV_BASE"`, in that order, straight after the `WT_ENV_BASE file not found` line; nothing removed |

- [ ] **Step 4 (`reviewer`): The three test cases (spec §2; D1, D12).**

| Run | PASS |
|---|---|
| `git diff --numstat main...HEAD -- tests/wt/run-tests.sh` | `30	0	tests/wt/run-tests.sh` |
| `git diff main...HEAD -- tests/wt/run-tests.sh` | one hunk in the `--- refusals` section, after `an unknown placeholder builds nothing` and before the existing-`.env` case: three `new_case app feat/one` cases, one with an untracked `$WT/.env.local` and `WT_ENV_BASE=.env.local`, one with `$CASE_DIR/outside.env` and `WT_ENV_BASE=../outside.env`, and one that commits `$WT/link.env`, a symlink to `../outside.env`, with `WT_ENV_BASE=link.env`. Each asserts exit 1, an empty fake docker log and no `$WT/.env`; the first two look for `git tracks: <path>` in the output, the third for `must not be a symlink: link.env` |

- [ ] **Step 5 (`reviewer`): Each row of spec §3's table is in `docs/wt.md`.**

| Run | PASS |
|---|---|
| `git grep -n -F macOS -- docs/wt.md` | one line, 31: the Requirements bullet says `Linux only` and that macOS is not supported, because of `ss` |
| `git grep -n -F 'build script' -- docs/wt.md` | one line, 112, in the paragraph that starts ``**`.wt.conf` is code.**`` (line 110), which also says `wt up` and `wt new` source it, that every line runs with your privileges, and what `wt new` does on someone else's branch |
| `git grep -n -F 'git tracks' -- docs/wt.md` | two lines: 119 (the `WT_ENV_BASE` row, which also says not a symlink, that `wt up` refuses any other, and that the file holds no secrets) and 174 (the Safety `.env` bullet) |
| `git grep -n -w -F symlink -- docs/wt.md` | four lines: 8 (the intro's "symlink it from a clone", unchanged), 119 (the `WT_ENV_BASE` row), 163 (the failure row) and 175 (the Safety `.env` bullet's `and any symlink`) |
| `git grep -n -F 'Real credentials' -- docs/wt.md` | one line, 120: the `WT_ENV` row |
| `git grep -n -F 'git clean' -- docs/wt.md` | one line, 153: the `WT_STATE_DIR` row, which says to keep it outside every repo and why |
| `git grep -n -F 'names a file git does not track' -- docs/wt.md` | one line, 163: a row of "When something fails" that also names a symlink, saying `wt` stops before writing `.env` and names the file |
| `git grep -n -F 'is no sandbox' -- docs/wt.md` | one line, 182: the last bullet of the Safety list |

- [ ] **Step 6 (`reviewer`): The two claims E's review flagged are gone (spec §4.2).**

| Run | PASS |
|---|---|
| `git grep -n -F 'Outside every repo.' -- docs/wt.md` | nothing |
| `git grep -n -F 'comes from the base file' -- docs/wt.md` | nothing |
| `git grep -n -A 2 -F 'comes from a file git tracks' -- docs/wt.md` | lines 174–176: one Safety bullet whose first two lines say `wt up` refuses any other base file, and any symlink, and whose last line says a stack `holds no real secrets` |

- [ ] **Step 7 (`reviewer`): Nothing else in `docs/wt.md` changed (spec §3).**

| Run | PASS |
|---|---|
| `git diff --numstat main...HEAD -- docs/wt.md` | `19	7	docs/wt.md` |
| `git diff main...HEAD -- docs/wt.md` | every hunk is one of the eight edits of Task 2 Step 1, (a)–(h); no other line differs |

- [ ] **Step 8 (`reviewer`): Only three files differ, and no other project is named (spec §4.2).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `bin/wt`, `docs/wt.md` and `tests/wt/run-tests.sh` |
| `git grep -n -i -w -E 'sat\|quartz' -- bin/wt tests/wt docs/wt.md` | nothing |
| `git log --format=%B main..HEAD \| grep -c -i -w -E 'sat\|quartz'` | `0` |

- [ ] **Step 9 (`reviewer`): The manifests.**

| Run | PASS |
|---|---|
| `claude plugin validate .` | passes; its only warnings are the root `CLAUDE.md` one and, if it appears, `ICON_MISSING` |

- [ ] **Step 10 (`owner`): Read what users will read.** `git -C /home/noob_master/hyper-relay diff main...hyper-relay-e1-wt-safety -- docs/wt.md`. PASS: the owner
  agrees each note is true of `wt` and says no more than spec §3 asks.

- [ ] **Step 11 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-e1-wt-safety` | exit 0, one line (a tree id) |

On exit 1 it names the conflicted files: tell the owner before merging.

- [ ] **Step 12 (`after merge`): Push, then the owner reinstalls (spec §4.3).** Precondition: the owner has merged
  `hyper-relay-e1-wt-safety` into `main`, and the main checkout is on `main`. The version stays 0.1.0.

```bash
git -C /home/noob_master/hyper-relay push origin main
```

Then the owner, in a Claude Code session: `/plugin install hyper-relay@hyper-relay`. A new session loads it.

| Run | PASS |
|---|---|
| `git -C ~/.claude/plugins/marketplaces/hyper-relay rev-parse HEAD`, then `git -C /home/noob_master/hyper-relay rev-parse main` | the same SHA |
| `grep -c -F -e 'must be a file git tracks' -e 'must not be a symlink' ~/.claude/plugins/cache/hyper-relay/hyper-relay/0.1.0/bin/wt` | `2`: agents' `wt` has both checks |
| `grep -c -F -e 'must be a file git tracks' -e 'must not be a symlink' ~/.local/bin/wt` | `2`: the owner's shell runs the main checkout's `bin/wt` (E2), so it has both checks on merge |

If either of the first two fails, stop and tell the owner; do not delete or uninstall anything.

- [ ] **Step 13 (`after merge`): The owner's projects still pass both checks (spec §4.3; D6).**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/sat.pentraze.com grep -n WT_ENV_BASE -- .wt.conf` | nothing: SAT's base file is the default, `.env.example` |
| `git -C /home/noob_master/sat.pentraze.com ls-files -s --error-unmatch -- .env.example` | one line starting `100644` (a regular file, not a symlink's `120000`) and ending `.env.example`, exit 0 |

Then the same two commands in each other repo of the owner's that commits a `.wt.conf` (`git -C <repo> ls-files --
.wt.conf` prints it); where its `.wt.conf` sets `WT_ENV_BASE`, give that path to `ls-files -s --error-unmatch`
instead of `.env.example`. PASS: exit 0 and a mode other than `120000` in every repo. On a non-zero exit or a
`120000`, tell the owner before anyone runs `wt up` there: that repo's `.wt.conf` must name a base file git tracks,
and not a symlink.
