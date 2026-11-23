// Drive the example app in a browser without installing packages (Node 22+).
//
// Usage: node web.mjs <chrome|firefox|safari> <command> [args]
//   nav URL                       open URL in the current tab
//   state                         print the E2E event history and button states
//   wait TEXT [COUNT] [SECONDS]   poll state until TEXT occurs COUNT times (default 1, 30 s);
//                                 TEXT is an event (onCaptchaReady) or a button state (Reset=enabled)
//   tap LABEL                     click Execute, Reset, Destroy, or Probe
//   checkbox                      click the SmartCaptcha checkbox
//   click X Y                     click at viewport coordinates
//   shot FILE                     save a screenshot (may show the challenge; never share it unredacted)
//   block [SECONDS]               Chrome only: block SmartCaptcha hosts, reload, and hold the session
//   reload                        Chrome only: reload, bypassing the cache
//   window WIDTH HEIGHT           Chrome only: resize the browser window
//   end                           Safari only: end the WebDriver session
//
// Set E2E_CHROME_TARGET_ID to the run-owned Chrome page ID. Ports can be overridden with
// E2E_CHROME_PORT, E2E_FIREFOX_PORT, or E2E_SAFARI_PORT. Safari keeps its WebDriver
// session ID in $E2E_TMP/safari-session, so set E2E_TMP to <tmp> for Safari.
// Output is limited to the sanitized E2E text, button states, and coordinates.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const PORTS = {
  chrome: process.env.E2E_CHROME_PORT || '9333',
  firefox: process.env.E2E_FIREFOX_PORT || '9334',
  safari: process.env.E2E_SAFARI_PORT || '9335',
};
const LABELS = ['Execute', 'Reset', 'Destroy', 'Probe'];
const BLOCKED_HOSTS = ['*smartcaptcha.cloud.yandex.ru*', '*smartcaptcha.yandexcloud.net*'];

const [, , browser, cmd, ...args] = process.argv;
if (!Object.hasOwn(PORTS, browser) || !cmd) {
  console.error('usage: node web.mjs <chrome|firefox|safari> <command> [args]; see the header comment');
  process.exit(2);
}
const port = PORTS[browser];
if (!/^\d+$/.test(port) || +port < 1 || +port > 65535) throw new Error('invalid browser port');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const timeout = 10000;

// Enables Flutter semantics once, then reads only the E2E text and the button states.
const STATE_JS = `(() => {
  const placeholder = document.querySelector('flt-semantics-placeholder');
  if (placeholder && !document.querySelector('flt-semantics')) placeholder.click();
  const label = (n) => (n.getAttribute('aria-label') || n.textContent || '').trim();
  const nodes = [...document.querySelectorAll('flt-semantics, flt-semantics *')];
  const events = nodes.map(label).find((t) => t.startsWith('E2E:')) || '(no E2E text)';
  const buttons = {};
  for (const b of document.querySelectorAll('[role=button]')) {
    const l = label(b);
    if (${JSON.stringify(LABELS)}.includes(l)) buttons[l] = b.getAttribute('aria-disabled') === 'true' ? 'disabled' : 'enabled';
  }
  // Hidden or occluded pages may stop rendering Flutter frames.
  const warning = document.visibilityState === 'hidden' ? 'page hidden; keep the browser window visible' : undefined;
  return JSON.stringify({ events, buttons, warning });
})()`;

const TAP_JS = (target) => `(() => {
  for (const b of document.querySelectorAll('[role=button]')) {
    if ((b.getAttribute('aria-label') || b.textContent || '').trim() !== ${JSON.stringify(target)}) continue;
    const r = b.getBoundingClientRect();
    return JSON.stringify({ x: r.x + r.width / 2, y: r.y + r.height / 2 });
  }
  return 'null';
})()`;

// Finds the checkbox iframe by size and returns its geometry and frame index, never its src.
const CHECKBOX_JS = `(() => {
  const frames = [...document.querySelectorAll('iframe')];
  const f = frames.find((i) => { const r = i.getBoundingClientRect(); return r.width > 100 && r.height > 50 && r.height < 200; });
  if (!f) return 'null';
  const r = f.getBoundingClientRect();
  const index = [...Array(window.frames.length).keys()].find((k) => window.frames[k] === f.contentWindow);
  return JSON.stringify({ x: r.x + 30, y: r.y + r.height / 2, fx: 30, fy: r.height / 2, index });
})()`;

