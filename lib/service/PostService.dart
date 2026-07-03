import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/PostModel.dart';
import 'HelperService.dart';

class PostService {
  // ─── GET USER POSTS ──────────────────────────────────────
  static Future<List<PostModel>> getUserPosts(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/users/$userId');
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load posts.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── CREATE POST ──────────────────────────────────────────
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

  // ─── GET FEED ────────────────────────────────────────────
  static Future<List<PostModel>> getFeed({int page = 0}) async {
    final uri = Uri.parse('${ApiConfig.feedUrl}?page=$page&size=10');
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load feed.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? body ?? [];
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

// ─── LIKE / UNLIKE POST ──────────────────────────────────
  static Future<void> likePost(int postId) async {
    final uri = Uri.parse(ApiConfig.likePostUrl(postId));
    http.Response response;
    try {
      response = await http.post(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw ApiException('Failed to like post.');
    }
  }
}
