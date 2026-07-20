import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';

class UpcomingQuizCard extends StatelessWidget {
  final String title;
  final DateTime startDateTime;
  final int durationMinutes;
  final int totalQuestions;
  final VoidCallback onTap;

  const UpcomingQuizCard({
    super.key,
    required this.title,
    required this.startDateTime,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _isToday(startDateTime);
    final timeStr = DateFormat('h:mm a').format(startDateTime);
    final dateStr = DateFormat('MMM d').format(startDateTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: AppDimensions.paddingSm),
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.successBg
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isToday ? 'Today' : dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday ? AppColors.success : AppColors.primaryBlue,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalQuestions questions',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${durationMinutes}m',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
