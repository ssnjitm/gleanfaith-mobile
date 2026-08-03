class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String home = '/home';

  // Auth
  static const String signin = '/auth/signin';
  static const String signup = '/auth/signup';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Features
  static const String quiz = '/quiz';
  static const String quizDetail = '/quiz/detail';
  static const String quizPlay = '/quiz/play';
  static const String quizResult = '/quiz/result';
  static const String leaderboard = '/leaderboard';
  static const String library = '/library';
  static const String libraryDetail = '/library/detail';
  static const String blog = '/blog';
  static const String blogDetail = '/blog/detail';
  static const String video = '/video';
  static const String audio = '/audio';
  static const String pdf = '/pdf';
  static const String article = '/article';
  static const String profile = '/profile';
  static const String settings = '/settings';

  //bible 
  static const String bibleSearch = '/bible/search';
  static const String bibleTopicDetail = '/bible/topic/:topic';
  static const String bibleVerseDetail = '/bible/verse/:book/:chapter/:verse';
}
