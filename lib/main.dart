import 'package:flutter/material.dart';
import 'config/Session.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session().load();
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