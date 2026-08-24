import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../common/widgets/app_empty_state.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../../../common/widgets/app_loading.dart';
import '../../../../common/widgets/shimmer_widget.dart';
import '../../../home/presentation/widgets/stats_card.dart';
import '../../../../../features/leaderboard/domain/entities/leaderboard_entities.dart';
import '../../../../../features/leaderboard/presentation/providers/leaderboard_provider.dart';

class LeaderboardHomePage extends ConsumerStatefulWidget {
  const LeaderboardHomePage({super.key});

  @override
  ConsumerState<LeaderboardHomePage> createState() => _LeaderboardHomePageState();
}

class _LeaderboardHomePageState extends ConsumerState<LeaderboardHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final state = ref.read(leaderboardProvider);
      if (state.status == LeaderboardStatus.initial) {
        ref.read(leaderboardProvider.notifier).load();
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(leaderboardProvider.notifier).load();
  }

  void _changePeriod(LeaderboardPeriod period) {
    ref.read(leaderboardProvider.notifier).changePeriod(period);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LeaderboardState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.data == null) {
      return const AppLoading(message: 'Loading leaderboard...');
    }

    if (state.status == LeaderboardStatus.error && state.data == null) {
      return AppErrorWidget(
        message: state.message ?? 'Could not load the leaderboard.',
        onRetry: () => ref.read(leaderboardProvider.notifier).load(),
      );
    }

    final entries = state.data?.entries ?? const [];
    final showInitialSpinner = state.isLoading && entries.isEmpty;
    final listItems = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
      children: [
        const SizedBox(height: AppDimensions.paddingSm),
        _PeriodSelector(
          selected: state.selectedPeriod,
          onChanged: _changePeriod,
        ),
        const SizedBox(height: AppDimensions.paddingMd),
        StatsCard(
          level: state.myRanking.level,
          totalPoints: state.myRanking.totalPoints,
          currentLevelPoints: state.myRanking.currentLevelPoints,
          nextLevelPoints: state.myRanking.nextLevelPoints,
          pointsToNextLevel: state.myRanking.pointsToNextLevel,
          badge: state.myRanking.badge.isEmpty ? 'bronze' : state.myRanking.badge,
          weeklyRank: _rankForPeriod(state),
          quizzesCompleted: state.myRanking.quizzesCompleted,
        ),
        const SizedBox(height: AppDimensions.lg),
        if (showInitialSpinner)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
            child: ShimmerList(itemCount: 6, itemHeight: 72),
          )
        else if (entries.isEmpty)
          AppEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'No rankings yet',
            subtitle:
                'Complete quizzes to earn points and appear on the ${state.selectedPeriod.label.toLowerCase()} leaderboard.',
            actionLabel: 'Refresh',
            onAction: _refresh,
          )
        else ...[
          _TopThree(entries: entries.take(3).toList()),
          if (listItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingMd,
                AppDimensions.sm,
                AppDimensions.paddingMd,
                0,
              ),
              child: Text(
                '${state.data?.totalParticipants ?? entries.length} participants',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[500] : AppColors.textLight,
                ),
              ),
            ),
          ...listItems.map((entry) => _EntryTile(entry: entry)),
        ],
      ],
    );
  }

  int _rankForPeriod(LeaderboardState state) {
    switch (state.selectedPeriod) {
      case LeaderboardPeriod.weekly:
        return state.myRanking.weeklyRank;
      case LeaderboardPeriod.monthly:
        return state.myRanking.monthlyRank;
      case LeaderboardPeriod.allTime:
        return state.myRanking.allTimeRank;
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final LeaderboardPeriod selected;
  final ValueChanged<LeaderboardPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        padding: const EdgeInsets.all(AppDimensions.xs),
        child: Row(
          children: LeaderboardPeriod.values.map((period) {
            final isSelected = period == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.grey[400]
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopThree extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _TopThree({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFFB45309),
    ];
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(
              child: _PodiumItem(entry: second, color: colors[1], barHeight: 30),
            )
          else
            const Spacer(),
          if (first != null)
            Expanded(
              child: _PodiumItem(entry: first, color: colors[0], barHeight: 46),
            ),
          if (third != null)
            Expanded(
              child: _PodiumItem(entry: third, color: colors[2], barHeight: 22),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  final double barHeight;

  const _PodiumItem({
    required this.entry,
    required this.color,
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${entry.points} pts',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Container(
          width: double.infinity,
          height: barHeight,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.all(4),
          child: Text(
            '#${entry.rank}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final leaderboardEntry = entry;
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
          SizedBox(
            width: 32,
            child: Text(
              '#${leaderboardEntry.rank}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey[300] : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            backgroundImage: (leaderboardEntry.avatar?.isNotEmpty == true)
                ? NetworkImage(leaderboardEntry.avatar!)
                : null,
            child: (leaderboardEntry.avatar?.isNotEmpty != true)
                ? Text(
                    leaderboardEntry.username.isNotEmpty
                        ? leaderboardEntry.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              leaderboardEntry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[100] : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${leaderboardEntry.points}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryAmber,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
