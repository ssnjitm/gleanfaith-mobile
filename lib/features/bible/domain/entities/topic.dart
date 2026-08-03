import 'package:equatable/equatable.dart';

class Topic extends Equatable {
  final int id;
  final String name;
  final int verseCount;

  const Topic({
    required this.id,
    required this.name,
    this.verseCount = 0,
  });

  @override
  List<Object?> get props => [id, name, verseCount];
}