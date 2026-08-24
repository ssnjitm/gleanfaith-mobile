import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_entities.dart';
import '../repositories/profile_repository.dart';

class GetAccountStatsUseCase {
  final ProfileRepository _repository;
  GetAccountStatsUseCase(this._repository);

  TaskEither<Failure, AccountStats> call() {
    return _repository.getAccountStats();
  }
}
