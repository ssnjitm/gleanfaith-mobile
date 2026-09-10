// crossword_board.dart
import '../../domain/entities/crosspuzzle_entities.dart';

class CrosswordCell {
  final int row;
  final int col;
  int? number;
  String value;
  String pencilValue;
  bool revealed;
  bool isActive;
  bool isSelected;
  bool inActiveClue;
  bool isWrong;
  bool justCorrected;

  CrosswordCell({
    required this.row,
    required this.col,
    this.value = '',
    this.pencilValue = '',
    this.revealed = false,
    this.isActive = false,
    this.isSelected = false,
    this.inActiveClue = false,
    this.isWrong = false,
    this.justCorrected = false,
  });

  String get key => '$row,$col';

  bool get isFilled => value.trim().isNotEmpty;

  CrosswordCell copy() {
    return CrosswordCell(
      row: row,
      col: col,
      value: value,
      pencilValue: pencilValue,
      revealed: revealed,
      isActive: isActive,
      isSelected: isSelected,
      inActiveClue: inActiveClue,
      isWrong: isWrong,
      justCorrected: justCorrected,
    )..number = number;
  }
}

class CrosswordBoard {
  final CrossPuzzle puzzle;
  final List<List<CrosswordCell>> grid;
  final int rows;
  final int cols;
  final Map<int, List<CrosswordCell>> acrossCells;
  final Map<int, List<CrosswordCell>> downCells;
  final List<CrossClue> acrossClues;
  final List<CrossClue> downClues;
  late final int totalActiveCells;

  bool _isAcross = true;
  int? _activeClueNumber;
  String? _activeDirection;
  int? _selectedRow;
  int? _selectedCol;
  bool _pencilMode = false;
  final String sessionId;

  CrosswordBoard._({
    required this.puzzle,
    required this.grid,
    required this.acrossCells,
    required this.downCells,
    required this.acrossClues,
    required this.downClues,
    required this.rows,
    required this.cols,
    required this.sessionId,
  }) {
    totalActiveCells = grid.fold<int>(0, (sum, row) {
      return sum + row.where((c) => c.isActive).length;
    });
  }

  factory CrosswordBoard.fromPuzzle(CrossPuzzle puzzle, {String? sessionId}) {
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

    final board = CrosswordBoard._(
      puzzle: puzzle,
      grid: grid,
      acrossCells: acrossCells,
      downCells: downCells,
      acrossClues: acrossClues,
      downClues: downClues,
      rows: rows,
      cols: cols,
      sessionId: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    if (puzzle.clues.isNotEmpty) {
      board._selectClue(
        acrossClues.isNotEmpty ? acrossClues.first : downClues.first,
      );
    }
    return board;
  }

  CrosswordBoard copy() {
    final newGrid = grid
        .map((row) => row.map((cell) => cell.copy()).toList())
        .toList();

    final newAcrossCells = <int, List<CrosswordCell>>{};
    final newDownCells = <int, List<CrosswordCell>>{};

    for (final entry in acrossCells.entries) {
      newAcrossCells[entry.key] = entry.value
          .map((c) => newGrid[c.row][c.col])
          .toList();
    }
    for (final entry in downCells.entries) {
      newDownCells[entry.key] = entry.value
          .map((c) => newGrid[c.row][c.col])
          .toList();
    }

    final board = CrosswordBoard._(
      puzzle: puzzle,
      grid: newGrid,
      acrossCells: newAcrossCells,
      downCells: newDownCells,
      acrossClues: acrossClues,
      downClues: downClues,
      rows: rows,
      cols: cols,
      sessionId: sessionId,
    );

    board._isAcross = _isAcross;
    board._activeClueNumber = _activeClueNumber;
    board._activeDirection = _activeDirection;
    board._selectedRow = _selectedRow;
    board._selectedCol = _selectedCol;
    board._pencilMode = _pencilMode;

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
      for (
        var c = clue.col;
        c < cols && c < clue.col + clue.answerLength;
        c++
      ) {
        cells.add(grid[clue.row][c]);
      }
    } else {
      for (
        var r = clue.row;
        r < rows && r < clue.row + clue.answerLength;
        r++
      ) {
        cells.add(grid[r][clue.col]);
      }
    }
    return cells;
  }

