/// Base state class for async screens with data, loading, error.
/// See clean-code §2.1 for rationale.
class AsyncState<T> {
  const AsyncState({
    this.data,
    this.isLoading = false,
    this.error,
    this.lastSyncAt,
  });

  final T? data;
  final bool isLoading;
  final Object? error;
  final DateTime? lastSyncAt;

  bool get hasData => data != null;
  bool get hasError => error != null;

  AsyncState<T> copyWith({
    T? data,
    bool? isLoading,
    Object? error,
    DateTime? lastSyncAt,
    bool clearError = false,
  }) {
    return AsyncState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  AsyncState<T> loading() => copyWith(isLoading: true, clearError: true);
  AsyncState<T> success(T data) =>
      AsyncState<T>(data: data, lastSyncAt: DateTime.now());
  AsyncState<T> failure(Object error) =>
      copyWith(isLoading: false, error: error);
}
