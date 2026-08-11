import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../providers/crosspuzzle_provider.dart';

class CrossPuzzleMyPuzzlesPage extends ConsumerStatefulWidget {
  const CrossPuzzleMyPuzzlesPage({super.key});

  @override
  ConsumerState<CrossPuzzleMyPuzzlesPage> createState() =>
      _CrossPuzzleMyPuzzlesPageState();
}

class _CrossPuzzleMyPuzzlesPageState extends ConsumerState<CrossPuzzleMyPuzzlesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crossPuzzleProvider.notifier).loadMyProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crossPuzzleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Puzzles')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(crossPuzzleProvider.notifier).loadMyProgress(),
        child: _buildBody(context, state, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CrossPuzzleState state, bool isDark) {
    final items = state.myProgress;

    if (state.status == CrossPuzzleStatus.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          const SizedBox(height: AppDimensions.xl),
          const Icon(Icons.collections_bookmark_outlined,
              size: 56, color: AppColors.textLight),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            state.message ?? 'No puzzles started yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.crossPuzzle),
            icon: const Icon(Icons.grid_4x4_rounded),
            label: const Text('Browse Puzzles'),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.paddingSm),
      itemBuilder: (context, index) => _ProgressCard(item: items[index], isDark: isDark),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CrossPuzzleWithProgress item;
  final bool isDark;

  const _ProgressCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = item.progress;
    final puzzle = item.puzzle;
    final isCompleted = progress.isCompleted;
    final color = isCompleted ? AppColors.success : AppColors.primaryAmber;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => context.push(
          RouteNames.crossPuzzlePlay,
          extra: {
            'id': puzzle.id,
            'title': puzzle.title,
          },
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
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
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.edit_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(progress),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(CrossPuzzleProgress progress) {
    if (progress.isCompleted) {
      return 'Solved at ${progress.accuracy}% · ${progress.pointsEarned} XP';
    }
    final filled = progress.gridState.length;
    return 'In progress · $filled filled · ${_fmtTime(progress.timeSpentSeconds)}';
  }

  String _fmtTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}