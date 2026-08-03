import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glean_faith_app/features/bible/domain/usecases/get_popular_topics.dart';
import 'package:glean_faith_app/features/bible/domain/usecases/get_topic_verses.dart';
import 'package:glean_faith_app/features/bible/domain/usecases/search_bible_text.dart';
import 'package:glean_faith_app/features/bible/domain/usecases/search_topics.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/topic_verse.dart';
import '../../domain/entities/verse.dart';
import 'bible_providers.dart';

// State definition
class BibleSearchState {
  final bool isLoading;
  final List<Topic> topics;
  final List<TopicVerse> topicVerses;
  final List<Verse> searchResults;
  final List<Topic> popularTopics;
  final String? errorMessage;
  final String currentQuery;
  final bool hasMoreResults;

  const BibleSearchState({
    this.isLoading = false,
    this.topics = const [],
    this.topicVerses = const [],
    this.searchResults = const [],
    this.popularTopics = const [],
    this.errorMessage,
    this.currentQuery = '',
    this.hasMoreResults = false,
  });

  BibleSearchState copyWith({
    bool? isLoading,
    List<Topic>? topics,
    List<TopicVerse>? topicVerses,
    List<Verse>? searchResults,
    List<Topic>? popularTopics,
    String? errorMessage,
    String? currentQuery,
    bool? hasMoreResults,
  }) {
    return BibleSearchState(
      isLoading: isLoading ?? this.isLoading,
      topics: topics ?? this.topics,
      topicVerses: topicVerses ?? this.topicVerses,
      searchResults: searchResults ?? this.searchResults,
      popularTopics: popularTopics ?? this.popularTopics,
      errorMessage: errorMessage ?? this.errorMessage,
      currentQuery: currentQuery ?? this.currentQuery,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
    );
  }
}

// Search Notifier
class BibleSearchNotifier extends StateNotifier<BibleSearchState> {
  final SearchTopicsUseCase _searchTopicsUseCase;
  final GetTopicVersesUseCase _getTopicVersesUseCase;
  final SearchBibleTextUseCase _searchBibleTextUseCase;
  final GetPopularTopicsUseCase _getPopularTopicsUseCase;

  BibleSearchNotifier(
    this._searchTopicsUseCase,
    this._getTopicVersesUseCase,
    this._searchBibleTextUseCase,
    this._getPopularTopicsUseCase,
  ) : super(const BibleSearchState()) {
    _loadPopularTopics();
  }

  Future<void> _loadPopularTopics() async {
    final result = await _getPopularTopicsUseCase.call(limit: 20).run();
    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure.message,
        popularTopics: const [],
      ),
      (topics) => state = state.copyWith(
        popularTopics: topics,
        errorMessage: null,
      ),
    );
  }

  Future<void> searchTopics(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        topics: const [],
        currentQuery: '',
        searchResults: const [],
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      currentQuery: query,
      errorMessage: null,
    );

    final result = await _searchTopicsUseCase.call(query.trim()).run();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        topics: const [],
      ),
      (topics) => state = state.copyWith(
        isLoading: false,
        topics: topics,
        errorMessage: null,
        searchResults: const [],
      ),
    );
  }

  Future<void> getTopicVerses(String topicName) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    final result = await _getTopicVersesUseCase.call(topicName).run();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        topicVerses: const [],
      ),
      (verses) => state = state.copyWith(
        isLoading: false,
        topicVerses: verses,
        errorMessage: null,
      ),
    );
  }

  Future<void> searchBibleText(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const []);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      currentQuery: query,
      errorMessage: null,
    );

    final result = await _searchBibleTextUseCase.call(query.trim()).run();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        searchResults: const [],
      ),
      (results) => state = state.copyWith(
        isLoading: false,
        searchResults: results,
        errorMessage: null,
        topics: const [],
      ),
    );
  }

  void clearSearch() {
    state = state.copyWith(
      topics: const [],
      searchResults: const [],
      currentQuery: '',
      errorMessage: null,
    );
  }

  void clearTopicVerses() {
    state = state.copyWith(
      topicVerses: const [],
    );
  }

  void refreshPopularTopics() {
    _loadPopularTopics();
  }
}

// Provider
final bibleSearchProvider = StateNotifierProvider<BibleSearchNotifier, BibleSearchState>((ref) {
  return BibleSearchNotifier(
    ref.watch(searchTopicsUseCaseProvider),
    ref.watch(getTopicVersesUseCaseProvider),
    ref.watch(searchBibleTextUseCaseProvider),
    ref.watch(getPopularTopicsUseCaseProvider),
  );
});