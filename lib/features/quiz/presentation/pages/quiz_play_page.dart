import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/entities/quiz_strings.dart';
import '../providers/daily_quiz_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/quiz_language_toggle.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  final QuizPlayArgs args;

  const QuizPlayPage({super.key, required this.args});

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
  bool _finishing = false;

  int _totalScore = 0;
  int _streak = 0;
  int _bestStreak = 0;

  /// Live quiz language. Seeded from the route args (the language the session
  /// was started with) but switchable per question via the EN | NP toggle, so a
  /// user who changes their mind mid-quiz sees the translation immediately
  /// instead of being stuck with the start-time language.
  late QuizLanguage _language;

  /// Seconds left in the countdown (requirement: daily quiz is time boxed).
  int _remainingSeconds = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  final Stopwatch _stopwatch = Stopwatch();

  late final AnimationController _feedbackController;
  late final AnimationController _pointsPopController;

  QuizPlayArgs get _args => widget.args;

  bool get _isDaily => _args.isDaily;

  /// UI copy is always English.
  ///
  /// The EN | NP toggle translates QUESTION content only (text, options,
  /// explanations) — never the app's own chrome, buttons or dialogs. The two
  /// concerns are deliberately separate: [QuizStrings.of] is always called with
  /// English here, and only `textFor` / `optionsFor` / `explanationFor` read
  /// [_language].
  QuizStrings get _strings => QuizStrings.of(QuizLanguage.english);

  /// Session resolved from the route extra first, provider second. The play
  /// page never depends on mutable global state to render.
  ActiveQuiz? get _activeQuiz =>
      _args.activeQuiz ?? ref.read(quizProvider).activeQuiz;

  @override
  void initState() {
    super.initState();
    _language = _args.language;
    _stopwatch.start();
    _remainingSeconds = _resolveDurationSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds == 0) unawaited(_onTimeUp());
        }
      });
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

  /// Every attempt gets the same client-owned time box.
  ///
  /// This deliberately ignores `ActiveQuiz.durationSeconds` and
  /// `QuizPlayArgs.fallbackDurationSeconds` (both parsed from the backend) so a
  /// schedule or start response with no duration, a 0, or an unexpected value
  /// can no longer produce an untimed or wildly over-long attempt. The server
  /// still owns scoring and receives `timeSpentSeconds` per answer.
  int _resolveDurationSeconds() => AppConstants.quizDurationSeconds;

  bool get _isLast {
    final quiz = _activeQuiz;
    return quiz != null && _currentIndex >= quiz.questions.length - 1;
  }

  bool get _isTimed => _resolveDurationSeconds() > 0;

  Future<void> _submitAnswer() async {
    final quiz = _activeQuiz;
    if (quiz == null || _selectedOption == null || _submitting) return;
    setState(() => _submitting = true);

    final result = await ref
        .read(quizProvider.notifier)
        .submitAnswer(
          sessionId: widget.args.sessionId,
          questionIndex: _currentIndex,
          selectedOptionIndex: _selectedOption!,
          timeSpentSeconds: _timeSpentOnCurrentQuestion,
        );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _lastAnswer = result;
    });

    if (result == null) {
      AlertWidget.showError(
        context,
        ref.read(quizProvider).message ?? 'Could not submit the answer.',
      );
      return;
    }

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

  Future<void> _goNext() async {
    if (_lastAnswer == null) return;
    if (!_isLast) {
      _questionStopwatch
        ..reset()
        ..start();
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

  late final Stopwatch _questionStopwatch = Stopwatch();

  int get _timeSpentOnCurrentQuestion {
    if (_questionStopwatch.isRunning) {
      return _questionStopwatch.elapsed.inSeconds;
    }
    return _elapsedSeconds;
  }

  /// Auto-submits the visible answer and finishes the run when the countdown
  /// reaches zero.
  Future<void> _onTimeUp() async {
    if (_finishing) return;
    if (_selectedOption != null && _lastAnswer == null) {
      await _submitAnswer();
    }
    if (!mounted) return;
    await AlertWidget.showConfirmDialog(
      context,
      title: _strings.timeUp,
      message: _strings.timeUpHint,
      confirmLabel: _strings.finishQuiz,
    );
    if (!mounted) return;
    await _completeQuiz();
  }

  Future<void> _completeQuiz() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final result = await ref
        .read(quizProvider.notifier)
        .completeQuiz(widget.args.sessionId);
    if (!mounted) return;
    setState(() => _finishing = false);

    final scheduleId = _args.scheduleId ?? _args.activeQuiz?.scheduleId;
    if (scheduleId != null && scheduleId.isNotEmpty) {
      ref.read(quizProvider.notifier).markAttempted(scheduleId);
    }
    if (_isDaily) ref.read(dailyQuizProvider.notifier).markAttemptUsed();

    ref.read(quizProvider.notifier).clearActiveQuiz();
    context.pushReplacement(
      RouteNames.quizResult,
      extra: QuizResultArgs(
        result: result,
        isDaily: _isDaily,
        language: _language,
      ),
    );
  }

  Future<void> _confirmExit() async {
    final confirmed = await AlertWidget.showConfirmDialog(
      context,
      title: 'Leave the quiz?',
      message: _isDaily
          ? 'The daily quiz allows a single attempt. Leaving now uses it up.'
          : 'Your progress in this session will be lost.',
      confirmLabel: 'Leave',
    );
    if (confirmed != true || !mounted) return;
    ref.read(quizProvider.notifier).clearActiveQuiz();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _activeQuiz;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (quiz == null || quiz.questions.isEmpty) {
      return _buildUnavailable(isDark);
    }

    if (_currentIndex >= quiz.questions.length) {
      return _buildUnavailable(isDark);
    }

    final question = quiz.questions[_currentIndex];
    final total = quiz.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF3F5FA),
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

  /// Shown when the session cannot be resolved — never a silent spinner.
  Widget _buildUnavailable(bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF3F5FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                'This quiz session is no longer available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                'It may have ended, or the attempt was already used.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLg),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(RouteNames.home),
                      child: Center(
                        child: Text(
                          _strings.moreQuizzes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
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
    final strings = _strings;

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
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _confirmExit,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.questionOf} ${_currentIndex + 1} / $total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _streak > 1
                          ? '$_streak ${strings.streakLabel}'
                          : strings.keepItUp,
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
              const SizedBox(width: AppDimensions.xs),
              _TimerChip(
                // A timed quiz counts down; an untimed one counts up so the
                // chip is never a frozen "00:00".
                time: _formatTime(
                  _isTimed ? _remainingSeconds : _elapsedSeconds,
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderColor: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderLight,
                isUrgent: _isTimed && _remainingSeconds <= 20,
                isCountdown: _isTimed,
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
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : AppColors.borderLight,
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
          // The EN | NP control lives on every question, so the user can switch
          // the language at any point instead of being locked to the language
          // the quiz happened to start in.
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
              const Spacer(),
              // Always shown. Gating it on `_isDaily || hasNepali` made the
              // control disappear whenever detection failed, so the one thing
              // that would explain the failure was the thing that vanished.
              // `hasNepali` is surfaced as a hint instead.
              QuizLanguageToggle(
                value: _language,
                onChanged: (next) => setState(() => _language = next),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            q.textFor(_language),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          // Scripture reference from the backend, when the question carries one.
          if (q.scriptureReference != null &&
              q.scriptureReference!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    q.scriptureReference!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          // Explicit proof of whether the Nepali variant was found, so a
          // backend that omits it is distinguishable from a broken toggle.
          if (_language == QuizLanguage.nepali && !q.hasNepali)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.xs),
              child: Text(
                'No Nepali translation for this question',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context, QuizQuestion q, bool isDark) {
    final options = q.optionsFor(_language);
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = index == _selectedOption;
        final isCorrect =
            _lastAnswer != null && index == _lastAnswer!.correctAnswerIndex;
        final isWrong =
            _lastAnswer != null && isSelected && !_lastAnswer!.isCorrect;
        final locked = _lastAnswer != null;

        Color? borderColor;
        Color? bgColor;
        if (locked && isCorrect) {
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
              color:
                  bgColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              elevation: isSelected || locked ? 0 : 1,
              shadowColor: AppColors.shadowLight,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                onTap: locked
                    ? null
                    : () {
                        unawaited(HapticFeedback.selectionClick());
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
                      color:
                          borderColor ??
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
                          color: _optionBadgeColor(
                            isSelected,
                            isCorrect,
                            isWrong,
                          ),
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
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

  Widget _buildFeedback(
    BuildContext context,
    AnswerResult answer,
    bool isDark,
  ) {
    final strings = _strings;
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _feedbackController,
            curve: Curves.easeIn,
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _feedbackController,
                    curve: Curves.easeOutBack,
                  ),
                ),
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
                        ? '${strings.correct} +${answer.pointsEarned} pts'
                        : strings.notQuite,
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
            if (answer.explanationFor(_language).isNotEmpty) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                answer.explanationFor(_language),
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
    final strings = _strings;
    final disabled =
        (_selectedOption == null && _lastAnswer == null) || _submitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMd,
          AppDimensions.paddingSm,
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
                  child: _submitting || _finishing
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
                                  ? (_isLast
                                        ? strings.finishQuiz
                                        : strings.nextQuestion)
                                  : strings.submitAnswer,
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
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final secs = (safe % 60).toString().padLeft(2, '0');
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
          const Icon(
            Icons.stars_rounded,
            color: AppColors.primaryAmber,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
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
  final bool isUrgent;
  final bool isCountdown;

  const _TimerChip({
    required this.time,
    required this.color,
    required this.borderColor,
    this.isUrgent = false,
    this.isCountdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isUrgent ? AppColors.error : AppColors.primaryBlue;
    final textColor = isUrgent
        ? AppColors.error
        : (isCountdown
              ? AppColors.textPrimary
              : (isDark ? Colors.white : AppColors.textPrimary));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isUrgent ? AppColors.error : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCountdown ? Icons.hourglass_bottom_rounded : Icons.timer_outlined,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
