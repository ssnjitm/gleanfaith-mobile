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
        _buildSectionHeader(context, 'General'),
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
        const Divider(height: 32),
        _buildSectionHeader(context, 'Appearance'),
        const SizedBox(height: 12),
        _ThemeSelector(settings: settings),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final UserSettings settings;

  const _ThemeSelector({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1F2937) : AppColors.bgGray;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ThemeOption(
              icon: Icons.light_mode,
              label: 'Light',
              isSelected: settings.themeMode == AppThemeMode.light,
              onTap: () {
                ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(themeMode: AppThemeMode.light),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ThemeOption(
              icon: Icons.dark_mode,
              label: 'Dark',
              isSelected: settings.themeMode == AppThemeMode.dark,
              onTap: () {
                ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(themeMode: AppThemeMode.dark),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ThemeOption(
              icon: Icons.settings_brightness,
              label: 'System',
              isSelected: settings.themeMode == AppThemeMode.system,
              onTap: () {
                ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(themeMode: AppThemeMode.system),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryBlue : AppColors.primaryBlue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.textWhite
                  : (isDark ? Colors.grey[400] : AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textWhite
                    : (isDark ? Colors.grey[400] : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
