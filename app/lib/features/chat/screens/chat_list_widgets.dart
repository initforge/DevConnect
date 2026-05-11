part of 'chat_list_screen.dart';

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
