import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_detail_provider.dart';
import '../providers/course_providers.dart';

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
    HapticFeedback.selectionClick();
    final wasAnswered = _answers[_current] != null;
    setState(() {
      _answers[_current] = index;
      _answeredCount += wasAnswered ? 0 : 1;
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
    final result = await ref
        .read(courseDetailProvider(args.courseId).notifier)
        .completeItem(
          args.itemId,
          score: score,
          maxScore: maxScore,
        );
    if (!mounted) return;
    setState(() {
      _completing = false;
      _result = result;
      if (result == null) _completeError = 'Failed to save score';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          actions: [
            if (_quiz != null && _result == null)
              IconButton(
                tooltip: 'Skip and finish',
                onPressed: _completing ? null : _submit,
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
          ],
          elevation: 0,
        ),
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
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
    if (_result != null) return _buildResult(isDark);
    return _buildPlaying(isDark);
  }

  Widget _buildPlaying(bool isDark) {
    final quiz = _quiz!;

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
        _buildBottomBar(isDark),
      ],
    );
  }

  Widget _buildQuestionPage(CourseQuizSet quiz, int index, bool isDark) {
    final q = quiz.questions[index];
    final selected = _answers.length > index ? _answers[index] : null;

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
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
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
              if (selected != null)
                const Text(
                  'Answered',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
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
            final isSelected = selected == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: Material(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                elevation: isSelected ? 2 : 1,
                shadowColor: AppColors.shadowLight,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusLg),
                  onTap: () => _select(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd,
                      vertical: AppDimensions.paddingSm + 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark
                                ? const Color(0xFF334155)
                                : AppColors.borderLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue
                                    .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final quiz = _quiz;
    if (quiz == null) return const SizedBox.shrink();
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
                color: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderLight,
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
                  buildButton(
                    label: isFirst ? 'Prev' : 'Prev',
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: isFirst
                        ? null
                        : () => _goTo(_current - 1),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  if (isLast)
                    buildButton(
                      label: 'Finish',
                      icon: const Icon(Icons.check_rounded, size: 20),
                      primary: true,
                      onPressed: _submit,
                    )
                  else
                    buildButton(
                      label: _current == quiz.questions.length - 2
                          ? 'Finish'
                          : 'Next',
                      icon: Icon(
                        _current == quiz.questions.length - 2
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      primary: true,
                      onPressed: _current == quiz.questions.length - 2
                          ? _submit
                          : () => _goTo(_current + 1),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final r = _result!;
    final score = _computeScore();
    final maxScore = _quiz!.maxScore;
    final pct = maxScore > 0 ? (score / maxScore * 100).round() : 0;
    final passed = pct >= 70;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 10,
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
                      color: passed ? AppColors.success : AppColors.error,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
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
                passed ? 'Great job! You passed!' : 'Keep practicing!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: passed ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Text(
              '${score.round()} / ${maxScore.round()} points · '
              '$_answeredCount/${_quiz!.questions.length} answered',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
            if (r.newlyAwarded) ...[
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
                      '+${r.pointsEarned} XP earned',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (r.courseCompleted) ...[
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
            if (r.level != null) ...[
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                'Level ${r.level!.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: const Text(
                  'Back to Course',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}