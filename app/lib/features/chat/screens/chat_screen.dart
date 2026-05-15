import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_grouping.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../widgets/day_separator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    implements WebSocketServiceListener {
  final _repository = ChatRepository();
  final _msgCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherUserTyping = false;
  User? _otherUser;
  List<Message> _messages = [];
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.addListener(this);
    WebSocketService.instance.subscribe(WsChannel.messages);
    _msgCtrl.addListener(_onTextChanged);
    unawaited(_repository.markConversationRead(widget.conversationId));
    // Load draft for this conversation
    final draft = AppPreferences.instance.getDraft(
      'chat.${widget.conversationId}',
    );
    if (draft != null && draft.isNotEmpty) {
      _msgCtrl.text = draft;
    }
    _load();
  }

  void _onTextChanged() {
    if (_typingTimer?.isActive ?? false) return;

    WebSocketService.instance.send('messages', {
      'type': 'typing',
      'conversationId': widget.conversationId,
      'isTyping': true,
    });

    _typingTimer = Timer(const Duration(seconds: 3), () {
      WebSocketService.instance.send('messages', {
        'type': 'typing',
        'conversationId': widget.conversationId,
        'isTyping': false,
      });
    });
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repository.getConversationOtherUser(widget.conversationId),
        _repository.getMessages(widget.conversationId),
      ]);
      if (!mounted) return;
      setState(() {
        _otherUser = results[0] as User?;
        _messages = results.length > 1 ? results[1] as List<Message> : [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _otherUser = null;
        _messages = const [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _msgCtrl.removeListener(_onTextChanged);
    // Save draft if text non-empty
    final text = _msgCtrl.text.trim();
    if (text.isNotEmpty) {
      AppPreferences.instance.setDraft('chat.${widget.conversationId}', text);
    }
    WebSocketService.instance.unsubscribe(WsChannel.messages);
    WebSocketService.instance.removeListener(this);
    unawaited(_repository.markConversationRead(widget.conversationId));
    _msgCtrl.dispose();
    super.dispose();
  }

  // --- WebSocketServiceListener ---

  @override
  void onWsConnected() {}

  @override
  void onWsDisconnected() {}

  @override
  void onWsError(String error) {}

  @override
  void onWsPresenceUpdate(String userId, bool isOnline) {
    if (userId == _otherUser?.id) {
      setState(() {
        _otherUser = _otherUser?.copyWith(isOnline: isOnline);
      });
    }
  }

  @override
  void onWsTyping(String userId, bool isTyping) {
    if (userId == _otherUser?.id) {
      setState(() {
        _otherUserTyping = isTyping;
      });
    }
  }

  @override
  void onWsMessage(WsMessage msg) {
    if (msg.channel != 'messages' || msg.data == null) return;
    final convId = msg.data!['conversationId']?.toString();
    if (convId != widget.conversationId) return;

    final message = Message(
      id: msg.data!['id']?.toString() ?? '',
      senderId: msg.data!['senderId']?.toString() ?? '',
      content: msg.data!['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (msg.data!['type']?.toString() ?? 'text'),
        orElse: () => MessageType.text,
      ),
      codeLanguage: msg.data!['codeLanguage']?.toString(),
      codeSource: msg.data!['codeSource']?.toString(),
      reactions: _parseMessageReactions(msg.data!['reactions']),
      isRead: msg.data!['isRead'] == true || msg.data!['is_read'] == 1,
      createdAt:
          DateTime.tryParse(msg.data!['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _messages = [..._messages, message];
      if (message.senderId == _otherUser?.id) {
        _otherUserTyping = false;
        unawaited(_repository.markConversationRead(widget.conversationId));
      }
    });
  }

  // --- Sending ---

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    setState(() => _isSending = true);
    try {
      final bytes = await image.readAsBytes();
      final name =
          image.name.isNotEmpty
              ? image.name
              : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await ApiService.instance.uploadFileBytes(
        '/media/upload',
        bytes: bytes,
        fileName: name,
        fieldName: 'file',
      );
      final imageUrl = (result['fullUrl'] ?? result['url'] ?? '') as String;
      if (imageUrl.isEmpty) throw Exception('Upload returned empty URL');

      await _repository.sendMessage(
        conversationId: widget.conversationId,
        content: imageUrl,
        type: MessageType.image,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to send message')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendCodeSnippet(String language, String code) async {
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      await _repository.sendMessage(
        conversationId: widget.conversationId,
        content: code,
        type: MessageType.code,
        codeLanguage: language,
        codeSource: code,
      );
      await _repository.markConversationRead(widget.conversationId);
      await _load();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showReactionPicker(Message message) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const reactions = ['👍', '❤️', '😂', '🎉', '👀', '✅'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  reactions
                      .map(
                        (emoji) => InkWell(
                          onTap: () => Navigator.of(context).pop(emoji),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );

    if (reaction == null) return;
    await _addReaction(message, reaction);
  }

  Future<void> _addReaction(Message message, String reaction) async {
    final before = _messages;
    final nextReactions =
        message.reactions.contains(reaction)
            ? message.reactions.where((item) => item != reaction).toList()
            : [...message.reactions, reaction];

    setState(() {
      _messages =
          _messages
              .map(
                (item) =>
                    item.id == message.id
                        ? _copyMessage(item, reactions: nextReactions)
                        : item,
              )
              .toList();
    });

    try {
      final updated = await _repository.addReaction(
        conversationId: widget.conversationId,
        messageId: message.id,
        reaction: reaction,
      );
      if (!mounted) return;
      setState(() {
        _messages =
            _messages
                .map((item) => item.id == updated.id ? updated : item)
                .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages = before);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('chat.unableReaction')),
        ),
      );
    }
  }

  void _showCodeSnippetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String selectedLanguage = 'Python';
        final codeCtrl = TextEditingController();

        return StatefulBuilder(
          builder:
              (ctx, setModalState) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      AppStrings.of(ctx).t('chat.sendCodeSnippet'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        labelText: AppStrings.of(ctx).t('chat.language'),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Python',
                          child: Text('Python'),
                        ),
                        DropdownMenuItem(
                          value: 'JavaScript',
                          child: Text('JavaScript'),
                        ),
                        DropdownMenuItem(value: 'Dart', child: Text('Dart')),
                        DropdownMenuItem(
                          value: 'TypeScript',
                          child: Text('TypeScript'),
                        ),
                        DropdownMenuItem(value: 'Java', child: Text('Java')),
                        DropdownMenuItem(value: 'C++', child: Text('C++')),
                        DropdownMenuItem(value: 'C#', child: Text('C#')),
                        DropdownMenuItem(value: 'Go', child: Text('Go')),
                        DropdownMenuItem(value: 'Rust', child: Text('Rust')),
                        DropdownMenuItem(value: 'Ruby', child: Text('Ruby')),
                        DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                        DropdownMenuItem(value: 'Swift', child: Text('Swift')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedLanguage = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      maxLines: 8,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(ctx).t('chat.pasteCode'),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final code = codeCtrl.text.trim();
                          if (code.isEmpty) return;
                          _sendCodeSnippet(selectedLanguage, code);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B53F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.of(ctx).t('chat.sendCode'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_otherUser == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: AppStrings.of(context).t('chat.conversationNotFound'),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopChat(context, _otherUser!, _messages);
    }

    return _buildMobileChat(context, _otherUser!, _messages);
  }

  Widget _buildDesktopChat(
    BuildContext context,
    User otherUser,
    List<Message> messages,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Column(
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
                  otherUser.isOnline
                      ? AppStrings.of(context).t('chat.online')
                      : AppStrings.of(context).t('chat.offline'),
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
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call — coming soon')),
              );
            },
            icon: const Icon(Icons.videocam_outlined, size: 20),
            tooltip: 'Video call',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call — coming soon')),
              );
            },
            icon: const Icon(Icons.call_outlined, size: 20),
            tooltip: 'Voice call',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildChatArea(context, otherUser, messages, isDesktop: true),
        ),
      ),
    );
  }

  Widget _buildMobileChat(
    BuildContext context,
    User otherUser,
    List<Message> messages,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    otherUser.isOnline
                        ? AppStrings.of(context).t('chat.online')
                        : AppStrings.of(context).t('chat.offline'),
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
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call — coming soon')),
              );
            },
            icon: const Icon(Icons.videocam_outlined, size: 20),
            tooltip: 'Video call',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call — coming soon')),
              );
            },
            icon: const Icon(Icons.call_outlined, size: 20),
            tooltip: 'Voice call',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildChatArea(context, otherUser, messages, isDesktop: false),
    );
  }

  Widget _buildChatArea(
    BuildContext context,
    User otherUser,
    List<Message> messages, {
    required bool isDesktop,
  }) {
    final currentUserId = AppPreferences.instance.userId;
    if (currentUserId == null) {
      return Center(
        child: Text(AppStrings.of(context).t('chat.sessionMissing')),
      );
    }

    // Build list items with day separators inserted between messages from different days
    final List<Widget> chatItems = [];
    String? lastDayLabel;
    for (final message in messages) {
      final label = DateGrouping.dayLabel(message.createdAt);
      if (label != lastDayLabel) {
        lastDayLabel = label;
        chatItems.add(DaySeparator(label: label));
      }
      chatItems.add(
        _MessageBubble(
          msg: message,
          isMe: message.senderId == currentUserId,
          isDesktop: isDesktop,
          onLongPress: () => _showReactionPicker(message),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            children: chatItems,
          ),
        ),
        if (_otherUserTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_otherUser!.displayName} is typing',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndSendImage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showCodeSnippetDialog,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.code,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context).t('chat.typeMessage'),
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
                    color: AppColors.primary,
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
    );
  }
}

