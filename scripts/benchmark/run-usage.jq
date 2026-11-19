# run-usage.jq: the transcript reader behind run-usage.sh (hyper-relay G.2; docs/benchmarks/README.md).
# run-usage.sh runs it as `jq -n -r -R -f run-usage.jq <transcripts>`: each input is one line of a Claude
# Code transcript, input_filename names its file, and $ARGS.named holds the rest: "mode" (report or
# sessions) and that mode's arguments, which run-usage.sh names.

# A transcript's time (2026-11-18T05:03:42.217Z) or a run log's (2026-11-18T05:10:12Z), in seconds.
def ts:
    (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)
    + (((capture("\\.(?<f>[0-9]+)Z$") | .f) // "0") | "0." + . | tonumber);

def iso: floor | todate;
def pad2: if . < 10 then "0" + tostring else tostring end;
def hms: floor as $s | "\($s / 3600 | floor)h \(($s % 3600) / 60 | floor | pad2)m \($s % 60 | pad2)s";
def two:
    if . < 0 then "-" + ((0 - .) | two)
    else ((. * 100 + 0.5) | floor) as $c | "\(($c - $c % 100) / 100).\($c % 100 | pad2)" end;
def usd: if . < 0 then "-$" + ((0 - .) | two) else "$" + two end;
def commas:
    tostring as $s | ($s | length) as $n
    | [range(0; $n) | $s[.:. + 1] + (if . < $n - 1 and ($n - . - 1) % 3 == 0 then "," else "" end)]
    | join("");
def cell: tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");

# The text of a message's content: a string, or the text blocks of an array.
def text_of:
    if type == "string" then .
    elif type == "array" then [.[] | select(type == "object" and .type == "text") | .text] | join(" ")
    else "" end;

# One API call: an assistant record with an id and a usage, not a synthetic message. Claude Code writes
# a call once per content block, each time with the same id and usage.
def is_call:
    .type == "assistant" and (.message | type) == "object"
    and (.message.id | type) == "string" and (.message.usage | type) == "object"
    and (.message.model // "") != "<synthetic>";

def usage_of:
    .message.usage as $u | (($u.cache_creation | type) == "object") as $split
    | {in: ($u.input_tokens // 0),
       cw5: (if $split then ($u.cache_creation.ephemeral_5m_input_tokens // 0) else ($u.cache_creation_input_tokens // 0) end),
       cw1: (if $split then ($u.cache_creation.ephemeral_1h_input_tokens // 0) else 0 end),
       cr: ($u.cache_read_input_tokens // 0),
       out: ($u.output_tokens // 0)};

# A record after which its transcript waits on the owner, until its next user or assistant record: an
# assistant message that ends its turn (no tool call pending), an AskUserQuestion call, an interruption.
def waits:
    (.type == "assistant"
        and ((.message.stop_reason // "tool_use") as $s | ($s != "tool_use" and $s != "pause_turn")
            or any(.message.content[]?; type == "object" and .type == "tool_use" and .name == "AskUserQuestion")))
    or (.type == "user" and (.message.content | text_of | startswith("[Request interrupted by user")));

# The owner's own prompt: not a tool result, a harness notice, another session's message or a local command.
def is_owner: .type == "user" and ((.origin | if type == "object" then .kind else null end) == "human");

# What one transcript line gives: a call, a timed record, the owner's prompt, a compaction, or a cost
# record (cost-state, which Claude Code writes with no time).
def events($src):
    fromjson? // empty
    | select(type == "object")
    | if .type == "cost-state" then
        {k: "cost", src: $src, n: input_line_number, total: (.totalCostUSD // 0), models: (.modelUsage // {})}
      elif (.timestamp | type) == "string" then
        (.timestamp | ts) as $t
        | (if is_call then {k: "call", src: $src, id: .message.id, t: $t, model: .message.model} + usage_of else empty end),
          (if .type == "user" or .type == "assistant" then {k: "rec", src: $src, t: $t, wait: waits} else empty end),
          (if is_owner then {k: "owner", src: $src, t: $t} else empty end),
          (if .type == "system" and .subtype == "compact_boundary" then {k: "compact", src: $src, t: $t} else empty end)
      else empty end;

# The length of the union of [start, end] spans.
def union_len:
    sort_by(.[0])
    | reduce .[] as $iv ({cur: null, total: 0};
        if .cur == null then .cur = $iv
        elif $iv[0] <= .cur[1] then .cur[1] = ([.cur[1], $iv[1]] | max)
        else .total += (.cur[1] - .cur[0]) | .cur = $iv end)
    | .total + (if .cur == null then 0 else .cur[1] - .cur[0] end);

# One transcript's working spans: from each record to the next, unless the record leaves it waiting.
def working:
    sort_by(.t) | . as $r
    | [range(0; length - 1) | select($r[.].wait | not) | [$r[.].t, $r[. + 1].t]];

def price_table:
    split("\n")
    | map(select(length > 0 and (startswith("#") | not)) | split("\t")
        | {model: .[0], over: (.[1] | tonumber), input: (.[2] | tonumber), output: (.[3] | tonumber),
           cr: (.[4] | tonumber), cw5: (.[5] | tonumber), cw1: (.[6] | tonumber)});
def price($table):
    (.in + .cw5 + .cw1 + .cr) as $prompt | .model as $m
    | [$table[] | select(.model == $m and (.over == 0 or $prompt > .over))] | max_by(.over);
def cost($table):
    price($table) as $p
    | if $p == null then 0
      else (.in * $p.input + .out * $p.output + .cr * $p.cr + .cw5 * $p.cw5 + .cw1 * $p.cw1) / 1000000 end;
def sums($table):
    {calls: length, in: (map(.in) | add // 0), cw5: (map(.cw5) | add // 0), cw1: (map(.cw1) | add // 0),
     cr: (map(.cr) | add // 0), out: (map(.out) | add // 0), cost: (map(cost($table)) | add // 0)};
def addsums:
    reduce .[] as $s ({calls: 0, in: 0, cw5: 0, cw1: 0, cr: 0, out: 0, cost: 0};
        .calls += $s.calls | .in += $s.in | .cw5 += $s.cw5 | .cw1 += $s.cw1 | .cr += $s.cr
        | .out += $s.out | .cost += $s.cost);
def row($label; $role; $type; $desc):
    "| \($label) | \($role) | \($type) | \($desc | cell) | \(.calls | commas) | \(.in | commas) | \(.cw5 | commas) | \(.cw1 | commas) | \(.cr | commas) | \(.out | commas) | \(.cost | two) |";

# A subagent's role: the first role line whose regex matches "<agentType>: <description>", else other.
def role_for($roles):
    "\(.type): \(.desc)" as $d
    | ([$roles[] | . as $r | select($d | test($r.re)) | $r.role] | first) // "other";

def report:
    $ARGS.named as $a
    | ($a.prices | price_table) as $P
    | {start: ($a.start | ts), spec: ($a.spec | ts), plan: ($a.plan | ts), merge: ($a.merge | ts)} as $w
    | ($a.man | map({key: .file, value: .}) | from_entries) as $byfile
    | ($a.man | map({key: .src, value: .}) | from_entries) as $bysrc
    | [inputs as $line | $byfile[input_filename].src as $src | $line | events($src)] as $ev
    | ([$ev[] | select(.k == "call")] | group_by(.id) | map(min_by(.t))) as $calls
    | ($calls | map(. + {row: (
        if .t < $w.start or .t > $w.merge then "outside"
        elif (.src | startswith("main:") | not) then .src
        elif .t < $w.spec then "main:design"
        elif .t < $w.plan then "main:planning"
        else "main:execution" end)})) as $rowed
    | [$rowed[] | select(.row != "outside")] as $in
    | [$rowed[] | select(.row == "outside")] as $out
    | [(["main:design", "design"], ["main:planning", "planning"], ["main:execution", "execution and review"])
        | .[0] as $r | {label: .[1], s: ([$in[] | select(.row == $r)] | sums($P))}] as $main
    | ([$in[] | select(.row | startswith("agent:"))] | group_by(.row)
        | map(.[0].row as $r
            | {first: (map(.t) | min), s: sums($P)} + ($bysrc[$r] | {agent, type, desc, parent})
            | .role = role_for($a.roles))
        | sort_by(.first)) as $agents
    | (([$ev[] | select(.k == "rec")] | group_by(.src) | map(working) | add // [])
        | map([([.[0], $w.start] | max), ([.[1], $w.merge] | min)] | select(.[1] > .[0]))
        | union_len) as $agent_time
    | ([$ev[] | select(.k == "owner" and (.src | startswith("main:")) and .t >= $w.start and .t <= $w.merge)]
        | length) as $owner
    | ([$ev[] | select(.k == "compact" and .t >= $w.start and .t <= $w.merge)] | length) as $compactions
    | ([$ev[] | select(.k == "cost")] | group_by(.src) | map(max_by(.n))) as $records
    | ([$a.man[] | select(.kind == "main") | .src] - [$records[].src] | map(ltrimstr("main:"))) as $missing
    | ($calls | map(cost($P)) | add // 0) as $own
    | ($records | map(.total) | add // 0) as $rec
    | ($rec - $own) as $gap
    | ($records | map(.models | to_entries[]) | group_by(.key)
        | map({key: .[0].key, value: {cost: (map(.value.costUSD // 0) | add), out: (map(.value.outputTokens // 0) | add)}})
        | from_entries) as $rec_models
    | ($calls | group_by(.model)
        | map({key: .[0].model, value: {cost: (map(cost($P)) | add), out: (map(.out) | add)}})
        | from_entries) as $own_models
    | ([$calls[] | select(price($P) == null) | .model] | group_by(.) | map({model: .[0], n: length})) as $unpriced
    | "# Usage: \($a.title)",
      "",
      "Config `\($a.config)`; sessions \([$a.man[] | select(.kind == "main") | .session] | join(", ")). The run: \($a.start) to \($a.merge) (UTC); spec \($a.spec), plan \($a.plan).",
      "",
      "| Row | Role | Type | Description | Calls | Input | Cache write 5m | Cache write 1h | Cache read | Output | Cost (USD) |",
      "|---|---|---|---|---|---|---|---|---|---|---|",
      ($main[] | . as $m | $m.s | row("main: \($m.label)"; "main"; ""; "")),
      ($agents[] | . as $g | $g.s
        | row("agent \($g.agent)\(if $g.parent then ", under \($g.parent)" else "" end)"; $g.role; $g.type; $g.desc)),
      ([$main[].s] | addsums | row("subtotal: main"; "main"; ""; "3 phases")),
      (reduce $agents[].role as $x ([]; if index([$x]) then . else . + [$x] end)
        | .[] as $r | [$agents[] | select(.role == $r) | .s] | length as $n
        | addsums | row("subtotal: \($r)"; $r; ""; "\($n) agent\(if $n == 1 then "" else "s" end)")),
      ($in | sums($P) | row("total"; ""; ""; "")),
      "",
      "- **Wall clock:** \($w.merge - $w.start | hms), from the run's start to its merge commit",
      "- **Agent time:** \($agent_time | hms), the union of the time some transcript of the run was working",
      "- **Waiting on the owner:** \($w.merge - $w.start - $agent_time | hms), wall clock minus agent time, nights included; never a cost of either workflow",
      "- **The owner's messages:** \($owner)",
      "- **Compactions:** \($compactions) (a compaction's own call is in the cost records, in no transcript)",
      "- **Outside the run:** \($out | length | commas) calls, \($out | sums($P) | .cost | usd), before its start or after its merge; not in the total",
      "- **Cross-check:** the transcripts of these sessions, whole: \($own | usd); the cost records (the last `cost-state` of each session): \($rec | usd); difference \($gap | usd) (\(if $rec > 0 then $gap / $rec * 100 else 0 end | two)% of the cost records). \(if ($missing | length) > 0 then "Incomplete: no cost record in session \($missing | join(", "))." elif $gap >= -0.005 and $gap <= 0.10 * $rec then "Within the tolerance (0 to 10%)." else "OUTSIDE the tolerance (0 to 10%): explain it in the results." end)",
      "- **By model**, cost records / transcripts: \((($rec_models | keys) + ($own_models | keys)) | unique | map(. as $m | "\($m) \($rec_models[$m].cost // 0 | usd), \($rec_models[$m].out // 0 | commas) output / \($own_models[$m].cost // 0 | usd), \($own_models[$m].out // 0 | commas) output") | join("; "))",
      (if ($unpriced | length) > 0
       then "- **Unpriced models** (no row in the prices file; their calls count as $0): \($unpriced | map("\(.model) (\(.n) call\(if .n == 1 then "" else "s" end))") | join(", "))"
       else empty end);

# --sessions: every session file with a timed record in [from, to], with its first and last record and
# the owner's first prompt in it.
def sessions:
    $ARGS.named as $a | ($a.from | ts) as $from | ($a.to | ts) as $to
    | reduce (inputs as $line | input_filename as $f | $line | fromjson? // empty
        | select(type == "object" and (.timestamp | type) == "string")
        | {f: $f, t: (.timestamp | ts), p: (if is_owner then (.message.content | text_of) else null end)}) as $e
        ({}; .[$e.f] |= ((. // {first: $e.t, last: $e.t, win: false, prompt: null, pt: null})
            | .first = ([.first, $e.t] | min) | .last = ([.last, $e.t] | max)
            | .win = (.win or ($e.t >= $from and $e.t <= $to))
            | if .prompt == null and $e.p != null then .prompt = $e.p | .pt = $e.t else . end))
    | [to_entries[] | select(.value.win)] | sort_by(.value.first)
    | if length == 0 then "No session has a record between \($a.from) and \($a.to)."
      else "| Session | Project | First record | Last record | First prompt |",
        "|---|---|---|---|---|",
        (.[] | (.key | split("/")) as $p | .value as $v
          | "| \($p[-1] | rtrimstr(".jsonl")) | \($p[-2]) | \($v.first | iso) | \($v.last | iso) | \(if $v.prompt == null then "(none)" else "\($v.pt | iso) \($v.prompt | gsub("\\s+"; " ") | .[0:80] | cell)" end) |")
      end;

if $ARGS.named.mode == "sessions" then sessions else report end
