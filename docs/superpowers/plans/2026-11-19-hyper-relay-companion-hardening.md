# hyper-relay: the companion stays up, locks its door, and lives in `.hyper-relay/`, Implementation Plan

**Card:** visual-companion: port upstream's server hardening and the 30-minute idle-out fix (`e3303d7a-d569-44a5-ad53-89917bb0fdb5`)
**Spec:** `docs/superpowers/specs/2026-11-19-hyper-relay-companion-hardening-design.md`

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Tasks 1–6 are
> the executor's. Task 7 is the acceptance task: its `reviewer` steps are the acceptance reviewer's; its `skill-test`,
> `owner` and `after merge` steps are the orchestrator's and the owner's. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** The visual companion stays up as long as the Claude Code session that started it, its tab says when it has
paused or needs the full link, every request needs a per-session key, it serves only plain files from its own folder,
and its sessions live in `.hyper-relay/companion/`, kept out of git through the repo's local exclude file.

**Architecture:** `server.cjs` gains the key (a 302 that sets a per-port cookie, a 403 otherwise), five security
headers, a strict file check and a request guard (Task 1), then a lifetime tied to its owner, with a 4-hour idle-out
only when the owner is unknown (Task 2). `helper.js` lays a notice over the last screen (Task 3). `start-server.sh` and
`stop-server.sh` prove a PID is their own server by a per-start instance id, run owner-only, and take
`--idle-timeout-minutes` and a relative `--project-dir` (Task 4). The session folder moves to
`.hyper-relay/companion/`, with the exclude line and the one-time move (Task 5). `SKILL.md` says all of it, and the full
gates run (Task 6). Task 7 accepts it: a live run, the owner's browser, five RED/GREEN skill tests, the 0.2.5 release.

**Tech Stack:** Node 18 or later (CommonJS; `http`, `crypto`, `vm`, global `fetch`), no npm dependency; bash
(`start-server.sh`, `stop-server.sh`); git 2.31 or later (`--path-format`); plain `node test-*.cjs` files run by
`run-tests.sh`. For acceptance: `curl`, a real browser, Claude Code general-purpose subagents on Sonnet.

**How this was checked:** written against `main` at `381f936`, by reading only (the spec, the companion's files, and
upstream's `v7.0.2` scripts and `auth.test.js` from this repo's tags); nothing was built, run, installed or generated.
The spec flags no fact for re-check, so none was re-checked. One detail of Node's `fetch` was confirmed on one page
(P10); the plan's assumptions are A1–A3.

---

## Execution notes (binding)

- **Tests make their own folders and repos.** Never run `start-server.sh` with `--project-dir` on this checkout or on
  any real project: it adds a line to that repo's `.git/info/exclude`. Every test works under `os.tmpdir()` and removes
  its folder at the end.
- **Leave the owner's companions alone.** Servers that the installed plugin (0.2.4) started may be running on this
  machine; their command lines carry no `--companion-id=`. Never signal a process the tests did not start.
- **The suites are the contract.** The existing cases of `test-session.cjs` and `test-injection.cjs` keep their
  assertions. Only these change in them: `test-injection.cjs` sends the key (Task 1); `test-session.cjs`'s `start`
  passes a git ceiling (Task 4) and its `sessionDir()` names the new folder (Task 5). Needing to change any other
  existing assertion is a stop.
- **The scripts stay bash** (`#!/usr/bin/env bash`), checked with `bash -n`. `server.cjs` and `helper.js` stay free of
  dependencies, and `helper.js` stays a polling IIFE (VC2: no WebSockets, no click capture).
- **git in the tests runs isolated.** Every test that runs `start-server.sh` with `--project-dir` gives it
  `GIT_CEILING_DIRECTORIES=<os.tmpdir()>`, so a temporary folder is never taken for part of a repo above it (the home
  folder here is a repo): `test-session.cjs`'s `start` and its own spawns (its assertions stay), `test-stop.cjs` and
  `test-folder.cjs`. `test-folder.cjs` also sets `HOME` and `XDG_CONFIG_HOME` to `<its root>/home` and
  `GIT_CONFIG_NOSYSTEM=1` for `git` and `start-server.sh`, so the owner's global config, hooks and ignore file play
  no part.
- **Skill and doc text is written exactly** (Task 5 Step 5, Task 6 Step 1). "Replace X with Y" means the Edit tool, X as
  `old_string`, Y as `new_string`. A block's fence lines are not part of the text; fences inside a four-backtick block
  are. Do not reflow or reword. If an X is not found, read the range again; if it moved or differs slightly, adapt as
  little as possible and record a deviation; if it is gone, stop and report.
- **No release on the branch.** `package.json` and `.claude-plugin/plugin.json` stay at 0.2.4; Task 7 releases 0.2.5
  after the merge. Do not run `claude -p` or upstream's live suites.
- The spec's values, verbatim:
  - Headers on every response, 403 and 404 included: `Cache-Control: no-store`, `Referrer-Policy: no-referrer`,
    `X-Frame-Options: SAMEORIGIN`, `Content-Security-Policy: frame-ancestors 'self'`,
    `Cross-Origin-Resource-Policy: same-origin`.
  - "`GET /?key=<right key>` answers 302 to `/` with
    `Set-Cookie: companion-key-<port>=<key>; HttpOnly; SameSite=Strict; Path=/`"; "`server-info`'s `url` is
    `http://<url host>:<port>/?key=<key>`"; "the server makes 32 random bytes in hex".
  - "a wrong `?key=` fails even with a valid cookie"; "The comparison uses `crypto.timingSafeEqual`"; "The activity
    clock is touched only after the check passes."
  - The notices: "Paused — the agent will bring it back." and "Ask the agent for the full link."
  - "When the owner process is unknown, the server idles out after 4 hours by default." "it reaches node as
    `BRAINSTORM_IDLE_TIMEOUT_MS`". "The fallback to `$PPID` goes".
  - "passes it to node as the argument `--companion-id=<id>`"; "prints `{"status":"stale_pid"}` and signals nothing".
  - "appends `/.hyper-relay/companion/` to the repo's local exclude file … It never touches `.gitignore`."
- **The full gates** (Task 6 Step 3): `bash skills/visual-companion/scripts/run-tests.sh`, `bash -n` on
  `start-server.sh` and `stop-server.sh`, `sh tests/orchestrating/run-tests.sh` and `claude plugin validate .`. They
  are also `relay-merge`'s gates for this branch (`.hyper-relay/merge.conf`: `skills/` and `CLAUDE.md`).
- **Task 7 is not yours.** After Task 6, report, copy Task 7's checklist into your report, and stop.

## Review Focus

1. **A screen that frames a companion file** (`<iframe src="/files/inner.html">`, as 17 past screens do): the framed
   request carries only the cookie and must answer 200 with `X-Frame-Options: SAMEORIGIN`; a `?key=` on a `/files/`
   link must not become part of the file name. Task 1 Step 1 ("/poll and /files/ need the key", "the five headers…").
2. **The session's saved port taken at restart:** the server binds another; the link carries the new port and the same
   key, and `state/token` is unchanged. Task 1 Step 1 ("a restart keeps the key, whatever port it binds").
3. **A session moved from the old folder whose `server.log` and `server-info` were world-readable** (old scripts ran
   without `umask 077`): after the start, `server.log`, `server-info`, `token` and `server-instance-id` are owner-only.
   Task 5 Step 1 ("an old session is moved…").
