import 'package:fpdart/fpdart.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/topic_verse.dart';
import '../../domain/repositories/bible_repository.dart';

class BibleRepositoryImpl implements BibleRepository {
  final DatabaseService _databaseService;

  BibleRepositoryImpl(this._databaseService);

  @override
  TaskEither<Failure, List<Topic>> searchTopics(String query) {
    return TaskEither.tryCatch(
      () async {
        if (query.length < 2) return <Topic>[];
        final results = await _databaseService.searchTopics(query);
        return results.map((row) => Topic(
          id: row['id'] as int,
          name: row['topic_name'] as String,
          verseCount: row['verse_count'] as int? ?? 0,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<TopicVerse>> getTopicVerses(String topicName, {int limit = 50}) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.getTopicVerses(topicName, limit: limit);
        return results.map((row) => TopicVerse(
          topicName: row['topic_name'] as String,
          verseReference: row['verse_reference'] as String,
          verseText: row['verse_text'] as String,
          book: row['book'] as String,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          votes: row['votes'] as int? ?? 0,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Verse>> searchBibleText(String query) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.searchBibleText(query);
        return results.map((row) => Verse(
          book: row['book'] as String,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          text: row['text'] as String,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Verse>> searchByReference(String query) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.searchByReference(query);
        return results.map((row) => Verse(
          book: row['book'] as String,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          text: row['text'] as String,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, Verse?> getVerseOfTheDay() {
    return TaskEither.tryCatch(
      () async {
        final row = await _databaseService.getVerseOfTheDay();
        if (row == null) return null;
        return Verse(
          book: row['book'] as String,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          text: row['text'] as String,
        );
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Topic>> getPopularTopics({int limit = 20}) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.getPopularTopics(limit: limit);
        return results.map((row) => Topic(
          id: 0,
          name: row['topic_name'] as String,
          verseCount: row['verse_count'] as int? ?? 0,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Topic>> getTopicsByBook(String book) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.getTopicsByBook(book);
        return results.map((row) => Topic(
          id: 0,
          name: row['topic_name'] as String,
          verseCount: row['verse_count'] as int? ?? 0,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, List<Verse>> getVerseContext({
    required String book,
    required int chapter,
    required int verse,
    int contextRange = 2,
  }) {
    return TaskEither.tryCatch(
      () async {
        final results = await _databaseService.getVerseContext(
          book: book,
          chapter: chapter,
          verse: verse,
          contextRange: contextRange,
        );
        return results.map((row) => Verse(
          book: row['book'] as String,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          text: row['text'] as String,
        )).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }
}