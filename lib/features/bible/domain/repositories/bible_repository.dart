import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/topic.dart';
import '../entities/verse.dart';
import '../entities/topic_verse.dart';
import '../entities/bible_book.dart';

abstract class BibleRepository {
  TaskEither<Failure, List<Topic>> searchTopics(String query);
  TaskEither<Failure, List<TopicVerse>> getTopicVerses(String topicName, {int limit});
  TaskEither<Failure, List<Verse>> searchBibleText(String query);
  TaskEither<Failure, List<Verse>> searchByReference(String query);
  TaskEither<Failure, Verse?> getVerseOfTheDay({DateTime? date});
  TaskEither<Failure, List<Topic>> getPopularTopics({int limit});
  TaskEither<Failure, List<Topic>> getTopicsByBook(String book);
  TaskEither<Failure, List<Verse>> getVerseContext({
    required String book,
    required int chapter,
    required int verse,
    int contextRange,
  });
  TaskEither<Failure, List<BibleBook>> getBooks();
  TaskEither<Failure, List<int>> getChapters(String book);
  TaskEither<Failure, List<Verse>> getChapterVerses({
    required String book,
    required int chapter,
  });
}