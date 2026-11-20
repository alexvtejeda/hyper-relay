const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// The browser stays in sync via HTTP polling (see helper.js + the /poll route
// below), not WebSockets — the user answers in the terminal, so no live
// bidirectional channel is needed.

// ========== Configuration ==========

const randomPort = () => 49152 + Math.floor(Math.random() * 16383);
const REQUESTED_PORT = Number(process.env.BRAINSTORM_PORT) || null;
const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
const CONTENT_DIR = path.join(SESSION_DIR, 'content');
const STATE_DIR = path.join(SESSION_DIR, 'state');
let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;

const MIME_TYPES = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml'
};

// ========== Templates and Constants ==========

const WAITING_PAGE = `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Brainstorm Companion</title>
<style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
h1 { color: #333; } p { color: #666; }</style>
</head>
<body><h1>Brainstorm Companion</h1>
<p>Waiting for the agent to push a screen...</p></body></html>`;

const FORBIDDEN_PAGE = `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Visual companion</title>
<style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
h1 { color: #333; font-size: 1.4rem; }</style>
</head>
<body><h1>Ask the agent for the full link.</h1></body></html>`;

const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
const helperInjection = '<script>\n' + helperScript + '\n</script>';

// ========== Helper Functions ==========

function isFullDocument(html) {
  const trimmed = html.trimStart().toLowerCase();
  return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
}

function wrapInFrame(content) {
  // A function replacement: a string would read $&, $` and $' in the content as patterns.
  return frameTemplate.replace('<!-- CONTENT -->', () => content);
}

function securityHeaders(extra = {}) {
  return {
    'Cache-Control': 'no-store',
    'Referrer-Policy': 'no-referrer',
    'X-Frame-Options': 'SAMEORIGIN',
    'Content-Security-Policy': "frame-ancestors 'self'",
    'Cross-Origin-Resource-Policy': 'same-origin',
    ...extra
  };
}

// The per-session key. Set in startServer(); the bound port in the 'listening' handler.
let sessionKey = '';
let boundPort = null;

