import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/remote_bible_verse.dart';
import '../repositories/remote_bible_repository.dart';

class GetRemoteVerseUseCase {
  final RemoteBibleRepository _repository;

  GetRemoteVerseUseCase(this._repository);

  TaskEither<Failure, RemoteBibleVerse> call({
    required String translationId,
    required String usfmBook,
    required int chapter,
    required int verse,
  }) {
    return _repository.getVerse(
      translationId: translationId,
      usfmBook: usfmBook,
      chapter: chapter,
      verse: verse,
    );
  }
}
