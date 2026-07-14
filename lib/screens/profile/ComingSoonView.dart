import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Placeholder content for the two "Soon" (locked) profile tabs.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: AppColors.textGrey),
            SizedBox(height: 10),
            Text('Coming Soon',
                style: TextStyle(
                    color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
