import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../service/PostService.dart';
import '../../../../theme/app_theme.dart';
import 'media_button.dart';

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
                    MediaButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Photo',
                      color: AppColors.success,
                      onTap: _pickImage,
                    ),
                    const SizedBox(width: 10),
                    MediaButton(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      color: AppColors.magenta,
                      onTap: _pickVideo,
                    ),
                    const SizedBox(width: 10),
                    MediaButton(
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
