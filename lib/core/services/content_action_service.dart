import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../common/widgets/alert_widget.dart';
import 'logger_service.dart';

/// Clipboard and system share-sheet actions for scripture content.
///
/// Both actions are decoration around the content, so a failure is reported to
/// the user instead of being swallowed: copy shows a success toast only after
/// the clipboard write resolves, and share catches the platform error and says
/// so. A silent no-op is indistinguishable from a broken button.
class ContentActionService {
  const ContentActionService._();

  static Future<bool> copy(
    BuildContext context, {
    required String text,
    String message = 'Copied to clipboard',
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        AlertWidget.showSuccess(context, message);
      }
      return true;
    } catch (error) {
      LoggerService.error('Copy to clipboard failed', error);
      if (context.mounted) {
        AlertWidget.showError(context, 'Could not copy to the clipboard.');
      }
      return false;
    }
  }

  static Future<bool> share(
    BuildContext context, {
    required String text,
    String? subject,
  }) async {
    try {
      final box = context.findRenderObject();
      final origin = box is RenderBox && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          title: subject,
          sharePositionOrigin: origin,
        ),
      );
      return true;
    } catch (error) {
      LoggerService.error('Share failed', error);
      if (context.mounted) {
        AlertWidget.showError(context, 'Could not open the share sheet.');
      }
      return false;
    }
  }
}

/// Formats a verse as `"<text>" — <reference>` for the clipboard and the share
/// sheet. Kept pure so the exact shared wording can be asserted in a test.
String formatVerseForSharing({
  required String text,
  required String reference,
}) {
  final trimmedText = text.trim();
  final trimmedReference = reference.trim();
  if (trimmedText.isEmpty) return trimmedReference;
  if (trimmedReference.isEmpty) return trimmedText;
  return '"$trimmedText" — $trimmedReference';
}
