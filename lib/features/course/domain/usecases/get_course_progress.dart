import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_progress_entities.dart';
import '../repositories/course_repository.dart';

class GetCourseProgressUseCase {
  final CourseRepository _repository;

  GetCourseProgressUseCase(this._repository);

  TaskEither<Failure, CourseProgressSnapshot> call(String courseId) {
    return _repository.getCourseProgress(courseId);
  }
}
