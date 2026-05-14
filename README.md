# DevConnect — Midterm Project (PRM393)

DevConnect là mạng xã hội chuyên biệt cho lập trình viên — nơi chia sẻ code, tìm đồng đội, và phát triển sự nghiệp.

---

## 📁 Cấu trúc dự án

```text
midterm-mobile/
├── app/                          # 📱 Flutter Mobile App
│   ├── lib/
│   │   ├── app/                  #   App entry & configuration
│   │   ├── core/                 #   Constants, models, services, theme, widgets
│   │   ├── data/                 #   Data layer (repositories, data sources)
│   │   ├── features/             #   Feature modules (13 modules)
│   │   │   ├── auth/             #     Đăng nhập / Đăng ký
│   │   │   ├── feed/             #     News Feed
│   │   │   ├── chat/             #     Nhắn tin realtime
│   │   │   ├── explore/          #     Khám phá (tìm người / bài viết)
│   │   │   ├── profile/          #     Hồ sơ cá nhân
│   │   │   ├── projects/         #     Quản lý dự án
│   │   │   ├── notifications/    #     Thông báo
│   │   │   ├── mentorship/       #     Mentor & Mentee
│   │   │   ├── leaderboard/      #     Bảng xếp hạng
│   │   │   ├── playground/       #     Code Playground
│   │   │   ├── analytics/        #     Thống kê
│   │   │   ├── settings/         #     Cài đặt
│   │   │   └── debug/            #     Debug tools
│   │   └── routing/              #   GoRouter navigation
│   └── integration_test/flows/   #   E2E Integration Tests (8 luồng)
├── backend/                      # ☁️ NestJS API Server
│   ├── src/                      #   Source code (NestJS Modules, Services, Controllers)
│   ├── prisma/                   #   Prisma ORM schema & migrations
│   ├── scripts/                  #   Utility scripts (seed, password reset)
│   └── Dockerfile                #   Container build config
├── docs/                         # 📖 Tài liệu kỹ thuật (7 files)
├── deliverables/                 # 📦 Report PDF + Presentation PPTX
└── docker-compose.yml            # 🐳 Docker orchestration (3 services)
```

---

## ⚙️ Yêu cầu hệ thống (Prerequisites)

Trước khi chạy dự án, đảm bảo đã cài đặt:

