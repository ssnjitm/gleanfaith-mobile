import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bible_study_entities.dart';

/// Repository for the user-scoped Bible study features:
/// continue-reading history and chapter notes (both remote).
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