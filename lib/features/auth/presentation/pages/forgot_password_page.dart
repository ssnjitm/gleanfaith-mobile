import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/auth_card.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await ref.read(authProvider.notifier).forgotPassword(
      _emailController.text.trim(),
    );

    if (error == null && mounted) {
      setState(() => _isSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthCard(
      title: 'Forgot Password?',
      subtitle: 'Enter your email to receive a password reset OTP',
      child: _isSuccess
          ? _SuccessContent(email: _emailController.text.trim())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthErrorBanner(
                    message: authState.status == AuthStatus.error ? authState.message : null,
                  ),
                  if (authState.status == AuthStatus.error)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        border: Border.all(color: AppColors.warningBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'If an account exists, you will receive an OTP',
                              style: TextStyle(fontSize: 13, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text('Email Address', style: AuthTextStyles.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the email address you used to sign up',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Send Reset OTP',
                    icon: Icons.send_rounded,
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleSubmit,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pushReplacement(RouteNames.signin),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Back to Login', style: AuthTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "We'll send a 6-digit OTP to verify your identity",
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final String email;

  const _SuccessContent({required this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 32, color: AppColors.success),
        ),
        const SizedBox(height: 16),
        const Text('Check Your Email', style: AuthTextStyles.title),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset OTP to",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The OTP is valid for 5 minutes',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Proceed to Reset Password',
          icon: Icons.key_rounded,
          onPressed: () {
            context.push(RouteNames.resetPassword, extra: email);
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () => context.pushReplacement(RouteNames.signin),
            child: const Text('Back to Login', style: AuthTextStyles.caption),
          ),
        ),
      ],
    );
  }
}