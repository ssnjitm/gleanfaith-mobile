import '../../domain/entities/quiz_entities.dart';

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) return value.values.toList();
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

/// Lenient int reader — the API mixes `10`, `10.0` (aggregation results) and
/// `"10"`, and a raw `as int?` cast throws on the latter two which used to
/// break the whole daily quiz payload.
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value == null) return null;
  return value.toString();
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
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
  final Map<String, dynamic>? metadata;

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
    this.metadata,
  });

  factory QuizScheduleModel.fromJson(Map<String, dynamic> json) {
    final quizSet = _asMap(json['quizSet']);
    final nestedQuestions = _asList(quizSet?['questions']);
    final rawTotal =
        _asInt(json['totalQuestions']) ?? _asInt(json['totalQuestion']);

    return QuizScheduleModel(
      id: _asString(json['_id']) ?? _asString(json['id']) ?? '',
      title: _asString(json['title']) ?? '',
      startDateTime:
          _asDate(json['startDateTime'] ?? json['startsAt']) ?? DateTime.now(),
      endDateTime:
          _asDate(json['endDateTime'] ?? json['endsAt']) ?? DateTime.now(),
      durationMinutes:
          _asInt(json['durationMinutes']) ?? _asInt(json['duration']) ?? 0,
      totalQuestions:
          rawTotal ?? (nestedQuestions.isNotEmpty ? nestedQuestions.length : 0),
      allowRetry: _asBool(json['allowRetry']) ?? false,
      maxRetries: _asInt(json['maxRetries']) ?? 1,
      status: _asString(json['status']) ?? '',
      metadata: _asMetadata(json['metadata']),
    );
  }

  static Map<String, dynamic>? _asMetadata(dynamic value) => _asMap(value);

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
      metadata: metadata,
    );
  }
}

class QuizQuestionModel {
  final String text;
  final List<String> options;
  final int questionIndex;
  final String? textNp;
  final List<String> optionsNp;

  const QuizQuestionModel({
    required this.text,
    required this.options,
    required this.questionIndex,
    this.textNp,
    this.optionsNp = const [],
  });

  factory QuizQuestionModel.fromJson(
    Map<String, dynamic> json, {
    int fallbackIndex = 0,
  }) {
    final np =
        _asMap(json['np']) ?? _asMap(json['ne']) ?? _asMap(json['nepali']);

    return QuizQuestionModel(
      text: _asString(json['text']) ?? _asString(json['question']) ?? '',
      options: _optionTexts(json['options']),
      questionIndex:
          _asInt(json['questionIndex']) ??
          _asInt(json['index']) ??
          fallbackIndex,
      textNp:
          _asString(json['textNp']) ??
          _asString(json['text_np']) ??
          _asString(json['npText']) ??
          _asString(json['textNepali']) ??
          _asString(np?['text']),
      optionsNp: _optionTexts(
        json['optionsNp'] ??
            json['options_np'] ??
            json['npOptions'] ??
            json['optionsNepali'] ??
            np?['options'],
      ),
    );
  }

  /// Options arrive either as plain strings, as `{text: ...}` objects or (for
  /// TRUE_FALSE questions) as raw booleans.
  static List<String> _optionTexts(dynamic value) {
    return _asList(value)
        .map((option) {
          final map = _asMap(option);
          if (map != null) {
            return _asString(map['text']) ??
                _asString(map['option']) ??
                _asString(map['label']) ??
                '';
          }
          if (option is bool) {
            return option ? 'True' : 'False';
          }
          return option?.toString() ?? '';
        })
        .where((option) => option.isNotEmpty)
        .toList();
  }

  QuizQuestion toEntity() => QuizQuestion(
    text: text,
    options: options,
    questionIndex: questionIndex,
    textNp: textNp,
    optionsNp: optionsNp,
  );
}

class ActiveQuizModel {
  final String sessionId;
  final int durationSeconds;
  final List<QuizQuestion> questions;
  final String? scheduleId;
  final String? title;
  final bool isDaily;
  final bool isSeries;
  final QuizLanguage language;

  const ActiveQuizModel({
    required this.sessionId,
    required this.durationSeconds,
    required this.questions,
    this.scheduleId,
    this.title,
    this.isDaily = false,
    this.isSeries = false,
    this.language = QuizLanguage.english,
  });

