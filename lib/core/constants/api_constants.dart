class ApiConstants {
  ApiConstants._();

  // static const String baseUrl = 'http://192.168.1.78:8000/api/v1';
  static const String baseUrl =
      'https://glean-faith-temp-backend-production.up.railway.app/api/v1';

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

  static String quizSetById(String id) => '/quiz-sets/$id';

  // Quiz Schedule & Sessions
  static const String quizScheduleUpcoming = '/quiz-schedule/upcoming';
  static const String quizScheduleHistory = '/quiz-schedule/history';
  static const String quizScheduleSeries = '/quiz-schedule/series';
  static const String quizScheduleStart = '/quiz-schedule/';
  static const String quizSessionAnswer = '/quiz-schedule/session/';
  static const String quizSessionComplete = '/quiz-schedule/session/';

  // Daily Quiz
  static const String dailyQuizToday = '/daily-quiz/today';
  static const String dailyQuizUpcoming = '/daily-quiz/upcoming';

  // Content Library
  static const String content = '/content';
  static const String contentCategories = '/content/categories';

  static String contentById(String id) => '/content/$id';

  // Courses
  static const String courses = '/courses';
  static const String coursesMyProgress = '/courses/my-progress';

  static String courseById(String id) => '/courses/$id';
  static String courseStart(String id) => '/courses/$id/start';
  static String courseReset(String id) => '/courses/$id/reset';
  static String courseProgress(String id) => '/courses/$id/progress';
  static String courseLessonComplete(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId/complete';
  static String courseItemComplete(String courseId, String itemId) =>
      '/courses/$courseId/items/$itemId/complete';

  // Leaderboard
  static const String leaderboard = '/leaderboard';
  static const String leaderboardMe = '/leaderboard/me';

  // Bible Study — Continue Reading / Bookmarks / Chapter Notes
  static const String readingHistory = '/reading-history';
  static const String readingHistoryRecent = '/reading-history/recent';
  static const String bookmarks = '/bookmarks';
  static const String notes = '/notes';

  static String bookmarkById(String id) => '/bookmarks/$id';
  static String noteById(String id) => '/notes/$id';

  // CrossPuzzle
  static const String crossPuzzle = '/crosspuzzle';
  static const String crossPuzzleProgress = '/crosspuzzle/progress';

  // Notifications (user-facing)
  static const String notificationsUser = '/notifications/user';
  static const String notificationsUserReadAll = '/notifications/user/read-all';

  static String notificationMarkRead(String id) =>
      '/notifications/user/$id/read';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Free Use Bible API (bible.helloao.org) ──────────────────────────────
  //
  // A completely separate host from [baseUrl]: no auth token is attached, no
  // auth refresh happens, and an outage here must never disturb the app's own
  // API calls. MIT-licensed, no API key, no quota, no signup.
  //
  // Serves the Home verse of the day in both languages. Fetching instead of
  // bundling keeps a Nepali Bible (megabytes of text) out of the app for a
  // feature used once a day, and keeps the English text in the same versification
  // as the Nepali — see `DailyVersePlan` for why that has to match.
  //
  // The endpoint is chapter-grained — `/{translation}/{USFM_BOOK}/{chapter}.json`
  // — so one request returns ~3-8 KB and a single verse is picked out of it.
  static const String freeBibleBaseUrl = 'https://bible.helloao.org';

  /// Nepali translation id on the Free Use Bible API. `npi` is Nepali
  /// (Devanagari script).
  ///
  /// Chosen over the other Nepali entry, `npi_ncb`, because `npi_ncb` currently
  /// serves its verse bodies as literal `?` characters instead of Devanagari.
  /// `npi_ulb` ("पवित्र बाइबल", full 66 books) is verified to return real text.
  static const String nepaliTranslationId = 'npi_ulb';

  /// English translation id on the Free Use Bible API.
  ///
  /// `eng_web` is "World English Bible Classic" (Public Domain). It is the
  /// English half of the verse of the day rather than the bundled SQLite KJV
  /// database, because English and Nepali must show the *same* verse: the two
  /// texts are resolved from the same curated reference, so a versification
  /// difference could otherwise put two different verses under one date.
  ///
  /// Do not substitute a non-English id that merely starts with `eng` — the host
  /// also serves e.g. `amp` (Chichewa), which answers 200 with the wrong script.
  static const String englishTranslationId = 'eng_web';

  /// Deliberately short. A slow free endpoint must not leave the verse card
  /// shimmering: the caller falls back to the other language, then to a
  /// hardcoded verse.
  static const Duration freeBibleTimeout = Duration(seconds: 12);

  /// Path of a single chapter, e.g. `/api/npi_ulb/JHN/3.json`.
  static String freeBibleChapter({
    required String translationId,
    required String usfmBook,
    required int chapter,
  }) => '/api/$translationId/$usfmBook/$chapter.json';
}
