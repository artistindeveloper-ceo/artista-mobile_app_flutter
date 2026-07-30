import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import '../utils/DeviceInfoHelper.dart';
import '../websocket/ChatSocketService.dart';
import 'HelperService.dart';
import 'ApiClient.dart';
import 'NotificationService.dart';
import 'PresenceService.dart';
import 'WebSocketService.dart';

class AuthService {
  // ─── LOGIN ──────────────────────────────────────────────────────
  static Future<UserModel> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConfig.loginUrl);

    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceDetails = await DeviceInfoHelper.getDeviceDetails();

    // iOS par abhi Push Notifications capability enable nahi hai
    // (paid Apple Developer account chahiye), isliye FCM token
    // maangna hi skip karo — warna APNS-token-not-set error aata hai
    final String? fcmToken =
        Platform.isIOS ? null : await FirebaseMessaging.instance.getToken();

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': emailOrMobile,
          'password': password,
          'deviceId': deviceId,
          'deviceType': deviceDetails['deviceType'],
          'deviceModel': deviceDetails['deviceModel'],
          'deviceOs': deviceDetails['deviceOs'],
          'fcmToken': fcmToken,
        }),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(body['message'] ?? 'Login failed. Please try again.');
    }

    final token = body['accessToken'] as String;
    final refreshTokenValue = body['refreshToken'] as String?;
    final userJson = body['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    Session().save(
      token: token,
      refreshToken: refreshTokenValue,
      userId: user.id,
      profilePhotoUrl: user.profilePhotoUrl,
      displayName: user.name,
    );

    await NotificationService.init();

    // ✅ Login successful — shared socket connect karo, uske upar
    // presence + chat dono subscribe honge.
    WebSocketService.instance.connect(token);
    PresenceService.instance.startListening();
    ChatSocketService().connect((message) {
      // TODO: unread badge update logic yahan call karein
      // e.g. ChatBadgeController.instance.onNewMessage(message);
    });

    return user;
  }

  // ─── REGISTER ───────────────────────────────────────────────────
  // Note: register auto-login nahi karta (session save nahi hoti).
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String accountType,
    String? professionalType,
    String? businessType,
    String? businessName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register');

    print('📤 Register URL: $uri');
    print(
        '📤 Register payload: username=${name.replaceAll(' ', '_').toLowerCase()}, '
        'email=$email, accountType=$accountType, professionalType=$professionalType, '
        'businessType=$businessType, businessName=$businessName');

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name.replaceAll(' ', '_').toLowerCase(),
          'displayName': name,
          'email': email,
          'password': password,
          'accountType': accountType,
          if (professionalType != null) 'professionalType': professionalType,
          if (businessType != null) 'businessType': businessType,
          if (businessName != null) 'businessName': businessName,
        }),
      );
      print('📥 Register status: ${response.statusCode}');
      print('📥 Register body: ${response.body}');
    } catch (e, stack) {
      print('❌ Register network/exception error: $e');
      print('❌ Stack: $stack');
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Registration failed.');
    }
  }

  // ─── CHANGE PASSWORD (POST /api/v1/users/me/password) ───────────
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse(ApiConfig.changePasswordUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(() => http.post(
            uri,
            headers: HelperService.authHeaders(),
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          ));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Could not reach server. Check your internet connection.');
    }

    final body = HelperService.safeDecode(response.body);
    if (response.statusCode != 200 || body['success'] == false) {
      throw ApiException(body['message'] ?? 'Password change failed.');
    }
  }

  // ─── REFRESH TOKEN ──────────────────────────────────────
  static Future<bool> refreshAccessToken() async {
    final oldRefreshToken = Session().refreshToken;
    if (oldRefreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': oldRefreshToken}),
      );

      if (response.statusCode == 200) {
        final body = HelperService.safeDecode(response.body);
        final newAccessToken = body['accessToken'] as String;
        final newRefreshToken = body['refreshToken'] as String?;

        await Session().updateAccessToken(
          newAccessToken,
          newRefreshToken: newRefreshToken,
        );

        // Access token badal gaya — WebSocket connection purane token se
        // bani thi, isliye use bhi naye token ke saath reconnect karo warna
        // agli baar socket drop hone par reconnect galat/expired token
        // bhejega. Presence + chat dono ko naye socket par resubscribe
        // karo (dono services internally isConnected check karte hain
        // isliye yeh safe hai).
        WebSocketService.instance.disconnect();
        WebSocketService.instance.connect(newAccessToken);
        PresenceService.instance.startListening();
        ChatSocketService().connect((message) {
          // TODO: unread badge update logic yahan call karein
          // e.g. ChatBadgeController.instance.onNewMessage(message);
        });

        return true;
      }
      return false;
    } catch (e) {
      if (e is ApiException) rethrow;
      return false;
    }
  }

  // ─── LOGOUT ─────────────────────────────────────────────
  static Future<void> logout() async {
    final refreshToken = Session().refreshToken;

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // ignore, local clear to hoga hi
    }

    // iOS par push notifications configured nahi hai, isliye
    // deleteToken() call karne ki zaroorat nahi (token bana hi nahi)
    if (!Platform.isIOS) {
      await FirebaseMessaging.instance.deleteToken();
    }

    // ✅ Logout hote hi presence + chat + socket sab band karo — warna
    // server side hume galat se "online" dikhata rahega jab tak socket
    // timeout na ho.
    PresenceService.instance.stopListening();
    ChatSocketService().disconnect();
    WebSocketService.instance.disconnect();

    await Session().clear();
  }

  // ─── FCM TOKEN SYNC (device.register endpoint) ───────────
  static Future<void> syncFcmToken(String newFcmToken) async {
    if (!Session().isLoggedIn) return;

    try {
      final deviceId = await DeviceInfoHelper.getDeviceId();
      await ApiClient.authorizedRequest(() => http.post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/device/register'),
            headers: HelperService.authHeaders(),
            body: jsonEncode({
              'deviceId': deviceId,
              'fcmToken': newFcmToken,
            }),
          ));
    } catch (e) {
      if (e is ApiException) rethrow;
      // silent fail — agla app-open pe retry ho jayega
    }
  }
}
