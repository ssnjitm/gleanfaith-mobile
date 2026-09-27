import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';
import '../providers/quiz_language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/confetti_burst.dart';

class QuizDetailPage extends ConsumerStatefulWidget {
  final String quizScheduleId;

  const QuizDetailPage({super.key, required this.quizScheduleId});

  @override
  ConsumerState<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends ConsumerState<QuizDetailPage> {
  bool _loading = false;
  bool _celebrating = false;
  Timer? _countdownTicker;

  QuizStrings get _strings =>
      QuizStrings.of(ref.watch(dailyQuizLanguageProvider));

  @override
  void initState() {
    super.initState();
    // Keeps the "Starts in ..." countdown fresh, and flips this page over to
    // the Start button the moment the quiz window opens.
    _countdownTicker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    await Future.wait([
      ref.read(quizProvider.notifier).loadAttemptedScheduleIds(),
      ref.read(quizProvider.notifier).loadUpcomingQuizzes(),
    ]);
    if (mounted) setState(() {});
  }

  /// The schedule this page is for, when it is present in the loaded list.
  QuizSchedule? get _schedule {
    final schedules = ref.read(quizProvider).upcomingQuizzes;
    for (final quiz in schedules) {
      if (quiz.id == widget.quizScheduleId) return quiz;
    }
    return null;
  }

  Future<void> _startQuiz() async {
    if (_loading) return;
    setState(() => _loading = true);
    final activeQuiz = await ref
        .read(quizProvider.notifier)
        .startQuiz(widget.quizScheduleId);
    if (!mounted) return;
    setState(() => _loading = false);

    final quizState = ref.read(quizProvider);
    final message = (quizState.message ?? '').trim();

    if (activeQuiz == null) {
      if (quizState.blockReason == QuizBlockReason.alreadyCompleted ||
          quizState.blockReason == QuizBlockReason.attemptsExhausted) {
        ref.read(quizProvider.notifier).markAttempted(widget.quizScheduleId);
        _celebrateCompleted();
        return;
      }
      if (quizState.blockReason == QuizBlockReason.notAvailable) {
        AlertWidget.showWarning(
          context,
          message.isEmpty
              ? 'This quiz is not open right now. Check the schedule and try again.'
              : message,
        );
        return;
      }
      // Previously a silent return here made the button look broken.
      AlertWidget.showError(
        context,
        message.isEmpty
            ? 'Could not start the quiz. Please try again.'
            : message,
      );
      return;
    }
    ref.read(quizProvider.notifier).clearBlockReason();
    context.pushReplacement(
      RouteNames.quizPlay,
      extra: QuizPlayArgs.from(activeQuiz, schedule: _schedule),
    );
  }

  void _celebrateCompleted() {
    HapticFeedback.heavyImpact();
    setState(() => _celebrating = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  void _goBack() {
    ref.read(quizProvider.notifier).clearBlockReason();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = _schedule;
    final alreadyDone =
        quizState.hasUsedAttempt(widget.quizScheduleId) ||
        quizState.blockReason == QuizBlockReason.alreadyCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(alreadyDone ? 'Quiz Completed' : 'Quiz'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBack,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(context, alreadyDone, isDark),
                const SizedBox(height: AppDimensions.lg),
                if (alreadyDone)
                  _buildCompletedSection(context, isDark)
                else ...[
                  _buildStatsRow(context, schedule, isDark),
                  const SizedBox(height: AppDimensions.lg),
                  _buildInfoCard(context, isDark),
                ],
              ],
            ),
          ),
          if (_celebrating)
            Positioned.fill(
              child: ConfettiBurst(
                particleCount: 120,
                onCompleted: () {
                  if (mounted && _celebrating) {
                    setState(() => _celebrating = false);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool alreadyDone, bool isDark) {
    final schedule = _schedule;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  alreadyDone ? Icons.emoji_events_rounded : Icons.quiz_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFE082),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alreadyDone
                          ? 'Completed'
                          : '${schedule?.totalQuestions ?? 10} Qs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            schedule?.title ?? 'Bible Quiz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            alreadyDone
                ? 'You have already conquered this quiz. Well done!'
                : 'Answer wisely to earn points and climb the leaderboard.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            children: [
              _HeroPill(
                icon: Icons.timer_outlined,
                label: schedule != null
                    ? '${schedule.durationMinutes} min'
                    : 'Timed',
              ),
              const SizedBox(width: AppDimensions.sm),
              _HeroPill(
                icon: Icons.emoji_events_outlined,
                label: (schedule?.attemptsAllowed ?? 1) > 1
                    ? '${schedule?.attemptsAllowed} attempts'
                    : 'One chance',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic schedule, bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.question_answer_rounded,
          value: '${schedule?.totalQuestions ?? 0}',
          label: 'Questions',
          color: AppColors.primaryBlue,
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.sm),
        _buildStatCard(
          icon: Icons.timer_rounded,
          value: '${schedule?.durationMinutes ?? 0}m',
          label: 'Duration',
          color: AppColors.primaryAmber,
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.sm),
        _buildStatCard(
          icon: Icons.stars_rounded,
          value: schedule?.allowRetry == true ? 'Yes' : 'No',
          label: 'Retry',
          color: AppColors.success,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
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
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          _InfoRow(
            icon: Icons.bolt_rounded,
            color: AppColors.primaryAmber,
            text: 'Answer quickly for bonus points',
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.sm),
          _InfoRow(
            icon: Icons.verified_rounded,
            color: AppColors.success,
            text: 'Correct answers earn you points',
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.sm),
          _InfoRow(
            icon: Icons.lock_clock_rounded,
            color: AppColors.error,
            text: scheduleRetryNote,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildAction(context, isDark),
        ],
      ),
    );
  }

  /// The Start button only appears once the quiz window is actually open.
  /// Before that we count down to the start time; afterwards we report that the
  /// window has closed.
  Widget _buildAction(BuildContext context, bool isDark) {
    final schedule = _schedule;
    if (schedule == null) {
      return _StatusNotice(
        icon: Icons.hourglass_empty_rounded,
        text: 'This quiz schedule is still loading.',
        isDark: isDark,
      );
    }

    final now = DateTime.now();
    if (now.isBefore(schedule.startDateTime)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusNotice(
            icon: Icons.lock_clock_rounded,
            text:
                '${_strings.notStartedYet} · '
                '${_strings.startsInLabel(schedule.startDateTime.difference(now))}',
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          _RefreshButton(label: 'Refresh', isDark: isDark, onTap: _reload),
        ],
      );
    }

    if (schedule.isEndedAt(now)) {
      return _StatusNotice(
        icon: Icons.event_busy_rounded,
        text: 'This quiz has ended. Results are no longer available.',
        isDark: isDark,
      );
    }

    return _buildStartButton(context, isDark);
  }

  String get scheduleRetryNote {
    final schedule = _schedule;
    return schedule?.allowRetry == true
        ? 'You can retry if you do not pass'
        : 'No retries — give it your best shot!';
  }

  Widget _buildStartButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: _loading ? null : _startQuiz,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: AppDimensions.sm),
                        Text(
                          'Start Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: AppColors.primaryAmber,
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                'Quiz Completed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'You have already completed this quiz.\nNo retries are available for this one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: const Text(
              'Back to Quizzes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _StatusNotice({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingMd,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAmber, size: 20),
          const SizedBox(width: AppDimensions.paddingSm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final Future<void> Function() onTap;

  const _RefreshButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppDimensions.paddingSm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
