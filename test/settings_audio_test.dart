import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/constants/asset_paths.dart';
import 'package:glean_faith_app/core/services/audio_service.dart';
import 'package:glean_faith_app/features/settings/data/models/user_settings_model.dart';
import 'package:glean_faith_app/features/settings/domain/entities/user_settings.dart';

void main() {
  group('UserSettings audio defaults', () {
    test('a fresh install is audible at full volume', () {
      const settings = UserSettings();
      expect(settings.audioEnabled, isTrue);
      expect(settings.soundVolume, 1.0);
    });

    test('copyWith changes the audio fields without touching the rest', () {
      const base = UserSettings(quizReminderInterval: 12);
      final updated = base.copyWith(audioEnabled: false, soundVolume: 0.3);

      expect(updated.audioEnabled, isFalse);
      expect(updated.soundVolume, 0.3);
      // Unrelated settings survive.
      expect(updated.quizReminderInterval, 12);
    });

    test('copyWith keeps the old volume when only the flag changes', () {
      const base = UserSettings(soundVolume: 0.25);
      final updated = base.copyWith(audioEnabled: false);

      expect(updated.audioEnabled, isFalse);
      expect(updated.soundVolume, 0.25);
    });
  });

  group('UserSettingsModel audio persistence', () {
    test('a blob written before audio existed loads the defaults', () {
      // Regression guard: the settings blob is one JSON object, so an existing
      // install has a stored string with no audio keys at all.
      final decoded = jsonDecode(
        '{"notificationsEnabled":false,"themeMode":"dark","language":"np",'
        '"quizReminderInterval":7}',
      ) as Map<String, dynamic>;

      final settings = UserSettingsModel.fromJson(decoded).toEntity();

      expect(settings.audioEnabled, isTrue);
      expect(settings.soundVolume, 1.0);
      // The pre-existing fields still load.
      expect(settings.notificationsEnabled, isFalse);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, 'np');
      expect(settings.quizReminderInterval, 7);
    });

    test('a volume stored as an int does not throw', () {
      // The real trap: jsonDecode returns 1 as an int, and `as double?` would
      // throw and blank the whole settings page.
      final settings = UserSettingsModel.fromJson({
        'soundVolume': 1,
      }).toEntity();

      expect(settings.soundVolume, 1.0);
    });

    test('a volume stored as a double round-trips', () {
      final stored = UserSettingsModel.fromJson({'soundVolume': 0.35});
      final entity = stored.toEntity();
      expect(entity.soundVolume, 0.35);

      final reparsed = UserSettingsModel.fromJson(stored.toJson()).toEntity();
      expect(reparsed.soundVolume, 0.35);
    });

    test('an out-of-range volume is clamped instead of crashing the slider', () {
      expect(
        UserSettingsModel.fromJson({'soundVolume': 5}).toEntity().soundVolume,
        1.0,
      );
      expect(
        UserSettingsModel.fromJson({'soundVolume': -3}).toEntity().soundVolume,
        0.0,
      );
    });

    test('muting is persisted, not just held in memory', () {
      const model = UserSettingsModel(audioEnabled: false, soundVolume: 0.0);
      final reparsed = UserSettingsModel.fromJson(model.toJson());

      expect(reparsed.audioEnabled, isFalse);
      expect(reparsed.soundVolume, 0.0);
    });

    test('two settings differing only in volume are not equal', () {
      // Equatable props must include the audio fields, or Riverpod would treat
      // a volume change as a no-op and never repaint the slider.
      const quiet = UserSettingsModel(soundVolume: 0.1);
      const loud = UserSettingsModel(soundVolume: 0.9);

      expect(quiet, isNot(loud));
    });
  });

  group('AudioService', () {
    test('enabling and volume are applied, and the volume is clamped', () {
      final service = AudioService();
      addTearDown(service.dispose);

      expect(service.enabled, isTrue);

      service.setEnabled(false);
      expect(service.enabled, isFalse);

      service.setVolume(2.5);
      expect(service.volume, 1.0);

      service.setVolume(-1);
      expect(service.volume, 0.0);
    });

    test('every sound maps to a bundled mp3 that actually exists on disk', () {
      for (final sound in SfxSound.values) {
        expect(
          sound.assetPath,
          startsWith('assets/audios/'),
          reason: '${sound.name} must live in the audios asset folder',
        );
        expect(sound.assetPath, endsWith('.mp3'));
        // Catches a renamed or deleted file, which would otherwise be a silent
        // no-op at runtime with no error surfaced anywhere.
        expect(
          File(sound.assetPath).existsSync(),
          isTrue,
          reason: '${sound.assetPath} is missing from the repo',
        );
      }
      // Distinct files — a copy/paste mistake here would play the wrong cue.
      final paths = SfxSound.values.map((s) => s.assetPath).toSet();
      expect(paths.length, SfxSound.values.length);
    });

    test('playing while muted does not throw', () {
      final service = AudioService();
      addTearDown(service.dispose);

      service.setEnabled(false);
      // Must stay silent rather than reaching for a player.
      expect(() => service.play(SfxSound.correct), returnsNormally);
      expect(() => service.play(SfxSound.timer), returnsNormally);
    });
  });
}
