import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import 'shimmer_widget.dart';

class StatsCardShimmer extends StatelessWidget {
  const StatsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF1A1A2E)]
              : [AppColors.primaryBlue, const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          children: [
            Row(
              children: [
                const ShimmerWidget(
                  width: 48,
                  height: 48,
                  borderRadius: AppDimensions.radiusLg,
                  baseColor: Color(0x33FFFFFF),
                  highlightColor: Color(0x55FFFFFF),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerWidget(
                        width: 100,
                        height: 18,
                        borderRadius: 4,
                        baseColor: Color(0x33FFFFFF),
                        highlightColor: Color(0x55FFFFFF),
                      ),
                      const SizedBox(height: 6),
                      ShimmerWidget(
                        width: 80,
                        height: 12,
                        borderRadius: 4,
                        baseColor: const Color(0x22FFFFFF),
                        highlightColor: const Color(0x33FFFFFF),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const ShimmerWidget(
                      width: 60,
                      height: 20,
                      borderRadius: 4,
                      baseColor: Color(0x33FFFFFF),
                      highlightColor: Color(0x55FFFFFF),
                    ),
                    const SizedBox(height: 4),
                    ShimmerWidget(
                      width: 50,
                      height: 10,
                      borderRadius: 4,
                      baseColor: const Color(0x22FFFFFF),
                      highlightColor: const Color(0x33FFFFFF),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            ShimmerWidget(
              width: double.infinity,
              height: 8,
              borderRadius: 4,
              baseColor: const Color(0x22FFFFFF),
              highlightColor: const Color(0x33FFFFFF),
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerWidget(
                  width: 90,
                  height: 10,
                  borderRadius: 4,
                  baseColor: const Color(0x22FFFFFF),
                  highlightColor: const Color(0x33FFFFFF),
                ),
                ShimmerWidget(
                  width: 100,
                  height: 10,
                  borderRadius: 4,
                  baseColor: const Color(0x22FFFFFF),
                  highlightColor: const Color(0x33FFFFFF),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Row(
              children: const [
                Expanded(
                  child: _StatColumnShimmer(
                    baseColor: Color(0x22FFFFFF),
                    highlightColor: Color(0x33FFFFFF),
                  ),
                ),
                Expanded(
                  child: _StatColumnShimmer(
                    baseColor: Color(0x22FFFFFF),
                    highlightColor: Color(0x33FFFFFF),
                  ),
                ),
                Expanded(
                  child: _StatColumnShimmer(
                    baseColor: Color(0x22FFFFFF),
                    highlightColor: Color(0x33FFFFFF),
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

class _StatColumnShimmer extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const _StatColumnShimmer({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerWidget(
          width: 20,
          height: 20,
          borderRadius: 10,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 4),
        ShimmerWidget(
          width: 30,
          height: 14,
          borderRadius: 4,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 2),
        ShimmerWidget(
          width: 36,
          height: 10,
          borderRadius: 4,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
      ],
    );
  }
}

class UpcomingQuizCardShimmer extends StatelessWidget {
  const UpcomingQuizCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: AppDimensions.paddingSm),
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
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
          Row(
            children: [
              ShimmerWidget(
                width: 56,
                height: 22,
                borderRadius: 6,
                baseColor: isDark ? const Color(0xFF334155) : null,
                highlightColor: isDark ? const Color(0xFF475569) : null,
              ),
              const Spacer(),
              ShimmerWidget(
                width: 60,
                height: 12,
                borderRadius: 4,
                baseColor: isDark ? const Color(0xFF334155) : null,
                highlightColor: isDark ? const Color(0xFF475569) : null,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          ShimmerWidget(
            width: 160,
            height: 14,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const Spacer(),
          Row(
            children: [
              ShimmerWidget(
                width: 90,
                height: 12,
                borderRadius: 4,
                baseColor: isDark ? const Color(0xFF334155) : null,
                highlightColor: isDark ? const Color(0xFF475569) : null,
              ),
              const SizedBox(width: AppDimensions.sm),
              ShimmerWidget(
                width: 30,
                height: 12,
                borderRadius: 4,
                baseColor: isDark ? const Color(0xFF334155) : null,
                highlightColor: isDark ? const Color(0xFF475569) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityTileShimmer extends StatelessWidget {
  const ActivityTileShimmer({super.key});

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
          ShimmerWidget(
            width: 40,
            height: 40,
            borderRadius: AppDimensions.radiusMd,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: 180,
                  height: 10,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          ShimmerWidget(
            width: 52,
            height: 24,
            borderRadius: 6,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
        ],
      ),
    );
  }
}

class QuickActionGridShimmer extends StatelessWidget {
  const QuickActionGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMd,
                  horizontal: AppDimensions.paddingSm,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    ShimmerCircle(
                      size: 44,
                      baseColor:
                          isDark ? const Color(0xFF334155) : null,
                      highlightColor:
                          isDark ? const Color(0xFF475569) : null,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    ShimmerWidget(
                      width: 50,
                      height: 10,
                      borderRadius: 4,
                      baseColor:
                          isDark ? const Color(0xFF334155) : null,
                      highlightColor:
                          isDark ? const Color(0xFF475569) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PromoCarouselShimmer extends StatelessWidget {
  const PromoCarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: ShimmerWidget(
        width: double.infinity,
        height: 190,
        borderRadius: AppDimensions.radiusXl,
      ),
    );
  }
}

class VerseOfTheDayShimmer extends StatelessWidget {
  const VerseOfTheDayShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerCard(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: 44,
            height: 44,
            borderRadius: AppDimensions.radiusLg,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 110,
                  height: 12,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: AppDimensions.xs),
                ShimmerWidget(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: AppDimensions.xs),
                ShimmerWidget(
                  width: 220,
                  height: 14,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                ShimmerWidget(
                  width: 90,
                  height: 12,
                  borderRadius: 4,
                  baseColor: isDark ? const Color(0xFF334155) : null,
                  highlightColor: isDark ? const Color(0xFF475569) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryCardShimmer extends StatelessWidget {
  const LibraryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          ShimmerWidget(
            width: double.infinity,
            height: 112,
            borderRadius: AppDimensions.radiusLg,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 120,
                    height: 14,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ShimmerWidget(
                        width: 50,
                        height: 18,
                        borderRadius: 20,
                        baseColor:
                            isDark ? const Color(0xFF334155) : null,
                        highlightColor:
                            isDark ? const Color(0xFF475569) : null,
                      ),
                      const Spacer(),
                      ShimmerWidget(
                        width: 40,
                        height: 10,
                        borderRadius: 4,
                        baseColor:
                            isDark ? const Color(0xFF334155) : null,
                        highlightColor:
                            isDark ? const Color(0xFF475569) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizCardShimmer extends StatelessWidget {
  const QuizCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        0,
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
      ),
      child: Container(
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
            ShimmerWidget(
              width: 48,
              height: 48,
              borderRadius: AppDimensions.radiusLg,
              baseColor: isDark ? const Color(0xFF334155) : null,
              highlightColor: isDark ? const Color(0xFF475569) : null,
            ),
            const SizedBox(width: AppDimensions.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: double.infinity,
                    height: 15,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  ShimmerWidget(
                    width: 130,
                    height: 12,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      ShimmerWidget(
                        width: 100,
                        height: 12,
                        borderRadius: 4,
                        baseColor: isDark
                            ? const Color(0xFF334155)
                            : null,
                        highlightColor: isDark
                            ? const Color(0xFF475569)
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      ShimmerWidget(
                        width: 30,
                        height: 12,
                        borderRadius: 4,
                        baseColor: isDark
                            ? const Color(0xFF334155)
                            : null,
                        highlightColor: isDark
                            ? const Color(0xFF475569)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            ShimmerWidget(
              width: 64,
              height: 24,
              borderRadius: 6,
              baseColor: isDark ? const Color(0xFF334155) : null,
              highlightColor: isDark ? const Color(0xFF475569) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          ShimmerWidget(
            width: double.infinity,
            height: 110,
            borderRadius: AppDimensions.radiusLg,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 100,
                    height: 14,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ShimmerWidget(
                        width: 70,
                        height: 10,
                        borderRadius: 4,
                        baseColor:
                            isDark ? const Color(0xFF334155) : null,
                        highlightColor:
                            isDark ? const Color(0xFF475569) : null,
                      ),
                      const SizedBox(width: 6),
                      ShimmerWidget(
                        width: 30,
                        height: 10,
                        borderRadius: 4,
                        baseColor:
                            isDark ? const Color(0xFF334155) : null,
                        highlightColor:
                            isDark ? const Color(0xFF475569) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  ShimmerWidget(
                    width: double.infinity,
                    height: 6,
                    borderRadius: 3,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardEntryShimmer extends StatelessWidget {
  const LeaderboardEntryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.sm,
        AppDimensions.paddingMd,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.sm + 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          ShimmerWidget(
            width: 24,
            height: 15,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.sm),
          ShimmerCircle(
            size: 36,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: ShimmerWidget(
              width: 140,
              height: 15,
              borderRadius: 4,
              baseColor: isDark ? const Color(0xFF334155) : null,
              highlightColor: isDark ? const Color(0xFF475569) : null,
            ),
          ),
          ShimmerWidget(
            width: 40,
            height: 15,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
        ],
      ),
    );
  }
}

class NotificationTileShimmer extends StatelessWidget {
  const NotificationTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(
        left: AppDimensions.paddingMd,
        right: AppDimensions.paddingMd,
        bottom: AppDimensions.paddingSm,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: 40,
            height: 40,
            borderRadius: AppDimensions.radiusMd,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: double.infinity,
                  height: 15,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: double.infinity,
                  height: 12,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: 4),
                ShimmerWidget(
                  width: 160,
                  height: 12,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: 60,
                  height: 10,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          ShimmerCircle(
            size: 88,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          ShimmerWidget(
            width: 140,
            height: 22,
            borderRadius: 6,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: 8),
          ShimmerWidget(
            width: 120,
            height: 14,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: 4),
          ShimmerWidget(
            width: 100,
            height: 12,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
        ],
      ),
    );
  }
}

class CrosswordPuzzleCardShimmer extends StatelessWidget {
  const CrosswordPuzzleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.xs,
      ),
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
          ShimmerWidget(
            width: 48,
            height: 48,
            borderRadius: AppDimensions.radiusLg,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 160,
                  height: 14,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: 100,
                  height: 10,
                  borderRadius: 4,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                ShimmerWidget(
                  width: double.infinity,
                  height: 6,
                  borderRadius: 3,
                  baseColor:
                      isDark ? const Color(0xFF334155) : null,
                  highlightColor:
                      isDark ? const Color(0xFF475569) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BibleBookListShimmer extends StatelessWidget {
  const BibleBookListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      itemCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.paddingSm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd),
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingMd - 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color:
                isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            ShimmerWidget(
              width: 36,
              height: 36,
              borderRadius: AppDimensions.radiusMd,
              baseColor: isDark ? const Color(0xFF334155) : null,
              highlightColor: isDark ? const Color(0xFF475569) : null,
            ),
            const SizedBox(width: AppDimensions.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 120 + (index * 10.0).clamp(0, 80),
                    height: 14,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    width: 60,
                    height: 10,
                    borderRadius: 4,
                    baseColor:
                        isDark ? const Color(0xFF334155) : null,
                    highlightColor:
                        isDark ? const Color(0xFF475569) : null,
                  ),
                ],
              ),
            ),
            ShimmerWidget(
              width: 20,
              height: 20,
              borderRadius: 10,
              baseColor: isDark ? const Color(0xFF334155) : null,
              highlightColor: isDark ? const Color(0xFF475569) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class VerseListShimmer extends StatelessWidget {
  const VerseListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      itemCount: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.paddingMd),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd),
      itemBuilder: (_, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: 24,
            height: 14,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: 6),
          ShimmerWidget(
            width: double.infinity,
            height: 12,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: 4),
          ShimmerWidget(
            width: double.infinity,
            height: 12,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
          const SizedBox(height: 4),
          ShimmerWidget(
            width: 200,
            height: 12,
            borderRadius: 4,
            baseColor: isDark ? const Color(0xFF334155) : null,
            highlightColor: isDark ? const Color(0xFF475569) : null,
          ),
        ],
      ),
    );
  }
}

class ChapterGridShimmer extends StatelessWidget {
  const ChapterGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      itemCount: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) => ShimmerWidget(
        width: double.infinity,
        height: double.infinity,
        borderRadius: AppDimensions.radiusMd,
        baseColor: isDark ? const Color(0xFF334155) : null,
        highlightColor: isDark ? const Color(0xFF475569) : null,
      ),
    );
  }
}
