import 'package:equatable/equatable.dart';

import 'remote_bible_verse.dart';

/// A whole chapter fetched from the free Free Use Bible endpoint.
///
/// The endpoint is chapter-grained, so one request yields every verse of a
/// chapter. That is exactly what the Bible reader needs: the Nepali
/// translation is not bundled in the offline SQLite database (which ships the
/// English KJV), so a Nepali chapter has to come from the network.
class RemoteBibleChapter extends Equatable {
  /// Which translation the text came from, e.g. `npi_ulb` or `eng_web`.
  final String translationId;

  /// USFM 3-letter book id, e.g. `JHN` — the addressable identifier.
  final String usfmBook;

  /// Book name in the translation's own script, e.g. `यूहन्‍ना`.
  final String bookName;

  final int chapter;

  /// Every verse of the chapter, in order.
  final List<RemoteBibleVerse> verses;

  const RemoteBibleChapter({
    required this.translationId,
    required this.usfmBook,
    required this.bookName,
    required this.chapter,
    required this.verses,
  });

  @override
  List<Object?> get props => [
    translationId,
    usfmBook,
    bookName,
    chapter,
    verses,
  ];
}
