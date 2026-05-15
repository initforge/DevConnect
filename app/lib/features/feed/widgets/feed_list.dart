import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import 'post_card.dart';
import '../../../core/widgets/shared_widgets.dart';

class FeedList extends StatefulWidget {
  final Future<List<Post>> Function({String? cursor}) fetcher;
  final bool highlightAi;
  final Future<void> Function() onRefresh;

  const FeedList({
    super.key,
    required this.fetcher,
    this.highlightAi = false,
    required this.onRefresh,
  });

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await widget.fetcher();
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(results);
          _isLoading = false;
          _hasMore = results.length >= 20; // Assuming 20 is the limit
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final lastId = _posts.isNotEmpty ? _posts.last.id : null;
      final results = await widget.fetcher(cursor: lastId);
      if (mounted) {
        setState(() {
          _posts.addAll(results);
          _isLoadingMore = false;
          _hasMore = results.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh();
          await _loadInitial();
        },
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            ErrorState(
              message: 'Unable to load your feed.\nPlease try again.',
              onRetry: _loadInitial,
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh();
          await _loadInitial();
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
        await _loadInitial();
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _posts[index];
          return Column(
            children: [
              if (index == 0 && widget.highlightAi) _buildAiBadge(),
              PostCard(
                post: post,
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
