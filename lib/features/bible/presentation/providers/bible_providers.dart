import 'dart:async';

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
import '../../domain/usecases/get_books.dart';
import '../../domain/usecases/get_chapters.dart';
import '../../domain/usecases/get_chapter_verses.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/bible_book.dart';

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

final getBooksUseCaseProvider = Provider<GetBooksUseCase>((ref) {
  return GetBooksUseCase(ref.watch(bibleRepositoryProvider));
});

final getChaptersUseCaseProvider = Provider<GetChaptersUseCase>((ref) {
  return GetChaptersUseCase(ref.watch(bibleRepositoryProvider));
});

final getChapterVersesUseCaseProvider = Provider<GetChapterVersesUseCase>((ref) {
  return GetChapterVersesUseCase(ref.watch(bibleRepositoryProvider));
});

/// Emits the current date and self-invalidates at the next local midnight,
/// causing any provider that watches it to recompute automatically the next day.
final currentDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(tomorrow.difference(now), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return now;
});

/// Verse of the day loaded from the Bible database.
final verseOfTheDayProvider = FutureProvider<Verse>((ref) async {
  ref.watch(currentDateProvider);
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

/// All 66 books of the Bible in canonical order for the reader.
final bibleBooksProvider = FutureProvider<List<BibleBook>>((ref) async {
  final result = await ref.watch(getBooksUseCaseProvider).call().run();
  return result.fold(
    (failure) => throw failure,
    (books) => books,
  );
});

/// Chapter numbers available in a book.
final bibleChaptersProvider = FutureProvider.family<List<int>, String>(
  (ref, book) async {
    final result = await ref.watch(getChaptersUseCaseProvider).call(book).run();
    return result.fold(
      (failure) => throw failure,
      (chapters) => chapters,
    );
  },
);

/// All verses of a full chapter.
final bibleChapterVersesProvider =
    FutureProvider.family<List<Verse>, ({String book, int chapter})>(
  (ref, args) async {
    final result = await ref
        .watch(getChapterVersesUseCaseProvider)
        .call(book: args.book, chapter: args.chapter)
        .run();
    return result.fold(
      (failure) => throw failure,
      (verses) => verses,
    );
  },
);