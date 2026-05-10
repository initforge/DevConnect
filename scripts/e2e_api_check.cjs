const assert = require('node:assert/strict');

const baseUrl = process.env.E2E_API_BASE_URL || 'http://127.0.0.1:8080';
const stamp = Date.now();
let token = '';
let user = null;
let project = null;

function listOf(data) {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data.data)) return data.data;
  if (Array.isArray(data.items)) return data.items;
  if (Array.isArray(data.notifications)) return data.notifications;
  return [];
}

async function request(method, path, body, auth = false) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(auth && token ? { authorization: `Bearer ${token}` } : {}),
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
    throw new Error(`${method} ${path} -> ${response.status}: ${text}`);
  }
  return data;
}

async function step(name, fn) {
  process.stdout.write(`- ${name} ... `);
  await fn();
  console.log('pass');
}

async function main() {
  await step('health', async () => {
    const data = await request('GET', '/health');
    assert.equal(data.status, 'ok');
  });

  await step('list seed users/posts/projects/jobs', async () => {
    assert.ok((await request('GET', '/api/users')).data.length >= 3);
    assert.ok((await request('GET', '/api/posts')).data.length >= 3);
    assert.ok((await request('GET', '/api/projects')).data.length >= 1);
    assert.ok((await request('GET', '/api/jobs')).data.length >= 1);
  });

  await step('register new user', async () => {
    const data = await request('POST', '/auth/register', {
      email: `e2e_${stamp}@devconnect.test`,
      password: 'password123',
      username: `e2e_${stamp}`,
      displayName: 'E2E User',
    });
    assert.ok(data.token);
    assert.ok(data.user.id);
    token = data.token;
    user = data.user;
  });

  await step('auth/me', async () => {
    const data = await request('GET', '/auth/me', undefined, true);
    assert.equal(data.user.id, user.id);
  });

  await step('create and fetch post', async () => {
    const data = await request('POST', '/api/posts', {
      authorId: user.id,
      title: `E2E Post ${stamp}`,
      content: 'Created by API E2E check',
      type: 'article',
      tags: ['E2E', 'API'],
    }, true);
    assert.ok(data.id);
    const fetched = await request('GET', `/api/posts/${data.id}`);
    assert.equal(fetched.id, data.id);
  });

  await step('like and bookmark post', async () => {
    const like = await request('POST', '/api/posts/p1/like', {}, true);
    assert.equal(typeof like.liked, 'boolean');
    const bookmark = await request('POST', '/api/posts/p1/bookmark', {}, true);
    assert.equal(typeof bookmark.bookmarked, 'boolean');
  });

  await step('create comment', async () => {
    const data = await request('POST', '/api/posts/p1/comments', {
      authorId: user.id,
      content: `E2E comment ${stamp}`,
    }, true);
    assert.ok(data.id);
  });

  await step('create and join project', async () => {
    project = await request('POST', '/api/projects', {
      title: `E2E Project ${stamp}`,
      description: 'Created by API E2E check',
      techStack: ['Node.js', 'Flutter'],
      maxMembers: 3,
    }, true);
    assert.ok(project.id);
    const data = await request('POST', `/api/projects/${project.id}/join`, {}, true);
    assert.ok(data.joined === true || data.success === true);
  });

  await step('send chat message', async () => {
    const data = await request('POST', '/api/conversations/conv1/messages', {
      senderId: user.id,
      content: `E2E message ${stamp}`,
      type: 'text',
    }, true);
    assert.ok(data.id);
  });

  await step('notifications and analytics', async () => {
    assert.ok(listOf(await request('GET', '/api/notifications', undefined, true)).length >= 1);
    const analytics = await request('GET', '/api/analytics', undefined, true);
    assert.ok(Object.keys(analytics).length > 0);
  });

  await step('code run endpoint', async () => {
    const data = await request('POST', '/api/code/run', {
      code: 'console.log("hello")',
      language: 'typescript',
    }, true);
    assert.ok('output' in data || 'result' in data || 'error' in data);
  });
}

main().catch((error) => {
  console.error('\nE2E API check failed');
  console.error(error);
  process.exit(1);
});
