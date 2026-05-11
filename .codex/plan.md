# Plan

Task id: 2026-05-11_07-24-19_resolve-residual-risks
Created: 2026-05-11T07:24:19+07:00
Updated: 2026-05-11T07:24:19+07:00
Goal: Resolve remaining risks from the production MVP pass: backend lockfile and CI npm ci, E2E/UI responsive smoke artifacts, safer backend split, and targeted long-file cleanup where practical.
Scope: CI config, backend package lock and entrypoint split, Playwright responsive smoke script/artifacts, existing E2E script stabilization, targeted Flutter long-file extraction only if low risk.
Files likely touched: .github/workflows/ci.yml, backend/package-lock.json, backend/src/server.js, backend/src/app.js or helpers, scripts/e2e_ui_flows.cjs, scripts/responsive_smoke.cjs, package.json, docs/product/MANUAL_QA_CHECKLIST.md, .codex/*
Steps: Inspect backend/server and UI scripts. Generate backend lockfile and switch CI to npm ci. Extract backend startup from route module without changing route behavior. Add/run Playwright responsive smoke with screenshots for mobile/tablet/desktop. Stabilize or document E2E script gate. Run analyze/tests/build/node checks.
Non-goals: Full feature rewrite, visual redesign, Docker API run while Docker engine is unavailable.
Verification: flutter analyze; flutter test; flutter build web; node checks; backend npm ci; Playwright responsive smoke; coverage gate if time.
Risk points: Large backend route file has many DB-dependent branches. Flutter web smoke may need local server and mocked/local storage setup. Docker remains external blocker if engine is off.
Status: in_progress
