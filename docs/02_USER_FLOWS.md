# 02 — Luồng người dùng & Business Logic

> **Đọc sau 01_OVERVIEW.** File này mô tả chi tiết **từng hành động** mà người dùng thực hiện trong app, bao gồm cả quy tắc nghiệp vụ và xử lý lỗi.

---

## Hành trình tổng thể

```mermaid
graph TD
    A["Mở App"] --> B{"Đã đăng nhập?"}
    B -->|Chưa| C["Màn hình Login"]
    B -->|Rồi| H["Home Feed"]
    
    C --> D["Đăng nhập"]
    C --> E["Đăng ký mới"]
    
    E --> E1["Step 1: Họ tên + Username + Email"]
    E1 --> E2["Step 2: Mật khẩu"]
    E2 --> E3["Step 3: Thành công ✅"]
    E3 --> F["Onboarding"]
    
    D --> G{"Onboarding xong?"}
    G -->|Chưa| F
    G -->|Rồi| H
    
    F --> H

    H --> I["Bảng tin"]
    H --> J["Khám phá"]
    H --> K["Chat"]
    H --> L["Thông báo"]
    H --> M["Profile"]
    
    J --> J1["Việc làm"]
    J --> J2["Sàn dự án"]
    J --> J3["Bảng xếp hạng"]
    J --> J4["Playground"]
    J --> J5["Mentorship"]

    M --> N["Cài đặt"]
    N --> O["Đăng xuất → Login"]
```

---

## 1. Xác thực (`auth`)

### 1.1 Đăng ký tài khoản (Multi-step Form)

Quy trình đăng ký chia **3 bước**, có thanh tiến trình ở trên cùng:

```mermaid
sequenceDiagram
    participant U as 👤 Người dùng
    participant App as 📱 App
    participant API as ☁️ Server
    participant DB as 🗄️ PostgreSQL

    Note over U,App: === STEP 1: Thông tin cá nhân ===
    U->>App: Nhập Họ tên, Username, Email
    App->>App: Validate (không để trống)
    U->>App: Bấm "Tiếp tục"

    Note over U,App: === STEP 2: Mật khẩu ===
    U->>App: Nhập mật khẩu
    App->>App: Tính độ mạnh real-time (xem bảng bên dưới)
    U->>App: Bấm "Đăng ký"
    App->>API: POST /auth/register
    API->>DB: INSERT INTO users
    DB-->>API: OK
    API-->>App: {token, user}
    App->>App: Lưu JWT vào SharedPreferences

    Note over U,App: === STEP 3: Thành công ===
    App->>App: Hiển thị ✅ "Đăng ký thành công!"
    App->>App: Tự động chuyển → Onboarding (2 giây)
```

**Quy tắc độ mạnh mật khẩu:**

Mật khẩu được đánh giá theo 4 tiêu chí, mỗi tiêu chí đạt = +0.25 điểm:

| Tiêu chí | Ví dụ đạt | Điểm |
|----------|----------|------|
| Độ dài ≥ 8 ký tự | `password` | +0.25 |
| Có chữ HOA | `Password` | +0.25 |
| Có chữ số | `Password1` | +0.25 |
| Có ký tự đặc biệt `!@#$%^&*` | `Password1!` | +0.25 |

| Tổng điểm | Nhãn hiển thị | Màu thanh |
|-----------|--------------|----------|
| 0 – 0.25 | Yếu | 🔴 Đỏ |
| 0.26 – 0.50 | Trung bình | 🟡 Vàng |
| 0.51 – 0.75 | Mạnh | 🔵 Xanh dương |
| 0.76 – 1.00 | Rất mạnh | 🟢 Xanh lá |

### 1.2 Đăng nhập

```mermaid
sequenceDiagram
    participant U as 👤 Người dùng
    participant App as 📱 App
    participant API as ☁️ Server

    U->>App: Nhập Email + Mật khẩu
    App->>App: Validate form

    alt ❌ Email không hợp lệ
        App-->>U: "Email không hợp lệ"
    else ❌ Mật khẩu < 8 ký tự
        App-->>U: "Mật khẩu tối thiểu 8 ký tự"
    else ❌ Để trống
        App-->>U: "Vui lòng nhập email / mật khẩu"
    else ✅ Hợp lệ
        App->>API: POST /auth/login
        alt Sai thông tin
            API-->>App: 401
            App-->>U: Snackbar "Sai email hoặc mật khẩu"
        else Đúng
            API-->>App: {token, user}
            App->>App: Lưu JWT → Home hoặc Onboarding
        end
    end
```

