import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/topic_verse.dart';
import '../repositories/bible_repository.dart';

class GetTopicVersesUseCase {
  final BibleRepository _repository;

  GetTopicVersesUseCase(this._repository);

  TaskEither<Failure, List<TopicVerse>> call(String topicName, {int limit = 50}) {
    return _repository.getTopicVerses(topicName, limit: limit);
  }
}