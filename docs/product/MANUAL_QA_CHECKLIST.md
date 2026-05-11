# Manual QA Checklist

Use this after CI is green.

Automated browser smoke now captures the responsive shell at mobile, tablet, and
desktop sizes:

```powershell
cd app
flutter build web --dart-define=SCREENSHOT_MODE=true
cd ..
npm run smoke:responsive
```

Screenshots and the report are written to `output/playwright/responsive_smoke/`.

## Navigation

- Mobile shows `Home`, `Explore`, `Post`, `Chat`, `More`.
- `More` opens Notifications, Profile, Projects, Jobs, Leaderboard, Analytics,
  Playground, Mentorship, Live Code Preview, and Settings.
- Desktop/tablet shows the full sidebar; no route requires typing a URL.

## Responsive

- 390px: no horizontal overflow, bottom nav does not cover primary actions.
- 768px: tablet rail/sidebar is usable and not cramped.
- 1440px: desktop layout is not just a stretched mobile screen.

## Core Flows

- Login, register, onboarding, logout.
- Create post, like, bookmark, comment.
- Search users/posts/projects.
- Chat list, chat detail, send message.
- Notifications count/read state.
- Project join and job apply.
- Mentorship match/request flow.
- Settings profile/password/theme/privacy toggles.

## AI

- With `AI_WORKER_URL` configured, code review and explain return Workers AI results.
- With AI Worker disabled/unavailable, backend returns fallback results without UI breakage.
- No secret appears in app bundle, logs, or browser console.
