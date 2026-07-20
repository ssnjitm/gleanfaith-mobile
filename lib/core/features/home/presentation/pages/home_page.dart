import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/home_data.dart';
import '../widgets/stats_card.dart';
import '../widgets/upcoming_quiz_card.dart';
import '../widgets/activity_tile.dart';
import '../widgets/quick_action_grid.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockData = _mockHomeData();

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: refresh home data
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
        children: [
          _buildGreeting(context, user?.fullName, isDark),
          const SizedBox(height: AppDimensions.paddingMd),
          StatsCard(
            level: mockData.stats.level,
            totalPoints: mockData.stats.totalPoints,
            currentLevelPoints: mockData.stats.currentLevelPoints,
            nextLevelPoints: mockData.stats.nextLevelPoints,
            pointsToNextLevel: mockData.stats.pointsToNextLevel,
            badge: mockData.stats.badge,
            weeklyRank: mockData.stats.weeklyRank,
            quizzesCompleted: mockData.stats.quizzesCompleted,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          _buildSectionHeader(context, 'Upcoming Quizzes', isDark),
          const SizedBox(height: AppDimensions.paddingSm),
          _buildUpcomingQuizzes(context, mockData.upcomingQuizzes),
          const SizedBox(height: AppDimensions.paddingLg),
          _buildSectionHeader(context, 'Quick Actions', isDark),
          const SizedBox(height: AppDimensions.paddingSm),
          QuickActionGrid(actions: _quickActions(context)),
          const SizedBox(height: AppDimensions.paddingLg),
          _buildSectionHeader(context, 'Recent Activity', isDark),
          const SizedBox(height: AppDimensions.paddingSm),
          _buildRecentActivity(context, mockData.recentActivity),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String? fullName, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingMd,
        AppDimensions.paddingMd,
        0,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              (fullName?.isNotEmpty == true)
                  ? fullName!.substring(0, 1).toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                ),
                Text(
                  fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              if (title == 'Upcoming Quizzes') {
                context.go(RouteNames.quiz);
              } else if (title == 'Recent Activity') {
                context.go(RouteNames.quiz);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See All', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingQuizzes(BuildContext context, List<UpcomingQuiz> quizzes) {
    if (quizzes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: _buildEmptyCard(context, 'No upcoming quizzes'),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        itemCount: quizzes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return UpcomingQuizCard(
            title: quiz.title,
            startDateTime: quiz.startDateTime,
            durationMinutes: quiz.durationMinutes,
            totalQuestions: quiz.totalQuestions,
            onTap: () => context.go(RouteNames.quiz),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<RecentActivity> activities) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: _buildEmptyCard(context, 'No recent activity'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Column(
        children: activities
            .map((a) => ActivityTile(
                  quizTitle: a.quizTitle,
                  score: a.score,
                  maxScore: a.maxScore,
                  percentageScore: a.percentageScore,
                  passed: a.passed,
                  timeAgo: _timeAgo(a.completedAt),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.xl,
        horizontal: AppDimensions.paddingMd,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey[500] : AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<QuickAction> _quickActions(BuildContext context) {
    return [
      QuickAction(
        icon: Icons.quiz_rounded,
        label: 'Take Quiz',
        color: AppColors.primaryBlue,
        bgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        onTap: () => context.go(RouteNames.quiz),
      ),
      QuickAction(
        icon: Icons.leaderboard_rounded,
        label: 'Leaderboard',
        color: AppColors.primaryAmber,
        bgColor: AppColors.primaryAmber.withValues(alpha: 0.1),
        onTap: () => context.go(RouteNames.leaderboard),
      ),
      QuickAction(
        icon: Icons.auto_stories_rounded,
        label: 'Library',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        onTap: () {},
      ),
      QuickAction(
        icon: Icons.person_rounded,
        label: 'Profile',
        color: AppColors.success,
        bgColor: AppColors.successBg,
        onTap: () => context.go(RouteNames.profile),
      ),
    ];
  }

  HomeData _mockHomeData() {
    return HomeData(
      stats: const UserStats(
        totalPoints: 1250,
        level: 3,
        currentLevelPoints: 250,
        nextLevelPoints: 500,
        pointsToNextLevel: 250,
        badge: 'bronze',
        weeklyRank: 12,
        quizzesCompleted: 8,
      ),
      upcomingQuizzes: [
        UpcomingQuiz(
          id: '1',
          title: 'The Gospel of John - Chapter 1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          durationMinutes: 15,
          totalQuestions: 10,
        ),
        UpcomingQuiz(
          id: '2',
          title: 'Psalms of Thanksgiving',
          startDateTime: DateTime.now().add(const Duration(days: 1)),
          durationMinutes: 20,
          totalQuestions: 15,
        ),
        UpcomingQuiz(
          id: '3',
          title: 'Book of Romans Overview',
          startDateTime: DateTime.now().add(const Duration(days: 3)),
          durationMinutes: 30,
          totalQuestions: 20,
        ),
      ],
      recentActivity: [
        RecentActivity(
          id: 'a1',
          quizTitle: 'Old Testament Prophets',
          score: 8,
          maxScore: 10,
          percentageScore: 80,
          passed: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        RecentActivity(
          id: 'a2',
          quizTitle: 'New Testament Parables',
          score: 5,
          maxScore: 10,
          percentageScore: 50,
          passed: false,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RecentActivity(
          id: 'a3',
          quizTitle: 'Fruit of the Spirit',
          score: 9,
          maxScore: 10,
          percentageScore: 90,
          passed: true,
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}
