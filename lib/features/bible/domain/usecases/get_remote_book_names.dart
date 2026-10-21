import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/remote_bible_repository.dart';

/// Fetches the localized name of every book of a remote translation.
///
/// The result is keyed by USFM id (`'JHN'`), which is the same key the app
/// uses everywhere else to address a book, so the reader can look a book up
/// without translating names back and forth.
class GetRemoteBookNamesUseCase {
  final RemoteBibleRepository _repository;

  GetRemoteBookNamesUseCase(this._repository);

  TaskEither<Failure, Map<String, String>> call({required String translationId}) {
    return _repository.getBookNames(translationId: translationId);
  }
}
