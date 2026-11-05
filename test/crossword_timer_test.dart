import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:glean_faith_app/core/error/error_handler.dart';
import 'package:glean_faith_app/core/error/failures.dart';
import 'package:glean_faith_app/core/router/route_names.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/entities/crosspuzzle_entities.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/repositories/crosspuzzle_repository.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/usecases/complete_puzzle.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/usecases/get_puzzle_detail.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/usecases/save_progress.dart';
import 'package:glean_faith_app/features/crosspuzzle/presentation/models/crossword_timer.dart';
import 'package:glean_faith_app/features/crosspuzzle/presentation/pages/crosspuzzle_play_page.dart';
import 'package:glean_faith_app/features/crosspuzzle/presentation/pages/crosspuzzle_result_page.dart';
import 'package:glean_faith_app/features/crosspuzzle/presentation/providers/crosspuzzle_provider.dart';
import 'package:go_router/go_router.dart';

/// Placeholder repository: the use cases below are fakes that override `call`,
/// so no repository method is ever reached.
class _StubRepository implements CrossPuzzleRepository {
  const _StubRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('stub repository');
}

class _FakeDetailUseCase extends GetPuzzleDetailUseCase {
  _FakeDetailUseCase(this.detail) : super(const _StubRepository());

  final CrossPuzzleDetail detail;

  @override
  TaskEither<Failure, CrossPuzzleDetail> call(String puzzleId) =>
      TaskEither.right(detail);
}

class _FakeSaveProgressUseCase extends SaveProgressUseCase {
  _FakeSaveProgressUseCase() : super(const _StubRepository());

  @override
  TaskEither<Failure, CrossPuzzleProgress> call({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) => TaskEither.left(const CacheFailure(message: 'save skipped in test'));
}

/// Completion is parked on a [Completer] so the test can inspect the page
/// while the request is in flight — exactly the window in which the reported
/// bug kept the timer running.
class _FakeCompletePuzzleUseCase extends CompletePuzzleUseCase {
  _FakeCompletePuzzleUseCase() : super(const _StubRepository());

  final Completer<void> _gate = Completer<void>();
  final List<int> receivedTimes = [];

  int? get receivedTimeSpentSeconds =>
      receivedTimes.isEmpty ? null : receivedTimes.last;

  void failNow() => _gate.complete();

  @override
  TaskEither<Failure, CrossPuzzleCompleteResult> call({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    receivedTimes.add(timeSpentSeconds);
    return TaskEither<Failure, CrossPuzzleCompleteResult>.tryCatch(
      () async {
        await _gate.future;
        throw Exception('submission failed');
      },
      (error, stackTrace) => handleError(error),
    );
  }
}

/// Completes immediately so the test can follow the real navigation to the
/// result page, which is the state the user reported as still ticking.
class _SuccessfulCompletePuzzleUseCase extends CompletePuzzleUseCase {
  _SuccessfulCompletePuzzleUseCase() : super(const _StubRepository());

  final List<int> receivedTimes = [];

