const http = require('node:http');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('node:crypto');
const { handleExtendedRoutes } = require('./route_modules/extended_routes');

const PORT = Number(process.env.PORT || 8080);
const WS_PORT = Number(process.env.WS_PORT || 8081);
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://devconnect:devconnect123@localhost:5432/devconnect';
const JWT_SECRET = process.env.JWT_SECRET || 'devconnect-secret-key-2024';
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID || '';
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET || '';

const pool = new Pool({ connectionString: DATABASE_URL });

// Rate limiting: Map<ip, {count, resetTime}>
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = Number(process.env.RATE_LIMIT_WINDOW_MS || 60000);
const RATE_LIMIT_MAX = Number(process.env.RATE_LIMIT_MAX || 2000);

function rateLimit(ip) {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return true;
  }
  if (entry.count >= RATE_LIMIT_MAX) return false;
  entry.count++;
  return true;
}

async function query(text, params) {
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}

// ========== WEBSOCKET (ws://) ==========
const { WebSocketServer } = (() => {
  try { return require('ws'); } catch { return { WebSocketServer: null }; }
})();

const wsClients = new Map(); // clientId -> { ws, userId }

function broadcast(channel, message, excludeClientId = null) {
  const msg = JSON.stringify({ channel, ...message });
  for (const [clientId, client] of wsClients) {
    if (clientId !== excludeClientId && client.ws.readyState === 1) {
      client.ws.send(msg);
    }
  }
}

function setupWebSocket(server) {
  if (!WebSocketServer) return;
  const wss = new WebSocketServer({ server });
  wss.on('connection', (ws, req) => {
    const clientId = crypto.randomUUID();
    wsClients.set(clientId, { ws, userId: null });

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data.toString());
        if (msg.type === 'auth') {
          try {
            const decoded = jwt.verify(msg.token, JWT_SECRET);
            wsClients.get(clientId).userId = decoded.userId;
            ws.send(JSON.stringify({ type: 'auth_ok', clientId }));
          } catch {
            ws.send(JSON.stringify({ type: 'auth_error' }));
          }
        }
        if (msg.type === 'subscribe' && msg.channel) {
          wsClients.get(clientId).channel = msg.channel;
          ws.send(JSON.stringify({ type: 'subscribed', channel: msg.channel }));
        }
        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong' }));
        }
      } catch {}
    });

    ws.on('close', () => wsClients.delete(clientId));
  });

  setInterval(() => {
    broadcast('heartbeat', { ts: Date.now() });
  }, 30000);
}

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  });
  res.end(body);
}

function badRequest(res, message) {
  json(res, 400, { error: message });
}

function unauthorized(res, message) {
  json(res, 401, { error: message });
}

function notFound(res) {
  json(res, 404, { error: 'Not found' });
}

