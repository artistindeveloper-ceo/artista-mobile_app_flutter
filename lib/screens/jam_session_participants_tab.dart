import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Participants tab — shown inside JamSessionDetailScreen's TabBarView.
/// Renders the list of session participants, each with their username,
/// avatar, and role badge (if a role has been assigned).
///
/// Pulled out of jam_session_detail_screen.dart to keep that file focused
/// on session/song/socket logic.
class ParticipantsTab extends StatelessWidget {
  final List<dynamic> participants;

  const ParticipantsTab({
    super.key,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'No participants yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (ctx, i) {
        final entry = participants[i];
        final p = entry['user'] ?? entry;
        final username = p['username'] ?? p['displayName'] ?? 'Unknown';
        final avatarUrl = p['avatarUrl'];
        final role = entry['role'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.gold,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textOnGold),
                  )
                : null,
          ),
          title: Text(
            username,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          trailing: role.toString().isNotEmpty
              ? _RoleBadge(role: role.toString())
              : null,
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: const TextStyle(fontSize: 11, color: AppColors.gold),
      ),
    );
  }
}
