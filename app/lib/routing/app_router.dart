import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/feed/screens/home_screen.dart';
import '../features/feed/screens/post_detail_screen.dart';
import '../features/feed/screens/create_post_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/explore/screens/search_results_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/projects/screens/project_marketplace_screen.dart';
import '../features/projects/screens/job_board_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/debug/screens/screenshot_lab_screen.dart';
import '../features/playground/screens/playground_screen.dart';
import '../features/playground/screens/live_code_screen.dart';
import '../features/mentorship/screens/mentorship_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../core/constants/routes.dart';
import '../core/config/app_runtime_config.dart';
import '../core/riverpod/providers.dart';
import '../core/state/feed_refresh_bus.dart';
import '../core/theme/app_colors.dart';
import '../core/services/app_preferences.dart';
import '../core/widgets/shared_widgets.dart';

const bool kScreenshotMode = AppRuntimeConfig.screenshotMode;

final appRouter = GoRouter(
  initialLocation: kScreenshotMode ? AppRoutes.shotLab : AppRoutes.login,
  redirect: (context, state) {
    if (kScreenshotMode) {
      return null;
    }
    // AppPreferences may not be initialized yet during early redirects
    String? token;
    bool onboardingCompleted = false;
    try {
      token = AppPreferences.instance.token;
      onboardingCompleted = AppPreferences.instance.onboardingCompleted;
    } catch (_) {
      // Preferences not initialized yet, skip redirect
      return null;
    }
    final isLoggedIn = token != null;
    final isAuthRoute =
        state.uri.toString() == AppRoutes.login ||
        state.uri.toString() == AppRoutes.register ||
        state.uri.toString() == AppRoutes.onboarding;

    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }
    if (isLoggedIn &&
        (state.uri.toString() == AppRoutes.login ||
            state.uri.toString() == AppRoutes.register)) {
      // If logged in but onboarding not completed, go to onboarding
      if (!onboardingCompleted) return AppRoutes.onboarding;
      return AppRoutes.home;
    }
    // If logged in and going to home, check onboarding status
    if (isLoggedIn &&
        state.uri.toString() == AppRoutes.home &&
        !onboardingCompleted) {
      return AppRoutes.onboarding;
    }
    return null;
  },
  routes: [
    if (kScreenshotMode)
      GoRoute(
        path: '/shot-lab',
        name: AppRoutes.nameShotLab,
        builder: (_, __) => const ScreenshotLabScreen(),
      ),
    // Auth
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.nameLogin,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: AppRoutes.nameRegister,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRoutes.nameOnboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),

    // Main app — Bottom navigation shell
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.nameHome,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.explore,
          name: AppRoutes.nameExplore,
          builder: (_, __) => const ExploreScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          name: AppRoutes.nameChatList,
          builder: (_, __) => const ChatListScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: AppRoutes.nameNotifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.nameProfile,
          builder:
              (_, __) =>
                  kScreenshotMode
                      ? const ProfileScreen(userId: 'u1')
                      : const ProfileScreen(),
        ),
      ],
    ),

    // Detail screens
    GoRoute(
      path: AppRoutes.postDetail,
      name: AppRoutes.namePostDetail,
      builder:
          (_, state) => PostDetailScreen(postId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.createPost,
      name: AppRoutes.nameCreatePost,
      builder: (_, __) => const CreatePostScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatDetail,
      name: AppRoutes.nameChatScreen,
      builder:
          (_, state) => ChatScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.userProfile,
      name: AppRoutes.nameUserProfile,
      builder: (_, state) => ProfileScreen(userId: state.pathParameters['id']),
    ),
    GoRoute(
      path: AppRoutes.search,
      name: AppRoutes.nameSearch,
      builder:
          (_, state) => SearchResultsScreen(
            initialQuery: state.uri.queryParameters['q'] ?? '',
          ),
    ),

    // Features
    GoRoute(
      path: AppRoutes.projects,
      name: AppRoutes.nameProjects,
      builder: (_, __) => const ProjectMarketplaceScreen(),
    ),
    GoRoute(
      path: AppRoutes.jobs,
      name: AppRoutes.nameJobs,
      builder: (_, __) => const JobBoardScreen(),
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      name: AppRoutes.nameLeaderboard,
      builder: (_, __) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.analytics,
      name: AppRoutes.nameAnalytics,
      builder: (_, __) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.playground,
      name: AppRoutes.namePlayground,
      builder: (_, __) => const PlaygroundScreen(),
    ),
    GoRoute(
      path: AppRoutes.liveCode,
      name: AppRoutes.nameLiveCode,
      builder: (_, __) => const LiveCodeScreen(),
    ),
    GoRoute(
      path: AppRoutes.mentorship,
      name: AppRoutes.nameMentorship,
      builder: (_, __) => const MentorshipScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.nameSettings,
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);

/// Bottom Navigation Shell — hiện ở tất cả main tabs
class _MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _unreadChats = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCounts();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      final notificationRepository = ref.read(notificationRepositoryProvider);
      final conversations = await chatRepository.getConversations();
      final notifications = await notificationRepository.getNotifications();
      if (mounted) {
        setState(() {
          _unreadChats = conversations.fold<int>(
            0,
            (sum, c) => sum + c.unreadCount,
          );
          _unreadNotifications = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (_) {
      // Silently handle errors for badge counts
    }
  }

  void refreshBadges() {
    _loadUnreadCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton:
          kScreenshotMode
              ? null
              : FloatingActionButton(
                onPressed: () async {
                  final created = await context.push<bool>('/create-post');
                  if (created == true) {
                    FeedRefreshBus.instance.refresh();
                  }
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.edit),
              ),
      floatingActionButtonLocation:
          kScreenshotMode ? null : FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        items: const [
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
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble,
            label: 'Chat',
            route: AppRoutes.chat,
          ),
          AppBottomNavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications,
            label: 'Notifications',
            route: AppRoutes.notifications,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: _calcIndex(GoRouterState.of(context).uri.toString()),
        currentRoute: GoRouterState.of(context).uri.toString(),
        badgeCounts: {2: _unreadChats, 3: _unreadNotifications},
      ),
    );
  }

  int _calcIndex(String path) {
    if (path.startsWith(AppRoutes.explore)) return 1;
    if (path.startsWith(AppRoutes.chat)) return 2;
    if (path.startsWith(AppRoutes.notifications)) return 3;
    if (path.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }
}
