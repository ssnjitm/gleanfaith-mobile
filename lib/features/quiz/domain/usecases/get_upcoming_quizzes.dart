import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class GetUpcomingQuizzesUseCase {
  final QuizRepository _repository;
  GetUpcomingQuizzesUseCase(this._repository);

  TaskEither<Failure, List<QuizSchedule>> call() {
    return _repository.getUpcomingQuizzes();
  }
}