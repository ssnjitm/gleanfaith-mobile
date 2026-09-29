import 'bible_game_localization.dart';

/// The four Bible games, each with its **own** pool of lives and its **own**
/// cooldown.
///
/// A per-game pool is what makes the stakes readable: burning all three lives in
/// Guess the Book locks that one game for two hours and leaves the other three
/// fully playable, so a single rough streak never walls the player out of the
/// whole section.
///
/// [storageSuffix] is the persisted key fragment, so the two can never drift.
enum BibleGameKind {
  guessBook('guess_book'),
  higherLower('higher_lower'),
  bookOrder('book_order'),
  findChapter('find_chapter');

  const BibleGameKind(this.storageSuffix);

  final String storageSuffix;

  /// Full secure-storage key for this game's lives record.
  String get storageKey => 'bible_game_lives_$storageSuffix';
}

/// The lives state of one [BibleGameKind]: how many lives are left, when a
/// cooldown expires, and how many mistakes the *current* round has made.
///
/// Pure and free of Flutter, storage and clock reads — every method takes the
/// current time as a parameter, so the whole cooldown/heal state machine is
/// unit-testable without waiting two hours or injecting a fake clock.
///
/// The rules:
/// * [maxLives] lives to start.
/// * Every wrong tap costs one life, clamped at 0.
/// * Losing the last life starts a [cooldownDuration] cooldown **immediately**
///   (not on leaving the game), so walking away cannot dodge it.
/// * A round finished with **zero** mistakes gives one life back, capped at
///   [maxLives] — a perfect round is the only way to recover early.
/// * Once [cooldownUntil] passes, lives refill to [maxLives] and the cooldown
///   clears. [settled] is how that happens without a background job: read state
///   with [normalizedAt] and it reports a full, unlocked game even if nothing
///   has written the refill to storage yet.
class GameLives {
  static const int maxLives = 3;
  static const Duration cooldownDuration = Duration(hours: 2);

  /// Lives remaining, 0..[maxLives].
  final int lives;

  /// When the cooldown ends, or null when the game is playable.
  final DateTime? cooldownUntil;

  /// Wrong taps in the round in progress. Not persisted — a round never
  /// survives an app restart anyway.
  final int mistakesThisRound;

  const GameLives({
    this.lives = maxLives,
    this.cooldownUntil,
    this.mistakesThisRound = 0,
  });

  /// A game that has never been played: full lives, no cooldown.
  const GameLives.full() : this();

  /// Whether the game is locked right now.
  ///
  /// Derived from [cooldownUntil] and the caller's clock, so a cooldown that
  /// lapsed while the app was closed reads as expired immediately.
  bool isCooldownActiveAt(DateTime now) {
    final until = cooldownUntil;
    return until != null && now.isBefore(until);
  }

  /// Time left on the cooldown; [Duration.zero] when playable.
  Duration cooldownRemainingAt(DateTime now) {
    final until = cooldownUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// A copy with the cooldown resolved against [now]: once it has elapsed the
  /// game is back to full lives with no cooldown.
  GameLives normalizedAt(DateTime now) {
    if (cooldownUntil == null) {
      if (lives == maxLives && mistakesThisRound == 0) return this;
      return GameLives(lives: lives.clamp(0, maxLives));
    }
    if (isCooldownActiveAt(now)) {
      // Locked: lives stay at 0 so the UI keeps showing the loss.
      return this;
    }
    return const GameLives.full();
  }

  /// Registers one wrong tap.
  ///
  /// Returns a copy with one fewer life; when that was the last life the
  /// cooldown starts now. A wrong tap made *during* a cooldown is ignored — the
  /// game is not playable, so there is nothing to lose.
  GameLives registerMistakeAt(DateTime now) {
    if (isCooldownActiveAt(now)) return this;
    final next = (lives - 1).clamp(0, maxLives);
    if (next > 0) {
      return GameLives(
        lives: next,
        cooldownUntil: cooldownUntil,
        mistakesThisRound: mistakesThisRound + 1,
      );
    }
    return GameLives(
      lives: 0,
      cooldownUntil: now.add(cooldownDuration),
      mistakesThisRound: mistakesThisRound + 1,
    );
  }

  /// A copy with [mistakesThisRound] reset, called when a new round starts.
  GameLives beginRound() {
    if (mistakesThisRound == 0) return this;
    return GameLives(lives: lives, cooldownUntil: cooldownUntil);
  }

  /// Awards the perfect-round bonus: one life back, capped at [maxLives].
  ///
  /// No-op when the round had a mistake, when the game is locked, or when lives
  /// are already full — a "perfect" round cannot be claimed during a cooldown,
  /// and the perfect-round test is what stops a lucky finish from refunding a
  /// life the player just spent on a mistake.
  ///
  /// Checking [mistakesThisRound] here (rather than trusting the caller) is
  /// deliberate: this is the rule, and a rule that depends on every call site
  /// remembering it is a rule that eventually leaks.
  GameLives rewardPerfectRoundAt(DateTime now) {
    if (isCooldownActiveAt(now)) return this;
    if (mistakesThisRound > 0) return this;
    if (lives >= maxLives) return beginRound();
    return GameLives(
      lives: lives + 1,
      cooldownUntil: cooldownUntil,
    );
  }

  /// Renders the remaining cooldown as `h:mm:ss` — or `m:ss` below an hour —
  /// using this language's numerals.
  String formatCooldownAt(DateTime now, BibleGameLanguage language) {
    return formatDuration(cooldownRemainingAt(now), language);
  }

  /// Formats any [duration] as a countdown in this language's numerals.
  ///
  /// Static because the cooldown length is needed before a [GameLives] exists —
  /// the "that was your last life, 2:00:00 cooldown" message is built at the
  /// moment of the mistake, not from the resulting state.
  ///
  /// Seconds are always shown: a cooldown that ticks down without them cannot be
  /// read at a glance, and the whole point of the dial is that the player sees
  /// it moving.
  static String formatDuration(Duration duration, BibleGameLanguage language) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String n(int value) => formatCount(value, language);
    if (hours > 0) {
      return '${n(hours)}:${_two(minutes, language)}:${_two(seconds, language)}';
    }
    return '${n(minutes)}:${_two(seconds, language)}';
  }

  static String _two(int value, BibleGameLanguage language) {
    final text = formatCount(value, language);
    return text.length >= 2 ? text : '0$text';
  }

  /// Serialized form for secure storage. Only the two durable fields are kept —
  /// [mistakesThisRound] deliberately is not, so a restart never leaves a
  /// half-scored round behind.
  Map<String, dynamic> toJson() => {
        'lives': lives,
        if (cooldownUntil != null)
          'cooldownUntil': cooldownUntil!.toIso8601String(),
      };

  /// Tolerant parser: anything unreadable yields a full, playable game rather
  /// than locking a player out because of a corrupt key.
  static GameLives fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GameLives.full();
    final rawLives = json['lives'];
    final lives = rawLives is int
        ? rawLives.clamp(0, maxLives)
        : (int.tryParse('${rawLives ?? ''}') ?? maxLives);
    DateTime? until;
    final raw = json['cooldownUntil'];
    if (raw is String && raw.isNotEmpty) {
      until = DateTime.tryParse(raw);
    } else if (raw is int) {
      until = DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return GameLives(
      lives: lives,
      cooldownUntil: until,
    );
  }

  @override
  String toString() => 'GameLives(lives: $lives, cooldownUntil: $cooldownUntil)';
}
