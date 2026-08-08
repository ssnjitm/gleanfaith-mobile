import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../data/repositories/bible_repository_impl.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/usecases/search_topics.dart';
import '../../domain/usecases/get_topic_verses.dart';
import '../../domain/usecases/search_bible_text.dart';
import '../../domain/usecases/search_by_reference.dart';
import '../../domain/usecases/get_verse_of_the_day.dart';
import '../../domain/usecases/get_popular_topics.dart';
import '../../domain/usecases/get_topics_by_book.dart';
import '../../domain/entities/verse.dart';

// Repository Provider
final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepositoryImpl(DatabaseService.instance);
});

// Use Case Providers
final searchTopicsUseCaseProvider = Provider<SearchTopicsUseCase>((ref) {
  return SearchTopicsUseCase(ref.watch(bibleRepositoryProvider));
});

final getTopicVersesUseCaseProvider = Provider<GetTopicVersesUseCase>((ref) {
  return GetTopicVersesUseCase(ref.watch(bibleRepositoryProvider));
});

final searchBibleTextUseCaseProvider = Provider<SearchBibleTextUseCase>((ref) {
  return SearchBibleTextUseCase(ref.watch(bibleRepositoryProvider));
});

final searchByReferenceUseCaseProvider = Provider<SearchByReferenceUseCase>((ref) {
  return SearchByReferenceUseCase(ref.watch(bibleRepositoryProvider));
});

final getVerseOfTheDayUseCaseProvider = Provider<GetVerseOfTheDayUseCase>((ref) {
  return GetVerseOfTheDayUseCase(ref.watch(bibleRepositoryProvider));
});

final getPopularTopicsUseCaseProvider = Provider<GetPopularTopicsUseCase>((ref) {
  return GetPopularTopicsUseCase(ref.watch(bibleRepositoryProvider));
});

final getTopicsByBookUseCaseProvider = Provider<GetTopicsByBookUseCase>((ref) {
  return GetTopicsByBookUseCase(ref.watch(bibleRepositoryProvider));
});

/// Verse of the day loaded from the Bible database.
final verseOfTheDayProvider = FutureProvider<Verse>((ref) async {
  final result = await ref.watch(getVerseOfTheDayUseCaseProvider).call().run();
  return result.fold(
    (failure) => throw failure,
    (verse) {
      if (verse == null) {
        throw StateError('Bible database is unavailable');
      }
      return verse;
    },
  );
});