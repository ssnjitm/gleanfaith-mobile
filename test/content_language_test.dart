import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/common/entities/content_language.dart';
import 'package:glean_faith_app/core/common/providers/content_language_provider.dart';
import 'package:glean_faith_app/core/common/providers/core_providers.dart';
import 'package:glean_faith_app/core/constants/app_constants.dart';
import 'package:glean_faith_app/core/services/storage_service.dart';
import 'package:glean_faith_app/features/bible_games/domain/entities/bible_game_localization.dart';
import 'package:glean_faith_app/features/bible_games/presentation/providers/bible_game_language_provider.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  /// Seeds a raw stored record, bypassing the notifier entirely.
  void seed(String key, String value) => _store[key] = value;

  String? peek(String key) => _store[key];

  /// Makes every write fail, so the notifier's error path can be exercised.
  bool failWrites = false;

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
    if (failWrites) throw StateError('storage unavailable');
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

  ProviderContainer makeContainer() {
    final created = ProviderContainer(
      overrides: [storageProvider.overrideWithValue(StorageService(storage))],
    );
    addTearDown(created.dispose);
    return created;
  }

  setUp(() {
    storage = _FakeSecureStorage();
    container = makeContainer();
  });

  group('ContentLanguage.fromCode', () {
    test('defaults to English for anything unusable', () {
      expect(ContentLanguage.fromCode(null), ContentLanguage.english);
      expect(ContentLanguage.fromCode(''), ContentLanguage.english);
      expect(ContentLanguage.fromCode('   '), ContentLanguage.english);
      expect(ContentLanguage.fromCode('klingon'), ContentLanguage.english);
      expect(ContentLanguage.fromCode('12'), ContentLanguage.english);
    });

    test('parses every alias a legacy or device value can carry', () {
      for (final alias in ['np', 'NP', 'ne', 'nep', 'Nepali', ' np ']) {
        expect(
          ContentLanguage.fromCode(alias),
          ContentLanguage.nepali,
          reason: alias,
        );
      }
      expect(ContentLanguage.fromCode('en'), ContentLanguage.english);
    });

    test('a regional or scripted locale still resolves', () {
      expect(ContentLanguage.fromCode('ne_NP'), ContentLanguage.nepali);
      expect(ContentLanguage.fromCode('ne-Latn'), ContentLanguage.nepali);
      expect(ContentLanguage.fromCode('en-US'), ContentLanguage.english);
    });

    test('the codes are the ones persisted on the wire', () {
      expect(ContentLanguage.english.code, 'en');
      expect(ContentLanguage.nepali.code, 'np');
    });
  });

  group('contentLanguageProvider', () {
    test('starts in English and persists a new selection', () async {
      final notifier = container.read(contentLanguageProvider.notifier);
      expect(container.read(contentLanguageProvider), ContentLanguage.english);

      await notifier.setLanguage(ContentLanguage.nepali);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(contentLanguageProvider), ContentLanguage.nepali);
      expect(
        storage.peek(AppConstants.contentLanguageKey),
        'np',
        reason: 'the choice must survive the app being closed',
      );
    });

    test('restores the persisted selection on the next launch', () async {
      storage.seed(AppConstants.contentLanguageKey, 'np');
      final restored = makeContainer();
      // Reading instantiates the provider, which restores asynchronously.
      restored.read(contentLanguageProvider);

      await Future<void>.delayed(Duration.zero);

      expect(restored.read(contentLanguageProvider), ContentLanguage.nepali);
    });

    test('an unknown persisted value falls back to English, never blanks',
        () async {
      storage.seed(AppConstants.contentLanguageKey, 'klingon');
      final restored = makeContainer();
      restored.read(contentLanguageProvider);

      await Future<void>.delayed(Duration.zero);

      expect(restored.read(contentLanguageProvider), ContentLanguage.english);
    });

    test('a legacy Nepali preference is adopted, not silently dropped',
        () async {
      storage.seed('verse_of_the_day_language', 'np');
      final restored = makeContainer();
      restored.read(contentLanguageProvider);

      await Future<void>.delayed(Duration.zero);

      expect(restored.read(contentLanguageProvider), ContentLanguage.nepali);
      expect(
        storage.peek(AppConstants.contentLanguageKey),
        'np',
        reason: 'the migration must write the global key so it is not repeated',
      );
    });

    test('a legacy preference that asked for English changes nothing',
        () async {
      storage.seed('daily_quiz_language', 'en');
      final restored = makeContainer();
      restored.read(contentLanguageProvider);

      await Future<void>.delayed(Duration.zero);

      expect(restored.read(contentLanguageProvider), ContentLanguage.english);
      expect(storage.peek(AppConstants.contentLanguageKey), isNull);
    });

    test('the global preference wins over the legacy ones', () async {
      storage.seed(AppConstants.contentLanguageKey, 'en');
      storage.seed('verse_of_the_day_language', 'np');
      final restored = makeContainer();
      restored.read(contentLanguageProvider);

      await Future<void>.delayed(Duration.zero);

      expect(restored.read(contentLanguageProvider), ContentLanguage.english);
    });

    test('a storage failure never breaks the toggle', () async {
      storage.failWrites = true;
      final notifier = container.read(contentLanguageProvider.notifier);

      await notifier.setLanguage(ContentLanguage.nepali);

      expect(
        container.read(contentLanguageProvider),
        ContentLanguage.nepali,
        reason: 'the in-memory switch must apply even if it cannot be saved',
      );
    });

    test('toggle flips between the two languages', () async {
      final notifier = container.read(contentLanguageProvider.notifier);

      await notifier.toggle();
      expect(container.read(contentLanguageProvider), ContentLanguage.nepali);

      await notifier.toggle();
      expect(container.read(contentLanguageProvider), ContentLanguage.english);
    });
  });

  group('bibleGameLanguageProvider', () {
    test('follows the global content language', () async {
      expect(
        container.read(bibleGameLanguageProvider),
        BibleGameLanguage.english,
      );

      await container
          .read(contentLanguageProvider.notifier)
          .setLanguage(ContentLanguage.nepali);

      expect(container.read(bibleGameLanguageProvider), BibleGameLanguage.nepali);
    });
  });
}
