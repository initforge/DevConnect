const http = require('node:http');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('node:crypto');

const { handleExtendedRoutes } = require('./route_modules/extended_routes');
const { registerAuthRoutes } = require('./route_modules/auth_routes');
const { registerUserRoutes } = require('./route_modules/user_routes');
const { registerPostRoutes } = require('./route_modules/post_routes');
const { registerProjectRoutes } = require('./route_modules/project_routes');
const { registerJobRoutes } = require('./route_modules/job_routes');
const { registerSocialRoutes } = require('./route_modules/social_routes');
const { registerAnalyticsRoutes } = require('./route_modules/analytics_routes');
const { registerMediaRoutes } = require('./route_modules/media_routes');

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

function broadcast(channel, message) {
  const msg = JSON.stringify({ channel, ...message });
  for (const [clientId, client] of wsClients) {
    if (client.ws.readyState === 1) {
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

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => { raw += chunk; if (raw.length > 1_000_000) req.destroy(); });
    req.on('end', () => { try { resolve(raw ? JSON.parse(raw) : {}); } catch { reject(new Error('Invalid JSON')); } });
  });
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

  // Shared context passed to every route module
  const ctx = { req, res, pathname, user, readBody, query, json, badRequest, unauthorized, notFound, broadcast };

  // ========== AUTH ENDPOINTS ==========
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

  // Route: auth/*
  if (pathname.startsWith('/auth/')) {
    const handled = await registerAuthRoutes({ ...ctx, JWT_SECRET, GITHUB_CLIENT_ID });
    if (handled) return;
  }

  // Route: users/*
  if (pathname.startsWith('/api/users/')) {
    const handled = await registerUserRoutes(ctx);
    if (handled) return;
  }

  // Route: posts/*
  if (pathname.startsWith('/api/posts')) {
    const handled = await registerPostRoutes(ctx);
    if (handled) return;
  }

  // Route: projects/*
  if (pathname.startsWith('/api/projects')) {
    const handled = await registerProjectRoutes(ctx);
    if (handled) return;
  }

  // Route: jobs/*
  if (pathname.startsWith('/api/jobs')) {
    const handled = await registerJobRoutes(ctx);
    if (handled) return;
  }

  // Route: conversations, notifications, follow
  if (pathname.startsWith('/api/conversations') || pathname.startsWith('/api/notifications')) {
    const handled = await registerSocialRoutes(ctx);
    if (handled) return;
  }

  // Route: follow
  if (pathname.startsWith('/api/users/') && pathname.endsWith('/follow')) {
    const handled = await registerSocialRoutes(ctx);
    if (handled) return;
  }

  // Route: leaderboard, analytics
  if (pathname === '/api/leaderboard' || pathname === '/api/analytics') {
    const handled = await registerAnalyticsRoutes(ctx);
    if (handled) return;
  }

  // Route: media
  if (pathname === '/api/media/upload') {
    const handled = await registerMediaRoutes(ctx);
    if (handled) return;
  }

  // Route: extended (AI + misc)
  const handledByExtendedRoutes = await handleExtendedRoutes(ctx);
  if (handledByExtendedRoutes) return;

  return notFound(res);
}

function createHttpServer() {
  return http.createServer(async (req, res) => {
    try {
      await route(req, res);
    } catch (error) {
      console.error(error);
      json(res, 500, { error: 'Internal server error' });
    }
  });
}

function startServer({ port = PORT, wsPort = WS_PORT } = {}) {
  const server = createHttpServer();
  server.listen(port, () => {
    console.log('DevConnect backend running at http://localhost:' + port);
    console.log('PostgreSQL connected');
    console.log('JWT authentication enabled');
    if (WebSocketServer) {
      const wsServer = http.createServer();
      wsServer.listen(wsPort, () => {
        setupWebSocket(wsServer);
        console.log('WebSocket server running at ws://localhost:' + wsPort);
      });
    } else {
      console.log('WebSocket not available (ws package not installed)');
    }
  });
  return server;
}

module.exports = {
  createHttpServer,
  startServer,
  route,
  pool,
  query,
  json,
  badRequest,
  unauthorized,
  notFound,
  readBody,
  mapUser: null,
  mapPost: null,
  mapProject: null,
};
