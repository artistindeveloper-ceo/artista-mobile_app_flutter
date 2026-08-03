import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/UserModel.dart';
import '../screens/auth/GoogleAuthResult.dart';
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
      accountType: user.accountType,
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

  // ─── GOOGLE SIGN-IN (STEP 1) ──────────────────────────────────────
  // Google se idToken lekar backend ke /auth/google endpoint ko bhejte
  // hain. Backend do cases return kar sakta hai:
  //   1. LOGIN_SUCCESS  -> user pehle se registered hai, seedha login
  //      (session save + socket connect yahin kar dete hain)
  //   2. SIGNUP_REQUIRED -> naya Google user hai, account type + category
  //      abhi tak nahi bhara — caller ko signupToken/email/name milega,
  //      jisse GoogleCompleteRegistrationScreen khulegi.
  static Future<GoogleAuthResult> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      // Web Client ID — Google Cloud Console me "Web application" type
      // OAuth client se liya hua, Android client ID nahi.
      serverClientId:
          '401598862863-n171u0e51di4qaddo9o5btlggi75sphm.apps.googleusercontent.com',
    );

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      throw ApiException('Google sign-in failed. Please try again.');
    }

    if (googleUser == null) {
      // User ne cancel kar diya picker se
      throw ApiException('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw ApiException('Could not get Google credentials. Please try again.');
    }

    final uri = Uri.parse(ApiConfig.googleLoginUrl);

    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceDetails = await DeviceInfoHelper.getDeviceDetails();
    final String? fcmToken =
        Platform.isIOS ? null : await FirebaseMessaging.instance.getToken();

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
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
      throw ApiException(
          body['message'] ?? 'Google sign-in failed. Please try again.');
    }

    final status = body['status'] as String?;

    // ── Case 1: naya user, account type/category abhi choose karni hai ──
    if (status == 'SIGNUP_REQUIRED') {
      return GoogleAuthResult.signupRequired(
        signupToken: body['signupToken'] as String,
        email: body['email'] as String?,
        name: body['name'] as String?,
      );
    }

    // ── Case 2: existing user, seedha login ──
    final authJson = body['auth'] as Map<String, dynamic>;
    final token = authJson['accessToken'] as String;
    final refreshTokenValue = authJson['refreshToken'] as String?;
    final userJson = authJson['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    Session().save(
      token: token,
      refreshToken: refreshTokenValue,
      userId: user.id,
      profilePhotoUrl: user.profilePhotoUrl,
      displayName: user.name,
      accountType: user.accountType,
    );

    await NotificationService.init();

    WebSocketService.instance.connect(token);
    PresenceService.instance.startListening();
    ChatSocketService().connect((message) {
      // TODO: unread badge update logic yahan call karein
    });

    return GoogleAuthResult.loginSuccess(user);
  }

  // ─── GOOGLE SIGN-IN (STEP 2) — COMPLETE REGISTRATION ──────────────
  // SIGNUP_REQUIRED aane ke baad, GoogleCompleteRegistrationScreen se
  // account type + category (+ business name agar business hai) select
  // karke ye call hota hai. Success pe seedha login ho jata hai
  // (session save + socket connect), normal register() ke ulat.
  static Future<UserModel> completeGoogleRegistration({
    required String signupToken,
    required String accountType,
    String? professionalType,
    String? businessType,
    String? businessName,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/auth/google/complete-registration');

    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceDetails = await DeviceInfoHelper.getDeviceDetails();
    final String? fcmToken =
        Platform.isIOS ? null : await FirebaseMessaging.instance.getToken();

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'signupToken': signupToken,
          'accountType': accountType,
          if (professionalType != null) 'professionalType': professionalType,
          if (businessType != null) 'businessType': businessType,
          if (businessName != null) 'businessName': businessName,
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

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(body['message'] ?? 'Registration failed.');
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
      accountType: user.accountType,
    );

    await NotificationService.init();

    WebSocketService.instance.connect(token);
    PresenceService.instance.startListening();
    ChatSocketService().connect((message) {
      // TODO: unread badge update logic yahan call karein
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
    } catch (e) {
      if (e is ApiException) rethrow;
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

        WebSocketService.instance.disconnect();
        WebSocketService.instance.connect(newAccessToken);
        PresenceService.instance.startListening();
        ChatSocketService().connect((message) {
          // TODO: unread badge update logic yahan call karein
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

    if (!Platform.isIOS) {
      await FirebaseMessaging.instance.deleteToken();
    }

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
