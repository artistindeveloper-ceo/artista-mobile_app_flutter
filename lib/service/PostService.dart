import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/PostModel.dart';
import 'HelperService.dart';
import 'ApiClient.dart'; // ← NAYA IMPORT
import 'MediaUploadService.dart';

class PostService {
  // ─── GET USER POSTS ──────────────────────────────────────
  static Future<List<PostModel>> getUserPosts(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/users/$userId');
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
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

  // ─── CREATE POST (presigned S3 upload) ────────────────────
  static Future<void> createPost({
    String? caption,
    File? mediaFile,
    bool isVideo = false,
  }) async {
    String? mediaKey;
    String mediaType = 'NONE';

    if (mediaFile != null) {
      final result = await MediaUploadService.uploadFile(
        mediaFile,
        mediaType: 'post',
        isVideo: isVideo,
      );
      mediaKey = result.key;
      mediaType = isVideo ? 'VIDEO' : 'IMAGE';
    }

    final uri = Uri.parse(ApiConfig.createPostUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
        () => http.post(
          uri,
          headers: {
            ...HelperService.authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'caption': caption,
            'mediaKey': mediaKey,
            'mediaType': mediaType,
          }),
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach server. Check your connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
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
      if (e is ApiException) rethrow;
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
      if (e is ApiException) rethrow;
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
      if (e is ApiException) rethrow;
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

  // ─── REGISTER VIEW (video ke liye) ───────────────────────
  static Future<void> registerView(int postId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/$postId/view');
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      if (e is ApiException) rethrow;
      // Silent fail — view count fail hone se user experience break nahi hona chahiye
    }
  }
}
