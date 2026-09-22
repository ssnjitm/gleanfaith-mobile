import 'package:equatable/equatable.dart';

/// A saved reading location for the "continue reading" feature.
///
/// The backend stores a language-agnostic `bookId` (e.g. `MAT`); the Flutter
/// side also keeps the display [bookName] so it can navigate without an extra
/// lookup. The backend only stores the id, so [bookName] is derivable and
/// optional for equality.
class ReadingPosition extends Equatable {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final DateTime? updatedAt;

  const ReadingPosition({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    this.updatedAt,
  });

  String get reference => '$bookName $chapter';

  @override
  List<Object?> get props => [bookId, chapter, verse];
}

/// A bookmarked verse (or whole chapter when [verse] is null).
class Bookmark extends Equatable {
  final String id;
  final String bookId;
  final String bookName;
  final int chapter;
  final int? verse;
  final String note;
  final DateTime? createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    this.verse,
    this.note = '',
    this.createdAt,
  });

  bool get isChapterBookmark => verse == null;

  String get reference =>
      verse == null ? '$bookName $chapter' : '$bookName $chapter:$verse';

  @override
  List<Object?> get props => [id, bookId, chapter, verse];
}

/// A user's plain-text note attached to a Bible chapter.
class ChapterNote extends Equatable {
  final String id;
  final String bookId;
  final String bookName;
  final int chapter;
  final String content;
  final DateTime? updatedAt;

  const ChapterNote({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.content,
    this.updatedAt,
  });

  String get reference => '$bookName $chapter';

  @override
  List<Object?> get props => [id, bookId, chapter, content];
}