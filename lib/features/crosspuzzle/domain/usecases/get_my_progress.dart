import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class GetMyProgressUseCase {
  final CrossPuzzleRepository _repository;
  GetMyProgressUseCase(this._repository);

  TaskEither<Failure, List<CrossPuzzleWithProgress>> call({
    int page = 1,
    int limit = 10,
  }) {
    return _repository.getMyProgress(page: page, limit: limit);
  }
}