Message _copyMessage(Message message, {List<String>? reactions, bool? isRead}) {
  return Message(
    id: message.id,
    senderId: message.senderId,
    content: message.content,
    type: message.type,
    codeLanguage: message.codeLanguage,
    codeSource: message.codeSource,
    reactions: reactions ?? message.reactions,
    isRead: isRead ?? message.isRead,
    createdAt: message.createdAt,
  );
}

List<String> _parseMessageReactions(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String) {
    return value.split('|').where((item) => item.isNotEmpty).toList();
  }
  return const [];
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.isDesktop = false,
    this.onLongPress,
  });

  final Message msg;
  final bool isMe;
  final bool isDesktop;
  final VoidCallback? onLongPress;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        isDesktop ? 600.0 : MediaQuery.of(context).size.width * 0.72;
    final isCode = msg.type == MessageType.code;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCode ? 0 : 14,
                    vertical: isCode ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCode
                            ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                            : isMe
                            ? AppColors.primary
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 18),
                    ),
                  ),
                  child:
                      isCode
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2B55),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (msg.codeLanguage ?? 'Code')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.code,
                                      size: 12,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  msg.content,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: Color(0xFF6E59F7),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Text(
                            msg.content,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color:
                                  isMe ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                ),
              ),
              if (msg.reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children:
                      msg.reactions
                          .map(
                            (reaction) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE8EAF2),
                                ),
                              ),
                              child: Text(
                                reaction,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.check,
                      size: 14,
                      color:
                          msg.isRead
                              ? const Color(0xFF5B53F6)
                              : AppColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
