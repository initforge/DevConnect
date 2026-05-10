# Showcase / Runtime Parity Audit

Date: 2026-05-09

## Scope

Audit target:

1. "Toan bo nut hoat dong"
2. "Giu duoc visual intent cua showcase, nhung runtime phai la mot he thong rieng va dong nhat"
3. Navigation/layout parity, especially bottom navigation, feature routing, and screenshot-mode branches

How to read showcase assets:

- `docs/showcase/index.html` and `docs/showcase/screenshots/*.png` are stitched design references.
- They are useful for per-screen composition and UX direction.
- They are **not** a fully systemized source of truth for shared runtime patterns like bottom nav, app shell, route flow, or CTA conventions.
- When stitched screenshots disagree on shared elements, the runtime app must choose one canonical pattern and document it.

Method used:

- Route/shell audit in [app_router.dart](P:\midterm-mobile\app\lib\routing\app_router.dart:98)
- Shared navigation audit in [shared_widgets.dart](P:\midterm-mobile\app\lib\core\widgets\shared_widgets.dart:964)
- Dual-mode screen audit for all `SCREENSHOT_MODE` branches
- Placeholder/no-op handler sweep across `app/lib/features`
- Existing smoke test status checked separately; note that smoke render coverage is not the same as full interaction parity

## Executive Summary

Current state is **not ready** to claim either of the following:

- "Toan bo nut da hoat dong"
- "Runtime da dong nhat hoan toan voi visual intent cua showcase"

What is true today:

- Showcase assets should be read as stitched design references, not as a final system spec.
- There are **7 screens** with explicit `SCREENSHOT_MODE` branching.
- Only **Analytics** has been pulled toward a shared live/showcase content path.
- The app still uses **two different bottom-nav systems**:
  - runtime shell `NavigationBar` in [app_router.dart](P:\midterm-mobile\app\lib\routing\app_router.dart:275)
  - ad-hoc `ShowcaseBottomNav` in [shared_widgets.dart](P:\midterm-mobile\app\lib\core\widgets\shared_widgets.dart:964)
- Several screens still maintain **separate showcase widget trees**, which means visual parity and interaction parity can drift independently.
- Multiple prominent buttons are still **no-op**, **snackbar-only**, or **state-only** rather than feature-complete.

## Architecture Findings

### 1. Global navigation is not unified

Runtime shell navigation only wraps:

- `/home`
- `/explore`
- `/chat`
- `/notifications`
- `/profile`

See [app_router.dart](P:\midterm-mobile\app\lib\routing\app_router.dart:98).

Standalone feature routes like `/projects`, `/jobs`, `/leaderboard`, `/analytics`, `/playground`, `/live-code`, `/mentorship`, `/settings` live **outside** that shell in [app_router.dart](P:\midterm-mobile\app\lib\routing\app_router.dart:166).

Impact:

- Runtime layout is split between shell-managed pages and standalone pages.
- Showcase-mode screens patch this mismatch inconsistently by manually adding `ShowcaseBottomNav` on some screens but not all.
- This is the main blocker to saying runtime navigation/layout is "dong bo".

### 2. Remaining dual-mode screens still have separate widget trees

Separate showcase trees still exist in:

- [chat_list_screen.dart](P:\midterm-mobile\app\lib\features\chat\screens\chat_list_screen.dart:90)
- [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:100)
- [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:138)
- [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:65)
- [playground_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\playground_screen.dart:61)
- [live_code_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\live_code_screen.dart:12)

Analytics still has screenshot branching at [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:55), but its content tree is now shared enough to count as the only partially unified screen.

Impact:

- Any visual fix may need to be applied twice.
- Showcase layout can drift from runtime layout without failing tests.
- Buttons in showcase and runtime can have different behavior, or behavior only on one side.

### 3. The real target is not "copy every screenshot literally"

The right target for this app is:

- keep the screen-level visual direction from showcase
- keep the runtime implementation honest about what is real vs placeholder
- normalize shared system pieces into one runtime architecture

So this audit treats two things as separate failures:

1. a screen that does not preserve the showcase intent
2. a runtime app that still behaves like stitched screens instead of one product system

