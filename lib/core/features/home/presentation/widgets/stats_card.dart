import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';

class StatsCard extends StatelessWidget {
  final int level;
  final int totalPoints;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;
  final String badge;
  final int weeklyRank;
  final int quizzesCompleted;

  const StatsCard({
    super.key,
    required this.level,
    required this.totalPoints,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
    required this.badge,
    required this.weeklyRank,
    required this.quizzesCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = nextLevelPoints > 0
        ? (currentLevelPoints / nextLevelPoints).clamp(0.0, 1.0)
        : 0.0;

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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          children: [
            Row(
              children: [
                _LevelBadge(level: level, badge: badge),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _badgeLabel(badge),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Total Points',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAmber),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentLevelPoints / $nextLevelPoints XP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$pointsToNextLevel XP to next level',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: AppDimensions.paddingMd),
            Row(
              children: [
                _StatItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Rank',
                  value: weeklyRank > 0 ? '#$weeklyRank' : '--',
                ),
                _StatItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  value: '$quizzesCompleted',
                ),
                _StatItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak',
                  value: '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _badgeLabel(String badge) {
    switch (badge) {
      case 'bronze':
        return 'Bronze Learner';
      case 'silver':
        return 'Silver Scholar';
      case 'gold':
        return 'Gold Master';
      case 'platinum':
        return 'Platinum Sage';
      default:
        return 'Beginner';
    }
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final String badge;

  const _LevelBadge({required this.level, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
