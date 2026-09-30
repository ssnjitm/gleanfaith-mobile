import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';

/// One selectable option in a [SegmentedCodeToggle].
class SegmentedCodeOption {
  /// Persisted / wire value, e.g. `np`.
  final String value;

  /// Compact label rendered inside the control, e.g. `NP`.
  final String label;

  const SegmentedCodeOption({required this.value, required this.label});
}

/// A compact pill segmented control, e.g. `EN | NP`.
///
/// Shared by the Daily Quiz surfaces and the Home "Verse of the Day" card so the
/// two toggles are guaranteed to look and behave identically. Purely presentational
/// and state-free: the owner reads and writes the selection.
class SegmentedCodeToggle extends StatelessWidget {
  final List<SegmentedCodeOption> options;

  /// The currently selected [SegmentedCodeOption.value].
  final String value;

  /// Called with the newly selected option's `value`.
  final ValueChanged<String> onChanged;

  /// Announced to screen readers, e.g. `Quiz language`.
  final String semanticsLabel;

  /// Renders an inverted (on-gradient) control for hero cards.
  final bool onGradient;

  const SegmentedCodeToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.semanticsLabel,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
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
        children: options.map((option) {
          final selected = option.value == value;
          return Semantics(
            button: true,
            selected: selected,
            label: '$semanticsLabel ${option.label}',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: selected ? null : () => onChanged(option.value),
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
                  option.label,
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