  factory ActiveQuizModel.fromJson(
    Map<String, dynamic> json, {
    QuizLanguage language = QuizLanguage.english,
  }) {
    final session = _asMap(json['session']) ?? const <String, dynamic>{};
    final quiz = _asMap(json['quiz']) ?? const <String, dynamic>{};
    final schedule = _asMap(json['schedule']) ?? const <String, dynamic>{};
    final quizSet = _asMap(json['quizSet']) ?? const <String, dynamic>{};

    final rawQuestions = _asList(
      json['questions'] ??
          session['questions'] ??
          quiz['questions'] ??
          json['questionsList'] ??
          quizSet['questions'],
    );

    final questions = <QuizQuestion>[];
    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = _asMap(rawQuestions[index]);
      if (raw == null) continue;
      questions.add(
        QuizQuestionModel.fromJson(raw, fallbackIndex: index).toEntity(),
      );
    }

    final metadata = _asMap(schedule['metadata']) ?? _asMap(json['metadata']);

    return ActiveQuizModel(
      sessionId:
          _asString(json['sessionId']) ??
          _asString(json['_id']) ??
          _asString(json['id']) ??
          _asString(session['sessionId']) ??
          _asString(session['_id']) ??
          '',
      durationSeconds:
          _asInt(json['durationSeconds']) ??
          _asInt(json['duration']) ??
          _asInt(json['remainingSeconds']) ??
          _asInt(json['timeLimitSeconds']) ??
          _asInt(session['durationSeconds']) ??
          0,
      questions: questions,
      scheduleId:
          _asString(json['quizScheduleId']) ??
          _asString(json['scheduleId']) ??
          _asString(schedule['_id']) ??
          _asString(schedule['id']),
      title:
          _asString(json['title']) ??
          _asString(quiz['title']) ??
          _asString(schedule['title']),
      isDaily: _asBool(metadata?['isDaily']) ?? false,
      isSeries:
          _asBool(metadata?['isSeries']) ??
          _asString(metadata?['seriesId']) != null,
      language: language,
    );
  }

  ActiveQuiz toEntity() => ActiveQuiz(
    sessionId: sessionId,
    durationSeconds: durationSeconds,
    questions: questions,
    scheduleId: scheduleId,
    title: title,
    isDaily: isDaily,
    isSeries: isSeries,
    language: language,
  );
}

class AnswerResultModel {
  final bool isCorrect;
  final int correctAnswerIndex;
  final String explanation;
  final int pointsEarned;
  final String? explanationNp;

  const AnswerResultModel({
    required this.isCorrect,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.pointsEarned,
    this.explanationNp,
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    return AnswerResultModel(
      isCorrect: _asBool(json['isCorrect']) ?? false,
      correctAnswerIndex: _asInt(json['correctAnswerIndex']) ?? -1,
      explanation: _asString(json['explanation']) ?? '',
      pointsEarned: _asInt(json['pointsEarned']) ?? 0,
      explanationNp:
          _asString(json['explanationNp']) ??
          _asString(json['explanation_np']) ??
          _asString(json['npExplanation']),
    );
  }

  AnswerResult toEntity() => AnswerResult(
    isCorrect: isCorrect,
    correctAnswerIndex: correctAnswerIndex,
    explanation: explanation,
    pointsEarned: pointsEarned,
    explanationNp: explanationNp,
  );
}

class QuizResultModel {
  final int score;
  final int maxPossibleScore;
  final int percentageScore;
  final bool passed;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int? totalPoints;
  final int? rank;

