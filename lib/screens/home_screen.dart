import 'package:flutter/material.dart';

import '../service/NotificationService.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'chat_list_screen.dart';
import 'community_screen.dart';
import 'jamming_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0; // ← NEW
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
    _loadUnreadCount(); // ← NEW
  }

  Future<void> _loadUnreadCount() async {
    // ← NEW
    final count = await NotificationService.getUnreadCount();
    setState(() => _unreadCount = count);
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
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.white,
        unselectedItemColor: const Color(0xFF7986CB),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: List.generate(
          5,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i], size: 22),
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
