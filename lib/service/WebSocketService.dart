import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/ApiConfig.dart';

/// Thin wrapper around StompClient. Single shared connection for the whole
/// app — presence AND (later) chat can both subscribe on top of it, so we
/// don't open multiple sockets.
class WebSocketService {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  StompClient? _client;
  String? _token;

  bool get isConnected => _client?.connected ?? false;

  // Destinations we were asked to subscribe to before the socket was
  // connected — replayed automatically in onConnect.
  final Map<String, void Function(StompFrame)> _pendingSubscriptions = {};
  final Map<String, StompUnsubscribe> _activeUnsubscribers = {};

  void connect(String jwtToken) {
    _token = jwtToken;

    // baseUrl looks like 'http://43.205.146.248:8081' — swap scheme for ws.
    final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws') +
        '/ws-native?token=$jwtToken';

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          // Keep it quiet in production; useful while wiring things up.
          print('🔌 WebSocket error: $error');
        },
        onStompError: (StompFrame frame) {
          print('🔌 STOMP error: ${frame.body}');
        },
        onDisconnect: (_) => print('🔌 WebSocket disconnected'),
        stompConnectHeaders: {'Authorization': 'Bearer $jwtToken'},
        // Auto-reconnect so presence/chat survive brief network drops.
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('🔌 WebSocket connected');
    // Replay any subscriptions requested before we were connected.
    _pendingSubscriptions.forEach((destination, callback) {
      _subscribeNow(destination, callback);
    });
  }

  /// Subscribe to a STOMP destination. Safe to call before connect() has
  /// finished — it queues and replays once connected.
  void subscribe(String destination, void Function(StompFrame) callback) {
    _pendingSubscriptions[destination] = callback;
    if (isConnected) {
      _subscribeNow(destination, callback);
    }
  }

  void _subscribeNow(String destination, void Function(StompFrame) callback) {
    if (_activeUnsubscribers.containsKey(destination)) return; // already on
    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: callback,
    );
    _activeUnsubscribers[destination] = unsubscribe;
  }

  void unsubscribe(String destination) {
    _activeUnsubscribers.remove(destination)?.call();
    _pendingSubscriptions.remove(destination);
  }

  void send(String destination, Map<String, dynamic> body) {
    if (!isConnected) return;
    _client!.send(destination: destination, body: jsonEncode(body));
  }

  void disconnect() {
    _client?.deactivate();
    _pendingSubscriptions.clear();
    _activeUnsubscribers.clear();
    _client = null;
    _token = null;
  }
}
