#!/bin/sh
# POSIX tests for wt. No real containers: a fake `docker` and `ss` go first on PATH,
# git is real, and each test gets its own repo, worktree and state directory.
# Usage: sh run-tests.sh   (WT_BIN overrides the script under test)
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
WT_BIN="${WT_BIN:-$HERE/../../bin/wt}"
FIXTURES="$HERE/fixtures"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
PASSED=0
FAILED=0

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

mkdir -p "$TMP_ROOT/fakebin"
cat > "$TMP_ROOT/fakebin/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_LOG"
case " $* " in
    *" config --format json "*) cat "$FAKE_CONFIG" ;;
    *" ps -a --format json "*) cat "$FAKE_PS" ;;
    *" up --build -d "*)
        [ -z "${FAKE_UP_OUTPUT:-}" ] || printf '%s\n' "$FAKE_UP_OUTPUT"
        exit "${FAKE_UP_RC:-0}"
        ;;
esac
exit 0
EOF
cat > "$TMP_ROOT/fakebin/ss" <<'EOF'
#!/bin/sh
for port in ${FAKE_BUSY:-}; do
    case "$*" in
        *":$port"*) echo "LISTEN 0 0 127.0.0.1:$port" ;;
    esac
done
exit 0
EOF
chmod +x "$TMP_ROOT/fakebin/docker" "$TMP_ROOT/fakebin/ss"

# Sets up a fresh project, worktree and state. Sets MAIN, WT, STATE_DIR, FAKE_*.
new_case() { # fixture branch
    CASE_DIR=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
    MAIN="$CASE_DIR/myproj"
    WT="$CASE_DIR/wt"
    STATE_DIR="$CASE_DIR/state"
    git init -q -b main "$MAIN"
    git -C "$MAIN" config user.email t@example.invalid
    git -C "$MAIN" config user.name t
    printf 'CORS_ALLOWED_ORIGINS=http://localhost:3001\nNEXT_PUBLIC_API_URL=x\nTRUSTED_PROXY_CIDRS=172.30.0.10/32\nOTHER=keep\n' > "$MAIN/.env.example"
    printf 'services: {}\n' > "$MAIN/docker-compose.yml"
    printf '.env\n' > "$MAIN/.gitignore"
    git -C "$MAIN" add .
    git -C "$MAIN" commit -qm init
    git -C "$MAIN" worktree add -q -b "$2" "$WT"
    export FAKE_LOG="$CASE_DIR/docker.log"
    export FAKE_CONFIG="$FIXTURES/$1.json"
    export FAKE_PS="$FIXTURES/ps-ok.json"
    : > "$FAKE_LOG"
    unset FAKE_BUSY FAKE_UP_RC FAKE_UP_OUTPUT
}

run_wt() { # dir args...
    run_dir=$1
    shift
    OUT=$(cd "$run_dir" && PATH="$TMP_ROOT/fakebin:$PATH" WT_STATE_DIR="$STATE_DIR" WT_WAIT_SECONDS=1 dash "$WT_BIN" "$@" 2>&1)
    RC=$?
}

conf() { # text
    printf '%s\n' "$1" > "$WT/.wt.conf"
}

APP_CONF="WT_SEED_PROFILE=seed
WT_ENV='CORS_ALLOWED_ORIGINS=http://localhost:{web}
NEXT_PUBLIC_API_URL=http://localhost:{api}/api/v1'"

echo '--- refusals'
new_case app feat/one
run_wt "$MAIN" up
assert_eq "up refuses a main checkout: exit" 1 "$RC"
assert_contains "up refuses a main checkout: message" "main checkout" "$OUT"
assert_eq "up refuses a main checkout: docker untouched" "" "$(cat "$FAKE_LOG")"

run_wt "$WT" up
assert_eq "up needs .wt.conf: exit" 1 "$RC"
assert_contains "up needs .wt.conf: message" ".wt.conf" "$OUT"

conf "WT_ENV='CORS_ALLOWD_ORIGINS=http://localhost:{web}'"
run_wt "$WT" up
assert_eq "a misspelled key stops before building: exit" 1 "$RC"
assert_contains "a misspelled key is named" "CORS_ALLOWD_ORIGINS" "$OUT"
assert_not_contains "a misspelled key builds nothing" "up --build" "$(cat "$FAKE_LOG")"

