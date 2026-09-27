import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/common/widgets/shimmer_placeholders.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';
import '../providers/daily_quiz_provider.dart';
import '../providers/quiz_language_provider.dart';
import '../providers/quiz_provider.dart';
import 'quiz_language_toggle.dart';

class DailyQuizHeroCard extends ConsumerStatefulWidget {
  const DailyQuizHeroCard({super.key});

  @override
  ConsumerState<DailyQuizHeroCard> createState() => _DailyQuizHeroCardState();
}

class _DailyQuizHeroCardState extends ConsumerState<DailyQuizHeroCard> {
  static const double _minHeight = 220;
  static const Color _darkStart = Color(0xFF1E3A5F);
  static const Color _darkEnd = Color(0xFF1A1A2E);
  static const Color _lightEnd = Color(0xFF7C3AED);

  Timer? _ticker;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyQuizProvider);
    final strings = ref.watch(quizStringsProvider);

    if (state.status == DailyQuizStatus.initial ||
        state.status == DailyQuizStatus.loading) {
      return const DailyQuizHeroShimmer();
    }

    if (state.status == DailyQuizStatus.error) {
      return _buildSurface(
        child: _buildMessage(
          icon: Icons.cloud_off_rounded,
          title: strings.loadFailed,
          message: state.message ?? strings.loadFailedHint,
          action: _buildRetryButton(strings),
        ),
      );
    }

    final today = state.today;
    if (state.status == DailyQuizStatus.empty || today == null) {
      return _buildSurface(
        child: _buildMessage(
          icon: Icons.calendar_today_rounded,
          title: strings.noQuizToday,
          message: strings.noQuizTodayHint,
        ),
      );
    }

    if (state.attemptUsed) {
      return _buildSurface(
        child: _buildMessage(
          icon: Icons.verified_rounded,
          title: strings.attemptUsed,
          message: strings.attemptUsedHint,
        ),
      );
    }

    return _buildAvailable(state, today, strings);
  }

  Widget _buildAvailable(
    DailyQuizState state,
    QuizSchedule today,
    QuizStrings strings,
  ) {
    final streak = _computeStreak(state.upcoming);
    final now = DateTime.now();
    final canStart = !today.isEndedAt(now);

    return _buildSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBadge(),
              const SizedBox(width: AppDimensions.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.dailyQuiz,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.dailyTagline,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0) _StreakChip(label: strings.dayCount(streak)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            children: [
              _CountdownPill(
                label: strings.remainingLabel(
                  today.endDateTime.difference(now),
                ),
              ),
              const Spacer(),
              const QuizLanguageToggle(onGradient: true),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          Row(
            children: [
              Text(
                today.totalQuestions > 0
                    ? '${today.totalQuestions} ${strings.questions}'
                    : strings.dailyChallenge,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              const _OneAttemptChip(),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          _StartButton(
            isLoading: _isStarting,
            label: strings.startNow,
            onTap: canStart && today.id.isNotEmpty
                ? () => _startToday(today)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSurface({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [_darkStart, _darkEnd]
              : [AppColors.primaryBlue, _lightEnd],
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
        child: child,
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: AppDimensions.paddingMd),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMd),
        Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: AppDimensions.paddingMd),
          action,
        ],
      ],
    );
  }

  Widget _buildRetryButton(QuizStrings strings) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(dailyQuizProvider.notifier).loadDailyQuiz();
        },
        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
        label: Text(
          strings.retry,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }

  /// Starts the daily session and hands the whole session to the play page.
  ///
  /// Every failure path now produces user feedback — previously an empty
  /// server message made the button look completely dead.
  Future<void> _startToday(QuizSchedule today) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    final strings = ref.read(quizStringsProvider);
    final language = ref.read(dailyQuizLanguageProvider);

    final activeQuiz = await ref
        .read(quizProvider.notifier)
        .startQuiz(today.id, language: language);
    if (!mounted) return;
    setState(() => _isStarting = false);

    if (activeQuiz == null) {
      _handleStartFailure(today, strings);
      return;
    }

    if (activeQuiz.sessionId.isEmpty || activeQuiz.questions.isEmpty) {
      AlertWidget.showError(
        context,
        'The quiz could not be loaded. Please try again.',
      );
      return;
    }

    await context.push(
      RouteNames.quizPlay,
      extra: QuizPlayArgs.from(activeQuiz, schedule: today, language: language),
    );
  }

  void _handleStartFailure(QuizSchedule today, QuizStrings strings) {
    final quizState = ref.read(quizProvider);
    final message = quizState.message ?? '';

    switch (quizState.blockReason) {
      case QuizBlockReason.alreadyCompleted:
      case QuizBlockReason.attemptsExhausted:
        ref.read(dailyQuizProvider.notifier).markAttemptUsed();
        ref.read(quizProvider.notifier).markAttempted(today.id);
        AlertWidget.showInfo(context, strings.attemptUsedHint);
        return;
      case QuizBlockReason.notAvailable:
        AlertWidget.showWarning(
          context,
          message.isEmpty ? 'This quiz is not available right now.' : message,
        );
        return;
      case QuizBlockReason.none:
        AlertWidget.showError(
          context,
          message.isEmpty
              ? 'Could not start the quiz. Please try again.'
              : message,
        );
        return;
    }
  }

  int _computeStreak(List<QuizSchedule> upcoming) {
    return upcoming.where((quiz) => quiz.isEndedAt(DateTime.now())).length;
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({this.icon = Icons.bolt_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: AppDimensions.iconMd),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final String label;

  const _StreakChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: AppDimensions.xs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OneAttemptChip extends ConsumerWidget {
  const _OneAttemptChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(quizStringsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.looks_one_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 3),
          Text(
            strings.oneAttemptOnly,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  final String label;

  const _CountdownPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, color: Colors.white, size: 13),
          const SizedBox(width: AppDimensions.xs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onTap;

  const _StartButton({
    required this.isLoading,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: Material(
        color: Colors.white.withValues(alpha: enabled ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: enabled ? 1 : 0.6,
                          ),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(
                          alpha: enabled ? 1 : 0.6,
                        ),
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
