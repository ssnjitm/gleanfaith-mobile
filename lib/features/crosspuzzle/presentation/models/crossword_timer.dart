/// Elapsed-time accounting for a single crossword attempt.
///
/// The play page ticks this once per second, but the value must stop moving the
/// instant the puzzle is submitted: the completion request carries the frozen
/// value, and the autosave / `dispose` writes must never report a longer time
/// than the one that was submitted.
///
/// This is deliberately plain Dart (no Flutter, no [Timer]) so the freezing
/// rules can be unit-tested without pumping a widget.
class CrosswordTimer {
  CrosswordTimer({int initialSeconds = 0})
    : _seconds = initialSeconds < 0 ? 0 : initialSeconds;

  int _seconds;
  bool _frozen = false;

  /// Whole seconds elapsed so far. Stable once [freeze] has been called.
  int get seconds => _seconds;

  /// Whether the clock has been frozen by a submission.
  bool get isFrozen => _frozen;

  /// Advances the clock by one second. A frozen clock ignores ticks, so a
  /// ticker callback that was already queued cannot push the time forward.
  void tick() {
    if (_frozen) return;
    _seconds += 1;
  }

  /// Freezes the clock and returns the value at the moment of submission.
  ///
  /// Calling this again is safe and returns the same value, so the completion
  /// request and the later progress writes always agree on the final time.
  int freeze() {
    _frozen = true;
    return _seconds;
  }

  /// Re-opens a frozen clock after a failed submission so the user can keep
  /// playing without losing the time already spent.
  void resume() {
    _frozen = false;
  }
}