new_case app feat/one
conf "WT_ENV='CORS_ALLOWED_ORIGINS=http://localhost:{wbe}'"
run_wt "$WT" up
assert_eq "an unknown placeholder stops: exit" 1 "$RC"
assert_contains "an unknown placeholder is named" "{wbe}" "$OUT"
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

new_case app feat/one
conf "$APP_CONF"
printf 'REAL=secret\n' > "$WT/.env"
run_wt "$WT" up
assert_eq "an existing .env is not overwritten: exit" 1 "$RC"
assert_eq "an existing .env is kept" "REAL=secret" "$(cat "$WT/.env")"

run_wt "$WT" down app
assert_eq "down refuses a real project name" 1 "$RC"
assert_contains "down refuses a real project name: message" "not a wt stack" "$OUT"
run_wt "$WT" down ../../etc-wt-x
assert_eq "down refuses a path" 1 "$RC"
run_wt "$WT" down app-wt-missing
assert_eq "down refuses an unknown stack" 1 "$RC"
assert_not_contains "refused downs never reach docker" " down " "$(cat "$FAKE_LOG")"

echo '--- up on app'
new_case app Feat/Add_Thing
conf "$APP_CONF"
run_wt "$WT" up
assert_eq "up succeeds" 0 "$RC"
ST="$STATE_DIR/myproj-wt-feat-add-thing"
assert_eq "stack name is project plus slug" 1 "$(ls "$STATE_DIR" | grep -c '^myproj-wt-feat-add-thing$')"
assert_contains "compose uses the stack name" "-p myproj-wt-feat-add-thing" "$(cat "$FAKE_LOG")"
assert_contains "up uses the override" "-f $ST/override.yml" "$(grep -- 'up --build' "$FAKE_LOG")"
assert_contains "the first up includes the seed profile" "--profile seed" "$(grep -- 'up --build' "$FAKE_LOG")"
assert_eq "api port is the first in slot 1" "api 8082 tcp 30100" "$(sed -n 1p "$ST/ports")"
assert_eq "web port" "web 3001 tcp 30104" "$(grep '^web ' "$ST/ports")"
OV=$(cat "$ST/override.yml")
assert_contains "override replaces ports" 'ports: !override' "$OV"
assert_contains "ports bind to loopback" '"127.0.0.1:30100:8082/tcp"' "$OV"
assert_contains "api gets its own image tag" 'image: app-api:wt-feat-add-thing' "$OV"
assert_not_contains "shared images are not retagged" 'postgres:wt' "$OV"
assert_not_contains "no subnet without a pinned one" 'subnet' "$OV"
assert_eq "images are recorded once each" 3 "$(wc -l < "$ST/images")"
ENVF=$(cat "$WT/.env")
assert_contains "CORS follows the web port" 'CORS_ALLOWED_ORIGINS=http://localhost:30104' "$ENVF"
assert_contains "the API URL follows the api port" 'NEXT_PUBLIC_API_URL=http://localhost:30100/api/v1' "$ENVF"
assert_contains "other values are kept" 'OTHER=keep' "$ENVF"
assert_contains "the URLs are printed" 'http://localhost:30104' "$OUT"
assert_eq "the seed is marked done" 0 "$([ -f "$ST/seeded" ]; echo $?)"

: > "$FAKE_LOG"
run_wt "$WT" up
assert_eq "a second up succeeds" 0 "$RC"
assert_not_contains "a second up does not seed again" "--profile seed" "$(grep -- 'up --build' "$FAKE_LOG")"
assert_eq "a second up keeps the ports" "web 3001 tcp 30104" "$(grep '^web ' "$ST/ports")"

echo '--- space-separated WT_ENV'
new_case app feat/one
conf "WT_ENV='CORS_ALLOWED_ORIGINS=http://localhost:{web} NEXT_PUBLIC_API_URL=http://localhost:{api}/api/v1'"
run_wt "$WT" up
assert_eq "spaces also separate pairs" 0 "$RC"
assert_contains "the second pair applies" 'NEXT_PUBLIC_API_URL=http://localhost:30100/api/v1' "$(cat "$WT/.env")"

