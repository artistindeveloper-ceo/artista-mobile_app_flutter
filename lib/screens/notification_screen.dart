import 'package:flutter/material.dart';

import '../config/ApiConfig.dart' as $baseUrl;
import '../service/NotificationService.dart';
import '../theme/app_theme.dart';
import 'Profile_Screen.dart'; // 👈 import your profile screen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifs = await NotificationService.getNotifications();
      print('🔔 NOTIF DATA: ${notifs}'); // 👈 add this
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
      await NotificationService.markAllNotificationsRead();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      case 'follow_request':
        return Icons.person_add_outlined;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
      case 'follow_request':
        return Colors.green;
      case 'message':
        return Colors.purple;
      default:
        return AppColors.primaryDark;
    }
  }

  // 👇 Navigate to profile on tap
  void _onNotificationTap(dynamic n) {
    final senderId = n['actor']?['id']; // 👈 'actor' not 'sender'
    if (senderId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: senderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadNotifications, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No notifications yet',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          final type = n['type'];
          final message = n['message'] ?? '';
          final timeAgo = n['createdAt'] ?? '';
          final isRead = n['read'] ?? false;
          final actor = n['actor'];
          final username = actor?['displayName'] ?? actor?['username'] ?? '';
          // final avatarUrl = n['avatarUrl'] ?? n['sender']?['avatarUrl'];

          final rawUrl = actor?['profilePhotoUrl'];
          final avatarUrl = rawUrl != null
              ? '${$baseUrl.ApiConfig.baseUrl}$rawUrl' // 👈 adds https://yourserver.com
              : null;
          return InkWell(
            // 👈 wrap with InkWell
            onTap: () => _onNotificationTap(n), // 👈 tap goes to profile
            child: Container(
              color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
              child: ListTile(
                leading: GestureDetector(
                  // 👈 avatar tap also works
                  onTap: () => _onNotificationTap(n),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(
                            _getIcon(type),
                            size: 13,
                            color: _getIconColor(type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: !isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
