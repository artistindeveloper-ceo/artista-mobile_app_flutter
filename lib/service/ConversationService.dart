import 'dart:convert';

import 'package:artist_in/service/HelperService.dart';
import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';

class ConversationService {
  // ─── GET CONVERSATIONS ───────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final uri = Uri.parse(ApiConfig.conversationsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load conversations.');
    }

    // ✅ Add this debug line
    print('💬 CONVERSATIONS RAW: ${response.body}');

    return body['data'] ?? body['content'] ?? body ?? [];
  }

// ─── GET MESSAGES ────────────────────────────────────────
  static Future<List<dynamic>> getMessages(int conversationId) async {
    final uri = Uri.parse(ApiConfig.conversationMessagesUrl(conversationId));
    http.Response response;
    try {
      response = await http.get(uri, headers: HelperService.authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load messages.');
    }
    return body['data'] ?? body['content'] ?? body ?? [];
  }

// ─── SEND MESSAGE ────────────────────────────────────────
  static Future<void> sendMessage({
    required int recipientId, // ✅ conversationId → recipientId
    required String content,
  }) async {
    final uri = Uri.parse(ApiConfig.sendMessageUrl(recipientId)); // ✅ correct
    try {
      final response = await http.post(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode({'content': content}),
      );
      print('📤 SEND MSG status: ${response.statusCode}');
      print('📤 SEND MSG body: ${response.body}');
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── MARK AS READ ────────────────────────────────────────
  static Future<void> markAsRead(int conversationId) async {
    final uri = Uri.parse(ApiConfig.markReadUrl(conversationId));
    try {
      await http.post(uri, headers: HelperService.authHeaders());
    } catch (e) {
      // Silent fail
    }
  }

  // ─── START / FIND CONVERSATION WITH USER ─────────────────
  static Future<int> startConversation(int userId) async {
    // POST /api/v1/messages/users/{recipientId} — creates conversation
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/users/$userId');
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: HelperService.authHeaders(),
        body: jsonEncode(
            {'content': '👋'}), // sends a hi to open the conversation
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('🗨️ startConversation status: ${response.statusCode}');
    print('🗨️ startConversation body: ${response.body}');

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Could not start conversation.');
    }

    // Extract conversationId from response
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return (data['conversationId'] ?? data['id']) as int;
  }

  static Future<int> getTotalUnreadCount() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/unread-count');
    final response =
        await http.get(uri, headers: await HelperService.authHeaders());

    if (response.statusCode != 200) {
      throw ApiException('Could not fetch unread count.');
    }

    return int.parse(response.body.trim());
  }
}
