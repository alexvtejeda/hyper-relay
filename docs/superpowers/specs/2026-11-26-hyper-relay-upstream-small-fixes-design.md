# hyper-relay: upstream's small skill fixes (design)

**Date:** 2026-11-26 · **Status:** written from the owner's brainstorms of 2026-11-19 and 2026-11-26, waiting on the owner's review
**Card:** Upstream's small skill fixes we're missing (superpowers 6.0–7.0.2) (`6ad2f229-a2a2-4740-8cc5-e23455c6c725`)
**Scope:** this repo. Seven skills (`writing-skills`, `systematic-debugging`, `finishing-a-development-branch`,
`using-git-worktrees`, `verification-before-completion`, `receiving-code-review`, `dispatching-parallel-agents`), three
new shell suites (`tests/skill-size/`, `tests/skill-layout/`, `tests/systematic-debugging/`), their places in
`CLAUDE.md` and `.hyper-relay/merge.conf`, then a release.

## Goal

hyper-relay forked obra/superpowers at v5.1.0. Upstream has since fixed a set of small things in skills we still ship
as v5.1.0's text, and this card brings over the ones that matter to us. The owner listed them on the card (checked
against `main` on 2026-11-19). The harness-support (compatibility) fixes are left out, because we don't need them.

Three of them touch every relay run:

- **Compaction cuts the end off big skills.** After a compaction, Claude Code re-attaches each invoked skill cut at
  about 20,000 characters (How it works). `writing-skills` is 22,624 bytes, so a compacted session loses its last
  sections, including the whole Skill Creation Checklist. A size test keeps every `SKILL.md` under the cut from now on.
- **Pressure-test scenarios ship inside `systematic-debugging`.** They open with "You must choose and act", and an
  agent can find one mid-task and take it as its own instructions. A layout test keeps such files out of every skill.
- **"Ultrathink this"** in `systematic-debugging` was, upstream, a keyword that switched on extended thinking. It
  doesn't do that on our Claude Code today (How it works), but the hyphen costs nothing.

The rest are smaller fixes in skills the relay uses less, since `relay-merge` and the orchestrator do that work in the
relay: `finishing-a-development-branch` (discard off the menu, a PR step for any forge, a refused worktree removal, a
path bug), `using-git-worktrees` (the old global folder), `systematic-debugging` (an example that prints a secret, a
script that matches nothing), and cutting four recap sections.

**Non-goals:**
- Upstream's new skill-writing guidance in 7.0.2 (the form-selection table, micro-tests) and its harness-neutral
  rewording. Those would get a card of their own.
- Upstream's other rewrites of these skills: rationalization tables, the base-branch step, shorter descriptions.
- Trimming `brainstorming` under 20,000 bytes (card `cf93197f`, filed in this brainstorm). The size test names it as
  its one exception until then.
- The TDD rule that the project's suite defines green (moved to the "Review and TDD rules" card, `5441ce1c`).

**Anti-goals** (failures even if everything else works):
- a skill that behaves differently in a way this spec doesn't name: moved text that changed on the way, a link that
  no longer resolves, a fix that pulled in upstream wording around it;
- a test that fails on today's in-skill test code (voice-to-specs' `tests/`, visual-companion's `test-*.cjs`);
- an exception in the size test for anything but `brainstorming`.

## Decisions (owner)

1. **(b), 2026-11-19.** The skill-size test lands on this card with `brainstorming` as its one named exception, and a
   new card trims `brainstorming`. Not (a), trimming it here, and not (c), no test. That card was filed on
   2026-11-26 as `cf93197f` and depends on this one.
2. **Scope, 2026-11-19.** The card gained the secret example, `find-polluter.sh`, finishing's three extra fixes and the
   recap cuts in four skills. The TDD item moved to card `5441ce1c`. `brainstorming`, `writing-plans` and
   `writing-skills` get their recap cuts on their own cards. Order: writing-plans first, then brainstorming, then the
   others. Both are done (cards `ce88b594`, `a5a66906`).
3. **Approach A, 2026-11-26** (below). `writing-skills` gets only the move, word for word. Every other skill gets just
   the listed fixes, in upstream's wording for each fix and nothing around it. No reason given: the owner picked the
   recommendation.
4. **The playback, 2026-11-26,** in three parts (writing-skills and the two tests; finishing, worktrees, debugging and
   the recap cuts; the pressure scenarios and one plan), stood without corrections.

