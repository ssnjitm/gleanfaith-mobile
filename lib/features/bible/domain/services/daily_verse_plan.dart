/// A single curated verse in the 365-verse daily plan.
///
/// [book] is the USFM 3-letter identifier (`JHN`, `PSA`, `PHM`, …) because the
/// Free Use Bible API is addressed by book id, not by display name. Keeping the
/// id here means the Nepali lookup needs no English-name → id mapping, and no
/// book-name lookup can drift when a translation renames a book.
class DailyVerseRef {
  final String book;
  final int chapter;
  final int verse;

  const DailyVerseRef(this.book, this.chapter, this.verse);

  /// `JHN 3:16` — the form the API's chapter path and the English reader use.
  String get label => '$book $chapter:$verse';

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is DailyVerseRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);
}

/// One curated verse per day of the year — the source for the verse of the day
/// in **both** languages.
///
/// English and Nepali resolve the same entry here, so the `EN | NP` toggle only
/// changes the text and the reference, never which verse the day points at. All
/// 365 references were verified to return real, non-empty text from both
/// translations (`eng_web` and `npi_ulb`), which is what makes that guarantee
/// safe to show.
///
/// Deliberately a list of references only — no verse text is bundled, so this
/// adds roughly 10 KB of source (a few KB after compilation) instead of the
/// multi-megabyte cost of shipping a Nepali Bible. The text is fetched on demand
/// from a free, keyless endpoint (see `RemoteBibleDataSource`).
///
/// The plan is deliberately "powerful verse" oriented — promises, commands,
/// encouragements and anchor texts — rather than an attempt to cover the canon.
class DailyVersePlan {
  DailyVersePlan._();

  static const String _fallbackLabel = 'JHN 3:16';

  static const DailyVerseRef _fallback = DailyVerseRef('JHN', 3, 16);

