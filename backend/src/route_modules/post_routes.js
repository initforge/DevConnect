module.exports = {
  registerPostRoutes,
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

function postSelect(uid) {
  return `p.*,
    u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name,
    u.email AS author_email, u.avatar_url AS author_avatar_url, u.bio AS author_bio,
    u.skills AS author_skills, u.follower_count AS author_follower_count,
    u.following_count AS author_following_count, u.post_count AS author_post_count,
    u.reputation AS author_reputation, u.is_online AS author_is_online,
    u.is_mentor AS author_is_mentor, u.created_at AS author_created_at,
    EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = '${uid}') AS is_liked_by_me,
    EXISTS(SELECT 1 FROM post_bookmarks pb WHERE pb.post_id = p.id AND pb.user_id = '${uid}') AS is_bookmarked_by_me`;
}

async function registerPostRoutes({ req, pathname, user, readBody, query, json, badRequest, unauthorized, notFound }) {
  const uid = user ? user.userId : 'anon';

  // GET /api/posts
  if (req.method === 'GET' && pathname === '/api/posts') {
    const url = new URL(req.url, 'http://localhost');
    const search = url.searchParams.get('search');
    const authorId = url.searchParams.get('authorId');
    const type = url.searchParams.get('type');
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;

    let sql;
    const params = [uid];

    if (type === 'foryou' || type === null) {
      sql = `SELECT ${postSelect(uid)},
        (p.like_count * 2 + p.comment_count * 3 + p.bookmark_count * 4 + p.view_count * 0.1) *
        (1 / (1 + EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 86400)) +
        u.reputation * 0.1 AS relevance_score
      FROM posts p JOIN users u ON u.id = p.author_id WHERE 1=1`;
    } else if (type === 'following') {
      if (!user) {
        return json(res, 200, { data: [], page, limit, total: 0, message: 'Login to see posts from people you follow' });
      }
      sql = `SELECT ${postSelect(uid)}
        FROM posts p JOIN users u ON u.id = p.author_id
        INNER JOIN user_follows f ON f.following_id = p.author_id WHERE f.follower_id = $1`;
    } else if (type === 'trending') {
      sql = `SELECT ${postSelect(uid)},
        (p.like_count * 2 + p.comment_count * 3 + p.bookmark_count * 4) *
        (1 / (1 + EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 43200)) AS trending_score
      FROM posts p JOIN users u ON u.id = p.author_id
      WHERE p.created_at > NOW() - INTERVAL '72 hours'`;
    } else {
      sql = `SELECT ${postSelect(uid)} FROM posts p JOIN users u ON u.id = p.author_id WHERE 1=1`;
    }

    if (search) {
      sql += ` AND (p.title ILIKE $${params.length + 1} OR p.content ILIKE $${params.length + 2} OR p.tags ILIKE $${params.length + 3})`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (authorId) {
      sql += ` AND p.author_id = $${params.length + 1}`;
      params.push(authorId);
    }

    if (type === 'foryou') {
      sql += ' ORDER BY relevance_score DESC, p.created_at DESC';
    } else if (type === 'trending') {
      sql += ' ORDER BY trending_score DESC';
    } else {
      sql += ' ORDER BY p.created_at DESC';
    }

    sql += ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const { rows, rowCount } = await query(sql, params);
    const posts = await Promise.all(rows.map(mapPost));
    return json(res, 200, { data: posts, page, limit, total: rowCount });
  }

  // POST /api/posts
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
      const { rows: postRows } = await query(`SELECT ${postSelect(uid)} FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $1`, [id]);
      const post = await mapPost(postRows[0]);
      return json(res, 201, post);
    } catch (e) {
      console.error('Create post error:', e);
      return badRequest(res, 'Create post failed');
    }
  }

  // GET /api/posts/:id
  if (req.method === 'GET' && /^\/api\/posts\/[^/]+$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/').at(-1));
    const { rows } = await query(`SELECT ${postSelect(uid)} FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $1`, [id]);
    const post = await mapPost(rows[0]);
    return post ? json(res, 200, post) : notFound(res);
  }

  // PATCH /api/posts/:id
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

      if (title !== undefined) { sql += ` title = $${paramIndex},`; params.push(title); paramIndex++; }
      if (content !== undefined) { sql += ` content = $${paramIndex},`; params.push(content); paramIndex++; }
      if (type !== undefined) { sql += ` type = $${paramIndex},`; params.push(type); paramIndex++; }
      if (tags !== undefined) { sql += ` tags = $${paramIndex},`; params.push(Array.isArray(tags) ? tags.join('|') : tags); paramIndex++; }

      if (params.length === 0) return badRequest(res, 'No fields to update');

      sql = sql.replace(/,$/, '');
      sql += ` WHERE id = $${paramIndex}`;
      params.push(id);

      await query(sql, params);

      const { rows: updatedRows } = await query(`SELECT ${postSelect(user.userId)} FROM posts p JOIN users u ON u.id = p.author_id WHERE p.id = $1`, [id]);
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

  // POST /api/posts/:id/view
  if (req.method === 'POST' && /^\/api\/posts\/[^/]+\/view$/.test(pathname)) {
    const id = decodeURIComponent(pathname.split('/')[3]);
    const viewerId = user ? user.userId : null;

    try {
      if (viewerId) {
        await query(`INSERT INTO post_views (post_id, user_id, viewed_at) VALUES ($1, $2, NOW()) ON CONFLICT (post_id, user_id) DO UPDATE SET viewed_at = NOW()`,
          [id, viewerId]);
      }
      await query('UPDATE posts SET view_count = view_count + 1 WHERE id = $1', [id]);
      return json(res, 200, { success: true, postId: id });
    } catch (e) {
      console.error('View tracking error:', e);
      return badRequest(res, 'Failed to track view');
    }
  }

  // GET /api/posts/:id/comments
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
      id: r.comment_id,
      content: r.comment_content,
      upvotes: r.comment_upvotes,
      createdAt: r.comment_created_at,
      author: await mapUser({ id: r.user_id, username: r.user_username, display_name: r.user_display_name,
        email: r.user_email, avatar_url: r.user_avatar_url, bio: r.user_bio, skills: r.user_skills,
        follower_count: r.user_follower_count, following_count: r.user_following_count,
        post_count: r.user_post_count, reputation: r.user_reputation, is_online: r.user_is_online,
        is_mentor: r.user_is_mentor, created_at: r.user_created_at }),
    })));
    return json(res, 200, comments);
  }

  // POST /api/posts/:id/comments
  if (req.method === 'POST' && /^\/api\/posts\/[^/]+\/comments$/.test(pathname)) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    try {
      const body = await readBody(req);
      if (!body.content) return badRequest(res, 'content is required');
      const authorId = body.authorId || (user ? user.userId : 'u1');
      const { rows: posts } = await query('SELECT id FROM posts WHERE id = $1', [postId]);
      if (!posts.length) return notFound(res);
      const id = `c${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();
      await query('INSERT INTO comments (id, post_id, author_id, content, upvotes, created_at) VALUES ($1, $2, $3, $4, 0, $5)',
        [id, postId, authorId, body.content, now]);
      await query('UPDATE posts SET comment_count = comment_count + 1 WHERE id = $1', [postId]);
      return json(res, 201, { id, postId, authorId, content: body.content, upvotes: 0, createdAt: now });
    } catch (e) {
      console.error('Create comment error:', e);
      return badRequest(res, 'Create comment failed');
    }
  }

  // PATCH /api/posts/:postId/comments/:commentId
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

  // POST /api/posts/:id/like
  if (req.method === 'POST' && pathname.startsWith('/api/posts/') && pathname.endsWith('/like')) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    const currentUserId = user ? user.userId : null;
    if (!currentUserId) return unauthorized(res, 'Not authenticated');

    const { rows: existing } = await query('SELECT id FROM post_likes WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);

    if (existing.length > 0) {
      await query('DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);
      await query('UPDATE posts SET like_count = like_count - 1 WHERE id = $1', [postId]);
      return json(res, 200, { liked: false, postId });
    } else {
      const id = `pl${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO post_likes (id, post_id, user_id) VALUES ($1, $2, $3)', [id, postId, currentUserId]);
      await query('UPDATE posts SET like_count = like_count + 1 WHERE id = $1', [postId]);
      return json(res, 200, { liked: true, postId });
    }
  }

  // POST /api/posts/:id/bookmark
  if (req.method === 'POST' && pathname.startsWith('/api/posts/') && pathname.endsWith('/bookmark')) {
    const postId = decodeURIComponent(pathname.split('/')[3]);
    const currentUserId = user ? user.userId : null;
    if (!currentUserId) return unauthorized(res, 'Not authenticated');

    const { rows: existing } = await query('SELECT id FROM post_bookmarks WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);

    if (existing.length > 0) {
      await query('DELETE FROM post_bookmarks WHERE post_id = $1 AND user_id = $2', [postId, currentUserId]);
      await query('UPDATE posts SET bookmark_count = bookmark_count - 1 WHERE id = $1', [postId]);
      return json(res, 200, { bookmarked: false, postId });
    } else {
      const id = `pb${Date.now()}${Math.floor(Math.random() * 1000)}`;
      await query('INSERT INTO post_bookmarks (id, post_id, user_id) VALUES ($1, $2, $3)', [id, postId, currentUserId]);
      await query('UPDATE posts SET bookmark_count = bookmark_count + 1 WHERE id = $1', [postId]);
      return json(res, 200, { bookmarked: true, postId });
    }
  }

  // GET /api/posts/bookmarked
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
      FROM posts p JOIN users u ON u.id = p.author_id
      JOIN post_bookmarks pb ON pb.post_id = p.id WHERE pb.user_id = $1
      ORDER BY pb.created_at DESC`, [currentUserId]);
    const posts = await Promise.all(rows.map(mapPost));
    return json(res, 200, posts);
  }

  return false;
}
