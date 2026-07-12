import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/common/widgets/app_loading.dart';
import '../../../../core/common/widgets/app_error_widget.dart';
import '../../domain/entities/user_settings.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.read(settingsProvider.notifier).loadSettings(),
        ),
        data: (settings) => _SettingsContent(settings: settings),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  final UserSettings settings;

  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      children: [
        SwitchListTile(
          title: const Text('Notifications'),
          subtitle: const Text('Receive quiz reminders'),
          value: settings.notificationsEnabled,
          activeTrackColor: AppColors.primaryBlue,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(notificationsEnabled: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: settings.darkMode,
          activeTrackColor: AppColors.primaryBlue,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(darkMode: value),
            );
          },
        ),
      ],
    );
  }
}
