import 'dart:math';

/// A single play session for any Bible game.
///
/// Every time a game is opened a BRAND-NEW session is created with a fresh
/// random [seed], so verses and question order differ on every visit — a run is
/// never predictable from previous runs. Within the session every random draw
/// is derived from [seed], keeping the whole run coherent (and reproducible in
/// tests by passing an explicit seed).
class GameSession {
  GameSession({int? seed})
      : seed = seed ?? DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  /// Session seed. Fresh on every open; drives all randomness in the run.
  final int seed;

  /// When this session was created.
  final DateTime startedAt = DateTime.now();

  /// Number of answered rounds (0 on a freshly opened session).
  int roundIndex = 0;

  /// Points accumulated this session.
  int score = 0;

  /// Current consecutive-correct streak.
  int streak = 0;

  /// Best streak reached this session.
  int bestStreak = 0;

  /// Session-scoped random generator — stable for the session, different for
  /// every open. Pass to `BibleGameEngine(random: ...)`.
  Random get random => Random(seed);

  /// Deterministic per-session seed for round [n]. Long endless sessions keep
  /// drawing fresh content without ever repeating a previous session's order.
  int seedForRound(int n) => (seed + n * 7919) & 0x7fffffff;

  /// Registers one answered round and updates score/streak. Set
  /// [advanceRound] to false when the answer is not a full "round" (e.g. a
  /// single book tap inside a Book Order round).
  void registerResult({
    required bool correct,
    required int points,
    bool advanceRound = true,
  }) {
    if (advanceRound) roundIndex += 1;
    if (correct) {
      score += points;
      streak += 1;
      if (streak > bestStreak) bestStreak = streak;
    } else {
      streak = 0;
    }
  }
}