import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/usecases/get_quiz_series.dart';
import 'quiz_provider.dart';

final getQuizSeriesUseCaseProvider = Provider<GetQuizSeriesUseCase>((ref) {
  return GetQuizSeriesUseCase(ref.watch(quizRepositoryProvider));
});

enum QuizSeriesStatus { initial, loading, success, error }

class QuizSeriesState {
  final QuizSeriesStatus status;
  final List<QuizSeries> series;
  final String? message;

  const QuizSeriesState({
    this.status = QuizSeriesStatus.initial,
    this.series = const [],
    this.message,
  });

  /// Every deployment of every series, flattened for the Series tab list.
  List<QuizSchedule> get deployments => series
      .expand((item) => item.deployments)
      .where((schedule) => schedule.id.isNotEmpty)
      .toList();

  QuizSeriesState copyWith({
    QuizSeriesStatus? status,
    List<QuizSeries>? series,
    String? message,
    bool clearMessage = false,
  }) {
    return QuizSeriesState(
      status: status ?? this.status,
      series: series ?? this.series,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final quizSeriesProvider =
    StateNotifierProvider<QuizSeriesNotifier, QuizSeriesState>((ref) {
      return QuizSeriesNotifier(ref);
    });

class QuizSeriesNotifier extends StateNotifier<QuizSeriesState> {
  final Ref _ref;

  QuizSeriesNotifier(this._ref) : super(const QuizSeriesState());

  Future<void> loadSeries() async {
    state = state.copyWith(
      status: QuizSeriesStatus.loading,
      clearMessage: true,
    );
    final result = await _ref.read(getQuizSeriesUseCaseProvider)().run();
    if (!mounted) return;
    result.fold(
      // The series endpoint is optional: a failure degrades the Series tab to
      // an empty state instead of breaking the whole quiz section.
      (failure) {
        LoggerService.warning('Quiz series unavailable: ${failure.message}');
        state = state.copyWith(
          status: QuizSeriesStatus.error,
          series: const [],
        );
      },
      (list) => state = state.copyWith(
        status: QuizSeriesStatus.success,
        series: list,
      ),
    );
  }
}
