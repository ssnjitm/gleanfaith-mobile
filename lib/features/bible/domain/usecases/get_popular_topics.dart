import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/topic.dart';
import '../repositories/bible_repository.dart';

class GetPopularTopicsUseCase {
  final BibleRepository _repository;

  GetPopularTopicsUseCase(this._repository);

  TaskEither<Failure, List<Topic>> call({int limit = 20}) {
    return _repository.getPopularTopics(limit: limit);
  }
}