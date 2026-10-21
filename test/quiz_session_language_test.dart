import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/quiz/data/models/quiz_models.dart';
import 'package:glean_faith_app/features/quiz/domain/entities/quiz_entities.dart';

/// Regression tests for the EN | NP control on the quiz questions screen.
///
/// The backend answers a session in the language it was started with, so a
/// session started with `?language=np` comes back as a **flat, single-language**
/// payload: a plain Nepali `text` string and a list of Nepali option strings.
///
/// The parser used to assume that the primary string is English, so the
/// Nepali text landed in the English slot: switching to English changed
/// nothing and the toggle looked dead.
const _npQuestion = 'तल्लो सम्बन्धी कुरा भन्ने कुन हो?';
const _npOptionA = 'दाऊन';
const _npOptionB = 'यशुशा';
const _enQuestion = 'Which book is called the Song of Songs?';
const _enOptionA = 'Ruth';
const _enOptionB = 'Joshua';

Map<String, dynamic> _flatPayload({
  required String text,
  required List<String> options,
}) {
  return {
    'index': 0,
    'type': 'mcq',
    'text': text,
    'options': options,
  };
}

Map<String, dynamic> _sessionPayload(List<Map<String, dynamic>> questions) {
  return {
    'sessionId': 'session-1',
    'durationSeconds': 600,
    'questions': questions,
  };
}

