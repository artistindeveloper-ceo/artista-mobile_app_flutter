import 'package:artist_in/screens/social_feed/post_bar.dart';
import 'package:artist_in/screens/social_feed/post_card.dart';
import 'package:flutter/material.dart';

import '../../service/HelperService.dart';
import '../../service/PostService.dart';
import '../../model/PostModel.dart';
import '../../theme/app_theme.dart';
import 'create_post_sheet.dart';


class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Following tab state ──
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _error;

  // ── Explore tab state ──
  List<PostModel> _explorePosts = [];
  bool _isExploreLoading = true;
  String? _exploreError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeed();
    _loadExplore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final posts = await PostService.getFeed();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        // Session expire ho chuka hai — login pe bhej do
        await HelperService.forceLogout(context);
        return;
      }
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadExplore() async {
    setState(() {
      _isExploreLoading = true;
      _exploreError = null;
    });
    try {
      final posts = await PostService.getExplore();
      setState(() {
        _explorePosts = posts;
        _isExploreLoading = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      setState(() {
        _isExploreLoading = false;
        _exploreError = e.toString();
      });
    }
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => CreatePostSheet(
          onPostCreated: () {
            _loadFeed();
            _loadExplore();
          },
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.bgAppBar,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.gold,
            tabs: const [
              Tab(text: 'Following'),
              Tab(text: 'Explore'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFollowingTab(),
              _buildExploreTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Following tab (Home feed + create-post bar) ──
  Widget _buildFollowingTab() {
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: AppColors.gold,
      backgroundColor: AppColors.bgSurfaceElevated,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _posts.isEmpty ? 2 : _posts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return PostBar(onTap: _openCreatePost);
          }
          if (_posts.isEmpty) {
            return const SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.feed_outlined,
                        size: 64, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text('No posts yet',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }
          return PostCard(post: _posts[index - 1]);
        },
      ),
    );
  }

  // ── Explore tab (public posts, no create-post bar) ──
  Widget _buildExploreTab() {
    if (_isExploreLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_exploreError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              _exploreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExplore,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_explorePosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExplore,
        color: AppColors.gold,
        backgroundColor: AppColors.bgSurfaceElevated,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_outlined,
                        size: 64, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text(
                      'Koi naya post nahi mila abhi',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExplore,
      color: AppColors.gold,
      backgroundColor: AppColors.bgSurfaceElevated,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        itemCount: _explorePosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return PostCard(post: _explorePosts[index]);
        },
      ),
    );
  }
}
