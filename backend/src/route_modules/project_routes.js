module.exports = {
  registerProjectRoutes,
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

async function registerProjectRoutes({ req, pathname, user, readBody, query, json, badRequest, unauthorized, notFound }) {
  // GET /api/projects
  if (req.method === 'GET' && pathname === '/api/projects') {
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
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

  // POST /api/projects
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

      const id = `proj${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();
      await query(
        `INSERT INTO projects (id, owner_id, title, description, tech_stack, status, member_count, max_members, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [id, user.userId, title, description, techStack.join('|'), 'LOOKING_FOR_MEMBERS', 1, maxMembers, now]
      );

      const { rows } = await query(`
        SELECT p.*,
          u.id AS owner_id, u.username AS owner_username, u.display_name AS owner_display_name,
          u.email AS owner_email, u.avatar_url AS owner_avatar_url, u.bio AS owner_bio,
          u.skills AS owner_skills, u.follower_count AS owner_follower_count,
          u.following_count AS owner_following_count, u.post_count AS owner_post_count,
          u.reputation AS owner_reputation, u.is_online AS owner_is_online,
          u.is_mentor AS owner_is_mentor, u.created_at AS owner_created_at
        FROM projects p JOIN users u ON u.id = p.owner_id WHERE p.id = $1
      `, [id]);

      const project = await mapProject(rows[0]);
      return json(res, 201, project);
    } catch (e) {
      console.error('Create project error:', e);
      return badRequest(res, 'Failed to create project');
    }
  }

  // GET /api/projects/:id
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

  return false;
}
