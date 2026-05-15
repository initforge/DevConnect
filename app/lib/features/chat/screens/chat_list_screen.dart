import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
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

class _ChatListScreenState extends State<ChatListScreen>
    implements WebSocketServiceListener {
  final _repository = ChatRepository();
  final _userRepository = UserRepository();

  List<User> _onlineUsers = [];
  List<Conversation> _conversations = [];
  final Set<String> _mutedConversationIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.addListener(this);
    WebSocketService.instance.subscribe(WsChannel.presence);
    WebSocketService.instance.subscribe(WsChannel.messages);
    _loadData();
  }

  @override
  void dispose() {
    WebSocketService.instance.unsubscribe(WsChannel.messages);
    WebSocketService.instance.unsubscribe(WsChannel.presence);
    WebSocketService.instance.removeListener(this);
    super.dispose();
  }

  // --- WebSocketServiceListener ---

  @override
  void onWsConnected() {}

  @override
  void onWsDisconnected() {}

  @override
  void onWsMessage(WsMessage msg) {
    if (!mounted ||
        msg.channel != WsChannel.messages.name ||
        msg.data == null) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return;
    }

    final conversationId = msg.data!['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) return;

    final senderId = msg.data!['senderId']?.toString() ?? '';
    final currentUserId = AppPreferences.instance.userId;
    final content = msg.data!['content']?.toString() ?? '';
    final updatedAt =
        DateTime.tryParse(msg.data!['createdAt']?.toString() ?? '') ??
        DateTime.now();

    setState(() {
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index < 0) return;

      final current = _conversations[index];
      final nextUnread =
          senderId == currentUserId ? 0 : current.unreadCount + 1;
      final updated = Conversation(
        id: current.id,
        otherUser: current.otherUser,
        lastMessage: content.isNotEmpty ? content : current.lastMessage,
        unreadCount: nextUnread,
        updatedAt: updatedAt,
      );

      final next = [..._conversations];
      next.removeAt(index);
      next.insert(0, updated);
      _conversations = next;
    });
  }

  @override
  void onWsError(String error) {}

  @override
  void onWsPresenceUpdate(String userId, bool isOnline) {
    setState(() {
      final updatedOnlineUsers = [..._onlineUsers];
      final onlineIndex = updatedOnlineUsers.indexWhere((u) => u.id == userId);

      if (isOnline) {
        if (onlineIndex >= 0) {
          updatedOnlineUsers[onlineIndex] = updatedOnlineUsers[onlineIndex]
              .copyWith(isOnline: true);
        } else {
          final relatedConversation = _conversations.where(
            (c) => c.otherUser.id == userId,
          );
          if (relatedConversation.isNotEmpty) {
            updatedOnlineUsers.add(
              relatedConversation.first.otherUser.copyWith(isOnline: true),
            );
          }
        }
      } else {
        updatedOnlineUsers.removeWhere((u) => u.id == userId);
      }

      _onlineUsers = updatedOnlineUsers;

      _conversations =
          _conversations.map<Conversation>((c) {
            if (c.otherUser.id == userId) {
              return Conversation(
                id: c.id,
                otherUser: c.otherUser.copyWith(isOnline: isOnline),
                lastMessage: c.lastMessage,
                unreadCount: c.unreadCount,
                updatedAt: c.updatedAt,
              );
            }
            return c;
          }).toList();
    });
  }

  @override
  void onWsTyping(String userId, bool isTyping) {
    // Optional: Implement typing indicator in chat list
  }

  // --- Data loading ---

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repository.getOnlineUsers(),
        _repository.getConversations(),
      ]);
      if (!mounted) return;
      setState(() {
        _onlineUsers = results[0] as List<User>;
        _conversations = results[1] as List<Conversation>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _onlineUsers = const [];
        _conversations = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context).t('chat.unableLoadChats')}: $error',
          ),
        ),
      );
    }
  }

  void _markConversationReadLocally(String conversationId) {
    setState(() {
      _conversations =
          _conversations.map((conversation) {
            if (conversation.id != conversationId) return conversation;
            return Conversation(
              id: conversation.id,
              otherUser: conversation.otherUser,
              lastMessage: conversation.lastMessage,
              unreadCount: 0,
              updatedAt: conversation.updatedAt,
            );
          }).toList();
    });
  }

  Future<bool> _deleteConversation(Conversation conversation) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t('chat.deleteConversation')),
          content: Text(
            strings
                .t('chat.deleteConversationBody')
                .replaceAll('{name}', conversation.otherUser.displayName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.t('chat.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                strings.t('chat.delete'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    final displayName = conversation.otherUser.displayName;
    try {
      await _repository.deleteConversation(conversation.id);
      if (!mounted) return false;
      await _loadData();
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(
              context,
            ).t('chat.deletedChat').replaceAll('{name}', displayName),
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

  Future<bool> _muteConversation(Conversation conversation) async {
    setState(() {
      if (_mutedConversationIds.contains(conversation.id)) {
        _mutedConversationIds.remove(conversation.id);
      } else {
        _mutedConversationIds.add(conversation.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mutedConversationIds.contains(conversation.id)
              ? AppStrings.of(context)
                  .t('chat.muted')
                  .replaceAll('{name}', conversation.otherUser.displayName)
              : AppStrings.of(context)
                  .t('chat.unmuted')
                  .replaceAll('{name}', conversation.otherUser.displayName),
        ),
      ),
    );
    return false;
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
              Text(
                AppStrings.of(context).t('chat.chooseContact'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
      _markConversationReadLocally(existing.first.id);
      unawaited(_repository.markConversationRead(existing.first.id));
      context.push('${AppRoutes.chatBase}/${existing.first.id}');
      return;
    }
    // Create conversation via API
    try {
      final result = await ApiService.instance.post('/chat/conversations', {
        'otherUserId': selectedUser.id,
      });
      if (!mounted) return;
      final conversationId = result['id']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        context.push('${AppRoutes.chatBase}/$conversationId');
        await _loadData();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('chat.unableLoadChats')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_kScreenshotMode) {
      return const _ShowcaseChatListScreen();
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 16,
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
          AppStrings.of(context).t('chat.messages'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
      body: DecorativeBackground(
        child: Center(
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.of(context).t('chat.searchConversations'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.of(context).t('chat.onlineNow'),
                      style: const TextStyle(
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
                    itemCount: _onlineUsers.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return const _NewChatAvatar();
                      }
                      final user = _onlineUsers[index - 1];
                      return GestureDetector(
                        onTap:
                            () => context.push(
                              '${AppRoutes.userBase}/${user.id}',
                            ),
                        child: _OnlineAvatar(user: user),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final conversation = _conversations[index];
                      return Dismissible(
                        key: Key(conversation.id),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            return _muteConversation(conversation);
                          }
                          return _deleteConversation(conversation);
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B53F6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: Icon(
                            _mutedConversationIds.contains(conversation.id)
                                ? Icons.volume_up_outlined
                                : Icons.volume_off_outlined,
                            color: Colors.white,
                          ),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _ConversationRow(
                          conversation: conversation,
                          isMuted: _mutedConversationIds.contains(
                            conversation.id,
                          ),
                          onTap: () async {
                            _markConversationReadLocally(conversation.id);
                            unawaited(
                              _repository.markConversationRead(conversation.id),
                            );
                            await context.push(
                              '${AppRoutes.chatBase}/${conversation.id}',
                            );
                            if (mounted) _loadData();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
