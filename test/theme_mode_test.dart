import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:glean_faith_app/core/common/providers/theme_mode_provider.dart';
import 'package:glean_faith_app/core/error/failures.dart';
import 'package:glean_faith_app/core/theme/app_theme.dart';
import 'package:glean_faith_app/core/theme/colors.dart';
import 'package:glean_faith_app/features/settings/data/models/user_settings_model.dart';
import 'package:glean_faith_app/features/settings/domain/entities/user_settings.dart';
import 'package:glean_faith_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:glean_faith_app/features/settings/presentation/providers/settings_provider.dart';

/// Stands in for the secure-storage backed repository so the theme-mode
/// mapping can be exercised without any platform channel.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    this.settings = const UserSettings(),
    this.failure,
  });

  final UserSettings settings;
  final Failure? failure;

  @override
  TaskEither<Failure, UserSettings> getSettings() {
    final error = failure;
    if (error != null) return TaskEither.left(error);
    return TaskEither.right(settings);
  }

  @override
  TaskEither<Failure, Unit> updateSettings(UserSettings settings) =>
      TaskEither.right(unit);
}

/// Builds a container whose settings load has already settled.
Future<ProviderContainer> _containerWith(SettingsRepository repository) async {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await container.read(settingsProvider.notifier).loadSettings();
  return container;
}