echo '--- pinned-net shape'
new_case pinned-net feat/one
conf "WT_SEED_PROFILE=seed
WT_SETUP='echo ran >> setup.log'
WT_ENV='TRUSTED_PROXY_CIDRS={ip:web}/32'"
run_wt "$WT" up
assert_eq "pinned-net shape succeeds" 0 "$RC"
ST="$STATE_DIR/myproj-wt-feat-one"
OV=$(cat "$ST/override.yml")
assert_contains "the subnet moves to the slot" '- subnet: 10.77.1.0/24' "$OV"
assert_contains "the subnet replaces the old one" 'config: !override' "$OV"
assert_contains "the fixed address keeps its last octet" 'ipv4_address: 10.77.1.10' "$OV"
assert_contains "the trusted proxy follows the address" 'TRUSTED_PROXY_CIDRS=10.77.1.10/32' "$(cat "$WT/.env")"
assert_contains "seed services get the new image tag" 'seed-builtin:' "$OV"
assert_eq "one tag per repo" 3 "$(wc -l < "$ST/images")"
run_wt "$WT" up
assert_eq "setup runs only once" 1 "$(wc -l < "$WT/setup.log")"

echo '--- slots and limit'
new_case app feat/one
conf "$APP_CONF"
run_wt "$WT" up
for b in two three four; do
    git -C "$MAIN" worktree add -q -b "feat/$b" "$CASE_DIR/wt-$b"
    cp "$WT/.wt.conf" "$CASE_DIR/wt-$b/.wt.conf"
done
run_wt "$CASE_DIR/wt-two" up
assert_eq "second stack takes slot 2" 2 "$(cat "$STATE_DIR/myproj-wt-feat-two/slot")"
assert_eq "second stack's port range" "api 8082 tcp 30200" "$(sed -n 1p "$STATE_DIR/myproj-wt-feat-two/ports")"
run_wt "$CASE_DIR/wt-three" up
assert_eq "third stack fits" 0 "$RC"
run_wt "$CASE_DIR/wt-four" up
assert_eq "a fourth stack is refused" 1 "$RC"
assert_contains "the refusal lists the stacks" "myproj-wt-feat-one" "$OUT"
assert_eq "a refused stack leaves no state" 1 "$([ -e "$STATE_DIR/myproj-wt-feat-four" ]; echo $?)"
run_wt "$WT" down myproj-wt-feat-two
run_wt "$CASE_DIR/wt-four" up
assert_eq "a freed slot is reused" 2 "$(cat "$STATE_DIR/myproj-wt-feat-four/slot")"

echo '--- busy ports'
new_case app feat/one
conf "$APP_CONF"
export FAKE_BUSY=30100
run_wt "$WT" up
assert_eq "a busy port is skipped" "api 8082 tcp 30101" "$(sed -n 1p "$STATE_DIR/myproj-wt-feat-one/ports")"

echo '--- failures'
new_case app feat/one
conf "$APP_CONF"
export FAKE_UP_RC=1
export FAKE_UP_OUTPUT="Bind for 127.0.0.1:30100 failed: port is already allocated"
run_wt "$WT" up
assert_eq "a taken port fails" 1 "$RC"
assert_contains "a taken port says what to do" "run wt up again" "$OUT"
assert_eq "a taken port frees the allocation" 1 "$([ -f "$STATE_DIR/myproj-wt-feat-one/ports" ]; echo $?)"
assert_eq "a failed up leaves the seed unmarked" 1 "$([ -f "$STATE_DIR/myproj-wt-feat-one/seeded" ]; echo $?)"

new_case app feat/one
conf "$APP_CONF"
export FAKE_PS="$FIXTURES/ps-seed-failed.json"
run_wt "$WT" up
assert_eq "a failed seed fails up" 1 "$RC"
assert_contains "a failed seed is named" "seed" "$OUT"
assert_eq "a failed seed is not marked" 1 "$([ -f "$STATE_DIR/myproj-wt-feat-one/seeded" ]; echo $?)"
export FAKE_PS="$FIXTURES/ps-ok.json"
: > "$FAKE_LOG"
run_wt "$WT" up
assert_contains "the next up retries the seed" "--profile seed" "$(grep -- 'up --build' "$FAKE_LOG")"

