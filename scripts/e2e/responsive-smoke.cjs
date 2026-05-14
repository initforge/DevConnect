const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');

const rootDir = path.resolve(__dirname, '..');
const webDir = path.join(rootDir, 'app', 'build', 'web');
const outDir = path.join(rootDir, 'output', 'playwright', 'responsive_smoke');
const port = Number(process.env.RESPONSIVE_SMOKE_PORT || 8124);
const baseUrl = `http://127.0.0.1:${port}`;

const routes = ['/home', '/more', '/projects'];
const viewports = [
  { name: 'mobile', width: 390, height: 844, isMobile: true },
  { name: 'tablet', width: 768, height: 1024, isMobile: false },
  { name: 'desktop', width: 1440, height: 900, isMobile: false },
];

const smokeUser = {
  id: 'smoke-user',
  username: 'smoke',
  displayName: 'Smoke User',
  email: 'smoke@example.test',
  skills: ['Flutter', 'Node.js'],
};

function contentType(file) {
  if (file.endsWith('.html')) return 'text/html; charset=utf-8';
  if (file.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (file.endsWith('.css')) return 'text/css; charset=utf-8';
  if (file.endsWith('.json')) return 'application/json; charset=utf-8';
  if (file.endsWith('.wasm')) return 'application/wasm';
  if (file.endsWith('.png')) return 'image/png';
  if (file.endsWith('.svg')) return 'image/svg+xml';
  return 'application/octet-stream';
}

function startStaticServer() {
  if (!fs.existsSync(path.join(webDir, 'index.html'))) {
    throw new Error('app/build/web/index.html not found. Run `flutter build web` first.');
  }

  const server = http.createServer((req, res) => {
    const url = new URL(req.url, baseUrl);
    const requested = decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname);
    const resolved = path.resolve(webDir, `.${requested}`);
    const file = resolved.startsWith(webDir) && fs.existsSync(resolved)
      ? resolved
      : path.join(webDir, 'index.html');
    res.writeHead(200, { 'content-type': contentType(file) });
    fs.createReadStream(file).pipe(res);
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', () => resolve(server));
  });
}

async function seedStorage(context) {
  await context.addInitScript((user) => {
    window.localStorage.setItem('flutter.auth.token', JSON.stringify('responsive-smoke-token'));
    window.localStorage.setItem('flutter.auth.user', JSON.stringify(JSON.stringify(user)));
    window.localStorage.setItem('flutter.onboarding.completed', JSON.stringify(true));
  }, smokeUser);
}

async function mockApi(context) {
  await context.route(/http:\/\/(localhost|127\.0\.0\.1)(?::(80|8080))?\/(api|auth|health).*/, async (route) => {
    const requestUrl = new URL(route.request().url());
    const pathname = requestUrl.pathname;
    let payload = { success: true };

    if (pathname === '/health') {
      payload = { status: 'ok' };
    } else if (pathname === '/auth/me' || pathname === '/api/users/me') {
      payload = { user: smokeUser };
    } else if (pathname === '/api/posts' || pathname === '/api/posts/recommendations') {
      payload = { data: [], page: 1, limit: 20, total: 0 };
    } else if (pathname === '/api/projects') {
      payload = { data: [], page: 1, limit: 20, total: 0 };
    } else if (pathname === '/api/jobs') {
      payload = { data: [], page: 1, limit: 20, total: 0 };
    } else if (pathname === '/api/conversations' || pathname === '/api/chat/conversations') {
      payload = { data: [], page: 1, limit: 20, total: 0 };
    } else if (pathname === '/api/notifications') {
      payload = [];
    } else if (pathname === '/api/notifications/count') {
      payload = { count: 0 };
    } else if (pathname === '/api/analytics' || pathname === '/api/analytics/me') {
      payload = {
        totalUsers: 0,
        totalPosts: 0,
        totalProjects: 0,
        totalJobs: 0,
        activeUsersThisWeek: 0,
        totalViews: 0,
        topPosts: [],
        readerStats: [],
      };
    } else if (pathname === '/api/users') {
      payload = [];
    } else if (pathname.startsWith('/api/users/')) {
      payload = smokeUser;
    }

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(payload),
    });
  });
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });
  const server = await startStaticServer();
  const browser = await chromium.launch({ headless: true });
  const rows = [];

  try {
    for (const viewport of viewports) {
      const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
        isMobile: viewport.isMobile,
        deviceScaleFactor: 1,
        serviceWorkers: 'block',
      });
      await mockApi(context);
      await seedStorage(context);
      const page = await context.newPage();
      const pageErrors = [];
      page.on('pageerror', (error) => pageErrors.push(error.stack || error.message));
      page.on('console', (message) => {
        if (message.type() === 'error') pageErrors.push(message.text());
      });

      for (const route of routes) {
        await page.goto(`${baseUrl}/#${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await page.waitForTimeout(3500);
        const hash = await page.evaluate(() => window.location.hash);
        assert.ok(hash.includes(route), `${viewport.name} ${route} redirected to ${hash}`);
        assert.equal(
          pageErrors.length,
          0,
          `${viewport.name} ${route} emitted page errors: ${pageErrors.join(' | ')}`,
        );

        const metrics = await page.evaluate(() => {
          const root = document.documentElement;
          const body = document.body;
          const surface = document.querySelector('flt-glass-pane, flutter-view, flt-scene-host, canvas, [flt-renderer]');
          const rect = surface?.getBoundingClientRect();
          return {
            clientWidth: root.clientWidth,
            scrollWidth: Math.max(root.scrollWidth, body.scrollWidth),
            clientHeight: root.clientHeight,
            scrollHeight: Math.max(root.scrollHeight, body.scrollHeight),
            surfaceTag: surface?.tagName || '',
            surfaceWidth: rect?.width || 0,
            surfaceHeight: rect?.height || 0,
          };
        });

        const file = path.join(outDir, `${viewport.name}_${route.replace(/^\//, '')}.png`);
        await page.screenshot({ path: file, fullPage: false });
        assert.ok(metrics.surfaceWidth > 0 && metrics.surfaceHeight > 0, `${viewport.name} ${route} did not render Flutter surface: ${JSON.stringify(metrics)}`);
        assert.ok(metrics.scrollWidth <= metrics.clientWidth + 2, `${viewport.name} ${route} has horizontal overflow ${metrics.scrollWidth} > ${metrics.clientWidth}`);
        rows.push({
          viewport: viewport.name,
          route,
          hash,
          screenshot: path.relative(rootDir, file).replaceAll(path.sep, '/'),
          pageErrors: pageErrors.length,
          firstError: pageErrors[0] || '',
        });
      }

      await context.close();
    }
  } finally {
    await browser.close().catch(() => {});
    server.close();
  }

  const report = [
    '# Responsive Smoke Report',
    '',
    `Generated: ${new Date().toISOString()}`,
    '',
    `App: ${baseUrl}`,
    '',
    '| Viewport | Route | Hash | Page errors | Screenshot |',
    '|---|---|---|---:|---|',
    ...rows.map((row) => `| ${row.viewport} | ${row.route} | ${row.hash} | ${row.pageErrors} | ${row.screenshot} |`),
    '',
    '## Page Errors',
    '',
    ...rows
      .filter((row) => row.firstError)
      .map((row) => `- ${row.viewport} ${row.route}: ${row.firstError.replaceAll('\n', ' ')}`),
    '',
  ].join('\n');
  fs.writeFileSync(path.join(outDir, 'responsive_smoke_report.md'), report, 'utf8');
  console.log(report);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
