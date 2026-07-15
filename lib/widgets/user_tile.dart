import 'package:flutter/material.dart';

import '../../../model/UserModel.dart';
import '../../../theme/app_theme.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onFollow;

  const UserTile({super.key, required this.user, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white))
            : null,
      ),
      title:
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: user.username != null
          ? Text('@${user.username}',
              style: const TextStyle(color: Colors.grey))
          : null,
      trailing: _buildTrailingButton(),
    );
  }

  Widget _buildTrailingButton() {
    if (user.isFollowing) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(90, 32),
        ),
        child: const Text('Following', style: TextStyle(fontSize: 12)),
      );
    }

    if (user.hasPendingFollowRequest) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: BorderSide(color: AppColors.primaryDark.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(90, 32),
        ),
        child: const Text('Requested', style: TextStyle(fontSize: 12)),
      );
    }

    return ElevatedButton(
      onPressed: onFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(80, 32),
      ),
      child: const Text('Follow', style: TextStyle(fontSize: 12)),
    );
  }
}
