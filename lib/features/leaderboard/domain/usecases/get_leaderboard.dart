import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaderboard_entities.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboardUseCase {
  final LeaderboardRepository _repository;
  GetLeaderboardUseCase(this._repository);

  TaskEither<Failure, LeaderboardData> call({
    required LeaderboardPeriod period,
    int limit = 100,
  }) {
    return _repository.getLeaderboard(period: period, limit: limit);
  }
}
