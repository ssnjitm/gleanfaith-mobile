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

Map<String, dynamic>? _maybeMap(dynamic value) {
  final map = _asMap(value);
  return map.isEmpty ? null : map;
}

/// Reads a scalar. Maps and lists are deliberately NOT stringified, so a
/// bilingual node can never render as the literal `{en: ..., np: ...}`.
/// Mirrors `_asString` in `quiz_models.dart` — keep the two in sync.
String? _asString(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num || value is bool) return value.toString();
  return null;
}

/// Devanagari block (U+0900–U+097F) — the script Nepali is written in.
final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');

bool _looksNepali(String? value) => value != null && _devanagari.hasMatch(value);

/// Resolves a value that is either a plain string or a `{en, np}` object.
///
/// Known keys first, then a split by script, so a renamed `np` key cannot
/// leave the EN | NP toggle inert.
({String? en, String? np}) _bilingual(dynamic value) {
  final map = _maybeMap(value);
  if (map == null) {
    final text = _asString(value);
    return (en: text, np: _looksNepali(text) ? text : null);
  }
  var en =
      _asString(map['en']) ??
      _asString(map['english']) ??
      _asString(map['text']) ??
      _asString(map['question']);
  var np =
      _asString(map['np']) ??
      _asString(map['ne']) ??
      _asString(map['nepali']) ??
      _asString(map['textNp']) ??
      _asString(map['text_np']);
  final strings = map.entries
      .where((entry) => !_isMetadataKey(entry.key))
      .map((entry) => entry.value)
      .whereType<String>()
      .toList();
  en ??= strings.firstWhere(
    (candidate) => !_looksNepali(candidate),
    orElse: () => '',
  );
  np ??= strings.firstWhere(_looksNepali, orElse: () => '');
  return (en: en.isEmpty ? null : en, np: np.isEmpty ? null : np);
}

/// One label per option for the requested language. An entry may be a plain
/// string, `{text: "..."}` or `{text: {en, np}}`.
List<String> _optionLabels(dynamic value, {required bool nepali}) {
  final labels = <String>[];
  for (final option in _asList(value)) {
    if (option is bool) {
      labels.add(option ? 'True' : 'False');
      continue;
    }
    final map = _maybeMap(option);
    if (map == null) {
      final label = _asString(option);
      if (label == null) continue;
      labels.add(nepali ? (_looksNepali(label) ? label : '') : label);
      continue;
    }
    final inner = map['text'] ?? map['label'] ?? map['option'];
    var pair = _bilingual(inner);
    if ((nepali ? pair.np : pair.en) == null) {
      pair = _bilingual(map);
    }
    final label = nepali ? pair.np : pair.en;
    labels.add((label == null || label.isEmpty) ? '' : label);
  }
  return labels;
}

bool _isMetadataKey(String key) {
  final lower = key.toLowerCase();
  return lower == 'id' ||
      lower == '_id' ||
      lower == 'key' ||
      lower == 'value' ||
      lower.contains('correct') ||
      lower.contains('weight') ||
      lower.contains('point');
}

/// Index of the option flagged correct via `is_correct` / `isCorrect`, which
/// is how the quiz payload marks the answer key. Returns null when absent.
int? _correctIndexFromOptions(Map<String, dynamic> question) {
  final options = _asList(question['options']);
  for (var index = 0; index < options.length; index++) {
    final map = _maybeMap(options[index]);
    if (map == null) continue;
    if (_toBool(map['is_correct']) || _toBool(map['isCorrect'])) return index;
  }
  return null;
}

/// The first Nepali string among several candidate fields.
String? _nepaliString(dynamic value) {
  final direct = _asString(value);
  if (_looksNepali(direct)) return direct;
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
        body: map['body'] as String? ?? '',
        fileUrl: map['fileUrl'] as String?,
        videoUrl: map['videoUrl'] as String?,
        tags: _asList(map['tags']).map((e) => e.toString()).toList(),
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
    final wrappedCourse = json['course'];
    final courseJson = wrappedCourse is Map
        ? Map<String, dynamic>.from(wrappedCourse)
        : json;

    final lessons = _asList(courseJson['lessons'])
        .whereType<Map>()
        .map((e) => CourseLessonModel.fromJson(_asMap(e)).lesson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final statsRaw = _asMap(courseJson['stats']);
    final totalItems = _toIntOrZero(
      statsRaw['totalItems'] ?? courseJson['totalItems'],
    );
    final totalLessons = _toIntOrZero(
      statsRaw['totalLessons'] ?? courseJson['totalLessons'],
    );
    var completedItems = _toIntOrZero(statsRaw['completedItems']);

    final progressRaw = _asMap(json['progress'] ?? courseJson['progress']);
    final completedIds = _asList(progressRaw['completedItems'])
        .map((e) => e.toString())
        .toSet();

    final userProgressRaw =
        json['userProgress'] ?? courseJson['userProgress'];
    final userProgress =
        CourseProgressSummaryModel.fromJson(userProgressRaw)?.summary;

    if (completedItems == 0 && completedIds.isNotEmpty) {
      completedItems = completedIds.length;
    }

    return CourseDetailModel(
      CourseDetail(
        id: courseJson['_id'] as String? ??
            courseJson['id'] as String? ??
            '',
        title: courseJson['title'] as String? ?? '',
        description: courseJson['description'] as String? ?? '',
        thumbnail: courseJson['thumbnail'] as String?,
        difficulty: courseJson['difficulty'] as String? ?? 'easy',
        categoryName: _categoryName(courseJson['categoryId']),
        points: _toIntOrZero(courseJson['points']),
        estimatedDurationMinutes:
            _toInt(courseJson['estimatedDurationMinutes']),
        totalCompletions: _toIntOrZero(courseJson['totalCompletions']),
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

class CourseQuizSetModel {
  final CourseQuizSet set;

  const CourseQuizSetModel(this.set);

  factory CourseQuizSetModel.fromJson(Map<String, dynamic> json) {
    final questions = _asList(json['questions'])
        .whereType<Map>()
        .map((raw) {
          final q = _asMap(raw);
          // Same payload as the daily quiz: `question: {en, np}` and
          // `options: [{id, text: {en, np}, is_correct}]`. Plain strings are
          // still accepted.
          final question = _bilingual(q['question'] ?? q['text'] ?? q['en']);
          final options = _optionLabels(q['options'], nepali: false);
          final optionsNp = _optionLabels(q['options'], nepali: true);
          return CourseQuizQuestion(
            text: question.en ?? '',
            options: options,
            correctAnswerIndex: _toIntOrZero(
              q['correctAnswerIndex'] ?? _correctIndexFromOptions(q),
            ),
            points: _toDouble(q['points']) ?? 1,
            explanation: _asString(q['explanation']),
            textNp: question.np,
            optionsNp: optionsNp.length == options.length &&
                    optionsNp.every((option) => option.isNotEmpty)
                ? optionsNp
                : const [],
            explanationNp: _nepaliString(
              q['explanationNp'] ?? q['explanation_np'] ?? q['npExplanation'],
            ),
            scriptureReference:
                _asString(q['scripture_reference']) ??
                _asString(q['scriptureReference']) ??
                _asString(q['reference']) ??
                _asString(q['scripture']),
          );
        })
        .toList();

    return CourseQuizSetModel(
      CourseQuizSet(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Quiz',
        description: json['description'] as String? ?? '',
        questions: questions,
      ),
    );
  }
}
