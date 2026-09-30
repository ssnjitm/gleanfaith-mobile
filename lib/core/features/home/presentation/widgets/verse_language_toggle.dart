import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/widgets/segmented_code_toggle.dart';
import '../../../../../features/bible/domain/entities/verse_of_the_day.dart';
import '../../../../../features/bible/presentation/providers/verse_language_provider.dart';

/// `EN | NP` control for the Home "Verse of the Day" card.
///
/// Changes **only** the verse text and its reference. Every label in the app
/// stays English in both modes — the card still says "Verse of the Day", and
/// the daily notification still says "Good Morning!".
class VerseLanguageToggle extends ConsumerWidget {
  const VerseLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(verseLanguageProvider);
    final notifier = ref.read(verseLanguageProvider.notifier);

    return SegmentedCodeToggle(
      semanticsLabel: 'Verse language',
      value: language.code,
      options: const [
        SegmentedCodeOption(value: 'en', label: 'EN'),
        SegmentedCodeOption(value: 'np', label: 'NP'),
      ],
      onChanged: (code) => notifier.setLanguage(VerseLanguage.fromCode(code)),
    );
  }
}
