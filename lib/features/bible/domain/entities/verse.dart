import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? reference;
  final int? votes;

  const Verse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.reference,
    this.votes,
  });

  String get formattedReference => '$book $chapter:$verse';
  String get shortText => text.length > 100 ? '${text.substring(0, 100)}...' : text;

  @override
  List<Object?> get props => [book, chapter, verse, text];
}