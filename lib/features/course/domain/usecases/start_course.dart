import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_progress_entities.dart';
import '../repositories/course_repository.dart';

class StartCourseUseCase {
  final CourseRepository _repository;

  StartCourseUseCase(this._repository);

  TaskEither<Failure, CourseProgressSnapshot> call(
    String courseId, {
    String? lessonId,
  }) {
    return _repository.startCourse(courseId, lessonId: lessonId);
  }
}
