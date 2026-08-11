import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../../domain/repositories/crosspuzzle_repository.dart';
import '../datasources/crosspuzzle_local_datasource.dart';
import '../datasources/crosspuzzle_remote_datasource.dart';
import '../models/crosspuzzle_models.dart';

/// Repository that prefers the remote API and transparently falls back to
/// the bundled 50-level local dataset whenever the backend is unreachable
/// or has no published puzzles yet.
class CrossPuzzleRepositoryImpl implements CrossPuzzleRepository {
  final CrossPuzzleRemoteDataSource _remoteDataSource;
  final CrossPuzzleLocalDataSource _localDataSource;

  CrossPuzzleRepositoryImpl(this._remoteDataSource, this._localDataSource);

  /// How long to wait for the backend before falling back to the bundled
  /// dataset. Keeps the loading spinner short when the API is unreachable.
  static const Duration _remoteTimeout = Duration(seconds: 5);

  @override
  TaskEither<Failure, List<CrossPuzzle>> getPuzzles({
    int page = 1,
    int limit = 10,
    String? difficulty,
  }) {
    return TaskEither.tryCatch(
      () async {
        var puzzles = <CrossPuzzle>[];
        try {
          final result = await _remoteDataSource
              .getPuzzles(
                page: page,
                limit: limit,
                difficulty: difficulty,
              )
              .timeout(_remoteTimeout);
          puzzles = result.map((e) => e.toEntity()).toList();
        } catch (_) {
          // Offline or backend error -> fall back to the bundled dataset.
        }

        if (puzzles.isEmpty) {
          puzzles = await _localDataSource.getLocalPuzzles();
        }

        if (difficulty != null && difficulty.isNotEmpty) {
          puzzles = puzzles
              .where((p) => p.difficulty.toLowerCase() == difficulty)
              .toList();
        }
        return puzzles;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CrossPuzzleDetail> getPuzzleDetail(String puzzleId) {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzleId)) {
      return TaskEither.tryCatch(
        () => _localDataSource.getLocalPuzzleDetail(puzzleId),
        (error, stackTrace) => handleError(error),
      );
    }

    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getPuzzleDetail(puzzleId);
        final puzzleRaw = result['puzzle'] is Map<String, dynamic>
            ? result['puzzle'] as Map<String, dynamic>
            : <String, dynamic>{};
        final progressRaw = result['progress'];
        final revealAnswers = result['revealAnswers'] as bool? ?? false;

        final puzzle = CrossPuzzleModel.fromJson(puzzleRaw).toEntity();
        final progress = progressRaw is Map<String, dynamic>
            ? CrossPuzzleProgressModel.fromJson(progressRaw).toEntity()
            : null;
        return CrossPuzzleDetail(
          puzzle: puzzle,
          progress: progress,
          revealAnswers: revealAnswers,
        );
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CrossPuzzleProgress?> getPuzzleProgress(String puzzleId) {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzleId)) {
      return TaskEither.tryCatch(
        () => _localDataSource.getLocalProgress(puzzleId),
        (error, stackTrace) => handleError(error),
      );
    }

    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getPuzzleProgress(puzzleId);
        return result == null
            ? null
            : CrossPuzzleProgressModel.fromJson(result).toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<CrossPuzzleWithProgress>> getMyProgress({
    int page = 1,
    int limit = 10,
  }) {
    return TaskEither.tryCatch(
      () async {
        List<CrossPuzzleWithProgress> progress;
        try {
          final result = await _remoteDataSource.getMyProgress(
            page: page,
            limit: limit,
          );
          progress = result.map((e) => e.toEntity()).toList();
        } catch (_) {
          // Offline or backend error -> fall back to local progress.
          progress = await _localDataSource.getMyLocalProgress();
        }
        return progress;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CrossPuzzleProgress> saveProgress({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzleId)) {
      return TaskEither.tryCatch(
        () => _localDataSource.saveLocalProgress(
          puzzleId: puzzleId,
          gridState: gridState,
          revealedCells: revealedCells,
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        ),
        (error, stackTrace) => handleError(error),
      );
    }

    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.saveProgress(
          puzzleId: puzzleId,
          gridState: gridState
              .map(
                (c) => GridCellModel(row: c.row, col: c.col, value: c.value).toJson(),
              )
              .toList(),
          revealedCells: revealedCells
              .map((c) => RevealedCellModel(row: c.row, col: c.col).toJson())
              .toList(),
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        );
        return result.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CrossPuzzleCompleteResult> completePuzzle({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzleId)) {
      return TaskEither.tryCatch(
        () => _localDataSource.completeLocalPuzzle(
          puzzleId: puzzleId,
          gridState: gridState,
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        ),
        (error, stackTrace) => handleError(error),
      );
    }

    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.completePuzzle(
          puzzleId: puzzleId,
          gridState: gridState
              .map(
                (c) => GridCellModel(row: c.row, col: c.col, value: c.value).toJson(),
              )
              .toList(),
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        );
        return result.toEntity();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, String> resetPuzzle(String puzzleId) {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzleId)) {
      return TaskEither.tryCatch(
        () async {
          await _localDataSource.resetLocalProgress(puzzleId);
          return 'reset';
        },
        (error, stackTrace) => handleError(error),
      );
    }

    return TaskEither.tryCatch(
      () async => _remoteDataSource.resetPuzzle(puzzleId),
      (error, stackTrace) => handleError(error),
    );
  }
}
