const IORedis = (() => {
  try { return require('ioredis'); } catch { return null; }
})();

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

let client = null;
let connected = false;

async function connect() {
  if (!IORedis) return false;
  try {
    client = new IORedis(REDIS_URL, {
      maxRetriesPerRequest: 3,
      retryStrategy: (times) => Math.min(times * 50, 2000),
    });
    await client.ping();
    connected = true;
    console.log('Redis caching enabled');
    return true;
  } catch {
    connected = false;
    client = null;
    console.log('Redis not available, cache layer disabled');
    return false;
  }
}

function get(key) {
  if (!connected || !client) return Promise.resolve(null);
  return client
    .get(key)
    .then((raw) => (raw ? JSON.parse(raw) : null))
    .catch(() => null);
}

function set(key, value, ttlSeconds = 300) {
  if (!connected || !client) return Promise.resolve(false);
  return client
    .set(key, JSON.stringify(value), 'EX', ttlSeconds)
    .then(() => true)
    .catch(() => false);
}

function del(key) {
  if (!connected || !client) return Promise.resolve(false);
  return client.del(key).then(() => true).catch(() => false);
}

function cacheKey(...parts) {
  return 'devconnect:' + parts.join(':');
}

module.exports = { connect, get, set, del, cacheKey, client };
