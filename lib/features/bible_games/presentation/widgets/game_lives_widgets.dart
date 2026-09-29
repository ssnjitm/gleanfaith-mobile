import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/game_lives.dart';

/// The heart row that shows how many lives a game has left.
///
/// Animation contract, because this is the feedback for the single most
/// important event in a run:
/// * [lives] dropping by one makes the heart that was lost shrink and fade out
///   with a shake, and flashes the row red.
/// * [pulseHeal] lights the row green and pops the hearts, for the
///   perfect-round life refund.
/// * All three lost leaves an empty grey row — the row is never hidden, so the
///   cost of a mistake stays visible instead of disappearing.
/// Which way a life event went, so the row can tint without a second flag.
enum _PulseDirection { none, heal, loss }

extension on _PulseDirection {
  Color get color {
    switch (this) {
      case _PulseDirection.heal:
        return AppColors.success;
      case _PulseDirection.loss:
        return AppColors.error;
      case _PulseDirection.none:
        return Colors.transparent;
    }
  }
}

class GameLivesRow extends StatefulWidget {
  final int lives;
  final int maxLives;

  /// Bumped by the page to animate a life refund.
  final int pulseHeal;

  /// Bumped by the page to animate a life loss.
  final int pulseLoss;

  final bool compact;

  const GameLivesRow({
    super.key,
    required this.lives,
    this.maxLives = GameLives.maxLives,
    this.pulseHeal = 0,
    this.pulseLoss = 0,
    this.compact = false,
  });

  @override
  State<GameLivesRow> createState() => _GameLivesRowState();
}

class _GameLivesRowState extends State<GameLivesRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Set when a trigger fires, consumed by the animation. [none] means "no
  /// feedback running", so a rebuild never flashes spuriously.
  _PulseDirection _direction = _PulseDirection.none;

  @override
  void didUpdateWidget(covariant GameLivesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseHeal != oldWidget.pulseHeal) {
      _direction = _PulseDirection.heal;
    } else if (widget.pulseLoss != oldWidget.pulseLoss) {
      _direction = _PulseDirection.loss;
    } else {
      return;
    }
    if (_pulse.isAnimating) _pulse.stop();
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        // A single overshoot-and-settle curve for both directions; the colour
        // is what tells them apart, not a different motion.
        final pop = 1 + math.sin(t * math.pi) * 0.28;
        final flash = (1 - t).clamp(0.0, 1.0);
        final tint = _direction == _PulseDirection.none
            ? Colors.transparent
            : _direction.color.withValues(alpha: flash * 0.22);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          child: Transform.scale(
            scale: t == 0 ? 1 : pop,
            child: child,
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.maxLives; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == widget.maxLives - 1 ? 0 : 4,
                  ),
                  child: Transform.scale(
                    // Stagger so the hearts pop in one after another.
                    scale: i < widget.lives ? value : 1,
                    child: _Heart(
                      filled: i < widget.lives,
                      emptyColor: emptyColor,
                      size: widget.compact ? 18 : 22,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Heart extends StatelessWidget {
  final bool filled;
  final Color emptyColor;
  final double size;

  const _Heart({
    required this.filled,
    required this.emptyColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: filled ? 1 : 0.86,
      duration: const Duration(milliseconds: 220),
      child: Icon(
        filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size,
        color: filled
            ? AppColors.error
            : emptyColor,
      ),
    );
  }
}

/// Wraps [child] in a shake + red flash that fires when a life is lost.
///
/// A wrong answer in a game with a lives system has to be felt, not just read:
/// the shake is the "that cost you" signal, and it is paired with the heart row
/// so the two never contradict each other.
class LifeLossShake extends StatefulWidget {
  final int trigger;
  final Widget child;

  const LifeLossShake({
    super.key,
    required this.trigger,
    required this.child,
  });

  @override
  State<LifeLossShake> createState() => _LifeLossShakeState();
}

class _LifeLossShakeState extends State<LifeLossShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant LifeLossShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Damped sine, three oscillations: a short sharp shake, not a wobble.
        final offset = math.sin(t * math.pi * 6) * 10 * (1 - t);
        final flash = (1 - t).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: ColoredBox(
            color: Color.fromRGBO(
              239,
              68,
              68,
              flash * (isDark ? 0.16 : 0.10),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A one-line banner shown when a life is lost or restored.
///
/// [tone] picks the colour so the same widget reports both directions; the
/// message itself is passed in already localized.
class LifeToastBanner extends StatefulWidget {
  final String message;
  final bool isPositive;
  final int trigger;

  const LifeToastBanner({
    super.key,
    required this.message,
    required this.isPositive,
    required this.trigger,
  });

  @override
  State<LifeToastBanner> createState() => _LifeToastBannerState();
}

class _LifeToastBannerState extends State<LifeToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    if (widget.trigger != 0) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant LifeToastBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Slide + fade in on every event so consecutive losses are readable as
    // separate events rather than a static line.
    if (widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trigger == 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isPositive ? AppColors.success : AppColors.error;

    return FadeTransition(
      opacity: _controller,
      child: SizeTransition(
        sizeFactor: _controller,
        axisAlignment: -1,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.35),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingSm),
            child: Row(
              children: [
                Icon(
                  widget.isPositive
                      ? Icons.add_circle_rounded
                      : Icons.error_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      shadows: [
                        if (isDark)
                          const Shadow(color: Color(0xFF0F172A), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
