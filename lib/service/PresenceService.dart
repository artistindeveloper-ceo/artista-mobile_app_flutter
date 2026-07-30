import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/ApiConfig.dart';
import 'ApiClient.dart';
import 'HelperService.dart';
import 'WebSocketService.dart';

/// Tracks which userIds are currently online. Subscribe a widget to this via
/// ChangeNotifier (e.g. AnimatedBuilder / ListenableBuilder / Provider) to
/// show a live green dot.
class PresenceService extends ChangeNotifier {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final Map<int, bool> _onlineStatus = {};
  final Map<int, DateTime?> _lastSeenAt = {};

  bool isOnline(int userId) => _onlineStatus[userId] ?? false;

  DateTime? lastSeenAt(int userId) => _lastSeenAt[userId];

  bool _subscribed = false;

  /// Call once after WebSocketService.instance.connect() — e.g. right after
  /// login, on app restart, and after token refresh. We check isConnected
  /// too (not just _subscribed) because disconnect()/connect() wipes the
  /// socket's pending subscriptions — a stale _subscribed=true would
  /// otherwise skip re-subscribing on the new socket.
  void startListening() {
    if (_subscribed && WebSocketService.instance.isConnected) return;
    _subscribed = true;
    WebSocketService.instance.subscribe('/topic/presence', _onPresenceEvent);
  }

  void _onPresenceEvent(frame) {
    if (frame.body == null) return;
    try {
      final data = jsonDecode(frame.body!) as Map<String, dynamic>;
      final userId = data['userId'] as int;
      final online = data['online'] as bool;
      _onlineStatus[userId] = online;
      _lastSeenAt[userId] = DateTime.now();
      notifyListeners();
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  /// REST fallback — call when opening a chat/profile screen so the dot is
  /// correct immediately, before any WebSocket event has arrived for that
  /// user.
  Future<void> fetchInitialStatus(int userId) async {
    final uri = Uri.parse(ApiConfig.presenceStatusUrl(userId));
    try {
      final response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _onlineStatus[userId] = data['online'] as bool? ?? false;
      final lastSeenRaw = data['lastSeenAt'] as String?;
      _lastSeenAt[userId] =
          lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null;
      notifyListeners();
    } catch (_) {
      // Silent fail — UI just shows nothing/offline until a WS event lands.
    }
  }

  /// Bulk REST fallback — call for a conversations/followers list so all
  /// dots are correct in a single request instead of N separate calls.
  Future<void> fetchBulkStatus(List<int> userIds) async {
    if (userIds.isEmpty) return;
    final query = userIds.join(',');
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/presence?userIds=$query');
    try {
      final response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
      if (response.statusCode != 200) return;
      final list = jsonDecode(response.body) as List<dynamic>;
      for (final item in list) {
        final data = item as Map<String, dynamic>;
        final userId = data['userId'] as int;
        _onlineStatus[userId] = data['online'] as bool? ?? false;
        final lastSeenRaw = data['lastSeenAt'] as String?;
        _lastSeenAt[userId] =
            lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null;
      }
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  void stopListening() {
    WebSocketService.instance.unsubscribe('/topic/presence');
    _subscribed = false;
    _onlineStatus.clear();
    _lastSeenAt.clear();
  }
}