async function connect(url) {
  const endpoint = new URL(url);
  if (endpoint.protocol !== 'ws:' || endpoint.hostname !== '127.0.0.1' || endpoint.port !== port) {
    throw new Error('browser endpoint is not the selected local port');
  }
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.close(); reject(new Error('browser connection timed out')); }, timeout);
    socket.onopen = () => { clearTimeout(timer); resolve(); };
    socket.onerror = () => { clearTimeout(timer); reject(new Error('browser connection failed')); };
  });
  let id = 0;
  const pending = new Map();
  const rejectPending = () => {
    for (const { reject, timer } of pending.values()) {
      clearTimeout(timer);
      reject(new Error('browser connection closed'));
    }
    pending.clear();
  };
  socket.onclose = rejectPending;
  socket.onerror = rejectPending;
  socket.onmessage = (m) => {
    const data = JSON.parse(m.data);
    const request = pending.get(data.id);
    if (!request) return;
    clearTimeout(request.timer);
    pending.delete(data.id);
    if (data.error) request.reject(new Error(`${request.method} failed`));
    else request.resolve(data);
  };
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const i = ++id;
    const timer = setTimeout(() => {
      pending.delete(i);
      reject(new Error(`${method} timed out`));
    }, timeout);
    pending.set(i, { resolve, reject, timer, method });
    try { socket.send(JSON.stringify({ id: i, method, params })); }
    catch (error) { clearTimeout(timer); pending.delete(i); reject(error); }
  });
  return { send, close: () => socket.close() };
}

const pointer = (x, y, extra = {}) => [{
  type: 'pointer', id: 'mouse', actions: [
    { type: 'pointerMove', x: Math.round(x), y: Math.round(y), ...extra },
    { type: 'pointerDown', button: 0 }, { type: 'pause', duration: 80 }, { type: 'pointerUp', button: 0 },
  ],
}];

async function chrome() {
  const targetId = process.env.E2E_CHROME_TARGET_ID;
  if (!targetId) throw new Error('set E2E_CHROME_TARGET_ID to the run-owned page ID');
  const response = await fetch(`http://127.0.0.1:${port}/json`, { signal: AbortSignal.timeout(timeout) });
  if (!response.ok) throw new Error('Chrome target discovery failed');
  const targets = await response.json();
  const target = targets.find((t) => t.type === 'page' && t.id === targetId);
  if (!target?.webSocketDebuggerUrl) throw new Error('run-owned Chrome page not found');
  const c = await connect(target.webSocketDebuggerUrl);
  const click = async (x, y) => {
    for (const type of ['mousePressed', 'mouseReleased']) {
      await c.send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    }
  };
  const reload = () => c.send('Page.reload', { ignoreCache: true });
  return {
    nav: async (url) => {
      const response = await c.send('Page.navigate', { url });
      if (response.result?.errorText) throw new Error('Page.navigate failed');
    },
    eval: async (expression) => {
      const response = await c.send('Runtime.evaluate', { expression, returnByValue: true });
      if (response.result?.exceptionDetails) throw new Error('Runtime.evaluate failed');
      return response.result?.result?.value;
    },
    shot: async () => (await c.send('Page.captureScreenshot')).result.data,
    click,
    // CDP input reaches cross-origin iframes at viewport coordinates.
    clickCheckbox: (p) => click(p.x, p.y),
    extra: {
      block: async (seconds = '120') => {
        if (!/^\d+$/.test(seconds) || +seconds < 1 || +seconds > 3600) throw new Error('invalid block duration');
        await c.send('Network.enable');
        await c.send('Network.setBlockedURLs', { urls: BLOCKED_HOSTS });
        await reload();
        console.log('blocking');
        await sleep(+seconds * 1000);
      },
      reload,
      // Emulation overrides end with the CDP session; window bounds persist.
      window: async (w, h) => {
        const { windowId } = (await c.send('Browser.getWindowForTarget')).result;
        await c.send('Browser.setWindowBounds', { windowId, bounds: { width: +w, height: +h } });
      },
    },
    close: c.close,
  };
}

async function firefox() {
  const c = await connect(`ws://127.0.0.1:${port}/session`);
  await c.send('session.new', { capabilities: {} });
  const top = async () => {
    const contexts = (await c.send('browsingContext.getTree')).result.contexts;
    if (contexts.length !== 1) throw new Error('expected exactly one run-owned Firefox tab');
    return contexts[0];
  };
  const context = (await top()).context;
  const perform = async (ctx, x, y) => {
    const r = await c.send('input.performActions', { context: ctx, actions: pointer(x, y) });
    return r;
  };
  return {
    nav: (url) => c.send('browsingContext.navigate', { context, url, wait: 'none' }),
    eval: async (expression) => {
      const response = await c.send('script.evaluate', { expression, target: { context }, awaitPromise: false });
      if (response.result?.type === 'exception') throw new Error('script.evaluate failed');
      return response.result?.result?.value;
    },
    shot: async () => (await c.send('browsingContext.captureScreenshot', { context })).result.data,
    click: (x, y) => perform(context, x, y),
    // Top-level pointer actions do not reach the cross-origin iframe, so act inside its browsing context.
    clickCheckbox: async (p) => {
      const child = (await top()).children?.[p.index];
      if (!child) throw new Error('checkbox frame context not found');
      await perform(child.context, p.fx, p.fy);
    },
    extra: {},
    // Ending the session immediately after input cancels the click.
    close: async () => { await sleep(500); await c.send('session.end'); c.close(); },
  };
}

