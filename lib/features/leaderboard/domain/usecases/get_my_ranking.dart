import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaderboard_entities.dart';
import '../repositories/leaderboard_repository.dart';

class GetMyRankingUseCase {
  final LeaderboardRepository _repository;
  GetMyRankingUseCase(this._repository);

  TaskEither<Failure, MyRanking> call() {
    return _repository.getMyRanking();
  }
}
