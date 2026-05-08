import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<List<AppNotification>> _load() => _repository.getNotifications();

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
    if (!mounted) return;
    setState(() {
      _loader = _load();
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    if (!mounted) return;
    setState(() {
      _loader = _load();
    });
  }

  void _handleNotificationTap(AppNotification item) {
    HapticFeedback.lightImpact();
    _markAsRead(item.id);
    switch (item.type) {
      case 'LIKE':
      case 'COMMENT':
      case 'MENTION':
      case 'BEST_ANSWER':
        if (item.fromUser != null) {
          context.push('/user/${item.fromUser!.id}');
        }
        break;
      case 'FOLLOW':
        if (item.fromUser != null) {
          context.push('/user/${item.fromUser!.id}');
        }
        break;
      default:
        break;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'LIKE':
        return Icons.favorite;
      case 'COMMENT':
        return Icons.chat_bubble;
      case 'FOLLOW':
        return Icons.person_add;
      case 'MENTION':
        return Icons.alternate_email;
      case 'BEST_ANSWER':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'LIKE':
        return AppColors.error;
      case 'COMMENT':
        return AppColors.primary;
      case 'FOLLOW':
        return AppColors.aiPurple;
      case 'MENTION':
        return AppColors.accent;
      case 'BEST_ANSWER':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final items = snapshot.data ?? const <AppNotification>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông báo'),
            actions: [
              TextButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        await _markAllRead();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đánh dấu đã đọc cho tất cả thông báo')),
                        );
                      },
                child: const Text('Đọc hết', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          body: items.isEmpty
              ? const EmptyNotifications()
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Container(
                      color: item.isRead ? null : AppColors.primary.withValues(alpha: 0.03),
                      child: ListTile(
                        onTap: () => _handleNotificationTap(item),
                        leading: Stack(
                          children: [
                            if (item.fromUser != null)
                              UserAvatar(name: item.fromUser!.displayName, size: 44)
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(_icon(item.type), color: _color(item.type)),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _color(item.type),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(_icon(item.type), size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          item.body,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                          maxLines: 2,
                        ),
                        subtitle: Text(
                          _timeAgo(item.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                        trailing: item.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
