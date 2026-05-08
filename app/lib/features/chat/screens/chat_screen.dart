import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/models.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = ChatRepository();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late Future<List<Object?>> _loader;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  void _loadFeeds() {
    _loader = Future.wait([
      _repository.getConversationOtherUser(widget.conversationId),
      _repository.getMessages(widget.conversationId),
    ]);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _repository.markConversationRead(widget.conversationId);
    _loadFeeds();
    if (!mounted) return;
    setState(() {});
    await _loader;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending) return;
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _repository.sendMessage(conversationId: widget.conversationId, content: content);
      _msgCtrl.clear();
      await _repository.markConversationRead(widget.conversationId);
      _loadFeeds();
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: FutureBuilder<List<Object?>>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: 'Đã xảy ra lỗi khi tải tin nhắn.\nVui lòng thử lại.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ?? const <Object?>[];
          final otherUser = data.isNotEmpty ? data[0] as User? : null;
          final messages = data.length > 1 ? (data[1] as List<Message>) : const <Message>[];

          if (otherUser == null) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Không tìm thấy hội thoại',
              subtitle: 'Hội thoại có thể đã bị xóa.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final message = messages[index];
                      final currentUserId = AppPreferences.instance.user?['id'] ?? 'u1';
                      final isMe = message.senderId == currentUserId;
                      return _MessageBubble(msg: message, isMe: isMe);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: const Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            decoration: InputDecoration(
                              hintText: 'Nhắn tin...',
                              filled: true,
                              fillColor: AppColors.surfaceAlt,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: AppColors.primary),
                                onPressed: _send,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              msg.content,
              style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
