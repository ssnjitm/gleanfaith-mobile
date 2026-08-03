import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/topic.dart';
import '../repositories/bible_repository.dart';

class GetTopicsByBookUseCase {
  final BibleRepository _repository;

  GetTopicsByBookUseCase(this._repository);

  TaskEither<Failure, List<Topic>> call(String book) {
    return _repository.getTopicsByBook(book);
  }
}