void main() {
  group('theme mode default (system)', () {
    test('a fresh UserSettings follows the system theme', () {
      expect(const UserSettings().themeMode, AppThemeMode.system);
    });

    test('a settings blob written before themeMode existed follows the '
        'system theme', () {
      final stored = UserSettingsModel.fromJson(const {'language': 'np'});
      expect(stored.themeMode, 'system');
      expect(stored.toEntity().themeMode, AppThemeMode.system);
    });

    test('an unknown stored theme falls back to system, never to dark', () {
      final stored = UserSettingsModel.fromJson(const {'themeMode': 'sepia'});
      expect(stored.toEntity().themeMode, AppThemeMode.system);
    });

    test('every AppThemeMode survives a store/load round trip', () {
      for (final mode in AppThemeMode.values) {
        final model = UserSettingsModel.fromEntity(UserSettings(themeMode: mode));
        final restored = UserSettingsModel.fromJson(model.toJson());
        expect(restored.toEntity().themeMode, mode);
        expect(model.toJson()['themeMode'], mode.name);
      }
    });
  });

  group('themeModeProvider', () {
    test('maps each stored setting onto a ThemeMode', () async {
      const expected = {
        AppThemeMode.light: ThemeMode.light,
        AppThemeMode.dark: ThemeMode.dark,
        AppThemeMode.system: ThemeMode.system,
      };
      for (final entry in expected.entries) {
        final container = await _containerWith(
          _FakeSettingsRepository(settings: UserSettings(themeMode: entry.key)),
        );
        expect(container.read(themeModeProvider), entry.value);
      }
    });

    test('is ThemeMode.system before the settings have loaded', () {
      // `themeModeProvider` is read first, which builds the notifier: its
      // constructor starts the async load and leaves the state in `loading`.
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider), isA<AsyncLoading<UserSettings>>());
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('stays ThemeMode.system when the settings load fails', () async {
      final container = await _containerWith(
        _FakeSettingsRepository(failure: const CacheFailure(message: 'nope')),
      );

      expect(container.read(settingsProvider), isA<AsyncError<UserSettings>>());
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('AppTheme parity', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    test('brightness and scaffold background match the palette', () {
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, AppColors.bgGray);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBg);
      expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    });

    test('dark surfaces are themed instead of Material defaults', () {
      // Every one of these renders as a full-screen overlay somewhere in the
      // app: an unthemed one is a white flash or an unreadable sheet.
      expect(dark.dialogTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.bottomSheetTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.bottomSheetTheme.modalBackgroundColor, AppColors.darkSurface);
      expect(dark.cardTheme.color, AppColors.darkSurface);
      expect(dark.popupMenuTheme.color, AppColors.darkSurface);
      expect(dark.drawerTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.snackBarTheme.backgroundColor, AppColors.darkSurfaceAlt);
      expect(dark.appBarTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.canvasColor, AppColors.darkBg);
      expect(dark.inputDecorationTheme.fillColor, AppColors.darkSurface);
    });

    test('light and dark never share a surface colour', () {
      final pairs = <String, List<Color?>>{
        'scaffold': [light.scaffoldBackgroundColor, dark.scaffoldBackgroundColor],
        'dialog': [
          light.dialogTheme.backgroundColor,
          dark.dialogTheme.backgroundColor,
        ],
        'bottom sheet': [
          light.bottomSheetTheme.backgroundColor,
          dark.bottomSheetTheme.backgroundColor,
        ],
        'card': [light.cardTheme.color, dark.cardTheme.color],
        'snack bar': [
          light.snackBarTheme.backgroundColor,
          dark.snackBarTheme.backgroundColor,
        ],
        'popup menu': [light.popupMenuTheme.color, dark.popupMenuTheme.color],
        'drawer': [
          light.drawerTheme.backgroundColor,
          dark.drawerTheme.backgroundColor,
        ],
        'app bar': [
          light.appBarTheme.backgroundColor,
          dark.appBarTheme.backgroundColor,
        ],
        'input fill': [
          light.inputDecorationTheme.fillColor,
          dark.inputDecorationTheme.fillColor,
        ],
      };
      pairs.forEach((name, colors) {
        expect(colors[0], isNotNull, reason: '$name has no light colour');
        expect(colors[1], isNotNull, reason: '$name has no dark colour');
        expect(colors[0], isNot(colors[1]), reason: '$name is shared');
      });
    });

    test('dark text stays readable on the dark surfaces', () {
      expect(dark.dialogTheme.titleTextStyle?.color, AppColors.darkTextPrimary);
      expect(dark.dialogTheme.contentTextStyle?.color, AppColors.darkTextMuted);
      expect(dark.listTileTheme.textColor, AppColors.darkTextSecondary);
      expect(dark.listTileTheme.subtitleTextStyle?.color, AppColors.darkTextMuted);
      expect(dark.iconTheme.color, AppColors.darkTextMuted);
      expect(dark.textTheme.bodyMedium?.color, AppColors.darkTextMuted);
      expect(dark.tabBarTheme.labelColor, AppColors.primaryLight);
      expect(dark.tabBarTheme.unselectedLabelColor, AppColors.darkTextMuted);
      expect(dark.snackBarTheme.contentTextStyle?.color, AppColors.darkTextPrimary);
    });

    test('placeholder, caret and selection are visible on dark', () {
      expect(
        dark.inputDecorationTheme.hintStyle?.color,
        AppColors.darkInputPlaceholder,
      );
      expect(
        dark.inputDecorationTheme.prefixIconColor,
        AppColors.darkInputIcon,
      );
      expect(dark.textSelectionTheme.cursorColor, AppColors.primaryLight);
      expect(dark.textSelectionTheme.selectionHandleColor, AppColors.primaryLight);
      expect(
        dark.textSelectionTheme.cursorColor,
        isNot(light.textSelectionTheme.cursorColor),
      );
    });

    test('dividers and loading tracks are not left transparent', () {
      expect(light.dividerTheme.color, AppColors.borderLight);
      expect(dark.dividerTheme.color, AppColors.darkBorder);
      expect(dark.progressIndicatorTheme.linearTrackColor, AppColors.darkBorder);
      expect(dark.progressIndicatorTheme.circularTrackColor, AppColors.darkBorder);
    });

    test('status-bar icons invert with the theme', () {
      expect(
        dark.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        light.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
    });
  });

  group('hardcoded-colour guard', () {
    // A pure-white/pure-black *surface* is the classic dark-mode bug: it stays
    // white when the theme flips. Text colours (including
    // `Colors.white.withValues(alpha: ...)` on a gradient) are legitimate and
    // are deliberately not matched here.
    final offenders = <String>[];
    final pattern = RegExp(
      r'(backgroundColor|fillColor|canvasColor|scaffoldBackgroundColor)'
      r':\s*(Colors\.white|Colors\.black|Color\(0xFF[Ff]{6}\)'
      r'|Color\(0xFF000000\))\s*[,)]',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // `// theme-guard: allowed` may sit on the offending line or the one
        // directly above it (a trailing comment can exceed the line length).
        if (line.contains('theme-guard: allowed') ||
            (i > 0 && lines[i - 1].contains('theme-guard: allowed'))) {
          continue;
        }
        if (pattern.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    test('no presentation surface is painted pure white or pure black', () {
      expect(
        offenders,
        isEmpty,
        reason: 'Use Theme.of(context).scaffoldBackgroundColor or an '
            'AppColors dark token instead:\n${offenders.join('\n')}',
      );
    });
  });
}
