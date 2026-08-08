import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class SearchByReferenceUseCase {
  final BibleRepository _repository;

  SearchByReferenceUseCase(this._repository);

  TaskEither<Failure, List<Verse>> call(String query) {
    return _repository.searchByReference(query);
  }
}
