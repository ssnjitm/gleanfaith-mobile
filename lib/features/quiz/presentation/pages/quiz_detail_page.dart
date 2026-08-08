import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../providers/quiz_provider.dart';

class QuizDetailPage extends ConsumerStatefulWidget {
  final String quizScheduleId;

  const QuizDetailPage({super.key, required this.quizScheduleId});

  @override
  ConsumerState<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends ConsumerState<QuizDetailPage> {
  bool _loading = false;

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    final activeQuiz = await ref
        .read(quizProvider.notifier)
        .startQuiz(widget.quizScheduleId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (activeQuiz == null) {
      final message = ref.read(quizProvider).message;
      if (message != null && message.isNotEmpty) {
        AlertWidget.showError(context, message);
      }
      return;
    }
    context.pushReplacement(RouteNames.quizPlay, extra: activeQuiz.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = quizState.upcomingQuizzes
        .where((q) => q.id == widget.quizScheduleId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: AppDimensions.paddingMd),
                  Text(
                    schedule?.title ?? 'Bible Quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (schedule != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      '${schedule.totalQuestions} questions · '
                      '${schedule.durationMinutes} minutes · '
                      '${schedule.allowRetry ? "Retries allowed" : "No retries"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Flexible(
              child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: AppColors.primaryAmber,
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    Text(
                      'Ready to begin?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'Answer carefully. Your score and progress '
                      'have been noted. Take your time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            FilledButton(
              onPressed: _loading ? null : _startQuiz,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}