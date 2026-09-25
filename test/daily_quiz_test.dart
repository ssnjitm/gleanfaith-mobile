import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/quiz/data/models/quiz_models.dart';
import 'package:glean_faith_app/features/quiz/presentation/providers/daily_quiz_provider.dart';

void main() {
  group('QuizScheduleModel metadata', () {
    test('parses daily metadata and exposes getters on the entity', () {
      final model = QuizScheduleModel.fromJson({
        '_id': 'daily-1',
        'title': 'Daily Quiz',
        'metadata': {'isDaily': true, 'dailyDate': '2026-09-25'},
      });

      expect(model.metadata?['isDaily'], isTrue);

      final entity = model.toEntity();
      expect(entity.isDaily, isTrue);
      expect(entity.dailyDate, '2026-09-25');
    });

    test('treats schedules without metadata as regular quizzes', () {
      final entity = QuizScheduleModel.fromJson({
        'id': 'quiz-1',
        'title': 'Genesis Quiz',
      }).toEntity();

      expect(entity.isDaily, isFalse);
      expect(entity.dailyDate, isNull);
    });

    test('ignores non-boolean isDaily values', () {
      final entity = QuizScheduleModel.fromJson({
        '_id': 'daily-2',
        'title': 'Daily Quiz',
        'metadata': {'isDaily': 'true', 'dailyDate': 20260925},
      }).toEntity();

      expect(entity.isDaily, isFalse);
      expect(entity.dailyDate, isNull);
    });
  });

  group('DailyQuizState', () {
    final schedule = QuizScheduleModel.fromJson({
      '_id': 'daily-1',
      'title': 'Daily Quiz',
    }).toEntity();

    test('clearToday removes a previously loaded quiz', () {
      final state = DailyQuizState(
        status: DailyQuizStatus.success,
        today: schedule,
      );

      final cleared = state.copyWith(
        status: DailyQuizStatus.empty,
        clearToday: true,
      );

      expect(cleared.status, DailyQuizStatus.empty);
      expect(cleared.today, isNull);
    });

    test('keeps today and message when they are not provided', () {
      final state = DailyQuizState(
        status: DailyQuizStatus.success,
        today: schedule,
        message: 'boom',
      );

      final updated = state.copyWith(status: DailyQuizStatus.loading);

      expect(updated.today, schedule);
      expect(updated.message, 'boom');
    });
  });
}
