const fs = require('node:fs');
const { execFileSync } = require('node:child_process');

const tracked = execFileSync('git', ['ls-files'], { encoding: 'utf8' })
  .split(/\r?\n/)
  .filter(Boolean);

const rows = tracked.map((file) => {
  const exists = fs.existsSync(file);
  const stat = exists ? fs.statSync(file) : null;
  return {
    file,
    exists,
    bytes: stat?.size || 0,
    category: categoryFor(file),
  };
});

const byCategory = rows.reduce((acc, row) => {
  acc[row.category] ||= { count: 0, bytes: 0 };
  acc[row.category].count += 1;
  acc[row.category].bytes += row.bytes;
  return acc;
}, {});

console.log('# Repo Inventory');
console.log('');
console.log('| Category | Files | Bytes |');
console.log('|---|---:|---:|');
for (const [category, value] of Object.entries(byCategory).sort()) {
  console.log(`| ${category} | ${value.count} | ${value.bytes} |`);
}

console.log('');
console.log('## Largest tracked files');
console.log('');
console.log('| File | Bytes | Category |');
console.log('|---|---:|---|');
for (const row of rows.filter((item) => item.exists).sort((a, b) => b.bytes - a.bytes).slice(0, 30)) {
  console.log(`| ${row.file} | ${row.bytes} | ${row.category} |`);
}

function categoryFor(file) {
  if (file.startsWith('app/lib/')) return 'flutter-source';
  if (file.startsWith('app/test/')) return 'flutter-tests';
  if (file.startsWith('app/integration_test/')) return 'flutter-integration-tests';
  if (file.startsWith('backend/src/')) return 'backend-source';
  if (file.startsWith('backend/scripts/')) return 'backend-scripts';
  if (file.startsWith('docs/showcase/')) return 'showcase-docs';
  if (file.startsWith('docs/')) return 'docs';
  if (file.startsWith('deliverables/')) return 'deliverables';
  if (file.startsWith('scripts/')) return 'automation-scripts';
  if (file.startsWith('ai-worker/')) return 'ai-worker';
  if (file.match(/\.(png|jpg|jpeg|gif|pdf|pptx)$/i)) return 'binary-assets';
  return 'project-config';
}
