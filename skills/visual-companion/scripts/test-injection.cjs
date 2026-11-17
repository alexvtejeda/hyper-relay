// Regression: a screen that inlines a full HTML page as a JS string contains an INNER
// </body></html>. The poll script must be injected before the LAST </body>, not the first,
// or it lands inside the literal and corrupts the page — but only as SERVED. The file on
// disk stays fine, which is what made this expensive to find the first time.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const SCRIPTS = __dirname;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vc-inject-'));
fs.mkdirSync(path.join(dir, 'content'), { recursive: true });
fs.mkdirSync(path.join(dir, 'state'), { recursive: true });

const screen = `<!DOCTYPE html>
<html><head><title>scene</title></head>
<body>
<div id="stage"></div>
<script>
const PAGE_HTML = \`<!DOCTYPE html>
<html><head><title>Sign in</title></head>
<body><form id="login"><input name="pw"></form>SENTINEL_INNER_INTACT</body></html>\`;
document.getElementById('stage').innerHTML = PAGE_HTML;
</script>
</body>
</html>
`;
fs.writeFileSync(path.join(dir, 'content', 'scene.html'), screen);

const PORT = 41999;
const srv = spawn('node', [path.join(SCRIPTS, 'server.cjs')], {
  env: { ...process.env, BRAINSTORM_DIR: dir, BRAINSTORM_PORT: String(PORT), BRAINSTORM_OWNER_PID: '' },
  stdio: ['ignore', 'pipe', 'pipe'],
});

function done(code) {
  try { srv.kill('SIGKILL'); } catch (e) {}
  fs.rmSync(dir, { recursive: true, force: true });
  process.exit(code);
}

setTimeout(async () => {
  const fail = [];
  let served;
  try {
    served = await (await fetch(`http://127.0.0.1:${PORT}/`)).text();
  } catch (e) {
    console.error('FAIL: could not reach server:', e.message);
    return done(1);
  }
  const inj = served.indexOf('const POLL_MS');
  const firstBody = served.indexOf('</body>');
  const lastBody = served.lastIndexOf('</body>');

  if (inj === -1) fail.push('helper script was not injected at all');
  if (firstBody === lastBody) fail.push('fixture is wrong: only one </body> in served bytes');
  if (inj !== -1 && inj < firstBody) fail.push('injection landed before the FIRST </body> (inside the JS string)');
  if (inj !== -1 && inj > lastBody) fail.push('injection landed after the LAST </body>');
  if (!served.includes('SENTINEL_INNER_INTACT</body></html>`')) {
    fail.push('the embedded page string literal was broken by the injection');
  }

  if (fail.length) {
    console.error('FAIL test-injection:');
    fail.forEach((f) => console.error('  - ' + f));
    return done(1);
  }
  console.log('ok  test-injection: poll script lands before the last </body>');
  done(0);
}, 700);
