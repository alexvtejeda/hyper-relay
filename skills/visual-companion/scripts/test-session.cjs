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
    fn();
    console.log('ok  ' + name);
  } catch (e) {
    failures.push(name + ': ' + e.message);
    console.error('FAIL ' + name + ': ' + e.message);
  }
}

function start(args) {
  const r = spawnSync('bash', [START, '--project-dir', root, ...args], { encoding: 'utf8' });
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
