import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        title: const Text('Edit Profile'),
      ),
      body: const Center(child: Text('Profile fields go here')),
    );
  }
}