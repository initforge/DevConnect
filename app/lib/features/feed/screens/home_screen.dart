import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../widgets/feed_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<String> _tabLabels = const [];
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppStrings.of(context);
    _tabLabels = [
      s.t('feed.forYou'),
      s.t('feed.following'),
      s.t('feed.trending'),
    ];
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 12,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF21B5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.code, color: Colors.white, size: 14),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
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
                tabs: _tabLabels.map((item) => Tab(text: item)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: DecorativeBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getContentMaxWidth(context),
            ),
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                FeedList(
                  key: const PageStorageKey('foryou'),
                  fetcher: _repository.getForYouPosts,
                  highlightAi: true,
                  onRefresh: _refresh,
                ),
                FeedList(
                  key: const PageStorageKey('following'),
                  fetcher: _repository.getFollowingPosts,
                  onRefresh: _refresh,
                ),
                FeedList(
                  key: const PageStorageKey('trending'),
                  fetcher: _repository.getTrendingPosts,
                  onRefresh: _refresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
