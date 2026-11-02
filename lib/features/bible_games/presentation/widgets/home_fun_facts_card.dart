import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/app_error_widget.dart';
import '../../../../core/common/widgets/shimmer_widget.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/bible_games_provider.dart';

/// Reveals one Bible fun fact at a time — a pure "did you know?" card, NOT a
/// game. Cycles through every fact the offline DB can produce. Shown on the
/// Home tab right after the quick actions.
///
/// The fact itself follows the **global content language**
/// (`bibleFunFactsProvider` already bakes the translation into each fact),
/// while the card's chrome stays English.
///
/// The card auto-slides to the next fact (default: every 6 seconds), loops back
/// after the last one, and pauses when:
/// - the user swipes or taps a dot/Next (the timer restarts from that moment),
/// - the user taps the play/pause control,
/// - the Home tab is not selected ([isActive]),
/// - another route is pushed over Home,
/// - the app is backgrounded,
/// - the platform's "Reduce Motion" accessibility setting is on.
class HomeFunFactsCard extends ConsumerStatefulWidget {
  const HomeFunFactsCard({
    super.key,
    this.isActive = true,
    this.autoSlideInterval = const Duration(seconds: 6),
  });

  /// False while the Home tab is not the selected bottom-nav tab. The card
  /// stays mounted inside the shell's `IndexedStack`, so this is the only
  /// reliable "am I on screen?" signal for tab switches.
  final bool isActive;

  /// How long each fact stays on screen before the card advances.
  final Duration autoSlideInterval;

  @override
  ConsumerState<HomeFunFactsCard> createState() => _HomeFunFactsCardState();
}

class _HomeFunFactsCardState extends ConsumerState<HomeFunFactsCard>
    with WidgetsBindingObserver, RouteAware {
  static const double _swipeThreshold = 40;

  Timer? _timer;
  ModalRoute<dynamic>? _subscribedRoute;
  int _index = 0;
  int _factCount = 0;
  bool _userPaused = false;
  bool _routeVisible = true;
  bool _appResumed = true;
  bool _reduceMotion = false;
  double _dragDistance = 0;

  bool get _canAutoSlide =>
      _factCount > 1 &&
      !_userPaused &&
      !_reduceMotion &&
      widget.isActive &&
      _routeVisible &&
      _appResumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appResumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || route == _subscribedRoute) return;
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    _subscribedRoute = route;
    _routeVisible = route.isCurrent;
    AppRouter.routeObserver.subscribe(this, route);
    _scheduleTimerSync();
  }

  @override
  void didUpdateWidget(HomeFunFactsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.autoSlideInterval != widget.autoSlideInterval) {
      _restartTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (_appResumed == resumed) return;
    _appResumed = resumed;
    _syncTimer();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncTimer();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _restartTimer();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncTimer();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncTimer();
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncTimer() {
    if (!_canAutoSlide) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    final interval = widget.autoSlideInterval <= Duration.zero
        ? const Duration(seconds: 6)
        : widget.autoSlideInterval;
    _timer = Timer.periodic(interval, (_) => _advance());
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    _syncTimer();
  }

  void _scheduleTimerSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTimer();
    });
  }

  void _advance() {
    if (!mounted || _factCount <= 1) return;
    setState(() => _index = (_index + 1) % _factCount);
  }

  void _showFact(int index, {bool resetTimer = true}) {
    if (_factCount == 0) return;
    setState(() => _index = index % _factCount);
    if (resetTimer) _restartTimer();
  }

  void _nextByUser() {
    if (_factCount <= 1) return;
    _showFact(_index + 1);
  }

  void _previousByUser() {
    if (_factCount <= 1) return;
    _showFact(_index - 1);
  }

  void _toggleAutoSlide() {
    if (_reduceMotion) return;
    setState(() => _userPaused = !_userPaused);
    _restartTimer();
  }

  void _onHorizontalDragStart(DragStartDetails _) {
    _dragDistance = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    final distance = _dragDistance;
    _dragDistance = 0;
    if (distance.abs() < _swipeThreshold) return;
    if (distance < 0) {
      _nextByUser();
    } else {
      _previousByUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _scheduleTimerSync();
    }

    final facts = ref.watch(bibleFunFactsProvider);
    final strings = ref.watch(bibleGameStringsProvider);

    final factCount = facts.value?.length ?? 0;
    if (factCount != _factCount) {
      _factCount = factCount;
      _scheduleTimerSync();
    }

    return facts.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: ShimmerWidget(
          width: double.infinity,
          height: 150,
          borderRadius: AppDimensions.radiusLg,
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
        ),
        child: AppErrorWidget(
          message: strings.loadFailed,
          onRetry: () => ref.invalidate(bibleFunFactsProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final index = _index % list.length;
        final fact = list[index];

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : AppColors.borderLight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAmber.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.primaryAmber,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.factsTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          strings.counter(index + 1, list.length),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(index),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fact.prompt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fact.correct,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryAmber,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fact.explain,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (list.length > 1) ...[
                      const SizedBox(height: 12),
                      _buildDots(
                        index: index,
                        count: list.length,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (list.length > 1)
                          IconButton(
                            onPressed: reduceMotion ? null : _toggleAutoSlide,
                            tooltip: reduceMotion
                                ? 'Auto-slide is off (Reduce Motion)'
                                : (_userPaused
                                      ? 'Resume auto-slide'
                                      : 'Pause auto-slide'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              _userPaused || reduceMotion
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.pause_circle_outline_rounded,
                              size: 20,
                              color: reduceMotion
                                  ? (isDark
                                        ? const Color(0xFF64748B)
                                        : AppColors.textLight)
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: _nextByUser,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            strings.factsNext,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots({
    required int index,
    required int count,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return Semantics(
          button: true,
          selected: selected,
          label: 'Show fact ${i + 1} of $count',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showFact(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: AnimatedContainer(
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: selected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryAmber
                      : (isDark
                            ? const Color(0xFF475569)
                            : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
