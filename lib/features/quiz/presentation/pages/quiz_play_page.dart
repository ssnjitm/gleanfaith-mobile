import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../providers/quiz_provider.dart';
import '../../domain/entities/quiz_entities.dart';
import '../widgets/confetti_burst.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final String sessionId;

  const QuizPlayPage({super.key, required this.sessionId});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _submitting = false;
  AnswerResult? _lastAnswer;
  bool _showConfetti = false;

  int _totalScore = 0;
  int _streak = 0;
  int _bestStreak = 0;

  Timer? _timer;
  int _elapsedSeconds = 0;
  final Stopwatch _stopwatch = Stopwatch();

  late final AnimationController _feedbackController;
  late final AnimationController _pointsPopController;

  ActiveQuiz? get _activeQuiz => ref.read(quizProvider).activeQuiz;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pointsPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _feedbackController.dispose();
    _pointsPopController.dispose();
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
          selectedOptionIndex: _selectedOption!,
          timeSpentSeconds: timeSpent,
        );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _lastAnswer = result;
    });

    if (result != null) {
      if (result.isCorrect) {
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
        _totalScore += result.pointsEarned;
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _showConfetti = true);
      } else {
        _streak = 0;
        unawaited(HapticFeedback.lightImpact());
      }
      unawaited(_feedbackController.forward(from: 0));
      unawaited(_pointsPopController.forward(from: 0));
    }
  }

  Future<void> _goNext() async {
    if (_lastAnswer == null) return;
    if (!_isLast) {
      setState(() {
        _currentIndex += 1;
        _selectedOption = null;
        _lastAnswer = null;
        _showConfetti = false;
      });
    } else {
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    setState(() => _submitting = true);
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F5FA),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(context, question, total, isDark),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: ListView(
                        key: ValueKey(_currentIndex),
                        padding: const EdgeInsets.all(AppDimensions.paddingMd),
                        children: [
                          _buildQuestionCard(context, question, isDark),
                          const SizedBox(height: AppDimensions.paddingMd),
                          _buildOptions(context, question, isDark),
                          if (_lastAnswer != null) ...[
                            const SizedBox(height: AppDimensions.paddingSm),
                            _buildFeedback(context, _lastAnswer!, isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
              if (_showConfetti)
                Positioned.fill(
                  child: ConfettiBurst(
                    particleCount: 70,
                    duration: const Duration(milliseconds: 1400),
                    onCompleted: () {
                      if (mounted && _showConfetti) {
                        setState(() => _showConfetti = false);
                      }
                },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    QuizQuestion question,
    int total,
    bool isDark,
  ) {
    final progress = total == 0 ? 0.0 : (_currentIndex / total);
    final time = _formatTime(_elapsedSeconds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : AppColors.borderLight,
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of $total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _streak > 1
                          ? '$_streak streak 🔥'
                          : 'Keep it up!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _streak > 1
                            ? AppColors.primaryAmber
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _ScoreBadge(
                score: _totalScore,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderColor: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderLight,
              ),
              const SizedBox(width: AppDimensions.sm),
              _TimerChip(
                time: time,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderColor: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderLight,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? const Color(0xFF334155) : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 0.7 ? AppColors.success : AppColors.primaryBlue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizQuestion q, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E293B), Color(0xFF273449)]
              : [Colors.white, const Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSm,
                  vertical: AppDimensions.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_alt_rounded,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'QUIZ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                        letterSpacing: 0.5,
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
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
        final locked = _lastAnswer != null;

        Color? borderColor;
        Color? bgColor;
        if (_lastAnswer != null && isCorrect) {
          borderColor = AppColors.success;
          bgColor = AppColors.success.withValues(alpha: 0.12);
        }
        if (isWrong) {
          borderColor = AppColors.error;
          bgColor = AppColors.error.withValues(alpha: 0.1);
        }
        if (locked && !isCorrect && !isWrong && isSelected) {
          borderColor = AppColors.warning;
          bgColor = AppColors.warning.withValues(alpha: 0.1);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(
                parent: _feedbackController,
                curve: const Interval(0, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: Material(
              color: bgColor ??
                  (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              elevation: isSelected || locked ? 0 : 1,
              shadowColor: AppColors.shadowLight,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                onTap: locked
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedOption = index);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMd,
                    vertical: AppDimensions.paddingSm + 4,
                  ),
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
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _optionBadgeColor(isSelected, isCorrect, isWrong),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isCorrect || isWrong
                                  ? Colors.white
                                  : (isSelected
                                      ? Colors.white
                                      : AppColors.primaryBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 22,
                        )
                      else if (isWrong)
                        const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _optionBadgeColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (isCorrect) return AppColors.success;
    if (isWrong) return AppColors.error;
    if (isSelected) return AppColors.primaryBlue;
    return AppColors.primaryBlue.withValues(alpha: 0.12);
  }

  Widget _buildFeedback(BuildContext context, AnswerResult answer, bool isDark) {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _feedbackController,
            curve: Curves.easeIn,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _feedbackController,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: answer.isCorrect
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.error.withValues(alpha: 0.1),
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
                  answer.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: answer.isCorrect ? AppColors.success : AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    answer.isCorrect
                        ? 'Correct! +${answer.pointsEarned} pts'
                        : 'Not quite',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: answer.isCorrect
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pointsPopController,
                  builder: (context, _) {
                    final scale = Tween<double>(begin: 1.4, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _pointsPopController,
                        curve: Curves.easeOutBack,
                      ),
                    );
                    return Transform.scale(
                      scale: scale.value,
                      child: Text(
                        answer.isCorrect ? '+${answer.pointsEarned}' : '+0',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryAmber,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (answer.explanation.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                answer.explanation,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final disabled =
        (_selectedOption == null && _lastAnswer == null) || _submitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMd,
          AppDimensions.sm,
          AppDimensions.paddingMd,
          AppDimensions.paddingMd,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: disabled
                  ? const LinearGradient(
                      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: disabled
                  ? null
                  : [
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
                onTap: disabled
                    ? null
                    : (_lastAnswer == null ? _submitAnswer : _goNext),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _lastAnswer != null
                                  ? (_isLast ? 'Finish Quiz' : 'Next Question')
                                  : 'Submit Answer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Icon(
                              _lastAnswer != null
                                  ? (_isLast
                                      ? Icons.flag_rounded
                                      : Icons.arrow_forward_rounded)
                                  : Icons.bolt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
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

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;
  final Color borderColor;

  const _ScoreBadge({
    required this.score,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.primaryAmber, size: 16),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final String time;
  final Color color;
  final Color borderColor;

  const _TimerChip({
    required this.time,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primaryBlue, size: 16),
          const SizedBox(width: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
