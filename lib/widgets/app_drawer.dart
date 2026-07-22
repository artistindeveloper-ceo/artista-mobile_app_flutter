import 'package:flutter/material.dart';

import '../config/ApiConfig.dart';
import '../config/Session.dart';
import '../screens/jamming_room/jamming_screen.dart';
import '../screens/auth/login_screen.dart';

import '../screens/profile/ProfileScreen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _name = 'Artista';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = Session();
    final name = await session.getDisplayName();
    final photo = await session.getProfilePhotoUrl();
    print("🖼️ Drawer photo URL: $photo"); // ← add karo
    print("👤 Drawer name: $name"); // ← add karo
    if (mounted) {
      setState(() {
        _name = name ?? 'Artista';
        _photoUrl = photo != null
            ? '${ApiConfig.baseUrl}$photo' // ← base URL add karo
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgSurface,
      width: MediaQuery.of(context).size.width * 0.6,
      child: Column(
        children: [
          // ── Header — tap to open own profile ──
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileScreen(), // no userId/username = own profile
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 16,
                20,
                20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.goldGradient,
                ),
              ),
              child: Row(
                children: [
                  // Profile photo or fallback icon
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.bgSurfaceElevated,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.gold, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            color: AppColors.textOnGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View Profile',
                          style: TextStyle(
                            color: AppColors.textOnGold.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: AppColors.textOnGold.withOpacity(0.7), size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.music_note_outlined,
                  label: 'Jamming',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JammingScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.send_outlined,
                  label: 'Contact Us',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.star_border,
                  label: 'Rate this app',
                  onTap: () => Navigator.pop(context),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(color: AppColors.divider),
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  iconColor: AppColors.logoutRed,
                  labelColor: AppColors.logoutRed,
                  onTap: () {
                    Session().clear();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textPrimary.withOpacity(0.75),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
