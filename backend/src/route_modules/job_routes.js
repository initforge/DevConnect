module.exports = {
  registerJobRoutes,
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

function mapJob(row) {
  return {
    id: row.id,
    company: row.company,
    title: row.title,
    location: row.location,
    remote: row.remote === 1,
    salaryRange: row.salary_range,
    techStack: parseSkills(row.tech_stack),
    experience: row.experience,
    matchPercent: row.match_percent,
    createdAt: row.created_at,
  };
}

async function registerJobRoutes({ req, pathname, readBody, query, json }) {
  // GET /api/jobs
  if (req.method === 'GET' && pathname === '/api/jobs') {
    const page = Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(new URL(req.url, 'http://localhost').searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;
    const { rows, rowCount } = await query(
      'SELECT * FROM jobs ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    const items = rows.map(mapJob);
    return json(res, 200, { data: items, page, limit, total: rowCount });
  }

  // GET /api/jobs/search
  if (req.method === 'GET' && pathname === '/api/jobs/search') {
    const url = new URL(req.url, 'http://localhost');
    const q = url.searchParams.get('q') || '';
    const tech = url.searchParams.get('tech') || '';
    const remote = url.searchParams.get('remote');
    let sql = 'SELECT * FROM jobs WHERE 1=1';
    const params = [];
    let i = 1;
    if (q) {
      sql += ` AND (title ILIKE $${i} OR company ILIKE $${i})`;
      params.push(`%${q}%`);
      i++;
    }
    if (tech) {
      const techs = tech.split(',');
      techs.forEach(t => { sql += ` AND tech_stack ILIKE $${i}`; params.push(`%${t}%`); i++; });
    }
    if (remote !== null) {
      sql += ` AND remote = $${i}`;
      params.push(remote === 'true' ? 1 : 0);
      i++;
    }
    sql += ' ORDER BY created_at DESC LIMIT 50';
    const { rows } = await query(sql, params);
    return json(res, 200, rows.map(mapJob));
  }

  return false;
}
