import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/crosspuzzle_entities.dart';

class CrossPuzzleResultPage extends ConsumerStatefulWidget {
  final CrossPuzzleCompleteResult? result;

  const CrossPuzzleResultPage({super.key, required this.result});

  @override
  ConsumerState<CrossPuzzleResultPage> createState() =>
      _CrossPuzzleResultPageState();
}

class _CrossPuzzleResultPageState extends ConsumerState<CrossPuzzleResultPage> {
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accuracy = result?.accuracy ?? 0;
    final newlyAwarded = result?.newlyAwarded ?? true;
    final level = result?.level;
    final isCompleted = result?.status == 'completed';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: Column(
                children: [
                  const SizedBox(height: AppDimensions.paddingMd),
                  _buildTrophy(accuracy, isDark),
                  const SizedBox(height: AppDimensions.lg),
                  Text(
                    isCompleted
                        ? (newlyAwarded ? 'Congratulations!' : 'Completed Again!')
                        : 'Keep Going!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isCompleted ? AppColors.success : AppColors.primaryAmber,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    isCompleted
                        ? (newlyAwarded
                            ? 'You solved the puzzle and earned XP!'
                            : 'Nice replay — no extra XP this time.')
                        : 'Not quite — every letter must be correct to unlock the next level.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[400] : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _buildProgressRing(accuracy, isDark),
                  const SizedBox(height: AppDimensions.xl),
                  _buildStats(result, isDark),
                  if (level != null) ...[
                    const SizedBox(height: AppDimensions.xl),
                    _buildLevelCard(level, isDark),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                  _buildButtons(context),
                ],
              ),
            ),
            if (newlyAwarded && accuracy >= 80)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _Confetti(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophy(int accuracy, bool isDark) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: accuracy >= 70
            ? AppColors.primaryGradient
            : LinearGradient(
                colors: [
                  AppColors.primaryAmber.withValues(alpha: 0.8),
                  AppColors.primaryAmber,
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressRing(int accuracy, bool isDark) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: accuracy / 100,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: accuracy >= 70 ? AppColors.success : AppColors.primaryAmber,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$accuracy%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ACCURACY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(CrossPuzzleCompleteResult? result, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
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
      child: Row(
        children: [
          _Stat(
            icon: Icons.grid_4x4_rounded,
            label: 'Correct',
            value: '${result?.correctCells ?? 0}/${result?.totalCells ?? 0}',
            color: AppColors.success,
            isDark: isDark,
          ),
          _Stat(
            icon: Icons.stars_rounded,
            label: 'XP',
            value: '${result?.pointsEarned ?? 0}',
            color: AppColors.primaryAmber,
            isDark: isDark,
          ),
          _Stat(
            icon: Icons.timer_outlined,
            label: 'Best',
            value: _fmtTime(result?.bestTimeSpentSeconds ?? 0),
            color: AppColors.primaryBlue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(UserLevelInfo level, bool isDark) {
    final total = level.nextLevelPoints <= 0 ? 1 : level.nextLevelPoints;
    final progress = level.currentLevelPoints / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: AppColors.primaryAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.primaryAmber, size: 22),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Level ${level.level}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${level.totalPoints} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: AppColors.primaryGradient.colors.first,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            '${level.level + 1} · ${level.pointsToNextLevel} XP to next level',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final result = widget.result;
    final isCompleted = result?.status == 'completed';

    return Column(
      children: [
        if (!isCompleted) ...[
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => context.pushReplacement(
                RouteNames.crossPuzzlePlay,
                extra: {
                  'id': result?.puzzleId ?? '',
                  'title': result?.title ?? '',
                },
              ),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.crossPuzzle),
            icon: const Icon(Icons.grid_4x4_rounded, size: 20),
            label: const Text(
              'More Puzzles',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.home),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(animation: _controller),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;

  _ConfettiPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final random = _FixedRandom(42);
    final colors = [
      AppColors.primaryBlue,
      AppColors.primaryAmber,
      AppColors.success,
      const Color(0xFF7C3AED),
      const Color(0xFFE91E63),
    ];
    for (var i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() - progress * 1.2) * size.height;
      final color = colors[i % colors.length];
      final rect = Rect.fromLTWH(x, y, 8, 12);
      final paint = Paint()..color = color.withValues(alpha: 1 - progress);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

class _FixedRandom {
  int _seed;
  _FixedRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return (_seed % 100000) / 100000.0;
  }
}