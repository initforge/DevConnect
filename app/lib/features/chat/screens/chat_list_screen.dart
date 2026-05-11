import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';

part 'chat_list_widgets.dart';

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
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getContentMaxWidth(context),
              ),
              child: Column(
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
                    height: ResponsiveUtils.isDesktop(context) ? 96 : 82,
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
            ),
          ),
        );
      },
    );
  }
}
