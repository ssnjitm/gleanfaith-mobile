import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
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
}
