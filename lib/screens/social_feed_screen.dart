import 'dart:io';


import 'package:artist_in/screens/profile/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../model/PostModel.dart';
import '../service/CommentService.dart';
import '../service/HelperService.dart';
import '../service/PostService.dart';
import '../theme/app_theme.dart';
import '../widgets/video_post_player.dart';

// ─── SOCIAL FEED SCREEN (Following + Explore tabs) ────────
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
            return _PostBar(onTap: _openCreatePost);
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

// ─── POST BAR ─────────────────────────────────────────────
class _PostBar extends StatelessWidget {
  final VoidCallback onTap;

  const _PostBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgSurfaceElevated,
            backgroundImage: Session().profilePhotoUrl != null
                ? NetworkImage(
                    '${ApiConfig.baseUrl}${Session().profilePhotoUrl}')
                : null,
            child: Session().profilePhotoUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  "What's on your mind?",
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_outlined,
                  color: AppColors.gold, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_outlined,
                  color: AppColors.magenta, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CREATE POST BOTTOM SHEET ─────────────────────────────
class CreatePostSheet extends StatefulWidget {
  final VoidCallback onPostCreated;
  final ScrollController? scrollController;

  const CreatePostSheet({
    super.key,
    required this.onPostCreated,
    this.scrollController,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _captionCtrl = TextEditingController();
  File? _selectedMedia;
  bool _isVideo = false;
  bool _isPosting = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedMedia = File(picked.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedMedia = File(picked.path);
        _isVideo = true;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedMedia = File(picked.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();

    if (caption.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption or media to post')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await PostService.createPost(
        caption: caption.isNotEmpty ? caption : null,
        mediaFile: _selectedMedia,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onPostCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        // Handle
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header with POST button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              _isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.textOnGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Post'),
                      ),
                    ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomInset + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _captionCtrl,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                if (_selectedMedia != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isVideo
                            ? Container(
                                height: 200,
                                color: AppColors.bgSurfaceElevated,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam,
                                          color: AppColors.textPrimary,
                                          size: 48),
                                      SizedBox(height: 8),
                                      Text(
                                        'Video selected',
                                        style: TextStyle(
                                            color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Image.file(
                                _selectedMedia!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMedia = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgBase.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Add to your post',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MediaButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Photo',
                      color: AppColors.success,
                      onTap: _pickImage,
                    ),
                    const SizedBox(width: 10),
                    _MediaButton(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      color: AppColors.magenta,
                      onTap: _pickVideo,
                    ),
                    const SizedBox(width: 10),
                    _MediaButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      color: AppColors.gold,
                      onTap: _takePhoto,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MEDIA BUTTON ─────────────────────────────────────────
class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── POST CARD ────────────────────────────────────────────
class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likedByMe;
    _likeCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await PostService.likePost(widget.post.id);
    } catch (_) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CommentsSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          if (mounted) setState(() => _commentsCount++);
        },
      ),
    );
  }

  void _openProfile(BuildContext context, PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(username: post.username), // ✅ use username
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      color: AppColors.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context, post),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                    child: post.userAvatarUrl == null
                        ? Text(
                            post.username.isNotEmpty
                                ? post.username[0].toUpperCase()
                                : '?',
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(context, post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (post.timeAgo != null)
                          Text(
                            post.timeAgo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ],
            ),
          ),

          // Post Image
          if (post.imageUrl != null)
            post.isVideo
                ? VideoPostPlayer(
                    videoUrl: post.imageUrl!,
                    postId: post.id,
                    viewsCount: post.viewsCount,
                  )
                : AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.bgSurfaceElevated,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.bgSurfaceElevated,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 40, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.magenta : AppColors.textPrimary,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.textPrimary),
                  onPressed: _openComments,
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border,
                      color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Like Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$_likeCount likes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Caption
          if (post.caption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  children: [
                    TextSpan(
                      text: '${post.username}  ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),

          // Comments Link
          GestureDetector(
            onTap: _openComments,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'View all $_commentsCount comments',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── COMMENTS BOTTOM SHEET ────────────────────────────────
class CommentsSheet extends StatefulWidget {
  final int postId;
  final VoidCallback? onCommentAdded;

  const CommentsSheet({super.key, required this.postId, this.onCommentAdded});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    try {
      await CommentService.addComment(widget.postId, text);
      _loadComments();
      widget.onCommentAdded?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(color: AppColors.divider),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) {
                          final c = _comments[i];
                          final author = c['author'] as Map<String, dynamic>?;
                          final username =
                              author?['username'] ?? c['username'] ?? 'unknown';
                          final avatarPath =
                              author?['profilePhotoUrl'] ?? c['userAvatarUrl'];
                          final avatarUrl = (avatarPath != null &&
                                  avatarPath.toString().isNotEmpty)
                              ? (avatarPath.toString().startsWith('http')
                                  ? avatarPath.toString()
                                  : '${ApiConfig.baseUrl}${avatarPath.toString().startsWith('/') ? '' : '/'}$avatarPath')
                              : null;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.bgSurfaceElevated,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    )
                                  : null,
                            ),
                            title: Text(username,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            subtitle: Text(
                              c['content'] ?? c['text'] ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.gold),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
