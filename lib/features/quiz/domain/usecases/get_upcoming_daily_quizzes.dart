import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class GetUpcomingDailyQuizzesUseCase {
  final QuizRepository _repository;
  GetUpcomingDailyQuizzesUseCase(this._repository);

  TaskEither<Failure, List<QuizSchedule>> call({int days = 7}) {
    return _repository.getUpcomingDailyQuizzes(days: days);
  }
}
