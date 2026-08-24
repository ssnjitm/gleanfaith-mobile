import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/leaderboard_entities.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_datasource.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;

  LeaderboardRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, LeaderboardData> getLeaderboard({
    required LeaderboardPeriod period,
    int limit = 100,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getLeaderboard(
          period: period.queryValue,
          limit: limit,
          fallbackPeriod: period,
        );
        return result.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, MyRanking> getMyRanking() {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getMyRanking();
        return result.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }
}
