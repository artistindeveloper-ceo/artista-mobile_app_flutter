import 'package:flutter/material.dart';

import '../../model/PostModel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fullscreen_video_page.dart';
import '../../widgets/video_thumbnail_tile.dart';


/// Renders the "Posts" tab: a 3-column grid of images/videos/text posts.
///
/// Returns a list of slivers so it can be dropped straight into a
/// CustomScrollView alongside the rest of the profile page.
class PhotoGridView extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;

  const PhotoGridView({
    super.key,
    required this.posts,
    required this.isLoading,
  });

  /// Use this when composing slivers manually (e.g. inside a
  /// CustomScrollView on the parent ProfileScreen).
  static List<Widget> slivers({
    required List<PostModel> posts,
    required bool isLoading,
  }) {
    if (isLoading) {
      return [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child:
                Center(child: CircularProgressIndicator(color: AppColors.gold)),
          ),
        ),
      ];
    }
    if (posts.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text('No posts yet',
                  style: TextStyle(color: AppColors.textGrey)),
            ),
          ),
        ),
      ];
    }
    return [
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _PostTile(post: posts[i], allPosts: posts),
          childCount: posts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Convenience non-sliver entry point (e.g. for previewing this widget
    // standalone). ProfileScreen itself uses `PhotoGridView.slivers(...)`.
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: slivers(posts: posts, isLoading: isLoading),
    );
  }
}

class _PostTile extends StatelessWidget {
  final PostModel post;
  final List<PostModel> allPosts;

  const _PostTile({required this.post, required this.allPosts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.bgBase, width: 1)),
      child: post.imageUrl == null
          ? Container(
              color: AppColors.gold.withValues(alpha: 0.15),
              child: const Icon(Icons.text_snippet_outlined,
                  color: AppColors.gold),
            )
          : post.isVideo
              ? VideoThumbnailTile(
                  videoUrl: post.imageUrl!,
                  viewsCount: post.viewsCount,
                  onTap: () => _openFullscreenVideo(context),
                )
              : Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.bgSurface,
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.gold),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, e, s) => Container(
                    color: AppColors.bgSurface,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.textTertiary),
                  ),
                ),
    );
  }

  void _openFullscreenVideo(BuildContext context) {
    final videoPosts =
        allPosts.where((p) => p.isVideo && p.imageUrl != null).toList();
    final tappedIndex = videoPosts.indexWhere((p) => p.id == post.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenVideoPage(
          videoPosts: videoPosts,
          initialIndex: tappedIndex >= 0 ? tappedIndex : 0,
        ),
      ),
    );
  }
}
