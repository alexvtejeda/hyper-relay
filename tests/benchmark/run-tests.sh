#!/bin/sh
# POSIX tests for G.2's benchmark tools (docs/benchmarks/README.md): scripts/benchmark/run-usage.sh and
# scripts/benchmark/plan-usage.sh on small fixture transcripts priced by a test prices file (plan-usage.sh
# also on fixture plans in a temporary git repo), and scripts/benchmark/superpowers-env.sh with a fake
# home folder and a fake claude that records its calls. HOME is a temporary folder before any tool runs,
# so nothing here reads or writes the real ~/.claude, ~/.claude.json or a login.
# Usage: sh tests/benchmark/run-tests.sh      Expect: "110 passed, 0 failed"
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
RU=$REPO/scripts/benchmark/run-usage.sh
SE=$REPO/scripts/benchmark/superpowers-env.sh
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P)
PASSED=0
FAILED=0

# The tools read these from the environment: none may leak in from the caller.
unset CLAUDE_CONFIG_DIR RUN_USAGE_PRICES FAKE_CLAUDE_LOG FAKE_SP_VERSION SP_VERSION
HOME=$TMP_ROOT/home
export HOME
mkdir -p "$HOME"

ok() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n       %s\n' "$1" "$2"; }

assert_eq() { # description expected actual
    if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2], got [$3]"; fi
}
assert_contains() { # description needle haystack
    case $3 in
        *"$2"*) ok "$1" ;;
        *) bad "$1" "[$2] not in [$3]" ;;
    esac
}
assert_not_contains() { # description needle haystack
    case $3 in
        *"$2"*) bad "$1" "[$2] should not be in [$3]" ;;
        *) ok "$1" ;;
    esac
}
yes_no() { # path: yes when it exists (a dangling link included), no when not
    if [ -e "$1" ] || [ -L "$1" ]; then echo yes; else echo no; fi
}

echo '--- prices.tsv'
PRICES=$REPO/scripts/benchmark/prices.tsv
assert_eq "prices: every row is a model, a threshold and five prices, all numbers" 0 \
    "$(if [ -f "$PRICES" ]; then awk -F '\t' '!/^#/ && NF { if (NF != 7) bad++; for (i = 2; i <= 7; i++) if ($i !~ /^[0-9]+(\.[0-9]+)?$/) bad++ } END { print bad + 0 }' "$PRICES"; else echo "no prices.tsv"; fi)"
assert_eq "prices: Opus, Sonnet and Haiku 5.5 have rows" 3 \
    "$(awk -F '\t' '!/^#/ && NF { print $1 }' "$PRICES" 2>/dev/null | sort -u | grep -c -E '^claude-(opus|sonnet|haiku)-5-5$')"
assert_contains "prices: the date they were taken, and where" \
    "2026-11-19 from https://platform.claude.com/docs/en/about-claude/pricing" "$(cat "$PRICES" 2>/dev/null)"

echo '--- run-usage: fixture transcripts'
printf '# test prices\ntest-big\t0\t1\t10\t0.1\t1.25\t2\ntest-small\t0\t0.5\t2\t0.05\t0.625\t1\ntest-small\t1000000\t1\t4\t0.1\t1.25\t2\n' \
    > "$TMP_ROOT/prices.tsv"

# Transcript records, one JSON object per line, as Claude Code writes them.
owner() { # time text: the owner's own prompt
    printf '{"type":"user","message":{"role":"user","content":"%s"},"origin":{"kind":"human"},"promptSource":"typed","timestamp":"%s"}\n' "$2" "$1"
}
prompt() { # time text: a user record with no origin, as a subagent's dispatch prompt is
    printf '{"type":"user","message":{"role":"user","content":"%s"},"timestamp":"%s"}\n' "$2" "$1"
}
result() { # time: a tool result
    printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t","content":"ok"}]},"toolUseResult":"ok","timestamp":"%s"}\n' "$1"
}
notice() { # time: the harness's notice that a background agent finished
    printf '{"type":"user","message":{"role":"user","content":"<task-notification>done</task-notification>"},"origin":{"kind":"task-notification"},"promptSource":"system","timestamp":"%s"}\n' "$1"
}
# call <time> <id> <model> <stop reason> <input> <5m write> <1h write> <read> <output> [<block>]:
# one content block of an API call, with usage.cache_creation; a text block unless one is given.
call() {
    block=${10:-}
    [ -n "$block" ] || block='{"type":"text","text":"x"}'
    printf '{"type":"assistant","message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":[%s],"stop_reason":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":%s,"ephemeral_1h_input_tokens":%s}}},"timestamp":"%s"}\n' \
        "$3" "$2" "$block" "$4" "$5" "$(($6 + $7))" "$8" "$9" "$6" "$7" "$1"
}
# old_call <time> <id> <model> <stop reason> <input> <write> <read> <output>: the same as an older
# Claude Code wrote it, with no usage.cache_creation, so its writes are 5-minute ones.
old_call() {
    printf '{"type":"assistant","message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":[{"type":"text","text":"x"}],"stop_reason":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}},"timestamp":"%s"}\n' \
        "$3" "$2" "$4" "$5" "$6" "$7" "$8" "$1"
}
TOOL='{"type":"tool_use","id":"t","name":"Bash","input":{}}'
ASK='{"type":"tool_use","id":"t","name":"AskUserQuestion","input":{}}'
THINK='{"type":"thinking","thinking":"x"}'

P=$HOME/cfg/projects/-proj
mkdir -p "$P/sess1/subagents" "$P/sess2/subagents"
D=2026-01-01T

