import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../../features/bible/presentation/providers/bible_providers.dart';
import 'verse_of_the_day_card.dart';

class HomeVerseOfTheDay extends ConsumerWidget {
  const HomeVerseOfTheDay({super.key});

  static const String _fallbackText =
      'For I know the plans I have for you, declares the Lord, plans to '
      'prosper you and not to harm you, plans to give you hope and a future.';
  static const String _fallbackReference = 'Jeremiah 29:11';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVerse = ref.watch(verseOfTheDayProvider);

    return asyncVerse.when(
      loading: () => const VerseOfTheDayCard(
        text: '',
        reference: '',
        isLoading: true,
      ),
      error: (_, _) => VerseOfTheDayCard(
        text: _fallbackText,
        reference: _fallbackReference,
        onTap: () => _openVerse(context, 'Jeremiah', 29, 11),
      ),
      data: (verse) => VerseOfTheDayCard(
        text: verse.text,
        reference: verse.formattedReference,
        onTap: () => _openVerse(
          context,
          verse.book,
          verse.chapter,
          verse.verse,
        ),
      ),
    );
  }

  void _openVerse(
    BuildContext context,
    String book,
    int chapter,
    int verse,
  ) {
    context.pushNamed(
      RouteNames.bibleVerseDetail,
      pathParameters: {
        'book': book,
        'chapter': chapter.toString(),
        'verse': verse.toString(),
      },
    );
  }
}
