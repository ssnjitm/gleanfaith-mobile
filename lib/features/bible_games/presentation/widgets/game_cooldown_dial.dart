import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../domain/entities/game_lives.dart';
import '../providers/bible_game_language_provider.dart';

/// A `h:mm:ss` (or `m:ss`) countdown for [lives], re-derived from the wall clock
/// every second.
///
/// Two rules make this correct rather than merely ticking:
///
/// * **Never decrement a counter.** Every frame re-reads `DateTime.now()` and
///   asks [GameLives] what is left, so the number cannot drift, cannot be
///   "paused" by a dropped frame, and is correct the instant it is built.
/// * **Re-read on resume.** Timers are suspended while an app is backgrounded,
///   so the first tick back would show whatever it last managed to render. An
///   [AppLifecycleListener] forces an immediate repaint instead, which is what
///   makes a cooldown that ended in the background show as ended rather than
///   stuck.
class GameCooldownCountdown extends ConsumerStatefulWidget {
  final GameLives lives;

  final TextStyle? style;

  const GameCooldownCountdown({
    super.key,
    required this.lives,
    this.style,
  });

  @override
  ConsumerState<GameCooldownCountdown> createState() =>
      _GameCooldownCountdownState();
}

class _GameCooldownCountdownState extends ConsumerState<GameCooldownCountdown> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      if (mounted) setState(() {});
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(bibleGameLanguageProvider);
    return Text(
      widget.lives.formatCooldownAt(DateTime.now(), language),
      style: widget.style ??
          const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
    );
  }
}

/// A ring that drains as the cooldown elapses, with [GameCooldownCountdown]
/// inside it.
///
/// The ring is what makes waiting legible at a glance — a bare number gives no
/// sense of how much is left, and a player who cannot see progress tends to keep
/// reopening the game to check.
class GameCooldownDial extends StatelessWidget {
  final GameLives lives;
  final bool isDark;

  const GameCooldownDial({
    super.key,
    required this.lives,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark ? const Color(0xFF1E293B) : AppColors.bgCard;
    final trackBorder = isDark ? const Color(0xFF334155) : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: Builder(
              builder: (context) {
                final now = DateTime.now();
                final total = GameLives.cooldownDuration.inMilliseconds;
                final left = lives.cooldownRemainingAt(now).inMilliseconds;
                final progress = total == 0 ? 1.0 : (left / total).clamp(0.0, 1.0);
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: trackColor,
                    valueColor: const AlwaysStoppedAnimation(AppColors.error),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: trackColor,
              border: Border.all(color: trackBorder),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(height: 6),
                GameCooldownCountdown(
                  lives: lives,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
