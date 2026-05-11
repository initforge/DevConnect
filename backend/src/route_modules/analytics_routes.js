module.exports = {
  registerAnalyticsRoutes,
};

async function registerAnalyticsRoutes({ req, pathname, query, json }) {
  // GET /api/leaderboard
  if (req.method === 'GET' && pathname === '/api/leaderboard') {
    const url = new URL(req.url, 'http://localhost');
    const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '20', 10)));
    const { rows } = await query('SELECT * FROM users ORDER BY reputation DESC LIMIT $1', [limit]);
    const leaderboard = await Promise.all(rows.map(async (r, i) => {
      const mapped = {
        id: r.id,
        username: r.username,
        displayName: r.display_name,
        email: r.email,
        avatarUrl: r.avatar_url,
        bio: r.bio,
        skills: r.skills ? r.skills.split('|').filter(Boolean) : [],
        followerCount: r.follower_count,
        followingCount: r.following_count,
        postCount: r.post_count,
        reputation: r.reputation,
        isOnline: r.is_online === 1,
        isMentor: r.is_mentor === 1,
        isFollowedByMe: false,
        createdAt: r.created_at,
      };
      return { rank: i + 1, user: mapped, points: r.reputation, rankChange: 0 };
    }));
    return json(res, 200, leaderboard);
  }

  // GET /api/analytics
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
      query(`SELECT title, view_count AS views, like_count AS likes
        FROM posts ORDER BY view_count DESC, like_count DESC LIMIT 3`),
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

  return false;
}
