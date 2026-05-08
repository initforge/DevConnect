// Seed test users via API
const http = require('node:http');

const API_BASE = process.env.API_URL || 'http://localhost:8080';

async function register(user) {
  const url = new URL('/auth/register', API_BASE);
  const body = JSON.stringify(user);

  return new Promise((resolve, reject) => {
    const req = http.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function seed() {
  const users = [
    { email: 'test@test.com', password: 'password123', username: 'testuser', displayName: 'Test User' },
    { email: 'minh@dev.com', password: 'password123', username: 'minhdev', displayName: 'Minh Nguyen' },
    { email: 'anh@dev.com', password: 'password123', username: 'anhtran', displayName: 'Anh Tran' },
  ];

  console.log(`🌱 Seeding users to ${API_BASE}...\n`);

  for (const user of users) {
    try {
      const res = await register(user);
      if (res.status === 201) {
        console.log(`✅ Registered: ${user.email}`);
      } else if (res.status === 400) {
        console.log(`ℹ️ Already exists: ${user.email}`);
      } else {
        console.log(`❌ Failed: ${user.email} (Status: ${res.status})`);
      }
    } catch (err) {
      console.error(`❌ Error registering ${user.email}:`, err.message);
    }
  }

  console.log('\n✨ Seeding complete!');
}

seed();
