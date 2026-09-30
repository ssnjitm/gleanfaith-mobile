import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ota_update/ota_update.dart';
import 'package:glean_faith_app/core/services/app_update_info.dart';
import 'package:glean_faith_app/core/services/app_update_service.dart';

/// A release is only installable if we know its build number and a real APK
/// URL, so most of these cases assert `null` rather than a partially-built
/// object.
void main() {
  group('AppUpdateInfo.fromResponse', () {
    Map<String, dynamic> base() => {
      'version': '1.2.0',
      'versionCode': 12,
      'forceUpdate': false,
      'releaseNotes': 'Bug fixes',
      'apkUrl': 'https://cdn.example.com/app.apk',
    };

    test('parses the documented payload', () {
      final info = AppUpdateInfo.fromResponse(base());
      expect(info, isNotNull);
      expect(info!.version, '1.2.0');
      expect(info.versionCode, 12);
      expect(info.forceUpdate, isFalse);
      expect(info.releaseNotes, 'Bug fixes');
      expect(info.apkUrl, 'https://cdn.example.com/app.apk');
    });

    test('unwraps a { "data": { ... } } envelope', () {
      final info = AppUpdateInfo.fromResponse({'data': base()});
      expect(info?.versionCode, 12);
    });

    test('unwraps a nested { "version": { ... } } object', () {
      final info = AppUpdateInfo.fromResponse({'version': base()});
      expect(info?.versionCode, 12);
    });

    // A renamed key must not silently disable updates for everyone.
    test('accepts snake_case and camelCase aliases', () {
      final info = AppUpdateInfo.fromResponse({
        'version_name': '2.0.0',
        'version_code': '20',
        'is_force': 'true',
        'release_notes': 'notes',
        'download_url': 'https://cdn.example.com/x.apk',
      });
      expect(info?.version, '2.0.0');
      expect(info?.versionCode, 20);
      expect(info?.forceUpdate, isTrue);
      expect(info?.releaseNotes, 'notes');
    });

    test('coerces forceUpdate from numbers and strings', () {
      expect(
        AppUpdateInfo.fromResponse({...base(), 'forceUpdate': 1})?.forceUpdate,
        isTrue,
      );
      expect(
        AppUpdateInfo.fromResponse({
          ...base(),
          'forceUpdate': 'yes',
        })?.forceUpdate,
        isTrue,
      );
      expect(
        AppUpdateInfo.fromResponse({
          ...base(),
          'forceUpdate': 'false',
        })?.forceUpdate,
        isFalse,
      );
      // Absent means optional, so a missing flag can never lock a user out.
      final info = AppUpdateInfo.fromResponse(
        {...base()}..remove('forceUpdate'),
      );
      expect(info?.forceUpdate, isFalse);
    });

    test('rejects a payload without a usable versionCode', () {
      expect(
        AppUpdateInfo.fromResponse({...base()}..remove('versionCode')),
        isNull,
      );
      expect(AppUpdateInfo.fromResponse({...base(), 'versionCode': 0}), isNull);
      expect(
        AppUpdateInfo.fromResponse({...base(), 'versionCode': -1}),
        isNull,
      );
      expect(
        AppUpdateInfo.fromResponse({...base(), 'versionCode': 'x'}),
        isNull,
      );
    });

    // An AAB is not installable and cleartext is blocked by the manifest, so
    // offering either would be a dead button.
    test('rejects a non-HTTPS or unparseable URL', () {
      expect(
        AppUpdateInfo.fromResponse({
          ...base(),
          'apkUrl': 'http://cdn.example.com/a.apk',
        }),
        isNull,
      );
      expect(
        AppUpdateInfo.fromResponse({...base(), 'apkUrl': 'not a url'}),
        isNull,
      );
      expect(
        AppUpdateInfo.fromResponse({...base(), 'apkUrl': 'https://'}),
        isNull,
      );
    });

    test('rejects a payload without a URL', () {
      expect(AppUpdateInfo.fromResponse({...base()}..remove('apkUrl')), isNull);
    });

    test('rejects non-object and null responses', () {
      expect(AppUpdateInfo.fromResponse(null), isNull);
      expect(AppUpdateInfo.fromResponse('nope'), isNull);
      expect(AppUpdateInfo.fromResponse(42), isNull);
      expect(AppUpdateInfo.fromResponse({'data': null}), isNull);
    });

    // A nested map must never be stringified into the release notes.
    test('never stringifies a container into releaseNotes', () {
      final info = AppUpdateInfo.fromResponse({
        ...base(),
        'releaseNotes': {'en': 'hi', 'np': 'ह'},
      });
      expect(info?.releaseNotes, '');
    });

    test('falls back to the versionCode when version is absent', () {
      final info = AppUpdateInfo.fromResponse(base()..remove('version'));
      expect(info?.version, '12');
    });

    test('formats the advertised size for the download button', () {
      expect(
        AppUpdateInfo.fromResponse({
          ...base(),
          'sizeBytes': 52428800,
        })?.readableSize,
        '50.0 MB',
      );
      expect(
        AppUpdateInfo.fromResponse({
          ...base(),
          'sizeBytes': 2048,
        })?.readableSize,
        '2 KB',
      );
      // Unknown size must render nothing, not "0 KB".
      expect(AppUpdateInfo.fromResponse(base())?.readableSize, '');
    });

    test('equality is value-based', () {
      expect(
        AppUpdateInfo.fromResponse(base()),
        AppUpdateInfo.fromResponse(base()),
      );
    });
  });

  group('ota_update event mapping', () {
    // Every failure the plugin can report must become a message a user can act
    // on; an unmapped code would show a raw enum name in the dialog.
    test('maps download progress to a 0..1 fraction', () {
      final progress = AppUpdateService.mapEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '42'),
      );
      expect(progress.phase, AppUpdatePhase.downloading);
      expect(progress.progress, closeTo(0.42, 0.0001));
    });

    test('clamps malformed progress instead of emitting NaN', () {
      // A NaN would pin the LinearProgressIndicator at an unrenderable value.
      for (final value in [null, '', 'abc']) {
        final progress = AppUpdateService.mapEvent(
          OtaEvent(OtaStatus.DOWNLOADING, value),
        );
        expect(progress.progress, isNotNull);
        expect(progress.progress!.isNaN, isFalse);
        expect(progress.progress, inInclusiveRange(0.0, 1.0));
      }
      expect(
        AppUpdateService.mapEvent(
          OtaEvent(OtaStatus.DOWNLOADING, '250'),
        ).progress,
        1.0,
      );
    });

    test('INSTALLING is its own terminal phase, not a download', () {
      final progress = AppUpdateService.mapEvent(
        OtaEvent(OtaStatus.INSTALLING, null),
      );
      expect(progress.phase, AppUpdatePhase.installing);
      expect(progress.progress, isNull);
    });

    test('every plugin failure becomes a user-facing message', () {
      const failing = [
        OtaStatus.ALREADY_RUNNING_ERROR,
        OtaStatus.PERMISSION_NOT_GRANTED_ERROR,
        OtaStatus.CHECKSUM_ERROR,
        OtaStatus.DOWNLOAD_ERROR,
        OtaStatus.CANCELED,
        OtaStatus.INSTALLATION_ERROR,
        OtaStatus.INTERNAL_ERROR,
      ];

      for (final status in failing) {
        final progress = AppUpdateService.mapEvent(OtaEvent(status, null));
        expect(
          progress.phase,
          AppUpdatePhase.failed,
          reason: '$status must map to a failure',
        );
        expect(progress.message, isNotNull);
        expect(progress.message, isNotEmpty);
      }
    });

    test('the permission error names the setting the user must change', () {
      final progress = AppUpdateService.mapEvent(
        OtaEvent(OtaStatus.PERMISSION_NOT_GRANTED_ERROR, null),
      );
      expect(progress.message, contains('Install unknown apps'));
    });

    test('INSTALLATION_DONE still resolves, so the stream cannot hang', () {
      // Only emitted with usePackageInstaller, which we do not enable; it must
      // still be handled so the switch stays exhaustive and the dialog settles.
      final progress = AppUpdateService.mapEvent(
        OtaEvent(OtaStatus.INSTALLATION_DONE, null),
      );
      expect(progress.phase, AppUpdatePhase.failed);
    });
  });

  group('platform gating', () {
    // iOS forbids self-installing an app and web/desktop have no package
    // installer, so the check must be a no-op there rather than showing a prompt
    // the user cannot complete.
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('is enabled on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppUpdateService.canInstallApk, isTrue);
    });

    test('is disabled on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(AppUpdateService.canInstallApk, isFalse);
    });

    test('is disabled on other desktop targets', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(AppUpdateService.canInstallApk, isFalse);
    });
  });
}
