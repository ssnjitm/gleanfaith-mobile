import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/verse_of_the_day.dart';

/// Selected language for the Home "Verse of the Day" card.
///
/// Separate from the Daily Quiz's `dailyQuizLanguageProvider` on purpose: the
/// quiz preference is quiz-specific, and coupling the two would silently
/// translate one surface because of the other. This one only ever changes the
/// *verse text* — the app's own labels stay English in both modes.
class VerseLanguageNotifier extends StateNotifier<VerseLanguage> {
  static const String storageKey = 'verse_of_the_day_language';

  final Ref _ref;

  VerseLanguageNotifier(this._ref) : super(VerseLanguage.english) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final stored = await _ref.read(storageProvider).read(storageKey);
      if (!mounted || stored == null) return;
      state = VerseLanguage.fromCode(stored);
    } catch (error) {
      LoggerService.warning('Could not restore verse language: $error');
    }
  }

  Future<void> setLanguage(VerseLanguage language) async {
    if (language == state) return;
    state = language;
    try {
      await _ref.read(storageProvider).write(storageKey, language.code);
    } catch (error) {
      LoggerService.warning('Could not persist verse language: $error');
    }
  }

  Future<void> toggle() => setLanguage(
    state == VerseLanguage.english
        ? VerseLanguage.nepali
        : VerseLanguage.english,
  );
}

final verseLanguageProvider =
    StateNotifierProvider<VerseLanguageNotifier, VerseLanguage>((ref) {
      return VerseLanguageNotifier(ref);
    });
