import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../router/route_names.dart';
// import '../../../../common/widgets/shimmer_placeholders.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/bible/domain/entities/verse_of_the_day.dart';
import '../../../../../features/bible/presentation/providers/verse_language_provider.dart';
import '../../../../../features/bible/presentation/providers/verse_of_the_day_provider.dart';
import '../../../../../features/bible_games/presentation/widgets/home_fun_facts_card.dart';
import '../../../../../features/bible_study/presentation/widgets/continue_reading_card.dart';
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

      // Determine the date the next 7:00 AM notification fires on, and load
      // the verse for THAT date so the notification matches the verse of the
      // day shown on the home page that day.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextFireAt7am = today.add(const Duration(hours: 7));
      final targetDate = nextFireAt7am.isAfter(now)
          ? today
          : today.add(const Duration(days: 1));

      // Same loader the Home card uses, so the two can never disagree — and it
      // honours the EN | NP toggle, meaning the notification body is Nepali
      // when the user has selected Nepali. The title stays English. Both
      // languages resolve the *same* curated verse, so a language change
      // re-renders one verse rather than swapping in a different one.
      final verse = await loadVerseOfTheDay(
        date: targetDate,
        language: ref.read(verseLanguageProvider),
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
      LoggerService.warning('Could not schedule daily verse notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The notification body is baked in at schedule time, so a language change
    // has to re-schedule it. Without this the 7:00 AM verse would keep the
    // previous language until the app happened to be resumed.
    ref.listen<VerseLanguage>(verseLanguageProvider, (previous, next) {
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
              const SizedBox(height: AppDimensions.paddingMd),
              const ContinueReadingCard(),
              _buildSectionHeader(context, 'Quick Actions', isDark),
              const SizedBox(height: AppDimensions.paddingSm),
              _buildQuickActionGrid(context, isDark),
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
      // Rankings live on the profile screen, which is reachable only from a
      // top-bar icon, so the carousel points at the games tab instead of
      // navigating behind the user's back.
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
          // The profile is no longer a bottom-nav tab or a home quick action;
          // the icon in this header is the single entry point to it.
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
