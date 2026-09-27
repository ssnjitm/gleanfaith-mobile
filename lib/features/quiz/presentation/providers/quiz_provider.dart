import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../data/datasources/quiz_remote_datasource.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/usecases/complete_quiz.dart';
import '../../domain/usecases/get_quiz_history.dart';
import '../../domain/usecases/get_upcoming_quizzes.dart';
import '../../domain/usecases/start_quiz.dart';
import '../../domain/usecases/submit_answer.dart';

enum QuizStatus { initial, loading, success, error }

/// Why a quiz could not be started.
enum QuizBlockReason { none, alreadyCompleted, notAvailable, attemptsExhausted }

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return QuizRepositoryImpl(QuizRemoteDataSource(dio));
});

final getUpcomingQuizzesUseCaseProvider = Provider<GetUpcomingQuizzesUseCase>((
  ref,
) {
  return GetUpcomingQuizzesUseCase(ref.watch(quizRepositoryProvider));
});

final getQuizHistoryUseCaseProvider = Provider<GetQuizHistoryUseCase>((ref) {
  return GetQuizHistoryUseCase(ref.watch(quizRepositoryProvider));
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

/// Everything the play page needs, handed over through the route `extra`.
///
/// The page used to rebuild itself from `quizProvider.activeQuiz`, which meant
/// that a dropped/cleared provider left the play screen spinning forever.
/// Passing the whole session makes the play page self-sufficient.
class QuizPlayArgs {
  final ActiveQuiz? activeQuiz;
  final String? scheduleId;
  final String? title;
  final bool isDaily;
  final bool isSeries;
  final QuizLanguage language;
  final int fallbackDurationSeconds;

  const QuizPlayArgs({
    this.activeQuiz,
    this.scheduleId,
    this.title,
    this.isDaily = false,
    this.isSeries = false,
    this.language = QuizLanguage.english,
    this.fallbackDurationSeconds = 0,
  });

  String get sessionId => activeQuiz?.sessionId ?? '';

  /// Wraps a freshly started session, inheriting the schedule metadata the
  /// play page needs.
  factory QuizPlayArgs.from(
    ActiveQuiz activeQuiz, {
    QuizSchedule? schedule,
    QuizLanguage language = QuizLanguage.english,
  }) {
    return QuizPlayArgs(
      activeQuiz: activeQuiz,
      scheduleId: activeQuiz.scheduleId ?? schedule?.id,
      title: activeQuiz.title ?? schedule?.title,
      isDaily: activeQuiz.isDaily || (schedule?.isDaily ?? false),
      isSeries: activeQuiz.isSeries || (schedule?.isSeries ?? false),
      language: language,
      fallbackDurationSeconds: schedule?.durationSeconds ?? 0,
    );
  }
}

/// Result payload handed to the summary screen.
class QuizResultArgs {
  final QuizResult? result;
  final bool isDaily;
  final QuizLanguage language;

  const QuizResultArgs({
    this.result,
    this.isDaily = false,
    this.language = QuizLanguage.english,
  });
}

class QuizState {
  final QuizStatus status;
  final List<QuizSchedule> upcomingQuizzes;
  final ActiveQuiz? activeQuiz;
  final String? message;
  final QuizBlockReason blockReason;

  /// Schedule ids the user already spent an attempt on (single-attempt rule).
  final Set<String> attemptedScheduleIds;

  /// True while a `startQuiz` request is in flight.
  final bool isStarting;

  const QuizState({
    this.status = QuizStatus.initial,
    this.upcomingQuizzes = const [],
    this.activeQuiz,
    this.message,
    this.blockReason = QuizBlockReason.none,
    this.attemptedScheduleIds = const {},
    this.isStarting = false,
  });

  /// True when [scheduleId] can no longer be started.
  bool hasUsedAttempt(String scheduleId) =>
      attemptedScheduleIds.contains(scheduleId);

  QuizState copyWith({
    QuizStatus? status,
    List<QuizSchedule>? upcomingQuizzes,
    ActiveQuiz? activeQuiz,
    bool clearActiveQuiz = false,
    String? message,
    bool clearMessage = false,
    QuizBlockReason? blockReason,
    Set<String>? attemptedScheduleIds,
    bool? isStarting,
  }) {
    return QuizState(
      status: status ?? this.status,
      upcomingQuizzes: upcomingQuizzes ?? this.upcomingQuizzes,
      // `activeQuiz ?? this.activeQuiz` alone can never clear the field, which
      // is why `clearActiveQuiz` exists as an explicit opt-in flag.
      activeQuiz: clearActiveQuiz ? null : (activeQuiz ?? this.activeQuiz),
      // Before this fix `message` was assigned unconditionally, so every
      // copyWith wiped the last error and the UI silently swallowed failures.
      message: clearMessage ? null : (message ?? this.message),
      blockReason: blockReason ?? this.blockReason,
      attemptedScheduleIds: attemptedScheduleIds ?? this.attemptedScheduleIds,
      isStarting: isStarting ?? this.isStarting,
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
    state = state.copyWith(status: QuizStatus.loading, clearMessage: true);
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

  /// Loads the attempt history so the UI can lock the Start button for
  /// quizzes that only allow a single attempt.
  Future<void> loadAttemptedScheduleIds() async {
    final result = await _ref.read(getQuizHistoryUseCaseProvider)().run();
    result.fold(
      // Non-blocking: without history we fall back to the server error that
      // `startQuiz` returns for a second attempt.
      (failure) =>
          LoggerService.warning('Quiz history unavailable: ${failure.message}'),
      (attempts) {
        final ids = attempts
            .where((attempt) => attempt.isCompleted)
            .map((attempt) => attempt.scheduleId)
            .where((id) => id.isNotEmpty)
            .toSet();
        state = state.copyWith(attemptedScheduleIds: ids);
      },
    );
  }

  void markAttempted(String scheduleId) {
    if (scheduleId.isEmpty) return;
    state = state.copyWith(
      attemptedScheduleIds: {...state.attemptedScheduleIds, scheduleId},
    );
  }

  /// Starts (or resumes) a session for [quizScheduleId].
  ///
  /// Returns the started session, or `null` when the backend refused it. On
  /// refusal the reason is always recorded in [QuizState] so callers can show
  /// feedback instead of failing silently.
  Future<ActiveQuiz?> startQuiz(
    String quizScheduleId, {
    QuizLanguage language = QuizLanguage.english,
  }) async {
    if (state.isStarting) return null;
    state = state.copyWith(
      isStarting: true,
      clearMessage: true,
      blockReason: QuizBlockReason.none,
    );

    final result = await _ref
        .read(startQuizUseCaseProvider)(quizScheduleId, language: language)
        .run();

    state = state.copyWith(isStarting: false);

    return result.fold(
      (failure) {
        state = state.copyWith(
          message: _fallbackMessage(failure),
          blockReason: _blockReasonFor(failure),
        );
        return null;
      },
      (quiz) {
        state = state.copyWith(
          activeQuiz: quiz,
          clearMessage: true,
          blockReason: QuizBlockReason.none,
        );
        LoggerService.info(
          'Quiz session ${quiz.sessionId} started with ${quiz.questions.length} questions',
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
    final result = await _ref
        .read(submitAnswerUseCaseProvider)
        .call(
          sessionId: sessionId,
          questionIndex: questionIndex,
          selectedOptionIndex: selectedOptionIndex,
          timeSpentSeconds: timeSpentSeconds,
        )
        .run();
    return result.fold((failure) {
      state = state.copyWith(message: _fallbackMessage(failure));
      return null;
    }, (answer) => answer);
  }

  Future<QuizResult?> completeQuiz(String sessionId) async {
    final result = await _ref
        .read(completeQuizUseCaseProvider)(sessionId)
        .run();
    return result.fold(
      (failure) {
        state = state.copyWith(message: _fallbackMessage(failure));
        return null;
      },
      (quizResult) {
        final scheduleId = state.activeQuiz?.scheduleId;
        if (scheduleId != null && scheduleId.isNotEmpty) {
          markAttempted(scheduleId);
        }
        return quizResult;
      },
    );
  }

  void clearActiveQuiz() {
    state = state.copyWith(
      clearActiveQuiz: true,
      clearMessage: true,
      blockReason: QuizBlockReason.none,
    );
  }

  void clearBlockReason() {
    state = state.copyWith(
      blockReason: QuizBlockReason.none,
      clearMessage: true,
    );
  }

  static String _fallbackMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }

  /// Classifies a start failure. Kept intentionally generous: the backend
  /// rejects a second attempt with several different 400/403/409 messages.
  static QuizBlockReason _blockReasonFor(Failure failure) {
    final lower = failure.message.toLowerCase();
    final statusCode = failure.statusCode;

    const completedMarkers = [
      'already completed',
      'already taken',
      'already attempted',
      'already submitted',
      'already exists',
      'attempt limit',
      'no more attempts',
      'limit reached',
      'exceeded',
    ];
    final unavailableMarkers = [
      'not active',
      'not available',
      'not started',
      'has ended',
      'has expired',
      'out of range',
      'not found',
      'access denied',
      'not scheduled',
    ];

    if (completedMarkers.any(lower.contains)) {
      return QuizBlockReason.alreadyCompleted;
    }
    if (unavailableMarkers.any(lower.contains)) {
      return QuizBlockReason.notAvailable;
    }
    if (statusCode == 403 || statusCode == 409) {
      return QuizBlockReason.attemptsExhausted;
    }
    return QuizBlockReason.none;
  }
}
