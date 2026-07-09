import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

class NotificationService {
// ─── GET NOTIFICATIONS ───────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final uri = Uri.parse(ApiConfig.notificationsUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('🔔 RAW NOTIFICATION RESPONSE: ${response.body}');

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load notifications.');
    }
    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list;
  }

// ─── UNREAD COUNT ─────────────────────────────────────────
  static Future<int> getUnreadCount() async {
    final uri = Uri.parse(ApiConfig.unreadCountUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      return 0;
    }
    final body = HelperService.safeDecode(response.body);
    return body['count'] ?? body['unreadCount'] ?? body['data'] ?? 0;
  }

// ─── MARK ALL READ ────────────────────────────────────────
  static Future<void> markAllNotificationsRead() async {
    final uri = Uri.parse(ApiConfig.markAllReadUrl);
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (_) {
      // Silent fail
    }
  }
}
