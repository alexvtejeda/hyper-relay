# hyper-relay: a lighter orchestrator, Plan 1: `relay-plan` Implementation Plan

**Card:** A lighter orchestrator context: clear any time, owner decisions on the board (`b43e3367-79eb-4289-a7dd-41edf35f95c2`)
**Spec:** `docs/superpowers/specs/2026-11-20-hyper-relay-lighter-orchestrator-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–6 are
> the executor's. Task 7 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `owner` and
> `after merge` steps are the owner's and the orchestrator's. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `relay-plan`, the command the orchestrator will ask about a plan instead of reading it (the hand-back
checks, the overlap with plans in flight, the acceptance steps by who runs them, one step's text, the skill-test
situations as files) and that keeps each plan's run folder and its `gates.log`; and let `.hyper-relay/agents.md`'s
header carry `fix-rounds`.

**Architecture:** One POSIX script, `bin/relay-plan`, run by dash like `bin/relay-merge`, with one subcommand per row of
the Contract's table. One awk scanner reads a plan into records (its line, whether it is inside a fence and which, its
task, its step), and every command that reads a plan filters those records, so fences are handled in one place
(Tasks 2–5). `tests/relay-plan/run-tests.sh` drives it on temporary git repos with three fixture files.
`bin/hyper-relay-agents` accepts `fix-rounds` and changes no generated file for it (Task 1). `docs/relay-plan.md`,
`.hyper-relay/merge.conf` and `CLAUDE.md` follow (Task 6). Plan 2 (the skills) calls the command only through the
Contract below.

**Tech Stack:** POSIX `sh` run by dash; git 2.31 or later (`--path-format`); `awk`, `sed`, `grep`, coreutils;
Markdown. No skill changes, so no `skill-test` steps.

**How this was checked:** written against `main` at `8fd43cf`, by reading only; nothing was built, run or generated.
The spec flags no fact for re-check, and no assumption about an outside system was needed.

---

## Execution notes (binding)

- **No `relay-plan` on `PATH` is this one.** The installed plugin (0.2.5) has none. Run the branch's as
  `dash bin/relay-plan`, and in the suite as `dash "$RP"`.
- **Never run `run-dir` or `gate` against this checkout.** They write this repo's `.git/info/exclude` and create
  `.hyper-relay/runs/` in the main checkout, which is the owner's state. Every test works in its own temporary repo.
- **Tests run git isolated,** as `tests/relay-merge/run-tests.sh` does: `HOME` inside the temporary root,
  `GIT_CONFIG_NOSYSTEM=1`, the four `GIT_AUTHOR_*` and `GIT_COMMITTER_*` values, `GIT_CEILING_DIRECTORIES` set to the
  temporary root, and `GIT_DIR` and `GIT_WORK_TREE` unset.
- **`bin/relay-plan` uses `set -u` and not `set -e`:** `gate` must outlive its command's failure, and every step checks
  its own status, as `bin/hyper-relay-agents` does. It sets `LC_ALL=C`, so sorting and matching are bytewise. Mode
  `100755`, as its siblings in `bin/`.
- **The suites are the contract.** `tests/hyper-relay-agents/run-tests.sh` keeps every existing assertion except the
  one spec §2 changes, line 130's list of keys (Task 1), and its header's `Expect:` count. Needing to change any other
  is a stop.
- **Text is written exactly** where a step says "with exactly this content" or "Replace X with Y" (the Edit tool, X as
  `old_string`): `docs/relay-plan.md`, `CLAUDE.md`, `.hyper-relay/merge.conf` and the fixtures. A block's own fence
  lines are not part of the text; fences inside a longer fence are. Do not reflow. If an X is not found, read the range
  again; if it moved or differs slightly, adapt as little as possible and record a deviation; if it is gone, stop.
- **The Contract below is binding,** word for word: the command's names, arguments, outputs and exit codes, the run
  folder and `gates.log`. A spec value it pins, verbatim: `fix-rounds must be a whole number from 1 to 9`; the exclude
  line `.hyper-relay/runs/`.
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.5; Task 7 releases 0.2.6
  after the merge. Do not run `claude -p` or upstream's live suites.
- **The full gates** (Task 6 Step 4): `sh tests/relay-plan/run-tests.sh`, `dash -n bin/relay-plan`,
  `sh tests/hyper-relay-agents/run-tests.sh`, `sh tests/hyper-relay-agents/guard-test.sh`, `dash -n bin/hyper-relay-agents`,
  `sh tests/orchestrating/run-tests.sh` (it reads `CLAUDE.md`) and `claude plugin validate .`.
- **Task 7 is not yours.**

## Review Focus

1. **A plan that quotes plans or skill text in fences** (a four-backtick text step holding `### Task 9`,
   `- [ ] **Step 9 (…)`, `- Modify:`, `git commit` and `Plan-Task:` lines; a `text` block holding a `## ` line): nothing
   inside a fence counts as a task, step, heading, trailer, path or placeholder. Task 3 Step 1 (`tasks 3`, five steps),
   Task 4 Step 1 (the good plan passes), Task 5 Step 1 (the fenced path is not shared).
2. **A step title that wraps onto the next line, and a who with words after it** (`` (`owner`; the orchestrator
   runs …) ``, `` (`after merge`, last) ``): `steps` prints the who from the backticks and the whole title on one line.
   Task 3 Step 1.
3. **A gate whose output is empty or has no final newline:** `EXIT` stays on its own line, and `gates` shows
   `(no output)`. Task 2 Step 1.
4. **`gate` from a subfolder or a linked worktree:** the command runs at that checkout's top, the block carries that
   checkout's `HEAD`, the log lands in the main checkout's run folder, and nothing is written in the worktree. Task 2
   Step 1.
