# 05 — Hướng dẫn phát triển (Development Guide)

> **Đọc sau 04_API.** File này hướng dẫn cách cài đặt, chạy, và làm việc với dự án trên máy local.

---

## Yêu cầu hệ thống

| Phần mềm | Phiên bản | Kiểm tra |
|----------|----------|---------|
| Node.js | v20+ | `node --version` |
| Docker & Docker Compose | Latest | `docker --version` |
| Flutter SDK | v3.29+ | `flutter --version` |
| Android Emulator hoặc iOS Simulator | — | `flutter devices` |

---

## Khởi chạy nhanh (Quick Start)

Toàn bộ quy trình chỉ cần 3 bước:

```mermaid
graph LR
    A["1️⃣ Docker Up<br/>(Backend + DB)"] --> B["2️⃣ Seed Data<br/>(Tạo user test)"] --> C["3️⃣ Flutter Run<br/>(Mở app)"]
```

### Bước 1: Khởi động Backend

```powershell
docker-compose up -d
```

Lệnh này sẽ khởi động 3 container:
- `api-server` → `http://localhost:8080`
- `postgres` → `localhost:5432`
- `redis` → `localhost:6379`

> **Kiểm tra**: Mở trình duyệt tới `http://localhost:8080/health` — phải thấy `{"status":"ok"}`

### Bước 2: Tạo dữ liệu test

```powershell
cd backend
npm install
npm run seed:users
```

Lệnh này tạo 3 tài khoản test sẵn:

| Email | Mật khẩu | Vai trò |
|-------|---------|--------|
| `minh@dev.com` | `password123` | User chính để demo |
| `anh@dev.com` | `password123` | User phụ (test follow, chat) |
| `test@test.com` | `password123` | User dự phòng |

### Bước 3: Chạy Flutter App

```powershell
cd app
flutter run
```

> **Lưu ý**: Nếu chạy trên thiết bị thật (không phải emulator), cần sửa IP trong `app/lib/core/constants/app_constants.dart` từ `localhost` sang IP máy tính của bạn.

---

## Các lệnh hữu ích

### Backend Scripts

Tất cả script nằm trong `backend/scripts/`:

| Lệnh | Tác dụng |
|-------|---------|
| `npm run test:api` | Chạy bộ kiểm tra API tự động (test tất cả endpoint) |
| `npm run seed:users` | Tạo user test qua API |
| `npm run update:passwords` | Reset tất cả mật khẩu về `password123` |

### Database Management

| Lệnh | Tác dụng |
|-------|---------|
| `psql $DATABASE_URL -f init.sql` | Khởi tạo schema từ đầu |
| `psql $DATABASE_URL -f seed.sql` | Seed dữ liệu mẫu |

### Docker Commands

| Lệnh | Tác dụng |
|-------|---------|
| `docker-compose up -d` | Khởi động tất cả container (chạy nền) |
| `docker-compose down` | Tắt tất cả container |
| `docker-compose logs -f api-server` | Xem log backend real-time |
| `docker-compose up --build -d` | Rebuild image rồi khởi động |

---

## Cấu hình môi trường

### Biến môi trường Backend

Các biến này được cấu hình trong `docker-compose.yml`:

| Biến | Giá trị mặc định | Mô tả |
|------|-----------------|-------|
| `PORT` | `8080` | Port của API server |
| `DATABASE_URL` | `postgres://devconnect:devconnect@postgres:5432/devconnect` | Connection string PostgreSQL |
| `JWT_SECRET` | `devconnect-jwt-secret-key` | Secret key để ký JWT token |
| `REDIS_URL` | `redis://redis:6379` | Connection string Redis |

### Cấu hình Flutter

File `app/lib/core/constants/app_constants.dart`:

| Constant | Giá trị | Mô tả |
|---------|---------|-------|
| `apiBaseUrl` | `http://localhost:8080` | URL của Backend API |

---

## Quy ước code (Conventions)

### Backend

- Sử dụng **Vanilla Node.js** `http` module (không dùng Express)
- Entry point duy nhất: `src/server.js`
- Tách logic thành module khi file lớn hơn 300 dòng

### Frontend

- **Riverpod** cho state management — không dùng `setState` cho business logic
- **GoRouter** cho navigation — khai báo routes tập trung
- Tách UI và Business Logic: Widget chỉ chứa UI, logic nằm trong Provider

### Cấu trúc file trong `features/`

```
features/
└── feature_name/
    ├── screens/        # Các màn hình (StatefulWidget)
    ├── widgets/        # Widget con tái sử dụng
    └── providers/      # Riverpod providers (nếu cần)
```

---

## Tiếp theo

Đọc **[06_TESTING.md](06_TESTING.md)** để hiểu cách chạy bộ test tự động.
