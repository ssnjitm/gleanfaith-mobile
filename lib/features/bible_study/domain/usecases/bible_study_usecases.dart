import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bible_study_entities.dart';
import '../repositories/bible_study_repository.dart';

class SaveReadingPositionUseCase {
  final BibleStudyRepository _repository;
  SaveReadingPositionUseCase(this._repository);

  TaskEither<Failure, ReadingPosition> call({
    required String bookName,
    required int chapter,
    required int verse,
  }) {
    return _repository.saveReadingPosition(
      bookName: bookName,
      chapter: chapter,
      verse: verse,
    );
  }
}

class GetRecentReadingUseCase {
  final BibleStudyRepository _repository;
  GetRecentReadingUseCase(this._repository);

  TaskEither<Failure, List<ReadingPosition>> call({int? limit, String? bookId}) {
    return _repository.getRecentReading(limit: limit, bookId: bookId);
  }
}

class GetBookmarksUseCase {
  final BibleStudyRepository _repository;
  GetBookmarksUseCase(this._repository);

  TaskEither<Failure, List<Bookmark>> call({String? bookId, int? chapter}) {
    return _repository.getBookmarks(bookId: bookId, chapter: chapter);
  }
}

class CreateBookmarkUseCase {
  final BibleStudyRepository _repository;
  CreateBookmarkUseCase(this._repository);

  TaskEither<Failure, Bookmark> call({
    required String bookName,
    required int chapter,
    int? verse,
    String note = '',
  }) {
    return _repository.createBookmark(
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      note: note,
    );
  }
}

class DeleteBookmarkUseCase {
  final BibleStudyRepository _repository;
  DeleteBookmarkUseCase(this._repository);

  TaskEither<Failure, Unit> call(String bookmarkId) {
    return _repository.deleteBookmark(bookmarkId);
  }
}

class GetNotesUseCase {
  final BibleStudyRepository _repository;
  GetNotesUseCase(this._repository);

  TaskEither<Failure, List<ChapterNote>> call({
    String? bookId,
    int? chapter,
    String? search,
  }) {
    return _repository.getNotes(bookId: bookId, chapter: chapter, search: search);
  }
}

class CreateNoteUseCase {
  final BibleStudyRepository _repository;
  CreateNoteUseCase(this._repository);

  TaskEither<Failure, ChapterNote> call({
    required String bookName,
    required int chapter,
    required String content,
  }) {
    return _repository.createNote(
      bookName: bookName,
      chapter: chapter,
      content: content,
    );
  }
}

class UpdateNoteUseCase {
  final BibleStudyRepository _repository;
  UpdateNoteUseCase(this._repository);

  TaskEither<Failure, ChapterNote> call({
    required String noteId,
    String? content,
    int? chapter,
  }) {
    return _repository.updateNote(noteId: noteId, content: content, chapter: chapter);
  }
}

class DeleteNoteUseCase {
  final BibleStudyRepository _repository;
  DeleteNoteUseCase(this._repository);

  TaskEither<Failure, Unit> call(String noteId) {
    return _repository.deleteNote(noteId);
  }
}