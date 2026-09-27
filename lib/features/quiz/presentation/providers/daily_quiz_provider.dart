import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/usecases/get_today_daily_quiz.dart';
import '../../domain/usecases/get_upcoming_daily_quizzes.dart';
import 'quiz_provider.dart';

final getTodayDailyQuizUseCaseProvider = Provider<GetTodayDailyQuizUseCase>((
  ref,
) {
  return GetTodayDailyQuizUseCase(ref.watch(quizRepositoryProvider));
});

final getUpcomingDailyQuizzesUseCaseProvider =
    Provider<GetUpcomingDailyQuizzesUseCase>((ref) {
      return GetUpcomingDailyQuizzesUseCase(ref.watch(quizRepositoryProvider));
    });

enum DailyQuizStatus { initial, loading, success, error, empty }

class DailyQuizState {
  final DailyQuizStatus status;
  final QuizSchedule? today;
  final List<QuizSchedule> upcoming;
  final String? message;

  /// True once the user has spent the single daily attempt. Derived from the
  /// attempt history so the Start button is locked before any request fails.
  final bool attemptUsed;

  const DailyQuizState({
    this.status = DailyQuizStatus.initial,
    this.today,
    this.upcoming = const [],
    this.message,
    this.attemptUsed = false,
  });

  /// Whether the daily quiz can still be played.
  bool get canStart =>
      status == DailyQuizStatus.success && today != null && !attemptUsed;

  DailyQuizState copyWith({
    DailyQuizStatus? status,
    QuizSchedule? today,
    bool clearToday = false,
    List<QuizSchedule>? upcoming,
    String? message,
    bool clearMessage = false,
    bool? attemptUsed,
  }) {
    return DailyQuizState(
      status: status ?? this.status,
      today: clearToday ? null : (today ?? this.today),
      upcoming: upcoming ?? this.upcoming,
      message: clearMessage ? null : (message ?? this.message),
      attemptUsed: attemptUsed ?? this.attemptUsed,
    );
  }
}

final dailyQuizProvider =
    StateNotifierProvider<DailyQuizNotifier, DailyQuizState>((ref) {
      return DailyQuizNotifier(ref);
    });

class DailyQuizNotifier extends StateNotifier<DailyQuizState> {
  final Ref _ref;

  DailyQuizNotifier(this._ref) : super(const DailyQuizState());

  Future<void> loadDailyQuiz({int days = 7}) async {
    state = state.copyWith(status: DailyQuizStatus.loading, clearMessage: true);

    final todayResult = await _ref
        .read(getTodayDailyQuizUseCaseProvider)()
        .run();
    if (!mounted) return;

    var nextStatus = DailyQuizStatus.success;
    var message = '';
    QuizSchedule? today;
    todayResult.fold(
      (failure) {
        nextStatus = DailyQuizStatus.error;
        message = failure.message;
      },
      (schedule) {
        today = schedule;
        if (schedule == null) nextStatus = DailyQuizStatus.empty;
      },
    );

    state = state.copyWith(
      status: nextStatus,
      today: today,
      clearToday: today == null,
      message: message.isEmpty ? null : message,
      clearMessage: message.isEmpty,
      attemptUsed: _hasUsedAttempt(today),
    );

    final upcomingResult = await _ref
        .read(getUpcomingDailyQuizzesUseCaseProvider)(days: days)
        .run();
    if (!mounted) return;

    final upcoming = upcomingResult.fold((failure) {
      LoggerService.warning('Daily quiz upcoming failed: ${failure.message}');
      return state.upcoming;
    }, (list) => list);
    state = state.copyWith(upcoming: upcoming);
  }

  /// Locks the daily quiz locally after the user finishes their single
  /// attempt, so the hero switches to the "attempt used" state immediately.
  void markAttemptUsed() {
    if (state.attemptUsed) return;
    state = state.copyWith(attemptUsed: true);
  }

  bool _hasUsedAttempt(QuizSchedule? schedule) {
    if (schedule == null || schedule.id.isEmpty) return state.attemptUsed;
    return _ref.read(quizProvider).hasUsedAttempt(schedule.id);
  }
}
