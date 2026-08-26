import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/course_entities.dart';
import '../models/course_models.dart';

class CourseRemoteDataSource {
  final Dio _dio;

  CourseRemoteDataSource(this._dio);

  Future<List<CourseModel>> getCourses({
    int page = 1,
    int limit = 50,
    String? difficulty,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiConstants.courses,
      queryParameters: {
        'page': page,
        'limit': limit,
        'difficulty': ?difficulty,
        'search': ?search,
      },
    );
    final list = _extractList(response.data, 'courses');
    return list
        .whereType<Map>()
        .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CourseDetailModel> getCourseDetail(String courseId) async {
    final response = await _dio.get(ApiConstants.courseById(courseId));
    final data = _extractMap(response.data);
    return CourseDetailModel.fromJson(data);
  }

  Future<CourseProgressSnapshotModel> getCourseProgress(
    String courseId,
  ) async {
    final response = await _dio.get(ApiConstants.courseProgress(courseId));
    return CourseProgressSnapshotModel.fromJson(_extractMap(response.data));
  }

  Future<CourseProgressSnapshotModel> startCourse(
    String courseId, {
    String? lessonId,
  }) async {
    final response = await _dio.post(
      ApiConstants.courseStart(courseId),
      data: lessonId == null ? null : {'lessonId': lessonId},
    );
    return CourseProgressSnapshotModel.fromJson(_extractMap(response.data));
  }

  Future<CompleteCourseItemResultModel> completeItem(
    String courseId,
    String itemId, {
    double? score,
    double? maxScore,
  }) async {
    final hasResult = score != null && maxScore != null && maxScore > 0;
    final response = await _dio.post(
      ApiConstants.courseItemComplete(courseId, itemId),
      data: hasResult
          ? {
              'score': score,
              'maxScore': maxScore,
            }
          : null,
    );
    return CompleteCourseItemResultModel.fromJson(_extractMap(response.data));
  }

  Future<CompleteCourseItemResultModel> completeLesson(
    String courseId,
    String lessonId,
  ) async {
    final response =
        await _dio.post(ApiConstants.courseLessonComplete(courseId, lessonId));
    return CompleteCourseItemResultModel.fromJson(_extractMap(response.data));
  }

  Future<void> resetProgress(String courseId) async {
    await _dio.post(ApiConstants.courseReset(courseId));
  }

  Future<CourseContentDocument> getContentById(String contentId) async {
    final response = await _dio.get(ApiConstants.contentById(contentId));
    final data = _extractMap(response.data);
    final raw = data['content'];
    final map =
        raw is Map ? Map<String, dynamic>.from(raw) : data;
    return CourseContentDocument(
      id: map['_id'] as String? ?? map['id'] as String? ?? contentId,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'written',
      fileUrl: map['fileUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      tags: (map['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      readTimeMinutes: int.tryParse(
            map['readTimeMinutes']?.toString() ?? '',
          ),
    );
  }

  Future<CourseQuizSet> getQuizSet(String quizSetId) async {
    final response = await _dio.get(ApiConstants.quizSetById(quizSetId));
    return CourseQuizSetModel.fromJson(_extractMap(response.data)).set;
  }

  List<dynamic> _extractList(dynamic response, String key) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final inner = data[key];
        if (inner is List) return inner;
      }
      final direct = response[key];
      if (direct is List) return direct;
      if (data is List) return data;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return response;
    }
    return {};
  }
}
