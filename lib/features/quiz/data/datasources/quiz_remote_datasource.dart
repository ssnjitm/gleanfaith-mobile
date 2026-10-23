import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/quiz_entities.dart';
import '../models/quiz_models.dart';

/// Devanagari block (U+0900–U+097F) — the script Nepali is written in. Duplicated
/// from `quiz_models.dart` so this diagnostic never goes stale against it.
final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');

class QuizRemoteDataSource {
  final Dio _dio;

  QuizRemoteDataSource(this._dio);

  Future<List<QuizScheduleModel>> getUpcomingQuizzes({int limit = 20}) async {
    final response = await _dio.get(
      ApiConstants.quizScheduleUpcoming,
      queryParameters: {'limit': limit},
    );
    return _extractList(response.data)
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(QuizScheduleModel.fromJson)
        .toList();
  }

  Future<QuizScheduleModel?> getTodayDailyQuiz() async {
    final response = await _dio.get(ApiConstants.dailyQuizToday);
    final schedule = _extractScheduleMap(response.data);
    if (schedule == null) return null;
    return QuizScheduleModel.fromJson(schedule).asDaily();
  }

  Future<List<QuizScheduleModel>> getUpcomingDailyQuizzes({
    int days = 7,
  }) async {
    final response = await _dio.get(
      ApiConstants.dailyQuizUpcoming,
      queryParameters: {'days': days},
    );
    return _extractList(response.data)
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((json) => QuizScheduleModel.fromJson(json).asDaily())
        .toList();
  }

  /// Completed/attempted quiz schedules, used to enforce the one-attempt rule
  /// before the user presses Start.
  Future<List<QuizAttemptModel>> getQuizHistory({int limit = 50}) async {
    final response = await _dio.get(
      ApiConstants.quizScheduleHistory,
      queryParameters: {'page': 1, 'limit': limit},
    );
    return _extractList(response.data)
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(QuizAttemptModel.fromJson)
        .where((attempt) => attempt.scheduleId.isNotEmpty)
        .toList();
  }