  const QuizResultModel({
    required this.score,
    required this.maxPossibleScore,
    required this.percentageScore,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    this.totalPoints,
    this.rank,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    final leaderboard =
        _asMap(json['leaderboard']) ??
        _asMap(json['ranking']) ??
        _asMap(json['userLevel']) ??
        const <String, dynamic>{};

    return QuizResultModel(
      score: _asInt(json['score']) ?? 0,
      maxPossibleScore:
          _asInt(json['maxPossibleScore']) ?? _asInt(json['maxScore']) ?? 0,
      percentageScore:
          _asInt(json['percentageScore']) ?? _asInt(json['percentage']) ?? 0,
      passed: _asBool(json['passed']) ?? false,
      totalQuestions:
          _asInt(json['totalQuestions']) ?? _asInt(json['totalAnswered']) ?? 0,
      correctAnswers: _asInt(json['correctAnswers']) ?? 0,
      wrongAnswers: _asInt(json['wrongAnswers']) ?? 0,
      totalPoints:
          _asInt(json['totalPoints']) ??
          _asInt(leaderboard['totalPoints']) ??
          _asInt(json['points']),
      rank:
          _asInt(json['rank']) ??
          _asInt(json['userRank']) ??
          _asInt(leaderboard['rank']) ??
          _asInt(leaderboard['allTimeRank']),
    );
  }

  QuizResult toEntity() => QuizResult(
    score: score,
    maxPossibleScore: maxPossibleScore,
    percentageScore: percentageScore,
    passed: passed,
    totalQuestions: totalQuestions,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    totalPoints: totalPoints,
    rank: rank,
  );
}

/// One row of `GET /quiz-schedule/history`.
class QuizAttemptModel {
  final String scheduleId;
  final String? sessionId;
  final bool isCompleted;
  final int? score;
  final DateTime? completedAt;

  const QuizAttemptModel({
    required this.scheduleId,
    this.sessionId,
    this.isCompleted = false,
    this.score,
    this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final schedule = _asMap(json['quizSchedule']) ?? const <String, dynamic>{};
    final status = (_asString(json['status']) ?? '').toLowerCase();
    final completedAt = _asDate(json['completedAt'] ?? json['finishedAt']);

    return QuizAttemptModel(
      scheduleId:
          _asString(json['quizScheduleId']) ??
          _asString(json['scheduleId']) ??
          _asString(schedule['_id']) ??
          _asString(schedule['id']) ??
          '',
      sessionId:
          _asString(json['sessionId']) ??
          _asString(json['session_id']) ??
          _asString(json['attemptId']),
      isCompleted:
          _asBool(json['isCompleted']) ??
          _asBool(json['completed']) ??
          status == 'completed' ||
              status == 'submitted' ||
              status == 'finished' ||
              completedAt != null,
      score: _asInt(json['score']) ?? _asInt(json['percentageScore']),
      completedAt: completedAt,
    );
  }

  QuizAttempt toEntity() => QuizAttempt(
    scheduleId: scheduleId,
    sessionId: sessionId,
    isCompleted: isCompleted,
    score: score,
    completedAt: completedAt,
  );
}

/// A row of `GET /quiz-schedule/series` plus its deployments.
class QuizSeriesModel {
  final String id;
  final String title;
  final String? description;
  final int durationValue;
  final String durationUnit;
  final String status;
  final List<QuizSchedule> deployments;

  const QuizSeriesModel({
    required this.id,
    required this.title,
    this.description,
    this.durationValue = 0,
    this.durationUnit = 'days',
    this.status = '',
    this.deployments = const [],
  });

  factory QuizSeriesModel.fromJson(Map<String, dynamic> json) {
    final rules = _asMap(json['defaultRules']) ?? const <String, dynamic>{};
    final title = _asString(json['title']) ?? '';

    final deployments =
        _asList(
          json['deployments'] ?? json['instances'] ?? json['schedules'],
        ).whereType<Map<dynamic, dynamic>>().map((raw) {
          final map = _asMap(raw) ?? const <String, dynamic>{};
          return QuizScheduleModel.fromJson(
            map['title'] == null ? {...map, 'title': title} : map,
          ).toEntity();
        }).toList();

    return QuizSeriesModel(
      id: _asString(json['_id']) ?? _asString(json['id']) ?? '',
      title: title,
      description: _asString(json['description']),
      durationValue:
          _asInt(json['durationValue']) ?? _asInt(rules['durationValue']) ?? 0,
      durationUnit: _asString(json['durationUnit']) ?? 'days',
      status: _asString(json['status']) ?? '',
      deployments: deployments,
    );
  }

  QuizSeries toEntity() => QuizSeries(
    id: id,
    title: title,
    description: description,
    durationValue: durationValue,
    durationUnit: durationUnit,
    status: status,
    deployments: deployments,
  );
}
