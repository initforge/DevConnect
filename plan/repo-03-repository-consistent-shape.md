> ✅ Done 2026-05-15

# Repo 03 — Repository return shape nhất quán

## Vị trí
- file/module chính (audit toàn bộ):
  - `app/lib/data/repositories/post_repository.dart`
  - `app/lib/data/repositories/user_repository.dart`
  - `app/lib/data/repositories/comment_repository.dart`
  - `app/lib/data/repositories/chat_repository.dart`
  - `app/lib/data/repositories/notification_repository.dart`
  - `app/lib/data/repositories/project_repository.dart`
  - `app/lib/data/repositories/job_repository.dart`
  - `app/lib/data/repositories/leaderboard_repository.dart`
  - `app/lib/data/repositories/interaction_repository.dart`
- file/module liên quan: `app/lib/core/models/` — verify mọi method trả entity model, không dynamic
- file/module có thể bị ảnh hưởng: caller screen, sau khi return type đổi từ `T?` sang `T` (throw on not-found) phải catch type mới

## Vấn đề
- Audit code-quality:
  - Một số method trả `null` cho lỗi (vd `getUserById` null = không tồn tại VS null = error).
  - Một số method trả `dynamic` hoặc `Map<String, dynamic>` thay model.
  - Inconsistent: vài method `getX` cho I/O (clean-code §1.3 nói tránh, dùng `fetchX`).
- non-goals:
  - KHÔNG đổi all naming `get`→`fetch` ngay (broad). Plan này chỉ chuẩn return type + null semantics.
  - KHÔNG đổi public API behavior cho caller (chỉ refactor internal + return type khi cần).

## Hướng giải quyết
- Bước 1 — Quy ước return shape:
  - `Future<T>` cho action 1 entity. Throw nếu fail (network, validation, etc.).
  - `Future<T?>` CHỈ cho query "tìm kiếm có thể không có" (vd `getById(id)` trả null nếu 404 hoặc DB không tìm thấy).
  - `Future<List<T>>` cho list. Empty list ≠ error (luôn return list, throw nếu fail).
  - `Stream<T>` cho realtime (chat messages stream).
- Bước 2 — Audit từng method, fix:
  - `chat_repository.getConversationOtherUser(id)` đang return `User?` cho cả error lẫn not-found → tách: throw `NotFoundException` nếu không tồn tại, return `User` chắc chắn.
  - `post_repository.getPostById(id)` tương tự.
  - Method trả `Map<String, dynamic>` → tạo model thật trong `core/models/` rồi map qua mapper.
- Bước 3 — Naming async I/O:
  - `getXxx` → `fetchXxx` cho I/O (network).
  - `getXxx` cho local cache lookup (DB).
  - Plan này CHỈ áp dụng cho method mới hoặc method touch khi refactor return type. Toàn bộ rename là plan riêng (chưa list).
- Bước 4 — chia commit per repo.
- Alternative đã loại trừ:
  - Dùng `Result<T, E>` pattern — loại theo clean-code §4.4.
  - Trả `T?` cho mọi error → loại vì user không phân biệt được null = error vs null = not found.
  - Đổi tên `get` → `fetch` cho TẤT CẢ method ngay — broad, blast radius lớn.

## Cách check & verify
- Commands:
  - `cd app && flutter analyze`
  - `flutter test test/data/repositories/`
- Manual:
  - Conversation không tồn tại → ChatScreen catch `NotFoundException` → EmptyState (đã có)
  - Post deleted → PostDetailScreen catch `NotFoundException` → "Post not found" (đã có)
- Downstream/upstream:
  - Caller catch type mới (sau `repo-02`) — verify chuỗi error handling thông suốt
  - Test mock trả null cho error case → update mock throw exception thay
- Tiêu chí pass:
  - 0 method trả `null` cho error (chỉ null = "not found" hợp lệ)
  - 0 method trả `dynamic` (đều typed)
  - List method luôn return List (rỗng OK), không null
- Tiêu chí fail / red flag:
  - Caller crash với "Null check operator on null value" → caller giả định null = error nhưng giờ throw → fix caller catch type
  - Test mock trả null cho error → update mock throw exception
  - Method trả `Map<String, dynamic>` chưa có model → tạo model trong `core/models/` trước khi đổi return type
