import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_progress_entities.dart';
import '../repositories/course_repository.dart';

class CompleteCourseLessonUseCase {
  final CourseRepository _repository;

  CompleteCourseLessonUseCase(this._repository);

  TaskEither<Failure, CompleteCourseItemResult> call(
    String courseId,
    String lessonId,
  ) {
    return _repository.completeLesson(courseId, lessonId);
  }
}
