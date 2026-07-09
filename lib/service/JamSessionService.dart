import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';

import '../config/Session.dart';
import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

class JamSessionService {
  // ─── MY SESSIONS ─────────────────────────────────────────
  static Future<List<dynamic>> getMySessions() async {
    final uri = Uri.parse(ApiConfig.mySessionsUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load sessions.');
    }
    return body['data'] ?? body['content'] ?? body ?? [];
  }

  // ─── CREATE SESSION ──────────────────────────────────────
  static Future<void> createSession({
    required String name,
    String? description,
  }) async {
    final uri = Uri.parse(ApiConfig.createSessionUrl);
    try {
      await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode({
              'name': name,
              if (description != null && description.isNotEmpty)
                'description': description,
            }),
          ));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── JOIN SESSION ────────────────────────────────────────
  static Future<Map<String, dynamic>?> joinSession(String inviteCode) async {
    final uri = Uri.parse(ApiConfig.joinSessionUrl(inviteCode));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not join session.');
    }
    return body['data'] ?? body;
  }

// ─── GET SESSION BY ID ───────────────────────────────────
  static Future<Map<String, dynamic>> getSessionById(int id) async {
    final uri = Uri.parse(ApiConfig.sessionByIdUrl(id));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load session.');
    }
    return body['data'] ?? body;
  }

  // ─── GET PARTICIPANTS ────────────────────────────────────
  static Future<List<dynamic>> getSessionParticipants(int id) async {
    final uri = Uri.parse(ApiConfig.sessionParticipantsUrl(id));
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200) return [];

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded; // ✅ raw array case (aapka backend)
      if (decoded is Map<String, dynamic>) {
        return decoded['data'] ??
            decoded['content'] ??
            []; // wrapped-object case (agar future me badle)
      }
      return [];
    } catch (_) {
      return [];
    }
  }

// ─── START SESSION ───────────────────────────────────────
  static Future<void> startSession(int id) async {
    final uri = Uri.parse(ApiConfig.startSessionUrl(id));
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── END SESSION ─────────────────────────────────────────
  static Future<void> endSession(int id) async {
    final uri = Uri.parse(ApiConfig.endSessionUrl(id));
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── LEAVE SESSION ───────────────────────────────────────
  static Future<void> leaveSession(int id) async {
    final uri = Uri.parse(ApiConfig.leaveSessionUrl(id));
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  /// Full session detail — includes setlist[], currentSongId, currentTransposeOffset
  static Future<Map<String, dynamic>> getSessionDetail(int sessionId) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Failed to load session.');
    }
    return body;
  }

  /// Leader/Co-leader only — add a song to setlist
  static Future<Map<String, dynamic>> addSongToSetlist(
      int sessionId, int songId,
      {int? position}) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId/setlist');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode(
                {'songId': songId, if (position != null) 'position': position}),
          ));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Failed to add song.');
    }
    return body;
  }

  /// Leader/Co-leader only — remove a song from setlist
  static Future<void> removeSongFromSetlist(
      int sessionId, int jamSessionSongId) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId/setlist/$jamSessionSongId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.delete(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200) {
      final body = HelperService.safeDecode(response.body);
      throw ApiException(body['message'] ?? 'Failed to remove song.');
    }
  }

  /// Leader/Co-leader only — switch the active song (broadcasts SONG_CHANGED to all)
  static Future<Map<String, dynamic>> changeCurrentSong(
      int sessionId, int jamSessionSongId,
      {int? transposeOffset}) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId/current-song');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode({
              'jamSessionSongId': jamSessionSongId,
              if (transposeOffset != null) 'transposeOffset': transposeOffset,
            }),
          ));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Failed to change song.');
    }
    return body;
  }

  /// Leader/Co-leader only — transpose the active song
  static Future<Map<String, dynamic>> transpose(
      int sessionId, int transposeOffset) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId/transpose');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode({'transposeOffset': transposeOffset}),
          ));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Failed to transpose.');
    }
    return body;
  }

  // Naya delta-based method — sirf +1/-1 bhejta hai, current value client ko pata hone ki zaroorat nahi
  static Future<Map<String, dynamic>> transposeByDelta(
      int sessionId, int deltaSteps) async {
    final response = await ApiClient.authorizedRequest(() => http.post(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/jam-sessions/$sessionId/transpose/delta'),
          headers: HelperService.authHeaders(),
          body: jsonEncode({'deltaSteps': deltaSteps}),
        ));
    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Failed to transpose');
    }
    return jsonDecode(response.body);
  }
}
