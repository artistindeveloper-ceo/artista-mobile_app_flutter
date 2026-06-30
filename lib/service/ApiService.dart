import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/PostModel.dart';
import '../model/UserModel.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // ─── Auth Headers ───────────────────────────────────────────────
  static Map<String, String> _authHeaders() {
    final token = Session().token;
    if (token == null)
      throw ApiException('Not logged in. Please log in again.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── LOGIN ──────────────────────────────────────────────────────
  static Future<UserModel> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConfig.loginUrl);
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': emailOrMobile, // ← 'email' → 'usernameOrEmail'
          'password': password,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);

    // Backend direct response deta hai, 'success' field nahi hai
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Login failed. Please try again.');
    }

    // Swagger se: accessToken aur user direct root mein hain
    final token = body['accessToken'] as String;
    final userJson = body['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    Session().save(
      token: token,
      userId: user.id,
      profilePhotoUrl: user.profilePhotoUrl,
      displayName: user.name,
    );
    return user;
  }

  // ─── GET CURRENT USER (GET /api/v1/users/me) ────────────────────
  static Future<UserModel> getMe() async {
    final uri = Uri.parse(ApiConfig.getMeUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Could not load profile.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    // ← THESE 3 LINES — make sure all 3 are there
    print('RAW avatarUrl: ${userJson['avatarUrl']}');
    print('RAW coverPhotoUrl: ${userJson['coverPhotoUrl']}');
    print('FULL USER JSON: $userJson');
    return UserModel.fromJson(userJson);
  }

  // ─── GET USER BY USERNAME (GET /api/v1/users/{username}) ────────
  static Future<UserModel> getUserByUsername(String username) async {
    final uri = Uri.parse(ApiConfig.userByUsernameUrl(username));
    print("🌐 getUserByUsername URL: $uri"); // add this
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print("📡 Status: ${response.statusCode}");
    print("📡 Body: ${response.body}"); // add this

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'User not found.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── SEARCH USERS (GET /api/v1/users/search?q=) ─────────────────
  static Future<List<UserModel>> searchUsers(String query) async {
    final uri = Uri.parse(
        '${ApiConfig.searchUsersUrl}?q=${Uri.encodeComponent(query)}');
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Search failed.');
    }

    final List<dynamic> list = body['data'] ?? [];
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── UPDATE PROFILE (PUT /api/v1/users/me) ──────────────────────
  static Future<UserModel> updateMe({
    required String name,
    String? username,
    String? bio,
  }) async {
    final uri = Uri.parse(ApiConfig.updateMeUrl);
    http.Response response;
    try {
      response = await http.put(
        uri,
        headers: _authHeaders(),
        body: jsonEncode({
          'name': name,
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Profile update failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── CHANGE PASSWORD (POST /api/v1/users/me/password) ───────────
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse(ApiConfig.changePasswordUrl);
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: _authHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Password change failed.');
    }
  }

  // ─── UPLOAD PROFILE PHOTO (POST /api/v1/users/me/profile-photo) ─
  static Future<UserModel> uploadProfilePhoto(File imageFile) async {
    final token = Session().token;
    if (token == null) throw ApiException('Not logged in.');

    final uri = Uri.parse(ApiConfig.uploadProfilePhotoUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final response = await http.Response.fromStream(streamed);
    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── UPLOAD COVER PHOTO (POST /api/v1/users/me/cover-photo) ─────
  static Future<UserModel> uploadCoverPhoto(File imageFile) async {
    final token = Session().token;
    if (token == null) throw ApiException('Not logged in.');

    final uri = Uri.parse(ApiConfig.uploadCoverPhotoUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final response = await http.Response.fromStream(streamed);
    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Cover photo upload failed.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── OLD METHOD (backward compat) ───────────────────────────────
  static Future<UserModel> getUserById(int id) async {
    final uri = Uri.parse(ApiConfig.userByIdUrl(id));
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server. Check your internet connection.');
    }

    print('getUserById status: ${response.statusCode}');
    print('getUserById body: ${response.body}');

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Could not load profile.');
    }

    final userJson = (body['data'] ?? body) as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  // ─── HELPER ─────────────────────────────────────────────────────
  static Map<String, dynamic> _safeDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

// ─── GET FEED ────────────────────────────────────────────
  static Future<List<PostModel>> getFeed({int page = 0}) async {
    final uri = Uri.parse('${ApiConfig.feedUrl}?page=$page&size=10');
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = _safeDecode(response.body);
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
      response = await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw ApiException('Failed to like post.');
    }
  }

// ─── GET COMMENTS ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final uri = Uri.parse(ApiConfig.postCommentsUrl(postId));
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    final body = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load comments.');
    }

    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

// ─── ADD COMMENT ─────────────────────────────────────────
  static Future<void> addComment(int postId, String text) async {
    final uri = Uri.parse(ApiConfig.postCommentsUrl(postId));
    try {
      await http.post(
        uri,
        headers: _authHeaders(),
        body: jsonEncode({'content': text}),
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── FOLLOW USER ─────────────────────────────────────────
  static Future<void> followUser(int userId) async {
    final uri = Uri.parse(ApiConfig.followUserUrl(userId));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── UNFOLLOW USER ───────────────────────────────────────
  static Future<void> unfollowUser(int userId) async {
    final uri = Uri.parse(ApiConfig.unfollowUserUrl(userId));
    try {
      await http.delete(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── PENDING FOLLOW REQUESTS ─────────────────────────────
  static Future<List<dynamic>> getPendingFollowRequests() async {
    final uri = Uri.parse(ApiConfig.pendingRequestsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load requests.');
    }
    return body['data'] ?? body['content'] ?? [];
  }

// ─── ACCEPT FOLLOW REQUEST ───────────────────────────────
  static Future<void> acceptFollowRequest(int requestId) async {
    final uri = Uri.parse(ApiConfig.acceptRequestUrl(requestId));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── REJECT FOLLOW REQUEST ───────────────────────────────
  static Future<void> rejectFollowRequest(int requestId) async {
    final uri = Uri.parse(ApiConfig.rejectRequestUrl(requestId));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

  // ─── GET CONVERSATIONS ───────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final uri = Uri.parse(ApiConfig.conversationsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
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
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
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
        headers: _authHeaders(),
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
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      // Silent fail
    }
  }

  // ─── GET NOTIFICATIONS ───────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final uri = Uri.parse(ApiConfig.notificationsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('🔔 RAW NOTIFICATION RESPONSE: ${response.body}');

    final body = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Could not load notifications.');
    }
    final List<dynamic> list = body['content'] ?? body['data'] ?? [];
    return list;
  }

// ─── UNREAD COUNT ─────────────────────────────────────────
  static Future<int> getUnreadCount() async {
    final uri = Uri.parse(ApiConfig.unreadCountUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      return 0;
    }
    final body = _safeDecode(response.body);
    return body['count'] ?? body['unreadCount'] ?? body['data'] ?? 0;
  }

// ─── MARK ALL READ ────────────────────────────────────────
  static Future<void> markAllNotificationsRead() async {
    final uri = Uri.parse(ApiConfig.markAllReadUrl);
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (_) {
      // Silent fail
    }
  }

  //-----------------------------------Jam-----------------------------------------
// ─── MY SESSIONS ─────────────────────────────────────────
  static Future<List<dynamic>> getMySessions() async {
    final uri = Uri.parse(ApiConfig.mySessionsUrl);
    http.Response response;
    try {
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
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
      await http.post(
        uri,
        headers: _authHeaders(),
        body: jsonEncode({
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── JOIN SESSION ────────────────────────────────────────
  static Future<Map<String, dynamic>?> joinSession(String inviteCode) async {
    final uri = Uri.parse(ApiConfig.joinSessionUrl(inviteCode));
    http.Response response;
    try {
      response = await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
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
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
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
      response = await http.get(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
    final body = _safeDecode(response.body);
    if (response.statusCode != 200) return [];
    return body['data'] ?? body['content'] ?? body ?? [];
  }

// ─── START SESSION ───────────────────────────────────────
  static Future<void> startSession(int id) async {
    final uri = Uri.parse(ApiConfig.startSessionUrl(id));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── END SESSION ─────────────────────────────────────────
  static Future<void> endSession(int id) async {
    final uri = Uri.parse(ApiConfig.endSessionUrl(id));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
    }
  }

// ─── LEAVE SESSION ───────────────────────────────────────
  static Future<void> leaveSession(int id) async {
    final uri = Uri.parse(ApiConfig.leaveSessionUrl(id));
    try {
      await http.post(uri, headers: _authHeaders());
    } catch (e) {
      throw ApiException('Could not reach server.');
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
        headers: _authHeaders(),
        body: jsonEncode({'content': '👋'}), // sends a hi to open the conversation
      );
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('🗨️ startConversation status: ${response.statusCode}');
    print('🗨️ startConversation body: ${response.body}');

    final body = _safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Could not start conversation.');
    }

    // Extract conversationId from response
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return (data['conversationId'] ?? data['id']) as int;
  }
}
