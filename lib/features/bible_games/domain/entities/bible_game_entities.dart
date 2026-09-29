import 'package:equatable/equatable.dart';

import 'bible_game_localization.dart';

/// A canonical Bible book with the counts the games need. Built from the
/// seeded `bible_books` table joined with `bible_verses`.
///
/// [name] is the **identity** key (the DB/KJV name) and is what every equality
/// check, list index and option value uses — it never changes. [displayName]
/// is the **rendered** name for the active language, produced by
/// [displayNameFor]. Keeping the two apart is what lets Nepali mode relabel a
/// book without disturbing the round logic.
class BibleGameBook extends Equatable {
  /// KJV/DB name. Stable identity, also the English display name.
  final String name;

  /// Name to render, in the currently selected language. Empty means "not
  /// localized yet" — see [displayName], which then reports [name].
  final String displayName;

  final String slug;
  final String testament;
  final int chapterCount;
  final int verseCount;

  /// 0-indexed position in the canonical 66-book ordering (Genesis = 0).
  final int canonicalIndex;

  const BibleGameBook({
    required this.name,
    required this.slug,
    required this.testament,
    required this.chapterCount,
    required this.verseCount,
    required this.canonicalIndex,
    this.displayName = '',
  });

  /// The label to put in front of the player. Falls back to the DB name when
  /// no language has been applied yet.
  String get label => displayName.isEmpty ? name : displayName;

  factory BibleGameBook.fromDbRow(
    Map<String, dynamic> row, {
    required int canonicalIndex,
  }) {
    return BibleGameBook(
      name: row['book'] as String? ?? '',
      slug: row['book_slug'] as String? ?? '',
      testament: row['testament'] as String? ?? '',
      chapterCount: _asInt(row['chapter_count']),
      verseCount: _asInt(row['verse_count']),
      canonicalIndex: canonicalIndex,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  bool get isOldTestament => testament == 'Old Testament';
  bool get isNewTestament => testament == 'New Testament';

  /// The name to render in [language], resolved **database first**:
  /// English uses the DB name, Nepali uses the inline catalog name and falls
  /// back to the DB name when the catalog has no entry.
  String displayNameFor(BibleGameLanguage language) {
    if (language == BibleGameLanguage.english) return name;
    final translated = bibleGameBookDataFor(slug: slug, name: name)?.nameNp;
    if (translated == null || translated.isEmpty) return name;
    return translated;
  }

  /// A copy of this book with [displayName] and [language] applied.
  ///
  /// Counts are *also* patched here: when the database reported 0 (fallback
  /// mode, e.g. web) the inline catalog supplies the canonical figure, so
  /// Higher / Lower stays playable with no database at all. A real non-zero DB
  /// count always wins.
  ///
  /// Must be safe to call in **both** directions on an already-localized copy,
  /// because the `EN | NP` toggle re-localizes the same objects. The
  /// already-localized name therefore has to be part of the "nothing changed"
  /// check — comparing only against the DB [name] made English a no-op and left
  /// a Nepali `displayName` stuck on screen after switching back.
  BibleGameBook localized(BibleGameLanguage language) {
    final data = bibleGameBookDataFor(slug: slug, name: name);
    final resolvedName = displayNameFor(language);
    final resolvedChapters =
        chapterCount > 0 ? chapterCount : (data?.chapters ?? 0);
    final resolvedVerses = verseCount > 0 ? verseCount : (data?.verses ?? 0);
    if (resolvedName == label &&
        resolvedChapters == chapterCount &&
        resolvedVerses == verseCount) {
      return this;
    }
    return copyWith(
      displayName: resolvedName,
      chapterCount: resolvedChapters,
      verseCount: resolvedVerses,
    );
  }

  BibleGameBook copyWith({
    String? name,
    String? displayName,
    String? slug,
    String? testament,
    int? chapterCount,
    int? verseCount,
    int? canonicalIndex,
  }) {
    return BibleGameBook(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      slug: slug ?? this.slug,
      testament: testament ?? this.testament,
      chapterCount: chapterCount ?? this.chapterCount,
      verseCount: verseCount ?? this.verseCount,
      canonicalIndex: canonicalIndex ?? this.canonicalIndex,
    );
  }

  @override
  List<Object?> get props => [
    name,
    slug,
    testament,
    chapterCount,
    verseCount,
    canonicalIndex,
  ];
}

/// A single verse in the shape the games need (no fpdart/Flutter imports).
///
/// [text] is always the offline-DB KJV text — the source of truth. [displayText]
/// is what gets rendered: for English it is the same string, for Nepali it is
/// the inline catalog translation when one exists. [hasTranslation] reports
/// which of the two happened so the UI can show a "no Nepali translation" hint
/// instead of silently rendering English.
class BibleGameVerse extends Equatable {
  final String book;
  final int chapter;
  final int verse;

  /// The KJV text straight from the database.
  final String text;

  /// The text to render in the active language.
  final String displayText;

  /// The book name to render in the active language.
  final String displayBook;

  /// Whether [displayText] is a real translation rather than the English
  /// fallback.
  final bool hasTranslation;

  const BibleGameVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.displayText = '',
    this.displayBook = '',
    this.hasTranslation = true,
  });

