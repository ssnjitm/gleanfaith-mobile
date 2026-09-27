import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class GetQuizSeriesUseCase {
  final QuizRepository _repository;

  GetQuizSeriesUseCase(this._repository);

  TaskEither<Failure, List<QuizSeries>> call() => _repository.getSeries();
}
