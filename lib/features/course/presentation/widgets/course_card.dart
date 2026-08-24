import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_entities.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(isDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingSm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.grey[500]
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${course.totalLessons} lessons',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : AppColors.textMuted,
                            ),
                          ),
                          if (course.estimatedDurationMinutes != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${course.estimatedDurationMinutes}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      _buildProgressRow(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.radiusLg - 1),
        topRight: Radius.circular(AppDimensions.radiusLg - 1),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (course.thumbnail != null && course.thumbnail!.isNotEmpty)
              Image.network(
                course.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _thumbnailFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _thumbnailFallback(loading: true);
                },
              )
            else
              _thumbnailFallback(),
            Positioned(
              top: AppDimensions.sm,
              left: AppDimensions.sm,
              child: _difficultyChip(),
            ),
            Positioned(
              top: AppDimensions.sm,
              right: AppDimensions.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.warning,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${course.points} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailFallback({bool loading = false}) {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.auto_stories_rounded,
              size: 36,
              color: AppColors.primaryBlue.withValues(alpha: 0.45),
            ),
    );
  }

  Widget _difficultyChip() {
    final color = _difficultyColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        course.difficulty.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color get _difficultyColor {
    switch (course.difficulty) {
      case 'hard':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _buildProgressRow(bool isDark) {
    final progress = course.userProgress;

    if (progress == null) {
      return Row(
        children: [
          const Text(
            'Start course',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_rounded,
            size: 13,
            color: isDark ? Colors.grey[500] : AppColors.textLight,
          ),
        ],
      );
    }

    if (progress.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 13),
            SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: course.progressFraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor:
                (isDark ? Colors.grey[700] : AppColors.borderLight)
                    ?.withValues(alpha: 0.6),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryAmber),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${progress.completedItems}/${course.totalItems} done',
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
            const Spacer(),
            const Text(
              'Continue',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

