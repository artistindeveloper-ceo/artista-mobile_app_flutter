import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/ApiService.dart';
import '../theme/app_theme.dart';
import '../service/SongService.dart';

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
  List<dynamic> _songs = [];
  Map<String, dynamic>? _selectedSong;
  bool _isLoading = true;
  int _transposeSteps = 0;

  // All musical keys in order (sharps only)
  static const _keys = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // Flat → Sharp enharmonic equivalents
  static const _flatToSharp = {
    'Cb': 'B',
    'Db': 'C#',
    'Eb': 'D#',
    'Fb': 'E',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSession();
    _loadSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);
    try {
      final session = await ApiService.getSessionById(widget.sessionId);
      final participants = await ApiService.getSessionParticipants(widget.sessionId);
      setState(() {
        _session = session;
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await Songservice.getMySongs();
      setState(() => _songs = songs);
    } catch (_) {}
  }

  /// Normalize root: convert flat to sharp equivalent
  String _normalizeRoot(String root) {
    return _flatToSharp[root] ?? root;
  }

  /// Transpose a single chord string e.g. "Abm", "C#maj7", "Bb7"
  String _transposeChord(String chord) {
    if (_transposeSteps == 0) return chord;

    // Match root (e.g. Ab, C#, G) + suffix (e.g. m, maj7, sus2)
    final match = RegExp(r'^([A-G][b#]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;

    String root = match.group(1)!;
    final suffix = match.group(2) ?? '';

    // Convert flat to sharp
    root = _normalizeRoot(root);

    final idx = _keys.indexOf(root);
    if (idx == -1) return chord; // unknown root, return as-is

    final newIdx = (_keys.length + idx + _transposeSteps) % _keys.length;
    return '${_keys[newIdx]}$suffix';
  }

  /// Transpose all chords inside [brackets] in a line
  String _transposeText(String text) {
    if (_transposeSteps == 0) return text;
    return text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]'),
          (m) => '[${_transposeChord(m.group(1)!)}]',
    );
  }

  String _getCurrentKey() {
    final originalKey = _selectedSong?['originalKey']
        ?? _selectedSong?['key']
        ?? _selectedSong?['original_key']
        ?? 'C';

    // Normalize flat keys
    final normalized = _normalizeRoot(originalKey);
    final idx = _keys.indexOf(normalized);
    if (idx == -1) return originalKey;
    return _keys[(_keys.length + idx + _transposeSteps) % _keys.length];
  }

  Future<void> _startSession() async {
    try {
      await ApiService.startSession(widget.sessionId);
      _showSnack('Session started!');
      _loadSession();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _endSession() async {
    try {
      await ApiService.endSession(widget.sessionId);
      _showSnack('Session ended!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _leaveSession() async {
    try {
      await ApiService.leaveSession(widget.sessionId);
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

  void _openSongPicker() {
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      future: Songservice.getPublicSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final allSongs = snapshot.data ?? [];
        if (allSongs.isEmpty) {
          return const Center(child: Text('No songs in library yet.', style: TextStyle(color: Colors.grey)));
        }

        final addedIds = _songs.map((s) => s['id']).toSet();

        return ListView.separated(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(12),
          itemCount: allSongs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final song = allSongs[index];
            final songId = song['id'];
            final title = song['title'] ?? 'Untitled';
            final artist = song['artist'] ?? '';
            final key = song['originalKey'] ?? song['original_key'] ?? '';
            final isAdded = addedIds.contains(songId);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryDark,
                child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: artist.isNotEmpty ? Text(artist) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (key.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(key, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  isAdded
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                      : IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primaryDark, size: 28),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() { if (!isAdded) _songs.add(song); });
                      _showSnack('$title added to session!');
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  if (!isAdded) _songs.add(song);
                  _selectedSong = song;
                  _transposeSteps = 0;
                });
              },
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
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Song Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Artist', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Key (e.g. C, G, Am, Abm)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: chordsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Chords (e.g. C G Am F)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: lyricsCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Lyrics with chords [C]Tujhe [G]dekha to...', border: OutlineInputBorder())),
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
                  await Songservice.addSong(
                    title: titleCtrl.text.trim(),
                    artist: artistCtrl.text.trim(),
                    key: keyCtrl.text.trim(),
                    chords: chordsCtrl.text.trim(),
                    lyrics: lyricsCtrl.text.trim(),
                  );
                  _showSnack('Song added to library!');
                  _loadSongs();
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
    final status = session['status'] ?? 'PENDING';
    final inviteCode = session['inviteCode'] ?? '';
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _copyInviteCode),
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
          // ── Participants Tab ──
          _participants.isEmpty
              ? const Center(child: Text('No participants yet', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: _participants.length,
            itemBuilder: (ctx, i) {
              final p = _participants[i];
              final username = p['username'] ?? 'Unknown';
              final avatarUrl = p['avatarUrl'];
              final role = p['role'] ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                      : null,
                ),
                title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: role.isNotEmpty
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(role, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                )
                    : null,
              );
            },
          ),

          // ── Songs Tab ──
          _selectedSong == null ? _buildSongList() : _buildSongDetail(),

          // ── Info Tab ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Invite Code: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(inviteCode, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: _copyInviteCode, child: const Icon(Icons.copy, size: 18, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Participants: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${_participants.length}', style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const Spacer(),
                if (status.toUpperCase() == 'PENDING')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Session'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                if (isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endSession,
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _leaveSession,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Session'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 48)),
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
          ? const Center(child: Text('No songs yet. Add one!', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _songs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final song = _songs[i];
          final title = song['title'] ?? 'Untitled';
          final artist = song['artist'] ?? '';
          final key = song['key'] ?? song['originalKey'] ?? '';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryDark,
              child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(artist),
            trailing: key.isNotEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(key, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            )
                : null,
            onTap: () => setState(() { _selectedSong = song; _transposeSteps = 0; }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSongPicker,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.music_note),
        label: const Text('Add Song'),
      ),
    );
  }

  Widget _buildSongDetail() {
    final song = _selectedSong!;
    final title = song['title'] ?? 'Untitled';
    final rawData = song['lyricsWithChords']
        ?? song['lyrics_with_chords']
        ?? song['lyrics']
        ?? '';
    final currentKey = _getCurrentKey();
    final lines = rawData.split('\n');

    return Row(
      children: [
        // ── LEFT: Lyrics + Chords (70%) ──
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // Top bar
              Container(
                color: AppColors.primaryDark.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedSong = null),
                      child: const Icon(Icons.arrow_back, color: AppColors.primaryDark, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('Key: $currentKey',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),

              // Transpose bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Transpose:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => setState(() => _transposeSteps--),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppColors.primaryDark,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _transposeSteps == 0 ? '0' : (_transposeSteps > 0 ? '+$_transposeSteps' : '$_transposeSteps'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => setState(() => _transposeSteps++),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      color: AppColors.primaryDark,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _transposeSteps = 0),
                      child: const Text('Reset', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),

              // Lyrics + Chords
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index] as String;

                    // Section label e.g. [Verse], [Chorus]
                    final sectionMatch = RegExp(r'^\[([^\]]+)\]$').firstMatch(line.trim());
                    if (sectionMatch != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          sectionMatch.group(1)!,
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    }

                    // Normal line: extract chords from [brackets]
                    final chordMatches = RegExp(r'\[([^\]]+)\]').allMatches(line);
                    final chords = chordMatches
                        .map((m) => _transposeChord(m.group(1)!))
                        .join('  ');
                    final lyrics = line.replaceAll(RegExp(r'\[[^\]]+\]'), '');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chords.trim().isNotEmpty)
                          Text(chords, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
                        if (lyrics.trim().isNotEmpty)
                          Text(lyrics, style: const TextStyle(fontSize: 14, height: 1.5)),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── DIVIDER ──
        Container(width: 1, color: Colors.grey.shade300),

        // ── RIGHT: Session Songs List (30%) ──
        SizedBox(
          width: 100,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: AppColors.primaryDark,
                child: const Text('Songs', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(
                child: _songs.isEmpty
                    ? const Center(child: Text('No songs', style: TextStyle(color: Colors.grey, fontSize: 11)))
                    : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (ctx, i) {
                    final s = _songs[i];
                    final sTitle = s['title'] ?? '';
                    final isSelected = _selectedSong?['id'] == s['id'];
                    return GestureDetector(
                      onTap: () => setState(() { _selectedSong = s; _transposeSteps = 0; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryDark.withOpacity(0.15) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                            left: isSelected
                                ? const BorderSide(color: AppColors.primaryDark, width: 3)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(sTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryDark : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}