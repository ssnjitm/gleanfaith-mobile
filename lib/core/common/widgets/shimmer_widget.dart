import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusMd,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFF3F4F6));

    return ListenableBuilder(
      listenable: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

class ShimmerTextLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double? widthFraction;

  const ShimmerTextLine({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = AppDimensions.radiusSm,
    this.widthFraction,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ??
        (widthFraction != null
            ? MediaQuery.of(context).size.width * widthFraction!
            : double.infinity);
    return ShimmerWidget(
      width: w,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double itemSpacing;
  final double borderRadius;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.itemSpacing = 12,
    this.borderRadius = AppDimensions.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
      itemBuilder: (_, index) => ShimmerWidget(
        width: double.infinity,
        height: itemHeight,
        borderRadius: borderRadius,
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Widget? child;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.borderRadius = AppDimensions.radiusLg,
    this.margin,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: child ??
          ShimmerWidget(
            width: double.infinity,
            height: height,
            borderRadius: borderRadius,
          ),
    );
  }
}
