import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';
import '../providers/quiz_provider.dart';
import '../widgets/confetti_burst.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  final QuizResultArgs args;

  const QuizResultPage({super.key, required this.args});

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ringAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();

    // The score was persisted by `completeQuiz`; drop any cached leaderboard so
    // the tab shows the new total/rank instead of the pre-quiz snapshot.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(leaderboardProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.args.result;
    // UI copy is always English; `args.language` only decides the language of
    // backend-supplied content. Keeps the chrome consistent with the play page.
    final strings = QuizStrings.of(QuizLanguage.english);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passed = result?.passed ?? false;
    final percentage = result?.percentageScore ?? 0;
    final stars = _starsFor(percentage);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(RouteNames.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.paddingMd),
                    _buildStars(stars),
                    const SizedBox(height: AppDimensions.lg),
                    _buildRing(percentage, isDark),
                    const SizedBox(height: AppDimensions.lg),
                    Text(
                      passed ? strings.congratulations : strings.niceTry,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: passed
                            ? AppColors.success
                            : AppColors.primaryAmber,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      passed ? strings.passedHint : strings.failedHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    _buildStatsCard(result, strings, isDark),
                    const SizedBox(height: AppDimensions.md),
                    _buildLeaderboardCta(result, strings, isDark),
                    const SizedBox(height: AppDimensions.xl),
                    _buildPrimaryButton(context, strings.backToHome),
                    const SizedBox(height: AppDimensions.paddingSm),
                    _buildSecondaryButton(context, strings.moreQuizzes),
                  ],
                ),
              ),
              if (passed)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiBurst(
                      particleCount: 110,
                      duration: Duration(milliseconds: 2200),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the running total and rank so the user can see the score they
  /// actually added, plus a shortcut into the leaderboard.
  Widget _buildLeaderboardCta(
    QuizResult? result,
    QuizStrings strings,
    bool isDark,
  ) {
    final totalPoints = result?.totalPoints;
    final rank = result?.rank;
    if (totalPoints == null && rank == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: () => _openLeaderboard(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: AppDimensions.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.scoreAdded,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPoints == null
                        ? strings.yourRank
                        : '$totalPoints ${strings.points}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (rank != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            const SizedBox(width: AppDimensions.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  /// The leaderboard is not a bottom-nav tab — it is pushed from the quiz tab's
  /// top-bar icon and from the score card on this page.
  void _openLeaderboard() {
    context.push(RouteNames.leaderboard);
  }

  Widget _buildPrimaryButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: () => context.go(RouteNames.home),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.home);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: filled
              ? const Icon(
                  Icons.star_rounded,
                  color: AppColors.primaryAmber,
                  size: 40,
                )
              : Icon(
                  Icons.star_border_rounded,
                  color: Colors.grey.withValues(alpha: 0.3),
                  size: 40,
                ),
        );
      }),
    );
  }

  int _starsFor(int percentage) {
    if (percentage >= 80) return 3;
    if (percentage >= 50) return 2;
    if (percentage >= 20) return 1;
    return 0;
  }

  Widget _buildRing(int percentage, bool isDark) {
    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, _) {
        return SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _ResultRingPainter(
              progress: _ringAnimation.value,
              passed: percentage >= 50,
              color: percentage >= 50 ? AppColors.success : AppColors.error,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCountUp(percentage),
                  const SizedBox(height: 4),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.grey[400] : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountUp(int target) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '${value.round()}%',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            height: 1,
            color: target >= 50 ? AppColors.success : AppColors.error,
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(QuizResult? result, QuizStrings strings, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BuildStat(
                icon: Icons.check_circle_rounded,
                label: strings.correctLabel,
                value: '${result?.correctAnswers ?? 0}',
                color: AppColors.success,
                isDark: isDark,
              ),
              _BuildStat(
                icon: Icons.cancel_rounded,
                label: strings.wrongLabel,
                value: '${result?.wrongAnswers ?? 0}',
                color: AppColors.error,
                isDark: isDark,
              ),
              _BuildStat(
                icon: Icons.emoji_events_rounded,
                label: strings.points,
                value: '${result?.score ?? 0}',
                color: AppColors.primaryAmber,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                result?.passed == true
                    ? Icons.emoji_events_rounded
                    : Icons.trending_up_rounded,
                color: result?.passed == true
                    ? AppColors.primaryAmber
                    : AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                result?.passed == true
                    ? '${result?.score ?? 0} / ${result?.maxPossibleScore ?? 0} ${strings.pointsEarned}'
                    : '${result?.totalQuestions ?? 0} ${strings.questionsAttempted}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _BuildStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRingPainter extends CustomPainter {
  final double progress;
  final bool passed;
  final Color color;

  _ResultRingPainter({
    required this.progress,
    required this.passed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    const stroke = 12.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: passed
            ? [AppColors.successLight, AppColors.success]
            : [AppColors.errorLight, AppColors.error],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ResultRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
