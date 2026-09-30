import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/services/app_update_info.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';

/// Storage key holding the `versionCode` the user last dismissed.
///
/// Without this the optional dialog would reappear on *every* app open, which
/// users experience as a bug. It stores the **dismissed** version, not a
/// timestamp, so publishing a newer release re-prompts automatically while a
/// re-published identical one stays quiet.
///
/// [StorageService] (flutter_secure_storage) is used rather than
/// `shared_preferences`: it is already a dependency, it is what every other
/// feature persists through, and this value is not large enough to justify a
/// second store.
const String kDismissedUpdateKey = 'app_update_dismissed_version_code';

enum AppUpdateStatus {
  /// Nothing has been checked yet.
  idle,

  /// A check is in flight.
  checking,

  /// A newer release is waiting for the user to accept it.
  available,

  /// The APK is downloading.
  downloading,

  /// The download finished and the system installer is open. Terminal: control
  /// now belongs to Android, and the app is usually killed when the install
  /// completes.
  installing,

  /// The run failed. Carries [AppUpdateState.message].
  error,
}

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;

  /// The release being offered, kept through the whole flow so the dialog can
  /// render the same notes while the download runs.
  final AppUpdateInfo? release;

  /// Download progress in `0..1`; null when the server sent no content length.
  final double? progress;

  /// Error text for [AppUpdateStatus.error].
  final String? message;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.release,
    this.progress,
    this.message,
  });

  bool get isBusy =>
      status == AppUpdateStatus.checking ||
      status == AppUpdateStatus.downloading;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? release,
    double? progress,
    String? message,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      release: release ?? this.release,
      progress: clearProgress ? null : (progress ?? this.progress),
      // A plain `message: null` cannot clear the field, because copyWith falls
      // back to `this.message`. Same trap as `QuizState.clearActiveQuiz`.
      message: clearError ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, release, progress, message];
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(ref.watch(appUpdateDioProvider));
});

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
      (ref) => AppUpdateNotifier(
        ref.watch(appUpdateServiceProvider),
        ref.watch(storageProvider),
      ),
    );

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final AppUpdateService _service;
  final StorageService _storage;

  AppUpdateNotifier(this._service, this._storage)
    : super(const AppUpdateState());

  /// Looks for a newer release and, if there is one, moves to
  /// [AppUpdateStatus.available].
  ///
  /// Safe to call on every launch and on resume. It is a silent no-op on
  /// iOS/web/desktop, on network failure, when the app is already current, and
  /// when the user previously dismissed *this* version.
  Future<void> check() async {
    if (state.isBusy) return;
    state = state.copyWith(status: AppUpdateStatus.checking, clearError: true);

    final result = await _service.check();
    final release = result.release;

    if (release == null) {
      state = state.copyWith(status: AppUpdateStatus.idle, clearError: true);
      return;
    }

    final dismissed = await _dismissedVersionCode();
    // A forced release ignores the dismissal: the user cannot opt out of it.
    if (!release.forceUpdate && dismissed >= release.versionCode) {
      state = state.copyWith(status: AppUpdateStatus.idle, clearError: true);
      return;
    }

    state = state.copyWith(
      status: AppUpdateStatus.available,
      release: release,
      clearError: true,
    );
  }

  /// "Update" - downloads the APK, then hands off to the system installer.
  ///
  /// Drives the plugin's event stream, so the dialog shows real byte progress
  /// rather than an indeterminate spinner. Guarded against re-entry: the plugin
  /// has a single native downloader and reports `ALREADY_RUNNING_ERROR` on a
  /// concurrent call, which would surface to the user as a failure caused by
  /// their own double tap.
  Future<void> updateNow() async {
    final release = state.release;
    if (release == null) return;
    if (state.status == AppUpdateStatus.downloading) return;

    state = state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0,
      clearError: true,
    );

    StreamSubscription<AppUpdateProgress>? subscription;
    subscription = _service
        .install(release)
        .listen(
          (progress) {
            if (!mounted) return;
            switch (progress.phase) {
              case AppUpdatePhase.downloading:
                state = state.copyWith(progress: progress.progress);
              case AppUpdatePhase.installing:
                // Terminal. Nothing after this is ours to report: Android owns the
                // install screen, and this app is normally killed when it finishes.
                state = state.copyWith(
                  status: AppUpdateStatus.installing,
                  clearProgress: true,
                );
                subscription?.cancel();
              case AppUpdatePhase.failed:
                state = state.copyWith(
                  status: AppUpdateStatus.error,
                  clearProgress: true,
                  message: progress.message,
                );
              case AppUpdatePhase.idle:
                // The plugin never emits this; treated as a no-op rather than
                // forcing a non-exhaustive switch.
                break;
            }
          },
          onError: (Object error) {
            LoggerService.error('App update failed', error);
            if (!mounted) return;
            state = state.copyWith(
              status: AppUpdateStatus.error,
              clearProgress: true,
              message: 'The update could not be completed. Please try again.',
            );
          },
        );
  }

  /// Aborts an in-flight download and returns the dialog to a retryable state.
  Future<void> cancelDownload() async {
    if (state.status != AppUpdateStatus.downloading) return;
    await _service.cancel();
    if (!mounted) return;
    state = state.copyWith(
      status: AppUpdateStatus.available,
      clearProgress: true,
      clearError: true,
    );
  }

  /// Returns to the "Update" button after a failure, keeping the release so the
  /// notes stay on screen.
  void retry() {
    final release = state.release;
    if (release == null) return;
    state = AppUpdateState(status: AppUpdateStatus.available, release: release);
  }

  /// "Later". Only reachable when the release is not forced.
  Future<void> dismiss() async {
    final release = state.release;
    if (release == null || release.forceUpdate) return;
    await _storage.write(kDismissedUpdateKey, '${release.versionCode}');
    LoggerService.info('Dismissed app update ${release.version}');
    state = const AppUpdateState();
  }

  /// Clears the dismissal so the next check re-prompts.
  Future<void> forgetDismissal() async {
    await _storage.delete(kDismissedUpdateKey);
  }

  Future<int> _dismissedVersionCode() async {
    final raw = await _storage.read(kDismissedUpdateKey);
    return int.tryParse(raw ?? '') ?? 0;
  }
}
