import 'dart:async';

import 'package:artist_in/service/ConversationService.dart';
import 'package:flutter/material.dart';

import '../../config/ApiConfig.dart';
import '../../config/UrlHelper.dart';
import '../../service/HelperService.dart';
import '../../service/PresenceService.dart';
import '../../theme/app_theme.dart';
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
    // List me jitne bhi users hain, unka live online status dikhane ke liye.
    PresenceService.instance.addListener(_onPresenceChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    PresenceService.instance.removeListener(_onPresenceChanged);
    super.dispose();
  }

  void _onPresenceChanged() {
    if (mounted) setState(() {}); // saare dots repaint
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final convos = await ConversationService.getConversations();
      setState(() {
        _conversations = convos;
        _isLoading = false;
      });
      _fetchPresenceForVisibleUsers(convos);
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Silent refresh — no spinner
  Future<void> _silentRefresh() async {
    try {
      final convos = await ConversationService.getConversations();
      if (!mounted) return;
      setState(() => _conversations = convos);
    } catch (e) {
      if (HelperService.isAuthError(e) && mounted) {
        await HelperService.forceLogout(context);
      }
    }
  }

  // Saare conversations ke otherUser ka initial presence ek hi bulk REST
  // call se laao — jab tak koi WebSocket event na aaye tab tak dots sahi
  // dikhne chahiye. N alag calls ki jagah 1 call.
  void _fetchPresenceForVisibleUsers(List<dynamic> convos) {
    final ids = convos
        .map((c) => (c['otherUser'] as Map<String, dynamic>?)?['id'] as int?)
        .whereType<int>()
        .toList();
    PresenceService.instance.fetchBulkStatus(ids);
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
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
                size: 64, color: AppColors.textTertiary.withOpacity(0.6)),
            const SizedBox(height: 12),
            const Text('No conversations yet',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Search people in Community tab to start chatting',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppColors.gold,
      backgroundColor: AppColors.bgSurfaceElevated,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (ctx, i) {
          final convo = _conversations[i];
          final convoId = convo['id'] ?? convo['conversationId'];
          final otherUser = convo['otherUser'] as Map<String, dynamic>? ?? {};
          final otherUserId = otherUser['id'] as int? ?? 0;
          final displayName =
              otherUser['displayName'] ?? otherUser['username'] ?? 'Unknown';
          final realUsername = otherUser['username']
              as String?; // ⬅️ NAYA: profile ke liye asli username
          final avatarUrl =
              UrlHelper.resolveMediaUrl(otherUser['profilePhotoUrl']);
          final lastMessage = convo['lastMessagePreview'] ?? '';
          final unreadCount = convo['unreadCount'] ?? 0;
          final timeAgo = _formatTime(convo['lastMessageAt']);
          final isOnline = PresenceService.instance.isOnline(otherUserId);

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: convoId,
                    username: displayName,
                    profileUsername: realUsername,
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
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gold,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.textOnGold,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgBase, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              displayName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
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
                    color: unreadCount > 0
                        ? AppColors.gold
                        : AppColors.textTertiary,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.magenta,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                          color: AppColors.textOnMagenta,
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
