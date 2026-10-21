import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/entities/content_language.dart';
import '../../../../core/common/providers/content_language_provider.dart';
import '../../../../core/common/widgets/segmented_code_toggle.dart';
import '../../domain/entities/quiz_entities.dart';
import '../providers/quiz_language_provider.dart';

/// Compact `EN | NP` segmented control used by the quiz surfaces.
///
/// It is a **mirror of the global content language**: the quiz no longer owns
/// a language preference of its own, so tapping this control switches the
/// whole app's Bible content — the verse of the day, the reader, the games and
/// the quiz — at once. The persisted state lives in
/// `contentLanguageProvider`.
///
/// Leave [onChanged] null to drive the global preference. Pass both [value]
/// and [onChanged] to control it locally — the play pages do this so a
/// language switch mid-quiz re-renders the current question immediately without
/// waiting on storage.
///
/// The visuals live in the shared [SegmentedCodeToggle] so this control and
/// the Home "Verse of the Day" language toggle can never drift apart.
class QuizLanguageToggle extends ConsumerWidget {
  /// Renders a light control for regular surfaces or an inverted (on-gradient)
  /// one for the hero card.
  final bool onGradient;

  /// Controlled mode: the currently selected language.
  final QuizLanguage? value;

  /// Controlled mode: called with the newly selected language.
  final ValueChanged<QuizLanguage>? onChanged;

  const QuizLanguageToggle({
    super.key,
    this.onGradient = false,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isControlled = value != null && onChanged != null;
    final QuizLanguage language = value ?? ref.watch(dailyQuizLanguageProvider);

    void select(QuizLanguage option) {
      if (isControlled) {
        onChanged!(option);
        return;
      }
      ref.read(contentLanguageProvider.notifier).setLanguage(
            option == QuizLanguage.nepali
                ? ContentLanguage.nepali
                : ContentLanguage.english,
          );
    }

    return SegmentedCodeToggle(
      semanticsLabel: 'Content language',
      onGradient: onGradient,
      value: language.code,
      options: const [
        SegmentedCodeOption(value: 'en', label: 'EN'),
        SegmentedCodeOption(value: 'np', label: 'NP'),
      ],
      onChanged: (code) => select(QuizLanguage.fromCode(code)),
    );
  }
}
