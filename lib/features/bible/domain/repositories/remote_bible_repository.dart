import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/remote_bible_chapter.dart';
import '../entities/remote_bible_verse.dart';

/// Read-only access to the free remote Bible translations.
abstract class RemoteBibleRepository {
  /// Resolves one verse by USFM book id, e.g. `('JHN', 3, 16)`, from
  /// [translationId].
  TaskEither<Failure, RemoteBibleVerse> getVerse({
    required String translationId,
    required String usfmBook,
    required int chapter,
    required int verse,
  });

  /// Resolves a whole chapter by USFM book id, e.g. `('JHN', 3)`, from
  /// [translationId].
  ///
  /// The Bible reader uses this to render a chapter in a language the bundled
  /// offline database does not carry.
  TaskEither<Failure, RemoteBibleChapter> getChapter({
    required String translationId,
    required String usfmBook,
    required int chapter,
  });

  /// Resolves the name of every book of [translationId], keyed by USFM id.
  ///
  /// The names come back in the translation's own script, which is what the
  /// reader's book list needs to show a localized book grid.
  TaskEither<Failure, Map<String, String>> getBookNames({
    required String translationId,
  });
}