new_case app feat/one
conf "$APP_CONF"
export FAKE_PS="$FIXTURES/ps-starting.json"
run_wt "$WT" up
assert_eq "a service stuck starting times out" 1 "$RC"
assert_contains "the timeout names the service" "web" "$OUT"

new_case app feat/one
conf "$APP_CONF"
export FAKE_PS="$FIXTURES/ps-seed-running.json"
run_wt "$WT" up
assert_eq "a seed still running is not ready" 1 "$RC"
assert_contains "the wait names the running seed" "waiting for: seed" "$OUT"
assert_eq "a seed still running is not marked" 1 "$([ -f "$STATE_DIR/myproj-wt-feat-one/seeded" ]; echo $?)"

new_case app feat/one
conf "$APP_CONF
WT_SETUP='exit 7'"
run_wt "$WT" up
assert_eq "a failed setup stops" 1 "$RC"
assert_not_contains "a failed setup builds nothing" "up --build" "$(cat "$FAKE_LOG")"

echo '--- ls and down'
new_case app feat/one
run_wt "$WT" ls
assert_eq "ls with no stacks" "no wt stacks" "$OUT"
conf "$APP_CONF"
run_wt "$WT" up
run_wt "$WT" ls
assert_contains "ls names the stack" "myproj-wt-feat-one" "$OUT"
assert_contains "ls prints URLs" "http://localhost:30104" "$OUT"
assert_not_contains "a live worktree is not stale" "stale" "$OUT"

: > "$FAKE_LOG"
run_wt "$WT" down
assert_eq "down in a worktree succeeds" 0 "$RC"
assert_contains "down removes volumes and profile containers" "compose -p myproj-wt-feat-one down -v --remove-orphans" "$(cat "$FAKE_LOG")"
assert_contains "down removes its own image" "image rm app-api:wt-feat-one" "$(cat "$FAKE_LOG")"
assert_not_contains "down leaves shared images" "postgres" "$(cat "$FAKE_LOG")"
assert_eq "down removes .env" 1 "$([ -e "$WT/.env" ]; echo $?)"
assert_eq "down removes the state" 1 "$([ -e "$STATE_DIR/myproj-wt-feat-one" ]; echo $?)"

conf "$APP_CONF"
run_wt "$WT" up
git -C "$MAIN" worktree remove --force "$WT"
run_wt "$MAIN" ls
assert_contains "ls marks a removed worktree stale" "stale" "$OUT"
assert_contains "ls gives the command that clears it" "wt down myproj-wt-feat-one" "$OUT"
run_wt "$MAIN" down myproj-wt-feat-one
assert_eq "down by name works without the worktree" 0 "$RC"

echo '--- new'
# A project whose .worktrees/ is ignored, with a feat/api branch one commit ahead.
new_repo() { # .wt.conf text (may be empty)
    new_case app feat/existing-wt
    printf '.env\n/.worktrees/\n' > "$MAIN/.gitignore"
    [ -z "$1" ] || printf '%s\n' "$1" > "$MAIN/.wt.conf"
    git -C "$MAIN" add .
    git -C "$MAIN" commit -qm ignore
    git -C "$MAIN" branch feat/api
    git -C "$MAIN" worktree add -q "$CASE_DIR/api-wt" feat/api
    printf 'api\n' > "$CASE_DIR/api-wt/api.txt"
    git -C "$CASE_DIR/api-wt" add api.txt
    git -C "$CASE_DIR/api-wt" commit -qm api
    git -C "$MAIN" worktree remove "$CASE_DIR/api-wt"
}
head_of() { git -C "$1" rev-parse HEAD; }

new_case app feat/one
run_wt "$MAIN" new feat/thing
assert_eq "new refuses an unignored .worktrees: exit" 1 "$RC"
assert_contains "new refuses an unignored .worktrees: message" "not gitignored" "$OUT"
assert_eq "new refuses an unignored .worktrees: no branch" 1 "$(git -C "$MAIN" show-ref --verify --quiet refs/heads/feat/thing; echo $?)"

