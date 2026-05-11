import test from 'node:test';
import assert from 'node:assert/strict';

import {
  isAuthorized,
  normalizeCodeReview,
  normalizeExplanation,
  normalizeMentorship,
} from '../src/worker.js';

test('authorization passes when no secret is configured', () => {
  const request = new Request('https://worker.test/v1/code-review');
  assert.equal(isAuthorized(request, {}), true);
});

test('authorization requires matching secret when configured', () => {
  const ok = new Request('https://worker.test/v1/code-review', {
    headers: { 'x-devconnect-ai-key': 'secret' },
  });
  const bad = new Request('https://worker.test/v1/code-review');
  assert.equal(isAuthorized(ok, { AI_WORKER_SECRET: 'secret' }), true);
  assert.equal(isAuthorized(bad, { AI_WORKER_SECRET: 'secret' }), false);
});

test('normalizes valid code review json', () => {
  const result = normalizeCodeReview(
    '{"score":9,"summary":"ok","issues":[]}',
    'const x = 1;',
    'javascript',
  );
  assert.equal(result.score, 9);
  assert.equal(result.summary, 'ok');
  assert.deepEqual(result.issues, []);
});

test('normalizes malformed code review output with fallback issue detection', () => {
  const result = normalizeCodeReview('not json', 'TODO: fix', 'text');
  assert.equal(result.score, 7);
  assert.equal(result.issues.length, 1);
});

test('normalizes explanation json', () => {
  const result = normalizeExplanation(
    '{"level":"beginner","explanation":"reads input","concepts":["I/O"],"complexity":"linear","alternatives":["split"]}',
    'intermediate',
  );
  assert.equal(result.level, 'beginner');
  assert.deepEqual(result.concepts, ['I/O']);
});

test('normalizes mentorship fallback from mentor list', () => {
  const result = normalizeMentorship('bad json', [
    { id: 'u1', reputation: 3000 },
    { id: 'u2', reputation: 1000 },
  ]);
  assert.equal(result.matches.length, 2);
  assert.equal(result.matches[0].mentorId, 'u1');
});
