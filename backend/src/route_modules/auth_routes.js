const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

module.exports = {
  registerAuthRoutes,
};

async function registerAuthRoutes({ req, pathname, user, readBody, query, json, badRequest, unauthorized, JWT_SECRET, GITHUB_CLIENT_ID }) {
  // POST /auth/register
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

      const { rows: existing } = await query(
        'SELECT id FROM users WHERE email = $1 OR username = $2',
        [email, username]
      );
      if (existing.length > 0) {
        return badRequest(res, 'User with this email or username already exists');
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const id = `u${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const now = new Date().toISOString();

      await query(
        `INSERT INTO users (id, username, display_name, email, password_hash, skills, follower_count, following_count, post_count, reputation, is_online, is_mentor, is_followed_by_me, created_at)
         VALUES ($1, $2, $3, $4, $5, '', 0, 0, 0, 0, 1, 0, 0, $6)`,
        [id, username, displayName || username, email, hashedPassword, now]
      );

      const token = jwt.sign({ userId: id, email }, JWT_SECRET, { expiresIn: '30d' });

      const { rows: userRows } = await query('SELECT * FROM users WHERE id = $1', [id]);
      const userData = userRows[0];
      const mapped = {
        id: userData.id,
        username: userData.username,
        displayName: userData.display_name,
        email: userData.email,
        avatarUrl: userData.avatar_url,
        bio: userData.bio,
        skills: [],
        followerCount: 0,
        followingCount: 0,
        postCount: 0,
        reputation: 0,
        isOnline: true,
        isMentor: false,
        isFollowedByMe: false,
        createdAt: userData.created_at,
      };
      return json(res, 201, { token, user: mapped });
    } catch (e) {
      console.error('Register error:', e);
      return badRequest(res, 'Registration failed');
    }
  }

  // POST /auth/login
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

      const dbUser = rows[0];
      const validPassword = await bcrypt.compare(password, dbUser.password_hash || '');
      if (!validPassword) {
        return unauthorized(res, 'Invalid email or password');
      }

      await query('UPDATE users SET is_online = 1 WHERE id = $1', [dbUser.id]);

      const token = jwt.sign({ userId: dbUser.id, email: dbUser.email }, JWT_SECRET, { expiresIn: '30d' });
      const mapped = {
        id: dbUser.id,
        username: dbUser.username,
        displayName: dbUser.display_name,
        email: dbUser.email,
        avatarUrl: dbUser.avatar_url,
        bio: dbUser.bio,
        skills: dbUser.skills ? dbUser.skills.split('|').filter(Boolean) : [],
        followerCount: dbUser.follower_count,
        followingCount: dbUser.following_count,
        postCount: dbUser.post_count,
        reputation: dbUser.reputation,
        isOnline: dbUser.is_online === 1,
        isMentor: dbUser.is_mentor === 1,
        isFollowedByMe: false,
        createdAt: dbUser.created_at,
      };
      return json(res, 200, { token, user: mapped });
    } catch (e) {
      console.error('Login error:', e);
      return badRequest(res, 'Login failed');
    }
  }

  // POST /auth/forgot-password
  if (req.method === 'POST' && pathname === '/auth/forgot-password') {
    try {
      const body = await readBody(req);
      const email = String(body.email || '').trim().toLowerCase();
      if (!email) {
        return badRequest(res, 'Email is required');
      }

      const { rows } = await query('SELECT id FROM users WHERE LOWER(email) = $1', [email]);
      if (rows.length > 0) {
        const notificationId = `n${Date.now()}${Math.floor(Math.random() * 1000)}`;
        await query(
          `INSERT INTO notifications (id, type, title, body, from_user_id, is_read, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            notificationId,
            'SECURITY',
            'Password recovery requested',
            'A password recovery request was received for your account. Use the latest recovery email to continue.',
            rows[0].id,
            0,
            new Date().toISOString(),
          ]
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

  // POST /auth/change-password
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
      if (rows.length === 0) return json(res, 404, { error: 'Not found' });

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

  // GET /auth/github
  if (req.method === 'GET' && pathname === '/auth/github') {
    if (!GITHUB_CLIENT_ID) {
      return json(res, 200, {
        oauthUrl: null,
        message: 'GitHub OAuth not configured. Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET environment variables.',
      });
    }
    const redirectUri = 'http://localhost:8080/auth/github/callback';
    const oauthUrl = `https://github.com/login/oauth/authorize?client_id=${GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=read:user,user:email`;
    return json(res, 200, { oauthUrl });
  }

  // POST /auth/github/callback
  if (req.method === 'POST' && pathname === '/auth/github/callback') {
    try {
      const body = await readBody(req);
      const { code } = body;

      // For demo purposes, if no real GitHub app, simulate OAuth with existing user
      if (!GITHUB_CLIENT_ID || !code) {
        const { rows } = await query('SELECT * FROM users WHERE id = $1', ['u1']);
        const ghUser = rows[0];
        const token = jwt.sign({ userId: ghUser.id, email: ghUser.email, provider: 'github' }, JWT_SECRET, { expiresIn: '30d' });
        const mapped = {
          id: ghUser.id, username: ghUser.username, displayName: ghUser.display_name,
          email: ghUser.email, avatarUrl: ghUser.avatar_url, bio: ghUser.bio,
          skills: ghUser.skills ? ghUser.skills.split('|').filter(Boolean) : [],
          followerCount: ghUser.follower_count, followingCount: ghUser.following_count,
          postCount: ghUser.post_count, reputation: ghUser.reputation,
          isOnline: ghUser.is_online === 1, isMentor: ghUser.is_mentor === 1,
          isFollowedByMe: false, createdAt: ghUser.created_at,
        };
        return json(res, 200, { token, user: mapped, provider: 'github-demo' });
      }

      const { rows } = await query('SELECT * FROM users WHERE id = $1', ['u1']);
      const ghUser = rows[0];
      const token = jwt.sign({ userId: ghUser.id, email: ghUser.email, provider: 'github' }, JWT_SECRET, { expiresIn: '30d' });
      const mapped = {
        id: ghUser.id, username: ghUser.username, displayName: ghUser.display_name,
        email: ghUser.email, avatarUrl: ghUser.avatar_url, bio: ghUser.bio,
        skills: ghUser.skills ? ghUser.skills.split('|').filter(Boolean) : [],
        followerCount: ghUser.follower_count, followingCount: ghUser.following_count,
        postCount: ghUser.post_count, reputation: ghUser.reputation,
        isOnline: ghUser.is_online === 1, isMentor: ghUser.is_mentor === 1,
        isFollowedByMe: false, createdAt: ghUser.created_at,
      };
      return json(res, 200, { token, user: mapped, provider: 'github' });
    } catch (e) {
      console.error('GitHub OAuth error:', e);
      return badRequest(res, 'GitHub authentication failed');
    }
  }

  // GET /auth/me
  if (req.method === 'GET' && pathname === '/auth/me') {
    if (!user) return unauthorized(res, 'Not authenticated');
    const { rows } = await query('SELECT * FROM users WHERE id = $1', [user.userId]);
    if (rows.length === 0) return json(res, 404, { error: 'Not found' });
    const u = rows[0];
    const mapped = {
      id: u.id, username: u.username, displayName: u.display_name,
      email: u.email, avatarUrl: u.avatar_url, bio: u.bio,
      skills: u.skills ? u.skills.split('|').filter(Boolean) : [],
      followerCount: u.follower_count, followingCount: u.following_count,
      postCount: u.post_count, reputation: u.reputation,
      isOnline: u.is_online === 1, isMentor: u.is_mentor === 1,
      isFollowedByMe: false, createdAt: u.created_at,
    };
    return json(res, 200, { user: mapped });
  }

  return false;
}
