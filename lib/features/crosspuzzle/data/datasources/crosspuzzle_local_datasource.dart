import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/storage_service.dart';
import '../../domain/entities/crosspuzzle_entities.dart';

/// Local-progress record persisted in secure storage for a puzzle.
class LocalProgressRecord {
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

  const LocalProgressRecord({
    this.status = 'in_progress',
    this.gridState = const [],
    this.revealedCells = const [],
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.timeSpentSeconds = 0,
    this.accuracy = 0,
    this.pointsEarned = 0,
    this.completions = 0,
    this.bestTimeSpentSeconds,
    required this.startedAt,
    this.completedAt,
    this.lastSavedAt,
  });

  bool get isCompleted => status == 'completed';

  factory LocalProgressRecord.fromJson(Map<String, dynamic> json) {
    final gridList = (json['gridState'] as List?) ?? const [];
    final revealedList = (json['revealedCells'] as List?) ?? const [];
    return LocalProgressRecord(
      status: json['status'] as String? ?? 'in_progress',
      gridState: gridList
          .whereType<Map<String, dynamic>>()
          .map((e) => GridCell(
                row: e['row'] as int? ?? 0,
                col: e['col'] as int? ?? 0,
                value: e['value'] as String? ?? '',
              ))
          .toList(),
      revealedCells: revealedList
          .whereType<Map<String, dynamic>>()
          .map((e) =>
              RevealedCell(row: e['row'] as int? ?? 0, col: e['col'] as int? ?? 0))
          .toList(),
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      completions: json['completions'] as int? ?? 0,
      bestTimeSpentSeconds: json['bestTimeSpentSeconds'] as int?,
      startedAt: json['startedAt'] as String? ?? DateTime.now().toIso8601String(),
      completedAt: json['completedAt'] as String?,
      lastSavedAt: json['lastSavedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'gridState': gridState
          .map((c) => {'row': c.row, 'col': c.col, 'value': c.value})
          .toList(),
      'revealedCells':
          revealedCells.map((c) => {'row': c.row, 'col': c.col}).toList(),
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'timeSpentSeconds': timeSpentSeconds,
      'accuracy': accuracy,
      'pointsEarned': pointsEarned,
      'completions': completions,
      'bestTimeSpentSeconds': bestTimeSpentSeconds,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'lastSavedAt': lastSavedAt,
    };
  }
}

/// Reads the bundled 50-level crossword dataset and provides
/// local-only progress persistence + grading (used as a fallback
/// when the backend has no published puzzles).
class CrossPuzzleLocalDataSource {
  final StorageService _storageService;
  static const String _assetPath = 'assets/databases/bible_crossword_50_sets.json';
  static const String _progressKey = 'crossword_local_progress';
  static const String _idPrefix = 'local_';

  CrossPuzzleLocalDataSource(this._storageService);

  /// Builds a stable local id for a set, e.g. `local_1`.
  static String localIdFor(int setNumber) => '$_idPrefix$setNumber';

  /// True when the puzzle id belongs to the local bundled dataset.
  static bool isLocalId(String puzzleId) => puzzleId.startsWith(_idPrefix);

  /// Reads the asset and returns each set as a [CrossPuzzle]
  /// (answers included — it is graded locally).
  Future<List<CrossPuzzle>> getLocalPuzzles() async {
    final sets = await _parseAsset();
    final progress = await _readAllProgress();
    return sets.map((set) {
      final puzzle = _buildPuzzle(set);
      final record = progress[puzzle.id];
      return _attachSummary(puzzle, record);
    }).toList();
  }

  Future<CrossPuzzleDetail> getLocalPuzzleDetail(String puzzleId) async {
    final sets = await _parseAsset();
    final set = sets.where((s) => localIdFor(s.setId) == puzzleId).firstOrNull;
    if (set == null) {
      // Fall back to the first set if the id is unknown.
      if (sets.isEmpty) {
        throw Exception('No local crossword sets available');
      }
      return _detailFor(sets.first);
    }
    return _detailFor(set);
  }

  Future<CrossPuzzleProgress?> getLocalProgress(String puzzleId) async {
    final record = (await _readAllProgress())[puzzleId];
    return record == null ? null : _progressFromRecord(record);
  }

  Future<List<CrossPuzzleWithProgress>> getMyLocalProgress() async {
    final sets = await _parseAsset();
    final progress = await _readAllProgress();
    final result = <CrossPuzzleWithProgress>[];
    for (final set in sets) {
      final id = localIdFor(set.setId);
      final record = progress[id];
      if (record == null || record.gridState.isEmpty && !record.isCompleted) {
        continue;
      }
      result.add(CrossPuzzleWithProgress(
        puzzle: _buildPuzzle(set),
        progress: _progressFromRecord(record),
      ));
    }
    return result;
  }

