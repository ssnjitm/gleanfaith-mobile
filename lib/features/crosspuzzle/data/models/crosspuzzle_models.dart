import '../../domain/entities/crosspuzzle_entities.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

String _parseDateString(dynamic value) {
  if (value == null) return '';
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}

class CrossClueModel {
  final int number;
  final String clue;
  final String? answer;
  final String direction;
  final int row;
  final int col;

  const CrossClueModel({
    required this.number,
    required this.clue,
    this.answer,
    required this.direction,
    required this.row,
    required this.col,
  });

  factory CrossClueModel.fromJson(Map<String, dynamic> json) {
    return CrossClueModel(
      number: json['number'] as int? ?? json['number_in_level'] as int? ?? 1,
      clue: json['clue'] as String? ?? '',
      answer: json['answer'] as String?,
      direction: json['direction'] as String? ?? 'across',
      row: json['row'] as int? ?? json['startRow'] as int? ?? 0,
      col: json['col'] as int? ?? json['startCol'] as int? ?? 0,
    );
  }

  CrossClue toEntity() {
    return CrossClue(
      number: number,
      clue: clue,
      answer: answer,
      direction: direction,
      row: row,
      col: col,
    );
  }
}

class GridCellModel {
  final int row;
  final int col;
  final String value;

  const GridCellModel({required this.row, required this.col, required this.value});

  factory GridCellModel.fromJson(Map<String, dynamic> json) {
    return GridCellModel(
      row: json['row'] as int? ?? 0,
      col: json['col'] as int? ?? 0,
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'row': row, 'col': col, 'value': value};

  GridCell toEntity() => GridCell(row: row, col: col, value: value);
}

class RevealedCellModel {
  final int row;
  final int col;

  const RevealedCellModel({required this.row, required this.col});

