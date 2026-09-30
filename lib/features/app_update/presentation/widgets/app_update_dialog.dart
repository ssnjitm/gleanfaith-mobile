import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_update_info.dart';
import '../../../../core/theme/colors.dart';
import '../providers/app_update_provider.dart';

/// Modal announcing a new release, with a download button.
///
/// The **only** update surface in the app. Two rules it must never break:
/// * A forced release is not dismissible â€” no barrier tap, no back gesture.
/// * The primary button is never rendered without a working `onPressed`. A
///   visibly greyed button that silently ignores taps was the exact bug the
///   daily-quiz Start button had, so `forceUpdate` is honoured by removing
///   "Later" entirely rather than by disabling a control.
class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key});

  /// Shows the dialog once for [AppUpdateState.status] == available/ready and
  /// returns when it closes.
  ///
  /// Guarded against re-entry: the caller may rebuild (any provider change, a
  /// rotation, returning from a nested route) while the dialog is up, and each
  /// of those would otherwise stack another copy.
  static Future<void> showIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    required int shownVersionCode,
  }) async {
    final state = ref.read(appUpdateProvider);
    if (state.status != AppUpdateStatus.available &&
        state.status != AppUpdateStatus.downloading &&
        state.status != AppUpdateStatus.error) {
      return;
    }
    if (state.release == null ||
        state.release!.versionCode == shownVersionCode) {
      return;
    }

    await showDialog<void>(
      context: context,
      // A forced update is the one case where the user genuinely cannot opt
      // out, so the route itself must be non-poppable.
      barrierDismissible: !state.release!.forceUpdate,
      builder: (context) =>
          const PopScope(canPop: false, child: AppUpdateDialog()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final release = state.release;
    if (release == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update Available',
              style: TextStyle(color: titleColor, fontSize: 18),
            ),
          ),
        ],
      ),
      content: _DialogBody(
        release: release,
        state: state,
        bodyColor: bodyColor,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      actions: [
        if (!release.forceUpdate)
          TextButton(
            onPressed: () {
              // Record the dismissal *before* popping: popping first would let
              // the next build re-show the dialog, because the dismissal has
              // not been persisted yet.
              ref.read(appUpdateProvider.notifier).dismiss();
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
        SizedBox(
          width: 132,
          height: 44,
          child: FilledButton(
            onPressed: state.status == AppUpdateStatus.checking
                ? null
                : () => ref.read(appUpdateProvider.notifier).updateNow(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _PrimaryLabel(state: state, release: release),
          ),
        ),
      ],
    );
  }
}

class _DialogBody extends ConsumerWidget {
  final AppUpdateInfo release;
  final AppUpdateState state;
  final Color bodyColor;

  const _DialogBody({
    required this.release,
    required this.state,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = release.readableSize;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version ${release.version}'
            '${size.isEmpty ? '' : '  -  $size'}',
            style: TextStyle(color: bodyColor, fontSize: 13),
          ),
          if (release.forceUpdate) ...[
            const SizedBox(height: 12),
            const _Notice(
              text: 'This update is required to continue using the app.',
              color: AppColors.error,
            ),
          ],
          if (release.releaseNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "What's new",
              style: TextStyle(
                color: bodyColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              release.releaseNotes,
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.45),
            ),
          ],
          if (state.status == AppUpdateStatus.downloading) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    state.progress == null
                        ? 'Downloading...'
                        // Truncated to a whole percent: a 100x-churned label
                        // re-lays out on every one of dozens of callbacks.
                        : 'Downloading ${(state.progress! * 100).floor()}%',
                    style: TextStyle(color: bodyColor, fontSize: 12),
                  ),
                ),
                // Escape hatch for a stalled download on a slow connection.
                TextButton(
                  onPressed: () =>
                      ref.read(appUpdateProvider.notifier).cancelDownload(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: bodyColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (state.status == AppUpdateStatus.installing) ...[
            const SizedBox(height: 14),
            const _Notice(
              text: 'Download complete. Follow the system prompt to install.',
              color: AppColors.success,
            ),
          ],
          if (state.status == AppUpdateStatus.error) ...[
            const SizedBox(height: 14),
            _Notice(
              text: state.message ?? 'The update failed.',
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryLabel extends StatelessWidget {
  final AppUpdateState state;
  final AppUpdateInfo release;

  const _PrimaryLabel({required this.state, required this.release});

  @override
  Widget build(BuildContext context) {
    // Keyed for Maestro / integration testing (see the flows under maestro/).
    return switch (state.status) {
      AppUpdateStatus.downloading => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      ),
      AppUpdateStatus.installing => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.install_mobile_rounded, size: 18),
          SizedBox(width: 6),
          Text('Installing'),
        ],
      ),
      AppUpdateStatus.error => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh_rounded, size: 18),
          const SizedBox(width: 6),
          Text(
            'Retry',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: release.forceUpdate ? Colors.white : null,
            ),
          ),
        ],
      ),
      _ => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download_rounded, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Update',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: release.forceUpdate ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    };
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;

  const _Notice({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12.5, height: 1.35),
      ),
    );
  }
}
