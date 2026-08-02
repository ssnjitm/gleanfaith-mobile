import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class SubmitAnswerUseCase {
  final QuizRepository _repository;
  SubmitAnswerUseCase(this._repository);

  TaskEither<Failure, AnswerResult> call({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
  }) {
    return _repository.submitAnswer(
      sessionId: sessionId,
      questionIndex: questionIndex,
      selectedOptionIndex: selectedOptionIndex,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}