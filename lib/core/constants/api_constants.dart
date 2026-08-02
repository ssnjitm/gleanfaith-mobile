class ApiConstants {
  ApiConstants._();

  // static const String baseUrl = 'http://192.168.1.78:8000/api/v1';
  static const String baseUrl = 'https://glean-faith-temp-backend-production.up.railway.app/api/v1';


  // Auth
  static const String login = '/auth/login';
  static const String registerRequest = '/auth/register-request';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // User
  static const String userMe = '/user/me';
  static const String userProfile = '/user/profile';
  static const String userStats = '/user/stats';

  // Quiz Sets (admin only — not used for user-facing quiz list)
  static const String quizSetsAll = '/quiz-sets/all-quizes';

  // Quiz Schedule & Sessions
  static const String quizScheduleUpcoming = '/quiz-schedule/upcoming';
  static const String quizScheduleStart = '/quiz-schedule/';
  static const String quizSessionAnswer = '/quiz-schedule/session/';
  static const String quizSessionComplete = '/quiz-schedule/session/';

  // Content Library
  static const String content = '/content';
  static const String contentCategories = '/content/categories';

  // Leaderboard
  static const String leaderboard = '/leaderboard';
  static const String leaderboardMe = '/leaderboard/me';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
