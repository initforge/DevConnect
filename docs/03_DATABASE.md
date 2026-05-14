# 03. Database

## 1. Nguyên tắc dữ liệu

PostgreSQL là nguồn sự thật chính. Redis chỉ là dữ liệu tạm để nhanh hơn. MinIO chỉ giữ file. Không còn MongoDB trong runtime hiện tại vì code không dùng nó.

Nói đơn giản: nếu mất Redis thì app chậm hơn nhưng dữ liệu thật vẫn còn. Nếu mất PostgreSQL thì mất dữ liệu chính. Nếu mất MinIO thì mất file upload.

## 2. Nhóm user

| Bảng | Dùng cho | Vì sao cần |
|---|---|---|
| `users` | Tài khoản, profile, skills, reputation, settings | Gần như màn nào cũng cần biết ai đang thao tác. |
| `user_follows` | Quan hệ follow/following | Feed Following, profile follower count, notification follow. |
| `fcm_tokens` | Push token thiết bị | Gửi push khi user offline. |
| `user_post_interactions` | View/like/comment/bookmark history | Gợi ý feed và analytics hành vi. |

Quan hệ follow có unique constraint `[followerId, followingId]` để một người không follow trùng cùng một người nhiều lần.

## 3. Nhóm post/feed

| Bảng | Dùng cho | Vì sao cần |
|---|---|---|
| `posts` | Bài viết chính | Giữ title, content, type, tags, count, trending score. |
| `post_likes` | Like của user trên post | Không chỉ lưu số count, còn phải biết user hiện tại đã like chưa. |
| `post_bookmarks` | Bookmark của user | Feed/detail cần state "đã lưu". |
| `comments` | Bình luận | Post detail, comment count, best answer. |

Count như `likeCount`, `commentCount`, `bookmarkCount` được lưu trên `posts` để list feed không phải đếm lại mỗi lần. Nhưng bảng phụ vẫn tồn tại để chống double-like và biết user nào đã tương tác.

## 4. Nhóm chat

| Bảng | Dùng cho | Vì sao cần |
|---|---|---|
| `conversations` | Một thread chat giữa user và otherUser | Chat list cần last message, unread count, updated time. |
| `messages` | Tin nhắn trong conversation | Chat detail cần nội dung, sender, read status, code snippet. |

Unread là state cấp conversation để chat list render nhanh. Khi mở conversation, backend mark message từ người khác là read và set `unreadCount = 0`.

## 5. Nhóm notification

| Bảng | Dùng cho | Vì sao cần |
|---|---|---|
| `notifications` | Like/comment/follow/mention/project events | Màn Notifications, badge unread, grouped display. |

Notification có `isRead` để UI biết cái nào cần highlight. Grouped notification nên giữ `mergedCount` ở response/model để UI có badge `+N`.

## 6. Nhóm project/job

| Bảng | Dùng cho | Vì sao cần |
|---|---|---|
| `projects` | Marketplace dự án | Owner, title, description, tech stack, status. |
| `project_members` hoặc membership tương đương | Join/accept/reject | Chủ dự án cần duyệt thành viên. |
| `jobs` | Job board | Công ty, title, remote, salary, tech stack. |
| `job_applications` | Apply job | User cần biết đã apply chưa, nhà tuyển dụng cần danh sách ứng viên. |

Các bảng này tách riêng để project/job không bị trộn vào post thường. Một dự án có lifecycle khác bài viết.

## 7. Redis

Redis giữ:

1. Cache feed: `posts:feed:*`.
2. Cache post detail: `posts:item:{id}:*`.
3. Presence chat: `online:user:{id}` với TTL ngắn.
4. BullMQ queues: trending recalculation, post notifications, AI/background jobs.

Sau khi like/bookmark/comment/create post, backend xóa cache post/feed để lần reload sau lấy số mới. Đây là phần quan trọng để tránh lỗi UI bị trôi count.

## 8. MinIO

MinIO giữ object file như ảnh upload. Database chỉ nên giữ URL hoặc object key. Lý do: file lớn không nên nhét vào PostgreSQL vì backup, query và storage sẽ nặng.

MinIO có:

1. Port `9000` cho API upload/download object.
2. Port `9001` cho console quản trị.

## 9. Index cần chú ý

Các index quan trọng:

1. `user_follows.followerId`, `followingId`: feed following và profile.
2. `post_likes.postId/userId`, `post_bookmarks.postId/userId`: toggle nhanh và chống trùng.
3. `conversations.userId`, `updatedAt DESC`: chat list.
4. `messages.conversationId`: load message theo thread.
5. Search vector/index cho posts/users: search results.

Nếu thiếu index, app vẫn "chạy được" nhưng khi dữ liệu lớn sẽ chậm và người dùng tưởng app lỗi.
