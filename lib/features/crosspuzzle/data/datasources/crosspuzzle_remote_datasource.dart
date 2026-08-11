import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/crosspuzzle_models.dart';

class CrossPuzzleRemoteDataSource {
  final Dio _dio;

  CrossPuzzleRemoteDataSource(this._dio);

  Future<List<CrossPuzzleModel>> getPuzzles({
    int page = 1,
    int limit = 10,
    String? difficulty,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }
    final response = await _dio.get(ApiConstants.crossPuzzle, queryParameters: query);
    final list = _extractList(response.data, 'puzzles');
    return list
        .map((e) => CrossPuzzleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPuzzleDetail(String puzzleId) async {
    final response = await _dio.get('${ApiConstants.crossPuzzle}/$puzzleId');
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>?> getPuzzleProgress(String puzzleId) async {
    final response = await _dio.get('${ApiConstants.crossPuzzle}/$puzzleId/progress');
    return _extractMapNullable(response.data);
  }

  Future<List<CrossPuzzleWithProgressModel>> getMyProgress({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.crossPuzzleProgress,
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = _extractList(response.data, 'progress');
    return list
        .map((e) => CrossPuzzleWithProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CrossPuzzleProgressModel> saveProgress({
    required String puzzleId,
    required List<Map<String, dynamic>> gridState,
    required List<Map<String, dynamic>> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    final response = await _dio.put(
      '${ApiConstants.crossPuzzle}/$puzzleId/progress',
      data: {
        'gridState': gridState,
        'revealedCells': revealedCells,
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'timeSpentSeconds': timeSpentSeconds,
      },
    );
    return CrossPuzzleProgressModel.fromJson(_extractMap(response.data));
  }

  Future<CrossPuzzleCompleteResultModel> completePuzzle({
    required String puzzleId,
    required List<Map<String, dynamic>> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.crossPuzzle}/$puzzleId/complete',
      data: {
        'gridState': gridState,
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'timeSpentSeconds': timeSpentSeconds,
      },
    );
    return CrossPuzzleCompleteResultModel.fromJson(_extractMap(response.data));
  }

  Future<String> resetPuzzle(String puzzleId) async {
    final response = await _dio.post('${ApiConstants.crossPuzzle}/$puzzleId/reset');
    final map = _extractMap(response.data);
    return (map['status'] as String?) ?? 'reset';
  }

  List<dynamic> _extractList(dynamic response, String key) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final inner = data[key];
        if (inner is List) return inner;
      }
      final direct = response[key];
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

  Map<String, dynamic>? _extractMapNullable(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data == null) return null;
    }
    if (response is Map<String, dynamic>) return response;
    return null;
  }
}