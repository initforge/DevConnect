import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/riverpod/providers.dart';
import '../../../data/repositories/post_repository.dart';
import 'feed_state.dart';

class FeedNotifier extends AutoDisposeFamilyNotifier<FeedState, FeedType> {
  @override
  FeedState build(FeedType arg) {
    _load();
    return const FeedState(isLoading: true);
  }

  Future<void> _load() async {
    state = const FeedState(isLoading: true);
    try {
      final repo = ref.read(postRepositoryProvider);
      final posts = await _fetchByType(repo, arg);
      state = FeedState(items: posts, hasMore: posts.length >= 20);
    } catch (e) {
      state = FeedState(error: e);
    }
  }

  Future<void> refresh() => _load();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(postRepositoryProvider);
      final cursor = state.items.isNotEmpty ? state.items.last.id : null;
      final more = await _fetchByType(repo, arg, cursor: cursor);
      state = state.appendItems(
        more,
        hasMore: more.length >= 20,
        cursor: cursor,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String postId) async {
    final idx = state.items.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = state.items[idx];
    final optimistic = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    final updated = [...state.items];
    updated[idx] = optimistic;
    state = state.copyWith(items: updated);
    try {
      await ref.read(postRepositoryProvider).toggleLike(postId);
    } catch (_) {
      // Rollback
      final rollback = [...state.items];
      rollback[idx] = post;
      state = state.copyWith(items: rollback);
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final idx = state.items.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = state.items[idx];
    final optimistic = post.copyWith(
      isBookmarkedByMe: !post.isBookmarkedByMe,
      bookmarkCount:
          post.isBookmarkedByMe
              ? post.bookmarkCount - 1
              : post.bookmarkCount + 1,
    );
    final updated = [...state.items];
    updated[idx] = optimistic;
    state = state.copyWith(items: updated);
    try {
      await ref.read(postRepositoryProvider).toggleBookmark(postId);
    } catch (_) {
      final rollback = [...state.items];
      rollback[idx] = post;
      state = state.copyWith(items: rollback);
    }
  }

  Future<List<Post>> _fetchByType(
    PostRepository repo,
    FeedType type, {
    String? cursor,
  }) {
    switch (type) {
      case FeedType.forYou:
        return repo.getForYouPosts(cursor: cursor);
      case FeedType.following:
        return repo.getFollowingPosts(cursor: cursor);
      case FeedType.trending:
        return repo.getTrendingPosts(cursor: cursor);
    }
  }
}

final feedNotifierProvider =
    AutoDisposeNotifierProviderFamily<FeedNotifier, FeedState, FeedType>(
      FeedNotifier.new,
    );
