import 'quiz_entities.dart';

/// Localised UI copy for the Daily Quiz surfaces (hero card, play page and
/// result summary).
///
/// Only the Daily Quiz is translated for now — the Series / Other quiz lists
/// stay in English. Question and option text is translated by the backend and
/// selected through `QuizQuestion.textFor` / `optionsFor`, not from here.
class QuizStrings {
  const QuizStrings._({
    required this.dailyQuiz,
    required this.dailyTagline,
    required this.questions,
    required this.dailyChallenge,
    required this.startNow,
    required this.endedIn,
    required this.ended,
    required this.startsIn,
    required this.notStartedYet,
    required this.notStartedYetHint,
    required this.startsAt,
    required this.noQuizToday,
    required this.noQuizTodayHint,
    required this.loadFailed,
    required this.loadFailedHint,
    required this.retry,
    required this.streak,
    required this.day,
    required this.days,
    required this.attemptUsed,
    required this.attemptUsedHint,
    required this.oneAttemptOnly,
    required this.viewResult,
    required this.questionOf,
    required this.keepItUp,
    required this.streakLabel,
    required this.submitAnswer,
    required this.nextQuestion,
    required this.finishQuiz,
    required this.correct,
    required this.notQuite,
    required this.points,
    required this.timeUp,
    required this.timeUpHint,
    required this.congratulations,
    required this.niceTry,
    required this.passedHint,
    required this.failedHint,
    required this.correctLabel,
    required this.wrongLabel,
    required this.pointsEarned,
    required this.questionsAttempted,
    required this.backToHome,
    required this.moreQuizzes,
    required this.viewLeaderboard,
    required this.scoreAdded,
    required this.yourRank,
  });

  final String dailyQuiz;
  final String dailyTagline;
  final String questions;
  final String dailyChallenge;
  final String startNow;
  final String endedIn;
  final String ended;
  final String startsIn;
  final String notStartedYet;
  final String notStartedYetHint;
  final String startsAt;
  final String noQuizToday;
  final String noQuizTodayHint;
  final String loadFailed;
  final String loadFailedHint;
  final String retry;
  final String streak;
  final String day;
  final String days;
  final String attemptUsed;
  final String attemptUsedHint;
  final String oneAttemptOnly;
  final String viewResult;
  final String questionOf;
  final String keepItUp;
  final String streakLabel;
  final String submitAnswer;
  final String nextQuestion;
  final String finishQuiz;
  final String correct;
  final String notQuite;
  final String points;
  final String timeUp;
  final String timeUpHint;
  final String congratulations;
  final String niceTry;
  final String passedHint;
  final String failedHint;
  final String correctLabel;
  final String wrongLabel;
  final String pointsEarned;
  final String questionsAttempted;
  final String backToHome;
  final String moreQuizzes;
  final String viewLeaderboard;
  final String scoreAdded;
  final String yourRank;

  static const QuizStrings en = QuizStrings._(
    dailyQuiz: 'Daily Quiz',
    dailyTagline: 'Test your knowledge every day',
    questions: 'questions',
    dailyChallenge: 'Daily challenge',
    startNow: 'Start Now',
    endedIn: 'Ends in',
    ended: 'Ended',
    startsIn: 'Starts in',
    notStartedYet: 'Not started yet',
    notStartedYetHint:
        'This quiz opens at the scheduled time. Come back then to play.',
    startsAt: 'Starts at',
    noQuizToday: 'No Daily Quiz Today',
    noQuizTodayHint: 'Check back tomorrow for a new challenge.',
    loadFailed: "Couldn't load daily quiz",
    loadFailedHint: 'Check your connection and try again.',
    retry: 'Retry',
    streak: 'Streak',
    day: 'day',
    days: 'days',
    attemptUsed: 'Attempt already used',
    attemptUsedHint:
        'You already completed today\'s daily quiz. Come back tomorrow.',
    oneAttemptOnly: 'One attempt only',
    viewResult: 'View Result',
    questionOf: 'Question',
    keepItUp: 'Keep it up!',
    streakLabel: 'streak',
    submitAnswer: 'Submit Answer',
    nextQuestion: 'Next Question',
    finishQuiz: 'Finish Quiz',
    correct: 'Correct!',
    notQuite: 'Not quite',
    points: 'Points',
    timeUp: "Time's up!",
    timeUpHint: 'Your remaining answers were submitted automatically.',
    congratulations: 'Congratulations!',
    niceTry: 'Nice Try!',
    passedHint: 'You passed the quiz. Amazing work!',
    failedHint: 'Almost there — keep learning and try again.',
    correctLabel: 'Correct',
    wrongLabel: 'Wrong',
    pointsEarned: 'points earned',
    questionsAttempted: 'questions attempted',
    backToHome: 'Back to Home',
    moreQuizzes: 'More Quizzes',
    viewLeaderboard: 'View Leaderboard',
    scoreAdded: 'Added to your total',
    yourRank: 'Your rank',
  );

