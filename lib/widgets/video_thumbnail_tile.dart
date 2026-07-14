import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoThumbnailTile extends StatefulWidget {
  final String videoUrl;
  final int viewsCount;
  final VoidCallback onTap;

  const VideoThumbnailTile({
    super.key,
    required this.videoUrl,
    required this.onTap,
    this.viewsCount = 0,
  });

  @override
  State<VideoThumbnailTile> createState() => _VideoThumbnailTileState();
}

class _VideoThumbnailTileState extends State<VideoThumbnailTile> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  Future<void> _loadFrame() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      await controller.seekTo(const Duration(milliseconds: 200));

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatViews(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasError)
            Container(
              color: AppColors.bgSurface,
              child: const Icon(Icons.error_outline,
                  color: AppColors.textTertiary),
            )
          else if (!_isReady)
            Container(
              color: AppColors.bgBase,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),

          // Top-right small play icon — Instagram jaisa
          Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.textPrimary,
              size: 20,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
              ],
            ),
          ),

          // Bottom-left view count — Instagram jaisa
          Positioned(
            bottom: 6,
            left: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: AppColors.textPrimary,
                  size: 14,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
                  ],
                ),
                const SizedBox(width: 2),
                Text(
                  _formatViews(widget.viewsCount),
                  style: AppFonts.body(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.6), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
