import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../providers/quiz_provider.dart';
import '../../domain/entities/quiz_entities.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final String sessionId;

  const QuizPlayPage({super.key, required this.sessionId});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _submitting = false;
  AnswerResult? _lastAnswer;
  Timer? _timer;
  int _elapsedSeconds = 0;
  final Stopwatch _stopwatch = Stopwatch();

  ActiveQuiz? get _activeQuiz => ref.read(quizProvider).activeQuiz;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  bool get _isLast {
    final quiz = _activeQuiz;
    return quiz != null && _currentIndex >= quiz.questions.length - 1;
  }

  Future<void> _submitAnswer() async {
    final quiz = _activeQuiz;
    if (quiz == null || _selectedOption == null || _submitting) return;
    setState(() => _submitting = true);

    final timeSpent = _stopwatch.elapsed.inSeconds;
    final result = await ref
        .read(quizProvider.notifier)
        .submitAnswer(
          sessionId: widget.sessionId,
          questionIndex: _currentIndex,
          selectedOptionIndex: _selectedIndex!,
          timeSpentSeconds: timeSpent,
        );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _lastAnswer = result;
    });
  }

  int? get _selectedIndex => _selectedOption;

  Future<void> _goNext() async {
    if (_lastAnswer == null) return;
    if (!_isLast) {
      setState(() {
        _currentIndex += 1;
        _selectedOption = null;
        _lastAnswer = null;
      });
    } else {
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    final result = await ref
        .read(quizProvider.notifier)
        .completeQuiz(widget.sessionId);
    if (!mounted) return;
    ref.read(quizProvider.notifier).clearActiveQuiz();
    context.pushReplacement(RouteNames.quizResult, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _activeQuiz;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (quiz == null || quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = quiz.questions[_currentIndex];
    final total = quiz.questions.length;
    final progress = (_currentIndex / total).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentIndex + 1} of $total'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            isDark ? const Color(0xFF334155) : AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryAmber,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                children: [
                  _buildQuestionCard(context, question, isDark),
                  const SizedBox(height: AppDimensions.paddingLg),
                  _buildOptions(context, question, isDark),
                  if (_lastAnswer != null) ...[
                    const SizedBox(height: AppDimensions.paddingMd),
                    _buildFeedback(context, _lastAnswer!, isDark),
                  ],
                ],
              ),
            ),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizQuestion q, bool isDark) {
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
      child: Text(
        q.text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, QuizQuestion q, bool isDark) {
    return Column(
      children: List.generate(q.options.length, (index) {
        final option = q.options[index];
        final isSelected = index == _selectedOption;
        final isCorrect =
            _lastAnswer != null && index == _lastAnswer!.correctAnswerIndex;
        final isWrong =
            _lastAnswer != null && isSelected && !_lastAnswer!.isCorrect;

        Color? borderColor;
        if (_lastAnswer != null && isCorrect) borderColor = AppColors.success;
        if (isWrong) borderColor = AppColors.error;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: Material(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: _lastAnswer != null
                  ? null
                  : () => setState(() => _selectedOption = index),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: borderColor ??
                        (isSelected
                            ? AppColors.primaryBlue
                            : (isDark
                                ? const Color(0xFF334155)
                                : AppColors.borderLight)),
                    width: isSelected || borderColor != null ? 2 : 1,
                  ),
                  color: _lastAnswer != null && isCorrect
                      ? AppColors.successBg.withValues(alpha: 0.3)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _optionIcon(index, isSelected, isCorrect, isWrong),
                      color: _optionColor(isSelected, isCorrect, isWrong),
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.paddingMd),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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
    );
  }

  IconData _optionIcon(int index, bool isSelected, bool isCorrect, bool isWrong) {
    if (isCorrect) return Icons.check_circle_rounded;
    if (isWrong) return Icons.cancel_rounded;
    return isSelected
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
  }

  Color _optionColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (isCorrect) return AppColors.success;
    if (isWrong) return AppColors.error;
    return isSelected ? AppColors.primaryBlue : AppColors.textLight;
  }

  Widget _buildFeedback(BuildContext context, AnswerResult answer, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: answer.isCorrect
            ? AppColors.successBg.withValues(alpha: 0.4)
            : AppColors.errorBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: answer.isCorrect ? AppColors.success : AppColors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: answer.isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                answer.isCorrect
                    ? 'Correct! +${answer.pointsEarned} pts'
                    : 'Not quite',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: answer.isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (answer.explanation.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              answer.explanation,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final disabled =
        (_selectedOption == null && _lastAnswer == null) || _submitting;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: disabled
              ? null
              : (_lastAnswer == null ? _submitAnswer : _goNext),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _lastAnswer != null
                      ? (_isLast ? 'Finish Quiz' : 'Next')
                      : 'Submit Answer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}