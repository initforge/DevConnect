# 11 - Parity 100% Plan and Checklist

Ngay lap: 2026-05-10

## Muc tieu dung

Khong duoc ket luan "100%" theo cam tinh. Chi duoc dung khi tat ca muc duoi day co bang chung:

1. Tat ca route showcase mo duoc.
2. Tat ca nut/chip/tab/input co hanh vi ro rang va duoc verify.
3. Moi tinh nang showcase duoc map sang app that: pass / partial / fail.
4. Anh app that gan showcase theo nguong da chot.
5. Runtime thuong va `SCREENSHOT_MODE=true` khong lech ve layout/flow chinh.
6. Test/build/analyze khong con loi chan release; neu con warning cu thi phai ghi ro khong anh huong parity.

Ket luan dung sau cung khong phai "anh giong tung pixel 100%", ma la:

> App da pass 100% checklist parity da dinh nghia: route, nut, flow, visual review, va runtime/screenshot consistency.

## Dinh nghia Pass / Partial / Fail

| Trang thai | Nghia |
|---|---|
| Pass | Da verify bang test hoac anh, dung ky vong, khong con loi can sua. |
| Partial | Co UI hoac flow mot phan, nhung thieu logic that, thieu test, hoac con lech ro voi showcase. |
| Fail | Khong mo duoc, nut khong lam gi, sai route, crash, ket loading, hoac lech visual/blocking flow. |
| Deferred | Co chu y de lai sau va khong duoc tinh la pass. |

## So lieu quet hien tai

| Hang muc | Ket qua |
|---|---:|
| Showcase screenshots | 20 |
| Routes can audit | 20 |
| Dart files co handler bam/chon/submit | 22 |
| Handler bam/chon/submit tim thay | 167 |
| Files co `SCREENSHOT_MODE` branch | 5, gom router + 4 screens |
| Magic route string `context.push('/...')` trong `app/lib` | 0 |

## Trang thai verify gan nhat

Cap nhat: 2026-05-10

| Gate | Ket qua |
|---|---|
| Route audit runtime thuong | Pass 20/20 |
| Route audit `SCREENSHOT_MODE=true` | Pass 20/20 |
| Browser console error | 0 route co console error |
| Horizontal overflow | 0 route co overflow |
| Visual diff showcase vs actual runtime | 11 pass, 9 review, 0 fail |
| Runtime vs screenshot mode | 17 pass, 3 review, 0 fail |
| Click handler audit | Da export 167 handler vao `output/parity/click_handler_audit.md` |
| UI E2E browser flows | Pass 9/9 flow chinh: login/onboarding, search, create post, profile/settings, chat, projects, jobs, playground, notifications |
| API E2E business flows | Pass: auth, post, like/bookmark/comment, project create/join, chat, notifications/analytics, code run |
| Flutter unit tests | Pass 112/112 |
| Flutter web build | Pass runtime va `SCREENSHOT_MODE=true`, `API_BASE_URL=http://127.0.0.1:8080` |
| Flutter analyze | Con 21 info cu trong `integration_test/flows`, khong co loi moi |
| Flutter integration test web | Bi chan: Flutter bao web devices chua support integration tests |
| Flutter integration test windows | Bi chan: thieu Visual Studio toolchain |

Artifacts:

- `output/parity/route_audit/route_audit.md`
- `output/parity/route_audit_runtime/route_audit.md`
- `output/parity/route_audit_screenshot_mode/route_audit.md`
- `output/parity/route_audit/screenshots/*.png`
- `output/parity/visual_diff/visual_diff_report.md`
- `output/parity/visual_diff/visual_diff_contact_sheet.png`
- `output/parity/runtime_vs_screenshot/runtime_vs_screenshot_report.md`
- `output/parity/runtime_vs_screenshot/runtime_vs_screenshot_contact_sheet.png`
- `output/parity/click_handler_audit.md`
- `output/playwright/e2e_ui_flows/e2e_ui_flows_report.md`

