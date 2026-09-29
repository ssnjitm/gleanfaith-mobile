import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/game_lives.dart';

/// Lives for every Bible game, keyed by [BibleGameKind], persisted in secure
/// storage.
///
/// Held as one map rather than a provider family so the games hub can render all
/// four lock badges from a single watch.
///
/// `Async` on purpose: the default for a missing key is "full lives", so a
/// synchronous read would briefly show a locked game as playable while the
/// stored cooldown was still being read. Pages must render
/// `AppLoading`/`ShimmerWidget` while this is loading and only then decide
/// whether to admit the player.
final gameLivesProvider =
    AsyncNotifierProvider<GameLivesNotifier, Map<BibleGameKind, GameLives>>(
  GameLivesNotifier.new,
);

class GameLivesNotifier extends AsyncNotifier<Map<BibleGameKind, GameLives>> {
  /// Changes made before the first read landed.
  ///
  /// A page can register a mistake while `build` is still reading four storage
  /// keys. Publishing then would replace the loading state with default lives and
  /// lose the change, so early mutations are held here and merged in `build`.
  final Map<BibleGameKind, GameLives> _pending = <BibleGameKind, GameLives>{};

  /// The provider's own clock, deliberately **not** owned by any page.
  ///
  /// A widget-scoped timer only advances while that widget is mounted, so a
  /// per-page ticker freezes the moment the player navigates away, and Flutter
  /// suspends timers entirely while the app is backgrounded. Owning the tick here
  /// — for the lifetime of the provider, which is as long as anything watches
  /// lives — means a cooldown is re-evaluated continuously and from every screen,
  /// not just the one that happens to be open.
  ///
  /// `settleExpiredCooldowns` is a no-op unless a cooldown actually lapsed, and
  /// `_updateAll` publishes nothing when nothing changed, so ticking every second
  /// costs a comparison rather than a rebuild.
  Timer? _clock;

  bool _disposeHooked = false;

  /// Re-evaluates on resume, because the gap while backgrounded is exactly when
  /// a cooldown lapses with nobody watching.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _onResume,
  );

  void _onResume() {
    // A backgrounded app has no timers, so this is the first and only chance to
    // notice a cooldown that ended while the player was away. It is also the
    /// moment to re-derive any on-screen countdown from the clock.
    settleExpiredCooldowns();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => settleExpiredCooldowns(),
    );
  }

  Map<BibleGameKind, GameLives> _current() {
    final loaded = state.value;
    if (loaded != null) return loaded;
    return {
      for (final kind in BibleGameKind.values) kind: const GameLives.full(),
    };
  }

  @override
  Future<Map<BibleGameKind, GameLives>> build() async {
    // Started before the first read so a cooldown that lapses during it is still
    // caught, and kept for the provider's whole life.
    _lifecycle;
    _startClock();
    if (!_disposeHooked) {
      _disposeHooked = true;
      ref.onDispose(() {
        _clock?.cancel();
        _lifecycle.dispose();
      });
    }
    final loaded = <BibleGameKind, GameLives>{};
    for (final kind in BibleGameKind.values) {
      loaded[kind] = GameLives.fromJson(await _read(kind));
    }
    // Resolve cooldowns that lapsed while the app was closed, and persist the
    // refill so the next cold start does not have to.
    final now = DateTime.now();
    final settled = <BibleGameKind, GameLives>{};
    for (final entry in loaded.entries) {
      final normalized = entry.value.normalizedAt(now);
      settled[entry.key] = normalized;
      if (!identical(normalized, entry.value)) {
        unawaited(_write(entry.key, normalized));
      }
    }
    // Fold in anything that happened mid-read, then make it durable.
    if (_pending.isNotEmpty) {
      for (final entry in _pending.entries) {
        settled[entry.key] = entry.value;
        unawaited(_write(entry.key, entry.value));
      }
      _pending.clear();
    }
    return settled;
  }

  /// The current lives for [kind]. Call only after `build` has completed;
  /// returns a full, playable game while loading.
  GameLives livesOf(BibleGameKind kind) =>
      _current()[kind] ?? const GameLives.full();

  /// A wrong tap: one life gone, cooldown if that was the last.
  void registerMistake(BibleGameKind kind) {
    _update(kind, (current) => current.registerMistakeAt(DateTime.now()));
  }

  /// A new round started: forget the previous round's mistakes.
  void beginRound(BibleGameKind kind) {
    _update(kind, (current) => current.beginRound(), persist: false);
  }

  /// A round finished with no mistakes: one life back, capped at 3.
  ///
  /// Persisted, because an earned life that evaporates on the next cold start
  /// would make the perfect-round reward feel arbitrary. No-op when lives are
  /// already full, so it is safe to call after every round without checking.
  void rewardPerfectRound(BibleGameKind kind) {
    _update(kind, (current) => current.rewardPerfectRoundAt(DateTime.now()));
  }

  /// Re-checks every cooldown against the clock and refills what has lapsed.
  ///
  /// Called by the cooldown overlay when its countdown reaches zero and by the
  /// hub's minute ticker. The app has no background job, so the moment a
  /// cooldown ends is the moment the UI notices. A no-op that changes nothing
  /// publishes nothing, so the minute tick stays free.
  void settleExpiredCooldowns() {
    final now = DateTime.now();
    _updateAll((current) => current.normalizedAt(now));
  }

  void _update(
    BibleGameKind kind,
    GameLives Function(GameLives current) transform, {
    bool persist = true,
  }) {
    // A mutation during the first read must not overwrite the loading state.
    if (!state.hasValue) {
      final before = _pending[kind] ?? const GameLives.full();
      _pending[kind] = transform(before);
      return;
    }
    final current = _current();
    final before = current[kind] ?? const GameLives.full();
    final after = transform(before);
    // Every transform is pure and returns `this` when nothing applies, so an
    // unchanged result means "no state change" — publishing it anyway would
    // rebuild the hub once a minute for nothing.
    if (identical(before, after)) return;
    final next = Map<BibleGameKind, GameLives>.of(current)..[kind] = after;
    _publish(next, persist: persist);
  }

  void _updateAll(
    GameLives Function(GameLives current) transform, {
    bool persist = true,
  }) {
    if (!state.hasValue) return;
    final current = _current();
    final next = <BibleGameKind, GameLives>{};
    var changed = false;
    for (final entry in current.entries) {
      final after = transform(entry.value);
      changed = changed || !identical(after, entry.value);
      next[entry.key] = after;
    }
    if (!changed) return;
    _publish(next, persist: persist);
  }

  void _publish(Map<BibleGameKind, GameLives> next, {required bool persist}) {
    state = AsyncData(next);
    if (!persist) return;
    for (final kind in BibleGameKind.values) {
      unawaited(_write(kind, next[kind] ?? const GameLives.full()));
    }
  }

  Future<Map<String, dynamic>?> _read(BibleGameKind kind) async {
    try {
      final raw = await ref.read(storageProvider).read(kind.storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error) {
      // An unreadable key must never lock a player out; fall back to full lives.
      LoggerService.warning('Could not read ${kind.storageKey}: $error');
      return null;
    }
  }

  Future<void> _write(BibleGameKind kind, GameLives lives) async {
    try {
      await ref
          .read(storageProvider)
          .write(kind.storageKey, jsonEncode(lives.toJson()));
    } catch (error) {
      LoggerService.warning('Could not persist ${kind.storageKey}: $error');
    }
  }
}
