import 'package:equatable/equatable.dart';

/// Languages the Home "Verse of the Day" card can be shown in.
///
/// Both languages resolve the *same* curated verse (see `DailyVersePlan`) and
/// differ only in the text and the localised reference, so switching the toggle
/// re-renders one verse instead of swapping in a different one.
enum VerseLanguage {
  english('en', 'EN'),
  nepali('np', 'NP');

  const VerseLanguage(this.code, this.shortLabel);

  /// Persisted / wire code.
  final String code;

  /// Compact label rendered inside the `EN | NP` toggle.
  final String shortLabel;

  /// Tolerant parser for stored preferences. Accepts the aliases the
  /// `QuizLanguage` parser accepts so a value written by either surface still
  /// resolves, and falls back to English for anything unknown — a corrupt
  /// preference must never be able to leave the card blank.
  static VerseLanguage fromCode(String? code) {
    switch (code?.trim().toLowerCase()) {
      case 'np':
      case 'ne':
      case 'nep':
      case 'nepali':
        return VerseLanguage.nepali;
      default:
        return VerseLanguage.english;
    }
  }
}

/// One resolved verse for one day, already in the language to display.
///
/// Separate from `Verse` on purpose. `Verse.book` is the canonical KJV name the
/// Bible reader needs for its deep link, while [reference] is whatever the
/// reader should *see* — which for Nepali is the Devanagari book name
/// (`यूहन्‍ना 3:16`). Collapsing the two into a single `Verse` would either break
/// navigation or lose the localised reference.
class VerseOfTheDay extends Equatable {
  /// Text to render, in the active [language].
  final String text;

  /// Reference to render, in the active [language] (e.g. `Jeremiah 29:11`).
  final String reference;

  /// Canonical KJV book name — always English, always safe to deep-link to.
  final String book;

  final int chapter;
  final int verse;

  /// The language the user selected — i.e. what the card is *trying* to show.
  final VerseLanguage language;

  /// True when the body is not in [language] — the selected translation could
  /// not be reached and the *other* language was served for the same reference,
  /// or neither could be reached. The card uses this to render a short, honest
  /// notice rather than passing the wrong language off as a translation. Note
  /// that a fallback keeps the same book/chapter/verse, so it is a language
  /// fallback and never a different verse.
  final bool isFallback;

  const VerseOfTheDay({
    required this.text,
    required this.reference,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.language,
    this.isFallback = false,
  });

  bool get isNepali => language == VerseLanguage.nepali;

  @override
  List<Object?> get props => [
    text,
    reference,
    book,
    chapter,
    verse,
    language,
    isFallback,
  ];
}
