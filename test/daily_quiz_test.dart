import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/constants/app_constants.dart';
import 'package:glean_faith_app/features/quiz/data/models/quiz_models.dart';
import 'package:glean_faith_app/features/quiz/domain/entities/quiz_entities.dart';
import 'package:glean_faith_app/features/quiz/domain/entities/quiz_strings.dart';
import 'package:glean_faith_app/features/quiz/presentation/providers/daily_quiz_provider.dart';
import 'package:glean_faith_app/features/quiz/presentation/providers/quiz_provider.dart';
import 'package:glean_faith_app/features/quiz/presentation/providers/quiz_series_provider.dart';

void main() {
  group('QuizScheduleModel metadata', () {
    test('parses daily metadata and exposes getters on the entity', () {
      final model = QuizScheduleModel.fromJson({
        '_id': 'daily-1',
        'title': 'Daily Quiz',
        'metadata': {'isDaily': true, 'dailyDate': '2026-09-25'},
      });

      expect(model.metadata?['isDaily'], isTrue);

      final entity = model.toEntity();
      expect(entity.isDaily, isTrue);
      expect(entity.dailyDate, '2026-09-25');
    });

    test('treats schedules without metadata as regular quizzes', () {
      final entity = QuizScheduleModel.fromJson({
        'id': 'quiz-1',
        'title': 'Genesis Quiz',
      }).toEntity();

      expect(entity.isDaily, isFalse);
      expect(entity.dailyDate, isNull);
    });

    test('ignores non-boolean isDaily values', () {
      final entity = QuizScheduleModel.fromJson({
        '_id': 'daily-2',
        'title': 'Daily Quiz',
        'metadata': {'isDaily': 'true', 'dailyDate': 20260925},
      }).toEntity();

      expect(entity.isDaily, isFalse);
      expect(entity.dailyDate, isNull);
    });
  });

  group('QuizScheduleModel id resolution', () {
    // An empty id made the daily Start button silently disabled, which is why a
    // tap did nothing at all. These lock the shapes the daily endpoint uses.
    test('reads a plain _id', () {
      expect(QuizScheduleModel.fromJson({'_id': 'abc'}).id, 'abc');
      expect(QuizScheduleModel.fromJson({'id': 'abc'}).id, 'abc');
    });

    test('reads quizScheduleId / scheduleId aliases', () {
      expect(
        QuizScheduleModel.fromJson({'quizScheduleId': 'qs-1'}).id,
        'qs-1',
      );
      expect(QuizScheduleModel.fromJson({'scheduleId': 'qs-2'}).id, 'qs-2');
    });

    test('reads the id of a nested quizSchedule wrapper', () {
      final model = QuizScheduleModel.fromJson({
        'quizScheduleId': 'qs-top',
        'quizSchedule': {'_id': 'qs-nested', 'title': 'Daily Quiz'},
      });

      expect(model.id, 'qs-top');
      expect(model.title, 'Daily Quiz');
    });

    test('falls back to a nested schedule id and copies its window', () {
      final model = QuizScheduleModel.fromJson({
        'dailyQuiz': {'_id': 'daily-1'},
        'quizSchedule': {
          '_id': 'qs-nested',
          'startsAt': '2026-09-28T00:00:00.000Z',
          'endsAt': '2026-09-29T00:00:00.000Z',
        },
      }).toEntity();

      expect(model.id, 'qs-nested');
      expect(model.startDateTime, DateTime.utc(2026, 9, 28));
      expect(model.endDateTime, DateTime.utc(2026, 9, 29));
    });

    test('prefers the schedule id over the daily quiz wrapper id', () {
      final model = QuizScheduleModel.fromJson({
        'dailyQuiz': {'_id': 'daily-doc'},
        'schedule': {'_id': 'qs-real'},
      });

      expect(model.id, 'qs-real');
    });

    test('leaves the id empty when the payload carries none', () {
      expect(QuizScheduleModel.fromJson({'title': 'Daily Quiz'}).id, '');
    });
  });

  group('Daily quiz language toggle availability', () {
    test('a schedule from the daily endpoint is always flagged as daily', () {
      // The daily endpoints do not send `metadata.isDaily`; without the flag
      // the play page hid the EN | NP toggle and skipped the single-attempt
      // rule.
      final plain = QuizScheduleModel.fromJson({
        '_id': 'qs-1',
        'title': 'Daily Quiz',
      });

      expect(plain.toEntity().isDaily, isFalse);

      final daily = plain.asDaily();
      expect(daily.metadata?['isDaily'], isTrue);
      expect(daily.toEntity().isDaily, isTrue);
      expect(daily.toEntity().attemptsAllowed, 1);
      expect(daily.id, 'qs-1');
    });

    test('asDaily keeps existing metadata', () {
      final daily = QuizScheduleModel.fromJson({
        '_id': 'qs-1',
        'metadata': {'dailyDate': '2026-09-28'},
      }).asDaily();

      expect(daily.metadata?['isDaily'], isTrue);
      expect(daily.metadata?['dailyDate'], '2026-09-28');
    });

    test('accepts the bilingual object on `text` (the start endpoint key)', () {
      // Regression: `_asString` used to stringify a Map, which rendered the
      // question body as "{en: ..., np: ...}".
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'durationSeconds': 600,
        'questions': [
          {
            'index': 0,
            'text': {
              'en': "Which Psalm begins with 'Blessed is the man'?",
              'np': "'धन्य छ मानिस' बाट सुरु हुने गीत कुन हो?",
            },
            'type': 'mcq',
            'options': [
              {
                'id': 'a',
                'text': {'en': 'Psalm 1', 'np': 'गीत १'},
                'is_correct': true,
              },
              {
                'id': 'b',
                'text': {'en': 'Psalm 19', 'np': 'गीत १९'},
                'is_correct': false,
              },
            ],
            'points': 1,
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.text, "Which Psalm begins with 'Blessed is the man'?");
      expect(question.text, isNot(contains('{')));
      expect(question.text, isNot(contains('mcq')));
      expect(question.textFor(QuizLanguage.nepali), "'धन्य छ मानिस' बाट सुरु हुने गीत कुन हो?");
      expect(question.optionsFor(QuizLanguage.nepali), ['गीत १', 'गीत १९']);
      expect(question.hasNepali, isTrue);
      expect(question.questionIndex, 0);
    });

    test('accepts additive textNp / optionsNp next to plain English strings', () {
      final model = ActiveQuizModel.fromJson({
        'questions': [
          {
            'index': 0,
            'text': 'Which Psalm begins with Blessed is the man?',
            'textNp': 'धन्य छ मानिस बाट सुरु हुने गीत कुन हो?',
            'options': ['Psalm 1', 'Psalm 19'],
            'optionsNp': ['गीत १', 'गीत १९'],
            'type': 'mcq',
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.text, 'Which Psalm begins with Blessed is the man?');
      expect(question.hasNepali, isTrue);
      expect(question.optionsFor(QuizLanguage.nepali), ['गीत १', 'गीत १९']);
    });

    test('accepts top-level en / np plain strings', () {
      final model = ActiveQuizModel.fromJson({
        'questions': [
          {
            'en': 'Who killed Absalom?',
            'np': 'अबशालोमलाई कसले मार्‍यो?',
            'options': [
              {'en': 'Joab', 'np': 'योआब'},
              {'en': 'Abner', 'np': 'अब्नेर'},
            ],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.text, 'Who killed Absalom?');
      expect(question.optionsFor(QuizLanguage.nepali), ['योआब', 'अब्नेर']);
    });

    test('the English-only start payload still renders without a translation', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'index': 0,
            'text': 'Which Psalm begins with Blessed is the man?',
            'type': 'mcq',
            'options': ['Psalm 1', 'Psalm 19', 'Psalm 51', 'Psalm 100'],
            'points': 1,
          },
        ],
        'durationSeconds': 600,
      });
      final question = model.toEntity().questions.single;

      expect(question.text, 'Which Psalm begins with Blessed is the man?');
      expect(question.options.length, 4);
      expect(question.hasNepali, isFalse);
      expect(
        question.textFor(QuizLanguage.nepali),
        'Which Psalm begins with Blessed is the man?',
      );
    });

    test('picks up scripture_reference and the is_correct answer key', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'id': 'q_001',
            'question': {
              'en': 'Which king was married to Jezebel?',
              'np': 'कुन राजाको विवाह इजबेलसँग थियो?',
            },
            'options': [
              {'id': 'a', 'text': {'en': 'Ahab', 'np': 'आहाब'}, 'is_correct': true},
              {'id': 'b', 'text': {'en': 'David', 'np': 'दाउद'}, 'is_correct': false},
            ],
            'scripture_reference': '1 Kings 16:30-31',
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.scriptureReference, '1 Kings 16:30-31');
      expect(question.textFor(QuizLanguage.nepali), 'कुन राजाको विवाह इजबेलसँग थियो?');
      expect(question.optionsFor(QuizLanguage.nepali), ['आहाब', 'दाउद']);
    });

    test('parses the live payload where question and option text are {en, np} objects', () {
      // Verbatim shape from GET /quiz-schedule/{id}/start. `question` is an
      // object, not a string, and every option wraps its copy in
      // `{id, text: {en, np}, is_correct}`. `_asString` used to stringify the
      // whole map, so the toggle had nothing to switch to.
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'id': 'q_001',
            'difficulty': 'medium',
            'category': 'Old Testament',
            'question': {
              'en': 'According to 1 Kings, which king of Israel was known for his extreme wickedness and was married to Jezebel?',
              'np': '१ राजाका अनुसार, इस्राएलका कुन राजा आफ्नो अत्यधिक दुष्टताका लागि चिनिन्थे र उहाँको विवाह इजबेलसँग भएको थियो?',
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
              {
                'id': 'c',
                'text': {'en': 'King Rehoboam', 'np': 'राजा रहबाम'},
                'is_correct': false,
              },
              {
                'id': 'd',
                'text': {'en': 'King Omri', 'np': 'राजा अम्री'},
                'is_correct': false,
              },
            ],
            'scripture_reference': '1 Kings 16:30-31',
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.text, startsWith('According to 1 Kings'));
      expect(question.options, [
        'King Ahab',
        'King Jeroboam',
        'King Rehoboam',
        'King Omri',
      ]);

      expect(question.hasNepali, isTrue);
      expect(question.textFor(QuizLanguage.nepali), startsWith('१ राजाका अनुसार'));
      expect(question.optionsFor(QuizLanguage.nepali), [
        'राजा आहाब',
        'राजा यारोबाम',
        'राजा रहबाम',
        'राजा अम्री',
      ]);
    });

    test('finds Nepali under an unknown key by Devanagari script', () {
      // The backend renames the Nepali fields between deployments; key-based
      // lookups alone left the toggle inert.
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Who wrote Genesis?',
            'translation': 'लेखक कसले हुन्?',
            'options': ['Moses', 'David'],
            'optionTranslations': ['मोसे', 'दाउद'],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.textNp, 'लेखक कसले हुन्?');
      expect(question.hasNepali, isTrue);
      expect(question.textFor(QuizLanguage.nepali), 'लेखक कसले हुन्?');
      expect(question.optionsFor(QuizLanguage.nepali), ['मोसे', 'दाउद']);
    });

    test('reads a per-question bilingual {en, np} object', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'en': {'text': 'Pick one', 'options': ['A', 'B']},
            'np': {'text': 'एउटा छान्नुहोस्', 'options': ['क', 'ख']},
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.text, 'Pick one');
      expect(question.options, ['A', 'B']);
      expect(question.textFor(QuizLanguage.nepali), 'एउटा छान्नुहोस्');
      expect(question.optionsFor(QuizLanguage.nepali), ['क', 'ख']);
    });

    test('finds Nepali per option object regardless of the key', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Pick one',
            'options': [
              {'text': 'Alpha', 'translation': 'एल्फा'},
              {'text': 'Beta', 'translation': 'बेटा'},
            ],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.optionsFor(QuizLanguage.nepali), ['एल्फा', 'बेटा']);
    });

    test('ignores a mismatched Nepali option list to keep indices aligned', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Pick one',
            'options': ['A', 'B', 'C'],
            'optionsNp': ['क', 'ख'],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.optionsFor(QuizLanguage.nepali), ['A', 'B', 'C']);
    });

    test('never treats the English text as the Nepali variant', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Who wrote Genesis?',
            'options': ['Moses', 'David'],
            'explanation': 'Moses is the traditional author.',
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.textNp, isNull);
      expect(question.hasNepali, isFalse);
      expect(question.textFor(QuizLanguage.nepali), 'Who wrote Genesis?');
    });

    test('finds a renamed Nepali explanation by script', () {
      final model = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 0,
        'explanation': 'Genesis names no human author.',
        'reason_np_text': 'उत्पत्तिले कुनै मानव लेखक उल्लेख गर्दैन।',
      }).toEntity();

      expect(
        model.explanationFor(QuizLanguage.nepali),
        'उत्पत्तिले कुनै मानव लेखक उल्लेख गर्दैन।',
      );
    });

    test('the client time box is a fixed 5 minutes', () {
      // Backend durations are deliberately ignored by the play page so an
      // omitted, zero or unexpected value can no longer leave an attempt
      // untimed or running far too long.
      expect(AppConstants.quizDurationSeconds, 300);
    });

    test('a question with Nepali content reports hasNepali', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Who wrote Genesis?',
            'options': ['Moses', 'David'],
            'textNp': 'लेखक कसले हो?',
            'optionsNp': ['मोसे', 'दाउद'],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.hasNepali, isTrue);
      expect(question.textFor(QuizLanguage.nepali), 'लेखक कसले हो?');
      expect(question.optionsFor(QuizLanguage.nepali), ['मोसे', 'दाउद']);
    });

    test('an English-only question reports no Nepali', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Who wrote Genesis?',
            'options': ['Moses', 'David'],
          },
        ],
      });

      expect(model.toEntity().questions.single.hasNepali, isFalse);
    });

    test('reads Nepali from a per-option bilingual shape', () {
      final model = ActiveQuizModel.fromJson({
        'sessionId': 's-1',
        'questions': [
          {
            'text': 'Pick one',
            'options': [
              {'en': 'Alpha', 'np': 'एल्फा'},
              {'en': 'Beta', 'np': 'बेटा'},
            ],
          },
        ],
      });
      final question = model.toEntity().questions.single;

      expect(question.hasNepali, isTrue);
      expect(question.optionsFor(QuizLanguage.nepali), ['एल्फा', 'बेटा']);
    });
  });

  group('DailyQuizState', () {
    final schedule = QuizScheduleModel.fromJson({
      '_id': 'daily-1',
      'title': 'Daily Quiz',
    }).toEntity();

    test('clearToday removes a previously loaded quiz', () {
      final state = DailyQuizState(
        status: DailyQuizStatus.success,
        today: schedule,
      );

      final cleared = state.copyWith(
        status: DailyQuizStatus.empty,
        clearToday: true,
      );

      expect(cleared.status, DailyQuizStatus.empty);
      expect(cleared.today, isNull);
    });

    test('keeps today and message when they are not provided', () {
      final state = DailyQuizState(
        status: DailyQuizStatus.success,
        today: schedule,
        message: 'boom',
      );

      final updated = state.copyWith(status: DailyQuizStatus.loading);

      expect(updated.today, schedule);
      expect(updated.message, 'boom');
    });
  });

  group('QuizLanguage', () {
    test('fromCode accepts every Nepali alias the backend may send', () {
      for (final code in ['np', 'ne', 'nep', 'nepali', 'NP', ' Nepali ']) {
        expect(QuizLanguage.fromCode(code), QuizLanguage.nepali, reason: code);
      }
    });

    test('fromCode falls back to English for unknown or null values', () {
      for (final code in [null, '', 'fr', 'xyz']) {
        expect(
          QuizLanguage.fromCode(code),
          QuizLanguage.english,
          reason: '$code',
        );
      }
    });
  });

  group('QuizQuestion localisation', () {
    test('uses the Nepali text and options when the backend provides them', () {
      final question = QuizQuestionModel.fromJson({
        'text': 'Who wrote the Book of Romans?',
        'options': ['Paul', 'Peter', 'John', 'James'],
        'textNp': 'रोमनहरू पुस्तक कसले लेखेका हुन्?',
        'optionsNp': ['पत्रुस', 'पत्रुस', 'यूहन्ना', 'याकूब'],
      }).toEntity();

      expect(
        question.textFor(QuizLanguage.nepali),
        'रोमनहरू पुस्तक कसले लेखेका हुन्?',
      );
      expect(question.optionsFor(QuizLanguage.nepali).first, 'पत्रुस');
      expect(
        question.textFor(QuizLanguage.english),
        'Who wrote the Book of Romans?',
      );
    });

    test('falls back to English when no Nepali variant exists', () {
      final question = QuizQuestionModel.fromJson({
        'text': 'Original text',
        'options': ['A', 'B'],
      }).toEntity();

      expect(question.textFor(QuizLanguage.nepali), 'Original text');
      expect(question.optionsFor(QuizLanguage.nepali), ['A', 'B']);
    });

    test('rejects a Nepali option list whose length breaks the answer key', () {
      final question = QuizQuestionModel.fromJson({
        'text': 'English',
        'options': ['A', 'B', 'C'],
        'optionsNp': ['क', 'ख'],
      }).toEntity();

      // Falling back keeps the correct-answer index aligned.
      expect(question.optionsFor(QuizLanguage.nepali), ['A', 'B', 'C']);
    });

    test('accepts the nested { np: { text, options } } shape', () {
      final question = QuizQuestionModel.fromJson({
        'text': 'English',
        'options': ['A', 'B'],
        'np': {
          'text': 'नेपाली',
          'options': ['अ', 'ब'],
        },
      }).toEntity();

      expect(question.textFor(QuizLanguage.nepali), 'नेपाली');
      expect(question.optionsFor(QuizLanguage.nepali), ['अ', 'ब']);
    });
  });

  group('AnswerResult explanation', () {
    test('uses the Nepali explanation when present', () {
      final answer = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 1,
        'explanation': 'Paul wrote Romans.',
        'explanationNp': 'रोमनहरू पत्रुसले लेखेका हुन्।',
        'pointsEarned': 10,
      }).toEntity();

      expect(
        answer.explanationFor(QuizLanguage.nepali),
        'रोमनहरू पत्रुसले लेखेका हुन्।',
      );
      expect(answer.explanationFor(QuizLanguage.english), 'Paul wrote Romans.');
    });

    test('falls back to the English explanation when blank', () {
      final answer = AnswerResultModel.fromJson({
        'isCorrect': true,
        'correctAnswerIndex': 0,
        'explanation': 'Only English here.',
        'explanationNp': '   ',
      }).toEntity();

      expect(answer.explanationFor(QuizLanguage.nepali), 'Only English here.');
    });
  });

  group('QuizSchedule attempts', () {
    test(
      'a daily quiz is always a single attempt even if allowRetry is true',
      () {
        final daily = QuizScheduleModel.fromJson({
          '_id': 'daily-1',
          'title': 'Daily Quiz',
          'allowRetry': true,
          'maxRetries': 5,
          'metadata': {'isDaily': true},
        }).toEntity();

        expect(daily.attemptsAllowed, 1);
      },
    );

    test('a series quiz honours maxRetries but never drops below one', () {
      final retryable = QuizScheduleModel.fromJson({
        '_id': 's-1',
        'title': 'Series',
        'allowRetry': true,
        'maxRetries': 3,
      }).toEntity();
      final zero = QuizScheduleModel.fromJson({
        '_id': 's-2',
        'title': 'Series',
        'allowRetry': true,
        'maxRetries': 0,
      }).toEntity();

      expect(retryable.attemptsAllowed, 3);
      expect(zero.attemptsAllowed, 1);
    });

    test('isActiveAt / isEndedAt bracket the schedule window', () {
      final schedule = QuizSchedule(
        id: 'q',
        title: 'Q',
        startDateTime: DateTime(2026, 9, 25, 10),
        endDateTime: DateTime(2026, 9, 25, 12),
        durationMinutes: 15,
        totalQuestions: 10,
        allowRetry: false,
        maxRetries: 0,
        status: 'active',
      );

      expect(schedule.isActiveAt(DateTime(2026, 9, 25, 11)), isTrue);
      expect(schedule.isActiveAt(DateTime(2026, 9, 25, 9)), isFalse);
      expect(schedule.isEndedAt(DateTime(2026, 9, 25, 13)), isTrue);
      expect(schedule.isEndedAt(DateTime(2026, 9, 25, 11)), isFalse);
    });
  });

  group('QuizState attempt tracking', () {
    test('hasUsedAttempt reflects the marked schedule ids', () {
      const state = QuizState(attemptedScheduleIds: {'daily-1'});

      expect(state.hasUsedAttempt('daily-1'), isTrue);
      expect(state.hasUsedAttempt('daily-2'), isFalse);
    });

    test(
      'copyWith keeps a previous message so start failures stay visible',
      () {
        const state = QuizState(message: 'already completed');

        final updated = state.copyWith(isStarting: true);

        expect(updated.message, 'already completed');
      },
    );

    test('clearMessage wipes the message', () {
      const state = QuizState(message: 'boom');

      expect(state.copyWith(clearMessage: true).message, isNull);
    });

    test('clearActiveQuiz actually removes the active session', () {
      const quiz = ActiveQuiz(
        sessionId: 'session-1',
        durationSeconds: 600,
        questions: [
          QuizQuestion(text: 'Q', options: ['A'], questionIndex: 0),
        ],
      );
      const state = QuizState(activeQuiz: quiz);

      // Regression guard: a plain `activeQuiz: null` could not clear the field
      // because copyWith fell back to `this.activeQuiz`.
      expect(state.copyWith(clearActiveQuiz: true).activeQuiz, isNull);
      expect(state.copyWith().activeQuiz, quiz);
    });
  });

  group('QuizPlayArgs.from', () {
    test('merges schedule metadata the session does not carry', () {
      final schedule = QuizSchedule(
        id: 'daily-1',
        title: 'Daily Quiz',
        startDateTime: DateTime(2026, 9, 25),
        endDateTime: DateTime(2026, 9, 26),
        durationMinutes: 10,
        totalQuestions: 5,
        allowRetry: false,
        maxRetries: 0,
        status: 'active',
        metadata: const {'isDaily': true},
      );
      const session = ActiveQuiz(
        sessionId: 'session-1',
        durationSeconds: 0,
        questions: [
          QuizQuestion(text: 'Q', options: ['A'], questionIndex: 0),
        ],
      );

      final args = QuizPlayArgs.from(
        session,
        schedule: schedule,
        language: QuizLanguage.nepali,
      );

      expect(args.sessionId, 'session-1');
      expect(args.scheduleId, 'daily-1');
      expect(args.title, 'Daily Quiz');
      expect(args.isDaily, isTrue);
      // The session had no duration, so the schedule supplies the timer.
      expect(args.fallbackDurationSeconds, 600);
      expect(args.language, QuizLanguage.nepali);
    });

    test('an empty args object has a blank session id', () {
      expect(const QuizPlayArgs().sessionId, isEmpty);
    });
  });

  group('DailyQuizState single attempt', () {
    final schedule = QuizScheduleModel.fromJson({
      '_id': 'daily-1',
      'title': 'Daily Quiz',
    }).toEntity();

    test('canStart is false once the attempt is used', () {
      final available = DailyQuizState(
        status: DailyQuizStatus.success,
        today: schedule,
      );
      final used = available.copyWith(attemptUsed: true);

      expect(available.canStart, isTrue);
      expect(used.canStart, isFalse);
    });

    test('canStart is false without a loaded quiz', () {
      expect(
        const DailyQuizState(status: DailyQuizStatus.success).canStart,
        isFalse,
      );
    });
  });

  group('QuizSeriesState', () {
    test('deployments flattens every series and drops empty ids', () {
      QuizSchedule deployment(String id) => QuizSchedule(
        id: id,
        title: 'Day $id',
        startDateTime: DateTime(2026, 9, 25),
        endDateTime: DateTime(2026, 9, 26),
        durationMinutes: 10,
        totalQuestions: 5,
        allowRetry: false,
        maxRetries: 0,
        status: 'active',
      );

      const state = QuizSeriesState(
        status: QuizSeriesStatus.success,
        series: [
          QuizSeries(id: 'a', title: 'A', deployments: []),
          QuizSeries(id: 'b', title: 'B', deployments: []),
        ],
      );

      expect(state.deployments, isEmpty);

      final withDeployments = state.copyWith(
        series: [
          const QuizSeries(id: 'a', title: 'A'),
          QuizSeries(
            id: 'b',
            title: 'B',
            deployments: [deployment('d1'), deployment('')],
          ),
        ],
      );

      expect(withDeployments.deployments.map((s) => s.id), ['d1']);
    });
  });

  group('Quiz window gating', () {
    final now = DateTime(2026, 9, 27, 12);
    final schedule = QuizSchedule(
      id: 's1',
      title: 'Daily',
      startDateTime: now.add(const Duration(hours: 3)),
      endDateTime: now.add(const Duration(hours: 9)),
      durationMinutes: 10,
      totalQuestions: 5,
      allowRetry: false,
      maxRetries: 0,
      status: 'scheduled',
    );

    test('is not active before the scheduled start', () {
      expect(schedule.isActiveAt(now), isFalse);
      expect(now.isBefore(schedule.startDateTime), isTrue);
    });

    test('is active inside the window and inactive after it closes', () {
      expect(schedule.isActiveAt(now.add(const Duration(hours: 4))), isTrue);
      expect(
        schedule.isActiveAt(
          schedule.endDateTime.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });
  });

  group('QuizStrings pre-start copy', () {
    test('startsInLabel reports the countdown prefix', () {
      final strings = QuizStrings.of(QuizLanguage.english);

      expect(
        strings.startsInLabel(const Duration(hours: 3)),
        'Starts in 3 h 0 m',
      );
      expect(
        strings.startsInLabel(const Duration(minutes: 20)),
        'Starts in 20 m',
      );
      expect(
        strings.startsInLabel(const Duration(seconds: 42)),
        'Starts in 42 s',
      );
      expect(
        strings.startsInLabel(const Duration(days: 2, hours: 3)),
        'Starts in 2 d 3 h',
      );
    });

    test(
      'startsInLabel falls back to the absolute start time once elapsed',
      () {
        final strings = QuizStrings.of(QuizLanguage.english);
        const elapsed = Duration(minutes: -5);

        expect(strings.startsInLabel(elapsed), strings.startsAt);
      },
    );

    test('both languages expose the pre-start copy', () {
      for (final language in QuizLanguage.values) {
        final strings = QuizStrings.of(language);
        expect(strings.notStartedYet.trim(), isNotEmpty, reason: language.name);
        expect(
          strings.notStartedYetHint.trim(),
          isNotEmpty,
          reason: language.name,
        );
        expect(strings.startsAt.trim(), isNotEmpty, reason: language.name);
      }
    });

    test('English and Nepali pre-start copy is actually different', () {
      final en = QuizStrings.of(QuizLanguage.english);
      final np = QuizStrings.of(QuizLanguage.nepali);

      expect(np.notStartedYet, isNot(en.notStartedYet));
      expect(np.notStartedYetHint, isNot(en.notStartedYetHint));
      expect(
        np.startsInLabel(const Duration(hours: 2)),
        isNot(en.startsInLabel(const Duration(hours: 2))),
      );
    });
  });
}
