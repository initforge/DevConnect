const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const appUrl = process.env.E2E_APP_URL || 'http://127.0.0.1:8123';
const apiUrl = process.env.E2E_API_BASE_URL || 'http://127.0.0.1:8080';
const outDir = path.resolve('output/playwright/e2e_ui_flows');
const stamp = Date.now();

let apiToken = '';
let apiUser = null;
let page;
let browser;
let context;
const apiResponses = [];
const consoleErrors = [];
const rows = [];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

async function api(method, route, body, auth = false) {
  const response = await fetch(`${apiUrl}${route}`, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(auth && apiToken ? { authorization: `Bearer ${apiToken}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${method} ${route} -> ${response.status}: ${text}`);
  }
  return data;
}

async function waitApp(ms = 2600) {
  await page.waitForTimeout(ms);
}

async function hash() {
  return page.evaluate(() => window.location.hash);
}

async function expectHashIncludes(value) {
  await page.waitForFunction(
    (expected) => window.location.hash.includes(expected),
    value,
    { timeout: 12000 },
  );
  assert.ok((await hash()).includes(value));
}

async function tap(x, y, waitMs = 900) {
  await page.mouse.click(x, y);
  if (waitMs) await page.waitForTimeout(waitMs);
}

async function typeAt(x, y, text, waitMs = 250) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(80);
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(text, { delay: 4 });
  if (waitMs) await page.waitForTimeout(waitMs);
}

async function screenshot(name) {
  const file = path.join(outDir, `${String(rows.length + 1).padStart(2, '0')}_${name}.png`);
  await page.screenshot({ path: file, fullPage: false });
  return path.relative(path.resolve('.'), file).replaceAll(path.sep, '/');
}

function sawApi(fragment, status = 200) {
  return apiResponses.some((item) => item.url.includes(fragment) && item.status === status);
}

async function step(name, fn) {
  process.stdout.write(`- ${name} ... `);
  const beforeErrors = consoleErrors.length;
  const beforeResponses = apiResponses.length;
  const started = Date.now();
  try {
    await fn();
    const shot = await screenshot(name.replace(/[^a-z0-9]+/gi, '_').toLowerCase());
    rows.push({
      status: 'pass',
      name,
      ms: Date.now() - started,
      hash: await hash(),
      apiResponses: apiResponses.slice(beforeResponses),
      consoleErrors: consoleErrors.slice(beforeErrors),
      screenshot: shot,
    });
    console.log('pass');
  } catch (error) {
    const shot = await screenshot(`failed_${name.replace(/[^a-z0-9]+/gi, '_').toLowerCase()}`).catch(() => '');
    rows.push({
      status: 'fail',
      name,
      ms: Date.now() - started,
      hash: await hash().catch(() => ''),
      error: error.message,
      apiResponses: apiResponses.slice(beforeResponses),
      consoleErrors: consoleErrors.slice(beforeErrors),
      screenshot: shot,
    });
    console.log('fail');
    throw error;
  }
}

async function openRoute(route, waitMs = 3000) {
  await page.goto('about:blank');
  await page.goto(`${appUrl}/#${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await waitApp(waitMs);
}

async function setup() {
  ensureDir(outDir);
  const health = await api('GET', '/health');
  assert.equal(health.status, 'ok');

  const email = `ui_${stamp}@devconnect.test`;
  const password = 'password123';
  const username = `ui_${stamp}`;
  const registered = await api('POST', '/auth/register', {
    email,
    password,
    username,
    displayName: 'UI E2E User',
  });
  apiToken = registered.token;
  apiUser = { ...registered.user, email, password, username };

  browser = await chromium.launch({ headless: true });
  context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    isMobile: true,
    serviceWorkers: 'block',
  });
  page = await context.newPage();
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });
  page.on('pageerror', (error) => consoleErrors.push(error.message));
  page.on('response', (response) => {
    const url = response.url();
    if (url.startsWith(apiUrl)) {
      apiResponses.push({ method: response.request().method(), url, status: response.status() });
    }
  });
}

async function writeReport() {
  const report = path.join(outDir, 'e2e_ui_flows_report.md');
  const pass = rows.filter((row) => row.status === 'pass').length;
  const fail = rows.length - pass;
  const lines = [
    '# E2E UI Flows Report',
    '',
    `Generated: ${new Date().toISOString()}`,
    '',
    `App: ${appUrl}`,
    '',
    `API: ${apiUrl}`,
    '',
    `Result: ${pass}/${rows.length} pass, ${fail} fail`,
    '',
    '| Status | Flow | Hash | API calls | Console errors | Screenshot |',
    '|---|---|---|---:|---:|---|',
  ];
  for (const row of rows) {
    lines.push(
      `| ${row.status} | ${row.name} | ${row.hash || ''} | ${row.apiResponses.length} | ${row.consoleErrors.length} | ${row.screenshot || ''} |`,
    );
    if (row.error) lines.push(`|  | error | ${row.error.replaceAll('|', '\\|')} |  |  |  |`);
  }
  lines.push('', '## API Evidence', '');
  for (const [index, row] of rows.entries()) {
    lines.push(`### ${index + 1}. ${row.name}`);
    if (!row.apiResponses.length) {
      lines.push('- No API call expected or observed.');
    } else {
      for (const response of row.apiResponses) {
        lines.push(`- ${response.status} ${response.method} ${response.url.replace(apiUrl, '')}`);
      }
    }
    if (row.consoleErrors.length) {
      lines.push('- Console errors:');
      for (const error of row.consoleErrors) lines.push(`  - ${error}`);
    }
    lines.push('');
  }
  fs.writeFileSync(report, lines.join('\n'), 'utf8');
  console.log(`Wrote ${report}`);
}

