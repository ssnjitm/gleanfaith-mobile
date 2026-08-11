import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/crosspuzzle_entities.dart';

abstract class CrossPuzzleRepository {
  TaskEither<Failure, List<CrossPuzzle>> getPuzzles({
    int page = 1,
    int limit = 10,
    String? difficulty,
  });

  TaskEither<Failure, CrossPuzzleDetail> getPuzzleDetail(String puzzleId);

  TaskEither<Failure, CrossPuzzleProgress?> getPuzzleProgress(String puzzleId);

  TaskEither<Failure, List<CrossPuzzleWithProgress>> getMyProgress({
    int page = 1,
    int limit = 10,
  });

  TaskEither<Failure, CrossPuzzleProgress> saveProgress({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  });

  TaskEither<Failure, CrossPuzzleCompleteResult> completePuzzle({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  });

  TaskEither<Failure, String> resetPuzzle(String puzzleId);
}