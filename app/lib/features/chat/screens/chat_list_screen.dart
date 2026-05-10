import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';

const bool _kScreenshotMode = AppRuntimeConfig.screenshotMode;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _repository = ChatRepository();
  final _userRepository = UserRepository();

  Future<bool> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete conversation?'),
          content: Text(
            'This removes your thread with ${conversation.otherUser.displayName} from the inbox.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    try {
      await _repository.deleteConversation(conversation.id);
      if (!mounted) return false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted chat with ${conversation.otherUser.displayName}',
          ),
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
  }

  Future<void> _showNewChatDialog() async {
    HapticFeedback.lightImpact();
    final users = await _userRepository.getAllUsers();
    if (!mounted) return;

    final selectedUser = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Choose a contact',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...users.map(
                (user) => ListTile(
                  leading: UserAvatar(
                    name: user.displayName,
                    size: 42,
                    isOnline: user.isOnline,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.username}'),
                  onTap: () => Navigator.of(ctx).pop(user),
                ),
              ),
            ],
          ),
    );

    if (selectedUser == null) return;
    final conversations = await _repository.getConversations();
    if (!mounted) return;
    final existing = conversations.where(
      (c) => c.otherUser.id == selectedUser.id,
    );
    if (existing.isNotEmpty) {
      context.push('${AppRoutes.chatBase}/${existing.first.id}');
      return;
    }
    context.push(
      '${AppRoutes.chat}/conv_${selectedUser.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kScreenshotMode) {
      return const _ShowcaseChatListScreen();
    }

    return FutureBuilder(
      future: Future.wait([
        _repository.getOnlineUsers(),
        _repository.getConversations(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onlineUsers = snapshot.data?[0] as List<User>? ?? const [];
        final conversations =
            snapshot.data?[1] as List<Conversation>? ?? const [];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            titleSpacing: 16,
            title: const Text(
              'Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: _showNewChatDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_square,
                      size: 18,
                      color: Color(0xFF5B53F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 14),
                      Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Search conversations...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ONLINE NOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: onlineUsers.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return const _NewChatAvatar();
                    }
                    final user = onlineUsers[index - 1];
                    return GestureDetector(
                      onTap:
                          () =>
                              context.push('${AppRoutes.userBase}/${user.id}'),
                      child: _OnlineAvatar(user: user),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final conversation = conversations[index];
                    return Dismissible(
                      key: Key(conversation.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _deleteConversation(conversation),
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _ConversationRow(conversation: conversation),
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
}

class _ShowcaseChatListScreen extends StatelessWidget {
  const _ShowcaseChatListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_square,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                    SizedBox(width: 8),
                    Text(
                      'Search conversations...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ONLINE NOW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _ShowcaseStoryAvatar(label: 'New', add: true),
                  SizedBox(width: 12),
                  _ShowcaseStoryAvatar(label: 'Alex', active: true),
                  SizedBox(width: 12),
                  _ShowcaseStoryAvatar(label: 'Sarah', active: true),
                  SizedBox(width: 12),
                  _ShowcaseStoryAvatar(label: 'Mike', active: true),
                  SizedBox(width: 12),
                  _ShowcaseStoryAvatar(label: 'Jane', active: true),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: const [
                  _ShowcaseConversationRow(
                    name: 'Alex Kim',
                    message: 'Just pushed the PR for the new UI...',
                    time: '14:20',
                    unread: true,
                  ),
                  _ShowcaseConversationRow(
                    name: 'Team Flutter',
                    message: 'David: The build is failing on iOS again',
                    time: '',
                    danger: true,
                  ),
                  _ShowcaseConversationRow(
                    name: 'Sarah Chen',
                    message: 'Thanks for the feedback on the API docs.',
                    time: 'Yesterday',
                  ),
                  _ShowcaseConversationRow(
                    name: 'Dev Community',
                    message: 'Jordan: Who\'s going to the meetup tonight?',
                    time: 'Yesterday',
                  ),
                  _ShowcaseConversationRow(
                    name: 'John Doe',
                    message: 'Sent a file: deployment_checklist.pdf',
                    time: 'Monday',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseStoryAvatar extends StatelessWidget {
  const _ShowcaseStoryAvatar({
    required this.label,
    this.add = false,
    this.active = false,
  });

  final String label;
  final bool add;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: add ? Colors.white : const Color(0xFFF4EEDF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: add ? const Color(0xFFD8DDEE) : AppColors.primary,
                ),
              ),
              alignment: Alignment.center,
              child:
                  add
                      ? const Icon(Icons.add, color: AppColors.textSecondary)
                      : Text(
                        label.characters.first,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
            ),
            if (active)
              const Positioned(
                right: 1,
                bottom: 1,
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ShowcaseConversationRow extends StatelessWidget {
  const _ShowcaseConversationRow({
    required this.name,
    required this.message,
    required this.time,
    this.unread = false,
    this.danger = false,
  });

  final String name;
  final String message;
  final String time;
  final bool unread;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEDF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              unread
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (danger)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    else if (unread)
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewChatAvatar extends StatelessWidget {
  const _NewChatAvatar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD8DDEE)),
          ),
          child: const Icon(Icons.add, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text('New', style: TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _OnlineAvatar extends StatelessWidget {
  const _OnlineAvatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(name: user.displayName, size: 48, isOnline: true),
        const SizedBox(height: 6),
        Text(
          user.displayName.split(' ').first,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('${AppRoutes.chatBase}/${conversation.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              name: conversation.otherUser.displayName,
              size: 48,
              isOnline: conversation.otherUser.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUser.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                conversation.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(conversation.updatedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color:
                                conversation.unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (conversation.unreadCount > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B53F6),
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 5) return 'Now';
  if (diff.inHours < 24) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  if (diff.inDays == 1) return 'Yesterday';
  return 'Monday';
}
