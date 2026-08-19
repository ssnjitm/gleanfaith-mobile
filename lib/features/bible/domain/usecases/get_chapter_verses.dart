import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class GetChapterVersesUseCase {
  final BibleRepository _repository;

  GetChapterVersesUseCase(this._repository);

  TaskEither<Failure, List<Verse>> call({
    required String book,
    required int chapter,
  }) {
    return _repository.getChapterVerses(book: book, chapter: chapter);
  }
}