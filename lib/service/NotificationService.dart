import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Exception/ApiException.dart';
import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../utils/DeviceInfoHelper.dart';
import 'HelperService.dart';
import 'ApiClient.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
  // deviceId zaroori hai ab — backend isi se decide karta hai
  // kis LoginDevice row ka fcmToken update karna hai.
  static Future<void> registerDeviceToken() async {
    if (!Session().isLoggedIn) return;

    final token = await getDeviceToken();
    if (token == null) return;

    final deviceId = await DeviceInfoHelper.getDeviceId();
    final uri = Uri.parse(ApiConfig.registerDeviceUrl);
    try {
      await ApiClient.authorizedRequest(
        () => http.post(
          uri,
          headers: {
            ...HelperService.authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'deviceId': deviceId,
            'fcmToken': token,
          }),
        ),
      );
      print('✅ Device token registered with backend');
    } catch (e) {
      print('❌ Failed to register device token: $e');
    }
  }

// ─── CREATE ANDROID NOTIFICATION CHANNEL ───────────────────
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Ye channel important notifications ke liye hai.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─── SHOW LOCAL NOTIFICATION (foreground ke liye) ───────────
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  // ─── FCM: SETUP LISTENERS (foreground + tap + token refresh) ────
  static void setupListeners() {
    // App foreground mein ho aur notification aaye
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // User ne notification tap kiya aur app background se open hui
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped: ${message.data}');
      // yahan navigation logic daalo (jaise specific screen pe le jaana)
    });

    // 🔴 YE NAYA HAI — background me FCM token refresh hone par backend update karo
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔔 FCM token refreshed, syncing with backend');
      registerDeviceToken();
    });
  }

  // ─── FCM: FULL INIT (ek hi call mein sab) ───────────────────
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    await _createNotificationChannel();
    await requestPermission();
    await registerDeviceToken();
    setupListeners();
  }
}