  /// The 365 curated verses, in day-of-year order (index 0 → Jan 1).
  static const List<DailyVerseRef> references = <DailyVerseRef>[
    // ── Genesis ────────────────────────────────────────────────────────────
    DailyVerseRef('GEN', 1, 1),
    DailyVerseRef('GEN', 1, 26),
    DailyVerseRef('GEN', 9, 13),
    DailyVerseRef('GEN', 12, 2),
    DailyVerseRef('GEN', 15, 6),
    DailyVerseRef('GEN', 22, 14),
    DailyVerseRef('GEN', 28, 15),
    DailyVerseRef('GEN', 39, 21),
    // ── Exodus ─────────────────────────────────────────────────────────────
    DailyVerseRef('EXO', 3, 14),
    DailyVerseRef('EXO', 14, 14),
    DailyVerseRef('EXO', 15, 2),
    DailyVerseRef('EXO', 20, 12),
    DailyVerseRef('EXO', 24, 10),
    DailyVerseRef('EXO', 33, 14),
    // ── Leviticus / Numbers / Deuteronomy ──────────────────────────────────
    DailyVerseRef('LEV', 19, 18),
    DailyVerseRef('LEV', 25, 10),
    DailyVerseRef('NUM', 6, 24),
    DailyVerseRef('NUM', 23, 19),
    DailyVerseRef('DEU', 6, 4),
    DailyVerseRef('DEU', 6, 5),
    DailyVerseRef('DEU', 8, 3),
    DailyVerseRef('DEU', 31, 6),
    // ── Joshua / Judges / Ruth / Samuel ─────────────────────────────────────
    DailyVerseRef('JOS', 1, 8),
    DailyVerseRef('JOS', 1, 9),
    DailyVerseRef('RUT', 1, 16),
    DailyVerseRef('1SA', 16, 7),
    DailyVerseRef('2SA', 22, 31),
    // ── Kings / Chronicles / Ezra / Nehemiah / Esther ──────────────────────
    DailyVerseRef('1KI', 8, 57),
    DailyVerseRef('2KI', 19, 15),
    DailyVerseRef('1CH', 16, 11),
    DailyVerseRef('1CH', 29, 11),
    DailyVerseRef('2CH', 7, 3),
    DailyVerseRef('2CH', 20, 17),
    DailyVerseRef('NEH', 1, 5),
    DailyVerseRef('NEH', 4, 6),
    DailyVerseRef('NEH', 8, 10),
    DailyVerseRef('EST', 4, 14),
    // ── Job ────────────────────────────────────────────────────────────────
    DailyVerseRef('JOB', 1, 21),
    DailyVerseRef('JOB', 19, 25),
    DailyVerseRef('JOB', 23, 10),
    // ── Psalms (1) ─────────────────────────────────────────────────────────
    DailyVerseRef('PSA', 1, 3),
    DailyVerseRef('PSA', 4, 8),
    DailyVerseRef('PSA', 8, 3),
    DailyVerseRef('PSA', 9, 1),
    DailyVerseRef('PSA', 9, 2),
    DailyVerseRef('PSA', 16, 5),
    DailyVerseRef('PSA', 16, 8),
    DailyVerseRef('PSA', 17, 6),
    DailyVerseRef('PSA', 18, 2),
    DailyVerseRef('PSA', 19, 1),
    DailyVerseRef('PSA', 20, 7),
    DailyVerseRef('PSA', 23, 1),
    DailyVerseRef('PSA', 23, 4),
    DailyVerseRef('PSA', 25, 4),
    DailyVerseRef('PSA', 26, 8),
    DailyVerseRef('PSA', 27, 1),
    DailyVerseRef('PSA', 27, 11),
    DailyVerseRef('PSA', 27, 14),
    // ── Psalms (2) ─────────────────────────────────────────────────────────
    DailyVerseRef('PSA', 28, 7),
    DailyVerseRef('PSA', 29, 11),
    DailyVerseRef('PSA', 30, 5),
    DailyVerseRef('PSA', 31, 24),
    DailyVerseRef('PSA', 32, 3),
    DailyVerseRef('PSA', 33, 5),
    DailyVerseRef('PSA', 34, 8),
    DailyVerseRef('PSA', 36, 9),
    DailyVerseRef('PSA', 37, 4),
    DailyVerseRef('PSA', 37, 5),
    DailyVerseRef('PSA', 40, 1),
    DailyVerseRef('PSA', 40, 2),
    DailyVerseRef('PSA', 41, 10),
    DailyVerseRef('PSA', 42, 11),
    DailyVerseRef('PSA', 43, 2),
    DailyVerseRef('PSA', 46, 1),
    DailyVerseRef('PSA', 46, 10),
    // ── Psalms (3) ─────────────────────────────────────────────────────────
    DailyVerseRef('PSA', 51, 1),
    DailyVerseRef('PSA', 51, 10),
    DailyVerseRef('PSA', 51, 12),
    DailyVerseRef('PSA', 51, 15),
    DailyVerseRef('PSA', 52, 8),
    DailyVerseRef('PSA', 55, 1),
    DailyVerseRef('PSA', 56, 3),
    DailyVerseRef('PSA', 57, 1),
    DailyVerseRef('PSA', 59, 1),
    DailyVerseRef('PSA', 60, 12),
    DailyVerseRef('PSA', 62, 5),
    DailyVerseRef('PSA', 63, 1),
    DailyVerseRef('PSA', 65, 2),
    DailyVerseRef('PSA', 66, 1),
    DailyVerseRef('PSA', 67, 1),
    DailyVerseRef('PSA', 68, 6),
    DailyVerseRef('PSA', 70, 4),
    DailyVerseRef('PSA', 71, 8),
    DailyVerseRef('PSA', 72, 18),
    DailyVerseRef('PSA', 73, 26),
    DailyVerseRef('PSA', 75, 7),
    DailyVerseRef('PSA', 78, 4),
    DailyVerseRef('PSA', 84, 11),
    DailyVerseRef('PSA', 85, 10),
    DailyVerseRef('PSA', 86, 5),
    // ── Psalms (4) ─────────────────────────────────────────────────────────
    DailyVerseRef('PSA', 90, 12),
    DailyVerseRef('PSA', 90, 17),
    DailyVerseRef('PSA', 91, 1),
    DailyVerseRef('PSA', 91, 2),
    DailyVerseRef('PSA', 91, 5),
    DailyVerseRef('PSA', 92, 1),
    DailyVerseRef('PSA', 93, 5),
    DailyVerseRef('PSA', 94, 19),
    DailyVerseRef('PSA', 95, 6),
    DailyVerseRef('PSA', 96, 1),
    DailyVerseRef('PSA', 98, 1),
    DailyVerseRef('PSA', 100, 2),
    DailyVerseRef('PSA', 101, 4),
    DailyVerseRef('PSA', 103, 1),
    DailyVerseRef('PSA', 103, 2),
    DailyVerseRef('PSA', 103, 3),
    DailyVerseRef('PSA', 104, 1),
    DailyVerseRef('PSA', 105, 1),
    DailyVerseRef('PSA', 105, 3),
    DailyVerseRef('PSA', 106, 1),
    DailyVerseRef('PSA', 107, 1),
    DailyVerseRef('PSA', 108, 3),
    DailyVerseRef('PSA', 111, 1),
    DailyVerseRef('PSA', 112, 7),
    DailyVerseRef('PSA', 113, 1),
    DailyVerseRef('PSA', 114, 1),
    DailyVerseRef('PSA', 115, 1),
    DailyVerseRef('PSA', 116, 13),
    DailyVerseRef('PSA', 117, 1),
    DailyVerseRef('PSA', 118, 6),
    DailyVerseRef('PSA', 118, 10),
    DailyVerseRef('PSA', 118, 24),
    // ── Psalms (5) ─────────────────────────────────────────────────────────
    DailyVerseRef('PSA', 119, 11),
    DailyVerseRef('PSA', 119, 105),
    DailyVerseRef('PSA', 119, 165),
    DailyVerseRef('PSA', 121, 1),
    DailyVerseRef('PSA', 122, 2),
    DailyVerseRef('PSA', 124, 8),
    DailyVerseRef('PSA', 126, 5),
    DailyVerseRef('PSA', 127, 1),
    DailyVerseRef('PSA', 128, 6),
    DailyVerseRef('PSA', 130, 5),
    DailyVerseRef('PSA', 132, 8),
    DailyVerseRef('PSA', 136, 1),
    DailyVerseRef('PSA', 138, 8),
    DailyVerseRef('PSA', 139, 7),
    DailyVerseRef('PSA', 139, 14),
    DailyVerseRef('PSA', 140, 5),
    DailyVerseRef('PSA', 141, 1),
    DailyVerseRef('PSA', 143, 8),
    DailyVerseRef('PSA', 144, 9),
    DailyVerseRef('PSA', 145, 1),
    DailyVerseRef('PSA', 145, 9),
    DailyVerseRef('PSA', 146, 5),
    DailyVerseRef('PSA', 146, 7),
    DailyVerseRef('PSA', 147, 3),
    DailyVerseRef('PSA', 147, 4),
    DailyVerseRef('PSA', 148, 5),
    DailyVerseRef('PSA', 149, 1),
    DailyVerseRef('PSA', 150, 1),
    // ── Proverbs ───────────────────────────────────────────────────────────
    DailyVerseRef('PRO', 1, 7),
    DailyVerseRef('PRO', 3, 5),
    DailyVerseRef('PRO', 3, 6),
    DailyVerseRef('PRO', 4, 23),
    DailyVerseRef('PRO', 9, 10),
    DailyVerseRef('PRO', 10, 9),
    DailyVerseRef('PRO', 10, 22),
    DailyVerseRef('PRO', 10, 24),
    DailyVerseRef('PRO', 11, 2),
    DailyVerseRef('PRO', 11, 14),
    DailyVerseRef('PRO', 12, 25),
    DailyVerseRef('PRO', 13, 20),
    DailyVerseRef('PRO', 15, 1),
    DailyVerseRef('PRO', 15, 3),
    DailyVerseRef('PRO', 16, 3),
    DailyVerseRef('PRO', 16, 9),
    DailyVerseRef('PRO', 16, 18),
    DailyVerseRef('PRO', 16, 24),
    DailyVerseRef('PRO', 17, 9),
    DailyVerseRef('PRO', 18, 10),
    DailyVerseRef('PRO', 18, 21),
    DailyVerseRef('PRO', 18, 24),
    DailyVerseRef('PRO', 19, 11),
    DailyVerseRef('PRO', 20, 7),
    DailyVerseRef('PRO', 20, 22),
    DailyVerseRef('PRO', 21, 21),
    DailyVerseRef('PRO', 21, 23),
    DailyVerseRef('PRO', 22, 6),
    DailyVerseRef('PRO', 24, 16),
    DailyVerseRef('PRO', 27, 1),
    DailyVerseRef('PRO', 27, 17),
    DailyVerseRef('PRO', 28, 13),
    DailyVerseRef('PRO', 29, 25),
    DailyVerseRef('PRO', 30, 5),
    DailyVerseRef('PRO', 31, 25),
    // ── Ecclesiastes / Song / Isaiah ────────────────────────────────────────
    DailyVerseRef('ECC', 3, 1),
    DailyVerseRef('ECC', 12, 13),
    DailyVerseRef('SNG', 8, 7),
    DailyVerseRef('ISA', 6, 3),
    DailyVerseRef('ISA', 9, 6),
    DailyVerseRef('ISA', 26, 3),
    DailyVerseRef('ISA', 30, 15),
    DailyVerseRef('ISA', 40, 8),
    DailyVerseRef('ISA', 40, 31),
    DailyVerseRef('ISA', 41, 10),
    DailyVerseRef('ISA', 43, 2),
    DailyVerseRef('ISA', 43, 19),
    DailyVerseRef('ISA', 45, 13),
    DailyVerseRef('ISA', 53, 5),
    DailyVerseRef('ISA', 55, 6),
    DailyVerseRef('ISA', 55, 8),
    DailyVerseRef('ISA', 55, 11),
    DailyVerseRef('ISA', 58, 6),
    DailyVerseRef('ISA', 59, 1),
    DailyVerseRef('ISA', 60, 1),
    DailyVerseRef('ISA', 61, 1),
    DailyVerseRef('ISA', 61, 3),
    DailyVerseRef('ISA', 62, 3),
    DailyVerseRef('ISA', 64, 8),
    DailyVerseRef('ISA', 65, 17),
    // ── Jeremiah / Lamentations / Ezekiel / Daniel ─────────────────────────
    DailyVerseRef('JER', 29, 11),
    DailyVerseRef('JER', 33, 3),
    DailyVerseRef('LAM', 3, 22),
    DailyVerseRef('EZK', 36, 26),
    DailyVerseRef('DAN', 6, 10),
    // ── Minor prophets ─────────────────────────────────────────────────────
    DailyVerseRef('HOS', 6, 6),
    DailyVerseRef('JOL', 2, 28),
    DailyVerseRef('AMO', 3, 3),
    DailyVerseRef('JON', 2, 2),
    DailyVerseRef('MIC', 5, 4),
    DailyVerseRef('MIC', 6, 8),
    DailyVerseRef('HAB', 2, 4),
    DailyVerseRef('ZEC', 4, 6),
    DailyVerseRef('ZEC', 9, 9),
    DailyVerseRef('MAL', 3, 10),
    DailyVerseRef('MAL', 4, 2),
    // ── Matthew ────────────────────────────────────────────────────────────
    DailyVerseRef('MAT', 5, 8),
    DailyVerseRef('MAT', 5, 9),
    DailyVerseRef('MAT', 5, 14),
    DailyVerseRef('MAT', 5, 16),
    DailyVerseRef('MAT', 5, 44),
    DailyVerseRef('MAT', 6, 33),
    DailyVerseRef('MAT', 6, 34),
    DailyVerseRef('MAT', 7, 7),
    DailyVerseRef('MAT', 11, 28),
    DailyVerseRef('MAT', 18, 20),
    DailyVerseRef('MAT', 22, 37),
    DailyVerseRef('MAT', 24, 35),
    DailyVerseRef('MAT', 25, 21),
    DailyVerseRef('MAT', 28, 20),
    // ── Mark / Luke ────────────────────────────────────────────────────────
    DailyVerseRef('MRK', 10, 27),
    DailyVerseRef('MRK', 12, 30),
    DailyVerseRef('MRK', 16, 15),
    DailyVerseRef('LUK', 1, 37),
    DailyVerseRef('LUK', 6, 31),
    DailyVerseRef('LUK', 6, 36),
    DailyVerseRef('LUK', 6, 38),
    DailyVerseRef('LUK', 10, 27),
    DailyVerseRef('LUK', 12, 34),
    DailyVerseRef('LUK', 15, 20),
    DailyVerseRef('LUK', 18, 27),
    // ── John ───────────────────────────────────────────────────────────────
    DailyVerseRef('JHN', 1, 1),
    DailyVerseRef('JHN', 1, 5),
    DailyVerseRef('JHN', 3, 16),
    DailyVerseRef('JHN', 3, 30),
    DailyVerseRef('JHN', 4, 24),
    DailyVerseRef('JHN', 6, 35),
    DailyVerseRef('JHN', 8, 12),
    DailyVerseRef('JHN', 8, 32),
    DailyVerseRef('JHN', 10, 10),
    DailyVerseRef('JHN', 11, 25),
    DailyVerseRef('JHN', 13, 34),
    DailyVerseRef('JHN', 14, 1),
    DailyVerseRef('JHN', 14, 6),
    DailyVerseRef('JHN', 14, 27),
    DailyVerseRef('JHN', 15, 5),
    DailyVerseRef('JHN', 16, 33),
    // ── Acts ───────────────────────────────────────────────────────────────
    DailyVerseRef('ACT', 1, 8),
    DailyVerseRef('ACT', 16, 31),
    DailyVerseRef('ACT', 17, 11),
    DailyVerseRef('ACT', 20, 35),
    // ── Romans ─────────────────────────────────────────────────────────────
    DailyVerseRef('ROM', 3, 23),
    DailyVerseRef('ROM', 5, 8),
    DailyVerseRef('ROM', 8, 1),
    DailyVerseRef('ROM', 8, 6),
    DailyVerseRef('ROM', 8, 28),
    DailyVerseRef('ROM', 8, 38),
    DailyVerseRef('ROM', 10, 17),
    DailyVerseRef('ROM', 12, 1),
    DailyVerseRef('ROM', 12, 2),
    DailyVerseRef('ROM', 12, 12),
    DailyVerseRef('ROM', 15, 4),
    DailyVerseRef('ROM', 15, 7),
    DailyVerseRef('ROM', 15, 13),
    // ── Corinthians / Galatians / Ephesians ─────────────────────────────────
    DailyVerseRef('1CO', 13, 4),
    DailyVerseRef('1CO', 13, 8),
    DailyVerseRef('1CO', 15, 58),
    DailyVerseRef('1CO', 16, 14),
    DailyVerseRef('2CO', 4, 16),
    DailyVerseRef('2CO', 5, 7),
    DailyVerseRef('2CO', 9, 7),
    DailyVerseRef('2CO', 12, 9),
    DailyVerseRef('GAL', 2, 20),
    DailyVerseRef('GAL', 5, 1),
    DailyVerseRef('GAL', 5, 22),
    DailyVerseRef('GAL', 5, 23),
    DailyVerseRef('GAL', 6, 9),
    DailyVerseRef('EPH', 2, 8),
    DailyVerseRef('EPH', 2, 10),
    DailyVerseRef('EPH', 4, 32),
    DailyVerseRef('EPH', 6, 10),
    DailyVerseRef('EPH', 6, 16),
    // ── Philippians / Colossians / Thessalonians ───────────────────────────
    DailyVerseRef('PHP', 1, 6),
    DailyVerseRef('PHP', 2, 14),
    DailyVerseRef('PHP', 4, 6),
    DailyVerseRef('PHP', 4, 13),
    DailyVerseRef('PHP', 4, 19),
    DailyVerseRef('COL', 1, 17),
    DailyVerseRef('COL', 3, 23),
    DailyVerseRef('COL', 3, 24),
    DailyVerseRef('1TH', 5, 16),
    DailyVerseRef('1TH', 5, 18),
    DailyVerseRef('1TH', 5, 21),
    DailyVerseRef('2TH', 3, 13),
    // ── Pastoral epistles ───────────────────────────────────────────────────
    DailyVerseRef('1TI', 4, 12),
    DailyVerseRef('1TI', 6, 12),
    DailyVerseRef('2TI', 1, 7),
    DailyVerseRef('2TI', 3, 16),
    DailyVerseRef('2TI', 3, 17),
    DailyVerseRef('TIT', 2, 11),
    DailyVerseRef('PHM', 1, 6),
    // ── Hebrews / James ─────────────────────────────────────────────────────
    DailyVerseRef('HEB', 4, 12),
    DailyVerseRef('HEB', 11, 1),
    DailyVerseRef('HEB', 12, 1),
    DailyVerseRef('HEB', 12, 2),
    DailyVerseRef('HEB', 13, 8),
    DailyVerseRef('JAS', 1, 5),
    DailyVerseRef('JAS', 1, 17),
    DailyVerseRef('JAS', 1, 19),
    DailyVerseRef('JAS', 2, 17),
    DailyVerseRef('JAS', 4, 7),
    DailyVerseRef('JAS', 4, 10),
    // ── Peter / John / Jude / Revelation ────────────────────────────────────
    DailyVerseRef('1PE', 1, 16),
    DailyVerseRef('1PE', 2, 9),
    DailyVerseRef('1PE', 4, 8),
    DailyVerseRef('1PE', 5, 7),
    DailyVerseRef('2PE', 1, 3),
    DailyVerseRef('1JN', 1, 9),
    DailyVerseRef('1JN', 4, 8),
    DailyVerseRef('1JN', 4, 18),
    DailyVerseRef('1JN', 4, 19),
    DailyVerseRef('1JN', 5, 21),
    DailyVerseRef('JUD', 1, 24),
    DailyVerseRef('REV', 1, 8),
    DailyVerseRef('REV', 3, 20),
    DailyVerseRef('REV', 4, 11),
    DailyVerseRef('REV', 5, 5),
    DailyVerseRef('REV', 7, 14),
    DailyVerseRef('REV', 11, 15),
    DailyVerseRef('REV', 12, 11),
    DailyVerseRef('REV', 19, 1),
    DailyVerseRef('REV', 21, 4),
    DailyVerseRef('REV', 21, 7),
    DailyVerseRef('REV', 22, 20),
    DailyVerseRef('REV', 22, 21),
  ];

