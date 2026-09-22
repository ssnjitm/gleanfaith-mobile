import '../../../../core/services/database_service.dart';

/// Language-agnostic book codes used by the backend (e.g. `MAT`), aligned
/// one-to-one with [kjvCanonicalBooks] so we can map by index.
const List<String> _bibleBookCodes = [
  // Old Testament
  'GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT', '1SA', '2SA',
  '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH', 'EST', 'JOB', 'PSA', 'PRO',
  'ECC', 'SNG', 'ISA', 'JER', 'LAM', 'EZK', 'DAN', 'HOS', 'JOL', 'AMO',
  'OBA', 'JON', 'MIC', 'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL',
  // New Testament
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH',
  'PHP', 'COL', '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS',
  '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV',
];

/// Map a display book name (e.g. `'1 Samuel'`) to the backend's uppercased
/// book code (e.g. `'1SA'`). Falls back to the uppercased normalized name so
/// unknown/unusual inputs still round-trip.
String bookCodeForName(String bookName) {
  final canonical = normalizeBookName(bookName);
  final index = kjvCanonicalBooks.indexOf(canonical);
  if (index < 0 || index >= _bibleBookCodes.length) {
    return canonical.toUpperCase();
  }
  return _bibleBookCodes[index];
}

/// Map a backend book code (e.g. `'MAT'`) back to a canonical display name
/// (e.g. `'Matthew'`). Falls back to the raw code when unknown.
String bookNameForCode(String bookCode) {
  final clean = bookCode.trim().toUpperCase();
  final index = _bibleBookCodes.indexOf(clean);
  if (index < 0 || index >= kjvCanonicalBooks.length) {
    return bookCode;
  }
  return kjvCanonicalBooks[index];
}