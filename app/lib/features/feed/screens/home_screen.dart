import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _tabs = const ['For You', 'Following', 'Trending'];
  final _repository = PostRepository();

  late Future<List<Post>> _forYouPosts;
  late Future<List<Post>> _followingPosts;
  late Future<List<Post>> _trendingPosts;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    FeedRefreshBus.instance.addListener(_handleExternalRefresh);
    _loadFeeds();
  }

  void _loadFeeds() {
    _forYouPosts = _repository.getForYouPosts();
    _followingPosts = _repository.getFollowingPosts();
    _trendingPosts = _repository.getTrendingPosts();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleExternalRefresh() {
    if (!mounted) return;
    setState(_loadFeeds);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(_loadFeeds);
    await Future.wait([_forYouPosts, _followingPosts, _trendingPosts]);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    FeedRefreshBus.instance.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFF),
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.code, color: Color(0xFF4F46E5), size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'DevConnect',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search, size: 20),
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.notifications),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 20),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: _tabs.map((item) => Tab(text: item)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getContentMaxWidth(context),
          ),
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildFeed(_forYouPosts, highlightAi: true),
              _buildFeed(_followingPosts),
              _buildFeed(_trendingPosts),
            ],
          ),
        ),
     ),
    );
  }

  Widget _buildFeed(
    Future<List<Post>> futurePosts, {
    bool highlightAi = false,
  }) {
    return FutureBuilder<List<Post>>(
      future: futurePosts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                ErrorState(
                  message: 'Unable to load your feed.\nPlease try again.',
                  onRetry: _refresh,
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? const <Post>[];
        if (posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 140),
                EmptyState(
                  icon: Icons.feed_outlined,
                  title: 'No posts yet',
                  subtitle:
                      'Your feed will appear here once content is available.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: ResponsiveUtils.isDesktop(context)
                ? const EdgeInsets.fromLTRB(0, 8, 0, 80)
                : const EdgeInsets.fromLTRB(0, 8, 0, 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0 && highlightAi)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AI PICKED FOR YOU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: PostCard(
                      post: post,
                      index: index,
                      onTap:
                          () => context.push('${AppRoutes.postBase}/${post.id}'),
                    ),
                  ),
                  if (index != posts.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
