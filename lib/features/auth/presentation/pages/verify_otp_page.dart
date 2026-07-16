import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/auth_card.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../providers/auth_provider.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _timeLeft = 300;
  bool _canResend = false;

  String get _email => (GoRouterState.of(context).extra as String?) ?? '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _startTimer() {
    _timer?.cancel();
    setState(() { _timeLeft = 300; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 0) {
        _timer?.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _timeLeft--);
      }
    });
  }

  String get _formattedTime {
    final m = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    if (_otp.length != 6) return;
    final error = await ref.read(authProvider.notifier).verifyOtp(_email, _otp);
    if (error == null && mounted) {
      context.go(RouteNames.signin);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    final error = await ref.read(authProvider.notifier).resendOtp(_email);
    if (error == null) {
      for (final c in _otpControllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthCard(
      title: 'Verify Your Email',
      subtitle: 'Enter the 6-digit code sent to ${_email.isNotEmpty ? _email : 'your email'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthErrorBanner(
            message: authState.status == AuthStatus.error ? authState.message : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                child: SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AuthTextStyles.otpDigit,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : AppColors.bgWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.otpBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.otpFocusBorder, width: 2),
                      ),
                    ),
                    onChanged: (v) => _onOtpChange(i, v),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (authState.status == AuthStatus.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          Center(
            child: _canResend
                ? GestureDetector(
                    onTap: _handleResend,
                    child: const Text('Resend verification code', style: AuthTextStyles.link),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Code expires in $_formattedTime',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Verify & Create Account',
            icon: Icons.verified_user_rounded,
            isLoading: false,
            isDisabled: _otp.length != 6,
            onPressed: _handleVerify,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => context.pushReplacement(RouteNames.signup),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('Back to Sign Up', style: AuthTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              "Didn't receive the code? Check your spam folder",
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}