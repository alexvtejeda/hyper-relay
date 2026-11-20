// Behaviour of server.cjs on its own: the key, the headers, safe file serving, the lifetime.
// Every server here runs under os.tmpdir() and is killed at the end.
const fs = require('fs');
const net = require('net');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn, spawnSync } = require('child_process');

const SERVER = path.join(__dirname, 'server.cjs');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vc-server-'));
const failures = [];
const procs = [];

async function check(name, fn) {
  try {
    const r = await fn();
    console.log('ok  ' + name + (r === 'skip-root' ? ' (skipped: root)' : ''));
  } catch (e) {
    failures.push(name + ': ' + e.message);
    console.error('FAIL ' + name + ': ' + e.message);
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg || 'assertion failed');
}

let n = 0;
function newSession() {
  const dir = path.join(root, 'session-' + (n++));
  fs.mkdirSync(path.join(dir, 'content'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'state'), { recursive: true });
  return dir;
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

async function serve(dir, env = {}) {
  const port = env.BRAINSTORM_PORT || String(await freePort());
  const proc = spawn('node', [SERVER], {
    env: { ...process.env, BRAINSTORM_DIR: dir, BRAINSTORM_PORT: port, BRAINSTORM_OWNER_PID: '', ...env },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  procs.push(proc);
  const info = await new Promise((resolve, reject) => {
    let buf = '';
    const timer = setTimeout(() => reject(new Error('no server-started line in 5 s')), 5000);
    proc.on('exit', () => { clearTimeout(timer); reject(new Error('server exited early')); });
    proc.stdout.on('data', (d) => {
      buf += d;
      for (const line of buf.split('\n')) {
        try {
          const j = JSON.parse(line);
          if (j.type === 'server-started') { clearTimeout(timer); resolve(j); return; }
        } catch (e) { /* partial line */ }
      }
    });
  });
  return { proc, dir, info };
}

async function get(s, p, { cookie } = {}) {
  const r = await fetch('http://127.0.0.1:' + s.info.port + p, {
    redirect: 'manual', headers: cookie ? { cookie } : {},
  });
  return { status: r.status, headers: r.headers, body: await r.text() };
}

function exited(proc, ms) {
  if (proc.exitCode !== null || proc.signalCode !== null) return Promise.resolve(true);
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(false), ms);
    proc.once('exit', () => { clearTimeout(timer); resolve(true); });
  });
}

// A raw request: fetch would normalise /files/.. to / before sending it.
function rawStatus(s, p, cookie) {
  return new Promise((resolve, reject) => {
    http.get({ host: '127.0.0.1', port: s.info.port, path: p, headers: { cookie } }, (res) => {
      res.resume();
      res.on('end', () => resolve(res.statusCode));
    }).on('error', reject);
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const stopped = (t) => JSON.parse(fs.readFileSync(path.join(t.dir, 'state', 'server-stopped'), 'utf8'));

(async () => {
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
  const now = Date.now() / 1000;
  fs.utimesSync(path.join(c, 'inner.html'), now - 60, now - 60);
  fs.utimesSync(path.join(c, 'screen.html'), now, now);
  fs.utimesSync(path.join(c, '.hidden.html'), now + 60, now + 60);
  fs.utimesSync(path.join(c, 'dir.html'), now + 60, now + 60);
  fs.lutimesSync(path.join(c, 'dangling.html'), now + 60, now + 60);
  const s = await serve(S, { BRAINSTORM_TOKEN: K });
  const C = `companion-key-${s.info.port}=${K}`;

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
    assert((await rawStatus(s, '/files/..', C)) === 404);
    assert((await get(s, '/poll', { cookie: C })).status === 200);
  });
  await check('a symlink and a hard link pointing outside are not served', async () => {
    for (const f of ['link.txt', 'hard.txt']) {
      const r = await get(s, '/files/' + f, { cookie: C });
      assert(r.status === 404 && !r.body.includes('outside secret'), f + ': status ' + r.status);
    }
  });
  await check('a directory and a dangling link named x.html are skipped', async () => {
    for (const f of ['dir.html', 'dangling.html']) {
      assert((await get(s, '/files/' + f, { cookie: C })).status === 404, f);
    }
    assert((await get(s, '/', { cookie: C })).body.includes('<h2>Secret screen</h2>'));
  });
  await check("$&, $` and $' in a fragment come out as written", async () => {
    const frag = "<p>A $& B $` C $' D</p>";
    const f = path.join(c, 'dollar.html');
    fs.writeFileSync(f, frag);
    fs.utimesSync(f, now + 120, now + 120);                          // the newest
    assert((await get(s, '/', { cookie: C })).body.includes(frag));
  });
  await check('an unreadable screen answers 500, and the server keeps answering', async () => {
    if (process.getuid && process.getuid() === 0) return 'skip-root';
    const f = path.join(c, 'locked.html');
    fs.writeFileSync(f, '<p>x</p>');
    fs.utimesSync(f, now + 180, now + 180);
    fs.chmodSync(f, 0);
    const r = await get(s, '/', { cookie: C });
    assert(r.status === 500 && r.headers.get('x-frame-options') === 'SAMEORIGIN', 'status ' + r.status);
    assert((await get(s, '/poll', { cookie: C })).status === 200);
    fs.chmodSync(f, 0o644);
  });

  // ---- the key's own checks ----
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
    const d = newSession(), t = await serve(d, {});
    const key = fs.readFileSync(path.join(d, 'state', 'token'), 'utf8').trim();
    t.proc.kill('SIGTERM');
    assert(await exited(t.proc, 3000), 'did not stop');
    const port = t.info.port;
    const holder = net.createServer();
    await new Promise((r) => holder.listen(port, '127.0.0.1', r));
    try {
      const t2 = await serve(d, { BRAINSTORM_PORT: String(port) });
      assert(t2.info.port !== port, 'bound the taken port');
      assert(t2.info.url === `http://localhost:${t2.info.port}/?key=${key}`, t2.info.url);
      assert(fs.readFileSync(path.join(d, 'state', 'token'), 'utf8').trim() === key, 'state/token changed');
    } finally {
      holder.close();
    }
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

  // LIFETIME-SECTION

  for (const p of procs) { try { p.kill('SIGKILL'); } catch (e) { /* gone */ } }
  fs.rmSync(root, { recursive: true, force: true });
  if (failures.length) {
    console.error(`\n${failures.length} failing:`);
    failures.forEach((f) => console.error('  - ' + f));
    process.exit(1);
  }
  console.log('\nall server tests passed');
})();
