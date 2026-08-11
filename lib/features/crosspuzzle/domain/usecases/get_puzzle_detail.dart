import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class GetPuzzleDetailUseCase {
  final CrossPuzzleRepository _repository;
  GetPuzzleDetailUseCase(this._repository);

  TaskEither<Failure, CrossPuzzleDetail> call(String puzzleId) {
    return _repository.getPuzzleDetail(puzzleId);
  }
}