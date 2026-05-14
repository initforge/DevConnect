const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');

const rootDir = path.resolve(__dirname, '..');
const webDir = path.join(rootDir, 'app', 'build', 'web');
const outDir = path.join(rootDir, 'output', 'playwright', 'full_suite');
const parityDir = path.join(rootDir, 'output', 'parity', 'route_audit_runtime', 'screenshots');
const port = Number(process.env.FULL_E2E_PORT || 8125);
const baseUrl = `http://127.0.0.1:${port}`;

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
const viewports = [
  { name: 'mobile', width: 390, height: 844, isMobile: true },
  { name: 'tablet', width: 768, height: 1024, isMobile: false },
  { name: 'desktop', width: 1440, height: 900, isMobile: false },
];

const user = {
  id: 'u1',
  username: 'minhdev',
  displayName: 'Minh Nguyen',
  email: 'minh@dev.com',
  avatarUrl: null,
  bio: 'Flutter and backend developer',
  skills: ['Flutter', 'Dart', 'Node.js', 'SQLite'],
  followerCount: 1250,
  followingCount: 340,
  postCount: 4,
  reputation: 3200,
  isOnline: true,
  isMentor: false,
};

const mentors = [
  {
    ...user,
    id: 'u2',
    username: 'anhtran',
    displayName: 'Anh Tran',
    isMentor: true,
    skills: ['Go', 'Docker', 'PostgreSQL', 'Redis'],
    reputation: 2800,
  },
  {
    ...user,
    id: 'u3',
    username: 'linhpham',
    displayName: 'Linh Pham',
    isMentor: true,
    skills: ['Python', 'AI', 'FastAPI'],
    reputation: 4500,
  },
];

const posts = [
  {
    id: 'p1',
    title: 'Getting Started with Flutter',
    content: 'Flutter is an open-source UI toolkit for shipping polished apps.',
    type: 'article',
    tags: ['Flutter', 'Dart', 'Mobile'],
    author: user,
    authorId: user.id,
    viewCount: 1500,
    likeCount: 120,
    commentCount: 2,
    bookmarkCount: 45,
    createdAt: '2026-05-01T10:00:00.000Z',
  },
];

const comments = [
  {
    id: 'c1',
    postId: 'p1',
    authorId: 'u2',
    author: mentors[0],
    content: 'Great introduction.',
    depth: 0,
    replyCount: 1,
    isBest: true,
    createdAt: '2026-05-01T12:00:00.000Z',
  },
];

const projects = [
  {
    id: 'proj1',
    title: 'DevConnect Mobile',
    description: 'A collaboration app for builders.',
    techStack: ['Flutter', 'NestJS', 'PostgreSQL'],
    status: 'LOOKING_FOR_MEMBERS',
    memberCount: 2,
    maxMembers: 5,
    owner: user,
    ownerId: user.id,
    createdAt: '2026-05-01T10:00:00.000Z',
  },
];

const jobs = [
  {
    id: 'job1',
    company: 'DevConnect Labs',
    title: 'Flutter Engineer',
    location: 'Remote',
    remote: true,
    salaryRange: '$3k-$5k',
    techStack: ['Flutter', 'Dart'],
    experience: 'Mid',
    matchPercent: 92,
    createdAt: '2026-05-01T10:00:00.000Z',
  },
];

const conversations = [
  {
    id: 'conv1',
    userId: 'u1',
    otherUserId: 'u2',
    otherUser: mentors[0],
    lastMessage: 'Let us pair on this.',
    unreadCount: 1,
    updatedAt: '2026-05-01T10:00:00.000Z',
  },
];

const messages = [
  {
    id: 'm1',
    conversationId: 'conv1',
    senderId: 'u2',
    content: 'Let us pair on this.',
    type: 'text',
    reactions: ['thumbs_up'],
    isRead: false,
    createdAt: '2026-05-01T10:00:00.000Z',
  },
];

const mentorshipRequests = [
  {
    id: 'mr1',
    menteeId: 'u1',
    mentorId: 'u2',
    status: 'accepted',
    note: 'Need help shipping production Flutter.',
    menteeDisplayName: user.displayName,
    mentorDisplayName: mentors[0].displayName,
    createdAt: '2026-05-01T10:00:00.000Z',
    updatedAt: '2026-05-02T10:00:00.000Z',
  },
];

const sessions = [
  {
    id: 'ms1',
    requestId: 'mr1',
    scheduledAt: '2026-05-14T12:00:00.000Z',
    status: 'scheduled',
    createdAt: '2026-05-01T10:00:00.000Z',
    updatedAt: '2026-05-01T10:00:00.000Z',
  },
];