# sess1: the run's first main session. A call before the start and one after the merge; a message
# written as two records; an open question; a line cut short; a compaction; two cost records.
{
    owner "${D}09:55:00.000Z" "before the run"
    call "${D}09:55:10.000Z" m0 test-big end_turn 1000000 0 0 0 0
    owner "${D}10:00:00.000Z" "start"
    call "${D}10:00:30.000Z" m1 test-big end_turn 2 0 1000000 0 100000 "$THINK"
    call "${D}10:00:31.000Z" m1 test-big end_turn 2 0 1000000 0 100000
    owner "${D}10:05:00.000Z" "an answer"
    call "${D}10:05:20.000Z" m2 test-big tool_use 2 0 0 1000000 50000 "$TOOL"
    result "${D}10:05:21.000Z"
    call "${D}10:05:30.000Z" m3 test-big end_turn 2 0 0 1000000 10000
    printf '%s\n' '{"type":"assistant","message":'
    notice "${D}10:15:00.000Z"
    call "${D}10:15:10.000Z" m4 test-big end_turn 2 0 0 2000000 20000
    owner "${D}10:25:00.000Z" "go"
    call "${D}10:25:10.000Z" m5 test-big tool_use 2 0 0 1000000 1000 "$ASK"
    result "${D}10:27:10.000Z"
    call "${D}10:27:20.000Z" m6 test-big end_turn 2 0 0 1000000 1000
    printf '{"type":"system","subtype":"compact_boundary","content":"Conversation compacted","timestamp":"%s"}\n' "${D}10:50:00.000Z"
    owner "${D}10:58:00.000Z" "merge it"
    call "${D}10:59:00.000Z" m7 test-big end_turn 2 0 0 1000000 1000
    owner "${D}11:05:00.000Z" "after"
    call "${D}11:05:30.000Z" m8 test-big end_turn 1000000 0 0 0 0
    printf '%s\n' '{"type":"cost-state","sessionId":"sess1","totalCostUSD":5,"modelUsage":{}}'
    printf '%s\n' '{"type":"cost-state","sessionId":"sess1","totalCostUSD":9.701039,"modelUsage":{"test-big":{"costUSD":9.370024,"outputTokens":302000},"test-small":{"costUSD":0.231015,"outputTokens":2000},"test-side":{"costUSD":0.1,"outputTokens":50}}}'
} > "$P/sess1.jsonl"
{
    prompt "${D}10:05:22.000Z" "write the plan"
    old_call "${D}10:05:40.000Z" p1 test-big tool_use 2 1000000 0 10000
    result "${D}10:06:00.000Z"
    call "${D}10:12:00.000Z" p2 test-big tool_use 2 0 0 1000000 100000 "$TOOL"
    result "${D}10:12:30.000Z"
    call "${D}10:14:50.000Z" p3 test-big tool_use 2 0 0 1000000 5000 "$TOOL"
    result "${D}10:14:51.000Z"
} > "$P/sess1/subagents/agent-a1.jsonl"
printf '%s\n' '{"agentType":"relay-planner","description":"Write the demo plan","spawnDepth":1}' \
    > "$P/sess1/subagents/agent-a1.meta.json"
{
    prompt "${D}10:30:00.000Z" "execute the plan"
    call "${D}10:30:10.000Z" e1 test-small tool_use 10 0 0 500000 1000 "$TOOL"
    result "${D}10:30:20.000Z"
    call "${D}10:39:00.000Z" e2 test-small tool_use 10 0 0 2000000 1000 "$TOOL"
    result "${D}10:39:01.000Z"
} > "$P/sess1/subagents/agent-a2.jsonl"
printf '%s\n' '{"agentType":"relay-executor","description":"Execute the demo plan","spawnDepth":1}' \
    > "$P/sess1/subagents/agent-a2.meta.json"
{
    prompt "${D}10:35:00.000Z" "review task 1"
    call "${D}10:35:30.000Z" r1 test-big tool_use 2 0 0 1000000 2000 "$TOOL"
    result "${D}10:35:31.000Z"
    call "${D}10:38:00.000Z" r2 test-big end_turn 2 0 0 1000000 2000 "$THINK"
    call "${D}10:38:01.000Z" r2 test-big end_turn 2 0 0 1000000 2000
} > "$P/sess1/subagents/agent-a3.jsonl"
printf '%s\n' '{"agentType":"general-purpose","description":"Review task 1 code","parentAgentId":"a2","spawnDepth":2}' \
    > "$P/sess1/subagents/agent-a3.meta.json"

# sess2: a second main session of the same run, with an Explore subagent no role line matches.
{
    owner "${D}10:40:00.000Z" "continue"
    call "${D}10:40:10.000Z" n1 test-big tool_use 2 0 0 1000000 1000 "$TOOL"
    result "${D}10:40:11.000Z"
    call "${D}10:40:20.000Z" n2 test-big end_turn 2 0 0 1000000 1000
    printf '%s\n' '{"type":"cost-state","sessionId":"sess2","totalCostUSD":0.220504,"modelUsage":{"test-big":{"costUSD":0.220004,"outputTokens":2000},"test-small":{"costUSD":0.0005,"outputTokens":200}}}'
} > "$P/sess2.jsonl"
{
    prompt "${D}10:40:12.000Z" "explore"
    call "${D}10:40:30.000Z" x1 test-small tool_use 100 0 0 0 100 "$TOOL"
    result "${D}10:41:00.000Z"
    call "${D}10:41:10.000Z" x2 test-small end_turn 100 0 0 0 100
} > "$P/sess2/subagents/agent-a4.jsonl"
printf '%s\n' '{"agentType":"Explore","description":"Explore the code","spawnDepth":1}' \
    > "$P/sess2/subagents/agent-a4.meta.json"

# sess3 has a model with no price and a cost record below its transcripts; sess4 has no cost record.
E=2026-01-02T
{
    owner "${E}10:00:00.000Z" "third"
    call "${E}10:00:10.000Z" q1 test-big end_turn 1000000 0 0 0 0
    owner "${E}10:00:20.000Z" "again"
    call "${E}10:00:30.000Z" q2 test-unknown end_turn 5000 0 0 0 10
    printf '%s\n' '{"type":"cost-state","sessionId":"sess3","totalCostUSD":0.5,"modelUsage":{"test-big":{"costUSD":0.5,"outputTokens":0}}}'
} > "$P/sess3.jsonl"
{
    owner "${E}10:01:00.000Z" "fourth"
    call "${E}10:01:10.000Z" q3 test-big end_turn 1000000 0 0 0 0
} > "$P/sess4.jsonl"

