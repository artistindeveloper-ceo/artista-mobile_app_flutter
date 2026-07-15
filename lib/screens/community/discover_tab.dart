import 'package:flutter/material.dart';

import '../../../model/UserModel.dart';
import '../../widgets/user_tile.dart';


class DiscoverTab extends StatelessWidget {
  final bool isLoading;
  final List<UserModel> users;
  final Future<void> Function() onRefresh;
  final void Function(int userId) onFollow;

  const DiscoverTab({
    super.key,
    required this.isLoading,
    required this.users,
    required this.onRefresh,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (users.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        itemBuilder: (ctx, i) {
          final user = users[i];
          return UserTile(
            user: user,
            onFollow: () => onFollow(user.id),
          );
        },
      ),
    );
  }
}
