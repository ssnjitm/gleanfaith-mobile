import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class StartQuizUseCase {
  final QuizRepository _repository;

  StartQuizUseCase(this._repository);

  TaskEither<Failure, ActiveQuiz> call(
    String quizScheduleId, {
    QuizLanguage language = QuizLanguage.english,
  }) => _repository.startQuiz(quizScheduleId, language: language);
}
