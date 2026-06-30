import 'dart:async';
import 'package:flutter/material.dart';
import '../service/ApiService.dart';
import '../theme/app_theme.dart';
import '../config/ApiConfig.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Har 5 second mein unread count refresh
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final convos = await ApiService.getConversations();
      setState(() {
        _conversations = convos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Silent refresh — no spinner
  Future<void> _silentRefresh() async {
    try {
      final convos = await ApiService.getConversations();
      if (!mounted) return;
      setState(() => _conversations = convos);
    } catch (_) {}
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.length < 16) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        // Aaj ka message — sirf time
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } else {
        // Purana — date dikhao
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _loadConversations, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No conversations yet',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Search people in Community tab to start chatting',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final convo = _conversations[i];
          final convoId = convo['id'] ?? convo['conversationId'];
          final otherUser = convo['otherUser'] as Map<String, dynamic>? ?? {};
          final otherUserId = otherUser['id'] as int? ?? 0;
          final displayName =
              otherUser['displayName'] ?? otherUser['username'] ?? 'Unknown';
          final rawAvatarUrl = otherUser['profilePhotoUrl'];
          final avatarUrl =
              rawAvatarUrl != null ? '${ApiConfig.baseUrl}$rawAvatarUrl' : null;
          final lastMessage = convo['lastMessagePreview'] ?? '';
          final unreadCount = convo['unreadCount'] ?? 0;
          final timeAgo = _formatTime(convo['lastMessageAt']);

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: convoId,
                    username: displayName,
                    avatarUrl: avatarUrl,
                    otherUserId: otherUserId,
                  ),
                ),
              ).then((_) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _loadConversations();
                });
              });
            },
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                fontWeight:
                    unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        unreadCount > 0 ? AppColors.primaryDark : Colors.grey,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
