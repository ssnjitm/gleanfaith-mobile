import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/entities/content_language.dart';
import '../../../../core/common/providers/content_language_provider.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';

/// The language the **quiz content** is rendered in.
///
/// It is not a separate preference: the quiz is one of the Bible-content
/// surfaces the global `EN | NP` control switches, so this provider simply
/// mirrors [contentLanguageProvider] into the quiz feature's own enum.
///
/// The quiz used to own a persisted `daily_quiz_language` preference with its
/// own toggle, which could disagree with the verse card. That toggle is gone —
/// the global control in Settings (and the mirrors on the quiz surfaces) now
/// drives both.
final dailyQuizLanguageProvider = Provider<QuizLanguage>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return language == ContentLanguage.nepali
      ? QuizLanguage.nepali
      : QuizLanguage.english;
});

/// Copy for the quiz surfaces.
///
/// The app's own chrome is **always** English, in both modes: a half
/// translated UI reads as a bug, so the toggle only ever switches *content*
/// (question text, options, explanations) — never the app's own labels.
final quizStringsProvider = Provider<QuizStrings>((ref) {
  return QuizStrings.of(QuizLanguage.english);
});
