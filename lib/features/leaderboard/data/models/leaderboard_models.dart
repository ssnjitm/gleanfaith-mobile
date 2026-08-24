import '../../domain/entities/leaderboard_entities.dart';

class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final int points;
  final String username;
  final String? avatar;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.points,
    required this.username,
    this.avatar,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ??
          (user is Map<String, dynamic> ? user['_id'] as String? ?? '' : ''),
      points: (json['points'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ??
          (user is Map<String, dynamic> ? user['username'] as String? ?? 'user' : 'user'),
      avatar: json['avatar'] as String?,
    );
  }

  LeaderboardEntry toEntity() {
    return LeaderboardEntry(
      rank: rank,
      userId: userId,
      points: points,
      username: username,
      avatar: avatar,
    );
  }
}

class LeaderboardDataModel {
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final int userRank;
  final int totalParticipants;

  const LeaderboardDataModel({
    required this.entries,
    required this.period,
    required this.userRank,
    required this.totalParticipants,
  });

  factory LeaderboardDataModel.fromJson(
    Map<String, dynamic> json,
    LeaderboardPeriod fallbackPeriod,
  ) {
    final periodRaw = (json['period'] as String? ?? '').toLowerCase();
    final period = switch (periodRaw) {
      'weekly' => LeaderboardPeriod.weekly,
      'monthly' => LeaderboardPeriod.monthly,
      'all_time' || 'alltime' => LeaderboardPeriod.allTime,
      _ => fallbackPeriod,
    };
    final entriesRaw = json['entries'];
    final entries = entriesRaw is List
        ? entriesRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => LeaderboardEntryModel.fromJson(e).toEntity())
            .toList()
        : <LeaderboardEntry>[];
    return LeaderboardDataModel(
      entries: entries,
      period: period,
      userRank: (json['userRank'] as num?)?.toInt() ?? 0,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
    );
  }

  LeaderboardData toEntity() {
    return LeaderboardData(
      entries: entries,
      period: period,
      userRank: userRank,
      totalParticipants: totalParticipants,
    );
  }
}

class MyRankingModel {
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

  const MyRankingModel({
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

  factory MyRankingModel.fromJson(Map<String, dynamic> json) {
    return MyRankingModel(
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentLevelPoints: (json['currentLevelPoints'] as num?)?.toInt() ?? 0,
      nextLevelPoints: (json['nextLevelPoints'] as num?)?.toInt() ?? 0,
      pointsToNextLevel: (json['pointsToNextLevel'] as num?)?.toInt() ?? 0,
      badge: json['badge'] as String? ?? '',
      weeklyRank: (json['weeklyRank'] as num?)?.toInt() ?? 0,
      monthlyRank: (json['monthlyRank'] as num?)?.toInt() ?? 0,
      allTimeRank: (json['allTimeRank'] as num?)?.toInt() ?? 0,
      quizzesCompleted: (json['quizzesCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  MyRanking toEntity() {
    return MyRanking(
      totalPoints: totalPoints,
      level: level,
      currentLevelPoints: currentLevelPoints,
      nextLevelPoints: nextLevelPoints,
      pointsToNextLevel: pointsToNextLevel,
      badge: badge,
      weeklyRank: weeklyRank,
      monthlyRank: monthlyRank,
      allTimeRank: allTimeRank,
      quizzesCompleted: quizzesCompleted,
    );
  }
}
