module.exports = {
  registerUserRoutes,
};

function userSelect(currentUserId) {
  const uid = currentUserId || 'anon';
  return `u.id, u.username, u.display_name, u.email, u.avatar_url, u.bio, u.skills,
    u.follower_count, u.following_count, u.post_count, u.reputation,
    u.is_online, u.is_mentor, u.created_at,
    EXISTS(SELECT 1 FROM user_follows uf WHERE uf.follower_id = '${uid}' AND uf.following_id = u.id) AS is_followed_by_me`;
}

function parseSkills(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value;
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

function mapUser(row) {
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

async function registerUserRoutes({ req, pathname, user, readBody, query, json, badRequest, unauthorized, notFound }) {
  const currentUserId = user ? user.userId : null;

  // GET /api/users
  if (req.method === 'GET' && pathname === '/api/users') {
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query(
      `SELECT ${userSelect(currentUserId)} FROM users u ORDER BY u.reputation DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // GET /api/users/:id/followers
  if (req.method === 'GET' && /^\/api\/users\/[^/]+\/followers$/.test(pathname)) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;

    const { rows, rowCount } = await query(`
      SELECT ${userSelect(currentUserId)}
      FROM users u
      INNER JOIN user_follows f ON f.follower_id = u.id
      WHERE f.following_id = $1
      ORDER BY f.created_at DESC
      LIMIT $2 OFFSET $3`,
      [targetUserId, limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // GET /api/users/:id/following
  if (req.method === 'GET' && /^\/api\/users\/[^/]+\/following$/.test(pathname)) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;

    const { rows, rowCount } = await query(`
      SELECT ${userSelect(currentUserId)}
      FROM users u
      INNER JOIN user_follows f ON f.following_id = u.id
      WHERE f.follower_id = $1
      ORDER BY f.created_at DESC
      LIMIT $2 OFFSET $3`,
      [targetUserId, limit, offset]
    );
    const users = await Promise.all(rows.map(mapUser));
    return json(res, 200, { data: users, page, limit, total: rowCount });
  }

  // GET /api/users/me/notification-settings
  if (req.method === 'GET' && pathname === '/api/users/me/notification-settings') {
    if (!user) return unauthorized(res, 'Not authenticated');
    return json(res, 200, {
      pushEnabled: true,
      emailEnabled: false,
      types: { likes: true, comments: true, follows: true, mentions: true, directMessages: true },
      quietHours: { enabled: false, start: '22:00', end: '08:00' },
    });
  }

  // PUT /api/users/me/notification-settings
  if (req.method === 'PUT' && pathname === '/api/users/me/notification-settings') {
    if (!user) return unauthorized(res, 'Not authenticated');
    try {
      const body = await readBody(req);
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

  // GET /api/users/search | /api/users/:id
  if (
    req.method === 'GET' &&
    pathname.startsWith('/api/users/') &&
    pathname.split('/').length === 4
  ) {
    const url = new URL(req.url, 'http://localhost');
    const id = decodeURIComponent(pathname.split('/').at(-1));

    if (id === 'search') {
      const q = url.searchParams.get('q') || '';
      if (q.length < 2) return json(res, 200, []);
      const { rows } = await query(
        `SELECT ${userSelect(currentUserId)} FROM users u
         WHERE u.username ILIKE $1 OR u.display_name ILIKE $1 OR u.bio ILIKE $1
         ORDER BY u.reputation DESC LIMIT 20`,
        [`%${q}%`]
      );
      const users = await Promise.all(rows.map(mapUser));
      return json(res, 200, users);
    }

    const { rows } = await query(
      `SELECT ${userSelect(currentUserId)} FROM users u WHERE u.id = $1`,
      [id]
    );
    const mapped = await mapUser(rows[0]);
    return mapped ? json(res, 200, mapped) : notFound(res);
  }

  // PUT /api/users/:id
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

      sql = sql.replace(/,$/, '');
      sql += ` WHERE id = $${paramIndex}`;
      params.push(id);

      await query(sql, params);

      const { rows } = await query('SELECT * FROM users WHERE id = $1', [id]);
      const mapped = await mapUser(rows[0]);
      return json(res, 200, mapped);
    } catch (e) {
      console.error('Update user error:', e);
      return badRequest(res, 'Update failed');
    }
  }

  // DELETE /api/users/:id
  if (req.method === 'DELETE' && /^\/api\/users\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    if (!user || user.userId !== id) return unauthorized(res, 'Not authorized to delete this user');

    try {
      const { rowCount } = await query('DELETE FROM users WHERE id = $1', [id]);
      if (!rowCount) return notFound(res);
      return json(res, 200, { success: true, deletedId: id });
    } catch (e) {
      console.error('Delete user error:', e);
      return badRequest(res, 'Failed to delete account');
    }
  }

  return false;
}
