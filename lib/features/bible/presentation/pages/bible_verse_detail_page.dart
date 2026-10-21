import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glean_faith_app/core/common/extensions/context_extensions.dart';
import 'package:glean_faith_app/core/router/route_names.dart';
import 'package:glean_faith_app/core/services/database_service.dart';
import 'package:glean_faith_app/features/bible_study/presentation/providers/bible_study_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/entities/verse.dart';
import '../providers/bible_providers.dart';

class BibleVerseDetailPage extends ConsumerStatefulWidget {
  final String book;
  final int chapter;
  final int verse;

  const BibleVerseDetailPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  @override
  ConsumerState<BibleVerseDetailPage> createState() => _BibleVerseDetailPageState();
}

class _BibleVerseDetailPageState extends ConsumerState<BibleVerseDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBookmark();
      unawaited(
        ref.read(recentReadingProvider.notifier).savePosition(
              bookName: widget.book,
              chapter: widget.chapter,
              verse: widget.verse,
            ),
      );
    });
  }

  void _initBookmark() {
    final arg = (book: widget.book, chapter: widget.chapter);
    if (ref.read(chapterBookmarksProvider(arg)).status ==
        BibleStudyStatus.initial) {
      ref.read(chapterBookmarksProvider(arg).notifier).load();
    }
  }

  Future<void> _toggleBookmark(({String book, int chapter}) arg) async {
    final notifier = ref.read(chapterBookmarksProvider(arg).notifier);
    await notifier.toggle(verse: widget.verse);
    if (!mounted) return;
    final nowBookmarked = ref
        .read(chapterBookmarksProvider(arg))
        .isBookmarked(widget.verse);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowBookmarked ? 'Verse bookmarked' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// The verses around the target one, two before and two after.
  ///
  /// Derived from the loaded chapter rather than queried separately, so the
  /// context is in the same language as the verse itself.
  List<Verse> _contextVerses(BibleChapter chapter) {
    final target = widget.verse;
    return chapter.verses
        .where((verse) => verse.verse >= target - 2 && verse.verse <= target + 2)
        .toList();
  }

  Verse? _targetVerse(BibleChapter chapter) {
    for (final verse in chapter.verses) {
      if (verse.verse == widget.verse) return verse;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arg = (book: widget.book, chapter: widget.chapter);
    final bookmarkState = ref.watch(chapterBookmarksProvider(arg));
    final isVerseBookmarked = bookmarkState.isBookmarked(widget.verse);

    // The chapter is loaded through the shared provider, so the verse follows
    // the global content language: a Nepali reader gets the Nepali text and
    // the Nepali reference, an English one the bundled KJV.
    final chapterAsync = ref.watch(
      bibleChapterProvider((book: widget.book, chapter: widget.chapter)),
    );
    final chapter = chapterAsync.value;
    final target = chapter == null ? null : _targetVerse(chapter);

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          chapter?.title ??
              '${normalizeBookName(widget.book)} ${widget.chapter}:${widget.verse}',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: target != null
                ? () {
                    // TODO: Implement copy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  }
                : null,
          ),
          IconButton(
            tooltip: isVerseBookmarked ? 'Remove book mark' : 'Bookmark verse',
            icon: Icon(
              isVerseBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isVerseBookmarked ? AppColors.primaryAmber : null,
            ),
            onPressed: () => _toggleBookmark(arg),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: target != null
                ? () {
                    // TODO: Implement share
                  }
                : null,
          ),
        ],
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load this verse.\n\n$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    bibleChapterProvider(
                      (book: widget.book, chapter: widget.chapter),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final verse = _targetVerse(data);
          if (verse == null) {
            return const Center(child: Text('Verse not found'));
          }
          final contextVerses = _contextVerses(data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isFallback) ...[
                  const _TranslationFallbackNotice(),
                  const SizedBox(height: 12),
                ],

                // Context label
                Text(
                  'Context (${data.title})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Context verses
                ...contextVerses.map((item) {
                  final isTargetVerse = item.verse == widget.verse;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isTargetVerse
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isTargetVerse
                          ? Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.verse}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isTargetVerse
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isTargetVerse
                                  ? AppColors.primaryBlue
                                  : isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.text,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: isTargetVerse
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isTargetVerse
                                  ? AppColors.primaryBlue
                                  : isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Full verse text (highlighted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.15),
                        AppColors.primaryAmber.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${verse.book} ${verse.chapter}:${verse.verse}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.text,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          color: isDark ? Colors.grey[200] : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Related topics (if available)
                _buildRelatedTopics(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRelatedTopics() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getTopicsByBook(widget.book),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final topics = snapshot.data!.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Topics in ${normalizeBookName(widget.book)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.map((topic) {
                return ActionChip(
                  label: Text(topic['topic_name'] as String),
                  onPressed: () {
                    // Navigate to topic detail
                    context.pushNamed(
                      RouteNames.bibleTopicDetail,
                      pathParameters: {
                        'topic': Uri.encodeComponent(topic['topic_name'] as String),
                      },
                    );
                  },
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Says out loud that the selected language was unavailable for this chapter
/// and the English text was served instead.
class _TranslationFallbackNotice extends StatelessWidget {
  const _TranslationFallbackNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryAmber.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.translate_rounded,
            size: 16,
            color: AppColors.primaryAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nepali translation unavailable. Showing English.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
