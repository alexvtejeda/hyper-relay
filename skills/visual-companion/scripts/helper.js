(function() {
  // The user answers in the terminal, not the browser — so there is no click
  // capture and no WebSocket. The only job here is to keep the page in sync
  // with the newest screen the agent writes: poll /poll, reload on change.
  //
  // The page also says when it cannot get a new screen, in one notice laid over the last
  // one: "Ask the agent for the full link." when the server refuses (403: the tab has no
  // key), and "Paused — the agent will bring it back." after 5 failed polls in a row (the
  // server has stopped). The first good poll after a notice reloads the page.
  const POLL_MS = 1000;
  const FAILURES_BEFORE_PAUSED = 5;
  const NOTICE_STYLE = 'position:fixed;top:0;left:0;right:0;z-index:2147483647;margin:0;padding:12px 16px;background:#92400e;color:#fff;font:600 15px/1.4 system-ui,sans-serif;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.3)';
  let current = null;
  let failures = 0;

  function showNotice(text) {
    let el = document.getElementById('companion-notice');
    if (el === null) {
      el = document.createElement('div');
      el.id = 'companion-notice';
      el.style.cssText = NOTICE_STYLE;
      document.body.appendChild(el);
    }
    el.textContent = text;
  }

  function failed() {
    failures += 1;
    if (failures >= FAILURES_BEFORE_PAUSED) showNotice('Paused — the agent will bring it back.');
  }

  async function poll() {
    try {
      const res = await fetch('/poll', { cache: 'no-store' });
      if (res.status === 403) {
        showNotice('Ask the agent for the full link.');
        return;
      }
      if (!res.ok) {
        failed();
        return;
      }
      const stamp = await res.json();
      failures = 0;
      if (document.getElementById('companion-notice') !== null) {
        window.location.reload();
        return;
      }
      const signature = stamp.file + '@' + stamp.mtime;
      if (current === null) {
        current = signature;
      } else if (signature !== current) {
        window.location.reload();
      }
    } catch (e) {
      failed();
    }
  }

  setInterval(poll, POLL_MS);
  poll();
})();
