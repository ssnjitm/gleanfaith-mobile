import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/leaderboard_entities.dart';
import '../models/leaderboard_models.dart';

class LeaderboardRemoteDataSource {
  final Dio _dio;

  LeaderboardRemoteDataSource(this._dio);

  Future<LeaderboardDataModel> getLeaderboard({
    required String period,
    required int limit,
    required LeaderboardPeriod fallbackPeriod,
  }) async {
    final response = await _dio.get(
      ApiConstants.leaderboard,
      queryParameters: {'period': period, 'limit': limit},
    );
    return LeaderboardDataModel.fromJson(_extractMap(response.data), fallbackPeriod);
  }

  Future<MyRankingModel> getMyRanking() async {
    final response = await _dio.get(ApiConstants.leaderboardMe);
    return MyRankingModel.fromJson(_extractMap(response.data));
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        if (data['entries'] is List) return data;
        final inner = data['leaderboard'];
        if (inner is Map<String, dynamic> && inner['entries'] is List) {
          return inner;
        }
        return data;
      }
      if (response['entries'] is List) return response;
    }
    return {};
  }
}
