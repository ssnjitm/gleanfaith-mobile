import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class CompleteQuizUseCase {
  final QuizRepository _repository;
  CompleteQuizUseCase(this._repository);

  TaskEither<Failure, QuizResult> call(String sessionId) {
    return _repository.completeQuiz(sessionId);
  }
}