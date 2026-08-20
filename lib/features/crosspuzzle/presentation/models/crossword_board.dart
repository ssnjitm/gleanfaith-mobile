import '../../domain/entities/crosspuzzle_entities.dart';

/// A single cell in the crossword grid.
class CrosswordCell {
  final int row;
  final int col;

  /// Clue number to display in the top-left corner (if this starts a clue).
  int? number;

  /// The letter the user has placed.
  String value;

  /// Whether this cell was revealed by a hint.
  bool revealed;

  /// Whether this cell is active (covered by at least one clue).
  bool isActive;

  /// True when this cell is currently selected.
  bool isSelected;

  /// True when this cell is part of the actively selected clue.
  bool inActiveClue;

  /// True when this cell has a wrong letter (marked on check).
  bool isWrong;

  CrosswordCell({
    required this.row,
    required this.col,
    this.value = '',
    this.revealed = false,
    this.isActive = false,
    this.isSelected = false,
    this.inActiveClue = false,
    this.isWrong = false,
  });

  String get key => '$row,$col';
}

/// Builds and manages the crossword board from puzzle clues.
class CrosswordBoard {
  final CrossPuzzle puzzle;
  final List<List<CrosswordCell>> grid;
  final int rows;
  final int cols;

  /// clue number -> list of cells (in order) for across clues.
  final Map<int, List<CrosswordCell>> acrossCells;

  /// clue number -> list of cells (in order) for down clues.
  final Map<int, List<CrosswordCell>> downCells;

  final List<CrossClue> acrossClues;
  final List<CrossClue> downClues;

  /// Total number of solvable (active) cells.
  late final int totalActiveCells;

  bool _isAcross = true;
  int? _activeClueNumber;
  String? _activeDirection;
  int? _selectedRow;
  int? _selectedCol;

  CrosswordBoard(
    this.puzzle,
    this.grid,
    this.acrossCells,
    this.downCells,
    this.acrossClues,
    this.downClues,
  )   : rows = puzzle.gridRows,
        cols = puzzle.gridCols {
    totalActiveCells = grid.fold<int>(0, (sum, row) {
      return sum + row.where((c) => c.isActive).length;
    });
  }

