import 'package:equatable/equatable.dart';

/// A canonical Bible book with the counts the games need. Built from the
/// seeded `bible_books` table joined with `bible_verses`.
class BibleGameBook extends Equatable {
  final String name;
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
  });

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
class BibleGameVerse extends Equatable {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  const BibleGameVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
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

  String get formattedReference => '$book $chapter:$verse';

  @override
  List<Object?> get props => [book, chapter, verse, text];
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
}

/// Guess the Book — show a complete verse, pick which book it comes from.
class GuessBookRound {
  final String snippet;
  final String fullText;
  final String reference;
  final String correctBook;
  final List<String> options;
  final int wordsShown;
  final String hint;

  const GuessBookRound({
    required this.snippet,
    required this.fullText,
    required this.reference,
    required this.correctBook,
    required this.options,
    required this.wordsShown,
    required this.hint,
  });
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
class FindChapterRound {
  final String targetLabel;
  final String correctBook;
  final int targetChapter;
  final List<String> options;
  final int correctIndex;

  const FindChapterRound({
    required this.targetLabel,
    required this.correctBook,
    required this.targetChapter,
    required this.options,
    required this.correctIndex,
  });
}

/// Fun Facts — a single trivia question with an explanation.
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