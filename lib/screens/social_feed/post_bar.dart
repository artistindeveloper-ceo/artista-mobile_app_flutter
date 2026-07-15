import 'package:flutter/material.dart';

import '../../../../config/ApiConfig.dart';
import '../../../../config/Session.dart';
import '../../../../theme/app_theme.dart';

class PostBar extends StatelessWidget {
  final VoidCallback onTap;

  const PostBar({super.key, required this.onTap});

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
