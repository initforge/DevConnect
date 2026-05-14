# 04. API

## 1. Quy ước chung

Backend có global prefix `/api`. Khi docs ghi `GET /posts`, URL thật qua Nginx là `http://localhost/api/posts`.

Auth dùng JWT. Flutter lưu token local, `ApiService` tự gắn header:

```http
Authorization: Bearer <token>
```

Socket.IO không dùng header HTTP thường trong browser flow; client gửi token qua `handshake.auth.token`.

## 2. Auth và user

| Endpoint | Screen gọi | Ý nghĩa |
|---|---|---|
| `POST /auth/login` | Login | Đăng nhập, trả token + user. |
| `POST /auth/register` | Register | Tạo account, trả token + user. |
| `POST /auth/refresh` | API service | Làm mới token khi hết hạn. |
| `GET /users/me` | Bootstrap/profile | Lấy user hiện tại. |
| `PATCH /users/me` | Onboarding/profile | Cập nhật skills/profile. |
| `GET /users/:id` | Profile/chat list | Lấy user khác. |
| `GET /users/:id/repos` | Profile | Lấy repo GitHub public. |
| `GET /users/:id/github-contributions` | Profile | Lấy contribution graph. |
| `POST /users/:id/github-sync` | Profile | Xóa cache GitHub và sync lại repo/contribution. |
| `POST /users/:id/follow` | Post detail/profile | Follow user. |
| `DELETE /users/:id/follow` | Profile | Unfollow user. |
| `GET /users/me/settings` | Settings | Lấy settings server. |
| `PATCH /users/me/settings` | Settings | Lưu settings server. |

## 3. Feed và post

| Endpoint | Screen gọi | Contract quan trọng |
|---|---|---|
| `GET /posts?type=foryou` | Home tab For You | Trả list post có `isLikedByMe`, `isBookmarkedByMe`, counts. |
| `GET /posts?type=following` | Home tab Following | Chỉ post từ người đã follow. |
| `GET /posts?type=trending` | Home tab Trending | Sort theo `trendingScore`. |
| `GET /posts/:id` | Post detail | Trả một post đủ author/tags/count/state. |
| `POST /posts` | Create post | Tạo post, queue notifications, xóa cache feed. |
| `POST /posts/:id/like` | Feed/detail | Trả `{ liked, likeCount, trendingScore }`. |
| `POST /posts/:id/bookmark` | Feed/detail | Trả `{ bookmarked, bookmarkCount, trendingScore }`. |
| `GET /posts/:id/comments` | Post detail | Load comment list. |
| `POST /posts/:id/comments` | Post detail | Tạo comment, tăng `commentCount`, xóa cache. |
| `PATCH /posts/:id/comments/:commentId/best-answer` | Post detail | Author chọn best answer, reset best answer cũ. |
| `GET /posts/search?q=` | Search results | Full-text search post. |

Like/bookmark không được chỉ trả bool nếu UI cần count đúng. Count thật từ backend là cách tránh bug bấm like rồi số cứ giảm sai.

## 4. Chat và realtime

HTTP:

| Endpoint | Screen gọi | Ý nghĩa |
|---|---|---|
| `GET /chat/conversations` | Chat list | List conversation + unread count + last message. |
| `GET /chat/conversations/:id/messages` | Chat detail | Tin nhắn trong thread. |
| `PATCH /chat/conversations/:id/read` | Chat list/detail | Mark conversation read ngay khi mở. |
| `POST /chat/conversations/:id/messages` | Chat detail | Gửi message bằng HTTP fallback. |
| `POST /chat/conversations/:id/messages/:messageId/reactions` | Chat detail | Toggle reaction trên message. |
| `DELETE /chat/conversations/:id` | Chat list | Xóa conversation. |

Socket.IO:

| Namespace/Event | Payload | Ý nghĩa |
|---|---|---|
| `/chat` handshake | `{ auth: { token } }` | Backend verify JWT để biết user thật. |
| `presence_change` | `{ userId, status }` | Online/offline. |
| `join_conversation` | `conversationId` | Join room. |
| `send_message` | `{ conversationId, content, type }` | Gửi message realtime. |
| `new_message` | message object | Broadcast message đã lưu. |
| `typing` | `{ conversationId, isTyping }` | Typing indicator. |

## 5. Notifications

| Endpoint | Screen gọi | Ý nghĩa |
|---|---|---|
| `GET /notifications` | Notifications | List notification. |
| `GET /notifications/count` | App badge | Unread count. |
| `PATCH /notifications/read-all` | Notifications | Mark all read. |
| `PATCH /social/notifications/:id/read` | Notifications | Mark one read. |

Client hiện update notification local list ngay sau API để user không cần reload.

## 6. Projects và jobs

| Endpoint | Screen gọi | Ý nghĩa |
|---|---|---|
| `GET /projects` | Project marketplace | List projects. |
| `GET /projects/:id` | Project detail | Detail. |
| `POST /projects` | Create project | Tạo project. |
| `POST /projects/:id/join` | Project detail | Xin tham gia. |
| `POST /projects/:id/members/:userId/accept` | Owner action | Duyệt member. |
| `GET /jobs` | Job board | List jobs. |
| `GET /jobs/:id` | Job detail/apply | Detail. |
| `POST /jobs/:id/apply` | Job board/detail | Apply job. |
| `GET /jobs/my-applications` | My applications | List application của user. |

## 7. Tools, AI, analytics

| Endpoint | Screen gọi | Ý nghĩa |
|---|---|---|
| `POST /playground/run` hoặc `/code/run` | Playground | Chạy code. |
| `POST /ai/code-review` | Post/playground/create | Review code. |
| `POST /ai/explain` | Post/playground | Giải thích code. |
| `POST /ai/mentor-match` | Mentorship | Tính match mentor. |
| `GET /leaderboard` | Leaderboard | Ranking. |
| `GET /analytics/me` | Analytics | Stats cá nhân. |
| `POST /media/upload` | Create/profile | Upload file lên MinIO. |

## 8. API pass thật là gì

Một endpoint không chỉ "trả 200". Pass thật cần:

1. Screen gọi đúng URL.
2. Backend đọc đúng user từ JWT.
3. Response có đủ field UI đang dùng.
4. Local cache/Redis cache không trả dữ liệu cũ sau mutation.
5. UI cập nhật ngay khi user tương tác, và rollback nếu API fail.
