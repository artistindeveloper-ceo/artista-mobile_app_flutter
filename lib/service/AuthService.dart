import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/ApiConfig.dart';
import '../config/Session.dart';
import 'ApiService.dart';

class AuthService {
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

  // ─── REGISTER ───────────────────────────────────────────
  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register');
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name.replaceAll(' ', '_').toLowerCase(),
          // "Ashvini Khare" → "ashvini_khare"
          'displayName': name,
          // "Ashvini Khare" (shown in UI)
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Registration failed.');
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Session().token}',
        // adjust if your Session stores it differently
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String message = 'Failed to update password';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = body['message'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
