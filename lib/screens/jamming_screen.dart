import 'package:flutter/material.dart';

import '../service/HelperService.dart';
import '../service/JamSessionService.dart';
import '../theme/app_theme.dart';
import 'jam_session_detail_screen.dart';

class JammingScreen extends StatefulWidget {
  const JammingScreen({super.key});

  @override
  State<JammingScreen> createState() => _JammingScreenState();
}

class _JammingScreenState extends State<JammingScreen> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sessions = await JamSessionService.getMySessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      if (HelperService.isAuthError(e)) {
        await HelperService.forceLogout(context);
        return;
      }
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ─── Create Session Dialog ────────────────────────────
  void _openCreateSession() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Jam Session',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Session Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await JamSessionService.createSession(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    _showSnack('Session created!');
                    _loadSessions();
                  } catch (e) {
                    if (HelperService.isAuthError(e)) {
                      await HelperService.forceLogout(context);
                      return;
                    }
                    _showSnack(e.toString(), isError: true);
                  }
                },
                child: const Text('Create Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Join Session Dialog ──────────────────────────────
  void _openJoinSession() {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join Jam Session',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Enter Invite Code',
                prefixIcon: Icon(Icons.vpn_key_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final session = await JamSessionService.joinSession(
                        codeCtrl.text.trim());
                    _showSnack('Joined session!');
                    _loadSessions();
                    if (session != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JamSessionDetailScreen(sessionId: session['id']),
                        ),
                      );
                    }
                  } catch (e) {
                    if (HelperService.isAuthError(e)) {
                      await HelperService.forceLogout(context);
                      return;
                    }
                    _showSnack(e.toString(), isError: true);
                  }
                },
                child: const Text('Join Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadSessions, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgSurfaceElevated,
                  child: _sessions.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.music_note_outlined,
                                        size: 64,
                                        color: AppColors.textTertiary
                                            .withOpacity(0.6)),
                                    const SizedBox(height: 12),
                                    const Text('No jam sessions yet',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    const Text('Create or join a session below',
                                        style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final s = _sessions[i];
                            final sessionId = s['id'];
                            final name = s['name'] ?? 'Jam Session';
                            final status = s['status'] ?? 'PENDING';
                            final inviteCode = s['inviteCode'] ?? '';
                            final participantCount = s['participantCount'] ?? 0;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JamSessionDetailScreen(
                                        sessionId: sessionId),
                                  ),
                                ).then((_) => _loadSessions());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        _StatusChip(status: status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.people_outline,
                                            size: 16,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('$participantCount participants',
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.vpn_key_outlined,
                                            size: 16,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(inviteCode,
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: _openJoinSession,
            backgroundColor: AppColors.bgSurfaceElevated,
            foregroundColor: AppColors.gold,
            icon: const Icon(Icons.login),
            label: const Text('Join'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _openCreateSession,
            backgroundColor: AppColors.magenta,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = AppColors.success;
        break;
      case 'ENDED':
        color = AppColors.textTertiary;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
