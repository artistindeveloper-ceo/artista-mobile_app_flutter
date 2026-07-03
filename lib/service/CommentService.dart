import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import 'HelperService.dart';

class CommentService {
  // ─── ADD COMMENT ─────────────────────────────────────────
  static Future<void> addComment(int postId, String text) async {
    final uri = Uri.parse(ApiConfig.postCommentsUrl(postId));
    try {
      await http.post(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode({'content': text}),
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── GET COMMENTS ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final uri = Uri.parse(ApiConfig.postCommentsUrl(postId));
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load comments.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
