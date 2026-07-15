import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class JamSessionInfoTab extends StatelessWidget {
  final Map<String, dynamic> session;
  final int participantCount;
  final bool isLeader;
  final VoidCallback onCopyInviteCode;
  final VoidCallback onStartSession;
  final VoidCallback onEndSession;
  final VoidCallback onLeaveSession;

  const JamSessionInfoTab({
    super.key,
    required this.session,
    required this.participantCount,
    required this.isLeader,
    required this.onCopyInviteCode,
    required this.onStartSession,
    required this.onEndSession,
    required this.onLeaveSession,
  });

  @override
  Widget build(BuildContext context) {
    final status = session['status'] ?? 'SCHEDULED';
    final inviteCode = session['inviteCode'] ?? '';
    final isActive = status.toString().toUpperCase() == 'LIVE';
    final statusUpper = status.toString().toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Status: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.toString(),
                    style: TextStyle(
                        color: isActive ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Invite Code: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Text(inviteCode,
                  style: const TextStyle(fontSize: 15, color: AppColors.gold)),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: onCopyInviteCode,
                  child: const Icon(Icons.copy,
                      size: 18, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Participants: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Text('$participantCount',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (isLeader && statusUpper == 'SCHEDULED')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartSession,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          if (isLeader && isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEndSession,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLeaveSession,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Session'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        ],
      ),
    );
  }
}
