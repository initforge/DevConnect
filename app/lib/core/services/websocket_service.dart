import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  error,
}

/// WebSocket message wrapper
class WsMessage {
  final WsMessageType type;
  final String? channel;
  final Map<String, dynamic>? data;
  final String? error;

  WsMessage({
    required this.type,
    this.channel,
    this.data,
    this.error,
  });

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
enum WsChannel {
  notifications,
  messages,
  presence,
  posts,
}

/// WebSocket connection state
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Abstract listener for WebSocket events
abstract class WebSocketServiceListener {
  void onWsConnected();
  void onWsDisconnected();
  void onWsMessage(WsMessage msg);
  void onWsError(String error);
  void onWsPresenceUpdate(String userId, bool isOnline);
}

/// Real WebSocket service with automatic reconnection
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _token;
  final List<WebSocketServiceListener> _listeners = [];
  final Set<WsChannel> _subscribedChannels = {};

  WsConnectionState _state = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  /// Connect to WebSocket server with authentication
  void connect({required String token}) {
    if (_state == WsConnectionState.connecting || _state == WsConnectionState.connected) {
      return;
    }

    _token = token;
    _state = WsConnectionState.connecting;
    _doConnect();
  }

  void _doConnect() {
    if (_token == null) return;

    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}/ws');
      _channel = WebSocketChannel.connect(uri);

      _state = WsConnectionState.connecting;
      _notifyDisconnected();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Send auth immediately after connection
      _sendRaw({'type': 'auth', 'token': _token});
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = WsMessage.fromJson(json);

      switch (msg.type) {
        case WsMessageType.auth:
          if (msg.error == null) {
            _state = WsConnectionState.connected;
            _reconnectAttempts = 0;
            _startHeartbeat();
            _notifyConnected();
            _resubscribeChannels();
          } else {
            _notifyError(msg.error!);
          }
          break;

        case WsMessageType.pong:
          // Heartbeat acknowledged
          break;

        case WsMessageType.subscribed:
          if (msg.channel != null) {
            final channel = WsChannel.values.firstWhere(
              (c) => c.name == msg.channel,
              orElse: () => WsChannel.notifications,
            );
            _subscribedChannels.add(channel);
          }
          break;

        case WsMessageType.notification:
        case WsMessageType.message:
        case WsMessageType.presence:
          _notifyMessage(msg);
          break;

        case WsMessageType.error:
          _notifyError(msg.error ?? 'Unknown error');
          break;

        default:
          _notifyMessage(msg);
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void _onError(dynamic error) {
    _notifyError(error.toString());
    _scheduleReconnect();
  }

  void _onDone() {
    _state = WsConnectionState.disconnected;
    _notifyDisconnected();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_state == WsConnectionState.connected) {
        _sendRaw({'type': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _state = WsConnectionState.disconnected;
      _notifyError('Max reconnection attempts reached');
      return;
    }

    _state = WsConnectionState.reconnecting;
    _reconnectAttempts++;

    // Exponential backoff with jitter
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts.clamp(0, 5));
    final cappedDelay = delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
    final jitter = Duration(milliseconds: (cappedDelay.inMilliseconds * 0.1 * (DateTime.now().millisecondsSinceEpoch % 100) / 100).round());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(cappedDelay + jitter, () {
      if (_token != null) {
        _doConnect();
      }
    });
  }

  void _sendRaw(Map<String, dynamic> data) {
    if (_channel != null && _state == WsConnectionState.connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _resubscribeChannels() {
    for (final channel in _subscribedChannels) {
      _sendRaw({'type': 'subscribe', 'channel': channel.name});
    }
  }

  /// Send message to a channel
  void send(String channel, Map<String, dynamic> data) {
    _sendRaw({
      'type': 'message',
      'channel': channel,
      'data': data,
    });
  }

  /// Subscribe to a channel (notifications, messages, presence, posts)
  void subscribe(WsChannel channel) {
    if (_state == WsConnectionState.connected) {
      _sendRaw({'type': 'subscribe', 'channel': channel.name});
      _subscribedChannels.add(channel);
    }
  }

  /// Unsubscribe from a channel
  void unsubscribe(WsChannel channel) {
    if (_state == WsConnectionState.connected) {
      _sendRaw({'type': 'unsubscribe', 'channel': channel.name});
      _subscribedChannels.remove(channel);
    }
  }

  /// Disconnect and cleanup
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _token = null;
    _state = WsConnectionState.disconnected;
    _subscribedChannels.clear();
    _notifyDisconnected();
  }

  /// Add listener for WebSocket events
  void addListener(WebSocketServiceListener listener) {
    _listeners.add(listener);
  }

  /// Remove listener
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
}