  factory BibleGameVerse.fromDbRow(Map<String, dynamic> row) {
    return BibleGameVerse(
      book: row['book'] as String? ?? '',
      chapter: row['chapter'] is int
          ? row['chapter'] as int
          : (int.tryParse('${row['chapter']}') ?? 0),
      verse: row['verse'] is int
          ? row['verse'] as int
          : (int.tryParse('${row['verse']}') ?? 0),
      text: row['text'] as String? ?? '',
    );
  }

  /// The text to render, falling back to the KJV [text].
  String get label => displayText.isEmpty ? text : displayText;

  /// The book name to render, falling back to the DB [book].
  String get bookLabel => displayBook.isEmpty ? book : displayBook;

  String get formattedReference => '$book $chapter:$verse';

  /// The reference with the book name and numerals in [language]'s style, e.g.
  /// `John 3:16` or `यूहन्ना ३:१६`.
  String referenceFor(BibleGameLanguage language) {
    final displayBook =
        bibleGameBookDataForName(book)?.nameFor(language) ?? book;
    return '$displayBook ${formatCount(chapter, language)}:'
        '${formatCount(verse, language)}';
  }

  /// Resolves the display text/book for [language].
  ///
  /// **Database first:** the KJV [text] stays authoritative. The inline
  /// catalog only supplies a Nepali rendering when it holds a match for this
  /// exact book/chapter/verse, in which case [hasTranslation] is true. Any
  /// other case keeps English and flags the fallback.
  BibleGameVerse localized(BibleGameLanguage language) {
    if (language == BibleGameLanguage.english) return this;
    final entry = bibleGameVerseDataFor(
      bookName: book,
      chapter: chapter,
      verse: verse,
    );
    final translated = entry?.textFor(language);
    final bookName = entry?.bookNameFor(language) ??
        bibleGameBookDataForName(book)?.nameFor(language);
    if (translated == null || translated.isEmpty) {
      return copyWith(hasTranslation: false, displayBook: bookName ?? '');
    }
    return copyWith(
      displayText: translated,
      displayBook: bookName ?? '',
      hasTranslation: true,
    );
  }

  BibleGameVerse copyWith({
    String? book,
    int? chapter,
    int? verse,
    String? text,
    String? displayText,
    String? displayBook,
    bool? hasTranslation,
  }) {
    return BibleGameVerse(
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      displayText: displayText ?? this.displayText,
      displayBook: displayBook ?? this.displayBook,
      hasTranslation: hasTranslation ?? this.hasTranslation,
    );
  }

  @override
  List<Object?> get props => [
    book,
    chapter,
    verse,
    text,
    displayText,
    displayBook,
    hasTranslation,
  ];
}

/// A stat about an extreme verse (longest/shortest) for the Fun Facts trivia.
class BibleVerseStat extends Equatable {
  final String reference;
  final int length;
  final String text;

  const BibleVerseStat({
    required this.reference,
    required this.length,
    required this.text,
  });

  @override
  List<Object?> get props => [reference, length, text];
}

class BibleGameExtremes extends Equatable {
  final BibleVerseStat longest;
  final BibleVerseStat shortest;

  const BibleGameExtremes({
    required this.longest,
    required this.shortest,
  });

