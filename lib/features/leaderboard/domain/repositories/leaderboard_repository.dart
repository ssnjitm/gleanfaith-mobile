import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaderboard_entities.dart';

abstract class LeaderboardRepository {
  TaskEither<Failure, LeaderboardData> getLeaderboard({
    required LeaderboardPeriod period,
    int limit,
  });
  TaskEither<Failure, MyRanking> getMyRanking();
}