# ru <args>: run-usage.sh with the test prices. Sets OUT (stdout and stderr) and RC.
ru() {
    OUT=$(RUN_USAGE_PRICES="$TMP_ROOT/prices.tsv" dash "$RU" "$@" 2>&1)
    RC=$?
}

echo '--- run-usage: one run, two sessions'
cat > "$TMP_ROOT/run-a.md" <<'EOF'
# Run log: demo run

<!-- a comment line, which starts no key -->
workflow: test
config: ~/cfg
session: sess1
session: sess2
session: sess1
start: 2026-01-01T10:00:00Z
spec: aaaaaaa 2026-01-01T10:10:00Z
plan: bbbbbbb 2026-01-01T10:20:00Z
merge: ccccccc 2026-01-01T11:00:00Z
role: ^relay-executor: → executor
role: plan$ → planner
role: [Rr]eview → reviewer

## Notes

session: sess3
EOF
ru "$TMP_ROOT/run-a.md"
assert_eq "usage: exit 0" 0 "$RC"
assert_contains "usage: the title comes from the log's first heading" "# Usage: Run log: demo run" "$OUT"
assert_contains "usage: only the header's sessions, each once" "sessions sess1, sess2. The run:" "$OUT"
assert_contains "usage: the design phase, before the spec commit; 1-hour writes at the 1-hour price" \
    "| main: design | main |  |  | 3 | 6 | 0 | 1,000,000 | 2,000,000 | 160,000 | 3.80 |" "$OUT"
assert_contains "usage: the planning phase, from the spec commit to the plan commit" \
    "| main: planning | main |  |  | 1 | 2 | 0 | 0 | 2,000,000 | 20,000 | 0.40 |" "$OUT"
assert_contains "usage: execution and review, to the merge, in both sessions" \
    "| main: execution and review | main |  |  | 5 | 10 | 0 | 0 | 5,000,000 | 5,000 | 0.55 |" "$OUT"
assert_contains "usage: a subagent row from its meta file; an older usage's writes count as 5-minute ones" \
    "| agent a1 | planner | relay-planner | Write the demo plan | 3 | 6 | 1,000,000 | 0 | 2,000,000 | 115,000 | 2.60 |" "$OUT"
assert_contains "usage: a role line keyed on the agent type wins, being first; a long prompt pays the higher tier" \
    "| agent a2 | executor | relay-executor | Execute the demo plan | 2 | 20 | 0 | 0 | 2,500,000 | 2,000 | 0.23 |" "$OUT"
assert_contains "usage: a nested subagent, under its parent" \
    "| agent a3, under a2 | reviewer | general-purpose | Review task 1 code | 2 | 4 | 0 | 0 | 2,000,000 | 4,000 | 0.24 |" "$OUT"
assert_contains "usage: a subagent no role line matches is other" \
    "| agent a4 | other | Explore | Explore the code | 2 | 200 | 0 | 0 | 0 | 200 | 0.00 |" "$OUT"
assert_eq "usage: subagent rows in the order they started" "a1 a2 a3 a4 " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| agent \(a[0-9]\).*/\1/p' | tr '\n' ' ')"
assert_eq "usage: a subtotal per role, main first" "main planner executor reviewer other " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| subtotal: \([a-z]*\) |.*/\1/p' | tr '\n' ' ')"
assert_contains "usage: the main subtotal" \
    "| subtotal: main | main |  | 3 phases | 9 | 18 | 0 | 1,000,000 | 9,000,000 | 185,000 | 4.75 |" "$OUT"
assert_contains "usage: a role's subtotal" \
    "| subtotal: planner | planner |  | 1 agent | 3 | 6 | 1,000,000 | 0 | 2,000,000 | 115,000 | 2.60 |" "$OUT"
assert_contains "usage: the total counts a repeated message id once and skips a cut-short line" \
    "| total |  |  |  | 18 | 248 | 1,000,000 | 1,000,000 | 15,500,000 | 306,200 | 7.82 |" "$OUT"
assert_contains "usage: wall clock, from the start to the merge" "- **Wall clock:** 1h 00m 00s" "$OUT"
assert_contains "usage: agent time leaves out turn-end waits and an open question, and counts overlaps once" \
    "- **Agent time:** 0h 22m 02s" "$OUT"
assert_contains "usage: waiting on the owner is the rest" "- **Waiting on the owner:** 0h 37m 58s" "$OUT"
assert_contains "usage: the owner's messages, not tool results, notices or dispatch prompts" \
    "- **The owner's messages:** 5" "$OUT"
assert_contains "usage: compactions within the run" "- **Compactions:** 1 " "$OUT"
assert_contains "usage: calls before the start or after the merge stay out of the total" \
    '- **Outside the run:** 2 calls, $2.00' "$OUT"
assert_contains "usage: the cross-check against the last cost record of each session" \
    'whole: $9.82; the cost records (the last `cost-state` of each session): $9.92; difference $0.10 (1.01% of the cost records). Within the tolerance (0 to 10%).' "$OUT"
assert_contains "usage: both sides by model" \
    '- **By model**, cost records / transcripts: test-big $9.59, 304,000 output / $9.59, 304,000 output; test-side $0.10, 50 output / $0.00, 0 output; test-small $0.23, 2,200 output / $0.23, 2,200 output' "$OUT"
assert_not_contains "usage: no unpriced model" "Unpriced" "$OUT"

echo '--- run-usage: a cross-check outside, or incomplete'
printf '%s\n' '# Run log: outside' '' 'config: ~/cfg' 'session: sess3' 'start: 2026-01-02T10:00:00Z' \
    'spec: - 2026-01-02T10:00:05Z' 'plan: - 2026-01-02T10:00:06Z' 'merge: - 2026-01-02T10:02:00Z' > "$TMP_ROOT/run-c.md"
