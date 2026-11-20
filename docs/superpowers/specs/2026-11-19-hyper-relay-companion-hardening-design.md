# hyper-relay: the companion stays up, locks its door, and lives in `.hyper-relay/` (design)

**Date:** 2026-11-19 · **Status:** design approved by the owner in chat on 2026-11-19, part by part
**Card:** visual-companion: port upstream's server hardening and the 30-minute idle-out fix (`e3303d7a-d569-44a5-ad53-89917bb0fdb5`)
**Initiative:** v0.1.0
**Scope:** this repo: `skills/visual-companion/` (`SKILL.md`, `scripts/server.cjs`, `scripts/start-server.sh`,
`scripts/stop-server.sh`, `scripts/helper.js`, its tests and `scripts/run-tests.sh`) and `CLAUDE.md`. One plan. Released
as the next patch after the research-before-plan release (0.2.5, unless `main` holds another version).

## Goal

The visual companion is the browser tab the owner looks at while an agent shows mockups; the owner answers in the
terminal. Two things are wrong with it today, and the owner wants both fixed (card `e3303d7a`):

- **It dies while the owner is still working,** and "it is a bit tedious having to ask for the screen again." Half of
  the last 30 companions on this machine stopped on the 30-minute idle-out while the session that started them was
  still running (How it works).
- **Its door is open.** Anything that can reach its port can read the screens, some of which embed real login pages;
  it serves whatever a symlink in its folder points at; one malformed request crashes it. Upstream (obra/superpowers)
  fixed these between v5.1.0 and v7.0.2.

The owner also asked for the companion's folder to move from `.superpowers/brainstorm/` to `.hyper-relay/companion/`,
so everything hyper-relay keeps in a project sits in one place.

The companion stays what it is: display-only, kept in sync by the page asking the server once a second. "Websockets
to detect clicks is overkill." Making the skill about faithful design is card `0f063392`, after this one.

## Decisions (owner, 2026-11-19)

| # | Question | Decision |
|---|---|---|
| VC1 | Scope | Upstream's security fixes and the idle-out fix. No compatibility fixes (Windows, other harnesses), no branding (card). |
| VC2 | Clicks, WebSockets | **None.** Display-only and polling stay. |
| VC3 | What must the lifetime fix achieve? | The owner never has to ask for the screen again. |
| VC4 | How long does the server live? | **(b) As long as the Claude Code session that started it,** open tab or not. Not (a), upstream's 4-hour idle-out alone. |
| VC5 | Part 1, staying up and recovering (§2) | As played back. |
| VC6 | Part 2, security and bug fixes (§3–§6) | As played back. |
| VC7 | Where do sessions live? | **(a) `.hyper-relay/companion/<session>/`,** only that subfolder ignored by git, with a one-time move of an old session from `.superpowers/brainstorm/` when it is started again (§5). |
| VC8 | Pressure scenarios | **S1–S5 as played back** (§9). |

