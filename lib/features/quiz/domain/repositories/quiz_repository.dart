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
  TaskEither<Failure, AnswerResult> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
  });
  TaskEither<Failure, QuizResult> completeQuiz(String sessionId);
}
