import 'package:artist_in/service/NotificationService.dart';
import 'package:artist_in/service/PresenceService.dart';
import 'package:artist_in/service/WebSocketService.dart';
import 'package:artist_in/websocket/ChatSocketService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/Session.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Session().load();

  if (Session().isLoggedIn) {
    await NotificationService.init();
    _connectRealtime();
  }

  runApp(const MyApp());
}

/// Single entry point for bringing up the shared socket + everything
/// that rides on top of it. Call this on app start (if already logged
/// in) AND right after a fresh login.
void _connectRealtime() {
  final token = Session().token;
  if (token == null) return;

  WebSocketService.instance.connect(token);
  PresenceService.instance.startListening();
  ChatSocketService().connect((message) {
    // TODO: unread badge update logic yahan call karein
    // e.g. ChatBadgeController.instance.onNewMessage(message);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App background se wapas aaya aur socket OS ne kill kar diya tha
    if (state == AppLifecycleState.resumed &&
        Session().isLoggedIn &&
        !WebSocketService.instance.isConnected) {
      _connectRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artist_in',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      color: Colors.white,
      home: const SplashScreen(),
    );
  }
}
