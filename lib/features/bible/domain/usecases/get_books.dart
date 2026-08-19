import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/bible_book.dart';
import '../repositories/bible_repository.dart';

class GetBooksUseCase {
  final BibleRepository _repository;

  GetBooksUseCase(this._repository);

  TaskEither<Failure, List<BibleBook>> call() {
    return _repository.getBooks();
  }
}