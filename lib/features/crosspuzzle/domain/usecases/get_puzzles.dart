import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class GetPuzzlesUseCase {
  final CrossPuzzleRepository _repository;
  GetPuzzlesUseCase(this._repository);

  TaskEither<Failure, List<CrossPuzzle>> call({
    int page = 1,
    int limit = 10,
    String? difficulty,
  }) {
    return _repository.getPuzzles(page: page, limit: limit, difficulty: difficulty);
  }
}