  /// Reusable quiz series (campaigns) with their deployments.
  Future<List<QuizSeriesModel>> getSeries({
    bool includeDeployments = true,
  }) async {
    final response = await _dio.get(
      ApiConstants.quizScheduleSeries,
      queryParameters: {'includeDeployments': includeDeployments},
    );
    final data = _extractMap(response.data);
    return _extractList(data['series'] ?? data['data'] ?? data['items'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(QuizSeriesModel.fromJson)
        .where((series) => series.id.isNotEmpty)
        .toList();
  }

  Future<ActiveQuizModel> startQuiz(
    String quizScheduleId, {
    QuizLanguage language = QuizLanguage.english,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.quizScheduleStart}$quizScheduleId/start',
      queryParameters: {'language': language.code},
    );
    final session = _extractSessionMap(response.data);
    _logQuestionShape(session, language: language);
    return ActiveQuizModel.fromJson(session, language: language);
  }

  /// The question set behind a scheduled quiz.
  ///
  /// The set is the source of truth for the questions and keeps every
  /// language variant the backend stores, while a running session is
  /// materialised in the language it was started with. It is therefore where
  /// the missing wording comes from.
  Future<QuizSetModel> getQuizSet(String quizSetId) async {
    final response = await _dio.get(ApiConstants.quizSetById(quizSetId));
    return QuizSetModel.fromJson(_asMap(response.data) ?? const {});
  }

  /// The quiz set a schedule points at, preferring the copy embedded in the
  /// schedule detail.
  ///
  /// `GET /quiz-schedule/{id}` is readable by a normal user and its
  /// `schedule.quizSetId` is the *whole set* (id, title and questions with every
  /// language variant), whereas `GET /quiz-sets/{id}` is admin-facing. Returning
  /// the embedded set avoids the second request entirely. When the field is only
  /// an id, the returned model carries the id so the caller can still fall back
  /// to the quiz-sets route.
  Future<QuizSetModel> getScheduleQuizSet(String scheduleId) async {
    final response = await _dio.get(
      '${ApiConstants.quizScheduleDetail}$scheduleId',
    );
    final data = _asMap(response.data) ?? const <String, dynamic>{};
    final body = _asMap(data['data']) ?? data;
    final schedule =
        _asMap(body['schedule']) ??
        _asMap(body['quizSchedule']) ??
        _asMap(body['quiz']) ??
        body;

    for (final key in const [
      'quizSetId',
      'quizsetId',
      'quizSet',
      'quiz_set',
      'quizSet_id',
      'quiz_set_id',
    ]) {
      final value = schedule[key] ?? body[key];
      final map = _asMap(value);
      if (map != null) {
        final set = QuizSetModel.fromJson(map);
        if (set.id.isNotEmpty || set.questions.isNotEmpty) return set;
      }
      final id = _asString(value);
      if (id != null && id.isNotEmpty) {
        return QuizSetModel(id: id, title: '', questions: const []);
      }
    }
    return const QuizSetModel(id: '', title: '', questions: []);
  }

  /// The quiz set id a schedule points at.
  ///
  /// Used when the session payload does not carry the set id itself.
  Future<String?> getScheduleQuizSetId(String scheduleId) async {
    final response = await _dio.get(
      '${ApiConstants.quizScheduleDetail}$scheduleId',
    );
    final data = _asMap(response.data) ?? const <String, dynamic>{};
    final body = _asMap(data['data']) ?? data;
    // The schedule may be the body itself or nested under a few common keys.
    for (final node in [
      body,
      _asMap(body['schedule']),
      _asMap(body['quizSchedule']),
      _asMap(body['quiz']),
      _asMap(data['schedule']),
    ]) {
      if (node == null) continue;
      for (final key in const [
        'quizSetId',
        'quizsetId',
        'quizSet_id',
        'quiz_set_id',
        'setId',
      ]) {
        final value = node[key];
        final plain = _asString(value);
        if (plain != null && plain.isNotEmpty) return plain;
        // The schedule detail **populates** the field: `quizSetId` is an object
        // `{_id, title, questions...}`, not a string. Treating it as a string
        // returned null and the EN | NP toggle reported "no quiz set id".
        final map = _asMap(value);
        final id = _asString(map?['_id']) ?? _asString(map?['id']);
        if (id != null && id.isNotEmpty) return id;
      }
      final set = _asMap(node['quizSet']) ?? _asMap(node['quiz_set']);
      if (set != null) {
        final id = _asString(set['_id']) ?? _asString(set['id']);
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  /// Re-reads a running session in another language.
  ///
  /// The backend answers a session in the language it was started with, so a
  /// session started in Nepali carries no English. Asking for the same session
  /// id with `?language=en` is the only way to get the other wording without
  /// starting a second attempt (which the daily quiz allows only once).
  ///
  /// A failure here is not fatal: the caller keeps the questions it has.
  Future<ActiveQuizModel> getSession(
    String sessionId, {
    QuizLanguage language = QuizLanguage.english,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.quizSessionGet}$sessionId',
      queryParameters: {'language': language.code},
    );
    final session = _extractSessionMap(response.data);
    _logQuestionShape(session, language: language);
    return ActiveQuizModel.fromJson(session, language: language);
  }

  /// Logs, per question, whether a Nepali variant actually arrived from the
  /// backend and whether the parser kept it. Only key names, string lengths and
  /// script flags are printed — never the copy itself.
  ///
  /// The three outcomes are distinct and each points somewhere different:
  ///   * `np key: absent`        -> the response shape is not the one we parse
  ///   * `np key: len=0`         -> the backend shipped no translation
  ///   * `np key: len>0 non-np`  -> the translation is not Devanagari
  ///   * `parsed=hasNepali`      -> the parser kept it; the UI is the problem
  void _logQuestionShape(
    Map<String, dynamic> session, {
    required QuizLanguage language,
  }) {
    final questions = session['questions'];
    if (questions is! List || questions.isEmpty) {
      LoggerService.warning(
        'Quiz session carried no questions (keys: ${session.keys.join(', ')})',
      );
      return;
    }
    for (final entry in questions.take(3)) {
      final first = _asMap(entry);
      if (first == null) continue;
      final parsed = QuizQuestionModel.fromJson(
        first,
        fallbackIndex: 0,
        language: language,
      ).toEntity();
      LoggerService.info(
        'Quiz q${first['id'] ?? parsed.questionIndex}: '
        'lang=${language.code} '
        'keys[${first.keys.join(', ')}] | '
        'q=${_npState(first['question'])} | '
        'opt=${_npState(first['options'])} | '
        'parsed hasNepali=${parsed.hasNepali} '
        'hasEnglish=${parsed.hasEnglish} '
        'enOptions=${parsed.options.length} '
        'npOptions=${parsed.optionsNp.length}',
      );
    }
  }

  /// Describes where a Nepali variant sits inside [value] without printing it.
  String _npState(dynamic value) {
    if (value is String) {
      return 'plain string len=${value.length} '
          'devanagari=${_devanagari.hasMatch(value)}';
    }
    if (value is! List) {
      final map = _asMap(value) ?? const <String, dynamic>{};
      if (map.isEmpty) {
        return '${value.runtimeType} (no map, no np key)';
      }
      return 'map[${map.keys.join(', ')}] '
          'np=${_npValueState(map)}';
    }
    var maps = 0;
    var withNp = 0;
    var withNonEmptyNp = 0;
    for (final option in value) {
      final map = _asMap(option);
      if (map == null || map.isEmpty) continue;
      maps++;
      if (map.containsKey('np')) {
        withNp++;
        final np = map['np'];
        if (np is String && np.trim().isNotEmpty) withNonEmptyNp++;
      }
    }
    return value.isEmpty
        ? 'empty list'
        : 'list len=${value.length} maps=$maps withNpKey=$withNp '
            'withNonEmptyNp=$withNonEmptyNp '
            '(sample option keys: '
            '${(_asMap(value.first) ?? const <String, dynamic>{}).keys.join(', ')})';
  }

  String _npValueState(Map<String, dynamic> map) {
    if (!map.containsKey('np')) {
      final script = map.entries
          .where((e) => e.value is String)
          .map((e) => '${e.key}(len=${(e.value as String).length},'
              'np=${_devanagari.hasMatch(e.value as String)})')
          .join(' ');
      return 'absent [$script]';
    }
    final np = map['np'];
    if (np is String) {
      return 'len=${np.length} devanagari=${_devanagari.hasMatch(np)}';
    }
    return 'present as ${np.runtimeType}';
  }

  Future<AnswerResultModel> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
    QuizLanguage language = QuizLanguage.english,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.quizSessionAnswer}$sessionId/answer',
      queryParameters: {'language': language.code},
      data: {
        'questionIndex': questionIndex,
        'selectedOptionIndex': selectedOptionIndex,
        'timeSpentSeconds': timeSpentSeconds,
      },
    );
    return AnswerResultModel.fromJson(_extractMap(response.data));
  }

