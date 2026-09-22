import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/alert_widget.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/common/widgets/shimmer_placeholders.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../features/bible_study/presentation/providers/bible_study_provider.dart';
import '../../domain/entities/verse.dart';
import '../providers/bible_providers.dart';

class BibleReadingPage extends ConsumerStatefulWidget {
  final String book;
  final int chapter;

  const BibleReadingPage({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  ConsumerState<BibleReadingPage> createState() => _BibleReadingPageState();
}

class _BibleReadingPageState extends ConsumerState<BibleReadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arg = (book: widget.book, chapter: widget.chapter);
      if (ref.read(chapterBookmarksProvider(arg)).status ==
          BibleStudyStatus.initial) {
        ref.read(chapterBookmarksProvider(arg).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(
      bibleChapterVersesProvider((book: widget.book, chapter: widget.chapter)),
    );
    final chaptersAsync = ref.watch(bibleChaptersProvider(widget.book));
    final arg = (book: widget.book, chapter: widget.chapter);
    final bookmarksState = ref.watch(chapterBookmarksProvider(arg));
    final isBookmarked = bookmarksState.isBookmarked(null);

    return AppScaffold(
      appBar: AppBar(
        title: Text('${normalizeBookName(widget.book)} ${widget.chapter}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isBookmarked ? 'Remove book mark' : 'Bookmark chapter',
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.primaryAmber : null,
            ),
            onPressed: () => _toggleChapterBookmark(arg),
          ),
          IconButton(
            tooltip: 'Chapter notes',
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: () => context.pushNamed(
              RouteNames.bibleChapterNotes,
              pathParameters: {
                'book': widget.book,
                'chapter': widget.chapter.toString(),
              },
            ),
          ),
        ],
      ),
      body: versesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDimensions.md),
          child: VerseListShimmer(),
        ),
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
          book: widget.book,
          chapter: widget.chapter,
          verses: verses,
          chapters: chaptersAsync.value ?? const [],
        ),
      ),
    );
  }

  Future<void> _toggleChapterBookmark(({String book, int chapter}) arg) async {
    final notifier = ref.read(chapterBookmarksProvider(arg).notifier);
    await notifier.toggle(verse: null);
    if (!mounted) return;
    final nowBookmarked = ref.read(chapterBookmarksProvider(arg)).isBookmarked(null);
    AlertWidget.showSnackBar(
      context,
      message: nowBookmarked ? 'Chapter bookmarked' : 'Bookmark removed',
      type: nowBookmarked ? AlertType.success : AlertType.info,
    );
  }
}

class _ChapterBody extends ConsumerStatefulWidget {
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
  ConsumerState<_ChapterBody> createState() => _ChapterBodyState();
}

class _ChapterBodyState extends ConsumerState<_ChapterBody> {
  final ScrollController _scrollController = ScrollController();
  Timer? _saveDebounce;
  bool _didInitPosition = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitPosition && widget.verses.isNotEmpty) {
      _didInitPosition = true;
      unawaited(
        ref.read(recentReadingProvider.notifier).savePosition(
              bookName: widget.book,
              chapter: widget.chapter,
              verse: widget.verses.first.verse,
            ),
      );
    }
  }

  void _onScroll() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 500),
      _saveEstimatedPosition,
    );
  }

  void _saveEstimatedPosition() {
    if (!mounted || widget.verses.isEmpty) return;
    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;
    var verse = widget.verses.first.verse;
    if (maxExtent > 0) {
      final ratio = (offset / maxExtent).clamp(0.0, 1.0);
      final index = (ratio * (widget.verses.length - 1)).round();
      verse = widget.verses[index].verse;
    }
    unawaited(
      ref.read(recentReadingProvider.notifier).savePosition(
            bookName: widget.book,
            chapter: widget.chapter,
            verse: verse,
          ),
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty) {
      return const Center(child: Text('No verses found for this chapter'));
    }

    final currentIndex = widget.chapters.indexOf(widget.chapter);
    final hasPrev = currentIndex > 0;
    final hasNext =
        currentIndex >= 0 && currentIndex < widget.chapters.length - 1;
    final prevChapter =
        hasPrev ? widget.chapters[currentIndex - 1] : widget.chapter;
    final nextChapter =
        hasNext ? widget.chapters[currentIndex + 1] : widget.chapter;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: widget.verses.length,
            itemBuilder: (context, index) {
              final verse = widget.verses[index];
              return _VerseLine(
                verse: verse,
                onTap: () => context.pushNamed(
                  RouteNames.bibleVerseDetail,
                  pathParameters: {
                    'book': verse.book,
                    'chapter': verse.chapter.toString(),
                    'verse': verse.verse.toString(),
                  },
                ),
              );
            },
          ),
        ),
        _ChapterNavigationBar(
          book: widget.book,
          chapter: widget.chapter,
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
                        'book': book,
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
                        'book': book,
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