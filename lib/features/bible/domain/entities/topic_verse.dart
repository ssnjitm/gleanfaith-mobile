import 'package:equatable/equatable.dart';
import 'verse.dart';

class TopicVerse extends Equatable {
  final String topicName;
  final String verseReference;
  final String verseText;
  final String book;
  final int chapter;
  final int verse;
  final int votes;

  const TopicVerse({
    required this.topicName,
    required this.verseReference,
    required this.verseText,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.votes,
  });

  Verse toVerse() => Verse(
        book: book,
        chapter: chapter,
        verse: verse,
        text: verseText,
        reference: verseReference,
        votes: votes,
      );

  @override
  List<Object?> get props => [topicName, verseReference, verseText];
}