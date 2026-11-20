// Behaviour of start-server.sh / server.cjs / stop-server.sh for NAMED sessions.
// Every case here is a requirement from
// docs/superpowers/specs/2026-09-09-sketch-loop-workflow-design.md §2.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const SCRIPTS = __dirname;
const START = path.join(SCRIPTS, 'start-server.sh');
const STOP = path.join(SCRIPTS, 'stop-server.sh');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vc-session-'));
const failures = [];
const started = [];

function check(name, fn) {
  try {
    const r = fn();
    console.log('ok  ' + name + (r === 'skip-proc' ? ' (skipped: no /proc)' : ''));
  } catch (e) {
    failures.push(name + ': ' + e.message);
    console.error('FAIL ' + name + ': ' + e.message);
  }
}

function start(args) {
  const r = spawnSync('bash', [START, '--project-dir', root, ...args], {
    encoding: 'utf8', env: { ...process.env, GIT_CEILING_DIRECTORIES: os.tmpdir() },
  });
  return { code: r.status, out: (r.stdout || '').trim(), err: (r.error && r.error.message) || r.stderr };
}

function sessionDir(name) {
  return path.join(root, '.superpowers', 'brainstorm', name);
}

function stop(name) {
  spawnSync('bash', [STOP, sessionDir(name)], { encoding: 'utf8' });
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

// 1. A named session creates a directory under its own name.
check('named session uses the name as its directory', () => {
  const r = start(['--session', 'alpha-topic']);
  started.push('alpha-topic');
  assert(r.code === 0, 'start failed: ' + r.out + r.err);
  assert(fs.existsSync(sessionDir('alpha-topic')), 'no dir at ' + sessionDir('alpha-topic'));
  const info = JSON.parse(r.out);
  assert(info.type === 'server-started' || info.type === 'server-info', 'unexpected: ' + r.out);
});

// 2. Restarting the same name REUSES the directory — screens survive.
check('restart preserves screens written before it', () => {
  const content = path.join(sessionDir('alpha-topic'), 'content');
  fs.writeFileSync(path.join(content, 'screen-one.html'), '<h2>kept</h2>');
  stop('alpha-topic');
  const r = start(['--session', 'alpha-topic']);
  assert(r.code === 0, 'restart failed: ' + r.out + r.err);
  assert(fs.existsSync(path.join(content, 'screen-one.html')), 'content/ was cleared on restart');
});

// 3. The port is stable across a restart.
check('restart reuses the same port', () => {
  const portFile = path.join(sessionDir('alpha-topic'), 'state', 'port');
  assert(fs.existsSync(portFile), 'no state/port file');
  const before = fs.readFileSync(portFile, 'utf8').trim();
  stop('alpha-topic');
  const r = start(['--session', 'alpha-topic']);
  assert(r.code === 0, 'restart failed');
  const after = fs.readFileSync(portFile, 'utf8').trim();
  assert(before === after, `port changed across restart: ${before} -> ${after}`);
});

// 4. Starting a live session again returns THAT server, not a second one.
check('second start returns the running server', () => {
  const pidFile = path.join(sessionDir('alpha-topic'), 'state', 'server.pid');
  const firstPid = fs.readFileSync(pidFile, 'utf8').trim();
  const r = start(['--session', 'alpha-topic']);
  assert(r.code === 0, 'second start failed: ' + r.out + r.err);
  const secondPid = fs.readFileSync(pidFile, 'utf8').trim();
  assert(firstPid === secondPid, `a second server was started: ${firstPid} -> ${secondPid}`);
});

// 5. A clean stop leaves no lying server-info behind.
check('stop removes server-info', () => {
  const info = path.join(sessionDir('alpha-topic'), 'state', 'server-info');
  // Precondition, or this passes vacuously on a session that never ran and proves nothing
  // about shutdown(): a live server must have written server-info before we stop it.
  assert(fs.existsSync(info), 'precondition failed — no server-info existed before the stop');
  stop('alpha-topic');
  assert(!fs.existsSync(info), 'server-info survived a clean stop — liveness checks will lie');
});

// Lifetime, owner, files and arguments (spec 2026-11-19-hyper-relay-companion-hardening).
function st(name) {
  return path.join(sessionDir(name), 'state');
}
const hasProc = fs.existsSync('/proc/self/cmdline');
function needsProc(fn) {
  return () => {
    if (!hasProc) return 'skip-proc';
    return fn();
  };
}

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
check("node runs with this start's instance id", needsProc(() => {
  const id = fs.readFileSync(path.join(st('owner-check'), 'server-instance-id'), 'utf8').trim();
  assert(/^[0-9a-f]{48}$/.test(id), 'id ' + id);
  const pid = fs.readFileSync(path.join(st('owner-check'), 'server.pid'), 'utf8').trim();
  const args = fs.readFileSync(`/proc/${pid}/cmdline`, 'utf8').split('\0');
  assert(args.includes('--companion-id=' + id) && args.some((a) => a.endsWith('server.cjs')), args.join(' '));
}));
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
check('--idle-timeout-minutes reaches node', needsProc(() => {
  start(['--session', 'idle-flag', '--idle-timeout-minutes', '7']); started.push('idle-flag');
  const pid = fs.readFileSync(path.join(st('idle-flag'), 'server.pid'), 'utf8').trim();
  assert(fs.readFileSync(`/proc/${pid}/environ`, 'utf8').split('\0').includes('BRAINSTORM_IDLE_TIMEOUT_MS=420000'));
}));
for (const bad of ['0', '-3', 'abc', '1.5', '08']) {
  check(`--idle-timeout-minutes refuses ${bad}`, () => {
    const r = start(['--session', 'idle-bad', '--idle-timeout-minutes', bad]);
    assert(r.code === 1 && r.out === '{"error": "--idle-timeout-minutes must be a positive integer"}', r.out);
  });
}
check('a relative --project-dir and one with a space both work', () => {
  const env = { ...process.env, GIT_CEILING_DIRECTORIES: os.tmpdir() };
  const rel = path.join(root, 'rel');
  fs.mkdirSync(rel);
  for (const [dir, cwd, top] of [['.', rel, rel], [path.join(root, 'with space'), root, path.join(root, 'with space')]]) {
    const r = spawnSync('bash', [START, '--project-dir', dir, '--session', 'rel-check'], { encoding: 'utf8', cwd, env });
    assert(r.status === 0, r.stdout);
    const info = JSON.parse(r.stdout);
    assert(info.state_dir.startsWith(top + path.sep) && fs.existsSync(info.screen_dir), info.state_dir);
    spawnSync('bash', [STOP, path.dirname(info.state_dir)], { encoding: 'utf8' });
  }
});

// 6. Bad names are refused rather than silently coerced into a path.
for (const bad of ['../escape', 'has/slash', '', 'Has-Caps', '-leading']) {
  check(`rejects invalid session name ${JSON.stringify(bad)}`, () => {
    const r = start(['--session', bad]);
    assert(r.code !== 0, 'accepted an invalid name');
    // Must be refused BY VALIDATION. "Unknown argument: --session" also exits non-zero with
    // an error, so matching /error/ alone would pass before --session even exists.
    assert(/invalid --session|must match/i.test(r.out), 'not refused by validation: ' + r.out);
  });
}

// Cleanup: stop anything still alive.
for (const name of started) stop(name);
fs.rmSync(root, { recursive: true, force: true });

if (failures.length) {
  console.error(`\n${failures.length} failing:`);
  failures.forEach((f) => console.error('  - ' + f));
  process.exit(1);
}
console.log('\nall session tests passed');
