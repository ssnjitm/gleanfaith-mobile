import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/leaderboard/data/models/leaderboard_models.dart';
import 'package:glean_faith_app/features/leaderboard/domain/entities/leaderboard_entities.dart';

void main() {
  group('fallbackLeaderboardResetUtc', () {
    test('weekly resets next Monday 00:00 UTC', () {
      // Wednesday 21 Oct 2026.
      final now = DateTime.utc(2026, 10, 21, 15, 30);
      final reset = fallbackLeaderboardResetUtc(
        LeaderboardPeriod.weekly,
        now: now,
      );

      expect(reset, DateTime.utc(2026, 10, 26));
    });

    test('weekly on a Monday resets the following Monday, not today', () {
      final now = DateTime.utc(2026, 10, 26, 9);
      final reset = fallbackLeaderboardResetUtc(
        LeaderboardPeriod.weekly,
        now: now,
      );

      expect(reset, DateTime.utc(2026, 11, 2));
    });

    test('weekly rolls from Sunday to Monday', () {
      final now = DateTime.utc(2026, 10, 25, 23, 59);
      final reset = fallbackLeaderboardResetUtc(
        LeaderboardPeriod.weekly,
        now: now,
      );

      expect(reset, DateTime.utc(2026, 10, 26));
    });

    test('monthly resets on the 1st of the next month 00:00 UTC', () {
      final now = DateTime.utc(2026, 10, 23, 13);
      final reset = fallbackLeaderboardResetUtc(
        LeaderboardPeriod.monthly,
        now: now,
      );

      expect(reset, DateTime.utc(2026, 11, 1));
    });

    test('monthly rolls December into January of the next year', () {
      final now = DateTime.utc(2026, 12, 31, 23, 59);
      final reset = fallbackLeaderboardResetUtc(
        LeaderboardPeriod.monthly,
        now: now,
      );

      expect(reset, DateTime.utc(2027, 1, 1));
    });

    test('all time never resets', () {
      final reset = fallbackLeaderboardResetUtc(LeaderboardPeriod.allTime);

      expect(reset, isNull);
    });
  });

  group('LeaderboardData.nextResetUtc', () {
    LeaderboardData data({
      DateTime? resetAt,
      DateTime? endsAt,
      LeaderboardPeriod period = LeaderboardPeriod.weekly,
    }) {
      return LeaderboardData(
        entries: const [],
        period: period,
        userRank: 0,
        totalParticipants: 0,
        resetAt: resetAt,
        endsAt: endsAt,
      );
    }

    test('prefers the server timestamp', () {
      final server = DateTime.utc(2026, 11, 3, 6);

      expect(data(resetAt: server).nextResetUtc(), server);
    });

    test('prefers endsAt over resetAt when both are present', () {
      final endsAt = DateTime.utc(2026, 11, 4, 6);
      final resetAt = DateTime.utc(2026, 11, 3, 6);

      expect(data(resetAt: resetAt, endsAt: endsAt).nextResetUtc(), endsAt);
    });

    test('normalises a local server timestamp to UTC', () {
      final local = DateTime(2026, 11, 3, 6);

      expect(
        data(resetAt: local).nextResetUtc(),
        local.toUtc(),
      );
    });

    test('falls back to the schedule when the server sends none', () {
      final reset = data(
        period: LeaderboardPeriod.monthly,
      ).nextResetUtc(now: DateTime.utc(2026, 10, 23, 13));

      expect(reset, DateTime.utc(2026, 11, 1));
    });
  });

  group('formatLeaderboardCountdown', () {
    test('shows days, hours and minutes when more than a day remains', () {
      const remaining = Duration(days: 2, hours: 14, minutes: 32);

      expect(formatLeaderboardCountdown(remaining), 'Ends in 2d 14h 32m');
    });

    test('shows hours and minutes when under a day', () {
      const remaining = Duration(hours: 5, minutes: 9);

      expect(formatLeaderboardCountdown(remaining), 'Ends in 5h 9m');
    });

    test('shows minutes and zero-padded seconds under an hour', () {
      const remaining = Duration(minutes: 4, seconds: 9);

      expect(formatLeaderboardCountdown(remaining), 'Ends in 4m 09s');
    });

    test('shows bare seconds under a minute', () {
      const remaining = Duration(seconds: 45);

      expect(formatLeaderboardCountdown(remaining), 'Ends in 45s');
    });

    test('never renders negative time', () {
      expect(
        formatLeaderboardCountdown(const Duration(seconds: -1)),
        'Resetting…',
      );
      expect(
        formatLeaderboardCountdown(const Duration(days: -2)),
        'Resetting…',
      );
    });
  });

  group('LeaderboardDataModel reset parsing', () {
    LeaderboardDataModel parse(Map<String, dynamic> json) =>
        LeaderboardDataModel.fromJson(json, LeaderboardPeriod.weekly);

    test('reads resetAt and endsAt', () {
      final model = parse({
        'entries': const [],
        'resetAt': '2026-11-02T00:00:00.000Z',
        'endsAt': '2026-11-03T00:00:00.000Z',
      });

      expect(model.resetAt, DateTime.utc(2026, 11, 2));
      expect(model.endsAt, DateTime.utc(2026, 11, 3));
    });

    test('reads the documented endDate field', () {
      final model = parse({
        'entries': const [],
        'startDate': '2026-10-26T00:00:00.000Z',
        'endDate': '2026-11-02T00:00:00.000Z',
      });

      expect(model.endsAt, DateTime.utc(2026, 11, 2));
    });

    test('accepts snake_case aliases', () {
      final model = parse({
        'entries': const [],
        'next_reset_at': '2026-11-02T00:00:00.000Z',
        'expires_at': '2026-11-03T00:00:00.000Z',
      });

      expect(model.resetAt, DateTime.utc(2026, 11, 2));
      expect(model.endsAt, DateTime.utc(2026, 11, 3));
    });

    test('falls back endsAt to resetAt when only one is sent', () {
      final model = parse({
        'entries': const [],
        'resetAt': '2026-11-02T00:00:00.000Z',
      });

      expect(model.endsAt, model.resetAt);
    });

    test('parses epoch seconds and milliseconds', () {
      final seconds = parse({
        'entries': const [],
        'resetAt': 1793491200,
      });
      final millis = parse({
        'entries': const [],
        'resetAt': 1793491200000,
      });

      expect(seconds.resetAt, DateTime.utc(2026, 11, 1));
      expect(millis.resetAt, DateTime.utc(2026, 11, 1));
    });

    test('ignores a malformed timestamp instead of throwing', () {
      final model = parse({
        'entries': const [],
        'resetAt': 'not-a-date',
      });

      expect(model.resetAt, isNull);
    });

    test('passes the reset timestamps through to the entity', () {
      final entity = parse({
        'entries': const [],
        'resetAt': '2026-11-02T00:00:00.000Z',
      }).toEntity();

      expect(entity.nextResetUtc(), DateTime.utc(2026, 11, 2));
    });
  });
}
