/// Pure transpose logic — semitone math, chord normalization, flat-to-sharp.
/// No Flutter dependency, so it's fully unit-testable.
class ChordTransposeUtils {
  static const keys = [
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

  static const flatToSharp = {
    'Cb': 'B',
    'Db': 'C#',
    'Eb': 'D#',
    'Fb': 'E',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  static String normalizeRoot(String root) => flatToSharp[root] ?? root;

  static String computeTransposedChord(String chord, int steps) {
    if (steps == 0) return chord;
    final match = RegExp(r'^([A-G][b#]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;
    final root = normalizeRoot(match.group(1)!);
    final suffix = match.group(2) ?? '';
    final idx = keys.indexOf(root);
    if (idx == -1) return chord;
    final newIdx = (keys.length + idx + steps) % keys.length;
    return '${keys[newIdx]}$suffix';
  }

  static String computeTransposedKey(String key, int steps) {
    final normalized = normalizeRoot(key);
    final idx = keys.indexOf(normalized);
    if (idx == -1) return key;
    return keys[(keys.length + idx + steps) % keys.length];
  }

  static String computeTransposedText(String text, int steps) {
    if (steps == 0) return text;
    return text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]'),
      (m) => '[${computeTransposedChord(m.group(1)!, steps)}]',
    );
  }
}
