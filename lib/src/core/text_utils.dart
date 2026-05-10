/// Capitalizes the first letter of every word, while preserving common
/// "all-caps" tokens that are widely recognized that way (SPF, BHA, AHA,
/// AM/PM, etc.).
String toTitleCase(String input) {
  final s = input.trim();
  if (s.isEmpty) return s;

  const keepUpper = {
    'SPF', 'AHA', 'BHA', 'PHA', 'EGF',
    'PM', 'AM', 'UV', 'UVA', 'UVB',
    'CBD', 'CBG', 'EWG', 'BPO',
  };

  // Split on whitespace, keep delimiters by re-joining with single spaces.
  return s.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;

    // Preserve numeric / percent / unit-style tokens (e.g. "10%", "0.5%").
    if (RegExp(r'^[\d.,%]+$').hasMatch(word)) return word;

    // Handle hyphenated compound words: capitalize each segment.
    if (word.contains('-')) {
      return word.split('-').map((seg) => _capSegment(seg, keepUpper)).join('-');
    }
    if (word.contains('/')) {
      return word.split('/').map((seg) => _capSegment(seg, keepUpper)).join('/');
    }
    return _capSegment(word, keepUpper);
  }).join(' ');
}

/// Returns a compact display-friendly version of a product name. Strips the
/// size / volume suffix that catalog rows usually carry after the first
/// comma, removes any parenthetical (e.g. "(50 ml)"), collapses internal
/// whitespace and softly caps the length so pill labels stay tidy.
String prettyProductName(String raw, {int maxLength = 28}) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  final commaIdx = s.indexOf(',');
  if (commaIdx > 0) s = s.substring(0, commaIdx);
  s = s.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length > maxLength) {
    s = '${s.substring(0, maxLength).trimRight()}…';
  }
  return s;
}

String _capSegment(String segment, Set<String> keepUpper) {
  if (segment.isEmpty) return segment;
  final upper = segment.toUpperCase();
  if (keepUpper.contains(upper)) return upper;
  // Allow apostrophes and other non-letter prefixes (e.g. "L'Oréal").
  final firstLetterIdx = segment.indexOf(RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]'));
  if (firstLetterIdx < 0) return segment;
  final before = segment.substring(0, firstLetterIdx);
  final letter = segment.substring(firstLetterIdx, firstLetterIdx + 1).toUpperCase();
  final rest = segment.substring(firstLetterIdx + 1).toLowerCase();
  return '$before$letter$rest';
}
