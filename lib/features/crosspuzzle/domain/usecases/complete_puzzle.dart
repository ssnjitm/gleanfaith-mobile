import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class CompletePuzzleUseCase {
  final CrossPuzzleRepository _repository;
  CompletePuzzleUseCase(this._repository);

  TaskEither<Failure, CrossPuzzleCompleteResult> call({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    return _repository.completePuzzle(
      puzzleId: puzzleId,
      gridState: gridState,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}