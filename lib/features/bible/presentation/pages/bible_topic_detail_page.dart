import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glean_faith_app/core/router/route_names.dart';
import 'package:glean_faith_app/core/services/content_action_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../providers/bible_search_provider.dart';
import '../widgets/verse_card.dart';

class BibleTopicDetailPage extends ConsumerStatefulWidget {
  final String topicName;

  const BibleTopicDetailPage({
    super.key,
    required this.topicName,
  });

  @override
  ConsumerState<BibleTopicDetailPage> createState() => _BibleTopicDetailPageState();
}

class _BibleTopicDetailPageState extends ConsumerState<BibleTopicDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bibleSearchProvider.notifier).getTopicVerses(widget.topicName);
    });
  }

  @override
  void dispose() {
    ref.read(bibleSearchProvider.notifier).clearTopicVerses();
    super.dispose();
  }

  void _onVerseTap(String book, int chapter, int verse) {
    context.pushNamed(
      RouteNames.bibleVerseDetail,
      pathParameters: {
        'book': book,
        'chapter': chapter.toString(),
        'verse': verse.toString(),
      },
    );
  }

  String _shareText(String topicName) {
    final verses = ref.read(bibleSearchProvider).topicVerses;
    final buffer = StringBuffer('Verses about $topicName');
    for (final verse in verses) {
      buffer
        ..write('\n\n')
        ..write(
          formatVerseForSharing(
            text: verse.verseText,
            reference: '${verse.book} ${verse.chapter}:${verse.verse}',
          ),
        );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bibleSearchProvider);
    final topicName = widget.topicName;

    return AppScaffold(
      appBar: AppBar(
        title: Text(topicName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Share topic',
            icon: const Icon(Icons.share),
            onPressed: () => ContentActionService.share(
              context,
              text: _shareText(topicName),
              subject: 'Verses about $topicName',
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(bibleSearchProvider.notifier)
                                .getTopicVerses(topicName);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.topicVerses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            'No verses found for "$topicName"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      itemCount: state.topicVerses.length,
                      itemBuilder: (context, index) {
                        final topicVerse = state.topicVerses[index];
                        return VerseCard(
                          topicVerse: topicVerse,
                          onTap: () => _onVerseTap(
                            topicVerse.book,
                            topicVerse.chapter,
                            topicVerse.verse,
                          ),
                        );
                      },
                    ),
    );
  }
}