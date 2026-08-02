import '../../domain/entities/quiz_entities.dart';

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) return value.values.toList();
  return const [];
}

class QuizScheduleModel {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final int totalQuestions;
  final bool allowRetry;
  final int maxRetries;
  final String status;

  const QuizScheduleModel({
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

  factory QuizScheduleModel.fromJson(Map<String, dynamic> json) {
    return QuizScheduleModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDateTime: _parseDate(json['startDateTime'] ?? json['startsAt']),
      endDateTime: _parseDate(json['endDateTime'] ?? json['endsAt']),
      durationMinutes: json['durationMinutes'] as int? ?? json['duration'] as int? ?? 0,
      totalQuestions: (json['totalQuestions'] as int?) ??
          (json['quizSet'] is Map
              ? _asList(json['quizSet']!['questions']).length
              : 0),
      allowRetry: json['allowRetry'] as bool? ?? false,
      maxRetries: json['maxRetries'] as int? ?? 1,
      status: json['status'] as String? ?? '',
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  QuizSchedule toEntity() {
    return QuizSchedule(
      id: id,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      allowRetry: allowRetry,
      maxRetries: maxRetries,
      status: status,
    );
  }
}

class QuizQuestionModel {
  final String text;
  final List<String> options;
  final int questionIndex;

  const QuizQuestionModel({
    required this.text,
    required this.options,
    required this.questionIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      text: json['text'] as String? ?? json['question'] as String? ?? '',
      options: _asList(json['options']).map((e) => e.toString()).toList(),
      questionIndex: json['questionIndex'] as int? ?? 0,
    );
  }

  QuizQuestion toEntity() {
    return QuizQuestion(
      text: text,
      options: options,
      questionIndex: questionIndex,
    );
  }
}

class ActiveQuizModel {
  final String sessionId;
  final int durationSeconds;
  final List<QuizQuestion> questions;

  const ActiveQuizModel({
    required this.sessionId,
    required this.durationSeconds,
    required this.questions,
  });

  factory ActiveQuizModel.fromJson(Map<String, dynamic> json) {
    final questions = _asList(json['questions'])
        .map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return ActiveQuizModel(
      sessionId: json['sessionId'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      questions: questions,
    );
  }

  ActiveQuiz toEntity() {
    return ActiveQuiz(
      sessionId: sessionId,
      durationSeconds: durationSeconds,
      questions: questions,
    );
  }
}

class AnswerResultModel {
  final bool isCorrect;
  final int correctAnswerIndex;
  final String explanation;
  final int pointsEarned;

  const AnswerResultModel({
    required this.isCorrect,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.pointsEarned,
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    return AnswerResultModel(
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? -1,
      explanation: json['explanation'] as String? ?? '',
      pointsEarned: json['pointsEarned'] as int? ?? 0,
    );
  }

  AnswerResult toEntity() {
    return AnswerResult(
      isCorrect: isCorrect,
      correctAnswerIndex: correctAnswerIndex,
      explanation: explanation,
      pointsEarned: pointsEarned,
    );
  }
}

class QuizResultModel {
  final int score;
  final int maxPossibleScore;
  final int percentageScore;
  final bool passed;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;

  const QuizResultModel({
    required this.score,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      score: json['score'] as int? ?? 0,
      maxPossibleScore: json['maxPossibleScore'] as int? ?? 0,
      percentageScore: json['percentageScore'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      wrongAnswers: json['wrongAnswers'] as int? ?? 0,
    );
  }

  QuizResult toEntity() {
    return QuizResult(
      score: score,
      maxPossibleScore: maxPossibleScore,
      percentageScore: percentageScore,
      passed: passed,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
    );
  }
}