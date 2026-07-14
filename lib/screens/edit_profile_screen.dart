import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        // backgroundColor / foregroundColor / titleTextStyle inherited
        // from AppTheme.theme.appBarTheme (gold Playfair Display title).
      ),
      body: Center(
        child: Text(
          'Profile fields go here',
          style: AppFonts.body(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