ru "$TMP_ROOT/run-c.md"
assert_eq "usage: a short run: exit 0" 0 "$RC"
assert_contains "usage: transcripts above the cost records are outside the tolerance" \
    'difference -$0.50 (-100.00% of the cost records). OUTSIDE the tolerance (0 to 10%): explain it in the results.' "$OUT"
assert_contains "usage: a model with no price is named, never priced silently" \
    '- **Unpriced models** (no row in the prices file; their calls count as $0): test-unknown (1 call)' "$OUT"
printf '%s\n' '# Run log: incomplete' '' 'config: ~/cfg' 'session: sess3' 'session: sess4' 'start: 2026-01-02T10:00:00Z' \
    'spec: - 2026-01-02T10:00:05Z' 'plan: - 2026-01-02T10:00:06Z' 'merge: - 2026-01-02T10:02:00Z' > "$TMP_ROOT/run-b.md"
ru "$TMP_ROOT/run-b.md"
assert_contains "usage: a session with no cost record makes the cross-check incomplete" \
    "Incomplete: no cost record in session sess4." "$OUT"

echo '--- run-usage: run logs it refuses'
sed '/^merge:/d' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-merge.md"
ru "$TMP_ROOT/bad-merge.md"
assert_eq "usage: no merge line: exit 1" 1 "$RC"
assert_contains "usage: no merge line: says so" "the run log has no 'merge:' line" "$OUT"
sed 's/^session: sess2$/session: nosuch/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-session.md"
ru "$TMP_ROOT/bad-session.md"
assert_eq "usage: an unknown session: exit 1" 1 "$RC"
assert_contains "usage: an unknown session: says so" "no transcript for session nosuch under" "$OUT"
sed 's/^role: plan\$ → planner$/role: plan -> planner/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-role.md"
ru "$TMP_ROOT/bad-role.md"
assert_eq "usage: a role line with no arrow: exit 1" 1 "$RC"
assert_contains "usage: a role line with no arrow: says so" "a role line needs" "$OUT"
sed 's/^start: .*/start: yesterday/' "$TMP_ROOT/run-a.md" > "$TMP_ROOT/bad-time.md"
ru "$TMP_ROOT/bad-time.md"
assert_contains "usage: a time not in UTC form: says so" "not a UTC time like 2026-11-20T14:03:00Z: yesterday" "$OUT"
ru
assert_eq "usage: no argument: exit 1" 1 "$RC"

echo '--- run-usage --sessions'
ru --sessions "$HOME/cfg" 2026-01-01T10:39:00Z 2026-01-01T10:41:00Z
assert_eq "sessions: exit 0" 0 "$RC"
assert_contains "sessions: a session with a record in the window, with its first prompt" \
    "| sess2 | -proj | 2026-01-01T10:40:00Z | 2026-01-01T10:40:20Z | 2026-01-01T10:40:00Z continue |" "$OUT"
assert_not_contains "sessions: a session with no record in it is left out" "| sess1 |" "$OUT"
ru --sessions "~/cfg" 2026-01-01T00:00:00Z 2026-01-03T00:00:00Z
assert_eq "sessions: every session in a wide window, by its first record" "sess1 sess2 sess3 sess4 " \
    "$(printf '%s\n' "$OUT" | sed -n 's/^| \(sess[0-9]\) |.*/\1/p' | tr '\n' ' ')"
assert_contains "sessions: the first prompt is the owner's, at its own time" \
    "| sess1 | -proj | 2026-01-01T09:55:00Z | 2026-01-01T11:05:30Z | 2026-01-01T09:55:00Z before the run |" "$OUT"
ru --sessions "$HOME/cfg" 2026-02-01T00:00:00Z 2026-02-02T00:00:00Z
assert_contains "sessions: an empty window says so" \
    "No session has a record between 2026-02-01T00:00:00Z and 2026-02-02T00:00:00Z." "$OUT"
ru --sessions "$HOME/cfg" 2026-01-01 2026-01-02T00:00:00Z
assert_eq "sessions: a time not in UTC form: exit 1" 1 "$RC"
# file_tool <tool> <path>: one tool_use content block, for call's last argument.
file_tool() {
    printf '{"type":"tool_use","id":"t","name":"%s","input":{"file_path":"%s"}}' "$1" "$2"
}
# agent_meta <transcript> <agent type>: the transcript's meta file.
agent_meta() {
    printf '{"agentType":"%s","description":"x","spawnDepth":1}\n' "$2" > "${1%.jsonl}.meta.json"
}
# pu <args>: plan-usage.sh with the test prices; no git repo above the temporary folder counts.
pu() {
    OUT=$(RUN_USAGE_PRICES="$TMP_ROOT/prices.tsv" GIT_CEILING_DIRECTORIES=$TMP_ROOT dash "$PU" "$@" 2>&1)
    RC=$?
}

echo '--- plan-usage: fixture plans and transcripts'
PU=$REPO/scripts/benchmark/plan-usage.sh
G=2026-01-03T
PR=$TMP_ROOT/pu-repo
PP=$PR/docs/superpowers/plans
PA=$PP/2026-01-01-pu-a.md
PB=$PP/2026-01-01-pu-b.md
PC=$PP/2026-01-01-pu-c.md
PD=$PP/2026-01-01-pu-d.md
PE=$PP/2026-01-01-pu-e.md
git init -q "$PR"
mkdir -p "$PP" "$PR/docs/superpowers/specs"
printf '%s\n' '# Demo spec' '' '## Goal' 'A demo.' > "$PR/docs/superpowers/specs/2026-01-01-pu-design.md"
cat > "$PA" <<'EOF'
# Plan A

**Spec:** `docs/superpowers/specs/2026-01-01-pu-design.md`

```sh
echo in no step
```

### Task 1: The tool

- [x] **Step 1: Write the failing test**

```sh
assert_eq one 1 "$x"
assert_eq two 2 "$y"
```

- [ ] **Step 2: Run test to verify it fails**

  ```sh
  sh tests/x/run-tests.sh
  ```

- [ ] **Step 3: The fixtures,** in `tests/x/run-tests.sh`:

```sh
fixture a
fixture b
fixture c
```

### Task 2: The docs

