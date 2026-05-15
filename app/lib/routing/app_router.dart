import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/oauth_callback_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
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
import '../features/projects/screens/project_detail_screen.dart';
import '../features/projects/screens/job_board_screen.dart';
import '../features/projects/screens/my_applications_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/debug/screens/screenshot_lab_screen.dart';
import '../features/playground/screens/playground_screen.dart';
import '../features/playground/screens/live_code_screen.dart';

import '../features/settings/screens/settings_screen.dart';
import '../features/more/screens/more_screen.dart';
import '../core/constants/routes.dart';
import '../core/config/app_runtime_config.dart';
import '../core/state/feed_refresh_bus.dart';
import '../core/services/app_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/responsive_scaffold.dart';

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
    final path = state.uri.path;
    final isLoggedIn = token != null;
    final isAuthRoute =
        path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.onboarding ||
        path == AppRoutes.oauthCallback;

    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }
    if (isLoggedIn && (path == AppRoutes.login || path == AppRoutes.register)) {
      // If logged in but onboarding not completed, go to onboarding
      if (!onboardingCompleted) return AppRoutes.onboarding;
      return AppRoutes.home;
    }
    // If logged in and going to home, check onboarding status
    if (isLoggedIn && path == AppRoutes.home && !onboardingCompleted) {
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
    GoRoute(
      path: AppRoutes.oauthCallback,
      name: AppRoutes.nameOauthCallback,
      builder: (_, __) => const OAuthCallbackScreen(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      name: AppRoutes.nameResetPassword,
      builder:
          (_, state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'] ?? '',
          ),
    ),

    // Main app — Navigation shell with responsive layout
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
          builder: (_, __) => const ProfileScreen(),
        ),
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
          path: AppRoutes.settings,
          name: AppRoutes.nameSettings,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.liveCode,
          name: AppRoutes.nameLiveCode,
          builder: (_, __) => const LiveCodeScreen(),
        ),
        GoRoute(
          path: AppRoutes.mentorship,
          name: AppRoutes.nameMentorship,
          builder: (_, __) => const _MentorshipPlaceholderScreen(),
        ),
        GoRoute(
          path: AppRoutes.more,
          name: AppRoutes.nameMore,
          builder: (_, __) => const MoreScreen(),
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
      path: AppRoutes.projectDetail,
      name: AppRoutes.nameProjectDetail,
      builder:
          (_, state) =>
              ProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.myApplications,
      name: AppRoutes.nameMyApplications,
      builder: (_, __) => const MyApplicationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      name: AppRoutes.nameSearch,
      builder:
          (_, state) => SearchResultsScreen(
            initialQuery: state.uri.queryParameters['q'] ?? '',
          ),
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.toString();
    final showFab =
        !kScreenshotMode &&
        (path == AppRoutes.home ||
            path == AppRoutes.explore ||
            path == AppRoutes.profile);
    return ResponsiveScaffold(
      body: widget.child,
      currentRoute: path,
      onDestinationSelected: (destination) => context.go(destination.route),
      onCreateSelected: () async {
        final created = await context.push<bool>('/create-post');
        if (created == true) {
          FeedRefreshBus.instance.refresh();
        }
      },
      floatingActionButton:
          showFab
              ? FloatingActionButton(
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
              )
              : null,
    );
  }
}

/// Placeholder screen for Mentorship feature (plan: feature-01-mentorship-paid-sessions.md)
class _MentorshipPlaceholderScreen extends StatelessWidget {
  const _MentorshipPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentorship')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Mentorship',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('Coming soon', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
