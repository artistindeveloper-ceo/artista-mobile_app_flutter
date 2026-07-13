import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/Session.dart';
import '../model/PostModel.dart';
import '../model/UserModel.dart';
import '../model/InstrumentModel.dart';
import '../service/AuthService.dart';
import '../service/ConversationService.dart';
import '../service/FollowUserService.dart';
import '../service/HelperService.dart';
import '../service/InstrumentService.dart';
import '../service/PostService.dart';
import '../service/UserProfileService.dart';
import '../service/UserService.dart';
import '../theme/app_theme.dart';

import '../widgets/fullscreen_video_page.dart';
import '../widgets/showAddInstrumentSheet.dart';
import '../widgets/video_thumbnail_tile.dart';
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

  // ── Profile tabs (Posts / Instruments / Coming Soon x2) ──
  int _selectedTabIndex = 0;
  List<InstrumentModel> _instruments = [];
  bool _isLoadingInstruments = true;

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
      _loadUserInstruments(user.id);
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

  Future<void> _loadUserInstruments(int userId) async {
    setState(() => _isLoadingInstruments = true);
    try {
      final instruments = await InstrumentService.getUserInstruments(userId);
      setState(() {
        _instruments = instruments;
        _isLoadingInstruments = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      // Non-fatal — just show empty state in the Instruments tab
      setState(() => _isLoadingInstruments = false);
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
        leading: !_isOwnProfile
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

            // ── 3. Tab Bar (Posts / Instruments / Coming Soon x2) ──
            SliverToBoxAdapter(child: _buildProfileTabBar()),

            const SliverToBoxAdapter(
                child: Divider(height: 1, color: Colors.grey)),

            // ── 4. Tab Content ──
            ..._buildTabContentSlivers(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Profile Tabs (Instagram-style: Posts / Instruments / Soon / Soon)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileTabBar() {
    final tabs = [
      _TabDef(icon: Icons.grid_on, label: 'Posts'),
      _TabDef(icon: Icons.music_note_outlined, label: 'Instruments'),
      _TabDef(icon: Icons.lock_outline, label: 'Soon'),
      _TabDef(icon: Icons.lock_outline, label: 'Soon'),
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _selectedTabIndex == i;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedTabIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primaryDark : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Icon(
                tabs[i].icon,
                size: 22,
                color: selected ? AppColors.primaryDark : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildTabContentSlivers() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPostsGridSlivers();
      case 1:
        return [SliverToBoxAdapter(child: _buildInstrumentsSection())];
      default:
        return [SliverToBoxAdapter(child: _buildComingSoonSection())];
    }
  }

  List<Widget> _buildPostsGridSlivers() {
    if (_isLoadingPosts) {
      return [
        const SliverToBoxAdapter(
            child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()))),
      ];
    }
    if (_posts.isEmpty) {
      return [
        const SliverToBoxAdapter(
            child: SizedBox(
                height: 200,
                child: Center(
                    child: Text('No posts yet',
                        style: TextStyle(color: Colors.grey))))),
      ];
    }
    return [
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (ctx, i) {
            final post = _posts[i];
            return Container(
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.white, width: 1)),
              child: post.imageUrl == null
                  ? Container(
                color: AppColors.primaryLight.withOpacity(0.3),
                child: const Icon(Icons.text_snippet_outlined,
                    color: AppColors.primaryDark),
              )
                  : post.isVideo
                  ? VideoThumbnailTile(
                videoUrl: post.imageUrl!,
                viewsCount: post.viewsCount,
                onTap: () {
                  final videoPosts = _posts
                      .where((p) => p.isVideo && p.imageUrl != null)
                      .toList();
                  final tappedIndex = videoPosts
                      .indexWhere((p) => p.id == post.id);
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => FullscreenVideoPage(
                        videoPosts: videoPosts,
                        initialIndex:
                        tappedIndex >= 0 ? tappedIndex : 0,
                      ),
                    ),
                  );
                },
              )
                  : Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      color: Colors.grey),
                ),
              ),
            );
          },
          childCount: _posts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.0),
      ),
    ];
  }

  Widget _buildInstrumentsSection() {
    if (_isLoadingInstruments) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    final primary = _instruments.where((i) => i.isPrimary).toList();
    final secondary = _instruments.where((i) => !i.isPrimary).toList();

    if (_instruments.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_off_outlined,
                  size: 40, color: AppColors.textGrey),
              const SizedBox(height: 10),
              const Text('No instruments added yet',
                  style: TextStyle(color: Colors.grey)),
              if (_isOwnProfile) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => showAddInstrumentSheet(
                    context,
                    onAdded: () => _loadUserInstruments(_user!.id),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Instrument'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOwnProfile)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showAddInstrumentSheet(
                  context,
                  onAdded: () => _loadUserInstruments(_user!.id),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ),
          if (primary.isNotEmpty) ...[
            const Text('Primary Instrument',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...primary.map((ins) => _InstrumentCard(instrument: ins)),
            const SizedBox(height: 20),
          ],
          if (secondary.isNotEmpty) ...[
            const Text('Secondary Instrument',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...secondary.map((ins) => _InstrumentCard(instrument: ins)),
          ],
        ],
      ),
    );
  }

  Widget _buildComingSoonSection() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: AppColors.textGrey),
            const SizedBox(height: 10),
            const Text('Coming Soon',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  _TabDef({required this.icon, required this.label});
}

class _InstrumentCard extends StatelessWidget {
  final InstrumentModel instrument;

  const _InstrumentCard({required this.instrument});

  @override
  Widget build(BuildContext context) {
    final details = instrument.userInstrumentDetails;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: instrument.displayImageUrl != null
                ? Image.network(
              instrument.displayImageUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => Container(
                width: 56,
                height: 56,
                color: AppColors.primaryLight.withOpacity(0.3),
                child: const Icon(Icons.music_note,
                    color: AppColors.primaryDark),
              ),
            )
                : Container(
              width: 56,
              height: 56,
              color: AppColors.primaryLight.withOpacity(0.3),
              child: const Icon(Icons.music_note,
                  color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Roland SPD-20" (brand + model)
                Text(instrument.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                // "Octapad" (instrument type)
                if (instrument.typeName.isNotEmpty)
                  Text(instrument.typeName,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12)),
                if (details?.proficiencyLevel != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      details!.proficiencyLevel!,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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