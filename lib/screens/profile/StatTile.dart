import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Small "count + label" column used in the profile stats row
/// (Posts / Followers / Following).
class StatTile extends StatelessWidget {
  final String label;
  final int count;

  const StatTile({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
