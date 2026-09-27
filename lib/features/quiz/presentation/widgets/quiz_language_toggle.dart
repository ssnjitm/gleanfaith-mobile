import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
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
    final language = value ?? ref.watch(dailyQuizLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void select(QuizLanguage option) {
      if (isControlled) {
        onChanged!(option);
      } else {
        ref.read(dailyQuizLanguageProvider.notifier).setLanguage(option);
      }
    }

    final trackColor = onGradient
        ? Colors.white.withValues(alpha: 0.2)
        : (isDark ? const Color(0xFF1E293B) : AppColors.bgCard);
    final borderColor = onGradient
        ? Colors.white24
        : (isDark ? const Color(0xFF334155) : AppColors.borderLight);
    final inactiveColor = onGradient
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textMuted);
    final activeBackground = onGradient ? Colors.white : AppColors.primaryBlue;
    final activeForeground = onGradient ? AppColors.primaryBlue : Colors.white;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: QuizLanguage.values.map((option) {
          final selected = option == language;
          return Semantics(
            button: true,
            selected: selected,
            label: 'Quiz language ${option.shortLabel}',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: selected ? null : () => select(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? activeBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  option.shortLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? activeForeground : inactiveColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
