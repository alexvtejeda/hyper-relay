# Run log: <C.1 or C.2>, <the card's title>

<!--
The "key: value" lines below, up to the first "## " heading, are the header scripts/benchmark/run-usage.sh
reads; keep every line you fill in that form. Times are UTC, written 2026-11-20T14:03:00Z: a commit's
time as `TZ=UTC git -C <repo> log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h %cd' <commit>`
prints it, and the start as `run-usage.sh --sessions` prints the run's first prompt. Add one "session:"
line per session of the run. A "role:" line is "<extended regex> → <role>", matched against
"<agentType>: <description>" of each subagent; the first match wins, and a subagent no line matches is
reported as "other". "spec:", "plan:" and "merge:" are "<short hash> <time>", with "-" for the hash when
a workflow never commits one. During the runs this file lives in ~/sat-benchmark/, outside both repos.
-->

workflow: <hyper-relay x.y.z | superpowers x.y.z>
card: <title> (<card id>)
config: <~/.claude | ~/.claude-superpowers>
start-commit: <short hash of SAT's main when the run started>
session: <session id>
start: <time of the owner's first message>
spec: <short hash> <time>
plan: <short hash> <time>
merge: <short hash> <time>
pitfalls-sha256: <the sha256 of ~/sat-benchmark/pitfalls.md>
role: <extended regex> → <role>

## Roles

<Why each role line is there, and why any "other" row left in the usage table is not a role.>

## The owner's click-through

<Every defect the owner finds, from the first click-through on, as it is found.>

| # | Found (UTC) | Defect, one line | Severity (Critical / Important / Minor) | Fixed in |
|---|---|---|---|---|

## In-process catches

<Filled at scoring from the catch counter's list, as the owner confirmed it.>

| # | Reviewer (role) | Finding, one line | Outcome (fixed / dropped / disputed) |
|---|---|---|---|

## Notes

<Anything that ran differently from docs/benchmarks/README.md: where a workflow put its spec and plan, a
Quartz call the superpowers run made, a session resumed after a break, a compaction.>
