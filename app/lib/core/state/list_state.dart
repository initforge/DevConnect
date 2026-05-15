/// State class for paginated list screens.
class ListState<T> {
  const ListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.cursor,
    this.lastSyncAt,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final bool hasMore;
  final String? cursor;
  final DateTime? lastSyncAt;

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get hasError => error != null;

  ListState<T> loading() => ListState<T>(isLoading: true);
  ListState<T> success(List<T> items, {bool hasMore = false, String? cursor}) =>
      ListState<T>(
        items: items,
        hasMore: hasMore,
        cursor: cursor,
        lastSyncAt: DateTime.now(),
      );
  ListState<T> failure(Object error) =>
      ListState<T>(items: items, error: error);
  ListState<T> loadingMore() => copyWith(isLoadingMore: true);
  ListState<T> appendItems(
    List<T> newItems, {
    bool hasMore = false,
    String? cursor,
  }) => ListState<T>(
    items: [...items, ...newItems],
    hasMore: hasMore,
    cursor: cursor,
    lastSyncAt: DateTime.now(),
  );

  ListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasMore,
    String? cursor,
    DateTime? lastSyncAt,
  }) {
    return ListState<T>(
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
