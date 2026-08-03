import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/UserModel.dart';

import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

// ✅ NEW — follow/unfollow ka result wrap karta hai. Backend ab
// FollowActionResponse (status, following, followersCount) bhejta hai,
// isliye Flutter side manual +1/-1 karne ki bajaye seedha yahi
// canonical count use karta hai.
class FollowActionResult {
  final String status;
  final bool following;
  final int followersCount;

  FollowActionResult({
    required this.status,
    required this.following,
    required this.followersCount,
  });

  factory FollowActionResult.fromJson(Map<String, dynamic> json) {
    return FollowActionResult(
      status: json['status']?.toString() ?? '',
      following: json['following'] ?? false,
      followersCount: json['followersCount'] is int
          ? json['followersCount']
          : int.tryParse('${json['followersCount']}') ?? 0,
    );
  }
}

class FollowUserservice {
  // ─── FOLLOW USER ─────────────────────────────────────────
  // ✅ CHANGED: ab FollowActionResult return karta hai (status, following,
  // followersCount) — backend ka FollowActionResponse parse karke.
  static Future<FollowActionResult> followUser(int userId) async {
    final uri = Uri.parse(ApiConfig.followUserUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach server.');
    }

    final decoded = HelperService.safeDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Could not follow user.';
      throw ApiException(message);
    }

    if (decoded is Map) {
      return FollowActionResult.fromJson(Map<String, dynamic>.from(decoded));
    }
    throw ApiException('Unexpected response from server.');
  }

  // ─── UNFOLLOW USER ───────────────────────────────────────
  // ✅ CHANGED: ab FollowActionResult return karta hai (pehle void tha)
  static Future<FollowActionResult> unfollowUser(int userId) async {
    final uri = Uri.parse(ApiConfig.unfollowUserUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.delete(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach server.');
    }

    final decoded = HelperService.safeDecode(response.body);

    if (response.statusCode != 200) {
      final message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Could not unfollow user.';
      throw ApiException(message);
    }

    if (decoded is Map) {
      return FollowActionResult.fromJson(Map<String, dynamic>.from(decoded));
    }
    throw ApiException('Unexpected response from server.');
  }

  // ─── PENDING FOLLOW REQUESTS ─────────────────────────────
  static Future<List<dynamic>> getPendingFollowRequests() async {
    final uri = Uri.parse(ApiConfig.pendingRequestsUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
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
      if (e is ApiException) rethrow;
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
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach server.');
    }
  }

  // ─── GET FOLLOWERS LIST ──────────────────────────────────
  static Future<List<UserModel>> getFollowers(int userId) async {
    final uri = Uri.parse(ApiConfig.followersUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
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
  static Future<List<UserModel>> getFollowing(int userId) async {
    final uri = Uri.parse(ApiConfig.followingUrl(userId));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
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