  bool get isAcross => _isAcross;
  String? get activeDirection => _activeDirection;
  int? get activeClueNumber => _activeClueNumber;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get pencilMode => _pencilMode;
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

  Map<String, String> get answerCells {
    final map = <String, String>{};
    for (final clue in [...acrossClues, ...downClues]) {
      final answer = clue.answer;
      if (answer == null || answer.isEmpty) continue;
      final cells = clue.direction == 'across'
          ? acrossCells[clue.number]
          : downCells[clue.number];
      if (cells == null) continue;
      for (var i = 0; i < cells.length && i < answer.length; i++) {
        map[cells[i].key] = answer[i].toUpperCase();
      }
    }
    return map;
  }

  bool get hasAnswers {
    if (totalActiveCells == 0) return false;
    return answerCells.length >= totalActiveCells;
  }

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

  bool _inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  void selectCell(int row, int col, {String? preferDirection}) {
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

    final dir = preferDirection ?? _activeDirection ?? 'across';
    final clue = _clueAtCell(row, col, preferredDirection: dir);
    if (clue != null) {
      _selectClue(clue);
    } else {
      _markInActiveClue();
    }
  }

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
    if (_selectedRow == null || _selectedCol == null || letter.isEmpty) {
      return false;
    }
    final cell = grid[_selectedRow!][_selectedCol!];
    if (!cell.isActive) return false;

    final upper = letter.toUpperCase();
    if (!RegExp(r'^[A-Z0-9]$').hasMatch(upper)) return false;

    if (_pencilMode) {
      if (cell.pencilValue == upper) {
        cell.pencilValue = '';
      } else {
        cell.pencilValue = upper;
      }
      return true;
    }