  factory CrosswordBoard.fromPuzzle(CrossPuzzle puzzle) {
    final rows = puzzle.gridRows;
    final cols = puzzle.gridCols;

    final grid = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => CrosswordCell(row: r, col: c),
        growable: false,
      ),
      growable: false,
    );

    for (final clue in puzzle.clues) {
      for (final cell in _clueCellsRefs(clue, grid, rows, cols)) {
        cell.isActive = true;
      }
    }

    final acrossCells = <int, List<CrosswordCell>>{};
    final downCells = <int, List<CrosswordCell>>{};
    final acrossClues = <CrossClue>[];
    final downClues = <CrossClue>[];

    for (final clue in puzzle.clues) {
      final cells = _clueCellsRefs(clue, grid, rows, cols);
      grid[clue.row][clue.col].number = clue.number;
      if (clue.direction == 'across') {
        acrossClues.add(clue);
        acrossCells[clue.number] = cells;
      } else {
        downClues.add(clue);
        downCells[clue.number] = cells;
      }
    }

    acrossClues.sort((a, b) => a.number.compareTo(b.number));
    downClues.sort((a, b) => a.number.compareTo(b.number));

    final board = CrosswordBoard(
      puzzle,
      grid,
      acrossCells,
      downCells,
      acrossClues,
      downClues,
    );
    if (puzzle.clues.isNotEmpty) {
      board._selectClue(
        acrossClues.isNotEmpty ? acrossClues.first : downClues.first,
      );
    }
    return board;
  }

  static List<CrosswordCell> _clueCellsRefs(
    CrossClue clue,
    List<List<CrosswordCell>> grid,
    int rows,
    int cols,
  ) {
    final cells = <CrosswordCell>[];
    if (clue.direction == 'across') {
      for (var c = clue.col; c < cols && c < clue.col + clue.answerLength; c++) {
        cells.add(grid[clue.row][c]);
      }
    } else {
      for (var r = clue.row; r < rows && r < clue.row + clue.answerLength; r++) {
        cells.add(grid[r][clue.col]);
      }
    }
    return cells;
  }

  // --- State reads -------------------------------------------------------

  bool get isAcross => _isAcross;

  String? get activeDirection => _activeDirection;

  int? get activeClueNumber => _activeClueNumber;

  int? get selectedRow => _selectedRow;

  int? get selectedCol => _selectedCol;

  List<CrosswordCell>? get activeCells => currentClueCells;

  List<CrosswordCell>? get currentClueCells {
    if (_activeClueNumber == null || _activeDirection == null) return null;
    final map = _activeDirection == 'across' ? acrossCells : downCells;
    return map[_activeClueNumber!];
  }

  CrossClue? get activeClue {
    if (_activeClueNumber == null || _activeDirection == null) return null;
    final list = _activeDirection == 'across' ? acrossClues : downClues;
    for (final clue in list) {
      if (clue.number == _activeClueNumber) return clue;
    }
    return null;
  }

  int get filledCellCount {
    var count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isActive && cell.value.trim().isNotEmpty) count++;
      }
    }
    return count;
  }

  int get emptyCellCount => totalActiveCells - filledCellCount;

  // --- Answer verification ----------------------------------------------

  /// Expected letter for every active cell, derived from the clue answers.
  /// Only populated when the puzzle ships answers (local datasets always do).
  Map<String, String> get answerCells {
    final map = <String, String>{};
    for (final clue in [...acrossClues, ...downClues]) {
      final answer = clue.answer;
      if (answer == null || answer.isEmpty) continue;
      final cells =
          clue.direction == 'across' ? acrossCells[clue.number] : downCells[clue.number];
      if (cells == null) continue;
      for (var i = 0; i < cells.length && i < answer.length; i++) {
        map[cells[i].key] = answer[i].toUpperCase();
      }
    }
    return map;
  }

  /// True when every active cell has a known expected letter, so the board
  /// can be graded locally. Remote puzzles hide answers until completed.
  bool get hasAnswers {
    if (totalActiveCells == 0) return false;
    return answerCells.length >= totalActiveCells;
  }

  /// True when every active cell holds the correct letter (all empty or wrong
  /// cells fail this). Only meaningful when [hasAnswers] is true.
  bool get isFullyCorrect {
    final answers = answerCells;
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isActive) continue;
        final expected = answers[cell.key];
        if (expected == null) continue;
        if (cell.value.trim().isEmpty || cell.value != expected) return false;
      }
    }
    return true;
  }

  /// Number of filled cells whose letter does not match the expected answer.
  int get wrongCellCount {
    final answers = answerCells;
    var count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isActive) continue;
        final expected = answers[cell.key];
        if (expected == null) continue;
        if (cell.value.trim().isNotEmpty && cell.value != expected) count++;
      }
    }
    return count;
  }

  /// Marks every filled-and-incorrect cell as wrong so the UI can highlight
  /// them. Correct/empty cells are cleared. No-op when answers are unknown.
  void markIncorrectCells() {
    final answers = answerCells;
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isActive) continue;
        final expected = answers[cell.key];
        if (expected == null) {
          cell.isWrong = false;
          continue;
        }
        cell.isWrong = cell.value.trim().isNotEmpty && cell.value != expected;
      }
    }
  }

  /// All filled cells in [row, col, value] form.
  List<GridCell> toGridState() {
    final result = <GridCell>[];
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isActive && cell.value.trim().isNotEmpty) {
          result.add(GridCell(row: cell.row, col: cell.col, value: cell.value));
        }
      }
    }
    return result;
  }

  List<RevealedCell> toRevealedCells() {
    final result = <RevealedCell>[];
    for (final row in grid) {
      for (final cell in row) {
        if (cell.revealed) {
          result.add(RevealedCell(row: cell.row, col: cell.col));
        }
      }
    }
    return result;
  }

  void restore(List<GridCell>? gridState, List<RevealedCell>? revealedCells) {
    gridState ??= const [];
    revealedCells ??= const [];
    for (final g in gridState) {
      if (_inBounds(g.row, g.col)) {
        grid[g.row][g.col].value = g.value;
      }
    }
    for (final r in revealedCells) {
      if (_inBounds(r.row, r.col)) {
        grid[r.row][r.col].revealed = true;
      }
    }
  }

  bool _inBounds(int row, int col) => row >= 0 && row < rows && col >= 0 && col < cols;

  // --- Input -------------------------------------------------------------

  void selectCell(int row, int col) {
    if (!_inBounds(row, col)) return;
    final cell = grid[row][col];
    if (!cell.isActive) return;

    for (final r in grid) {
      for (final c in r) {
        c.isSelected = false;
        c.inActiveClue = false;
      }
    }
    cell.isSelected = true;
    _selectedRow = row;
    _selectedCol = col;

    // Try to keep a matching clue active if it covers this cell.
    final clue = _clueAtCell(row, col);
    if (clue != null) {
      _selectClue(clue);
    } else {
      _markInActiveClue();
    }
  }

  /// Move selection: [dx, dy] where across moves in row (+1 col), down in col.
  bool moveBy(int dy, int dx) {
    if (_selectedRow == null || _selectedCol == null) return false;
    final dir = _activeDirection ?? 'across';

    for (var step = 1; step < mathMax(rows, cols); step++) {
      final nextRow = _selectedRow! + (dir == 'down' ? dy * step : 0);
      final nextCol = _selectedCol! + (dir == 'across' ? dx * step : 0);
      if (!_inBounds(nextRow, nextCol)) break;
      if (grid[nextRow][nextCol].isActive) {
        selectCell(nextRow, nextCol);
        return true;
      }
    }
    return false;
  }

  void moveToNext() => moveBy(0, 1);

  void moveToPrev() => moveBy(0, -1);

  void moveDown() => moveBy(1, 0);

  void moveUp() => moveBy(-1, 0);

  bool inputLetter(String letter) {
    if (_selectedRow == null || _selectedCol == null || letter.isEmpty) return false;
    final cell = grid[_selectedRow!][_selectedCol!];
    if (!cell.isActive) return false;

    final upper = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(upper)) return false;

    cell.value = upper;
    cell.isWrong = false;
    _markInActiveClue();
    moveToNext();
    return true;
  }

  void clearCell() {
    if (_selectedRow == null || _selectedCol == null) return;
    final cell = grid[_selectedRow!][_selectedCol!];
    if (!cell.isActive) return;
    cell.value = '';
    cell.isWrong = false;
    _markInActiveClue();
  }

  void toggleDirection() {
    if (_selectedRow == null || _selectedCol == null || _activeDirection == null) {
      return;
    }
    final newDir = _activeDirection == 'across' ? 'down' : 'across';
    // Find a clue of the new direction covering the selected cell.
    CrossClue? candidate;
    for (final clue in (newDir == 'across' ? acrossClues : downClues)) {
      if (_covers(clue, _selectedRow!, _selectedCol!)) {
        candidate = clue;
        break;
      }
    }
    if (candidate != null) {
      _selectClue(candidate);
    } else {
      _isAcross = newDir == 'across';
      _activeDirection = newDir;
      _markInActiveClue();
    }
  }

  void selectClue(int number, String direction) {
    final clue = _clueByNumber(number, direction);
    if (clue == null) return;
    _selectClue(clue);
    selectCell(clue.row, clue.col);
  }

  void selectClueCell(int number, String direction, CrosswordCell cell) {
    final clue = _clueByNumber(number, direction);
    if (clue == null) return;
    _selectClue(clue);
    selectCell(cell.row, cell.col);
  }

  void _selectClue(CrossClue clue) {
    _isAcross = clue.direction == 'across';
    _activeDirection = clue.direction;
    _activeClueNumber = clue.number;
  }

  CrossClue? _clueByNumber(int number, String direction) {
    final list = direction == 'across' ? acrossClues : downClues;
    for (final clue in list) {
      if (clue.number == number) return clue;
    }
    return null;
  }

  CrossClue? _clueAtCell(int row, int col) {
    for (final clue in acrossClues) {
      if (_covers(clue, row, col)) return clue;
    }
    for (final clue in downClues) {
      if (_covers(clue, row, col)) return clue;
    }
    return null;
  }

  bool _covers(CrossClue clue, int row, int col) {
    if (clue.direction == 'across') {
      return clue.row == row &&
          col >= clue.col &&
          col < clue.col + clue.answerLength;
    }
    return clue.col == col &&
        row >= clue.row &&
        row < clue.row + clue.answerLength;
  }

  void _markInActiveClue() {
    for (final r in grid) {
      for (final c in r) {
        c.inActiveClue = false;
      }
    }
    final cells = currentClueCells;
    if (cells == null) return;
    for (final cell in cells) {
      grid[cell.row][cell.col].inActiveClue = true;
    }
  }

  /// Reveal the first empty/reported-wrong cell of the active clue.
  /// Fills the correct letter when the clue's answer is available
  /// (i.e. `revealAnswers` is true); otherwise it only marks the cell
  /// as revealed — the server grades the final grid anyway.
  /// Returns the revealed cell, or null if the whole clue is already filled.
  CrosswordCell? revealNextHint() {
    final clue = activeClue;
    final cells = currentClueCells;
    if (cells == null) return null;
    final answer = clue?.answer;
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      if (cell.value.trim().isEmpty || cell.isWrong) {
        cell.revealed = true;
        cell.isWrong = false;
        if (answer != null && i < answer.length) {
          cell.value = answer[i].toUpperCase();
        }
        selectCell(cell.row, cell.col);
        return cell;
      }
    }
    return null;
  }

  int get currentHintsNeeded {
    final cells = currentClueCells;
    if (cells == null) return 0;
    return cells.where((c) => c.value.trim().isEmpty || c.isWrong).length;
  }
}

int mathMax(int a, int b) => a > b ? a : b;