```sh
echo after a heading
```

- [ ] **Step 1: The doc**

```markdown
# Doc
Some text.
```

- [ ] **Step 2: The skill text**

````markdown
Intro.
```sh
inner
```
````

```
plain
```
EOF
printf '%s\n' '# Plan B' '' '- [ ] **Step 1: Write the failing test**' > "$PB"
printf '%s\n' '# Plan C' '' '**Spec:** `docs/superpowers/specs/nosuch-design.md`' > "$PC"
printf '%s\n' '# Plan D' > "$PD"
printf '%s\n' '# Plan E' > "$PE"

PS=$HOME/.claude/projects/-pu
mkdir -p "$PS/s1/subagents" "$PS/s2/subagents" "$PS/s3/subagents" "$HOME/pu-other/projects/-x/s9/subagents"
# a1, plan A's planner, resumed an hour later: a call written as two records, an older record with no
# cache_creation, a line cut short, a <synthetic> record.
{
    prompt "${G}10:00:00.000Z" "write plan A"
    call "${G}10:01:00.000Z" A1 test-big tool_use 10 1000000 0 0 10000 "$TOOL"
    result "${G}10:01:01.000Z"
    call "${G}10:02:00.000Z" A2 test-big tool_use 10 0 1000000 1000000 20000 "$THINK"
    call "${G}10:02:01.000Z" A2 test-big tool_use 10 0 1000000 1000000 20000 "$(file_tool Write "$PA")"
    result "${G}10:02:02.000Z"
    old_call "${G}10:03:00.000Z" A3 test-big end_turn 10 1000000 2000000 30000
    printf '%s\n' '{"type":"assistant","message":'
    call "${G}10:03:05.000Z" A0 '<synthetic>' end_turn 0 0 0 0 0
    prompt "${G}11:03:05.000Z" "revise plan A"
    call "${G}11:04:00.000Z" A4 test-big tool_use 10 0 0 3000000 45000 "$(file_tool Edit "$PA")"
    result "${G}11:04:01.000Z"
    call "${G}11:05:10.000Z" A5 test-big end_turn 20 100000 0 3000000 60000
} > "$PS/s1/subagents/agent-a1.jsonl"
agent_meta "$PS/s1/subagents/agent-a1.jsonl" relay-planner
# b1 and b2, two planners of plan B; b3, of another type, also edited it; b4 only read it.
{
    prompt "${G}12:00:00.000Z" "write plan B"
    call "${G}12:50:00.000Z" B1 test-small tool_use 100 0 0 2000000 10000 "$(file_tool Write "$PB")"
} > "$PS/s2/subagents/agent-b1.jsonl"
agent_meta "$PS/s2/subagents/agent-b1.jsonl" relay-planner
{
    prompt "${G}13:00:00.000Z" "revise plan B"
    call "${G}13:20:00.000Z" B2 test-big tool_use 100 500000 0 0 20000 "$(file_tool Edit "$PB")"
} > "$PS/s2/subagents/agent-b2.jsonl"
agent_meta "$PS/s2/subagents/agent-b2.jsonl" relay-planner
{
    prompt "${G}13:30:00.000Z" "fix plan B"
    call "${G}13:30:30.000Z" B3 test-small tool_use 100 0 0 100000 5000 "$(file_tool MultiEdit "$PB")"
} > "$PS/s2/subagents/agent-b3.jsonl"
agent_meta "$PS/s2/subagents/agent-b3.jsonl" general-purpose
{
    prompt "${G}13:40:00.000Z" "read plan B"
    call "${G}13:40:10.000Z" B4 test-big tool_use 0 0 0 0 1000000 "$(file_tool Read "$PB")"
} > "$PS/s2/subagents/agent-b4.jsonl"
agent_meta "$PS/s2/subagents/agent-b4.jsonl" Explore
# c1 wrote plan C in a worktree; c2 wrote a file of the same name in another repo; e1 wrote plan E on a model
# with no price.
{
    prompt "${G}14:00:00.000Z" "write plan C"
    call "${G}14:01:00.000Z" C1 test-big tool_use 1 0 0 0 1000 "$(file_tool Write "$PR/.worktrees/w1/docs/superpowers/plans/2026-01-01-pu-c.md")"
} > "$PS/s3/subagents/agent-c1.jsonl"
agent_meta "$PS/s3/subagents/agent-c1.jsonl" relay-planner
{
    prompt "${G}14:10:00.000Z" "write another repo's plan"
    call "${G}14:10:30.000Z" C2 test-big tool_use 0 0 0 0 1000000 "$(file_tool Write "$TMP_ROOT/elsewhere/docs/superpowers/plans/2026-01-01-pu-c.md")"
} > "$PS/s3/subagents/agent-c2.jsonl"
agent_meta "$PS/s3/subagents/agent-c2.jsonl" relay-planner
{
    prompt "${G}16:00:00.000Z" "write plan E"
    call "${G}16:00:10.000Z" E1 test-unknown tool_use 1 0 0 0 1 "$(file_tool Write "$PE")"
} > "$PS/s3/subagents/agent-e1.jsonl"
agent_meta "$PS/s3/subagents/agent-e1.jsonl" relay-planner
# z1, in another config folder, wrote plan D.
{
    prompt "${G}15:00:00.000Z" "write plan D"
    call "${G}15:00:20.000Z" D1 test-big tool_use 0 0 0 0 100 "$(file_tool Write "$PD")"
} > "$HOME/pu-other/projects/-x/s9/subagents/agent-z1.jsonl"
agent_meta "$HOME/pu-other/projects/-x/s9/subagents/agent-z1.jsonl" general-purpose

