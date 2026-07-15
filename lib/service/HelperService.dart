import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Exception/ApiException.dart';
import '../config/Session.dart';
import '../screens/auth/login_screen.dart';

class HelperService {
  // ─── HELPER ─────────────────────────────────────────────────────
  static Map<String, dynamic> safeDecode(String raw) {
    // no underscore
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  // ─── Auth Headers ───────────────────────────────────────────────
  static Map<String, String> authHeaders() {
    final token = Session().token;
    if (token == null) {
      throw ApiException('Not logged in. Please log in again.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Global Auth Error Handler ───────────────────────────
  static bool isAuthError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('unauthenticated') ||
        msg.contains('unauthorized') ||
        msg.contains('not logged in') ||
        msg.contains('security context') ||
        msg.contains('401') ||
        msg.contains('403');
  }

  static Future<void> forceLogout(BuildContext context) async {
    await Session().clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
