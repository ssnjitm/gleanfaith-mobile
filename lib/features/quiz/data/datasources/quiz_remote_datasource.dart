import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/quiz_models.dart';

class QuizRemoteDataSource {
  final Dio _dio;

  QuizRemoteDataSource(this._dio);

  Future<List<QuizScheduleModel>> getUpcomingQuizzes() async {
    final response = await _dio.get(
      ApiConstants.quizScheduleUpcoming,
      queryParameters: {'limit': 10},
    );
    final list = _extractList(response.data);
    return list
        .map((e) => QuizScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ActiveQuizModel> startQuiz(String quizScheduleId) async {
    final response = await _dio.post(
      '${ApiConstants.quizScheduleStart}$quizScheduleId/start',
    );
    return ActiveQuizModel.fromJson(_extractMap(response.data));
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

  List<dynamic> _extractList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final inner = data['quizzes'] ?? data['items'] ?? data['results'];
        if (inner is List) return inner;
      }
      final direct = response['quizzes'] ?? response['items'];
      if (direct is List) return direct;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
    }
    if (response is Map<String, dynamic>) return response;
    return {};
  }
}