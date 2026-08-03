import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
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
  bool _isSearchingByTopic = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      ref.read(bibleSearchProvider.notifier).clearSearch();
      return;
    }

    if (_isSearchingByTopic) {
      ref.read(bibleSearchProvider.notifier).searchTopics(query);
    } else {
      ref.read(bibleSearchProvider.notifier).searchBibleText(query);
    }
  }

  void _onTopicSelected(String topicName) {
    context.pushNamed(
      RouteNames.bibleTopicDetail,
      pathParameters: {'topic': Uri.encodeComponent(topicName)},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bibleSearchProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Bible Search'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchingByTopic ? Icons.search : Icons.topic,
              color: AppColors.primaryBlue,
            ),
            tooltip: _isSearchingByTopic ? 'Search Bible Text' : 'Search Topics',
            onPressed: () {
              setState(() {
                _isSearchingByTopic = !_isSearchingByTopic;
              });
              _searchController.clear();
              ref.read(bibleSearchProvider.notifier).clearSearch();
            },
          ),
        ],
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: _isSearchingByTopic 
                    ? 'Search topics (e.g., peace, love)' 
                    : 'Search Bible text...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
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
              onChanged: (value) {
                setState(() {});
                _performSearch(value);
              },
              onSubmitted: (value) => _performSearch(value),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchingByTopic ? Icons.topic : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSearchingByTopic = !_isSearchingByTopic;
                });
                _searchController.clear();
                ref.read(bibleSearchProvider.notifier).clearSearch();
                _searchFocusNode.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BibleSearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
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
                  ref.read(bibleSearchProvider.notifier).refreshPopularTopics();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show results for search
    if (state.currentQuery.isNotEmpty) {
      if (_isSearchingByTopic) {
        if (state.topics.isEmpty) {
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
                    'No topics found for "${state.currentQuery}"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Try a different word or search the Bible text',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSearchingByTopic = false;
                      });
                      _performSearch(state.currentQuery);
                    },
                    child: const Text('Search Bible Text Instead'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          itemCount: state.topics.length,
          itemBuilder: (context, index) {
            final topic = state.topics[index];
            return TopicCard(
              topic: topic,
              onTap: () => _onTopicSelected(topic.name),
            );
          },
        );
      } else {
        // Bible text search results
        if (state.searchResults.isEmpty) {
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
                    'No verses found for "${state.currentQuery}"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSearchingByTopic = true;
                      });
                      _performSearch(state.currentQuery);
                    },
                    child: const Text('Search Topics Instead'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          itemCount: state.searchResults.length,
          itemBuilder: (context, index) {
            final verse = state.searchResults[index];
            return VerseResultTile(
              verse: verse,
              onTap: () {
                // Navigate to verse detail with context
                context.pushNamed(
                  RouteNames.bibleVerseDetail,
                  pathParameters: {
                    'book': verse.book,
                    'chapter': verse.chapter.toString(),
                    'verse': verse.verse.toString(),
                  },
                );
              },
            );
          },
        );
      }
    }

    // Show popular topics (no search query)
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
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              labelStyle: const TextStyle(color: AppColors.primaryBlue),
            );
          }).toList(),
        ),
      ],
    );
  }
}