import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_entities.dart';
import '../repositories/course_repository.dart';

class GetCoursesUseCase {
  final CourseRepository _repository;

  GetCoursesUseCase(this._repository);

  TaskEither<Failure, List<Course>> call({
    int page = 1,
    int limit = 50,
    String? difficulty,
    String? search,
  }) {
    return _repository.getCourses(
      page: page,
      limit: limit,
      difficulty: difficulty,
      search: search,
    );
  }
}
