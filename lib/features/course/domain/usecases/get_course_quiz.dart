import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_entities.dart';
import '../repositories/course_repository.dart';

class GetCourseQuizUseCase {
  final CourseRepository _repository;

  GetCourseQuizUseCase(this._repository);

  TaskEither<Failure, CourseQuizSet> call(String quizSetId) {
    return _repository.getQuizSet(quizSetId);
  }
}
