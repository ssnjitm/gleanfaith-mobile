import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_providers.dart';
import '../providers/course_quiz_attempts.dart';

class CourseQuizReviewPage extends ConsumerStatefulWidget {
  final CourseQuizReviewArgs? args;

  const CourseQuizReviewPage({super.key, required this.args});

  @override
  ConsumerState<CourseQuizReviewPage> createState() =>
      _CourseQuizReviewPageState();
}

class _CourseQuizReviewPageState extends ConsumerState<CourseQuizReviewPage> {
  CourseQuizSet? _quiz;
  CourseQuizAttempt? _attempt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = widget.args;
    if (a == null) {
      setState(() {
        _loading = false;
        _error = 'Missing quiz details';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final best = await ref
        .read(courseQuizAttemptsProvider.notifier)
        .bestFor(a.itemId);
    final result = await ref
        .read(getCourseQuizUseCaseProvider)
        .call(a.refId)
        .run();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = best != null ? null : f.message;
      }),
      (quiz) => setState(() {
        _loading = false;
        _quiz = quiz;
        _attempt = best;
      }),
    );
  }

  Future<void> _reAttempt() async {
    final a = widget.args;
    if (a == null) return;
    final result = await context.push<Object?>(
      RouteNames.courseQuizPlay,
      extra: CourseQuizPlayArgs(
        courseId: a.courseId,
        itemId: a.itemId,
        refId: a.refId,
        title: a.title,
        attemptsBefore: 0,
        lessonContentArgs: a.lessonContentArgs,
      ),
    );
    await _load();
    if (result is CompleteCourseItemResult && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _readLesson() {
    final target = widget.args?.lessonContentArgs;
    if (target == null) return;
    context.push(RouteNames.courseContent, extra: target);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: Text(
          a?.title ?? 'Review',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return _buildSummarySkeleton(isDark);

    if (_quiz == null) {
      return AppErrorWidget(
        message: _error ?? 'Could not load review',
        onRetry: _load,
      );
    }

    final quiz = _quiz!;
    final attempt = _attempt;
    final bestPct = attempt?.percentage.round() ?? 0;
    final passed = attempt?.passed ?? false;

    return Column(
      children: [
        _buildSummaryCard(bestPct, passed, quiz, isDark),
        Expanded(
          child: _attempt == null
              ? _buildNoAttempt(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingMd,
                    AppDimensions.sm,
                    AppDimensions.paddingMd,
                    AppDimensions.paddingLg,
                  ),
                  itemCount: quiz.questions.length,
                  itemBuilder: (context, index) =>
                      _buildQuestionReview(quiz, index),
                ),
        ),
        _buildBottomBar(isDark),
      ],
    );
  }

  Widget _buildSummaryCard(
    int bestPct,
    bool passed,
    CourseQuizSet quiz,
    bool isDark,
  ) {
    final attempt = _attempt;
    final answered = attempt?.answeredCount ?? 0;
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMd),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: CircularProgressIndicator(
                  value: attempt == null ? 0 : (bestPct / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor:
                      isDark ? const Color(0xFF0F172A) : AppColors.bgGray,
                  color: passed ? AppColors.success : AppColors.error,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                attempt == null ? '—' : '$bestPct%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed && attempt != null ? 'Passed!' : 'Best attempt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attempt == null
                      ? 'No attempts recorded yet.'
                      : 'Best ${attempt.score.round()} / ${attempt.maxScore.round()} pts · '
                          '$answered/${quiz.questions.length} answered',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAttempt(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 56,
            color: isDark ? Colors.grey[600] : AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            'Take this quiz first to build a review.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(CourseQuizSet quiz, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = quiz.questions[index];
    final attempts = _attempt?.answers ?? const <int?>[];
    final userAnswer =
        index < attempts.length ? attempts[index] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (userAnswer == null)
                const Text(
                  'Not answered',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                )
              else if (userAnswer == q.correctAnswerIndex)
                const Text(
                  'Correct',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                )
              else
                const Text(
                  'Incorrect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            q.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          ...List.generate(q.options.length, (i) {
            final isCorrectOption = i == q.correctAnswerIndex;
            final isUserChoice = userAnswer == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSm + 2,
                vertical: AppDimensions.sm,
              ),
              decoration: BoxDecoration(
                color: isCorrectOption
                    ? AppColors.success.withValues(alpha: 0.08)
                    : (isUserChoice
                        ? AppColors.error.withValues(alpha: 0.08)
                        : (isDark ? const Color(0xFF0F172A) : AppColors.bgGray)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isCorrectOption
                      ? AppColors.success.withValues(alpha: 0.6)
                      : (isUserChoice
                          ? AppColors.error.withValues(alpha: 0.6)
                          : (isDark
                              ? const Color(0xFF334155)
                              : AppColors.borderLight)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrectOption
                        ? Icons.check_circle_rounded
                        : (isUserChoice
                            ? Icons.cancel_rounded
                            : Icons.radio_button_unchecked_rounded),
                    size: 18,
                    color: isCorrectOption
                        ? AppColors.success
                        : (isUserChoice ? AppColors.error : AppColors.textLight),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: isCorrectOption || isUserChoice
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              q.explanation!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _reAttempt,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Re-attempt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.args?.lessonContentArgs != null) ...[
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _readLesson,
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text('Read Lesson'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
        ),
      ],
    );
  }
}