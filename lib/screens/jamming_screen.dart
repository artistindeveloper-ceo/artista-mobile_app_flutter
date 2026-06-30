import 'package:flutter/material.dart';
import '../service/ApiService.dart';
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
      final sessions = await ApiService.getMySessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Jam Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Session Name',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.createSession(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    _showSnack('Session created!');
                    _loadSessions();
                  } catch (e) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join Jam Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Enter Invite Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final session = await ApiService.joinSession(
                        codeCtrl.text.trim());
                    _showSnack('Joined session!');
                    _loadSessions();
                    if (session != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JamSessionDetailScreen(
                              sessionId: session['id']),
                        ),
                      );
                    }
                  } catch (e) {
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
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadSessions,
                child: const Text('Retry')),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadSessions,
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
                        color: Colors.grey.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('No jam sessions yet',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text(
                        'Create or join a session below',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12)),
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
            final participantCount =
                s['participantCount'] ?? 0;

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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$participantCount participants',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.vpn_key_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(inviteCode,
                            style: const TextStyle(
                                color: Colors.grey,
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
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            icon: const Icon(Icons.login),
            label: const Text('Join'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _openCreateSession,
            backgroundColor: AppColors.primaryDark,
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
        color = Colors.green;
        break;
      case 'ENDED':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}