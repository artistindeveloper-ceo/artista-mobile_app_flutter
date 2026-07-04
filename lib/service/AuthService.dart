import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import 'HelperService.dart';

class AuthService {
  // ─── LOGIN ──────────────────────────────────────────────────────
  static Future<UserModel> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConfig.loginUrl);
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': emailOrMobile, // ← 'email' → 'usernameOrEmail'
          'password': password,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);

    // Backend direct response deta hai, 'success' field nahi hai
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Login failed. Please try again.');
    }

    // Swagger se: accessToken aur user direct root mein hain
    final token = body['accessToken'] as String;
    final userJson = body['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    Session().save(
      token: token,
      userId: user.id,
      profilePhotoUrl: user.profilePhotoUrl,
      displayName: user.name,
    );
    return user;
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
          'displayName': name,
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Registration failed.');
    }
  }

  // ─── CHANGE PASSWORD (POST /api/v1/users/me/password) ───────────
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse(ApiConfig.changePasswordUrl);
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Password change failed.');
    }
  }
}
