import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';

import 'HelperService.dart';

class FollowUserservice {
// ─── FOLLOW USER ─────────────────────────────────────────
  static Future<void> followUser(int userId) async {
    final uri = Uri.parse(ApiConfig.followUserUrl(userId));
    try {
      await http.post(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── UNFOLLOW USER ───────────────────────────────────────
  static Future<void> unfollowUser(int userId) async {
    final uri = Uri.parse(ApiConfig.unfollowUserUrl(userId));
    try {
      await http.delete(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── PENDING FOLLOW REQUESTS ─────────────────────────────
  static Future<List<dynamic>> getPendingFollowRequests() async {
    final uri = Uri.parse(ApiConfig.pendingRequestsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load requests.');
    }
    return body['data'] ?? body['content'] ?? [];
  }

// ─── ACCEPT FOLLOW REQUEST ───────────────────────────────
  static Future<void> acceptFollowRequest(int requestId) async {
    final uri = Uri.parse(ApiConfig.acceptRequestUrl(requestId));
    try {
      await http.post(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── REJECT FOLLOW REQUEST ───────────────────────────────
  static Future<void> rejectFollowRequest(int requestId) async {
    final uri = Uri.parse(ApiConfig.rejectRequestUrl(requestId));
    try {
      await http.post(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }
}
