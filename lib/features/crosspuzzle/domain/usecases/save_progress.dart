import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';
import '../repositories/crosspuzzle_repository.dart';

class SaveProgressUseCase {
  final CrossPuzzleRepository _repository;
  SaveProgressUseCase(this._repository);

  TaskEither<Failure, CrossPuzzleProgress> call({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    return _repository.saveProgress(
      puzzleId: puzzleId,
      gridState: gridState,
      revealedCells: revealedCells,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}