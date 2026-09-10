import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import 'crossword_keyboard.dart';

class CrosswordClueBar extends StatelessWidget {
  final String? clueText;
  final int? clueNumber;
  final String? direction;
  final int? answerLength;
  final bool canGoPrev;
  final bool canGoNext;
  final CrosswordInputMode mode;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggleMode;
  final VoidCallback onClueTap;

  const CrosswordClueBar({
    super.key,
    required this.clueText,
    required this.clueNumber,
    required this.direction,
    required this.answerLength,
    required this.canGoPrev,
    required this.canGoNext,
    required this.mode,
    required this.onPrev,
    required this.onNext,
    required this.onToggleMode,
    required this.onClueTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAcross = direction == 'across';
    final dirColor = isAcross ? AppColors.primaryBlue : AppColors.primaryAmber;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _ChevronButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrev,
                enabled: canGoPrev,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClueTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(isAcross, dirColor),
                      const SizedBox(height: 3),
                      Text(
                        clueText ?? 'Tap any box to start solving',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey[200]
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ModeToggle(mode: mode, isDark: isDark, onTap: onToggleMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(bool isAcross, Color dirColor) {
    final label = clueNumber == null
        ? ''
        : '${clueNumber!}${isAcross ? '-Across' : '-Down'}'
              '${answerLength != null ? ' ($answerLength letters)' : ''}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: dirColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: dirColor,
            ),
          ),
        ),
        if (clueText != null) ...[
          const SizedBox(width: 6),
          Icon(
            isAcross ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
            size: 12,
            color: dirColor.withValues(alpha: 0.7),
          ),
        ],
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDark;

  const _ChevronButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? (isDark
                    ? AppColors.primaryBlue.withValues(alpha: 0.16)
                    : AppColors.primaryBlue.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 24,
          color: enabled
              ? (isDark ? Colors.grey[300] : AppColors.textSecondary)
              : (isDark ? Colors.grey[700] : Colors.grey[300]),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final CrosswordInputMode mode;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.mode,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPencil = mode == CrosswordInputMode.pencil;

    return Tooltip(
      message: isPencil ? 'Switch to Pen mode' : 'Switch to Pencil mode',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPencil
                ? (isDark
                      ? AppColors.primaryAmber.withValues(alpha: 0.2)
                      : AppColors.primaryAmber.withValues(alpha: 0.12))
                : (isDark
                      ? AppColors.primaryBlue.withValues(alpha: 0.2)
                      : AppColors.primaryBlue.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPencil
                  ? AppColors.primaryAmber.withValues(alpha: 0.55)
                  : AppColors.primaryBlue.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPencil ? Icons.edit_off_rounded : Icons.edit_rounded,
                size: 15,
                color: isPencil
                    ? AppColors.primaryAmber
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: 5),
              Text(
                isPencil ? 'Pencil' : 'Pen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isPencil
                      ? AppColors.primaryAmber
                      : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
