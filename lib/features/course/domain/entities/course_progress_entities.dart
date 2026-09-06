import 'course_entities.dart';

class LessonItemFlag {
  final String itemId;
  final String refType;
  final String refId;
  final bool completed;

  const LessonItemFlag({
    required this.itemId,
    required this.refType,
    required this.refId,
    required this.completed,
  });
}

class LessonProgress {
  static const statusNotStarted = 'not_started';
  static const statusInProgress = 'in_progress';
  static const statusCompleted = 'completed';

  final String lessonId;
  final String title;
  final int order;
  final String status;
  final List<LessonItemFlag> items;

  const LessonProgress({
    required this.lessonId,
    required this.title,
    required this.order,
    required this.status,
    required this.items,
  });

  bool get isCompleted => status == statusCompleted;

  int get completedCount => items.where((e) => e.completed).length;
}

class CourseQuizResult {
  final String itemId;
  final String refId;
  final String quizTitle;
  final double score;
  final double maxScore;
  final double percentage;
  final bool passed;
  final int attempts;
  final DateTime? lastAttemptAt;

  const CourseQuizResult({
    required this.itemId,
    required this.refId,
    required this.quizTitle,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.attempts,
    required this.lastAttemptAt,
  });
}

class CourseProgressSnapshot {
  final String courseId;
  final String courseTitle;
  final String status; // in_progress | completed
  final int totalLessons;
  final int completedLessons;
  final int totalItems;
  final int completedItemsCount;
  final int percentageComplete;
  final List<LessonProgress> lessons;
  final List<CourseQuizResult> quizResults;
  final int pointsEarned;
  final int completions;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const CourseProgressSnapshot({
    required this.courseId,
    required this.courseTitle,
    required this.status,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalItems,
    required this.completedItemsCount,
    required this.percentageComplete,
    required this.lessons,
    required this.quizResults,
    required this.pointsEarned,
    required this.completions,
    required this.startedAt,
    required this.completedAt,
  });

  Set<String> get completedItemIds => lessons
      .expand((l) => l.items)
      .where((i) => i.completed)
      .map((i) => i.itemId)
      .toSet();

  CourseQuizResult? resultForItem(String itemId) {
    for (final r in quizResults) {
      if (r.itemId == itemId) return r;
    }
    return null;
  }
}

class CourseLevelInfo {
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;

  const CourseLevelInfo({
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
  });
}

class CompleteCourseItemResult {
  final String courseId;
  final String? itemId;
  final int completedItems;
  final int totalItems;
  final int completedLessons;
  final int totalLessons;
  final bool courseCompleted;
  final bool newlyAwarded;
  final int pointsEarned;
  final int completions;
  final DateTime? completedAt;
  final CourseLevelInfo? level;
  final CourseQuizResult? quizResult;

  const CompleteCourseItemResult({
    required this.courseId,
    required this.itemId,
    required this.completedItems,
    required this.totalItems,
    required this.completedLessons,
    required this.totalLessons,
    required this.courseCompleted,
    required this.newlyAwarded,
    required this.pointsEarned,
    required this.completions,
    required this.completedAt,
    required this.level,
    required this.quizResult,
  });
}

class CourseContentViewArgs {
  final String courseId;
  final String itemId;
  final String refId;
  final bool alreadyCompleted;
  final CourseContentDocument? embedded;

  const CourseContentViewArgs({
    required this.courseId,
    required this.itemId,
    required this.refId,
    required this.alreadyCompleted,
    this.embedded,
  });
}

class CourseQuizPlayArgs {
  final String courseId;
  final String itemId;
  final String refId;
  final String title;
  final int attemptsBefore;
  final CourseContentViewArgs? lessonContentArgs;

  const CourseQuizPlayArgs({
    required this.courseId,
    required this.itemId,
    required this.refId,
    required this.title,
    required this.attemptsBefore,
    this.lessonContentArgs,
  });
}

class CourseQuizReviewArgs {
  final String courseId;
  final String itemId;
  final String refId;
  final String title;
  final CourseContentViewArgs? lessonContentArgs;

  const CourseQuizReviewArgs({
    required this.courseId,
    required this.itemId,
    required this.refId,
    required this.title,
    this.lessonContentArgs,
  });
}

class CourseQuizAttempt {
  final double score;
  final double maxScore;
  final List<int?> answers;
  final DateTime attemptedAt;

  const CourseQuizAttempt({
    required this.score,
    required this.maxScore,
    required this.answers,
    required this.attemptedAt,
  });

  double get percentage => maxScore > 0 ? score / maxScore * 100 : 0;

  bool get passed => percentage >= 70;

  int get answeredCount => answers.where((a) => a != null).length;

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'maxScore': maxScore,
      'answers': answers,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }

  factory CourseQuizAttempt.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (json['maxScore'] as num?)?.toDouble() ?? 0;
    final answers = <int?>[];
    final raw = json['answers'];
    if (raw is List) {
      answers.addAll(raw.map((e) => e is num ? e.toInt() : null));
    }
    return CourseQuizAttempt(
      score: score,
      maxScore: maxScore,
      answers: answers,
      attemptedAt: DateTime.tryParse(json['attemptedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