  @override
  TaskEither<Failure, CrossPuzzleCompleteResult> call({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) {
    receivedTimes.add(timeSpentSeconds);
    return TaskEither.right(
      CrossPuzzleCompleteResult(
        puzzleId: puzzleId,
        title: 'Timer puzzle',
        status: 'completed',
        totalCells: 1,
        correctCells: 1,
        accuracy: 100,
        pointsEarned: 10,
        newlyAwarded: false,
        completions: 1,
        bestTimeSpentSeconds: timeSpentSeconds,
        completedAt: DateTime(2026, 1, 1).toIso8601String(),
        level: const UserLevelInfo(
          totalPoints: 10,
          level: 1,
          currentLevelPoints: 10,
          nextLevelPoints: 100,
          pointsToNextLevel: 90,
        ),
      ),
    );
  }
}

/// A puzzle with no clues, so the board has zero active cells and
/// `_canSubmit` is immediately true without typing through the on-screen
/// keyboard.
CrossPuzzleDetail _detail({int storedSeconds = 0, String status = 'in_progress'}) {
  final created = DateTime(2026, 1, 1);
  return CrossPuzzleDetail(
    puzzle: CrossPuzzle(
      id: 'local_1',
      title: 'Timer puzzle',
      difficulty: 'easy',
      gridRows: 1,
      gridCols: 1,
      clues: const [],
      points: 10,
      status: 'published',
      revealAnswers: true,
      createdAt: created,
      updatedAt: created,
    ),
    progress: CrossPuzzleProgress(
      id: 'progress_1',
      puzzleId: 'local_1',
      status: status,
      gridState: const [],
      revealedCells: const [],
      mistakes: 0,
      hintsUsed: 0,
      timeSpentSeconds: storedSeconds,
      accuracy: 0,
      pointsEarned: 0,
      completions: 0,
      startedAt: created.toIso8601String(),
    ),
    revealAnswers: true,
  );
}

Widget _harness({
  required CrossPuzzleDetail detail,
  required _FakeCompletePuzzleUseCase complete,
}) {
  return ProviderScope(
    overrides: [
      getPuzzleDetailUseCaseProvider.overrideWithValue(
        _FakeDetailUseCase(detail),
      ),
      completePuzzleUseCaseProvider.overrideWithValue(complete),
      saveProgressUseCaseProvider.overrideWithValue(
        _FakeSaveProgressUseCase(),
      ),
    ],
    child: const MaterialApp(
      home: CrossPuzzlePlayPage(puzzleId: 'local_1', title: 'Timer puzzle'),
    ),
  );
}

int _timerSeconds(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        RegExp(r'^\d{1,2}:\d{2}(?::\d{2})?$').hasMatch(widget.data ?? ''),
  );
  expect(finder, findsOneWidget, reason: 'exactly one mm:ss label is rendered');
  final parts = tester
      .widget<Text>(finder)
      .data!
      .split(':')
      .map(int.parse)
      .toList();
  return parts.length == 3
      ? parts[0] * 3600 + parts[1] * 60 + parts[2]
      : parts[0] * 60 + parts[1];
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Submit puzzle'));
  await tester.pump();
}

/// Routes the play page and the result page through a real [GoRouter] so the
/// successful submission can be followed all the way to the result screen.
Widget _routedHarness({
  required CrossPuzzleDetail detail,
  required CompletePuzzleUseCase complete,
}) {
  final router = GoRouter(
    initialLocation: RouteNames.crossPuzzlePlay,
    routes: [
      GoRoute(
        path: RouteNames.crossPuzzlePlay,
        builder: (context, state) => const CrossPuzzlePlayPage(
          puzzleId: 'local_1',
          title: 'Timer puzzle',
        ),
      ),
      GoRoute(
        path: RouteNames.crossPuzzleResult,
        builder: (context, state) => CrossPuzzleResultPage(
          result: state.extra is CrossPuzzleCompleteResult
              ? state.extra as CrossPuzzleCompleteResult
              : null,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      getPuzzleDetailUseCaseProvider.overrideWithValue(
        _FakeDetailUseCase(detail),
      ),
      completePuzzleUseCaseProvider.overrideWithValue(complete),
      saveProgressUseCaseProvider.overrideWithValue(
        _FakeSaveProgressUseCase(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('CrosswordTimer', () {
    test('starts from the time restored with the saved progress', () {
      final timer = CrosswordTimer(initialSeconds: 125);

      expect(timer.seconds, 125);
      expect(timer.isFrozen, isFalse);
    });

    test('ticks one second at a time while running', () {
      final timer = CrosswordTimer();

      timer.tick();
      timer.tick();

      expect(timer.seconds, 2);
    });

    test('freeze stops the clock and returns the submission time', () {
      final timer = CrosswordTimer(initialSeconds: 40);
      timer.tick();

      expect(timer.freeze(), 41);
      expect(timer.isFrozen, isTrue);

      for (var i = 0; i < 30; i++) {
        timer.tick();
      }

      expect(timer.seconds, 41, reason: 'a frozen clock ignores ticks');
    });

    test('freeze is idempotent so every write reports the same final time', () {
      final timer = CrosswordTimer(initialSeconds: 12);
      timer.tick();

      expect(timer.freeze(), 13);
      expect(timer.freeze(), 13);
    });

    test('resume continues from the frozen time after a failed submission', () {
      final timer = CrosswordTimer(initialSeconds: 9);
      expect(timer.freeze(), 9);

      timer.tick();
      expect(timer.seconds, 9);

      timer.resume();
      expect(timer.isFrozen, isFalse);
      timer.tick();
      expect(timer.seconds, 10);
    });

    test('a negative restored time is clamped to zero', () {
      expect(CrosswordTimer(initialSeconds: -30).seconds, 0);
    });
  });

  group('CrossPuzzlePlayPage timer', () {
    testWidgets('a completed level replays from zero', (tester) async {
      final complete = _FakeCompletePuzzleUseCase();

      await tester.pumpWidget(
        _harness(
          detail: _detail(storedSeconds: 300, status: 'completed'),
          complete: complete,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _timerSeconds(tester),
        0,
        reason:
            'the finished run keeps its own frozen time; a replay starts fresh',
      );
    });

    testWidgets('an unfinished level resumes the saved time', (tester) async {
      final complete = _FakeCompletePuzzleUseCase();

      await tester.pumpWidget(
        _harness(detail: _detail(storedSeconds: 125), complete: complete),
      );
      await tester.pumpAndSettle();

      expect(_timerSeconds(tester), 125);
    });

    testWidgets('freezes the clock the moment the puzzle is submitted', (
      tester,
    ) async {
      final complete = _FakeCompletePuzzleUseCase();

      await tester.pumpWidget(
        _harness(detail: _detail(storedSeconds: 100), complete: complete),
      );
      await tester.pumpAndSettle();

      await _submit(tester);

      final frozenSeconds = _timerSeconds(tester);
      expect(
        complete.receivedTimeSpentSeconds,
        frozenSeconds,
        reason: 'the frozen time is what the completion request carries',
      );
      expect(
        find.byIcon(Icons.pause_circle_outline_rounded),
        findsOneWidget,
        reason: 'the header shows the clock is paused',
      );

      await tester.pump(const Duration(seconds: 5));

      expect(
        _timerSeconds(tester),
        frozenSeconds,
        reason: 'the timer must not keep counting after submission',
      );
      expect(complete.receivedTimeSpentSeconds, frozenSeconds);
      expect(complete.receivedTimes, hasLength(1));
    });

    testWidgets('a successful submission navigates away with a fixed final time', (
      tester,
    ) async {
      final complete = _SuccessfulCompletePuzzleUseCase();

      await tester.pumpWidget(
        _routedHarness(detail: _detail(storedSeconds: 75), complete: complete),
      );
      await tester.pumpAndSettle();

      final beforeSubmit = _timerSeconds(tester);
      await _submit(tester);
      await tester.pumpAndSettle();

      expect(
        find.byType(CrossPuzzlePlayPage),
        findsNothing,
        reason: 'the play page (and its clock) is replaced by the result page',
      );
      expect(complete.receivedTimes, hasLength(1));
      expect(
        complete.receivedTimes.single,
        greaterThanOrEqualTo(beforeSubmit),
        reason: 'the submitted time cannot be shorter than the visible clock',
      );

      final finalSeconds = complete.receivedTimes.single;
      final expected = '${(finalSeconds ~/ 60).toString().padLeft(2, '0')}:'
          '${(finalSeconds % 60).toString().padLeft(2, '0')}';
      expect(find.text('Best'), findsOneWidget);
      expect(
        find.text(expected),
        findsOneWidget,
        reason: 'the result page shows the frozen completion time',
      );

      // A ticker that survived the submission would leave a pending periodic
      // timer, which the test binding reports when the tree is torn down.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('a failed submission resumes the clock', (tester) async {
      final complete = _FakeCompletePuzzleUseCase();

      await tester.pumpWidget(
        _harness(detail: _detail(storedSeconds: 30), complete: complete),
      );
      await tester.pumpAndSettle();

      await _submit(tester);
      final frozenSeconds = _timerSeconds(tester);
      expect(frozenSeconds, complete.receivedTimeSpentSeconds);

      complete.failNow();
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));

      expect(
        _timerSeconds(tester),
        greaterThan(frozenSeconds),
        reason: 'an attempt that was not submitted must keep its clock running',
      );
      expect(find.byIcon(Icons.pause_circle_outline_rounded), findsNothing);

      // Let the failure snackbar's 4s auto-dismiss timer expire so the test
      // binding does not report a pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
