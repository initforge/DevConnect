import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/riverpod/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationRepository();
  late Future<List<AppNotification>> _loader;
  List<AppNotification> _items = [];
  int _selectedTab = 0;
  String? _teamInviteState;

  @override
  void initState() {
    super.initState();
    _loader = _repository.getNotifications().then((items) {
      _items = items;
      return items;
    });
    _teamInviteState = AppPreferences.instance.teamInviteState;
  }

  Future<void> _reload() async {
    setState(() {
      _loader = _repository.getNotifications().then((items) {
        _items = items;
        return items;
      });
    });
    await _loader;
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _reload();
  }

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
    // Invalidate badge provider so home_screen bell updates
    ProviderScope.containerOf(
      context,
    ).invalidate(unreadNotificationCountProvider);
    if (!mounted) return;
    setState(() {
      _items =
          _items
              .map(
                (item) => AppNotification(
                  id: item.id,
                  type: item.type,
                  title: item.title,
                  body: item.body,
                  fromUser: item.fromUser,
                  isRead: true,
                  createdAt: item.createdAt,
                  mergedCount: item.mergedCount,
                ),
              )
              .toList();
      _loader = Future.value(_items);
    });
  }

  Future<void> _markSingleRead(AppNotification item) async {
    if (item.isRead) return;
    await _repository.markAsRead(item.id);
    if (!mounted) return;
    setState(() {
      _items =
          _items.map((notification) {
            if (notification.id != item.id) return notification;
            return AppNotification(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              body: notification.body,
              fromUser: notification.fromUser,
              isRead: true,
              createdAt: notification.createdAt,
              mergedCount: notification.mergedCount,
            );
          }).toList();
      _loader = Future.value(_items);
    });
  }

  Future<void> _handleInvite(String decision) async {
    await AppPreferences.instance.setTeamInviteState(decision);
    // Persist to backend so it doesn't reappear across devices
    try {
      await ApiService.instance.post('/notifications/team-invite', {
        'decision': decision,
      });
    } catch (_) {}
    if (!mounted) return;

    setState(() => _teamInviteState = decision);
    final strings = AppStrings.current();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == 'accepted'
              ? strings.t('notifications.accepted')
              : strings.t('notifications.declined'),
        ),
      ),
    );

    if (decision == 'accepted') {
      context.go(AppRoutes.projects);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<AppNotification>>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: _NotificationsSkeleton());
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                strings.t('notifications.title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Center(
              child: ErrorState(
                message: strings.t('notifications.unableLoad'),
                onRetry: _reload,
              ),
            ),
          );
        }

        final items = snapshot.data ?? const <AppNotification>[];
        final filtered = _filter(items);
        final today = filtered.take(4).toList();
        final earlier = filtered.skip(4).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Text(
              strings.t('notifications.title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            actions: const [],
          ),
          body: DecorativeBackground(
            child:
                items.isEmpty
                    ? const EmptyNotifications()
                    : Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                        ),
                        child: _buildNotificationsContent(
                          context,
                          items,
                          today,
                          earlier,
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsContent(
    BuildContext context,
    List<AppNotification> items,
    List<AppNotification> today,
    List<AppNotification> earlier,
  ) {
    final strings = AppStrings.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        children: [
          ScreenGradientHeader(
            title: strings.t('notifications.title'),
            subtitle: strings.t('notifications.subtitle'),
            icon: Icons.notifications_active_outlined,
            gradientColors: const [Color(0xFF5B53F6), Color(0xFF00D9A6)],
          ),
          const SizedBox(height: 14),
          _FilterTabs(
            selected: _selectedTab,
            onSelected: (value) => setState(() => _selectedTab = value),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _markAllRead,
              child: Text(
                AppStrings.of(context).t('notifications.markAllRead'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.of(context).t('notifications.today'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...today.map(
            (item) =>
                _NotificationTile(item: item, onTap: () => _handleTap(item)),
          ),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              AppStrings.of(context).t('notifications.earlier'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...earlier.map(
              (item) =>
                  _NotificationTile(item: item, onTap: () => _handleTap(item)),
            ),
          ],
          if (_teamInviteState == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.of(context).t('notifications.teamInvite'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleInvite('accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B53F6),
                          minimumSize: const Size(74, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppStrings.of(context).t('common.accept'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _handleInvite('declined'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(74, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppStrings.of(context).t('common.decline'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<AppNotification> _filter(List<AppNotification> items) {
    switch (_selectedTab) {
      case 1:
        return items.where((e) => e.type.toLowerCase() == 'mention').toList();
      case 2:
        return items.where((e) => e.type.toLowerCase() == 'follow').toList();
      default:
        return items;
    }
  }

  Future<void> _handleTap(AppNotification item) async {
    HapticFeedback.lightImpact();
    await _markSingleRead(item);
    if (!mounted) return;
    switch (item.type.toLowerCase()) {
      case 'follow':
        if (item.fromUser != null) {
          context.push('${AppRoutes.userBase}/${item.fromUser!.id}');
        }
        break;
      case 'like':
      case 'comment':
      case 'mention':
        if (item.targetPostId != null && item.targetPostId!.isNotEmpty) {
          context.push('${AppRoutes.postBase}/${item.targetPostId}');
        } else if (item.fromUser != null) {
          context.push('${AppRoutes.userBase}/${item.fromUser!.id}');
        } else {
          context.go(AppRoutes.home);
        }
        break;
      default:
        if (item.targetPostId != null && item.targetPostId!.isNotEmpty) {
          context.push('${AppRoutes.postBase}/${item.targetPostId}');
        } else if (item.fromUser != null) {
          context.push('${AppRoutes.userBase}/${item.fromUser!.id}');
        }
    }
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final labels = [
      strings.t('notifications.all'),
      strings.t('notifications.mentions'),
      strings.t('notifications.follows'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF5B53F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'LIKE' => Icons.favorite,
      'COMMENT' => Icons.chat_bubble,
      'FOLLOW' => Icons.person_add_alt_1,
      'MENTION' => Icons.alternate_email,
      _ => Icons.notifications_none,
    };
    final color = switch (item.type) {
      'LIKE' => const Color(0xFFFFEEF3),
      'COMMENT' => const Color(0xFFF1F2FF),
      'FOLLOW' => const Color(0xFFF5EEFF),
      'MENTION' => const Color(0xFFEFF6FF),
      _ => const Color(0xFFF4F6FA),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE7EAF2)),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF5B53F6)),
                ),
                if (item.mergedCount > 1)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.mergedCount > 99
                            ? '99+'
                            : '+${item.mergedCount - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.body,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(item.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final strings = AppStrings.current();
    if (diff.inHours < 1) {
      return strings.isVietnamese
          ? '${diff.inMinutes} phút trước'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return strings.isVietnamese
          ? '${diff.inHours} giờ trước'
          : '${diff.inHours}h ago';
    }
    return strings.isVietnamese
        ? '${diff.inDays} ngày trước'
        : '${diff.inDays}d ago';
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: 6,
      itemBuilder: (_, __) => const NotificationTileSkeleton(),
    );
  }
}
