import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../constants/asset_paths.dart';
import 'logger_service.dart';

/// Plays the bundled short sound effects (correct / incorrect / timer / ending).
///
/// Design notes:
/// - **A pool, not one player per sound.** `just_audio` cannot retrigger a
///   player mid-playback, so a single player would cut the previous sound off.
///   Two players per sound lets consecutive answers overlap naturally.
/// - **Never throws.** Audio is decoration; a missing platform plugin (web
///   without `just_audio_web`, or a widget test) must not break a quiz. The
///   first failure flips [_platformSupported] off so we stop retrying and stop
///   logging.
/// - **Assets are preloaded lazily.** `setAsset` decodes asynchronously, and
///   decoding on first play makes the feedback arrive after the animation, so
///   [preload] kicks the load off as soon as audio is switched on.
class AudioService {
  AudioService();

  /// How many players to keep per sound. Two is enough to let a correct and an
  /// incorrect cue overlap without either being chopped off.
  static const int _poolSize = 2;

  /// Longest we let the timer file run. It is a ~1 minute loop, but a countdown
  /// tick should be a short blip.
  static const Duration _timerBlip = Duration(milliseconds: 400);

  final Map<SfxSound, List<AudioPlayer>> _pools = {};
  final Map<SfxSound, int> _cursor = {};

  /// Players whose asset load has been kicked off.
  final Map<AudioPlayer, Future<void>> _loadFutures = {};

  final Map<AudioPlayer, Timer> _stopTimers = {};

  bool _platformSupported = true;
  bool _enabled = true;
  double _volume = 1;
  bool _preloadStarted = false;

  /// Whether sound effects play at all.
  bool get enabled => _enabled;

  /// Current output volume, 0.0 – 1.0.
  double get volume => _volume;

  /// False once a platform error proved this device cannot play the assets.
  bool get platformSupported => _platformSupported;

  /// Enables or disables every effect. Turning it off also silences whatever is
  /// currently playing, so a mute mid-cue is immediate.
  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) stopAll();
  }

  /// Sets output volume. Applied immediately, including mid-playback, so
  /// dragging the slider in Settings is audible.
  void setVolume(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (_volume == clamped) return;
    _volume = clamped;
    for (final player in _allPlayers) {
      unawaited(_guard(() => player.setVolume(_volume)));
    }
  }

  /// Warms the asset cache so the first tap is not silent.
  ///
  /// Fire-and-forget: failures are swallowed (see [_guard]) and only logged once
  /// per sound. The pools must be created here — they are otherwise only built
  /// on first play, which would make this method a no-op at startup.
  void preload() {
    if (_preloadStarted || !_platformSupported) return;
    _preloadStarted = true;
    for (final sound in SfxSound.values) {
      _poolFor(sound);
      unawaited(_load(sound));
    }
  }

  /// Plays [sound] at the configured volume.
  ///
  /// Returns as soon as playback is triggered; awaiting the `play()` future
  /// would block on the clip finishing, which no caller wants.
  void play(SfxSound sound) {
    if (!_enabled || !_platformSupported || _volume <= 0) return;

    if (sound == SfxSound.timer) {
      _play(sound, stopAfter: _timerBlip);
      return;
    }
    _play(sound);
  }

  /// Stops everything immediately. Used when audio is switched off and on
  /// teardown.
  void stopAll() {
    _cancelAllTimers();
    for (final player in _allPlayers) {
      unawaited(_guard(() => player.stop()));
    }
  }

  /// Releases the native players. Safe to call more than once.
  Future<void> dispose() async {
    _cancelAllTimers();
    final players = _allPlayers;
    _pools.clear();
    _cursor.clear();
    _loadFutures.clear();
    for (final player in players) {
      try {
        await player.dispose();
      } catch (error) {
        LoggerService.warning('AudioService: dispose failed: $error');
      }
    }
  }

  void _play(SfxSound sound, {Duration? stopAfter}) {
    final player = _takePlayer(sound);
    unawaited(
      _guard(() async {
        await _ensureLoaded(sound, player);
        if (!_enabled || !_platformSupported) return;
        // Rewind, do not `stop()`. A player that reached the end of its clip
        // sits at the end position, where `play()` is silent — so the second
        // time a pooled player is reused the cue would go missing. Seeking to
        // zero also retriggers a still-playing clip, which is what a countdown
        // blip should do.
        await player.seek(Duration.zero);
        await player.setVolume(_volume);
        unawaited(player.play());

        if (stopAfter != null) {
          _scheduleStop(player, stopAfter);
        }
      }),
    );
  }

  /// Round-robins the pool, preferring a player that has finished.
  AudioPlayer _takePlayer(SfxSound sound) {
    final pool = _poolFor(sound);
    final cursor = _cursor[sound] ?? 0;
    _cursor[sound] = (cursor + 1) % pool.length;
    return pool[cursor];
  }

  /// The pool for [sound], created on first use.
  List<AudioPlayer> _poolFor(SfxSound sound) {
    return _pools.putIfAbsent(sound, () {
      final created = List<AudioPlayer>.generate(
        _poolSize,
        (_) => AudioPlayer(),
        growable: false,
      );
      for (final player in created) {
        unawaited(_guard(() => player.setVolume(_volume)));
      }
      return created;
    });
  }

  Future<void> _load(SfxSound sound) async {
    final pool = _pools[sound];
    if (pool == null) return;
    for (final player in pool) {
      // Individually guarded: a pool that fails to load must not reject the
      // whole preload and surface as an unhandled async error.
      try {
        await _ensureLoaded(sound, player);
      } catch (_) {
        return;
      }
    }
  }

  /// Caches the in-flight (and settled) asset load per player, so two
  /// overlapping taps never call `setAsset` twice on the same player.
  ///
  /// A cached future cannot hang: whatever `setAsset` does, the future settles.
  /// On failure it rethrows, which `_guard` turns into "disable the platform".
  Future<void> _ensureLoaded(SfxSound sound, AudioPlayer player) {
    return _loadFutures[player] ??= () async {
      await player.setAsset(sound.assetPath);
      await player.setVolume(_volume);
    }();
  }

  void _scheduleStop(AudioPlayer player, Duration after) {
    _stopTimers[player]?.cancel();
    _stopTimers[player] = Timer(after, () {
      _stopTimers.remove(player);
      unawaited(_guard(() => player.stop()));
    });
  }

  void _cancelAllTimers() {
    for (final timer in _stopTimers.values) {
      timer.cancel();
    }
    _stopTimers.clear();
  }

  Iterable<AudioPlayer> get _allPlayers =>
      _pools.values.expand((pool) => pool);

  /// Runs [action], swallowing errors and disabling the platform on failure.
  Future<void> _guard(Future<void> Function() action) async {
    if (!_platformSupported) return;
    try {
      await action();
    } catch (error) {
      if (!_platformSupported) return;
      _platformSupported = false;
      LoggerService.warning('AudioService disabled, playback unavailable: $error');
    }
  }
}
