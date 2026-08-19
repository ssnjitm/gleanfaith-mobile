import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/crosspuzzle_local_datasource.dart';
import '../../domain/entities/crosspuzzle_entities.dart';
import '../providers/crosspuzzle_provider.dart';

class CrossPuzzleHomePage extends ConsumerStatefulWidget {
  const CrossPuzzleHomePage({super.key});

  @override
  ConsumerState<CrossPuzzleHomePage> createState() => _CrossPuzzleHomePageState();
}

class _CrossPuzzleHomePageState extends ConsumerState<CrossPuzzleHomePage>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.05,
    )..repeat(reverse: true);
    Future.microtask(() {
      ref.read(crossPuzzleProvider.notifier).loadPuzzles();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Returned from a play/result page — reload so completion + unlock
    // state on the journey path stays fresh.
    ref.read(crossPuzzleProvider.notifier).loadPuzzles();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crossPuzzleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CrossWord Puzzles'),
        actions: [
          IconButton(
            tooltip: 'My Puzzles',
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => context.push(RouteNames.crossPuzzleMyPuzzles),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(crossPuzzleProvider.notifier).loadPuzzles(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingXl),
          children: [
            const SizedBox(height: AppDimensions.sm),
            _buildHero(isDark),
            const SizedBox(height: AppDimensions.paddingLg),
            _buildProgressSummary(context, state, isDark),
            const SizedBox(height: AppDimensions.paddingMd),
            _buildJourney(context, state, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_4x4_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bible Crossword',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solve each level to unlock the next one!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(
    BuildContext context,
    CrossPuzzleState state,
    bool isDark,
  ) {
    final puzzles = state.puzzles;
    final solved = puzzles
        .where((p) => p.userProgress?.isCompleted ?? false)
        .length;
    final total = puzzles.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      child: Row(
        children: [
          Text(
            total == 0 ? 'Journey' : 'Level $solved of $total solved',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(solved / total * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJourney(
    BuildContext context,
    CrossPuzzleState state,
    bool isDark,
  ) {
    final puzzles = state.puzzles;

    if (state.status == CrossPuzzleStatus.loading && puzzles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (puzzles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              state.message ?? 'No crossword puzzles available yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final ordered = _orderPuzzles(puzzles);
    return JourneyMap(
      puzzles: ordered,
      pulse: _pulseController,
      onTap: _openPuzzle,
    );
  }

  /// Sorts puzzles by level number so the journey is always in order,
  /// even when the provider returns them unsorted.
  List<CrossPuzzle> _orderPuzzles(List<CrossPuzzle> puzzles) {
    int levelOf(CrossPuzzle p) {
      if (CrossPuzzleLocalDataSource.isLocalId(p.id)) {
        final num = int.tryParse(p.id.substring('local_'.length));
        if (num != null) return num;
      }
      return puzzles.indexOf(p) + 1;
    }

    final sorted = [...puzzles]..sort((a, b) => levelOf(a).compareTo(levelOf(b)));
    return sorted;
  }

  void _openPuzzle(CrossPuzzle puzzle, bool unlocked) {
    if (!unlocked) {
      AlertWidget.showInfo(context, 'Solve the previous level to unlock this one');
      return;
    }
    context.push(
      RouteNames.crossPuzzlePlay,
      extra: {
        'id': puzzle.id,
        'title': puzzle.title,
      },
    );
  }
}

enum _LevelState { locked, unlocked, current, completed }

/// Candy Crush style serpentine journey path with sequential unlock.
class JourneyMap extends StatelessWidget {
  final List<CrossPuzzle> puzzles;
  final Animation<double> pulse;
  final void Function(CrossPuzzle puzzle, bool unlocked) onTap;

  const JourneyMap({
    super.key,
    required this.puzzles,
    required this.pulse,
    required this.onTap,
  });

  static const double _nodeSize = 56;
  static const double _hStep = 88;
  static const double _vStep = 74;
  static const double _edgeMargin = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final perRow = ((width - 2 * _edgeMargin - _nodeSize) / _hStep)
                .floor() +
            1;
        final cols = perRow.clamp(3, 6);

        final rows = (puzzles.length / cols).ceil();
        final mapWidth =
            _edgeMargin * 2 + (cols - 1) * _hStep + _nodeSize;
        final mapHeight = _edgeMargin * 2 + (rows - 1) * _vStep + _nodeSize;

        final centers = <Offset>[];
        for (var i = 0; i < puzzles.length; i++) {
          final row = i ~/ cols;
          var col = i % cols;
          if (row.isOdd) col = cols - 1 - col;
          centers.add(Offset(
            _edgeMargin + col * _hStep + _nodeSize / 2,
            _edgeMargin + row * _vStep + _nodeSize / 2,
          ));
        }

        final states = _computeStates();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: mapWidth,
            height: mapHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _JourneyPainter(
                      centers: centers,
                      states: states,
                    ),
                  ),
                ),
                for (var i = 0; i < puzzles.length; i++)
                  Positioned(
                    left: centers[i].dx - _nodeSize / 2,
                    top: centers[i].dy - _nodeSize / 2,
                    width: _nodeSize,
                    height: _nodeSize,
                    child: _LevelNode(
                      puzzle: puzzles[i],
                      state: states[i],
                      isLast: i == puzzles.length - 1,
                      pulse: pulse,
                      onTap: () => onTap(
                        puzzles[i],
                        states[i] != _LevelState.locked,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_LevelState> _computeStates() {
    final states = <_LevelState>[];
    var prevDone = true;
    for (final puzzle in puzzles) {
      final done = puzzle.userProgress?.isCompleted ?? false;
      if (done) {
        states.add(_LevelState.completed);
        prevDone = true;
      } else if (prevDone) {
        states.add(_LevelState.current);
        prevDone = false;
      } else {
        states.add(_LevelState.locked);
      }
    }
    return states;
  }
}

class _JourneyPainter extends CustomPainter {
  final List<Offset> centers;
  final List<_LevelState> states;

  _JourneyPainter({required this.centers, required this.states});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty) return;

    final base = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final basePath = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      basePath.lineTo(centers[i].dx, centers[i].dy);
    }
    canvas.drawPath(basePath, base);

    // Progress path: segments between two non-locked nodes that are either
    // completed or the current (first unlocked) level.
    final progressPaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final progressPath = Path();
    var started = false;
    for (var i = 0; i < centers.length - 1; i++) {
      final a = states[i];
      final b = states[i + 1];
      if (a == _LevelState.locked || b == _LevelState.locked) continue;
      if (!started) {
        progressPath.moveTo(centers[i].dx, centers[i].dy);
        started = true;
      }
      progressPath.lineTo(centers[i + 1].dx, centers[i + 1].dy);
    }
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter oldDelegate) {
    return oldDelegate.centers != centers || oldDelegate.states != states;
  }
}

class _LevelNode extends StatelessWidget {
  final CrossPuzzle puzzle;
  final _LevelState state;
  final bool isLast;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _LevelNode({
    required this.puzzle,
    required this.state,
    required this.isLast,
    required this.pulse,
    required this.onTap,
  });

  String get _levelLabel {
    if (CrossPuzzleLocalDataSource.isLocalId(puzzle.id)) {
      return puzzle.id.substring('local_'.length);
    }
    return puzzle.title;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final Color ring;
    IconData? icon;
    double scale = 1;

    switch (state) {
      case _LevelState.locked:
        bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB);
        fg = isDark ? Colors.grey[500]! : AppColors.textMuted;
        ring = isDark ? const Color(0xFF334155) : Colors.transparent;
        icon = Icons.lock_rounded;
        break;
      case _LevelState.unlocked:
        bg = AppColors.primaryBlue.withValues(alpha: 0.15);
        fg = AppColors.primaryBlue;
        ring = AppColors.primaryBlue;
        break;
      case _LevelState.current:
        bg = AppColors.primaryGradient.colors.last;
        fg = Colors.white;
        ring = AppColors.primaryAmber;
        scale = pulse.value;
        break;
      case _LevelState.completed:
        bg = AppColors.success;
        fg = Colors.white;
        ring = AppColors.success;
        icon = isLast ? Icons.emoji_events_rounded : Icons.check_rounded;
        break;
    }

    final label = icon == null ? _levelLabel : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: ring == Colors.transparent
                    ? null
                    : Border.all(
                        color: ring,
                        width: state == _LevelState.current ? 3 : 2,
                      ),
                boxShadow: state == _LevelState.current
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAmber.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: fg, size: 22)
                    : Text(
                        label!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}