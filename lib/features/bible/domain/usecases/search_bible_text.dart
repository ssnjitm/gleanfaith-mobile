import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class SearchBibleTextUseCase {
  final BibleRepository _repository;

  SearchBibleTextUseCase(this._repository);

  TaskEither<Failure, List<Verse>> call(String query) {
    return _repository.searchBibleText(query);
  }
}