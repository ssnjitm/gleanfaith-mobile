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
class QuizLanguageToggle extends ConsumerWidget {
  /// Renders a light control for regular surfaces or an inverted (on-gradient)
  /// one for the hero card.
  final bool onGradient;

  const QuizLanguageToggle({super.key, this.onGradient = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(dailyQuizLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              onTap: () => ref
                  .read(dailyQuizLanguageProvider.notifier)
                  .setLanguage(option),
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