Calls made by the orchestrator, which the owner did not object to: framing allowed for the companion itself (§4,
not upstream's DENY); the key per session in `state/token`, always kept (§3); a redirect sets the cookie (§3); the
"paused" notice after about 5 seconds (§2); the start script adds the git exclude line itself (§5); a running old
session is not moved until it has stopped (§5); upstream's `--open` left out; the test style (§7). After the builder
check: the `$PPID` fallback goes, so an unresolved owner means the 4-hour idle-out (§2); `server-info`'s two new
field names (§2); a server an old script started is treated as running and never signalled (§2); a taken port gives a
new link, as today (§2); the instance id's argument form (§2).

## How it works

Each fact with its source and the date it was checked. Line numbers drift; functions are named instead where they
help.

**Our companion today** (`skills/visual-companion/scripts/` at `7ec3133`, read 2026-11-19):

- `start-server.sh --project-dir P --session NAME` makes `P/.superpowers/brainstorm/NAME/{content,state}`, reuses the
  port saved in `state/port`, records the harness (its grandparent process) as the owner, and starts `node server.cjs`
  in the background. It prints a `server-started` JSON line with the URL and writes it to `state/server-info`.
- The agent writes a screen as a new `.html` file in `content/`. `GET /` serves the newest one by modification time,
  wrapped in `frame-template.html` when it is a fragment, with `helper.js` injected before the last `</body>`. The page
  calls `GET /poll` every second and reloads when the newest file's name or time changes. `GET /files/<name>` serves a
  file from `content/`. There are no other routes and no authentication.
- `handleRequest` calls `touchActivity()` first, for every request. Every 60 seconds the server exits if the owner
  process is gone ("owner process exited") or if 30 minutes passed with no request ("idle timeout"). An open tab polls
  every second, so the idle-out fires only when no tab is polling: a closed tab, a tab the browser suspended, or a
  machine asleep.
- `helper.js` swallows a failed poll and a non-OK answer, so after the server dies the tab keeps the last screen, with
  no sign anything is wrong.
- `stop-server.sh` signals whatever PID `state/server.pid` holds; `start-server.sh` treats any live process with that
  PID as its server. Foreground mode writes the shell's PID, not node's.
- `start-server.sh` clears `server.pid` and `server-info` for a dead server, but never `server-stopped`, so after one
  restart the old "stopped" marker sits beside a running server. `SKILL.md`'s loop tells the agent to restart when that
  file exists.

**Bugs found by reading** (2026-11-19, a research agent's report checked by the orchestrator against the code):

- `wrapInFrame` is `frameTemplate.replace('<!-- CONTENT -->', content)`: a fragment containing `$&` or `` $` `` is
  mangled (checked with `node -e`). Full documents skip `wrapInFrame`; the `</body>` injection uses `lastIndexOf` and
  is safe.
- `GET /files/` with an empty name (or `..`) resolves to the content folder itself; `existsSync` is true and
  `readFileSync` throws `EISDIR` inside the handler with no `try`, which crashes the server. No key is needed.
- `existsSync` follows symlinks, so `/files/<link>` serves any file the link points at. Dotfiles are served and can be
  picked as the newest screen. A directory or dangling link named `x.html` throws in `/` and `/poll`.
- `start-server.sh` builds its paths from `--project-dir` as given, then `cd`s to the script folder before writing the
  log and PID files, so `--project-dir .` fails ("failed to start within 5 seconds").

**Upstream** (obra/superpowers, `v5.1.0..v7.0.2` under `skills/brainstorming/scripts/` and `tests/brainstorm-server/`,
fetched tags in this repo, read 2026-11-19):

- The per-session key: `cb5bb88`, with follow-ups `7fbae02`, `b17d54f`, `0410679`, `8f2525a`, `3a907d6`. It covers key
  generation (`crypto.randomBytes(32)`), the `?key=` URL, an HttpOnly, SameSite=Strict cookie named per port, the 403
  page, `timingSafeEqual`, owner-only files, `umask 077`, and activity counted only after authorization.
- File serving: `isRegularFileInsideContentDir`, which uses `lstat`, rejects symlinks and files with more than one
  link, checks `realpath`, and rejects dotfiles (`2b108b7`).
- The security headers: `no-store`, `no-referrer`, `X-Frame-Options: DENY`, `frame-ancestors 'none'` and
  `Cross-Origin-Resource-Policy: same-origin`.
- Stopping by a per-start instance id checked against `/proc/<pid>/cmdline` (`6bc49f0`, after `5ddce06` and
  `7c805f3`).
- The idle timeout of 4 hours and `--idle-timeout-minutes` (`56757f6`).
- `$&` (`bb92a77`, v7.0.0).
- The relative `--project-dir` fix (`22f0b46`, v7.0.2).
- Upstream's tests are plain `node` scripts plus two bash tests. Their one dependency, `ws`, is only for WebSocket
  clients.
- **Not applicable to ours:** the WebSocket gate and frame cap, the `sessionStorage` bootstrap, and the reconnect UI
  built on a socket.

**This machine** (2026-11-19):

- The last 30 `state/server-stopped` files across the owner's projects: 15 "idle timeout", 11 "owner process exited",
  4 "stopped by signal". The owner-process check works here.
- 17 past screens show companion files in an iframe (`<iframe … src="/files/…">`): 9 in SAT, 6 in playground, 2 in
  another project. Upstream's DENY would blank them.
- `.superpowers/` is git-ignored in SAT, playground and quartz, which hold 52, 21 and 7 sessions.
- `.hyper-relay/` holds tracked files: `agents.md` here and in SAT, `merge.conf` here.
- **The owner process is Claude Code.** A script the Bash tool runs as one command has, as its parent, the tool's
  short-lived `bash -c` wrapper, and as its grandparent the long-lived `claude` process (seen with a script printing
  both, in this session, 2026-11-19: parent `/bin/bash -c source …/shell-snapshot …`, grandparent `claude`, up 6h29m).
  So `start-server.sh`'s "grandparent" rule finds the session; its fallback to `$PPID` would find the wrapper, which
  dies seconds later.
- **Git's exclude file in a worktree.** `git rev-parse --path-format=absolute --git-path info/exclude` gives the main
  repo's `.git/info/exclude` from the main checkout and from a linked worktree alike; a line added there makes
  `git check-ignore -q .hyper-relay/companion/` succeed in both. `git check-ignore` works on a path that does not exist
  yet (exit 1 before, 0 after). Checked in a scratch repo with a worktree, git 2.43.0 (this machine), 2026-11-19;
  `--path-format` needs git 2.31 or later.

## 1. What changes where

| File | Change |
|---|---|
| `skills/visual-companion/scripts/server.cjs` | Lifetime (§2), the key (§3), headers and file serving (§4), `$&` (§6) |
| `skills/visual-companion/scripts/start-server.sh` | The folder, the exclude line and the move (§5); the key file, `umask` and instance id (§2, §3); `--idle-timeout-minutes`; the relative `--project-dir` fix (§6); clearing `server-stopped` |
| `skills/visual-companion/scripts/stop-server.sh` | Signals only its own server (§2) |
| `skills/visual-companion/scripts/helper.js` | The "paused" and "ask for the link" notices (§2) |
| `skills/visual-companion/scripts/test-*.cjs`, `run-tests.sh` | New and updated tests (§7) |
| `skills/visual-companion/SKILL.md` | Lifetime, the link, the notices, the folder, git (§8) |
| `CLAUDE.md` | The rule "`docs/superpowers/` and `.superpowers/` keep their names" (§5) |

`frame-template.html` and every other skill stay as they are.

## 2. Staying up and recovering

- **Lifetime.** While the owner process is known and alive, the server never idles out. It exits when the owner
  process exits, as today.
- **The fallback.** When the owner process is unknown, the server idles out after 4 hours by default.
  `start-server.sh --idle-timeout-minutes <positive integer>` sets it, and it reaches node as
  `BRAINSTORM_IDLE_TIMEOUT_MS`. Only requests that pass the key check (§3) and new or changed screens count as activity.
  "Unknown" means the script's grandparent cannot be resolved, or is PID 1, or is already dead at startup (today's
  check). The fallback to `$PPID` goes: that is the Bash tool's short-lived wrapper (How it works), so a server tied
  to it would exit seconds after starting.
- **`server-info`** (written by `server.cjs`, as today) gains two fields, so the agent and the tests can read which
  applies: `owner_pid` (a number, or `null`) and `idle_timeout_ms` (a number when `owner_pid` is `null`, otherwise
  `null`). The start script's printed JSON carries `git_exclude` and `moved_from` (§5) for that start only; they do
  not go into `server-info`.
- **A taken port.** When the session's saved port is taken on restart, the server binds another, as today, and the
  printed link carries the new port. The agent gives the owner the new link (`SKILL.md` already says so); the old tab
  shows "Paused" until the new link is opened.
- **Restart.** A restart reuses the session's port and its key (§3), so an open tab carries on. `start-server.sh`
  removes `state/server-stopped` when it starts a server.
- **The tab** (`helper.js`):
  - After about 5 consecutive failed polls (no answer, or an error other than 403), it lays a notice over the last
    screen: "Paused — the agent will bring it back."
  - On a 403 it shows instead: "Ask the agent for the full link."
  - On the first successful poll after either notice, it reloads to the newest screen.
  - The notice carries its own inline styles, so it works on full documents as well as fragments.
- **Stopping only its own server.**
  - Each start makes a random instance id, saves it in `state/server-instance-id` (owner-only) and passes it to node
    as the argument `--companion-id=<id>`.
  - `stop-server.sh` signals a PID only when that process's command line holds exactly that argument. It reads
    `/proc/<pid>/cmdline`, or `ps -o args= -p <pid>` where there is no `/proc`.
  - Otherwise it removes the stale PID file, prints `{"status":"stale_pid"}` and signals nothing. A missing or
    malformed id also signals nothing.
  - `start-server.sh`'s "already running" check uses the same proof.
  - **A server an old script started** has no instance id. `start-server.sh` and the move (§5) treat it as running
    when its PID is alive and its `server-info` exists (today's check): a wrong "running" only delays a move.
    `stop-server.sh` never signals it without the proof, so it ends with its session or its own 30-minute idle-out.
- **Foreground mode** records node's own PID: the script writes `$$` and then `exec`s node.

## 3. The key

- **Making and keeping it.** On a session's first start, the server makes 32 random bytes in hex. It keeps the key in
  `state/token` (owner-only) and reuses it on every restart of that session, whatever port it binds.
- **Tests.** A `BRAINSTORM_TOKEN` environment value overrides it, for tests.
- **The link.** `server-info`'s `url` is `http://<url host>:<port>/?key=<key>`.
- **Opening the link.** `GET /?key=<right key>` answers 302 to `/` with
  `Set-Cookie: companion-key-<port>=<key>; HttpOnly; SameSite=Strict; Path=/`, so the key leaves the address bar.
- **The check.** Every route (`/`, `/poll`, `/files/…` and the not-found answer) requires the key:
  - in `?key=`, which wins: a wrong `?key=` fails even with a valid cookie;
  - otherwise in the cookie.
  - The comparison uses `crypto.timingSafeEqual`.
  - A failure answers 403 with a small page: "Ask the agent for the full link."
  - The activity clock is touched only after the check passes.
- **Owner-only files.** `start-server.sh` runs with `umask 077`. `state/token`, `state/server-info` (which holds the
  keyed link), `state/server.log` and `state/server-instance-id` are owner-only.

## 4. Headers and file serving

**Headers on every response,** 403 and 404 included:
- `Cache-Control: no-store`
- `Referrer-Policy: no-referrer`
- `X-Frame-Options: SAMEORIGIN`
- `Content-Security-Policy: frame-ancestors 'self'`
- `Cross-Origin-Resource-Policy: same-origin`

The companion can still frame its own files (How it works: 17 screens do); other sites cannot frame it.

**File serving.** A file is served, or picked as the newest screen, only when all of these hold:
- `lstat` says it is a regular file with one link;
- its `realpath` is inside the content folder's `realpath`;
- its name is not empty and does not start with `.`.

Anything else is "not found". The request handler is wrapped so that no request can crash the server: an unexpected
error answers 500 and the server keeps running.

## 5. The folder, git and the move

- **The folder.** `--project-dir P --session NAME` uses `P/.hyper-relay/companion/NAME/{content,state}`. Without
  `--project-dir`, sessions stay under `/tmp` as today.
- **Git.** When `P` is in a git work tree and `git check-ignore` says `.hyper-relay/companion/` is not ignored,
  `start-server.sh` appends `/.hyper-relay/companion/` to the repo's local exclude file (the path
  `git rev-parse --path-format=absolute --git-path info/exclude` gives, made if missing; from a worktree it is the main
  repo's file, which covers every worktree, as How it works records). It never touches `.gitignore`. The JSON it prints
  then carries `"git_exclude": "added"`. When the folder is already ignored, or `P` is not in a repo, it does nothing
  and says nothing.
- **The one-time move.** When `P/.hyper-relay/companion/NAME` does not exist and `P/.superpowers/brainstorm/NAME` does:
  - If that old session's server is running (by §2's check for a server an old script started), the script prints
    its `server-info` as today and moves nothing.
  - Otherwise it moves the folder to the new place, keeping its screens and `state/port`, then starts there. The JSON
    carries `"moved_from": "<old path>"`.
  - The old folder's link had no key, so the moved session gets a new one.
- **Old sessions** never started again stay where they are, readable as files.
- **`CLAUDE.md`'s rule** becomes: `docs/superpowers/` keeps its name, because Quartz accepts specs and plans only under
  it. The visual companion keeps its sessions in `.hyper-relay/companion/`, git-ignored, and older sessions may still
  sit in `.superpowers/brainstorm/`.

## 6. The two bugs

- A fragment is placed into the frame literally: `$&`, `` $` `` and `$'` in it come out as written (a function
  replacement, as upstream's `bb92a77`).
- `--project-dir` is made absolute (and created) before the script changes folder, so `--project-dir .` and a path
  with a space work.

## 7. Tests

**Style.** In `scripts/`, plain `node test-*.cjs` files with no dependencies, using global `fetch` and `spawnSync` for
the shell scripts, run by `run-tests.sh` as today. A shell test may be a `.cjs` that drives the scripts.

**The two existing tests** pass the key (through `BRAINSTORM_TOKEN`).

**Each change has a test.** These port upstream's HTTP cases:

- **The key:**
  - 403 with no key, and with a wrong key;
  - a wrong `?key=` beside a valid cookie;
  - the 302 and the cookie's flags;
  - a load with the cookie alone;
  - `/poll` and `/files/` need the key;
  - the headers on 200, 403 and 404;
  - a rejected request does not count as activity.
- **File serving:**
  - a dotfile;
  - `/files/` with an empty name (404, and the server still answers);
  - a symlink and a hard link pointing outside;
  - a directory and a dangling link named `x.html`.
- **Lifetime:**
  - with a live owner, no idle exit past the timeout;
  - with no owner, an idle exit after the timeout. The test needs a short check interval; an environment value for
    the interval is the builder's call.
  - a restart keeps the port and the key;
  - `server-stopped` is cleared on start.
- **Stopping:**
  - a reused PID that is not ours is not signalled;
  - the real server is signalled;
  - no PID file;
  - an impostor with no id, a wrong id, and a malformed id.
- **The folder:**
  - a new session in `.hyper-relay/companion/`;
  - the exclude line added once, and not added when the folder is already ignored or `P` is not in a repo;
  - an old session moved, keeping its screens and port;
  - an old session whose server is running, not moved.
- **The bugs:** `$&` shown as written; `--project-dir .` and a path with a space.

The notices in `helper.js` are tested as far as Node allows without a browser (for example, loading it with a fake
`fetch` and `document`, which is the builder's call). The owner's click-through covers how they look.

`CLAUDE.md`'s Checks row stays `bash skills/visual-companion/scripts/run-tests.sh`: every case `ok`, exit 0.

## 8. `skills/visual-companion/SKILL.md`

The plan writes the new sentences in full. They say:

- **The folder.** Every `.superpowers/brainstorm/` becomes `.hyper-relay/companion/`, in the text and in the examples.
- **The link.**
  - The start example's JSON shows the `url` with `?key=…`.
  - "Tell the user the URL once" becomes: give the full link, key included, exactly as printed, once. It keeps working
    across restarts.
- **Lifetime.**
  - The companion stays up while the Claude Code session that started it runs. It stops when that session ends, or
    after 4 hours idle when it cannot tell which session started it (`--idle-timeout-minutes`).
  - Every "30 minutes" goes, and so does "no requests".
- **The loop's first step.** The server is running when `state/server-info` exists and `state/server-stopped` does
  not. Then write the screen; there is no restart and no new link. Otherwise restart with the same `--session`; the
  link does not change.
- **The notices.**
  - When the human partner says the page reads "Ask the agent for the full link", give them the full link again,
    from `state/server-info`. Do not restart.
  - When they say the tab shows "Paused", restart with the same session name. The tab comes back by itself.
- **Git.**
  - When the start JSON says `"git_exclude": "added"`, tell the human partner in one line that the folder is now
    ignored through the repo's local exclude file.
  - Never edit `.gitignore` for the companion.
  - This replaces "Remind the user to add `.superpowers/` to `.gitignore`".
- **The move.** When the start JSON carries `moved_from`, say in one line that the session's screens moved to the new
  folder.
- **Unchanged:** the launch lines for other platforms (VC1), and everything about how screens are written (card
  `0f063392`).

## 9. Pressure scenarios

Each runs on `main`'s skills (RED) and the branch's (GREEN), on Sonnet, as a `skill-test` step, written as
`hyper-relay:writing-plans`' "Skill tests" section says and run by the orchestrator.

| # | Situation | The new text must | Today's text does |
|---|---|---|---|
| S1 | Same session, two hours after the last screen; the owner asks for a new one; `server-info` exists and `server-stopped` does not | Write the screen with no restart and no new link | Assumes the 30-minute idle-out, restarts, may announce the link again |
| S2 | The owner says the page reads "Ask the agent for the full link" | Give the full link with its key from `state/server-info`; no restart | Restarts or starts debugging |
| S3 | The owner says the tab shows "Paused" | Restart with the same session name and say it is back; the link is unchanged | Does not recognise the notice |
| S4 | The owner asks where session X's screens are | `.hyper-relay/companion/X/content/` | `.superpowers/brainstorm/X/` |
| S5 | Starting in a repo; the start JSON carries `"git_exclude": "added"` | Pass on the one-line note; do not edit `.gitignore` | Reminds the owner to add `.superpowers/` to `.gitignore` |

## 10. Acceptance and release

The reviewer's steps, on the branch:

1. **The gates.**
   - `bash skills/visual-companion/scripts/run-tests.sh`: every case `ok`, exit 0.
   - `bash -n` on `start-server.sh` and `stop-server.sh`: silent.
   - `claude plugin validate .`: passes, with the three known warnings.
   - `sh tests/orchestrating/run-tests.sh`: `0 failed`.
2. **A live run,** in a temporary git repo with `--project-dir`. `curl` shows:
   - 403 without the key;
   - 302 with `?key=`, its `Set-Cookie` carrying `HttpOnly` and `SameSite=Strict`;
   - the five headers on a 200;
   - 404 for `/files/` with the server still answering;
   - the exclude line added once;
   - a stop that removes the server.
3. **Only the planned files:** `git diff --name-only main...HEAD` lists exactly §1's files, plus any new `test-*.cjs`.

The owner's steps, at the click-through:

4. **In a real browser:**
   - the full link opens the companion;
   - a screen that frames a companion file still renders;
   - stopping the server shows "Paused" within seconds, and starting it again brings the page back by itself;
   - opening the link without its key shows "Ask the agent for the full link".
5. **Skill tests S1–S5** (§9), run by the orchestrator, RED and GREEN: all GREEN, with RED recorded.

After the merge:

- **Release** the next patch (0.2.5, unless `main` holds another version), as this repo's `.hyper-relay/agents.md`
  (Releases) says.
- **Your update:** `claude plugin update hyper-relay@hyper-relay` and `/reload-plugins`.
- **Role agents:** none of the templates change. `hyper-relay-agents --check` here and in SAT confirms they are
  current.

## 11. Order

This plan runs after the research-before-plan branch merges, and its release follows that one. Card `0f063392`
(faithful design) follows this one, because both edit `skills/visual-companion/SKILL.md`.

## 12. Out of scope

- WebSockets and click capture (VC2).
- Upstream's `--open`.
- Windows, MSYS2 and other harnesses' launch fixes, and branding (VC1).
- What the skill says about designing screens (card `0f063392`).
- Moving sessions that are never started again.
- The companion's look (`frame-template.html`).
