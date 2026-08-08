import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/quiz_remote_datasource.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/usecases/complete_quiz.dart';
import '../../domain/usecases/get_upcoming_quizzes.dart';
import '../../domain/usecases/start_quiz.dart';
import '../../domain/usecases/submit_answer.dart';

enum QuizStatus { initial, loading, success, error }

enum QuizBlockReason { none, alreadyCompleted }

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return QuizRepositoryImpl(QuizRemoteDataSource(dio));
});

final getUpcomingQuizzesUseCaseProvider = Provider<GetUpcomingQuizzesUseCase>((ref) {
  return GetUpcomingQuizzesUseCase(ref.watch(quizRepositoryProvider));
});

final startQuizUseCaseProvider = Provider<StartQuizUseCase>((ref) {
  return StartQuizUseCase(ref.watch(quizRepositoryProvider));
});

final submitAnswerUseCaseProvider = Provider<SubmitAnswerUseCase>((ref) {
  return SubmitAnswerUseCase(ref.watch(quizRepositoryProvider));
});

final completeQuizUseCaseProvider = Provider<CompleteQuizUseCase>((ref) {
  return CompleteQuizUseCase(ref.watch(quizRepositoryProvider));
});

class QuizState {
  final QuizStatus status;
  final List<QuizSchedule> upcomingQuizzes;
  final ActiveQuiz? activeQuiz;
  final String? message;
  final QuizBlockReason blockReason;

  const QuizState({
    this.status = QuizStatus.initial,
    this.upcomingQuizzes = const [],
    this.activeQuiz,
    this.message,
    this.blockReason = QuizBlockReason.none,
  });

  QuizState copyWith({
    QuizStatus? status,
    List<QuizSchedule>? upcomingQuizzes,
    ActiveQuiz? activeQuiz,
    String? message,
    QuizBlockReason? blockReason,
  }) {
    return QuizState(
      status: status ?? this.status,
      upcomingQuizzes: upcomingQuizzes ?? this.upcomingQuizzes,
      activeQuiz: activeQuiz ?? this.activeQuiz,
      message: message,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref);
});

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref _ref;

  QuizNotifier(this._ref) : super(const QuizState());

  Future<void> loadUpcomingQuizzes() async {
    state = state.copyWith(status: QuizStatus.loading, message: null);
    final result = await _ref.read(getUpcomingQuizzesUseCaseProvider)().run();
    result.fold(
      (failure) => state = state.copyWith(
        status: QuizStatus.error,
        message: failure.message,
      ),
      (quizzes) => state = state.copyWith(
        status: QuizStatus.success,
        upcomingQuizzes: quizzes,
      ),
    );
  }

  Future<ActiveQuiz?> startQuiz(String quizScheduleId) async {
    final result = await _ref.read(startQuizUseCaseProvider)(quizScheduleId).run();
    return result.fold(
      (failure) {
        final lower = failure.message.toLowerCase();
        final alreadyCompleted = lower.contains('already completed') ||
            lower.contains('already taken') ||
            lower.contains('already attempted') ||
            (failure.statusCode == 400 || failure.statusCode == 409) &&
                lower.contains('complete');
        state = state.copyWith(
          message: failure.message,
          blockReason: alreadyCompleted
              ? QuizBlockReason.alreadyCompleted
              : QuizBlockReason.none,
        );
        return null;
      },
      (quiz) {
        state = state.copyWith(
          activeQuiz: quiz,
          message: null,
          blockReason: QuizBlockReason.none,
        );
        return quiz;
      },
    );
  }

  Future<AnswerResult?> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
  }) async {
    final result = await _ref.read(submitAnswerUseCaseProvider).call(
      sessionId: sessionId,
      questionIndex: questionIndex,
      selectedOptionIndex: selectedOptionIndex,
      timeSpentSeconds: timeSpentSeconds,
    ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return null;
      },
      (answer) => answer,
    );
  }

  Future<QuizResult?> completeQuiz(String sessionId) async {
    final result = await _ref.read(completeQuizUseCaseProvider)(sessionId).run();
    return result.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return null;
      },
      (quizResult) => quizResult,
    );
  }

  void clearActiveQuiz() {
    state = state.copyWith(
      activeQuiz: null,
      message: null,
      blockReason: QuizBlockReason.none,
    );
  }

  void clearBlockReason() {
    state = state.copyWith(
      blockReason: QuizBlockReason.none,
      message: null,
    );
  }
}