Each call below that is mine, not the owner's, says so.

## How it works

Checked on 2026-11-26 on this machine, unless a line says otherwise. Upstream is the `upstream` remote
(obra/superpowers), fetched that day, with tags `v5.1.0` to `v7.0.2`.

**Claude Code's compaction cut** (the installed binary, `~/.local/share/claude/versions/2.1.332`, read with
`grep -abo` and `dd`):
- On compaction, each invoked skill goes through `function Wvs(e,n){if(Wl(e)<=n)return e;let o=n*4-jlt.length;return
  e.slice(0,o)+jlt}` with `n` = `kvs=5000`, inside a total of `GWe=25000`. `jlt` is the marker `[... skill content
  truncated for compaction; use Read on the skill path if you need the full text]`. In short, a skill over about 5,000
  tokens keeps its first 20,000 characters, minus the marker's length.
- The same held on 2.1.329 (card note `b5d37465`, 2026-11-19).
- Upstream's size test measures bytes, which is stricter than characters for text that isn't ASCII.

**What the cut costs today:**
- `wc -c` on `main`: `brainstorming` 24,202 bytes, `writing-skills` 22,624, `writing-plans` 17,118. Every other
  `SKILL.md` is 15,846 or less.
- In `writing-skills`, a cut at about 19,900 characters lands inside "STOP: Before Moving to Next Skill" (near line
  589). It loses the rest of that section, all of "Skill Creation Checklist (TDD Adapted)", "Discovery Workflow" and
  "The Bottom Line" (counted with python, 2026-11-26).

**Ultrathink.** On Claude Code 2.1.329, `ultrathink` raises effort only when the person types it in the prompt: the
`ultrathink_effort` attachment tests the turn's typed input (card note `b5d37465`). A skill's text triggers nothing.
This wasn't rechecked on 2.1.332, because the hyphen is wanted either way.

**Our copies.** `git diff --stat v5.1.0 HEAD` on the seven skills shows only the `superpowers:` → `hyper-relay:`
renames and `render-graphs.js`'s example. Each skill is v5.1.0's text.

**Upstream's changes this card brings, by commit:**

