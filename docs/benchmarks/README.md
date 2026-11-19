# G.2: a superpowers baseline on SAT

hyper-relay's README is to compare its relay with upstream superpowers on measured usage. This folder fixes
how that is measured, before either run starts (spec:
`docs/superpowers/specs/2026-11-19-hyper-relay-g2-superpowers-baseline-design.md`). One SAT feature, C.1, is
built with hyper-relay's relay; a comparable one, C.2, with upstream superpowers' full workflow. The two are
compared on tokens, time and escaped defects. Nothing is built twice.

| File | What it is |
|---|---|
| `run-log-template.md` | One run's log; its header is what `run-usage.sh` reads |
| `pitfall-brief.md` | The brief of the agent that writes the sealed pitfall list (step 2) |
| `restate-prompt.md` | Restates both specs as plain requirements lists (step 6) |
| `blind-review-prompt.md` | The blind review of one feature's code (step 6) |
| `verify-prompt.md` | Its second pass, which confirms or refutes each finding (step 6) |
| `catches-prompt.md` | Lists both runs' in-process catches (step 6) |
| `pitfall-check-prompt.md` | Checks the sealed list on both merged features (step 6) |

The tools are in `scripts/benchmark/`: `superpowers-env.sh` builds the two config folders, and `run-usage.sh`
turns a run log into a usage table (`run-usage.sh --sessions` finds a run's sessions).

## The rules of both runs

- **No run is told it is being measured.** Nothing about this benchmark goes where a run's agents read: not
  SAT's `CLAUDE.md`, not SAT's auto-memory, not C.1's card. The run logs, the pitfall list and every other
  file of the benchmark stay in `~/sat-benchmark/`, outside both repos.
- **The same conditions.** An Opus 5.5 main session at the owner's usual effort (both config folders share
  the owner's `settings.json`, so change it in neither). Each run starts in a fresh session, and the session
  that brainstormed G.2 runs neither. Nothing else runs on SAT while a run is going: the time would blur,
  and SAT's web suite must never run twice at once.
- **The owner answers what the workflow asks, as usual,** and volunteers no requirement they would
  otherwise leave out.
- **The same bar to finish:** `make merge`'s gates pass and the owner's click-through passes. The owner
  merges with `make merge` in both runs. Fixes after a failed click-through count inside the run.
- **Transcripts expire.** Claude Code deletes transcripts older than `cleanupPeriodDays`, 30 days by
  default. Run `run-usage.sh` on a run's log as soon as it merges, keep its output beside the log, and
  finish scoring within 30 days of C.1's start.

## Paths

Every command below runs in the owner's own terminal, after these three lines. Set `SAT` to the path of SAT's main
checkout first (`export SAT=<its path>`): this repo names no path for it, and the second line stops when it is unset.

```sh
HR=~/hyper-relay           # this repo's main checkout, on main
SAT=${SAT:?set SAT to the path of the SAT main checkout first}
BENCH=~/sat-benchmark      # outside both repos
```

A commit's time goes into a log in UTC, as this prints it:

```sh
TZ=UTC git -C "$SAT" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h %cd' <commit>
```

## 1. The config folders

Build both on the day C.1 starts, so both runs start under the same day's environment:

```sh
"$HR/scripts/benchmark/superpowers-env.sh"
"$HR/scripts/benchmark/superpowers-env.sh" --neutral
```

Each prints what it linked, copied, changed and installed; the first also prints the superpowers version it
installed (5.1.0 or later), for C.2's log. A folder that exists is refused: if they were built earlier (at
G.2's acceptance) and `~/.claude/settings.json`, `~/.claude/CLAUDE.md` or the MCP servers of `~/.claude.json`
have changed since, move both aside (`mv ~/.claude-superpowers ~/.claude-superpowers.old`, the same for
`~/.claude-neutral`) and build them again.

The folders link the owner's own `~/.claude/skills`, `agents`, `commands`, `rules`, `hooks` and `bin`, and copy
its `settings.json`, so every other hook stays: `ccs` and the rest still write to `~/.claude/session-state`
from either run. That is harmless, and the same in both runs.

Then log in to each and check it, from a scratch folder, so nothing about SAT lands in either:

```sh
mkdir -p /tmp/g2-check && cd /tmp/g2-check
CLAUDE_CONFIG_DIR=~/.claude-superpowers claude
```

In that session: `/login`; `/plugin` lists superpowers, frontend-design, gopls-lsp and ui-ux-pro-max as
installed, and no hyper-relay; typing `/` offers `superpowers:` skills and no `hyper-relay:` one; `/mcp`
lists codebase-memory-mcp, context7 and playwright, and no Quartz (that check is about `/mcp` alone);
`/memory` shows no auto-memory notes. A user-level skill from `~/.claude/skills`, such as
`quartz-import-roadmap`, also shows in `/` in both folders: it is the owner's own skill, present in the relay
run's environment too, so it is expected. The skill check is only that no `hyper-relay:` skill appears.
Then `/exit`, and the same with `CLAUDE_CONFIG_DIR=~/.claude-neutral claude`, which has neither superpowers
nor hyper-relay.

## 2. The sealed pitfall list

```sh
mkdir -p "$BENCH/blind"
```

In a session of the owner's normal setup that is neither run's (this repo's, say), have Claude copy from
Quartz the title and description of card C.1 (`1504e8f8-ddcf-474d-b7ef-978c4a069069`) under `## C.1` and of
card C.2 (`df5a7bd8-da19-439a-af51-508ff3893984`) under `## C.2`, verbatim and without their notes, into
`~/sat-benchmark/cards.md`. Then give the brief and the cards to one headless session in the neutral folder:
it never saw G.2's brainstorm, and it keeps no transcript.

```sh
cd "$SAT"
cat "$HR/docs/benchmarks/pitfall-brief.md" "$BENCH/cards.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH" \
      --allowedTools Read Write "Bash(grep *)" "Bash(sha256sum *)"
chmod a-w "$BENCH/pitfalls.md"
```

It replies with the path and a `sha256sum` line, nothing else. The hash goes in both run logs
(`pitfalls-sha256:`). Nobody opens `pitfalls.md` before step 6, the owner included: knowing it would shape
the brainstorming answers.

## 3. SAT, before C.1

```sh
cd "$SAT"
"$HR/bin/hyper-relay-agents"            # refreshes SAT's role agents
"$HR/bin/hyper-relay-agents" --check    # prints nothing
make ps                                 # every service up, healthy where it has a check
git status --short                      # nothing
grep -r -i -l -e benchmark -e baseline ~/.claude/projects/"$(printf '%s' "$SAT" | tr -c 'A-Za-z0-9' '-')"/memory   # nothing
```

## 4. C.1, with the relay

```sh
cp "$HR/docs/benchmarks/run-log-template.md" "$BENCH/run-log-c1.md"
git -C "$SAT" rev-parse --short main      # start-commit
claude plugin list --json | jq -r '.[] | select(.id == "hyper-relay@hyper-relay") | .version'
```

Fill `workflow: hyper-relay <that version>`, `card:`, `config: ~/.claude`, `start-commit:` and
`pitfalls-sha256:`. Then start a fresh session in SAT's main checkout, in the owner's normal setup, and ask
for card C.1 as the owner would ask for any card:

```sh
cd "$SAT" && claude
```

The relay runs as it stands on the day. At its stop 4, after the click-through passes, the owner merges
with `make merge BRANCH=<the branch>` and tells the orchestrator so. Log every click-through defect as it
is found. After the merge, fill the rest of the log:

- `spec:`, `plan:` and `merge:`: the commit that added C.1's spec, the commit of its approved plan, and the
  merge commit, each with its UTC time.
- `session:` and `start:`: list the sessions of the run's days and pick the run's (SAT's project folder,
  the run's first prompt); `start:` is the first one's first-prompt time.

  ```sh
  "$HR/scripts/benchmark/run-usage.sh" --sessions ~/.claude <the run's first day, 00:00:00Z> <the merge time>
  ```

- `role:` lines, for example:

  ```text
  role: ^sat-planner: → planner
  role: ^sat-executor: → executor
  role: ^sat-reviewer: → acceptance reviewer
  role: [Cc]ode review → code reviewer
  role: [Pp]lan review|[Rr]eview the .* plan → plan reviewer
  ```

Then:

```sh
"$HR/scripts/benchmark/run-usage.sh" "$BENCH/run-log-c1.md" > "$BENCH/usage-c1.md"
```

Give every `other` row a role line, or a reason under the log's Roles, and run it again.

## 5. C.2, with upstream superpowers

From the new `main`, after C.1's merge:

```sh
cd "$SAT"
git status --short                   # nothing
git rev-parse --short main           # start-commit
wt new feat/notify-issue-activity
cp "$HR/docs/benchmarks/run-log-template.md" "$BENCH/run-log-c2.md"
cd "$SAT/.worktrees/notify-issue-activity"
CLAUDE_CONFIG_DIR=~/.claude-superpowers claude
```

Fill `workflow: superpowers <the version step 1 printed>`, `card:`, `config: ~/.claude-superpowers`,
`start-commit:` and `pitfalls-sha256:`. The worktree has none of SAT's gitignored `.claude/` (its role
agents, which point at hyper-relay's skills, and the planner guard) and no `.mcp.json` (Quartz), so neither
reaches the run. The superpowers run does not read the board: the owner's first message asks to build the
feature and pastes card C.2's title and description. Where superpowers offers a choice, take its full path:
subagent-driven development rather than inline execution, and the worktree it is in. At
`finishing-a-development-branch`, choose to keep the branch; after the click-through passes, merge from the
main checkout:

```sh
cd "$SAT" && make merge BRANCH=feat/notify-issue-activity
```

Fill the rest as in step 4, with `~/.claude-superpowers` for `--sessions`. Superpowers commits its spec and
plan on the branch: `spec:` and `plan:` are those commits
(`git -C "$SAT" log --diff-filter=A --format=%h -- <the file's path>`). If it never commits one, write `-`
and the time of the owner's message approving it, and say so under Notes. Note there too where it put its
spec and plan, and any Quartz call it made (SAT's `CLAUDE.md` names the board). Example role lines for its
subagent-driven development (its version 7 has one task reviewer, giving the spec-compliance and the
quality verdicts together):

```text
role: [Ii]mplement → implementer
role: [Ss]pec (compliance )?review → spec reviewer
role: [Qq]uality review → quality reviewer
role: [Tt]ask review|[Rr]eview [Tt]ask → task reviewer
role: [Ff]inal|[Ww]hole[- ]branch → final reviewer
```

```sh
"$HR/scripts/benchmark/run-usage.sh" "$BENCH/run-log-c2.md" > "$BENCH/usage-c2.md"
```

## 6. Scoring

After both merges. The `<…>` values are in the run logs.

**a. The seal.** `sha256sum "$BENCH/pitfalls.md"` prints the hash both logs hold. If it does not, the
list does not count, and the results say so.

**b. Usage.** `usage-c1.md` and `usage-c2.md`, each from its final log. Read each one's Cross-check line: a
gap outside its tolerance is explained in the results, never ignored.

**c. In-process catches.** The counter reads only copies of the run's own transcripts, never a whole
`projects` tree. Write `$BENCH/catches-input.md`, one line per transcript, `<run> <role> <path>`: every
reviewer role's subagent transcripts, the executor's or implementers', and each run's main sessions (role
`main`). A row `agent <id>` of session `<session>` is the file
`<config>/projects/*/<session>/subagents/agent-<id>.jsonl`; a main session is
`<config>/projects/*/<session>.jsonl`. Copy each listed file into `$BENCH/transcripts/` as
`<run>-<its file name>` (`c1` or `c2`), list those copies as the `<path>`s, and give the counter that folder
alone:

```sh
mkdir -p "$BENCH/transcripts"
cd "$BENCH"
cat "$HR/docs/benchmarks/catches-prompt.md" "$BENCH/catches-input.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/transcripts" \
      --allowedTools Read "Bash(jq *)" "Bash(grep *)" > "$BENCH/catches.md"
```

The owner checks `catches.md` and copies each run's confirmed list into its log's In-process catches.

**d. The requirements lists.** One session restates both specs (their paths as merged in SAT):

```sh
printf 'C.1: %s\nC.2: %s\n' <C.1's spec path> <C.2's spec path> > "$BENCH/restate-input.md"
cd "$SAT"
cat "$HR/docs/benchmarks/restate-prompt.md" "$BENCH/restate-input.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" --allowedTools Read Write
```

It writes `$BENCH/blind/requirements-c1.md` and `$BENCH/blind/requirements-c2.md`.

**e. The blind review and its verification**, for each feature; C.1 shown, C.2 the same with its own
commits and `c2`:

```sh
git -C "$SAT" worktree add --detach "$BENCH/review-c1" <C.1 merge>
cd "$BENCH/review-c1"
sed -e 's/<START>/<C.1 start-commit>/g' -e "s|<REQUIREMENTS>|$BENCH/blind/requirements-c1.md|g" \
    "$HR/docs/benchmarks/blind-review-prompt.md" \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" \
      --allowedTools Read "Bash(git diff *)" "Bash(grep *)" > "$BENCH/blind-c1.md"
{ sed -e 's/<START>/<C.1 start-commit>/g' -e "s|<REQUIREMENTS>|$BENCH/blind/requirements-c1.md|g" \
      "$HR/docs/benchmarks/verify-prompt.md"; cat "$BENCH/blind-c1.md"; } \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --add-dir "$BENCH/blind" \
      --allowedTools Read "Bash(git diff *)" "Bash(grep *)" > "$BENCH/verified-c1.md"
cd "$BENCH" && git -C "$SAT" worktree remove "$BENCH/review-c1"
```

Each session reaches only its worktree and `$BENCH/blind/`: the sealed list and the run logs are out of its
reach. Its prompt tells it not to read git history, so the review is blind to the label but not provably
blind, and the results say so. Only confirmed Critical and Important findings count.

**f. The sealed list**, on both merged features:

```sh
cd "$SAT"
{ sed -e 's/<C1_MERGE>/<C.1 merge>/g' -e 's/<C2_MERGE>/<C.2 merge>/g' "$HR/docs/benchmarks/pitfall-check-prompt.md"; \
  cat "$BENCH/pitfalls.md"; } \
  | CLAUDE_CONFIG_DIR=~/.claude-neutral claude -p --model claude-opus-5-5 --no-session-persistence \
      --permission-mode dontAsk --allowedTools Read "Bash(git show *)" "Bash(git grep *)" > "$BENCH/pitfall-check.md"
```

The owner confirms each answer.

**g. Diff sizes**, over the same paths as the blind review:

```sh
git -C "$SAT" diff --shortstat <C.1 start-commit>..<C.1 merge> -- api web mailer-worker
git -C "$SAT" diff --shortstat <C.2 start-commit>..<C.2 merge> -- api web mailer-worker
```

## 7. The results

Write `docs/benchmarks/<date>-superpowers-baseline.md` in this repo, with:

- both usage tables, with each run's wall clock, agent time, waiting time and the owner's message count;
  the waiting time is time spent on the owner, nights included, and never a cost of either workflow;
- each run's cross-check, and the explanation of any gap outside its tolerance;
- each run's in-process catches, counted, not scored;
- the escaped defects per yardstick, as raw counts: the click-through's defects, the blind review's
  confirmed Critical and Important findings, and the sealed list's answers; beside each feature's diff size
  (files and changed lines);
- the superpowers version, and both start commits;
- the caveats: one pair, so n = 1, which is evidence about these two runs and not a general rate; C.2 ran
  second, with C.1 and an older producer beside it to copy, which favours superpowers; the blind review is
  blind to the label, not provably blind; and whatever the logs' Notes record.

Copy `run-log-c1.md`, `run-log-c2.md`, `usage-c1.md` and `usage-c2.md` to `docs/benchmarks/runs/` and commit
them with it. Card G takes its numbers from it. This repo is public: the results and the logs carry
numbers, one-line findings and commit hashes, never SAT's code, data or secrets.
