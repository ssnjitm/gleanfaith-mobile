import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/quiz_entities.dart';
import '../repositories/quiz_repository.dart';

class GetQuizHistoryUseCase {
  final QuizRepository _repository;

  GetQuizHistoryUseCase(this._repository);

  TaskEither<Failure, List<QuizAttempt>> call() => _repository.getQuizHistory();
}
