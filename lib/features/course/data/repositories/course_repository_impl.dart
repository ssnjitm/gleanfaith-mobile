import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource _remoteDataSource;

  CourseRepositoryImpl(this._remoteDataSource);

  @override
  TaskEither<Failure, List<Course>> getCourses({
    int page = 1,
    int limit = 50,
    String? difficulty,
    String? search,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getCourses(
          page: page,
          limit: limit,
          difficulty: difficulty,
          search: search,
        );
        return result.map((e) => e.course).toList();
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CourseDetail> getCourseDetail(String courseId) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getCourseDetail(courseId);
        return result.detail;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CourseContentDocument> getContent(String contentId) {
    return TaskEither.tryCatch(
      () => _remoteDataSource.getContentById(contentId),
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CourseProgressSnapshot> getCourseProgress(
    String courseId,
  ) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.getCourseProgress(courseId);
        return result.snapshot;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CourseProgressSnapshot> startCourse(
    String courseId, {
    String? lessonId,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result =
            await _remoteDataSource.startCourse(courseId, lessonId: lessonId);
        return result.snapshot;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CompleteCourseItemResult> completeItem(
    String courseId,
    String itemId, {
    double? score,
    double? maxScore,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await _remoteDataSource.completeItem(
          courseId,
          itemId,
          score: score,
          maxScore: maxScore,
        );
        return result.result;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, CompleteCourseItemResult> completeLesson(
    String courseId,
    String lessonId,
  ) {
    return TaskEither.tryCatch(
      () async {
        final result =
            await _remoteDataSource.completeLesson(courseId, lessonId);
        return result.result;
      },
      (error, stackTrace) => handleError(error),
    );
  }

  @override
  TaskEither<Failure, void> resetProgress(String courseId) {
    return TaskEither.tryCatch(
      () => _remoteDataSource.resetProgress(courseId),
      (error, stackTrace) => handleError(error),
    );
  }
}
