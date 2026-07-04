import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';

typedef ChatMessageHandler = void Function(Map<String, dynamic> message);

/// Global chat socket — connects once for the whole app session (not tied
/// to a single conversation) and listens on the user's private queue so
/// the unread badge updates instantly without polling.
///
/// Singleton: only one connection should exist for the app's lifetime,
/// separate from JamSessionSocketService (which is per jam-session).
class ChatSocketService {
  ChatSocketService._internal();

  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  StompClient? _client;
  bool _connected = false;
  ChatMessageHandler? _onMessage;

  void connect(ChatMessageHandler onMessage) {
    if (_connected) {
      // Already connected — just update the handler (e.g. HomeScreen rebuilt)
      _onMessage = onMessage;
      return;
    }
    _onMessage = onMessage;
    final token = Session().token;

    // ⚠️ Same '/ws' endpoint as JamSessionSocketService — must match
    // WebSocketConfig.registerStompEndpoints().
    final wsUrl =
        '${ApiConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}/ws';

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic e) => print('ChatSocket WS error: $e'),
        onStompError: (frame) => print('ChatSocket STOMP error: ${frame.body}'),
        onDisconnect: (_) => _connected = false,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    _client!.subscribe(
      // Spring resolves this to the caller's own private queue based on
      // the authenticated Principal — matches convertAndSendToUser(...).
      destination: '/user/queue/messages',
      callback: (StompFrame f) {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!);
          if (data is Map<String, dynamic>) _onMessage?.call(data);
        } catch (_) {}
      },
    );
  }

  void disconnect() {
    if (_connected) {
      _client?.deactivate();
      _connected = false;
    }
  }
}
