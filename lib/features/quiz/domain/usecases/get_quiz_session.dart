import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

/// Re-reads a running quiz session in another language.
///
/// The backend answers a session in the language it was started with, so a
/// Nepali session carries no English wording. Fetching the same session id
/// with the other language is the only way to translate the questions without
/// starting a second attempt — the daily quiz allows exactly one.
class GetQuizSessionUseCase {
  final QuizRepository _repository;

  GetQuizSessionUseCase(this._repository);

  TaskEither<Failure, ActiveQuiz> call(
    String sessionId, {
    QuizLanguage language = QuizLanguage.english,
  }) => _repository.getSession(sessionId, language: language);
}
