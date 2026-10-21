import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/remote_bible_chapter.dart';
import '../repositories/remote_bible_repository.dart';

/// Fetches a whole chapter of scripture from the free remote Bible endpoint.
class GetRemoteChapterUseCase {
  final RemoteBibleRepository _repository;

  GetRemoteChapterUseCase(this._repository);

  TaskEither<Failure, RemoteBibleChapter> call({
    required String translationId,
    required String usfmBook,
    required int chapter,
  }) {
    return _repository.getChapter(
      translationId: translationId,
      usfmBook: usfmBook,
      chapter: chapter,
    );
  }
}
