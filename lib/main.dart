import 'package:artist_in/service/NotificationService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/Session.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

// Yeh top-level function hona ZAROORI hai (kisi class ke andar nahi)
// Background/killed state mein notification aane par yeh call hota hai
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
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artist_in',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      // ✅ White background jab tak Flutter load ho
      color: Colors.white,
      home: const SplashScreen(),
    );
  }
}
