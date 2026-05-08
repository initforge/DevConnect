// Test DevConnect API
const http = require('node:http');

const API_BASE = process.env.API_URL || 'http://localhost:8080';

async function request(path, method = 'GET', body = null, headers = {}) {
  const url = new URL(path, API_BASE);
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            data: data ? JSON.parse(data) : null
          });
        } catch {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  console.log(`🚀 Starting API tests on ${API_BASE}...\n`);

  try {
    // 1. Health Check
    console.log('--- 1. Health Check ---');
    const health = await request('/health');
    console.log(`[${health.status}] /health:`, health.data, '\n');

    // 2. Auth: Login
    console.log('--- 2. Login ---');
    const login = await request('/auth/login', 'POST', {
      email: 'minh@dev.com',
      password: 'password123'
    });
    console.log(`[${login.status}] /auth/login:`, login.data?.user?.username || 'Failed', '\n');

    const token = login.data?.token;

    // 3. Get Posts
    console.log('--- 3. Get Posts ---');
    const posts = await request('/api/posts');
    console.log(`[${posts.status}] /api/posts: ${posts.data?.data?.length || 0} posts found\n`);

    // 4. Get Current User (Me)
    if (token) {
      console.log('--- 4. Get Current User (Me) ---');
      const me = await request('/auth/me', 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`[${me.status}] /auth/me:`, me.data?.user?.displayName || 'Failed', '\n');
    }

    console.log('✅ All tests finished!');
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

runTests();
