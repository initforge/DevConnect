# 01. Tổng Quan DevConnect

## 1. DevConnect là gì

DevConnect là một mạng xã hội cho lập trình viên. Người dùng có thể đăng bài, đọc feed cá nhân hóa, bình luận, lưu bài, nhắn tin, nhận thông báo, tìm dự án, ứng tuyển job, dùng playground/AI để review hoặc giải thích code.

`docs/showcase` là bộ ảnh chuẩn để đối chiếu trải nghiệm. App thật phải được kiểm tra ngược lại với bộ ảnh đó, không chỉ nhìn một màn rồi kết luận "chạy được".

## 2. Kiến trúc một câu

Flutter render giao diện. NestJS nhận request và realtime event. PostgreSQL giữ dữ liệu chính. Redis giữ cache, queue và presence ngắn hạn. MinIO giữ file upload. Nginx đứng trước để gom các cổng thành một cửa vào.

Luồng cơ bản:

1. Người dùng bấm trong Flutter.
2. Flutter gọi `http://localhost/api/...` hoặc mở Socket.IO namespace `/chat`.
3. Nginx nhận request ở port `80` và chuyển vào backend NestJS port `8080`.
4. Backend đọc/ghi PostgreSQL, dùng Redis cho cache/queue, dùng MinIO nếu có file.
5. Flutter cập nhật UI ngay nếu action phù hợp optimistic state, rồi đồng bộ lại theo kết quả backend.

## 3. Vì sao có các container

| Container | Vai trò | Lý do tồn tại |
|---|---|---|
| `nginx` | Cửa vào duy nhất ở port `80` | Trình duyệt/mobile chỉ cần gọi một host. Nginx proxy `/api`, `/chat`, `/storage` đến đúng service bên trong. |
| `backend` | NestJS API ở port nội bộ `8080` | Chứa logic auth, feed, chat, notification, project, job, AI, media. |
| `postgres` | Database chính | Dữ liệu quan hệ như user, post, comment, like, bookmark, conversation, message cần transaction và index rõ ràng. |
| `redis` | Cache + queue + presence | Feed, profile, trending cần trả nhanh; BullMQ cần Redis; online status cần TTL ngắn. |
| `minio` | Object storage | File upload cần storage kiểu S3 thay vì nhét blob vào database. |

## 4. Vì sao có nhiều port

| Port | Ai dùng | Giải thích |
|---:|---|---|
| `80` | Người dùng/app | Cổng chính qua Nginx. Flutter web/mobile mặc định gọi `http://localhost/api`. |
| `8080` | Backend bên trong Docker hoặc local dev | NestJS listen ở đây. Khi chạy qua Nginx, người dùng không cần gọi trực tiếp port này. |
| `5432` | Backend -> PostgreSQL | Cổng database, không dành cho UI. |
| `6379` | Backend/BullMQ -> Redis | Cổng cache/queue/presence, không dành cho UI. |
| `9000` | Backend/Nginx -> MinIO API | Cổng máy dùng để upload/download object. |
| `9001` | Dev/admin | Console web của MinIO. Đây là lý do MinIO có 2 port: một port cho API, một port cho màn quản trị. |

## 5. Vì sao chọn tech này

| Tech | Dùng cho | Vì sao hợp |
|---|---|---|
| Flutter | App mobile/web | Một codebase cho nhiều màn, UI nhiều animation, chạy được mobile và web build. |
| NestJS | Backend | Module rõ ràng, guard/auth/gateway/queue dễ tách, hợp TypeScript. |
| Prisma + PostgreSQL | Data chính | Quan hệ user/post/comment/message cần unique constraint, transaction, index, full-text search. |
| Redis | Cache, BullMQ, online TTL | Dữ liệu tạm, cần nhanh, mất được, tự hết hạn. |
| Socket.IO | Chat/presence/typing | Dễ reconnect, event rõ, Flutter có client package. |
| MinIO | File/media | Tương thích S3, chạy local bằng Docker, không khóa vào cloud vendor. |
| Nginx | Reverse proxy | Gom port, proxy websocket, proxy object storage, đơn giản hóa URL cho app. |

## 6. Nguồn sự thật

Nguồn sự thật theo thứ tự:

1. Code runtime trong `app/lib`, `backend/src`, `docker-compose.yml`, `nginx.conf`.
2. `docs/showcase` là chuẩn hình ảnh và chuẩn luồng cần đối chiếu.
3. Docs 01-07 giải thích trạng thái hiện tại sau khi đối chiếu, không thay thế code.

Nếu docs nói có một feature nhưng route/API không có, đó là lỗi docs. Nếu showcase có một trạng thái mà runtime chưa xử lý, đó là gap cần đưa vào roadmap, không được viết như đã hoàn thiện.