  factory RevealedCellModel.fromJson(Map<String, dynamic> json) {
    return RevealedCellModel(
      row: json['row'] as int? ?? 0,
      col: json['col'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  RevealedCell toEntity() => RevealedCell(row: row, col: col);
}

class CrossPuzzleModel {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final String difficulty;
  final String? categoryId;
  final int gridRows;
  final int gridCols;
  final List<CrossClueModel> clues;
  final int points;
  final String status;
  final bool revealAnswers;
  final CrossPuzzleProgressSummaryModel? userProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrossPuzzleModel({
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

  factory CrossPuzzleModel.fromJson(Map<String, dynamic> json) {
    final cluesList = (json['clues'] as List?)?.cast<dynamic>() ?? const [];
    final userProgressRaw = json['userProgress'];
    return CrossPuzzleModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      difficulty: json['difficulty'] as String? ?? 'easy',
      categoryId: json['categoryId'] as String?,
      gridRows: json['gridRows'] as int? ?? json['rows'] as int? ?? 10,
      gridCols: json['gridCols'] as int? ?? json['cols'] as int? ?? 10,
      clues: cluesList
          .map((e) => CrossClueModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      points: json['points'] as int? ?? 100,
      status: json['status'] as String? ?? 'published',
      revealAnswers: json['revealAnswers'] as bool? ?? false,
      userProgress: userProgressRaw is Map<String, dynamic>
          ? CrossPuzzleProgressSummaryModel.fromJson(userProgressRaw)
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  CrossPuzzle toEntity() {
    return CrossPuzzle(
      id: id,
      title: title,
      description: description,
      thumbnail: thumbnail,
      difficulty: difficulty,
      categoryId: categoryId,
      gridRows: gridRows,
      gridCols: gridCols,
      clues: clues.map((e) => e.toEntity()).toList(),
      points: points,
      status: status,
      revealAnswers: revealAnswers,
      userProgress: userProgress?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CrossPuzzleProgressSummaryModel {
  final String status;
  final int accuracy;
  final int pointsEarned;
  final int completions;
  final int hintsUsed;
  final int mistakes;
  final int filledCells;
  final int timeSpentSeconds;
  final String? completedAt;
  final String? lastSavedAt;

  const CrossPuzzleProgressSummaryModel({
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

  factory CrossPuzzleProgressSummaryModel.fromJson(Map<String, dynamic> json) {
    return CrossPuzzleProgressSummaryModel(
      status: json['status'] as String? ?? 'in_progress',
      accuracy: json['accuracy'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      completions: json['completions'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      filledCells: json['filledCells'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      completedAt: json['completedAt'] as String?,
      lastSavedAt: json['lastSavedAt'] as String?,
    );
  }

  CrossPuzzleProgressSummary toEntity() {
    return CrossPuzzleProgressSummary(
      status: status,
      accuracy: accuracy,
      pointsEarned: pointsEarned,
      completions: completions,
      hintsUsed: hintsUsed,
      mistakes: mistakes,
      filledCells: filledCells,
      timeSpentSeconds: timeSpentSeconds,
      completedAt: completedAt,
      lastSavedAt: lastSavedAt,
    );
  }
}

class CrossPuzzleProgressModel {
  final String id;
  final String puzzleId;
  final String status;
  final List<GridCellModel> gridState;
  final List<RevealedCellModel> revealedCells;
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

  const CrossPuzzleProgressModel({
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

  factory CrossPuzzleProgressModel.fromJson(Map<String, dynamic> json) {
    return CrossPuzzleProgressModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      puzzleId: json['puzzleId'] as String? ?? '',
      status: json['status'] as String? ?? 'in_progress',
      gridState: _parseCells(json['gridState']),
      revealedCells: _parseRevealed(json['revealedCells']),
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      completions: json['completions'] as int? ?? 0,
      bestTimeSpentSeconds: json['bestTimeSpentSeconds'] as int?,
      startedAt: _parseDateString(json['startedAt']),
      completedAt: json['completedAt'] as String?,
      lastSavedAt: json['lastSavedAt'] as String?,
    );
  }

  static List<GridCellModel> _parseCells(dynamic value) {
    final raw = value is List ? value.cast<dynamic>() : const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GridCellModel.fromJson)
        .toList();
  }

  static List<RevealedCellModel> _parseRevealed(dynamic value) {
    final raw = value is List ? value.cast<dynamic>() : const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RevealedCellModel.fromJson)
        .toList();
  }

  CrossPuzzleProgress toEntity() {
    return CrossPuzzleProgress(
      id: id,
      puzzleId: puzzleId,
      status: status,
      gridState: gridState.map((e) => e.toEntity()).toList(),
      revealedCells: revealedCells.map((e) => e.toEntity()).toList(),
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      timeSpentSeconds: timeSpentSeconds,
      accuracy: accuracy,
      pointsEarned: pointsEarned,
      completions: completions,
      bestTimeSpentSeconds: bestTimeSpentSeconds,
      startedAt: startedAt,
      completedAt: completedAt,
      lastSavedAt: lastSavedAt,
    );
  }
}

class UserLevelInfoModel {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;

  const UserLevelInfoModel({
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
  });

  factory UserLevelInfoModel.fromJson(Map<String, dynamic> json) {
    return UserLevelInfoModel(
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentLevelPoints: json['currentLevelPoints'] as int? ?? 0,
      nextLevelPoints: json['nextLevelPoints'] as int? ?? 0,
      pointsToNextLevel: json['pointsToNextLevel'] as int? ?? 0,
    );
  }

  UserLevelInfo toEntity() {
    return UserLevelInfo(
      totalPoints: totalPoints,
      level: level,
      currentLevelPoints: currentLevelPoints,
      nextLevelPoints: nextLevelPoints,
      pointsToNextLevel: pointsToNextLevel,
    );
  }
}

class CrossPuzzleCompleteResultModel {
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
  final UserLevelInfoModel level;

  const CrossPuzzleCompleteResultModel({
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

  factory CrossPuzzleCompleteResultModel.fromJson(Map<String, dynamic> json) {
    final levelRaw = json['level'] is Map<String, dynamic>
        ? json['level'] as Map<String, dynamic>
        : <String, dynamic>{};
    return CrossPuzzleCompleteResultModel(
      puzzleId: json['puzzleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      totalCells: json['totalCells'] as int? ?? 0,
      correctCells: json['correctCells'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      newlyAwarded: json['newlyAwarded'] as bool? ?? false,
      completions: json['completions'] as int? ?? 1,
      bestTimeSpentSeconds: json['bestTimeSpentSeconds'] as int? ?? 0,
      completedAt: _parseDateString(json['completedAt']),
      level: UserLevelInfoModel.fromJson(levelRaw),
    );
  }

  CrossPuzzleCompleteResult toEntity() {
    return CrossPuzzleCompleteResult(
      puzzleId: puzzleId,
      title: title,
      status: status,
      totalCells: totalCells,
      correctCells: correctCells,
      accuracy: accuracy,
      pointsEarned: pointsEarned,
      newlyAwarded: newlyAwarded,
      completions: completions,
      bestTimeSpentSeconds: bestTimeSpentSeconds,
      completedAt: completedAt,
      level: level.toEntity(),
    );
  }
}

class CrossPuzzleWithProgressModel {
  final CrossPuzzleModel puzzle;
  final CrossPuzzleProgressModel progress;

  const CrossPuzzleWithProgressModel({
    required this.puzzle,
    required this.progress,
  });

  factory CrossPuzzleWithProgressModel.fromJson(Map<String, dynamic> json) {
    final puzzleRaw = json['puzzle'] is Map<String, dynamic>
        ? json['puzzle'] as Map<String, dynamic>
        : <String, dynamic>{};
    return CrossPuzzleWithProgressModel(
      puzzle: CrossPuzzleModel.fromJson(puzzleRaw),
      progress: CrossPuzzleProgressModel.fromJson(json),
    );
  }

  CrossPuzzleWithProgress toEntity() {
    return CrossPuzzleWithProgress(
      puzzle: puzzle.toEntity(),
      progress: progress.toEntity(),
    );
  }
}