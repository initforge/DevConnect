const fs = require('node:fs');

const file = process.argv[2] || 'coverage/lcov.info';
const minTotal = Number(process.env.MIN_FLUTTER_COVERAGE || 10);
const minCore = Number(process.env.MIN_CORE_COVERAGE || 80);

if (!fs.existsSync(file)) {
  console.error(`Coverage file not found: ${file}`);
  process.exit(1);
}

const text = fs.readFileSync(file, 'utf8');
const records = text.split('end_of_record').map((record) => record.trim()).filter(Boolean);

let totalFound = 0;
let totalHit = 0;
let coreFound = 0;
let coreHit = 0;

for (const record of records) {
  const source = record.match(/^SF:(.+)$/m)?.[1] || '';
  const lines = [...record.matchAll(/^DA:\d+,(\d+)/gm)].map((match) => Number(match[1]));
  const found = lines.length;
  const hit = lines.filter((count) => count > 0).length;

  totalFound += found;
  totalHit += hit;

  if (source.includes('/lib/core/') || source.includes('\\lib\\core\\') ||
      source.includes('/lib/data/repositories/') || source.includes('\\lib\\data\\repositories\\')) {
    coreFound += found;
    coreHit += hit;
  }
}

const totalPct = percentage(totalHit, totalFound);
const corePct = coreFound === 0 ? 100 : percentage(coreHit, coreFound);

console.log(`Flutter total coverage: ${totalPct.toFixed(2)}%`);
console.log(`Flutter core/repository coverage: ${corePct.toFixed(2)}%`);

if (totalPct < minTotal) {
  console.error(`Total coverage is below ${minTotal}%.`);
  process.exit(1);
}

if (corePct < minCore) {
  console.error(`Core/repository coverage is below ${minCore}%.`);
  process.exit(1);
}

function percentage(hit, found) {
  if (found === 0) return 0;
  return (hit / found) * 100;
}
