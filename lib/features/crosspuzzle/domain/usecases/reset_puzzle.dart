import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/crosspuzzle_repository.dart';

class ResetPuzzleUseCase {
  final CrossPuzzleRepository _repository;
  ResetPuzzleUseCase(this._repository);

  TaskEither<Failure, String> call(String puzzleId) {
    return _repository.resetPuzzle(puzzleId);
  }
}