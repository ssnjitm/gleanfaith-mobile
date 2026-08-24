import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';
import 'course_providers.dart';

enum CourseDetailPhase { loading, ready, error }

class CourseDetailState {
  final CourseDetailPhase phase;
  final CourseDetail? detail;
  final CourseProgressSnapshot? progress;
  final String? message;
  final bool working;

  const CourseDetailState({
    this.phase = CourseDetailPhase.loading,
    this.detail,
    this.progress,
    this.message,
    this.working = false,
  });

  CourseDetailState copyWith({
    CourseDetailPhase? phase,
    CourseDetail? detail,
    CourseProgressSnapshot? progress,
    String? message,
    bool? working,
    bool clearProgress = false,
  }) {
    return CourseDetailState(
      phase: phase ?? this.phase,
      detail: detail ?? this.detail,
      progress: clearProgress ? null : (progress ?? this.progress),
      message: message,
      working: working ?? this.working,
    );
  }
}

final courseDetailProvider = StateNotifierProvider.family<
    CourseDetailNotifier, CourseDetailState, String>((ref, courseId) {
  return CourseDetailNotifier(ref, courseId);
});

class CourseDetailNotifier extends StateNotifier<CourseDetailState> {
  final Ref _ref;
  final String courseId;

  CourseDetailNotifier(this._ref, this.courseId)
      : super(const CourseDetailState()) {
    load();
  }

  Future<void> load() async {
    if (state.detail == null) {
      state = state.copyWith(phase: CourseDetailPhase.loading, message: null);
    }

    final detailResult = await _ref
        .read(getCourseDetailUseCaseProvider)
        .call(courseId)
        .run();

    await detailResult.fold(
      (failure) async {
        state = state.copyWith(
          phase: CourseDetailPhase.error,
          message: failure.message,
        );
      },
      (detail) async {
        state = state.copyWith(
          phase: CourseDetailPhase.ready,
          detail: detail,
          clearProgress: true,
          message: null,
        );
        final progressResult = await _ref
            .read(getCourseProgressUseCaseProvider)
            .call(courseId)
            .run();
        progressResult.fold(
          (_) => state = state.copyWith(clearProgress: true),
          (snapshot) => state = state.copyWith(progress: snapshot),
        );
      },
    );
  }

  Future<void> startCourse() async {
    state = state.copyWith(working: true, message: null);
    final firstLessonId = state.detail?.lessons.isNotEmpty == true
        ? state.detail!.lessons.first.id
        : null;

    final result = await _ref.read(startCourseUseCaseProvider).call(
      courseId,
      lessonId: firstLessonId,
    ).run();

    await result.fold(
      (failure) async {
        state = state.copyWith(
          working: false,
          message: failure.message,
        );
      },
      (snapshot) async {
        state = state.copyWith(
          working: false,
          progress: snapshot,
          clearProgress: false,
        );
        await load();
      },
    );
  }

  Future<CompleteCourseItemResult?> completeItem(
    String itemId, {
    double? score,
    double? maxScore,
  }) async {
    state = state.copyWith(working: true, message: null);
    final result = await _ref.read(completeCourseItemUseCaseProvider).call(
      courseId,
      itemId,
      score: score,
      maxScore: maxScore,
    ).run();

    CompleteCourseItemResult? completed;
    result.fold(
      (failure) {
        state = state.copyWith(working: false, message: failure.message);
      },
      (value) {
        completed = value;
        state = state.copyWith(working: false);
      },
    );
    if (completed != null) {
      await load();
    }
    return completed;
  }

  Future<CompleteCourseItemResult?> completeLesson(String lessonId) async {
    state = state.copyWith(working: true, message: null);
    final result =
        await _ref.read(completeCourseLessonUseCaseProvider).call(
              courseId,
              lessonId,
            ).run();

    CompleteCourseItemResult? completed;
    result.fold(
      (failure) {
        state = state.copyWith(working: false, message: failure.message);
      },
      (value) {
        completed = value;
        state = state.copyWith(working: false);
      },
    );
    if (completed != null) {
      await load();
    }
    return completed;
  }

  Future<void> reset() async {
    state = state.copyWith(working: true, message: null);
    final result =
        await _ref.read(resetCourseProgressUseCaseProvider).call(courseId).run();
    result.fold(
      (failure) => state = state.copyWith(
        working: false,
        message: failure.message,
      ),
      (_) {},
    );
    await load();
  }
}