PU_HEAD='| Plan | Agents | Model | API calls | Output | Cache write | Cache read | Uncached in | Final context | Tool uses | Duration | Cost | Plan lines | Spec lines | Test code | Other code | Text |'
PU_SEP='|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|'
ROW_A='| 2026-01-01-pu-a.md | relay-planner | test-big | 5 | 165,000 | 3,100,000 | 9,000,000 | 60 | 3,100,020 | 3 | 5m10s | $7.18 | 56 | 4 | 5 | 3 | 7 |'
ROW_B='| 2026-01-01-pu-b.md | relay-planner ×2, general-purpose | test-small, test-big | 3 | 35,000 | 500,000 | 2,100,000 | 300 | 100,100 | 3 | 1h10m30s | $1.08 | 3 | - | 0 | 0 | 0 |'
ROW_C='| 2026-01-01-pu-c.md | relay-planner | test-big | 1 | 1,000 | 0 | 0 | 1 | 1 | 1 | 1m00s | $0.01 | 3 | - | 0 | 0 | 0 |'
ROW_D='| 2026-01-01-pu-d.md | general-purpose | test-big | 1 | 100 | 0 | 0 | 0 | 0 | 1 | 0m20s | $0.00 | 1 | - | 0 | 0 | 0 |'
PU_USAGE='usage: plan-usage.sh [--config <folder>] [--no-header] <plan file>'

echo '--- plan-usage: rows'
pu "$PA"
assert_eq "plan-usage: the header names the columns, in order" "$PU_HEAD" "$(printf '%s\n' "$OUT" | sed -n 1p)"
assert_eq "plan-usage: the separator" "$PU_SEP" "$(printf '%s\n' "$OUT" | sed -n 2p)"
assert_eq "plan-usage: a resumed planner: one call per message id, no <synthetic> call or model, 5-minute and 1-hour writes priced apart, an older record's writes as 5-minute ones, the hour between its prompts left out, a cut-short line skipped; the plan's shape and its spec's lines" \
    "$ROW_A" "$(printf '%s\n' "$OUT" | sed -n 3p)"
assert_eq "plan-usage: three lines in all" 3 "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')"
cd "$PR" || exit 1
pu --no-header docs/superpowers/plans/2026-01-01-pu-a.md
cd - > /dev/null || exit 1
assert_eq "plan-usage --no-header: the row alone, for a plan path relative to the checkout's top" "$ROW_A" "$OUT"
pu --no-header "$PB"
assert_eq "plan-usage: two planners and an agent of another type that edited the plan are summed, one that only read it is not; no Spec line" \
    "$ROW_B" "$OUT"
pu --no-header "$PC"
assert_eq "plan-usage: a plan written in a worktree; the same file name in another repo does not count; a Spec line naming no file" \
    "$ROW_C" "$OUT"
git -C "$PR" add docs
git -C "$PR" -c core.hooksPath=/dev/null -c commit.gpgsign=false -c user.name=test -c user.email=test@example.invalid commit -q -m fixtures
git -C "$PR" -c core.hooksPath=/dev/null worktree add -q "$PR/.worktrees/w2"
pu --no-header "$PR/.worktrees/w2/docs/superpowers/plans/2026-01-01-pu-a.md"
assert_eq "plan-usage: a plan given by its path in a worktree is measured as the main checkout's" "$ROW_A" "$OUT"

echo '--- plan-usage: the config folder'
pu --no-header --config "~/pu-other" "$PD"
assert_eq "plan-usage --config: a leading ~/ is the home folder, and only that folder's transcripts count" "$ROW_D" "$OUT"
CLAUDE_CONFIG_DIR=$HOME/pu-other
export CLAUDE_CONFIG_DIR
pu --no-header "$PD"
assert_eq "plan-usage: CLAUDE_CONFIG_DIR is the default config folder" "$ROW_D" "$OUT"
pu --no-header --config "$HOME/.claude" "$PA"
assert_eq "plan-usage: --config wins over CLAUDE_CONFIG_DIR" "$ROW_A" "$OUT"
unset CLAUDE_CONFIG_DIR

echo '--- plan-usage: what it refuses'
pu "$PP/2026-01-01-nosuch.md"
assert_eq "plan-usage: no plan file: exit 1, says so" "1 plan-usage: no plan file at $PP/2026-01-01-nosuch.md" "$RC $OUT"
mkdir -p "$TMP_ROOT/norepo"
printf '# x\n' > "$TMP_ROOT/norepo/plan.md"
pu "$TMP_ROOT/norepo/plan.md"
assert_eq "plan-usage: a plan outside a git repo: exit 1, says so" "1 plan-usage: not in a git repo: $TMP_ROOT/norepo/plan.md" "$RC $OUT"
mkdir -p "$TMP_ROOT/empty-cfg"
pu --config "$TMP_ROOT/empty-cfg" "$PA"
assert_eq "plan-usage: a config folder with no projects folder: exit 1, says so" "1 plan-usage: no projects folder in $TMP_ROOT/empty-cfg" "$RC $OUT"
pu "$PD"
assert_eq "plan-usage: a plan no agent wrote: exit 1, says so" \
    "1 plan-usage: no agent wrote docs/superpowers/plans/2026-01-01-pu-d.md (transcripts under $HOME/.claude/projects)" "$RC $OUT"
pu "$PE"
assert_eq "plan-usage: a model with no price: exit 1, says so" "1 plan-usage: no price for test-unknown in $TMP_ROOT/prices.tsv" "$RC $OUT"
pu
assert_eq "plan-usage: no argument: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu --bogus "$PA"
assert_eq "plan-usage: an option it does not know: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu "$PA" "$PB"
assert_eq "plan-usage: two plans: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"
pu --config
assert_eq "plan-usage: --config with no folder: the usage line, exit 1" "1 $PU_USAGE" "$RC $OUT"


