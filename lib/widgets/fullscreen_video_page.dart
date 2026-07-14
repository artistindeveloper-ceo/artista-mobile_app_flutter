import 'package:flutter/material.dart';
import '../model/PostModel.dart';
import '../theme/app_theme.dart';
import 'video_post_player.dart';

class FullscreenVideoPage extends StatefulWidget {
  final List<PostModel> videoPosts; // sab video posts is list mein
  final int initialIndex; // jis pe tap kiya tha

  const FullscreenVideoPage({
    super.key,
    required this.videoPosts,
    required this.initialIndex,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kept near-black (matches AppTheme.bgBase) rather than pure
      // Colors.black — stays immersive for video while staying on-theme.
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            // Reels jaisa vertical swipe
            itemCount: widget.videoPosts.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final post = widget.videoPosts[index];
              // Sirf current + adjacent pages ko load karo (performance)
              final isNearby = (index - _currentIndex).abs() <= 1;
              if (!isNearby) {
                return Container(color: AppColors.bgBase);
              }
              return Center(
                child: VideoPostPlayer(
                  videoUrl: post.imageUrl!,
                  postId: post.id,
                  viewsCount: post.viewsCount,
                ),
              );
            },
          ),

          // Back button — top-left, Instagram jaisa transparent overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Caption overlay (agar caption hai to niche dikhao, Instagram jaisa)
          if (widget.videoPosts[_currentIndex].caption != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 60,
              child: Text(
                widget.videoPosts[_currentIndex].caption!,
                style: AppFonts.body(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ).copyWith(
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
