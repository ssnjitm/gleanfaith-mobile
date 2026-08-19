import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class GetVerseOfTheDayUseCase {
  final BibleRepository _repository;

  GetVerseOfTheDayUseCase(this._repository);

  TaskEither<Failure, Verse?> call({DateTime? date}) {
    return _repository.getVerseOfTheDay(date: date);
  }
}
