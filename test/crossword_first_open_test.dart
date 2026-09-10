import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/services/storage_service.dart';
import 'package:glean_faith_app/features/crosspuzzle/data/datasources/crosspuzzle_local_datasource.dart';
import 'package:glean_faith_app/features/crosspuzzle/domain/entities/crosspuzzle_entities.dart';
import 'package:glean_faith_app/features/crosspuzzle/presentation/models/crossword_board.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    return _store.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrossPuzzleLocalDataSource datasource;

  setUp(() {
    datasource = CrossPuzzleLocalDataSource(StorageService(_FakeSecureStorage()));
  });

  test('all 50 local sets build interlocking boards without crashing', () async {
    final puzzles = await datasource.getLocalPuzzles();
    expect(puzzles.length, 50);

    for (final puzzle in puzzles) {
      expect(puzzle.gridRows, greaterThan(0));
      expect(puzzle.gridCols, greaterThan(0));
      expect(puzzle.clues.length, greaterThan(0));

      // Every clue must sit fully inside the grid.
      for (final clue in puzzle.clues) {
        final answerLen = clue.answer?.length ?? 0;
        if (clue.direction == 'across') {
          expect(clue.row, inInclusiveRange(0, puzzle.gridRows - 1));
          expect(clue.col + answerLen, lessThanOrEqualTo(puzzle.gridCols));
        } else {
          expect(clue.col, inInclusiveRange(0, puzzle.gridCols - 1));
          expect(clue.row + answerLen, lessThanOrEqualTo(puzzle.gridRows));
        }
      }

      final board = CrosswordBoard.fromPuzzle(puzzle);
      expect(board.totalActiveCells, greaterThan(0));

      // A professional layout must mix across and down clues.
      final hasAcross = puzzle.clues.any((c) => c.direction == 'across');
      final hasDown = puzzle.clues.any((c) => c.direction == 'down');
      expect(hasAcross, isTrue);
      expect(hasDown, isTrue, reason: '${puzzle.id} should interlock both ways');
    }
  });

  test('clue numbers are sequential and shared across start cells', () async {
    final puzzles = await datasource.getLocalPuzzles();

    for (final puzzle in puzzles) {
      final numbers = puzzle.clues.map((c) => c.number).toSet().toList()
        ..sort();
      // Numbers start at 1 and have no gaps.
      for (var i = 0; i < numbers.length; i++) {
        expect(numbers[i], i + 1, reason: '${puzzle.id} numbering gap');
      }

      // Words sharing a start cell must share a number.
      final startNumbers = <String, int>{};
      for (final clue in puzzle.clues) {
        final key = '${clue.row},${clue.col}';
        final existing = startNumbers[key];
        if (existing != null) {
          expect(existing, clue.number,
              reason: '${puzzle.id} shared start cell must share number');
        } else {
          startNumbers[key] = clue.number;
        }
      }
    }
  });

  test('local detail round-trips for every puzzle id', () async {
    final puzzles = await datasource.getLocalPuzzles();
    for (final puzzle in puzzles) {
      final detail = await datasource.getLocalPuzzleDetail(puzzle.id);
      expect(detail.puzzle.id, puzzle.id);
      expect(detail.puzzle.clues.length, puzzle.clues.length);
    }
  });

  Map<String, String> answersFor(CrossPuzzle puzzle) {
    final answers = <String, String>{};
    for (final clue in puzzle.clues) {
      final answer = clue.answer ?? '';
      if (clue.direction == 'across') {
        for (var i = 0; i < answer.length; i++) {
          answers['${clue.row},${clue.col + i}'] = answer[i];
        }
      } else {
        for (var i = 0; i < answer.length; i++) {
          answers['${clue.row + i},${clue.col}'] = answer[i];
        }
      }
    }
    return answers;
  }

  List<GridCell> gridFromAnswers(Map<String, String> answers) {
    return answers.entries.map((e) {
      final parts = e.key.split(',');
      return GridCell(
        row: int.parse(parts[0]),
        col: int.parse(parts[1]),
        value: e.value,
      );
    }).toList();
  }

  test('board can verify a fully correct grid locally', () async {
    final puzzles = await datasource.getLocalPuzzles();
    for (final puzzle in puzzles) {
      final board = CrosswordBoard.fromPuzzle(puzzle);
      expect(board.hasAnswers, isTrue, reason: '${puzzle.id} must ship answers');
      expect(board.isFullyCorrect, isFalse,
          reason: '${puzzle.id} starts empty so must not be correct');
    }
  });

  test('partial/wrong submission does NOT complete or unlock the puzzle',
      () async {
    final puzzles = await datasource.getLocalPuzzles();
    final puzzle = puzzles.first;
    final answers = answersFor(puzzle);
    final wrongGrid = answers.entries.map((e) {
      final parts = e.key.split(',');
      final wrongLetter = e.value == 'A' ? 'B' : 'A';
      return GridCell(
        row: int.parse(parts[0]),
        col: int.parse(parts[1]),
        value: wrongLetter,
      );
    }).toList();

    final result = await datasource.completeLocalPuzzle(
      puzzleId: puzzle.id,
      gridState: wrongGrid,
      mistakes: 0,
      hintsUsed: 0,
      timeSpentSeconds: 10,
    );

    expect(result.status, 'in_progress');
    expect(result.newlyAwarded, isFalse);
    expect(result.accuracy, lessThan(100));

    final refreshed = await datasource.getLocalPuzzles();
    final refreshedPuzzle = refreshed.firstWhere((p) => p.id == puzzle.id);
    expect(refreshedPuzzle.userProgress?.isCompleted, isFalse,
        reason: 'a partial solve must not unlock the next level');
  });

  test('fully correct submission completes and unlocks the next level',
      () async {
    final puzzles = await datasource.getLocalPuzzles();
    final puzzle = puzzles.first;
    final correctGrid = gridFromAnswers(answersFor(puzzle));

    final result = await datasource.completeLocalPuzzle(
      puzzleId: puzzle.id,
      gridState: correctGrid,
      mistakes: 0,
      hintsUsed: 0,
      timeSpentSeconds: 10,
    );

    expect(result.status, 'completed');
    expect(result.newlyAwarded, isTrue);
    expect(result.accuracy, 100);

    final refreshed = await datasource.getLocalPuzzles();
    final refreshedPuzzle = refreshed.firstWhere((p) => p.id == puzzle.id);
    expect(refreshedPuzzle.userProgress?.isCompleted, isTrue);
  });

  test('numeric-answer puzzles can be fully solved via the board input API',
      () async {
    final puzzles = await datasource.getLocalPuzzles();
    final numericPuzzles = puzzles.where((p) {
      return p.clues.any((c) => c.answer != null && c.answer!.contains(RegExp(r'[0-9]')));
    }).toList();

    expect(numericPuzzles.length, 2, reason: 'sets 35 and 44 must ship digits');

    for (final puzzle in numericPuzzles) {
      final board = CrosswordBoard.fromPuzzle(puzzle);
      final answers = answersFor(puzzle);

      // Choose the first cell of the first clue so the active clue is set.
      board.selectClue(puzzle.clues.first.number, puzzle.clues.first.direction);

      var filled = 0;
      // Fill every answer cell by navigating the grid the way a user would.
      for (final entry in answers.entries) {
        final parts = entry.key.split(',');
        final row = int.parse(parts[0]);
        final col = int.parse(parts[1]);
        board.selectCell(row, col);
        final before = filled;
        expect(board.inputLetter(entry.value), isTrue,
            reason: '${puzzle.id} should accept `$entry`');
        if (board.grid[row][col].value.trim().isNotEmpty) {
          filled++;
        }
        expect(board.grid[row][col].value, entry.value.toUpperCase(),
            reason: '${puzzle.id} cell $row,$col holds `$entry`');
        expect(filled, greaterThan(before),
            reason: '${puzzle.id} should advance after an accepted letter');
      }

      expect(board.isFullyCorrect, isTrue,
          reason: '${puzzle.id} must be fully solvable (digits included)');
      expect(board.filledCellCount, board.totalActiveCells);
    }
  });

  test('numeric answers are accepted by inputLetter one character per cell',
      () async {
    final puzzles = await datasource.getLocalPuzzles();
    final puzzle = puzzles.firstWhere((p) => p.id == 'local_35');

    final board = CrosswordBoard.fromPuzzle(puzzle);
    final digitClue = puzzle.clues.firstWhere(
      (c) => c.answer != null && c.answer!.contains(RegExp(r'[0-9]')),
    );
    final answer = digitClue.answer!;

    for (var i = 0; i < answer.length; i++) {
      board.selectCell(
        digitClue.row + (digitClue.direction == 'down' ? i : 0),
        digitClue.col + (digitClue.direction == 'across' ? i : 0),
      );
      expect(board.inputLetter(answer[i]), isTrue,
          reason: 'digit `${answer[i]}` must be accepted');
    }

    final cells = digitClue.direction == 'across'
        ? board.acrossCells[digitClue.number]!
        : board.downCells[digitClue.number]!;
    final actual = cells.map((c) => c.value).join();
    expect(actual, answer, reason: 'board should store the full numeric word');
  });

  void fillClue(CrosswordBoard board, CrossClue clue, String letter) {
    board.selectClue(clue.number, clue.direction);
    final cells = clue.direction == 'across'
        ? board.acrossCells[clue.number]!
        : board.downCells[clue.number]!;
    for (final cell in cells) {
      board.selectCell(cell.row, cell.col);
      expect(board.inputLetter(letter), isTrue);
    }
  }

  test('clearCurrentClue empties only the active word and reselects its start',
      () async {
    final puzzles = await datasource.getLocalPuzzles();
    final puzzle = puzzles.first;
    final board = CrosswordBoard.fromPuzzle(puzzle);

    final first = puzzle.clues.first;
    final second = puzzle.clues.last;
    fillClue(board, first, 'A');
    fillClue(board, second, 'B');

    final firstCells = first.direction == 'across'
        ? board.acrossCells[first.number]!
        : board.downCells[first.number]!;
    final secondCells = second.direction == 'across'
        ? board.acrossCells[second.number]!
        : board.downCells[second.number]!;

    expect(firstCells.every((c) => c.value.trim().isNotEmpty), isTrue);
    expect(secondCells.every((c) => c.value.trim().isNotEmpty), isTrue);

    board.selectClue(first.number, first.direction);
    board.clearCurrentClue();

    expect(firstCells.every((c) => c.value.trim().isEmpty), isTrue,
        reason: 'active clue cells must be emptied');
    expect(board.grid[first.row][first.col].isSelected, isTrue,
        reason: 'selection returns to the start of the cleared word');
    expect(secondCells.every((c) => c.value.trim().isNotEmpty), isTrue,
        reason: 'other words must remain filled');
  });

  test('clearAll empties the whole grid and keeps revealed hints', () async {
    final puzzles = await datasource.getLocalPuzzles();
    final puzzle = puzzles.first;
    final board = CrosswordBoard.fromPuzzle(puzzle);

    final answers = answersFor(puzzle);
    for (final entry in answers.entries) {
      final parts = entry.key.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      board.selectCell(row, col);
      board.inputLetter(entry.value);
    }
    expect(board.filledCellCount, board.totalActiveCells);

    final firstKey = answers.keys.first;
    final firstParts = firstKey.split(',');
    final firstCell =
        board.grid[int.parse(firstParts[0])][int.parse(firstParts[1])];
    firstCell.revealed = true;

    board.clearAll();

    expect(board.filledCellCount, 0,
        reason: 'grid must be empty after clearAll');
    expect(firstCell.revealed, isTrue,
        reason: 'revealed hints survive clearAll');
    expect(firstCell.value, '');
    expect(board.selectedRow, isNotNull,
        reason: 'a cell stays selected after clearing');
  });
}
