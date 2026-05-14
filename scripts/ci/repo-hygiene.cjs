const fs = require('node:fs');
const { execFileSync } = require('node:child_process');

const tracked = execFileSync('git', ['ls-files'], { encoding: 'utf8' })
  .split(/\r?\n/)
  .filter(Boolean);

const forbidden = [
  /^output\//,
  /^app\/build\//,
  /^app\/\.dart_tool\//,
  /^node_modules\//,
  /^\.env$/,
  /^.*\/\.env$/,
  /^app\/screenshots\/ui[0-9_]*\.xml$/,
  /^app\/screenshots\/screen\.png$/,
  /^app\/screenshot\.png$/,
];

const offenders = tracked.filter((file) =>
  fs.existsSync(file) && forbidden.some((pattern) => pattern.test(file)));

if (offenders.length) {
  console.error('Tracked generated/debug artifacts found:');
  for (const file of offenders) console.error(`- ${file}`);
  process.exit(1);
}

console.log('Repo hygiene check passed.');
