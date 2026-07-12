class AppConstants {
  AppConstants._();

  static const String appName = 'Glean Faith';
  static const String appVersion = '1.0.0';
  static const int quizQuestionLimit = 10;
  static const int leaderboardLimit = 50;
  static const int weeklyLeaderboardDays = 7;
  static const int monthlyLeaderboardDays = 30;

  // Secure storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
}
