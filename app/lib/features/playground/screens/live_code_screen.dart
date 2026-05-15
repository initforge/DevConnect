import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_delta.dart';
import '../../../core/utils/user_colors.dart';
import '../../../core/widgets/decorative_widgets.dart';

class LiveCodeScreen extends StatefulWidget {
  final String roomId;
  const LiveCodeScreen({super.key, this.roomId = 'demo-room'});

  @override
  State<LiveCodeScreen> createState() => _LiveCodeScreenState();
}

class _LiveCodeScreenState extends State<LiveCodeScreen> {
  late IO.Socket _socket;
  final TextEditingController _codeCtrl = TextEditingController(
    text: "const DevConnect = () => {\n  return <LiveCodeRoom />;\n};",
  );
  final Map<String, _RemoteCursor> _remoteCursors = {};
  late final String _localUserId;
  late final String _localName;
  late String _lastSentCode;
  bool _isConnected = false;
  bool _applyingRemoteChange = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    final user = AppPreferences.instance.user;
    _localUserId =
        AppPreferences.instance.userId ??
        'guest-${DateTime.now().millisecondsSinceEpoch}';
    _localName =
        user?['displayName']?.toString() ??
        user?['username']?.toString() ??
        'Guest';
    _lastSentCode = _codeCtrl.text;
    _codeCtrl.addListener(_sendCursorUpdate);
    _initSocket();
  }

  void _initSocket() {
    final liveUrl = AppConstants.wsBaseUrl.replaceFirst(RegExp(r'^ws'), 'http');
    _socket = IO.io(
      '$liveUrl/live',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': _localUserId})
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      setState(() => _isConnected = true);
      _socket.emit('join_room', widget.roomId);
    });

    _socket.on('room_joined', (data) {
      if (data is! Map) return;
      final nextCode = data['code']?.toString();
      if (nextCode == null) return;
      _applyingRemoteChange = true;
      setState(() {
        _codeCtrl.value = TextEditingValue(
          text: nextCode,
          selection: TextSelection.collapsed(
            offset: nextCode.length.clamp(0, nextCode.length).toInt(),
          ),
        );
        _lastSentCode = nextCode;
        _revision = int.tryParse(data['revision']?.toString() ?? '') ?? 0;
      });
      _applyingRemoteChange = false;
    });

    _socket.on('code_updated', (data) {
      if (data is Map && data['userId']?.toString() == _localUserId) return;
      final nextCode =
          data is Map ? _applyRemotePayload(data) : data?.toString();
      if (nextCode != null && _codeCtrl.text != nextCode) {
        _applyingRemoteChange = true;
        final oldSelection = _codeCtrl.selection;
        setState(() {
          _codeCtrl.value = TextEditingValue(
            text: nextCode,
            selection: TextSelection.collapsed(
              offset: oldSelection.baseOffset.clamp(0, nextCode.length).toInt(),
            ),
          );
          _lastSentCode = nextCode;
          _revision =
              data is Map
                  ? int.tryParse(data['revision']?.toString() ?? '') ??
                      _revision
                  : _revision;
        });
        _applyingRemoteChange = false;
      }
      if (data is Map && data['cursor'] is Map) {
        _upsertRemoteCursor(data['cursor'] as Map);
      }
    });

    _socket.on('cursor_updated', (data) {
      if (data is Map) _upsertRemoteCursor(data);
    });

    _socket.onDisconnect((_) => setState(() => _isConnected = false));
  }

  void _onCodeChanged(String code) {
    if (_applyingRemoteChange) return;
    final delta = TextDelta.fromChange(_lastSentCode, code);
    final baseRevision = _revision;
    _revision += 1;
    _lastSentCode = code;
    _socket.emit('code_change', {
      'roomId': widget.roomId,
      'code': code,
      'baseRevision': baseRevision,
      'revision': _revision,
      'userId': _localUserId,
      'cursor': _localCursorPayload(),
      'delta': delta.toJson(),
    });
  }

  String? _applyRemotePayload(Map data) {
    final delta = data['delta'];
    if (delta is Map) {
      final start = int.tryParse(delta['start']?.toString() ?? '');
      final deleteCount = int.tryParse(delta['deleteCount']?.toString() ?? '');
      final insertText = delta['insertText']?.toString() ?? '';
      if (start != null && deleteCount != null) {
        final text = _codeCtrl.text;
        final safeStart = start.clamp(0, text.length).toInt();
        final safeEnd = (safeStart + deleteCount).clamp(0, text.length).toInt();
        return text.replaceRange(safeStart, safeEnd, insertText);
      }
    }
    return data['code']?.toString();
  }

  void _sendCursorUpdate() {
    if (!_isConnected || _applyingRemoteChange) return;
    _socket.emit('cursor_update', {
      'roomId': widget.roomId,
      ..._localCursorPayload(),
    });
  }

  Map<String, dynamic> _localCursorPayload() {
    return {
      'userId': _localUserId,
      'name': _localName,
      'offset':
          _codeCtrl.selection.baseOffset
              .clamp(0, _codeCtrl.text.length)
              .toInt(),
      'color': UserColors.hexFromColor(UserColors.colorForUserId(_localUserId)),
    };
  }

  void _upsertRemoteCursor(Map data) {
    final userId = data['userId']?.toString();
    if (userId == null || userId == _localUserId) return;
    setState(() {
      _remoteCursors[userId] = _RemoteCursor(
        name: data['name']?.toString() ?? 'Guest',
        offset: int.tryParse(data['offset']?.toString() ?? '') ?? 0,
        color: _parseHexColor(data['color']?.toString()),
      );
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _codeCtrl.removeListener(_sendCursorUpdate);
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 12,
                      color: _isConnected ? Colors.green : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Live Session' : 'Connecting...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const _HeaderPill(
                      icon: Icons.schedule,
                      label: '23:45',
                      color: Color(0xFFF3F0FF),
                      textColor: Color(0xFF5B53F6),
                    ),
                    const SizedBox(width: 8),
                    const _HeaderPill(
                      icon: Icons.call_end,
                      label: 'End',
                      color: Color(0xFFFFEFEF),
                      textColor: AppColors.error,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ParticipantAvatar(
                          label: _avatarLabel(_localName),
                          color: AppColors.primary,
                        ),
                        ..._remoteCursors.values.map(
                          (cursor) => _ParticipantAvatar(
                            label: _avatarLabel(cursor.name),
                            color: cursor.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE7EAF3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFD),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
                            child: const Row(
                              children: [
                                _Dot(Color(0xFFF87171)),
                                SizedBox(width: 6),
                                _Dot(Color(0xFFFBBF24)),
                                SizedBox(width: 6),
                                _Dot(Color(0xFF34D399)),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: TextField(
                                  controller: _codeCtrl,
                                  maxLines: null,
                                  onChanged: _onCodeChanged,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF1E293B),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _RemoteCursorOverlay(
                                      cursors: _remoteCursors.values.toList(),
                                      code: _codeCtrl.text,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: _CursorPresenceBar(
                                  cursors: _remoteCursors.values.toList(),
                                  code: _codeCtrl.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B53F6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Let me use the new API hook so we can keep state in sync.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE7EAF3))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      _ActionCircle(
                        Icons.mic_none,
                        onTap:
                            () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mic — demo only')),
                            ),
                      ),
                      const SizedBox(width: 12),
                      _ActionCircle(
                        Icons.videocam_outlined,
                        onTap:
                            () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera — demo only'),
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      _ActionCircle(
                        Icons.screen_share_outlined,
                        onTap:
                            () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Screen share — demo only'),
                              ),
                            ),
                      ),
                      const Spacer(),
                      _ActionCircle(
                        Icons.chat_bubble_outline,
                        primary: true,
                        onTap:
                            () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat — demo only')),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.label,
    this.color = const Color(0xFF5B53F6),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle(this.icon, {this.primary = false, this.onTap});

  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF5B53F6) : const Color(0xFFF4F6FA),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: primary ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CursorPresenceBar extends StatelessWidget {
  const _CursorPresenceBar({required this.cursors, required this.code});

  final List<_RemoteCursor> cursors;
  final String code;

  @override
  Widget build(BuildContext context) {
    if (cursors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          cursors.take(3).map((cursor) {
            final position = _lineColumn(code, cursor.offset);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: cursor.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cursor.color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 2, height: 14, color: cursor.color),
                  const SizedBox(width: 6),
                  Text(
                    '${cursor.name} L${position.$1}:C${position.$2}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cursor.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _RemoteCursorOverlay extends StatelessWidget {
  const _RemoteCursorOverlay({required this.cursors, required this.code});

  final List<_RemoteCursor> cursors;
  final String code;

  @override
  Widget build(BuildContext context) {
    if (cursors.isEmpty) return const SizedBox.shrink();
    const lineHeight = 19.5;
    const charWidth = 7.8;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children:
              cursors.take(4).map((cursor) {
                final position = _lineColumn(code, cursor.offset);
                final top = ((position.$1 - 1) * lineHeight).clamp(
                  0,
                  constraints.maxHeight - 22,
                );
                final left = ((position.$2 - 1) * charWidth).clamp(
                  0,
                  constraints.maxWidth - 90,
                );
                return Positioned(
                  left: left.toDouble(),
                  top: top.toDouble(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 2, height: 18, color: cursor.color),
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cursor.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cursor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RemoteCursor {
  const _RemoteCursor({
    required this.name,
    required this.offset,
    required this.color,
  });

  final String name;
  final int offset;
  final Color color;
}

(int, int) _lineColumn(String text, int offset) {
  final safeOffset = offset.clamp(0, text.length).toInt();
  final before = text.substring(0, safeOffset);
  final lines = before.split('\n');
  return (lines.length, lines.last.length + 1);
}

Color _parseHexColor(String? value) {
  if (value == null || value.isEmpty) return AppColors.primary;
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return parsed == null ? AppColors.primary : Color(parsed);
}

String _avatarLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
