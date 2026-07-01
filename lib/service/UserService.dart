import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class UserService {
  // ─── Auth Headers ──────────────────────────────────────
  static Map<String, String> _authHeaders() {
    final token = Session().token;
    if (token == null)
      throw ApiException('Not logged in. Please log in again.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Safe Decode ───────────────────────────────────────
  static Map<String, dynamic> _safeDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

// ─── GET ALL USERS (Discover) ─────────────────────────
  static Future<List<UserModel>> getAllUsers() async {
    // ✅ Correct URL matching your backend
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/community/users/discover?page=0&size=20');

    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('Discover → ${response.statusCode}: ${response.body}'); // debug

    final body = _safeDecode(response.body);
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
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('Search → ${response.statusCode}: ${response.body}'); // debug

    final body = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Search failed.');
    }

    final List<dynamic> list = body['content'] ?? []; // ✅ correct key
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