| Tool | Phiên bản tối thiểu | Mục đích |
|------|---------------------|----------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 4.x+ | Chạy Backend, PostgreSQL, Redis |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.7.2+ | Build & chạy mobile app |
| [Node.js](https://nodejs.org/) | 20+ | Chạy seed scripts & API tests |
| [Git](https://git-scm.com/) | 2.x+ | Clone source code |
| Android Studio / Xcode | Latest | Android Emulator / iOS Simulator |

> **Lưu ý:** Đảm bảo Flutter đã được cấu hình đúng bằng lệnh `flutter doctor`.

---

## 🚀 Quick Start (Máy mới pull về)

### Bước 1: Clone dự án

```powershell
git clone https://github.com/initforge/DevConnect.git
cd DevConnect
```

### Bước 2: Khởi động Backend (Docker)

```powershell
docker-compose up -d
```

Lệnh này sẽ tự động:
- Build **Backend** Node.js API → `localhost:8080`
- Khởi tạo **PostgreSQL 16** → `localhost:5432` (tự chạy `init.sql` để tạo schema + seed data)
- Khởi tạo **Redis 7** → `localhost:6379`

Kiểm tra tất cả services đã chạy:

```powershell
docker-compose ps
```

### Bước 3: Tạo dữ liệu test (seed passwords)

```powershell
cd backend
npm install
npm run seed:users
```

> `init.sql` đã tạo sẵn 6 users với dữ liệu demo, lệnh `seed:users` sẽ hash password để có thể đăng nhập.

### Bước 4: Chạy Flutter App

```powershell
cd app
flutter pub get
flutter run
```

> Chọn device (Android Emulator / iOS Simulator / Chrome) khi được hỏi.

---

## 🔌 Kiến trúc hệ thống

```text
┌─────────────────┐     HTTP/REST      ┌─────────────────┐
│   Flutter App    │ ◄────────────────► │  Node.js API    │
│   (Mobile)       │     WebSocket      │  (Port 8080)    │
└─────────────────┘                     └────────┬────────┘
                                                 │
                                    ┌────────────┴────────────┐
                                    │                         │
                              ┌─────▼─────┐           ┌──────▼──────┐
                              │ PostgreSQL │           │    Redis    │
                              │ (Port 5432)│           │ (Port 6379) │
                              └───────────┘           └─────────────┘
```

| Component | Công nghệ | Port | Mô tả |
|-----------|-----------|------|--------|
| Mobile App | Flutter 3.7+ / Dart | — | UI + Business Logic (Riverpod) |
| API Server | Node.js 20+ | 8080 | REST API + WebSocket realtime |
| Database | PostgreSQL 16 | 5432 | 10 tables, full relational schema |
| Cache | Redis 7 | 6379 | Session & realtime data |

---

## 🛠️ Tech Stack

### Frontend (Flutter)

| Category | Library | Mục đích |
|----------|---------|----------|
| State Management | `flutter_riverpod` | Quản lý state toàn app |
| Networking | `dio` | HTTP client cho REST API |
| Realtime | `web_socket_channel` | Chat realtime qua WebSocket |
| Routing | `go_router` | Declarative navigation |
| UI | `google_fonts`, `shimmer`, `cached_network_image` | Typography, loading effects, image cache |
| Storage | `shared_preferences`, `sqflite` | Local cache & offline data |
| Utilities | `intl`, `image_picker`, `share_plus`, `connectivity_plus` | Đa ngôn ngữ, chọn ảnh, chia sẻ, kiểm tra mạng |

### Backend (Node.js)

| Category | Library | Mục đích |
|----------|---------|----------|
| Database | `pg` | PostgreSQL client |
| Auth | `bcrypt`, `jsonwebtoken` | Hash password & JWT tokens |
| Realtime | `ws` | WebSocket server |

### 🤖 AI Cloudflare Workers Proxy

Một Cloudflare Worker cung cấp AI features (code review, explain code, mentorship match) qua Workers AI binding:

```powershell
cd ai-worker
npm install
npm test         # Unit tests
npm run check    # Syntax check
```

Cấu hình: `ai-worker/wrangler.toml`

Env variables cần thiết (xem `.env.example` tại root):
- `AI_WORKER_SECRET` — secret cho backend-to-worker auth

Backend proxy tự động fallback sang rule-based responses nếu Worker không khả dụng.

---

## 🗄️ Database Schema

10 tables chính:

| Table | Mô tả |
|-------|--------|
| `users` | Thông tin user (username, email, skills, reputation...) |
| `posts` | Bài viết (article, discussion, snippet, project, til) |
| `comments` | Bình luận theo post |
| `notifications` | Thông báo (comment, like, follow, mention, best_answer) |
| `projects` | Dự án tìm đồng đội |
| `jobs` | Tin tuyển dụng |
| `conversations` | Cuộc hội thoại chat |
| `messages` | Tin nhắn (text, code snippet) |
| `user_follows` | Quan hệ follow giữa users |
| `post_likes` / `post_bookmarks` | Like & Bookmark bài viết |

---

## 🧪 Testing

### CI Coverage Gate (Automated)

Th project chạy CI tự động qua GitHub Actions (`.github/workflows/ci.yml`):

```powershell
# Flutter: static check + unit tests + coverage
cd app
flutter analyze
flutter test --coverage

# Backend: install + build check + API tests (requires Docker Postgres)
cd backend
npm ci
npm run build
# Run API tests: scripts/ci/e2e-api.cjs (requires Docker)

# AI Worker: unit tests
cd ai-worker
npm test && npm run check
```

Coverage thresholds: **10% total**, **80% core/repositories**.

### API Testing

```powershell
cd backend
npm run test:api        # Kiểm tra tất cả API endpoints
npm run test:login      # Test luồng đăng nhập
```

> **E2E & Visual Tests** là manual — Playwright screenshots (`scripts/e2e/responsive-smoke.cjs`) không nằm trong CI gate bắt buộc. Chạy thủ công khi cần.

### Flutter Integration Tests (8 luồng E2E)

```powershell
cd app
flutter test integration_test/flows/
```

| # | Test File | Nội dung |
|---|-----------|----------|
| 0 | `00_full_journey_test.dart` | Full user journey (end-to-end) |
| 1 | `01_auth_flow_test.dart` | Đăng ký → Đăng nhập → Đăng xuất |
| 2 | `02_feed_flow_test.dart` | Xem feed → Tạo bài → Like/Bookmark |
| 3 | `03_explore_flow_test.dart` | Tìm kiếm → Follow → Xem profile |
| 4 | `04_social_flow_test.dart` | Chat → Notifications → Interactions |
| 5 | `05_settings_flow_test.dart` | Đổi theme → Đổi thông tin → Logout |
| 6 | `06_edge_cases_test.dart` | Empty states, error handling, edge cases |
| 7 | `07_data_integrity_test.dart` | Data consistency & validation |

---

## 🛠️ Development Commands

### Backend

| Lệnh | Tác dụng |
|-------|----------|
| `npm start` | Chạy server production |
| `npm run dev` | Chạy server với hot-reload (`--watch`) |
| `npm run test:api` | Kiểm tra tất cả API endpoints |
| `npm run test:login` | Test luồng đăng nhập |
| `npm run seed:users` | Tạo/cập nhật user test với password hash |
| `npm run update:passwords` | Reset tất cả mật khẩu về `password123` |

### Docker

| Lệnh | Tác dụng |
|-------|----------|
| `docker-compose up -d` | Khởi động tất cả services (background) |
| `docker-compose down` | Dừng tất cả services |
| `docker-compose down -v` | Dừng + xóa data (reset database) |
| `docker-compose logs -f backend` | Xem logs backend realtime |
| `docker-compose ps` | Kiểm tra trạng thái services |
| `docker-compose up -d --build` | Rebuild và khởi động lại |

### Flutter

| Lệnh | Tác dụng |
|-------|----------|
| `flutter pub get` | Cài dependencies |
| `flutter run` | Chạy app trên device/emulator |
| `flutter run -d chrome` | Chạy trên Chrome (web) |
| `flutter build apk` | Build APK release |
| `flutter test` | Chạy unit tests |
| `flutter test integration_test/` | Chạy integration tests |

---

## 👥 Test Accounts

| Email | Mật khẩu | Tên | Vai trò |
|-------|----------|-----|---------|
| `minh@dev.com` | `password123` | Minh Nguyen | Flutter & Backend dev |
| `anh@dev.com` | `password123` | Anh Tran | Backend engineer, Mentor |
| `linh@dev.com` | `password123` | Linh Pham | AI/ML researcher, Mentor |
| `duc@dev.com` | `password123` | Duc Le | React & Next.js dev |
| `thu@dev.com` | `password123` | Thu Huong | Full-stack developer |
| `nam@dev.com` | `password123` | Nam Pham | Mobile developer |

---

## 📖 Tài liệu (Đọc theo thứ tự)

| # | File | Nội dung |
|---|------|----------|
| 1 | [01_OVERVIEW](docs/01_OVERVIEW.md) | Tổng quan sản phẩm & kiến trúc hệ thống |
| 2 | [02_USER_FLOWS](docs/02_USER_FLOWS.md) | Luồng người dùng & Business Logic |
| 3 | [03_DATABASE](docs/03_DATABASE.md) | Schema cơ sở dữ liệu (ER Diagram) |
| 4 | [04_API](docs/04_API.md) | Đặc tả API endpoints |
| 5 | [05_DEVELOPMENT](docs/05_DEVELOPMENT.md) | Cài đặt môi trường & quy trình dev |
| 6 | [06_TESTING](docs/06_TESTING.md) | Cấu trúc test & cách chạy |
| 7 | [07_ROADMAP](docs/07_ROADMAP.md) | Lộ trình phát triển |

---

## 📦 Deliverables

| File | Mô tả |
|------|--------|
| `deliverables/DevConnect_Midterm_Report_PRM393.pdf` | Báo cáo Midterm (PDF) |
| `deliverables/DevConnect_Midterm_Presentation_PRM393.pptx` | Slide thuyết trình (PPTX) |

---

## 🔧 Troubleshooting

### Docker không khởi động được

```powershell
# Kiểm tra Docker Desktop đã chạy chưa
docker info

# Nếu port bị chiếm, kiểm tra và kill process
netstat -ano | findstr :8080
netstat -ano | findstr :5432
```

### Không đăng nhập được

```powershell
# Reset password cho tất cả users
cd backend
npm run update:passwords

# Hoặc seed lại users
npm run seed:users
```

### Flutter build lỗi

```powershell
# Xóa cache và rebuild
cd app
flutter clean
flutter pub get
flutter run
```

### Reset toàn bộ database

```powershell
# Xóa volume và tạo lại từ đầu
docker-compose down -v
docker-compose up -d

# Chờ Postgres healthy rồi seed lại
cd backend
npm run seed:users
```