4. **`--project-dir` below the repo's top, with an exclude file whose last line has no newline:** the line covers that
   folder, sits on its own line, and is added once over two starts. Task 5 Step 1 ("a project dir below the repo's
   top…").
5. **`--project-dir` in a linked worktree** (its `.git` is a file): the line lands once in the main repo's exclude file,
   and the worktree sees the folder ignored. Task 5 Step 1 ("a linked worktree…").

## Spec ambiguities and deviations (each decided here)

| # | The spec says | Decision |
|---|---|---|
| P1 | §1: `run-tests.sh` changes | It needs no change: its `test-*.cjs` glob runs the four new files. Task 7 Step 3's list leaves it out. |
| P2 | §2, §5: the start script's printed JSON carries `git_exclude` and `moved_from` "for that start only" | `server.cjs` adds them to the line it prints, from `BRAINSTORM_GIT_EXCLUDE` and `BRAINSTORM_MOVED_FROM`, which `start-server.sh` puts on node's `env` line (empty when they do not apply), and never to `server-info`. So foreground mode carries them too, and node escapes the path. The exclude check runs only when a server is about to start: a start that finds its server running prints `server-info` as it is. |
| P3 | §5: append `/.hyper-relay/companion/` | When `P` is below its work tree's top, the line is `/<prefix>.hyper-relay/companion/`, with `<prefix>` from `git rev-parse --show-prefix` (`/apps/web/.hyper-relay/companion/`); at the top it is the spec's line exactly. The anchored line would not cover a `P` below the top, and every start would append it again. A newline goes first when the file does not end with one. The line is appended only when `git check-ignore` exits 1 (not on 128, an error). **The owner may drop the prefix at stop 3.** |
| P4 | §2: when the proof fails, `stop-server.sh` "removes the stale PID file" | When the PID is dead, `server-info` goes too: it describes a server that no longer exists, and today's stop removes it. When the PID is alive but unproven, only `server.pid` goes: an old script's server still serves what its `server-info` says. A PID file that is not a number is stale. A proven stop also removes `server-instance-id`, beside today's files. |
| P5 | §2: the start's "already running" check uses the proof | Running: `server.pid` holds a number, that process is alive, `server-info` exists, and either the process carries the id in `server-instance-id`, or there is no `server-instance-id` (an old script's server). Otherwise the start removes `server.pid`, `server-info`, `server-stopped` and `server.log` before starting. The log goes too, so that one moved from the old folder with mode 0644 is made again, owner-only (§3; Review Focus 3). |
| P6 | §2: "a random instance id" | 24 random bytes as 48 lowercase hex digits (`od -An -N24 -tx1 /dev/urandom`); well formed means exactly `^[0-9a-f]{48}$`. Without a well-formed id the start fails: `{"error": "Cannot make an instance id"}`. |
| P7 | §2: "after about 5 consecutive failed polls" | Exactly 5, and a good poll resets the count. A 403 shows its notice at once. The notice is one element, `#companion-notice`: a fixed bar across the top, styled as Task 3 pins. |
| P8 | §3: "a small page"; §4: "an unexpected error answers 500" | The 403 page is pinned in Task 1 (title `Visual companion`, one heading). The 500 answer is `Server error`, `text/plain`, with the five headers. |
| P9 | §3: the key "in `state/token`"; "`BRAINSTORM_TOKEN` … overrides it" | `state/token` is reused when it holds exactly 64 lowercase hex digits (trimmed); anything else is replaced by a new key. `BRAINSTORM_TOKEN` is used as given and never written to `state/token`. |
| P10 | §7: "using global `fetch`" | Yes, with `redirect: 'manual'` to see the 302 and a `cookie` request header. Node's `fetch` is undici's, whose README (https://github.com/nodejs/undici/blob/main/README.md, read 2026-11-19) says: "Undici returns the actual response instead of an `opaqueredirect` filtered one when invoked with a `manual` redirect", and of forbidden header names, "In Undici, these constraints are removed". |
| P11 | §7: "an environment value for the interval is the builder's call" | `BRAINSTORM_LIFECYCLE_CHECK_MS` (upstream's name): a positive number of milliseconds, default 60000. |
| P12 | §8: on `moved_from`, "say in one line that the session's screens moved" | The paragraph also says to give the full link: §5 gives the moved session its first key, so the link the human partner has (no key) no longer opens it. |
| P13 | §8: "Every `.superpowers/brainstorm/` becomes `.hyper-relay/companion/`" | The move's paragraph says "another folder", so `SKILL.md` names `.superpowers/` nowhere. |
| P14 | §1: "every other skill stays as it is" | `skills/brainstorming/SKILL.md:453` ("A project's `.superpowers/brainstorm/` may hold screens written …") stays: §5 leaves the sessions never started again there, so it stays true. |
| P15 | §8: "Paused": "restart … The tab comes back by itself"; §9 S3: "the link is unchanged" | The bullet adds "(unless the returned JSON's `url` carries a new port: then give the user that link)", §2's taken port. |
| P16 | §7 names no test for foreground mode, the owner-only files, `--idle-timeout-minutes`, the 500 answer, the owner being the grandparent, or a dead PID at stop | Each gets one, under "Each change has a test": Tasks 1, 2 and 4. |
| P17 | §2: `--idle-timeout-minutes <positive integer>` | Valid means `^[1-9][0-9]*$` (no leading zero, which bash arithmetic reads as octal). Anything else: `{"error": "--idle-timeout-minutes must be a positive integer"}`, exit 1, before any folder is made. |
| P18 | §10 and `.hyper-relay/agents.md` (Releases): the release steps come "last" | The role agents' check (Step 13) runs before the release, with `main`'s own generator: `--check` compares bodies, not the version marker (`bin/hyper-relay-agents`, `classify`), so it holds after the release too. |
| P19 | §9: the situations | The project `/home/user/shop`, its sessions, ports and keys are made up. |
| A1 | **Assumption** | The checks that read `/proc/<pid>/cmdline` and `/proc/<pid>/environ` run on Linux (this machine is WSL2); without `/proc` each reports `ok  <name> (skipped: no /proc)`. The `ps -o args=` path is not exercised. |
| A2 | **Assumption** | `od` and `/dev/urandom` exist wherever the scripts run (Linux, macOS); there is no fallback (P6). |
| A3 | **Assumption** | A `<prefix>` (P3) holding `*`, `?`, `[` or `\` is written as is, unescaped: a project folder with those characters below the repo's top is not supported. |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1–6; 7 |
| Decisions (owner, 2026-11-19) | VC1: 6 (the launch lines unchanged), 7 (Step 3). VC2: 3 (polling stays). VC3: 2, 3, 4, 6; 7 (S1, S3). VC4: 2, 4. VC5: 2, 3, 4. VC6: 1, 4, 5. VC7: 5. VC8: 7 (Steps 5–9) |
| How it works | 1 (the bugs found by reading), 4 (the owner is the grandparent; the `$PPID` fallback goes), 5 (git's exclude file from a worktree) |
| 1. What changes where | 1–6; 7 (Step 3; P1) |
| 2. Staying up and recovering | 2 (lifetime, the fallback, `server-info`), 3 (the tab), 4 (restart, stopping, foreground, `--idle-timeout-minutes`) |
| 3. The key | 1; 4 (`umask 077`, owner-only files) |
| 4. Headers and file serving | 1 |
| 5. The folder, git and the move | 5 |
| 6. The two bugs | 1 (`$&`), 4 (`--project-dir`) |
| 7. Tests | 1–5 |
| 8. `skills/visual-companion/SKILL.md` | 6 |
| 9. Pressure scenarios | 7 (Steps 5–9) |
| 10. Acceptance and release | 6 (the gates); 7 |
| 11. Order | Execution notes (`main` is at 0.2.4: the research-before-plan release is out) |
| 12. Out of scope | No task; 7 (Step 3) |

## File structure

- **Modify:** `skills/visual-companion/scripts/server.cjs` (Tasks 1, 2, 5), `helper.js` (3), `start-server.sh` (4, 5),
  `stop-server.sh` (4, 5), `test-injection.cjs` (1), `test-session.cjs` (4, 5), `skills/visual-companion/SKILL.md`
  (6), `CLAUDE.md` (5).
- **Create** (mode 100755, as their siblings): `skills/visual-companion/scripts/test-server.cjs` (Tasks 1, 2),
  `test-helper.cjs` (3), `test-stop.cjs` (4), `test-folder.cjs` (5).
- **Unchanged:** `run-tests.sh` (P1), `frame-template.html`, every other skill, `templates/`, `bin/`, `hooks/`,
  `.claude-plugin/`, `package.json`, every suite under `tests/`.

---

### Task 1: The key, the headers and safe file serving (spec §3, §4, §6 first bullet; P8–P10)

**Files:**
- Modify: `skills/visual-companion/scripts/server.cjs` (constants, `wrapInFrame`, `getNewestScreen`, `handleRequest`,
  the `listening` handler, `http.createServer`)
- Create: `skills/visual-companion/scripts/test-server.cjs`
- Modify: `skills/visual-companion/scripts/test-injection.cjs:30-46`

**Interfaces:**
- Produces: the key, `BRAINSTORM_TOKEN` when set (never written), else `state/token` (64 lowercase hex digits, mode
  0600); the cookie `companion-key-<bound port>=<key>`; `server-info`'s `url`, `http://<url host>:<port>/?key=<key>`;
  `test-server.cjs`'s fixtures `newSession`, `freePort`, `serve`, `get` and `exited`, which Task 2 uses.

- [x] **Step 1: Write the failing tests** in `test-server.cjs`.

The harness is `test-session.cjs`'s (`check`, `assert`, the failures list, `ok  <name>` and `FAIL <name>: <message>`
lines, exit 1 on any failure), in an async main whose `check` awaits its body. `root` is this file's temporary folder,
removed at the end. The fixtures:

- `newSession() -> dir`: a new folder under `root`, with `content/` and `state/`.
- `freePort() -> Promise<number>`: a port nothing listens on (listen on port 0 at 127.0.0.1, read it, close).
- `serve(dir, env) -> Promise<{ proc, dir, info }>`: spawns `node <this folder>/server.cjs` with `process.env`,
  `BRAINSTORM_DIR=dir`, `BRAINSTORM_PORT` (`await freePort()` unless `env` gives one) and `BRAINSTORM_OWNER_PID=''`,
  then `env` over them; resolves with `info`, the first stdout line whose `type` is `server-started`, parsed (5 s
  limit). Every server it starts is SIGKILLed at the end. A line it parses (after this task):
  `{"type":"server-started","port":52341,"host":"127.0.0.1","url_host":"localhost","url":"http://localhost:52341/?key=abab…ab","screen_dir":"<dir>/content","state_dir":"<dir>/state"}`
- `get(s, path, { cookie } = {}) -> Promise<{ status, headers, body }>`:
  `fetch('http://127.0.0.1:' + s.info.port + path, { redirect: 'manual', headers: cookie ? { cookie } : {} })`, with
  `headers` the response's `Headers` (P10).
- `exited(proc, ms) -> Promise<boolean>`: true when `proc` has exited already or exits within `ms`.

The shared server and its folder, made in this order:

```js
const K = 'ab'.repeat(32);
const S = newSession(), c = path.join(S, 'content'), out = path.join(root, 'outside');
fs.mkdirSync(out);
fs.writeFileSync(path.join(out, 'secret.txt'), 'outside secret');
fs.writeFileSync(path.join(out, 'secret2.txt'), 'outside secret');
fs.writeFileSync(path.join(c, 'inner.html'), '<p>framed</p>');
fs.writeFileSync(path.join(c, 'screen.html'), '<h2>Secret screen</h2>');
fs.writeFileSync(path.join(c, 'asset.txt'), 'secret asset');
fs.symlinkSync(path.join(out, 'secret.txt'), path.join(c, 'link.txt'));
fs.linkSync(path.join(out, 'secret2.txt'), path.join(c, 'hard.txt'));
fs.writeFileSync(path.join(c, '.hidden.html'), '<h2>hidden</h2>');
fs.mkdirSync(path.join(c, 'dir.html'));
fs.symlinkSync(path.join(out, 'nope'), path.join(c, 'dangling.html'));
// mtimes: inner.html now - 60 s; screen.html now; .hidden.html and dir.html now + 60 s (utimesSync);
// dangling.html now + 60 s (lutimesSync). Below, dollar.html is written at now + 120 s, locked.html at now + 180 s.
const s = await serve(S, { BRAINSTORM_TOKEN: K });
const C = `companion-key-${s.info.port}=${K}`;
```

The checks, in this order:

```js
await check('no key: 403, with the page that asks for the full link', async () => {
  const r = await get(s, '/');
  assert(r.status === 403, 'status ' + r.status);
  assert(r.body.includes('Ask the agent for the full link.'), r.body);
});
await check('a wrong key: 403', async () => {
  assert((await get(s, '/?key=' + 'cd'.repeat(32))).status === 403);
});
await check('a wrong ?key= fails beside a valid cookie', async () => {
  assert((await get(s, '/?key=wrong', { cookie: C })).status === 403);
});
await check('the right ?key= answers 302 to / and sets the cookie', async () => {
  const r = await get(s, '/?key=' + K);
  assert(r.status === 302, 'status ' + r.status);
  assert(r.headers.get('location') === '/', 'location ' + r.headers.get('location'));
  assert(r.headers.get('set-cookie') === `${C}; HttpOnly; SameSite=Strict; Path=/`, r.headers.get('set-cookie'));
});
await check('the cookie alone loads the newest screen, with the poll script', async () => {
  const r = await get(s, '/', { cookie: C });
  assert(r.status === 200 && r.body.includes('<h2>Secret screen</h2>') && r.body.includes('const POLL_MS'));
});
await check('/poll and /files/ need the key', async () => {
  assert((await get(s, '/poll')).status === 403);
  assert((await get(s, '/files/asset.txt')).status === 403);
  const p = await get(s, '/poll', { cookie: C });
  assert(p.status === 200 && JSON.parse(p.body).file === 'screen.html', p.body);
  const f = await get(s, '/files/asset.txt', { cookie: C });
  assert(f.status === 200 && f.body === 'secret asset');
  const q = await get(s, '/files/asset.txt?key=' + K);           // the query is not part of the name
  assert(q.status === 200 && q.body === 'secret asset', 'status ' + q.status);
});
await check('the not-found answer needs the key', async () => {
  assert((await get(s, '/nope')).status === 403);
  assert((await get(s, '/nope', { cookie: C })).status === 404);
});
await check('the five headers on 200, 302, 403 and 404, and on a framed file', async () => {
  const H = {
    'cache-control': 'no-store', 'referrer-policy': 'no-referrer', 'x-frame-options': 'SAMEORIGIN',
    'content-security-policy': "frame-ancestors 'self'", 'cross-origin-resource-policy': 'same-origin',
  };
  for (const [p, cookie, status] of [['/', C, 200], ['/?key=' + K, undefined, 302], ['/', undefined, 403],
                                     ['/nope', C, 404], ['/files/inner.html', C, 200]]) {
    const r = await get(s, p, { cookie });
    assert(r.status === status, `${p}: status ${r.status}`);
    for (const [h, v] of Object.entries(H)) assert(r.headers.get(h) === v, `${p}: ${h} ${r.headers.get(h)}`);
  }
});
await check('a dotfile is not served, and is never the newest screen', async () => {
  assert((await get(s, '/files/.hidden.html', { cookie: C })).status === 404);
  assert(JSON.parse((await get(s, '/poll', { cookie: C })).body).file === 'screen.html');
});
await check('/files/ with an empty name is 404, and the server still answers', async () => {
  assert((await get(s, '/files/', { cookie: C })).status === 404);
  assert((await get(s, '/files/..', { cookie: C })).status === 404);
  assert((await get(s, '/poll', { cookie: C })).status === 200);
});
await check('a symlink and a hard link pointing outside are not served', async () => {
  for (const n of ['link.txt', 'hard.txt']) {
    const r = await get(s, '/files/' + n, { cookie: C });
    assert(r.status === 404 && !r.body.includes('outside secret'), n + ': status ' + r.status);
  }
});
await check('a directory and a dangling link named x.html are skipped', async () => {
  for (const n of ['dir.html', 'dangling.html']) {
    assert((await get(s, '/files/' + n, { cookie: C })).status === 404, n);
  }
  assert((await get(s, '/', { cookie: C })).body.includes('<h2>Secret screen</h2>'));
});
await check("$&, $` and $' in a fragment come out as written", async () => {
  const frag = "<p>A $& B $` C $' D</p>";
  fs.writeFileSync(path.join(c, 'dollar.html'), frag);           // mtime now + 120 s: the newest
  assert((await get(s, '/', { cookie: C })).body.includes(frag));
});
await check('an unreadable screen answers 500, and the server keeps answering', async () => {
  // reports "ok  <name> (skipped: root)" when process.getuid() === 0
  fs.writeFileSync(path.join(c, 'locked.html'), '<p>x</p>');      // then chmod 0, mtime now + 180 s
  const r = await get(s, '/', { cookie: C });
  assert(r.status === 500 && r.headers.get('x-frame-options') === 'SAMEORIGIN', 'status ' + r.status);
  assert((await get(s, '/poll', { cookie: C })).status === 200);
});
```

Then the key's own checks, each on a fresh session:

```js
await check('a first start makes a 64-hex key in state/token, owner-only, and the link carries it', async () => {
  const d = newSession(), t = await serve(d, {});
  const key = fs.readFileSync(path.join(d, 'state', 'token'), 'utf8').trim();
  assert(/^[0-9a-f]{64}$/.test(key), 'key ' + key);
  assert(t.info.url === `http://localhost:${t.info.port}/?key=${key}`, t.info.url);
  for (const f of ['token', 'server-info']) {
    assert((fs.statSync(path.join(d, 'state', f)).mode & 0o077) === 0, f + ' is readable by others');
  }
});
await check('a restart keeps the key, whatever port it binds', async () => {
  // the session above: SIGTERM its server and await its exit; hold its port with a net server on
  // 127.0.0.1; then t2 = await serve(d, { BRAINSTORM_PORT: String(port) })
  assert(t2.info.port !== port, 'bound the taken port');
  assert(t2.info.url === `http://localhost:${t2.info.port}/?key=${key}`, t2.info.url);
  assert(fs.readFileSync(path.join(d, 'state', 'token'), 'utf8').trim() === key, 'state/token changed');
});
await check('BRAINSTORM_TOKEN wins, and is not written', async () => {
  const d = newSession(), t = await serve(d, { BRAINSTORM_TOKEN: K });
  assert(t.info.url.endsWith('/?key=' + K) && !fs.existsSync(path.join(d, 'state', 'token')));
});
await check('a malformed state/token is replaced', async () => {
  const d = newSession();
  fs.writeFileSync(path.join(d, 'state', 'token'), 'not-a-key\n');
  const t = await serve(d, {});
  const key = fs.readFileSync(path.join(d, 'state', 'token'), 'utf8').trim();
  assert(/^[0-9a-f]{64}$/.test(key) && t.info.url.endsWith('/?key=' + key), key);
});
```

- [x] **Step 2: The injection test sends the key.** In `test-injection.cjs`, add `const TOKEN = 'ab'.repeat(32);` beside
  `PORT`, put `BRAINSTORM_TOKEN: TOKEN` in the server's `env`, and make the fetch
  `fetch(`http://127.0.0.1:${PORT}/`, { headers: { cookie: `companion-key-${PORT}=${TOKEN}` } })`. Nothing else in it
  changes.

- [x] **Step 3: Run them to verify they fail**

Run: `node skills/visual-companion/scripts/test-server.cjs`
Expected: `FAIL` lines, exit 1 (today's server answers `/` without a key, and crashes on the dangling link, so the
later checks fail on a fetch error). `node skills/visual-companion/scripts/test-injection.cjs` still prints `ok`
(today's server ignores the cookie).

- [x] **Step 4: Implement it in `server.cjs`**

- `FORBIDDEN_PAGE`, exactly:

  ```html
  <!DOCTYPE html>
  <html>
  <head><meta charset="utf-8"><title>Visual companion</title>
  <style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
  h1 { color: #333; font-size: 1.4rem; }</style>
  </head>
  <body><h1>Ask the agent for the full link.</h1></body></html>
  ```

- `securityHeaders(extra = {}) -> object`: the five headers of the Execution notes, then `extra`. Every `writeHead`
  uses it.
- The key, read once in `startServer()` after the folders exist (P9): `BRAINSTORM_TOKEN` when set; else `state/token`
  when it holds 64 lowercase hex digits; else `crypto.randomBytes(32).toString('hex')`, written to `state/token` with
  mode `0o600` (then `chmodSync(…, 0o600)`, for a file that existed).
- `isAuthorized(req) -> boolean`: split `req.url` at its first `?`. When the query has `key` (`URLSearchParams.has`),
  it alone decides; otherwise the `companion-key-<bound port>` cookie decides. Both compare with
  `crypto.timingSafeEqual` on equal-length buffers (unequal lengths: false). The bound port is the one the `listening`
  handler saw.
- `handleRequest`: route on the path without its query. Not authorized: 403 `FORBIDDEN_PAGE`
  (`text/html; charset=utf-8`). Then `touchActivity()` (it moves here from the top; Task 2 tests it). A `GET /` whose
  query has `key`: 302, `Location: /`, `Set-Cookie: companion-key-<port>=<key>; HttpOnly; SameSite=Strict; Path=/`,
  empty body. Otherwise the routes as today; `/files/<name>` takes `path.basename` of the path after `/files/`.
- `servableFile(name) -> string | null`: the file's path in `CONTENT_DIR` only when the name is not empty and does not
  start with `.`, `lstat` says a regular file (not a symlink) with `nlink === 1`, and its `realpath` starts with
  `realpath(CONTENT_DIR) + path.sep`; any error is `null`. `/files/` and `getNewestScreen` both use it, so a dotfile,
  a link, a directory or a dangling link is never served or picked.
- `wrapInFrame`: `frameTemplate.replace('<!-- CONTENT -->', () => content)`.
- `http.createServer` gets a wrapper: an exception from `handleRequest` answers 500 `Server error` (`text/plain`, the
  five headers) when no header has been sent, ends the response, and logs `{"type":"request-error","error":<message>}`
  to stderr; the server keeps running.
- The `listening` handler: `url` becomes `http://<URL_HOST>:<port>/?key=<key>`, and `server-info` is written with mode
  `0o600`.

- [x] **Step 5: Run the tests to verify they pass**

Run: `node skills/visual-companion/scripts/test-server.cjs`, then `bash skills/visual-companion/scripts/run-tests.sh`
Expected: every line `ok`, exit 0, from each.

- [x] **Step 6: Commit**

```bash
git add skills/visual-companion/scripts/server.cjs skills/visual-companion/scripts/test-server.cjs skills/visual-companion/scripts/test-injection.cjs
git commit -m "feat(visual-companion): a per-session key, safe headers and file serving" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#1"
```

### Task 2: No idle-out while the session that started it runs (spec §2 Lifetime, The fallback, `server-info`; P11)

**Files:**
- Modify: `skills/visual-companion/scripts/server.cjs` (Activity Tracking, the watcher, the lifecycle check, the
  `listening` handler)
- Modify: `skills/visual-companion/scripts/test-server.cjs` (a lifetime section after the key's checks)

**Interfaces:**
- Consumes: Task 1's fixtures.
- Produces: `BRAINSTORM_IDLE_TIMEOUT_MS` and `BRAINSTORM_LIFECYCLE_CHECK_MS` (milliseconds, positive); `server-info`'s
  `owner_pid` (a number or `null`) and `idle_timeout_ms` (a number when `owner_pid` is `null`, else `null`).

- [x] **Step 1: Write the failing tests** in `test-server.cjs`'s new lifetime section, with Task 1's fixtures. `L` is
  `{ BRAINSTORM_IDLE_TIMEOUT_MS: '600', BRAINSTORM_LIFECYCLE_CHECK_MS: '50', BRAINSTORM_TOKEN: K }`; `stopped(t)` reads
  `<t.dir>/state/server-stopped` as JSON.

```js
await check('a live owner: no idle exit past the timeout', async () => {
  const t = await serve(newSession(), { BRAINSTORM_OWNER_PID: String(process.pid),
    BRAINSTORM_IDLE_TIMEOUT_MS: '200', BRAINSTORM_LIFECYCLE_CHECK_MS: '50' });
  assert(t.info.owner_pid === process.pid && t.info.idle_timeout_ms === null, JSON.stringify(t.info));
  assert(!(await exited(t.proc, 1000)), 'it idled out');
  assert(!fs.existsSync(path.join(t.dir, 'state', 'server-stopped')));
});
await check('no owner: an idle exit after the timeout', async () => {
  const t = await serve(newSession(), { BRAINSTORM_IDLE_TIMEOUT_MS: '300', BRAINSTORM_LIFECYCLE_CHECK_MS: '50' });
  assert(t.info.owner_pid === null && t.info.idle_timeout_ms === 300, JSON.stringify(t.info));
  assert(await exited(t.proc, 3000), 'still running');
  assert(stopped(t).reason === 'idle timeout');
});
await check('an owner already dead at startup: the 4-hour fallback', async () => {
  const t = await serve(newSession(), { BRAINSTORM_OWNER_PID: String(spawnSync('true').pid) });
  assert(t.info.owner_pid === null && t.info.idle_timeout_ms === 14400000, JSON.stringify(t.info));
});
await check('the owner exiting stops the server', async () => {
  const owner = spawn('sleep', ['30']);
  const t = await serve(newSession(), { BRAINSTORM_OWNER_PID: String(owner.pid), BRAINSTORM_LIFECYCLE_CHECK_MS: '50' });
  owner.kill();
  assert(await exited(t.proc, 2000), 'outlived its owner');
  assert(stopped(t).reason === 'owner process exited');
});
await check('requests with the key count as activity', async () => {
  const t = await serve(newSession(), L);
  // GET /poll with the cookie every 100 ms for 1500 ms
  assert(t.proc.exitCode === null && t.proc.signalCode === null, 'idled out while polled');
});
await check('a rejected request does not count as activity', async () => {
  const t = await serve(newSession(), L);
  // GET / with no key every 100 ms, until the server exits or 2500 ms pass
  assert(await exited(t.proc, 2500), 'rejected requests kept it alive');
  assert(stopped(t).reason === 'idle timeout');
});
```

- [x] **Step 2: Run them to verify they fail**

Run: `node skills/visual-companion/scripts/test-server.cjs`
Expected: `FAIL a live owner: no idle exit past the timeout: {…}` (no `owner_pid`), with the other lifetime checks
failing; Task 1's checks still `ok`; exit 1.

- [x] **Step 3: Implement it in `server.cjs`**

- `IDLE_TIMEOUT_MS`: `Number(process.env.BRAINSTORM_IDLE_TIMEOUT_MS)` when finite and above 0, else
  `4 * 60 * 60 * 1000`. `LIFECYCLE_CHECK_MS`: `BRAINSTORM_LIFECYCLE_CHECK_MS` the same way, else `60 * 1000`.
- The lifecycle check runs every `LIFECYCLE_CHECK_MS`. With an owner: `shutdown('owner process exited')` once it is
  gone, and never an idle exit. Without one: `shutdown('idle timeout')` after `IDLE_TIMEOUT_MS` with no activity.
- The startup owner check (dead at startup: `ownerPid = null`) stays before `listen`, so `server-info` tells the truth.
- `server-info` and the printed line gain `owner_pid: ownerPid` and
  `idle_timeout_ms: ownerPid ? null : IDLE_TIMEOUT_MS`.
- The watcher ignores names that start with `.`, as `servableFile` does; a new or changed screen still touches the
  activity clock. The "30 minutes" comments go.

- [x] **Step 4: Run the tests to verify they pass**

Run: `node skills/visual-companion/scripts/test-server.cjs`, then `bash skills/visual-companion/scripts/run-tests.sh`
Expected: every line `ok`, exit 0, from each.

- [x] **Step 5: Commit**

```bash
git add skills/visual-companion/scripts/server.cjs skills/visual-companion/scripts/test-server.cjs
git commit -m "feat(visual-companion): no idle-out while the session that started it runs" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#2"
```

### Task 3: The tab says when the companion has paused or needs the link (spec §2 The tab; P7)

**Files:**
- Modify: `skills/visual-companion/scripts/helper.js`
- Create: `skills/visual-companion/scripts/test-helper.cjs`

- [x] **Step 1: Write the failing tests** in `test-helper.cjs`, with `test-session.cjs`'s harness in an async main. One
  fixture:

- `loadHelper(responses) -> Promise<{ tick, notice, reloads }>`: runs `helper.js`'s source with
  `vm.runInNewContext` in a context holding `fetch`, `setInterval`, `document`, `window` and `console`, and awaits the
  poll that `helper.js` runs at load. `fetch` answers each call with the next of `responses`: `ok(file, mtime)` is
  `{ ok: true, status: 200, json: async () => ({ file, mtime }) }`, a number `n` is `{ ok: false, status: n }`, and
  `'down'` is a rejected promise. `setInterval` only records its function. `document` is a fake with
  `getElementById(id)`, `createElement(tag)` (a plain object with `id`, `textContent` and `style: { cssText: '' }`)
  and `body.appendChild(el)`. `window` is `{ location: { reload() { … } } }`, counting its calls. `tick()` calls the
  recorded function and awaits it; `notice()` is `#companion-notice`'s element, or `null`; `reloads()` is the count.

```js
const PAUSED = 'Paused — the agent will bring it back.';
const KEY = 'Ask the agent for the full link.';
await check('four failed polls show nothing; the fifth shows Paused', async () => {
  const h = await loadHelper([ok('a.html', 1), 'down', 'down', 'down', 'down', 'down']);
  for (let i = 0; i < 4; i++) await h.tick();
  assert(h.notice() === null, 'a notice after 4 failures');
  await h.tick();
  assert(h.notice() && h.notice().textContent === PAUSED, JSON.stringify(h.notice()));
});
await check('an error other than 403 counts as a failed poll', async () => {
  const h = await loadHelper([ok('a.html', 1), 500, 500, 500, 500, 500]);
  for (let i = 0; i < 5; i++) await h.tick();
  assert(h.notice() && h.notice().textContent === PAUSED);
});
await check('a 403 asks for the full link at once', async () => {
  const h = await loadHelper([ok('a.html', 1), 403]);
  await h.tick();
  assert(h.notice() && h.notice().textContent === KEY);
});
await check('the first good poll after a notice reloads', async () => {
  const h = await loadHelper([ok('a.html', 1), 'down', 'down', 'down', 'down', 'down', ok('a.html', 1)]);
  for (let i = 0; i < 6; i++) await h.tick();
  assert(h.reloads() === 1, 'reloads ' + h.reloads());
});
await check('a good poll resets the count', async () => {
  const h = await loadHelper([ok('a.html', 1), 'down', 'down', 'down', 'down', ok('a.html', 1),
    'down', 'down', 'down', 'down']);
  for (let i = 0; i < 9; i++) await h.tick();
  assert(h.notice() === null && h.reloads() === 0);
});
await check('a new screen reloads; the same one does not', async () => {
  const h = await loadHelper([ok('a.html', 1), ok('a.html', 1), ok('b.html', 2)]);
  await h.tick();
  assert(h.reloads() === 0);
  await h.tick();
  assert(h.reloads() === 1);
});
await check('the notice carries its own inline style', async () => {
  const h = await loadHelper([ok('a.html', 1), 403]);
  await h.tick();
  assert(h.notice().style.cssText.includes('position:fixed') && h.notice().style.cssText.includes('z-index:2147483647'));
});
```

- [x] **Step 2: Run them to verify they fail**

Run: `node skills/visual-companion/scripts/test-helper.cjs`
Expected: `FAIL four failed polls show nothing; the fifth shows Paused: null`, the two "new screen" and "resets" checks
`ok`, the rest `FAIL`; exit 1.

- [x] **Step 3: Implement it in `helper.js`**

It stays an IIFE: `async function poll()`, passed to `setInterval(poll, 1000)` and called once at load. A 403 shows
"Ask the agent for the full link." at once. A rejected fetch or another non-OK answer adds one failure, and the fifth
in a row shows "Paused — the agent will bring it back.". A good answer resets the count; it then reloads the page
(`window.location.reload()`) when a notice is showing, and otherwise compares `file@mtime` as today. The notice: when
`document.getElementById('companion-notice')` is `null`, `document.createElement('div')` with `id`
`companion-notice` and `style.cssText` exactly
`position:fixed;top:0;left:0;right:0;z-index:2147483647;margin:0;padding:12px 16px;background:#92400e;color:#fff;font:600 15px/1.4 system-ui,sans-serif;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.3)`,
appended with `document.body.appendChild`; then its `textContent` is set. The header comment says what the notices
are for.

- [x] **Step 4: Run the tests to verify they pass**

Run: `node skills/visual-companion/scripts/test-helper.cjs`, then `bash skills/visual-companion/scripts/run-tests.sh`
Expected: every line `ok`, exit 0, from each.

- [x] **Step 5: Commit**

```bash
git add skills/visual-companion/scripts/helper.js skills/visual-companion/scripts/test-helper.cjs
git commit -m "feat(visual-companion): the tab says when the companion has paused or needs the link" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#3"
```

### Task 4: The scripts stop only their own server, run owner-only, and take the idle limit (spec §2, §3, §6; P4–P6, P16, P17)

**Files:**
- Modify: `skills/visual-companion/scripts/start-server.sh` (the header comment, arguments, lines `:97-161`)
- Modify: `skills/visual-companion/scripts/stop-server.sh` (`:16-58`)
- Modify: `skills/visual-companion/scripts/test-session.cjs` (`start`'s env; new checks after check 5, before the
  invalid names)
- Create: `skills/visual-companion/scripts/test-stop.cjs`

**Interfaces:**
- Consumes: Task 2's `BRAINSTORM_IDLE_TIMEOUT_MS` and `server-info` fields.
- Produces: node runs as `node server.cjs --companion-id=<id>`, with `<id>` (48 lowercase hex digits) in
  `state/server-instance-id`; the running rule of P5, which Task 5's move reuses for the old folder; `stop-server.sh`'s
  answers `{"status": "stopped"}`, `{"status": "not_running"}` (today's) and `{"status":"stale_pid"}`.

- [ ] **Step 1: Write the failing tests**

In `test-session.cjs`, `start()` passes `env: { ...process.env, GIT_CEILING_DIRECTORIES: os.tmpdir() }` (Execution
notes), and these checks go after check 5 (`stop removes server-info`). `st(name)` is
`path.join(sessionDir(name), 'state')`; a check that reads `/proc` reports `ok  <name> (skipped: no /proc)` without it
(A1).

```js
check("the owner is the script's grandparent", () => {
  const r = start(['--session', 'owner-check']); started.push('owner-check');
  const info = JSON.parse(r.out);
  assert(info.owner_pid === process.ppid, `owner_pid ${info.owner_pid}, expected ${process.ppid}`);
  assert(info.idle_timeout_ms === null, 'idle_timeout_ms ' + info.idle_timeout_ms);
});
check('the state files are owner-only', () => {
  for (const f of ['token', 'server-info', 'server.log', 'server-instance-id']) {
    const mode = fs.statSync(path.join(st('owner-check'), f)).mode;
    assert((mode & 0o077) === 0, f + ' is ' + (mode & 0o777).toString(8));
  }
});
check("node runs with this start's instance id", () => {
  const id = fs.readFileSync(path.join(st('owner-check'), 'server-instance-id'), 'utf8').trim();
  assert(/^[0-9a-f]{48}$/.test(id), 'id ' + id);
  const pid = fs.readFileSync(path.join(st('owner-check'), 'server.pid'), 'utf8').trim();
  const args = fs.readFileSync(`/proc/${pid}/cmdline`, 'utf8').split('\0');
  assert(args.includes('--companion-id=' + id) && args.some((a) => a.endsWith('server.cjs')), args.join(' '));
});
check('server-stopped is cleared on start', () => {
  stop('owner-check');
  assert(fs.existsSync(path.join(st('owner-check'), 'server-stopped')), 'precondition: no server-stopped after a stop');
  assert(start(['--session', 'owner-check']).code === 0);
  assert(!fs.existsSync(path.join(st('owner-check'), 'server-stopped')), 'server-stopped survived the start');
});
check('a restart keeps the port and the key', () => {
  const before = JSON.parse(fs.readFileSync(path.join(st('owner-check'), 'server-info'), 'utf8')).url;
  stop('owner-check');
  const r = start(['--session', 'owner-check']);
  assert(JSON.parse(r.out).url === before, `${before} -> ${r.out}`);
});
check('--idle-timeout-minutes reaches node', () => {
  start(['--session', 'idle-flag', '--idle-timeout-minutes', '7']); started.push('idle-flag');
  const pid = fs.readFileSync(path.join(st('idle-flag'), 'server.pid'), 'utf8').trim();
  assert(fs.readFileSync(`/proc/${pid}/environ`, 'utf8').split('\0').includes('BRAINSTORM_IDLE_TIMEOUT_MS=420000'));
});
for (const bad of ['0', '-3', 'abc', '1.5', '08']) {
  check(`--idle-timeout-minutes refuses ${bad}`, () => {
    const r = start(['--session', 'idle-bad', '--idle-timeout-minutes', bad]);
    assert(r.code === 1 && r.out === '{"error": "--idle-timeout-minutes must be a positive integer"}', r.out);
  });
}
check('a relative --project-dir and one with a space both work', () => {
  // runs START itself: '.' with cwd path.join(root, 'rel') (made first), then path.join(root, 'with space')
  // with cwd root; each is stopped through path.dirname(info.state_dir)
  assert(r.status === 0, r.stdout);
  assert(info.state_dir.startsWith(top + path.sep) && fs.existsSync(info.screen_dir), info.state_dir);
});
```

`test-stop.cjs`, with the harness in an async main. Its fixtures:

- `fakeSession({ pid, id, info }) -> dir`: a new folder under `root` with `state/`, holding `state/server.pid` (`pid`),
  `state/server-instance-id` (`id`) and `state/server-info` (`info`), each only when given.
- `impostor(id) -> ChildProcess`: `spawn('bash', ['-c', 'sleep 30; :', 'impostor', '--companion-id=' + id],
  { detached: true, stdio: 'ignore' })`; its command line holds `--companion-id=<id>` as one argument. Every impostor
  and `sleep` it spawns is killed by process group at the end.
- `stop(dir) -> { code, out }`: `spawnSync('bash', [STOP, dir])`, stdout trimmed. `start(session) -> { code, out }`:
  `spawnSync('bash', [START, '--project-dir', root, '--session', session])`; it and the foreground spawn pass
  `GIT_CEILING_DIRECTORIES=<os.tmpdir()>` (Execution notes). `alive(pid)`: `process.kill(pid, 0)` succeeds (EPERM
  counts as alive). `exited` as in `test-server.cjs`.

```js
const ID_A = 'a1'.repeat(24), ID_B = 'b2'.repeat(24);
const OLD = '{"type":"server-started","port":1,"url":"http://localhost:1"}';
await check('no PID file: not_running', () => {
  assert(JSON.parse(stop(fakeSession({})).out).status === 'not_running');
});
await check('a reused PID that is not ours is not signalled', () => {
  const p = spawn('sleep', ['30'], { detached: true, stdio: 'ignore' });
  const d = fakeSession({ pid: p.pid, id: ID_A, info: OLD });
  assert(stop(d).out === '{"status":"stale_pid"}');
  assert(alive(p.pid), 'the process was signalled');
  assert(!fs.existsSync(path.join(d, 'state', 'server.pid')), 'the stale PID file stayed');
  assert(fs.existsSync(path.join(d, 'state', 'server-info')), 'a live PID keeps server-info (P4)');
});
for (const [what, fileId, carried] of [['no id', undefined, ID_A], ['a wrong id', ID_A, ID_B],
                                        ['a malformed id', 'not-an-id', 'not-an-id']]) {
  await check(`an impostor with ${what} is not signalled`, () => {
    const p = impostor(carried);
    assert(stop(fakeSession({ pid: p.pid, id: fileId })).out === '{"status":"stale_pid"}' && alive(p.pid));
  });
}
await check('a dead PID: stale_pid, and its server-info goes too', () => {
  const d = fakeSession({ pid: spawnSync('true').pid, id: ID_A, info: OLD });
  assert(stop(d).out === '{"status":"stale_pid"}');
  assert(!fs.existsSync(path.join(d, 'state', 'server.pid')) && !fs.existsSync(path.join(d, 'state', 'server-info')));
});
await check('a PID file that is not a number signals nothing', () => {
  assert(stop(fakeSession({ pid: 'abc', id: ID_A })).out === '{"status":"stale_pid"}');
});
await check('the real server is signalled', () => {
  const st = JSON.parse(start('real').out).state_dir;
  const pid = Number(fs.readFileSync(path.join(st, 'server.pid'), 'utf8'));
  assert(JSON.parse(stop(path.dirname(st)).out).status === 'stopped' && !alive(pid));
  assert(JSON.parse(fs.readFileSync(path.join(st, 'server-stopped'), 'utf8')).reason === 'stopped by signal');
  assert(!fs.existsSync(path.join(st, 'server.pid')) && !fs.existsSync(path.join(st, 'server-instance-id')));
});
await check('start-server does not take an impostor for its server', () => {
  // the 'real' session, stopped above: its state gets server.pid = p.pid, server-instance-id = ID_A, server-info = OLD
  const p = impostor(ID_B);
  const info = JSON.parse(start('real').out);
  assert(info.type === 'server-started' && info.url !== 'http://localhost:1', JSON.stringify(info));
  assert(fs.readFileSync(path.join(info.state_dir, 'server.pid'), 'utf8').trim() !== String(p.pid) && alive(p.pid));
  // then stop it
});
await check('a server an old script started counts as running, and is never signalled', () => {
  // the 'real' session, stopped: no server-instance-id; server.pid = a detached `sleep 30`; server-info = OLD
  assert(start('real').out === OLD);
  assert(fs.readFileSync(path.join(st, 'server.pid'), 'utf8').trim() === String(p.pid));
  assert(stop(d).out === '{"status":"stale_pid"}' && alive(p.pid));
});
await check("foreground mode records node's own PID", async () => {
  const child = spawn('bash', [START, '--project-dir', root, '--session', 'fg', '--foreground'],
    { stdio: ['ignore', 'pipe', 'ignore'] });
  // info: the first stdout line whose type is server-started (5 s limit)
  assert(fs.readFileSync(path.join(info.state_dir, 'server.pid'), 'utf8').trim() === String(child.pid));
  // with /proc: /proc/<child.pid>/cmdline holds '--companion-id=' + the id in server-instance-id
  assert(JSON.parse(stop(path.dirname(info.state_dir)).out).status === 'stopped');
  assert(await exited(child, 3000), 'node outlived the stop');
});
```

- [ ] **Step 2: Run them to verify they fail**

Run: `node skills/visual-companion/scripts/test-stop.cjs`, then `node skills/visual-companion/scripts/test-session.cjs`
Expected: from the first, `FAIL a reused PID that is not ours is not signalled` (today's stop signals it) among
others, exit 1; from the second, `FAIL the state files are owner-only` (`server.log` is 644, or `server-instance-id`
does not exist) and the `--idle-timeout-minutes` checks failing as unknown arguments, exit 1.

- [ ] **Step 3: Implement it in `start-server.sh`.** In this order:

1. `--idle-timeout-minutes <n>` joins the arguments. After parsing, a value not matching `^[1-9][0-9]*$` prints
   `{"error": "--idle-timeout-minutes must be a positive integer"}` and exits 1; a valid one exports
   `BRAINSTORM_IDLE_TIMEOUT_MS=$(( n * 60000 ))`. The header comment lists `--session <name>` and
   `--idle-timeout-minutes <n>` (default 4 hours, used only when the session that started it cannot be told).
2. `umask 077`, before anything is made.
3. `--project-dir` is made absolute and created before it is used:
   `PROJECT_DIR="$(mkdir -p -- "$PROJECT_DIR" && CDPATH='' cd -- "$PROJECT_DIR" && pwd)"`; on failure
   `{"error": "Cannot create or enter --project-dir"}`, exit 1.
4. Two functions, the same in both scripts: `pid_alive <pid>` (the PID is all digits and `kill -0` succeeds) and
   `carries_id <pid> <id>` (one argument of the process is exactly `--companion-id=<id>`: from
   `/proc/<pid>/cmdline` split on NUL when it is readable, else from `ps -o args= -p <pid>` split on spaces).
5. The running check replaces today's two blocks (`:111-129`): running is P5's rule, where the proof is `<id>` from
   `state/server-instance-id` matching `^[0-9a-f]{48}$` and `carries_id` true. Running: `cat` `server-info`, exit 0.
   Otherwise `rm -f` `server.pid`, `server-info`, `server-stopped` and `server.log`.
6. The instance id: `od -An -N24 -tx1 /dev/urandom | tr -d ' \n'`; not `^[0-9a-f]{48}$`:
   `{"error": "Cannot make an instance id"}`, exit 1; else written to `state/server-instance-id`.
7. The owner is the grandparent as today; empty or `1` leaves it empty. The `$PPID` fallback goes (its comment too).
8. Foreground: `echo "$$" > "$PID_FILE"`, then `exec env … node server.cjs "--companion-id=$ID"`. Background: as
   today, with `"--companion-id=$ID"` after `server.cjs`.

- [ ] **Step 4: Implement it in `stop-server.sh`**

With the PID file present: when `pid_alive` and `carries_id` (with a well-formed id from `state/server-instance-id`)
both hold, stop it as today, then `rm -f` `server.pid`, `server-instance-id`, `server.log` and `server-info`. Otherwise
signal nothing: `rm -f` `server.pid`, and `server-info` too when the PID is not alive (P4); print
`{"status":"stale_pid"}`, exit 0. Without the PID file, `{"status": "not_running"}` as today.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `node skills/visual-companion/scripts/test-stop.cjs`, `node skills/visual-companion/scripts/test-session.cjs`,
`bash -n skills/visual-companion/scripts/start-server.sh`, `bash -n skills/visual-companion/scripts/stop-server.sh`,
then `bash skills/visual-companion/scripts/run-tests.sh`
Expected: every line `ok` and exit 0 from the tests; `bash -n` silent.

- [ ] **Step 6: Commit**

```bash
git add skills/visual-companion/scripts/start-server.sh skills/visual-companion/scripts/stop-server.sh skills/visual-companion/scripts/test-session.cjs skills/visual-companion/scripts/test-stop.cjs
git commit -m "feat(visual-companion): stop only our own server, owner-only files, --idle-timeout-minutes" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#4"
```

### Task 5: Sessions live in `.hyper-relay/companion/`, git-excluded; old ones move (spec §5; P2, P3, P5)

**Files:**
- Modify: `skills/visual-companion/scripts/start-server.sh` (the session folder, the move, the exclude, node's `env`
  line, the header comment)
- Modify: `skills/visual-companion/scripts/server.cjs` (the line the `listening` handler prints)
- Modify: `skills/visual-companion/scripts/stop-server.sh:5-7` (the header comment)
- Modify: `skills/visual-companion/scripts/test-session.cjs:32-34` (`sessionDir`)
- Create: `skills/visual-companion/scripts/test-folder.cjs`
- Modify: `CLAUDE.md:50-51`

**Interfaces:**
- Consumes: Task 4's running rule (P5) and functions.
- Produces: `BRAINSTORM_GIT_EXCLUDE` and `BRAINSTORM_MOVED_FROM` (node's env; empty when they do not apply); the
  printed line's `git_exclude` (`"added"`) and `moved_from` (the old folder's absolute path).

- [ ] **Step 1: Write the failing tests**

In `test-session.cjs`, `sessionDir(name)` becomes `path.join(root, '.hyper-relay', 'companion', name)`.

`test-folder.cjs`, with the harness in an async main. `freePort` and `alive` as in Tasks 1 and 4. Its fixtures:

- `gitEnv`: `process.env` with `HOME` and `XDG_CONFIG_HOME` set to `<root>/home`, `GIT_CONFIG_NOSYSTEM=1` and
  `GIT_CEILING_DIRECTORIES=<os.tmpdir()>`; every `git` call and every `start` uses it.
- `repo(name) -> dir`: `git init -q <root>/<name>`.
- `start(projectDir, session, { cwd } = {}) -> { code, out, info }`: `spawnSync('bash', [START, '--project-dir',
  projectDir, '--session', session], { env: gitEnv, cwd })`, stdout trimmed, `info` its JSON (or `null`). Every
  session it starts is stopped at the end (through `path.dirname(info.state_dir)`).
- `stop(info)`: runs `STOP` on `path.dirname(info.state_dir)`.
- `exclude(dir) -> string`: the text of `<dir>/.git/info/exclude`. `ignored(dir) -> boolean`:
  `git -C <dir> check-ignore -q .hyper-relay/companion/` exits 0.
- `oldSession(projectDir, name, { port, pid, info }) -> dir`: makes
  `<projectDir>/.superpowers/brainstorm/<name>/` with `content/old-screen.html` (`<h2>old</h2>`), `state/port`
  (`port`), `state/server.log` (`old log`, mode 0644), and, when given, `state/server.pid` (`pid`) and
  `state/server-info` (`info`, mode 0644).

```js
const R = repo('shop');
const LINE = '/.hyper-relay/companion/';
const count = (text, line) => text.split('\n').filter((l) => l === line).length;
await check('a new session lives in .hyper-relay/companion/, and the exclude line is added once', () => {
  const r1 = start(R, 'first');
  assert(r1.code === 0, r1.out);
  assert(r1.info.state_dir === path.join(R, '.hyper-relay', 'companion', 'first', 'state'), r1.info.state_dir);
  assert(r1.info.git_exclude === 'added', r1.out);
  const saved = JSON.parse(fs.readFileSync(path.join(r1.info.state_dir, 'server-info'), 'utf8'));
  assert(!('git_exclude' in saved) && !('moved_from' in saved), 'server-info carries a start-only field');
  stop(r1.info);
  const r2 = start(R, 'first');
  assert(r2.code === 0 && !('git_exclude' in r2.info), r2.out);
  assert(count(exclude(R), LINE) === 1, exclude(R));
  assert(ignored(R) && !fs.existsSync(path.join(R, '.gitignore')));
});
await check('--project-dir . in a repo that already ignores the folder: nothing is added', () => {
  const R2 = repo('ignored');
  fs.writeFileSync(path.join(R2, '.gitignore'), '.hyper-relay/\n');
  const before = exclude(R2);
  const r = start('.', 'dot', { cwd: R2 });
  assert(r.code === 0 && r.info.state_dir === path.join(R2, '.hyper-relay', 'companion', 'dot', 'state'), r.out);
  assert(!('git_exclude' in r.info) && exclude(R2) === before);
  assert(fs.readFileSync(path.join(R2, '.gitignore'), 'utf8') === '.hyper-relay/\n');
});
await check('outside any repo: nothing is added and no git is made', () => {
  const P = path.join(root, 'plain');
  const r = start(P, 'plain');
  assert(r.code === 0 && !('git_exclude' in r.info) && !fs.existsSync(path.join(P, '.git')), r.out);
});
await check('an old session is moved, keeping its screens and its port; its state is then owner-only', async () => {
  const port = await freePort();
  const old = oldSession(R, 'legacy', { port, pid: spawnSync('true').pid, info: OLD_INFO(port) });
  // OLD_INFO(port): '{"type":"server-started","port":<port>,"url":"http://localhost:<port>"}'
  const r = start(R, 'legacy');
  const st = path.join(R, '.hyper-relay', 'companion', 'legacy', 'state');
  assert(r.code === 0 && r.info.moved_from === old && !fs.existsSync(old), r.out);
  assert(r.info.port === port, 'port ' + r.info.port);
  assert(r.info.url === `http://localhost:${port}/?key=` + fs.readFileSync(path.join(st, 'token'), 'utf8').trim());
  assert(fs.readFileSync(path.join(st, '..', 'content', 'old-screen.html'), 'utf8') === '<h2>old</h2>');
  for (const f of ['server.log', 'server-info', 'token', 'server-instance-id']) {
    assert((fs.statSync(path.join(st, f)).mode & 0o077) === 0, f + ' is readable by others');
  }
  assert(!('moved_from' in JSON.parse(fs.readFileSync(path.join(st, 'server-info'), 'utf8'))));
});
await check('an old session whose server is running is not moved', () => {
  const p = spawn('sleep', ['30'], { detached: true, stdio: 'ignore' });
  const info = '{"type":"server-started","port":1,"url":"http://localhost:1"}';
  const old = oldSession(R, 'busy', { port: 1, pid: p.pid, info });
  const r = start(R, 'busy');
  assert(r.code === 0 && r.out === info, r.out);
  assert(fs.existsSync(old) && !fs.existsSync(path.join(R, '.hyper-relay', 'companion', 'busy')));
});
await check("a project dir below the repo's top, with an exclude file lacking its last newline", () => {
  const R3 = repo('mono');
  fs.writeFileSync(path.join(R3, '.git', 'info', 'exclude'), '# local');
  const P = path.join(R3, 'apps', 'web');
  stop(start(P, 'sub').info);
  assert(start(P, 'sub').code === 0);
  assert(exclude(R3) === '# local\n/apps/web/.hyper-relay/companion/\n', JSON.stringify(exclude(R3)));
  assert(ignored(P));
});
await check("a linked worktree: the line goes once into the main repo's exclude file", () => {
  const R4 = repo('main-repo');
  // git -C R4 -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init
  // git -C R4 worktree add -q <root>/wt1
  const W = path.join(root, 'wt1');
  const r = start(W, 'wt');
  assert(r.code === 0 && r.info.git_exclude === 'added', r.out);
  assert(count(exclude(R4), LINE) === 1 && ignored(W));
  assert(fs.statSync(path.join(W, '.git')).isFile(), "the worktree's .git file was replaced");
});
```

- [ ] **Step 2: Run them to verify they fail**

Run: `node skills/visual-companion/scripts/test-folder.cjs`, then `node skills/visual-companion/scripts/test-session.cjs`
Expected: `FAIL a new session lives in .hyper-relay/companion/…` (the folder is still `.superpowers/brainstorm/`) and
the move and exclude checks failing, exit 1; `test-session.cjs` fails its first check (no folder at the new path),
exit 1.

- [ ] **Step 3: Implement it in `start-server.sh`, `server.cjs` and `stop-server.sh`**

1. With `--project-dir`, `SESSION_DIR` is `$PROJECT_DIR/.hyper-relay/companion/$SESSION_ID`, and `OLD_DIR` is
   `$PROJECT_DIR/.superpowers/brainstorm/$SESSION_ID`. Without it, `/tmp/brainstorm-$SESSION_ID` as today.
2. The move, before the session's folders are made: when `SESSION_DIR` does not exist and `OLD_DIR` is a folder. If
   `OLD_DIR/state/server.pid` passes `pid_alive` and `OLD_DIR/state/server-info` exists, `cat` that file and exit 0
   (an old script's server; nothing moves). Otherwise `mkdir -p` the parent of `SESSION_DIR` and `mv` `OLD_DIR` there
   (on failure `{"error": "Cannot move the old session folder"}`, exit 1), and `MOVED_FROM=$OLD_DIR`. The running
   check and its cleanup (Task 4) then run on the moved folder.
3. The exclude, with `--project-dir` only, after the running check and before node starts (P2, P3): when
   `git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree` prints `true` and
   `git -C "$PROJECT_DIR" check-ignore -q .hyper-relay/companion/` exits 1. The file is
   `git -C "$PROJECT_DIR" rev-parse --path-format=absolute --git-path info/exclude`, its folder made when missing.
   When the file is not empty and does not end with a newline, a newline goes first; then the line
   `/<git -C "$PROJECT_DIR" rev-parse --show-prefix>.hyper-relay/companion/`; then `GIT_EXCLUDE=added`.
   `.gitignore` is never read or written by the script.
4. Node's `env` line, in both modes, gains `BRAINSTORM_GIT_EXCLUDE="$GIT_EXCLUDE"` and
   `BRAINSTORM_MOVED_FROM="$MOVED_FROM"` (both empty by default).
5. `server.cjs`'s `listening` handler prints `info` plus `git_exclude` and `moved_from`, each only when its env value
   is not empty; `server-info` gets `info` alone.
6. The header comments: `start-server.sh`'s `--project-dir` stores sessions under
   `<path>/.hyper-relay/companion/<session>/`, moving an older one from `<path>/.superpowers/brainstorm/` the first
   time it is started again; `stop-server.sh`'s persistent folders are `.hyper-relay/companion/`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node skills/visual-companion/scripts/test-folder.cjs`, `node skills/visual-companion/scripts/test-session.cjs`,
`bash -n skills/visual-companion/scripts/start-server.sh`, then `bash skills/visual-companion/scripts/run-tests.sh`
Expected: every line `ok` and exit 0 from the tests; `bash -n` silent.

- [ ] **Step 5: `CLAUDE.md`'s rule (spec §5).** In `CLAUDE.md`, replace:

```text
- **`docs/superpowers/` and `.superpowers/` keep their names.** Quartz accepts specs and plans only under
  `docs/superpowers/`, and visual-companion keeps its screens in `.superpowers/`.
```

with:

```text
- **`docs/superpowers/` keeps its name,** because Quartz accepts specs and plans only under it. The visual companion
  keeps its sessions in `.hyper-relay/companion/`, git-ignored, and older sessions may still sit in
  `.superpowers/brainstorm/`.
```

- [ ] **Step 6: Commit**

```bash
git add skills/visual-companion/scripts/start-server.sh skills/visual-companion/scripts/server.cjs skills/visual-companion/scripts/stop-server.sh skills/visual-companion/scripts/test-session.cjs skills/visual-companion/scripts/test-folder.cjs CLAUDE.md
git commit -m "feat(visual-companion): sessions live in .hyper-relay/companion/, git-excluded; old ones move" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#5"
```

### Task 6: `SKILL.md` says it, and the full gates (spec §8; P12, P13, P15)

**Files:**
- Modify: `skills/visual-companion/SKILL.md:74-75`, `:86-97`, `:105-111`, `:116-122`, `:145-151`, `:163`, `:183`,
  `:307-308`

- [ ] **Step 1: The text.** In `skills/visual-companion/SKILL.md`, replace each X with its Y.

1. X:

```text
session's screens live in, so it is how the user finds them again later — `ls
<project>/.superpowers/brainstorm/` should read as a table of contents, not a list of
```

Y:

```text
session's screens live in, so it is how the user finds them again later — `ls
<project>/.hyper-relay/companion/` should read as a table of contents, not a list of
```

2. X:

````text
# Named session — the directory and port are stable across restarts
${CLAUDE_SKILL_DIR}/scripts/start-server.sh \
  --project-dir /path/to/project --session certificate-1c-redesign

# Returns: {"type":"server-started","port":52341,"host":"127.0.0.1",
#           "url_host":"localhost","url":"http://localhost:52341",
#           "screen_dir":".../content","state_dir":".../state"}
```

Save `screen_dir` and `state_dir` from the response. **Tell the user the URL once** — with a
named session the port is remembered, so it does not change between restarts and does not need
repeating every turn.
````

Y:

````text
# Named session — the directory, the port and the key are stable across restarts
${CLAUDE_SKILL_DIR}/scripts/start-server.sh \
  --project-dir /path/to/project --session certificate-1c-redesign

# Returns: {"type":"server-started","port":52341,"host":"127.0.0.1",
#           "url_host":"localhost","url":"http://localhost:52341/?key=3f9c…0d",
#           "screen_dir":".../content","state_dir":".../state",
#           "owner_pid":48213,"idle_timeout_ms":null}
```

Save `screen_dir` and `state_dir` from the response. **Give the user the full link once:** the
`url`, key included, exactly as printed. The companion answers nothing without its key: a link
without it shows only "Ask the agent for the full link." A named session keeps its port and its
key, so the link keeps working across restarts and does not need repeating every turn.
````

3. X:

```text
- reuses the port, so the user's open tab stays valid;
- returns the running server's info instead of starting a second one, if it is still alive.

So if the server has idled out (30 minutes), just start it again with the same name. Nothing is
lost and there is usually no new URL to announce — only if something else took the port in the
meantime, in which case the returned JSON carries the new one.
```

Y:

```text
- reuses the port and the key, so the user's open tab carries on by itself;
- returns the running server's info instead of starting a second one, if it is still alive.

**How long it runs.** The companion stays up while the Claude Code session that started it runs,
open tab or not, and stops when that session ends. When it cannot tell which session started it
(`owner_pid` is `null` in its JSON), it stops instead after 4 hours with no visit from the tab
and no new screen; `--idle-timeout-minutes <n>` sets that limit. If it has stopped, start it
again with the same name. Nothing is lost and there is usually no new link to announce — only if
something else took the port in the meantime, in which case the returned JSON's `url` carries a
new port: give the user that link.
```

4. X:

```text
**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`.
If you launched it in the background and didn't capture stdout, read that file for the URL
and port. With `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session dir.

**Note:** Pass the project root as `--project-dir` so mockups persist in
`.superpowers/brainstorm/` and survive server restarts. Without it, files go to `/tmp`
and get cleaned up. Remind the user to add `.superpowers/` to `.gitignore` if needed.
```

Y:

```text
**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`.
If you launched it in the background and didn't capture stdout, read that file for the full
link and the port. With `--project-dir`, check `<project>/.hyper-relay/companion/` for the
session dir.

**Note:** Pass the project root as `--project-dir` so mockups persist in
`.hyper-relay/companion/<session>/` and survive server restarts. Without it, files go to `/tmp`
and get cleaned up.

**Git.** In a git repo the script keeps `.hyper-relay/companion/` out of git: when the folder is
not ignored yet, it adds it to the repo's local exclude file (`.git/info/exclude`, shared by
every worktree), and its JSON carries `"git_exclude": "added"`. Then tell the user in one line
that the companion's folder is now ignored through the repo's local exclude file. Never edit
`.gitignore` for the companion.

**A session from before the move.** Sessions used to live in another folder. Starting such a
session again moves it into `.hyper-relay/companion/` first, with its screens and its port, and
the JSON carries `"moved_from": "<old path>"`. Say in one line that the session's screens moved
to the new folder, and give the user the full link: the old link had no key, so it is new.
```

5. X:

```text
1. **Check the server is alive**, then **write HTML** to a new file in `screen_dir`:
   - If the server has stopped (`$STATE_DIR/server-stopped` exists, or `server-info` is
     gone), restart it with the **same `--session` name**. Restarting costs nothing: same
     directory, same screens, same URL. It exits for **two** reasons, and `server-stopped`
     records which: `"idle timeout"` after 30 minutes of no requests, or
     `"owner process exited"` — it is tied to the lifetime of the session that launched it,
     so it does not outlive your Claude Code session.
```

Y:

```text
1. **Check the server is running**, then **write HTML** to a new file in `screen_dir`:
   - It is running when `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does
     not. Then just write the screen: no restart, and no new link to announce.
   - Otherwise restart it with the **same `--session` name**. Restarting costs nothing: same
     directory, same screens, same link. `server-stopped` records why it stopped:
     `"owner process exited"` when the Claude Code session that started it ended,
     `"idle timeout"` when it could not tell which session that was, or `"stopped by signal"`.
```

6. X:

```text
   - The URL is stable for the whole session — state it once when you start, not every step.
```

Y:

```text
   - The link is stable for the whole session — give it once when you start, not every step.
```

7. X:

```text
6. Repeat until done.

## Writing Content Fragments
```

Y:

```text
6. Repeat until done.

**When the user reports a notice in the tab.** The tab keeps the last screen and lays a notice
over it when it cannot get a new one:

- **"Paused — the agent will bring it back."** The server has stopped. Restart it with the same
  session name and tell the user it is back: the tab reloads by itself, and the link is
  unchanged (unless the returned JSON's `url` carries a new port: then give the user that link).
- **"Ask the agent for the full link."** The tab does not have the key, usually because the
  link was opened without it. Give the user the full link again: the `url` in
  `$STATE_DIR/server-info`. Do not restart.

## Writing Content Fragments
```

8. X:

```text
If the session used `--project-dir`, mockup files persist in `.superpowers/brainstorm/`
for later reference. Only `/tmp` sessions are deleted on stop.
```

Y:

```text
If the session used `--project-dir`, mockup files persist in `.hyper-relay/companion/`
for later reference. Only `/tmp` sessions are deleted on stop.
```

- [ ] **Step 2: Check it**

| Run | Expected |
|---|---|
| `grep -c -F '.superpowers' skills/visual-companion/SKILL.md` | `0` |
| `grep -c -E '30 minutes\|no requests\|idled out' skills/visual-companion/SKILL.md` | `0` |
| `grep -c -F '.hyper-relay/companion/' skills/visual-companion/SKILL.md` | `6` |
| `grep -c -F 'Ask the agent for the full link.' skills/visual-companion/SKILL.md` | `2` |
| `grep -c -F 'Paused — the agent will bring it back.' skills/visual-companion/SKILL.md` | `1` |
| `grep -c -F '.gitignore' skills/visual-companion/SKILL.md` | `1` |
| `grep -c -F 'Paused — the agent will bring it back.' skills/visual-companion/scripts/helper.js` | `1` or more |
| `grep -c -F 'Ask the agent for the full link.' skills/visual-companion/scripts/helper.js` | `1` or more |
| `grep -c -F 'Ask the agent for the full link.' skills/visual-companion/scripts/server.cjs` | `1` or more |

Then commit:

```bash
git add skills/visual-companion/SKILL.md
git commit -m "docs(visual-companion): the skill's lifetime, link, notices, folder and git" -m "Plan-Task: docs/superpowers/plans/2026-11-19-hyper-relay-companion-hardening.md#6"
```

- [ ] **Step 3: The full gates, once.** In a command inside a table cell, `\|` is a plain `|`.

| Run | Expected |
|---|---|
| `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, no `FAIL`, exit 0 |
| `bash -n skills/visual-companion/scripts/start-server.sh` | silent |
| `bash -n skills/visual-companion/scripts/stop-server.sh` | silent |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `claude plugin validate .` | passes (exit 0); report every warning verbatim (expected: the root `CLAUDE.md` one, `ICON_MISSING`, and `PRIVACY_URL_MISSING` only in the main checkout) |
| `pgrep -af -- '--companion-[i]d='` | nothing (no test server left) |
| `pgrep -af 'visual-companion/scripts/[s]erver.cjs'` | nothing |
| `git diff --name-only main...HEAD` | exactly the twelve files of Task 7 Step 3 |
| `git status --short` | nothing (on a branch run, nothing but untracked files under `docs/superpowers/` that you did not create) |

Then report, copy Task 7's checklist (Steps 1–15, each with its marker and its PASS) into your report, and stop: Task 7
is not yours.

### Task 7: Acceptance (spec §9, §10; P15, P18, P19). Not the executor's

Each step is marked with who runs it:
- **`reviewer`**: the acceptance reviewer, before the merge, from the top of the checkout on the branch
  (`hyper-relay-companion-hardening`) its dispatch names (Steps 1–4).
- **`skill-test`**: the orchestrator, after acceptance and beside the code review, by the standing leg (`reviewing.md`
  §3): its `red/` and `green/` folders hold `main`'s and the branch's `skills/`. Steps 5–9 are S1–S5: each is
  dispatched twice, on Sonnet, with the leg's preamble and then the step's situation, verbatim, its `<CONTEXT>` line
  replaced by the block below, verbatim.
- **`owner`**: the owner, at the click-through (Steps 10–12); the orchestrator runs the commands.
- **`after merge`**: the orchestrator with the owner, once the branch is merged and the main checkout
  `/home/noob_master/hyper-relay` is on `main` (Steps 13–15).

In a command inside a table cell, `\|` is a plain `|`. The companions the reviewer and the orchestrator start below are
owned by their Claude Code session, so each step stops what it starts.

**`<CONTEXT>`** (P19):

```text
This test is set in a project your human partner works on: a git repo at /home/user/shop, your working directory. You
are the agent your human partner talks to, in Claude Code, brainstorming a design with them, and you use the skill
`hyper-relay:visual-companion` (the folder `visual-companion` in your skills folder) to show them mockups in their
browser while they answer in the terminal. `${CLAUDE_SKILL_DIR}` in that skill is its folder. Your tools include Read,
Write, Edit, Grep, Glob and Bash. In this test you cannot read files or run commands: list each read and command among
your commands, in order, and take what it would show from the facts the situation gives. For a screen you write, give
its file name and one line on its content instead of its HTML. Today is 2026-11-21.
```

- [ ] **Step 1 (`reviewer`): The gates (spec §10 step 1).**

| Run | PASS |
|---|---|
| `bash skills/visual-companion/scripts/run-tests.sh` | every case `ok`, no `FAIL`, exit 0 |
| `bash -n skills/visual-companion/scripts/start-server.sh` | silent |
| `bash -n skills/visual-companion/scripts/stop-server.sh` | silent |
| `claude plugin validate .` | passes (exit 0); its warnings are exactly the root `CLAUDE.md` one, `ICON_MISSING` and, only in the main checkout, `PRIVACY_URL_MISSING` |
| `sh tests/orchestrating/run-tests.sh \| tail -n 1` | ends `0 failed` |
| `git diff --stat main...HEAD -- package.json .claude-plugin` | nothing (the release is after the merge) |

- [ ] **Step 2 (`reviewer`): A live run in a temporary git repo (spec §10 step 2).** One command per run, in order.
  `<port>` and `<key>` come from the first start's `url`.

| Run | PASS |
|---|---|
| `rm -rf /tmp/vc-accept`, then `git init -q /tmp/vc-accept` | exit 0 |
| `bash skills/visual-companion/scripts/start-server.sh --project-dir /tmp/vc-accept --session accept` | one JSON line: `"type":"server-started"`, `url` `http://localhost:<port>/?key=<key>` with 64 hex digits, `"git_exclude":"added"`, `owner_pid` a number, `"idle_timeout_ms":null` |
| `printf '<h2>Accept</h2>\n' > /tmp/vc-accept/.hyper-relay/companion/accept/content/accept.html` | exit 0 |
| `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:<port>/` | `403` |
| `curl -s -D - -o /dev/null 'http://localhost:<port>/?key=<key>'` | status `302`; `Location: /`; `Set-Cookie: companion-key-<port>=<key>; HttpOnly; SameSite=Strict; Path=/` |
| `curl -s -D - -H 'Cookie: companion-key-<port>=<key>' http://localhost:<port>/` | status `200`; `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, `X-Frame-Options: SAMEORIGIN`, `Content-Security-Policy: frame-ancestors 'self'`, `Cross-Origin-Resource-Policy: same-origin`; the body holds `<h2>Accept</h2>` |
| `curl -s -o /dev/null -w '%{http_code}\n' -H 'Cookie: companion-key-<port>=<key>' http://localhost:<port>/files/` | `404` |
| `curl -s -H 'Cookie: companion-key-<port>=<key>' http://localhost:<port>/poll` | JSON with `"file":"accept.html"` (it still answers) |
| `bash skills/visual-companion/scripts/stop-server.sh /tmp/vc-accept/.hyper-relay/companion/accept` | `{"status": "stopped"}` |
| `curl -s -o /dev/null -w '%{http_code}\n' -m 2 http://localhost:<port>/poll` | `000` (nothing answers) |
| `bash skills/visual-companion/scripts/start-server.sh --project-dir /tmp/vc-accept --session accept` | the same `url` (port and key kept); no `git_exclude` field |
| `grep -c -x -F '/.hyper-relay/companion/' /tmp/vc-accept/.git/info/exclude` | `1` |
| `git -C /tmp/vc-accept status --porcelain` | nothing (the folder is ignored) |
| `test -e /tmp/vc-accept/.gitignore \|\| echo absent` | `absent` |
| `bash skills/visual-companion/scripts/stop-server.sh /tmp/vc-accept/.hyper-relay/companion/accept`, then `rm -rf /tmp/vc-accept` | `{"status": "stopped"}` |

- [ ] **Step 3 (`reviewer`): Only the planned files (spec §10 step 3; §12; P1).**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `CLAUDE.md`, `skills/visual-companion/SKILL.md`, and under `skills/visual-companion/scripts/`: `helper.js`, `server.cjs`, `start-server.sh`, `stop-server.sh`, `test-folder.cjs`, `test-helper.cjs`, `test-injection.cjs`, `test-server.cjs`, `test-session.cjs`, `test-stop.cjs` |
| `git diff main...HEAD -- skills \| grep -c -E '^\+.*(/home/\|/Users/\|~/)'` | `0` |
| `git diff --stat main...HEAD -- skills/visual-companion/scripts/frame-template.html skills/visual-companion/scripts/run-tests.sh` | nothing |

- [ ] **Step 4 (`reviewer`): The text against the plan (spec §5, §8; P12, P13, P15).** Read
  `git diff main...HEAD -- skills/visual-companion/SKILL.md CLAUDE.md`. PASS: each hunk is one of Task 6 Step 1's or
  Task 5 Step 5's "Replace X with Y" edits, with Y word for word, and nothing else differs; Task 6 Step 2's nine
  checks give their expected counts. A sentence that contradicts the spec beyond the P-notes is a FAIL, with its line.

- [ ] **Step 5 (`skill-test`): S1, two hours later, the server is still up (§9 S1; §8 the loop).**

Situation:

```text
<CONTEXT>

Two hours ago, in this conversation, you started a companion session named `checkout-layout` with `--project-dir
/home/user/shop`, gave your human partner the link it printed, and showed three screens, the last of them
`layout-v2.html`. You saved the start JSON's `screen_dir` and `state_dir`; call them `$SCREEN_DIR` and `$STATE_DIR`.
For the two hours since, you have talked in the terminal about payment providers, with no screen, and your human
partner was away from the computer for an hour of it.

Your human partner now writes: "OK, back to the layout. Show me the checkout with the address step folded into the
payment step."

If you look in `$STATE_DIR`, it holds `server-info`, `server.pid`, `port`, `token`, `server-instance-id` and
`server.log`, and no `server-stopped`. `server-info` reads:
{"type":"server-started","port":52341,"host":"127.0.0.1","url_host":"localhost","url":"http://localhost:52341/?key=3f9c0d7e5a1b2c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d","screen_dir":"$SCREEN_DIR","state_dir":"$STATE_DIR","owner_pid":48213,"idle_timeout_ms":null}

Give your commands, in order, and your next message to your human partner, verbatim.
```

GREEN must: at most read `$STATE_DIR` (`server-info` there, `server-stopped` not); run neither `start-server.sh` nor
`stop-server.sh`; write one new file in `$SCREEN_DIR` with a new name, with the Write tool; and send a message that
says what is on screen and asks for the answer in the terminal, without giving the link again.

RED is expected to: run `start-server.sh --session checkout-layout` again, in case the server idled out after 30
minutes, and/or give the link again. A RED that only checks the files and writes the screen is recorded as not
failing.

- [ ] **Step 6 (`skill-test`): S2, "Ask the agent for the full link" (§9 S2; §8 the notices).**

Situation:

```text
<CONTEXT>

An hour ago, in this conversation, you started a companion session named `checkout-layout` with `--project-dir
/home/user/shop` and gave your human partner its link; you have shown two screens since. You saved the start JSON's
`screen_dir` and `state_dir`; call them `$SCREEN_DIR` and `$STATE_DIR`.

Your human partner now writes: "I wanted it in Firefox too, so I typed localhost:52341 there, and the page just says
'Ask the agent for the full link.' What's going on?"

If you look in `$STATE_DIR`, it holds `server-info` and no `server-stopped`. `server-info` reads:
{"type":"server-started","port":52341,"host":"127.0.0.1","url_host":"localhost","url":"http://localhost:52341/?key=3f9c0d7e5a1b2c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d","screen_dir":"$SCREEN_DIR","state_dir":"$STATE_DIR","owner_pid":48213,"idle_timeout_ms":null}

Give your commands, in order, and your next message to your human partner, verbatim.
```

GREEN must: read `$STATE_DIR/server-info`; run neither `start-server.sh` nor `stop-server.sh` and no `curl`; and give
the full link, `http://localhost:52341/?key=3f9c0d7e5a1b2c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d`, every
digit, saying it must be opened with its key.

RED is expected to: not know the message: restart the server, or debug it (`curl`, the log, a stop and a start), or
give a link without its key.

- [ ] **Step 7 (`skill-test`): S3, the tab shows "Paused" (§9 S3; §8 the notices; P15).**

Situation:

```text
<CONTEXT>

Yesterday, in this conversation, you started a companion session named `checkout-layout` with `--project-dir
/home/user/shop`, gave your human partner its link and showed four screens. You saved the start JSON's `screen_dir`
and `state_dir`; call them `$SCREEN_DIR` and `$STATE_DIR`. Claude Code was closed overnight, and this morning your
human partner resumed this conversation with `claude --resume`.

Your human partner now writes: "The companion tab I left open says 'Paused — the agent will bring it back.' Can we
carry on with the layout?"

If you look in `$STATE_DIR`, it holds `server-stopped`, `port`, `token` and `server.log`, and no `server-info`.
`server-stopped` reads: {"reason":"owner process exited","timestamp":1795215600000}
If you run `start-server.sh` with `--project-dir /home/user/shop --session checkout-layout`, it prints:
{"type":"server-started","port":52341,"host":"127.0.0.1","url_host":"localhost","url":"http://localhost:52341/?key=3f9c0d7e5a1b2c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d","screen_dir":"$SCREEN_DIR","state_dir":"$STATE_DIR","owner_pid":50122,"idle_timeout_ms":null}

Give your commands, in order, and your next message to your human partner, verbatim.
```

GREEN must: run `start-server.sh` with `--project-dir /home/user/shop --session checkout-layout`, and tell the human
partner it is back and the open tab will reload by itself, with the link unchanged; not ask them to reload, or to open
a link, by hand.

RED is expected to: not know the notice: it may restart (its text restarts on `server-stopped`), but asks the human
partner to refresh the page or open the URL again.

- [ ] **Step 8 (`skill-test`): S4, where the screens are (§9 S4; §8 the folder).**

Situation:

```text
<CONTEXT>

Earlier today, in another conversation, you showed your human partner mockups in a companion session named
`invoice-pdf`, started with `--project-dir /home/user/shop`. That conversation's notes are not available to you.

Your human partner now writes: "Where are the invoice-pdf mockups on disk? I want to send the HTML files to Dana."

Answer from the skill: in this test, a listing or a search shows nothing you can use.

Give your commands, in order, and your next message to your human partner, verbatim.
```

GREEN must: answer `/home/user/shop/.hyper-relay/companion/invoice-pdf/content/`, offering no other folder as where
they are.

RED is expected to: answer `/home/user/shop/.superpowers/brainstorm/invoice-pdf/` (or its `content/`).

- [ ] **Step 9 (`skill-test`): S5, the start adds the exclude line (§9 S5; §8 git).**

Situation:

```text
<CONTEXT>

In this conversation your human partner agreed to see mockups in the browser, and to the session name
`onboarding-flow`. You ran
`${CLAUDE_SKILL_DIR}/scripts/start-server.sh --project-dir /home/user/shop --session onboarding-flow`, and it printed:
{"type":"server-started","port":52877,"host":"127.0.0.1","url_host":"localhost","url":"http://localhost:52877/?key=9d1e4b7a2c5f8e0d3b6a9c2e5f8b1d4a7c0e3f6b9d2a5c8e1f4b7d0a3c6e9f2b","screen_dir":"/home/user/shop/.hyper-relay/companion/onboarding-flow/content","state_dir":"/home/user/shop/.hyper-relay/companion/onboarding-flow/state","owner_pid":48213,"idle_timeout_ms":null,"git_exclude":"added"}

The repo has a `.gitignore`, which mentions neither `.superpowers/` nor `.hyper-relay/`. You have not written a screen
yet.

Give the commands you run next, in order, up to and including writing the first screen (a layout for the welcome
step), and your next message to your human partner, verbatim.
```

GREEN must: give the full link once, with its key, and one line saying the companion's folder is now ignored through
the repo's local exclude file; no command or edit touches `.gitignore`, and nothing asks the human partner to add
anything to `.gitignore`.

RED is expected to: remind the human partner to add `.superpowers/` (or the companion's folder) to `.gitignore`, or
edit `.gitignore` itself.

- [ ] **Step 10 (`owner`): In a real browser (spec §10 step 4).** The orchestrator runs, one command per call, from
  the top of the checkout on the branch:

```bash
rm -rf /tmp/vc-click
git init -q /tmp/vc-click
bash skills/visual-companion/scripts/start-server.sh --project-dir /tmp/vc-click --session click
printf '<h2>Inner</h2>\n' > /tmp/vc-click/.hyper-relay/companion/click/content/inner.html
printf '<h2>A framed file</h2>\n<iframe src="/files/inner.html" style="width:100%%;height:200px"></iframe>\n' > /tmp/vc-click/.hyper-relay/companion/click/content/frame.html
```

and gives the owner the full link from the start's `url`. Then, in order:

| Action | PASS |
|---|---|
| The owner opens the full link | the companion opens; the address bar ends at `/` (the key has left it) |
| The owner looks at the screen | "A framed file", with "Inner" rendered inside the frame |
| The orchestrator runs `bash skills/visual-companion/scripts/stop-server.sh /tmp/vc-click/.hyper-relay/companion/click` | within about 10 seconds the tab shows "Paused — the agent will bring it back." over the last screen |
| The orchestrator runs the start command again | the tab reloads to the screen by itself, with no click |
| The owner opens `http://localhost:<port>/` in a private window | "Ask the agent for the full link." |
| The orchestrator runs the stop command, then `rm -rf /tmp/vc-click` | `{"status": "stopped"}` |

- [ ] **Step 11 (`owner`): Read the new text.** Read
  `git -C /home/noob_master/hyper-relay diff main...hyper-relay-companion-hardening -- skills/visual-companion/SKILL.md CLAUDE.md`,
  with stop 4's skill-test results and the P-notes, P3, P4, P12 and P15 above all. PASS: the owner agrees with them as
  written. A change goes to the executor as a finding.

- [ ] **Step 12 (`owner`; the orchestrator runs the command at the click-through, before the merge): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay merge-tree --write-tree main hyper-relay-companion-hardening` | exit 0, one line (a tree id) |

The merge runs as the installed relay says: `relay-merge` from the main checkout on `main`.

- [ ] **Step 13 (`after merge`): Re-check on `main`, and the role agents (spec §10; P18).** None of the templates
  change, so the agents stay current; `main`'s own generator checks it here and in SAT.

| Run | PASS |
|---|---|
| `git -C /home/noob_master/hyper-relay branch --show-current` | `main` |
| `bash /home/noob_master/hyper-relay/skills/visual-companion/scripts/run-tests.sh` | every case `ok`, exit 0 |
| `cd /home/noob_master/hyper-relay && claude plugin validate .` | passes; warnings the root `CLAUDE.md` one, `ICON_MISSING` and `PRIVACY_URL_MISSING` |
| `git -C /home/noob_master/hyper-relay status --porcelain --untracked-files=no` | nothing |
| `cd /home/noob_master/hyper-relay && sh bin/hyper-relay-agents --check` | nothing, exit 0 |
| `cd /home/noob_master/sat.pentraze.com && sh /home/noob_master/hyper-relay/bin/hyper-relay-agents --check` | nothing, exit 0 |

A line from `--check` stops the step: tell the owner.

- [ ] **Step 14 (`after merge`): The release, 0.2.5 (spec §10; `.hyper-relay/agents.md`, Releases, (1) and (2)).**
  The owner approves this push at stop 4: it also takes `main`'s earlier unpushed commits (this spec and plan among
  them), which is expected. In the main checkout on `main` (no `MERGE_HEAD`), one command per Bash call, with
  `<x.y.z>` the version `--check` shows with its patch number raised by one (`0.2.5` from `0.2.4`):

| Run | PASS |
|---|---|
| `cd /home/noob_master/hyper-relay && scripts/bump-version.sh --check` | both files at one version, no drift (`0.2.4`) |
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

- [ ] **Step 15 (`after merge`, last): The owner updates and reloads (Releases, (3)).** The owner runs, in a shell,
  `claude plugin update hyper-relay@hyper-relay`, then `/reload-plugins` in the orchestrator's running session (or
  starts a new session).

| Run | PASS |
|---|---|
| `test -d /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z> && echo cached` | `cached` |
| `grep -c -F -- '--companion-id=' /home/noob_master/.claude/plugins/cache/hyper-relay/hyper-relay/<x.y.z>/skills/visual-companion/scripts/start-server.sh` | `1` or more |

If the update says it is already at the latest version, the owner runs `claude plugin marketplace update hyper-relay`
and the update again. If a check still fails, stop and tell the owner; delete or uninstall nothing. Companions that
0.2.4's scripts started keep running until their sessions end (spec §2, a server an old script started). Then tick the
acceptance task as `reviewing.md` §5 says.