  @override
  List<Object?> get props => [longest, shortest];
}

/// The data bundle every game page needs to start a session.
class BibleGamesData {
  final List<BibleGameBook> books;
  final BibleGameExtremes? extremes;

  const BibleGamesData({
    required this.books,
    this.extremes,
  });

  bool get isEmpty => books.isEmpty;

  /// This bundle with every book relabelled for [language] and its counts
  /// patched from the inline catalog when the database reported none.
  ///
  /// The engine and the widgets both read the *localized* books, so a round
  /// built from this list renders correctly without any per-widget language
  /// lookup. Identity is untouched — [BibleGameBook.name] stays the DB name.
  BibleGamesData localized(BibleGameLanguage language) {
    if (language == BibleGameLanguage.english) return this;
    return BibleGamesData(
      books: [for (final book in books) book.localized(language)],
      extremes: extremes,
    );
  }
}

/// Guess the Book — show a complete verse, pick which book it comes from.
///
/// [correctBook] and [options] hold DB book names (identity). The `display*`
/// fields hold the same values relabelled for the active language, so the
/// widgets can render without re-resolving anything.
class GuessBookRound {
  final String snippet;
  final String fullText;
  final String reference;
  final String correctBook;
  final List<String> options;
  final int wordsShown;
  final String hint;

  /// The book name to render for [correctBook].
  final String displayCorrectBook;

  /// The option labels to render, index-aligned with [options].
  final List<String> displayOptions;

  /// The reference to render, with the localized book name and numerals.
  final String displayReference;

  /// Whether [fullText] is a real translation rather than the KJV fallback.
  final bool hasTranslation;

  const GuessBookRound({
    required this.snippet,
    required this.fullText,
    required this.reference,
    required this.correctBook,
    required this.options,
    required this.wordsShown,
    required this.hint,
    this.displayCorrectBook = '',
    this.displayOptions = const [],
    this.displayReference = '',
    this.hasTranslation = true,
  });

  /// The correct book to render.
  String get correctBookLabel =>
      displayCorrectBook.isEmpty ? correctBook : displayCorrectBook;

  /// The reference to render.
  String get referenceLabel =>
      displayReference.isEmpty ? reference : displayReference;
}

/// Higher / Lower — tap the book that has more chapters.
class HigherLowerRound {
  final BibleGameBook left;
  final BibleGameBook right;

  const HigherLowerRound({required this.left, required this.right});

  BibleGameBook get higher =>
      left.chapterCount >= right.chapterCount ? left : right;
}

/// Book Order Race — tap the books in canonical order.
class BookOrderRound {
  final List<BibleGameBook> shuffledBooks;

  const BookOrderRound({required this.shuffledBooks});

  List<BibleGameBook> get correctOrder {
    final ordered = [...shuffledBooks]
      ..sort((a, b) => a.canonicalIndex.compareTo(b.canonicalIndex));
    return ordered;
  }
}

/// Find the Chapter — tap the correct "book chapter" tile on a grid.
///
/// Like [GuessBookRound], [correctBook] is the DB identity while the
/// `display*` fields are the rendered (localized) values. [options] stays
/// index-aligned with [displayOptions].
class FindChapterRound {
  final String targetLabel;
  final String correctBook;
  final int targetChapter;
  final List<String> options;
  final int correctIndex;

  final String displayTargetLabel;
  final List<String> displayOptions;

  const FindChapterRound({
    required this.targetLabel,
    required this.correctBook,
    required this.targetChapter,
    required this.options,
    required this.correctIndex,
    this.displayTargetLabel = '',
    this.displayOptions = const [],
  });

  /// The target tile to render.
  String get targetLabelText =>
      displayTargetLabel.isEmpty ? targetLabel : displayTargetLabel;

  /// The option labels to render, index-aligned with [options].
  List<String> get optionLabels => displayOptions.isEmpty
      ? options
      : displayOptions;
}

/// A fun fact about the Bible, ready to reveal (prompt + answer + detail).
class FunFactRound {
  final String prompt;
  final String correct;
  final List<String> options;
  final String explain;

  const FunFactRound({
    required this.prompt,
    required this.correct,
    required this.options,
    required this.explain,
  });
}