# A fake claude, first on PATH, that records each call as "<CLAUDE_CONFIG_DIR> | <arguments>".
mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/claude" <<'EOF'
#!/bin/sh
printf '%s | %s\n' "${CLAUDE_CONFIG_DIR:-unset}" "$*" >> "$FAKE_CLAUDE_LOG"
case "$*" in
    "plugin marketplace add "*) exit 0 ;;
    "plugin install superpowers@superpowers-marketplace")
        dir=$CLAUDE_CONFIG_DIR/plugins/cache/superpowers-marketplace/superpowers/$FAKE_SP_VERSION
        mkdir -p "$dir/.claude-plugin"
        printf '{"name":"superpowers","version":"%s"}\n' "$FAKE_SP_VERSION" > "$dir/.claude-plugin/plugin.json"
        printf '%s\n' "$dir" > "$CLAUDE_CONFIG_DIR/fake-superpowers"
        exit 0 ;;
    "plugin install "*) exit 0 ;;
    "plugin list --json")
        if [ -f "$CLAUDE_CONFIG_DIR/fake-superpowers" ]; then
            printf '[{"id":"superpowers@superpowers-marketplace","version":"%s","scope":"user","enabled":true,"installPath":"%s"}]\n' \
                "$FAKE_SP_VERSION" "$(cat "$CLAUDE_CONFIG_DIR/fake-superpowers")"
        else
            echo '[]'
        fi
        exit 0 ;;
esac
echo "fake claude: unexpected call: $*" >&2
exit 1
EOF
chmod +x "$TMP_ROOT/fakebin/claude"

SETTINGS='{"env":{"EXAMPLE":"1"},"model":"opus","hooks":{"PreToolUse":[{"matcher":"*","hooks":[{"type":"command","command":"~/.claude/bin/ccs hook PreToolUse","timeout":5}]}],"Stop":[{"matcher":"*","hooks":[{"type":"command","command":"~/.claude/bin/ccs hook Stop","timeout":5}]},{"matcher":"*","hooks":[{"type":"command","command":"/opt/quartz/bin/quartz hook flush","async":true}]}],"SubagentStop":[{"matcher":"*","hooks":[{"type":"command","command":"/opt/quartz/bin/quartz hook flush","async":true}]}]},"enabledPlugins":{"frontend-design@claude-plugins-official":true,"playwright@claude-plugins-official":false,"ui-ux-pro-max@ui-ux-pro-max-skill":true,"hyper-relay@hyper-relay":true},"extraKnownMarketplaces":{"ui-ux-pro-max-skill":{"source":{"source":"github","repo":"example/ui-ux-pro-max-skill"}},"hyper-relay":{"source":{"source":"github","repo":"example/hyper-relay"}}}}'
CLAUDE_JSON='{"oauthAccount":{"emailAddress":"someone@example.invalid"},"projects":{"/somewhere":{"mcpServers":{"local":{"command":"x"}}}},"mcpServers":{"context7":{"type":"http","url":"https://example.invalid/mcp"},"playwright":{"command":"npx"}}}'
CLAUDE_MD_OK=$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' \
    'All creative work runs through the hyper-relay relay.' '' '### Quartz' '' 'The board is live.' '' \
    '## Code Quality' '' '- Fix the root cause.' '' '## Design' '' '- Count, do not prescribe.')

# make_home [<CLAUDE.md>] [<.claude.json>]: a fresh fake home with ~/.claude (skills, agents, hooks,
# bin; no commands, no rules) and ~/.claude.json, and an empty claude log.
make_home() {
    HOME=$(mktemp -d "$TMP_ROOT/home.XXXXXX")
    export HOME
    mkdir -p "$HOME/.claude/skills/demo" "$HOME/.claude/agents" "$HOME/.claude/hooks" "$HOME/.claude/bin"
    printf 'demo\n' > "$HOME/.claude/skills/demo/SKILL.md"
    printf '%s\n' "${1:-$CLAUDE_MD_OK}" > "$HOME/.claude/CLAUDE.md"
    printf '%s\n' "$SETTINGS" > "$HOME/.claude/settings.json"
    printf '%s\n' "${2:-$CLAUDE_JSON}" > "$HOME/.claude.json"
    FAKE_CLAUDE_LOG=$HOME/claude.log
    export FAKE_CLAUDE_LOG
    : > "$FAKE_CLAUDE_LOG"
}

# se <args>: superpowers-env.sh with the fake claude first on PATH; superpowers is at SP_VERSION
# (7.0.2 unless set). Sets OUT and RC.
se() {
    OUT=$(PATH="$TMP_ROOT/fakebin:$PATH" FAKE_SP_VERSION="${SP_VERSION:-7.0.2}" dash "$SE" "$@" 2>&1)
    RC=$?
}

echo '--- superpowers-env: the default build'
make_home
SUM_BEFORE=$(cksum "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude.json")
se
T=$HOME/.claude-superpowers
assert_eq "env: exit 0" 0 "$RC"
assert_eq "env: skills, agents, hooks and bin link to the owner's" \
    "$HOME/.claude/skills $HOME/.claude/agents $HOME/.claude/hooks $HOME/.claude/bin" \
    "$(readlink "$T/skills") $(readlink "$T/agents") $(readlink "$T/hooks") $(readlink "$T/bin")"
assert_eq "env: commands and rules, which the owner has none of, are skipped" "no no" \
    "$(yes_no "$T/commands") $(yes_no "$T/rules")"
assert_contains "env: says what it skipped" "skipped commands: there is no" "$OUT"
assert_eq "env: CLAUDE.md loses the relay's section, its Quartz part included, and keeps the rest" \
    "$(printf '%s\n' '# Global Instructions' '' '## Code Quality' '' '- Fix the root cause.' '' '## Design' '' '- Count, do not prescribe.')" \
    "$(cat "$T/CLAUDE.md")"
assert_eq "env: settings.json enables the same plugins, without hyper-relay" \
    "frontend-design@claude-plugins-official=true playwright@claude-plugins-official=false ui-ux-pro-max@ui-ux-pro-max-skill=true" \
    "$(jq -r '.enabledPlugins | to_entries | map("\(.key)=\(.value)") | join(" ")' "$T/settings.json")"
assert_eq "env: settings.json drops the hyper-relay marketplace only" "ui-ux-pro-max-skill" \
    "$(jq -r '.extraKnownMarketplaces | keys | join(" ")' "$T/settings.json")"
assert_eq "env: Stop keeps its other hook, without quartz hook flush" "~/.claude/bin/ccs hook Stop" \
    "$(jq -r '[.hooks.Stop[].hooks[].command] | join(",")' "$T/settings.json")"
