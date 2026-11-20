// helper.js in a fake browser: when it shows its notices, and when it reloads.
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const SOURCE = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf8');
const failures = [];

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

const ok = (file, mtime) => ({ ok: true, status: 200, json: async () => ({ file, mtime }) });

async function loadHelper(responses) {
  const queue = responses.slice();
  let tickFn = null;
  let reloadCount = 0;
  const elements = {};
  const context = {
    fetch: async () => {
      const next = queue.shift();
      if (next === 'down') throw new Error('connection refused');
      if (typeof next === 'number') return { ok: false, status: next };
      return next;
    },
    setInterval: (fn) => { tickFn = fn; },
    document: {
      getElementById: (id) => elements[id] || null,
      createElement: (tag) => ({ tag, id: '', textContent: '', style: { cssText: '' } }),
      body: { appendChild: (el) => { elements[el.id] = el; } },
    },
    window: { location: { reload() { reloadCount += 1; } } },
    console,
  };
  vm.runInNewContext(SOURCE, context);
  await new Promise((r) => setImmediate(r));        // the poll helper.js runs at load
  return {
    tick: async () => { await tickFn(); },
    notice: () => elements['companion-notice'] || null,
    reloads: () => reloadCount,
  };
}

const PAUSED = 'Paused — the agent will bring it back.';
const KEY = 'Ask the agent for the full link.';

(async () => {
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

  if (failures.length) {
    console.error(`\n${failures.length} failing:`);
    failures.forEach((f) => console.error('  - ' + f));
    process.exit(1);
  }
  console.log('\nall helper tests passed');
})();
