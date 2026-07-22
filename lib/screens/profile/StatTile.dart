import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Small "count + label" column used in the profile stats row
/// (Posts / Followers / Following). Pass [onTap] to make it tappable
/// (e.g. Followers/Following open a list, Instagram-style).
class StatTile extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