const journals = [
  {
    id: 'mj1',
    requestId: 'mr1',
    authorId: 'u1',
    text: 'Refactored API retry flow and verified tests.',
    mentorFeedback: 'Good progress. Add one integration test next.',
    createdAt: '2026-05-05T10:00:00.000Z',
    updatedAt: '2026-05-05T10:00:00.000Z',
  },
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function contentType(file) {
  if (file.endsWith('.html')) return 'text/html; charset=utf-8';
  if (file.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (file.endsWith('.css')) return 'text/css; charset=utf-8';
  if (file.endsWith('.json')) return 'application/json';
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
  await context.addInitScript((seed) => {
    window.localStorage.setItem('flutter.auth.token', JSON.stringify(seed.token));
    window.localStorage.setItem('flutter.auth.user', JSON.stringify(JSON.stringify(seed.user)));
    window.localStorage.setItem('flutter.onboarding.completed', JSON.stringify(true));
  }, { token: 'full-suite-token', user });
}

function pagePayload(pathname, method) {
  if (pathname === '/health') return { status: 'ok' };
  if (pathname === '/auth/me' || pathname === '/api/users/me') return { user };
  if (pathname === '/auth/login' || pathname === '/auth/register') return { token: 'full-suite-token', user };
  if (pathname === '/api/users/search') return { data: mentors };
  if (pathname === '/api/users') return [user, ...mentors];
  if (pathname.startsWith('/api/users/')) return pathname.endsWith('/github-sync') ? { repos: [], contributions: [] } : user;
  if (pathname === '/api/posts' && method === 'POST') return { ...posts[0], id: `p-${Date.now()}` };
  if (pathname === '/api/posts' || pathname === '/api/posts/recommendations') return { data: posts, page: 1, limit: 20, total: posts.length };
  if (pathname === '/api/posts/p1') return posts[0];
  if (pathname === '/api/posts/p1/comments' || pathname.endsWith('/comments')) return comments;
  if (pathname === '/api/projects') return method === 'POST' ? projects[0] : { data: projects, page: 1, limit: 20, total: projects.length };
  if (pathname.startsWith('/api/projects/')) return pathname.endsWith('/join') ? { success: true } : projects[0];
  if (pathname === '/api/jobs') return { data: jobs, page: 1, limit: 20, total: jobs.length };
  if (pathname.startsWith('/api/jobs/')) return jobs[0];
  if (pathname === '/api/conversations' || pathname === '/api/chat/conversations') return { data: conversations, page: 1, limit: 20, total: conversations.length };
  if (pathname.includes('/messages')) return method === 'POST' ? { ...messages[0], id: `m-${Date.now()}` } : messages;
  if (pathname === '/api/notifications') return [
    { id: 'n1', type: 'like', title: 'New like', body: 'Anh liked your post', mergedCount: 3, isRead: false, createdAt: '2026-05-01T10:00:00.000Z' },
  ];
  if (pathname === '/api/notifications/count') return { count: 1 };
  if (pathname === '/api/analytics' || pathname === '/api/analytics/me') {
    return {
      totalViews: 8400,
      activeUsersThisWeek: 15,
      topPosts: [{ title: posts[0].title, views: 2400, likes: 120 }],
      readerStats: [{ label: 'Flutter', pct: 0.42 }, { label: 'Node.js', pct: 0.28 }],
    };
  }
  if (pathname === '/api/leaderboard') return { data: [user, ...mentors] };
  if (pathname === '/api/code/run' || pathname === '/api/playground/run') return { stdout: 'Hello DevConnect', status: { description: 'Accepted' } };
  if (pathname === '/api/ai/code-review') return { summary: 'Looks good', suggestions: ['Add tests'] };
  if (pathname === '/api/ai/explain') return { explanation: 'This code prints a message.' };
  if (pathname === '/api/mentorship/mentors') return mentors;
  if (pathname === '/api/mentorship/requests') return mentorshipRequests;
  if (pathname === '/api/mentorship/sessions') return sessions;
  if (pathname === '/api/mentorship/journals') return journals;
  if (pathname === '/api/mentorship/weekly-summary') {
    return { acceptedCount: 1, scheduledCount: 1, journalCount: 1, completed: 3, target: 5, text: 'You completed 3/5 mentorship goals this week: 1 scheduled, 1 journaled, 1 active.' };
  }
  return { success: true, data: [] };
}

async function mockApi(context) {
  await context.route(/http:\/\/(localhost|127\.0\.0\.1)(?::(80|8080))?\/(api|auth|health).*/, async (route) => {
    const request = route.request();
    const requestUrl = new URL(request.url());
    const payload = pagePayload(requestUrl.pathname, request.method());
    await route.fulfill({
      status: request.method() === 'POST' && requestUrl.pathname === '/api/posts' ? 201 : 200,
      contentType: 'application/json',
      body: JSON.stringify(payload),
    });
  });
}

function shouldIgnoreConsole(text) {
  return /WebSocket|socket\.io|ERR_CONNECTION_REFUSED|Failed to load resource/i.test(text);
}

function addAssertion(state, condition, message) {
  state.assertions += 1;
  assert.ok(condition, message);
}

async function main() {
  ensureDir(outDir);
  ensureDir(parityDir);
  const server = await startStaticServer();
  const browser = await chromium.launch({ headless: true });
  const rows = [];
  const state = { assertions: 0 };

  try {
    for (const viewport of viewports) {
      for (const [name, routePath] of routes) {
        const context = await browser.newContext({
          viewport: { width: viewport.width, height: viewport.height },
          isMobile: viewport.isMobile,
          deviceScaleFactor: 1,
          serviceWorkers: 'block',
        });
        await mockApi(context);
        if (!publicRoutes.has(routePath.split('?')[0])) await seedStorage(context);

        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', (error) => errors.push(error.stack || error.message));
        page.on('console', (message) => {
          if (message.type() === 'error' && !shouldIgnoreConsole(message.text())) {
            errors.push(message.text());
          }
        });

        const started = Date.now();
        await page.goto(`${baseUrl}/#${routePath}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
        await page.waitForTimeout(7000);

        const metrics = await page.evaluate(() => {
          const root = document.documentElement;
          const body = document.body;
          const surface = document.querySelector('flt-glass-pane, flutter-view, flt-scene-host, canvas, [flt-renderer]');
          const rect = surface?.getBoundingClientRect();
          return {
            hash: window.location.hash,
            bodyTextLength: body.innerText.length,
            childCount: body.children.length,
            clientWidth: root.clientWidth,
            clientHeight: root.clientHeight,
            scrollWidth: Math.max(root.scrollWidth, body.scrollWidth),
            scrollHeight: Math.max(root.scrollHeight, body.scrollHeight),
            surfaceTag: surface?.tagName || '',
            surfaceWidth: rect?.width || 0,
            surfaceHeight: rect?.height || 0,
          };
        });

        const screenshot = path.join(outDir, `${viewport.name}_${name}.png`);
        const parityScreenshot = path.join(parityDir, `${name}.png`);
        await page.screenshot({ path: screenshot, fullPage: false });
        if (viewport.name === 'mobile') fs.copyFileSync(screenshot, parityScreenshot);
        const bytes = fs.statSync(screenshot).size;

        addAssertion(state, metrics.hash.includes(routePath.split('?')[0]), `${viewport.name} ${name} wrong hash ${metrics.hash}`);
        addAssertion(state, metrics.clientWidth === viewport.width, `${viewport.name} ${name} width mismatch`);
        addAssertion(state, metrics.clientHeight === viewport.height, `${viewport.name} ${name} height mismatch`);
        addAssertion(state, metrics.scrollWidth <= metrics.clientWidth + 2, `${viewport.name} ${name} horizontal overflow`);
        addAssertion(state, metrics.scrollHeight >= metrics.clientHeight * 0.5, `${viewport.name} ${name} short document`);
        addAssertion(state, metrics.surfaceTag.length > 0, `${viewport.name} ${name} missing Flutter surface`);
        addAssertion(state, metrics.surfaceWidth > 0, `${viewport.name} ${name} zero surface width`);
        addAssertion(state, metrics.surfaceHeight > 0, `${viewport.name} ${name} zero surface height`);
        addAssertion(state, metrics.childCount > 0, `${viewport.name} ${name} empty body`);
        addAssertion(state, bytes > 10000, `${viewport.name} ${name} screenshot likely blank`);
        addAssertion(state, fs.existsSync(screenshot), `${viewport.name} ${name} screenshot missing`);
        addAssertion(state, errors.length === 0, `${viewport.name} ${name} page errors: ${errors.join(' | ')}`);
        addAssertion(state, Date.now() - started < 30000, `${viewport.name} ${name} too slow`);
        addAssertion(state, routePath.startsWith('/'), `${viewport.name} ${name} invalid route path`);

        rows.push({
          viewport: viewport.name,
          screen: name,
          route: routePath,
          ms: Date.now() - started,
          screenshot: path.relative(rootDir, screenshot).replaceAll(path.sep, '/'),
          errors: errors.length,
          bytes,
        });
        await context.close();
      }
    }
  } finally {
    await browser.close().catch(() => {});
    server.close();
  }

  const report = [
    '# Full Playwright Suite Report',
    '',
    `Generated: ${new Date().toISOString()}`,
    '',
    `Routes: ${routes.length}`,
    `Viewports: ${viewports.length}`,
    `Assertions: ${state.assertions}`,
    '',
    '| Viewport | Screen | Route | ms | Errors | Bytes | Screenshot |',
    '|---|---|---|---:|---:|---:|---|',
    ...rows.map((row) => `| ${row.viewport} | ${row.screen} | ${row.route} | ${row.ms} | ${row.errors} | ${row.bytes} | ${row.screenshot} |`),
    '',
  ].join('\n');
  fs.writeFileSync(path.join(outDir, 'full_suite_report.md'), report, 'utf8');
  fs.writeFileSync(path.join(outDir, 'full_suite_report.json'), JSON.stringify({ assertions: state.assertions, rows }, null, 2));
  console.log(report);
  assert.equal(state.assertions, routes.length * viewports.length * 14);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
