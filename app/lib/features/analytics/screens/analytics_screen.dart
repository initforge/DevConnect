import 'package:flutter/material.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';

part 'analytics_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _loader;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loader = _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    return await ApiService.instance.getObject('/analytics/me');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: strings.nav('home'), route: AppRoutes.home),
          AppBottomNavItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: strings.nav('explore'), route: AppRoutes.explore),
          AppBottomNavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: strings.nav('analytics'), route: AppRoutes.analytics),
          AppBottomNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: strings.nav('profile'), route: AppRoutes.profile),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.analytics,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: Text(strings.t('analytics.title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(icon: const Icon(Icons.auto_awesome, size: 16), text: strings.t('analytics.recommendation')),
            Tab(icon: const Icon(Icons.speed, size: 16), text: strings.t('analytics.cache')),
            Tab(icon: const Icon(Icons.queue, size: 16), text: strings.t('analytics.queues')),
            Tab(icon: const Icon(Icons.trending_up, size: 16), text: strings.t('analytics.engagement')),
          ],
        ),
      ),
      body: DecorativeBackground(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
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
                      const Icon(Icons.error_outline, size: 44, color: AppColors.textTertiary),
                      const SizedBox(height: 14),
                      Text(strings.t('analytics.unableLoad'), style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => setState(() => _loader = _loadAnalytics()),
                        child: Text(strings.t('analytics.tryAgain')),
                      ),
                    ],
                  ),
                );
              }
              return _buildTabs(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(Map<String, dynamic> data) {
    final strings = AppStrings.of(context);
    final rec = data['recommendation'] as Map<String, dynamic>? ?? {};
    final redis = data['redis'] as Map<String, dynamic>? ?? {};
    final bullmq = data['bullmq'] as Map<String, dynamic>? ?? {};
    final engagement = data['userEngagement'] as Map<String, dynamic>? ?? {};

    final cacheBreakdown = redis['cacheBreakdown'] as Map<String, dynamic>? ?? {};
    final queues = (bullmq['queues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final topPosts = (engagement['topPosts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final topTags = (rec['topTags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final interactions = rec['interactions'] as Map<String, dynamic>? ?? {};

    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Recommendation
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
          children: [
            _SectionCard(
              title: strings.t('analytics.recEngine'),
              icon: Icons.auto_awesome,
              children: [
                Row(
                  children: [
                    _StatusBadge(label: rec['method']?.toString() ?? 'Unknown', active: rec['svdActive'] == true),
                    const Spacer(),
                    Text(
                      'SVD: ${_asInt(rec['svdFactors']?['users'])} users / ${_asInt(rec['svdFactors']?['posts'])} posts',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'LIKES', value: '${_asInt(interactions['likes'])}')),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'BOOKMARKS', value: '${_asInt(interactions['bookmarks'])}')),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'COMMENTS', value: '${_asInt(interactions['comments'])}')),
                  ],
                ),
                if (topTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(strings.t('analytics.topInterestTags'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: topTags.map((t) => _TagChip(tag: t['tag']?.toString() ?? '', count: _asInt(t['count']))).toList(),
                  ),
                ],
              ],
            ),
            _ExplainCard(
              title: strings.t('analytics.howItWorks'),
              text: strings.t('analytics.recExplain'),
              icon: Icons.lightbulb_outline,
            ),
          ],
        ),
        // Tab 2: Cache
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
          children: [
            _SectionCard(
              title: strings.t('analytics.redisPerf'),
              icon: Icons.speed,
              children: [
                Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'HIT RATE', value: '${_asInt(redis['hitRate'])}%', color: AppColors.success)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'MEMORY', value: '${redis['memoryUsedMB'] ?? 0} MB')),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'CLIENTS', value: '${_asInt(redis['connectedClients'])}')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(strings.t('analytics.cacheBreakdown'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _CacheBar(label: 'Feed Cache', count: _asInt(cacheBreakdown['feed']), total: _asInt(cacheBreakdown['total'])),
                _CacheBar(label: 'Leaderboard', count: _asInt(cacheBreakdown['leaderboard']), total: _asInt(cacheBreakdown['total'])),
                _CacheBar(label: 'SVD Factors', count: _asInt(cacheBreakdown['svd']), total: _asInt(cacheBreakdown['total'])),
                _CacheBar(label: 'AI Cache', count: _asInt(cacheBreakdown['aiCache']), total: _asInt(cacheBreakdown['total'])),
                _CacheBar(label: 'Rate Limits', count: _asInt(cacheBreakdown['rateLimit']), total: _asInt(cacheBreakdown['total'])),
              ],
            ),
            _ExplainCard(
              title: strings.t('analytics.howItWorks'),
              text: strings.t('analytics.cacheExplain'),
              icon: Icons.lightbulb_outline,
            ),
          ],
        ),
        // Tab 3: Queues
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
          children: [
            _SectionCard(
              title: strings.t('analytics.bullmqProc'),
              icon: Icons.queue,
              children: [
                Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'COMPLETED', value: '${_asInt(bullmq['totalCompleted'])}', color: AppColors.success)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'FAILED', value: '${_asInt(bullmq['totalFailed'])}', color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 10),
                ...queues.map((q) => _QueueRow(
                  name: q['name']?.toString() ?? '',
                  completed: _asInt(q['completed']),
                  failed: _asInt(q['failed']),
                  waiting: _asInt(q['waiting']),
                )),
              ],
            ),
            _ExplainCard(
              title: strings.t('analytics.howItWorks'),
              text: strings.t('analytics.queueExplain'),
              icon: Icons.lightbulb_outline,
            ),
          ],
        ),
        // Tab 4: Engagement
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
          children: [
            _SectionCard(
              title: strings.t('analytics.engagement'),
              icon: Icons.trending_up,
              children: [
                Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'VIEWS', value: '${_asInt(engagement['totalViews'])}')),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'LIKES', value: '${_asInt(engagement['totalLikes'])}')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'COMMENTS', value: '${_asInt(engagement['totalComments'])}')),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricTile(label: 'FOLLOWERS', value: '${_asInt(engagement['followers'])}')),
                  ],
                ),
                if (topPosts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(strings.t('analytics.topPosts'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...topPosts.asMap().entries.map((e) => _TopPostRow(
                    rank: e.key + 1,
                    title: e.value['title']?.toString() ?? '',
                    views: _asInt(e.value['views']),
                    likes: _asInt(e.value['likes']),
                  )),
                ],
              ],
            ),
            _ExplainCard(
              title: strings.t('analytics.howItWorks'),
              text: strings.t('analytics.engageExplain'),
              icon: Icons.lightbulb_outline,
            ),
          ],
        ),
      ],
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
