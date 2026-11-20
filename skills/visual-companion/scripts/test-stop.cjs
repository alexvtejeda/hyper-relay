// stop-server.sh and start-server.sh prove a pid is their own server by its instance id.
// Every folder is under os.tmpdir(); only processes this test starts are ever signalled.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const START = path.join(__dirname, 'start-server.sh');
const STOP = path.join(__dirname, 'stop-server.sh');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vc-stop-'));
const failures = [];
const spawned = [];
const sessions = [];
const stateDirs = {};   // session name -> its state dir, as the start script printed it
const ENV = { ...process.env, GIT_CEILING_DIRECTORIES: os.tmpdir() };
const hasProc = fs.existsSync('/proc/self/cmdline');

async function check(name, fn) {
  try {
    const r = await fn();
    console.log('ok  ' + name + (r === 'skip-proc' ? ' (skipped: no /proc)' : ''));
  } catch (e) {
    failures.push(name + ': ' + e.message);
    console.error('FAIL ' + name + ': ' + e.message);
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg || 'assertion failed');
}

let n = 0;
function fakeSession({ pid, id, info }) {
  const dir = path.join(root, 'fake-' + (n++));
  const st = path.join(dir, 'state');
  fs.mkdirSync(st, { recursive: true });
  if (pid !== undefined) fs.writeFileSync(path.join(st, 'server.pid'), String(pid) + '\n');
  if (id !== undefined) fs.writeFileSync(path.join(st, 'server-instance-id'), id + '\n');
  if (info !== undefined) fs.writeFileSync(path.join(st, 'server-info'), info + '\n');
  return dir;
}

function impostor(id) {
  const p = spawn('bash', ['-c', 'sleep 30; :', 'impostor', '--companion-id=' + id],
    { detached: true, stdio: 'ignore' });
  spawned.push(p.pid);
  return p;
}

function detachedSleep() {
  const p = spawn('sleep', ['30'], { detached: true, stdio: 'ignore' });
  spawned.push(p.pid);
  return p;
}

function stop(dir) {
  const r = spawnSync('bash', [STOP, dir], { encoding: 'utf8' });
  return { code: r.status, out: (r.stdout || '').trim() };
}

function start(session) {
  const r = spawnSync('bash', [START, '--project-dir', root, '--session', session], { encoding: 'utf8', env: ENV });
  const out = (r.stdout || '').trim();
  try { stateDirs[session] = JSON.parse(out).state_dir || stateDirs[session]; } catch (e) { /* an error line */ }
  if (stateDirs[session] && !sessions.includes(path.dirname(stateDirs[session]))) {
    sessions.push(path.dirname(stateDirs[session]));
  }
  return { code: r.status, out };
}

function alive(pid) {
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
}

function exited(proc, ms) {
  if (proc.exitCode !== null || proc.signalCode !== null) return Promise.resolve(true);
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(false), ms);
    proc.once('exit', () => { clearTimeout(timer); resolve(true); });
  });
}

const ID_A = 'a1'.repeat(24), ID_B = 'b2'.repeat(24);
const OLD = '{"type":"server-started","port":1,"url":"http://localhost:1"}';
const stateOf = (session) => stateDirs[session];

(async () => {
  await check('no PID file: not_running', () => {
    assert(JSON.parse(stop(fakeSession({})).out).status === 'not_running');
  });
  await check('a reused PID that is not ours is not signalled', () => {
    const p = detachedSleep();
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
    const st = stateOf('real');
    const p = impostor(ID_B);
    fs.writeFileSync(path.join(st, 'server.pid'), p.pid + '\n');
    fs.writeFileSync(path.join(st, 'server-instance-id'), ID_A + '\n');
    fs.writeFileSync(path.join(st, 'server-info'), OLD + '\n');
    const info = JSON.parse(start('real').out);
    assert(info.type === 'server-started' && info.url !== 'http://localhost:1', JSON.stringify(info));
    assert(fs.readFileSync(path.join(info.state_dir, 'server.pid'), 'utf8').trim() !== String(p.pid) && alive(p.pid));
    stop(path.dirname(info.state_dir));
  });
  await check('a server an old script started counts as running, and is never signalled', () => {
    const st = stateOf('real'), d = path.dirname(st);
    const p = detachedSleep();
    fs.rmSync(path.join(st, 'server-instance-id'), { force: true });
    fs.rmSync(path.join(st, 'server-stopped'), { force: true });
    fs.writeFileSync(path.join(st, 'server.pid'), p.pid + '\n');
    fs.writeFileSync(path.join(st, 'server-info'), OLD + '\n');
    assert(start('real').out === OLD);
    assert(fs.readFileSync(path.join(st, 'server.pid'), 'utf8').trim() === String(p.pid));
    assert(stop(d).out === '{"status":"stale_pid"}' && alive(p.pid));
  });
  await check("foreground mode records node's own PID", async () => {
    if (!hasProc) return 'skip-proc';
    const child = spawn('bash', [START, '--project-dir', root, '--session', 'fg', '--foreground'],
      { stdio: ['ignore', 'pipe', 'ignore'], env: ENV });
    const info = await new Promise((resolve, reject) => {
      let buf = '';
      const timer = setTimeout(() => reject(new Error('no server-started line in 5 s')), 5000);
      child.stdout.on('data', (d) => {
        buf += d;
        for (const line of buf.split('\n')) {
          try {
            const j = JSON.parse(line);
            if (j.type === 'server-started') { clearTimeout(timer); resolve(j); return; }
          } catch (e) { /* partial line */ }
        }
      });
    });
    sessions.push(path.dirname(info.state_dir));
    assert(fs.readFileSync(path.join(info.state_dir, 'server.pid'), 'utf8').trim() === String(child.pid), 'pid file ' + fs.readFileSync(path.join(info.state_dir, 'server.pid'), 'utf8') + ' child ' + child.pid);
    const id = fs.readFileSync(path.join(info.state_dir, 'server-instance-id'), 'utf8').trim();
    const args = fs.readFileSync(`/proc/${child.pid}/cmdline`, 'utf8').split('\0');
    assert(args.includes('--companion-id=' + id), args.join(' '));
    // Async: node is this test's own child, and a zombie stays "alive" to kill -0 until this
    // process reaps it, which it cannot do while blocked in a spawnSync.
    const so = await new Promise((resolve) => {
      let buf = '';
      const p = spawn('bash', [STOP, path.dirname(info.state_dir)]);
      p.stdout.on('data', (d) => { buf += d; });
      p.on('close', () => resolve(buf.trim()));
    });
    assert(JSON.parse(so).status === 'stopped', so);
    assert(await exited(child, 3000), 'node outlived the stop');
  });

  for (const s of sessions) stop(s);
  for (const pid of spawned) {
    try { process.kill(-pid, 'SIGKILL'); } catch (e) { /* gone */ }
    try { process.kill(pid, 'SIGKILL'); } catch (e) { /* gone */ }
  }
  fs.rmSync(root, { recursive: true, force: true });
  if (failures.length) {
    console.error(`\n${failures.length} failing:`);
    failures.forEach((f) => console.error('  - ' + f));
    process.exit(1);
  }
  console.log('\nall stop tests passed');
})();