  /// Number of verses in a full plan year.
  static const int length = 365;

  /// Reference used when [date] cannot be mapped (never in practice — every
  /// day of every year maps to an index — but a total API failure still needs a
  /// stable answer).
  static const DailyVerseRef fallback = _fallback;

  /// String form of [fallback], for logging and error messages.
  static const String fallbackLabel = _fallbackLabel;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Day of the year, 1 (Jan 1) through 365/366.
  ///
  /// Computed on UTC-normalised dates on purpose: `DateTime(y, m, d)` values
  /// live in local time, and `difference()` between two local midnights is not
  /// always a whole number of days in a DST zone, which would silently shift
  /// the day by one twice a year.
  static int dayOfYear(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    return day.difference(DateTime.utc(day.year, 1, 1)).inDays + 1;
  }

  /// Index into [references] for [date].
  ///
  /// The plan is laid out on a 365-day calendar. In a leap year the offset
  /// applied from 1 March keeps every date mapped to the verse a non-leap year
  /// would show, so 29 February deliberately repeats 1 March's verse instead of
  /// pushing the whole year forward and leaving the final verse unreachable.
  static int indexFor(DateTime date) {
    final day = dayOfYear(date);
    final leap = isLeapYear(date.year);
    final offset = leap && day > 60 ? 1 : 0;
    return (day - 1 - offset).clamp(0, length - 1);
  }

  /// The curated verse scheduled for [date].
  static DailyVerseRef forDate(DateTime date) {
    if (references.length != length) {
      // A mis-sized plan must never index out of range; the assertions in the
      // test suite catch this, and the modulo keeps the app alive until then.
      return references[dayOfYear(date) % references.length];
    }
    return references[indexFor(date)];
  }
}