function keyMatches(given) {
  const a = Buffer.from(String(given));
  const b = Buffer.from(sessionKey);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function splitUrl(url) {
  const i = url.indexOf('?');
  return i === -1 ? { pathname: url, query: new URLSearchParams('') }
                  : { pathname: url.slice(0, i), query: new URLSearchParams(url.slice(i + 1)) };
}

function cookieValue(req, name) {
  for (const part of String(req.headers.cookie || '').split(';')) {
    const eq = part.indexOf('=');
    if (eq !== -1 && part.slice(0, eq).trim() === name) return part.slice(eq + 1).trim();
  }
  return null;
}

// A ?key= decides alone, so a wrong one fails even beside a valid cookie.
function isAuthorized(req, query) {
  if (query.has('key')) return keyMatches(query.get('key'));
  const c = cookieValue(req, 'companion-key-' + boundPort);
  return c !== null && keyMatches(c);
}

// The path of a plain file in CONTENT_DIR, or null: not a dotfile, not a link (symbolic or
// hard), not a directory, and really inside CONTENT_DIR.
function servableFile(name) {
  try {
    if (!name || name.startsWith('.')) return null;
    const fp = path.join(CONTENT_DIR, name);
    const st = fs.lstatSync(fp);
    if (!st.isFile() || st.nlink !== 1) return null;
    const real = fs.realpathSync(fp);
    return real.startsWith(fs.realpathSync(CONTENT_DIR) + path.sep) ? fp : null;
  } catch (e) {
    return null;
  }
}

function getNewestScreen() {
  const files = fs.readdirSync(CONTENT_DIR)
    .filter(f => f.endsWith('.html'))
    .map(f => servableFile(f))
    .filter(fp => fp !== null)
    .map(fp => ({ path: fp, mtime: fs.statSync(fp).mtime.getTime() }))
    .sort((a, b) => b.mtime - a.mtime);
  return files.length > 0 ? files[0].path : null;
}

// ========== HTTP Request Handler ==========

function handleRequest(req, res) {
  const { pathname, query } = splitUrl(req.url);
  if (!isAuthorized(req, query)) {
    res.writeHead(403, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
    res.end(FORBIDDEN_PAGE);
    return;
  }
  touchActivity();
  if (req.method === 'GET' && pathname === '/' && query.has('key')) {
    res.writeHead(302, securityHeaders({
      'Location': '/',
      'Set-Cookie': `companion-key-${boundPort}=${query.get('key')}; HttpOnly; SameSite=Strict; Path=/`
    }));
    res.end();
  } else if (req.method === 'GET' && pathname === '/') {
    const screenFile = getNewestScreen();
    let html = screenFile
      ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
      : WAITING_PAGE;

    // Inject before the LAST </body>, never the first. A scene that inlines a
    // real page as a JS string carries an inner </body></html>, and
    // String.replace() with a STRING pattern hits the first match only — the
    // poll script would land inside that literal and corrupt the page, but only
    // as SERVED. The file on disk stays fine, which is what makes this
    // expensive to find: check the served bytes, not the file.
    const bodyClose = html.lastIndexOf('</body>');
    html = bodyClose === -1
      ? html + helperInjection
      : html.slice(0, bodyClose) + helperInjection + '\n' + html.slice(bodyClose);

    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
    res.end(html);
  } else if (req.method === 'GET' && pathname === '/poll') {
    // Reload signal for the browser: newest screen's filename + mtime.
    // The client reloads when either changes (see helper.js).
    const screenFile = getNewestScreen();
    const stamp = screenFile
      ? { file: path.basename(screenFile), mtime: fs.statSync(screenFile).mtime.getTime() }
      : { file: null, mtime: 0 };
    res.writeHead(200, securityHeaders({ 'Content-Type': 'application/json' }));
    res.end(JSON.stringify(stamp));
  } else if (req.method === 'GET' && pathname.startsWith('/files/')) {
    const filePath = servableFile(path.basename(pathname.slice(7)));
    if (!filePath) {
      res.writeHead(404, securityHeaders());
      res.end('Not found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, securityHeaders({ 'Content-Type': contentType }));
    res.end(fs.readFileSync(filePath));
  } else {
    res.writeHead(404, securityHeaders());
    res.end('Not found');
  }
}

function safeHandleRequest(req, res) {
  try {
    handleRequest(req, res);
  } catch (e) {
    console.error(JSON.stringify({ type: 'request-error', error: e.message }));
    if (!res.headersSent) res.writeHead(500, securityHeaders({ 'Content-Type': 'text/plain' }));
    res.end('Server error');
  }
}

// ========== Activity Tracking ==========

// While the session that started the server runs, it never idles out. Only when that
// session is unknown (no owner pid) does it stop after IDLE_TIMEOUT_MS without activity.
const positiveMs = (v, fallback) => (Number.isFinite(Number(v)) && Number(v) > 0 ? Number(v) : fallback);
const IDLE_TIMEOUT_MS = positiveMs(process.env.BRAINSTORM_IDLE_TIMEOUT_MS, 4 * 60 * 60 * 1000);
const LIFECYCLE_CHECK_MS = positiveMs(process.env.BRAINSTORM_LIFECYCLE_CHECK_MS, 60 * 1000);
let lastActivity = Date.now();

function touchActivity() {
  lastActivity = Date.now();
}

// ========== File Watching ==========

const debounceTimers = new Map();

// ========== Server Startup ==========

function startServer() {
  if (!fs.existsSync(CONTENT_DIR)) fs.mkdirSync(CONTENT_DIR, { recursive: true });
  if (!fs.existsSync(STATE_DIR)) fs.mkdirSync(STATE_DIR, { recursive: true });

  // The key: BRAINSTORM_TOKEN as given (never written), else the one in state/token, else a
  // new one. A restart keeps it, so the user's link keeps working.
  const tokenFile = path.join(STATE_DIR, 'token');
  if (process.env.BRAINSTORM_TOKEN) {
    sessionKey = process.env.BRAINSTORM_TOKEN;
  } else {
    let saved = '';
    try { saved = fs.readFileSync(tokenFile, 'utf-8').trim(); } catch (e) {}
    if (/^[0-9a-f]{64}$/.test(saved)) {
      sessionKey = saved;
    } else {
      sessionKey = crypto.randomBytes(32).toString('hex');
      fs.writeFileSync(tokenFile, sessionKey + '\n', { mode: 0o600 });
    }
    fs.chmodSync(tokenFile, 0o600);
  }

  // Track known files to distinguish new screens from updates.
  // macOS fs.watch reports 'rename' for both new files and overwrites,
  // so we can't rely on eventType alone.
  const knownFiles = new Set(
    fs.readdirSync(CONTENT_DIR).filter(f => f.endsWith('.html'))
  );

  const server = http.createServer(safeHandleRequest);

  const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
    if (!filename || filename.startsWith('.') || !filename.endsWith('.html')) return;

    if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
    debounceTimers.set(filename, setTimeout(() => {
      debounceTimers.delete(filename);
      const filePath = path.join(CONTENT_DIR, filename);

      if (!fs.existsSync(filePath)) return; // file was deleted
      touchActivity();

      if (!knownFiles.has(filename)) {
        knownFiles.add(filename);
        console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
      } else {
        console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
      }
      // The browser picks this up on its next /poll — no push needed.
    }, 100));
  });
  watcher.on('error', (err) => console.error('fs.watch error:', err.message));

  let shuttingDown = false;
  function shutdown(reason) {
    if (shuttingDown) return;   // SIGTERM twice, or a signal during the idle check
    shuttingDown = true;
    console.log(JSON.stringify({ type: 'server-stopped', reason }));
    const infoFile = path.join(STATE_DIR, 'server-info');
    if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
    fs.writeFileSync(
      path.join(STATE_DIR, 'server-stopped'),
      JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
    );
    watcher.close();
    clearInterval(lifecycleCheck);
    server.close(() => process.exit(0));
    // helper.js polls every second, so a keep-alive socket can hold server.close() open
    // past the moment stop-server.sh escalates to SIGKILL. Exit anyway.
    setTimeout(() => process.exit(0), 1000).unref();
  }

  function ownerAlive() {
    if (!ownerPid) return true;
    try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
  }

  // With an owner: exit when it is gone, never for idleness. Without one: exit after
  // IDLE_TIMEOUT_MS with no activity.
  const lifecycleCheck = setInterval(() => {
    if (ownerPid) {
      if (!ownerAlive()) shutdown('owner process exited');
    } else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) {
      shutdown('idle timeout');
    }
  }, LIFECYCLE_CHECK_MS);
  lifecycleCheck.unref();

  // Without these, stop-server.sh's plain `kill` terminates node before shutdown() runs:
  // server-info is left behind claiming a live server, and every liveness check reads a lie.
  process.on('SIGTERM', () => shutdown('stopped by signal'));
  process.on('SIGINT', () => shutdown('stopped by signal'));

  // Validate owner PID at startup. If it's already dead, the PID resolution
  // was wrong (common on WSL, Tailscale SSH, and cross-user scenarios).
  // Disable monitoring and rely on the idle timeout instead (server-info says which).
  if (ownerPid) {
    try { process.kill(ownerPid, 0); }
    catch (e) {
      if (e.code !== 'EPERM') {
        console.log(JSON.stringify({ type: 'owner-pid-invalid', pid: ownerPid, reason: 'dead at startup' }));
        ownerPid = null;
      }
    }
  }

  // A remembered port keeps the URL stable across restarts. If something else took it in
  // the meantime, fall back to a random one rather than dying — a changed URL is an
  // inconvenience, a dead server is a lost session.
  let port = REQUESTED_PORT || randomPort();
  let retries = 0;

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE' && retries < 10) {
      retries += 1;
      port = randomPort();
      server.listen(port, HOST);
      return;
    }
    console.error(JSON.stringify({ type: 'server-error', error: err.message }));
    process.exit(1);
  });

  // 'listening' rather than the listen() callback, so this fires again after a retry.
  server.on('listening', () => {
    boundPort = Number(port);
    const info = JSON.stringify({
      type: 'server-started', port: Number(port), host: HOST,
      url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + port + '/?key=' + sessionKey,
      screen_dir: CONTENT_DIR, state_dir: STATE_DIR,
      owner_pid: ownerPid, idle_timeout_ms: ownerPid ? null : IDLE_TIMEOUT_MS
    });
    console.log(info);
    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n', { mode: 0o600 });
    fs.writeFileSync(path.join(STATE_DIR, 'port'), String(port) + '\n');
  });

  server.listen(port, HOST);
}

if (require.main === module) {
  startServer();
}

module.exports = { startServer };
