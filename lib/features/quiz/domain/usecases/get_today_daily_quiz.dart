import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class GetTodayDailyQuizUseCase {
  final QuizRepository _repository;
  GetTodayDailyQuizUseCase(this._repository);

  TaskEither<Failure, QuizSchedule?> call() {
    return _repository.getTodayDailyQuiz();
  }
}
