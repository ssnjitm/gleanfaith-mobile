import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_entities.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/usecases/complete_course_item.dart';
import '../../domain/usecases/complete_course_lesson.dart';
import '../../domain/usecases/get_course_content.dart';
import '../../domain/usecases/get_course_detail.dart';
import '../../domain/usecases/get_course_progress.dart';
import '../../domain/usecases/get_course_quiz.dart';
import '../../domain/usecases/get_courses.dart';
import '../../domain/usecases/reset_course_progress.dart';
import '../../domain/usecases/start_course.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CourseRepositoryImpl(CourseRemoteDataSource(dio));
});

final getCoursesUseCaseProvider = Provider<GetCoursesUseCase>((ref) {
  return GetCoursesUseCase(ref.watch(courseRepositoryProvider));
});

final getCourseDetailUseCaseProvider = Provider<GetCourseDetailUseCase>((ref) {
  return GetCourseDetailUseCase(ref.watch(courseRepositoryProvider));
});

final getCourseContentUseCaseProvider =
    Provider<GetCourseContentUseCase>((ref) {
  return GetCourseContentUseCase(ref.watch(courseRepositoryProvider));
});

final getCourseQuizUseCaseProvider = Provider<GetCourseQuizUseCase>((ref) {
  return GetCourseQuizUseCase(ref.watch(courseRepositoryProvider));
});

final getCourseProgressUseCaseProvider =
    Provider<GetCourseProgressUseCase>((ref) {
  return GetCourseProgressUseCase(ref.watch(courseRepositoryProvider));
});

final startCourseUseCaseProvider = Provider<StartCourseUseCase>((ref) {
  return StartCourseUseCase(ref.watch(courseRepositoryProvider));
});

final completeCourseItemUseCaseProvider =
    Provider<CompleteCourseItemUseCase>((ref) {
  return CompleteCourseItemUseCase(ref.watch(courseRepositoryProvider));
});

final completeCourseLessonUseCaseProvider =
    Provider<CompleteCourseLessonUseCase>((ref) {
  return CompleteCourseLessonUseCase(ref.watch(courseRepositoryProvider));
});

final resetCourseProgressUseCaseProvider =
    Provider<ResetCourseProgressUseCase>((ref) {
  return ResetCourseProgressUseCase(ref.watch(courseRepositoryProvider));
});

enum CoursesStatus { initial, loading, success, error }

class CoursesState {
  final CoursesStatus status;
  final List<Course> courses;
  final String? difficulty;
  final String? message;

  const CoursesState({
    this.status = CoursesStatus.initial,
    this.courses = const [],
    this.difficulty,
    this.message,
  });

  CoursesState copyWith({
    CoursesStatus? status,
    List<Course>? courses,
    String? difficulty,
    String? message,
  }) {
    return CoursesState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      difficulty: difficulty,
      message: message,
    );
  }
}

final coursesProvider = StateNotifierProvider<CoursesNotifier, CoursesState>((
  ref,
) {
  return CoursesNotifier(ref);
});

class CoursesNotifier extends StateNotifier<CoursesState> {
  final Ref _ref;

  CoursesNotifier(this._ref) : super(const CoursesState());

  Future<void> load({String? difficulty, bool forceRefresh = false}) async {
    final hasData = state.courses.isNotEmpty && !forceRefresh;
    state = state.copyWith(
      status: hasData ? CoursesStatus.success : CoursesStatus.loading,
      difficulty: difficulty ?? state.difficulty,
      message: null,
    );

    final result =
        await _ref.read(getCoursesUseCaseProvider).call(
      difficulty: state.difficulty,
    ).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: state.courses.isEmpty ? CoursesStatus.error : CoursesStatus.success,
        message: failure.message,
      ),
      (courses) => state = state.copyWith(
        status: CoursesStatus.success,
        courses: courses,
        message: null,
      ),
    );
  }

  void setDifficulty(String? difficulty) {
    load(difficulty: difficulty);
  }

  Future<void> refresh() => load(forceRefresh: true);
}
