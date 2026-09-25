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
import '../providers/daily_quiz_provider.dart';
import '../providers/quiz_provider.dart';

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

    if (state.status == DailyQuizStatus.initial ||
        state.status == DailyQuizStatus.loading) {
      return const DailyQuizHeroShimmer();
    }

    if (state.status == DailyQuizStatus.error) {
      return _buildSurface(
        child: _buildMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t load daily quiz',
          message: state.message ?? 'Check your connection and try again.',
          action: _buildRetryButton(),
        ),
      );
    }

    final today = state.today;
    if (state.status == DailyQuizStatus.empty || today == null) {
      return _buildSurface(
        child: _buildMessage(
          icon: Icons.calendar_today_rounded,
          title: 'No Daily Quiz Today',
          message: 'Check back tomorrow for a new challenge.',
        ),
      );
    }

    return _buildAvailable(state, today);
  }

  Widget _buildAvailable(DailyQuizState state, QuizSchedule today) {
    final streak = _computeStreak(state.upcoming);

    return _buildSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBadge(),
              const SizedBox(width: AppDimensions.paddingMd),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Test your knowledge every day',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (streak > 0) _StreakChip(streak: streak),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            children: [
              _CountdownPill(label: _formatRemaining(today.endDateTime)),
              const Spacer(),
              Text(
                today.totalQuestions > 0
                    ? '${today.totalQuestions} questions'
                    : 'Daily challenge',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          _StartButton(
            isLoading: _isStarting,
            onTap: today.id.isEmpty ? null : () => _startToday(today),
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
      mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildRetryButton() {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(dailyQuizProvider.notifier).loadDailyQuiz();
        },
        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
        label: const Text(
          'Retry',
          style: TextStyle(color: Colors.white, fontSize: 13),
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

  Future<void> _startToday(QuizSchedule today) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    final activeQuiz = await ref
        .read(quizProvider.notifier)
        .startQuiz(today.id);
    if (!mounted) return;
    setState(() => _isStarting = false);

    if (activeQuiz == null) {
      final quizState = ref.read(quizProvider);
      if (quizState.blockReason == QuizBlockReason.alreadyCompleted) {
        AlertWidget.showInfo(
          context,
          'You already completed today\'s daily quiz.',
        );
      } else if (quizState.message != null && quizState.message!.isNotEmpty) {
        AlertWidget.showError(context, quizState.message!);
      }
      return;
    }

    await context.push(RouteNames.quizPlay, extra: activeQuiz.sessionId);
  }

  String _formatRemaining(DateTime endDateTime) {
    final remaining = endDateTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Ended';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) return 'Ends in ${days}d ${hours}h';
    if (hours > 0) return 'Ends in ${hours}h ${minutes}m';
    return 'Ends in ${minutes}m';
  }

  int _computeStreak(List<QuizSchedule> upcoming) {
    return upcoming
        .where((quiz) => quiz.endDateTime.isBefore(DateTime.now()))
        .length;
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
  final int streak;

  const _StreakChip({required this.streak});

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
            '$streak day${streak == 1 ? '' : 's'}',
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
  final VoidCallback? onTap;

  const _StartButton({required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
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
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: AppDimensions.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
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
