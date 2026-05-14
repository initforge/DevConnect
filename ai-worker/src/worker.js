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

    // ---- Regular (non-streaming) endpoints ----

    if (route === 'code-review') {
      return json(await codeReview(env, body));
    }
    if (route === 'explain') {
      return json(await explainCode(env, body));
    }
    if (route === 'mentorship-match') {
      return json(await mentorshipMatch(env, body));
    }

    // ---- Streaming (SSE) endpoints ----

    if (route === 'code-review/stream') {
      return streamCodeReview(env, body);
    }
    if (route === 'explain/stream') {
      return streamExplainCode(env, body);
    }
    if (route === 'mentorship-match/stream') {
      return streamMentorshipMatch(env, body);
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
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    `Review this ${language} snippet for a developer social app.`,
    langInstr,
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
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    `Explain this ${language} snippet for a ${level} developer.`,
    langInstr,
    'Return concise JSON with level, explanation, concepts, complexity, alternatives.',
    code,
  ].join('\n\n');

  const generated = await runModel(env, env.AI_MODEL_EXPLAIN, prompt);
  return normalizeExplanation(generated, level);
}

export async function mentorshipMatch(env, body) {
  const user = body.user || {};
  const mentors = Array.isArray(body.mentors) ? body.mentors.slice(0, 20) : [];
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    'Rank mentorship matches for a developer social app.',
    langInstr,
    'Return concise JSON with matches array: mentorId, score, label, reasons.',
    JSON.stringify({ user, mentors }),
  ].join('\n\n');

  const generated = await runModel(env, env.AI_MODEL_MENTORSHIP, prompt, locale);
  return normalizeMentorship(generated, mentors);
}

async function runModel(env, model, prompt, locale) {
  const response = await env.AI.run(model || '@cf/meta/llama-3.1-8b-instruct', {
    messages: [
      {
        role: 'system',
        content: `You are DevConnect AI. Reply with valid compact JSON only. Respect the language instruction in the user prompt. Locale: ${locale}`,
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

// ---- Streaming helpers ----

/**
 * Create an SSE response from an async iterable of text chunks.
 */
function sseStream(asyncIterable) {
  const stream = new ReadableStream({
    async start(controller) {
      try {
        for await (const chunk of asyncIterable) {
          controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify(chunk)}\n\n`));
        }
        controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'));
      } catch (error) {
        controller.enqueue(
          new TextEncoder().encode(
            `data: ${JSON.stringify({ phase: 'error', message: error.message })}\n\n`,
          ),
        );
      }
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
      connection: 'keep-alive',
    },
  });
}

/**
 * Stream a code review via Workers AI streaming API.
 */
export async function streamCodeReview(env, body) {
  const code = clampText(body.code || '');
  const language = String(body.language || 'text');
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    `Review this ${language} snippet for a developer social app.`,
    langInstr,
    'Return progressive feedback as you think through the code.',
    'Start with an overview, then call out specific issues with line numbers.',
    code,
  ].join('\n\n');

  return streamModel(env, env.AI_MODEL_CODE_REVIEW, prompt, (text) => {
    return { phase: 'reviewing', text };
  });
}

/**
 * Stream a code explanation via Workers AI streaming API.
 */
export async function streamExplainCode(env, body) {
  const code = clampText(body.code || '');
  const language = String(body.language || 'text');
  const level = String(body.level || 'intermediate');
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    `Explain this ${language} snippet for a ${level} developer.`,
    langInstr,
    'Walk through the code step by step, building up the explanation progressively.',
    code,
  ].join('\n\n');

  return streamModel(env, env.AI_MODEL_EXPLAIN, prompt, (text) => {
    return { phase: 'explaining', text };
  });
}

/**
 * Stream a mentorship match via Workers AI streaming API.
 */
export async function streamMentorshipMatch(env, body) {
  const user = body.user || {};
  const mentors = Array.isArray(body.mentors) ? body.mentors.slice(0, 20) : [];
  const locale = String(body.locale || 'en');
  const langInstr = locale === 'vi'
    ? 'Respond entirely in Vietnamese.'
    : 'Respond entirely in English.';
  const prompt = [
    'Rank mentorship matches for a developer social app.',
    langInstr,
    'Explain your reasoning progressively as you evaluate each candidate.',
    JSON.stringify({ user, mentors }),
  ].join('\n\n');

  return streamModel(env, env.AI_MODEL_MENTORSHIP, prompt, (text) => {
    return { phase: 'matching', text };
  });
}

/**
 * Generic streaming helper that calls Workers AI with stream: true.
 */
async function streamModel(env, model, prompt, mapChunk) {
  try {
    const stream = await env.AI.run(model || '@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        {
          role: 'system',
          content: 'You are DevConnect AI. Provide helpful, progressive feedback.',
        },
        { role: 'user', content: prompt },
      ],
      stream: true,
    });

    return sseStream(async function* () {
      // Workers AI streaming returns an async iterable of Response objects
      const reader = stream.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          // value.delta contains the incremental text chunk
          const text = value?.delta || value?.response || '';
          if (text) {
            yield mapChunk(text);
          }
        }
      } finally {
        reader.releaseLock();
      }
    });
  } catch (error) {
    // Fallback: non-streaming response wrapped in a single SSE event
    return json({
      phase: 'error',
      message: `Streaming unavailable: ${error.message}`,
      fallback: true,
    });
  }
}
