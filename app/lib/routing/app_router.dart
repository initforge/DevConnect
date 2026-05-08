import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/feed/screens/home_screen.dart';
import '../features/feed/screens/post_detail_screen.dart';
import '../features/feed/screens/create_post_screen.dart';
import '../features/explore/screens/explore_screen.dart';
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
import '../core/state/feed_refresh_bus.dart';
import '../core/theme/app_colors.dart';
import '../core/services/app_preferences.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/notification_repository.dart';

const bool kScreenshotMode = kDebugMode && bool.fromEnvironment('SCREENSHOT_MODE');

final appRouter = GoRouter(
  initialLocation: kScreenshotMode ? '/shot-lab' : '/login',
  redirect: (context, state) {
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
    final isAuthRoute = state.uri.toString() == '/login' || state.uri.toString() == '/register' || state.uri.toString() == '/onboarding';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && (state.uri.toString() == '/login' || state.uri.toString() == '/register')) {
      // If logged in but onboarding not completed, go to onboarding
      if (!onboardingCompleted) return '/onboarding';
      return '/home';
    }
    // If logged in and going to home, check onboarding status
    if (isLoggedIn && state.uri.toString() == '/home' && !onboardingCompleted) {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    if (kScreenshotMode)
      GoRoute(
        path: '/shot-lab',
        name: 'shotLab',
        builder: (_, __) => const ScreenshotLabScreen(),
      ),
    // Auth
    GoRoute(path: '/login', name: 'login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', name: 'register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, __) => const OnboardingScreen()),

    // Main app — Bottom navigation shell
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/explore', name: 'explore', builder: (_, __) => const ExploreScreen()),
        GoRoute(path: '/chat', name: 'chatList', builder: (_, __) => const ChatListScreen()),
        GoRoute(path: '/notifications', name: 'notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // Detail screens
    GoRoute(path: '/post/:id', name: 'postDetail',
      builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id']!)),
    GoRoute(path: '/create-post', name: 'createPost', builder: (_, __) => const CreatePostScreen()),
    GoRoute(path: '/chat/:id', name: 'chatScreen',
      builder: (_, state) => ChatScreen(conversationId: state.pathParameters['id']!)),
    GoRoute(path: '/user/:id', name: 'userProfile',
      builder: (_, state) => ProfileScreen(userId: state.pathParameters['id'])),

    // Features
    GoRoute(path: '/projects', name: 'projects', builder: (_, __) => const ProjectMarketplaceScreen()),
    GoRoute(path: '/jobs', name: 'jobs', builder: (_, __) => const JobBoardScreen()),
    GoRoute(path: '/leaderboard', name: 'leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(path: '/analytics', name: 'analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/playground', name: 'playground', builder: (_, __) => const PlaygroundScreen()),
    GoRoute(path: '/live-code', name: 'liveCode', builder: (_, __) => const LiveCodeScreen()),
    GoRoute(path: '/mentorship', name: 'mentorship', builder: (_, __) => const MentorshipScreen()),
    GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),
  ],
);

/// Bottom Navigation Shell — hiện ở tất cả main tabs
class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  final _chatRepository = ChatRepository();
  final _notificationRepository = NotificationRepository();
  
  int _unreadChats = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCounts();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final conversations = await _chatRepository.getConversations();
      final notifications = await _notificationRepository.getNotifications();
      if (mounted) {
        setState(() {
          _unreadChats = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
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
      floatingActionButton: FloatingActionButton(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calcIndex(GoRouterState.of(context).uri.toString()),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/explore');
            case 2: context.go('/chat');
            case 3: context.go('/notifications');
            case 4: context.go('/profile');
          }
        },
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: _buildBadge(_unreadChats, Icons.chat_bubble_outline),
            selectedIcon: _buildBadge(_unreadChats, Icons.chat_bubble, selected: true),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: _buildBadge(_unreadNotifications, Icons.notifications_outlined),
            selectedIcon: _buildBadge(_unreadNotifications, Icons.notifications, selected: true),
            label: 'Thông báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, IconData icon, {bool selected = false}) {
    if (count == 0) {
      return Icon(icon);
    }
    return Badge(
      label: Text(count > 99 ? '99+' : '$count', style: const TextStyle(fontSize: 10)),
      backgroundColor: count > 0 ? AppColors.error : AppColors.primary,
      child: Icon(icon),
    );
  }

  int _calcIndex(String path) {
    if (path.startsWith('/explore')) return 1;
    if (path.startsWith('/chat')) return 2;
    if (path.startsWith('/notifications')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }
}