# 02. User Flows

## 1. Bảng đối chiếu `docs/showcase`

| Showcase | Route runtime | File chính | Trạng thái |
|---|---|---|---|
| `01_login.png` | `/login` | `app/lib/features/auth/screens/login_screen.dart` | Có route/auth UI. |
| `02_register.png` | `/register` | `register_screen.dart` | Có route/register UI. |
| `03_onboarding.png` | `/onboarding` | `onboarding_screen.dart` | Đã sửa responsive: dùng `CustomScrollView`, grid theo width, CTA không bị đẩy khỏi màn thấp. |
| `04_home_feed.png` | `/home` | `home_screen.dart`, `feed_list.dart`, `post_card.dart` | Đã nối comment action sang detail, fix navigation GoRouter, sync like/bookmark count qua backend response/cache invalidation. |
| `05_post_detail.png` | `/post/:id` | `post_detail_screen.dart` | Comment, like, bookmark, follow có flow thật; comment icon focus composer. |
| `06_explore.png` | `/explore` | `explore_screen.dart` | Có route khám phá/search surface. |
| `07_profile.png` | `/profile`, `/user/:id` | `profile_screen.dart` | Có profile route và GitHub-related API stub/runtime. |
| `08_create_post.png` | `/create-post` | `create_post_screen.dart` | Có create post + AI sheet. |
| `09_direct_message.png` | `/chat/:id` | `chat_screen.dart` | Đã sửa mark-read khi vào chat và khi nhận message trong chat đang mở. |
| `10_chat_list.png` | `/chat` | `chat_list_screen.dart` | Đã sửa unread clear tức thì, realtime presence theo token, realtime last-message khi list đang mở. |
| `11_notifications.png` | `/notifications` | `notifications_screen.dart` | Đã sửa mark-read local ngay sau API, không chờ reload thủ công. |
| `12_project_marketplace.png` | `/projects` | `project_marketplace_screen.dart` | Có list/join/project detail flow. |
| `13_job_board.png` | `/jobs` | `job_board_screen.dart` | Có list/apply/my applications flow. |
| `14_leaderboard.png` | `/leaderboard` | `leaderboard_screen.dart` | Có route và backend module. |
| `15_analytics.png` | `/analytics` | `analytics_screen.dart` | Có route và backend module. |
| `16_code_playground.png` | `/playground` | `playground_screen.dart` | Có run/review/explain API flow. |
| `17_mentorship.png` | `/mentorship` | `mentorship_screen.dart` | Có mentors/requests API flow. |
| `18_live_code.png` | `/live-code` | `live_code_screen.dart`, `live.gateway.ts` | Có live room/service/gateway, vẫn cần QA realtime sâu hơn. |
| `19_settings.png` | `/settings` | `settings_screen.dart` | Có grouped settings UI; cần manual QA mobile/tablet/desktop khi chỉnh nhiều toggle. |
| `20_search_results.png` | `/search?q=...` | `search_results_screen.dart` | Có route/search state; empty state cần dùng showcase làm benchmark visual. |

## 2. Auth: đăng nhập, đăng ký, vào app

1. Người dùng nhập email/password hoặc chọn GitHub.
2. Flutter gọi `POST /api/auth/login` hoặc `POST /api/auth/register`.
3. Backend kiểm tra user, tạo JWT token, trả user profile.
4. Flutter lưu token vào `SharedPreferences` (`auth.token`) và set token cho `ApiService`.
5. Router thấy có token, nếu onboarding xong thì vào `/home`, nếu chưa thì vào `/onboarding`.

Điểm cần nhớ: app không nên tự tin chỉ vì login screen hiện ra. Pass thật là token được lưu, route guard đọc đúng token, và API sau đó có header `Authorization: Bearer ...`.

## 3. Onboarding: chọn sở thích

1. Người dùng chọn skill/topic.
2. Flutter lưu local bằng `AppPreferences.saveOnboardingData`.
3. Nếu đã login, Flutter patch `/api/users/me` để backend biết skills.
4. Flutter set `onboarding.completed = true` rồi điều hướng `/home`.

Vì màn này phải chạy trên mobile thấp, UI dùng scroll thay vì nhét grid vào `Expanded`. CTA vẫn nằm sau grid và scroll tới được, không bị tràn khỏi viewport.

## 4. Feed: like, bookmark, comment

1. Home gọi `GET /api/posts?type=foryou|following|trending`.
2. Backend đọc Postgres hoặc Redis cache, trả post kèm `isLikedByMe`, `isBookmarkedByMe`, counts.
3. Khi bấm like/bookmark, Flutter cập nhật UI ngay.
4. Backend toggle trong transaction, trả lại state và count thật.
5. Backend xóa cache `posts:item:*` và `posts:feed:*` để reload không lấy số cũ.
6. Nếu API fail, Flutter rollback state cũ và báo lỗi.

Comment trên card không phải nút chết nữa: nó mở `/post/:id`, nơi comment composer xử lý `POST /api/posts/:id/comments`.

## 5. Post detail: đọc, tương tác, bình luận

1. Flutter gọi `GET /api/posts/:id` và `GET /api/posts/:id/comments`.
2. Người dùng like/bookmark/follow thì UI optimistic trước, API đồng bộ sau.
3. Người dùng nhập comment, Flutter gọi `POST /api/posts/:id/comments`.
4. Backend tạo comment, tăng `commentCount`, xóa cache post/feed.
5. Flutter refresh detail và phát `FeedRefreshBus` để feed sau đó có số mới.

## 6. Chat: list, unread, read, presence

1. Flutter bootstrap token rồi mở Socket.IO `http://localhost/chat` với `auth.token`.
2. Backend `ChatGateway` verify token, lấy `payload.sub`, set Redis `online:user:{id}`, broadcast `presence_change`.
3. Chat list gọi `GET /api/chat/conversations`.
4. Khi tap conversation, chat list clear unread local ngay và gọi `PATCH /api/chat/conversations/:id/read`.
5. Chat screen cũng mark read khi vào màn và khi nhận tin nhắn mới trong conversation đang mở.
6. Tin nhắn gửi qua `POST /api/chat/conversations/:id/messages` hoặc socket event, backend lưu message và update last message.

Mục tiêu UX: badge unread biến mất ngay khi mở chat, không phải reload trang.

## 7. Notifications: unread và grouped state

1. Flutter gọi `GET /api/notifications`.
2. User tap notification hoặc `Mark all as read`.
3. Backend patch read state.
4. Flutter cập nhật local list ngay sau API, không đợi reload thủ công.

Thông báo realtime có gateway riêng trong backend, nhưng client hiện tập trung realtime ở chat namespace. Nếu muốn badge app-wide realtime hoàn chỉnh, cần nối thêm notification namespace ở roadmap.

## 8. Projects, jobs, tools

Projects và jobs đi theo CRUD/action flow quen thuộc:

1. List screen gọi `GET`.
2. Detail hoặc action gọi `GET :id`, `POST :id/join`, `POST :id/apply`.
3. Backend dùng Postgres để giữ trạng thái application/member.
4. Flutter refresh list/detail để UI không lệch.

Playground/AI dùng API riêng vì đây là thao tác tốn tài nguyên và có thể chạy nền/queue.
