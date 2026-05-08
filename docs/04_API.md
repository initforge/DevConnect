# 04 — Đặc tả API (API Specification)

> **Đọc sau 03_DATABASE.** File này liệt kê tất cả endpoint của Backend, kèm ví dụ request/response cụ thể.

---

## Thông tin chung

| Thuộc tính | Giá trị |
|-----------|---------|
| Base URL | `http://localhost:8080` |
| Content-Type | `application/json` |
| Auth | Bearer Token (JWT) trong header `Authorization` |

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

---

## Bản đồ Endpoints

```mermaid
graph LR
    subgraph "🔓 Public"
        R[POST /auth/register]
        L[POST /auth/login]
        H[GET /health]
    end

    subgraph "🔒 Cần JWT"
        ME[GET /auth/me]
        GP[GET /api/posts]
        CP[POST /api/posts]
        LK[POST /api/posts/:id/like]
        GU[GET /api/users]
        GU1[GET /api/users/:id]
        FO[POST /api/users/:id/follow]
        ST[GET /api/status]
    end
```

---

## 1. Authentication

### `POST /auth/register` — Đăng ký

**Request:**
```json
{
  "email": "minh@dev.com",
  "password": "StrongPass123!",
  "username": "minhdev",
  "displayName": "Minh Nguyen"
}
```

**Response 201:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "usr_abc123",
    "username": "minhdev",
    "display_name": "Minh Nguyen",
    "email": "minh@dev.com",
    "reputation": 0
  }
}
```

| Lỗi | Nguyên nhân |
|-----|-----------|
| 400 | Thiếu trường bắt buộc |
| 409 | Email hoặc Username đã tồn tại |

---

### `POST /auth/login` — Đăng nhập

**Request:**
```json
{
  "email": "minh@dev.com",
  "password": "StrongPass123!"
}
```

**Response 200:** `{ "token": "...", "user": {...} }`

| Lỗi | Nguyên nhân |
|-----|-----------|
| 401 | Sai email hoặc mật khẩu |

---

### `GET /auth/me` — Thông tin user hiện tại 🔒

**Response 200:**
```json
{
  "id": "usr_abc123",
  "username": "minhdev",
  "display_name": "Minh Nguyen",
  "bio": "Flutter developer",
  "skills": ["Flutter", "Dart", "Go"],
  "reputation": 1250,
  "follower_count": 89,
  "following_count": 156,
  "post_count": 12
}
```

---

## 2. Social Feed

### `GET /api/posts` — Lấy bảng tin 🔒

**Query Parameters:**

| Param | Type | Default | Mô tả |
|-------|------|---------|-------|
| `type` | string | `foryou` | `foryou` / `trending` / `following` |
| `page` | int | 1 | Số trang |
| `limit` | int | 20 | Số bài mỗi trang |

**Response 200:**
```json
[
  {
    "id": "post_xyz",
    "title": "Flutter State Management 2026",
    "content": "## Giới thiệu\nRiverpod là...",
    "type": "article",
    "tags": ["Flutter", "Riverpod"],
    "author": {
      "id": "usr_abc123",
      "display_name": "Minh Nguyen",
      "avatar_url": null,
      "is_online": true
    },
    "like_count": 42,
    "comment_count": 7,
    "is_liked_by_me": false,
    "is_bookmarked_by_me": true,
    "created_at": "2026-05-01T10:30:00Z"
  }
]
```

---

### `POST /api/posts` — Tạo bài viết 🔒

**Request:**
```json
{
  "title": "TIL: Dart Records",
  "content": "Hôm nay tôi học được...",
  "type": "til",
  "tags": ["Dart", "TIL"]
}
```

**Response 201:** Object bài viết vừa tạo.

---

### `POST /api/posts/:id/like` — Toggle Like 🔒

Bấm 1 lần = Like, bấm lần 2 = Unlike (toggle).

**Response 200:**
```json
{ "liked": true, "like_count": 43 }
```

---

## 3. Users & Networking

### `GET /api/users` — Danh sách users 🔒

Sắp xếp theo `reputation` giảm dần (dùng cho Leaderboard).

### `GET /api/users/:id` — Chi tiết Profile 🔒

### `POST /api/users/:id/follow` — Toggle Follow 🔒

**Response 200:**
```json
{ "following": true, "follower_count": 90 }
```

---

## 4. System

### `GET /health` — Health Check

```json
{ "status": "ok", "uptime": 123456, "timestamp": "2026-05-07T08:30:00Z" }
```

### `GET /api/status` — Module Status 🔒

```json
{ "database": "connected", "redis": "connected", "websocket": "active" }
```

---

## Tiếp theo

Đọc **[05_DEVELOPMENT.md](05_DEVELOPMENT.md)** để biết cách cài đặt và chạy dự án trên máy của bạn.
