import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/bible_study_entities.dart';
import '../providers/bible_study_provider.dart';

/// Home "Continue Reading" card backed by the remote reading-history endpoint.
class ContinueReadingCard extends ConsumerStatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  ConsumerState<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends ConsumerState<ContinueReadingCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(recentReadingProvider);
      if (state.status == BibleStudyStatus.initial) {
        ref.read(recentReadingProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recentReadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.status == BibleStudyStatus.loading ||
        state.status == BibleStudyStatus.initial) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: ShimmerWidget(
          width: double.infinity,
          height: 86,
          borderRadius: AppDimensions.radiusLg,
        ),
      );
    }

    if (state.status == BibleStudyStatus.error || state.positions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Reading',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.pushNamed(RouteNames.bibleBookmarks),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.bookmarks_outlined, size: 16),
                label: const Text('Bookmarks', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
            itemCount: state.positions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
            itemBuilder: (context, index) => _PositionCard(
              position: state.positions[index],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMd),
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  final ReadingPosition position;

  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => context.pushNamed(
          RouteNames.bibleChapter,
          pathParameters: {
            'book': position.bookName,
            'chapter': position.chapter.toString(),
          },
        ),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.bookName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chapter ${position.chapter}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}