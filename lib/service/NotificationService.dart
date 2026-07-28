import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import 'HelperService.dart';
import 'ApiClient.dart';
import 'dart:convert';
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─── GET NOTIFICATIONS ───────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final uri = Uri.parse(ApiConfig.notificationsUrl);
    http.Response response;
    try {
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      throw ApiException('Could not reach server.');
    }

    print('🔔 RAW NOTIFICATION RESPONSE: ${response.body}');

    final body = HelperService.safeDecode(response.body);
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
      response = await ApiClient.authorizedRequest(
          () => http.get(uri, headers: HelperService.authHeaders()));
    } catch (e) {
      return 0;
    }
    final body = HelperService.safeDecode(response.body);
    return body['count'] ?? body['unreadCount'] ?? body['data'] ?? 0;
  }

  // ─── MARK ALL READ ────────────────────────────────────────
  static Future<void> markAllNotificationsRead() async {
    final uri = Uri.parse(ApiConfig.markAllReadUrl);
    try {
      await ApiClient.authorizedRequest(
          () => http.post(uri, headers: HelperService.authHeaders()));
    } catch (_) {
      // Silent fail
    }
  }

  // ─── FCM: REQUEST PERMISSION ───────────────────────────────
  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 FCM Permission status: ${settings.authorizationStatus}');
  }

  // ─── FCM: GET DEVICE TOKEN ──────────────────────────────────
  static Future<String?> getDeviceToken() async {
    final token = await _messaging.getToken();
    print('🔔 FCM Token: $token');
    return token;
  }

  // ─── FCM: REGISTER TOKEN WITH BACKEND ───────────────────────
  static Future<void> registerDeviceToken() async {
    final token = await getDeviceToken();
    if (token == null) return;

    final uri = Uri.parse(ApiConfig.registerDeviceUrl);
    try {
      await ApiClient.authorizedRequest(
            () => http.post(
          uri,
          headers: {
            ...HelperService.authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fcmToken': token}),
        ),
      );
      print('✅ Device token registered with backend');
    } catch (e) {
      print('❌ Failed to register device token: $e');
    }
  }

  // ─── FCM: SETUP LISTENERS (foreground + tap) ────────────────
  static void setupListeners() {
    // App foreground mein ho aur notification aaye
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground notification: ${message.notification?.title}');
      // yahan apna in-app banner/snackbar dikha sakte ho
    });

    // User ne notification tap kiya aur app background se open hui
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped: ${message.data}');
      // yahan navigation logic daalo (jaise specific screen pe le jaana)
    });
  }

  // ─── FCM: FULL INIT (ek hi call mein sab) ───────────────────
  static Future<void> init() async {
    await requestPermission();
    await registerDeviceToken();
    setupListeners();
  }
}
