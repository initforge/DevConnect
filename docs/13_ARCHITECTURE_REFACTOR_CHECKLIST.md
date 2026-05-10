# Architecture Refactor Checklist

Generated: 2026-05-10

Status: completed

## Goal

Resolve the maintainability issues from the architecture review, keep the existing product behavior intact, and rerun full E2E verification.

## Scope

- Backend route structure and duplicated handlers.
- Flutter runtime configuration and dependency access.
- Shared UI maintainability without visual redesign.
- API fallback/error policy where silent failures can hide regressions.
- Generated artifact hygiene.
- Full verification after changes.

## Non-goals

- No visual redesign.
- No database schema redesign.
- No broad business-flow rewrite.
- No deletion of user-authored uncommitted work.

## Tasks

### 1. Backend Route Structure

- [x] Add a small route module boundary for late-stage utility/AI endpoints.
- [x] Move AI/code/job-apply/project-join/notification-count/user-repos/comment-vote handlers out of `backend/src/server.js`.
- [x] Remove duplicated post edit/delete handlers that are shadowed by earlier routes.
- [x] Keep response shapes and auth behavior unchanged.
- [x] Add a backend smoke/syntax check.

### 2. Flutter Runtime Config

- [x] Create a single `AppRuntimeConfig` location for `SCREENSHOT_MODE`.
- [x] Replace duplicated `bool.fromEnvironment('SCREENSHOT_MODE')` constants.
- [x] Keep screenshot route behavior unchanged.

### 3. Flutter Dependency Boundaries

- [x] Add provider definitions for services and repositories.
- [x] Migrate router shell badge loading to providers.
- [x] Leave screen migrations as explicit follow-up only where a broad rewrite would risk parity.

### 4. Shared UI Maintainability

- [x] Split `shared_widgets.dart` into a barrel plus focused part files.
- [x] Preserve public imports from `core/widgets/shared_widgets.dart`.
- [x] Avoid behavior or layout changes.

### 5. API Fallback/Error Policy

- [x] Stop silent mutation fallback where API failures should surface.
- [x] Keep read fallback for offline-first flows.
- [x] Add lightweight debug logging for swallowed offline fallbacks.

### 6. Repo Hygiene

- [x] Ignore generated Playwright/parity artifacts.
- [x] Ignore local `.playwright-cli/`.
- [x] Keep committed docs/scripts deliberate.

### 7. Verification

- [x] `flutter format` / `dart format` for touched Dart files.
- [x] Backend syntax/smoke check.
- [x] `flutter analyze`.
- [x] `flutter test`.
- [x] `flutter build web`.
- [x] API E2E.
- [x] UI E2E.
- [x] Route parity audit runtime and screenshot mode.
- [x] Visual/parity diff reports where applicable.

## Final Verification Results

- `node --check backend/src/server.js`: pass.
- `node --check backend/src/route_modules/extended_routes.js`: pass.
- `flutter analyze`: no issues found.
- `flutter test`: 112/112 pass.
- `flutter build web`: pass for runtime and `SCREENSHOT_MODE=true`.
- `node scripts/e2e_api_check.cjs`: pass.
- `node scripts/e2e_ui_flows.cjs`: 9/9 pass.
- `scripts/parity_route_audit.cjs` runtime: 20/20 pass.
- `scripts/parity_route_audit.cjs` screenshot-mode: 20/20 pass.
- `scripts/compare_route_screenshots.py`: 17 pass / 3 review / 0 fail.
- `scripts/visual_diff_showcase.py`: 11 pass / 9 review / 0 fail.

## Risk Points

- Backend route extraction can break closures if dependencies are not passed explicitly.
- Provider migration must not create provider reads outside a valid `WidgetRef`.
- Shared widget split must preserve exports to avoid widespread import churn.
- Tightening mutation errors can expose existing API failures that were previously hidden.
