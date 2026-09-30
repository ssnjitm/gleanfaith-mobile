import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_constants.dart';
import 'app_update_info.dart';
import 'logger_service.dart';

/// Outcome of comparing the installed build against the published one.
enum UpdateAvailability {
  /// Nothing newer, or the platform cannot install an APK.
  upToDate,

  /// A newer version exists and should be offered.
  available,
}

/// The phases `ota_update` reports, mapped onto something the UI can drive.
///
/// The plugin's own `OtaStatus` is deliberately not exposed past this file:
/// its names are upper-snake-case and it adds `INSTALLATION_DONE` /
/// `INSTALLATION_ERROR`, which only ever fire when `usePackageInstaller: true`.
/// This app uses the default install intent, so those never arrive.
enum AppUpdatePhase {
  /// Nothing has run yet.
  idle,

  /// APK is downloading; `progress` is 0..1.
  downloading,

  /// The download finished and the system installer has been opened.
  installing,

  /// The run failed; `message` explains why.
  failed,
}

/// One step of an in-flight update run.
class AppUpdateProgress {
  final AppUpdatePhase phase;

  /// 0..1 while [phase] is [AppUpdatePhase.downloading]; null when the server
  /// sent no content length.
  final double? progress;

  /// User-facing error text, set only for [AppUpdatePhase.failed].
  final String? message;

  const AppUpdateProgress.downloading(this.progress)
    : phase = AppUpdatePhase.downloading,
      message = null;

  const AppUpdateProgress.installing()
    : phase = AppUpdatePhase.installing,
      progress = null,
      message = null;

  const AppUpdateProgress.failed(this.message)
    : phase = AppUpdatePhase.failed,
      progress = null;
}

/// Android in-app self-update for **sideloaded** distribution, built on
/// `ota_update`.
///
/// ## Platform support: Android only
///
/// The package markets itself as "Android and iOS", but that is not true in
/// practice. Its `pubspec.yaml` declares only `platforms: android`, so the iOS
/// pod is never registered; the `ios/` folder in the package is unreachable
/// dead code, and its own README says the iOS path is "not yet functioning".
/// What that dead code did was call `UIApplication.openURL` on the `.ipa` URL —
/// i.e. open Safari — which is not an update mechanism: iOS only installs apps
/// signed through the App Store (or an enterprise/AltStore channel). So iOS
/// users are pointed at the store instead of shown a prompt they cannot finish.
/// See [canInstallApk].
///
/// ## Distribution
///
/// This is the **sideload** path. A build distributed through Google Play must
/// not use it — Play policy forbids self-installing updates, and
/// `REQUEST_INSTALL_PACKAGES` triggers a policy rejection. For Play, use
/// Play In-App Updates (`in_app_update`) against the same
/// `AppUpdateInfo`; that is why parsing and comparison live here and the
/// transport does not.
///
/// ## Constraints the caller cannot bypass
/// * The APK must be signed with the **same key** as the installed build, or
///   Android rejects it with a signature mismatch and the user is stuck.
/// * Only an `.apk` can be installed. An `.aab` is Play-only.
/// * Android 8+ needs the user to grant "Install unknown apps" to this app;
///   that grant cannot be requested from code.
/// * The `provider` + `res/xml/filepaths.xml` entries are mandatory and are not
///   provided by the plugin's manifest. Without them the download succeeds and
///   the installer then fails.
class AppUpdateService {
  final Dio _dio;

  AppUpdateService(this._dio);

