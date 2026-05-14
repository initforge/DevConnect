# 07. Roadmap

## 1. Nguyên tắc

Roadmap không được viết như runtime đã xong. Mục nào đã chạy thật thì ghi "đã có". Mục nào mới có UI/showcase thì ghi "partial". Mục nào chưa nối backend hoặc chưa QA sâu thì ghi "cần làm".

## 2. Đã sửa trong pass hiện tại

1. Onboarding responsive: bỏ layout dễ vỡ `Expanded + GridView`, dùng `CustomScrollView` và grid theo width/height.
2. Feed comment action: comment trên card mở post detail thật.
3. Feed navigation: dùng GoRouter đúng route `/post/:id`.
4. Like/bookmark backend: trả count thật và xóa Redis cache post/feed sau mutation.
5. Chat realtime auth: Socket.IO gateway đọc `handshake.auth.token`, không đọc `query.userId`.
6. Chat unread: tap conversation clear badge local ngay và gọi mark-read backend.
7. Chat read khi đang mở: nhận message trong conversation đang mở thì mark read.
8. Chat presence: online/offline cập nhật conversation + online list nếu user có trong conversation.
9. Notifications: mark read cập nhật local list ngay sau API.
10. Docker compose: bỏ MongoDB vì runtime hiện tại không dùng.
11. Backend build: sửa query Prisma `follow -> userFollow` và relation live room để `npm run build` pass.
12. Responsive smoke: sửa script seed auth thật sự chạy.

## 3. Đã có runtime nhưng cần QA sâu hơn

| Khu vực | Hiện trạng | Cần QA |
|---|---|---|
| Login/register | Có route/API | Form error state, token refresh, logout. |
| Feed | Có list/action/cache | Race khi bấm nhanh nhiều lần, offline rollback. |
| Post detail | Có detail/comment/AI | Comment nesting/reply/best answer. |
| Chat | Có HTTP + Socket.IO | Multi-user thật với 2 browser, reconnect, message order. |
| Notifications | Có API/read state | Realtime notification namespace chưa nối client app-wide. |
| Projects/jobs | Có list/action | Quyền owner/member/applicant. |
| Playground/AI | Có endpoint và UI | Timeout, queue status, error state. |
| Live code | Có module/gateway | Collaboration thật, reconnect, permission host/viewer. |
| Settings | Có UI và local/server paths | Mobile/tablet text overflow, persistence đủ field. |
| Search | Có route/API | Empty/zero-result parity với showcase. |

## 4. Cần làm để parity gần `docs/showcase` hơn

1. Capture đủ 20 màn runtime và diff với `docs/showcase/screenshots`.
2. Thêm test hành vi feed: like/bookmark/comment không drift sau reload.
3. Thêm test chat hai client: unread/read/presence/last message.
4. Nối notification realtime client nếu muốn badge app-wide không cần polling.
5. Làm search empty/result states khớp showcase.
6. Làm settings responsive QA với text dài và tablet layout.
7. Chuẩn hóa screenshot mode để mỗi showcase screen có route/state cố định.
8. Tách rõ UI demo với feature thật trong code bằng flag hoặc naming.

## 5. Nợ kỹ thuật

1. Backend chưa có `.spec.ts`, nên `npm test` hiện pass bằng `--passWithNoTests`.
2. Một số Flutter warning/info cũ vẫn tồn tại: unused imports, deprecated `withOpacity`, unused widgets.
3. Responsive smoke hiện chỉ mở 3 route, chưa thay thế full parity 20 màn.
4. WebSocket smoke static có thể báo refused nếu backend thật không chạy.
5. Docs showcase data cũ còn nói MongoDB chat, trong khi runtime thật dùng PostgreSQL chat. Docs mới lấy runtime làm nguồn sự thật.

## 6. Ưu tiên tiếp theo

1. Full route parity: 20 screens, mobile first, có report.
2. Chat e2e: 2 user, read/unread/presence/reconnect.
3. Feed e2e: like/comment/bookmark + reload.
4. Notification e2e: mark-one, mark-all, count badge.
5. Settings/search responsive polish.
6. Backend unit/e2e tests cho services có mutation.
7. CI gate: `flutter analyze`, `flutter test`, `flutter build web`, `npm run build`, responsive smoke.
