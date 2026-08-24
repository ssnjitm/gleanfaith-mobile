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

  const LeaderboardData({
    required this.entries,
    required this.period,
    required this.userRank,
    required this.totalParticipants,
  });
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