  /// Whether this platform can install an APK.
  ///
  /// `defaultTargetPlatform` is `android` under `flutter_test`, which keeps the
  /// comparison logic unit-testable without a device.
  static bool get canInstallApk =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The build number of the running app, from `pubspec.yaml`'s
  /// `version: 1.0.0+3`.
  Future<int> installedVersionCode() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber.trim()) ?? 0;
    } catch (error) {
      LoggerService.warning('Could not read the installed version: $error');
      return 0;
    }
  }

  /// Reads the published release, or `null` when the endpoint is unreachable or
  /// does not describe something installable.
  Future<AppUpdateInfo?> fetchLatestRelease() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.appLatestVersion);
      return AppUpdateInfo.fromResponse(response.data);
    } catch (error) {
      // A failed update check must never be user-visible: no network, a 404 from
      // a backend that has not deployed the endpoint yet, or a proxy hiccup all
      // just mean "carry on with the version you have".
      LoggerService.warning('App update check failed: $error');
      return null;
    }
  }

  /// True only when [release] is genuinely newer than the installed build.
  Future<bool> isNewerThanInstalled(AppUpdateInfo release) async {
    final installed = await installedVersionCode();
    // `installed == 0` means PackageInfo failed. Offering an update then would be
    // a coin flip, so stay quiet rather than nag users or offer a downgrade.
    if (installed <= 0) return false;
    return release.versionCode > installed;
  }

  /// Convenience: fetch, then compare.
  Future<({UpdateAvailability status, AppUpdateInfo? release})> check() async {
    if (!canInstallApk) {
      return (status: UpdateAvailability.upToDate, release: null);
    }
    final release = await fetchLatestRelease();
    if (release == null) {
      return (status: UpdateAvailability.upToDate, release: null);
    }
    if (!await isNewerThanInstalled(release)) {
      return (status: UpdateAvailability.upToDate, release: null);
    }
    return (status: UpdateAvailability.available, release: release);
  }

  /// Downloads [release] and opens the system installer, emitting progress.
  ///
  /// Deliberately **not** built on `_dio.download`, even though this class holds
  /// a Dio: the plugin needs the bytes in its own `<files>/ota_update/` folder
  /// (that is what `res/xml/filepaths.xml` exposes), and it already does the
  /// transfer, the SHA-256 verification and the install intent. Routing it
  /// through Dio would mean writing the APK somewhere the FileProvider cannot
  /// see, which fails at install time rather than at download time.
  ///
  /// Uses a fresh [OtaUpdate] per call: the plugin caches its progress stream on
  /// the instance, so a reused instance returns the *previous* run's completed
  /// stream and the update silently does nothing. A second concurrent run on the
  /// plugin's single native downloader reports `ALREADY_RUNNING_ERROR`, which is
  /// why [cancel] exists.
  Stream<AppUpdateProgress> install(AppUpdateInfo release) {
    // The plugin throws synchronously on a filename containing '/', and on any
    // channel error the stream reports instead of throwing — so the try/catch is
    // for the argument case only.
    final ota = OtaUpdate();

    return ota
        .execute(
          release.apkUrl,
          destinationFilename: _destinationFilename(release),
          // Verified by the plugin after download; a mismatch aborts instead of
          // handing a truncated file to the installer.
          sha256checksum: release.sha256,
          headers: const <String, String>{},
        )
        .map(mapEvent)
        .handleError((Object error) {
          // Belt-and-braces: anything the plugin surfaces as a stream error
          // rather than an OtaStatus.
          LoggerService.error('App update stream failed', error);
          throw const AppUpdateProgress.failed(
            'The update could not be started. Please try again.',
          );
        });
  }

  /// Cancels an in-flight download. Only meaningful while
  /// [AppUpdatePhase.downloading] is current — once the installer is open the
  /// run has left the app's hands.
  Future<void> cancel() async {
    try {
      await OtaUpdate().cancel();
    } catch (error) {
      LoggerService.warning('Could not cancel the update: $error');
    }
  }

  /// Filename the plugin saves the APK as.
  ///
  /// Keyed by `versionCode` so a new release never reuses a stale file, and kept
  /// free of '/' because the plugin rejects a path in this argument outright.
  static String _destinationFilename(AppUpdateInfo release) =>
      'glean-faith-${release.versionCode}.apk';

  /// Public only so the mapping can be unit-tested; it is not part of the
  /// intended call surface.
  @visibleForTesting
  static AppUpdateProgress mapEvent(OtaEvent event) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        // The plugin reports whole-number percentages; guard the division
        // because a malformed 0 would otherwise produce NaN and pin the
        // progress bar at an unrenderable value.
        final percent = double.tryParse(event.value ?? '') ?? 0;
        return AppUpdateProgress.downloading((percent / 100).clamp(0.0, 1.0));

      case OtaStatus.INSTALLING:
        return const AppUpdateProgress.installing();

      case OtaStatus.ALREADY_RUNNING_ERROR:
        return const AppUpdateProgress.failed(
          'An update is already downloading. Wait for it to finish.',
        );

      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        // The one failure users hit often, so it names the actual fix instead of
        // reporting a bare code.
        return const AppUpdateProgress.failed(
          'Allow "Install unknown apps" for Glean Faith in your device '
          'settings, then try again.',
        );

      case OtaStatus.CHECKSUM_ERROR:
        return const AppUpdateProgress.failed(
          'The downloaded file was corrupted. Please try again.',
        );

      case OtaStatus.DOWNLOAD_ERROR:
        return const AppUpdateProgress.failed(
          'Download failed. Check your connection and try again.',
        );

      case OtaStatus.CANCELED:
        return const AppUpdateProgress.failed('The update was canceled.');

      // INSTALLATION_DONE / INSTALLATION_ERROR only occur with
      // usePackageInstaller: true, which this app does not enable. Treated as a
      // terminal failure rather than ignored, so a future switch to that mode
      // surfaces on screen instead of hanging.
      case OtaStatus.INSTALLATION_DONE:
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
        return AppUpdateProgress.failed(
          event.value?.trim().isNotEmpty == true
              ? 'Update failed: ${event.value}'
              : 'The update could not be completed. Please try again.',
        );
    }
  }
}
