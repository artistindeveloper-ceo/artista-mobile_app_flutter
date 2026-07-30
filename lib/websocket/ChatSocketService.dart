import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../service/WebSocketService.dart';

typedef ChatMessageHandler = void Function(Map<String, dynamic> message);

/// Chat message listener — rides on top of the single shared
/// WebSocketService connection (does NOT open its own socket). Listens on
/// the user's private queue so the unread badge updates instantly without
/// polling.
class ChatSocketService {
  ChatSocketService._internal();

  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  static const String _destination = '/user/queue/messages';

  ChatMessageHandler? _onMessage;
  bool _subscribed = false;

  /// Call once after WebSocketService.instance.connect() — e.g. right
  /// after login, on app restart, and after token refresh. Same isConnected
  /// check as PresenceService — a stale _subscribed=true must not skip
  /// re-subscribing on a freshly reconnected socket.
  void connect(ChatMessageHandler onMessage) {
    _onMessage = onMessage;
    if (_subscribed && WebSocketService.instance.isConnected) return;
    _subscribed = true;
    WebSocketService.instance.subscribe(_destination, _onFrame);
  }

  void _onFrame(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final data = jsonDecode(frame.body!);
      if (data is Map<String, dynamic>) _onMessage?.call(data);
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void disconnect() {
    WebSocketService.instance.unsubscribe(_destination);
    _subscribed = false;
    _onMessage = null;
  }
}
