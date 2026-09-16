import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

enum GameOptionState { idle, selected, correct, wrong }

/// Shared card wrapper for game rounds: white (light) / slate (dark) surface
/// with a soft shadow, optional title and a child.
class GameRoundCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const GameRoundCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Score + streak header shown at the top of every game page.
class GameScoreHeader extends StatelessWidget {
  final int score;
  final int streak;
  final String? optional;

  const GameScoreHeader({
    super.key,
    required this.score,
    required this.streak,
    this.optional,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.textWhite),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.textWhite,
          ),
          const SizedBox(width: 4),
          Text(
            'x$streak',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (optional != null) ...[
            const Spacer(),
            Flexible(
              child: Text(
                optional!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable answer chip used by the multiple-choice games. Reflects the
/// answer state (correct / wrong / selected) with explicit colors.
class GameOptionTile extends StatelessWidget {
  final String label;
  final GameOptionState state;
  final VoidCallback? onTap;
  final bool disabled;

  const GameOptionTile({
    super.key,
    required this.label,
    this.state = GameOptionState.idle,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color background = isDark ? const Color(0xFF1E293B) : AppColors.bgCard;
    Color border = isDark ? const Color(0xFF334155) : AppColors.borderLight;
    Color foreground = isDark
        ? const Color(0xFFE2E8F0)
        : AppColors.textSecondary;
    IconData? icon;
    Color? iconColor;

    switch (state) {
      case GameOptionState.correct:
        background = isDark
            ? const Color(0xFF064E3B)
            : AppColors.successBg;
        border = AppColors.success;
        foreground = AppColors.success;
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        break;
      case GameOptionState.wrong:
        background = isDark ? const Color(0xFF7F1D1D) : AppColors.errorBg;
        border = AppColors.error;
        foreground = AppColors.error;
        icon = Icons.cancel_rounded;
        iconColor = AppColors.error;
        break;
      case GameOptionState.selected:
        border = AppColors.primaryBlue;
        background = isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.45)
            : AppColors.primaryBlue.withValues(alpha: 0.08);
        foreground = AppColors.primaryBlue;
        break;
      case GameOptionState.idle:
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: iconColor, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// End-of-game summary card with the score, best streak and replay/home
/// actions.
class GameResultCard extends StatelessWidget {
  final int score;
  final int bestStreak;
  final int totalAnswered;
  final String title;
  final String subtitle;
  final VoidCallback onReplay;

  const GameResultCard({
    super.key,
    required this.score,
    required this.bestStreak,
    required this.totalAnswered,
    required this.title,
    required this.subtitle,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : AppColors.shadowMedium,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.textWhite,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : AppColors.bgGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Correct answers out of $totalAnswered',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: AppColors.primaryAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Best streak: $bestStreak',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: AppButtonStyles.outlinedButton,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: AppButtonStyles.primaryGradientButton,
                      onPressed: onReplay,
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}