## Screen-by-Screen Parity Status

| Screen | Runtime data | Shared layout path | Nav parity | Button parity | Status |
|---|---|---:|---:|---:|---|
| Analytics | Yes | Partial | Partial | No | Partial |
| Projects | Yes | No | No | No | Fail |
| Chat list | Yes | No | Mixed | No | Fail |
| Create post | Yes | No | N/A | No | Fail |
| Post detail | Yes | No | No | No | Fail |
| Playground | Yes | No | No | No | Fail |
| Live code | Static | No | N/A | No | Fail |
| Jobs | Yes | Single runtime only | No shared feature-shell | Partial | Partial |
| Leaderboard | Yes | Single runtime only | No shared feature-shell | Unknown/limited | Partial |
| Mentorship | Yes | Single runtime only | No shared feature-shell | No | Partial |
| Settings | Yes | Single runtime only | No shared feature-shell | Mostly yes | Partial |

## Concrete Gaps by Screen

### Analytics

Good:

- Live data is wired from analytics + current user + posts in [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:33)
- Shared content rendering is centralized in [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:128)

Still missing:

- Range chips only change highlight state; they do not change data/query in [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:154)
- Notification bell is decorative only in [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:140)
- Chart and deltas are not driven by selected range in [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:311)

### Projects

- Runtime returns live screen; screenshot mode returns separate showcase screen in [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:65)
- Runtime has **no bottom nav**, showcase does in [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:194)
- Runtime FAB only shows snackbar in [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:71)
- Showcase FAB is no-op in [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:202)
- Showcase card CTA is no-op in [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:398)
- Runtime join action is real in [project_repository.dart](P:\midterm-mobile\app\lib\data\repositories\project_repository.dart:57)

### Chat list

- Runtime and showcase are separate trees in [chat_list_screen.dart](P:\midterm-mobile\app\lib\features\chat\screens\chat_list_screen.dart:90)
- Runtime new-chat button opens dialog in [chat_list_screen.dart](P:\midterm-mobile\app\lib\features\chat\screens\chat_list_screen.dart:121)
- Showcase header/search/conversation stack is static markup in [chat_list_screen.dart](P:\midterm-mobile\app\lib\features\chat\screens\chat_list_screen.dart:248)

### Create post

- Runtime and showcase are separate trees in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:100)
- Runtime submit is real in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:73)
- Runtime image picker is real in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:54)
- Runtime GIF action is still no-op in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:150)
- Showcase post button is no-op in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:412)
- Showcase media buttons are no-op in [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:710)

### Post detail

- Runtime and showcase are separate trees in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:138)
- Runtime share button actually copies link in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:185)
- Runtime bookmark is wired in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:83)
- Runtime follow CTA is snackbar-only in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:209)
- Showcase share/bookmark buttons are no-op in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:333)
- Showcase follow button is disabled in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:377)
- Showcase has bottom nav; runtime detail does not in [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:340)

### Playground

- Runtime and showcase are separate trees in [playground_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\playground_screen.dart:61)
- Runtime run button calls `/api/code/run` in [playground_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\playground_screen.dart:28)
- Showcase run button is no-op in [playground_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\playground_screen.dart:185)
- Showcase has bottom nav; runtime does not in [playground_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\playground_screen.dart:199)

### Live code

- Runtime and showcase are separate trees in [live_code_screen.dart](P:\midterm-mobile\app\lib\features\playground\screens\live_code_screen.dart:12)
- No primary interaction handlers are wired on either branch
- This screen is currently presentational, not feature-complete

## Placeholder / Incomplete Button Inventory

These are the clearest user-facing gaps found in the sweep:

- [ ] Analytics range chips change style only; no real filtering
  - [analytics_screen.dart](P:\midterm-mobile\app\lib\features\analytics\screens\analytics_screen.dart:154)
- [ ] Project creation FAB is roadmap snackbar only
  - [project_marketplace_screen.dart](P:\midterm-mobile\app\lib\features\projects\screens\project_marketplace_screen.dart:71)
- [ ] Create-post GIF action is no-op
  - [create_post_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\create_post_screen.dart:150)
