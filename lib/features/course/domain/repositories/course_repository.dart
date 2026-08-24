import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/course_entities.dart';
import '../entities/course_progress_entities.dart';

abstract class CourseRepository {
  TaskEither<Failure, List<Course>> getCourses({
    int page,
    int limit,
    String? difficulty,
    String? search,
  });

  TaskEither<Failure, CourseDetail> getCourseDetail(String courseId);

  TaskEither<Failure, CourseContentDocument> getContent(
    String contentId,
  );

  TaskEither<Failure, CourseProgressSnapshot> getCourseProgress(
    String courseId,
  );

  TaskEither<Failure, CourseProgressSnapshot> startCourse(
    String courseId, {
    String? lessonId,
  });

  TaskEither<Failure, CompleteCourseItemResult> completeItem(
    String courseId,
    String itemId, {
    double? score,
    double? maxScore,
  });

  TaskEither<Failure, CompleteCourseItemResult> completeLesson(
    String courseId,
    String lessonId,
  );

  TaskEither<Failure, void> resetProgress(String courseId);
}
