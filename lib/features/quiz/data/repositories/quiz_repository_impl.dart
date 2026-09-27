import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource _remoteDataSource;

  QuizRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, List<QuizSchedule>> getUpcomingQuizzes() {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.getUpcomingQuizzes();
      return result.map((e) => e.toEntity()).toList();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, QuizSchedule?> getTodayDailyQuiz() {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.getTodayDailyQuiz();
      return result?.toEntity();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, List<QuizSchedule>> getUpcomingDailyQuizzes({
    int days = 7,
  }) {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.getUpcomingDailyQuizzes(
        days: days,
      );
      return result.map((e) => e.toEntity()).toList();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, List<QuizAttempt>> getQuizHistory() {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.getQuizHistory();
      return result.map((e) => e.toEntity()).toList();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, List<QuizSeries>> getSeries() {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.getSeries();
      return result.map((e) => e.toEntity()).toList();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, ActiveQuiz> startQuiz(
    String quizScheduleId, {
    QuizLanguage language = QuizLanguage.english,
  }) {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.startQuiz(
        quizScheduleId,
        language: language,
      );
      return result.toEntity();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, AnswerResult> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
  }) {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.submitAnswer(
        sessionId: sessionId,
        questionIndex: questionIndex,
        selectedOptionIndex: selectedOptionIndex,
        timeSpentSeconds: timeSpentSeconds,
      );
      return result.toEntity();
    }, (error, stackTrace) => handleError(error));
  }

  @override
  TaskEither<Failure, QuizResult> completeQuiz(String sessionId) {
    return TaskEither.tryCatch(() async {
      final result = await _remoteDataSource.completeQuiz(sessionId);
      return result.toEntity();
    }, (error, stackTrace) => handleError(error));
  }
}
