import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../services/logger_service.dart';
import '../entities/content_language.dart';
import 'core_providers.dart';

/// The single global switch for every piece of Bible content in the app.
///
/// Before this provider existed the app carried **four** independent language
/// systems (the Home verse card, the Daily Quiz, the Bible games and the
/// course quiz), each with its own enum, its own storage key and its own
/// toggle. They could disagree — the verse card in Nepali while the games
/// were in English — and a user had to hunt for the right switch on the right
/// screen. Now there is one state, one storage key and one control.
///
/// ## What it does and does not switch
///
/// It switches **Bible content**: verse text, book names, references, the
/// verse of the day, Bible fun facts and quiz question content. It does
/// **not** switch the app's own chrome — buttons, labels, menus and error
/// messages stay in the app's default UI language (English) in both modes.
class ContentLanguageNotifier extends StateNotifier<ContentLanguage> {
  ContentLanguageNotifier(this._ref) : super(ContentLanguage.english) {
    _restore();
  }

  final Ref _ref;

  /// Keys written by the pre-global builds, in priority order.
  ///
  /// They are read once — on the very first launch after the upgrade — so a
  /// user who had already chosen Nepali for the verse card or the games keeps
  /// that choice instead of silently snapping back to English.
  static const List<String> legacyStorageKeys = <String>[
    'verse_of_the_day_language',
    'daily_quiz_language',
    'bible_game_language',
  ];

  /// Reads the persisted selection, migrating a legacy preference if needed.
  Future<void> _restore() async {
    try {
      final storage = _ref.read(storageProvider);

      final stored = await storage.read(AppConstants.contentLanguageKey);
      if (stored != null) {
        if (!mounted) return;
        state = ContentLanguage.fromCode(stored);
        return;
      }

      // No global preference yet — adopt the first legacy one that asked for
      // Nepali, so the upgrade does not silently undo the user's choice.
      for (final key in legacyStorageKeys) {
        final legacy = await storage.read(key);
        if (legacy == null) continue;
        final language = ContentLanguage.fromCode(legacy);
        if (language == ContentLanguage.english) continue;
        if (!mounted) return;
        state = language;
        await storage.write(AppConstants.contentLanguageKey, language.code);
        LoggerService.info(
          'Migrated content language to ${language.code} from "$key"',
        );
        return;
      }
    } catch (error) {
      LoggerService.warning('Could not restore content language: $error');
    }
  }

  /// Selects the language every Bible surface renders in.
  Future<void> setLanguage(ContentLanguage language) async {
    if (language == state) return;
    state = language;
    try {
      await _ref
          .read(storageProvider)
          .write(AppConstants.contentLanguageKey, language.code);
    } catch (error) {
      // The in-memory switch already applied; it just will not be remembered
      // next launch. Never let a storage hiccup break the toggle.
      LoggerService.warning('Could not persist content language: $error');
    }
  }

  /// Flips between the two languages, which is what the `EN | NP` control
  /// sends when it is not controlled by its owner.
  Future<void> toggle() => setLanguage(
        state == ContentLanguage.english
            ? ContentLanguage.nepali
            : ContentLanguage.english,
      );
}

/// The global Bible-content language.
///
/// Read it with `ref.watch(contentLanguageProvider)` and change it with
/// `ref.read(contentLanguageProvider.notifier).setLanguage(...)`.
final contentLanguageProvider =
    StateNotifierProvider<ContentLanguageNotifier, ContentLanguage>((ref) {
  return ContentLanguageNotifier(ref);
});