new_repo ""
run_wt "$MAIN" new
assert_eq "new needs a branch" 1 "$RC"
assert_contains "new without a branch prints usage" "usage: wt new" "$OUT"
run_wt "$MAIN" new feat/thing --frm main
assert_eq "new refuses an unknown option" 1 "$RC"
run_wt "$MAIN" new 'feat/bad..name'
assert_eq "new refuses an invalid branch name" 1 "$RC"

run_wt "$MAIN" new feat/thing
assert_eq "new from main succeeds" 0 "$RC"
assert_eq "new drops the type/ prefix" 0 "$([ -d "$MAIN/.worktrees/thing" ]; echo $?)"
assert_eq "new branches from main by default" "$(head_of "$MAIN")" "$(head_of "$MAIN/.worktrees/thing")"
assert_eq "new checks out the new branch" "feat/thing" "$(git -C "$MAIN/.worktrees/thing" branch --show-current)"
assert_contains "new prints the path" "$MAIN/.worktrees/thing on feat/thing (from main)" "$OUT"
assert_eq "new never touches docker" "" "$(cat "$FAKE_LOG")"

run_wt "$MAIN" new feat/web --from feat/api
assert_eq "new --from succeeds" 0 "$RC"
assert_eq "new --from stacks on the base" "$(git -C "$MAIN" rev-parse feat/api)" "$(head_of "$MAIN/.worktrees/web")"
run_wt "$MAIN" new feat/web2 --from=feat/api
assert_eq "new --from= also works" "$(git -C "$MAIN" rev-parse feat/api)" "$(head_of "$MAIN/.worktrees/web2")"

run_wt "$MAIN" new feat/nobase --from feat/missing
assert_eq "new refuses an unknown base" 1 "$RC"
assert_contains "new names the unknown base" "feat/missing" "$OUT"
assert_eq "an unknown base creates no branch" 1 "$(git -C "$MAIN" show-ref --verify --quiet refs/heads/feat/nobase; echo $?)"

run_wt "$MAIN" new fix/thing
assert_eq "new refuses an existing folder" 1 "$RC"
assert_contains "new names the existing folder" ".worktrees/thing already exists" "$OUT"

run_wt "$MAIN" new feat/api --from main
assert_eq "new reuses an existing branch" 0 "$RC"
assert_eq "a reused branch keeps its own commits" "$(git -C "$MAIN" rev-parse feat/api)" "$(head_of "$MAIN/.worktrees/api")"
assert_contains "a reused branch says --from was ignored" "ignored --from main" "$OUT"

run_wt "$MAIN/.worktrees/web" new feat/deep/nested
assert_eq "new from inside a worktree succeeds" 0 "$RC"
assert_eq "new from a worktree lands under the main checkout" 0 "$([ -d "$MAIN/.worktrees/deep-nested" ]; echo $?)"
assert_eq "new from a worktree nests nothing" 1 "$([ -e "$MAIN/.worktrees/web/.worktrees" ]; echo $?)"

new_repo "WT_SETUP='echo up >> up-setup.log'
WT_NEW_SETUP='pwd > new-setup.log'"
run_wt "$MAIN" new feat/thing
assert_eq "new with WT_NEW_SETUP succeeds" 0 "$RC"
assert_eq "WT_NEW_SETUP runs in the new worktree" "$(cd "$MAIN/.worktrees/thing" && pwd -P)" "$(cat "$MAIN/.worktrees/thing/new-setup.log")"
assert_eq "new does not run WT_SETUP" 1 "$([ -e "$MAIN/.worktrees/thing/up-setup.log" ]; echo $?)"

new_repo "WT_NEW_SETUP='exit 3'"
run_wt "$MAIN" new feat/thing
assert_eq "a failed WT_NEW_SETUP fails new" 1 "$RC"
assert_contains "a failed WT_NEW_SETUP says the worktree exists" "worktree created at" "$OUT"
assert_eq "a failed WT_NEW_SETUP keeps the worktree" 0 "$([ -d "$MAIN/.worktrees/thing" ]; echo $?)"

printf '\n%s passed, %s failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
