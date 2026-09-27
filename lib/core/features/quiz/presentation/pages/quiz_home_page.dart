import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/shimmer_placeholders.dart';
import '../../../../router/app_router.dart';
import '../../../../router/route_names.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/dimensions.dart';
import '../../../../../features/quiz/domain/entities/quiz_entities.dart';
import '../../../../../features/quiz/presentation/providers/daily_quiz_provider.dart';
import '../../../../../features/quiz/presentation/providers/quiz_provider.dart';
import '../../../../../features/quiz/presentation/providers/quiz_series_provider.dart';
import '../../../../../features/quiz/presentation/widgets/daily_quiz_hero_card.dart';

/// Quiz hub split into three tabs: Daily (hero), Series (multi-day campaigns)
/// and Other (everything else that is not a daily or series quiz).
enum QuizTab { daily, series, other }

class QuizHomePage extends ConsumerStatefulWidget {
  const QuizHomePage({super.key});

  @override
  ConsumerState<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends ConsumerState<QuizHomePage> with RouteAware {
  ModalRoute<dynamic>? _subscribedRoute;
  QuizTab _tab = QuizTab.daily;

  /// The attempt history must be loaded *before* the daily quiz so the hero can
  /// lock its single attempt up front instead of relying on a server error.
  Future<void> _loadAll() async {
    await ref.read(quizProvider.notifier).loadAttemptedScheduleIds();
    await Future.wait([
      ref.read(quizProvider.notifier).loadUpcomingQuizzes(),
      ref.read(dailyQuizProvider.notifier).loadDailyQuiz(),
      ref.read(quizSeriesProvider.notifier).loadSeries(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || route == _subscribedRoute) return;
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    _subscribedRoute = route;
    AppRouter.routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _loadAll();
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
      _subscribedRoute = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No App Bar title: the tab row is the page header.
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.only(
                  top: AppDimensions.sm,
                  bottom: AppDimensions.paddingXl,
                ),
                children: switch (_tab) {
                  QuizTab.daily => _buildDailyTab(),
                  QuizTab.series => _buildSeriesTab(),
                  QuizTab.other => _buildOtherTab(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingMd,
        AppDimensions.paddingMd,
        0,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(context, QuizTab.daily, 'Daily', isDark),
          _buildTabItem(context, QuizTab.series, 'Series', isDark),
          _buildTabItem(context, QuizTab.other, 'Other', isDark),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    QuizTab tab,
    String label,
    bool isDark,
  ) {
    final selected = tab == _tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDailyTab() {
    final state = ref.watch(dailyQuizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final upcoming = state.upcoming
        .where((quiz) => !quiz.isEndedAt(now))
        .where((quiz) => quiz.id != state.today?.id)
        .toList();

    if (upcoming.isEmpty) {
      return const [DailyQuizHeroCard(), SizedBox(height: AppDimensions.lg)];
    }

    return [
      const DailyQuizHeroCard(),
      const SizedBox(height: AppDimensions.lg),
      _SectionTitle(title: 'Coming up', isDark: isDark),
      const SizedBox(height: AppDimensions.sm),
      ...upcoming.map((quiz) => _QuizCard(quiz: quiz, badge: 'Daily')),
    ];
  }

  List<Widget> _buildSeriesTab() {
    final seriesState = ref.watch(quizSeriesProvider);
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (seriesState.status == QuizSeriesStatus.loading &&
        seriesState.series.isEmpty) {
      return const [QuizCardShimmer(), QuizCardShimmer(), QuizCardShimmer()];
    }

    if (seriesState.series.isEmpty) {
      return const [
        _EmptyTab(
          icon: Icons.workspaces_rounded,
          title: 'No quiz series',
          subtitle: 'Multi-day quiz series will show up here.',
        ),
      ];
    }

    return [
      for (final series in seriesState.series) ...[
        _SeriesCard(
          series: series,
          isDark: isDark,
          usedScheduleIds: quizState.attemptedScheduleIds,
        ),
        const SizedBox(height: AppDimensions.paddingMd),
      ],
    ];
  }

  List<Widget> _buildOtherTab() {
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizzes = quizState.upcomingQuizzes
        .where((quiz) => !quiz.isDaily && !quiz.isSeries)
        .toList();

    if (quizState.status == QuizStatus.loading && quizzes.isEmpty) {
      return const [QuizCardShimmer(), QuizCardShimmer(), QuizCardShimmer()];
    }

    if (quizzes.isEmpty) {
      return [
        _EmptyTab(
          icon: Icons.quiz_outlined,
          title: 'No other quizzes',
          subtitle: quizState.message ?? 'Check back soon for new quizzes.',
        ),
      ];
    }

    return [
      _SectionTitle(title: 'All quizzes', isDark: isDark),
      const SizedBox(height: AppDimensions.sm),
      ...quizzes.map((quiz) => _QuizCard(quiz: quiz)),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.xl,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isDark ? Colors.grey[600] : AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final QuizSeries series;
  final bool isDark;
  final Set<String> usedScheduleIds;

  const _SeriesCard({
    required this.series,
    required this.isDark,
    required this.usedScheduleIds,
  });

  @override
  Widget build(BuildContext context) {
    final deployments = series.deployments
        .where((schedule) => schedule.id.isNotEmpty)
        .toList();
    final doneCount = deployments
        .where((schedule) => usedScheduleIds.contains(schedule.id))
        .length;
    final total = deployments.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: const Icon(
                    Icons.workspaces_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        series.durationValue > 0
                            ? '${series.durationValue} ${series.durationUnit}'
                            : (series.description ?? 'Quiz series'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: AppDimensions.paddingMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                '$doneCount of $total days completed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
            ],
            if (deployments.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingSm),
              ...deployments
                  .take(3)
                  .map(
                    (schedule) => _QuizCard(
                      quiz: schedule,
                      badge: 'Series',
                      compact: true,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizSchedule quiz;
  final String? badge;
  final bool compact;

  const _QuizCard({required this.quiz, this.badge, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = quiz.isActiveAt(DateTime.now());
    final isEnded = quiz.isEndedAt(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        0,
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => context.push(RouteNames.quizDetail, extra: quiz.id),
          child: Container(
            padding: EdgeInsets.all(
              compact ? AppDimensions.paddingSm : AppDimensions.paddingMd,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isActive
                    ? AppColors.success.withValues(alpha: 0.4)
                    : (isDark
                          ? const Color(0xFF334155)
                          : AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 40 : 48,
                  height: compact ? 40 : 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: compact ? 20 : 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        _dateLabel(quiz),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.totalQuestions} questions',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          const Icon(Icons.timer_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.durationMinutes}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  isActive: isActive,
                  isEnded: isEnded,
                  badge: badge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(QuizSchedule quiz) {
    final now = DateTime.now();
    final sameDay =
        now.year == quiz.startDateTime.year &&
        now.month == quiz.startDateTime.month &&
        now.day == quiz.startDateTime.day;
    if (sameDay) {
      return 'Today · ${DateFormat('h:mm a').format(quiz.startDateTime)}';
    }
    return DateFormat('MMM d, h:mm a').format(quiz.startDateTime);
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isEnded;
  final String? badge;

  const _StatusBadge({
    required this.isActive,
    required this.isEnded,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final Color background;

    if (isActive) {
      label = 'Active';
      color = AppColors.success;
      background = AppColors.successBg;
    } else if (isEnded) {
      label = 'Ended';
      color = AppColors.textMuted;
      background = AppColors.bgGray;
    } else if (badge != null) {
      label = badge!;
      color = AppColors.primaryBlue;
      background = AppColors.primaryBlue.withValues(alpha: 0.1);
    } else {
      label = 'Scheduled';
      color = AppColors.primaryBlue;
      background = AppColors.primaryBlue.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
