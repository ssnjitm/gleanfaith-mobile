import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_progress_entities.dart';
import '../repositories/course_repository.dart';

class CompleteCourseItemUseCase {
  final CourseRepository _repository;

  CompleteCourseItemUseCase(this._repository);

  TaskEither<Failure, CompleteCourseItemResult> call(
    String courseId,
    String itemId, {
    double? score,
    double? maxScore,
  }) {
    return _repository.completeItem(
      courseId,
      itemId,
      score: score,
      maxScore: maxScore,
    );
  }
}
