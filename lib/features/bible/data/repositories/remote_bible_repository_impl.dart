import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/remote_bible_datasource.dart';
import '../../domain/entities/remote_bible_verse.dart';
import '../../domain/repositories/remote_bible_repository.dart';

class RemoteBibleRepositoryImpl implements RemoteBibleRepository {
  final RemoteBibleDataSource _remoteDataSource;

  RemoteBibleRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, RemoteBibleVerse> getVerse({
    required String translationId,
    required String usfmBook,
    required int chapter,
    required int verse,
  }) {
    return TaskEither.tryCatch(
      () => _remoteDataSource.getVerse(
        translationId: translationId,
        usfmBook: usfmBook,
        chapter: chapter,
        verse: verse,
      ),
      (error, stackTrace) => handleError(error),
    );
  }
}
