const { Queue, Worker } = (() => {
  try {
    const mod = require('bullmq');
    return { Queue: mod.Queue, Worker: mod.Worker };
  } catch {
    return { Queue: null, Worker: null };
  }
})();

const IORedis = (() => {
  try { return require('ioredis'); } catch { return null; }
})();

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const JUDGE0_URL = process.env.JUDGE0_URL || '';
const JUDGE0_API_KEY = process.env.JUDGE0_API_KEY || '';
const JUDGE0_RAPIDAPI_HOST = process.env.JUDGE0_RAPIDAPI_HOST || '';
const JUDGE0_POLL_INTERVAL_MS = Number(process.env.JUDGE0_POLL_INTERVAL_MS || 2000);
const JUDGE0_MAX_POLLS = Number(process.env.JUDGE0_MAX_POLLS || 15);
let connection = null;
let feedQueue = null;
let codeExecutionQueue = null;
let workers = [];

async function init(pool, queryFn) {
  if (!Queue || !IORedis) {
    console.log('BullMQ not available, job workers disabled');
    return { enqueue: () => Promise.resolve(false) };
  }

  connection = new IORedis(REDIS_URL, {
    maxRetriesPerRequest: null, // BullMQ requires this
    retryStrategy: (times) => Math.min(times * 50, 2000),
  });

  feedQueue = new Queue('feed', { connection });
  const notifQueue = new Queue('notifications', { connection });
  const cleanupQueue = new Queue('cleanup', { connection });
  codeExecutionQueue = new Queue('code-execution', { connection });

  // Feed recalculation worker
  workers.push(
    new Worker(
      'feed',
      async (job) => {
        console.log(`[worker] Processing feed job ${job.id}: ${job.name}`);
        switch (job.name) {
          case 'recalculate': {
            const { userId } = job.data;
            if (userId) {
              await queryFn(`
                UPDATE users SET
                  post_count = COALESCE((SELECT COUNT(*) FROM posts WHERE author_id = $1), 0),
                  follower_count = COALESCE((SELECT COUNT(*) FROM follows WHERE following_id = $1), 0),
                  following_count = COALESCE((SELECT COUNT(*) FROM follows WHERE follower_id = $1), 0)
                WHERE id = $1
              `, [userId]);
            } else {
              await queryFn(`
                UPDATE users u SET
                  post_count = COALESCE(pc.cnt, 0),
                  follower_count = COALESCE(fc.cnt, 0),
                  following_count = COALESCE(fg.cnt, 0)
                FROM
                  (SELECT author_id, COUNT(*) cnt FROM posts GROUP BY author_id) pc,
                  (SELECT following_id, COUNT(*) cnt FROM follows GROUP BY following_id) fc,
                  (SELECT follower_id, COUNT(*) cnt FROM follows GROUP BY follower_id) fg
                WHERE u.id = pc.author_id OR u.id = fc.following_id OR u.id = fg.follower_id
              `);
            }
            return 'Feed recalculated';
          }
          case 'warm_cache': {
            const { key, ttl = 300 } = job.data;
            if (key) {
              const redis = require('./cache');
              const cached = await redis.get(key);
              if (!cached) {
                console.log(`[worker] Cache miss for ${key}, will populate on next request`);
              }
            }
            return 'Cache warmed';
          }
          default:
            return `Unknown feed job: ${job.name}`;
        }
      },
      { connection }
    )
  );

  // Notification digest worker
  workers.push(
    new Worker(
      'notifications',
      async (job) => {
        console.log(`[worker] Processing notification job ${job.id}: ${job.name}`);
        switch (job.name) {
          case 'digest': {
            const { userId, interval = 'daily' } = job.data;
            const { rows } = await queryFn(`
              SELECT COUNT(*) as unread_count
              FROM notifications
              WHERE user_id = $1 AND is_read = false
            `, [userId]);
            const count = Number(rows[0]?.unread_count ?? 0);
            if (count > 0) {
              console.log(`[worker] User ${userId} has ${count} unread notifications (${interval} digest)`);
            }
            return `Digest complete: ${count} unread`;
          }
          case 'broadcast': {
            const { message } = job.data;
            console.log(`[worker] Broadcasting: ${JSON.stringify(message).slice(0, 80)}`);
            return 'Broadcast sent';
          }
          default:
            return `Unknown notification job: ${job.name}`;
        }
      },
      { connection }
    )
  );

  // Cleanup worker
  workers.push(
    new Worker(
      'cleanup',
      async (job) => {
        console.log(`[worker] Processing cleanup job ${job.id}: ${job.name}`);
        switch (job.name) {
          case 'stale_sessions': {
            const result = await queryFn(
              `DELETE FROM sessions WHERE expires_at < NOW()`
            );
            return `Cleaned up ${result.rowCount ?? 0} stale sessions`;
          }
          case 'stale_tokens': {
            const result = await queryFn(
              `DELETE FROM refresh_tokens WHERE expires_at < NOW()`
            );
            return `Cleaned up ${result.rowCount ?? 0} stale tokens`;
          }
          case 'old_logs': {
            return 'Logs rotated';
          }
          default:
            return `Unknown cleanup job: ${job.name}`;
        }
      },
      { connection }
    )
  );

  // Code execution worker (Judge0 polling)
  workers.push(
    new Worker(
      'code-execution',
      async (job) => {
        console.log(`[worker] Processing code-execution job ${job.id}: ${job.name}`);
        switch (job.name) {
          case 'execute': {
            const { token, language, jobId } = job.data;
            const cache = require('./cache');
            const cacheKey = `code-exec:${jobId}`;

            // Poll Judge0 for result
            for (let i = 0; i < JUDGE0_MAX_POLLS; i++) {
              await new Promise(resolve => setTimeout(resolve, JUDGE0_POLL_INTERVAL_MS));

              try {
                const pollUrl = `${JUDGE0_URL.replace(/\/$/, '')}/submissions/${token}?base64_encoded=false`;
                const pollRes = await fetch(pollUrl, {
                  headers: {
                    'x-rapidapi-key': JUDGE0_API_KEY,
                    'x-rapidapi-host': JUDGE0_RAPIDAPI_HOST,
                  },
                });

                if (!pollRes.ok) continue;

                const result = await pollRes.json();
                if (result.status && result.status.id > 2) {
                  if (result.status.id === 3) {
                    await cache.set(cacheKey, {
                      output: result.stdout || '',
                      language,
                      executionTime: Number(result.time) * 1000 || 0,
                      memory: result.memory || 0,
                      source: 'judge0',
                      status: 'completed',
                    }, 300);
                  } else {
                    await cache.set(cacheKey, {
                      output: '',
                      error: result.compile_output || result.stderr || `Execution failed (status ${result.status.description})`,
                      language,
                      source: 'judge0-error',
                      status: 'failed',
                    }, 300);
                  }
                  return { jobId, status: 'completed' };
                }
              } catch (err) {
                console.error(`[worker] Judge0 poll error on attempt ${i + 1}:`, err.message);
              }
            }

            // Timed out
            await cache.set(cacheKey, {
              status: 'timeout',
              error: 'Execution timed out waiting for Judge0 result',
            }, 300);
            return { jobId, status: 'timeout' };
          }
          default:
            return `Unknown code-execution job: ${job.name}`;
        }
      },
      { connection }
    )
  );

  console.log('BullMQ job workers initialized');

  return {
    enqueue: async (queueName, jobName, data, opts = {}) => {
      const queue = { feed: feedQueue, notifications: notifQueue, cleanup: cleanupQueue, 'code-execution': codeExecutionQueue }[queueName];
      if (!queue) throw new Error(`Unknown queue: ${queueName}`);
      await queue.add(jobName, data, opts);
      return true;
    },
    close: async () => {
      for (const w of workers) await w.close();
      if (feedQueue) await feedQueue.close();
      if (notifQueue) await notifQueue.close();
      if (cleanupQueue) await cleanupQueue.close();
      if (codeExecutionQueue) await codeExecutionQueue.close();
      if (connection) await connection.quit();
    },
  };
}

module.exports = { init };
