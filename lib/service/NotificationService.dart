import 'dart:convert';
import 'dart:io' show Platform;
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
      if (e is ApiException) rethrow;
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
      if (e is ApiException) rethrow;
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
    // iOS par push notification permission maangne ki zaroorat nahi
    // (paid Apple Developer account / Push Notifications capability
    // abhi enable nahi hai, isliye iOS ke liye poora FCM flow skip)
    if (Platform.isIOS) {
      print(
          '🔕 iOS: Push notification permission skipped (not configured yet)');
      return;
    }

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 FCM Permission status: ${settings.authorizationStatus}');
  }

  // ─── FCM: GET DEVICE TOKEN ──────────────────────────────────
  static Future<String?> getDeviceToken() async {
    // iOS par abhi Push Notifications capability enable nahi hai
    // (Apple Developer paid account chahiye), isliye seedha null return
    // karo taaki login/app normally chale, sirf push notification na aaye
    if (Platform.isIOS) {
      print(
          '🔕 iOS: FCM token fetch skipped (Push Notifications not configured)');
      return null;
    }

    await requestPermission();

    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("APNS Token: $apnsToken");

    if (apnsToken == null) {
      print("APNS token not available yet.");
      return null;
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $fcmToken");

    return fcmToken;
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
      if (e is ApiException) rethrow;
      print('❌ Failed to register device token: $e');
    }
  }

// ─── CREATE ANDROID NOTIFICATION CHANNEL ───────────────────
  static Future<void> _createNotificationChannel() async {
    if (Platform.isIOS) return; // Android-only feature

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
    // iOS par abhi push notifications configured nahi hai,
    // isliye FCM listeners register hi mat karo
    if (Platform.isIOS) {
      print('🔕 iOS: FCM listeners skipped (not configured)');
      return;
    }

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

    // 🔴 background me FCM token refresh hone par backend update karo
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
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    if (Platform.isIOS) {
      // iOS ke liye push notification setup poora skip —
      // sirf normal login/app flow chalne do
      print('🔕 iOS: NotificationService.init() — push setup skipped');
      return;
    }

    await _createNotificationChannel();
    await requestPermission();
    await registerDeviceToken();
    setupListeners();
  }
}
