import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_detail_provider.dart';
import '../providers/course_providers.dart';
import '../providers/course_quiz_attempts.dart';

class CourseQuizPlayPage extends ConsumerStatefulWidget {
  const CourseQuizPlayPage({super.key, required this.args});

  final CourseQuizPlayArgs? args;

  @override
  ConsumerState<CourseQuizPlayPage> createState() =>
      _CourseQuizPlayPageState();
}

class _CourseQuizPlayPageState extends ConsumerState<CourseQuizPlayPage> {
  CourseQuizSet? _set;
  String? _loadError;

  final PageController _pageController = PageController();
  final List<int?> _answers = [];
  int _current = 0;
  int _answeredCount = 0;

  bool _completing = false;
  String? _completeError;
  CompleteCourseItemResult? _result;
  CourseQuizAttempt? _bestAfter;
  bool _isNewBest = false;

  CourseQuizSet? get _quiz => _set;
  double get _progress => _quiz == null || _quiz!.questions.isEmpty
      ? 0
      : (_current + 1) / _quiz!.questions.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final args = widget.args;
    if (args == null) {
      setState(() => _loadError = 'Missing quiz details');
      return;
    }
    final result = await ref
        .read(getCourseQuizUseCaseProvider)
        .call(args.refId)
        .run();
    result.fold(
      (f) {
        if (mounted) setState(() => _loadError = f.message);
      },
      (set) {
        if (set.questions.isEmpty) {
          if (mounted) {
            setState(() => _loadError = 'This quiz has no questions yet');
          }
          return;
        }
        if (mounted) {
          setState(() {
            _set = set;
            _answers.clear();
            _answers.addAll(List<int?>.filled(set.questions.length, null));
          });
        }
      },
    );
  }

  void _select(int index) {
    if (_completing || _set == null) return;
    if (_answers[_current] != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _answers[_current] = index;
      _answeredCount += 1;
    });
  }

  void _goTo(int index) {
    if (index < 0 || index >= (_quiz?.questions.length ?? 0)) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    final args = widget.args;
    if (args == null || _quiz == null || _completing) return;
    setState(() {
      _completing = true;
      _completeError = null;
    });
    final score = _computeScore();
    final maxScore = _quiz!.maxScore;
    final snapshot = List<int?>.of(_answers);
    final notifier = ref.read(courseQuizAttemptsProvider.notifier);
    final isNewBest = await notifier.isNewBest(args.itemId, score);

    CompleteCourseItemResult? result;
    if (isNewBest) {
      result = await ref
          .read(courseDetailProvider(args.courseId).notifier)
          .completeItem(
            args.itemId,
            score: score,
            maxScore: maxScore,
          );
      if (result == null) {
        if (mounted) {
          setState(() {
            _completing = false;
            _completeError = 'Failed to save score. Try again.';
          });
        }
        return;
      }
      await notifier.saveBest(
        args.itemId,
        CourseQuizAttempt(
          score: score,
          maxScore: maxScore,
          answers: snapshot,
          attemptedAt: DateTime.now(),
        ),
      );
    }

    final bestNow = await ref
        .read(courseQuizAttemptsProvider.notifier)
        .bestFor(args.itemId);
    if (!mounted) return;
    setState(() {
      _completing = false;
      _result = result;
      _bestAfter = bestNow ??
          CourseQuizAttempt(
            score: score,
            maxScore: maxScore,
            answers: snapshot,
            attemptedAt: DateTime.now(),
          );
      _isNewBest = isNewBest;
    });
  }

  double _computeScore() {
    if (_quiz == null) return 0;
    double score = 0;
    for (int i = 0; i < _quiz!.questions.length; i++) {
      final q = _quiz!.questions[i];
      final selected = _answers.length > i ? _answers[i] : null;
      if (selected == null) continue;
      if (selected == q.correctAnswerIndex) score += q.points;
    }
    return score;
  }

  void _restart() {
    final quiz = _quiz;
    if (quiz == null) return;
    setState(() {
      _answers.clear();
      _answers.addAll(List<int?>.filled(quiz.questions.length, null));
      _answeredCount = 0;
      _current = 0;
      _result = null;
      _bestAfter = null;
      _isNewBest = false;
      _completeError = null;
    });
    _pageController.jumpToPage(0);
  }

  Future<void> _openReview() async {
    final args = widget.args;
    if (args == null) return;
    await context.push(
      RouteNames.courseQuizReview,
      extra: CourseQuizReviewArgs(
        courseId: args.courseId,
        itemId: args.itemId,
        refId: args.refId,
        title: args.title,
        lessonContentArgs: args.lessonContentArgs,
      ),
    );
  }

  void _readLesson() {
    final args = widget.args;
    final target = args?.lessonContentArgs;
    if (target == null) return;
    context.push(RouteNames.courseContent, extra: target);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _result != null) {
          Navigator.of(context).pop(_result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            args?.title ?? 'Quiz',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null && _quiz == null) {
      return AppErrorWidget(
        message: _loadError!,
        onRetry: () => setState(() {
          _loadError = null;
          _load();
        }),
      );
    }
    if (_quiz == null) return const AppLoading();
    if (_result != null || _bestAfter != null) return _buildResult();
    return _buildPlaying();
  }

  Widget _buildPlaying() {
    final quiz = _quiz!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingMd,
            4,
            AppDimensions.paddingMd,
            8,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '$_answeredCount/${quiz.questions.length} answered',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_current + 1}/${quiz.questions.length}',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
                  color: AppColors.primaryBlue,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: quiz.questions.length,
            onPageChanged: (index) {
              if (mounted) setState(() => _current = index);
            },
            itemBuilder: (context, index) {
              return _buildQuestionPage(quiz, index, isDark);
            },
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildQuestionPage(CourseQuizSet quiz, int index, bool isDark) {
    final q = quiz.questions[index];
    final selected = _answers.length > index ? _answers[index] : null;
    final answered = selected != null;
    final isCorrect = answered && selected == q.correctAnswerIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.sm,
        AppDimensions.paddingMd,
        AppDimensions.paddingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (q.points != 1) ...[
                const SizedBox(width: AppDimensions.sm),
                Text(
                  '${q.points.round()} pts',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              if (answered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isCorrect ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_rounded : Icons.close_rounded,
                        size: 13,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isCorrect ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            q.text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          ...List.generate(q.options.length, (i) {
            final isThis = selected == i;
            final isCorrectOption = i == q.correctAnswerIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: _optionTile(
                letter: String.fromCharCode(65 + i),
                text: q.options[i],
                isThis: isThis,
                answered: answered,
                isCorrectOption: isCorrectOption,
                onTap: () => _select(i),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String letter,
    required String text,
    required bool isThis,
    required bool answered,
    required bool isCorrectOption,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color? borderColor;
    Color? circleColor;
    IconData? markIcon;
    Color? markColor;
    Color? tileColor;

    if (answered) {
      if (isCorrectOption) {
        borderColor = AppColors.success;
        circleColor = AppColors.success;
        markIcon = Icons.check_rounded;
        markColor = AppColors.success;
        tileColor = AppColors.success.withValues(alpha: 0.06);
      } else if (isThis) {
        borderColor = AppColors.error;
        circleColor = AppColors.error;
        markIcon = Icons.close_rounded;
        markColor = AppColors.error;
        tileColor = AppColors.error.withValues(alpha: 0.06);
      }
    } else if (isThis) {
      borderColor = AppColors.primaryBlue;
      circleColor = AppColors.primaryBlue;
    }

    return Material(
      color: tileColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
            vertical: AppDimensions.paddingSm + 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: borderColor ??
                  (isDark ? const Color(0xFF334155) : AppColors.borderLight),
              width: borderColor != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: circleColor ??
                      AppColors.primaryBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: markIcon != null
                      ? Icon(markIcon,
                          size: 18, color: markColor ?? Colors.white)
                      : Text(
                          letter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: circleColor != null
                                ? Colors.white
                                : AppColors.primaryBlue,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isThis
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final quiz = _quiz;
    if (quiz == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFirst = _current == 0;
    final isLast = _current == quiz.questions.length - 1;

    Widget buildButton({
      required String label,
      required Widget? icon,
      required VoidCallback? onPressed,
      bool primary = false,
    }) {
      if (primary) {
        return Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon ?? const SizedBox.shrink(),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : AppColors.borderLight,
                disabledForegroundColor:
                    isDark ? Colors.white38 : AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
            ),
          ),
        );
      }
      return Expanded(
        child: SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon ?? const SizedBox.shrink(),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_completeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: Text(
                  _completeError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12.5,
                  ),
                ),
              ),
            Row(
              children: [
                if (_completing)
                  const Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else ...[
                  if (!isFirst) ...[
                    buildButton(
                      label: 'Prev',
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: () => _goTo(_current - 1),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                  ],
                  if (isLast)
                    buildButton(
                      label: 'Finish',
                      icon: const Icon(Icons.check_rounded, size: 20),
                      primary: true,
                      onPressed: _submit,
                    )
                  else
                    buildButton(
                      label: 'Next',
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      primary: true,
                      onPressed: () => _goTo(_current + 1),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempt = _bestAfter!;
    final pct = attempt.percentage.round();
    final passed = attempt.passed;
    final thisPct = _computeScore();
    final thisMax = _quiz!.maxScore;
    final thisPctValue =
        thisMax > 0 ? (thisPct / thisMax * 100).round() : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: (attempt.percentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 11,
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
                      color: passed ? AppColors.success : AppColors.error,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: passed ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const Text(
                        'Best score',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd,
                vertical: AppDimensions.paddingSm,
              ),
              decoration: BoxDecoration(
                color: passed
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: Text(
                _isNewBest
                    ? (passed ? 'New best score! You passed!' : 'New best score!')
                    : (passed ? 'Best score kept — keep practicing!' : 'Not this time'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              'This attempt: $thisPctValue% (${thisPct.round()} / ${thisMax.round()} pts) · '
              '$_answeredCount/${_quiz!.questions.length} answered',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
            if (_result?.newlyAwarded == true) ...[
              const SizedBox(height: AppDimensions.paddingLg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMd,
                  vertical: AppDimensions.paddingSm + 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: AppColors.primaryAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.primaryAmber, size: 22),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      '+${_result!.pointsEarned} XP earned',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result?.courseCompleted == true) ...[
              const SizedBox(height: AppDimensions.paddingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMd,
                  vertical: AppDimensions.paddingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: AppColors.primaryBlue, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Course Completed!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _completing ? null : _openReview,
                    icon: const Icon(Icons.fact_check_outlined, size: 20),
                    label: const Text('Review Attempt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _completing ? null : _restart,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Re-attempt Quiz'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                  ),
                ),
                if (widget.args?.lessonContentArgs != null) ...[
                  const SizedBox(height: AppDimensions.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _completing ? null : _readLesson,
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
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_result),
                  child: const Text('Back to Course'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}