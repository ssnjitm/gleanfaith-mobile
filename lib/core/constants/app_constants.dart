class AppConstants {
  AppConstants._();

  static const String appName = 'Glean Faith';
  static const String appVersion = '1.0.0';
  static const int quizQuestionLimit = 10;

  /// Time box for a single quiz attempt, in seconds (5 minutes).
  ///
  /// The quiz countdown is owned by the client, not the backend: the start
  /// response and the schedule may both omit a duration, which previously left
  /// the attempt untimed. Every attempt uses this budget regardless of what the
  /// server sends.
  static const int quizDurationSeconds = 5 * 60;
  static const int leaderboardLimit = 50;
  static const int weeklyLeaderboardDays = 7;
  static const int monthlyLeaderboardDays = 30;

  // Secure storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String courseQuizAttemptsKey = 'course_quiz_attempts';
}