### 1.3 Onboarding

Sau đăng ký lần đầu, user chọn **kỹ năng quan tâm** (Flutter, React, Go, Python…). Dữ liệu này dùng để cá nhân hóa tab "Dành cho bạn" trên Feed.

---

## 2. Bảng tin (`feed`)

### 2.1 Ba tab bảng tin

| Tab | Thuật toán | Ý nghĩa |
|-----|-----------|---------|
| **Dành cho bạn** | Hybrid Relevance | Kết hợp kỹ năng user + bài viết phổ biến → Gợi ý bài phù hợp nhất |
| **Xu hướng** | High Engagement 72h | Bài có nhiều Like + Comment nhất trong 3 ngày gần đây |
| **Đang theo dõi** | Following Filter | Chỉ hiển thị bài từ những user đã Follow |

### 2.2 Tương tác trên bài viết

```mermaid
stateDiagram-v2
    state "Chưa Like (♡)" as CL
    state "Đã Like (❤️)" as DL
    state "Chưa Bookmark (☆)" as CB
    state "Đã Bookmark (★)" as DB

    [*] --> CL
    CL --> DL: Bấm Like
    DL --> CL: Bấm lại (Unlike)
    
    [*] --> CB
    CB --> DB: Bấm Bookmark
    DB --> CB: Bấm lại (Unbookmark)
```

> **Optimistic UI**: Icon đổi trạng thái **ngay lập tức** khi bấm, không chờ server. Nếu server trả lỗi → UI tự revert về trạng thái cũ. Điều này giúp app cảm giác cực kỳ mượt mà.

### 2.3 Tạo bài viết mới

Bấm nút FAB (+) trên Home → Điền form:

| Trường | Bắt buộc | Mô tả |
|--------|---------|-------|
| Tiêu đề | ✅ | Tên bài viết |
| Nội dung | ✅ | Hỗ trợ Markdown |
| Loại bài | ✅ | `Article` / `TIL` / `Question` |
| Tags | ❌ | Gắn nhãn chủ đề |

### 2.4 Chi tiết bài viết & Bình luận

Bấm vào bài viết → Xem chi tiết → Gửi bình luận:
- Nhập nội dung vào ô comment ở cuối màn hình
- Bấm icon Send (➤)
- Comment mới xuất hiện ngay trên danh sách
- `comment_count` trên bài viết được tăng lên

### 2.5 Pull-to-Refresh & Infinite Scroll

- **Kéo xuống** (Pull-to-refresh): Tải lại toàn bộ feed từ đầu
- **Cuộn tới cuối**: Tự động tải trang tiếp theo (Infinite scroll, 20 bài/trang)

---

## 3. Tuyển dụng (`job_board`)

### 3.1 Hiển thị Job Card

Mỗi thẻ việc làm hiển thị:

```
┌──────────────────────────────────┐
│ [G]  Google — Senior Flutter Dev │  ← Logo chữ cái đầu + Tên công ty
│                          [85%]   │  ← Match % (xanh lá)
│                                  │
│ [Flutter] [Dart] [Firebase]      │  ← Tech Stack chips
│ 📍 Hà Nội - Remote              │  ← Địa điểm + Remote
│ 💰 $3,000 - $5,000              │  ← Khoảng lương
│                                  │
│ ┌──────────────────────────────┐ │
│ │      Ứng tuyển ngay          │ │  ← Nút ứng tuyển
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

### 3.2 Luồng ứng tuyển

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant App as 📱 App
    participant API as ☁️ Server

    U->>App: Bấm "Ứng tuyển ngay"

    alt Chưa đăng nhập
        App-->>U: Snackbar "Vui lòng đăng nhập"
    else Đã ứng tuyển rồi
        App-->>App: Không làm gì (idempotent)
    else Lần đầu
        App->>API: POST /api/jobs/{id}/apply
        API-->>App: 200 OK
        App->>App: Nút đổi → "Đã ứng tuyển" (màu xanh lá)
        App-->>U: Snackbar "Đã ứng tuyển thành công!"
    end
```

