import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../providers/crosspuzzle_provider.dart';

class CrossPuzzleHomePage extends ConsumerStatefulWidget {
  const CrossPuzzleHomePage({super.key});

  @override
  ConsumerState<CrossPuzzleHomePage> createState() => _CrossPuzzleHomePageState();
}

class _CrossPuzzleHomePageState extends ConsumerState<CrossPuzzleHomePage> {
  String _selectedDifficulty = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crossPuzzleProvider.notifier).loadPuzzles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crossPuzzleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CrossWord Puzzles'),
        actions: [
          IconButton(
            tooltip: 'My Puzzles',
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => context.push(RouteNames.crossPuzzleMyPuzzles),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(crossPuzzleProvider.notifier)
            .loadPuzzles(difficulty: _selectedDifficulty),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
          children: [
            const SizedBox(height: AppDimensions.sm),
            _buildDifficultyFilters(isDark),
            const SizedBox(height: AppDimensions.sm),
            _buildHero(isDark),
            const SizedBox(height: AppDimensions.sm),
            _buildGrid(context, state, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyFilters(bool isDark) {
    const filters = [
      ('', 'All'),
      ('easy', 'Easy'),
      ('medium', 'Medium'),
      ('hard', 'Hard'),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        children: filters.map((filter) {
          final value = filter.$1;
          final label = filter.$2;
          final active = _selectedDifficulty == value;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: ChoiceChip(
              label: Text(label),
              selected: active,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _selectedDifficulty = value);
                ref
                    .read(crossPuzzleProvider.notifier)
                    .loadPuzzles(difficulty: value);
              },
              selectedColor: AppColors.primaryBlue,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : (isDark ? Colors.grey[300] : AppColors.textSecondary),
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
              side: BorderSide(
                color: active ? AppColors.primaryBlue : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_4x4_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bible Crossword',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill the grid, earn XP, level up!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, CrossPuzzleState state, bool isDark) {
    final puzzles = state.puzzles;

    if (state.status == CrossPuzzleStatus.loading && puzzles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (puzzles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              state.message ?? 'No crossword puzzles available yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.paddingSm,
        mainAxisSpacing: AppDimensions.paddingSm,
        childAspectRatio: 1.6,
      ),
      itemCount: puzzles.length,
      itemBuilder: (context, index) {
        final puzzle = puzzles[index];
        return _PuzzleCard(puzzle: puzzle, isDark: isDark);
      },
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  final CrossPuzzle puzzle;
  final bool isDark;

  const _PuzzleCard({required this.puzzle, required this.isDark});

  Color get _difficultyColor {
    switch (puzzle.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.primaryAmber;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = puzzle.userProgress;
    final isCompleted = progress?.isCompleted ?? false;
    final isInProgress = progress != null && !isCompleted;

    final String badge;
    final Color badgeColor;
    if (isCompleted) {
      badge = 'Solved·${progress!.completions}×';
      badgeColor = AppColors.success;
    } else if (isInProgress) {
      badge = '${progress.filledCells} filled';
      badgeColor = AppColors.primaryAmber;
    } else {
      badge = 'Start';
      badgeColor = AppColors.primaryBlue;
    }

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
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : (isInProgress
                            ? Icons.arrow_forward_rounded
                            : Icons.grid_4x4_rounded),
                    color: badgeColor,
                    size: 22,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      puzzle.difficulty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _difficultyColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
              const SizedBox(height: 2),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}