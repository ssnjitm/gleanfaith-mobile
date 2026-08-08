import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

class UpcomingQuizCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const UpcomingQuizCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
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
                    color: AppColors.primaryAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryAmber,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.schedule_rounded, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('h:mm a').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
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
                const Icon(Icons.help_outline_rounded, size: 14),
                const SizedBox(width: 4),
                Text(
                  subtitle,
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
}