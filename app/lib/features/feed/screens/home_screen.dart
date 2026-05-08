import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _tabs = const ['Dành cho bạn', 'Đang theo dõi', 'Xu hướng'];
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

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) {
      HapticFeedback.selectionClick();
    }
  }

  void _loadFeeds() {
    _forYouPosts = _repository.getForYouPosts();
    _followingPosts = _repository.getFollowingPosts();
    _trendingPosts = _repository.getTrendingPosts();
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
    _tabCtrl.removeListener(_onTabChanged);
    FeedRefreshBus.instance.removeListener(_handleExternalRefresh);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('DevConnect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: _tabs.map((item) => Tab(text: item)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFeed(_forYouPosts),
          _buildFeed(_followingPosts),
          _buildFeed(_trendingPosts),
        ],
      ),
    );
  }

  Widget _buildFeed(Future<List<Post>> futurePosts) {
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                ErrorState(
                  message: 'Đã xảy ra lỗi khi tải bài viết.\nVui lòng kiểm tra kết nối mạng.',
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
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.feed_outlined,
                  title: 'Chưa có bài viết nào',
                  subtitle: 'Tạo bài viết đầu tiên hoặc kiểm tra lại dữ liệu local.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => PostCard(
              post: posts[index],
              onTap: () => context.push('/post/${posts[index].id}'),
            ),
          ),
        );
      },
    );
  }
}
