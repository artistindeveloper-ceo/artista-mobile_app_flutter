import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/PostModel.dart';
import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT

class PostService {
  // ─── GET USER POSTS ──────────────────────────────────────
  static Future<List<PostModel>> getUserPosts(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/users/$userId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
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
    final uri = Uri.parse(ApiConfig.createPostUrl).replace(
      queryParameters: {
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    );

    // Multipart request ko ek function mein wrap kiya taki ApiClient
    // ise retry kar sake (401 aane par) — Bearer token hamesha fresh
    // Session().token se uthaya jayega, refresh ke baad bhi
    Future<http.Response> sendMultipart() async {
      final token = Session().token;
      if (token == null) throw ApiException('Not logged in.');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      if (mediaFile != null) {
        final ext = mediaFile.path.split('.').last.toLowerCase();
        // mimeType filhal use nahi ho raha, future mime package ke liye rakha hai

        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            mediaFile.path,
            // contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(sendMultipart);
    } catch (e) {
      throw ApiException('Could not reach server. Check your connection.');
    }

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
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
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
      response = await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw ApiException('Failed to like post.');
    }
  }

  // ─── GET EXPLORE ─────────────────────────────────────────
  static Future<List<PostModel>> getExplore({int page = 0}) async {
    final uri = Uri.parse('${ApiConfig.exploreUrl}?page=$page&size=10');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load explore feed.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? body ?? [];
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
