import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/entities/verse.dart';
import '../providers/bible_providers.dart';

class BibleReadingPage extends ConsumerWidget {
  final String book;
  final int chapter;

  const BibleReadingPage({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(
      bibleChapterVersesProvider((book: book, chapter: chapter)),
    );
    final chaptersAsync = ref.watch(bibleChaptersProvider(book));

    return AppScaffold(
      appBar: AppBar(
        title: Text('$book $chapter'),
        centerTitle: true,
      ),
      body: versesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Text(
              'Could not load this chapter.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (verses) => _ChapterBody(
          book: book,
          chapter: chapter,
          verses: verses,
          chapters: chaptersAsync.value ?? const [],
        ),
      ),
    );
  }
}

class _ChapterBody extends StatelessWidget {
  final String book;
  final int chapter;
  final List<Verse> verses;
  final List<int> chapters;

  const _ChapterBody({
    required this.book,
    required this.chapter,
    required this.verses,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const Center(child: Text('No verses found for this chapter'));
    }

    final currentIndex = chapters.indexOf(chapter);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < chapters.length - 1;
    final prevChapter = hasPrev ? chapters[currentIndex - 1] : chapter;
    final nextChapter = hasNext ? chapters[currentIndex + 1] : chapter;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return _VerseLine(
                verse: verse,
                onTap: () => context.pushNamed(
                  RouteNames.bibleVerseDetail,
                  pathParameters: {
                    'book': Uri.encodeComponent(verse.book),
                    'chapter': verse.chapter.toString(),
                    'verse': verse.verse.toString(),
                  },
                ),
              );
            },
          ),
        ),
        _ChapterNavigationBar(
          book: book,
          chapter: chapter,
          prevChapter: prevChapter,
          nextChapter: nextChapter,
          hasPrev: hasPrev,
          hasNext: hasNext,
        ),
      ],
    );
  }
}

class _VerseLine extends StatelessWidget {
  final Verse verse;
  final VoidCallback onTap;

  const _VerseLine({required this.verse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.xs,
          horizontal: AppDimensions.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${verse.verse}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : AppColors.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: Text(
                verse.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.grey[200] : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterNavigationBar extends StatelessWidget {
  final String book;
  final int chapter;
  final int prevChapter;
  final int nextChapter;
  final bool hasPrev;
  final bool hasNext;

  const _ChapterNavigationBar({
    required this.book,
    required this.chapter,
    required this.prevChapter,
    required this.nextChapter,
    required this.hasPrev,
    required this.hasNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.bgWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderLight,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev
                ? () => context.pushReplacementNamed(
                      RouteNames.bibleChapter,
                      pathParameters: {
                        'book': Uri.encodeComponent(book),
                        'chapter': prevChapter.toString(),
                      },
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
            label: Text('Ch. $prevChapter'),
          ),
          Text(
            'Chapter $chapter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : AppColors.textMuted,
            ),
          ),
          TextButton.icon(
            onPressed: hasNext
                ? () => context.pushReplacementNamed(
                      RouteNames.bibleChapter,
                      pathParameters: {
                        'book': Uri.encodeComponent(book),
                        'chapter': nextChapter.toString(),
                      },
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
            label: Text('Ch. $nextChapter'),
          ),
        ],
      ),
    );
  }
}