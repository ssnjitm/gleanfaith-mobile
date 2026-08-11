import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/crosspuzzle_local_datasource.dart';
import '../../data/datasources/crosspuzzle_remote_datasource.dart';
import '../../data/repositories/crosspuzzle_repository_impl.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../../domain/repositories/crosspuzzle_repository.dart';
import '../../domain/usecases/complete_puzzle.dart';
import '../../domain/usecases/get_my_progress.dart';
import '../../domain/usecases/get_puzzle_detail.dart';
import '../../domain/usecases/get_puzzle_progress.dart';
import '../../domain/usecases/get_puzzles.dart';
import '../../domain/usecases/reset_puzzle.dart';
import '../../domain/usecases/save_progress.dart';

enum CrossPuzzleStatus { initial, loading, success, error }

final crossPuzzleRepositoryProvider = Provider<CrossPuzzleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return CrossPuzzleRepositoryImpl(
    CrossPuzzleRemoteDataSource(dio),
    CrossPuzzleLocalDataSource(storage),
  );
});

final getPuzzlesUseCaseProvider = Provider<GetPuzzlesUseCase>((ref) {
  return GetPuzzlesUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final getPuzzleDetailUseCaseProvider = Provider<GetPuzzleDetailUseCase>((ref) {
  return GetPuzzleDetailUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final getPuzzleProgressUseCaseProvider = Provider<GetPuzzleProgressUseCase>((ref) {
  return GetPuzzleProgressUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final getMyProgressUseCaseProvider = Provider<GetMyProgressUseCase>((ref) {
  return GetMyProgressUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final saveProgressUseCaseProvider = Provider<SaveProgressUseCase>((ref) {
  return SaveProgressUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final completePuzzleUseCaseProvider = Provider<CompletePuzzleUseCase>((ref) {
  return CompletePuzzleUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

final resetPuzzleUseCaseProvider = Provider<ResetPuzzleUseCase>((ref) {
  return ResetPuzzleUseCase(ref.watch(crossPuzzleRepositoryProvider));
});

class CrossPuzzleState {
  final CrossPuzzleStatus status;
  final List<CrossPuzzle> puzzles;
  final List<CrossPuzzleWithProgress> myProgress;
  final CrossPuzzleDetail? activeDetail;
  final String? message;
  final String selectedDifficulty;

  const CrossPuzzleState({
    this.status = CrossPuzzleStatus.initial,
    this.puzzles = const [],
    this.myProgress = const [],
    this.activeDetail,
    this.message,
    this.selectedDifficulty = '',
  });

  CrossPuzzleState copyWith({
    CrossPuzzleStatus? status,
    List<CrossPuzzle>? puzzles,
    List<CrossPuzzleWithProgress>? myProgress,
    CrossPuzzleDetail? activeDetail,
    String? message,
    String? selectedDifficulty,
  }) {
    return CrossPuzzleState(
      status: status ?? this.status,
      puzzles: puzzles ?? this.puzzles,
      myProgress: myProgress ?? this.myProgress,
      activeDetail: activeDetail ?? this.activeDetail,
      message: message,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
    );
  }
}

final crossPuzzleProvider = StateNotifierProvider<CrossPuzzleNotifier, CrossPuzzleState>((ref) {
  return CrossPuzzleNotifier(ref);
});

class CrossPuzzleNotifier extends StateNotifier<CrossPuzzleState> {
  final Ref _ref;

  CrossPuzzleNotifier(this._ref) : super(const CrossPuzzleState());

  Future<void> loadPuzzles({String? difficulty}) async {
    state = state.copyWith(
      status: CrossPuzzleStatus.loading,
      message: null,
      selectedDifficulty: difficulty ?? state.selectedDifficulty,
    );
    final result = await _ref
        .read(getPuzzlesUseCaseProvider)
        .call(difficulty: difficulty ?? state.selectedDifficulty)
        .run();
    result.fold(
      (failure) => state = state.copyWith(
        status: CrossPuzzleStatus.error,
        message: failure.message,
      ),
      (puzzles) => state = state.copyWith(
        status: CrossPuzzleStatus.success,
        puzzles: puzzles,
      ),
    );
  }

  Future<void> loadMyProgress() async {
    state = state.copyWith(status: CrossPuzzleStatus.loading, message: null);
    final result = await _ref.read(getMyProgressUseCaseProvider)().run();
    result.fold(
      (failure) => state = state.copyWith(
        status: CrossPuzzleStatus.error,
        message: failure.message,
      ),
      (progress) => state = state.copyWith(
        status: CrossPuzzleStatus.success,
        myProgress: progress,
      ),
    );
  }

  Future<CrossPuzzleDetail?> loadPuzzleDetail(String puzzleId) async {
    state = state.copyWith(status: CrossPuzzleStatus.loading, message: null);
    final result = await _ref.read(getPuzzleDetailUseCaseProvider)(puzzleId).run();
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: CrossPuzzleStatus.error,
          message: failure.message,
        );
        return null;
      },
      (detail) {
        state = state.copyWith(
          status: CrossPuzzleStatus.success,
          activeDetail: detail,
        );
        return detail;
      },
    );
  }

  Future<CrossPuzzleProgress?> saveProgress({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    final result = await _ref.read(saveProgressUseCaseProvider).call(
          puzzleId: puzzleId,
          gridState: gridState,
          revealedCells: revealedCells,
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return null;
      },
      (progress) => progress,
    );
  }

  Future<CrossPuzzleCompleteResult?> completePuzzle({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    state = state.copyWith(status: CrossPuzzleStatus.loading, message: null);
    final result = await _ref.read(completePuzzleUseCaseProvider).call(
          puzzleId: puzzleId,
          gridState: gridState,
          mistakes: mistakes,
          hintsUsed: hintsUsed,
          timeSpentSeconds: timeSpentSeconds,
        ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: CrossPuzzleStatus.error,
          message: failure.message,
        );
        return null;
      },
      (completeResult) {
        state = state.copyWith(
          status: CrossPuzzleStatus.success,
          message: null,
        );
        return completeResult;
      },
    );
  }

  Future<bool> resetPuzzle(String puzzleId) async {
    final result = await _ref.read(resetPuzzleUseCaseProvider)(puzzleId).run();
    return result.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return false;
      },
      (_) => true,
    );
  }

  void clearActiveDetail() {
    state = state.copyWith(activeDetail: null, message: null);
  }
}