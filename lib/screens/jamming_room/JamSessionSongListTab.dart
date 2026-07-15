import 'package:flutter/material.dart';

import '../../service/JamSessionService.dart';
import '../../service/SongService.dart';
import '../../theme/app_theme.dart';

class JamSessionSongListTab extends StatefulWidget {
  final int sessionId;
  final List<dynamic> songs;
  final bool isLeader;
  final void Function(Map<String, dynamic> entry) onSwitchSong;
  final void Function(String msg, {bool isError}) onSnack;
  final void Function(List<dynamic> updatedSongs) onSongsChanged;

  const JamSessionSongListTab({
    super.key,
    required this.sessionId,
    required this.songs,
    required this.isLeader,
    required this.onSwitchSong,
    required this.onSnack,
    required this.onSongsChanged,
  });

  @override
  State<JamSessionSongListTab> createState() => _JamSessionSongListTabState();
}

class _JamSessionSongListTabState extends State<JamSessionSongListTab> {
  void _openSongPicker() {
    if (!widget.isLeader) {
      widget.onSnack('Only the leader can add songs.', isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Songs',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              TabBar(
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.gold,
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
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textSecondary)));
        }
        final allSongs = snapshot.data ?? [];
        if (allSongs.isEmpty) {
          return const Center(
              child: Text('No songs in library yet.',
                  style: TextStyle(color: AppColors.textSecondary)));
        }

        String query = '';
        List<dynamic> filteredSongs = allSongs;

        return StatefulBuilder(
          builder: (context, setSearchState) {
            final addedSongIds = widget.songs.map((s) => s['songId']).toSet();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search songs by title or artist...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.bgSurfaceElevated,
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
                              style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredSongs.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.divider),
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
                                backgroundColor: AppColors.gold,
                                child: Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: AppColors.textOnGold)),
                              ),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              subtitle: artist.isNotEmpty
                                  ? Text(artist,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (key.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(key,
                                          style: const TextStyle(
                                              color: AppColors.gold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                  const SizedBox(width: 8),
                                  isAdded
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: AppColors.success,
                                              size: 28),
                                          onPressed: () async {
                                            final entry =
                                                widget.songs.firstWhere(
                                              (s) => s['songId'] == songId,
                                              orElse: () => null,
                                            );
                                            if (entry == null) return;
                                            try {
                                              await JamSessionService
                                                  .removeSongFromSetlist(
                                                      widget.sessionId,
                                                      entry['id']);
                                              final updated =
                                                  List<dynamic>.from(
                                                      widget.songs)
                                                    ..removeWhere((s) =>
                                                        s['songId'] == songId);
                                              widget.onSongsChanged(updated);
                                              setSearchState(() {});
                                              widget.onSnack(
                                                  '$title removed from session.');
                                            } catch (e) {
                                              widget.onSnack(e.toString(),
                                                  isError: true);
                                            }
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.gold,
                                              size: 28),
                                          onPressed: () async {
                                            if (widget.songs.any(
                                                (s) => s['songId'] == songId)) {
                                              return;
                                            }
                                            try {
                                              final newEntry =
                                                  await JamSessionService
                                                      .addSongToSetlist(
                                                          widget.sessionId,
                                                          songId);
                                              final updated =
                                                  List<dynamic>.from(
                                                      widget.songs);
                                              if (!updated.any((s) =>
                                                  s['id'] == newEntry['id'])) {
                                                updated.add(newEntry);
                                              }
                                              widget.onSongsChanged(updated);
                                              setSearchState(() {});
                                              widget.onSnack(
                                                  '$title added to session!');
                                            } catch (e) {
                                              widget.onSnack(e.toString(),
                                                  isError: true);
                                            }
                                          },
                                        ),
                                ],
                              ),
                              onTap: () async {
                                if (isAdded) return;
                                if (widget.songs
                                    .any((s) => s['songId'] == songId)) {
                                  return;
                                }
                                try {
                                  final newEntry =
                                      await JamSessionService.addSongToSetlist(
                                          widget.sessionId, songId);
                                  final updated =
                                      List<dynamic>.from(widget.songs)
                                        ..add(newEntry);
                                  widget.onSongsChanged(updated);
                                  setSearchState(() {});
                                  widget.onSnack('$title added to session!');
                                } catch (e) {
                                  widget.onSnack(e.toString(), isError: true);
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
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Song Title *')),
          const SizedBox(height: 12),
          TextField(
              controller: artistCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Artist')),
          const SizedBox(height: 12),
          TextField(
              controller: keyCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Key (e.g. C, G, Am, Abm)')),
          const SizedBox(height: 12),
          TextField(
              controller: chordsCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Chords (e.g. C G Am F)')),
          const SizedBox(height: 12),
          TextField(
              controller: lyricsCtrl,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Lyrics with chords [C]Tujhe [G]dekha to...')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
                  widget.onSnack(
                      'Song added to library! Now add it from Library tab.');
                } catch (e) {
                  widget.onSnack(e.toString(), isError: true);
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
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: widget.songs.isEmpty
          ? const Center(
              child: Text('No songs yet.',
                  style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: widget.songs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (ctx, i) {
                final entry = widget.songs[i];
                final title = entry['title'] ?? 'Untitled';
                final artist = entry['artist'] ?? '';
                final key = entry['originalKey'] ?? '';

                final tile = ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.textOnGold)),
                  ),
                  title: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  subtitle: Text(artist,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: key.toString().isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(key.toString(),
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold)),
                        )
                      : null,
                  onTap: () => widget.onSwitchSong(entry),
                );

                if (!widget.isLeader) return tile;

                return Dismissible(
                  key: ValueKey(entry['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            backgroundColor: AppColors.bgSurfaceElevated,
                            title: const Text('Remove song?',
                                style: TextStyle(color: AppColors.textPrimary)),
                            content: Text('Remove "$title" from this session?',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(dctx, true),
                                  child: const Text('Remove',
                                      style:
                                          TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    final updated = List<dynamic>.from(widget.songs)
                      ..removeAt(i);
                    widget.onSongsChanged(updated);
                    try {
                      await JamSessionService.removeSongFromSetlist(
                          widget.sessionId, entry['id']);
                      widget.onSnack('$title removed.');
                    } catch (e) {
                      widget.onSnack(e.toString(), isError: true);
                      final reverted = List<dynamic>.from(widget.songs)
                        ..insert(i, entry);
                      widget.onSongsChanged(
                          reverted); // fail hone par wapas dikhao
                    }
                  },
                  child: tile,
                );
              },
            ),
      floatingActionButton: widget.isLeader
          ? FloatingActionButton.extended(
              onPressed: _openSongPicker,
              backgroundColor: AppColors.magenta,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.music_note),
              label: const Text('Add Song'),
            )
          : null,
    );
  }
}
