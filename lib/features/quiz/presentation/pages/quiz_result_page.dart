import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/quiz_entities.dart';

class QuizResultPage extends ConsumerWidget {
  final QuizResult? result;

  const QuizResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passed = result?.passed ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed
                      ? AppColors.successBg
                      : AppColors.errorBg,
                ),
                child: Icon(
                  passed ? Icons.check_rounded : Icons.cancel_rounded,
                  size: 60,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              Text(
                passed ? 'Congratulations!' : 'Keep Learning!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                passed
                    ? 'You passed the quiz. Great job!'
                    : 'Don\'t worry, try again next time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${result?.percentageScore ?? 0}%',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      '${result?.score ?? 0} / ${result?.maxPossibleScore ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (result?.percentageScore ?? 0) / 100,
                        minHeight: 10,
                        backgroundColor:
                            isDark ? const Color(0xFF334155) : AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation(
                          passed ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      children: [
                        _BuildStat(
                          icon: Icons.check_circle_rounded,
                          label: 'Correct',
                          value: '${result?.correctAnswers ?? 0}',
                          color: AppColors.success,
                        ),
                        _BuildStat(
                          icon: Icons.cancel_rounded,
                          label: 'Wrong',
                          value: '${result?.wrongAnswers ?? 0}',
                          color: AppColors.error,
                        ),
                        _BuildStat(
                          icon: Icons.help_rounded,
                          label: 'Total',
                          value: '${result?.totalQuestions ?? 0}',
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(RouteNames.home),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BuildStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}