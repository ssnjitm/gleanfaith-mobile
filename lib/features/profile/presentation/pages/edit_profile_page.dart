import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(profileProvider.notifier).load();
    });
  }

  void _fillFromProfile() {
    final authUser = ref.read(authProvider).user;
    final profile = ref.read(profileProvider).profile;
    _fullNameController.text =
        profile?.fullName ?? authUser?.fullName ?? '';
    _usernameController.text =
        profile?.username ?? authUser?.username ?? '';
    _phoneController.text =
        profile?.phoneNumber ?? authUser?.phoneNumber ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(profileProvider.notifier).updateProfile(
          fullName: _fullNameController.text,
          username: _usernameController.text,
          phoneNumber: _phoneController.text,
        );
    if (!mounted) return;
    if (success) {
      AlertWidget.showSuccess(context, 'Profile updated');
      context.pop();
    } else {
      final message = ref.read(profileProvider).message;
      AlertWidget.showError(context, message ?? 'Could not update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_initialized && state.profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_fillFromProfile);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          children: [
            Text(
              'Keep your details up to date',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Username is required' : null,
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(
              height: AppDimensions.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: state.isSaving ? null : _handleSubmit,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(state.isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ),
            if (state.profile?.email != null &&
                (state.profile?.email.isNotEmpty ?? false)) ...[
              const SizedBox(height: AppDimensions.paddingLg),
              Center(
                child: Text(
                  'Email: ${state.profile!.email} (cannot be changed here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