void main() {
  group('A session started in Nepali (flat single-language payload)', () {
    final model = QuizQuestionModel.fromJson(
      _flatPayload(text: _npQuestion, options: [_npOptionA, _npOptionB]),
      language: QuizLanguage.nepali,
    );
    final question = model.toEntity();

    test('does not put the Nepali text in the English slot', () {
      expect(question.text, isEmpty);
      expect(question.textNp, _npQuestion);
    });

    test('keeps the delivered text as the fallback', () {
      expect(question.primaryText, _npQuestion);
    });

    test('renders the Nepali text for Nepali', () {
      expect(question.textFor(QuizLanguage.nepali), _npQuestion);
    });

    test('never renders a blank body for English', () {
      // The session has no English wording, so the delivered text is shown
      // rather than an empty question.
      expect(question.textFor(QuizLanguage.english), _npQuestion);
    });

    test('reports which languages the session carries', () {
      expect(question.hasNepali, isTrue);
      expect(question.hasEnglish, isFalse);
    });

    test('keeps the Nepali options aligned with the answer key', () {
      expect(question.optionsFor(QuizLanguage.nepali), [
        _npOptionA,
        _npOptionB,
      ]);
      expect(question.optionsFor(QuizLanguage.english), [
        _npOptionA,
        _npOptionB,
      ]);
      expect(question.optionsFor(QuizLanguage.english), hasLength(2));
    });
  });

  group('A session started in English (flat single-language payload)', () {
    final model = QuizQuestionModel.fromJson(
      _flatPayload(text: _enQuestion, options: [_enOptionA, _enOptionB]),
      language: QuizLanguage.english,
    );
    final question = model.toEntity();

    test('keeps the English text in the English slot', () {
      expect(question.text, _enQuestion);
      expect(question.textNp, isNull);
    });

    test('reports which languages the session carries', () {
      expect(question.hasEnglish, isTrue);
      expect(question.hasNepali, isFalse);
    });

    test('falls back to English for Nepali', () {
      expect(question.textFor(QuizLanguage.nepali), _enQuestion);
      expect(question.optionsFor(QuizLanguage.nepali), [
        _enOptionA,
        _enOptionB,
      ]);
    });
  });

  group('A bilingual payload', () {
    final model = QuizQuestionModel.fromJson({
      'index': 0,
      'question': {'en': _enQuestion, 'np': _npQuestion},
      'options': [
        {
          'id': 'a',
          'text': {'en': _enOptionA, 'np': _npOptionA},
        },
        {
          'id': 'b',
          'text': {'en': _enOptionB, 'np': _npOptionB},
        },
      ],
    }, language: QuizLanguage.english);
    final question = model.toEntity();

    test('keeps both wordings', () {
      expect(question.text, _enQuestion);
      expect(question.textNp, _npQuestion);
      expect(question.hasEnglish, isTrue);
      expect(question.hasNepali, isTrue);
    });

    test('switches the text in both directions', () {
      expect(question.textFor(QuizLanguage.english), _enQuestion);
      expect(question.textFor(QuizLanguage.nepali), _npQuestion);
    });

    test('switches the options in both directions', () {
      expect(question.optionsFor(QuizLanguage.english), [
        _enOptionA,
        _enOptionB,
      ]);
      expect(question.optionsFor(QuizLanguage.nepali), [
        _npOptionA,
        _npOptionB,
      ]);
    });

    test('delivers the session language as the fallback', () {
      expect(question.primaryText, _enQuestion);
    });
  });

  group('Re-reading a session in the other language', () {
    test('the Nepali session carries no English wording', () {
      final session = ActiveQuizModel.fromJson(
        _sessionPayload([
          _flatPayload(text: _npQuestion, options: [_npOptionA, _npOptionB]),
        ]),
        language: QuizLanguage.nepali,
      ).toEntity();

      expect(session.questions.single.hasEnglish, isFalse);
      expect(session.questions.single.hasNepali, isTrue);
    });

    test('the same session id re-read in English carries the English wording',
        () {
      final session = ActiveQuizModel.fromJson(
        _sessionPayload([
          _flatPayload(text: _enQuestion, options: [_enOptionA, _enOptionB]),
        ]),
        language: QuizLanguage.english,
      ).toEntity();

      expect(session.sessionId, 'session-1');
      expect(session.questions.single.textFor(QuizLanguage.english), _enQuestion);
      expect(session.questions.single.hasEnglish, isTrue);
    });

    test('the session language is carried on the entity', () {
      final session = ActiveQuizModel.fromJson(
        _sessionPayload([
          _flatPayload(text: _npQuestion, options: [_npOptionA, _npOptionB]),
        ]),
        language: QuizLanguage.nepali,
      ).toEntity();

      expect(session.language, QuizLanguage.nepali);
    });
  });

  group('Every supported payload keeps the question readable', () {    final payloads = <Map<String, dynamic>>[
      _flatPayload(text: _enQuestion, options: [_enOptionA, _enOptionB]),
      _flatPayload(text: _npQuestion, options: [_npOptionA, _npOptionB]),
      {
        'index': 0,
        'question': {'en': _enQuestion, 'np': _npQuestion},
        'options': [
          {'id': 'a', 'text': {'en': _enOptionA, 'np': _npOptionA}},
          {'id': 'b', 'text': {'en': _enOptionB, 'np': _npOptionB}},
        ],
      },
      {
        'index': 0,
        'text': _enQuestion,
        'textNp': _npQuestion,
        'options': [_enOptionA, _enOptionB],
        'optionsNp': [_npOptionA, _npOptionB],
      },
    ];

    for (final payload in payloads) {
      for (final language in QuizLanguage.values) {
        test('${payload['text'] ?? 'bilingual'} / ${language.code}', () {
          final question = QuizQuestionModel.fromJson(
            payload,
            language: language,
          ).toEntity();

          expect(question.textFor(QuizLanguage.english), isNotEmpty);
          expect(question.textFor(QuizLanguage.nepali), isNotEmpty);
          expect(question.optionsFor(QuizLanguage.english), isNotEmpty);
          expect(question.optionsFor(QuizLanguage.nepali), isNotEmpty);
        });
      }
    }
  });

  group('The answer explanation follows the same rule', () {
    test('a Nepali explanation is not passed off as English', () {
      final answer = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 0,
        'pointsEarned': 1,
        'explanation': 'यो पुस्तक गीतहरुको पुस्तक हो।',
      }).toEntity();

      expect(answer.explanation, isEmpty);
      expect(answer.explanationNp, 'यो पुस्तक गीतहरुको पुस्तक हो।');
      // The feedback line never blanks, whatever the toggle says.
      expect(answer.explanationFor(QuizLanguage.english), isNotEmpty);
      expect(
        answer.explanationFor(QuizLanguage.nepali),
        'यो पुस्तक गीतहरुको पुस्तक हो।',
      );
    });

    test('an English explanation falls back for Nepali', () {
      final answer = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 0,
        'pointsEarned': 1,
        'explanation': 'This book is the Song of Songs.',
      }).toEntity();

      expect(answer.explanation, 'This book is the Song of Songs.');
      expect(answer.explanationNp, isNull);
      expect(
        answer.explanationFor(QuizLanguage.nepali),
        'This book is the Song of Songs.',
      );
    });

    test('a bilingual payload keeps both explanations', () {
      final answer = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 0,
        'pointsEarned': 1,
        'explanation': 'This book is the Song of Songs.',
        'explanationNp': 'यो पुस्तक गीतहरुको पुस्तक हो।',
      }).toEntity();

      expect(
        answer.explanationFor(QuizLanguage.english),
        'This book is the Song of Songs.',
      );
      expect(
        answer.explanationFor(QuizLanguage.nepali),
        'यो पुस्तक गीतहरुको पुस्तक हो।',
      );
    });
  });
}
