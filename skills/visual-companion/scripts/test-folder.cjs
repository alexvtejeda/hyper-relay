// Where sessions live: .hyper-relay/companion/, kept out of git through the repo's local
// exclude file, and the one-time move from .superpowers/brainstorm/. Everything runs under
// os.tmpdir(), in repos made here, with git isolated from the owner's own config.
const fs = require('fs');
const net = require('net');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const START = path.join(__dirname, 'start-server.sh');
const STOP = path.join(__dirname, 'stop-server.sh');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vc-folder-'));
const failures = [];
const spawned = [];
const sessions = [];
fs.mkdirSync(path.join(root, 'home'));
const gitEnv = {
  ...process.env, HOME: path.join(root, 'home'), XDG_CONFIG_HOME: path.join(root, 'home'),
  GIT_CONFIG_NOSYSTEM: '1', GIT_CEILING_DIRECTORIES: os.tmpdir(),
};

async function check(name, fn) {
  try {
    await fn();
    console.log('ok  ' + name);
  } catch (e) {
    failures.push(name + ': ' + e.message);
    console.error('FAIL ' + name + ': ' + e.message);
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg || 'assertion failed');
}

function freePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.on('error', reject);
    srv.listen(0, '127.0.0.1', () => {
      const port = srv.address().port;
      srv.close(() => resolve(port));
    });
  });
}

function git(dir, ...args) {
  return spawnSync('git', ['-C', dir, ...args], { env: gitEnv, encoding: 'utf8' });
}

function repo(name) {
  const dir = path.join(root, name);
  spawnSync('git', ['init', '-q', dir], { env: gitEnv });
  return dir;
}

function start(projectDir, session, { cwd } = {}) {
  const r = spawnSync('bash', [START, '--project-dir', projectDir, '--session', session],
    { env: gitEnv, cwd, encoding: 'utf8' });
  const out = (r.stdout || '').trim();
  let info = null;
  try { info = JSON.parse(out); } catch (e) { /* an error line */ }
  if (info && info.state_dir) sessions.push(path.dirname(info.state_dir));
  return { code: r.status, out, info };
}

function stop(info) {
  spawnSync('bash', [STOP, path.dirname(info.state_dir)], { encoding: 'utf8' });
}

const exclude = (dir) => fs.readFileSync(path.join(dir, '.git', 'info', 'exclude'), 'utf8');
const ignored = (dir) => git(dir, 'check-ignore', '-q', '.hyper-relay/companion/').status === 0;

function oldSession(projectDir, name, { port, pid, info }) {
  const d = path.join(projectDir, '.superpowers', 'brainstorm', name);
  fs.mkdirSync(path.join(d, 'content'), { recursive: true });
  fs.mkdirSync(path.join(d, 'state'), { recursive: true });
  fs.writeFileSync(path.join(d, 'content', 'old-screen.html'), '<h2>old</h2>');
  fs.writeFileSync(path.join(d, 'state', 'port'), String(port) + '\n');
  fs.writeFileSync(path.join(d, 'state', 'server.log'), 'old log\n', { mode: 0o644 });
  fs.chmodSync(path.join(d, 'state', 'server.log'), 0o644);
  if (pid !== undefined) fs.writeFileSync(path.join(d, 'state', 'server.pid'), String(pid) + '\n');
  if (info !== undefined) {
    fs.writeFileSync(path.join(d, 'state', 'server-info'), info + '\n');
    fs.chmodSync(path.join(d, 'state', 'server-info'), 0o644);
  }
  return d;
}

const LINE = '/.hyper-relay/companion/';
const count = (text, line) => text.split('\n').filter((l) => l === line).length;

(async () => {
  const R = repo('shop');
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
    const old = oldSession(R, 'legacy', { port, pid: spawnSync('true').pid,
      info: `{"type":"server-started","port":${port},"url":"http://localhost:${port}"}` });
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
    spawned.push(p.pid);
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
    git(R4, '-c', 'user.name=t', '-c', 'user.email=t@example.invalid', 'commit', '-q', '--allow-empty', '-m', 'init');
    const W = path.join(root, 'wt1');
    assert(git(R4, 'worktree', 'add', '-q', W).status === 0, 'worktree add failed');
    const r = start(W, 'wt');
    assert(r.code === 0 && r.info.git_exclude === 'added', r.out);
    assert(count(exclude(R4), LINE) === 1 && ignored(W));
    assert(fs.statSync(path.join(W, '.git')).isFile(), "the worktree's .git file was replaced");
  });

  for (const d of sessions) spawnSync('bash', [STOP, d], { encoding: 'utf8' });
  for (const pid of spawned) {
    try { process.kill(-pid, 'SIGKILL'); } catch (e) { /* gone */ }
  }
  fs.rmSync(root, { recursive: true, force: true });
  if (failures.length) {
    console.error(`\n${failures.length} failing:`);
    failures.forEach((f) => console.error('  - ' + f));
    process.exit(1);
  }
  console.log('\nall folder tests passed');
})();
