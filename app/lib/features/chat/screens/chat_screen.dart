import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = ChatRepository();
  final _msgCtrl = TextEditingController();
  late Future<List<Object?>> _loader;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loader = Future.wait([
      _repository.getConversationOtherUser(widget.conversationId),
      _repository.getMessages(widget.conversationId),
    ]);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _repository.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
      _msgCtrl.clear();
      await _repository.markConversationRead(widget.conversationId);
      _load();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? const <Object?>[];
        final otherUser = data.isNotEmpty ? data[0] as User? : null;
        final messages =
            data.length > 1 ? data[1] as List<Message> : const <Message>[];

        if (otherUser == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Conversation not found',
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                UserAvatar(
                  name: otherUser.displayName,
                  size: 36,
                  isOnline: otherUser.isOnline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        otherUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              otherUser.isOnline
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: const [
              Icon(Icons.videocam_outlined, size: 20),
              SizedBox(width: 16),
              Icon(Icons.call_outlined, size: 20),
              SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TODAY, 2:30 PM',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  itemCount: messages.length + 2,
                  itemBuilder: (_, index) {
                    if (index == 1) {
                      return const _CodePreviewBubble();
                    }
                    if (index == messages.length + 1) {
                      return const _LinkPreviewBubble(
                        isMe: false,
                        title: 'React Performance Guide',
                        subtitle: 'devconnect.io/blog/recursive-ui',
                      );
                    }

                    final currentUserId =
                        AppPreferences.instance.user?['id'] ?? 'u1';
                    final adjustedIndex = index > 1 ? index - 1 : index;
                    final message = messages[adjustedIndex];
                    return _MessageBubble(
                      msg: message,
                      isMe: message.senderId == currentUserId,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE8EAF2))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F6FA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FA),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B53F6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isSending ? null : _send,
                          icon:
                              _isSending
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});

  final Message msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF6E59F7) : const Color(0xFFF3F5F9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 18),
              ),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePreviewBubble extends StatelessWidget {
  const _CodePreviewBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.74,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Text(
                  'REACT COMPONENT',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.copy_outlined,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'const TreeView = ({ data }) => {\n  return (\n    <div>\n      {data.map(item => (\n        <Node key={item.id} {...item} />\n      ))}\n    </div>\n  );\n};',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF6E59F7),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPreviewBubble extends StatelessWidget {
  const _LinkPreviewBubble({
    required this.isMe,
    required this.title,
    required this.subtitle,
  });

  final bool isMe;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.64,
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF5B53F6),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}
