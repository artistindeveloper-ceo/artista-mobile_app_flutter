import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import 'HelperService.dart';

class SongService {
// ─── GET MY SONGS ─────────────────────────────────────
  static Future<List<dynamic>> getMySongs() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/mine');
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
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
        headers: HelperService.authHeaders(),
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
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200) return [];
    final body = HelperService.safeDecode(response.body);
    // Swagger response mein "content" array hai
    return body['content'] ?? [];
  }

  // ─── GET SONG BY ID (full details incl. lyricsWithChords) ─
  static Future<Map<String, dynamic>> getSongById(int songId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/$songId');
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Song not found.');
    }
    return body['data'] ?? body;
  }
}
