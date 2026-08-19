import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/services/storage_service.dart';
import 'package:glean_faith_app/features/crosspuzzle/data/datasources/crosspuzzle_local_datasource.dart';
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
}
