import 'package:equatable/equatable.dart';

/// A book of the Bible with enough metadata to render the reader navigation.
class BibleBook extends Equatable {
  final String name;
  final int chapterCount;

  /// Either `'Old Testament'` or `'New Testament'`.
  final String testament;

  const BibleBook({
    required this.name,
    required this.chapterCount,
    required this.testament,
  });

  bool get isOldTestament => testament == 'Old Testament';

  @override
  List<Object?> get props => [name, chapterCount, testament];
}