async function safari() {
  if (!process.env.E2E_TMP) throw new Error('set E2E_TMP to <tmp> for Safari');
  const file = path.join(process.env.E2E_TMP, 'safari-session');
  const base = `http://127.0.0.1:${port}`;
  const request = async (method, p, body) => {
    const res = await fetch(base + p, { method, headers: { 'content-type': 'application/json' }, body: body && JSON.stringify(body), signal: AbortSignal.timeout(timeout) });
    const { value } = await res.json();
    if (!res.ok || value?.error) {
      const error = new Error('Safari WebDriver request failed');
      error.invalidSession = value?.error === 'invalid session id';
      throw error;
    }
    return value;
  };
  let sid = fs.existsSync(file) ? fs.readFileSync(file, 'utf8').trim() : null;
  if (!sid && cmd !== 'end') {
    sid = (await request('POST', '/session', { capabilities: { alwaysMatch: { browserName: 'safari' } } })).sessionId;
    fs.writeFileSync(file, sid);
  }
  // safaridriver drops pointer input, and Flutter stops painting, unless Safari is the active app.
  if (sid) {
    execFileSync('osascript', ['-e', 'tell application "Safari" to activate']);
    await sleep(500);
  }
  const click = (x, y) => request('POST', `/session/${sid}/actions`, { actions: pointer(x, y, { origin: 'viewport' }) });
  return {
    nav: (url) => request('POST', `/session/${sid}/url`, { url }),
    eval: (e) => request('POST', `/session/${sid}/execute/sync`, { script: `return ${e};`, args: [] }),
    shot: () => request('GET', `/session/${sid}/screenshot`),
    click,
    clickCheckbox: (p) => click(p.x, p.y),
    extra: {
      end: async () => {
        if (sid) {
          try { await request('DELETE', `/session/${sid}`); }
          catch (error) { if (!error.invalidSession) throw error; }
        }
        fs.rmSync(file, { force: true });
      },
    },
    close: () => {},
  };
}

async function state(d) {
  const raw = JSON.parse(await d.eval(STATE_JS));
  const events = raw.events;
  const allowed = /^(?:called: (?:probe done|onCaptchaReady|onChallengeShown|onChallengeHidden|onTokenExpired|onNetworkError|onJavaScriptError|onNavigationRequest|onChallengeSolved, token non-null: (?:true|false))|Wasm: (?:true|false))$/;
  if (typeof events !== 'string' || (events !== '(no E2E text)' &&
      (!events.startsWith('E2E:') || events.slice(4).trim().split(' | ').some((event) => event && !allowed.test(event))))) {
    throw new Error('invalid event history');
  }
  if (!raw.buttons || typeof raw.buttons !== 'object') throw new Error('invalid button state');
  const buttons = {};
  for (const label of LABELS) {
    if (!(label in raw.buttons)) continue;
    if (!['enabled', 'disabled'].includes(raw.buttons[label])) throw new Error('invalid button state');
    buttons[label] = raw.buttons[label];
  }
  const warning = raw.warning === 'page hidden; keep the browser window visible' ? raw.warning : undefined;
  return { events, buttons, warning };
}

function count(s, text) {
  const haystack = `${s.events} ${Object.entries(s.buttons).map(([k, v]) => `${k}=${v}`).join(' ')}`;
  return haystack.split(text).length - 1;
}

let d;
try {
  d = await { chrome, firefox, safari }[browser]();
} catch (error) {
  console.error(`error: ${error.message}`);
  process.exit(2);
}
let exitCode = 0;
try {
  if (cmd === 'nav') {
    if (!args[0]) throw new Error('URL required');
    await d.nav(args[0]);
    console.log('navigated');
  } else if (cmd === 'state') {
    console.log(JSON.stringify(await state(d)));
  } else if (cmd === 'wait') {
    const [text, min = '1', seconds = '30'] = args;
    const deadline = Date.now() + +seconds * 1000;
    let s = await state(d);
    while (count(s, text) < +min && Date.now() < deadline) {
      await sleep(500);
      s = await state(d);
    }
    const ok = count(s, text) >= +min;
    console.log(`${ok ? 'ok' : 'timeout'}: ${JSON.stringify(s)}`);
    if (!ok) exitCode = 1;
  } else if (cmd === 'tap' || cmd === 'checkbox') {
    await state(d);
    const p = JSON.parse(await d.eval(cmd === 'tap' ? TAP_JS(args[0]) : CHECKBOX_JS));
    const name = cmd === 'tap' ? args[0] : 'checkbox';
    if (!p) {
      console.log(`${name} not found`);
      exitCode = 1;
    } else {
      await (cmd === 'tap' ? d.click(p.x, p.y) : d.clickCheckbox(p));
      console.log(`clicked ${name} at ${Math.round(p.x)},${Math.round(p.y)}`);
    }
  } else if (cmd === 'click') {
    await d.click(+args[0], +args[1]);
    console.log('clicked');
  } else if (cmd === 'shot') {
    fs.writeFileSync(args[0], Buffer.from(await d.shot(), 'base64'));
    console.log('saved');
  } else if (cmd in d.extra) {
    await d.extra[cmd](...args);
    console.log(`${cmd} ok`);
  } else {
    console.error(`unknown command for ${browser}: ${cmd}`);
    exitCode = 2;
  }
} catch (error) {
  console.error(`error: ${error.message}`);
  exitCode = 1;
} finally {
  await d.close();
}
process.exit(exitCode);
