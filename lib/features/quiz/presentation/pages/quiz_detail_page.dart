import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
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

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    final activeQuiz = await ref
        .read(quizProvider.notifier)
        .startQuiz(widget.quizScheduleId);
    if (!mounted) return;
    setState(() => _loading = false);

    final quizState = ref.read(quizProvider);
    if (activeQuiz == null) {
      if (quizState.blockReason == QuizBlockReason.alreadyCompleted) {
        _celebrateCompleted();
        return;
      }
      if (quizState.message != null && quizState.message!.isNotEmpty) {
        AlertWidget.showError(context, quizState.message!);
      }
      return;
    }
    ref.read(quizProvider.notifier).clearBlockReason();
    context.pushReplacement(RouteNames.quizPlay, extra: activeQuiz.sessionId);
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
    final schedule = quizState.upcomingQuizzes
        .where((q) => q.id == widget.quizScheduleId)
        .firstOrNull;
    final alreadyDone =
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
    final schedule = ref
        .watch(quizProvider)
        .upcomingQuizzes
        .where((q) => q.id == widget.quizScheduleId)
        .firstOrNull;

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
                      alreadyDone ? 'Completed' : '${schedule?.totalQuestions ?? 10} Qs',
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
                label: schedule?.allowRetry == true
                    ? 'Retries allowed'
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
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
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
          _buildStartButton(context, isDark),
        ],
      ),
    );
  }

  String get scheduleRetryNote {
    final schedule = ref
        .watch(quizProvider)
        .upcomingQuizzes
        .where((q) => q.id == widget.quizScheduleId)
        .firstOrNull;
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
                        Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 24),
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
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.4),
            ),
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
