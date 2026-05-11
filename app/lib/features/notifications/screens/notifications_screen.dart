import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
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
  int _selectedTab = 0;
  String? _teamInviteState;

  @override
  void initState() {
    super.initState();
    _loader = _repository.getNotifications();
    _teamInviteState = AppPreferences.instance.teamInviteState;
  }

  Future<void> _reload() async {
    setState(() {
      _loader = _repository.getNotifications();
    });
  }

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
    if (!mounted) return;
    await _reload();
  }

  Future<void> _markSingleRead(AppNotification item) async {
    if (item.isRead) return;
    await _repository.markAsRead(item.id);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _handleInvite(String decision) async {
    await AppPreferences.instance.setTeamInviteState(decision);
    if (!mounted) return;

    setState(() => _teamInviteState = decision);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == 'accepted'
              ? 'You joined Team Flutter.'
              : 'Team Flutter invite declined.',
        ),
      ),
    );

    if (decision == 'accepted') {
      context.go(AppRoutes.projects);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            body: Center(
              child: ErrorState(
                message: 'Unable to load notifications right now.',
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
            title: const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.tune, size: 20),
              ),
            ],
          ),
          body: items.isEmpty
              ? const EmptyNotifications()
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      children: [
                        _FilterTabs(
                          selected: _selectedTab,
                          onSelected:
                              (value) => setState(() => _selectedTab = value),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _markAllRead,
                            child: const Text(
                              'Mark all as read',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ...today.map(
                        (item) => _NotificationTile(
                          item: item,
                          onTap: () => _handleTap(item),
                        ),
                      ),
                      if (earlier.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Earlier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...earlier.map(
                          (item) => _NotificationTile(
                            item: item,
                            onTap: () => _handleTap(item),
                          ),
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
                              const Text(
                                "You've been invited to join the Team Flutter organization.",
                                style: TextStyle(
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
                                    child: const Text(
                                      'Accept',
                                      style: TextStyle(fontSize: 11),
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
                                    child: const Text(
                                      'Decline',
                                      style: TextStyle(fontSize: 11),
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
                ),
              ),
        );
      },
    );
  }

  List<AppNotification> _filter(List<AppNotification> items) {
    switch (_selectedTab) {
      case 1:
        return items.where((e) => e.type == 'MENTION').toList();
      case 2:
        return items.where((e) => e.type == 'FOLLOW').toList();
      default:
        return items;
    }
  }

  Future<void> _handleTap(AppNotification item) async {
    HapticFeedback.lightImpact();
    await _markSingleRead(item);
    if (!mounted) return;
    if (item.fromUser != null) {
      context.push('${AppRoutes.userBase}/${item.fromUser!.id}');
    }
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['All', 'Mentions', 'Follows'];
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
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
