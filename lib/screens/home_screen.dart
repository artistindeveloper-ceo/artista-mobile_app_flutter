import 'dart:async';

import 'package:artist_in/screens/profile/ProfileScreen.dart';
import 'package:artist_in/screens/social_feed/social_feed_screen.dart';
import 'package:flutter/material.dart';

import '../service/ConversationService.dart';
import '../service/NotificationService.dart';
import '../theme/app_theme.dart';
import '../websocket/ChatSocketService.dart';
import '../widgets/app_drawer.dart';
import 'chat/chat_list_screen.dart';
import 'community/community_screen.dart';
import 'jamming_room/jamming_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0; // notifications
  int _chatUnreadCount = 0; // total unread chat messages
  Timer? _chatBadgeTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Home',
    'Chats',
    'Community',
    'Jamming',
    'Profile'
  ];
  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.chat_bubble_outline,
    Icons.people_outline,
    Icons.music_note_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadChatUnreadCount();

    ChatSocketService().connect((message) {
      if (!mounted) return;
      if (_currentIndex != 1) {
        setState(() => _chatUnreadCount++);
      }
    });

    _chatBadgeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadChatUnreadCount();
    });
  }

  @override
  void dispose() {
    _chatBadgeTimer?.cancel();
    ChatSocketService().disconnect();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _loadChatUnreadCount() async {
    try {
      final convos = await ConversationService.getConversations();
      int total = 0;
      for (final c in convos) {
        total += (c['unreadCount'] ?? 0) as int;
      }
      if (!mounted) return;
      setState(() => _chatUnreadCount = total);
    } catch (_) {
      // Silent fail — badge simply won't update this cycle
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const SocialFeedScreen();
      case 1:
        return const ChatListScreen();
      case 2:
        return const CommunityScreen();
      case 3:
        return const JammingScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _EmptyTab(label: _titles[_currentIndex]);
    }
  }

  // Badge dot uses theme's error/notification color, not a hardcoded hex.
  Widget _buildNavIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.notification,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // FIXED: removed `backgroundColor: AppColors.white`.
      // Scaffold now inherits `scaffoldBackgroundColor` from AppTheme
      // (AppColors.bgBase) automatically — no more white feed area.
      drawer: const AppDrawer(),
      appBar: AppBar(
        // FIXED: removed explicit backgroundColor/foregroundColor overrides.
        // AppBarTheme in app_theme.dart already sets these — single source
        // of truth, so a future theme swap updates this screen for free.
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  ).then((_) => _loadUnreadCount());
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.notification,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _loadChatUnreadCount();
            });
          }
        },
        // FIXED: removed backgroundColor / selectedItemColor /
        // unselectedItemColor overrides (the old `0xFF7986CB` navy-purple
        // leftover is gone). BottomNavigationBarTheme now fully controls
        // this — gold for selected, muted grey for unselected.
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: List.generate(
          5,
          (i) => BottomNavigationBarItem(
            icon: i == 1
                ? _buildNavIcon(_icons[i], _chatUnreadCount)
                : Icon(_icons[i], size: 22),
            label: _titles[i],
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;

  const _EmptyTab({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '$label Coming Soon',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
