const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const baseUrl = process.env.PARITY_BASE_URL || 'http://127.0.0.1:8123';
const apiBaseUrl = process.env.PARITY_API_BASE_URL || 'http://127.0.0.1:8080';
const outputRoot = path.resolve(process.env.PARITY_OUTPUT_DIR || 'output/parity/route_audit');
const viewport = {
  width: Number(process.env.PARITY_WIDTH || 390),
  height: Number(process.env.PARITY_HEIGHT || 844),
};
const settleMs = Number(process.env.PARITY_SETTLE_MS || 3500);
const serviceWorkers = process.env.PARITY_SERVICE_WORKERS || 'block';

const routes = [
  ['01_login', '/login'],
  ['02_register', '/register'],
  ['03_onboarding', '/onboarding'],
  ['04_home_feed', '/home'],
  ['05_post_detail', '/post/p1'],
  ['06_explore', '/explore'],
  ['07_profile', '/profile'],
  ['08_create_post', '/create-post'],
  ['09_direct_message', '/chat/conv1'],
  ['10_chat_list', '/chat'],
  ['11_notifications', '/notifications'],
  ['12_project_marketplace', '/projects'],
  ['13_job_board', '/jobs'],
  ['14_leaderboard', '/leaderboard'],
  ['15_analytics', '/analytics'],
  ['16_code_playground', '/playground'],
  ['17_mentorship', '/mentorship'],
  ['18_live_code', '/live-code'],
  ['19_settings', '/settings'],
  ['20_search_results', '/search?q=flutter'],
];

const publicRoutes = new Set(['/login', '/register', '/onboarding']);

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

async function createAuditAuth() {
  if (process.env.PARITY_SEED_AUTH === '0') return null;
  const response = await fetch(`${apiBaseUrl}/auth/github/callback`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ code: '' }),
  });
  if (!response.ok) {
    throw new Error(`Auth seed failed: ${response.status} ${await response.text()}`);
  }
  const data = await response.json();
  if (!data.token || !data.user) {
    throw new Error('Auth seed response missing token or user');
  }
  return data;
}

async function main() {
  ensureDir(outputRoot);
  const screenshotDir = path.join(outputRoot, 'screenshots');
  ensureDir(screenshotDir);
  const auth = await createAuditAuth();

  const browser = await chromium.launch({ headless: true });
  const rows = [];

  for (const [name, route] of routes) {
    const currentErrors = [];
    const context = await browser.newContext({
      viewport,
      deviceScaleFactor: 1,
      isMobile: true,
      serviceWorkers,
    });
    const routePath = route.split('?')[0];
    if (auth && !publicRoutes.has(routePath)) {
      await context.addInitScript(({ token, user }) => {
        window.localStorage.setItem('flutter.auth.token', JSON.stringify(token));
        window.localStorage.setItem('flutter.auth.user', JSON.stringify(JSON.stringify(user)));
        window.localStorage.setItem('flutter.onboarding.completed', JSON.stringify(true));
      }, auth);
    }
    const page = await context.newPage();
    page.on('console', (message) => {
      if (message.type() === 'error') {
        currentErrors.push(message.text());
      }
    });
    page.on('pageerror', (error) => {
      currentErrors.push(error.message);
    });

    const url = `${baseUrl}/#${route}`;
    const started = Date.now();
    let status = 'pass';
    let error = '';

    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await page.waitForTimeout(settleMs);
    } catch (err) {
      status = 'fail';
      error = err.message;
    }

    const horizontalOverflow = await page
      .evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth)
      .catch(() => true);
    const screenshot = path.join(screenshotDir, `${name}.png`);
    await page.screenshot({ path: screenshot, fullPage: false }).catch(() => {});
    const screenshotBytes = fs.existsSync(screenshot) ? fs.statSync(screenshot).size : 0;

    if (horizontalOverflow || currentErrors.length > 0 || screenshotBytes < 10000) {
      status = status === 'fail' ? status : 'partial';
    }

    rows.push({
      name,
      route,
      status,
      ms: Date.now() - started,
      horizontalOverflow,
      consoleErrors: currentErrors.slice(),
      screenshotBytes,
      screenshot: path.relative(outputRoot, screenshot).replaceAll(path.sep, '/'),
      error,
    });

    console.log(`${status.toUpperCase()} ${name} ${route}`);
    await context.close();
  }

  await browser.close();

  let md = '# Route Parity Audit\n\n';
  md += `Generated: ${new Date().toISOString()}\n\n`;
  md += `Base URL: ${baseUrl}\n\n`;
  md += `Viewport: ${viewport.width}x${viewport.height}\n\n`;
  md += '| Status | Screen | Route | Overflow | Console errors | Screenshot bytes | Screenshot |\n';
  md += '|---|---|---|---:|---:|---:|---|\n';
  for (const row of rows) {
    md += `| ${row.status} | ${row.name} | ${row.route} | ${row.horizontalOverflow ? 'yes' : 'no'} | ${row.consoleErrors.length} | ${row.screenshotBytes} | ${row.screenshot} |\n`;
  }

  const failures = rows.filter((row) => row.status !== 'pass');
  if (failures.length) {
    md += '\n## Problems\n\n';
    for (const row of failures) {
      md += `### ${row.name} ${row.route}\n\n`;
      if (row.error) md += `- Navigation error: ${row.error}\n`;
      if (row.horizontalOverflow) md += '- Horizontal overflow detected.\n';
      if (row.screenshotBytes < 10000) md += '- Screenshot is likely blank or failed.\n';
      for (const error of row.consoleErrors) md += `- Console error: ${error}\n`;
      md += '\n';
    }
  }

  fs.writeFileSync(path.join(outputRoot, 'route_audit.md'), md);
  fs.writeFileSync(path.join(outputRoot, 'route_audit.json'), JSON.stringify(rows, null, 2));

  const failCount = failures.length;
  console.log(`Route audit complete. ${routes.length - failCount}/${routes.length} pass.`);
  if (failCount) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
