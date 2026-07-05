import 'dart:async';

import 'package:flutter/material.dart';

import '../service/ConversationService.dart';
import '../service/NotificationService.dart';
import '../theme/app_theme.dart';
import '../websocket/ChatSocketService.dart';
import '../widgets/app_drawer.dart';
import 'chat_list_screen.dart';
import 'community_screen.dart';
import 'jamming_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';
import 'jamming_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0; // notifications
  int _chatUnreadCount = 0; // ← NEW: total unread chat messages
  Timer? _chatBadgeTimer; // ← NEW
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
    _loadChatUnreadCount(); // initial load

    // Real-time: connects once for the whole app session. On every new
    // message pushed from backend, bump the badge instantly.
    ChatSocketService().connect((message) {
      if (!mounted) return;
      // If user is already inside the Chats tab, skip the bump — the
      // conversation screen itself will mark-as-read and the count will
      // resync when they leave that tab (see onTap below).
      if (_currentIndex != 1) {
        setState(() => _chatUnreadCount++);
      }
    });

    // Fallback polling every 30 sec — safety net in case the socket drops
    // (e.g. app backgrounded/foregrounded, network blip). Kept infrequent
    // since the socket handles the real-time case now.
    _chatBadgeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadChatUnreadCount();
    });
  }

  @override
  void dispose() {
    _chatBadgeTimer?.cancel();
    ChatSocketService().disconnect(); // ← NEW
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  // ← NEW: sums unreadCount across all conversations
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

  // ← NEW: builds a nav icon, adding a red badge on top-right if count > 0
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
                color: AppColors.accent,
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
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Translate icon
          IconButton(
            icon: const Icon(Icons.translate, color: AppColors.white),
            onPressed: () {},
          ),
          // Notification icon with count
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  ).then((_) => _loadUnreadCount()); // reload after back
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
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
          // Jab user Chats tab kholta hai, thodi der baad badge refresh
          // (chat screen mark-as-read kar chuka hoga)
          if (index == 1) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _loadChatUnreadCount();
            });
          }
        },
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.white,
        unselectedItemColor: const Color(0xFF7986CB),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: List.generate(
          5,
          (i) => BottomNavigationBarItem(
            // ← CHANGED: index 1 (Chats) now shows badge via _buildNavIcon
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined,
              size: 64, color: AppColors.textGrey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            '$label Coming Soon',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
