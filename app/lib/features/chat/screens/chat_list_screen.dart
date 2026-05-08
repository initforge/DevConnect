import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _repository = ChatRepository();
  final _userRepository = UserRepository();

  Future<void> _showNewChatDialog() async {
    HapticFeedback.lightImpact();
    final users = await _userRepository.getAllUsers();
    if (!mounted) return;

    final selectedUser = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn người nhắn tin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('Không có người dùng nào'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: users.length,
                      itemBuilder: (_, index) {
                        final user = users[index];
                        return ListTile(
                          leading: UserAvatar(
                            name: user.displayName,
                            size: 44,
                            isOnline: user.isOnline,
                          ),
                          title: Text(user.displayName),
                          subtitle: Text('@${user.username}'),
                          trailing: user.isOnline
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.of(ctx).pop(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (selectedUser != null) {
      final conversations = await _repository.getConversations();
      if (!mounted) return;
      final existing = conversations.where((c) => c.otherUser.id == selectedUser.id).toList();
      if (existing.isNotEmpty) {
        context.push('/chat/${existing.first.id}');
      } else {
        final convId = 'conv_${selectedUser.id}_${DateTime.now().millisecondsSinceEpoch}';
        context.push('/chat/$convId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _repository.getOnlineUsers(),
        _repository.getConversations(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final onlineUsers = snapshot.data?[0] as List? ?? const [];
        final conversations = snapshot.data?[1] as List? ?? const [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tin nhắn'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_square),
                onPressed: () => _showNewChatDialog(),
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: onlineUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, index) {
                    final user = onlineUsers[index];
                    return GestureDetector(
                      onTap: () => context.push('/user/${user.id}'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(name: user.displayName, size: 48, isOnline: true),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 52,
                            child: Text(
                              user.displayName.split(' ').last,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (_, index) {
                    final conversation = conversations[index];
                    return Dismissible(
                      key: Key(conversation.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Xóa hội thoại sẽ làm ở phase sau')),
                        );
                        return false;
                      },
                      background: Container(
                        color: AppColors.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: UserAvatar(
                          name: conversation.otherUser.displayName,
                          size: 48,
                          isOnline: conversation.otherUser.isOnline,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.otherUser.displayName,
                                style: TextStyle(
                                  fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _timeAgo(conversation.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: conversation.unreadCount > 0 ? AppColors.primary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: conversation.unreadCount > 0 ? AppColors.textPrimary : AppColors.textTertiary,
                                ),
                              ),
                            ),
                            if (conversation.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () async {
                          await context.push('/chat/${conversation.id}');
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
