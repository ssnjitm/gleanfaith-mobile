import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/course/data/models/course_models.dart';
import 'package:glean_faith_app/features/quiz/domain/entities/quiz_entities.dart';

void main() {
  test('course quiz parses the same {en, np} payload', () {
    final model = CourseQuizSetModel.fromJson({
      '_id': 'set-1',
      'title': 'Kings',
      'questions': [
        {
          'id': 'q_001',
          'question': {
            'en': 'Which king was married to Jezebel?',
            'np': 'कुन राजाको विवाह इजबेलसँग थियो?',
          },
          'options': [
            {
              'id': 'a',
              'text': {'en': 'King Ahab', 'np': 'राजा आहाब'},
              'is_correct': true,
            },
            {
              'id': 'b',
              'text': {'en': 'King Jeroboam', 'np': 'राजा यारोबाम'},
              'is_correct': false,
            },
          ],
          'scripture_reference': '1 Kings 16:30-31',
        },
      ],
    });
    final question = model.set.questions.single;

    expect(question.text, 'Which king was married to Jezebel?');
    expect(question.options, ['King Ahab', 'King Jeroboam']);
    expect(question.correctAnswerIndex, 0);
    expect(question.scriptureReference, '1 Kings 16:30-31');
    expect(question.hasNepali, isTrue);
    expect(
      question.textFor(QuizLanguage.nepali),
      'कुन राजाको विवाह इजबेलसँग थियो?',
    );
    expect(question.optionsFor(QuizLanguage.nepali), [
      'राजा आहाब',
      'राजा यारोबाम',
    ]);
  });

  test('course quiz still accepts plain string questions', () {
    final model = CourseQuizSetModel.fromJson({
      'questions': [
        {
          'text': 'Plain question',
          'options': ['A', 'B'],
          'correctAnswerIndex': 1,
        },
      ],
    });
    final question = model.set.questions.single;

    expect(question.text, 'Plain question');
    expect(question.options, ['A', 'B']);
    expect(question.correctAnswerIndex, 1);
    expect(question.hasNepali, isFalse);
    expect(question.textFor(QuizLanguage.nepali), 'Plain question');
  });
}
