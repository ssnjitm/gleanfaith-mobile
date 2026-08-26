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

  int _index = 0;
  int? _selected;
  bool _answered = false;

  bool _completing = false;
  String? _completeError;
  CompleteCourseItemResult? _result;

  CourseQuizSet? get _quiz => _set;
  bool get _isLast => _index >= (_quiz?.questions.length ?? 0) - 1;
  double get _progress => _quiz == null || _quiz!.questions.isEmpty
      ? 0
      : (_index + (_answered ? 1 : 0)) / _quiz!.questions.length;

  @override
  void initState() {
    super.initState();
    _load();
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
          if (mounted) setState(() => _loadError = 'This quiz has no questions yet');
          return;
        }
        if (mounted) setState(() => _set = set);
      },
    );
  }

  void _confirm() {
    if (_selected == null || _answered) return;
    HapticFeedback.selectionClick();
    setState(() => _answered = true);
  }

  void _next() {
    if (_isLast) {
      _submit();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  Future<void> _submit() async {
    final args = widget.args;
    if (args == null || _quiz == null) return;
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
      if (i < _selectedAnswers.length && _selectedAnswers[i] == q.correctAnswerIndex) {
        score += q.points;
      }
    }
    return score;
  }

  final List<int?> _selectedAnswers = [];

  void _recordAnswer() {
    while (_selectedAnswers.length <= _index) {
      _selectedAnswers.add(null);
    }
    _selectedAnswers[_index] = _selected;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = widget.args;

    ref.listen(courseDetailProvider(args?.courseId ?? '').notifier, (_, _) {});

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
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loadError != null && _quiz == null) {
      return AppErrorWidget(
        message: _loadError!,
        onRetry: () => setState(() { _loadError = null; _load(); }),
      );
    }
    if (_quiz == null) return const AppLoading();
    if (_result != null) return _buildResult(isDark);
    return _buildPlaying(isDark);
  }

  Widget _buildPlaying(bool isDark) {
    final quiz = _quiz!;
    final q = quiz.questions[_index];
    final locked = _answered;

    final optionColors = List<Color?>.generate(q.options.length, (i) {
      if (!locked) return null;
      final correct = i == q.correctAnswerIndex;
      final wrong = i == _selected && !correct;
      if (correct) return AppColors.success.withValues(alpha: 0.12);
      if (wrong) return AppColors.error.withValues(alpha: 0.1);
      return null;
    });

    final optionBorders = List<Color>.generate(q.options.length, (i) {
      if (!locked) {
        return i == _selected
            ? AppColors.primaryBlue
            : (isDark ? const Color(0xFF334155) : AppColors.borderLight);
      }
      final correct = i == q.correctAnswerIndex;
      final wrong = i == _selected && !correct;
      if (correct) return AppColors.success;
      if (wrong) return AppColors.error;
      return isDark ? const Color(0xFF334155) : AppColors.borderLight;
    });

    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.bgGray,
          color: AppColors.primaryBlue,
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
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
                        '${_index + 1}/${quiz.questions.length}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: Material(
                      color: optionColors[i] ??
                          (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      elevation: _selected == i && !locked ? 2 : 0,
                      shadowColor: AppColors.shadowLight,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        onTap: locked
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _selected = i);
                              },
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
                              color: optionBorders[i],
                              width: (_selected == i || locked && i == q.correctAnswerIndex) ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _badgeColor(
                                    locked,
                                    i == q.correctAnswerIndex,
                                    i == _selected && !locked,
                                    _selected == i && locked &&
                                        i != q.correctAnswerIndex,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: (locked && i == q.correctAnswerIndex) ||
                                              (locked && _selected == i && i != q.correctAnswerIndex)
                                          ? Colors.white
                                          : (_selected == i
                                              ? Colors.white
                                              : AppColors.primaryBlue),
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
                                    fontWeight: _selected == i
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (locked && i == q.correctAnswerIndex)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 22)
                              else if (locked &&
                                  _selected == i &&
                                  i != q.correctAnswerIndex)
                                const Icon(Icons.cancel_rounded,
                                    color: AppColors.error, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (_answered && q.explanation != null && q.explanation!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingMd),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_rounded,
                            size: 20, color: AppColors.primaryAmber),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            q.explanation!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildBottomBar(locked, isDark),
      ],
    );
  }

  Widget _buildBottomBar(bool locked, bool isDark) {
    final label = _completing
        ? 'Submitting...'
        : locked
            ? (_isLast ? 'Finish Quiz' : 'Next Question')
            : 'Confirm Answer';
    final enabled = _completing
        ? false
        : locked
            ? true
            : _selected != null;

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
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: enabled
                    ? () {
                        if (!_answered) {
                          _recordAnswer();
                          _confirm();
                        } else {
                          _next();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? const Color(0xFF1E293B) : AppColors.borderLight,
                  disabledForegroundColor:
                      isDark ? Colors.white38 : AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: _completing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
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
              '${score.round()} / ${maxScore.round()} points',
              style: TextStyle(
                fontSize: 15,
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

  Color _badgeColor(bool locked, bool correct, bool selected, bool wrongSelected) {
    if (locked && correct) return AppColors.success;
    if (wrongSelected) return AppColors.error;
    if (selected) return AppColors.primaryBlue;
    return AppColors.primaryBlue.withValues(alpha: 0.12);
  }
}
