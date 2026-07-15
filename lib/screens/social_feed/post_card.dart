import 'package:flutter/material.dart';

import '../../../../model/PostModel.dart';
import '../../../../screens/profile/ProfileScreen.dart';
import '../../../../service/PostService.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/video_post_player.dart';
import 'comments_sheet.dart';

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
