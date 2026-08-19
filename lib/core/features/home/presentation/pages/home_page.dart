import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/bible/presentation/providers/bible_providers.dart';
import '../../domain/entities/home_data.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/home_verse_of_the_day.dart';
import '../widgets/upcoming_quiz_card.dart';
import '../widgets/activity_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDailyVerseNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleDailyVerseNotification();
    }
  }

  Future<void> _scheduleDailyVerseNotification() async {
    try {
      final user = ref.read(authProvider).user;
      final firstName = (user?.fullName ?? '').split(' ').first.trim();

      // Determine the date the next 7:00 AM notification fires on, and fetch
      // the deterministic verse for THAT date so the notification matches the
      // verse of the day shown on the home page that day.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextFireAt7am = today.add(const Duration(hours: 7));
      final targetDate = nextFireAt7am.isAfter(now)
          ? today
          : today.add(const Duration(days: 1));

      final result = await ref
          .read(getVerseOfTheDayUseCaseProvider)
          .call(date: targetDate)
          .run();
      final verse = result.fold(
        (failure) => throw failure,
        (v) => v,
      );
      if (verse == null) return;

      // Clean brackets if present in raw verse text
      final cleanedText = verse.text.replaceAll('{', '').replaceAll('}', '');

      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleDailyVerse(
        userName: firstName,
        verseText: cleanedText,
        verseReference: verse.formattedReference,
        date: targetDate,
      );
    } catch (e) {
      LoggerService.warning('Could not schedule daily verse notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mockData = _mockHomeData();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // TODO: refresh home data
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
            children: [
              _buildGreeting(context, user?.fullName, isDark),
              const SizedBox(height: AppDimensions.paddingMd),
              PromoCarousel(slides: _promoSides(context)),
              const SizedBox(height: AppDimensions.paddingMd),
              const HomeVerseOfTheDay(),
              const SizedBox(height: AppDimensions.paddingLg),
              _buildSectionHeader(context, 'Quick Actions', isDark),
              const SizedBox(height: AppDimensions.paddingSm),
              _buildQuickActionGrid(context, isDark),
              const SizedBox(height: AppDimensions.paddingLg),
              _buildSectionHeader(context, 'Upcoming Quizzes', isDark),
              const SizedBox(height: AppDimensions.paddingSm),
              _buildUpcomingQuizzes(context, mockData.upcomingQuizzes),
              const SizedBox(height: AppDimensions.paddingLg),
              _buildSectionHeader(context, 'Recent Activity', isDark),
              const SizedBox(height: AppDimensions.paddingSm),
              _buildRecentActivity(context, mockData.recentActivity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, bool isDark) {
    final actions = _quickActions(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return Material(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: action.onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PromoSlide> _promoSides(BuildContext context) {
    return [
      PromoSlide(
        title: 'Daily Quiz Challenge',
        subtitle: 'Grow in faith and win points every day.',
        icon: Icons.emoji_events_rounded,
        onTap: () => context.go(RouteNames.quiz),
      ),
      PromoSlide(
        title: 'Bible Study Library',
        subtitle: 'Explore articles, videos and podcasts.',
        icon: Icons.auto_stories_rounded,
        onTap: () => context.go(RouteNames.profile),
      ),
      PromoSlide(
        title: 'Join the Leaderboard',
        subtitle: 'Compete with the community this week.',
        icon: Icons.leaderboard_rounded,
        onTap: () => context.go(RouteNames.leaderboard),
      ),
    ];
  }

  Widget _buildGreeting(BuildContext context, String? fullName, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
        AppDimensions.paddingMd,
        0,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              (fullName?.isNotEmpty == true) ? fullName!.substring(0, 1).toUpperCase() : 'U',
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
              if (title == 'Upcoming Quizzes' || title == 'Recent Activity') {
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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

  Widget _buildRecentActivity(BuildContext context, List<RecentActivity> activities) {
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

  List<_QuickActionItem> _quickActions(BuildContext context) {
    return [
      _QuickActionItem(
        icon: Icons.quiz_rounded,
        label: 'Take Quiz',
        color: AppColors.primaryBlue,
        bgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        onTap: () {
          ref.read(mainTabIndexProvider.notifier).state = 1;
        },
      ),
      _QuickActionItem(
        icon: Icons.menu_book_rounded,
        label: 'Bible Learning',
        color: AppColors.primaryAmber,
        bgColor: AppColors.primaryAmber.withValues(alpha: 0.1),
        onTap: () => context.pushNamed(RouteNames.bibleReader),
      ),
      _QuickActionItem(
        icon: Icons.auto_stories_rounded,
        label: 'Library',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        onTap: () => context.push(RouteNames.library),
      ),
      _QuickActionItem(
        icon: Icons.search_rounded,
        label: 'Bible Search',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        onTap: () => context.pushNamed(RouteNames.bibleSearch),
      ),
      _QuickActionItem(
        icon: Icons.grid_4x4_rounded,
        label: 'Crossword',
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
        onTap: () => context.pushNamed(RouteNames.crossPuzzle),
      ),
      _QuickActionItem(
        icon: Icons.person_rounded,
        label: 'Profile',
        color: AppColors.success,
        bgColor: AppColors.successBg,
        onTap: () {
          ref.read(mainTabIndexProvider.notifier).state = 3;
        },
      ),
    ];
  }

  HomeData _mockHomeData() {
    return HomeData(
      stats: const UserStats(),
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

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}