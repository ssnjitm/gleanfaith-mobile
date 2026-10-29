import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../services/content_action_service.dart';
import '../../../../../features/bible/domain/entities/verse_of_the_day.dart';
import '../../../../../features/bible/presentation/providers/verse_of_the_day_provider.dart';
import 'verse_of_the_day_card.dart';

class HomeVerseOfTheDay extends ConsumerWidget {
  const HomeVerseOfTheDay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVerse = ref.watch(verseOfTheDayDisplayProvider);

    return asyncVerse.when(
      loading: () =>
          const VerseOfTheDayCard(text: '', reference: '', isLoading: true),
      // The loader already substitutes a hardcoded verse for a total failure, so
      // this only fires if the provider itself throws.
      error: (_, _) => const VerseOfTheDayCard(
        text: kVerseFallbackText,
        reference: kVerseFallbackReference,
      ),
      data: (verse) => _buildCard(context, ref, verse),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    VerseOfTheDay verse,
  ) {
    final shareText = formatVerseForSharing(
      text: verse.text,
      reference: verse.reference,
    );

    return VerseOfTheDayCard(
      text: verse.text,
      reference: verse.reference,
      isNepali: verse.isNepali,
      // A fallback can now happen in *either* direction: English mode falls
      // back to Nepali just as Nepali mode falls back to English, so the
      // notice is no longer gated on the selected language.
      showTranslationNotice: verse.isFallback,
      onTap: () => _openVerse(context, verse),
      onCopy: () => ContentActionService.copy(context, text: shareText),
      onShare: () => ContentActionService.share(
        context,
        text: shareText,
        subject: verse.reference,
      ),
    );
  }

  void _openVerse(BuildContext context, VerseOfTheDay verse) {
    context.pushNamed(
      RouteNames.bibleVerseDetail,
      // [VerseOfTheDay.book] is always the canonical KJV name even in Nepali
      // mode, so the reader deep link resolves in both languages.
      pathParameters: {
        'book': verse.book,
        'chapter': verse.chapter.toString(),
        'verse': verse.verse.toString(),
      },
    );
  }
}
