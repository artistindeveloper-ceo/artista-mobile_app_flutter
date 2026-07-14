import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProfileTabDef {
  final IconData icon;
  final String label;

  const ProfileTabDef({required this.icon, required this.label});
}

/// The Instagram-style tab row: Posts / Instruments / Soon / Soon.
class ProfileTabBar extends StatelessWidget {
  static const List<ProfileTabDef> tabs = [
    ProfileTabDef(icon: Icons.grid_on, label: 'Posts'),
    ProfileTabDef(icon: Icons.music_note_outlined, label: 'Instruments'),
    ProfileTabDef(icon: Icons.shopping_cart_outlined, label: 'Soon'),
    ProfileTabDef(icon: Icons.remove_moderator_outlined, label: 'Soon'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgBase,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = selectedIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Icon(
                  tabs[i].icon,
                  size: 22,
                  color: selected ? AppColors.gold : AppColors.textTertiary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