5. **A local exclude file whose last line has no newline, and `run-dir` run twice:** the line lands on its own line,
   once. Task 2 Step 1.

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §12: how `check` detects "a task that commits" is the builder's | A task commits when a line inside one of its `bash`, `sh` or `shell` fences starts, after spaces, with `git` and its git subcommand (the first word after `git` and its options, `-C <path>` and `-c <name>=<value>` included) is `commit`. A trailer is `Plan-Task: <value>` whose `<value>` (up to a space or a quote) ends in `#<digits>`, and it counts only inside such a fence. Prose mentions and placeholders (`<plan path>#<N>`) are not trailers, and neither is anything in a `markdown` or `text` fence, so a plan that quotes another plan or a skill is read right. The acceptance task (the last) needs no trailer, since its commits are the release's (the companion-hardening plan's Task 7 has none, and §1 says that plan passes); a trailer there must still be its own. |
| P2 | Contract: checks run "outside fences" | A fence opens, outside a fence, on a line of at least three backticks or tildes after optional spaces or tabs; its info is the first word after them. A backtick line whose info holds a backtick is not a fence (a line that starts with inline code). It closes on a line of the same character, at least as many, then only spaces. Fences do not nest: what is inside is content. |
| P3 | Contract: "the acceptance task", its steps | A task is a `### Task <N>` heading outside a fence, and runs to the next `## ` or `### ` heading outside a fence, or the end. `tasks <N>` counts those headings; `acceptance task <M>` is the last one's number. A step is a line `- [ ] **Step <id>` (or `[x]`) outside a fence, and runs to the next step or the task's end. Its who is the first inline-code span in the parenthesis after `**Step <id> (`, as written; `?` when there is none. Its title runs from after the first `): ` to the next `**`, joined with one space across lines when it wraps. A step without the parenthesis has the text after `**Step <id>` as its title, without a leading colon. |
| P4 | Contract: `Situation:` with a ```` ```text ```` fence, `GREEN must:`, `RED is expected to:` | Each label starts a line outside a fence, and may be bold (`**Situation:**`). `check` wants the first fence opened after `Situation:`, within the step, to have the info `text`. `scenarios` takes that first fence whatever its info, so a plan written before the rule still yields its situations. |
| P5 | Contract: "any detail under a FAIL at most 5 lines" | A FAIL line carries the first problem; each further problem is a line under it, indented by two spaces, at most 5; when more remain, the 5th reads `  and <k> more`. Task 4 Step 3 pins each problem's text. |
| P6 | Contract: `committed` ("on `main`; during a branch run, that the file exists") | When the main checkout is on `main`, `git log -1 main -- <plan>` must print a commit; otherwise (a branch run) the file must exist. |
| P7 | Contract: `overlap`'s `<other>` "is a plan path or an in-flight branch" | An `<other>` that is an existing file is a plan; otherwise a local branch, whose plan is `docs/superpowers/plans/<YYYY-MM-DD>-<branch>.md` in the current checkout (the first such name in sort order); neither, or a branch with no such plan: exit 2. Paths are every inline-code item on a `- Create:`, `- Modify:` or `- Test:` line outside fences, without those starting with `:` and with a `:<digits, commas, dashes>` suffix dropped, as `parallel.md` §2's pipeline does today. Lines per `<other>`, in the order given: its `shared` lines by path, then its `numbered` lines. No overlap: no output, exit 0; any: exit 1. |
| P8 | Contract: the branch is the file name "without its `YYYY-MM-DD-` prefix and `.md`" | Each is dropped only when present (`odd.md` → `odd`). |
| P9 | Contract: `run-dir` adds the exclude line "when `git check-ignore -q .hyper-relay/runs/` fails" | Added only on exit 1; any other failure is exit 2. A newline goes first when the file does not end with one, and the file's folder is made when missing, as `start-server.sh` does for the companion. The line is `.hyper-relay/runs/`, as the Contract writes it (the companion's own line is anchored with a `/`). `gate` makes the run folder the same way when it is missing. |
| P10 | Contract: `gate` "runs `<command>` with `sh -c`" | Its stdin is `/dev/null`. A command holding a newline is refused (exit 2), since `GATE <sha> <command>` must stay one line. A newline is added before `EXIT` when the output does not end with one, and the same in what it prints. |
| P11 | Contract: `gates` reads blocks | A block starts at a line `GATE <hex sha> <command>` and ends at the next line `EXIT <integer>`; a gate whose output holds a line of exactly that form would cut its block short (none of this repo's suites prints one). Commands come in the order of their first block, or in the order named. `<short sha>` is the sha's first 7 characters. With no non-empty output line, the last part is `(no output)`. A named command with no block: `FAIL <command>: not in gates.log`. A log with no block and no command named: exit 1. |
| P12 | Contract: `scenarios` writes "its fenced text, without the fence" | Verbatim. A placeholder line such as the companion-hardening plan's `<CONTEXT>`, which pointed at a block outside the step, is written as it is and expanded by nothing. Plan 2's `writing-plans` text decides whether a situation must be whole. A `skill-test` step without one prints `FAIL <id>: no fenced situation`; no `skill-test` step at all is exit 1. |
| P13 | Contract: `steps` exit codes | After its first line, exit 1 when no step matches (none at all, or none of the who asked for); a plan with no task prints nothing and exits 1; an unknown who is exit 2. |
| P14 | §2: the generator accepts `fix-rounds` | Valid is one digit from 1 to 9; an empty value is refused too. The unknown-key message lists `fix-rounds` after `execute`. |
| P15 | §1: `merge.conf` gains `relay-plan`'s lines | `relay-merge` reads `main`'s committed `merge.conf`, so the new lines gate later branches: this branch's merge runs `main`'s current lines (`bin/hyper-relay-agents`, `tests/hyper-relay-agents/`, `CLAUDE.md`), and Task 7 Step 7 runs `relay-plan`'s suite on `main` after the merge. |
| P16 | §10: the reviewer "runs `relay-plan` against this repo's own merged plans … and reports what it prints"; L2: no reviewer step reruns the gates | The reviewer runs no gate. Step 1 is PASS or FAIL on the companion-hardening plan (§1: it passes every check). Step 2 runs `check` and `steps` on every other plan and judges each FAIL: a real gap in an older plan, or a misreading by `relay-plan` (which is the FAIL). Step 3 is a live run of `run-dir`, `gate` and `gates` in a scratch repo. |
| P17 | §1: `docs/relay-plan.md`, "as `docs/relay-merge.md` is `relay-merge`'s" | It gives the symlink line for a shell's `PATH`, as that doc does. The owner (stop 3, 2026-11-20): Task 7 Step 9, after the release, links `~/.local/bin/relay-plan` to this main checkout's `bin/relay-plan`, as `wt` and `relay-merge` are linked, so that an OpenCode orchestrator or the owner's shell finds `relay-plan` by name; `CLAUDE.md`'s "How a change reaches the owner" gains its bullet (Task 6 Step 3). |

## Contract

Both plans carry this section, identical.

**The run folder.** One per plan: `<main checkout>/.hyper-relay/runs/<branch>/`, where the main checkout is the parent
of `git rev-parse --path-format=absolute --git-common-dir`, and `<branch>` is the plan's file name without its
`YYYY-MM-DD-` prefix and `.md` (`dispatching.md` §3's rule). Git ignores `.hyper-relay/runs/`. It holds:

| Path | Written by | What |
|---|---|---|
| `executor.md` | the executor | its full report; each fix round appends a `## Fix round <k>` section |
| `gates.log` | `relay-plan gate` | every gate run, in blocks (below) |
| `acceptance/` | the acceptance reviewer | its evidence files, and `report.md`, its full report |
| `code-review.md` | the code reviewer | its full review |
| `plan-review.md` | the plan reviewer | its full findings |
| `skill-tests/` | the orchestrator, the test runs, the judge | `red/`, `green/`, `step-<id>.txt`, `step-<id>-green.md`, `step-<id>-red.md`, `verdicts.md` |
| `status` | the orchestrator | without Quartz only: the plan's one-line status |
| `cards.md` | any agent | without Quartz only: proposed cards, one `## ` section each |

A brainstorm without Quartz keeps its decisions in `<main checkout>/.hyper-relay/runs/<topic>/brainstorm.md`.

**`gates.log`.** Blocks, appended. Each starts with a line `GATE <full sha> <command>` (the checkout's `HEAD` when the
gate ran), then the command's stdout and stderr, then a line `EXIT <code>`. It is only ever appended to: a command
is known by its exact text, so the executor's summary names each gate by the text it gave `relay-plan gate`, and the
orchestrator passes the same text to `relay-plan gates`.

**Files over time.** `relay-plan run-dir` only creates; it never clears anything. A fresh executor (not a fix round)
writes `executor.md` anew; a fix round appends its section. Older blocks in `gates.log` stay and are judged by their
sha.

**`relay-plan`.** POSIX shell, run by dash, at `bin/relay-plan`; Claude Code puts it on `PATH` as it does
`relay-merge`. A `<plan>` is a path relative to the repo's top, or absolute. Output is short by design: one line per
item, and any detail under a FAIL at most 5 lines. Exit 0 means all ok, 1 a check failed or nothing was found, 2 a
usage error or a missing file.

| Command | Does | Prints |
|---|---|---|
| `relay-plan run-dir <plan>` | creates the plan's run folder; when `git check-ignore -q .hyper-relay/runs/` fails in the main checkout, adds a `.hyper-relay/runs/` line to the file `git rev-parse --git-path info/exclude` prints there | the folder's absolute path |
| `relay-plan check <plan> [--spec <spec>] [--sibling <plan>]… [--base <plan>]` | `planning.md` §2's checks that need no MCP: `committed` (on `main`; during a branch run, that the file exists), `card` (with `--spec`: when the spec names a card, the plan's header has a `**Card:**`/`**Cards:**` line or a `**Spec:**` line naming the spec), `trailers` (each task that commits carries `Plan-Task: <plan path>#<N>` once, its own N and path), `acceptance` (the last task's steps each name a who from the four), `skill-tests` (each `skill-test` step has `Situation:` with a ```` ```text ```` fence, `GREEN must:` and `RED is expected to:`), `placeholders` (`planning.md` §2's pattern, outside fences and inline code), `coverage` (with `--spec`: every `## ` heading of the spec is in the Spec coverage table), `contract` (with `--sibling`: identical `## Contract` sections), `builds-on` (with `--base`: the header's `**Builds on:**` names it) | `ok <check>` or `FAIL <check>: <detail>`, one per check run |
| `relay-plan overlap <plan> <other>…` | `parallel.md` §2's conflict check; an `<other>` is a plan path or an in-flight branch (its plan's paths plus `git diff --name-only main...<branch>`) | `shared <path> (<other>)` and `numbered <folder><digits> (<other>)`, one per overlap |
| `relay-plan steps <plan> [reviewer\|owner\|after-merge\|skill-test]` | lists the acceptance task's steps, all or one who's (the argument `after-merge` selects the plan's `after merge` steps) | first `tasks <N>; acceptance task <M>`, then `<id>`, tab, `<who>` as the plan writes it (`after merge` with its space), tab, `<title>` per step |
| `relay-plan step <plan> <id>` | one acceptance step's full text, from its `- [ ] **Step` line to the next step or the task's end | the step |
| `relay-plan scenarios <plan> <dir>` | writes each `skill-test` step's situation (its fenced text, without the fence) to `<dir>/step-<id>.txt`; exit 1 when a `skill-test` step has no fenced situation | `<id>`, tab, `<file>`, tab, `<title>` per scenario |
| `relay-plan gate <plan> <command>` | runs `<command>` with `sh -c` from the top of the current checkout (the main checkout or a worktree), appends its block to the plan's run folder's `gates.log` (found through the main checkout, as `run-dir` finds it), and exits with the command's code | the output's last 5 lines, then `EXIT <code>` |
| `relay-plan gates <plan> [<command>…]` | for each command in `gates.log` (or each one named, matched by exact text), takes its latest block; FAIL when its exit is not 0, or its sha is not `git rev-parse refs/heads/<branch>`; exit 2 when the branch or the log does not exist. With no command named after a fix round, the full gates' blocks are older than the tip and FAIL: that is by design, and the check after a fix round names its commands | `ok\|FAIL <command>: exit <code> at <short sha>: <last non-empty output line>` per command |

**`fix-rounds`.** An optional key in `.hyper-relay/agents.md`'s header: `fix-rounds: <n>`, a whole number from 1 to 9;
absent means 2. The generator accepts it and changes no generated file for it; any other value is refused with
`fix-rounds must be a whole number from 1 to 9`. The orchestrator reads it from `main`'s facts file, as it reads
`execute:`.

**The label.** A card filed by the relay without the owner asking for it carries the label `proposed`.

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 2–5 (the command the lighter orchestrator routes through); the rest is Plan 2's |
| Decisions (owner, 2026-11-20) | L2: 2 (`gate`, `gates`). L4: 1 (`fix-rounds`). L6: 2–5. L8: this plan is Approach A's Plan 1. L1, L3, L5: Plan 2's. L7: out |
| How it works | 1 (the header refuses unknown keys), 2 (the exclude line; the main checkout from a worktree), 3 and 4 (the acceptance steps' form) |
| Approaches | No task: Approach A is this plan and its sibling |
| The plans | 1–6 (Plan 1's list); 7 (the release) |
| Contract | 1 (`fix-rounds`); 2 (the run folder, `gates.log`, `run-dir`, `gate`, `gates`); 3 (`steps`, `step`, `scenarios`); 4 (`check`); 5 (`overlap`); 6 (the user reference). The label: Plan 2's |
| 1. `bin/relay-plan` (Plan 1) | 2–5 (the command and its suite), 6 (`docs/relay-plan.md`, `merge.conf`, `CLAUDE.md`), 7 (Step 9, the symlink) |
| 2. `fix-rounds` (Plan 1) | 1 |
| 3. The board holds the state (Plan 2) | No task: Plan 2's |
| 4. The run folder and short hand-backs (Plan 2) | No task: Plan 2's (this plan's `run-dir` makes the folder) |
| 5. No check runs twice (Plan 2) | No task: Plan 2's (this plan's `gate` and `gates` are its tools) |
| 6. The owner's decisions on the board (Plan 2) | No task: Plan 2's (`fix-rounds`, Task 1, is the cap's setting) |
| 7. Routing by path (Plan 2) | No task: Plan 2's (Tasks 3–5 make the commands it routes through) |
| 8. The other files (Plan 2) | No task: Plan 2's |
| 9. Pressure scenarios (Plan 2's skill tests) | No task: Plan 2's |
| 10. Testing and acceptance | 6 (the executor's gates); 7 (Steps 1–4 the reviewer's, 7 the re-check on `main`) |
| 11. Releases | 7 (Steps 8 and 10: 0.2.6) |
| 12. Out of scope, and left to the builder | No task; the builder's calls are P1–P17 |

## File structure

- **Create:** `bin/relay-plan` (Tasks 2–5; mode `100755`), `tests/relay-plan/run-tests.sh` (Tasks 2–5),
  `tests/relay-plan/fixtures/plan.md` (Task 3), `tests/relay-plan/fixtures/spec.md` and
  `tests/relay-plan/fixtures/sibling.md` (Task 4), `docs/relay-plan.md` (Task 6).
- **Modify:** `bin/hyper-relay-agents` and `tests/hyper-relay-agents/run-tests.sh` (Task 1); `.hyper-relay/merge.conf`
  and `CLAUDE.md` (Task 6).
- **Unchanged:** `skills/`, `templates/`, `hooks/`, `.claude-plugin/`, `package.json`, `README.md`,
  `.hyper-relay/agents.md`, every other suite.

---

### Task 1: The `fix-rounds` key (spec §2; the Contract's `fix-rounds`; P14)

**Files:**
- Modify: `bin/hyper-relay-agents:179-192` (`validate`)
- Test: `tests/hyper-relay-agents/run-tests.sh` (line 130's list; a new section after `--- the execute key`; the
  header's `Expect:`)

- [x] **Step 1: Write the failing tests.** Line 130's expected text becomes
  `(the keys are project, reviewer, execute, fix-rounds, model.planner, model.executor and model.reviewer)`. A new
  section, `echo '--- the fix-rounds key'`, after the execute key's, with the suite's own helpers:

```sh
new_plugin
new_repo
gen "$R"
# copy the four generated files ($R/$AG/demo-{planner,executor,reviewer}.md and $R/$GD) aside, outside $R
facts_header 'fix-rounds: 3'
gen "$R"
assert_eq "fix-rounds: 3 is accepted" 0 "$RC"
assert_eq "fix-rounds: nothing is rewritten" "unchanged .claude/agents/demo-planner.md
unchanged .claude/agents/demo-executor.md
unchanged .claude/agents/demo-reviewer.md
unchanged .claude/hooks/hyper-relay-planner-guard.py" "$OUT"
# for each of the four files: assert_eq "fix-rounds: <file> is the same, byte for byte" yes <cmp -s of the copy and the file>
for v in 1 9; do
    new_repo
    facts_header "fix-rounds: $v"
    gen "$R"
    assert_eq "fix-rounds: $v is accepted" 0 "$RC"
done
for v in 0 10 two ''; do
    new_repo
    facts_header "fix-rounds: $v"
    gen "$R"
    assert_eq "fix-rounds: \"$v\" is refused: exit 1" 1 "$RC"
    assert_contains "fix-rounds: \"$v\" is refused: the message" "fix-rounds must be a whole number from 1 to 9" "$OUT"
    assert_eq "fix-rounds: \"$v\" is refused: nothing written" no "$(exists "$R/.claude")"
done
```

- [x] **Step 2: Run them to verify they fail**

Run: `sh tests/hyper-relay-agents/run-tests.sh | grep -c '^FAIL'`
Expected: a number above 0: `fix-rounds: 3 is accepted` fails (`unknown header key fix-rounds`), and so does line 130's.

- [x] **Step 3: Implement it in `validate`.** A `fix-rounds)` case beside `execute)`: a value that is not one digit
  from 1 to 9 (`[1-9]` as a `case` pattern) gets `problem "fix-rounds must be a whole number from 1 to 9"`; the value is
  not stored or used. The unknown-key problem becomes
  `unknown header key $key (the keys are project, reviewer, execute, fix-rounds, model.planner, model.executor and model.reviewer)`.
  Nothing else changes. The header's `Expect:` count becomes the suite's new total.

- [x] **Step 4: Run the tests to verify they pass**

Run: `sh tests/hyper-relay-agents/run-tests.sh | tail -n 1`, then `dash -n bin/hyper-relay-agents`
Expected: `<n> passed, 0 failed`, with `<n>` the header's `Expect:` count; `dash -n` silent.

- [x] **Step 5: Commit**

```bash
git add bin/hyper-relay-agents tests/hyper-relay-agents/run-tests.sh
git commit -m "feat: the facts header accepts fix-rounds, 1 to 9" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#1"
```

### Task 2: `relay-plan`'s frame, `run-dir`, `gate` and `gates` (the Contract's run folder, `gates.log` and three rows; P8–P11)

**Files:**
- Create: `bin/relay-plan`
- Create: `tests/relay-plan/run-tests.sh`

**Interfaces:**
- Produces, in `bin/relay-plan`: `TOP` (the current checkout's top) and `MAIN` (the main checkout); `abs_path <path>`
  (a relative path under `TOP`, an absolute one unchanged) and `rel_path <path>` (an absolute path under `TOP` without
  `$TOP/`, a relative one unchanged); `need_file <path>` (exit 2, `relay-plan: no such file: <path>`, unless it is a
  file); `branch_of <path>` (P8); `ensure_run_dir <branch>` (P9; prints the folder's absolute path, no trailing `/`);
  `usage_error <message>` (the message and the usage line on stderr, exit 2).
- Produces, in the suite: `RP`; `new_repo` (sets `CASE` and `MAIN`); `files_plan <path> <line>…`; `commit_all <message>`;
  `commit_in <checkout> <file> <text>`; `rp <dir> <arg>…` (sets `OUT`, `ERR`, `RC`); `exists <path>`.

- [x] **Step 1: Write the failing tests** in `tests/relay-plan/run-tests.sh`. The harness and isolation are
  `tests/relay-merge/run-tests.sh`'s (`ok`, `bad`, `assert_eq`, `assert_contains`, `assert_not_contains`, the summary
  line `<n> passed, <m> failed`, a non-zero exit on any failure; the Execution notes' git settings). The header says
  what it tests and `Expect: "<n> passed, 0 failed"`. Its fixtures:

- `RP="${RELAY_PLAN_BIN:-$HERE/../../bin/relay-plan}"`.
- `new_repo`: `CASE` a new folder under the temporary root; `MAIN="$CASE/proj"`, `git init -q -b main`; its
  `.git/info/exclude` holds exactly `# new_repo` and a newline; a `README` committed as `init`.
- `files_plan <path> <line>…`: writes `$MAIN/<path>`, making its folder. Given
  `docs/superpowers/plans/2026-01-02-demo-plan.md` and the two lines shown last below, it writes:

  ```text
  # Plan

  ### Task 1: Files

  **Files:**
  - Create: `db/000097_orders.sql`
  - Modify: `src/main.sh:10-20`
  ```

- `commit_all <message>`: stages everything in `$MAIN` and commits. `commit_in` as `tests/relay-merge/`'s.
- `rp <dir> <arg>…`: runs `dash "$RP" <arg>…` with `<dir>` as the working directory and stdin from `/dev/null`;
  `OUT` its stdout and `ERR` its stderr (each without trailing newlines), `RC` its exit.

`P` is `docs/superpowers/plans/2026-01-02-demo-plan.md`. The checks, in this order:

```sh
echo '--- usage'
new_repo
rp "$MAIN"
assert_eq "no command: exit 2" 2 "$RC"
assert_contains "no command: the usage" "usage: relay-plan" "$ERR"
rp "$MAIN" frobnicate "$P"
assert_eq "an unknown command: exit 2" 2 "$RC"
rp "$MAIN" run-dir docs/nope.md
assert_eq "a missing plan: exit 2" 2 "$RC"
assert_contains "a missing plan: named" "no such file: docs/nope.md" "$ERR"
rp "$CASE" run-dir "$P"
assert_eq "outside a repo: exit 2" 2 "$RC"

echo '--- run-dir'
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: exit 0" 0 "$RC"
assert_eq "run-dir: prints the folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir: the folder exists" yes "$(exists "$MAIN/.hyper-relay/runs/demo-plan")"
assert_eq "run-dir: the exclude file gains the line" "# new_repo
.hyper-relay/runs/" "$(cat "$MAIN/.git/info/exclude")"
rp "$MAIN" run-dir "$MAIN/$P"
assert_eq "run-dir again, by an absolute path: the same folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir again: the line is there once" 1 "$(grep -c -x -F '.hyper-relay/runs/' "$MAIN/.git/info/exclude")"
: > "$MAIN/.hyper-relay/runs/demo-plan/executor.md"
assert_eq "run-dir: git status shows none of it" "" "$(git -C "$MAIN" status --porcelain --untracked-files=all)"
files_plan docs/superpowers/plans/odd.md '- Modify: `x`'
rp "$MAIN" run-dir docs/superpowers/plans/odd.md
assert_eq "run-dir: a name without a date" "$MAIN/.hyper-relay/runs/odd" "$OUT"

new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
printf '# kept' > "$MAIN/.git/info/exclude"
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: an exclude file without a last newline: the line on its own" "# kept
.hyper-relay/runs/" "$(cat "$MAIN/.git/info/exclude")"

new_repo
printf '.hyper-relay/\n' > "$MAIN/.gitignore"
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
rp "$MAIN" run-dir "$P"
assert_eq "run-dir: already ignored: exit 0" 0 "$RC"
assert_eq "run-dir: already ignored: the exclude file is untouched" "# new_repo" "$(cat "$MAIN/.git/info/exclude")"

new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
git -C "$MAIN" worktree add -q "$CASE/wt" -b demo-plan
rp "$CASE/wt" run-dir "$P"
assert_eq "run-dir from a worktree: the main checkout's folder" "$MAIN/.hyper-relay/runs/demo-plan" "$OUT"
assert_eq "run-dir from a worktree: the main repo's exclude file" 1 "$(grep -c -x -F '.hyper-relay/runs/' "$MAIN/.git/info/exclude")"
assert_eq "run-dir from a worktree: nothing in the worktree" no "$(exists "$CASE/wt/.hyper-relay")"

echo '--- gate'
new_repo
files_plan "$P" '- Modify: `src/main.sh`'
commit_all plan
git -C "$MAIN" switch -q -c demo-plan
TIP=$(git -C "$MAIN" rev-parse HEAD)
SHORT=$(printf '%s' "$TIP" | cut -c1-7)
LOG="$MAIN/.hyper-relay/runs/demo-plan/gates.log"
rp "$MAIN" gate "$P" 'echo one; echo two'
assert_eq "gate: exit 0" 0 "$RC"
assert_eq "gate: the output, then EXIT" "one
two
EXIT 0" "$OUT"
assert_eq "gate: makes the folder and writes the block" "GATE $TIP echo one; echo two
one
two
EXIT 0" "$(cat "$LOG")"
rp "$MAIN" gate "$P" 'seq 7'
assert_eq "gate: only the last 5 lines" "3
4
5
6
7
EXIT 0" "$OUT"
rp "$MAIN" gate "$P" 'echo bad >&2; exit 3'
assert_eq "gate: exits with the command's code" 3 "$RC"
assert_eq "gate: stderr is part of the output" "bad
EXIT 3" "$OUT"
rp "$MAIN" gate "$P" "printf 'no newline'"
assert_eq "gate: EXIT on its own line" "no newline
EXIT 0" "$(tail -n 2 "$LOG")"
rp "$MAIN/docs" gate "$P" pwd
assert_eq "gate: from a subfolder, runs at the top" "$MAIN
EXIT 0" "$OUT"
rp "$MAIN" gate "$P" true
assert_eq "gate: no output" "EXIT 0" "$OUT"
rp "$MAIN" gate "$P" 'echo a
echo b'
assert_eq "gate: a command with a newline: exit 2" 2 "$RC"
assert_eq "gate: the log has one block per run" 6 "$(grep -c '^GATE ' "$LOG")"

echo '--- gates'
rp "$MAIN" gates "$P"
assert_eq "gates: exit 1 when one failed" 1 "$RC"
assert_eq "gates: each command's latest block, in order" "ok echo one; echo two: exit 0 at $SHORT: two
ok seq 7: exit 0 at $SHORT: 7
FAIL echo bad >&2; exit 3: exit 3 at $SHORT: bad
ok printf 'no newline': exit 0 at $SHORT: no newline
ok pwd: exit 0 at $SHORT: $MAIN
ok true: exit 0 at $SHORT: (no output)" "$OUT"
rp "$MAIN" gates "$P" true 'echo one; echo two'
assert_eq "gates: the commands named, in that order" "ok true: exit 0 at $SHORT: (no output)
ok echo one; echo two: exit 0 at $SHORT: two" "$OUT"
assert_eq "gates: all ok: exit 0" 0 "$RC"
rp "$MAIN" gates "$P" 'never ran'
assert_eq "gates: a command that never ran" "FAIL never ran: not in gates.log" "$OUT"
assert_eq "gates: a command that never ran: exit 1" 1 "$RC"
commit_in "$MAIN" src/fix.sh 'fixed'
NEW=$(git -C "$MAIN" rev-parse HEAD | cut -c1-7)
rp "$MAIN" gates "$P" 'echo one; echo two'
assert_eq "gates: a block older than the tip fails" "FAIL echo one; echo two: exit 0 at $SHORT: two" "$OUT"
rp "$MAIN" gate "$P" 'echo one; echo two'
rp "$MAIN" gates "$P" 'echo one; echo two'
assert_eq "gates: the latest block counts" "ok echo one; echo two: exit 0 at $NEW: two" "$OUT"
files_plan docs/superpowers/plans/2026-01-02-no-branch.md '- Modify: `x`'
rp "$MAIN" gates docs/superpowers/plans/2026-01-02-no-branch.md
assert_eq "gates: no branch: exit 2" 2 "$RC"
git -C "$MAIN" branch no-log
files_plan docs/superpowers/plans/2026-01-02-no-log.md '- Modify: `x`'
rp "$MAIN" gates docs/superpowers/plans/2026-01-02-no-log.md
assert_eq "gates: no log: exit 2" 2 "$RC"

echo '--- gate in a worktree'
new_repo
files_plan docs/superpowers/plans/2026-01-03-wt-plan.md '- Modify: `x`'
commit_all plan
git -C "$MAIN" worktree add -q "$CASE/wt" -b wt-plan
rp "$CASE/wt" gate docs/superpowers/plans/2026-01-03-wt-plan.md pwd
assert_eq "gate in a worktree: runs at the worktree's top" "$CASE/wt
EXIT 0" "$OUT"
assert_eq "gate in a worktree: the block, in the main checkout's run folder" "GATE $(git -C "$CASE/wt" rev-parse HEAD) pwd" \
    "$(head -n 1 "$MAIN/.hyper-relay/runs/wt-plan/gates.log")"
assert_eq "gate in a worktree: nothing in the worktree" no "$(exists "$CASE/wt/.hyper-relay")"
rp "$MAIN" gates docs/superpowers/plans/2026-01-03-wt-plan.md
assert_eq "gates from the main checkout reads the worktree's runs" 0 "$RC"
```

- [x] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`
Expected: failures (`bin/relay-plan` does not exist, so only the cases that expect exit 2 can pass), and a non-zero
exit.

- [x] **Step 3: Implement `bin/relay-plan`'s frame and the three commands**

- `#!/bin/sh`; a header comment, as `bin/relay-merge`'s, with the eight commands, the exit codes and
  `docs/relay-plan.md`; `set -u`, `LC_ALL=C`; a temporary folder for the run, removed on exit.
- Dispatch on the first argument: `run-dir`, `check`, `overlap`, `steps`, `step`, `scenarios`, `gate`, `gates`;
  anything else, or no argument, is `usage_error`. The usage line starts `usage: relay-plan` and names
  `docs/relay-plan.md`. Each command checks its own argument count (exit 2).
- Outside a git repo: `relay-plan: not inside a git repository`, exit 2. `TOP` from `git rev-parse --show-toplevel`,
  `MAIN` the parent of `git rev-parse --path-format=absolute --git-common-dir`. A `<plan>` is relative to `TOP`, not
  to the working directory.
- `ensure_run_dir <branch>` (P9): `git -C "$MAIN" check-ignore -q .hyper-relay/runs/`; on exit 1, the exclude file is
  `git -C "$MAIN" rev-parse --path-format=absolute --git-path info/exclude`; make its folder, add a newline when it
  is not empty and does not end with one, append `.hyper-relay/runs/`. Then `mkdir -p` the folder.
- `run-dir <plan>`: `need_file`, then print `ensure_run_dir "$(branch_of <plan>)"`.
- `gate <plan> <command>` (P10): `need_file`; refuse a command with a newline; the sha is `git rev-parse HEAD` in
  `TOP`; run `sh -c "<command>"` from `TOP` with stdin `/dev/null`, stdout and stderr into one temporary file; append
  `GATE <sha> <command>`, the output (plus a newline when it lacks one) and `EXIT <code>` to `<run folder>/gates.log`,
  which `ensure_run_dir` gives; print `tail -n 5` of the output (the same newline rule) and `EXIT <code>`; exit with
  the code.
- `gates <plan> [<command>…]` (P11): `need_file`; the tip is `git rev-parse -q --verify refs/heads/<branch>`, else
  `relay-plan: no branch <branch>`, exit 2; the log must exist, else `relay-plan: no gates.log for <branch>`, exit 2.
  One awk pass reads the blocks, keeping per command the latest block's sha, exit and last non-empty output line, and
  the order of first appearance; the named commands reach it through a temporary file, one per line. Each line:
  `ok` when the exit is 0 and the sha equals the tip, else `FAIL`; then `<command>: exit <code> at <sha's first 7>: <line>`.
  Exit 1 when any line is `FAIL`, or when the log has no block and no command was named (stderr
  `relay-plan: no gate in <log>`).

- [x] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`
Expected: `<n> passed, 0 failed`, with `<n>` the header's `Expect:`; `dash -n` silent.

- [x] **Step 5: Commit** (`bin/relay-plan` with mode `100755`: `chmod +x` before `git add`)

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh
git commit -m "feat: relay-plan keeps a plan's run folder and its gate runs" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#2"
```

### Task 3: Reading a plan: `steps`, `step` and `scenarios` (the Contract's three rows; P2–P4, P12, P13)

**Files:**
- Modify: `bin/relay-plan`
- Create: `tests/relay-plan/fixtures/plan.md`
- Modify: `tests/relay-plan/run-tests.sh`

**Interfaces:**
- Consumes: Task 2's frame.
- Produces, in `bin/relay-plan`: `scan <file>`, which prints one record per line of `<file>`, tab-separated:
  `<line number>`, `<kind>`, `<task>`, `<step>`, `<text>`. `<kind>` is `prose`; `open:<info>` for a line that opens a
  fence, `code:<info>` for a line inside it, `close:<info>` for the line that closes it (`<info>` may be empty), all by
  P2. `<task>` is the number of the `### Task` heading the line falls under, else `0`; `<step>` the id of the step it
  falls under within that task, else `0` (both by P3, from prose lines only). `<text>` is the line unchanged, and the
  last field, so a tab in it survives. `task_summary <file>` prints `<count> <last task number>` (`0 0` with no task).
  `acceptance_steps <file>` prints `<id>`, tab, `<who>`, tab, `<title>` for each step of the last task (P3).
  `step_text <file> <id>` prints that step's lines, trailing blank lines dropped, and returns 1 when there is no such
  step.
- Produces, in the suite: `fixture_repo` (a `new_repo` holding the fixtures; sets `P`, `BASE`, `OBASE`) and
  `variant <edit>` (rewrites `$MAIN/$P` as `fixtures/plan.md` with the edit, an awk or sed program, and commits it).

- [x] **Step 1: The fixture plan, and the failing tests.** Create `tests/relay-plan/fixtures/plan.md` with exactly
  this content:

`````markdown
# Demo Implementation Plan

**Spec:** `docs/superpowers/specs/2026-01-02-demo-design.md`
**Builds on:** `docs/superpowers/plans/2026-01-01-demo-base.md`

**Goal:** A fixture for relay-plan's suite. `TODO` and `Similar to Task 1` here are inline code.

---

## Contract

Both plans share this.

| Path | What |
|---|---|
| `gates.log` | the gate runs |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1 |
| 1. The tool | 1, 2 |
| 2. Acceptance | 3 |

### Task 1: The tool

**Files:**
- Create: `src/tool.sh`
- Modify: `src/main.sh:10-20`
- Test: `tests/tool.sh`

- [ ] **Step 1: Commit**

```bash
git add src/tool.sh src/main.sh tests/tool.sh
git commit -m "feat: the tool" -m "Plan-Task: docs/superpowers/plans/2026-01-02-demo-plan.md#1"
```

### Task 2: The guide

**Files:**
- Modify: `docs/guide.md`

- [ ] **Step 1: Replace the guide with exactly:**

````markdown
### Task 9: Not a task

- Modify: `src/fenced.sh`

- [ ] **Step 9 (`owner`): Not a step**

```bash
git commit -m "x" -m "Plan-Task: docs/superpowers/plans/2026-01-09-other.md#9"
```

TBD
````

- [ ] **Step 2: Commit**

```bash
git add docs/guide.md
git commit -m "docs: the guide" -m "Plan-Task: docs/superpowers/plans/2026-01-02-demo-plan.md#2"
```

### Task 3: Acceptance. Not the executor's

```text
## Not a heading: a fenced line in the acceptance task
```

- [ ] **Step 1 (`reviewer`): The tool runs.**

| Run | PASS |
|---|---|
| `sh src/tool.sh` | exit 0 |

- [ ] **Step 2 (`skill-test`): S1, the first scenario.**

Situation:

```text
You are the orchestrator.

The plan is done.
```

GREEN must: run the tool.

RED is expected to: skip it.

- [ ] **Step 3 (`skill-test`): S2, the second scenario.**

**Situation:**

```text
You are the executor.
```

GREEN must: commit.

RED is expected to: not commit.

- [ ] **Step 4 (`owner`; the orchestrator runs the command at the click-through): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git merge-tree --write-tree main demo-plan` | exit 0 |

- [ ] **Step 5 (`after merge`, last): The release.**

```bash
git -C /tmp/demo commit -m "chore: release v1.0.1"
```

## Last-task record (Task 3)

- [ ] **Step 6 (`owner`): Not in the task.**
`````

`fixture_repo`: a `new_repo` with `fixtures/plan.md` at `$P` (`docs/superpowers/plans/2026-01-02-demo-plan.md`),
`# Base` at `$BASE` (`docs/superpowers/plans/2026-01-01-demo-base.md`) and `# Other base` at `$OBASE`
(`docs/superpowers/plans/2026-01-01-other-base.md`), committed on `main`. In the expected outputs below, `\t` is a tab
(build them with `printf`).

```sh
echo '--- steps'
fixture_repo
rp "$MAIN" steps "$P"
assert_eq "steps: the summary, then every step of the last task, nothing fenced or after it" \
  "$(printf 'tasks 3; acceptance task 3\n1\treviewer\tThe tool runs.\n2\tskill-test\tS1, the first scenario.\n3\tskill-test\tS2, the second scenario.\n4\towner\tThe branch merges cleanly.\n5\tafter merge\tThe release.')" "$OUT"
assert_eq "steps: exit 0" 0 "$RC"
rp "$MAIN" steps "$P" skill-test
assert_eq "steps: one who's" "$(printf 'tasks 3; acceptance task 3\n2\tskill-test\tS1, the first scenario.\n3\tskill-test\tS2, the second scenario.')" "$OUT"
rp "$MAIN" steps "$P" after-merge
assert_eq "steps: after-merge selects after merge" "$(printf 'tasks 3; acceptance task 3\n5\tafter merge\tThe release.')" "$OUT"
rp "$MAIN" steps "$P" owner
assert_eq "steps: a wrapped title, on one line" "$(printf 'tasks 3; acceptance task 3\n4\towner\tThe branch merges cleanly.')" "$OUT"
rp "$MAIN" steps "$P" nobody
assert_eq "steps: an unknown who: exit 2" 2 "$RC"
files_plan docs/superpowers/plans/2026-01-03-bare.md '- Modify: `x`'
rp "$MAIN" steps docs/superpowers/plans/2026-01-03-bare.md
assert_eq "steps: no step: the summary only" "tasks 1; acceptance task 1" "$OUT"
assert_eq "steps: no step: exit 1" 1 "$RC"

echo '--- step'
rp "$MAIN" step "$P" 4
assert_eq "step: its lines, to the next step" "$STEP4" "$OUT"
rp "$MAIN" step "$P" 5
assert_eq "step: the last one ends at the task's end" "$STEP5" "$OUT"
rp "$MAIN" step "$P" 6
assert_eq "step: not a step of the acceptance task: exit 1" 1 "$RC"

echo '--- scenarios'
rp "$MAIN" scenarios "$P" "$CASE/sc"
assert_eq "scenarios: one line per skill-test step" \
  "$(printf '2\t%s\tS1, the first scenario.\n3\t%s\tS2, the second scenario.' "$CASE/sc/step-2.txt" "$CASE/sc/step-3.txt")" "$OUT"
assert_eq "scenarios: exit 0" 0 "$RC"
# step-2.txt is byte for byte 'You are the orchestrator.\n\nThe plan is done.\n' (cmp against printf)
# step-3.txt is byte for byte 'You are the executor.\n' (a bold **Situation:** label counts)
# variant: Step 3's situation without its two fence lines (the second "```text" line, and the "```" after "You are the executor.")
rp "$MAIN" scenarios "$P" "$CASE/sc2"
assert_eq "scenarios: a situation without a fence" \
  "$(printf '2\t%s\tS1, the first scenario.\nFAIL 3: no fenced situation' "$CASE/sc2/step-2.txt")" "$OUT"
assert_eq "scenarios: without a fence: exit 1" 1 "$RC"
assert_eq "scenarios: without a fence: no file for it" no "$(exists "$CASE/sc2/step-3.txt")"
# variant: the second "```text" line becomes "```" (Step 3's fence, without its info)
rp "$MAIN" scenarios "$P" "$CASE/sc3"
assert_eq "scenarios: a fence without info still counts" 0 "$RC"
rp "$MAIN" scenarios docs/superpowers/plans/2026-01-03-bare.md "$CASE/sc4"
assert_eq "scenarios: no skill-test step: exit 1" 1 "$RC"
```

`STEP4` is exactly these lines (no newline after the last):

```text
- [ ] **Step 4 (`owner`; the orchestrator runs the command at the click-through): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git merge-tree --write-tree main demo-plan` | exit 0 |
```

`STEP5` is exactly these lines (no newline after the last; the blank line before `## Last-task record` is dropped):

````text
- [ ] **Step 5 (`after merge`, last): The release.**

```bash
git -C /tmp/demo commit -m "chore: release v1.0.1"
```
````

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | grep -c '^FAIL'`
Expected: a number above 0 (the three commands are usage errors today); Task 2's checks still `ok`.

- [ ] **Step 3: Implement `scan`, the three helpers and the three commands in `bin/relay-plan`**

- `scan`: one awk program over the file, by P2 and P3; every reading command runs it once into a temporary file and
  filters its records.
- `steps <plan> [<who>]`: the who argument is one of `reviewer`, `owner`, `after-merge` (it matches `after merge`) and
  `skill-test`, else exit 2. Print `tasks <count>; acceptance task <last>` from `task_summary` (nothing, and exit 1,
  when there is no task), then the matching lines of `acceptance_steps`; exit 1 when none (P13).
- `step <plan> <id>`: `step_text`; exit 1, printing nothing, when there is no such step.
- `scenarios <plan> <dir>` (P4, P12): `mkdir -p <dir>`; for each step whose who is `skill-test`, in order: in its
  records, the first prose line whose text starts with `Situation:` or `**Situation:**`, then the first `open:` record
  after it; the `code:` records up to its `close:` are written, one line each, to `<dir>/step-<id>.txt`, and
  `<id>`, tab, `<dir>/step-<id>.txt`, tab, `<title>` is printed. A step without both prints
  `FAIL <id>: no fenced situation` and makes the exit 1. No `skill-test` step: `relay-plan: no skill-test step in <plan>`
  on stderr, exit 1.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`
Expected: `<n> passed, 0 failed` (the header's `Expect:` updated); `dash -n` silent.

- [ ] **Step 5: Commit**

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh tests/relay-plan/fixtures/plan.md
git commit -m "feat: relay-plan lists a plan's acceptance steps, prints one, and writes its skill-test situations" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#3"
```

### Task 4: `check` (the Contract's `check` row; `planning.md` §2; P1, P5, P6)

**Files:**
- Modify: `bin/relay-plan`
- Create: `tests/relay-plan/fixtures/spec.md`
- Create: `tests/relay-plan/fixtures/sibling.md`
- Modify: `tests/relay-plan/run-tests.sh` (`fixture_repo` gains the two fixtures; a `check` section)

**Interfaces:**
- Consumes: Task 3's `scan`, `task_summary` and `acceptance_steps`, and `fixture_repo` and `variant`.

- [x] **Step 1: The fixtures, and the failing tests.** Create `tests/relay-plan/fixtures/spec.md` with exactly this
  content:

````markdown
# Demo (design)

**Date:** 2026-01-02
**Card:** A demo card (`00000000-0000-4000-8000-000000000000`)

## Goal

A fixture for relay-plan's suite.

## 1. The tool

```text
## Not a section
```

## 2. Acceptance

The tool runs.
````

Create `tests/relay-plan/fixtures/sibling.md` with exactly this content:

```markdown
# Demo sibling Implementation Plan

**Spec:** `docs/superpowers/specs/2026-01-02-demo-design.md`

---

## Contract

Both plans share this.

| Path | What |
|---|---|
| `gates.log` | the gate runs |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1 |
```

`fixture_repo` also puts `fixtures/spec.md` at `$S` (`docs/superpowers/specs/2026-01-02-demo-design.md`) and
`fixtures/sibling.md` at `$SIB` (`docs/superpowers/plans/2026-01-02-demo-sibling.md`). `ALL` stands for the options
`--spec "$S" --sibling "$SIB" --base "$BASE"`. A helper, `fails_alone <name> <expected FAIL line> <option>…`, runs
`check "$P" <option>…` in `$MAIN` (`$ALL` when no option is given) and asserts: exit 1, exactly one line starting
`FAIL `, and that line equal to the expected one.

```sh
echo '--- check'
fixture_repo
rp "$MAIN" check "$P" --spec "$S" --sibling "$SIB" --base "$BASE"
assert_eq "check: the good plan passes every check, in order" "ok committed
ok card
ok trailers
ok acceptance
ok skill-tests
ok placeholders
ok coverage
ok contract
ok builds-on" "$OUT"
assert_eq "check: the good plan: exit 0" 0 "$RC"
rp "$MAIN" check "$P"
assert_eq "check: without options, the five that need none" "ok committed
ok trailers
ok acceptance
ok skill-tests
ok placeholders" "$OUT"
rp "$MAIN" check "$MAIN/$P" --spec "$MAIN/$S"
assert_eq "check: absolute paths read the same" 0 "$RC"
rp "$MAIN" check "$P" --spec docs/nope.md
assert_eq "check: a missing spec: exit 2" 2 "$RC"
rp "$MAIN" check "$P" --colour red
assert_eq "check: an unknown option: exit 2" 2 "$RC"
```

Then one case per broken fixture, each a `variant` of the good plan unless it says otherwise, each with
`fails_alone`:

| Case (the edit) | Expected FAIL line |
|---|---|
| committed: a `fixture_repo` built with `$P` written after its commit, and never committed | `FAIL committed: main has no commit of docs/superpowers/plans/2026-01-02-demo-plan.md` |
| card: the `**Spec:**` line removed | `FAIL card: the spec names a card, and the plan's header has no **Card:**, **Cards:** or **Spec:** line naming docs/superpowers/specs/2026-01-02-demo-design.md` |
| trailers: Task 1's `#1` becomes `#2` | `FAIL trailers: Task 1: Plan-Task docs/superpowers/plans/2026-01-02-demo-plan.md#2 is not docs/superpowers/plans/2026-01-02-demo-plan.md#1` |
| trailers: Task 1's trailer names `docs/superpowers/plans/2026-01-02-other-plan.md#1` | `FAIL trailers: Task 1: Plan-Task docs/superpowers/plans/2026-01-02-other-plan.md#1 is not docs/superpowers/plans/2026-01-02-demo-plan.md#1` |
| trailers: Task 2's commit line without its ` -m "Plan-Task: …#2"` | `FAIL trailers: Task 2 commits without a Plan-Task trailer` |
| trailers: Task 1's `git commit` line given twice | `FAIL trailers: Task 1 carries 2 Plan-Task trailers` |
| acceptance: `` (`owner`; `` becomes `` (`the owner`; `` | `FAIL acceptance: Step 4: "the owner" is not reviewer, owner, after merge or skill-test` |
| skill-tests: Step 3's situation fence opened as ```` ``` ```` instead of ```` ```text ```` | ```` FAIL skill-tests: Step 3: no ```text fence after Situation: ```` |
| skill-tests: the line `RED is expected to: skip it.` removed | `FAIL skill-tests: Step 2: no RED is expected to: line` |
| placeholders: a line `Fill this in: TBD.` after the `**Goal:**` line | `FAIL placeholders: line <its line number in $MAIN/$P>: Fill this in: TBD.` |
| coverage: the row `\| 2. Acceptance \| 3 \|` removed | `FAIL coverage: not in the Spec coverage table: 2. Acceptance` |
| contract: the good plan, with `$SIB` rewritten so that `Both plans share this.` reads `Both plans share that.`, committed | `FAIL contract: docs/superpowers/plans/2026-01-02-demo-sibling.md differs, first at: Both plans share that.` |
| builds-on: the good plan, run with `--base "$OBASE"` in place of `--base "$BASE"` | `FAIL builds-on: the header's **Builds on:** does not name docs/superpowers/plans/2026-01-01-other-base.md` |

Two more cases, each asserting the one line named:

- `$P` left uncommitted as above, and the main checkout switched to a new branch with `git switch -q -c other`: the
  output holds `ok committed`.
- `$S` rewritten without its `**Card:**` line and committed, and the plan's `**Spec:**` line removed: the output holds
  `ok card`.

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | grep -c '^FAIL'`
Expected: a number above 0 (`check` is a usage error today); Tasks 2 and 3's checks still `ok`.

- [ ] **Step 3: Implement `check <plan> [--spec <spec>] [--sibling <plan>]… [--base <plan>]` in `bin/relay-plan`**

Options in any order after `<plan>`; each named file must exist (`need_file`); an unknown option is `usage_error`.
The checks run in the Contract's order, each printing `ok <check>` or a FAIL by P5; exit 1 when any FAILs. The plan's
header is its records before the first prose line that is `---` or starts with `## `; the spec's, its records before
its first prose `## ` line. Each check's rule, and the problems it reports (`<rel>` is a path from the repo's top):

| Check | Rule | Problem text |
|---|---|---|
| `committed` | P6 | `main has no commit of <plan rel>` |
| `card` | When a spec header line holds `**Card:**` or `**Cards:**`: a plan header line holds one of them, or holds `**Spec:**` and the spec's `<rel>` | `the spec names a card, and the plan's header has no **Card:**, **Cards:** or **Spec:** line naming <spec rel>` |
| `trailers` | P1, task by task, in order | `Task <N>: Plan-Task <value> is not <plan rel>#<N>`; `Task <N> commits without a Plan-Task trailer`; `Task <N> carries <k> Plan-Task trailers` |
| `acceptance` | each step of the last task has a who from the four (P3) | `the plan has no task`; `Task <M> has no step`; `Step <id>: no who`; `Step <id>: "<who>" is not reviewer, owner, after merge or skill-test` |
| `skill-tests` | for each `skill-test` step: a `Situation:` line, the first fence after it opened with the info `text`, a `GREEN must:` line, a `RED is expected to:` line (P4) | `Step <id>: no Situation: line`; ```` Step <id>: no ```text fence after Situation: ````; `Step <id>: no GREEN must: line`; `Step <id>: no RED is expected to: line` |
| `placeholders` | prose lines, with every inline-code span removed, matched against `TBD\|TODO\|implement later\|fill in details\|Similar to Task` | `line <n>: <the line as written, its first 80 characters>` |
| `coverage` | each prose `## ` heading of the spec, its text after `## ` with trailing spaces dropped, equals the first cell, trimmed, of a table row in the plan's `## Spec coverage` section | `no ## Spec coverage section`; `not in the Spec coverage table: <heading>` |
| `contract` | the section under a prose heading that is `## Contract`, or starts with `## Contract `, up to the next prose `## ` heading, without the heading and without leading and trailing blank lines, is the same line for line in the plan and in each sibling | `<file rel>: no ## Contract section`; `<sibling rel> differs, first at: <the sibling's first differing line, its first 80 characters, or (end of section)>` |
| `builds-on` | a plan header line holds `**Builds on:**` and the base's `<rel>` | `no **Builds on:** line in the header`; `the header's **Builds on:** does not name <base rel>` |

In that table, a `\|` inside a cell is a plain `|`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`
Expected: `<n> passed, 0 failed` (the header's `Expect:` updated); `dash -n` silent.

- [ ] **Step 5: Commit**

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh tests/relay-plan/fixtures/spec.md tests/relay-plan/fixtures/sibling.md
git commit -m "feat: relay-plan check runs a new plan's hand-back checks" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#4"
```

### Task 5: `overlap` (the Contract's `overlap` row; `parallel.md` §2; P7)

**Files:**
- Modify: `bin/relay-plan`
- Modify: `tests/relay-plan/run-tests.sh` (an `overlap` section)

**Interfaces:**
- Consumes: Task 3's `scan`; Task 2's `files_plan`, `commit_all`, `commit_in`; Task 3's `fixture_repo`.

- [ ] **Step 1: Write the failing tests**

```sh
echo '--- overlap'
fixture_repo
B=docs/superpowers/plans/2026-01-03-b.md
files_plan "$B" '- Modify: `src/main.sh`' '- Modify: `src/fenced.sh`' '- Create: `src/b.sh`'
commit_all b
rp "$MAIN" overlap "$P" "$B"
assert_eq "overlap: a shared file, without :lines; a fenced path is not the plan's" "shared src/main.sh ($B)" "$OUT"
assert_eq "overlap: found: exit 1" 1 "$RC"

M1=docs/superpowers/plans/2026-01-03-m1.md
M2=docs/superpowers/plans/2026-01-03-m2.md
files_plan "$M1" '- Create: `db/000097_orders.sql`' '- Create: `docs/2026-01-03-a.md`' '- Test: `tests/m1.sh`'
files_plan "$M2" '- Create: `db/000097_coupons.sql`' '- Create: `docs/2026-01-03-b.md`' '- Modify: `tests/m1.sh`'
commit_all m
rp "$MAIN" overlap "$M1" "$M2"
assert_eq "overlap: shared, then numbered; a date is not a number" "shared tests/m1.sh ($M2)
numbered db/000097 ($M2)" "$OUT"

C=docs/superpowers/plans/2026-01-03-c.md
files_plan "$C" '- Modify: `ui/x.sh`'
commit_all c
rp "$MAIN" overlap "$M1" "$C"
assert_eq "overlap: none: no output" "" "$OUT"
assert_eq "overlap: none: exit 0" 0 "$RC"
rp "$MAIN" overlap "$P" "$C" "$B"
assert_eq "overlap: several others, in the order given" "shared src/main.sh ($B)" "$OUT"

files_plan docs/superpowers/plans/2026-01-03-b-branch.md '- Modify: `ui/x.sh`'
commit_all 'the b-branch plan'
git -C "$MAIN" switch -q -c b-branch
commit_in "$MAIN" tests/m1.sh 'changed'
commit_in "$MAIN" db/000097_extra.sql 'added'
git -C "$MAIN" switch -q main
rp "$MAIN" overlap "$M1" b-branch
assert_eq "overlap: a branch's diff counts" "shared tests/m1.sh (b-branch)
numbered db/000097 (b-branch)" "$OUT"
rp "$MAIN" overlap "$C" b-branch
assert_eq "overlap: a branch's plan counts" "shared ui/x.sh (b-branch)" "$OUT"
rp "$MAIN" overlap "$M1" no-such-thing
assert_eq "overlap: neither a plan nor a branch: exit 2" 2 "$RC"
```

- [ ] **Step 2: Run them to verify they fail**

Run: `sh tests/relay-plan/run-tests.sh | grep -c '^FAIL'`
Expected: a number above 0 (`overlap` is a usage error today); the earlier sections still `ok`.

- [ ] **Step 3: Implement `overlap <plan> <other>…` in `bin/relay-plan`** (P7)

At least one `<other>`, else `usage_error`. A plan's paths and its `- Create:` paths come from its `prose` records; a
branch adds `git diff --name-only main...<branch>` to its plan's paths and
`git diff --name-only --diff-filter=A main...<branch>` to its created ones. A numbered key is what
`sed -E -n 's#^(.*/)?([0-9]+)[_.][^/]*$#\1\2#p'` prints for a created path. For each `<other>`, in order: a
`shared <path> (<other>)` line per path in both lists, sorted, then a `numbered <key> (<other>)` line per key in both,
sorted; `<other>` as given on the command line.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `sh tests/relay-plan/run-tests.sh | tail -n 1`, then `dash -n bin/relay-plan`
Expected: `<n> passed, 0 failed` (the header's `Expect:` updated); `dash -n` silent.

- [ ] **Step 5: Commit**

```bash
git add bin/relay-plan tests/relay-plan/run-tests.sh
git commit -m "feat: relay-plan overlap finds shared files and numbered collisions" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#5"
```

### Task 6: The user reference, this repo's gates and `CLAUDE.md`; the full gates (spec §1; P15, P17)

**Files:**
- Create: `docs/relay-plan.md`
- Modify: `.hyper-relay/merge.conf:17` and `:45-47`
- Modify: `CLAUDE.md:21-27` (Layout), `:83-84` (How a change reaches the owner) and the Checks table's `relay-merge`
  row

- [ ] **Step 1: The user reference.** Create `docs/relay-plan.md` with exactly this content:

````markdown
# relay-plan: a plan's answers, for the relay

`relay-plan` answers the relay orchestrator's questions about a plan, so that it never reads a plan whole: whether a
newly written plan passes the hand-back checks, whether it can run beside the plans in flight, which acceptance steps
there are and who runs each, one step's text, and the skill-test situations as files. It also keeps each plan's run
folder, where the relay's agents leave their reports, and the branch's gate runs in it.

It ships with hyper-relay as `bin/relay-plan`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `relay-plan` by name. For your own shell (and OpenCode's), symlink it from a
clone into a directory on your `PATH`:

```sh
ln -sfn /path/to/hyper-relay/bin/relay-plan ~/.local/bin/relay-plan
```

## Requirements

- A POSIX shell: `relay-plan` is written for dash and runs as `#!/bin/sh`.
- git 2.31 or later, and `awk`.

## Plans, branches and run folders

Run it anywhere in the repo's main checkout or in one of its worktrees. A `<plan>` is a path from the repo's top, or an
absolute path, and the file must exist.

A plan's branch is its file name without a leading `YYYY-MM-DD-` and without `.md`:
`docs/superpowers/plans/2026-11-20-demo.md` runs on the branch `demo`.

Its run folder is `.hyper-relay/runs/<branch>/` in the main checkout (the parent of
`git rev-parse --path-format=absolute --git-common-dir`), so the main checkout and every worktree share it. Git
ignores `.hyper-relay/runs/`: when it does not yet, `relay-plan` adds that line to the repo's local exclude file (the
file `git rev-parse --git-path info/exclude` names), never to `.gitignore`. Nothing in a run folder is ever cleared.

## Output and exit codes

One line per item. Under a `FAIL` line, at most 5 lines of detail, each indented by two spaces.

| Exit | Means |
|---|---|
| 0 | all ok |
| 1 | a check failed, or nothing was found |
| 2 | a usage error, a missing file, or a missing branch or log |

`gate` exits with its command's code instead.

## Reading a plan

Nothing inside a fenced code block counts as a task, a step, a heading, a path or a placeholder, so a plan that quotes
another plan or a skill's text in a fence is read right. A task is a `### Task <N>` heading, and runs to the next `## `
or `### ` heading. The last task is the acceptance task. Its steps are written
``- [ ] **Step <id> (`<who>` …): <title>**``, where `<who>` is `reviewer`, `owner`, `after merge` or `skill-test`, and
the title may wrap onto the next line.

## Commands

### `relay-plan run-dir <plan>`

Creates the plan's run folder when it does not exist, and prints its absolute path.

### `relay-plan check <plan> [--spec <spec>] [--sibling <plan>]… [--base <plan>]`

The checks of a newly written plan, in this order, one line each: `ok <check>`, or `FAIL <check>: <detail>`.

| Check | Runs | Passes when |
|---|---|---|
| `committed` | always | `main` has a commit of the plan; when the main checkout is on another branch (a branch run), the file exists |
| `card` | with `--spec` | the spec's header names no card, or the plan's header has a `**Card:**` or `**Cards:**` line, or a `**Spec:**` line naming the spec |
| `trailers` | always | each task that commits carries `Plan-Task: <plan path>#<N>` once, with its own number |
| `acceptance` | always | each step of the acceptance task names who runs it |
| `skill-tests` | always | each `skill-test` step has a `Situation:` line, then a fence opened as ```` ```text ````, and a `GREEN must:` and a `RED is expected to:` line |
| `placeholders` | always | no `TBD`, `TODO`, `implement later`, `fill in details` or `Similar to Task` outside fences and inline code |
| `coverage` | with `--spec` | every `## ` heading of the spec is the first cell of a row in the plan's `## Spec coverage` table |
| `contract` | with `--sibling` | the plan's `## Contract` section is the same, line for line, as each sibling's |
| `builds-on` | with `--base` | the plan's header has a `**Builds on:**` line naming the base |

A task commits when one of its `bash`, `sh` or `shell` code blocks runs `git commit`, and a trailer counts only in such
a block. The acceptance task needs no trailer: its commits, if it has any, are the release's.

### `relay-plan overlap <plan> <other>…`

Whether `<plan>` can run beside each `<other>`: a plan, or a branch in flight. A plan's paths are the quoted ones on
its `- Create:`, `- Modify:` and `- Test:` lines, without a `:<lines>` part. A branch's are its plan's
(`docs/superpowers/plans/<YYYY-MM-DD>-<branch>.md`) and what `git diff --name-only main...<branch>` lists. It prints
`shared <path> (<other>)` for each path in both, and `numbered <folder><digits> (<other>)` when both create files in
one folder whose names start with the same digits followed by `_` or `.`, such as migrations (a date is not a
number here). No output, and exit 0: no overlap.

### `relay-plan steps <plan> [reviewer|owner|after-merge|skill-test]`

The acceptance task's steps, all or one who's. The first line is `tasks <N>; acceptance task <M>`: the plan's number of
tasks, and the acceptance task's number (the tasks before it are the executor's). Then one line per step: its id, who
runs it (as the plan writes it, `after merge` with its space) and its title, separated by tabs.

### `relay-plan step <plan> <id>`

One acceptance step's full text, from its `- [ ] **Step <id>` line to the next step or the end of the task.

### `relay-plan scenarios <plan> <dir>`

Writes each `skill-test` step's situation, the text of the first fenced block after its `Situation:` line without the
fence lines, to `<dir>/step-<id>.txt`, and prints its id, that file and its title, separated by tabs. A `skill-test`
step with no fenced situation prints `FAIL <id>: no fenced situation`, and the exit is 1.

### `relay-plan gate <plan> <command>`

Runs `<command>` with `sh -c` from the top of the current checkout (the main checkout or a worktree), and appends a
block to the run folder's `gates.log`:

```text
GATE <full sha of the checkout's HEAD> <command>
<the command's stdout and stderr>
EXIT <code>
```

It prints the output's last 5 lines, then `EXIT <code>`, and exits with the command's code. The log is only ever
appended to. A command is known by its exact text, so give `gates` the same text; a command must be one line.

### `relay-plan gates <plan> [<command>…]`

For each command in `gates.log`, or each one named, its latest block, as
`ok <command>: exit <code> at <short sha>: <last non-empty output line>`, or `FAIL` in the same form when the exit is
not 0 or the block ran at another commit than the tip of the plan's branch. A named command that never ran is
`FAIL <command>: not in gates.log`. After a fix round the earlier blocks are older than the tip and FAIL, so the check
after a fix round names the commands it reran.
````

- [ ] **Step 2: This repo's gates.** In `.hyper-relay/merge.conf`, replace:

```text
bin/relay-merge                 build  dash -n bin/relay-merge
```

with:

```text
bin/relay-merge                 build  dash -n bin/relay-merge
bin/relay-plan                  build  dash -n bin/relay-plan
```

and replace:

```text
# relay-merge.
bin/relay-merge                 test   sh tests/relay-merge/run-tests.sh
tests/relay-merge/              test   sh tests/relay-merge/run-tests.sh
```

with:

```text
# relay-merge.
bin/relay-merge                 test   sh tests/relay-merge/run-tests.sh
tests/relay-merge/              test   sh tests/relay-merge/run-tests.sh

# relay-plan.
bin/relay-plan                  test   sh tests/relay-plan/run-tests.sh
tests/relay-plan/               test   sh tests/relay-plan/run-tests.sh
```

Each prefix is padded with spaces to 32 characters, as the lines around it.

- [ ] **Step 3: `CLAUDE.md`.** Replace:

```text
  repo's gates are `.hyper-relay/merge.conf`, which maps its paths to the Checks table below.
```

with:

```text
  repo's gates are `.hyper-relay/merge.conf`, which maps its paths to the Checks table below.
- `bin/relay-plan`: `relay-plan`, which answers the relay orchestrator's questions about a plan (its hand-back checks,
  its overlap with plans in flight, its acceptance steps and skill-test situations) and keeps each plan's run folder,
  `.hyper-relay/runs/<branch>/`, with the branch's gate runs (POSIX shell, run by dash). `docs/relay-plan.md` is its
  user reference.
```

Replace:

```text
  tests `relay-merge`, on temporary git repos with a fake `wt`.
```

with:

```text
  tests `relay-merge`, on temporary git repos with a fake `wt`. `tests/relay-plan/` tests `relay-plan`, on temporary
  git repos with fixture plans.
```

Replace:

```text
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
```

with:

```text
| relay-merge | `sh tests/relay-merge/run-tests.sh` | `0 failed` |
| relay-plan | `sh tests/relay-plan/run-tests.sh` | `0 failed` |
```

Replace:

```text
  `bin/relay-merge`, as `wt`'s is: a change reaches it as soon as it merges.
```

with:

```text
  `bin/relay-merge`, as `wt`'s is: a change reaches it as soon as it merges.
- **`relay-plan`** in the owner's shell is `~/.local/bin/relay-plan`, a symlink to this main checkout's
  `bin/relay-plan`, as `relay-merge`'s is: a change reaches it as soon as it merges.
```

Then commit:

```bash
git add docs/relay-plan.md .hyper-relay/merge.conf CLAUDE.md
git commit -m "docs: relay-plan's user reference, its gates and its place in CLAUDE.md" -m "Plan-Task: docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-relay-plan.md#6"
```

- [ ] **Step 4: The full gates, once.** In a command inside a table cell, `\|` is a plain `|`.

| Run | Expected |
|---|---|
| `sh tests/relay-plan/run-tests.sh \| tail -n 1` | `<n> passed, 0 failed`, `<n>` as its header's `Expect:` |
| `dash -n bin/relay-plan` | silent |
| `sh tests/hyper-relay-agents/run-tests.sh \| tail -n 1` | `<n> passed, 0 failed`, `<n>` as its header's `Expect:` |
| `sh tests/hyper-relay-agents/guard-test.sh \| tail -n 1` | ends `0 failed` |
| `dash -n bin/hyper-relay-agents` | silent |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout) |
| `git ls-files -s bin/relay-plan` | starts `100755` |
| `git rev-parse --git-path info/exclude`, then `grep -c -x -F '.hyper-relay/runs/' <that file>` | `0` (nothing touched this repo's exclude file) |
| `git diff --name-only main...HEAD` | exactly the ten files of Task 7 Step 4 |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

### Task 7: Acceptance (spec §10, §11; P15–P17). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, from the top of the checkout on the branch
  (`hyper-relay-lighter-orchestrator-relay-plan`) its dispatch names (Steps 1–4). `relay-plan` on `PATH` is the
  installed plugin's, which has none, so every step runs the branch's as `dash bin/relay-plan`. No step reruns the
  gates (spec L2, §10: the executor ran them).
- **`owner`**: the owner, at the click-through (Steps 5–6); the orchestrator runs the commands.
- **`after merge`**: the orchestrator with the owner, once the branch is merged and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 7–10).

In a command inside a table cell, `\|` is a plain `|`. `<C>` is
`docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md`, and `<E>` is the reviewer's evidence folder.

- [ ] **Step 1 (`reviewer`): `relay-plan` on the companion-hardening plan (spec §1, §10).**

| Run | PASS |
|---|---|
| `dash bin/relay-plan check <C> --spec docs/superpowers/specs/2026-11-19-hyper-relay-companion-hardening-design.md` | exactly `ok committed`, `ok card`, `ok trailers`, `ok acceptance`, `ok skill-tests`, `ok placeholders`, `ok coverage`, one per line; exit 0 |
| `dash bin/relay-plan steps <C>` | first `tasks 7; acceptance task 7`, then 15 lines, ids 1–15 in order: 1–4 `reviewer`, 5–9 `skill-test`, 10–12 `owner`, 13–15 `after merge`; Step 12's title `The branch merges cleanly.`; Step 15's `The owner updates and reloads (Releases, (3)).`; exit 0 |
| `dash bin/relay-plan steps <C> after-merge` | the first line, then the lines for 13, 14 and 15 only |
| `dash bin/relay-plan step <C> 12` | its first line starts ``- [x] **Step 12 (`owner`;``, and its last is ``The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`.`` |
| `dash bin/relay-plan scenarios <C> <E>/scenarios` | 5 lines, ids 5–9, files `<E>/scenarios/step-5.txt` to `step-9.txt`; exit 0 |
| `head -n 1 <E>/scenarios/step-5.txt`, then `tail -n 1 <E>/scenarios/step-9.txt` | `<CONTEXT>`; then `step), and your next message to your human partner, verbatim.` |

- [ ] **Step 2 (`reviewer`): `relay-plan` on every other plan (spec §10; P16).** For each file
  `git ls-files docs/superpowers/plans` lists, other than `<C>`, run `dash bin/relay-plan check <plan>` and
  `dash bin/relay-plan steps <plan>`, one command per run. For the plan of this branch's sibling,
  `docs/superpowers/plans/2026-11-20-hyper-relay-lighter-orchestrator-skills.md`, and for this plan, also run
  `dash bin/relay-plan check <plan> --spec docs/superpowers/specs/2026-11-20-hyper-relay-lighter-orchestrator-design.md --sibling <the other of the two>`.
  Report each output in full. For every `FAIL`, and for every `steps` first line whose task count differs from the
  plan's own `### Task` headings as you read them, judge it in one line: a real gap in that plan (for example a
  situation without a fence in a plan written before that rule), or `relay-plan` misreading it. PASS: no misreading,
  and this plan prints only `ok` lines. A misreading is a FAIL, with the plan, its line and why. A real gap in the
  sibling plan is a finding against that plan, for the orchestrator, not a FAIL here.

- [ ] **Step 3 (`reviewer`): A live run in a scratch repo (the Contract's `run-dir`, `gate`, `gates`).** `<S>` is
  `<E>/scratch`; `<B>` is the absolute path of the branch's checkout. These git commands write only in `<S>`. One
  command per run, in order.

| Run | PASS |
|---|---|
| `git init -q -b main <S>` | exit 0 |
| `mkdir -p <S>/docs/superpowers/plans`, then `cp <C> <S>/docs/superpowers/plans/2026-11-19-demo.md` | exit 0 |
| `git -C <S> add docs` | exit 0 |
| `git -C <S> -c core.hooksPath=/dev/null -c user.name=reviewer -c user.email=reviewer@example.invalid commit -q -m plan` | exit 0 |
| `git -C <S> switch -q -c demo` | exit 0 |
| `cd <S> && dash <B>/bin/relay-plan run-dir docs/superpowers/plans/2026-11-19-demo.md` | `<S>/.hyper-relay/runs/demo` (with `<S>` as `pwd -P` gives it) |
| the same command again, then `grep -c -x -F '.hyper-relay/runs/' <S>/.git/info/exclude` | the same path; `1` |
| `cd <S> && dash <B>/bin/relay-plan gate docs/superpowers/plans/2026-11-19-demo.md 'echo ok-one'` | `ok-one`, then `EXIT 0`; exit 0 |
| `cd <S> && dash <B>/bin/relay-plan gate docs/superpowers/plans/2026-11-19-demo.md false` | `EXIT 1`; exit 1 |
| `cd <S> && dash <B>/bin/relay-plan gates docs/superpowers/plans/2026-11-19-demo.md` | `ok echo ok-one: exit 0 at <7 hex>: ok-one`, then `FAIL false: exit 1 at <the same 7>: (no output)`; exit 1 |
| `git -C <S> status --porcelain --untracked-files=all` | nothing |
| `git -C <S> -c core.hooksPath=/dev/null -c user.name=reviewer -c user.email=reviewer@example.invalid commit -q --allow-empty -m next` | exit 0 |
| `cd <S> && dash <B>/bin/relay-plan gates docs/superpowers/plans/2026-11-19-demo.md 'echo ok-one'` | `FAIL echo ok-one: exit 0 at <the earlier 7>: ok-one` (older than the tip); exit 1 |

- [ ] **Step 4 (`reviewer`): Only the planned files, and the text as planned (spec §1, §2; P17).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `.hyper-relay/merge.conf`, `CLAUDE.md`, `bin/hyper-relay-agents`, `bin/relay-plan`, `docs/relay-plan.md`, `tests/hyper-relay-agents/run-tests.sh`, `tests/relay-plan/fixtures/plan.md`, `tests/relay-plan/fixtures/sibling.md`, `tests/relay-plan/fixtures/spec.md`, `tests/relay-plan/run-tests.sh` |
| `git ls-files -s bin/relay-plan` | starts `100755` |
| `git diff --stat main...HEAD -- package.json .claude-plugin skills templates hooks README.md` | nothing |
| `git diff main...HEAD -- bin docs/relay-plan.md \| grep -c -E '^\+.*(/home/\|/Users/)'` | `0` |
| `git diff main...HEAD -- docs/relay-plan.md CLAUDE.md .hyper-relay/merge.conf` | each hunk is one of Task 6's "with exactly this content" or "Replace X with Y" texts, word for word, and nothing else differs |
| `git diff main...HEAD -- bin/hyper-relay-agents` | only Task 1 Step 3's two changes |

- [ ] **Step 5 (`owner`): Read the reference and the calls made here.** Read `docs/relay-plan.md` on the branch, with
  P1, P3, P7, P12 and P17 above. PASS: the owner agrees with them as written. A change goes to the executor as a
  finding.

- [ ] **Step 6 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch merges
  cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-lighter-orchestrator-relay-plan` | exit 0, one line (a tree id) |

The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`.

- [ ] **Step 7 (`after merge`): Re-check on `main`, and the role agents (spec §10; P15).** `main`'s `merge.conf` did
  not yet name `relay-plan`'s suite when this branch merged, so it runs here.

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `sh /home/noob_master/hyper-relay/tests/relay-plan/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `dash -n /home/noob_master/hyper-relay/bin/relay-plan` | silent |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |
| `cd /home/noob_master/hyper-relay && sh bin/hyper-relay-agents --check` | nothing, exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/hyper-relay/bin/hyper-relay-agents --check` | nothing, exit 0 |

A line from `--check` stops the step: tell the owner.

- [ ] **Step 8 (`after merge`): The release, 0.2.6 (spec §11; `.hyper-relay/agents.md`, Releases, (1) and (2)).** The
  owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (the spec and both plans among
  them), which is expected. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with `<x.y.z>`
  the version `--check` shows with its patch number raised by one (`0.2.6` from `0.2.5`), unless the owner names another:

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.5`) |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh <x.y.z>` | exit 0; `package.json` and `.claude-plugin/plugin.json` raised to `<x.y.z>` |
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at `<x.y.z>` |
| `git -C /home/noob_master/hyper-relay diff --numstat` | exactly `1	1	.claude-plugin/plugin.json` and `1	1	package.json`; otherwise stop and show the owner `git diff` |

Then:

```bash
git -C /home/noob_master/hyper-relay add package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay commit -m "chore: release v<x.y.z>" -m "<the committing session's attribution lines>" -- package.json .claude-plugin/plugin.json
git -C /home/noob_master/hyper-relay tag v<x.y.z>
git -C /home/noob_master/hyper-relay push origin main v<x.y.z>
```

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay log -1 --format=%s main` | `chore: release v<x.y.z>` |
| `git -C /home/noob_master/hyper-relay show --stat --format= main` | the two files only |
| `git -C /home/noob_master/hyper-relay rev-parse main`, then `git -C /home/noob_master/hyper-relay rev-parse origin/main` | the same SHA |
| `git -C /home/noob_master/hyper-relay ls-remote origin refs/tags/v<x.y.z>` | one line |

- [ ] **Step 9 (`after merge`; the owner runs the `ln`, which is the owner's shell setup): The symlink (P17).** As
  `wt` and `relay-merge` are linked, so that an OpenCode orchestrator or the owner's shell finds `relay-plan` by name.
  First, `test -e /home/noob_master/.local/bin/relay-plan || test -L /home/noob_master/.local/bin/relay-plan; echo $?`
  must print `1` (nothing there yet); if it prints `0`, stop and ask the owner. Then the owner runs:

```bash
ln -sfn /home/noob_master/hyper-relay/bin/relay-plan /home/noob_master/.local/bin/relay-plan
```

| Run | PASS |
|---|---|
| `readlink /home/noob_master/.local/bin/relay-plan` | `/home/noob_master/hyper-relay/bin/relay-plan` |
| `command -v relay-plan`, in the owner's shell | `/home/noob_master/.local/bin/relay-plan` |
| `relay-plan; echo "exit $?"`, in the owner's shell | the `usage: relay-plan` line, then `exit 2` |
| `RELAY_PLAN_BIN=/home/noob_master/.local/bin/relay-plan sh /home/noob_master/hyper-relay/tests/relay-plan/run-tests.sh \| tail -n 1` | ends `0 failed` |

- [ ] **Step 10 (`after merge`, last): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session). Plan 2 runs only after this step passes: its executor and orchestrator call `relay-plan` by
  name.

| Run | PASS |
|---|---|
| `test -x /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/relay-plan && echo cached` | `cached` |
| `command -v relay-plan`, in the orchestrator's session after the reload | `/home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/bin/relay-plan` |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If `command -v` still prints nothing or an older path after `/reload-plugins`, the owner starts a
new session and it is run there. If a check still fails, stop and tell the owner; delete or uninstall nothing. Then
tick the acceptance task as `reviewing.md` §5 says.
