import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/bible_games_provider.dart';

/// Reveals one Bible fun fact at a time — a pure "did you know?" card, NOT a
/// game. Cycles through every fact the offline DB can produce. Shown on the
/// Home tab right after the quick actions.
class HomeFunFactsCard extends ConsumerStatefulWidget {
  const HomeFunFactsCard({super.key});

  @override
  ConsumerState<HomeFunFactsCard> createState() => _HomeFunFactsCardState();
}

class _HomeFunFactsCardState extends ConsumerState<HomeFunFactsCard> {
  int _index = 0;

  void _next() {
    final facts = ref.read(bibleFunFactsProvider).value;
    if (facts == null || facts.isEmpty) return;
    setState(() => _index = (_index + 1) % facts.length);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final facts = ref.watch(bibleFunFactsProvider);

    return facts.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: ShimmerWidget(
          width: double.infinity,
          height: 150,
          borderRadius: AppDimensions.radiusLg,
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: AppErrorWidget(
          message: 'Could not load Bible facts.',
          onRetry: () => ref.invalidate(bibleFunFactsProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final index = _index % list.length;
        final fact = list[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAmber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.primaryAmber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bible Fun Facts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${index + 1}/${list.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(index),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fact.prompt,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fact.correct,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryAmber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fact.explain,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _next,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Next fact  ›',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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
}