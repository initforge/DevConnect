import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../application/feed_notifier.dart';
import '../application/feed_state.dart';
import 'post_card.dart';

class FeedList extends ConsumerStatefulWidget {
  const FeedList({
    super.key,
    required this.feedType,
    this.highlightAi = false,
    required this.onRefresh,
  });

  final FeedType feedType;
  final bool highlightAi;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<FeedList> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(feedNotifierProvider(widget.feedType).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider(widget.feedType));

    if (feedState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: 5,
        itemBuilder: (_, __) => const PostCardSkeleton(),
      );
    }

    if (feedState.hasError) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh();
          await ref
              .read(feedNotifierProvider(widget.feedType).notifier)
              .refresh();
        },
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            ErrorState(
              message: 'Unable to load your feed.\nPlease try again.',
              onRetry:
                  () =>
                      ref
                          .read(feedNotifierProvider(widget.feedType).notifier)
                          .refresh(),
            ),
          ],
        ),
      );
    }

    if (feedState.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh();
          await ref
              .read(feedNotifierProvider(widget.feedType).notifier)
              .refresh();
        },
        child: ListView(
          children: const [
            SizedBox(height: 140),
            EmptyState(
              icon: Icons.feed_outlined,
              title: 'No posts yet',
              subtitle: 'Your feed will appear here once content is available.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
        await ref
            .read(feedNotifierProvider(widget.feedType).notifier)
            .refresh();
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: feedState.items.length + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedState.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: PostCardSkeleton(),
            );
          }

          final post = feedState.items[index];
          return Column(
            children: [
              if (index == 0 && widget.highlightAi) _buildAiBadge(),
              PostCard(
                post: post,
                feedType: widget.feedType,
                index: index,
                onTap: () => context.push('${AppRoutes.postBase}/${post.id}'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAiBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 11,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Personalized for you',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF047857),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Based on your interests & activity',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF6EE7B7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
