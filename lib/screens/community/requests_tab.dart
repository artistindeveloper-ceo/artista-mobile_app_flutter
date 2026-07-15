import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../utils/avatar_url_util.dart';

class RequestsTab extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> requests;
  final Future<void> Function() onRefresh;
  final void Function(int requestId) onAccept;
  final void Function(int requestId) onReject;

  const RequestsTab({
    super.key,
    required this.isLoading,
    required this.requests,
    required this.onRefresh,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return const Center(
        child: Text('No pending follow requests',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (ctx, i) {
          final req = requests[i];
          final requestId = req['id'] ?? req['requestId'];
          final requester = req['requester'] as Map<String, dynamic>?;
          final username =
              req['username'] ?? requester?['username'] ?? 'Unknown';
          final rawAvatarPath =
              req['profilePhotoUrl'] ?? requester?['profilePhotoUrl'];
          final avatarUrl = AvatarUrlUtil.build(rawAvatarPath);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white))
                  : null,
            ),
            title: Text(username,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Wants to follow you'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
                  onPressed: () => onAccept(requestId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                  onPressed: () => onReject(requestId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
