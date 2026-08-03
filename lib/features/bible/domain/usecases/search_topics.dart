import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/topic.dart';
import '../repositories/bible_repository.dart';

class SearchTopicsUseCase {
  final BibleRepository _repository;

  SearchTopicsUseCase(this._repository);

  TaskEither<Failure, List<Topic>> call(String query) {
    return _repository.searchTopics(query);
  }
}