    cell.value = upper;
    cell.isWrong = _isWrongLetter(cell);
    _markInActiveClue();
    _advanceCursor();
    return true;
  }

  void setPencilMode(bool enabled) {
    _pencilMode = enabled;
    if (enabled) {
      for (final row in grid) {
        for (final cell in row) {
          cell.isWrong = false;
        }
      }
    }
  }

  bool _isWrongLetter(CrosswordCell cell) {
    if (!hasAnswers) return false;
    final expected = answerCells[cell.key];
    return expected != null && expected != cell.value;
  }

  void _advanceCursor() {
    final cells = currentClueCells;
    if (cells == null || cells.isEmpty) return;

    final idx = _selectedIndexIn(cells);
    if (idx >= 0 && idx < cells.length - 1) {
      final next = cells[idx + 1];
      selectCell(next.row, next.col);
      return;
    }
    _jumpToNextIncompleteClue();
  }

  int _selectedIndexIn(List<CrosswordCell> cells) {
    if (_selectedRow == null || _selectedCol == null) return -1;
    return cells.indexWhere(
      (c) => c.row == _selectedRow && c.col == _selectedCol,
    );
  }

  void _jumpToNextIncompleteClue() {
    final dir = _activeDirection ?? 'across';
    final sameDir = dir == 'across' ? acrossClues : downClues;
    final otherDir = dir == 'across' ? downClues : acrossClues;
    final map = dir == 'across' ? acrossCells : downCells;
    final otherMap = dir == 'across' ? downCells : acrossCells;

    final currentIndex = sameDir.indexWhere(
      (c) => c.number == _activeClueNumber,
    );

    CrossClue? target;
    for (var i = 1; i <= sameDir.length; i++) {
      final clue = sameDir[(currentIndex + i) % sameDir.length];
      if (!_clueFilled(map[clue.number])) {
        target = clue;
        break;
      }
    }
    target ??= otherDir.firstWhere(
      (c) => !_clueFilled(otherMap[c.number]),
      orElse: () => otherDir.isEmpty ? sameDir.first : otherDir.first,
    );

    _selectClue(target);
    final cells = (target.direction == 'across'
        ? acrossCells
        : downCells)[target.number];
    if (cells != null && cells.isNotEmpty) {
      final firstEmpty = cells.indexWhere((c) => c.value.trim().isEmpty);
      final cell = firstEmpty >= 0 ? cells[firstEmpty] : cells.first;
      selectCell(cell.row, cell.col);
    }
  }

  bool _clueFilled(List<CrosswordCell>? cells) {
    if (cells == null || cells.isEmpty) return true;
    return cells.every((c) => c.value.trim().isNotEmpty);
  }

  void handleBackspace() {
    if (_selectedRow == null || _selectedCol == null) return;
    final cell = grid[_selectedRow!][_selectedCol!];
    if (!cell.isActive) return;

    if (_pencilMode && cell.pencilValue.isNotEmpty) {
      cell.pencilValue = '';
      return;
    }

    if (cell.value.trim().isNotEmpty) {
      cell.value = '';
      cell.isWrong = false;
      _markInActiveClue();
      return;
    }

    final cells = currentClueCells;
    if (cells == null) return;
    final idx = _selectedIndexIn(cells);
    if (idx > 0) {
      final prev = cells[idx - 1];
      selectCell(prev.row, prev.col);
      prev.value = '';
      prev.pencilValue = '';
      prev.isWrong = false;
      _markInActiveClue();
    }
  }

  void clearCell() {
    if (_selectedRow == null || _selectedCol == null) return;
    final cell = grid[_selectedRow!][_selectedCol!];
    if (!cell.isActive) return;
    cell.value = '';
    cell.isWrong = false;
    _markInActiveClue();
  }

  void clearCurrentClue() {
    final cells = currentClueCells;
    if (cells == null || cells.isEmpty) return;
    for (final cell in cells) {
      cell.value = '';
      cell.pencilValue = '';
      cell.isWrong = false;
    }
    selectCell(cells.first.row, cells.first.col);
  }

  void clearAll() {
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isActive) continue;
        cell.value = '';
        cell.pencilValue = '';
        cell.isWrong = false;
      }
    }
    _selectFirstActiveCell();
  }

  void _selectFirstActiveCell() {
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isActive) {
          selectCell(cell.row, cell.col);
          return;
        }
      }
    }
  }

  void toggleDirection() {
    if (_selectedRow == null || _selectedCol == null) {
      return;
    }
    final currentDir = _activeDirection ?? 'across';
    final newDir = currentDir == 'across' ? 'down' : 'across';
    CrossClue? candidate;
    for (final clue in (newDir == 'across' ? acrossClues : downClues)) {
      if (_covers(clue, _selectedRow!, _selectedCol!)) {
        candidate = clue;
        break;
      }
    }
    if (candidate != null) {
      _selectClue(candidate);
      _markInActiveClue();
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

  CrossClue? _clueAtCell(int row, int col, {String? preferredDirection}) {
    final dir = preferredDirection ?? 'across';
    final primary = dir == 'down' ? downClues : acrossClues;
    final secondary = dir == 'down' ? acrossClues : downClues;
    for (final clue in primary) {
      if (_covers(clue, row, col)) return clue;
    }
    for (final clue in secondary) {
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
        cell.pencilValue = '';
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

  bool get activeClueFilledCorrectly {
    final cells = currentClueCells;
    if (cells == null || cells.isEmpty) return false;
    if (!cells.every((c) => c.value.trim().isNotEmpty)) return false;
    final answers = answerCells;
    return cells.every((c) => answers[c.key] == c.value);
  }

  bool get currentClueFilled {
    final cells = currentClueCells;
    if (cells == null || cells.isEmpty) return false;
    return cells.every((c) => c.value.trim().isNotEmpty);
  }

  List<CrosswordCell>? clueCells(int number, String direction) {
    final map = direction == 'across' ? acrossCells : downCells;
    return map[number];
  }

  bool isClueFilled(int number, String direction) {
    final cells = clueCells(number, direction);
    if (cells == null || cells.isEmpty) return false;
    return cells.every((c) => c.value.trim().isNotEmpty);
  }

  bool isClueFilledCorrectly(int number, String direction) {
    final cells = clueCells(number, direction);
    if (cells == null || cells.isEmpty) return false;
    final answers = answerCells;
    if (!cells.every((c) => answers[c.key] != null)) return false;
    return cells.every(
      (c) => c.value.trim().isNotEmpty && answers[c.key] == c.value,
    );
  }
}

int mathMax(int a, int b) => a > b ? a : b;
