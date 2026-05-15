import '../../../core/models/models.dart';
import '../../../core/state/list_state.dart';

export '../../../data/repositories/post_repository.dart' show FeedType;

class FeedState extends ListState<Post> {
  const FeedState({
    super.items,
    super.isLoading,
    super.isLoadingMore,
    super.error,
    super.hasMore,
    super.cursor,
    super.lastSyncAt,
  });

  @override
  FeedState loading() => const FeedState(isLoading: true);

  @override
  FeedState success(List<Post> items, {bool hasMore = false, String? cursor}) =>
      FeedState(
        items: items,
        hasMore: hasMore,
        cursor: cursor,
        lastSyncAt: DateTime.now(),
      );

  @override
  FeedState failure(Object error) => FeedState(items: items, error: error);

  @override
  FeedState loadingMore() => _copyWith(isLoadingMore: true);

  @override
  FeedState appendItems(
    List<Post> newItems, {
    bool hasMore = false,
    String? cursor,
  }) => FeedState(
    items: [...items, ...newItems],
    hasMore: hasMore,
    cursor: cursor,
    lastSyncAt: DateTime.now(),
  );

  @override
  FeedState copyWith({
    List<Post>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasMore,
    String? cursor,
    DateTime? lastSyncAt,
  }) => _copyWith(
    items: items,
    isLoading: isLoading,
    isLoadingMore: isLoadingMore,
    error: error,
    hasMore: hasMore,
    cursor: cursor,
    lastSyncAt: lastSyncAt,
  );

  FeedState _copyWith({
    List<Post>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasMore,
    String? cursor,
    DateTime? lastSyncAt,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}
