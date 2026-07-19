import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';

const List<String> _dailyVerses = [
  '"For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future." — Jeremiah 29:11',
  '"I can do all things through Him who strengthens me." — Philippians 4:13',
  '"Trust in the Lord with all your heart and lean not on your own understanding." — Proverbs 3:5',
  '"The Lord is my shepherd; I shall not want." — Psalm 23:1',
  '"Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go." — Joshua 1:9',
  '"For God so loved the world that He gave His one and only Son, that whoever believes in Him shall not perish but have eternal life." — John 3:16',
  '"Peace I leave with you; My peace I give to you. Not as the world gives do I give to you." — John 14:27',
];

class AuthCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _verseController;
  late Animation<double> _verseFade;
  int _verseIndex = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _verseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _verseFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _verseController, curve: Curves.easeInOut),
    );
    _verseController.forward();

    _startVerseCycle();
  }

  void _startVerseCycle() {
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      _verseController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _verseIndex = (_verseIndex + 1) % _dailyVerses.length);
        _verseController.forward();
        _startVerseCycle();
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return _AnimatedBackground(controller: _bgController);
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlassCard(),
                      const SizedBox(height: 24),
                      _buildVerseText(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF2563EB) : const Color(0xFF3B82F6)).withValues(alpha: isDark ? 0.15 : 0.10),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: isDark ? 0.25 : 0.35),
                (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)).withValues(alpha: isDark ? 0.20 : 0.30),
              ],
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.25 : 0.40),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseText() {
    return AnimatedBuilder(
      animation: _verseController,
      builder: (context, _) {
        return Opacity(
          opacity: _verseFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _dailyVerses[_verseIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textSecondary
                ).withValues(alpha: 0.65),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A5F),
                  Color(0xFF1E1B4B),
                ]
              : const [
                  Color(0xFFEFF6FF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFBEB),
                ],
        ),
      ),
      child: Stack(
        children: List.generate(5, (i) => _Blob(controller: controller, index: i, isDark: isDark)),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Animation<double> controller;
  final int index;
  final bool isDark;

  const _Blob({
    required this.controller,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final val = controller.value;
    final size = MediaQuery.of(context).size;
    final phase = (val * 0.3 + index * 0.22) % 1.0;
    final x = sin(phase * pi * 2 + index * 1.1) * size.width * 0.35 + size.width * 0.5;
    final y = cos(phase * pi * 2 * 0.7 + index * 0.9) * size.height * 0.25 + size.height * 0.5;
    final blobSize = 120.0 + sin(val * pi * 2 + index * 0.5) * 40;

    final colors = index % 2 == 0
        ? [
            const Color(0xFF2563EB).withValues(alpha: isDark ? 0.40 : 0.30),
            const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.20 : 0.12),
          ]
        : [
            const Color(0xFFD97706).withValues(alpha: isDark ? 0.35 : 0.25),
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.10),
          ];

    return Positioned(
      left: x - blobSize / 2,
      top: y - blobSize / 2,
      child: Container(
        width: blobSize,
        height: blobSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: isDark ? 0.4 : 0.20),
              blurRadius: isDark ? 80 : 60,
              spreadRadius: isDark ? 15 : 8,
            ),
          ],
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: AppButtonStyles.primaryGradientButton,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String? message;

  const AuthErrorBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        border: Border.all(color: AppColors.errorBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  final String message;

  const AuthSuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        border: Border.all(color: AppColors.success),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}