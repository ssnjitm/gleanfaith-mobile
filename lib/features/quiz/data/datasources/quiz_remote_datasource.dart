import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/quiz_entities.dart';
import '../models/quiz_models.dart';

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
    _logQuestionShape(session);
    return ActiveQuizModel.fromJson(session, language: language);
  }

  /// Logs the key shape of the first question so a translation problem is
  /// diagnosable without guessing. Only key names and string lengths are
  /// printed — never the copy itself.
  void _logQuestionShape(Map<String, dynamic> session) {
    final questions = session['questions'];
    if (questions is! List || questions.isEmpty) {
      LoggerService.warning(
        'Quiz session carried no questions (keys: ${session.keys.join(', ')})',
      );
      return;
    }
    final first = _asMap(questions.first);
    if (first == null) return;
    final question = _asMap(first['question']);
    final options = first['options'];
    final firstOption = options is List && options.isNotEmpty
        ? _asMap(options.first)
        : null;
    LoggerService.info(
      'Quiz question keys: ${first.keys.join(', ')} | '
      'question is ${question == null ? 'a ${first['question'].runtimeType}' : 'a map with ${question.keys.join(', ')}'} | '
      'option keys: ${firstOption?.keys.join(', ') ?? 'n/a'}',
    );
  }

  Future<AnswerResultModel> submitAnswer({
    required String sessionId,
    required int questionIndex,
    required int selectedOptionIndex,
    required int timeSpentSeconds,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.quizSessionAnswer}$sessionId/answer',
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
        data['questions'] ?? _asMap(data['quizSet'])?['questions'];
    if (questions is List) return data;

    return {...data, 'questions': const <dynamic>[]};
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    final map = _asMap(response);
    if (map == null) return const <String, dynamic>{};
    return _asMap(map['data']) ?? map;
  }
}
