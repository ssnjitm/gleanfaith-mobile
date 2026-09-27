import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';

/// Selected language for the Daily Quiz (`en` | `np`). Defaults to English and
/// is persisted locally so the choice survives restarts.
class QuizLanguageNotifier extends StateNotifier<QuizLanguage> {
  static const String storageKey = 'daily_quiz_language';

  final Ref _ref;

  QuizLanguageNotifier(this._ref) : super(QuizLanguage.english) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final stored = await _ref.read(storageProvider).read(storageKey);
      if (!mounted || stored == null) return;
      state = QuizLanguage.fromCode(stored);
    } catch (error) {
      LoggerService.warning('Could not restore quiz language: $error');
    }
  }

  Future<void> setLanguage(QuizLanguage language) async {
    if (language == state) return;
    state = language;
    try {
      await _ref.read(storageProvider).write(storageKey, language.code);
    } catch (error) {
      LoggerService.warning('Could not persist quiz language: $error');
    }
  }

  Future<void> toggle() => setLanguage(
    state == QuizLanguage.english ? QuizLanguage.nepali : QuizLanguage.english,
  );
}

final dailyQuizLanguageProvider =
    StateNotifierProvider<QuizLanguageNotifier, QuizLanguage>((ref) {
      return QuizLanguageNotifier(ref);
    });

/// Localised copy for the Daily Quiz surfaces, derived from the selected
/// language so widgets can just read `ref.watch(quizStringsProvider)`.
final quizStringsProvider = Provider<QuizStrings>((ref) {
  return QuizStrings.of(ref.watch(dailyQuizLanguageProvider));
});
