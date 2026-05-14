import 'package:flutter/material.dart';

import '../constants/routes.dart';

enum FeatureDestinationGroup { primary, social, opportunities, tools, system }

enum FeatureDestinationStatus { stable, preview }

class FeatureDestination {
  const FeatureDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.group,
    this.status = FeatureDestinationStatus.stable,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final FeatureDestinationGroup group;
  final FeatureDestinationStatus status;

  bool matchesRoute(String path) {
    if (route == AppRoutes.home) return path.startsWith(AppRoutes.home);
    if (route == AppRoutes.explore) return path.startsWith(AppRoutes.explore);
    if (route == AppRoutes.chat) return path.startsWith(AppRoutes.chat);
    if (route == AppRoutes.more) return path.startsWith(AppRoutes.more);
    return path == route || path.startsWith('$route/');
  }
}

class FeatureDestinations {
  FeatureDestinations._();

  static const home = FeatureDestination(
    id: 'home',
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: AppRoutes.home,
    group: FeatureDestinationGroup.primary,
  );

  static const explore = FeatureDestination(
    id: 'explore',
    label: 'Explore',
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore,
    route: AppRoutes.explore,
    group: FeatureDestinationGroup.primary,
  );

  static const chat = FeatureDestination(
    id: 'chat',
    label: 'Chat',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    route: AppRoutes.chat,
    group: FeatureDestinationGroup.primary,
  );

  static const more = FeatureDestination(
    id: 'more',
    label: 'More',
    icon: Icons.apps_outlined,
    activeIcon: Icons.apps,
    route: AppRoutes.more,
    group: FeatureDestinationGroup.primary,
  );

  static const notifications = FeatureDestination(
    id: 'notifications',
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    route: AppRoutes.notifications,
    group: FeatureDestinationGroup.social,
  );

  static const profile = FeatureDestination(
    id: 'profile',
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    route: AppRoutes.profile,
    group: FeatureDestinationGroup.social,
  );

  static const projects = FeatureDestination(
    id: 'projects',
    label: 'Projects',
    icon: Icons.forum_outlined,
    activeIcon: Icons.forum,
    route: AppRoutes.projects,
    group: FeatureDestinationGroup.opportunities,
  );

  static const jobs = FeatureDestination(
    id: 'jobs',
    label: 'Jobs',
    icon: Icons.work_outline,
    activeIcon: Icons.work,
    route: AppRoutes.jobs,
    group: FeatureDestinationGroup.opportunities,
  );


  static const playground = FeatureDestination(
    id: 'playground',
    label: 'Playground',
    icon: Icons.code_outlined,
    activeIcon: Icons.code,
    route: AppRoutes.playground,
    group: FeatureDestinationGroup.tools,
  );

  static const analytics = FeatureDestination(
    id: 'analytics',
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics,
    route: AppRoutes.analytics,
    group: FeatureDestinationGroup.tools,
  );

  static const leaderboard = FeatureDestination(
    id: 'leaderboard',
    label: 'Leaderboard',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    route: AppRoutes.leaderboard,
    group: FeatureDestinationGroup.tools,
  );

  static const liveCode = FeatureDestination(
    id: 'live-code',
    label: 'Live Code Preview',
    icon: Icons.co_present_outlined,
    activeIcon: Icons.co_present,
    route: AppRoutes.liveCode,
    group: FeatureDestinationGroup.tools,
    status: FeatureDestinationStatus.preview,
  );

  static const settings = FeatureDestination(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    route: AppRoutes.settings,
    group: FeatureDestinationGroup.system,
  );

  static const mobile = <FeatureDestination>[
    home,
    explore,
    chat,
    more,
  ];

  static const sidebar = <FeatureDestination>[
    home,
    explore,
    chat,
    notifications,
    profile,
    projects,
    jobs,
    playground,
    analytics,
    leaderboard,
    liveCode,
    settings,
  ];

  static const moreItems = <FeatureDestination>[
    notifications,
    profile,
    projects,
    jobs,
    leaderboard,
    analytics,
    playground,
    liveCode,
    settings,
  ];

  static FeatureDestination? fromRoute(String path) {
    for (final item in sidebar) {
      if (item.matchesRoute(path)) return item;
    }
    if (path.startsWith(AppRoutes.more)) return more;
    return null;
  }

  static String groupLabel(FeatureDestinationGroup group) {
    switch (group) {
      case FeatureDestinationGroup.primary:
        return 'Primary';
      case FeatureDestinationGroup.social:
        return 'Social';
      case FeatureDestinationGroup.opportunities:
        return 'Opportunities';
      case FeatureDestinationGroup.tools:
        return 'Tools';
      case FeatureDestinationGroup.system:
        return 'System';
    }
  }
}
