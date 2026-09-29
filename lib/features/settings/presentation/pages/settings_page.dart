import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/audio_providers.dart';
import '../../../../core/constants/asset_paths.dart';
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
        const Divider(height: 32),
        _buildSectionHeader(context, 'Audio'),
        SwitchListTile(
          title: const Text('Sound effects'),
          subtitle: const Text('Play sounds for answers, countdown and results'),
          value: settings.audioEnabled,
          activeTrackColor: AppColors.primaryBlue,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(audioEnabled: value),
            );
          },
        ),
        // Hidden rather than disabled: a slider under an off switch looks
        // broken, and the whole point of it is to be gone when muted.
        if (settings.audioEnabled) ...[
          _VolumeControl(settings: settings),
        ],
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

/// Volume slider with a live percentage and an audible preview.
///
/// Persists only on release ([Slider.onChangeEnd]). Dragging writes to secure
/// storage on every frame otherwise — dozens of `json.encode` writes per
/// gesture — and a storage hiccup mid-drag would replace the whole page state
/// with an error. The value is still pushed to the [AudioService] live, so the
/// preview blip reflects exactly where the thumb is.
class _VolumeControl extends ConsumerStatefulWidget {
  final UserSettings settings;

  const _VolumeControl({required this.settings});

  @override
  ConsumerState<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<_VolumeControl> {
  late double _volume = widget.settings.soundVolume.clamp(0.0, 1.0);

  @override
  void didUpdateWidget(covariant _VolumeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The stored value won (e.g. reverted elsewhere) — follow it unless the
    // user is mid-drag.
    if (oldWidget.settings.soundVolume != widget.settings.soundVolume) {
      _volume = widget.settings.soundVolume.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = (_volume * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              Icon(
                _volume <= 0
                    ? Icons.volume_off_rounded
                    : _volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                size: 20,
                color: isDark ? Colors.grey[400] : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Volume',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _volume,
            max: 1.0,
            divisions: 20,
            label: '$percent%',
            activeColor: AppColors.primaryBlue,
            inactiveColor: isDark ? const Color(0xFF334155) : AppColors.borderLight,
            onChanged: (value) {
              setState(() => _volume = value);
              // Live, so the preview below is heard at the dragged level.
              ref.read(audioServiceProvider).setVolume(value);
            },
            onChangeEnd: (value) {
              ref.read(settingsProvider.notifier).updateSettings(
                widget.settings.copyWith(soundVolume: value),
              );
              _preview();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: OutlinedButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Test sound'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
              ),
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ),
      ],
    );
  }

  void _preview() {
    ref.read(audioServiceProvider).play(SfxSound.correct);
  }
}
