class CourseProgressSummary {
  final String status; // in_progress | completed
  final int completedItems;
  final int pointsEarned;
  final int completions;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastSavedAt;

  const CourseProgressSummary({
    required this.status,
    required this.completedItems,
    required this.pointsEarned,
    required this.completions,
    this.startedAt,
    this.completedAt,
    this.lastSavedAt,
  });

  bool get isCompleted => status == 'completed';
}

class Course {
  final String id;
  final String title;
  final String description;
  final String? thumbnail;
  final String difficulty; // easy | medium | hard
  final String? categoryName;
  final int points;
  final int? estimatedDurationMinutes;
  final DateTime? publishedAt;
  final int totalLessons;
  final int totalItems;
  final CourseProgressSummary? userProgress;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.difficulty,
    required this.categoryName,
    required this.points,
    required this.estimatedDurationMinutes,
    required this.publishedAt,
    required this.totalLessons,
    required this.totalItems,
    required this.userProgress,
  });

  bool get isStarted => userProgress != null;
  bool get isCompleted => userProgress?.isCompleted ?? false;
  double get progressFraction =>
      totalItems == 0 ? 0 : (userProgress?.completedItems ?? 0) / totalItems;
}

class CourseItemContent {
  final String id;
  final String title;
  final String type; // written | pdf | audio | video
  final String? thumbnailUrl;
  final int? readTimeMinutes;

  const CourseItemContent({
    required this.id,
    required this.title,
    required this.type,
    required this.thumbnailUrl,
    required this.readTimeMinutes,
  });
}

class CourseContentDocument {
  final String id;
  final String title;
  final String body;
  final String type; // written | pdf | audio | video
  final String? fileUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<String> tags;
  final int? readTimeMinutes;

  const CourseContentDocument({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.fileUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.tags,
    required this.readTimeMinutes,
  });
}

class CourseItemQuiz {
  final String id;
  final String title;
  final String description;
  final int questionCount;

  const CourseItemQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
  });
}

class CourseLessonItem {
  final String itemId;
  final String refType; // content | quiz
  final String refId;
  final CourseItemContent? content;
  final CourseItemQuiz? quiz;

  const CourseLessonItem({
    required this.itemId,
    required this.refType,
    required this.refId,
    required this.content,
    required this.quiz,
  });

  bool get isQuiz => refType == 'quiz';

  String get title => isQuiz
      ? (quiz?.title ?? 'Quiz')
      : (content?.title ?? 'Untitled content');

  String get displayType =>
      isQuiz ? 'quiz' : (content?.type ?? 'written');
}

class CourseLesson {
  final String id;
  final String title;
  final String? description;
  final int order;
  final List<CourseLessonItem> items;

  const CourseLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.items,
  });
}

class CourseDetailStats {
  final int totalLessons;
  final int totalItems;
  final int completedItems;

  const CourseDetailStats({
    required this.totalLessons,
    required this.totalItems,
    required this.completedItems,
  });

  double get fraction =>
      totalItems == 0 ? 0 : completedItems / totalItems;
}

class CourseDetail {
  final String id;
  final String title;
  final String description;
  final String? thumbnail;
  final String difficulty;
  final String? categoryName;
  final int points;
  final int? estimatedDurationMinutes;
  final int totalCompletions;
  final List<CourseLesson> lessons;
  final CourseDetailStats stats;
  final Set<String> completedItemIds;
  final CourseProgressSummary? userProgress;

  const CourseDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.difficulty,
    required this.categoryName,
    required this.points,
    required this.estimatedDurationMinutes,
    required this.totalCompletions,
    required this.lessons,
    required this.stats,
    required this.completedItemIds,
    required this.userProgress,
  });

  bool get isStarted => userProgress != null || completedItemIds.isNotEmpty;
  bool get isCompleted => userProgress?.isCompleted ?? false;
}
