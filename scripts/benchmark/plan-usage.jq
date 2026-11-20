# plan-usage.jq: the transcript reader behind plan-usage.sh (hyper-relay; docs/benchmarks/README.md).
# plan-usage.sh runs it as `jq -n -r -R -f plan-usage.jq <transcripts>`: each input is one line of a Claude
# Code transcript, input_filename names its file, and $ARGS.named holds the rest. It prints the table's
# header and row, or one line starting "!!" that plan-usage.sh turns into a refusal.

# A transcript's time (2026-11-18T05:03:42.217Z), in seconds.
def ts:
    (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)
    + (((capture("\\.(?<f>[0-9]+)Z$") | .f) // "0") | "0." + . | tonumber);

def pad2: if . < 10 then "0" + tostring else tostring end;
def two:
    if . < 0 then "-" + ((0 - .) | two)
    else ((. * 100 + 0.5) | floor) as $c | "\(($c - $c % 100) / 100).\($c % 100 | pad2)" end;
def commas:
    tostring as $s | ($s | length) as $n
    | [range(0; $n) | $s[.:. + 1] + (if . < $n - 1 and ($n - . - 1) % 3 == 0 then "," else "" end)]
    | join("");

# One API call: an assistant record with an id and a usage, not a synthetic message.
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
    | (.in * $p.input + .out * $p.output + .cr * $p.cr + .cw5 * $p.cw5 + .cw1 * $p.cw1) / 1000000;

# A file path that is the plan: in the main checkout, or in a copy of it under .worktrees/<one folder>/.
def is_plan($main; $rp):
    type == "string"
    and (. == $main + "/" + $rp
        or (startswith($main + "/.worktrees/") and endswith("/" + $rp)
            and (ltrimstr($main + "/.worktrees/") | rtrimstr("/" + $rp) | length > 0 and (contains("/") | not))));

def writes_plan($main; $rp):
    .type == "assistant"
    and any(.message.content[]?;
        type == "object" and .type == "tool_use"
        and (.name == "Write" or .name == "Edit" or .name == "MultiEdit")
        and (.input.file_path | is_plan($main; $rp)));

def timed: select((.type == "user" or .type == "assistant") and (.timestamp | type) == "string");

# The active seconds of one agent's records, in line order: from each prompt (a user record that is not a
# tool result) to the last record before the next prompt, or to the agent's last record.
def active:
    [.[] | timed | {t: (.timestamp | ts),
        p: (.type == "user" and ((.message.content | type == "array" and any(.[]; type == "object" and .type == "tool_result")) | not))}]
    | reduce .[] as $e ({s: null, l: null, tot: 0};
        if $e.p then (if .s != null then .tot += (.l - .s) else . end) | .s = $e.t | .l = $e.t
        elif .s != null then .l = $e.t
        else . end)
    | .tot + (if .s == null then 0 else .l - .s end);

def dfmt:
    floor as $s | ($s / 3600 | floor) as $h | (($s % 3600) / 60 | floor) as $m | ($s % 60) as $sec
    | if $h > 0 then "\($h)h\($m | pad2)m\($sec | pad2)s" else "\($m)m\($sec | pad2)s" end;

def uniq_in_order: reduce .[] as $x ([]; if index([$x]) then . else . + [$x] end);

def num: if test("^[0-9]+$") then tonumber | commas else . end;

$ARGS.named as $a
| ($a.prices | price_table) as $P
| [inputs as $line | input_filename as $f | ($line | fromjson? // empty | select(type == "object")) | {f: $f, r: .}] as $all
| (reduce $all[] as $e ({}; .[$e.f] += [$e.r])) as $byfile
| [$byfile | to_entries[] | select(.value | any(.[]; writes_plan($a.main; $a.rp)))
    | {f: .key, type: ($a.types[.key] // "?"), recs: .value,
       first: ([.value[] | timed | .timestamp | ts] | first)}] as $ag
| if ($ag | length) == 0 then "!!no agent wrote \($a.rp) (transcripts under \($a.config)/projects)"
  else
    ([$ag[].recs[] | select(is_call) | {id: .message.id, t: (.timestamp | ts), model: .message.model} + usage_of]
        | group_by(.id) | map(min_by(.t)) | sort_by(.t)) as $calls
    | ([$calls[] | select(price($P) == null)] | first) as $bad
    | if $bad != null then "!!no price for \($bad.model) in \($a.pricesfile)"
      else
        ($calls | map(cost($P)) | add // 0) as $cost
        | ($ag | sort_by(.first) | map(.type)) as $types
        | ($types | uniq_in_order | map(. as $t | ([$types[] | select(. == $t)] | length) as $n
            | if $n > 1 then "\($t) ×\($n)" else $t end) | join(", ")) as $agents
        | ($calls | map(.model) | uniq_in_order | join(", ")) as $models
        | ($calls | last // {in: 0, cw5: 0, cw1: 0, cr: 0} | .in + .cw5 + .cw1 + .cr) as $final
        | ([$ag[].recs[] | select(.type == "assistant") | .message.content? | arrays | .[]
            | select(type == "object" and .type == "tool_use")] | length) as $tools
        | ([$ag[] | .recs | active] | add) as $secs
        | (if $a.header == "1" then
            "| Plan | Agents | Model | API calls | Output | Cache write | Cache read | Uncached in | Final context | Tool uses | Duration | Cost | Plan lines | Spec lines | Test code | Other code | Text |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
           else empty end),
          ([$a.plan, $agents, $models, ($calls | length | commas),
            ($calls | map(.out) | add // 0 | commas),
            ($calls | map(.cw5 + .cw1) | add // 0 | commas),
            ($calls | map(.cr) | add // 0 | commas),
            ($calls | map(.in) | add // 0 | commas),
            ($final | commas), ($tools | commas), ($secs | dfmt), ("$" + ($cost | two)),
            ($a.planlines | num), ($a.speclines | num), ($a.test | num), ($a.other | num), ($a.text | num)]
           | "| " + join(" | ") + " |")
      end
  end
