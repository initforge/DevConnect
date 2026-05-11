# CI Coverage Gate

DevConnect now treats CI coverage and static checks as the required automated
quality gate. UI E2E and screenshot parity are optional/manual checks.

## Required Jobs

- Repo hygiene: `node scripts/maintenance/repo_hygiene_check.cjs`
- Flutter static check: `flutter analyze`
- Flutter unit/widget tests: `flutter test --coverage`
- Flutter coverage baseline: `node scripts/coverage/check_lcov.cjs app/coverage/lcov.info`
- Flutter build smoke: `flutter build web`
- Backend syntax: `node --check backend/src/server.js` and route modules
- Backend API smoke: Docker backend/postgres plus `node scripts/e2e_api_check.cjs`
- AI Worker tests: `node --test ai-worker/test/*.test.js`

## Coverage Baseline

- Total Flutter coverage baseline: 10%.
- Core/repository coverage baseline: 80%.

The total baseline starts low because the project has many screen widgets and
the current tests focus on models/services/repositories. Raise
`MIN_FLUTTER_COVERAGE` gradually as widget tests are added.

## Non-Gates

- Playwright UI E2E.
- Screenshot parity and visual diff.
- Manual responsive QA.

These remain useful before demos, but they are not required for CI merge.
