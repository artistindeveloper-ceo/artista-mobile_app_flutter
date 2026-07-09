import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../service/PostService.dart';

class VideoPostPlayer extends StatefulWidget {
  final String videoUrl;
  final int postId;
  final int viewsCount; // ← NEW

  const VideoPostPlayer({
    super.key,
    required this.videoUrl,
    required this.postId,
    this.viewsCount = 0, // ← NEW
  });

  @override
  State<VideoPostPlayer> createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = true;
  bool _isVisible = false;
  Timer? _hideIconTimer;
  bool _showMuteIcon = false;
  bool _viewRegistered = false; // ← duplicate register na ho isliye

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      if (!_viewRegistered) {
        _viewRegistered = true;
        PostService.registerView(widget.postId);
      }

      if (_isVisible) {
        _controller!.play();
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visibleFraction = info.visibleFraction;
    final shouldPlay = visibleFraction > 0.65;

    if (shouldPlay == _isVisible) return;
    _isVisible = shouldPlay;

    if (_controller == null || !_isInitialized) return;

    if (shouldPlay) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0 : 1);
      _showMuteIcon = true;
    });

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showMuteIcon = false);
    });
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
  void dispose() {
    _hideIconTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error_outline, size: 40, color: Colors.grey),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.black87,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: Key('video_post_${widget.postId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _toggleMute,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio == 0
              ? 1
              : _controller!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              VideoPlayer(_controller!),

              // Mute/unmute icon — fade in/out
              AnimatedOpacity(
                opacity: _showMuteIcon ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // Bottom-left views count — Instagram jaisa
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        _formatViews(widget.viewsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom-right mute indicator
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        _formatViews(widget.viewsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
