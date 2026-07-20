class UserStats {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;
  final String badge;
  final int weeklyRank;
  final int quizzesCompleted;

  const UserStats({
    this.totalPoints = 0,
    this.level = 1,
    this.currentLevelPoints = 0,
    this.nextLevelPoints = 100,
    this.pointsToNextLevel = 100,
    this.badge = 'bronze',
    this.weeklyRank = 0,
    this.quizzesCompleted = 0,
  });
}

class UpcomingQuiz {
  final String id;
  final String title;
  final DateTime startDateTime;
  final int durationMinutes;
  final int totalQuestions;

  const UpcomingQuiz({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.durationMinutes,
    required this.totalQuestions,
  });
}

class RecentActivity {
  final String id;
  final String quizTitle;
  final int score;
  final int maxScore;
  final int percentageScore;
  final bool passed;
  final DateTime completedAt;

  const RecentActivity({
    required this.id,
    required this.quizTitle,
    required this.score,
    required this.maxScore,
    required this.percentageScore,
    required this.passed,
    required this.completedAt,
  });
}

class HomeData {
  final UserStats stats;
  final List<UpcomingQuiz> upcomingQuizzes;
  final List<RecentActivity> recentActivity;

  const HomeData({
    required this.stats,
    this.upcomingQuizzes = const [],
    this.recentActivity = const [],
  });
}
