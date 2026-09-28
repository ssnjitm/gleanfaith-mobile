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

/// Devanagari block (U+0900–U+097F) — the script Nepali is written in.
final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');

/// True when [value] contains Devanagari characters, i.e. it is Nepali text.
///
/// The backend ships both languages per question but does not guarantee *which*
/// key holds the Nepali variant (`textNp`, `nepaliQuestion`, a nested `np`
/// object, a per-option `{en, np}` pair…). Detecting the script is name
/// agnostic, so a key rename cannot silently leave the EN | NP toggle dead.
bool _looksNepali(String? value) {
  if (value == null) return false;
  return _devanagari.hasMatch(value);
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
    // `GET /daily-quiz/today` does not return a bare schedule: it nests the
    // schedule (and sometimes a daily-quiz wrapper) under its own key, and the
    // identifier is then `quizScheduleId`/`scheduleId` rather than `_id`/`id`.
    // A missed id produced an EMPTY id, which made the Start button silently
    // disabled — the single worst failure mode of the daily quiz.
    final schedule =
        _asMap(json['quizSchedule']) ?? _asMap(json['schedule']) ?? const {};
    final daily =
        _asMap(json['dailyQuiz']) ?? _asMap(json['today']) ?? const {};
    // Nested values are defaults only: whatever the top level carries wins.
    final merged = <String, dynamic>{...schedule, ...daily, ...json};

    final quizSet = _asMap(merged['quizSet']);
    final nestedQuestions = _asList(quizSet?['questions']);
    final rawTotal =
        _asInt(merged['totalQuestions']) ?? _asInt(merged['totalQuestion']);

    return QuizScheduleModel(
      id: _resolveId(json, schedule, daily),
      title: _asString(merged['title']) ?? '',
      startDateTime:
          _asDate(merged['startDateTime'] ?? merged['startsAt']) ??
          DateTime.now(),
      endDateTime:
          _asDate(merged['endDateTime'] ?? merged['endsAt']) ?? DateTime.now(),
      durationMinutes:
          _asInt(merged['durationMinutes']) ?? _asInt(merged['duration']) ?? 0,
      totalQuestions:
          rawTotal ?? (nestedQuestions.isNotEmpty ? nestedQuestions.length : 0),
      allowRetry: _asBool(merged['allowRetry']) ?? false,
      maxRetries: _asInt(merged['maxRetries']) ?? 1,
      status: _asString(merged['status']) ?? '',
      metadata: _asMetadata(merged['metadata']),
    );
  }

  /// First identifier we can find, preferring the schedule's own id over the
  /// daily-quiz wrapper id — only a schedule id can be started.
  static String _resolveId(
    Map<String, dynamic> json,
    Map<String, dynamic> schedule,
    Map<String, dynamic> daily,
  ) {
    const keys = ['_id', 'id', 'quizScheduleId', 'scheduleId'];
    for (final source in [json, schedule, daily]) {
      for (final key in keys) {
        final value = _asString(source[key]);
        if (value != null) return value;
      }
    }
    return '';
  }

  static Map<String, dynamic>? _asMetadata(dynamic value) => _asMap(value);

  QuizScheduleModel copyWith({
    String? id,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? durationMinutes,
    int? totalQuestions,
    bool? allowRetry,
    int? maxRetries,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return QuizScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      allowRetry: allowRetry ?? this.allowRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Marks a schedule served by the daily-quiz endpoints as a daily quiz.
  ///
  /// Those endpoints only return a daily schedule, but the payload often omits
  /// `metadata.isDaily`. Without the flag the app treated the session as a
  /// regular quiz: no EN | NP toggle, and the single-attempt rule did not apply.
  QuizScheduleModel asDaily() {
    if (metadata?['isDaily'] == true) return this;
    return copyWith(metadata: {...?metadata, 'isDaily': true});
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
    // Shapes seen from the backend, all accepted:
    //  a) `question: {en, np}` + `options: [{id, text: {en, np}, is_correct}]`
    //  b) `text: "..."`      + `textNp: "..."`, `options: [...]`, `optionsNp: [...]`
    //  c) `en: {text, options}` + `np: {text, options}`
    //  d) `question: {np: {text, options}}` alongside an English `question`
    final text = _englishText(json);
    final textNp = _nepaliText(json, english: text);

    var options = _optionLabels(json['options'], nepali: false);
    var optionsNp = _optionLabels(json['options'], nepali: true);

    // (c) the language nodes carry their own text and options.
    if (options.isEmpty) {
      options = _optionLabels(_node(json, 'en')?['options'], nepali: false);
    }
    if (!_usable(optionsNp)) {
      optionsNp = _optionLabels(_node(json, 'np')?['options'], nepali: true);
    }
    // (b) a sibling list of Nepali options.
    if (!_usable(optionsNp)) {
      for (final key in const [
        'optionsNp',
        'options_np',
        'npOptions',
        'optionsNepali',
        'optionTranslations',
      ]) {
        final labels = _optionLabels(json[key], nepali: true);
        if (labels.isNotEmpty) {
          optionsNp = labels;
          break;
        }
      }
    }

    return QuizQuestionModel(
      text: text,
      options: options,
      questionIndex:
          _asInt(json['questionIndex']) ??
          _asInt(json['index']) ??
          _asInt(json['order']) ??
          fallbackIndex,
      textNp: textNp,
      // A partial or mismatched Nepali list is discarded so answer indices stay
      // aligned with the answer key; `optionsFor` then falls back to English.
      optionsNp:
          optionsNp.length == options.length && _usable(optionsNp)
          ? optionsNp
          : const [],
    );
  }

  /// The `en` / `np` / `ne` / `nepali` sub-object, when the payload has one.
  static Map<String, dynamic>? _node(Map<String, dynamic> json, String key) {
    for (final alias in [key, if (key == 'np') ...['ne', 'nepali']]) {
      final map = _asMap(json[alias]);
      if (map != null) return map;
    }
    return null;
  }

  /// English question text.
  static String _englishText(Map<String, dynamic> json) {
    // (a) `question: {en, np}`
    final question = _asMap(json['question']);
    if (question != null) {
      final en = _bilingual(question).en;
      if (en != null) return en;
    }
    // (b) a plain `question` / `text` string.
    final plain = _asString(json['question']) ?? _asString(json['text']);
    if (plain != null) return plain;
    // (c) `en: {text, options}`
    final en = _node(json, 'en');
    final nested = _asString(en?['text']) ?? _asString(en?['question']);
    if (nested != null) return nested;
    return _bilingual(json).en ?? '';
  }

  /// Nepali question text: known keys first, then a script scan so a renamed
  /// field cannot leave the EN | NP toggle inert.
  static String? _nepaliText(Map<String, dynamic> json, {required String english}) {
    // (a) `question: {en, np}`
    final question = _asMap(json['question']);
    if (question != null) {
      final np = _bilingual(question).np;
      if (np != null) return np;
    }
    // (b) sibling keys.
    for (final key in const [
      'textNp',
      'text_np',
      'npText',
      'nepaliText',
      'questionNp',
      'translation',
    ]) {
      final candidate = _asString(json[key]);
      if (_looksNepali(candidate)) return candidate;
    }
    // (c) / (d) `np: {text, options}`.
    final np = _node(json, 'np');
    final nested = _asString(np?['text']) ?? _asString(np?['question']);
    if (_looksNepali(nested)) return nested;

    // Last resort: any Devanagari string on the question that is not the
    // English text.
    return _scanNepali(json, exclude: english);
  }

  /// Reads one label per option for the requested language.
  ///
  /// An entry may be a plain string, a boolean (TRUE_FALSE), `{text: "..."}` or
  /// `{text: {en, np}}`. When the inner value holds only one language, the whole
  /// entry is re-scanned by script, so `{text, translation}` also resolves.
  static List<String> _optionLabels(dynamic value, {required bool nepali}) {
    final labels = <String>[];
    for (final option in _asList(value)) {
      if (option is bool) {
        final label = option ? 'True' : 'False';
        labels.add(label);
        continue;
      }
      final map = _asMap(option);
      if (map == null) {
        final label = _asString(option);
        if (label == null) continue;
        // A plain string list is English; only accept it as Nepali when it is
        // actually written in Devanagari.
        labels.add(nepali ? (_looksNepali(label) ? label : '') : label);
        continue;
      }
      final inner = map['text'] ?? map['label'] ?? map['option'];
      var pair = _bilingual(inner);
      if ((nepali ? pair.np : pair.en) == null) {
        pair = _bilingual(map);
      }
      final label = nepali ? pair.np : pair.en;
      labels.add((label == null || label.isEmpty) ? '' : label);
    }
    return labels;
  }

  /// Resolves a value that is either a plain string or a `{en, np}` object.
  ///
  /// Known keys are tried first (`en`/`np` plus their aliases), then the object
  /// is split by script: the first Devanagari string is the Nepali side, the
  /// first non-Devanagari one is the English side. The script split is what
  /// keeps the toggle working if the backend renames `np` to something else.
  static ({String? en, String? np}) _bilingual(dynamic value) {
    final map = _asMap(value);
    if (map == null) {
      final text = _asString(value);
      return (en: text, np: _looksNepali(text) ? text : null);
    }

    var en =
        _asString(map['en']) ??
        _asString(map['english']) ??
        _asString(map['text']) ??
        _asString(map['question']);
    var np =
        _asString(map['np']) ??
        _asString(map['ne']) ??
        _asString(map['nepali']) ??
        _asString(map['nepaliText']) ??
        _asString(map['npText']) ??
        _asString(map['textNp']) ??
        _asString(map['text_np']);

    // Only real strings are considered, so `is_correct: true` or an option `id`
    // can never be mistaken for copy.
    final strings = map.entries
        .where((entry) => !_isMetadataKey(entry.key))
        .map((entry) => entry.value)
        .whereType<String>()
        .toList();
    en ??= strings.firstWhere(
      (candidate) => !_looksNepali(candidate),
      orElse: () => '',
    );
    np ??= strings.firstWhere(_looksNepali, orElse: () => '');

    return (en: en.isEmpty ? null : en, np: np.isEmpty ? null : np);
  }

  /// Keys that hold identifiers or flags rather than copy.
  static bool _isMetadataKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'id' ||
        lower == '_id' ||
        lower == 'key' ||
        lower == 'value' ||
        lower == 'correct' ||
        lower.contains('correct') ||
        lower.contains('weight') ||
        lower.contains('point');
  }

  /// Any Devanagari string in [json] (one level of nesting), other than
  /// [exclude].
  static String? _scanNepali(Map<String, dynamic> json, {required String exclude}) {
    for (final entry in json.entries) {
      if (_isOptionKey(entry.key) || _isMetadataKey(entry.key)) continue;
      final candidate = _asString(entry.value);
      if (candidate != exclude && _looksNepali(candidate)) return candidate;
    }
    for (final entry in json.entries) {
      if (_isOptionKey(entry.key) || _isMetadataKey(entry.key)) continue;
      final map = _asMap(entry.value);
      if (map == null) continue;
      for (final inner in map.values) {
        final candidate = _asString(inner);
        if (candidate != exclude && _looksNepali(candidate)) return candidate;
      }
    }
    return null;
  }

  static bool _isOptionKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('option') || lower.contains('choice');
  }

  /// True when every slot holds real copy. Reading a plain English string list
  /// as Nepali yields empty placeholders, and those must not be mistaken for a
  /// translation.
  static bool _usable(List<String> labels) {
    return labels.isNotEmpty && labels.every((label) => label.isNotEmpty);
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
    final explanation = _asString(json['explanation']) ?? '';
    return AnswerResultModel(
      isCorrect: _asBool(json['isCorrect']) ?? false,
      correctAnswerIndex: _asInt(json['correctAnswerIndex']) ?? -1,
      explanation: explanation,
      pointsEarned: _asInt(json['pointsEarned']) ?? 0,
      explanationNp: _findNepaliExplanation(json, explanation: explanation),
    );
  }

  /// Known aliases first, then a script scan of every other string in the
  /// payload, so a renamed field still translates.
  static String? _findNepaliExplanation(
    Map<String, dynamic> json, {
    required String explanation,
  }) {
    const aliases = [
      'explanationNp',
      'explanation_np',
      'npExplanation',
      'explanationNepali',
      'nepaliExplanation',
      'npText',
      'nepaliText',
    ];
    for (final alias in aliases) {
      final candidate = _asString(json[alias]);
      if (_looksNepali(candidate)) return candidate;
    }

    final nested = _asMap(json['np']) ?? _asMap(json['ne']) ??
        _asMap(json['nepali']);
    if (nested != null) {
      final candidate = _asString(
        nested['explanation'] ?? nested['text'] ?? nested['reason'],
      );
      if (_looksNepali(candidate)) return candidate;
    }

    for (final entry in json.entries) {
      final candidate = _asString(entry.value);
      if (candidate != explanation && _looksNepali(candidate)) return candidate;
    }

    return null;
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
