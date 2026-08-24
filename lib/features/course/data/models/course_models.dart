import '../../domain/entities/course_entities.dart';
import '../../domain/entities/course_progress_entities.dart';

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) return value.values.toList();
  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

int _toIntOrZero(dynamic value) => _toInt(value) ?? 0;

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _toBool(dynamic value) => value == true || value == 'true';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String? _categoryName(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value['name'] as String?;
  }
  if (value is Map) return value['name']?.toString();
  return null;
}

class CourseProgressSummaryModel {
  final CourseProgressSummary summary;

  const CourseProgressSummaryModel(this.summary);

  static CourseProgressSummaryModel? fromJson(dynamic json) {
    if (json is! Map) return null;
    final map = _asMap(json);
    return CourseProgressSummaryModel(
      CourseProgressSummary(
        status: map['status'] as String? ?? 'in_progress',
        completedItems: _toIntOrZero(map['completedItems']),
        pointsEarned: _toIntOrZero(map['pointsEarned']),
        completions: _toIntOrZero(map['completions']),
        startedAt: _parseDate(map['startedAt']),
        completedAt: _parseDate(map['completedAt']),
        lastSavedAt: _parseDate(map['lastSavedAt']),
      ),
    );
  }
}

class CourseModel {
  final Course course;

  const CourseModel(this.course);

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      Course(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
        difficulty: json['difficulty'] as String? ?? 'easy',
        categoryName: _categoryName(json['categoryId']),
        points: _toIntOrZero(json['points']),
        estimatedDurationMinutes: _toInt(json['estimatedDurationMinutes']),
        publishedAt: _parseDate(json['publishedAt']),
        totalLessons: _toIntOrZero(json['totalLessons']),
        totalItems: _toIntOrZero(json['totalItems']),
        userProgress:
            CourseProgressSummaryModel.fromJson(json['userProgress'])?.summary,
      ),
    );
  }
}

class CourseItemContentModel {
  final CourseItemContent content;

  const CourseItemContentModel(this.content);

  static CourseItemContentModel? fromJson(dynamic json) {
    if (json is! Map) return null;
    final map = _asMap(json);
    return CourseItemContentModel(
      CourseItemContent(
        id: map['_id'] as String? ?? map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        type: map['type'] as String? ?? 'written',
        thumbnailUrl: map['thumbnailUrl'] as String?,
        readTimeMinutes: _toInt(map['readTimeMinutes']),
      ),
    );
  }
}

class CourseItemQuizModel {
  final CourseItemQuiz quiz;

  const CourseItemQuizModel(this.quiz);

  static CourseItemQuizModel? fromJson(dynamic json) {
    if (json is! Map) return null;
    final map = _asMap(json);
    return CourseItemQuizModel(
      CourseItemQuiz(
        id: map['_id'] as String? ?? map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        questionCount: _toIntOrZero(map['questionCount']),
      ),
    );
  }
}

class CourseLessonItemModel {
  final CourseLessonItem item;

  const CourseLessonItemModel(this.item);

  factory CourseLessonItemModel.fromJson(Map<String, dynamic> json) {
    return CourseLessonItemModel(
      CourseLessonItem(
        itemId: json['_id'] as String? ?? json['itemId'] as String? ?? '',
        refType: json['refType'] as String? ?? 'content',
        refId: json['refId'] as String? ?? '',
        content: CourseItemContentModel.fromJson(json['content'])?.content,
        quiz: CourseItemQuizModel.fromJson(json['quiz'])?.quiz,
      ),
    );
  }
}

class CourseLessonModel {
  final CourseLesson lesson;

  const CourseLessonModel(this.lesson);

  factory CourseLessonModel.fromJson(Map<String, dynamic> json) {
    return CourseLessonModel(
      CourseLesson(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        order: _toIntOrZero(json['order']),
        items: _asList(json['items'])
            .whereType<Map>()
            .map((e) => CourseLessonItemModel.fromJson(_asMap(e)).item)
            .toList(),
      ),
    );
  }
}

class CourseDetailModel {
  final CourseDetail detail;

  const CourseDetailModel(this.detail);

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) {
    final lessons = _asList(json['lessons'])
        .whereType<Map>()
        .map((e) => CourseLessonModel.fromJson(_asMap(e)).lesson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final statsRaw = _asMap(json['stats']);
    final totalItems = _toIntOrZero(
      statsRaw['totalItems'] ?? json['totalItems'],
    );
    final totalLessons = _toIntOrZero(
      statsRaw['totalLessons'] ?? json['totalLessons'],
    );
    var completedItems = _toIntOrZero(statsRaw['completedItems']);

    final progressRaw = _asMap(json['progress']);
    final completedIds = _asList(progressRaw['completedItems'])
        .map((e) => e.toString())
        .toSet();

    final userProgress =
        CourseProgressSummaryModel.fromJson(json['userProgress'])?.summary;

    if (completedItems == 0 && progressRaw.isNotEmpty) {
      completedItems = completedIds.length;
    }

    return CourseDetailModel(
      CourseDetail(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
        difficulty: json['difficulty'] as String? ?? 'easy',
        categoryName: _categoryName(json['categoryId']),
        points: _toIntOrZero(json['points']),
        estimatedDurationMinutes: _toInt(json['estimatedDurationMinutes']),
        totalCompletions: _toIntOrZero(json['totalCompletions']),
        lessons: lessons,
        stats: CourseDetailStats(
          totalLessons: totalLessons,
          totalItems: totalItems,
          completedItems: completedItems,
        ),
        completedItemIds: completedIds,
        userProgress: userProgress,
      ),
    );
  }
}

