import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../providers/course_detail_provider.dart';

Future<CompleteCourseItemResult?> showQuizAttemptSheet(
  BuildContext context, {
  required String courseId,
  required String itemId,
  required String quizTitle,
  int? questionCount,
  CourseQuizResult? previous,
}) {
  return showModalBottomSheet<CompleteCourseItemResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuizAttemptSheet(
      courseId: courseId,
      itemId: itemId,
      quizTitle: quizTitle,
      questionCount: questionCount,
      previous: previous,
    ),
  );
}

class _QuizAttemptSheet extends ConsumerStatefulWidget {
  final String courseId;
  final String itemId;
  final String quizTitle;
  final int? questionCount;
  final CourseQuizResult? previous;

  const _QuizAttemptSheet({
    required this.courseId,
    required this.itemId,
    required this.quizTitle,
    required this.questionCount,
    required this.previous,
  });

  @override
  ConsumerState<_QuizAttemptSheet> createState() => _QuizAttemptSheetState();
}

class _QuizAttemptSheetState extends ConsumerState<_QuizAttemptSheet> {
  late final TextEditingController _scoreController;
  late final TextEditingController _maxScoreController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final prev = widget.previous;
    _scoreController = TextEditingController(
      text: prev != null ? _trim(prev.score) : '',
    );
    _maxScoreController = TextEditingController(
      text: prev != null && prev.maxScore > 0
          ? _trim(prev.maxScore)
          : (widget.questionCount?.toString() ?? '10'),
    );
  }

  String _trim(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  double get _score => double.tryParse(_scoreController.text) ?? 0;

  double get _maxScore => double.tryParse(_maxScoreController.text) ?? 0;

  double get _percentage =>
      _maxScore > 0 ? (_score / _maxScore * 100).clamp(0, 100) : 0;

  bool get _passed => _percentage >= 70;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPrevious = widget.previous != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXl),
            topRight: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLg,
          AppDimensions.paddingMd,
          AppDimensions.paddingLg,
          AppDimensions.paddingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: AppColors.primaryAmber,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSm + 2),
                Expanded(
                  child: Text(
                    widget.quizTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Enter your quiz score to record this attempt. '
              'Your best percentage is kept.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
            if (hasPrevious) ...[
              const SizedBox(height: AppDimensions.paddingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingSm + 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.previous!.passed
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 16,
                      color: widget.previous!.passed
                          ? AppColors.success
                          : AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Best ${widget.previous!.percentage.round()}% · '
                        '${widget.previous!.attempts} attempt(s)'
                        '${widget.previous!.passed ? ' · Passed' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey[300]
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.paddingMd),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Score',
                      hintText: 'e.g. 8',
                      prefixIcon: const Icon(Icons.grade_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingSm + 2),
                Expanded(
                  child: TextField(
                    controller: _maxScoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Max Score',
                      hintText: 'e.g. 10',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingSm + 4),
              decoration: BoxDecoration(
                color: (_passed && _maxScore > 0
                        ? AppColors.success
                        : AppColors.warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _passed ? Icons.verified_rounded : Icons.timelapse_rounded,
                    size: 18,
                    color: _passed && _maxScore > 0
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    _maxScore > 0
                        ? '${_percentage.round()}% · '
                            '${_passed ? 'Passing score' : 'Needs 70% to pass'}'
                        : 'Enter score and max score',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton.icon(
                onPressed:
                    (_submitting || _maxScore <= 0) ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: Text(
                  _submitting ? 'Saving...' : 'Record Attempt',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result =
        await ref.read(courseDetailProvider(widget.courseId).notifier).completeItem(
              widget.itemId,
              score: _score,
              maxScore: _maxScore,
            );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }
}
