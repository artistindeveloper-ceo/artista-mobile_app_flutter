import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/Session.dart';
import '../model/PostModel.dart';
import '../config/ApiConfig.dart';
import '../service/ApiService.dart';

class PostService {
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

  // ─── GET USER POSTS ──────────────────────────────────────
  static Future<List<PostModel>> getUserPosts(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/users/$userId');
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load posts.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── CREATE POST ──────────────────────────────────────────
  // API: POST /api/v1/posts
  //   caption  → query param (string)
  //   media    → multipart file (optional)
  static Future<void> createPost({
    String? caption,
    File? mediaFile,
  }) async {
    final token = Session().token;
    if (token == null) throw ApiException('Not logged in.');

    // Build URI with caption as query param
    final uri = Uri.parse(ApiConfig.createPostUrl).replace(
      queryParameters: {
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    // Attach media file if selected
    if (mediaFile != null) {
      final ext = mediaFile.path.split('.').last.toLowerCase();
      final mimeType = ['mp4', 'mov', 'avi', 'mkv'].contains(ext)
          ? 'video/$ext'
          : 'image/$ext';

      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          // contentType: MediaType.parse(mimeType), // add mime package if needed
        ),
      );
    }

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException('Could not reach server. Check your connection.');
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException(body['message'] ?? 'Failed to create post.');
    }
  }
}
