import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/Session.dart';
import '../model/PostModel.dart';
import '../model/UserModel.dart';
import '../service/AuthService.dart';
import '../service/ConversationService.dart';
import '../service/FollowUserService.dart';
import '../service/HelperService.dart';
import '../service/PostService.dart';
import '../service/UserProfileService.dart';
import '../service/UserService.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final String? username;

  const ProfileScreen({super.key, this.userId, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  String? _error;

  bool get _isOwnProfile => widget.username == null && widget.userId == null;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      UserModel user;
      if (widget.username != null) {
        user = await UserService.getUserByUsername(widget.username!);
      } else {
        user = await UserService.getMe();
      }
      setState(() {
        _user = user;
        _isLoading = false;
        _isFollowing = user.isFollowing;
      });
      _loadUserPosts(user.id);
    } catch (e, stack) {
      print("❌ PROFILE ERROR: $e\n$stack");
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

  Future<void> _toggleFollow() async {
    final user = _user!;
    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await FollowUserservice.unfollowUser(user.id);
      } else {
        await FollowUserservice.followUser(user.id);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _isFollowLoading = false);
    }
  }

  Future<void> _loadUserPosts(int userId) async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await PostService.getUserPosts(userId);
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (!_isOwnProfile) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      _showSnack('Uploading profile photo...');
      final updated =
          await UserProfileService.uploadProfilePhoto(File(picked.path));
      await Session().updateProfilePhoto(updated.profilePhotoUrl);
      setState(() => _user = updated);
      _showSnack('Profile photo updated!');
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _pickAndUploadCoverPhoto() async {
    if (!_isOwnProfile) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      _showSnack('Uploading cover photo...');
      final updated =
          await UserProfileService.uploadCoverPhoto(File(picked.path));
      setState(() => _user = updated);
      _showSnack('Cover photo updated!');
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      _showSnack(e.toString(), isError: true);
    }
  }

  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _user?.name);
    final usernameCtrl = TextEditingController(text: _user?.username);
    final bioCtrl = TextEditingController(text: _user?.bio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Username', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Bio', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final updated = await UserService.updateMe(
                      name: nameCtrl.text.trim(),
                      username: usernameCtrl.text.trim(),
                      bio: bioCtrl.text.trim(),
                    );
                    setState(() => _user = updated);
                    _showSnack('Profile updated!');
                  } catch (e) {
                    _showSnack(e.toString(), isError: true);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'New Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    _showSnack('Passwords do not match!', isError: true);
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await AuthService.changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text);
                    _showSnack('Password changed!');
                  } catch (e) {
                    _showSnack(e.toString(), isError: true);
                  }
                },
                child: const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final user = _user!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context))
            : null,
        title: Text(user.username ?? user.name,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: false,
        actions: [
          if (_isOwnProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.black),
              onSelected: (val) {
                if (val == 'password') _openChangePassword();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'password',
                    child: Row(children: [
                      Icon(Icons.lock_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Change Password')
                    ])),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. Cover Photo ──
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _isOwnProfile ? _pickAndUploadCoverPhoto : null,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.primaryLight,
                  child: user.coverPhotoUrl != null
                      ? Image.network(user.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, s) => const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.white)))
                      : Center(
                          child: Icon(
                              _isOwnProfile
                                  ? Icons.add_photo_alternate
                                  : Icons.photo,
                              size: 40,
                              color: Colors.white)),
                ),
              ),
            ),

            // ── 2. Avatar + Stats Row (Instagram style) ──
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap:
                              _isOwnProfile ? _pickAndUploadProfilePhoto : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 34, color: Colors.white))
                                    : null,
                              ),
                              if (_isOwnProfile)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: AppColors.primaryDark,
                                    child: const Icon(Icons.camera_alt,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ── Stats (Posts, Followers, Following) ──
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatTile(label: 'Posts', count: _posts.length),
                              _StatTile(
                                  label: 'Followers',
                                  count: user.followersCount),
                              _StatTile(
                                  label: 'Following',
                                  count: user.followingCount),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Name, Username, Bio ──
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText)),
                    if (user.username != null)
                      Text('@${user.username}',
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 13)),
                    if (user.role != null)
                      Text(user.role!,
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 13)),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(user.bio!, style: const TextStyle(fontSize: 14)),
                    ],

                    const SizedBox(height: 12),

                    // ── Buttons ──
                    if (_isOwnProfile)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _openEditProfile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side:
                                const BorderSide(color: AppColors.primaryDark),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Follow/Following
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isFollowLoading ? null : _toggleFollow,
                              icon: _isFollowLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Icon(
                                      _isFollowing
                                          ? Icons.person_remove_outlined
                                          : Icons.person_add_outlined,
                                      size: 16),
                              label: Text(_isFollowing ? 'Following' : 'Follow',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey[300]
                                    : AppColors.primaryDark,
                                foregroundColor: _isFollowing
                                    ? Colors.black87
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Message
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final conversationId =
                                      await ConversationService
                                          .startConversation(user.id);
                                  if (mounted) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            conversationId: conversationId,
                                            username:
                                                user.username ?? user.name,
                                            avatarUrl: user.avatarUrl,
                                            otherUserId: user.id,
                                          ),
                                        ));
                                  }
                                } catch (e) {
                                  _showSnack(e.toString(), isError: true);
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(
                                    color: AppColors.primaryDark),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: Divider(height: 1, color: Colors.grey)),

            // ── 3. Posts Grid ──
            if (_isLoadingPosts)
              const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator())))
            else if (_posts.isEmpty)
              const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 200,
                      child: Center(
                          child: Text('No posts yet',
                              style: TextStyle(color: Colors.grey)))))
            else
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final post = _posts[i];
                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.white, width: 1)),
                      child: post.imageUrl != null
                          ? Image.network(post.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, s) =>
                                  const Icon(Icons.broken_image))
                          : Container(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              child: const Icon(Icons.text_snippet_outlined,
                                  color: AppColors.primaryDark),
                            ),
                    );
                  },
                  childCount: _posts.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int count;

  const _StatTile({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
