class CrossClue {
  final int number; // grid number shown in the cell (1-based)
  final String clue;
  final String? answer; // never sent to a user who has not completed the puzzle
  final String direction; // "across" | "down"
  final int row; // 0-based start cell
  final int col; // 0-based start cell

  const CrossClue({
    required this.number,
    required this.clue,
    this.answer,
    required this.direction,
    required this.row,
    required this.col,
  });

  int get answerLength => answer?.length ?? 0;
}

class GridCell {
  final int row;
  final int col;
  final String value;

  const GridCell({required this.row, required this.col, required this.value});
}

class RevealedCell {
  final int row;
  final int col;

  const RevealedCell({required this.row, required this.col});
}

class CrossPuzzle {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final String difficulty; // easy | medium | hard
  final String? categoryId;
  final int gridRows;
  final int gridCols;
  final List<CrossClue> clues;
  final int points;
  final String status; // draft | published | archived
  final bool revealAnswers;
  final CrossPuzzleProgressSummary? userProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrossPuzzle({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.difficulty,
    this.categoryId,
    required this.gridRows,
    required this.gridCols,
    required this.clues,
    required this.points,
    required this.status,
    required this.revealAnswers,
    this.userProgress,
    required this.createdAt,
    required this.updatedAt,
  });
}

class CrossPuzzleProgressSummary {
  final String status; // in_progress | completed
  final int accuracy;
  final int pointsEarned;
  final int completions;
  final int hintsUsed;
  final int mistakes;
  final int filledCells;
  final int timeSpentSeconds;
  final String? completedAt;
  final String? lastSavedAt;

  const CrossPuzzleProgressSummary({
    required this.status,
    required this.accuracy,
    required this.pointsEarned,
    required this.completions,
    required this.hintsUsed,
    required this.mistakes,
    required this.filledCells,
    required this.timeSpentSeconds,
    this.completedAt,
    this.lastSavedAt,
  });

  bool get isCompleted => status == 'completed';

  int get totalSolvedCells => filledCells;
}

class CrossPuzzleProgress {
  final String id;
  final String puzzleId;
  final String status; // in_progress | completed
  final List<GridCell> gridState;
  final List<RevealedCell> revealedCells;
  final int mistakes;
  final int hintsUsed;
  final int timeSpentSeconds;
  final int accuracy;
  final int pointsEarned;
  final int completions;
  final int? bestTimeSpentSeconds;
  final String startedAt;
  final String? completedAt;
  final String? lastSavedAt;

  const CrossPuzzleProgress({
    required this.id,
    required this.puzzleId,
    required this.status,
    required this.gridState,
    required this.revealedCells,
    required this.mistakes,
    required this.hintsUsed,
    required this.timeSpentSeconds,
    required this.accuracy,
    required this.pointsEarned,
    required this.completions,
    this.bestTimeSpentSeconds,
    required this.startedAt,
    this.completedAt,
    this.lastSavedAt,
  });

  bool get isCompleted => status == 'completed';
}

class CrossPuzzleDetail {
  final CrossPuzzle puzzle;
  final CrossPuzzleProgress? progress;
  final bool revealAnswers;

  const CrossPuzzleDetail({
    required this.puzzle,
    this.progress,
    required this.revealAnswers,
  });
}

class UserLevelInfo {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;

  const UserLevelInfo({
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
  });
}

class CrossPuzzleCompleteResult {
  final String puzzleId;
  final String title;
  final String status;
  final int totalCells;
  final int correctCells;
  final int accuracy;
  final int pointsEarned;
  final bool newlyAwarded;
  final int completions;
  final int bestTimeSpentSeconds;
  final String completedAt;
  final UserLevelInfo level;

  const CrossPuzzleCompleteResult({
    required this.puzzleId,
    required this.title,
    required this.status,
    required this.totalCells,
    required this.correctCells,
    required this.accuracy,
    required this.pointsEarned,
    required this.newlyAwarded,
    required this.completions,
    required this.bestTimeSpentSeconds,
    required this.completedAt,
    required this.level,
  });
}

class CrossPuzzleWithProgress {
  final CrossPuzzle puzzle;
  final CrossPuzzleProgress progress;

  const CrossPuzzleWithProgress({
    required this.puzzle,
    required this.progress,
  });
}