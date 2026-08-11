import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class GetPuzzleProgressUseCase {
  final CrossPuzzleRepository _repository;
  GetPuzzleProgressUseCase(this._repository);

  TaskEither<Failure, CrossPuzzleProgress?> call(String puzzleId) {
    return _repository.getPuzzleProgress(puzzleId);
  }
}