  Future<QuizResultModel> completeQuiz(String sessionId) async {
    final response = await _dio.post(
      '${ApiConstants.quizSessionComplete}$sessionId/complete',
    );
    return QuizResultModel.fromJson(_extractMap(response.data));
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  List<dynamic> _extractList(dynamic response) {
    final map = _asMap(response);
    if (map != null) {
      final data = map['data'];
      final dataMap = _asMap(data);
      if (data is List) return data;
      if (dataMap != null) {
        final inner =
            dataMap['quizzes'] ??
            dataMap['items'] ??
            dataMap['results'] ??
            dataMap['series'];
        if (inner is List) return inner;
      }
      final direct =
          map['quizzes'] ??
          map['items'] ??
          map['results'] ??
          map['series'] ??
          map['attempts'];
      if (direct is List) return direct;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }

  Map<String, dynamic>? _extractScheduleMap(dynamic response) {
    final map = _asMap(response);
    if (map == null) return null;

    final data = _asMap(map['data']);
    if (data != null) {
      final nested = _asMap(data['schedule']) ?? _asMap(data['quiz']);
      if (nested != null) {
        return nested.isEmpty ? null : nested;
      }
      return data.isEmpty ? null : data;
    }
    if (map['data'] != null) return null;

    final hasScheduleFields =
        map.containsKey('_id') ||
        map.containsKey('id') ||
        map.containsKey('title');
    return hasScheduleFields ? map : null;
  }

  /// Normalises the `start` response to a flat map that always exposes
  /// `sessionId` and `questions`.
  ///
  /// The backend nests the session in three different ways depending on the
  /// route (`data`, `data.session`, `data.quiz`), and when none of the keys
  /// matched `QuizPlayPage` used to sit on a spinner forever because
  /// `questions` came back empty.
  Map<String, dynamic> _extractSessionMap(dynamic response) {
    final map = _asMap(response) ?? const <String, dynamic>{};
    final data = _asMap(map['data']) ?? map;

    for (final key in const ['session', 'activeQuiz', 'quizSession', 'quiz']) {
      final nested = _asMap(data[key]);
      if (nested == null) continue;
      if (nested.containsKey('questions')) {
        // Flatten the wrapper without letting the nested key overwrite itself.
        final merged = <String, dynamic>{...data, ...nested};
        merged.remove(key);
        return merged;
      }
      if (nested.containsKey('sessionId') || nested.containsKey('_id')) {
        return {...data, ...nested};
      }
    }

    final questions =
        data['questions'] ??
        _asMap(data['quizSet'])?['questions'] ??
        _asMap(data['quiz_set'])?['questions'];
    if (questions is List) return data;

    return {...data, 'questions': const <dynamic>[]};
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    final map = _asMap(response);
    if (map == null) return const <String, dynamic>{};
    return _asMap(map['data']) ?? map;
  }
}
