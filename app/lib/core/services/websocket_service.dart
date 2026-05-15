import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';

/// WebSocket message types for real-time communication
enum WsMessageType {
  auth,
  ping,
  pong,
  subscribe,
  subscribed,
  message,
  notification,
  presence,
  typing,
  error,
}

/// WebSocket message wrapper
class WsMessage {
  final WsMessageType type;
  final String? channel;
  final Map<String, dynamic>? data;
  final String? error;

  WsMessage({required this.type, this.channel, this.data, this.error});

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: WsMessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'error'),
        orElse: () => WsMessageType.error,
      ),
      channel: json['channel'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (channel != null) 'channel': channel,
    if (data != null) 'data': data,
  };
}

/// Channel types for subscription
enum WsChannel { notifications, messages, presence, posts }

/// WebSocket connection state
enum WsConnectionState { disconnected, connecting, connected, reconnecting }

/// Abstract listener for WebSocket events
abstract class WebSocketServiceListener {
  void onWsConnected();
  void onWsDisconnected();
  void onWsMessage(WsMessage msg);
  void onWsError(String error);
  void onWsPresenceUpdate(String userId, bool isOnline);
  void onWsTyping(String userId, bool isTyping);
}

/// Socket.IO-backed realtime service for chat, presence, and typing.
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  io.Socket? _socket;
  String? _token;
  final List<WebSocketServiceListener> _listeners = [];
  final Set<WsChannel> _subscribedChannels = {};
  final Set<String> _joinedConversations = {};

  WsConnectionState _state = WsConnectionState.disconnected;

  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  String get _socketOrigin {
    final apiUri = Uri.parse(AppConstants.apiBaseUrl);
    return Uri(
      scheme: apiUri.scheme.isEmpty ? 'http' : apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    ).toString();
  }

  /// Connect to Socket.IO server with authentication token.
  void connect({required String token}) {
    if (_token == token && _socket?.connected == true) {
      return;
    }

    _token = token;
    _disposeSocket();
    _state = WsConnectionState.connecting;
    _createSocket();
  }

  void _createSocket() {
    if (_token == null) return;

    final socket = io.io(
      '$_socketOrigin/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0)
          .disableAutoConnect()
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      _state = WsConnectionState.connected;
      _notifyConnected();
      _resubscribeRooms();
    });

    socket.onReconnectAttempt((attempt) {
      _state = WsConnectionState.reconnecting;
      _notifyError('Reconnecting... attempt $attempt');
    });

    socket.onReconnect((_) {
      _state = WsConnectionState.connected;
      _notifyConnected();
      _resubscribeRooms();
    });

    socket.onReconnectFailed((_) {
      _state = WsConnectionState.disconnected;
      _notifyError('Reconnect failed');
      _notifyDisconnected();
    });

    socket.onDisconnect((reason) {
      if (reason == 'io client disconnect') {
        _state = WsConnectionState.disconnected;
        _notifyDisconnected();
        return;
      }

      _state = WsConnectionState.reconnecting;
      _notifyError('Socket disconnected: $reason');
    });

    socket.onConnectError((error) {
      _state = WsConnectionState.reconnecting;
      _notifyError(error.toString());
    });

    socket.onError((error) {
      _notifyError(error.toString());
    });

    socket.on('presence_change', (data) {
      final map = _toMap(data);
      final userId = map['userId']?.toString() ?? '';
      final status = map['status']?.toString() ?? 'offline';
      if (userId.isEmpty) return;
      _notifyPresenceUpdate(userId, status == 'online');
    });

    socket.on('user_typing', (data) {
      final map = _toMap(data);
      final userId = map['userId']?.toString() ?? '';
      if (userId.isEmpty) return;
      _notifyTyping(userId, map['isTyping'] == true);
    });

    socket.on('new_message', (data) {
      final map = _toMap(data);
      _notifyMessage(
        WsMessage(
          type: WsMessageType.message,
          channel: WsChannel.messages.name,
          data: map,
        ),
      );
    });

    socket.connect();
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return Map<String, dynamic>.fromEntries(
            decoded.entries.map(
              (entry) => MapEntry(entry.key.toString(), entry.value),
            ),
          );
        }
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  void _resubscribeRooms() {
    for (final channel in _subscribedChannels) {
      if (channel == WsChannel.messages) {
        for (final conversationId in _joinedConversations) {
          _socket?.emit('join_conversation', conversationId);
        }
      }
    }
  }

  void _disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Join a conversation room for message and typing events.
  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _joinedConversations.add(conversationId);
    _socket?.emit('join_conversation', conversationId);
  }

  /// Leave a conversation room.
  void leaveConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _joinedConversations.remove(conversationId);
    _socket?.emit('leave_conversation', conversationId);
  }

  /// Send message to a channel.
  void send(String channel, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || channel.isEmpty) {
      return;
    }

    switch (channel) {
      case 'messages':
        if (data['type']?.toString() == 'typing') {
          socket.emit('typing', data);
        } else {
          socket.emit('send_message', data);
        }
        break;
      default:
        socket.emit(channel, data);
    }
  }

  /// Subscribe to a channel (notifications, messages, presence, posts).
  void subscribe(WsChannel channel) {
    _subscribedChannels.add(channel);
  }

  /// Unsubscribe from a channel.
  void unsubscribe(WsChannel channel) {
    _subscribedChannels.remove(channel);
  }

  /// Disconnect and cleanup.
  void disconnect() {
    _disposeSocket();
    _token = null;
    _state = WsConnectionState.disconnected;
    _subscribedChannels.clear();
    _joinedConversations.clear();
    _notifyDisconnected();
  }

  /// Add listener for WebSocket events.
  void addListener(WebSocketServiceListener listener) {
    _listeners.add(listener);
  }

  /// Remove listener.
  void removeListener(WebSocketServiceListener listener) {
    _listeners.remove(listener);
  }

  void _notifyConnected() {
    for (final listener in _listeners) {
      listener.onWsConnected();
    }
  }

  void _notifyDisconnected() {
    for (final listener in _listeners) {
      listener.onWsDisconnected();
    }
  }

  void _notifyMessage(WsMessage msg) {
    for (final listener in _listeners) {
      listener.onWsMessage(msg);
    }
  }

  void _notifyError(String error) {
    for (final listener in _listeners) {
      listener.onWsError(error);
    }
  }

  void _notifyPresenceUpdate(String userId, bool isOnline) {
    for (final listener in _listeners) {
      listener.onWsPresenceUpdate(userId, isOnline);
    }
  }

  void _notifyTyping(String userId, bool isTyping) {
    for (final listener in _listeners) {
      listener.onWsTyping(userId, isTyping);
    }
  }
}