  static const QuizStrings np = QuizStrings._(
    dailyQuiz: 'दैनिक क्विज',
    dailyTagline: 'हरेक दिन आफ्नो ज्ञान जाँच्नुहोस्',
    questions: 'प्रश्न',
    dailyChallenge: 'दैनिक चुनौती',
    startNow: 'सुरु गर्नुहोस्',
    endedIn: 'समाप्त हुने',
    ended: 'समाप्त',
    startsIn: 'सुरु हुने',
    notStartedYet: 'अझै सुरु भएको छैन',
    notStartedYetHint: 'यो क्विज तोकिएको समयमा खुल्छ। त्यसपछि आएर खेल्नुहोस्।',
    startsAt: 'सुरु हुने समय',
    noQuizToday: 'आज कुनै दैनिक क्विज छैन',
    noQuizTodayHint: 'नयाँ चुनौतीका लागि भोलि फेरि हेर्नुहोस्।',
    loadFailed: 'दैनिक क्विज लोड हुन सकेन',
    loadFailedHint: 'इन्टरनेट जाँचेर पुनः प्रयास गर्नुहोस्।',
    retry: 'पुनः प्रयास',
    streak: 'लगातार',
    day: 'दिन',
    days: 'दिन',
    attemptUsed: 'प्रयास पहिले नै प्रयोग भइसक्यो',
    attemptUsedHint:
        'तपाईंले आजको दैनिक क्विज पूरा गरिसक्नुभयो। भोलि फेरि आउनुहोस्।',
    oneAttemptOnly: 'एकपटक मात्र प्रयास',
    viewResult: 'नतिजा हेर्नुहोस्',
    questionOf: 'प्रश्न',
    keepItUp: 'यसरी नै जारी राख्नुहोस्!',
    streakLabel: 'लगातार',
    submitAnswer: 'उत्तर पेश गर्नुहोस्',
    nextQuestion: 'अर्को प्रश्न',
    finishQuiz: 'क्विज समाप्त गर्नुहोस्',
    correct: 'सही छ!',
    notQuite: 'ठीकै भएन',
    points: 'अंक',
    timeUp: 'समय सकियो!',
    timeUpHint: 'बाँकी उत्तरहरू स्वतः पेश गरियो।',
    congratulations: 'बधाई छ!',
    niceTry: 'राम्रो प्रयास!',
    passedHint: 'तपाईंले क्विज उत्तीर्ण गर्नुभयो। धन्यवाद!',
    failedHint: 'अलि कम पर्नुभयो — अझै पढ्नुहोस् र पुनः प्रयास गर्नुहोस्।',
    correctLabel: 'सही',
    wrongLabel: 'गल्ती',
    pointsEarned: 'अंक प्राप्त',
    questionsAttempted: 'प्रश्नहरू गरिए',
    backToHome: 'गृहपृष्ठमा',
    moreQuizzes: 'थप क्विज',
    viewLeaderboard: 'लिडरबोर्ड हेर्नुहोस्',
    scoreAdded: 'जम्मा अंकमा थपियो',
    yourRank: 'तपाईंको स्थान',
  );

  static QuizStrings of(QuizLanguage language) =>
      language == QuizLanguage.nepali ? np : en;

  /// `Ends in 2h 5m` / `Ends in 12m` / `Ended` for a countdown.
  String remainingLabel(Duration remaining) {
    if (remaining.isNegative) return ended;
    return _durationLabel(remaining, endedIn);
  }

  /// `Starts in 2h 5m` for a quiz whose window has not opened yet.
  String startsInLabel(Duration remaining) {
    if (remaining.isNegative) return startsAt;
    return _durationLabel(remaining, startsIn);
  }

  String _durationLabel(Duration remaining, String prefix) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) return '$prefix $days d $hours h';
    if (hours > 0) return '$prefix $hours h $minutes m';
    final seconds = remaining.inSeconds % 60;
    if (minutes == 0) return '$prefix $seconds s';
    return '$prefix $minutes m';
  }

  /// `3 days` / `1 day` for the streak chip.
  String dayCount(int count) => count == 1 ? '1 $day' : '$count $days';
}
