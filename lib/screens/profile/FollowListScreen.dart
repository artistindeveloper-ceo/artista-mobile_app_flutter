import 'package:flutter/material.dart';

import '../../model/UserModel.dart';
import '../../service/FollowUserService.dart';
import '../../service/HelperService.dart';
import '../../theme/app_theme.dart';
import 'ProfileScreen.dart';

/// Instagram-style Followers / Following list with tabs.
/// Tap a row to open that user's profile.
class FollowListScreen extends StatefulWidget {
  final int userId;
  final String username;

  /// 0 = Followers tab first, 1 = Following tab first
  final int initialTab;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  String? _followersError;
  String? _followingError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadFollowers();
    _loadFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoadingFollowers = true;
      _followersError = null;
    });
    try {
      final list = await FollowUserservice.getFollowers(widget.userId);
      if (!mounted) return;
      setState(() {
        _followers = list;
        _isLoadingFollowers = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        _followersError = e.toString();
        _isLoadingFollowers = false;
      });
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoadingFollowing = true;
      _followingError = null;
    });
    try {
      final list = await FollowUserservice.getFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _following = list;
        _isLoadingFollowing = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        _followingError = e.toString();
        _isLoadingFollowing = false;
      });
    }
  }

  void _openUserProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(username: user.username),
      ),
    );
  }

  Widget _buildList({
    required List<UserModel> users,
    required bool isLoading,
    required String? error,
    required VoidCallback onRetry,
    required String emptyLabel,
  }) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: AppColors.textGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (users.isEmpty) {
      return Center(
        child:
            Text(emptyLabel, style: const TextStyle(color: AppColors.textGrey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final user = users[i];
        return ListTile(
          onTap: () => _openUserProfile(user),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.bgSurfaceElevated,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.gold),
                  )
                : null,
          ),
          title: Text(
            user.name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          subtitle: user.username != null
              ? Text('@${user.username}',
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 12))
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgAppBar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.username,
            style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textGrey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            users: _followers,
            isLoading: _isLoadingFollowers,
            error: _followersError,
            onRetry: _loadFollowers,
            emptyLabel: 'No followers yet',
          ),
          _buildList(
            users: _following,
            isLoading: _isLoadingFollowing,
            error: _followingError,
            onRetry: _loadFollowing,
            emptyLabel: 'Not following anyone yet',
          ),
        ],
      ),
    );
  }
}
