import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bible_study_entities.dart';

/// Repository for the three user-scoped Bible study features:
/// continue-reading history, bookmarks and chapter notes (all remote).
abstract class BibleStudyRepository {
  // ── Continue reading ─────────────────────────────────────────────────────
  TaskEither<Failure, ReadingPosition> saveReadingPosition({
    required String bookName,
    required int chapter,
    required int verse,
  });

  TaskEither<Failure, List<ReadingPosition>> getRecentReading({
    int? limit,
    String? bookId,
  });

  // ── Bookmarks ───────────────────────────────────────────────────────────
  TaskEither<Failure, List<Bookmark>> getBookmarks({
    String? bookId,
    int? chapter,
  });

  TaskEither<Failure, Bookmark> createBookmark({
    required String bookName,
    required int chapter,
    int? verse,
    String note,
  });

  TaskEither<Failure, Unit> deleteBookmark(String bookmarkId);

  // ── Chapter notes ───────────────────────────────────────────────────────
  TaskEither<Failure, List<ChapterNote>> getNotes({
    String? bookId,
    int? chapter,
    String? search,
  });

  TaskEither<Failure, ChapterNote> createNote({
    required String bookName,
    required int chapter,
    required String content,
  });

  TaskEither<Failure, ChapterNote> updateNote({
    required String noteId,
    String? content,
    int? chapter,
  });

  TaskEither<Failure, Unit> deleteNote(String noteId);
}