- [ ] Post-detail follow action is snackbar only
  - [post_detail_screen.dart](P:\midterm-mobile\app\lib\features\feed\screens\post_detail_screen.dart:209)
- [ ] Search-results "Clear" button is no-op
  - [search_results_screen.dart](P:\midterm-mobile\app\lib\features\explore\screens\search_results_screen.dart:196)
- [ ] Notifications "Accept" / "Decline" buttons are no-op
  - [notifications_screen.dart](P:\midterm-mobile\app\lib\features\notifications\screens\notifications_screen.dart:139)
- [ ] Feed-card overflow menu is no-op
  - [post_card.dart](P:\midterm-mobile\app\lib\features\feed\widgets\post_card.dart:150)
- [ ] Login "Forgot password" is snackbar only
  - [login_screen.dart](P:\midterm-mobile\app\lib\features\auth\screens\login_screen.dart:268)
- [ ] Mentorship primary CTA and connect CTA are snackbar only
  - [mentorship_screen.dart](P:\midterm-mobile\app\lib\features\mentorship\screens\mentorship_screen.dart:82)
  - [mentorship_screen.dart](P:\midterm-mobile\app\lib\features\mentorship\screens\mentorship_screen.dart:322)

## Checklist To Reach "Fully Matching"

Working definition of "fully matching" for this repo:

- screen-level visual intent matches showcase closely enough
- runtime interactions are real where visible
- shared system pieces are unified even if stitched screenshots were not fully consistent

### P0 - Architecture / Navigation

- [ ] Decide one canonical bottom-nav system for runtime feature routes
- [ ] Either move feature routes into a shared shell or introduce a second shared feature shell
- [ ] Remove ad-hoc screen-by-screen nav duplication where possible
- [ ] Define whether detail routes (`post`, `create-post`, `chat-detail`) should intentionally keep or omit bottom nav

### P0 - Remove separate showcase trees

- [ ] Projects: replace `_ShowcaseProjectMarketplaceScreen` with shared content builder fed by sample/live data
- [ ] Chat list: replace `_ShowcaseChatListScreen` with shared content builder
- [ ] Create post: replace `_ShowcaseCreatePostScreen` and shared composer actions
- [ ] Post detail: replace `_ShowcasePostDetailScreen` with shared content builder
- [ ] Playground: replace `_ShowcasePlaygroundScreen` with shared content builder
- [ ] Live code: replace `_ShowcaseLiveCodeScreen` or explicitly mark the screen as static-only

### P0 - Make visible buttons real

- [ ] Implement real analytics range filtering
- [ ] Implement real project-create flow or remove/add roadmap badge
- [ ] Implement real GIF/media strategy in create-post
- [ ] Implement real follow/connect workflows where CTA is exposed
- [ ] Implement search-history clear action
- [ ] Implement notification invite accept/decline actions
- [ ] Implement feed overflow menu
- [ ] Implement password recovery flow or remove the CTA

### P1 - Data parity

- [ ] Analytics chart should use real series, not static painter data only
- [ ] Analytics delta values should come from range-aware calculations
- [ ] Showcase sample data should map into the same view model shape as live data
- [ ] Remove text/content drift between showcase copy and runtime copy where the screen is meant to match exactly

### P1 - Interaction parity tests

- [ ] Add route-level interaction tests that tap top-right actions, FABs, chips, primary CTA buttons
- [ ] Add parity assertions for bottom-nav presence/absence by route
- [ ] Add tests that compare screenshot-mode and live-mode widget anchors for the same screens

### P2 - Visual regression discipline

- [ ] Add a parity review checklist to PR workflow for all `SCREENSHOT_MODE` screens
- [ ] Re-capture current screenshots after each parity fix
- [ ] Verify mobile viewport and emulator behavior separately from web

## Acceptance Standard

Only mark the app as fully matched when all of the following are true:

- No remaining separate showcase-only widget trees for parity-critical screens
- No visible primary CTA is no-op, snackbar-only, or disabled without explicit product reason
- Bottom navigation/layout behavior is intentional and consistent by route class
- Live runtime and showcase/sample runtime share the same component structure
- Tap-level interaction tests exist for all audited showcase routes
