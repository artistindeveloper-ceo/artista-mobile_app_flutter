import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';

typedef JamEventHandler = void Function(Map<String, dynamic> event);

class JamSessionSocketService {
  final int sessionId;
  final JamEventHandler onEvent;
  StompClient? _client;
  bool _connected = false;

  JamSessionSocketService({required this.sessionId, required this.onEvent});

  void connect() {
    final token = Session().token;

    // ⚠️ IMPORTANT: '/ws' path apne WebSocketConfig.registerStompEndpoints()
    // me jo bhi mapping hai usse match karo (e.g. registry.addEndpoint("/ws")).
    final wsUrl =
        '${ApiConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}/ws-native?token=$token';
    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic e) => print('JamSocket WS error: $e'),
        onStompError: (frame) => print('JamSocket STOMP error: ${frame.body}'),
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
      destination: '/topic/jam-sessions/$sessionId',
      callback: (StompFrame f) {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!);
          if (data is Map<String, dynamic>) onEvent(data);
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
