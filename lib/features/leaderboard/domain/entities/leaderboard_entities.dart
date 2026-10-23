enum LeaderboardPeriod { weekly, monthly, allTime }

extension LeaderboardPeriodX on LeaderboardPeriod {
  String get queryValue {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'weekly';
      case LeaderboardPeriod.monthly:
        return 'monthly';
      case LeaderboardPeriod.allTime:
        return 'all_time';
    }
  }

  String get label {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'Weekly';
      case LeaderboardPeriod.monthly:
        return 'Monthly';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final int points;
  final String username;
  final String? avatar;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.points,
    required this.username,
    this.avatar,
  });
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final int userRank;
  final int totalParticipants;
  final DateTime? resetAt;
  final DateTime? endsAt;

  const LeaderboardData({
    required this.entries,
    required this.period,
    required this.userRank,
    required this.totalParticipants,
    this.resetAt,
    this.endsAt,
  });

  /// Reset timestamp for this period, in UTC.
  ///
  /// Server-provided timestamps always win, so every device agrees with the
  /// backend that actually resets the rankings. Without one, the client falls
  /// back to the documented schedule: Monday 00:00 UTC for weekly and the 1st
  /// of the next month 00:00 UTC for monthly. All-time never resets.
  DateTime? nextResetUtc({DateTime? now}) {
    final explicit = endsAt ?? resetAt;
    if (explicit != null) return explicit.toUtc();
    return fallbackLeaderboardResetUtc(period, now: now);
  }
}

/// Client-side fallback reset schedule for [period], in UTC.
DateTime? fallbackLeaderboardResetUtc(
  LeaderboardPeriod period, {
  DateTime? now,
}) {
  final current = (now ?? DateTime.now()).toUtc();
  switch (period) {
    case LeaderboardPeriod.weekly:
      final daysUntilMonday = (DateTime.monday - current.weekday) % 7;
      final days = daysUntilMonday == 0 ? 7 : daysUntilMonday;
      return DateTime.utc(current.year, current.month, current.day)
          .add(Duration(days: days));
    case LeaderboardPeriod.monthly:
      return DateTime.utc(current.year, current.month + 1, 1);
    case LeaderboardPeriod.allTime:
      return null;
  }
}

/// Human-readable countdown, e.g. `Ends in 2d 14h 32m`, `Ends in 4m 09s`,
/// or `Resetting…` once the window has closed.
String formatLeaderboardCountdown(Duration remaining) {
  if (remaining.inSeconds <= 0) return 'Resetting…';
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;
  if (days > 0) return 'Ends in ${days}d ${hours}h ${minutes}m';
  if (hours > 0) return 'Ends in ${hours}h ${minutes}m';
  if (minutes > 0) {
    final padded = seconds.toString().padLeft(2, '0');
    return 'Ends in ${minutes}m ${padded}s';
  }
  return 'Ends in ${seconds}s';
}

class MyRanking {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;
  final String badge;
  final int weeklyRank;
  final int monthlyRank;
  final int allTimeRank;
  final int quizzesCompleted;

  const MyRanking({
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
    required this.badge,
    required this.weeklyRank,
    required this.monthlyRank,
    required this.allTimeRank,
    required this.quizzesCompleted,
  });

  static const empty = MyRanking(
    totalPoints: 0,
    level: 1,
    currentLevelPoints: 0,
    nextLevelPoints: 0,
    pointsToNextLevel: 0,
    badge: '',
    weeklyRank: 0,
    monthlyRank: 0,
    allTimeRank: 0,
    quizzesCompleted: 0,
  );
}
