import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_game_localization.dart';

/// The `EN | NP` control shown on the games hub and on every game page.
///
/// Controlled: the caller passes the [value] and an [onChanged] handler, so the
/// same widget works in the hub card and in a page `AppBar` without either
/// place owning the state. Selecting the language that is already active is a
/// no-op — going back to the device language is a separate, explicit action
/// (see the hub's "Game language" card), because tapping the active segment
/// would otherwise look like a broken button.
class BibleGameLanguageToggle extends StatelessWidget {
  final BibleGameLanguage value;
  final ValueChanged<BibleGameLanguage> onChanged;

  /// Inverts the colours for use on a coloured/gradient surface.
  final bool onGradient;

  /// Shrinks the padding and type size for an `AppBar` action.
  final bool compact;

  const BibleGameLanguageToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.onGradient = false,
    this.compact = false,
  });

  static const List<BibleGameLanguage> _options = [
    BibleGameLanguage.english,
    BibleGameLanguage.nepali,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : (isDark ? const Color(0xFF0F172A) : AppColors.bgGray);
    final activeColor = onGradient ? Colors.white : AppColors.primaryBlue;
    final inactiveColor = onGradient
        ? Colors.white70
        : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: onGradient
            ? null
            : Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderLight,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _options)
            _Segment(
              label: _labelFor(option),
              isActive: option == value,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              background: background,
              compact: compact,
              onTap: option == value ? null : () => onChanged(option),
            ),
        ],
      ),
    );
  }

  /// Each segment shows the language in its OWN script, never translated into
  /// the other one — `English` stays `English` and `नेपाली` stays `नेपाली`, so
  /// the control is readable no matter which language is active.
  static String _labelFor(BibleGameLanguage language) {
    return language == BibleGameLanguage.nepali ? 'नेपाली' : 'EN';
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color background;
  final bool compact;
  final VoidCallback? onTap;

  const _Segment({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.background,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: isActive ? background : inactiveColor,
          ),
        ),
      ),
    );
  }
}
