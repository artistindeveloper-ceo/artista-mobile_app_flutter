import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../config/Session.dart';
import '../service/UserService.dart';
import 'auth/login_screen.dart';
import 'auth/change_password_screen.dart';
import 'profile/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPrivate = false;
  bool _isLoadingPrivacy = true;
  bool _isSavingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyStatus();
  }

  Future<void> _loadPrivacyStatus() async {
    try {
      final user = await UserService.getMe();
      if (!mounted) return;
      setState(() {
        _isPrivate = user.isPrivate;
        _isLoadingPrivacy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrivacy = false);
    }
  }

  Future<void> _togglePrivacy(bool newValue) async {
    setState(() {
      _isPrivate = newValue; // optimistic update
      _isSavingPrivacy = true;
    });
    try {
      await UserService.updatePrivacy(newValue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          newValue
              ? 'Your account is now Private'
              : 'Your account is now Public',
          style: AppFonts.body(
              color: AppColors.textOnGold, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      // Revert on failure
      if (!mounted) return;
      setState(() => _isPrivate = !newValue);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Could not update privacy setting.',
          style: AppFonts.body(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSavingPrivacy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Settings'),
        // backgroundColor / foregroundColor / titleTextStyle are inherited
        // from AppTheme.theme.appBarTheme (gold Playfair Display title).
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Change Email',
            onTap: () {
              // TODO: hook up change email screen
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(), // uses AppTheme.dividerTheme (AppColors.divider)
          ),

          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {
              // TODO: hook up notifications screen
            },
          ),

          // Private Account toggle
          _isLoadingPrivacy
              ? ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.textSecondary),
                  title: Text('Privacy & Security',
                      style: AppFonts.body(
                          fontSize: 15, color: AppColors.textPrimary)),
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                )
              : SwitchListTile(
                  secondary: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.textSecondary),
                  title: Text('Private Account',
                      style: AppFonts.body(
                          fontSize: 15, color: AppColors.textPrimary)),
                  subtitle: Text(
                    _isPrivate
                        ? 'New followers must be approved'
                        : 'Anyone can follow you instantly',
                    style: AppFonts.body(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                  value: _isPrivate,
                  onChanged: _isSavingPrivacy ? null : _togglePrivacy,
                  activeColor: AppColors.gold,
                  activeTrackColor: AppColors.goldDim,
                  inactiveThumbColor: AppColors.textTertiary,
                  inactiveTrackColor: AppColors.bgSurfaceElevated,
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                ),

          _SettingsTile(
            icon: Icons.language_outlined,
            label: 'Language',
            onTap: () {
              // TODO: hook up language screen
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),

          _SectionHeader(title: 'Account Actions'),
          _SettingsTile(
            icon: Icons.delete_outline,
            label: 'Delete Account',
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context),
          ),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Logout',
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: () async {
              await Session().clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // backgroundColor / shape / titleTextStyle / contentTextStyle
        // inherited from AppTheme.theme.dialogTheme.
        title: const Text('Delete Account'),
        content: const Text(
            'This action is permanent and cannot be undone. Are you sure you want to delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'), // gold via textButtonTheme
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: call ApiService.deleteAccount() then navigate to login
            },
            child: Text(
              'Delete',
              style: AppFonts.body(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        label,
        style: AppFonts.body(
          color: labelColor ?? AppColors.textPrimary,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 18, color: AppColors.textTertiary),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
