import 'package:flutter/material.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';

part 'analytics_widgets.dart';

const bool _kScreenshotMode = AppRuntimeConfig.screenshotMode;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();
  late Future<_AnalyticsSourceData> _loader;

  String _selectedRange = '7d';

  @override
  void initState() {
    super.initState();
    _loader = _loadAnalyticsViewData();
  }

  Future<_AnalyticsSourceData> _loadAnalyticsViewData() async {
    final results = await Future.wait<dynamic>([
      ApiService.instance.getObject('/api/analytics'),
      _userRepository.getCurrentUser(),
    ]);

    final analytics = results[0] as Map<String, dynamic>;
    final currentUser = results[1] as User?;
    final posts =
        currentUser == null
            ? const <Post>[]
            : await _postRepository.getPostsByAuthor(currentUser.id, limit: 20);

    return _AnalyticsSourceData(
      analytics: analytics,
      currentUser: currentUser,
      posts: posts,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kScreenshotMode) {
      return _buildScaffold(_showcaseViewData);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Analytics',
            route: AppRoutes.analytics,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.analytics,
        centerCreate: true,
      ),
      body: SafeArea(
        child: FutureBuilder<_AnalyticsSourceData>(
          future: _loader,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Unable to load analytics data',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loader = _loadAnalyticsViewData();
                        });
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }

            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Scaffold _buildScaffold(_AnalyticsViewData data) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Analytics',
            route: AppRoutes.analytics,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.analytics,
        centerCreate: true,
      ),
      body: SafeArea(child: _buildContent(data)),
    );
  }

  Widget _buildContent(dynamic payload) {
    final data =
        payload is _AnalyticsSourceData
            ? _buildLiveViewData(
              analytics: payload.analytics,
              currentUser: payload.currentUser,
              posts: payload.posts,
              range: _selectedRange,
            )
            : payload as _AnalyticsViewData;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_none, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedRange = '7d'),
              child: _RangeChip(
                label: '7 Days',
                selected: _selectedRange == '7d',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedRange = '30d'),
              child: _RangeChip(
                label: '30 Days',
                selected: _selectedRange == '30d',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedRange = 'all'),
              child: _RangeChip(
                label: 'All Time',
                selected: _selectedRange == 'all',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EAF2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TinyMetric(
                      label: data.metrics[0].label,
                      value: data.metrics[0].value,
                      delta: data.metrics[0].delta,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TinyMetric(
                      label: data.metrics[1].label,
                      value: data.metrics[1].value,
                      delta: data.metrics[1].delta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TinyMetric(
                      label: data.metrics[2].label,
                      value: data.metrics[2].value,
                      delta: data.metrics[2].delta,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TinyMetric(
                      label: data.metrics[3].label,
                      value: data.metrics[3].value,
                      delta: data.metrics[3].delta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EAF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Viewer Over Time',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                data.chartValue,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ChartPainter(),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        if (data.topItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Top Performing',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...data.topItems.asMap().entries.map(
            (entry) => _RankedAnalyticsRow(
              rank: '#${entry.key + 1}',
              title: entry.value.title,
              value: entry.value.value,
            ),
          ),
        ],
        if (data.audience.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Audience Insights',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EAF2)),
            ),
            child: Column(
              children:
                  data.audience
                      .map(
                        (item) => _ReaderBar(
                          label: item.label,
                          percent: item.percent,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ],
    );
  }

  _AnalyticsViewData _buildLiveViewData({
    required Map<String, dynamic> analytics,
    required User? currentUser,
    required List<Post> posts,
    required String range,
  }) {
    final now = DateTime.now();
    final filteredPosts = switch (range) {
      '7d' =>
        posts
            .where(
              (post) =>
                  post.createdAt.isAfter(now.subtract(const Duration(days: 7))),
            )
            .toList(),
      '30d' =>
        posts
            .where(
              (post) => post.createdAt.isAfter(
                now.subtract(const Duration(days: 30)),
              ),
            )
            .toList(),
      _ => posts,
    };

    final totalViews = _sumPosts(filteredPosts, (post) => post.viewCount);
    final totalLikes = _sumPosts(filteredPosts, (post) => post.likeCount);
    final totalComments = _sumPosts(filteredPosts, (post) => post.commentCount);
    final followers = currentUser?.followerCount ?? 0;
    final shouldUseFallback = range == 'all' && filteredPosts.isEmpty;

    final resolvedViews =
        totalViews > 0 || !shouldUseFallback
            ? totalViews
            : _asInt(analytics['totalViews']);
    final resolvedLikes =
        totalLikes > 0 || !shouldUseFallback
            ? totalLikes
            : _sumDynamicList(
              analytics['topPosts'] as List? ?? const [],
              'likes',
            );
    final resolvedComments = totalComments;
    final resolvedFollowers =
        followers > 0 ? followers : _asInt(analytics['activeUsersThisWeek']);

    final rankedPosts = [...filteredPosts]
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    final liveTopItems =
        rankedPosts.isNotEmpty
            ? rankedPosts
                .take(3)
                .map(
                  (post) => _AnalyticsRankedItem(
                    title: post.title,
                    value: _formatCompact(post.viewCount),
                  ),
                )
                .toList()
            : (shouldUseFallback
                ? (analytics['topPosts'] as List? ?? const [])
                    .take(3)
                    .map(
                      (item) => _AnalyticsRankedItem(
                        title: item['title']?.toString() ?? 'Untitled',
                        value: _formatCompact(_asInt(item['views'])),
                      ),
                    )
                    .toList()
                : <_AnalyticsRankedItem>[]);

    final audience =
        ((analytics['readerStats'] as List? ?? const [])
            .map(
              (item) => _AnalyticsAudienceItem(
                label: item['label']?.toString() ?? '',
                percent: (item['pct'] as num?)?.toDouble() ?? 0,
              ),
            )
            .where((item) => item.label.isNotEmpty)
            .toList());

    return _AnalyticsViewData(
      metrics: [
        _AnalyticsMetric(
          label: 'VIEWS',
          value: _formatNumber(resolvedViews),
          delta: '+12%',
        ),
        _AnalyticsMetric(
          label: 'LIKES',
          value: _formatNumber(resolvedLikes),
          delta: '+8%',
        ),
        _AnalyticsMetric(
          label: 'COMMENTS',
          value: _formatNumber(resolvedComments),
          delta: '+5%',
        ),
        _AnalyticsMetric(
          label: 'FOLLOWERS',
          value: _formatNumber(resolvedFollowers),
          delta: '+3%',
        ),
      ],
      chartValue: _formatCompact(resolvedViews),
      topItems: liveTopItems,
      audience: audience,
    );
  }

  int _sumPosts(List<Post> posts, int Function(Post post) selector) {
    return posts.fold<int>(0, (sum, post) => sum + selector(post));
  }

  int _sumDynamicList(List<dynamic> items, String key) {
    return items.fold<int>(0, (sum, item) => sum + _asInt(item[key]));
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reversedIndex = text.length - i;
      buffer.write(text[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

class _AnalyticsViewData {
  const _AnalyticsViewData({
    required this.metrics,
    required this.chartValue,
    required this.topItems,
    required this.audience,
  });

  final List<_AnalyticsMetric> metrics;
  final String chartValue;
  final List<_AnalyticsRankedItem> topItems;
  final List<_AnalyticsAudienceItem> audience;
}

class _AnalyticsSourceData {
  const _AnalyticsSourceData({
    required this.analytics,
    required this.currentUser,
    required this.posts,
  });

  final Map<String, dynamic> analytics;
  final User? currentUser;
  final List<Post> posts;
}

class _AnalyticsMetric {
  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final String delta;
}

class _AnalyticsRankedItem {
  const _AnalyticsRankedItem({required this.title, required this.value});

  final String title;
  final String value;
}

class _AnalyticsAudienceItem {
  const _AnalyticsAudienceItem({required this.label, required this.percent});

  final String label;
  final double percent;
}
