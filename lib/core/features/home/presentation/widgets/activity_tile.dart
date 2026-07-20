import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';

class ActivityTile extends StatelessWidget {
  final String quizTitle;
  final int score;
  final int maxScore;
  final int percentageScore;
  final bool passed;
  final String timeAgo;

  const ActivityTile({
    super.key,
    required this.quizTitle,
    required this.score,
    required this.maxScore,
    required this.percentageScore,
    required this.passed,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSm),
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.successBg
                  : AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: passed ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$score/$maxScore · $percentageScore% · $timeAgo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.successBg
                  : AppColors.errorBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              passed ? 'Passed' : 'Failed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: passed ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
