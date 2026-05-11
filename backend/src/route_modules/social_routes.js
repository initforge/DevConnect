module.exports = {
  registerSocialRoutes,
};

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

async function registerSocialRoutes({ req, pathname, user, readBody, query, json, badRequest, unauthorized, notFound }) {
  const currentUserId = user ? user.userId : null;

  // ========== NOTIFICATIONS ==========

  // GET /api/notifications
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

  // PATCH /api/notifications/:id/read
  if (req.method === 'PATCH' && /^\/api\/notifications\/[^/]+\/read$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/')[3]);
    await query('UPDATE notifications SET is_read = 1 WHERE id = $1', [id]);
    return json(res, 200, { success: true, notificationId: id });
  }

  // PATCH /api/notifications/read-all
  if (req.method === 'PATCH' && pathname === '/api/notifications/read-all') {
    await query('UPDATE notifications SET is_read = 1');
    return json(res, 200, { success: true });
  }

  // ========== CONVERSATIONS ==========

  // GET /api/conversations
  if (req.method === 'GET' && pathname === '/api/conversations') {
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
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
      lastMessage: r.last_message,
      unreadCount: r.unread_count,
      updatedAt: r.updated_at,
    })));
    return json(res, 200, { data: convs, page, limit, total: rowCount });
  }

  // GET /api/conversations/:id
  if (req.method === 'GET' && /^\/api\/conversations\/[^/]+$/.test(pathname) && !pathname.endsWith('/messages') && !pathname.endsWith('/read')) {
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query(`
      SELECT c.id AS conversation_id, c.last_message, c.unread_count, c.updated_at,
        u.id AS user_id, u.username AS user_username, u.display_name AS user_display_name,
        u.email AS user_email, u.avatar_url AS user_avatar_url, u.bio AS user_bio,
        u.skills AS user_skills, u.follower_count AS user_follower_count,
        u.following_count AS user_following_count, u.post_count AS user_post_count,
        u.reputation AS user_reputation, u.is_online AS user_is_online,
        u.is_mentor AS user_is_mentor, u.created_at AS user_created_at
      FROM conversations c JOIN users u ON u.id = c.other_user_id WHERE c.id = $1 LIMIT 1`,
      [conversationId]
    );
    if (!rows.length) return notFound(res);
    const row = rows[0];
    return json(res, 200, {
      id: row.conversation_id,
      otherUser: await mapUser({ id: row.user_id, username: row.user_username, display_name: row.user_display_name,
        email: row.user_email, avatar_url: row.user_avatar_url, bio: row.user_bio, skills: row.user_skills,
        follower_count: row.user_follower_count, following_count: row.user_following_count,
        post_count: row.user_post_count, reputation: row.user_reputation, is_online: row.user_is_online,
        is_mentor: row.user_is_mentor, created_at: row.user_created_at }),
      lastMessage: row.last_message,
      unreadCount: row.unread_count,
      updatedAt: row.updated_at,
    });
  }

  // DELETE /api/conversations/:id
  if (req.method === 'DELETE' && /^\/api\/conversations\/[^/]+$/.test(pathname)) {
    if (!user) return unauthorized(res, 'Not authenticated');
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rowCount } = await query('DELETE FROM conversations WHERE id = $1', [conversationId]);
    if (!rowCount) return notFound(res);
    return json(res, 200, { success: true, conversationId });
  }

  // GET /api/conversations/:id/messages
  if (req.method === 'GET' && /^\/api\/conversations\/[^/]+\/messages$/.test(pathname)) {
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query(
      'SELECT * FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC',
      [conversationId]
    );
    return json(res, 200, rows.map((r) => ({
      id: r.id,
      conversationId: r.conversation_id,
      senderId: r.sender_id,
      content: r.content,
      type: r.type,
      createdAt: r.created_at,
    })));
  }

  // PATCH /api/conversations/:id/read
  if (req.method === 'PATCH' && /^\/api\/conversations\/[^/]+\/read$/.test(pathname)) {
    if (!user) return unauthorized(res, 'Not authenticated');
    const conversationId = decodeURIComponent(pathname.split('/')[3]);
    await query(
      'UPDATE messages SET is_read = 1 WHERE conversation_id = $1 AND sender_id <> $2',
      [conversationId, user.userId]
    );
    await query('UPDATE conversations SET unread_count = 0 WHERE id = $1', [conversationId]);
    return json(res, 200, { success: true, conversationId });
  }

  // POST /api/conversations/:id/messages
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
      await query('UPDATE conversations SET last_message = $1, updated_at = $2 WHERE id = $3', [body.content, now, conversationId]);

      return json(res, 201, { id, conversationId, senderId, content: body.content, type: body.type || 'text', createdAt: now });
    } catch (e) {
      console.error('Send message error:', e);
      return badRequest(res, 'Send message failed');
    }
  }

  // ========== FOLLOW / UNFOLLOW ==========

  // POST /api/users/:id/follow
  if (req.method === 'POST' && pathname.startsWith('/api/users/') && pathname.endsWith('/follow')) {
    const targetUserId = decodeURIComponent(pathname.split('/')[3]);
    if (!user) return unauthorized(res, 'Not authenticated');
    if (targetUserId === user.userId) return badRequest(res, 'Cannot follow yourself');

    const { rows: existing } = await query(
      'SELECT id FROM user_follows WHERE follower_id = $1 AND following_id = $2',
      [user.userId, targetUserId]
    );

    if (existing.length > 0) {
      await query('DELETE FROM user_follows WHERE follower_id = $1 AND following_id = $2', [user.userId, targetUserId]);
      await query('UPDATE users SET follower_count = follower_count - 1 WHERE id = $1', [targetUserId]);
      await query('UPDATE users SET following_count = following_count - 1 WHERE id = $1', [user.userId]);
      return json(res, 200, { following: false, targetUserId });
    } else {
      const id = `f${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO user_follows (id, follower_id, following_id) VALUES ($1, $2, $3)', [id, user.userId, targetUserId]);
      await query('UPDATE users SET follower_count = follower_count + 1 WHERE id = $1', [targetUserId]);
      await query('UPDATE users SET following_count = following_count + 1 WHERE id = $1', [user.userId]);
      return json(res, 200, { following: true, targetUserId });
    }
  }

  return false;
}
