import 'package:equatable/equatable.dart';

/// A single verse fetched from the free Free Use Bible endpoint.
class RemoteBibleVerse extends Equatable {
  /// Which translation the text came from, e.g. `npi_ulb` or `eng_web`.
  final String translationId;

  /// USFM 3-letter book id, e.g. `JHN` — the addressable identifier.
  final String usfmBook;

  /// Book name in the translation's own script, e.g. `यूहन्‍ना`.
  final String bookName;

  final int chapter;
  final int verse;
  final String text;

  const RemoteBibleVerse({
    required this.translationId,
    required this.usfmBook,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  /// Localised reference, e.g. `यूहन्‍ना 3:16`.
  String get reference => '$bookName $chapter:$verse';

  @override
  List<Object?> get props => [
    translationId,
    usfmBook,
    bookName,
    chapter,
    verse,
    text,
  ];
}
