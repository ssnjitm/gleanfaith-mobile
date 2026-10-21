import 'package:equatable/equatable.dart';

import '../../../../core/common/entities/content_language.dart';

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
  ///
  /// This is the **global** Bible-content language
  /// (`contentLanguageProvider`), not a card-local preference: the verse of
  /// the day, the reader, the fun facts and the quiz all follow it.
  final ContentLanguage language;

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

  bool get isNepali => language == ContentLanguage.nepali;

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
