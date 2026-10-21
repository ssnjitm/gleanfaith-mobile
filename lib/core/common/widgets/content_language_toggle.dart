import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/content_language.dart';
import '../providers/content_language_provider.dart';
import 'segmented_code_toggle.dart';

/// The `EN | NP` control for the **global** Bible-content language.
///
/// This is the only language control in the app: it reads and writes
/// `contentLanguageProvider`, so flipping it switches the verse of the day,
/// the Bible reader, the Bible fun facts, the Bible games and the quiz
/// content everywhere at once.
///
/// It changes **Bible content only**. The app's own chrome — labels, buttons,
/// menus, error messages — stays in the app's default UI language in both
/// modes.
///
/// Leave [value] and [onChanged] null to drive the global preference. Pass
/// both to control it locally (the quiz play pages do this so a switch
/// mid-quiz re-renders the current question immediately).
class ContentLanguageToggle extends ConsumerWidget {
  /// Renders a light control for regular surfaces or an inverted (on-gradient)
  /// one for hero cards.
  final bool onGradient;

  /// Controlled mode: the currently selected language.
  final ContentLanguage? value;

  /// Controlled mode: called with the newly selected language.
  final ValueChanged<ContentLanguage>? onChanged;

  /// Announced to screen readers, e.g. `Content language`.
  final String semanticsLabel;

  const ContentLanguageToggle({
    super.key,
    this.onGradient = false,
    this.value,
    this.onChanged,
    this.semanticsLabel = 'Content language',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isControlled = value != null && onChanged != null;
    final ContentLanguage language =
        value ?? ref.watch(contentLanguageProvider);

    void select(ContentLanguage option) {
      if (isControlled) {
        onChanged!(option);
      } else {
        ref.read(contentLanguageProvider.notifier).setLanguage(option);
      }
    }

    return SegmentedCodeToggle(
      semanticsLabel: semanticsLabel,
      onGradient: onGradient,
      value: language.code,
      options: const [
        SegmentedCodeOption(value: 'en', label: 'EN'),
        SegmentedCodeOption(value: 'np', label: 'NP'),
      ],
      onChanged: (code) => select(ContentLanguage.fromCode(code)),
    );
  }
}