function createdId(prefix) {
  return `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

function parseSkills(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    if (typeof value === 'string' && value.includes('|')) {
      return value.split('|').filter(s => s.trim().length > 0);
    }
    return [];
  }
}

// Auth middleware - decode JWT token
async function authMiddleware(req) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.slice(7);
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch {
    return null;
  }
}

async function mapUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    username: row.username,
    displayName: row.display_name,
    email: row.email,
    avatarUrl: row.avatar_url,
    bio: row.bio,
    skills: parseSkills(row.skills),
    followerCount: row.follower_count,
    followingCount: row.following_count,
    postCount: row.post_count,
    reputation: row.reputation,
    isOnline: row.is_online === 1,
    isMentor: row.is_mentor === 1,
    isFollowedByMe: row.is_followed_by_me === true || row.is_followed_by_me === 1,
    createdAt: row.created_at,
  };
}

async function mapPost(row) {
  if (!row) return null;
  const author = await mapUser({
    id: row.author_id,
    username: row.author_username,
    display_name: row.author_display_name,
    email: row.author_email,
    avatar_url: row.author_avatar_url,
    bio: row.author_bio,
    skills: row.author_skills,
    follower_count: row.author_follower_count,
    following_count: row.author_following_count,
    post_count: row.author_post_count,
    reputation: row.author_reputation,
    is_online: row.author_is_online,
    is_mentor: row.author_is_mentor,
    created_at: row.author_created_at,
  });
  return {
    id: row.id,
    title: row.title,
    content: row.content,
    type: row.type,
    tags: parseSkills(row.tags),
    viewCount: row.view_count,
    likeCount: row.like_count,
    commentCount: row.comment_count,
    bookmarkCount: row.bookmark_count,
    createdAt: row.created_at,
    author,
    isLikedByMe: row.is_liked_by_me === true || row.is_liked_by_me === 1,
    isBookmarkedByMe: row.is_bookmarked_by_me === true || row.is_bookmarked_by_me === 1,
  };
}

async function mapProject(row) {
  const owner = await mapUser({
    id: row.owner_id,
    username: row.owner_username,
    display_name: row.owner_display_name,
    email: row.owner_email,
    avatar_url: row.owner_avatar_url,
    bio: row.owner_bio,
    skills: row.owner_skills,
    follower_count: row.owner_follower_count,
    following_count: row.owner_following_count,
    post_count: row.owner_post_count,
    reputation: row.owner_reputation,
    is_online: row.owner_is_online,
    is_mentor: row.owner_is_mentor,
    created_at: row.owner_created_at,
  });
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    techStack: parseSkills(row.tech_stack),
    status: row.status,
    memberCount: row.member_count,
    maxMembers: row.max_members,
    createdAt: row.created_at,
    owner,
  };
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => { raw += chunk; if (raw.length > 1_000_000) req.destroy(); });
    req.on('end', () => { try { resolve(raw ? JSON.parse(raw) : {}); } catch { reject(new Error('Invalid JSON')); } });
  });
}

async function route(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const { pathname } = url;

  if (req.method === 'OPTIONS') return json(res, 204, {});

  // Rate limiting
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '';
  if (!rateLimit(clientIp)) {
    return json(res, 429, { error: 'Too many requests. Please try again later.' });
  }

  // User authentication
  const user = await authMiddleware(req).catch(() => null);

  // ========== AUTH ENDPOINTS ==========

  // POST /auth/register - Register new user
  if (req.method === 'POST' && pathname === '/auth/register') {
    try {
      const body = await readBody(req);
      const { email, password, username, displayName } = body;

      if (!email || !password || !username) {
        return badRequest(res, 'Email, password, and username are required');
      }

      if (password.length < 8) {
        return badRequest(res, 'Password must be at least 8 characters');
      }

      // Check if user exists
      const { rows: existing } = await query('SELECT id FROM users WHERE email = $1 OR username = $2', [email, username]);
      if (existing.length > 0) {
        return badRequest(res, 'User with this email or username already exists');
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);
      const id = `u${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();

      await query(
        `INSERT INTO users (id, username, display_name, email, password_hash, skills, follower_count, following_count, post_count, reputation, is_online, is_mentor, is_followed_by_me, created_at)
         VALUES ($1, $2, $3, $4, $5, '', 0, 0, 0, 0, 1, 0, 0, $6)`,
        [id, username, displayName || username, email, hashedPassword, now]
      );

      // Generate token
      const token = jwt.sign({ userId: id, email }, JWT_SECRET, { expiresIn: '30d' });

      const userData = await mapUser((await query('SELECT * FROM users WHERE id = $1', [id])).rows[0]);
      return json(res, 201, { token, user: userData });
    } catch (e) {
      console.error('Register error:', e);
      return badRequest(res, 'Registration failed');
    }
  }

  // POST /auth/login - Login with email/password
  if (req.method === 'POST' && pathname === '/auth/login') {
    try {
      const body = await readBody(req);
      const { email, password } = body;

      if (!email || !password) {
        return badRequest(res, 'Email and password are required');
      }

      const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
      if (rows.length === 0) {
        return unauthorized(res, 'Invalid email or password');
      }

      const user = rows[0];
      const validPassword = await bcrypt.compare(password, user.password_hash || '');
      if (!validPassword) {
        return unauthorized(res, 'Invalid email or password');
      }

      // Update online status
      await query('UPDATE users SET is_online = 1 WHERE id = $1', [user.id]);

      const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });
      const userData = await mapUser(user);
      return json(res, 200, { token, user: userData });
    } catch (e) {
      console.error('Login error:', e);
      return badRequest(res, 'Login failed');
    }
  }

  // POST /auth/forgot-password - Request password reset
  if (req.method === 'POST' && pathname === '/auth/forgot-password') {
    try {
      const body = await readBody(req);
      const email = String(body.email || '').trim().toLowerCase();
      if (!email) {
        return badRequest(res, 'Email is required');
      }

      const { rows } = await query('SELECT id FROM users WHERE LOWER(email) = $1', [email]);
      if (rows.length > 0) {
        const notificationId = createdId('n');
        await query(
          'INSERT INTO notifications (id, type, title, body, from_user_id, is_read, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [
            notificationId,
            'SECURITY',
            'Password recovery requested',
            'A password recovery request was received for your account. Use the latest recovery email to continue.',
            rows[0].id,
            0,
            new Date().toISOString(),
          ],
        );
      }

      return json(res, 200, {
        success: true,
        message: 'If an account exists for that email, recovery instructions have been queued.',
      });
    } catch (e) {
      console.error('Forgot password error:', e);
      return badRequest(res, 'Failed to start password recovery');
    }
  }

  // POST /auth/change-password - Change password
  if (req.method === 'POST' && pathname === '/auth/change-password') {
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const body = await readBody(req);
      const { currentPassword, newPassword } = body;

      if (!currentPassword || !newPassword) {
        return badRequest(res, 'Current password and new password are required');
      }

      if (newPassword.length < 8) {
        return badRequest(res, 'New password must be at least 8 characters');
      }

      const { rows } = await query('SELECT * FROM users WHERE id = $1', [user.userId]);
      if (rows.length === 0) return notFound(res);

      const dbUser = rows[0];
      const validPassword = await bcrypt.compare(currentPassword, dbUser.password_hash || '');
      if (!validPassword) {
        return badRequest(res, 'Current password is incorrect');
      }

      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await query('UPDATE users SET password_hash = $1 WHERE id = $2', [hashedPassword, user.userId]);

      return json(res, 200, { success: true, message: 'Password changed successfully' });
    } catch (e) {
      console.error('Change password error:', e);
      return badRequest(res, 'Failed to change password');
    }
  }

  // GET /auth/github - Get GitHub OAuth URL
  if (req.method === 'GET' && pathname === '/auth/github') {
    if (!GITHUB_CLIENT_ID) {
      return json(res, 200, {
        oauthUrl: null,
        message: 'GitHub OAuth not configured. Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET environment variables.'
      });
    }
    const redirectUri = `http://localhost:8080/auth/github/callback`;
    const oauthUrl = `https://github.com/login/oauth/authorize?client_id=${GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=read:user,user:email`;
    return json(res, 200, { oauthUrl });
  }

  // POST /auth/github/callback - Exchange code for GitHub user (simplified - for demo without real GitHub app)
  if (req.method === 'POST' && pathname === '/auth/github/callback') {
    try {
      const body = await readBody(req);
      const { code } = body;

      // For demo purposes, if no real GitHub app, simulate OAuth with existing user
      if (!GITHUB_CLIENT_ID || !code) {
        // Simulate GitHub OAuth by returning existing user u1
        const { rows } = await query('SELECT * FROM users WHERE id = $1', ['u1']);
        const user = rows[0];
        const token = jwt.sign({ userId: user.id, email: user.email, provider: 'github' }, JWT_SECRET, { expiresIn: '30d' });
        const userData = await mapUser(user);
        return json(res, 200, { token, user: userData, provider: 'github-demo' });
      }

      // Real GitHub OAuth would exchange code for token here
      // For now, return demo user
      const { rows } = await query('SELECT * FROM users WHERE id = $1', ['u1']);
      const user = rows[0];
      const token = jwt.sign({ userId: user.id, email: user.email, provider: 'github' }, JWT_SECRET, { expiresIn: '30d' });
      const userData = await mapUser(user);
      return json(res, 200, { token, user: userData, provider: 'github' });
    } catch (e) {
      console.error('GitHub OAuth error:', e);
      return badRequest(res, 'GitHub authentication failed');
    }
  }

  // GET /auth/me - Get current user from token
  if (req.method === 'GET' && pathname === '/auth/me') {
    if (!user) return unauthorized(res, 'Not authenticated');
    const { rows } = await query('SELECT * FROM users WHERE id = $1', [user.userId]);
    if (rows.length === 0) return notFound(res);
    const userData = await mapUser(rows[0]);
    return json(res, 200, { user: userData });
  }

  // ========== HEALTH & STATUS ==========

  if (req.method === 'GET' && pathname === '/health') {
    try {
      await query('SELECT 1');
      return json(res, 200, { status: 'ok', database: 'postgresql', mode: 'production', auth: 'jwt-enabled' });
    } catch (e) {
      return json(res, 503, { status: 'error', database: 'postgresql', error: e.message });
    }
  }

  if (req.method === 'GET' && pathname === '/api/status') {
    return json(res, 200, {
      phase: 'production-ready',
      auth: 'jwt-enabled',
      mobileDataStrategy: 'Flutter SQLite local-first',
      backendDataStrategy: 'Node HTTP API + PostgreSQL',
      futureModules: ['analytics', 'mentorship', 'playground', 'live-code', 'ai-recommendation'],
    });
  }

  // ========== USERS ==========

  if (req.method === 'GET' && pathname === '/api/users') {
    const currentUserId = user ? user.userId : null;
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query(
      `SELECT u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
        u.follower_count, u.following_count, u.post_count, u.reputation,
        u.is_online, u.is_mentor, u.created_at,
        EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = $1 AND uf.following_id = u.id) AS is_followed_by_me
      FROM users u ORDER BY u.reputation DESC LIMIT $2 OFFSET $3`,
      [currentUserId || 'anon', limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // ========== FOLLOWERS / FOLLOWING (before :id route) ==========

  // GET /api/users/:id/followers - Get followers list
  if (req.method === 'GET' && /^\/api\/users\/[^/]+\/followers$/.test(pathname)) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const currentUserId = user ? user.userId : null;

    const { rows, rowCount } = await query(`
      SELECT u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
        u.follower_count, u.following_count, u.post_count, u.reputation,
        u.is_online, u.is_mentor, u.created_at,
        EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = $1 AND uf.following_id = u.id) AS is_followed_by_me
      FROM users u
      INNER JOIN user_follows f ON f.follower_id = u.id
      WHERE f.following_id = $2
      ORDER BY f.created_at DESC
      LIMIT $3 OFFSET $4`,
      [currentUserId || 'anon', targetUserId, limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // GET /api/users/:id/following - Get following list
  if (req.method === 'GET' && /^\/api\/users\/[^/]+\/following$/.test(pathname)) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const currentUserId = user ? user.userId : null;

    const { rows, rowCount } = await query(`
      SELECT u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
        u.follower_count, u.following_count, u.post_count, u.reputation,
        u.is_online, u.is_mentor, u.created_at,
        EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = $1 AND uf.following_id = u.id) AS is_followed_by_me
      FROM users u
      INNER JOIN user_follows f ON f.following_id = u.id
      WHERE f.follower_id = $2
      ORDER BY f.created_at DESC
      LIMIT $3 OFFSET $4`,
      [currentUserId || 'anon', targetUserId, limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // ========== NOTIFICATION SETTINGS (before :id route) ==========

  // GET /api/users/me/notification-settings - Get notification settings
  if (req.method === 'GET' && pathname === '/api/users/me/notification-settings') {
    if (!user) return unauthorized(res, 'Not authenticated');

    // Return default notification settings
    return json(res, 200, {
      pushEnabled: true,
      emailEnabled: false,
      types: {
        likes: true,
        comments: true,
        follows: true,
        mentions: true,
        directMessages: true,
      },
      quietHours: {
        enabled: false,
        start: '22:00',
        end: '08:00',
      },
    });
  }

  // PUT /api/users/me/notification-settings - Update notification settings
  if (req.method === 'PUT' && pathname === '/api/users/me/notification-settings') {
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const body = await readBody(req);

      // In production: save to database
      // For demo: return updated settings
      const settings = {
        pushEnabled: body.pushEnabled ?? true,
        emailEnabled: body.emailEnabled ?? false,
        types: {
          likes: body.types?.likes ?? true,
          comments: body.types?.comments ?? true,
          follows: body.types?.follows ?? true,
          mentions: body.types?.mentions ?? true,
          directMessages: body.types?.directMessages ?? true,
        },
        quietHours: {
          enabled: body.quietHours?.enabled ?? false,
          start: body.quietHours?.start ?? '22:00',
          end: body.quietHours?.end ?? '08:00',
        },
      };

      return json(res, 200, settings);
    } catch (e) {
      console.error('Update notification settings error:', e);
      return badRequest(res, 'Failed to update notification settings');
    }
  }

  // ========== USERS ==========

  if (
    req.method === 'GET' &&
    pathname.startsWith('/api/users/') &&
    pathname.split('/').length === 4
  ) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    // Handle /api/users/search
    if (id === 'search') {
      const q = url.searchParams.get('q') || '';
      if (q.length < 2) return json(res, 200, []);
      const currentUserId = user ? user.userId : null;
      const { rows } = await query(
        `SELECT u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
          u.follower_count, u.following_count, u.post_count, u.reputation,
          u.is_online, u.is_mentor, u.created_at,
          EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = $1 AND uf.following_id = u.id) AS is_followed_by_me
        FROM users u
        WHERE u.username ILIKE $2 OR u.display_name ILIKE $2 OR u.bio ILIKE $2
        ORDER BY u.reputation DESC LIMIT 20`,
        [currentUserId || 'anon', `%${q}%`]
      );
      const users = await Promise.all(rows.map(mapUser));
      return json(res, 200, users);
    }
    // Handle /api/users/:id
    const currentUserId = user ? user.userId : null;
    const { rows } = await query(
      `SELECT u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
        u.follower_count, u.following_count, u.post_count, u.reputation,
        u.is_online, u.is_mentor, u.created_at,
        EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = $1 AND uf.following_id = u.id) AS is_followed_by_me
      FROM users u WHERE u.id = $2`,
      [currentUserId || 'anon', id]
    );
    const mappedUser = await mapUser(rows[0]);
    return mappedUser ? json(res, 200, mappedUser) : notFound(res);
  }

  // PUT /api/users/:id - Update user profile
  if (req.method === 'PUT' && pathname.startsWith('/api/users/')) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    if (!user || user.userId !== id) return unauthorized(res, 'Not authorized to update this user');

    try {
      const body = await readBody(req);
      const { displayName, bio, skills, isOnline } = body;

      let sql = 'UPDATE users SET';
      const params = [];
      let paramIndex = 1;

      if (displayName !== undefined) {
        sql += ` display_name = $${paramIndex},`;
        params.push(displayName);
        paramIndex++;
      }
      if (bio !== undefined) {
        sql += ` bio = $${paramIndex},`;
        params.push(bio);
        paramIndex++;
      }
      if (skills !== undefined) {
        sql += ` skills = $${paramIndex},`;
        params.push(Array.isArray(skills) ? skills.join('|') : skills);
        paramIndex++;
      }
      if (isOnline !== undefined) {
        sql += ` is_online = $${paramIndex},`;
        params.push(isOnline ? 1 : 0);
        paramIndex++;
      }

      // Remove trailing comma
      sql = sql.replace(/,$/, '');
      sql += ` WHERE id = $${paramIndex}`;
      params.push(id);

      await query(sql, params);

      const { rows } = await query('SELECT * FROM users WHERE id = $1', [id]);
      const userData = await mapUser(rows[0]);
      return json(res, 200, userData);
    } catch (e) {
      console.error('Update user error:', e);
      return badRequest(res, 'Update failed');
    }
  }

  // DELETE /api/users/:id - Delete current user account
  if (req.method === 'DELETE' && /^\/api\/users\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    if (!user || user.userId !== id) {
      return unauthorized(res, 'Not authorized to delete this user');
    }

    try {
      const { rowCount } = await query('DELETE FROM users WHERE id = $1', [id]);
      if (!rowCount) return notFound(res);
      return json(res, 200, { success: true, deletedId: id });
    } catch (e) {
      console.error('Delete user error:', e);
      return badRequest(res, 'Failed to delete account');
    }
  }

  // ========== POSTS ==========

  if (req.method === 'GET' && pathname === '/api/posts') {
    const search = url.searchParams.get('search');
    const authorId = url.searchParams.get('authorId');
    const type = url.searchParams.get('type'); // foryou, following, trending
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const currentUserId = user ? user.userId : null;

    let sql;
    const params = [currentUserId || 'anon'];

    // For You tab - all posts with score ranking (hybrid algorithm)
    if (type === 'foryou' || type === null) {
      sql = `
        SELECT p.*,
          u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
          u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
          u.skills AS author_skills, u.follower_count AS author_follower_count,
          u.following_count AS author_following_count, u.post_count AS author_post_count,
          u.reputation AS author_reputation, u.is_online AS author_is_online,
          u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
          EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
          EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me,
          -- Hybrid score: engagement + recency + author reputation
          (p.like_count * 2 + p.comment_count * 3 + p.bookmark_count * 4 + p.view_count * 0.1) *
          (1 / (1 + EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 86400)) +
          u.reputation * 0.1 AS relevance_score
        FROM posts p JOIN users u ON u.id = p.author_id WHERE 1=1`;
    }
    // Following tab - posts from users you follow
    else if (type === 'following') {
      if (!currentUserId) {
        return json(res, 200, { data: [], page, limit, total: 0, message: 'Login to see posts from people you follow' });
      }
      sql = `
        SELECT p.*,
          u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
          u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
          u.skills AS author_skills, u.follower_count AS author_follower_count,
          u.following_count AS author_following_count, u.post_count AS author_post_count,
          u.reputation AS author_reputation, u.is_online AS author_is_online,
          u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
          EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
          EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me
        FROM posts p
        JOIN users u ON u.id = p.author_id
        INNER JOIN user_follows f ON f.following_id = p.author_id
        WHERE f.follower_id = $1`;
    }
    // Trending tab - posts from last 72 hours with engagement score
    else if (type === 'trending') {
      sql = `
        SELECT p.*,
          u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
          u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
          u.skills AS author_skills, u.follower_count AS author_follower_count,
          u.following_count AS author_following_count, u.post_count AS author_post_count,
          u.reputation AS author_reputation, u.is_online AS author_is_online,
          u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
          EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
          EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me,
          -- Trending score: recent engagement normalized by age
          (p.like_count * 2 + p.comment_count * 3 + p.bookmark_count * 4) *
          (1 / (1 + EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 43200)) AS trending_score
        FROM posts p JOIN users u ON u.id = p.author_id
        WHERE p.created_at > NOW() - INTERVAL '72 hours'`;
    }
    // Default: basic query
    else {
      sql = `
        SELECT p.*,
          u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
          u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
          u.skills AS author_skills, u.follower_count AS author_follower_count,
          u.following_count AS author_following_count, u.post_count AS author_post_count,
          u.reputation AS author_reputation, u.is_online AS author_is_online,
          u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
          EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
          EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me
        FROM posts p JOIN users u ON u.id = p.author_id WHERE 1=1`;
    }

    if (search) {
      sql += ' AND (p.title ILIKE $' + (params.length+1) + ' OR p.content ILIKE $' + (params.length+2) + ' OR p.tags ILIKE $' + (params.length+3) + ')';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (authorId) {
      sql += ' AND p.author_id = $' + (params.length+1);
      params.push(authorId);
    }

    // Order by appropriate score
    if (type === 'foryou') {
      sql += ' ORDER BY relevance_score DESC, p.created_at DESC';
    } else if (type === 'trending') {
      sql += ' ORDER BY trending_score DESC';
    } else {
      sql += ' ORDER BY p.created_at DESC';
    }

    sql += ' LIMIT $' + (params.length+1) + ' OFFSET $' + (params.length+2);
    params.push(limit, offset);

    const { rows, rowCount } = await query(sql, params);
    const posts = await Promise.all(rows.map(mapPost));
    return json(res, 200, { data: posts, page, limit, total: rowCount });
  }

  if (req.method === 'POST' && pathname === '/api/posts') {
    try {
      const body = await readBody(req);
      if (!body.title || !body.content) return badRequest(res, 'title and content are required');
      const authorId = body.authorId || (user ? user.userId : 'u1');
      const { rows: users } = await query('SELECT id FROM users WHERE id = $1', [authorId]);
      if (!users.length) return badRequest(res, 'authorId does not exist');
      const id = `p${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();
      const tags = Array.isArray(body.tags) ? body.tags.join('|') : '';
      await query(
        'INSERT INTO posts (id, author_id, title, content, type, tags, view_count, like_count, comment_count, bookmark_count, created_at) VALUES ($1, $2, $3, $4, $5, $6, 0, 0, 0, 0, $7)',
        [id, authorId, body.title, body.content, body.type || 'article', tags, now]
      );
      await query('UPDATE users SET post_count = post_count + 1 WHERE id = $1', [authorId]);
      const { rows: postRows } = await query(`SELECT p.*,
        u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
        u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
        u.skills AS author_skills, u.follower_count AS author_follower_count,
        u.following_count AS author_following_count, u.post_count AS author_post_count,
        u.reputation AS author_reputation, u.is_online AS author_is_online,
        u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
        FALSE AS is_liked_by_me, FALSE AS is_bookmarked_by_me
      FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $1`, [id]);
      const post = await mapPost(postRows[0]);
      return json(res, 201, post);
    } catch (e) {
      console.error('Create post error:', e);
      return badRequest(res, 'Create post failed');
    }
  }

  if (req.method === 'GET' && /^\/api\/posts\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    const currentUserId = user ? user.userId : null;
    const { rows } = await query(`
      SELECT p.*,
        u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
        u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
        u.skills AS author_skills, u.follower_count AS author_follower_count,
        u.following_count AS author_following_count, u.post_count AS author_post_count,
        u.reputation AS author_reputation, u.is_online AS author_is_online,
        u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
        EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me
      FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $2`, [currentUserId || 'anon', id]);
    const post = await mapPost(rows[0]);
    return post ? json(res, 200, post) : notFound(res);
  }

  // PATCH /api/posts/:id - Edit post
  if (req.method === 'PATCH' && /^\/api\/posts\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const { rows } = await query('SELECT author_id FROM posts WHERE id = $1', [id]);
      if (rows.length === 0) return notFound(res);
      if (rows[0].author_id !== user.userId) return unauthorized(res, 'Not authorized to edit this post');

      const body = await readBody(req);
      const { title, content, type, tags } = body;

      let sql = 'UPDATE posts SET';
      const params = [];
      let paramIndex = 1;

      if (title !== undefined) {
        sql += ` title = $${paramIndex},`;
        params.push(title);
        paramIndex++;
      }
      if (content !== undefined) {
        sql += ` content = $${paramIndex},`;
        params.push(content);
        paramIndex++;
      }
      if (type !== undefined) {
        sql += ` type = $${paramIndex},`;
        params.push(type);
        paramIndex++;
      }
      if (tags !== undefined) {
        sql += ` tags = $${paramIndex},`;
        params.push(Array.isArray(tags) ? tags.join('|') : tags);
        paramIndex++;
      }

      if (params.length === 0) {
        return badRequest(res, 'No fields to update');
      }

      // Remove trailing comma and add WHERE clause
      sql = sql.replace(/,$/, '');
      sql += ` WHERE id = $${paramIndex}`;
      params.push(id);

      await query(sql, params);

      // Fetch updated post
      const currentUserId = user.userId;
      const { rows: updatedRows } = await query(`
        SELECT p.*,
          u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
          u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
          u.skills AS author_skills, u.follower_count AS author_follower_count,
          u.following_count AS author_following_count, u.post_count AS author_post_count,
          u.reputation AS author_reputation, u.is_online AS author_is_online,
          u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
          EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked_by_me,
          EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = $1) AS is_bookmarked_by_me
        FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $2`, [currentUserId, id]);
      const post = await mapPost(updatedRows[0]);
      return json(res, 200, post);
    } catch (e) {
      console.error('Edit post error:', e);
      return badRequest(res, 'Edit post failed');
    }
  }

  // DELETE /api/posts/:id
  if (req.method === 'DELETE' && /^\/api\/posts\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    if (!user) return unauthorized(res, 'Not authenticated');

    const { rows } = await query('SELECT author_id FROM posts WHERE id = $1', [id]);
    if (rows.length === 0) return notFound(res);
    if (rows[0].author_id !== user.userId) return unauthorized(res, 'Not authorized to delete this post');

    await query('DELETE FROM posts WHERE id = $1', [id]);
    return json(res, 200, { success: true, deletedId: id });
  }

  // POST /api/posts/:id/view - Track post view
  if (req.method === 'POST' && /^\/api\/posts\/[^/]+\/view$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/')[3]);
    const viewerId = user ? user.userId : null;

    try {
      // Insert or update view record (upsert)
      if (viewerId) {
        await query(`
          INSERT INTO post_views (post_id, user_id, viewed_at)
          VALUES ($1, $2, NOW())
          ON CONFLICT (post_id, user_id) DO UPDATE SET viewed_at = NOW()
        `, [id, viewerId]);
      }

      // Increment view count
      await query('UPDATE posts SET view_count = view_count + 1 WHERE id = $1', [id]);

      return json(res, 200, { success: true, postId: id });
    } catch (e) {
      console.error('View tracking error:', e);
      return badRequest(res, 'Failed to track view');
    }
  }

  // ========== COMMENTS ==========

  if (req.method === 'GET' && /^\/api\/posts\/[^/]+\/comments$/.test(pathname)) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query(`
      SELECT c.id AS comment_id, c.content AS comment_content, c.upvotes AS comment_upvotes, c.created_at AS comment_created_at,
        u.id AS user_id, u.username AS user_username, u.display_name AS user_display_name,
        u.email AS user_email, u.avatar_url AS user_avatar_url, u.bio AS user_bio,
        u.skills AS user_skills, u.follower_count AS user_follower_count,
        u.following_count AS user_following_count, u.post_count AS user_post_count,
        u.reputation AS user_reputation, u.is_online AS user_is_online,
        u.is_mentor AS user_is_mentor, u.created_at AS user_created_at
      FROM comments c JOIN users u ON u.id = c.author_id WHERE c.post_id = $1 ORDER BY c.created_at ASC`, [postId]);
    const comments = await Promise.all(rows.map(async (r) => ({
      id: r.comment_id, content: r.comment_content, upvotes: r.comment_upvotes, createdAt: r.comment_created_at,
      author: await mapUser({ id: r.user_id, username: r.user_username, display_name: r.user_display_name,
        email: r.user_email, avatar_url: r.user_avatar_url, bio: r.user_bio, skills: r.user_skills,
        follower_count: r.user_follower_count, following_count: r.user_following_count,
        post_count: r.user_post_count, reputation: r.user_reputation, is_online: r.user_is_online,
        is_mentor: r.user_is_mentor, created_at: r.user_created_at }),
    })));
    return json(res, 200, comments);
  }

  if (req.method === 'POST' && /^\/api\/posts\/[^/]+\/comments$/.test(pathname)) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    try {
      const body = await readBody(req);
      if (!body.content) return badRequest(res, 'content is required');
      const authorId = body.authorId || (user ? user.userId : 'u1');
      const { rows: posts } = await query('SELECT id FROM posts WHERE id = $1', [postId]);
      if (!posts.length) return notFound(res);
      const id = createdId('c');
      const now = new Date().toISOString();
      await query('INSERT INTO comments (id, post_id, author_id, content, upvotes, created_at) VALUES ($1, $2, $3, $4, 0, $5)', [id, postId, authorId, body.content, now]);
      await query('UPDATE posts SET comment_count = comment_count + 1 WHERE id = $1', [postId]);
      return json(res, 201, { id, postId, authorId, content: body.content, upvotes: 0, createdAt: now });
    } catch (e) {
      console.error('Create comment error:', e);
      return badRequest(res, 'Create comment failed');
    }
  }

  // PATCH /api/posts/:postId/comments/:commentId - Edit comment
  if (req.method === 'PATCH' && /^\/api\/posts\/[^/]+\/comments\/[^/]+$/.test(pathname)) {
    const segments = pathname.split('/');
    const postId = decodeURIComponent(segments[3]);
    const commentId = decodeURIComponent(segments[5]);
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const { rows } = await query('SELECT author_id FROM comments WHERE id = $1 AND post_id = $2', [commentId, postId]);
      if (!rows.length) return notFound(res);
      if (rows[0].author_id !== user.userId) return unauthorized(res, 'Not authorized to edit this comment');

      const body = await readBody(req);
      if (!body.content) return badRequest(res, 'content is required');

      await query('UPDATE comments SET content = $1 WHERE id = $2', [body.content, commentId]);
      return json(res, 200, { success: true, id: commentId, content: body.content });
    } catch (e) {
      console.error('Edit comment error:', e);
      return badRequest(res, 'Failed to edit comment');
    }
  }

  // DELETE /api/posts/:postId/comments/:commentId
  if (req.method === 'DELETE' && /^\/api\/posts\/[^/]+\/comments\/[^/]+$/.test(pathname)) {
    const segments = pathname.split('/');
    const postId = decodeURIComponent(segments[3]);
    const commentId = decodeURIComponent(segments[5]);
    if (!user) return unauthorized(res, 'Not authenticated');
    const { rows } = await query('SELECT author_id FROM comments WHERE id = $1 AND post_id = $2', [commentId, postId]);
    if (!rows.length) return notFound(res);
    if (rows[0].author_id !== user.userId) return unauthorized(res, 'Not authorized');
    await query('DELETE FROM comments WHERE id = $1', [commentId]);
    await query('UPDATE posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = $1', [postId]);
    return json(res, 200, { success: true, deletedId: commentId });
  }

  // ========== PROJECTS ==========

  if (req.method === 'GET' && pathname === '/api/projects') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query(`
      SELECT p.*,
        u.id AS owner_id, u.username AS owner_username, u.display_name AS owner_display_name,
        u.email AS owner_email, u.avatar_url AS owner_avatar_url, u.bio AS owner_bio,
        u.skills AS owner_skills, u.follower_count AS owner_follower_count,
        u.following_count AS owner_following_count, u.post_count AS owner_post_count,
        u.reputation AS owner_reputation, u.is_online AS owner_is_online,
        u.is_mentor AS owner_is_mentor, u.created_at AS owner_created_at
      FROM projects p JOIN users u ON u.id = p.owner_id ORDER BY p.created_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    const projects = await Promise.all(rows.map(mapProject));
    return json(res, 200, { data: projects, page, limit, total: rowCount });
  }

  // POST /api/projects - Create project
  if (req.method === 'POST' && pathname === '/api/projects') {
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const body = await readBody(req);
      const title = String(body.title || '').trim();
      const description = String(body.description || '').trim();
      const techStack = Array.isArray(body.techStack)
        ? body.techStack.map((item) => String(item).trim()).filter(Boolean)
        : [];
      const maxMembers = Math.min(20, Math.max(2, Number(body.maxMembers || 5)));

      if (!title || !description) {
        return badRequest(res, 'Title and description are required');
      }

      const id = createdId('proj');
      const now = new Date().toISOString();
      await query(
        `INSERT INTO projects (id, owner_id, title, description, tech_stack, status, member_count, max_members, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          id,
          user.userId,
          title,
          description,
          techStack.join('|'),
          'LOOKING_FOR_MEMBERS',
          1,
          maxMembers,
          now,
        ],
      );

      const { rows } = await query(`
        SELECT p.*,
          u.id AS owner_id, u.username AS owner_username, u.display_name AS owner_display_name,
          u.email AS owner_email, u.avatar_url AS owner_avatar_url, u.bio AS owner_bio,
          u.skills AS owner_skills, u.follower_count AS owner_follower_count,
          u.following_count AS owner_following_count, u.post_count AS owner_post_count,
          u.reputation AS owner_reputation, u.is_online AS owner_is_online,
          u.is_mentor AS owner_is_mentor, u.created_at AS owner_created_at
        FROM projects p JOIN users u ON u.id = p.owner_id
        WHERE p.id = $1
      `, [id]);

      const project = await mapProject(rows[0]);
      return json(res, 201, project);
    } catch (e) {
      console.error('Create project error:', e);
      return badRequest(res, 'Failed to create project');
    }
  }

  // ========== JOBS ==========

  if (req.method === 'GET' && pathname === '/api/jobs') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query('SELECT * FROM jobs ORDER BY created_at DESC LIMIT $1 OFFSET $2', [limit, offset]);
    const items = rows.map((r) => ({
      id: r.id, company: r.company, title: r.title, location: r.location,
      remote: r.remote === 1, salaryRange: r.salary_range, techStack: parseSkills(r.tech_stack),
      experience: r.experience, matchPercent: r.match_percent, createdAt: r.created_at,
    }));
    return json(res, 200, { data: items, page, limit, total: rowCount });
  }

  // ========== LEADERBOARD ==========

  if (req.method === 'GET' && pathname === '/api/leaderboard') {
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const { rows } = await query('SELECT * FROM users ORDER BY reputation DESC LIMIT $1', [limit]);
    const leaderboard = await Promise.all(rows.map(async (r, i) => ({ rank: i+1, user: await mapUser(r), points: r.reputation, rankChange: 0 })));
    return json(res, 200, leaderboard);
  }

  // ========== ANALYTICS ==========

  if (req.method === 'GET' && pathname === '/api/analytics') {
    const [
      userCountResult,
      postCountResult,
      projectCountResult,
      jobCountResult,
      activeUsersResult,
      totalViewsResult,
      topPostsResult,
    ] = await Promise.all([
      query('SELECT COUNT(*) as count FROM users'),
      query('SELECT COUNT(*) as count FROM posts'),
      query('SELECT COUNT(*) as count FROM projects'),
      query('SELECT COUNT(*) as count FROM jobs'),
      query('SELECT COUNT(*) as count FROM users WHERE is_online = 1'),
      query('SELECT COALESCE(SUM(view_count), 0) as total FROM posts'),
      query(`
        SELECT title, view_count AS views, like_count AS likes
        FROM posts
        ORDER BY view_count DESC, like_count DESC
        LIMIT 3
      `),
    ]);
    return json(res, 200, {
      totalUsers: Number(userCountResult.rows[0]?.count ?? 0),
      totalPosts: Number(postCountResult.rows[0]?.count ?? 0),
      totalProjects: Number(projectCountResult.rows[0]?.count ?? 0),
      totalJobs: Number(jobCountResult.rows[0]?.count ?? 0),
      activeUsersThisWeek: Number(activeUsersResult.rows[0]?.count ?? 0),
      totalViews: Number(totalViewsResult.rows[0]?.total ?? 0),
      topPosts: topPostsResult.rows.map((row) => ({
        title: row.title,
        views: Number(row.views ?? 0),
        likes: Number(row.likes ?? 0),
      })),
      readerStats: [
        { label: 'Mobile', pct: 0.52 },
        { label: 'Web', pct: 0.31 },
        { label: 'Backend', pct: 0.17 },
      ],
    });
  }

  // ========== CONVERSATIONS ==========

  if (req.method === 'GET' && pathname === '/api/conversations') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query(`
      SELECT c.id AS conversation_id, c.last_message, c.unread_count, c.updated_at,
        u.id AS user_id, u.username AS user_username, u.display_name AS user_display_name,
        u.email AS user_email, u.avatar_url AS user_avatar_url, u.bio AS user_bio,
        u.skills AS user_skills, u.follower_count AS user_follower_count,
        u.following_count AS user_following_count, u.post_count AS user_post_count,
        u.reputation AS user_reputation, u.is_online AS user_is_online,
        u.is_mentor AS user_is_mentor, u.created_at AS user_created_at
      FROM conversations c JOIN users u ON u.id = c.other_user_id ORDER BY c.updated_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    const convs = await Promise.all(rows.map(async (r) => ({
      id: r.conversation_id,
      otherUser: await mapUser({ id: r.user_id, username: r.user_username, display_name: r.user_display_name,
        email: r.user_email, avatar_url: r.user_avatar_url, bio: r.user_bio, skills: r.user_skills,
        follower_count: r.user_follower_count, following_count: r.user_following_count,
        post_count: r.user_post_count, reputation: r.user_reputation, is_online: r.user_is_online,
        is_mentor: r.user_is_mentor, created_at: r.user_created_at }),
      lastMessage: r.last_message, unreadCount: r.unread_count, updatedAt: r.updated_at,
    })));
    return json(res, 200, { data: convs, page, limit, total: rowCount });
  }

  if (req.method === 'GET' && /^\/api\/conversations\/[^/]+$/.test(pathname)) {
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query(`
      SELECT c.id AS conversation_id, c.last_message, c.unread_count, c.updated_at,
        u.id AS user_id, u.username AS user_username, u.display_name AS user_display_name,
        u.email AS user_email, u.avatar_url AS user_avatar_url, u.bio AS user_bio,
        u.skills AS user_skills, u.follower_count AS user_follower_count,
        u.following_count AS user_following_count, u.post_count AS user_post_count,
        u.reputation AS user_reputation, u.is_online AS user_is_online,
        u.is_mentor AS user_is_mentor, u.created_at AS user_created_at
      FROM conversations c
      JOIN users u ON u.id = c.other_user_id
      WHERE c.id = $1
      LIMIT 1`,
      [conversationId]
    );
    if (!rows.length) return notFound(res);
    const row = rows[0];
    return json(res, 200, {
      id: row.conversation_id,
      otherUser: await mapUser({
        id: row.user_id,
        username: row.user_username,
        display_name: row.user_display_name,
        email: row.user_email,
        avatar_url: row.user_avatar_url,
        bio: row.user_bio,
        skills: row.user_skills,
        follower_count: row.user_follower_count,
        following_count: row.user_following_count,
        post_count: row.user_post_count,
        reputation: row.user_reputation,
        is_online: row.user_is_online,
        is_mentor: row.user_is_mentor,
        created_at: row.user_created_at,
      }),
      lastMessage: row.last_message,
      unreadCount: row.unread_count,
      updatedAt: row.updated_at,
    });
  }

  if (req.method === 'DELETE' && /^\/api\/conversations\/[^/]+$/.test(pathname)) {
    if (!user) return unauthorized(res, 'Not authenticated');
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rowCount } = await query(
      'DELETE FROM conversations WHERE id = $1',
      [conversationId],
    );
    if (!rowCount) return notFound(res);
    return json(res, 200, { success: true, conversationId });
  }

  if (req.method === 'GET' && /^\/api\/conversations\/[^/]+\/messages$/.test(pathname)) {
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query('SELECT * FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC', [conversationId]);
    return json(res, 200, rows.map((r) => ({ id: r.id, conversationId: r.conversation_id, senderId: r.sender_id, content: r.content, type: r.type, createdAt: r.created_at })));
  }

  // PATCH /api/conversations/:id/read - Mark conversation as read
  if (req.method === 'PATCH' && /^\/api\/conversations\/[^/]+\/read$/.test(pathname)) {
    if (!user) return unauthorized(res, 'Not authenticated');
    const conversationId = decodeURIComponent(pathname.split('/')[3]);

    await query(
      'UPDATE messages SET is_read = 1 WHERE conversation_id = $1 AND sender_id <> $2',
      [conversationId, user.userId],
    );
    await query(
      'UPDATE conversations SET unread_count = 0 WHERE id = $1',
      [conversationId],
    );
    return json(res, 200, { success: true, conversationId });
  }

  // POST /api/conversations/:id/messages - Send message
  if (req.method === 'POST' && /^\/api\/conversations\/[^/]+\/messages$/.test(pathname)) {
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const body = await readBody(req);
      if (!body.content) return badRequest(res, 'content is required');

      const id = `m${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();
      const senderId = body.senderId || user.userId;

      await query(
        'INSERT INTO messages (id, conversation_id, sender_id, content, type, reactions, is_read, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [id, conversationId, senderId, body.content, body.type || 'text', '', 0, now]
      );

      // Update conversation last_message and unread_count
      await query('UPDATE conversations SET last_message = $1, updated_at = $2 WHERE id = $3', [body.content, now, conversationId]);

      return json(res, 201, { id, conversationId, senderId, content: body.content, type: body.type || 'text', createdAt: now });
    } catch (e) {
      console.error('Send message error:', e);
      return badRequest(res, 'Send message failed');
    }
  }

  // ========== NOTIFICATIONS ==========

  if (req.method === 'GET' && pathname === '/api/notifications') {
    const { rows } = await query(`
      SELECT n.*,
        u.id AS from_user_id_joined,
        u.username AS from_user_username,
        u.display_name AS from_user_display_name,
        u.email AS from_user_email,
        u.avatar_url AS from_user_avatar_url,
        u.bio AS from_user_bio,
        u.skills AS from_user_skills,
        u.follower_count AS from_user_follower_count,
        u.following_count AS from_user_following_count,
        u.post_count AS from_user_post_count,
        u.reputation AS from_user_reputation,
        u.is_online AS from_user_is_online,
        u.is_mentor AS from_user_is_mentor,
        u.created_at AS from_user_created_at
      FROM notifications n
      LEFT JOIN users u ON u.id = n.from_user_id
      ORDER BY n.created_at DESC
    `);
    const items = await Promise.all(rows.map(async (r) => ({
      id: r.id,
      type: r.type,
      title: r.title,
      body: r.body,
      isRead: r.is_read === 1,
      createdAt: r.created_at,
      fromUser: r.from_user_id_joined ? await mapUser({
        id: r.from_user_id_joined,
        username: r.from_user_username,
        display_name: r.from_user_display_name,
        email: r.from_user_email,
        avatar_url: r.from_user_avatar_url,
        bio: r.from_user_bio,
        skills: r.from_user_skills,
        follower_count: r.from_user_follower_count,
        following_count: r.from_user_following_count,
        post_count: r.from_user_post_count,
        reputation: r.from_user_reputation,
        is_online: r.from_user_is_online,
        is_mentor: r.from_user_is_mentor,
        created_at: r.from_user_created_at,
      }) : null,
    })));
    return json(res, 200, items);
  }

  // PATCH /api/notifications/:id/read - Mark notification as read
  if (req.method === 'PATCH' && /^\/api\/notifications\/[^/]+\/read$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/')[3]);
    await query('UPDATE notifications SET is_read = 1 WHERE id = $1', [id]);
    return json(res, 200, { success: true, notificationId: id });
  }

  // PATCH /api/notifications/read-all - Mark all notifications as read
  if (req.method === 'PATCH' && pathname === '/api/notifications/read-all') {
    await query('UPDATE notifications SET is_read = 1');
    return json(res, 200, { success: true });
  }

  // ========== FOLLOW / UNFOLLOW ==========

  // POST /api/users/:id/follow - Toggle follow
  if (req.method === 'POST' && pathname.startsWith('/api/users/') && pathname.endsWith('/follow')) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    if (!user) return unauthorized(res, 'Not authenticated');
    if (targetUserId === user.userId) return badRequest(res, 'Cannot follow yourself');

    // Check if already following
    const { rows: existing } = await query(
      'SELECT id FROM user_follows WHERE follower_id = $1 AND following_id = $2',
      [user.userId, targetUserId]
    );

    if (existing.length > 0) {
      // Unfollow
      await query('DELETE FROM user_follows WHERE follower_id = $1 AND following_id = $2', [user.userId, targetUserId]);
      await query('UPDATE users SET follower_count = follower_count - 1 WHERE id = $1', [targetUserId]);
      await query('UPDATE users SET following_count = following_count - 1 WHERE id = $1', [user.userId]);
      broadcast('notification', { type: 'unfollow', targetUserId, followerId: user.userId });
      return json(res, 200, { following: false, targetUserId });
    } else {
      // Follow
      const id = `f${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO user_follows (id, follower_id, following_id) VALUES ($1, $2, $3)', [id, user.userId, targetUserId]);
      await query('UPDATE users SET follower_count = follower_count + 1 WHERE id = $1', [targetUserId]);
      await query('UPDATE users SET following_count = following_count + 1 WHERE id = $1', [user.userId]);
      broadcast('notification', { type: 'follow', targetUserId, followerId: user.userId });
      return json(res, 200, { following: true, targetUserId });
    }
  }

  // ========== MEDIA UPLOAD ==========

  // POST /api/media/upload - Upload image/media
  if (req.method === 'POST' && pathname === '/api/media/upload') {
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      // Parse multipart form data
      const contentType = req.headers['content-type'] || '';
      if (!contentType.includes('multipart/form-data')) {
        return badRequest(res, 'Content-Type must be multipart/form-data');
      }

      // Simple file reading (for demo - production should use formidable/multer)
      let body = '';
      req.on('data', chunk => { body += chunk.toString(); });
      body = await new Promise(resolve => {
        let data = '';
        req.on('data', chunk => { data += chunk.toString(); });
        req.on('end', () => resolve(data));
      });

      // For demo: return mock upload response
      // Production: use multer/formidable to handle file upload
      const id = `m${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const timestamp = Date.now();
      const mockUrl = `/uploads/media/${id}_${timestamp}.jpg`;

      return json(res, 201, {
        id,
        url: mockUrl,
        thumbnailUrl: mockUrl,
        message: 'Media upload endpoint ready. Configure multer for actual file handling.'
      });
    } catch (e) {
      console.error('Media upload error:', e);
      return badRequest(res, 'Failed to upload media');
    }
  }

  // ========== LIKE / UNLIKE POST ==========

  // POST /api/posts/:id/like - Toggle like
  if (req.method === 'POST' && pathname.startsWith('/api/posts/') && pathname.endsWith('/like')) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    const currentUserId = user ? user.userId : null;
    if (!currentUserId) return unauthorized(res, 'Not authenticated');

    const { rows: existing } = await query(
      'SELECT id FROM post_likes WHERE post_id = $1 AND user_id = $2',
      [postId, currentUserId]
    );

    if (existing.length > 0) {
      // Unlike
      await query('DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);
      await query('UPDATE posts SET like_count = like_count - 1 WHERE id = $1', [postId]);
      return json(res, 200, { liked: false, postId });
    } else {
      // Like
      const id = `pl${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO post_likes (id, post_id, user_id) VALUES ($1, $2, $3)', [id, postId, currentUserId]);
      await query('UPDATE posts SET like_count = like_count + 1 WHERE id = $1', [postId]);
      return json(res, 200, { liked: true, postId });
    }
  }

  // ========== BOOKMARK / UNBOOKMARK POST ==========

  // POST /api/posts/:id/bookmark - Toggle bookmark
  if (req.method === 'POST' && pathname.startsWith('/api/posts/') && pathname.endsWith('/bookmark')) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    const currentUserId = user ? user.userId : null;
    if (!currentUserId) return unauthorized(res, 'Not authenticated');

    const { rows: existing } = await query(
      'SELECT id FROM post_bookmarks WHERE post_id = $1 AND user_id = $2',
      [postId, currentUserId]
    );

    if (existing.length > 0) {
      // Unbookmark
      await query('DELETE FROM post_bookmarks WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);
      await query('UPDATE posts SET bookmark_count = bookmark_count - 1 WHERE id = $1', [postId]);
      return json(res, 200, { bookmarked: false, postId });
    } else {
      // Bookmark
      const id = `pb${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO post_bookmarks (id, post_id, user_id) VALUES ($1, $2, $3)', [id, postId, currentUserId]);
      await query('UPDATE posts SET bookmark_count = bookmark_count + 1 WHERE id = $1', [postId]);
      return json(res, 200, { bookmarked: true, postId });
    }
  }

  // GET /api/posts/bookmarked - Get bookmarked posts
  if (req.method === 'GET' && pathname === '/api/posts/bookmarked') {
    const currentUserId = user ? user.userId : 'anon';
    const { rows } = await query(`
      SELECT p.*,
        u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
        u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
        u.skills AS author_skills, u.follower_count AS author_follower_count,
        u.following_count AS author_following_count, u.post_count AS author_post_count,
        u.reputation AS author_reputation, u.is_online AS author_is_online,
        u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
        1 AS is_bookmarked_by_me
      FROM posts p
      JOIN users u ON u.id = p.author_id
      JOIN post_bookmarks pb ON pb.post_id = p.id
      WHERE pb.user_id = $1
      ORDER BY pb.created_at DESC`, [currentUserId]);
    const posts = await Promise.all(rows.map(mapPost));
    return json(res, 200, posts);
  }

  // ========== JOBS SEARCH ==========

  if (req.method === 'GET' && pathname === '/api/jobs/search') {
    const q = url.searchParams.get('q') || '';
    const tech = url.searchParams.get('tech') || '';
    const remote = url.searchParams.get('remote');
    let sql = 'SELECT * FROM jobs WHERE 1=1';
    const params = [];
    let i = 1;
    if (q) { sql += ` AND (title ILIKE $${i} OR company ILIKE $${i})`; params.push(`%${q}%`); i++; }
    if (tech) {
      const techs = tech.split(',');
      techs.forEach(t => { sql += ` AND tech_stack ILIKE $${i}`; params.push(`%${t}%`); i++; });
    }
    if (remote !== null) { sql += ` AND remote = $${i}`; params.push(remote === 'true' ? 1 : 0); i++; }
    sql += ' ORDER BY created_at DESC LIMIT 50';
    const { rows } = await query(sql, params);
    const items = rows.map((r) => ({
      id: r.id, company: r.company, title: r.title, location: r.location,
      remote: r.remote === 1, salaryRange: r.salary_range, techStack: parseSkills(r.tech_stack),
      experience: r.experience, matchPercent: r.match_percent, createdAt: r.created_at,
    }));
    return json(res, 200, items);
  }

  // ========== PROJECT DETAIL ==========

  if (req.method === 'GET' && pathname.startsWith('/api/projects/') && pathname !== '/api/projects') {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    const { rows } = await query(`
      SELECT p.*,
        u.id AS owner_id, u.username AS owner_username, u.display_name AS owner_display_name,
        u.email AS owner_email, u.avatar_url AS owner_avatar_url, u.bio AS owner_bio,
        u.skills AS owner_skills, u.follower_count AS owner_follower_count,
        u.following_count AS owner_following_count, u.post_count AS owner_post_count,
        u.reputation AS owner_reputation, u.is_online AS owner_is_online,
        u.is_mentor AS owner_is_mentor, u.created_at AS owner_created_at
      FROM projects p JOIN users u ON u.id = p.owner_id WHERE p.id = $1`, [id]);
    if (rows.length === 0) return notFound(res);
    const project = await mapProject(rows[0]);
    return json(res, 200, project);
  }

  const handledByExtendedRoutes = await handleExtendedRoutes({
    req,
    res,
    pathname,
    user,
    readBody,
    query,
    json,
    badRequest,
    unauthorized,
    notFound,
    parseSkills,
  });
  if (handledByExtendedRoutes) return;

  return notFound(res);
}

const server = http.createServer(async (req, res) => {
  try { await route(req, res); }
  catch (error) { console.error(error); json(res, 500, { error: 'Internal server error' }); }
});

server.listen(PORT, () => {
  console.log(`DevConnect backend running at http://localhost:${PORT}`);
  console.log(`PostgreSQL connected`);
  console.log(`JWT authentication enabled`);
  if (WebSocketServer) {
    const wsServer = http.createServer();
    wsServer.listen(WS_PORT, () => {
      setupWebSocket(wsServer);
      console.log(`WebSocket server running at ws://localhost:${WS_PORT}`);
    });
  } else {
    console.log(`WebSocket not available (ws package not installed)`);
  }
});

process.on('SIGINT', () => { pool.end(() => server.close(() => process.exit(0))); });