assert_eq "env: SubagentStop, left empty, is dropped" false "$(jq -r '.hooks | has("SubagentStop")' "$T/settings.json")"
assert_eq "env: every other hook and setting is the owner's" \
    "$(jq -c 'del(.hooks.Stop, .hooks.SubagentStop, .enabledPlugins, .extraKnownMarketplaces)' "$HOME/.claude/settings.json")" \
    "$(jq -c 'del(.hooks.Stop, .hooks.SubagentStop, .enabledPlugins, .extraKnownMarketplaces)' "$T/settings.json")"
assert_eq "env: .claude.json holds only the mcpServers block" '["mcpServers"]' "$(jq -c 'keys' "$T/.claude.json")"
assert_eq "env: with the owner's servers" "context7 playwright" "$(jq -r '.mcpServers | keys | join(" ")' "$T/.claude.json")"
assert_eq "env: .claude.json is readable by its owner only" "$T/.claude.json" "$(find "$T/.claude.json" -perm 600)"
assert_eq "env: no projects folder, so no auto-memory" no "$(yes_no "$T/projects")"
assert_eq "env: every claude call runs with CLAUDE_CONFIG_DIR set to the new folder" 0 \
    "$(grep -c -v -F "$T | " "$FAKE_CLAUDE_LOG")"
assert_eq "env: the marketplaces, the enabled plugins, then superpowers and its version" \
    "$(printf '%s\n' "$T | plugin marketplace add anthropics/claude-plugins-official" \
        "$T | plugin marketplace add example/ui-ux-pro-max-skill" \
        "$T | plugin install frontend-design@claude-plugins-official" \
        "$T | plugin install ui-ux-pro-max@ui-ux-pro-max-skill" \
        "$T | plugin marketplace add obra/superpowers-marketplace" \
        "$T | plugin install superpowers@superpowers-marketplace" \
        "$T | plugin list --json")" \
    "$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "env: prints the installed superpowers version" "superpowers 7.0.2, read from" "$OUT"
assert_eq "env: the owner's ~/.claude and ~/.claude.json are unchanged" "$SUM_BEFORE" \
    "$(cksum "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude.json")"

echo '--- superpowers-env: a folder that exists'
: > "$FAKE_CLAUDE_LOG"
se
assert_eq "env: a folder that exists: exit 1" 1 "$RC"
assert_contains "env: a folder that exists: refused" "already exists" "$OUT"
assert_eq "env: a folder that exists: claude is never called" "" "$(cat "$FAKE_CLAUDE_LOG")"

echo '--- superpowers-env: --neutral'
make_home
se --neutral
N=$HOME/.claude-neutral
assert_eq "env: --neutral: exit 0" 0 "$RC"
assert_eq "env: --neutral: builds ~/.claude-neutral" yes "$(yes_no "$N/settings.json")"
assert_eq "env: --neutral: installs neither workflow" 0 "$(grep -c -i -e superpowers -e hyper-relay "$FAKE_CLAUDE_LOG")"
assert_contains "env: --neutral: still installs the other plugins" \
    "$N | plugin install frontend-design@claude-plugins-official" "$(cat "$FAKE_CLAUDE_LOG")"
assert_eq "env: --neutral: its settings name neither workflow" 0 \
    "$(grep -c -i -e superpowers -e hyper-relay "$N/settings.json")"

echo '--- superpowers-env: a folder given, and the superpowers version'
SP_VERSION=4.3.1
se "$HOME/old"
assert_eq "env: superpowers 4.3.1: exit 1" 1 "$RC"
assert_contains "env: superpowers 4.3.1: refused, older than the fork point" "superpowers 4.3.1 is older than 5.1.0" "$OUT"
SP_VERSION=5.1.0
se "$HOME/exact"
assert_eq "env: superpowers 5.1.0 itself: exit 0" 0 "$RC"
assert_eq "env: a folder given: built there" yes "$(yes_no "$HOME/exact/settings.json")"
SP_VERSION=10.0.0
se "$HOME/ten"
assert_eq "env: superpowers 10.0.0, compared as numbers: exit 0" 0 "$RC"
unset SP_VERSION

echo '--- superpowers-env: a CLAUDE.md that changed shape'
make_home "$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' 'Use the relay.' '' '## Design')"
se
assert_eq "env: no Code Quality heading: exit 1" 1 "$RC"
assert_contains "env: no Code Quality heading: refused" "changed shape" "$OUT"
assert_eq "env: no Code Quality heading: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"
make_home "$(printf '%s\n' '# Global Instructions' '' '## Code Quality' '' '- Fix the root cause.')"
se
assert_eq "env: no Workflow heading: exit 1" 1 "$RC"
make_home "$(printf '%s\n' '# Global Instructions' '' '## Workflow: the relay' '' 'Use the relay.' '' \
    '## Code Quality' '' '- Tick the Quartz card.')"
se
assert_eq "env: Quartz left after the cut: exit 1" 1 "$RC"
assert_contains "env: Quartz left after the cut: refused" "still names hyper-relay or Quartz" "$OUT"
assert_eq "env: Quartz left after the cut: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"

echo '--- superpowers-env: what it will not carry over'
make_home "" '{"mcpServers":{"Quartz":{"command":"quartz"}}}'
se
assert_eq "env: a Quartz MCP server: exit 1" 1 "$RC"
assert_contains "env: a Quartz MCP server: refused" "hold a Quartz server" "$OUT"
make_home
jq '.enabledPlugins["x@nowhere"] = true' "$HOME/.claude/settings.json" > "$HOME/settings.tmp"
mv "$HOME/settings.tmp" "$HOME/.claude/settings.json"
se
assert_eq "env: a marketplace with no source: exit 1" 1 "$RC"
assert_contains "env: a marketplace with no source: refused, naming it" "no source for the marketplace nowhere" "$OUT"
assert_eq "env: a marketplace with no source: nothing is built" no "$(yes_no "$HOME/.claude-superpowers")"
se --bogus
assert_eq "env: an option it does not know: exit 1" 1 "$RC"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