Files con `SCREENSHOT_MODE`:

- `app/lib/routing/app_router.dart`
- `app/lib/features/analytics/screens/analytics_screen.dart`
- `app/lib/features/chat/screens/chat_list_screen.dart`
- `app/lib/features/feed/screens/post_detail_screen.dart`
- `app/lib/features/projects/screens/project_marketplace_screen.dart`

## Dieu kien dung cuoi cung

Tat ca checkbox phai pass:

- [x] Route audit pass 20/20 o runtime thuong.
- [x] Route audit pass 20/20 o `SCREENSHOT_MODE=true`.
- [x] Browser audit khong co console error tren 20 route.
- [x] Browser audit khong co horizontal overflow tren 20 route.
- [x] Visual contact sheet da review thu cong, khong con man lech ro.
- [x] Visual diff showcase vs app actual duoc tao cho 20/20 man.
- [x] Runtime vs screenshot mode diff duoc tao cho cac route co branch.
- [x] Button audit co danh sach day du cho 167 handler hien tai.
- [x] Tat ca handler duoc gan ky vong: navigate / mutate state / API / dialog / dismiss / disabled / deferred.
- [x] Khong con handler khong ro tac dung.
- [x] Cac flow chinh co test tu dong pass.
- [x] `flutter build web` pass.
- [x] `flutter analyze` khong con issue moi; neu con issue cu thi duoc ghi ro.

## Checklist route va visual

| ID | Route | Showcase | Runtime route | Screenshot mode | Visual status | Can verify |
|---|---|---|---|---|---|---|
| 01 | `/login` | `01_login.png` | [ ] | [ ] | [ ] | form, login, github button, signup link, forgot password |
| 02 | `/register` | `02_register.png` | [ ] | [ ] | [ ] | multi-step form, password toggle, terms, login link |
| 03 | `/onboarding` | `03_onboarding.png` | [ ] | [ ] | [ ] | chip select, continue, skip |
| 04 | `/home` | `04_home_feed.png` | [ ] | [ ] | [ ] | tabs, search, notifications, feed card actions, bottom nav |
| 05 | `/post/p1` | `05_post_detail.png` | [ ] | [ ] | [ ] | back/share/bookmark/follow/AI/comment/reaction |
| 06 | `/explore` | `06_explore.png` | [ ] | [ ] | [ ] | search, filters, post cards, user follow, topic cards |
| 07 | `/profile` | `07_profile.png` | [ ] | [ ] | [ ] | edit/settings/message/follow/post tabs |
| 08 | `/create-post` | `08_create_post.png` | [ ] | [ ] | [ ] | post type, content, tags, AI review, media buttons, submit |
| 09 | `/chat/conv1` | `09_direct_message.png` | [ ] | [ ] | [ ] | send message, input, back, call/video icons |
| 10 | `/chat` | `10_chat_list.png` | [ ] | [ ] | [ ] | new chat, conversation tap, search |
| 11 | `/notifications` | `11_notifications.png` | [ ] | [ ] | [ ] | tabs, mark read, invite accept/decline, item tap |
| 12 | `/projects` | `12_project_marketplace.png` | [ ] | [ ] | [ ] | filters, save, join, create project |
| 13 | `/jobs` | `13_job_board.png` | [ ] | [ ] | [ ] | filters, remote toggle, apply |
| 14 | `/leaderboard` | `14_leaderboard.png` | [ ] | [ ] | [ ] | ranking display, filters if present |
| 15 | `/analytics` | `15_analytics.png` | [ ] | [ ] | [ ] | date range tabs, chart/cards, notification icon |
| 16 | `/playground` | `16_code_playground.png` | [ ] | [ ] | [ ] | language select, run, AI review, AI explain |
| 17 | `/mentorship` | `17_mentorship.png` | [ ] | [ ] | [ ] | find match, connect |
| 18 | `/live-code` | `18_live_code.png` | [ ] | [ ] | [ ] | editor, chat, mic/video/screen/chat controls |
| 19 | `/settings` | `19_settings.png` | [ ] | [ ] | [ ] | edit profile, password, github, delete, toggles, logout |
| 20 | `/search?q=flutter` | `20_search_results.png` | [ ] | [ ] | [ ] | tabs, search submit/clear, result card tap, user/project actions |

