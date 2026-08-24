import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/course_repository.dart';

class ResetCourseProgressUseCase {
  final CourseRepository _repository;

  ResetCourseProgressUseCase(this._repository);

  TaskEither<Failure, void> call(String courseId) {
    return _repository.resetProgress(courseId);
  }
}
