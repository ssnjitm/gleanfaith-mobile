import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/bible_game_localization.dart';

/// The language the Bible games render in.
///
/// The **device locale is the default**, but the user can override it from the
/// `EN | NP` toggle on the games hub or any game page. The override is
/// persisted under [AppConstants.bibleGameLanguageKey], so the choice survives
/// a restart instead of snapping back to the phone's language.
///
/// `BibleGameLanguage.fromCode` can only ever return one of the two supported
/// languages, so an unusual or missing device locale lands on a fully-populated
/// bundle rather than a blank screen.
class BibleGameLanguageNotifier extends Notifier<BibleGameLanguage> {
  @override
  BibleGameLanguage build() {
    unawaited(_restoreOverride());
    return BibleGameLanguage.fromCode(deviceLanguageCode());
  }

  /// The user picks a language explicitly. `null` clears the override and hands
  /// control back to the device locale.
  Future<void> setLanguage(BibleGameLanguage? language) async {
    state = language ?? BibleGameLanguage.fromCode(deviceLanguageCode());
    try {
      final storage = ref.read(storageProvider);
      if (language == null) {
        await storage.delete(AppConstants.bibleGameLanguageKey);
      } else {
        await storage.write(AppConstants.bibleGameLanguageKey, language.code);
      }
    } catch (error) {
      // A storage failure must not break the toggle — the in-memory switch
      // already applied, it just will not be remembered next launch.
      LoggerService.warning('Could not persist Bible games language: $error');
    }
  }

  /// Toggles between the two languages, which is what the `EN | NP` control
  /// sends. Selecting the language already in use switches to the other one.
  Future<void> toggle() => setLanguage(
        state == BibleGameLanguage.nepali
            ? BibleGameLanguage.english
            : BibleGameLanguage.nepali,
      );

  /// Flips the `EN | NP` control to the language the device itself uses, so the
  /// user gets back to "follow my phone".
  Future<void> useDeviceLanguage() => setLanguage(null);

  /// Whether the games are currently pinned rather than following the device.
  bool get isOverridden => state != BibleGameLanguage.fromCode(deviceLanguageCode());

  Future<void> _restoreOverride() async {
    try {
      final stored = await ref.read(storageProvider).read(
            AppConstants.bibleGameLanguageKey,
          );
      if (stored == null) return;
      final restored = BibleGameLanguage.fromCode(stored);
      if (restored == state) return;
      state = restored;
    } catch (error) {
      LoggerService.warning('Could not read Bible games language: $error');
    }
  }
}

/// The active Bible games language (device locale, or the user's override).
final bibleGameLanguageProvider =
    NotifierProvider<BibleGameLanguageNotifier, BibleGameLanguage>(
  BibleGameLanguageNotifier.new,
);

/// Localised copy for the games, so a widget can just read
/// `ref.watch(bibleGameStringsProvider).higherLowerQuestion`.
final bibleGameStringsProvider = Provider<BibleGameStrings>((ref) {
  return BibleGameStrings.of(ref.watch(bibleGameLanguageProvider));
});

/// The device's preferred language code, or null when it cannot be determined.
String? deviceLanguageCode() {
  final locales = PlatformDispatcher.instance.locales;
  if (locales.isNotEmpty) return locales.first.languageCode;
  final fallback = PlatformDispatcher.instance.locale;
  return fallback == const Locale('und') ? null : fallback.languageCode;
}