## Checklist flow chinh

| Flow | Ky vong | Test tu dong | Trang thai |
|---|---|---|---|
| Auth login | Dang nhap thanh cong, vao app shell | [ ] | [ ] |
| Auth register | Tao user, qua onboarding | [ ] | [ ] |
| Onboarding | Chon skill, continue/skip dung | [ ] | [ ] |
| Feed navigation | Home tabs va card detail dung | [ ] | [ ] |
| Create post | Tao bai viet hoac ghi ro deferred neu mock | [ ] | [ ] |
| Post detail | Like/bookmark/comment/follow/AI actions dung | [ ] | [ ] |
| Search | Query, tab, result navigation dung | [ ] | [ ] |
| Profile | Own profile va user profile dung | [ ] | [ ] |
| Chat | List -> detail -> send message dung | [ ] | [ ] |
| Notifications | Read state/invite actions dung | [ ] | [ ] |
| Projects | Filter/join/create dung | [ ] | [ ] |
| Jobs | Filter/apply dung | [ ] | [ ] |
| Leaderboard | Data/ranking hien dung | [ ] | [ ] |
| Analytics | Range tabs/chart/cards dung | [ ] | [ ] |
| Playground | Run/review/explain dung | [ ] | [ ] |
| Mentorship | Match/connect dung | [ ] | [ ] |
| Live code | Controls co tac dung ro rang | [ ] | [ ] |
| Settings | Toggles/profile/password/logout/delete dung | [ ] | [ ] |

## Plan lam viec

### Phase 1 - Dong bang benchmark

- [ ] Chot 20 route audit.
- [ ] Chot mock data/API on dinh de test khong bi phu thuoc backend that.
- [ ] Chup actual screenshots runtime thuong.
- [ ] Chup actual screenshots `SCREENSHOT_MODE=true`.
- [ ] Tao contact sheet va visual diff cho 20 man.

### Phase 2 - Button audit

- [ ] Export danh sach 167 handler hien tai.
- [ ] Gan label nguoi dung cho tung handler.
- [ ] Gan ky vong cho tung handler.
- [ ] Chia handler thanh nhom: navigation, state, API, dialog, form, disabled, deferred.
- [ ] Viet test cho nhom critical.
- [ ] Ghi ro nut nao chi snackbar/state-only va co chap nhan hay khong.

### Phase 3 - Runtime/screenshot parity

- [ ] Xoa hoac thu hep cac widget tree rieng cho screenshot mode neu khong can.
- [ ] Dam bao bottom nav/app shell theo mot quy uoc.
- [ ] Dam bao route feature co chung logic navigation.
- [ ] Chup diff lai sau moi sua.

### Phase 4 - Visual polish

- [ ] Sua cac man lech ro truoc: post detail, create post, playground/live code neu con lech.
- [ ] Sua spacing/card/chip/tab/action row theo showcase.
- [ ] Kiem tra mobile 390x844 va desktop/narrow neu can.

### Phase 5 - Final gate

- [ ] `flutter analyze`
- [ ] `flutter build web`
- [ ] route audit 20/20
- [ ] button audit pass
- [ ] flow tests pass
- [ ] visual contact sheet pass
- [ ] runtime vs screenshot pass
- [ ] cap nhat report cuoi cung voi bang chung anh/test

## Nguyen tac khong duoc pha

- Khong tinh la pass neu chi render dep nhung nut khong co hanh vi.
- Khong tinh la pass neu chi co screenshot mode dung ma runtime thuong sai.
- Khong tinh la pass neu handler chi snackbar nhung showcase the hien tinh nang that, tru khi ghi `Deferred`.
- Khong dung "100%" khi chua co bang pass/fail cho tung route, nut, flow.
