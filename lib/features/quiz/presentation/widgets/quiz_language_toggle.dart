import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/segmented_code_toggle.dart';
import '../../domain/entities/quiz_entities.dart';
import '../providers/quiz_language_provider.dart';

/// Compact `EN | NP` segmented control used by the Daily Quiz surfaces.
///
/// The Daily Quiz starts in English; tapping the other code switches the whole
/// quiz (question text plus UI copy) to that language.
///
/// Leave [onChanged] null to drive the globally persisted preference. Pass both
/// [value] and [onChanged] to control it locally — the play page does this so a
/// language switch mid-quiz re-renders the current question immediately without
/// waiting on storage.
///
/// The visuals live in the shared [SegmentedCodeToggle] so this control and the
/// Home "Verse of the Day" language toggle can never drift apart.
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
      } else {
        ref.read(dailyQuizLanguageProvider.notifier).setLanguage(option);
      }
    }

    return SegmentedCodeToggle(
      semanticsLabel: 'Quiz language',
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
