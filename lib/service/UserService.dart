import 'dart:convert';

import 'package:artist_in/service/HelperService.dart';
import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../model/UserModel.dart';

class UserService {
  // ─── GET CURRENT USER (GET /api/v1/users/me) ────────────────────
  static Future<UserModel> getMe() async {
    final uri = Uri.parse(ApiConfig.getMeUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Could not load profile.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── GET USER BY USERNAME (GET /api/v1/users/{username}) ────────
  static Future<UserModel> getUserByUsername(String username) async {
    final uri = Uri.parse(ApiConfig.userByUsernameUrl(username));
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'User not found.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── UPDATE PROFILE (PUT /api/v1/users/me) ──────────────────────
  static Future<UserModel> updateMe({
    required String name,
    String? username,
    String? bio,
  }) async {
    final uri = Uri.parse(ApiConfig.updateMeUrl);
    http.Response response;
    try {
      response = await http.put(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode({
          'name': name,
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Profile update failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── UPDATE PRIVACY ONLY (PUT /api/v1/users/me) ─────────────────
  // ✅ NEW — separate lightweight call so Settings screen doesn't need
  // to resend name/username/bio just to toggle the privacy switch.
  // Backend's UpdateProfileRequest only touches fields that are
  // non-null, so sending just {"isPrivate": ...} is safe.
  static Future<UserModel> updatePrivacy(bool isPrivate) async {
    final uri = Uri.parse(ApiConfig.updateMeUrl);
    http.Response response;
    try {
      response = await http.put(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode({'isPrivate': isPrivate}),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(
          body['message'] ?? 'Could not update privacy setting.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── GET ALL USERS (Discover) ─────────────────────────
  static Future<List<UserModel>> getAllUsers() async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/community/users/discover?page=0&size=20');

    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load users.');
    }

    final List<dynamic> list = body['content'] ?? [];
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── SEARCH USERS (GET /api/v1/users/search?query=) ─────────────
  static Future<List<UserModel>> searchUsers(String query,
      {int page = 0, int size = 20}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/search?query=${Uri.encodeQueryComponent(query)}&page=$page&size=$size');

    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Search failed.');
    }

    final List<dynamic> list = body['content'] ?? [];
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
