import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../domain/entities/verse.dart';
import '../providers/bible_search_provider.dart';
import '../widgets/topic_card.dart';
import '../widgets/verse_result_tile.dart';
import '../widgets/popular_topics_grid.dart';

class BibleSearchPage extends ConsumerStatefulWidget {
  const BibleSearchPage({super.key});

  @override
  ConsumerState<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends ConsumerState<BibleSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _performSearch(value),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      ref.read(bibleSearchProvider.notifier).clearSearch();
      return;
    }
    ref.read(bibleSearchProvider.notifier).searchAll(query);
  }

  void _onTopicSelected(String topicName) {
    context.pushNamed(
      RouteNames.bibleTopicDetail,
      pathParameters: {'topic': Uri.encodeComponent(topicName)},
    );
  }

  void _onVerseTap(Verse verse) {
    context.pushNamed(
      RouteNames.bibleVerseDetail,
      pathParameters: {
        'book': verse.book,
        'chapter': verse.chapter.toString(),
        'verse': verse.verse.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bibleSearchProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Bible Search'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search Bible, topics or reference (e.g. John 3:16)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _debounce?.cancel();
                    _searchController.clear();
                    ref.read(bibleSearchProvider.notifier).clearSearch();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[50],
        ),
        onChanged: _onQueryChanged,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildContent(BibleSearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentQuery.isNotEmpty) {
      final hasResults =
          state.searchResults.isNotEmpty || state.topics.isNotEmpty;
      if (hasResults) {
        return _buildSearchResults(state);
      }
      if (state.errorMessage != null) {
        return _buildErrorState(state);
      }
      return _buildEmptyState(state);
    }

    return _buildBrowseContent(state);
  }

  Widget _buildErrorState(BibleSearchState state) {
    return Center(
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
              onPressed: () => _performSearch(state.currentQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BibleSearchState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
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
              'No results found for "${state.currentQuery}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Try a different word, or a reference like "John 3:16" or "Psalm 23".',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BibleSearchState state) {
    final hasVerses = state.searchResults.isNotEmpty;
    final hasTopics = state.topics.isNotEmpty;

    final children = <Widget>[];

    if (hasVerses) {
      children.add(
        _SectionHeader(
          title: 'Verses',
          count: state.searchResults.length,
        ),
      );
      for (final verse in state.searchResults) {
        children.add(
          VerseResultTile(
            verse: verse,
            query: state.currentQuery,
            onTap: () => _onVerseTap(verse),
          ),
        );
      }
      if (hasTopics) {
        children.add(const SizedBox(height: AppDimensions.lg));
      }
    }

    if (hasTopics) {
      children.add(
        _SectionHeader(
          title: 'Topics',
          count: state.topics.length,
        ),
      );
      for (final topic in state.topics) {
        children.add(
          TopicCard(
            topic: topic,
            onTap: () => _onTopicSelected(topic.name),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      children: children,
    );
  }

  Widget _buildBrowseContent(BibleSearchState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Topics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(bibleSearchProvider.notifier).refreshPopularTopics();
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          if (state.popularTopics.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.lg),
                child: Text('No popular topics available'),
              ),
            )
          else
            PopularTopicsGrid(
              topics: state.popularTopics,
              onTopicTap: _onTopicSelected,
            ),
          const SizedBox(height: AppDimensions.lg),
          _buildQuickSearchSection(),
        ],
      ),
    );
  }

  Widget _buildQuickSearchSection() {
    final quickTopics = [
      'love',
      'peace',
      'faith',
      'hope',
      'grace',
      'forgiveness',
      'prayer',
      'wisdom',
      'John 3:16',
      'Psalm 23',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Search',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickTopics.map((topic) {
            return ActionChip(
              label: Text(topic),
              onPressed: () {
                _searchController.text = topic;
                setState(() {});
                _performSearch(topic);
              },
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: AppColors.primaryBlue),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.sm, bottom: AppDimensions.sm),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
