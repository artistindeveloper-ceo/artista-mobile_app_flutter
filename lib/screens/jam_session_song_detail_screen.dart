import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays the currently active song's transposed lyrics/chords, plus a
/// leader-only transpose control bar and a song-switcher sidebar.
///
/// This widget is purely presentational — all state (current song, songs
/// list, transpose offset) lives in the parent JamSessionDetailScreen and is
/// passed in. Actions are reported back via callbacks so the parent (which
/// owns the WebSocket connection) stays the single source of truth.
class JamSessionSongDetailScreen extends StatelessWidget {
  final Map<String, dynamic> currentSongDisplay;
  final List<dynamic> songs;
  final int currentTransposeOffset;
  final bool isLeader;

  final VoidCallback onBack;
  final void Function(int delta) onTranspose;
  final VoidCallback onResetTranspose;
  final void Function(Map<String, dynamic> entry) onSwitchSong;

  // Lyrics-view accent colors (distinct from brand gold/magenta so
  // section markers & chords stay easy to scan against the dark bg).
  static const Color _sectionColor = Color(0xFF4DB6AC); // teal
  static const Color _chordColor = Color(0xFF64B5F6); // light blue

  const JamSessionSongDetailScreen({
    super.key,
    required this.currentSongDisplay,
    required this.songs,
    required this.currentTransposeOffset,
    required this.isLeader,
    required this.onBack,
    required this.onTranspose,
    required this.onResetTranspose,
    required this.onSwitchSong,
  });

  @override
  Widget build(BuildContext context) {
    final title = currentSongDisplay['title'] ?? 'Untitled';
    final currentKey = currentSongDisplay['transposedKey'] ?? '';
    final rawData = currentSongDisplay['transposedLyricsWithChords'] ?? '';
    final lines = rawData.toString().split('\n');
    final activeJamSongId = currentSongDisplay['jamSessionSongId'];

    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildHeader(title, currentKey),
              if (isLeader) _buildTransposeBar(),
              Expanded(child: _buildLyricsList(lines)),
            ],
          ),
        ),
        Container(width: 1, color: AppColors.border),
        SizedBox(
          width: 100,
          child: _buildSongSidebar(activeJamSongId),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String currentKey) {
    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Text('Key: $currentKey',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.gold)),
        ],
      ),
    );
  }

  Widget _buildTransposeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Transpose:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          IconButton(
            onPressed: () => onTranspose(-1),
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: AppColors.gold,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          Text('$currentTransposeOffset',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.gold)),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => onTranspose(1),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: AppColors.gold,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onResetTranspose,
            icon: const Icon(Icons.restart_alt, size: 20),
            color: AppColors.textTertiary,
            tooltip: 'Reset to original key',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList(List<String> lines) {
    return Container(
      color: AppColors.bgBase,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          final sectionMatch =
              RegExp(r'^\[([^\]]+)\]$').firstMatch(line.trim());
          if (sectionMatch != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(sectionMatch.group(1)!,
                  style: const TextStyle(
                      color: _sectionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            );
          }
          final chordMatches = RegExp(r'\[([^\]]+)\]').allMatches(line);
          final chords = chordMatches.map((m) => m.group(1)!).join('  ');
          final lyrics = line.replaceAll(RegExp(r'\[[^\]]+\]'), '');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chords.trim().isNotEmpty)
                Text(chords,
                    style: const TextStyle(
                        color: _chordColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 13)),
              if (lyrics.trim().isNotEmpty)
                Text(lyrics,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textPrimary)),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongSidebar(dynamic activeJamSongId) {
    return Container(
      color: AppColors.bgSurface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: AppColors.gold,
            child: const Text('Songs',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textOnGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No songs',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 11)))
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (ctx, i) {
                      final entry = songs[i];
                      final sTitle = entry['title'] ?? '';
                      final isSelected = activeJamSongId == entry['id'];
                      return GestureDetector(
                        onTap: () => onSwitchSong(entry),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border(
                              bottom:
                                  const BorderSide(color: AppColors.divider),
                              left: isSelected
                                  ? const BorderSide(
                                      color: AppColors.gold, width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            sTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
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
    );
  }
}
