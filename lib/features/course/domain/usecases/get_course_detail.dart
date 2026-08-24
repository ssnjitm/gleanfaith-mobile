import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_entities.dart';
import '../repositories/course_repository.dart';

class GetCourseDetailUseCase {
  final CourseRepository _repository;

  GetCourseDetailUseCase(this._repository);

  TaskEither<Failure, CourseDetail> call(String courseId) {
    return _repository.getCourseDetail(courseId);
  }
}
