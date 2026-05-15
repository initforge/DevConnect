import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/riverpod/providers.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../application/feed_notifier.dart';
import '../application/feed_state.dart';
import '../widgets/feed_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<String> _tabLabels = const [];
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
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

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _refresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await Future.wait([
      ref.read(feedNotifierProvider(FeedType.forYou).notifier).refresh(),
      ref.read(feedNotifierProvider(FeedType.following).notifier).refresh(),
      ref.read(feedNotifierProvider(FeedType.trending).notifier).refresh(),
    ]);
  }

  bool get _showVerificationBanner {
    if (_bannerDismissed) return false;
    final user = AppPreferences.instance.user;
    if (user == null) return false;
    final emailVerified = user['emailVerified'];
    return emailVerified == false;
  }

  Widget _buildVerificationBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF856404)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please verify your email.',
              style: TextStyle(fontSize: 13, color: Color(0xFF856404)),
            ),
          ),
          TextButton(
            onPressed: _resendVerification,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Resend',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF856404),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _bannerDismissed = true),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF856404)),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerification() async {
    try {
      await ApiService.instance.post('/auth/send-verification', {});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send verification email.')),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(unreadNotificationCountProvider);
                    final unread = count.valueOrNull ?? 0;
                    if (unread <= 0) return const SizedBox.shrink();
                    return Positioned(
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
                    );
                  },
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
        child: Column(
          children: [
            if (_showVerificationBanner) _buildVerificationBanner(),
            Expanded(
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
                        feedType: FeedType.forYou,
                        highlightAi: true,
                        onRefresh: _refresh,
                      ),
                      FeedList(
                        key: const PageStorageKey('following'),
                        feedType: FeedType.following,
                        onRefresh: _refresh,
                      ),
                      FeedList(
                        key: const PageStorageKey('trending'),
                        feedType: FeedType.trending,
                        onRefresh: _refresh,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
