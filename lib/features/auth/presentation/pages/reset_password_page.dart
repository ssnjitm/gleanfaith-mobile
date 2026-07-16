import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/auth_card.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../providers/auth_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isOtpStep = true;
  bool _isSuccess = false;
  String _passwordError = '';

  String get _email => (GoRouterState.of(context).extra as String?) ?? '';

  @override
  void dispose() {
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _onOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleOtpSubmit() {
    if (_otp.length == 6) {
      setState(() => _isOtpStep = false);
    }
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return false;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => _passwordError = 'Password must contain at least one uppercase letter');
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = 'Password must contain at least one number');
      return false;
    }
    setState(() => _passwordError = '');
    return true;
  }

  Future<void> _handlePasswordSubmit() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    if (!_validatePassword(_newPasswordController.text)) return;

    final error = await ref.read(authProvider.notifier).resetPassword(
      email: _email,
      otp: _otp,
      newPassword: _newPasswordController.text,
    );

    if (error == null && mounted) {
      setState(() => _isSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) {
      return AuthCard(
        title: 'Verify Reset Code',
        subtitle: '',
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Password Reset Successful!', style: AuthTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Your password has been changed successfully.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Go to Login',
              icon: Icons.login_rounded,
              onPressed: () => context.go(RouteNames.signin),
            ),
          ],
        ),
      );
    }

    return AuthCard(
      title: _isOtpStep ? 'Verify Reset Code' : 'Create New Password',
      subtitle: _isOtpStep
          ? 'Enter the 6-digit code sent to $_email'
          : 'Your new password must be different from previous ones',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.status == AuthStatus.error)
            AuthErrorBanner(message: authState.message),

          if (_isOtpStep) ...[
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
                        fillColor: isDark ? const Color(0xFF334155) : AppColors.bgWhite,
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
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Enter the 6-digit OTP sent to your email',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Verify OTP',
              icon: Icons.key_rounded,
              isDisabled: _otp.length != 6,
              onPressed: _handleOtpSubmit,
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => context.pushReplacement(RouteNames.forgotPassword),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text('Back to Forgot Password', style: AuthTextStyles.caption),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text('New Password', style: AuthTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.inputIcon,
                  ),
                  onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Confirm New Password', style: AuthTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.inputIcon,
                  ),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_newPasswordController.text.isNotEmpty)
              _PasswordRequirements(password: _newPasswordController.text),
            if (_passwordError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(_passwordError, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Reset Password',
              icon: Icons.lock_rounded,
              isLoading: authState.status == AuthStatus.loading,
              isDisabled: _newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty,
              onPressed: _handlePasswordSubmit,
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReqRow(label: 'At least 8 characters', met: password.length >= 8),
        const SizedBox(height: 2),
        _ReqRow(label: 'One uppercase letter', met: password.contains(RegExp(r'[A-Z]'))),
        const SizedBox(height: 2),
        _ReqRow(label: 'One number', met: password.contains(RegExp(r'[0-9]'))),
      ],
    );
  }
}

class _ReqRow extends StatelessWidget {
  final String label;
  final bool met;

  const _ReqRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle,
          size: 12,
          color: met ? AppColors.success : AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}