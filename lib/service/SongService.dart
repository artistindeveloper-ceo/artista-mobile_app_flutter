import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/ApiConfig.dart';
import '../config/Session.dart';
import 'ApiService.dart';

class Songservice {
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
// ─── GET MY SONGS ─────────────────────────────────────
  static Future<List<dynamic>> getMySongs() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/mine');
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
    if (response.statusCode != 200) return [];
    return body['data'] ?? body['content'] ?? body ?? [];
  }

// ─── ADD SONG ─────────────────────────────────────────
  static Future<void> addSong({
    required String title,
    String? artist,
    String? key,
    String? chords,
    String? lyrics,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs');
    try {
      await http.post(
        uri,
        headers: _authHeaders(),
        body: jsonEncode({
          'title': title,
          if (artist != null && artist.isNotEmpty) 'artist': artist,
          if (key != null && key.isNotEmpty) 'key': key,
          if (chords != null && chords.isNotEmpty) 'chords': chords,
          if (lyrics != null && lyrics.isNotEmpty) 'lyrics': lyrics,
        }),
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── GET PUBLIC SONGS (All songs from DB) ─────────────
  static Future<List<dynamic>> getPublicSongs() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/songs/public?page=0&size=100',
    );
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200) return [];
    final body = _safeDecode(response.body);
    // Swagger response mein "content" array hai
    return body['content'] ?? [];
  }
}
