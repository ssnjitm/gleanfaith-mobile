import 'package:equatable/equatable.dart';

import '../../../../core/common/entities/content_language.dart';
import 'verse.dart';

/// One chapter of scripture, ready to render in the selected content language.
///
/// The bundled SQLite database only ships the English KJV, so a Nepali chapter
/// is fetched from the free remote endpoint. When that fetch fails the chapter
/// falls back to the offline English text and [isFallback] says so — the same
/// verse, in the other language, never silently swapped for a different one.
class BibleChapter extends Equatable {
  /// Canonical KJV book name — always English, always safe to deep-link to.
  final String book;

  /// The book name to render, in the selected language.
  ///
  /// English resolves to the canonical name; Nepali resolves to the Devanagari
  /// name the remote endpoint returns.
  final String bookName;

  final int chapter;

  /// Every verse of the chapter, in order.
  final List<Verse> verses;

  /// The language the chapter was requested in.
  final ContentLanguage language;

  /// True when the chapter could not be served in [language] and the other
  /// language was used instead. A fallback keeps the same book/chapter/verse,
  /// so it is a language fallback and never a different passage.
  final bool isFallback;

  const BibleChapter({
    required this.book,
    required this.bookName,
    required this.chapter,
    required this.verses,
    required this.language,
    this.isFallback = false,
  });

  /// The heading to render, e.g. `John 3` or `यूहन्‍ना ३`.
  String get title => '$bookName $chapter';

  @override
  List<Object?> get props => [
    book,
    bookName,
    chapter,
    verses,
    language,
    isFallback,
  ];
}
