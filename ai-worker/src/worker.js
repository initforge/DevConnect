const MAX_INPUT_CHARS = 12000;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ status: 'ok' });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    if (!isAuthorized(request, env)) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const body = await safeJson(request);
    const route = url.pathname.replace(/^\/v1\//, '');

    if (route === 'code-review') {
      return json(await codeReview(env, body));
    }
    if (route === 'explain') {
      return json(await explainCode(env, body));
    }
    if (route === 'mentorship-match') {
      return json(await mentorshipMatch(env, body));
    }

    return json({ error: 'Not found' }, 404);
  },
};

export function isAuthorized(request, env) {
  if (!env.AI_WORKER_SECRET) return true;
  return request.headers.get('x-devconnect-ai-key') === env.AI_WORKER_SECRET;
}

export async function codeReview(env, body) {
  const code = clampText(body.code || '');
  const language = String(body.language || 'text');
  const prompt = [
    `Review this ${language} snippet for a developer social app.`,
    'Return concise JSON with score, summary, and issues array.',
    'Each issue has type, severity, line, message, fix.',
    code,
  ].join('\n\n');

  const generated = await runModel(env, env.AI_MODEL_CODE_REVIEW, prompt);
  return normalizeCodeReview(generated, code, language);
}

export async function explainCode(env, body) {
  const code = clampText(body.code || '');
  const language = String(body.language || 'text');
  const level = String(body.level || 'intermediate');
  const prompt = [
    `Explain this ${language} snippet for a ${level} developer.`,
    'Return concise JSON with level, explanation, concepts, complexity, alternatives.',
    code,
  ].join('\n\n');

  const generated = await runModel(env, env.AI_MODEL_EXPLAIN, prompt);
  return normalizeExplanation(generated, level);
}

export async function mentorshipMatch(env, body) {
  const user = body.user || {};
  const mentors = Array.isArray(body.mentors) ? body.mentors.slice(0, 20) : [];
  const prompt = [
    'Rank mentorship matches for a developer social app.',
    'Return concise JSON with matches array: mentorId, score, label, reasons.',
    JSON.stringify({ user, mentors }),
  ].join('\n\n');

  const generated = await runModel(env, env.AI_MODEL_MENTORSHIP, prompt);
  return normalizeMentorship(generated, mentors);
}

async function runModel(env, model, prompt) {
  const response = await env.AI.run(model || '@cf/meta/llama-3.1-8b-instruct', {
    messages: [
      {
        role: 'system',
        content: 'You are DevConnect AI. Reply with valid compact JSON only.',
      },
      { role: 'user', content: prompt },
    ],
  });
  return response?.response || response?.result?.response || response;
}

export function normalizeCodeReview(generated, code, language) {
  const parsed = parseJson(generated);
  if (parsed && typeof parsed === 'object') {
    return {
      score: boundedNumber(parsed.score, 1, 10, 7),
      summary: String(parsed.summary || `Reviewed ${language} snippet.`),
      issues: Array.isArray(parsed.issues) ? parsed.issues.slice(0, 8) : [],
    };
  }

  return {
    score: 7,
    summary: `Reviewed ${language} snippet with Workers AI.`,
    issues: code.includes('TODO')
      ? [{
          type: 'readiness',
          severity: 'medium',
          line: 1,
          message: 'The snippet still contains TODO markers.',
          fix: 'Resolve TODO markers before publishing.',
        }]
      : [],
  };
}

export function normalizeExplanation(generated, level) {
  const parsed = parseJson(generated);
  if (parsed && typeof parsed === 'object') {
    return {
      level: String(parsed.level || level),
      explanation: String(parsed.explanation || parsed.summary || 'The snippet performs a focused workflow.'),
      concepts: Array.isArray(parsed.concepts) ? parsed.concepts.slice(0, 8) : ['Control flow'],
      complexity: String(parsed.complexity || 'Linear in the number of processed lines.'),
      alternatives: Array.isArray(parsed.alternatives) ? parsed.alternatives.slice(0, 5) : [],
    };
  }

  return {
    level,
    explanation: 'The snippet performs a focused workflow step by step.',
    concepts: ['Control flow'],
    complexity: 'Linear in the number of processed lines.',
    alternatives: ['Extract helpers if the snippet grows.'],
  };
}

export function normalizeMentorship(generated, mentors) {
  const parsed = parseJson(generated);
  if (parsed && Array.isArray(parsed.matches)) {
    return {
      matches: parsed.matches.slice(0, 10).map((item) => ({
        mentorId: String(item.mentorId || item.id || ''),
        score: boundedNumber(item.score, 1, 100, 75),
        label: String(item.label || 'Good fit'),
        reasons: Array.isArray(item.reasons) ? item.reasons.slice(0, 4) : ['Relevant profile.'],
      })).filter((item) => item.mentorId),
    };
  }

  return {
    matches: mentors.slice(0, 10).map((mentor, index) => ({
      mentorId: String(mentor.id),
      score: Math.max(55, 92 - index * 6),
      label: index === 0 ? 'Strong fit' : 'Good fit',
      reasons: ['Relevant skill profile.', `Experience signal: ${mentor.reputation || 0} XP`],
    })),
  };
}

function parseJson(value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  const text = String(value).trim();
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

function boundedNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.max(min, Math.min(max, Math.round(number)));
}

function clampText(value) {
  return String(value).slice(0, MAX_INPUT_CHARS);
}

async function safeJson(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}
