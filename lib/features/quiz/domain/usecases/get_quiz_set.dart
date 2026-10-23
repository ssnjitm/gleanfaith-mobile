import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

/// Fetches the question set behind a scheduled quiz.
///
/// The set is the only source that keeps **every** language variant: a
/// running session is materialised in the language it was started with, so a
/// session started in Nepali carries no English at all. The set is where the
/// missing wording comes from.
class GetQuizSetUseCase {
  final QuizRepository _repository;

  GetQuizSetUseCase(this._repository);

  TaskEither<Failure, QuizQuestionSet> call(String quizSetId) =>
      _repository.getQuizSet(quizSetId);
}

/// Resolves the quiz set id of a schedule.
///
/// Used when the session payload does not carry the set id itself.
class GetScheduleQuizSetIdUseCase {
  final QuizRepository _repository;

  GetScheduleQuizSetIdUseCase(this._repository);

  TaskEither<Failure, String?> call(String scheduleId) =>
      _repository.getScheduleQuizSetId(scheduleId);
}

/// Fetches the set **embedded in the schedule detail**.
///
/// `GET /quiz-schedule/{id}` is readable by a normal user and returns the whole
/// set (with every language variant), while `GET /quiz-sets/{id}` is
/// admin-facing. The embedded copy is therefore the reliable source of the
/// other language; the returned set may only carry an id, in which case the
/// caller can still fall back to [GetQuizSetUseCase].
class GetScheduleQuizSetUseCase {
  final QuizRepository _repository;

  GetScheduleQuizSetUseCase(this._repository);

  TaskEither<Failure, QuizQuestionSet?> call(String scheduleId) =>
      _repository.getScheduleQuizSet(scheduleId);
}
