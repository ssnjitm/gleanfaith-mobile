import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/bible_repository.dart';

class GetChaptersUseCase {
  final BibleRepository _repository;

  GetChaptersUseCase(this._repository);

  TaskEither<Failure, List<int>> call(String book) {
    return _repository.getChapters(book);
  }
}