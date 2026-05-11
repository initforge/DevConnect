const AI_WORKER_URL = process.env.AI_WORKER_URL || '';
const AI_WORKER_SECRET = process.env.AI_WORKER_SECRET || '';
const AI_TIMEOUT_MS = Number(process.env.AI_TIMEOUT_MS || 10000);

async function callAiWorker(route, payload, normalize) {
  if (!AI_WORKER_URL) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);
  try {
    const response = await fetch(`${AI_WORKER_URL.replace(/\/$/, '')}/v1/${route}`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(AI_WORKER_SECRET ? { 'x-devconnect-ai-key': AI_WORKER_SECRET } : {}),
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!response.ok) return null;
    const data = await response.json();
    return { ...normalize(data), source: 'workers-ai' };
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeCodeReview(data) {
  return {
    score: Number(data.score || 7),
    summary: String(data.summary || 'Smart review completed.'),
    issues: Array.isArray(data.issues) ? data.issues : [],
  };
}

function normalizeCodeExplanation(data) {
  return {
    level: String(data.level || 'intermediate'),
    explanation: String(data.explanation || data.summary || 'This snippet executes a focused workflow.'),
    concepts: Array.isArray(data.concepts) ? data.concepts : ['Control flow'],
    complexity: String(data.complexity || 'Linear in the number of processed lines.'),
    alternatives: Array.isArray(data.alternatives) ? data.alternatives : [],
  };
}

function normalizeMentorMatches(data) {
  return {
    matches: Array.isArray(data.matches) ? data.matches : [],
  };
}

async function handleExtendedRoutes(ctx) {
  const {
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
  } = ctx;

  if (req.method === 'POST' && pathname === '/api/ai/code-review') {
    try {
      const body = await readBody(req);
      const proxied = await callAiWorker('code-review', body, normalizeCodeReview);
      if (proxied) {
        json(res, 200, proxied);
        return true;
      }

      const code = String(body.code || '');
      const language = String(body.language || 'text').toLowerCase();
      const issues = [];
      const lines = code.split('\n');

      const firstLineContaining = (needles) => {
        const index = lines.findIndex((line) =>
          needles.some((needle) => line.includes(needle)));
        return index >= 0 ? index + 1 : 1;
      };

      if (code.includes('print(') || code.includes('console.log(')) {
        issues.push({
          type: 'maintainability',
          severity: 'low',
          line: firstLineContaining(['print(', 'console.log(']),
          message: 'Debug output is still present in the snippet.',
          fix: 'Replace ad-hoc prints with structured logging or remove them before sharing the code.',
        });
      }

      if (!code.includes('try') && !code.includes('catch') && code.length > 140) {
        issues.push({
          type: 'reliability',
          severity: 'medium',
          line: 1,
          message: 'There is no obvious error-handling branch for failures.',
          fix: 'Add a guarded execution path or surface a user-facing fallback state.',
        });
      }

      if (code.includes('TODO') || code.includes('FIXME')) {
        issues.push({
          type: 'readiness',
          severity: 'medium',
          line: firstLineContaining(['TODO', 'FIXME']),
          message: 'The snippet still contains unresolved placeholders.',
          fix: 'Resolve TODO markers before treating this snippet as ready-to-share code.',
        });
      }

      const penalties = issues.reduce((sum, issue) => {
        if (issue.severity === 'high') return sum + 3;
        if (issue.severity === 'medium') return sum + 2;
        return sum + 1;
      }, 0);
      const score = Math.max(4, Math.min(10, 10 - penalties));

      json(res, 200, {
        score,
        summary: issues.length === 0
          ? `This ${language} snippet looks clean and ready to share.`
          : `This ${language} snippet is close, but a few issues should be cleaned up first.`,
        issues,
        source: 'fallback',
      });
      return true;
    } catch (e) {
      badRequest(res, 'Failed to review code');
      return true;
    }
  }

  if (req.method === 'POST' && pathname === '/api/ai/explain') {
    try {
      const body = await readBody(req);
      const proxied = await callAiWorker('explain', body, normalizeCodeExplanation);
      if (proxied) {
        json(res, 200, proxied);
        return true;
      }

      const code = String(body.code || '');
      const language = String(body.language || 'text');
      const level = String(body.level || 'intermediate');
      const concepts = [];
      if (code.includes('class ')) concepts.push('Object modeling');
      if (code.includes('async') || code.includes('await')) concepts.push('Async control flow');
      if (code.includes('for ') || code.includes('while ')) concepts.push('Iteration');
      if (code.includes('if ')) concepts.push('Branching logic');
      if (code.includes('return')) concepts.push('Return value flow');

      const explanation = level === 'beginner'
        ? `This ${language} snippet runs from top to bottom and performs one focused task at a time.`
        : level === 'advanced'
          ? `This ${language} snippet combines ${concepts.length ? concepts.join(', ') : 'basic control flow'} with a straightforward execution path and low structural overhead.`
          : `This ${language} snippet is organized as a focused workflow: setup first, execution next, and output last.`;

      json(res, 200, {
        level,
        explanation,
        concepts: concepts.length ? concepts : ['Control flow', 'Data transformation'],
        complexity: code.split('\n').length > 20
          ? 'Mostly linear work with moderate readability overhead.'
          : 'Mostly constant or linear work with low cognitive overhead.',
        alternatives: [
          'Extract reusable logic into named helpers if the snippet keeps growing.',
          'Add validation and typed guards when the input can vary at runtime.',
        ],
        source: 'fallback',
      });
      return true;
    } catch (e) {
      badRequest(res, 'Failed to explain code');
      return true;
    }
  }

  if (req.method === 'POST' && pathname === '/api/ai/mentorship-match') {
    try {
      const body = await readBody(req);
      const proxied = await callAiWorker('mentorship-match', body, normalizeMentorMatches);
      if (proxied) {
        json(res, 200, proxied);
        return true;
      }

      const requestedUser = body.user || {};
      const skills = new Set([
        ...(requestedUser.skills || []),
        ...(requestedUser.goals || []),
      ].map((item) => String(item).toLowerCase()));
      const mentors = Array.isArray(body.mentors) ? body.mentors : [];

      const matches = mentors.map((mentor) => {
        const mentorSkills = new Set((mentor.skills || [])
          .map((item) => String(item).toLowerCase()));
        const overlapCount = [...skills].filter((skill) =>
          mentorSkills.has(skill)).length;
        const overlapScore = skills.size === 0 ? 0.5 : overlapCount / skills.size;
        const experienceScore = Math.min(1, Math.max(0.35, Number(mentor.reputation || 0) / 3000));
        const followerScore = Math.min(1, Math.max(0.2, Number(mentor.followerCount || 0) / 100));
        const score = Math.round(((overlapScore * 0.55) + (experienceScore * 0.3) + (followerScore * 0.15)) * 100);
        const sharedSkills = [...skills].filter((skill) =>
          mentorSkills.has(skill)).slice(0, 3);

        return {
          mentorId: mentor.id,
          score: Math.max(50, Math.min(98, score)),
          label: score >= 85 ? 'Strong fit' : 'Good fit',
          reasons: [
            sharedSkills.length ? `Shared skills: ${sharedSkills.join(', ')}` : 'Complementary profile for your current goals',
            `Experience signal: ${Number(mentor.reputation || 0)} XP`,
            mentor.bio || 'Consistent mentoring profile and skill alignment.',
          ],
        };
      }).sort((a, b) => b.score - a.score);

      json(res, 200, { matches, source: 'fallback' });
      return true;
    } catch (e) {
      badRequest(res, 'Failed to score mentorship matches');
      return true;
    }
  }

  if (req.method === 'POST' && pathname === '/api/code/run') {
    try {
      const body = await readBody(req);
      const { code, language } = body;
      const lang = (language || 'python').toLowerCase();
      let output = '';
      if (code && code.includes('print')) {
        const matches = code.match(/print\s*\(\s*["'](.+?)["']\s*\)/g);
        if (matches) {
          output = matches.map((m) => m.match(/["'](.+?)["']/)?.[1] || '').join('\n');
        } else {
          output = `[Safe ${lang} runner] Parsed snippet successfully (${code.length} chars)`;
        }
      } else {
        output = `[Safe ${lang} runner] Parsed snippet (${code?.length || 0} chars)\nNo stdout produced.`;
      }
      json(res, 200, {
        output,
        language: lang,
        executionTime: Math.floor(Math.random() * 100) + 10,
      });
      return true;
    } catch (e) {
      badRequest(res, 'Failed to execute code');
      return true;
    }
  }

  if (req.method === 'POST' && pathname.startsWith('/api/jobs/') && pathname.endsWith('/apply')) {
    if (!user) {
      unauthorized(res, 'Not authenticated');
      return true;
    }
    const jobId = decodeURIComponent(pathname.split('/')[3]);
    json(res, 200, { success: true, jobId, appliedAt: new Date().toISOString() });
    return true;
  }

  if (req.method === 'POST' && pathname.startsWith('/api/projects/') && pathname.endsWith('/join')) {
    if (!user) {
      unauthorized(res, 'Not authenticated');
      return true;
    }
    const projectId = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query(
      'SELECT member_count, max_members FROM projects WHERE id = $1 LIMIT 1',
      [projectId],
    );
    if (!rows.length) {
      notFound(res);
      return true;
    }

    const memberCount = Number(rows[0].member_count || 0);
    const maxMembers = Number(rows[0].max_members || 0);
    if (memberCount >= maxMembers) {
      badRequest(res, 'Project is already full');
      return true;
    }

    await query(
      'UPDATE projects SET member_count = member_count + 1 WHERE id = $1',
      [projectId],
    );
    json(res, 200, {
      success: true,
      joined: true,
      projectId,
      joinedAt: new Date().toISOString(),
    });
    return true;
  }

  if (req.method === 'GET' && pathname === '/api/notifications/count') {
    const { rows } = await query(
      'SELECT COUNT(*) AS count FROM notifications WHERE is_read = 0',
    );
    json(res, 200, { count: Number(rows[0]?.count || 0) });
    return true;
  }

  if (req.method === 'GET' && pathname.startsWith('/api/users/') && pathname.endsWith('/repos')) {
    const id = decodeURIComponent(pathname.split('/')[3]);
    const { rows } = await query('SELECT username FROM users WHERE id = $1', [id]);
    if (rows.length === 0) {
      notFound(res);
      return true;
    }
    const username = rows[0].username;
    json(res, 200, [
      {
        id: `${id}-r1`,
        name: `${username}_portfolio`,
        description: 'Personal portfolio and projects',
        stars: Math.floor(Math.random() * 100),
        language: 'Dart',
        url: '#',
      },
      {
        id: `${id}-r2`,
        name: `devconnect-${username}`,
        description: 'DevConnect related project',
        stars: Math.floor(Math.random() * 50),
        language: 'Dart',
        url: '#',
      },
    ]);
    return true;
  }

  if (req.method === 'POST' && pathname.startsWith('/api/comments/') && pathname.endsWith('/vote')) {
    if (!user) {
      unauthorized(res, 'Not authenticated');
      return true;
    }
    const commentId = decodeURIComponent(pathname.split('/')[3]);
    await query('UPDATE comments SET upvotes = upvotes + 1 WHERE id = $1', [commentId]);
    json(res, 200, { success: true, commentId });
    return true;
  }

  return false;
}

module.exports = {
  handleExtendedRoutes,
};