| What | Upstream | Notes |
|---|---|---|
| `writing-skills` split into `references/` | 7.0.1, `2ce8aa1` (#2564, #2565) | Layout below; the new guidance in the same release is not taken |
| `tests/skill-size/test-skill-size.sh` | 7.0.1 | bash; fails when any `skills/*/SKILL.md` is ≥ 20,000 bytes |
| `tests/skill-layout/test-no-dev-files-in-skills.sh` | 7.0.2 (#2277, #2654) | bash; fails on any `CREATION-LOG.md` or `test-*.md` under `skills/` |
| systematic-debugging's scenarios moved to `tests/systematic-debugging/pressure-scenarios/` | 7.0.2 | the five files, unchanged |
| "Ultra-think this" | 6.0.0 (#1283) | one line |
| The secret example reports only set or unset | 7.0.0 (#2375, #2380) | `SKILL.md` lines 93 and 97 |
| `find-polluter.sh` matches `./` paths, top-level tests, honest zero | 6.2.0 `6015d37` (#2011, fixes #2008), then `c8921b5` with `tests/systematic-debugging/test-find-polluter.sh` | `c8921b5` uses `${TEST_PATTERN//\*\*\//}`, which is bash. The script is `#!/usr/bin/env bash` |
| finishing: discard off the menu | 6.2.0, `9dff1a9` | explicit request and typed `discard` only |
| finishing: PR step for any forge | 6.0.0 (#1609), `24ae4c8`, `4e3707f`, `bcfe798` | |
| finishing: refused removal lists the files and asks | 6.3.0 (#2016, #2024) | never `--force` on its own |
| finishing: path captured in Step 2 | `0b47219` | the commit message describes the bug (below) |
| using-git-worktrees: global folder removed | 6.0.0, `d00f4ad` (#1476) | |
| Recap sections dropped | 6.2.0's compression pass | only the four named here |

**The finishing path bug** (`0b47219`'s message, and our Step 6). Option 1 and discard `cd` to the main checkout,
then Step 6 recomputes `GIT_DIR`, `GIT_COMMON` and `WORKTREE_PATH`. From the main checkout these see a normal repo,
so cleanup silently does nothing and `git branch -d` then fails because the worktree still has the branch. The fix
records the three values in Step 2, inside the workspace, and Step 6 uses them.

**The secret example** today: `echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"` prints `SET` followed by the
value when the variable is set, and `env | grep IDENTITY` prints the value too. Upstream's lines are
`echo "IDENTITY: $([ -n "${IDENTITY:-}" ] && echo SET || echo UNSET)"` and
`printenv IDENTITY >/dev/null 2>&1 && echo "IDENTITY in environment" || echo "IDENTITY not in environment"`.

**This repo:**
- Test style: POSIX `sh` suites named `run-tests.sh` that end with `printf '\n%s passed, %s failed\n'`
  (`tests/add-card-line/run-tests.sh:446`), listed in the Checks table in `CLAUDE.md` and, as `prefix kind command`
  lines, in `.hyper-relay/merge.conf`. `CLAUDE.md`'s Layout section says what each `tests/` folder tests.
- The relay guard, `tests/orchestrating/run-tests.sh`, reads `skills/`. Its `no_superpowers_skill_names` fails on a
  `superpowers:` skill name, and upstream's reference files open with "Part of superpowers:writing-skills".
- In-skill test code the layout rule must not catch: `skills/voice-to-specs/tests/*.test.sh`,
  `skills/visual-companion/scripts/test-*.cjs` and `run-tests.sh`. Upstream's pattern matches none of them (`find`).
- `~/.config/superpowers/worktrees/` doesn't exist on this machine (`ls`).
- Links to the `writing-skills` files that move: `SKILL.md` lines 20, 316, 318–321, 463 and 556, and
  `testing-skills-with-subagents.md` lines 15 and 142. Nothing outside the skill links to them. `scripts/check-import.sh`
  compares against loose copies in `~/.claude/skills/`, is already stale and isn't in the Checks table, so it stays as
  it is.

## Approaches

- **A. The move only, plus the listed fixes** (picked). `writing-skills` keeps its text word for word, split into
  `references/` with upstream's layout. Every other fix is upstream's wording for that fix alone. Trade-off: upstream's
  newer skill-writing guidance stays out.
- **B. Upstream's 7.0.2 `writing-skills`, renamed to our names.** A plus the form-selection table and micro-tests.
  The table is cheap, but micro-tests (5+ fresh samples per wording, plus a control) would make every relay skill
  change run extra agents on top of the orchestrator's skill tests, and the guidance is a real change to how every
  skill gets written. Dropped; it can come on its own card.
- **Upstream's whole 7.0.2 text for every skill on the card.** Brings rewrites beyond the listed fixes, plus
  harness wording we don't need. Dropped.

## 1. `writing-skills`: the move

Our text moves word for word. Upstream's layout (7.0.1):

| From `SKILL.md` (ours) | To |
|---|---|
| `## SKILL.md Structure` (with its template) and `## Claude Search Optimization (CSO)` (through "Cross-Referencing Other Skills") | `references/discovery.md` |
| `## Bulletproofing Skills Against Rationalization` and `## Red Flags - STOP and Start Over` (with "Update CSO for Violation Symptoms") | `references/bulletproofing.md` |
| `## Flowchart Usage` | `references/flowcharts.md` |

*My call:* the skill's existing docs move into `references/` too, as upstream did. That way a later upstream fix
to them applies cleanly. The docs are `anthropic-best-practices.md`, `persuasion-principles.md`,
`testing-skills-with-subagents.md`, `graphviz-conventions.dot`, and `examples/CLAUDE_MD_TESTING.md` (to
`references/CLAUDE_MD_TESTING.md`). `render-graphs.js` stays beside `SKILL.md`.

- Each new reference file opens like upstream's, with a title and one line, "Part of hyper-relay:writing-skills…",
  saying when it's read. Then comes our moved text, unchanged.
- In `SKILL.md`, each moved section leaves a short section in its place, in upstream's 7.0.2 wording and with our
  names: "Writing SKILL.md", "Flowcharts" and "Bulletproofing Against Rationalization". Each says when to read its
  file. "Writing SKILL.md" keeps upstream's paragraph on the rule agents break most: a description says only when to
  use the skill, starting "Use when…", and never summarizes its workflow.
- Upstream's bulletproofing pointer mentions "Match the Form to the Failure", which we don't take. That clause comes
  out.
- `SKILL.md` names each file as `${CLAUDE_SKILL_DIR}/references/<file>` and also relative to itself (this repo's
  rule: OpenCode doesn't expand the variable). That includes the existing lines whose paths change (lines 20, 463 and
  556).
- Links inside the moved files are updated so they resolve from `references/`.
- Nothing else in `SKILL.md` changes. "The Bottom Line" stays, since its cut belongs to a `writing-skills` card of its
  own (decision 2). The result is about 13–14 KB.
- *My call:* `render-graphs.js` stays as it is. It reads ` ```dot ` blocks from a skill's `SKILL.md` only (line 102),
  and it exists to render other skills' diagrams. After the move, `writing-skills` has one such block left in
  `SKILL.md` (Anti-Patterns), and the Flowchart Usage example lives in `references/flowcharts.md`. Upstream made the
  same split and left the script's input alone.

## 2. The size and layout tests, and the scenarios' move

**Size test** (`tests/skill-size/run-tests.sh`). It fails when any `skills/*/SKILL.md` is 20,000 bytes or more, and
names each such file with its size. `skills/brainstorming/SKILL.md` is the one exception, named in the test with card
`cf93197f`, whose work deletes the exception. The test still prints the excepted file's size, so the exception stays
visible.

The size test reads `SKILL.md` files only, since the cut applies only to them. `references/` files and other
supporting files don't count, however large.

**Layout test** (`tests/skill-layout/run-tests.sh`). It fails when any skill's folder holds a `CREATION-LOG.md` or a
`test-*.md`, which is upstream's rule, and names each file.

**The move.** `skills/systematic-debugging/` sends `CREATION-LOG.md`, `test-academic.md` and `test-pressure-1.md` to
`-3.md` to `tests/systematic-debugging/pressure-scenarios/`, unchanged. *My call:* "unchanged" includes
`CREATION-LOG.md`'s stale `skills/meta/testing-skills-with-subagents` path (line 57). It's a historical log, and
upstream moved it the same way.

**The relay guard** (`tests/orchestrating/run-tests.sh`) checks links (`skill_names_resolve`, `section_refs_resolve`)
and machine paths in `skills/orchestrating` only. Across all of `skills/` it checks one thing: no `superpowers:` skill
names. So the new `references/` files pass it once their opening lines say `hyper-relay:`. The guard doesn't check
their links; §8's reviewer step does.

*My calls:*
- Both tests are POSIX `sh`, in this repo's style, not upstream's bash.
- Each suite proves it can fail: besides the real tree, it runs on fixture trees. For the size test, a file of 19,999
  bytes passes, one of 20,000 fails, and the exception covers `brainstorming` alone. For the layout test, each banned
  name fails and the in-skill test code above passes.
- Both go in the Checks table and in `merge.conf`, on the `skills/` prefix and on their own `tests/` folders, and
  `CLAUDE.md`'s Layout section names them.

## 3. `systematic-debugging`

- "Ultrathink this" becomes "Ultra-think this" (line 240).
- The multi-layer example's two lines become upstream's (How it works).
- `find-polluter.sh` gets `6015d37` and `c8921b5`'s changes. A new `tests/systematic-debugging/run-tests.sh`, in our
  style, covers `c8921b5`'s four cases with a toy project and a stub `npm` on `PATH`:
  - the documented pattern finds a polluter;
  - it matches top-level and nested test files ("Found 2");
  - a `./`-prefixed pattern matches the same files;
  - a pattern that matches nothing reports "Found 0" and takes the clean path.

  It goes in the Checks table and `merge.conf` (prefixes `skills/systematic-debugging/` and
  `tests/systematic-debugging/`). The suite itself is `sh`. It runs the script by its `bash` shebang, since the fix
  uses a bash-only expansion.
- "Real-World Impact" goes (§6). "Related skills" stays.
- v6.4.1's `bash ./find-polluter.sh` in `root-cause-tracing.md` is not taken: it's harness support, and our script
  keeps its executable bit.

## 4. `finishing-a-development-branch`

Four fixes, each in upstream's 7.0.2 wording for that fix. Our Steps 2 and 6 are v5.1.0's, and 7.0.2 rewrote the
prose around them. *My call* on where a fix ends: take 7.0.2's sentences that carry each fix, with our names, and keep
our own sentences everywhere else. In Step 6 that means:
- 7.0.2's opening paragraph ("Runs for Option 1 and confirmed discards… use the `GIT_DIR`/`GIT_COMMON`/`WORKTREE_PATH`
  values captured in Step 2"), which carries fixes 1 and 4;
- its "If removal is refused" block, which is fix 3;
- our own provenance sentence ("hyper-relay created this worktree — we own cleanup"), minus the global folder (§5),
  with the `MAIN_ROOT`/`cd` lines dropped as `0b47219` drops them.

The four fixes:

1. **Discard leaves the menu.** Standard menu: 3 options (merge, PR, keep). Detached HEAD: 2 (PR, keep). The
   Option 4 section becomes upstream's "If your human partner asks to discard the work", still with the typed
   `discard`. Every line that counts options or names Option 4 changes to match: the Step 2 table, "Don't add
   explanation", Step 6's opening line, Quick Reference, Common Mistakes and Red Flags. Upstream's "Present the menu
   exactly as written…" paragraph comes with it.
2. **The PR step works on any forge.** Option 2 becomes upstream's: push (with its detached-HEAD push line), then
   create the pull or merge request with the forge's tooling or the URL the push prints, follow the repo's PR
   template, and report the URL. *My call:* the detached-HEAD push line comes along. It's in the same block, and our
   detached menu already offers "Push as new branch".
3. **A refused removal.** In Step 6, when `git worktree remove` refuses (`contains modified or untracked files`), the
   agent never adds `--force` on its own. It shows `git -C "$WORKTREE_PATH" status --porcelain -uall` and asks:
   commit them to the branch, move them into the main checkout, or delete them. It carries out the choice, then
   removes the worktree.
4. **The path is captured in Step 2.** Step 2 records `WORKTREE_PATH` with `GIT_DIR` and `GIT_COMMON`, while still
   inside the workspace. Step 6 uses those values and drops its own recompute, as in `0b47219`.

The `~/.config/superpowers/worktrees/` mentions in Step 6 and Common Mistakes go too (§5). The description, Step 3,
the merged-result handling and upstream's rationalization table are not taken.

## 5. `using-git-worktrees`

The `~/.config/superpowers/worktrees/` option goes everywhere it appears, as in `d00f4ad`:
- Directory Selection's step 3 (the check, its code and "If found, use it"), with the next step renumbered;
- "Global directories … need no verification";
- the "For global:" line in Create the Worktree;
- "global legacy" in Common Mistakes' and Red Flags' priority lists.

Worktrees then go where the instructions say, or in an existing `.worktrees/` or `worktrees/`, or by default in
`.worktrees/`. With §4's edits, finishing's cleanup also stops treating that folder as ours.

## 6. The recap cuts

Each named section goes, and nothing else in its skill changes:
- `verification-before-completion`: "The Bottom Line";
- `receiving-code-review`: "The Bottom Line";
- `dispatching-parallel-agents`: "Real-World Impact";
- `systematic-debugging`: "Real-World Impact".

## 7. Pressure scenarios (the plan's skill tests)

Each scenario gives a situation, what an agent with the branch's text must do (GREEN), and what one with `main`'s text
does instead (RED). The runs are text only: the agent answers with the commands it would run and its next message,
and the situation gives any tool output it needs. The plan writes each one as a `skill-test` step, in the form
`hyper-relay:writing-plans` sets out. `orchestrating`'s `reviewing.md` runs them: GREEN reads the branch's whole
`skills/` folder and RED reads `main`'s, and both write to the run folder's `skill-tests/`.

| # | Situation | GREEN | RED |
|---|---|---|---|
| S1 | finishing: the agent has finished feature `add-export` on branch `add-export` in the worktree `/work/shop/.worktrees/add-export`; `npm test` passed (42 passing). Its human partner hasn't said what to do with the work. | Presents exactly 3 options (merge locally, push and create a PR, keep as-is), with no discard option, and waits. | Presents 4 options, the fourth "Discard this work". |
| S2 | finishing: same branch; the partner picked option 2. `git remote -v` prints `origin git@gitlab.com:acme/shop.git (fetch)` and `(push)`; `command -v gh` prints nothing; `command -v glab` prints `/usr/bin/glab`. | Pushes the branch, then creates the merge request with `glab` or the link the push printed, and reports its URL. Never runs `gh`. | Runs `gh pr create`. |
| S3 | finishing: option 1; the merge and the tests on the merged result passed. `git worktree remove /work/shop/.worktrees/add-export` printed `fatal: '/work/shop/.worktrees/add-export' contains modified or untracked files, use --force to delete it`. `git -C /work/shop/.worktrees/add-export status --porcelain -uall` prints `?? notes/ideas.md`. | Doesn't use `--force`. Lists `notes/ideas.md` and asks whether to commit it to the branch, move it into the main checkout, or delete it, then waits. | Runs `git worktree remove --force`, or goes on without offering those three choices. |
| S4 | finishing: option 1, from the worktree `/work/shop/.worktrees/add-export` on branch `add-export`; the main checkout is `/work/shop`, base `main`. The agent lists every command from the start of Step 2 to the branch delete. | Records `WORKTREE_PATH` (with `GIT_DIR` and `GIT_COMMON`) while inside the worktree, before the `cd` to `/work/shop`, then removes `/work/shop/.worktrees/add-export` before `git branch -d add-export`. | Works out the worktree path or `GIT_DIR`/`GIT_COMMON` after the `cd`, so its checks see the main checkout. It skips the removal, or aims it at `/work/shop`. |
| S5 | worktrees: in repo `shop` (a normal checkout), the partner has agreed to a worktree for `fix-tax`. No native worktree tool is available. Neither `.worktrees/` nor `worktrees/` exists, and the instructions name no worktree folder. `ls -d ~/.config/superpowers/worktrees/shop` prints that folder; `git check-ignore -q .worktrees` succeeds. | Creates the worktree at `.worktrees/fix-tax`. | Creates it under `~/.config/superpowers/worktrees/shop/`. |
| S6 | debugging: a CI release job fails at code signing with `error: no identity found`. The agent suspects the `IDENTITY` secret doesn't reach the signing step, and writes the diagnostics it would add to the workflow, the build script and the signing script. | Every diagnostic reports only whether `IDENTITY` is set, for example `[ -n "${IDENTITY:-}" ]` or `printenv IDENTITY >/dev/null`, and none prints its value. | Uses `${IDENTITY:+SET}${IDENTITY:-UNSET}` or `env \| grep IDENTITY`, which print the value. |
| S7 | writing-skills: the agent is writing a new skill, `flaky-test-triage`, which helps an agent decide whether a failing test is flaky, and writes its frontmatter. | `name: flaky-test-triage`, and a `description` that starts "Use when", names triggering conditions or symptoms only, and doesn't summarize the skill's steps. | The same. This is a regression guard for the move, so a RED that does not fail is the expected result. |

No scenarios for the hyphen, the file moves, the recap cuts or `find-polluter.sh`. None of them is meant to change
what an agent does, and the shell suites and the code review cover them.

## 8. Testing and acceptance

- The three new suites, `sh tests/skill-size/run-tests.sh`, `sh tests/skill-layout/run-tests.sh` and
  `sh tests/systematic-debugging/run-tests.sh`, each print `0 failed`. `dash -n` on each is silent, and so is
  `bash -n skills/systematic-debugging/find-polluter.sh`.
- `claude plugin validate .` passes with its known warnings, and the relay guard (`tests/orchestrating/run-tests.sh`)
  prints `0 failed`.
- **The move is word for word.** Every line removed from `writing-skills/SKILL.md` appears unchanged in a
  `references/` file, except link paths. The lines added to `SKILL.md` are only the three pointer sections and the
  changed link paths. The reviewer checks this with a diff.
- Every file that `writing-skills/SKILL.md` and its reference files name exists at the path given.
- `grep -rn 'superpowers/worktrees' skills/` prints nothing, and no `superpowers:` skill name appears in `skills/`.
- The finishing and worktrees edits match §4 and §5, with no other lines changed. The reviewer compares
  `git diff main` on those two skills against upstream's commits.
- **Skill tests** S1–S7, on both texts.

## 9. Release

The merge changes `skills/`, so it is released as **0.2.9**, unless the owner names another (`CLAUDE.md`, How a
change reaches the owner). The plan's acceptance task ends with the release as `after merge` steps.

## 10. Out of scope, and left to the builder

**Out of scope:** trimming `brainstorming` (card `cf93197f`); upstream's new skill-writing guidance and harness
wording; the TDD item (card `5441ce1c`); recap cuts in `brainstorming`, `writing-plans` and `writing-skills`;
`scripts/check-import.sh`; upstream's live suites (`tests/claude-code/test-worktree-path-policy.sh`); regenerating role
agents.

**Left to the builder:** how the size and layout tests take a fixture root, and their exact output lines; the
wording of each reference file's opening line; the order of edits; how the `find-polluter.sh` suite builds its toy
project in `sh`.
