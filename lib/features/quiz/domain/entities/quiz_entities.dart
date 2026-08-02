class QuizSchedule {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final int totalQuestions;
  final bool allowRetry;
  final int maxRetries;
  final String status;

  const QuizSchedule({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.allowRetry,
    required this.maxRetries,
    required this.status,
  });
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int questionIndex;

  const QuizQuestion({
    required this.text,
    required this.options,
    required this.questionIndex,
  });
}

class ActiveQuiz {
  final String sessionId;
  final int durationSeconds;
  final List<QuizQuestion> questions;

  const ActiveQuiz({
    required this.sessionId,
    required this.durationSeconds,
    required this.questions,
  });
}

class AnswerResult {
  final bool isCorrect;
  final int correctAnswerIndex;
  final String explanation;
  final int pointsEarned;

  const AnswerResult({
    required this.isCorrect,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.pointsEarned,
  });
}

class QuizResult {
  final int score;
  final int maxPossibleScore;
  final int percentageScore;
  final bool passed;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;

  const QuizResult({
    required this.score,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
  });
}