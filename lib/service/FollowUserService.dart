import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/UserModel.dart';

import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

class FollowUserservice {
  // ─── FOLLOW USER ─────────────────────────────────────────
  // ✅ CHANGED: now returns the backend status string so the UI can show
  // the correct state — "FOLLOWING", "REQUEST_PENDING", or "ALREADY_FOLLOWING".
  static Future<String> followUser(int userId) async {
    final uri = Uri.parse(ApiConfig.followUserUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Could not follow user.';
      try {
        final body = HelperService.safeDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }
      } catch (_) {}
      throw ApiException(message);
    }

    final raw = response.body.trim();
    if (raw.isEmpty) return 'FOLLOWING'; // fallback if backend sends empty 200

    // Backend may return a plain string ("REQUEST_PENDING") or JSON
    // wrapped like {"data":"REQUEST_PENDING"}. Handle both.
    try {
      final decoded = HelperService.safeDecode(raw);
      if (decoded is Map && decoded['data'] != null) {
        return decoded['data'].toString();
      }
    } catch (_) {
      // not JSON — it's a plain string body
    }
    return raw.replaceAll('"', '');
  }

  // ─── UNFOLLOW USER ───────────────────────────────────────
  static Future<void> unfollowUser(int userId) async {
    final uri = Uri.parse(ApiConfig.unfollowUserUrl(userId));
    try {
      await ApiClient.authorizedRequest(
          () => http.delete(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── PENDING FOLLOW REQUESTS ─────────────────────────────
  static Future<List<dynamic>> getPendingFollowRequests() async {
    final uri = Uri.parse(ApiConfig.pendingRequestsUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
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
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── REJECT FOLLOW REQUEST ───────────────────────────────
  static Future<void> rejectFollowRequest(int requestId) async {
    final uri = Uri.parse(ApiConfig.rejectRequestUrl(requestId));
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── GET FOLLOWERS LIST ──────────────────────────────────
  // ✅ NEW — used by the Instagram-style Followers/Following screen.
  static Future<List<UserModel>> getFollowers(int userId) async {
    final uri = Uri.parse(ApiConfig.followersUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final decoded = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      final message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Could not load followers.';
      throw ApiException(message);
    }

    final List<dynamic> list = decoded is Map
        ? (decoded['data'] ?? decoded['content'] ?? [])
        : (decoded is List ? decoded : []);
    return list
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── GET FOLLOWING LIST ──────────────────────────────────
  // ✅ NEW
  static Future<List<UserModel>> getFollowing(int userId) async {
    final uri = Uri.parse(ApiConfig.followingUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final decoded = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      final message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Could not load following.';
      throw ApiException(message);
    }

    final List<dynamic> list = decoded is Map
        ? (decoded['data'] ?? decoded['content'] ?? [])
        : (decoded is List ? decoded : []);
    return list
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
