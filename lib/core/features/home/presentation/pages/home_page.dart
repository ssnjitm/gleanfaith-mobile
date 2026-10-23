import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
import '../../../../common/widgets/app_empty_state.dart';
import '../../../../common/widgets/shimmer_placeholders.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../common/entities/content_language.dart';
import '../../../../common/providers/content_language_provider.dart';
import '../../../../../features/app_update/presentation/providers/app_update_provider.dart';
import '../../../../../features/app_update/presentation/widgets/app_update_dialog.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/bible/presentation/providers/remote_bible_providers.dart';
import '../../../../../features/bible/presentation/providers/verse_of_the_day_provider.dart';
import '../../../../../features/bible_games/presentation/widgets/home_fun_facts_card.dart';
import '../../../../../features/bible_study/presentation/widgets/continue_reading_card.dart';
import '../../../../../features/leaderboard/domain/entities/leaderboard_entities.dart';
import '../../../../../features/leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../../profile/presentation/widgets/profile_top_bar_button.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/home_verse_of_the_day.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  int _shownUpdateVersionCode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDailyVerseNotification();
      _checkForAppUpdate();
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
      _checkForAppUpdate();
    }
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final notifier = ref.read(appUpdateProvider.notifier);
      await notifier.check();
      if (!mounted) return;
      await AppUpdateDialog.showIfNeeded(
        context,
        ref,
        shownVersionCode: _shownUpdateVersionCode,
      );
      final release = ref.read(appUpdateProvider).release;
      if (release != null) {
        _shownUpdateVersionCode = release.versionCode;
      }
    } catch (error) {
      LoggerService.warning('Update prompt skipped: ');
    }
  }

  Future<void> _scheduleDailyVerseNotification() async {
    try {
      final user = ref.read(authProvider).user;
      final firstName = (user?.fullName ?? '').split(' ').first.trim();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextFireAt7am = today.add(const Duration(hours: 7));
      final targetDate = nextFireAt7am.isAfter(now)
          ? today
          : today.add(const Duration(days: 1));

      final verse = await loadVerseOfTheDay(
        date: targetDate,
        language: ref.read(contentLanguageProvider),
        getRemoteVerse: ref.read(getRemoteVerseUseCaseProvider),
      );

      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleDailyVerse(
        userName: firstName,
        verseText: verse.text,
        verseReference: verse.reference,
        date: targetDate,
      );
    } catch (e) {
      LoggerService.warning('Could not schedule daily verse notification: ');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ContentLanguage>(contentLanguageProvider, (previous, next) {
      if (previous != next) {
        _scheduleDailyVerseNotification();
      }
    });

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
            children: [
              _buildGreeting(context, user?.fullName, isDark),
              const SizedBox(height: AppDimensions.paddingMd),
              PromoCarousel(slides: _promoSides(context)),
              const SizedBox(height: AppDimensions.paddingMd),
              const HomeVerseOfTheDay(),
              const SizedBox(height: AppDimensions.paddingMd),
              const ContinueReadingCard(),
              _buildSectionHeader(context, 'Quick Actions', isDark),
              const SizedBox(height: AppDimensions.paddingSm),
              _buildQuickActionGrid(context, isDark),
              const SizedBox(height: AppDimensions.paddingMd),
              _buildLeaderboardPreview(context, isDark),
              const SizedBox(height: AppDimensions.paddingMd),
              const HomeFunFactsCard(),
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
        onTap: () => ref.read(mainTabIndexProvider.notifier).state = MainTab.quiz,
      ),
      PromoSlide(
        title: 'Bible Study Library',
        subtitle: 'Explore articles, videos and podcasts.',
        icon: Icons.auto_stories_rounded,
        onTap: () => ref.read(mainTabIndexProvider.notifier).state = MainTab.library,
      ),
      PromoSlide(
        title: 'Play Bible Games',
        subtitle: 'Test how well you know your Bible.',
        icon: Icons.sports_esports_rounded,
        onTap: () => ref.read(mainTabIndexProvider.notifier).state = MainTab.games,
      ),
    ];
  }

  Widget _buildGreeting(BuildContext context, String? fullName, bool isDark) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

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
                  ',',
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
          const ProfileTopBarButton(),
          const SizedBox(width: AppDimensions.paddingSm),
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
              onPressed: () => context.push(RouteNames.notifications),
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, bool isDark) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final entries = leaderboardState.data?.entries ?? const [];

    if (leaderboardState.status == LeaderboardStatus.initial &&
        leaderboardState.data == null) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(leaderboardProvider.notifier).load();
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RouteNames.leaderboard),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Material(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: () => context.push(RouteNames.leaderboard),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    if (leaderboardState.isLoading && entries.isEmpty)
                      const Column(
                        children: [
                          LeaderboardEntryShimmer(),
                          LeaderboardEntryShimmer(),
                          LeaderboardEntryShimmer(),
                        ],
                      )
                    else if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingLg),
                        child: AppEmptyState(
                          icon: Icons.leaderboard_outlined,
                          title: 'No rankings yet',
                          subtitle: 'Complete quizzes to see leaderboard',
                          onAction: () => context.push(RouteNames.leaderboard),
                          actionLabel: 'Go to Leaderboard',
                        ),
                      )
                    else
                      ...entries
                          .take(3)
                          .map(
                            (entry) => _HomeLeaderboardTile(
                              entry: entry,
                              isDark: isDark,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          ref.read(mainTabIndexProvider.notifier).state = MainTab.quiz;
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
        onTap: () {
          ref.read(mainTabIndexProvider.notifier).state = MainTab.library;
        },
      ),
      _QuickActionItem(
        icon: Icons.search_rounded,
        label: 'Bible Search',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        onTap: () {
          ref.read(mainTabIndexProvider.notifier).state = MainTab.bibleSearch;
        },
      ),
      _QuickActionItem(
        icon: Icons.grid_4x4_rounded,
        label: 'Crossword',
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
        onTap: () => context.pushNamed(RouteNames.crossPuzzle),
      ),
      _QuickActionItem(
        icon: Icons.sports_esports_rounded,
        label: 'Bible Games',
        color: const Color(0xFFEA580C),
        bgColor: const Color(0xFFEA580C).withValues(alpha: 0.1),
        onTap: () {
          ref.read(mainTabIndexProvider.notifier).state = MainTab.games;
        },
      ),
    ];
  }
}

class _HomeLeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isDark;

  const _HomeLeaderboardTile({
    required this.entry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.sm + 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey[300] : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            backgroundImage:
                (entry.avatar?.isNotEmpty == true) ? NetworkImage(entry.avatar!) : null,
            child: (entry.avatar?.isNotEmpty != true)
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[100] : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryAmber,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'pts',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
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
