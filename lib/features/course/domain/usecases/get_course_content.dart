import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_entities.dart';
import '../repositories/course_repository.dart';

class GetCourseContentUseCase {
  final CourseRepository _repository;

  GetCourseContentUseCase(this._repository);

  TaskEither<Failure, CourseContentDocument> call(String contentId) {
    return _repository.getContent(contentId);
  }
}
