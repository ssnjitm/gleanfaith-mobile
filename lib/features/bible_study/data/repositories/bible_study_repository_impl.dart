import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/bible_study_entities.dart';
import '../../domain/repositories/bible_study_repository.dart';
import '../bible_study_mapper.dart';
import '../datasources/bible_study_remote_datasource.dart';

class BibleStudyRepositoryImpl implements BibleStudyRepository {
  final BibleStudyRemoteDataSource _remoteDataSource;

  BibleStudyRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, ReadingPosition> saveReadingPosition({
    required String bookName,
    required int chapter,
    required int verse,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.saveReadingPosition(
            bookId: bookCodeForName(bookName),
            chapter: chapter,
            verse: verse,
          ))
              .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<ReadingPosition>> getRecentReading({
    int? limit,
    String? bookId,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.getRecentReading(limit: limit, bookId: bookId))
              .map((model) => model.toEntity())
              .toList(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Bookmark>> getBookmarks({
    String? bookId,
    int? chapter,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.getBookmarks(bookId: bookId, chapter: chapter))
              .map((model) => model.toEntity())
              .toList(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Bookmark> createBookmark({
    required String bookName,
    required int chapter,
    int? verse,
    String note = '',
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.createBookmark(
            bookId: bookCodeForName(bookName),
            chapter: chapter,
            verse: verse,
            note: note,
          ))
              .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Unit> deleteBookmark(String bookmarkId) {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.deleteBookmark(bookmarkId);
        return unit;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<ChapterNote>> getNotes({
    String? bookId,
    int? chapter,
    String? search,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.getNotes(
            bookId: bookId,
            chapter: chapter,
            search: search,
          ))
              .map((model) => model.toEntity())
              .toList(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, ChapterNote> createNote({
    required String bookName,
    required int chapter,
    required String content,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.createNote(
            bookId: bookCodeForName(bookName),
            chapter: chapter,
            content: content,
          ))
              .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, ChapterNote> updateNote({
    required String noteId,
    String? content,
    int? chapter,
  }) {
    return TaskEither.tryCatch(
      () async =>
          (await _remoteDataSource.updateNote(
            noteId: noteId,
            content: content,
            chapter: chapter,
          ))
              .toEntity(),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Unit> deleteNote(String noteId) {
    return TaskEither.tryCatch(
      () async {
        await _remoteDataSource.deleteNote(noteId);
        return unit;
      },
      (error, stackTrace) => handleError(error),
    );
  }
}