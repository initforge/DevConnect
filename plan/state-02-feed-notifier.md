> ✅ Done 2026-05-15

# State 02 — Migrate feed sang FeedNotifier (Riverpod)

## Vị trí
- file/module chính sẽ tạo:
  - `app/lib/features/feed/application/feed_notifier.dart`
  - `app/lib/features/feed/application/feed_state.dart`
- file/module hiện tại sẽ refactor:
  - `app/lib/features/feed/widgets/feed_list.dart` — manage `_isLoading`, `_isLoadingMore`, `_hasMore`, `_posts` thủ công với setState
  - `app/lib/features/feed/widgets/post_card.dart` — gọi `_repository.toggleLike/Bookmark` trực tiếp + ScaffoldMessenger trong widget (vi phạm §2.2)
  - `app/lib/features/feed/screens/home_screen.dart` — 3 Future cho 3 tab, manual rebuild
- file/module liên quan:
  - `app/lib/data/repositories/post_repository.dart` (depend `repo-01`)
  - `app/lib/core/state/list_state.dart` (depend `state-01`)
  - `app/lib/core/state/feed_refresh_bus.dart` — sẽ thay bằng Riverpod invalidate
- file/module có thể bị ảnh hưởng:
  - `app/lib/features/feed/screens/post_detail_screen.dart` — sau khi like, invalidate FeedNotifier
  - `app/lib/features/profile/screens/profile_screen.dart` — Posts tab sync với feed reactions

## Vấn đề
- `FeedList` quản lý cursor/loading thủ công với setState → khó test, dễ bug (off-by-one trong `_hasMore = results.length >= 20` heuristic).
- `PostCard` (StatefulWidget) gọi repository + Snackbar trực tiếp → vi phạm clean-code §2.2 (notifier KHÔNG gọi UI; widget KHÔNG gọi repo).
- Không có 1 nguồn truth cho posts → like ở post detail không sync về list (phải full reload).
- non-goals:
  - KHÔNG đổi visual layout PostCard.
  - KHÔNG migrate explore/search (chỉ feed).
  - KHÔNG implement reactions ngay (depend `feature-05` riêng).

## Hướng giải quyết
- Bước 1: Tạo `FeedState` extend `ListState<Post>`:
  - + field `feedType: FeedType` (forYou/following/trending)
- Bước 2: Tạo `FeedNotifier` (family theo `FeedType`):
  - `build(FeedType type) async → ListState<Post>` initial load
  - `Future<void> refresh()`
  - `Future<void> loadMore()`
  - `Future<void> toggleLike(String postId)` — optimistic update state, rollback nếu fail
  - `Future<void> toggleBookmark(String postId)` — tương tự
  - Notifier KHÔNG gọi UI (Snackbar). Error → set state.error → screen lắng nghe và hiện snackbar.
- Bước 3: Rewrite FeedList → `ConsumerWidget` watch `feedNotifierProvider(feedType)`:
  - Loading state → render skeleton (depend `quickwin-01`)
  - Empty → EmptyState
  - Error → ErrorState với retry
  - Has data → ListView build PostCard
- Bước 4: Rewrite PostCard → `ConsumerWidget`, không StatefulWidget:
  - Like/bookmark button onPressed → `ref.read(feedNotifierProvider(feedType).notifier).toggleLike(post.id)`
  - Listen state.error → showSnackBar via `ref.listen`
  - Lấy `liked/bookmarked/likeCount` từ post entity (state là source of truth)
- Bước 5: home_screen — 3 FeedList với 3 family instance.
- Bước 6: post_detail_screen — sau khi like, invalidate `feedNotifierProvider(...)` để feed sync.
- Bước 7: Xoá `FeedRefreshBus` global singleton (Riverpod invalidate thay thế).
- Alternative đã loại trừ:
  - Giữ FeedRefreshBus ChangeNotifier — loại do clean-code §2.2 (không global state ngoài Riverpod).
  - PostCard nhận onLike/onBookmark callback từ parent — tradeoff OK nhưng kém scale (mỗi parent define lại).

## Cách check & verify
- Commands:
  - `cd app && flutter analyze`
  - `flutter test test/features/feed/` (sẽ tạo cùng plan: notifier_test với mock PostRepository)
  - `flutter test integration_test/flows/feed_flow_02_test.dart`
- Manual:
  - Mở home → 3 tab load độc lập
  - Tab For You: like 1 post → like count tăng ngay (optimistic)
  - Mạng fail → like rollback + snackbar lỗi (depend `quickwin-06`)
  - Mở post detail từ feed, like ở detail → quay lại feed → like state sync
  - Pull-to-refresh → list reload
  - Scroll bottom → load more, hiện skeleton inline
- Downstream/upstream:
  - `state-01-state-class-template.md` ready, dùng `ListState<T>`
  - `repo-01-post-repository-dry.md` ready, repository method DRY
  - `quickwin-01-skeleton-loading.md` ready, skeleton wire vào loading state
- Tiêu chí pass:
  - FeedList ≤200 dòng (giảm từ 206)
  - PostCard là `ConsumerWidget`, KHÔNG gọi repo trực tiếp, KHÔNG gọi ScaffoldMessenger
  - 3 tab feed dùng cùng FeedNotifier với family
  - Like tại 1 chỗ sync sang chỗ khác qua provider
  - Test pass
- Tiêu chí fail / red flag:
  - State.error không show snackbar → ref.listen chưa setup đúng → check pattern listen-on-state-change
  - Optimistic không rollback đúng → kiểm copyWith deep enough cho posts list
  - Family instance bị recreate quá nhiều → autoDispose có thể quá hung → tinh chỉnh keepAlive