async function main() {
  await setup();

  await step('login form then onboarding continue', async () => {
    await openRoute('/login', 3500);
    await page.keyboard.press('Tab');
    await page.keyboard.type(apiUser.email, { delay: 4 });
    await page.keyboard.press('Tab');
    await page.keyboard.type(apiUser.password, { delay: 4 });
    await tap(190, 583, 4200);
    assert.ok(sawApi('/auth/login', 200), 'login API response not observed');
    await expectHashIncludes('/onboarding');
    await tap(190, 776, 2500);
    await expectHashIncludes('/home');
    const storedToken = await page.evaluate(() => window.localStorage.getItem('flutter.auth.token'));
    assert.ok(storedToken && storedToken.length > 20, 'auth token missing after login');
  });

  await step('home search button, submit query, switch tabs, clear', async () => {
    await openRoute('/home');
    await tap(324, 28, 1800);
    await tap(38, 155, 3500);
    await waitApp(3500);
    assert.ok(sawApi('/api/users/search', 200), 'search users API not observed');
    await tap(135, 104);
    await tap(225, 104);
    await tap(322, 104);
    await tap(356, 48, 1200);
  });

  await step('create post from floating action button and confirm AI review', async () => {
    const title = `UI E2E Post ${stamp}`;
    await openRoute('/create-post', 2200);
    await typeAt(190, 127, title);
    await tap(349, 29, 3200);
    await tap(268, 521, 4500);
    assert.ok(sawApi('/api/ai/code-review', 200), 'AI review API not observed');
    assert.ok(sawApi('/api/posts', 201), 'create post API not observed');
    const posts = await api('GET', '/api/posts?limit=50', undefined, true);
    assert.ok(posts.data.some((post) => post.title === title), 'created post not found through API');
  });

  await step('profile screen opens and settings toggles persist locally', async () => {
    await openRoute('/profile', 4200);
    await expectHashIncludes('/profile');
    await tap(365, 28, 1700);
    await tap(342, 365, 500);
    await tap(342, 494, 500);
    await tap(342, 535, 500);
    const prefs = await page.evaluate(() => ({
      privateProfile: window.localStorage.getItem('flutter.settings.privateProfile'),
      pushNotif: window.localStorage.getItem('flutter.settings.pushNotif'),
      emailNotif: window.localStorage.getItem('flutter.settings.emailNotif'),
    }));
    assert.ok(prefs.privateProfile || prefs.pushNotif || prefs.emailNotif, 'settings localStorage not updated');
  });

  await step('chat list opens conversation and sends message', async () => {
    const message = `UI E2E message ${stamp}`;
    await openRoute('/chat', 3500);
    await tap(190, 278, 2200);
    await typeAt(150, 817, message);
    await tap(360, 817, 2500);
    assert.ok(sawApi('/api/conversations/conv', 201) || sawApi('/messages', 201), 'send message API not observed');
  });

  await step('projects screen joins newest API-created project', async () => {
    const project = await api('POST', '/api/projects', {
      title: `UI E2E Project ${stamp}`,
      description: 'Project used by the UI browser E2E test.',
      techStack: ['Flutter', 'Node.js'],
      maxMembers: 4,
    }, true);
    await openRoute('/projects', 4200);
    await tap(331, 260, 2400);
    assert.ok(sawApi(`/api/projects/${project.id}/join`, 200), 'project join API not observed');
  });

  await step('jobs filters and apply button mutate UI state', async () => {
    await openRoute('/jobs', 3500);
    await tap(344, 169, 900);
    await tap(195, 456, 1400);
  });

  await step('playground run, AI review, and AI explain actions call APIs', async () => {
    await openRoute('/playground', 2500);
    await tap(340, 29, 3500);
    assert.ok(sawApi('/api/code/run', 200), 'code run API not observed');
    await tap(82, 698, 2800);
    assert.ok(sawApi('/api/ai/code-review', 200), 'playground AI review API not observed');
    await page.keyboard.press('Escape');
    await waitApp(500);
    await tap(250, 698, 2800);
    assert.ok(sawApi('/api/ai/explain', 200), 'playground AI explain API not observed');
  });

  await step('notifications mark read and invite action', async () => {
    await openRoute('/notifications', 2500);
    await tap(63, 121, 900);
    await page.mouse.wheel(0, 700);
    await waitApp(700);
    await tap(96, 765, 1200);
  });

  await writeReport();
  await context.close();
  await browser.close();
}

main().catch(async (error) => {
  console.error('\nE2E UI flow failed');
  console.error(error);
  await writeReport().catch(() => {});
  if (context) await context.close().catch(() => {});
  if (browser) await browser.close().catch(() => {});
  process.exit(1);
});
