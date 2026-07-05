import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/Session.dart';
import '../service/JamSessionService.dart';
import '../websocket/JamSessionSocketService.dart';
import '../service/SongService.dart';
import '../theme/app_theme.dart';
import 'jam_session_song_detail_screen.dart';
import 'jam_session_participants_tab.dart';

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

  static const _keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  static const _flatToSharp = {
    'Cb': 'B',
    'Db': 'C#',
    'Eb': 'D#',
    'Fb': 'E',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#'
  };

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
          'transposedKey': _computeTransposedKey(originalKey, transposeOffset),
          'transposedLyricsWithChords':
              _computeTransposedText(rawLyrics, transposeOffset),
        };
      });
    } catch (_) {}
  }

  String _normalizeRoot(String root) => _flatToSharp[root] ?? root;

  String _computeTransposedChord(String chord, int steps) {
    if (steps == 0) return chord;
    final match = RegExp(r'^([A-G][b#]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;
    String root = _normalizeRoot(match.group(1)!);
    final suffix = match.group(2) ?? '';
    final idx = _keys.indexOf(root);
    if (idx == -1) return chord;
    final newIdx = (_keys.length + idx + steps) % _keys.length;
    return '${_keys[newIdx]}$suffix';
  }

  String _computeTransposedKey(String key, int steps) {
    final normalized = _normalizeRoot(key);
    final idx = _keys.indexOf(normalized);
    if (idx == -1) return key;
    return _keys[(_keys.length + idx + steps) % _keys.length];
  }

  String _computeTransposedText(String text, int steps) {
    if (steps == 0) return text;
    return text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]'),
      (m) => '[${_computeTransposedChord(m.group(1)!, steps)}]',
    );
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
      backgroundColor: isError ? Colors.red : Colors.green,
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

  void _openSongPicker() {
    if (!_isLeader) {
      _showSnack('Only the leader can add songs.', isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Songs',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TabBar(
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryDark,
                tabs: const [
                  Tab(icon: Icon(Icons.library_music), text: 'Library'),
                  Tab(icon: Icon(Icons.add), text: 'Add New'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLibraryTab(ctx, scrollCtrl),
                    _buildAddSongFormTab(ctx),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryTab(BuildContext ctx, ScrollController scrollCtrl) {
    return FutureBuilder<List<dynamic>>(
      future: SongService.getPublicSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final allSongs = snapshot.data ?? [];
        if (allSongs.isEmpty) {
          return const Center(
              child: Text('No songs in library yet.',
                  style: TextStyle(color: Colors.grey)));
        }

        final addedSongIds = _songs.map((s) => s['songId']).toSet();

        String query = '';
        List<dynamic> filteredSongs = allSongs;

        return StatefulBuilder(
          builder: (context, setSearchState) {
            final addedSongIds = _songs.map((s) => s['songId']).toSet();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search songs by title or artist...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                    ),
                    onChanged: (value) {
                      setSearchState(() {
                        query = value.trim().toLowerCase();
                        filteredSongs = allSongs.where((song) {
                          final title =
                              (song['title'] ?? '').toString().toLowerCase();
                          final artist =
                              (song['artist'] ?? '').toString().toLowerCase();
                          return title.contains(query) ||
                              artist.contains(query);
                        }).toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredSongs.isEmpty
                      ? const Center(
                          child: Text('No matching songs.',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredSongs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final song = filteredSongs[index];
                            final songId = song['id'];
                            final title = song['title'] ?? 'Untitled';
                            final artist = song['artist'] ?? '';
                            final key = song['originalKey'] ??
                                song['original_key'] ??
                                '';
                            final isAdded = addedSongIds.contains(songId);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryDark,
                                child: Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: artist.isNotEmpty ? Text(artist) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (key.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(key,
                                          style: const TextStyle(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                  const SizedBox(width: 8),
                                  isAdded
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.green, size: 28),
                                          onPressed: () async {
                                            final entry = _songs.firstWhere(
                                              (s) => s['songId'] == songId,
                                              orElse: () => null,
                                            );
                                            if (entry == null) return;
                                            try {
                                              await JamSessionService
                                                  .removeSongFromSetlist(
                                                      widget.sessionId,
                                                      entry['id']);
                                              setState(() => _songs.removeWhere(
                                                  (s) =>
                                                      s['songId'] == songId));
                                              setSearchState(() {});
                                              _showSnack(
                                                  '$title removed from session.');
                                            } catch (e) {
                                              _showSnack(e.toString(),
                                                  isError: true);
                                            }
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primaryDark,
                                              size: 28),
                                          onPressed: () async {
                                            // Agar already add ho chuka hai to dobara mat karo
                                            if (_songs.any(
                                                (s) => s['songId'] == songId))
                                              return;
                                            try {
                                              final newEntry =
                                                  await JamSessionService
                                                      .addSongToSetlist(
                                                          widget.sessionId,
                                                          songId);
                                              if (!mounted) return;
                                              setState(() {
                                                if (!_songs.any((s) =>
                                                    s['id'] ==
                                                    newEntry['id'])) {
                                                  _songs.add(newEntry);
                                                }
                                              });
                                              setSearchState(() {});
                                              _showSnack(
                                                  '$title added to session!');
                                            } catch (e) {
                                              _showSnack(e.toString(),
                                                  isError: true);
                                            }
                                          },
                                        ),
                                ],
                              ),
                              onTap: () async {
                                if (isAdded) return;
                                if (_songs.any((s) => s['songId'] == songId))
                                  return;
                                try {
                                  final newEntry =
                                      await JamSessionService.addSongToSetlist(
                                          widget.sessionId, songId);
                                  setState(() => _songs.add(newEntry));
                                  setSearchState(() {});
                                  _showSnack('$title added to session!');
                                } catch (e) {
                                  _showSnack(e.toString(), isError: true);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAddSongFormTab(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    final lyricsCtrl = TextEditingController();
    final chordsCtrl = TextEditingController();
    final keyCtrl = TextEditingController(text: 'C');

    return SingleChildScrollView(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Song Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: artistCtrl,
              decoration: const InputDecoration(
                  labelText: 'Artist', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Key (e.g. C, G, Am, Abm)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: chordsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Chords (e.g. C G Am F)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: lyricsCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Lyrics with chords [C]Tujhe [G]dekha to...',
                  border: OutlineInputBorder())),
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
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await SongService.addSong(
                    title: titleCtrl.text.trim(),
                    artist: artistCtrl.text.trim(),
                    key: keyCtrl.text.trim(),
                    chords: chordsCtrl.text.trim(),
                    lyrics: lyricsCtrl.text.trim(),
                  );
                  _showSnack(
                      'Song added to library! Now add it from Library tab.');
                } catch (e) {
                  _showSnack(e.toString(), isError: true);
                }
              },
              child: const Text('Save to Library'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = _session ?? {};
    final name = session['name'] ?? 'Jam Session';
    final status = session['status'] ?? 'SCHEDULED';
    final inviteCode = session['inviteCode'] ?? '';
    final isActive = status.toString().toUpperCase() == 'LIVE';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _copyInviteCode),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
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
              ? _buildSongList()
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Status: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status.toString(),
                          style: TextStyle(
                              color: isActive ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Invite Code: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(inviteCode, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    GestureDetector(
                        onTap: _copyInviteCode,
                        child: const Icon(Icons.copy,
                            size: 18, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Participants: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${_participants.length}',
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const Spacer(),
                if (_isLeader && status.toString().toUpperCase() == 'SCHEDULED')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Session'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                if (_isLeader && isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endSession,
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _leaveSession,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Session'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 48)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return Scaffold(
      body: _songs.isEmpty
          ? const Center(
              child:
                  Text('No songs yet.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _songs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final entry = _songs[i];
                final title = entry['title'] ?? 'Untitled';
                final artist = entry['artist'] ?? '';
                final key = entry['originalKey'] ?? '';

                final tile = ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryDark,
                    child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(artist),
                  trailing: key.toString().isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primaryDark.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(key.toString(),
                              style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold)),
                        )
                      : null,
                  onTap: () => _switchToSong(entry),
                );

                // Sirf leader hi swipe-to-delete kar sake
                if (!_isLeader) return tile;

                return Dismissible(
                  key: ValueKey(entry['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Remove song?'),
                            content: Text('Remove "$title" from this session?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(dctx, true),
                                  child: const Text('Remove',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    setState(() => _songs.removeAt(i));
                    try {
                      await JamSessionService.removeSongFromSetlist(
                          widget.sessionId, entry['id']);
                      _showSnack('$title removed.');
                    } catch (e) {
                      _showSnack(e.toString(), isError: true);
                      setState(() => _songs.insert(
                          i, entry)); // fail hone par wapas dikhao
                    }
                  },
                  child: tile,
                );
              },
            ),
      floatingActionButton: _isLeader
          ? FloatingActionButton.extended(
              onPressed: _openSongPicker,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.music_note),
              label: const Text('Add Song'),
            )
          : null,
    );
  }
}
