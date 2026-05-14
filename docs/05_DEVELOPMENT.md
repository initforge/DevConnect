# 05. Development

## 1. Cần cài gì

1. Flutter SDK để chạy app mobile/web.
2. Node.js để chạy NestJS backend và Playwright scripts.
3. Docker Desktop để chạy PostgreSQL, Redis, MinIO, Nginx, backend container.

Không cần MongoDB nữa vì stack runtime hiện tại không dùng MongoDB.

## 2. Chạy bằng Docker

Từ root repo:

```powershell
docker compose up --build
```

Các service chính:

1. Nginx: `http://localhost`
2. Backend nội bộ: `backend:8080`
3. PostgreSQL: `postgres:5432`
4. Redis: `redis:6379`
5. MinIO API: `minio:9000`
6. MinIO console: `http://localhost:9001`

Flutter app mặc định gọi `http://localhost/api`, tức là đi qua Nginx.

## 3. Chạy app Flutter local

Từ `app/`:

```powershell
flutter pub get
flutter run -d chrome
```

Build web:

```powershell
flutter build web
```

Nếu chạy Android emulator, API host thường là `10.0.2.2` thay vì `localhost`. Code đã có nhánh xử lý trong constants/config.

## 4. Chạy backend local

Từ `backend/`:

```powershell
npm install
npm run build
npm run start
```

Backend cần:

1. `DATABASE_URL`
2. `REDIS_HOST`
3. `REDIS_PORT`
4. `JWT_SECRET`
5. MinIO env nếu test upload.

Khi chạy ngoài Docker, `DATABASE_URL` phải trỏ tới Postgres mà máy host truy cập được, không dùng hostname `postgres` trừ khi đang ở trong Docker network.

## 5. Nginx proxy hoạt động thế nào

`nginx.conf` nhận request ở port `80`.

1. `/api/...` đi vào backend `8080`.
2. `/chat` và Socket.IO cũng đi qua backend vì location `/` proxy websocket upgrade.
3. `/storage/...` đi vào MinIO port `9000`.
4. `/minio-console/...` đi vào MinIO console port `9001`.

Lợi ích: frontend không cần biết từng service nằm cổng nào. Nó chỉ gọi một origin.

## 6. Khi thêm feature mới

Quy trình đúng:

1. Tìm màn trong `docs/showcase`.
2. Map route runtime trong `app/lib/routing/app_router.dart`.
3. Tìm repository/API client trong `app/lib/data/repositories`.
4. Tìm controller/service backend tương ứng trong `backend/src`.
5. Kiểm tra response shape: UI đang đọc field nào, backend có trả field đó không.
6. Sửa code.
7. Chạy verification trong `06_TESTING.md`.
8. Cập nhật docs nếu contract hoặc behavior đổi.

## 7. Khi sửa realtime

Không được chỉ sửa client hoặc chỉ sửa backend.

Checklist:

1. Client dùng đúng namespace (`/chat`, `/live`, `/notifications` nếu có).
2. Client gửi token qua đúng chỗ (`handshake.auth.token`).
3. Backend verify token cùng secret với HTTP JWT.
4. Event name giống nhau 100%.
5. Backend lưu DB trước rồi mới broadcast event.
6. UI có local update khi user đang nhìn màn đó.
7. Reload lại vẫn thấy đúng state từ DB, không phụ thuộc state tạm.

## 8. Dọn file

Không dùng `git clean` bừa vì worktree có nhiều file người dùng/agent khác tạo sẵn. Chỉ xóa file đã xác nhận:

1. Build artifact sinh ra và ignore đúng.
2. Dump/tạm không được route/code/docs tham chiếu.
3. Output test cũ nếu không còn cần làm bằng chứng.

`docs/showcase` không phải file rác. Nó là benchmark.