class LessonProgressModel {
  final LessonProgress progress;

  const LessonProgressModel(this.progress);

  static LessonProgressModel fromJson(Map<String, dynamic> json) {
    return LessonProgressModel(
      LessonProgress(
        lessonId:
            json['lessonId'] as String? ?? json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        order: _toIntOrZero(json['order']),
        status: json['status'] as String? ?? LessonProgress.statusNotStarted,
        items: _asList(json['items'])
            .whereType<Map>()
            .map((raw) {
              final item = _asMap(raw);
              return LessonItemFlag(
                itemId:
                    item['itemId'] as String? ?? item['_id'] as String? ?? '',
                refType: item['refType'] as String? ?? 'content',
                refId: item['refId'] as String? ?? '',
                completed: _toBool(item['completed']),
              );
            })
            .toList(),
      ),
    );
  }
}

class CourseQuizResultModel {
  final CourseQuizResult result;

  const CourseQuizResultModel(this.result);

  static CourseQuizResultModel fromJson(Map<String, dynamic> json) {
    final score = _toDouble(json['score']) ?? 0;
    final maxScore = _toDouble(json['maxScore']) ?? 0;
    final percentage = _toDouble(json['percentage']) ??
        (maxScore > 0 ? score / maxScore * 100 : 0);
    return CourseQuizResultModel(
      CourseQuizResult(
        itemId: json['itemId'] as String? ?? '',
        refId: json['refId'] as String? ?? '',
        quizTitle: json['quizTitle'] as String? ?? 'Quiz',
        score: score,
        maxScore: maxScore,
        percentage: percentage,
        passed: _toBool(json['passed']),
        attempts: _toIntOrZero(json['attempts']),
        lastAttemptAt: _parseDate(json['lastAttemptAt']),
      ),
    );
  }
}

class CourseProgressSnapshotModel {
  final CourseProgressSnapshot snapshot;

  const CourseProgressSnapshotModel(this.snapshot);

  factory CourseProgressSnapshotModel.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);

    int read(String key) =>
        _toIntOrZero(json[key] ?? summary[key]);

    final lessons = _asList(json['lessons'])
        .whereType<Map>()
        .map((e) => LessonProgressModel.fromJson(_asMap(e)).progress)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final quizResults = _asList(json['quizResults'])
        .whereType<Map>()
        .map((e) => CourseQuizResultModel.fromJson(_asMap(e)).result)
        .toList();

    final totalItems = read('totalItems');
    final completedCount = read('completedItems');
    final percentage = _toInt(json['percentageComplete'] ??
            summary['percentageComplete']) ??
        (totalItems > 0 ? (completedCount / totalItems * 100).round() : 0);

    return CourseProgressSnapshotModel(
      CourseProgressSnapshot(
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String? ?? '',
        status: json['status'] as String? ?? 'in_progress',
        totalLessons: read('totalLessons'),
        completedLessons: read('completedLessons'),
        totalItems: totalItems,
        completedItemsCount: completedCount,
        percentageComplete: percentage,
        lessons: lessons,
        quizResults: quizResults,
        pointsEarned: _toIntOrZero(json['pointsEarned']),
        completions: _toIntOrZero(json['completions']),
        startedAt: _parseDate(json['startedAt']),
        completedAt: _parseDate(json['completedAt']),
      ),
    );
  }
}

class CompleteCourseItemResultModel {
  final CompleteCourseItemResult result;

  const CompleteCourseItemResultModel(this.result);

  factory CompleteCourseItemResultModel.fromJson(Map<String, dynamic> json) {
    final levelRaw = _asMap(json['level']);
    final quizRaw = _asMap(json['quizResult']);

    return CompleteCourseItemResultModel(
      CompleteCourseItemResult(
        courseId: json['courseId'] as String? ?? '',
        itemId: json['itemId'] as String?,
        completedItems: _toIntOrZero(json['completedItems']),
        totalItems: _toIntOrZero(json['totalItems']),
        completedLessons: _toIntOrZero(json['completedLessons']),
        totalLessons: _toIntOrZero(json['totalLessons']),
        courseCompleted: _toBool(json['courseCompleted']),
        newlyAwarded: _toBool(json['newlyAwarded']),
        pointsEarned: _toIntOrZero(json['pointsEarned']),
        completions: _toIntOrZero(json['completions']),
        completedAt: _parseDate(json['completedAt']),
        level: levelRaw.isEmpty
            ? null
            : CourseLevelInfo(
                totalPoints: _toIntOrZero(levelRaw['totalPoints']),
                level: _toIntOrZero(levelRaw['level']),
                currentLevelPoints:
                    _toIntOrZero(levelRaw['currentLevelPoints']),
                nextLevelPoints: _toIntOrZero(levelRaw['nextLevelPoints']),
                pointsToNextLevel:
                    _toIntOrZero(levelRaw['pointsToNextLevel']),
              ),
        quizResult: quizRaw.isEmpty
            ? null
            : CourseQuizResultModel.fromJson(quizRaw).result,
      ),
    );
  }
}
