# 06. Testing

## 1. Mục tiêu test

Test ở đây không chỉ là "app mở được". Test đúng là xem phản ứng sau khi user thao tác:

1. Bấm like thì count và icon có đúng không.
2. Bấm comment thì có vào flow comment thật không.
3. Mở chat thì unread badge mất ngay không.
4. Gửi/nhận message thì last message/read/presence có lệch không.
5. Mark read notification có đổi UI ngay không.
6. Onboarding có dùng được trên màn thấp không.

## 2. Lệnh kiểm tra bắt buộc

Từ `app/`:

```powershell
flutter analyze
flutter test
flutter build web
```

Từ `backend/`:

```powershell
npm run build
npm test -- --runInBand --passWithNoTests
```

Từ root repo, sau khi đã `flutter build web`:

```powershell
npm run smoke:responsive
```

`npm test` backend hiện không có file `.spec.ts`, nên dùng `--passWithNoTests` để lệnh phản ánh đúng trạng thái repo thay vì fail giả.

## 3. Responsive smoke

`scripts/e2e/responsive-smoke.cjs`:

1. Serve `app/build/web`.
2. Seed auth/onboarding local storage.
3. Mock API cơ bản.
4. Mở `/home`, `/more`, `/projects`.
5. Chụp mobile/tablet/desktop.
6. Assert không horizontal overflow và Flutter surface có render.

Output:

```text
output/playwright/responsive_smoke/
```

Nếu backend thật không chạy, report có thể ghi console error websocket refused. Điều đó không làm responsive smoke fail, nhưng khi test realtime thật thì phải chạy backend.

## 4. Manual QA bắt buộc cho các màn user đã nêu

### 4.1 Onboarding

Viewport cần thử:

1. Mobile thấp: `390x640`
2. Mobile thường: `390x844`
3. Tablet: `768x1024`
4. Desktop: `1440x900`

Pass khi:

1. Header thấy được.
2. Grid skill không tràn ngang.
3. CTA `Continue` có thể thấy hoặc scroll tới được.
4. Không có text chồng nhau.

### 4.2 Home feed

Pass khi:

1. Bấm like: icon đổi ngay, count tăng/giảm đúng một đơn vị.
2. Bấm lại: count quay lại đúng, không giảm liên tục.
3. Reload feed: count không quay về số cache cũ.
4. Bấm comment: vào `/post/:id`.
5. Bấm bookmark: icon/count đồng bộ.

### 4.3 Post detail

Pass khi:

1. Like/bookmark ở detail không lệch với feed sau refresh.
2. Follow cập nhật author state.
3. Gửi comment xong comment list tăng và feed count refresh.
4. Comment icon focus vào composer.

### 4.4 Chat

Pass khi:

1. Chat list hiển thị unread badge.
2. Tap conversation: badge mất ngay, không cần reload.
3. Chat screen gọi mark read khi vào màn.
4. Nhận message khi đang ở chat: conversation vẫn read.
5. Presence online/offline đi từ token thật, không đọc `query.userId` giả.
6. Last message preview đổi khi message event đến list đang mở.

### 4.5 Notifications

Pass khi:

1. Tap notification: row chuyển read ngay sau API.
2. Mark all read: toàn bộ row chuyển read.
3. Grouped count không mất field.
4. Reload lại vẫn đúng theo backend.

## 5. Showcase parity

`docs/showcase` là benchmark visual. Khi có thời gian chạy full parity:

1. Capture đủ 20 route theo danh sách trong `02_USER_FLOWS.md`.
2. Lưu actual screenshot vào `output/parity/...`.
3. Dùng `scripts/parity/visual-diff.py` để so ảnh nếu có actual đúng tên.
4. Diff lớn không tự động đồng nghĩa lỗi, nhưng phải review: layout lệch, state thiếu, action không thật.

## 6. Kết quả verification gần nhất

Ngày kiểm tra: 2026-05-13.

| Lệnh | Kết quả |
|---|---|
| `flutter analyze` | Có warning/info cũ, không có error compile. |
| `flutter test` | Pass `140/140`. |
| `flutter build web` | Pass. |
| `npm run build` trong `backend/` | Pass sau khi sửa query Prisma sai. |
| `npm test -- --runInBand --passWithNoTests` | Pass, repo backend chưa có spec test. |
| `npm run smoke:responsive` | Pass routing/render/overflow; report còn websocket refused nếu backend thật chưa chạy. |