**Quy tắc nghiệp vụ quan trọng:**
- Nút "Đã ứng tuyển" có `backgroundColor: success.withOpacity(0.1)` và `borderColor: success`
- Bấm lại nút "Đã ứng tuyển" → **không xảy ra gì** (idempotent, `_appliedJobs.contains(jobId)` trả `true`)
- Hỗ trợ Pull-to-refresh để cập nhật danh sách việc mới

---

## 4. Sàn dự án (`project_marketplace`)

### 4.1 Hiển thị Project Card

```
┌──────────────────────────────────┐
│ 👤 Minh Nguyen        [Tuyển]   │  ← Owner + Badge trạng thái
│ DevConnect Mobile App            │  ← Tên dự án
│ Mạng xã hội cho lập trình viên  │  ← Mô tả
│                                  │
│ [Flutter] [Node.js] [PostgreSQL] │  ← Tech Stack chips
│ 3/5 thành viên                   │  ← Tiến độ nhóm
└──────────────────────────────────┘
```

| Trạng thái | Badge | Màu |
|-----------|-------|-----|
| `LOOKING_FOR_MEMBERS` | Tuyển | 🟠 Accent |
| Khác | Hoạt động | 🔵 Primary |

- FAB "Tạo dự án" → Hiện Snackbar: *"Tạo dự án mới sẽ triển khai ở phase sau"*

---

## 5. Bảng xếp hạng (`leaderboard`)

Danh sách user sắp xếp theo `reputation` (giảm dần). Top 3 hiển thị icon đặc biệt (🥇🥈🥉).

---

## 6. Chat (`chat`)

### 6.1 Danh sách hội thoại

Hiển thị: Avatar + Tên + Tin nhắn cuối + Badge số tin chưa đọc

### 6.2 Gửi tin nhắn

```mermaid
sequenceDiagram
    participant A as 👤 User A
    participant WS as 🔌 WebSocket
    participant B as 👤 User B

    A->>WS: Gửi {content, type: "text"}
    WS->>WS: Lưu vào DB (messages)
    WS->>B: Push real-time
    B->>B: Hiển thị tin nhắn mới
```

**Loại tin nhắn:** `text` (văn bản) và `code` (code snippet có `code_language`)

---

## 7. Thông báo (`notifications`)

| Loại | Trigger | Nội dung |
|------|---------|---------|
| Like | Ai đó like bài của bạn | "X đã thích bài viết của bạn" |
| Follow | Ai đó follow bạn | "X đã theo dõi bạn" |
| Comment | Ai đó comment bài của bạn | "X đã bình luận bài viết của bạn" |

Nút **"Đọc hết"** → Đánh dấu tất cả `is_read = 1`

---

## 8. Profile (`profile`)

### 8.1 Cấu trúc màn hình

```
┌──────────────────────────────┐
│  [Avatar]   [Edit] [⚙️]     │
│  Minh Nguyen                 │
│  @minhdev                    │
│  Flutter developer           │
│                              │
│  ┌────────┬────────┬───────┐ │
│  │Bài viết│Theo dõi│Ng. TD │ │
│  │  12    │  156   │  89   │ │
│  └────────┴────────┴───────┘ │
│                              │
│  [Bài viết] [Đã lưu] [❤️]   │
│  ─ Danh sách nội dung ───── │
└──────────────────────────────┘
```

### 8.2 Xem Profile người khác

Bấm Avatar trên Feed/Chat/Leaderboard → Hiển thị Profile + nút **"Theo dõi"** (thay cho "Edit")

### 8.3 Follow/Unfollow

Toggle: Bấm 1 lần = Follow → Bấm lại = Unfollow. Cập nhật `follower_count` / `following_count` tức thì.

---

## 9. Cài đặt (`settings`)

| Mục | Tương tác | Loại UI |
|-----|----------|---------|
| Tài khoản | Chỉnh sửa thông tin cá nhân | Navigation |
| Giao diện | Chuyển Dark/Light mode | Switch toggle |
| Thông báo | Bật/tắt push notification | Switch toggle |
| Quyền riêng tư | Cấu hình hiển thị profile | Navigation |
| Về ứng dụng | Hiển thị phiên bản | Info page |
| Đăng xuất | Xóa JWT → Quay về Login | Button (destructive) |

---

## Tiếp theo

Đọc **[03_DATABASE.md](03_DATABASE.md)** để hiểu cấu trúc dữ liệu lưu trữ phía sau các luồng nghiệp vụ này.
