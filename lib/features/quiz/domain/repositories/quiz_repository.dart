import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';

abstract class QuizRepository {
  TaskEither<Failure, List<QuizSchedule>> getUpcomingQuizzes();
  TaskEither<Failure, QuizSchedule?> getTodayDailyQuiz();
  TaskEither<Failure, List<QuizSchedule>> getUpcomingDailyQuizzes({
    int days = 7,
  });
  TaskEither<Failure, List<QuizAttempt>> getQuizHistory();
  TaskEither<Failure, List<QuizSeries>> getSeries();
  TaskEither<Failure, ActiveQuiz> startQuiz(
    String quizScheduleId, {
    QuizLanguage language,
  });

  /// Re-reads a running session in another language.
  ///
  /// A session is answered in the language it was started with, so the other
  /// wording has to be fetched for the same session id — starting a second
  /// session would burn the single daily attempt.
  TaskEither<Failure, ActiveQuiz> getSession(
    String sessionId, {
    QuizLanguage language,
  });
  TaskEither<Failure, AnswerResult> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
    QuizLanguage language,
  });
  TaskEither<Failure, QuizResult> completeQuiz(String sessionId);
}