  Future<CrossPuzzleProgress> saveLocalProgress({
    required String puzzleId,
    required List<GridCell> gridState,
    required List<RevealedCell> revealedCells,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    final all = await _readAllProgress();
    final existing = all[puzzleId] ??
        LocalProgressRecord(
          startedAt: DateTime.now().toIso8601String(),
          bestTimeSpentSeconds: null,
        );

    final updated = LocalProgressRecord(
      status: existing.status,
      gridState: gridState,
      revealedCells: revealedCells,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      timeSpentSeconds: timeSpentSeconds,
      accuracy: existing.accuracy,
      pointsEarned: existing.pointsEarned,
      completions: existing.completions,
      bestTimeSpentSeconds: existing.bestTimeSpentSeconds,
      startedAt: existing.startedAt,
      completedAt: existing.completedAt,
      lastSavedAt: DateTime.now().toIso8601String(),
    );
    all[puzzleId] = updated;
    await _writeAllProgress(all);
    return _progressFromRecord(updated);
  }

  /// Grades the submitted grid locally using the bundled answers and
  /// returns a result shaped exactly like the backend's complete payload.
  Future<CrossPuzzleCompleteResult> completeLocalPuzzle({
    required String puzzleId,
    required List<GridCell> gridState,
    required int mistakes,
    required int hintsUsed,
    required int timeSpentSeconds,
  }) async {
    final detail = await getLocalPuzzleDetail(puzzleId);
    final puzzle = detail.puzzle;

    final answerCells = <String, String>{};
    for (final clue in puzzle.clues) {
      final answer = clue.answer ?? '';
      if (clue.direction == 'across') {
        for (var i = 0; i < answer.length; i++) {
          answerCells['${clue.row},${clue.col + i}'] = answer[i];
        }
      } else {
        for (var i = 0; i < answer.length; i++) {
          answerCells['${clue.row + i},${clue.col}'] = answer[i];
        }
      }
    }

    final totalCells = answerCells.length;
    var correctCells = 0;
    final graded = <String>{};
    for (final cell in gridState) {
      final key = '${cell.row},${cell.col}';
      if (!graded.add(key)) continue;
      final expected = answerCells[key];
      if (expected != null && expected == cell.value.toUpperCase()) {
        correctCells += 1;
      }
    }

    final accuracy = totalCells > 0 ? ((correctCells / totalCells) * 100).round() : 0;
    final isSolved = totalCells > 0 && correctCells == totalCells;
    final pointsEarned = ((puzzle.points * accuracy) / 100).round();

    final all = await _readAllProgress();
    final existing = all[puzzleId] ??
        LocalProgressRecord(
          startedAt: DateTime.now().toIso8601String(),
        );
    final wasCompleted = existing.status == 'completed';
    final newlyAwarded = isSolved && !wasCompleted;
    final completions = existing.completions + (isSolved ? 1 : 0);
    final prevBest = existing.bestTimeSpentSeconds;
    final bestTime = isSolved
        ? (prevBest == null
            ? timeSpentSeconds
            : (timeSpentSeconds < prevBest ? timeSpentSeconds : prevBest))
        : prevBest;

    final now = DateTime.now().toIso8601String();
    final updated = LocalProgressRecord(
      status: isSolved ? 'completed' : 'in_progress',
      gridState: gridState,
      revealedCells: existing.revealedCells,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      timeSpentSeconds: timeSpentSeconds,
      accuracy: accuracy,
      pointsEarned: newlyAwarded ? existing.pointsEarned + pointsEarned : existing.pointsEarned,
      completions: completions,
      bestTimeSpentSeconds: bestTime,
      startedAt: existing.startedAt,
      completedAt: isSolved ? now : existing.completedAt,
      lastSavedAt: now,
    );
    all[puzzleId] = updated;
    await _writeAllProgress(all);

    return CrossPuzzleCompleteResult(
      puzzleId: puzzleId,
      title: puzzle.title,
      status: isSolved ? 'completed' : 'in_progress',
      totalCells: totalCells,
      correctCells: correctCells,
      accuracy: accuracy,
      pointsEarned: isSolved ? pointsEarned : 0,
      newlyAwarded: newlyAwarded,
      completions: completions,
      bestTimeSpentSeconds: bestTime ?? timeSpentSeconds,
      completedAt: isSolved ? now : existing.completedAt ?? '',
      level: _buildLevelInfo(all),
    );
  }

  Future<bool> resetLocalProgress(String puzzleId) async {
    final all = await _readAllProgress();
    final removed = all.remove(puzzleId) != null;
    await _writeAllProgress(all);
    return removed;
  }

  // --- Internals ---------------------------------------------------------

  Future<List<_LocalSet>> _parseAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final sets = (json['sets'] as List?) ?? const [];
    return sets
        .map((e) => _LocalSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, LocalProgressRecord>> _readAllProgress() async {
    final raw = await _storageService.read(_progressKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(
            key,
            LocalProgressRecord.fromJson(value as Map<String, dynamic>),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAllProgress(Map<String, LocalProgressRecord> all) async {
    final json = all.map((key, value) => MapEntry(key, value.toJson()));
    await _storageService.write(_progressKey, jsonEncode(json));
  }

  CrossPuzzle _buildPuzzle(_LocalSet set) {
    if (set.questions.isEmpty) {
      throw Exception('Crossword set ${set.setId} has no questions');
    }

    final layout = _buildCrosswordLayout(set.questions);

    final difficulty = _majorityDifficulty(set.questions);

    return CrossPuzzle(
      id: localIdFor(set.setId),
      title: set.title,
      description: 'Level ${set.setId} · ${set.questions.length} clues',
      thumbnail: null,
      difficulty: difficulty,
      categoryId: null,
      gridRows: layout.rows,
      gridCols: layout.cols,
      clues: layout.clues,
      points: 100,
      status: 'published',
      revealAnswers: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Builds an interlocking across/down crossword layout from the set's
  /// questions. Words are placed greedily (longest first), crossing at
  /// shared letters; clue numbers follow classic reading order
  /// (top-left first), with a shared number when across + down words start
  /// on the same cell.
  _CrosswordLayout _buildCrosswordLayout(List<_LocalQuestion> questions) {
    final placed = <_LayoutWord>[];
    final occupied = <String, String>{};

    final sorted = [...questions]
      ..sort((a, b) => b.answer.length.compareTo(a.answer.length));

    // Place the longest word horizontally in the top-left corner.
    final first = sorted.first;
    placed.add(_LayoutWord(
      question: first,
      direction: 'across',
      row: 0,
      col: 0,
    ));
    for (var c = 0; c < first.answer.length; c++) {
      occupied['0,$c'] = first.answer[c];
    }

    for (var i = 1; i < sorted.length; i++) {
      final word = sorted[i];
      final best = _findBestPlacement(word, occupied);
      if (best != null) {
        placed.add(best);
        _markPlaced(best, occupied);
      } else {
        // No intersection found — start a fresh island below the grid.
        final startRow = _maxOccupiedRow(occupied) + 2;
        final fallback = _LayoutWord(
          question: word,
          direction: 'across',
          row: startRow,
          col: 0,
        );
        placed.add(fallback);
        _markPlaced(fallback, occupied);
      }
    }

    // Normalize coordinates to a 0-based grid.
    var minRow = 0, minCol = 0, maxRow = 0, maxCol = 0;
    for (final word in placed) {
      for (var i = 0; i < word.answer.length; i++) {
        final row = word.direction == 'down' ? word.row + i : word.row;
        final col = word.direction == 'across' ? word.col + i : word.col;
        if (row < minRow) minRow = row;
        if (row > maxRow) maxRow = row;
        if (col < minCol) minCol = col;
        if (col > maxCol) maxCol = col;
      }
    }

    // Assign clue numbers in reading order over the normalized grid.
    final numbers = <String, int>{};
    final startKeys = placed.map((w) {
      final r = w.row - minRow;
      final c = w.col - minCol;
      return '$r,$c';
    }).toSet();
    var nextNumber = 1;
    for (var r = minRow; r <= maxRow; r++) {
      for (var c = minCol; c <= maxCol; c++) {
        final key = '${r - minRow},${c - minCol}';
        if (startKeys.contains(key)) {
          numbers[key] = nextNumber++;
        }
      }
    }

    final clues = placed.map((w) {
      final row = w.row - minRow;
      final col = w.col - minCol;
      return CrossClue(
        number: numbers['$row,$col']!,
        clue: w.question.clue,
        answer: w.answer,
        direction: w.direction,
        row: row,
        col: col,
      );
    }).toList();

    return _CrosswordLayout(
      clues: clues,
      rows: maxRow - minRow + 1,
      cols: maxCol - minCol + 1,
    );
  }

  _LayoutWord? _findBestPlacement(
    _LocalQuestion word,
    Map<String, String> occupied,
  ) {
    _LayoutWord? best;
    var bestScore = -1;

    // Try every cell of every placed word as a crossing point.
    final placedCells = occupied.keys.toList();
    for (final key in placedCells) {
      final parts = key.split(',');
      final pr = int.parse(parts[0]);
      final pc = int.parse(parts[1]);
      final letter = occupied[key]!;
      for (var li = 0; li < word.answer.length; li++) {
        if (word.answer[li] != letter) continue;

        // Try placing this word vertically, crossing at (pr, pc).
        final vStartRow = pr - li;
        final vScore = _scorePlacement(
          word,
          vStartRow,
          pc,
          'down',
          occupied,
        );
        if (vScore != null && vScore > bestScore) {
          bestScore = vScore;
          best = _LayoutWord(
            question: word,
            direction: 'down',
            row: vStartRow,
            col: pc,
          );
        }

        // Try placing this word horizontally, crossing at (pr, pc).
        final hStartCol = pc - li;
        final hScore = _scorePlacement(
          word,
          pr,
          hStartCol,
          'across',
          occupied,
        );
        if (hScore != null && hScore > bestScore) {
          bestScore = hScore;
          best = _LayoutWord(
            question: word,
            direction: 'across',
            row: pr,
            col: hStartCol,
          );
        }
      }
    }
    return best;
  }

  /// Validates a candidate placement and returns a score (or null when
  /// invalid). Higher = better: prefers more shared letters and a more
  /// compact result.
  int? _scorePlacement(
    _LocalQuestion word,
    int row,
    int col,
    String direction,
    Map<String, String> occupied,
  ) {
    final length = word.answer.length;
    final dr = direction == 'down' ? 1 : 0;
    final dc = direction == 'across' ? 1 : 0;

    var intersections = 0;
    var minRow = row, maxRow = row, minCol = col, maxCol = col;

    for (var i = 0; i < length; i++) {
      final r = row + dr * i;
      final c = col + dc * i;
      final key = '$r,$c';
      final existing = occupied[key];
      if (existing != null) {
        if (existing != word.answer[i]) return null;
        intersections++;
      } else {
        // Perpendicular neighbours must be empty (no parallel touch).
        final pr = direction == 'down' ? 0 : 1;
        final pc = direction == 'down' ? 1 : 0;
        if (occupied.containsKey('${r - pr},${c - pc}') ||
            occupied.containsKey('${r + pr},${c + pc}')) {
          return null;
        }
      }
      if (r < minRow) minRow = r;
      if (r > maxRow) maxRow = r;
      if (c < minCol) minCol = c;
      if (c > maxCol) maxCol = c;
    }

    // Words must not merge: empty cell right before/after the word.
    if (occupied.containsKey('${row - dr},${col - dc}') ||
        occupied.containsKey('${row + dr * length},${col + dc * length}')) {
      return null;
    }

    if (intersections == 0) return null;

    final area = (maxRow - minRow + 1) * (maxCol - minCol + 1);
    return intersections * 1000 - area;
  }

  void _markPlaced(_LayoutWord word, Map<String, String> occupied) {
    for (var i = 0; i < word.answer.length; i++) {
      final r = word.direction == 'down' ? word.row + i : word.row;
      final c = word.direction == 'across' ? word.col + i : word.col;
      occupied['$r,$c'] = word.answer[i];
    }
  }

  int _maxOccupiedRow(Map<String, String> occupied) {
    var maxRow = 0;
    for (final key in occupied.keys) {
      final row = int.parse(key.split(',')[0]);
      if (row > maxRow) maxRow = row;
    }
    return maxRow;
  }

  CrossPuzzle _attachSummary(CrossPuzzle puzzle, LocalProgressRecord? record) {
    if (record == null) return puzzle;
    return CrossPuzzle(
      id: puzzle.id,
      title: puzzle.title,
      description: puzzle.description,
      thumbnail: puzzle.thumbnail,
      difficulty: puzzle.difficulty,
      categoryId: puzzle.categoryId,
      gridRows: puzzle.gridRows,
      gridCols: puzzle.gridCols,
      clues: puzzle.clues,
      points: puzzle.points,
      status: puzzle.status,
      revealAnswers: record.isCompleted,
      userProgress: CrossPuzzleProgressSummary(
        status: record.status,
        accuracy: record.accuracy,
        pointsEarned: record.pointsEarned,
        completions: record.completions,
        hintsUsed: record.hintsUsed,
        mistakes: record.mistakes,
        filledCells: record.gridState.length,
        timeSpentSeconds: record.timeSpentSeconds,
        completedAt: record.completedAt,
        lastSavedAt: record.lastSavedAt,
      ),
      createdAt: puzzle.createdAt,
      updatedAt: puzzle.updatedAt,
    );
  }

  Future<CrossPuzzleDetail> _detailFor(_LocalSet set) async {
    final id = localIdFor(set.setId);
    final record = (await _readAllProgress())[id];
    final puzzle = _attachSummary(_buildPuzzle(set), record);
    return CrossPuzzleDetail(
      puzzle: puzzle,
      progress: record == null ? null : _progressFromRecord(record),
      revealAnswers: record?.isCompleted ?? false,
    );
  }

  CrossPuzzleProgress _progressFromRecord(LocalProgressRecord record) {
    return CrossPuzzleProgress(
      id: '',
      puzzleId: '',
      status: record.status,
      gridState: record.gridState,
      revealedCells: record.revealedCells,
      mistakes: record.mistakes,
      hintsUsed: record.hintsUsed,
      timeSpentSeconds: record.timeSpentSeconds,
      accuracy: record.accuracy,
      pointsEarned: record.pointsEarned,
      completions: record.completions,
      bestTimeSpentSeconds: record.bestTimeSpentSeconds,
      startedAt: record.startedAt,
      completedAt: record.completedAt,
      lastSavedAt: record.lastSavedAt,
    );
  }

  UserLevelInfo _buildLevelInfo(Map<String, LocalProgressRecord> all) {
    var total = 0;
    for (final record in all.values) {
      total += record.pointsEarned;
    }
    const base = 1000;
    final level = (total ~/ base) + 1;
    final currentLevelPoints = total - (level - 1) * base;
    final nextLevelPoints = level * base;
    return UserLevelInfo(
      totalPoints: total,
      level: level,
      currentLevelPoints: currentLevelPoints,
      nextLevelPoints: nextLevelPoints,
      pointsToNextLevel: nextLevelPoints - total,
    );
  }

  String _majorityDifficulty(List<_LocalQuestion> questions) {
    final counts = <String, int>{};
    for (final q in questions) {
      final d = q.difficulty.isEmpty ? 'easy' : q.difficulty;
      counts[d] = (counts[d] ?? 0) + 1;
    }
    var best = 'easy';
    var bestCount = -1;
    counts.forEach((key, value) {
      if (value > bestCount) {
        best = key;
        bestCount = value;
      }
    });
    return best;
  }
}

class _LocalSet {
  final int setId;
  final int level;
  final String title;
  final List<_LocalQuestion> questions;

  const _LocalSet({
    required this.setId,
    required this.level,
    required this.title,
    required this.questions,
  });

  factory _LocalSet.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List?) ?? const [];
    return _LocalSet(
      setId: json['set_id'] as int? ?? json['level'] as int? ?? 1,
      level: json['level'] as int? ?? json['set_id'] as int? ?? 1,
      title: json['title'] as String? ?? 'Level ${json['set_id'] ?? 1}',
      questions: questions
          .map((e) => _LocalQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _LocalQuestion {
  final int id;
  final int numberInLevel;
  final String clue;
  final String answer;
  final int length;
  final String reference;
  final String category;
  final String difficulty;

  const _LocalQuestion({
    required this.id,
    required this.numberInLevel,
    required this.clue,
    required this.answer,
    required this.length,
    required this.reference,
    required this.category,
    required this.difficulty,
  });

  factory _LocalQuestion.fromJson(Map<String, dynamic> json) {
    return _LocalQuestion(
      id: json['id'] as int? ?? 0,
      numberInLevel: json['number_in_level'] as int? ?? json['id'] as int? ?? 1,
      clue: json['clue'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      length: json['length'] as int? ?? (json['answer'] as String? ?? '').length,
      reference: json['reference'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
    );
  }
}

/// Result of [CrossPuzzleLocalDataSource._buildCrosswordLayout].
class _CrosswordLayout {
  final List<CrossClue> clues;
  final int rows;
  final int cols;

  const _CrosswordLayout({
    required this.clues,
    required this.rows,
    required this.cols,
  });
}

/// A single word placed on the crossword grid.
class _LayoutWord {
  final _LocalQuestion question;
  final String answer;
  final String direction; // across | down
  final int row;
  final int col;

  _LayoutWord({
    required this.question,
    required this.direction,
    required this.row,
    required this.col,
  }) : answer = question.answer;
}