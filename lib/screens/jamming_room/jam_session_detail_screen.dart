import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/Session.dart';
import '../../service/JamSessionService.dart';
import '../../websocket/JamSessionSocketService.dart';
import '../../service/SongService.dart';
import '../../theme/app_theme.dart';
import '../../utils/chord_transpose_utils.dart';
import 'JamSessionSongListTab.dart';
import 'jam_session_song_detail_screen.dart';
import 'jam_session_participants_tab.dart';

import 'jam_session_info_tab.dart';

class JamSessionDetailScreen extends StatefulWidget {
  final int sessionId;

  const JamSessionDetailScreen({super.key, required this.sessionId});

  @override
  State<JamSessionDetailScreen> createState() => _JamSessionDetailScreenState();
}

class _JamSessionDetailScreenState extends State<JamSessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _session;
  List<dynamic> _participants = [];
  List<dynamic> _songs =
      []; // setlist entries: {id, songId, title, artist, originalKey, position, transposeOffset, performed}
  Map<String, dynamic>?
      _currentSongDisplay; // {jamSessionSongId, title, artist, transposedKey, transposedLyricsWithChords}
  bool _isLoading = true;
  bool _isLeader = false;
  JamSessionSocketService? _socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEverything();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socket?.disconnect();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    setState(() => _isLoading = true);
    try {
      final session =
          await JamSessionService.getSessionDetail(widget.sessionId);
      final participants =
          await JamSessionService.getSessionParticipants(widget.sessionId);

      final currentUserId = Session()
          .userId; // ⚠️ apni Session class me userId field confirm karo
      final leaderId = session['leader']?['id'];

      setState(() {
        _session = session;
        _participants = participants;
        _songs = List<dynamic>.from(session['setlist'] ?? []);
        _isLeader = currentUserId != null &&
            leaderId != null &&
            currentUserId == leaderId;
        _isLoading = false;
      });

      // Agar koi song already active hai (jab user session me late join/reopen kare)
      final currentSongId = session['currentSongId'];
      final transposeOffset = session['currentTransposeOffset'] ?? 0;
      if (currentSongId != null) {
        await _loadCurrentSongDisplay(currentSongId, transposeOffset);
      }

      _connectSocket();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  void _connectSocket() {
    _socket = JamSessionSocketService(
      sessionId: widget.sessionId,
      onEvent: _handleSocketEvent,
    );
    _socket!.connect();
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['eventType'];
    if (!mounted) return;

    switch (type) {
      case 'SONG_CHANGED':
      case 'TRANSPOSE_CHANGED':
        final currentSong = event['currentSong'];
        setState(() {
          _currentSongDisplay = {
            'jamSessionSongId': currentSong?['id'],
            'title': currentSong?['title'],
            'artist': currentSong?['artist'],
            'transposedKey': event['transposedKey'],
            'transposedLyricsWithChords': event['transposedLyricsWithChords'],
          };
          _session!['currentTransposeOffset'] = event['transposeOffset'] ?? 0;
        });
        break;

      case 'SETLIST_UPDATED':
        final rawList = List<dynamic>.from(event['setlist'] ?? []);
        final seen = <dynamic>{};
        final deduped = rawList.where((s) => seen.add(s['id'])).toList();
        setState(() => _songs = deduped);
        break;

      case 'PARTICIPANT_JOINED':
      case 'PARTICIPANT_LEFT':
        JamSessionService.getSessionParticipants(widget.sessionId).then((p) {
          if (mounted) setState(() => _participants = p);
        });
        break;

      case 'SESSION_STARTED':
      case 'SESSION_ENDED':
        JamSessionService.getSessionDetail(widget.sessionId).then((s) {
          if (mounted) setState(() => _session = s);
        });
        break;
    }
  }

  /// Fetch full lyrics for the currently active song and compute transposed
  /// text client-side (used only on initial load, before any socket event).
  Future<void> _loadCurrentSongDisplay(
      int jamSessionSongId, int transposeOffset) async {
    try {
      final entry = _songs.firstWhere(
        (s) => s['id'] == jamSessionSongId,
        orElse: () => null,
      );
      if (entry == null) return;

      final fullSong = await SongService.getSongById(entry['songId']);
      final rawLyrics =
          fullSong['lyricsWithChords'] ?? fullSong['lyrics_with_chords'] ?? '';
      final originalKey =
          fullSong['originalKey'] ?? fullSong['original_key'] ?? 'C';

      setState(() {
        _currentSongDisplay = {
          'jamSessionSongId': jamSessionSongId,
          'title': entry['title'],
          'artist': entry['artist'],
          'transposedKey': ChordTransposeUtils.computeTransposedKey(
              originalKey, transposeOffset),
          'transposedLyricsWithChords':
              ChordTransposeUtils.computeTransposedText(
                  rawLyrics, transposeOffset),
        };
      });
    } catch (_) {}
  }

  Future<void> _startSession() async {
    try {
      await JamSessionService.startSession(widget.sessionId);
      _showSnack('Session started!');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _endSession() async {
    try {
      await JamSessionService.endSession(widget.sessionId);
      _showSnack('Session ended!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _leaveSession() async {
    try {
      await JamSessionService.leaveSession(widget.sessionId);
      _showSnack('Left session!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _copyInviteCode() {
    final code = _session?['inviteCode'] ?? '';
    Clipboard.setData(ClipboardData(text: code));
    _showSnack('Invite code copied!');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  /// Leader/Co-leader taps a song from the setlist → officially switches it,
  /// broadcasts SONG_CHANGED to every participant via WebSocket.
  Future<void> _switchToSong(Map<String, dynamic> entry) async {
    if (!_isLeader) {
      _showSnack('Only the leader can change the song.', isError: true);
      return;
    }
    try {
      final event = await JamSessionService.changeCurrentSong(
          widget.sessionId, entry['id']);
      final currentSong = event['currentSong'];
      setState(() {
        _currentSongDisplay = {
          'jamSessionSongId': currentSong?['id'],
          'title': currentSong?['title'],
          'artist': currentSong?['artist'],
          'transposedKey': event['transposedKey'],
          'transposedLyricsWithChords': event['transposedLyricsWithChords'],
        };
        // Session's offset ko naye song ke actual offset ke saath sync karo
        _session!['currentTransposeOffset'] = event['transposeOffset'] ?? 0;
      });
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _doTranspose(int delta) async {
    if (!_isLeader || _currentSongDisplay == null) return;
    try {
      // Sirf delta bhejo — current offset ka pata hone ki zaroorat nahi,
      // backend hi source of truth hai
      final event =
          await JamSessionService.transposeByDelta(widget.sessionId, delta);
      setState(() {
        _session!['currentTransposeOffset'] = event['transposeOffset'];
        _currentSongDisplay!['transposedKey'] = event['transposedKey'];
        _currentSongDisplay!['transposedLyricsWithChords'] =
            event['transposedLyricsWithChords'];
      });
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _resetTranspose() async {
    if (!_isLeader || _currentSongDisplay == null) return;
    final currentOffset = (_session?['currentTransposeOffset'] ?? 0) as int;
    if (currentOffset == 0) return; // already original key mein hai
    try {
      // Backend sirf delta accept karta hai, isliye offset ko 0 tak
      // wapas laane ke liye uska ulta delta bhej dete hain
      final event = await JamSessionService.transposeByDelta(
          widget.sessionId, -currentOffset);
      setState(() {
        _session!['currentTransposeOffset'] = event['transposeOffset'];
        _currentSongDisplay!['transposedKey'] = event['transposedKey'];
        _currentSongDisplay!['transposedLyricsWithChords'] =
            event['transposedLyricsWithChords'];
      });
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final session = _session ?? {};
    final name = session['name'] ?? 'Jam Session';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgAppBar,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.share, color: AppColors.textPrimary),
              onPressed: _copyInviteCode),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Participants'),
            Tab(text: 'Songs'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ParticipantsTab(participants: _participants),
          _currentSongDisplay == null
              ? JamSessionSongListTab(
                  sessionId: widget.sessionId,
                  songs: _songs,
                  isLeader: _isLeader,
                  onSwitchSong: _switchToSong,
                  onSnack: _showSnack,
                  onSongsChanged: (updated) => setState(() => _songs = updated),
                )
              : JamSessionSongDetailScreen(
                  currentSongDisplay: _currentSongDisplay!,
                  songs: _songs,
                  currentTransposeOffset:
                      (_session?['currentTransposeOffset'] ?? 0) as int,
                  isLeader: _isLeader,
                  onBack: () => setState(() => _currentSongDisplay = null),
                  onTranspose: _doTranspose,
                  onResetTranspose: _resetTranspose,
                  onSwitchSong: _switchToSong,
                ),
          JamSessionInfoTab(
            session: session,
            participantCount: _participants.length,
            isLeader: _isLeader,
            onCopyInviteCode: _copyInviteCode,
            onStartSession: _startSession,
            onEndSession: _endSession,
            onLeaveSession: _leaveSession,
          ),
        ],
      ),
    );
  }
}
