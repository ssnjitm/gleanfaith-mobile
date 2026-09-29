import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/common/providers/core_providers.dart';
import 'package:glean_faith_app/core/services/storage_service.dart';
import 'package:glean_faith_app/features/bible_games/domain/entities/game_lives.dart';
import 'package:glean_faith_app/features/bible_games/presentation/providers/game_lives_provider.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  /// Seeds a raw stored record, bypassing the notifier entirely.
  void seed(String key, String value) => _store[key] = value;

  String? peek(String key) => _store[key];

  @override
  Future<void> write({
    required String key,
    String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    return _store.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    LinuxOptions? lOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = _FakeSecureStorage();
    container = ProviderContainer(
      overrides: [storageProvider.overrideWithValue(StorageService(storage))],
    );
    addTearDown(container.dispose);
  });

  /// The stored record, read back the way a cold start would.
  GameLives stored(BibleGameKind kind) {
    final raw = storage.peek(kind.storageKey);
    if (raw == null) return const GameLives.full();
    final decoded = jsonDecode(raw);
    return GameLives.fromJson(decoded is Map<String, dynamic> ? decoded : null);
  }

  group('gameLivesProvider', () {
    test('a fresh install reads full lives for every game', () async {
      final lives = await container.read(gameLivesProvider.future);
      expect(lives.length, BibleGameKind.values.length);
      for (final entry in lives.entries) {
        expect(entry.value.lives, GameLives.maxLives, reason: '${entry.key}');
        expect(entry.value.isCooldownActiveAt(DateTime.now()), isFalse);
      }
    });

    test('the third mistake is persisted, not just held in memory', () async {
      final notifier = container.read(gameLivesProvider.notifier);
      notifier.registerMistake(BibleGameKind.guessBook);
      notifier.registerMistake(BibleGameKind.guessBook);
      notifier.registerMistake(BibleGameKind.guessBook);

      // Yield so the unawaited writes land.
      await Future<void>.delayed(Duration.zero);

      final saved = stored(BibleGameKind.guessBook);
      expect(saved.lives, 0);
      expect(
        saved.isCooldownActiveAt(DateTime.now()),
        isTrue,
        reason: 'the lock must survive the app being closed',
      );
    });

    test('losing all lives in one game leaves the other three playable',
        () async {
      final notifier = container.read(gameLivesProvider.notifier);
      for (var i = 0; i < GameLives.maxLives; i++) {
        notifier.registerMistake(BibleGameKind.higherLower);
      }
      await Future<void>.delayed(Duration.zero);

      final now = DateTime.now();
      expect(
        notifier.livesOf(BibleGameKind.higherLower).isCooldownActiveAt(now),
        isTrue,
      );
      for (final kind in BibleGameKind.values) {
        if (kind == BibleGameKind.higherLower) continue;
        expect(
          notifier.livesOf(kind).isCooldownActiveAt(now),
          isFalse,
          reason: 'a per-game pool must not lock the whole section',
        );
      }
    });

    test('a cooldown that lapsed while the app was closed refills on load',
        () async {
      // Exactly what a backgrounded/killed app leaves behind: a valid record
      // whose window has already passed.
      storage.seed(
        BibleGameKind.bookOrder.storageKey,
        jsonEncode({
          'lives': 0,
          'cooldownUntil': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
        }),
      );

      final lives = await container.read(gameLivesProvider.future);
      expect(lives[BibleGameKind.bookOrder]!.lives, GameLives.maxLives);
      expect(lives[BibleGameKind.bookOrder]!.cooldownUntil, isNull);
    });

    test('a corrupt record refills rather than locking the player out',
        () async {
      storage.seed(BibleGameKind.findChapter.storageKey, 'not json at all');

      final lives = await container.read(gameLivesProvider.future);
      expect(
        lives[BibleGameKind.findChapter]!.lives,
        GameLives.maxLives,
        reason: 'unreadable storage must never be a punishment',
      );
    });

    test('a cooldown still in the future is honoured on load', () async {
      final until = DateTime.now().add(const Duration(hours: 1));
      storage.seed(
        BibleGameKind.findChapter.storageKey,
        jsonEncode({'lives': 0, 'cooldownUntil': until.toIso8601String()}),
      );

      final lives = await container.read(gameLivesProvider.future);
      expect(lives[BibleGameKind.findChapter]!.lives, 0);
      expect(
        lives[BibleGameKind.findChapter]!.isCooldownActiveAt(DateTime.now()),
        isTrue,
      );
    });

    test('settling with nothing to settle does not republish', () async {
      await container.read(gameLivesProvider.future);
      final before = container.read(gameLivesProvider);
      container.read(gameLivesProvider.notifier).settleExpiredCooldowns();
      await Future<void>.delayed(Duration.zero);
      expect(
        identical(container.read(gameLivesProvider), before),
        isTrue,
        reason: 'the once-a-minute settle must be free when no lock lapses',
      );
    });

    test('a perfect-round refund is persisted', () async {
      final notifier = container.read(gameLivesProvider.notifier);
      notifier.registerMistake(BibleGameKind.guessBook);
      await Future<void>.delayed(Duration.zero);
      expect(stored(BibleGameKind.guessBook).lives, 2);

      // A new, clean round, then a perfect finish.
      notifier.beginRound(BibleGameKind.guessBook);
      notifier.rewardPerfectRound(BibleGameKind.guessBook);
      await Future<void>.delayed(Duration.zero);

      expect(
        stored(BibleGameKind.guessBook).lives,
        3,
        reason: 'an earned life must not evaporate on the next cold start',
      );
    });

    test('beginRound alone is not written to storage', () async {
      await container.read(gameLivesProvider.future);
      container.read(gameLivesProvider.notifier).beginRound(
            BibleGameKind.guessBook,
          );
      await Future<void>.delayed(Duration.zero);
      expect(
        storage.peek(BibleGameKind.guessBook.storageKey),
        isNull,
        reason: 'the per-round mistake counter is not durable state',
      );
    });

    test('a mistake registered before the first read is not lost', () async {
      // No `await` first: the notifier is mid-read of four storage keys.
      final notifier = container.read(gameLivesProvider.notifier);
      notifier.registerMistake(BibleGameKind.guessBook);

      final lives = await container.read(gameLivesProvider.future);
      expect(
        lives[BibleGameKind.guessBook]!.lives,
        GameLives.maxLives - 1,
        reason: 'an early mutation must not be overwritten by the read',
      );
      await Future<void>.delayed(Duration.zero);
      expect(stored(BibleGameKind.guessBook).lives, GameLives.maxLives - 1);
    });
  });
}
