// Utility script to hash all user passwords (useful after seeding)
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://devconnect:devconnect123@localhost:5432/devconnect';
const DEFAULT_PASSWORD = process.env.DEFAULT_PASSWORD || 'password123';

const pool = new Pool({ connectionString: DATABASE_URL });

async function run() {
  console.log(`🔌 Connecting to ${DATABASE_URL.split('@')[1]}...`);

  try {
    const { rows: users } = await pool.query('SELECT id, email, username FROM users');
    console.log(`👤 Found ${users.length} users.`);

    const hash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
    console.log(`🔑 Hashing all passwords to "${DEFAULT_PASSWORD}"...`);

    for (const user of users) {
      await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, user.id]);
      console.log(`   ✅ Updated: ${user.email || user.username}`);
    }

    console.log('\n✨ All passwords updated successfully!');
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

run();
