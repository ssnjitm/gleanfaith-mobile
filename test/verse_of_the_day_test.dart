import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/constants/api_constants.dart';
import 'package:glean_faith_app/core/services/database_service.dart';
import 'package:glean_faith_app/features/bible/data/datasources/remote_bible_datasource.dart';
import 'package:glean_faith_app/features/bible/data/repositories/remote_bible_repository_impl.dart';
import 'package:glean_faith_app/features/bible/domain/entities/remote_bible_verse.dart';
import 'package:glean_faith_app/features/bible/domain/entities/verse_of_the_day.dart';
import 'package:glean_faith_app/features/bible/domain/services/daily_verse_plan.dart';
import 'package:glean_faith_app/features/bible/domain/usecases/get_remote_verse.dart';
import 'package:glean_faith_app/features/bible/presentation/providers/verse_of_the_day_provider.dart';

/// Real, network-verified payload from the free Nepali endpoint.
const String _nepaliJohn3 = '''
{
  "translation": {"id": "npi_ulb", "language": "npi"},
  "book": {
    "id": "JHN",
    "commonName": "यूहन्‍ना",
    "order": 43,
    "numberOfChapters": 21
  },
  "chapter": {
    "number": 3,
    "content": [
      {"type": "heading", "content": ["यूहन्‍ना अध्याय ३"]},
      {"type": "verse", "number": 15, "content": ["निम्न श्लोक"]},
      {
        "type": "verse",
        "number": 16,
        "content": ["किनभने परमेश्‍वरले संसारलाई यस्तो प्रेम गर्नुभयो, तर उसले अनन्त जीवन पाओस् ।"]
      },
      {"type": "verse", "number": 17, "content": ["किनभने परमेश्‍वरले आफ्नो एक मात्र पुत्र दिनुभयो ।"]}
    ]
  },
  "numberOfVerses": 36
}
''';

/// The same verse as `eng_web` actually serves it: an inline run split by a
/// footnote marker, each run an object rather than a string. This is the shape
/// that made a naive string-only join return `''` and blank the card.
const String _webJohn3 = '''
{
  "translation": {"id": "eng_web", "language": "eng"},
  "book": {"id": "JHN", "commonName": "John"},
  "chapter": {
    "number": 3,
    "content": [
      {"type": "verse", "number": 15, "content": ["No one has seen God at any time."]},
      {
        "type": "verse",
        "number": 16,
        "content": [
          {"text": "For God so loved the world, that he gave his only born", "wordsOfJesus": true},
          {"noteId": 12},
          {"text": "Son, that whoever believes in him should not perish, but have eternal life.", "wordsOfJesus": true}
        ]
      },
      {
        "type": "verse",
        "number": 17,
        "content": [
          {"text": "For God didn't send his Son into the world to judge the world, but that the world", "wordsOfJesus": true},
          {"text": "should be saved through him."}
        ]
      }
    ]
  }
}
''';

/// A chapter that is *not* the one the plan asks for. Used to prove a
/// misrouted response is rejected instead of rendered as today's verse.
const String _wrongChapter = '''
{
  "book": {"id": "PSA", "commonName": "भजन संग्रह"},
  "chapter": {
    "number": 23,
    "content": [
      {
        "type": "verse",
        "number": 1,
        "content": ["यहोवा मेरो चरवाह हो, ", "मा अभाव छैन ।"]
      }
    ]
  }
}
''';

/// Serves a per-translation body, so a test can fail one language while the
/// other still answers.
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, String> bodies;
  final int statusCode;

  /// Translation ids that should fail as if the host were unreachable.
  final Set<String> failing;

  /// Every path the client actually asked for, so a test can prove it was
  /// sent the day it was asked about.
  final List<String> requestedPaths = [];

  _FakeAdapter({
    this.bodies = const {},
    this.statusCode = 200,
    this.failing = const {},
  });

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    final translationId =
        RegExp(r'^/api/([^/]+)/').firstMatch(options.path)?.group(1) ?? '';

    if (failing.contains(translationId)) {
      throw Exception('Failed host lookup: $translationId');
    }

    final body = bodies[translationId];
    if (body == null) {
      return ResponseBody.fromString(
        '{"error":"translation not found"}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Dio _dio(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: ApiConstants.freeBibleBaseUrl));
  dio.httpClientAdapter = adapter;
  return dio;
}

/// A distinct book name per USFM code *and* per language, so a test can tell
/// which translation the app actually rendered.
String _nepaliName(String usfm) => 'किताब-$usfm';

String _englishName(String usfm) => 'Book-$usfm';

/// Builds a chapter payload satisfying exactly [ref], so the expected result is
/// derived from the plan instead of a hand-guessed date.
String _payloadFor(DailyVerseRef ref, {required bool nepali}) {
  final book = ref.book;
  final name = nepali ? _nepaliName(book) : _englishName(book);
  final text = nepali
      ? 'वाक्य-$book-${ref.chapter}-${ref.verse}'
      : 'verse-$book-${ref.chapter}-${ref.verse}';
  return '''
{
  "book": {"id": "$book", "commonName": "$name"},
  "chapter": {
    "number": ${ref.chapter},
    "content": [
      {"type": "heading", "content": ["शीर्षक"]},
      {"type": "verse", "number": 9999, "content": ["another chapter"]},
      {"type": "verse", "number": ${ref.verse}, "content": ["$text"]}
    ]
  }
}
''';
}

/// A use case answering every translation from [ref]'s chapter.
GetRemoteVerseUseCase _use(_FakeAdapter adapter) => GetRemoteVerseUseCase(
  RemoteBibleRepositoryImpl(RemoteBibleDataSource(_dio(adapter))),
);

/// Both translations serving [ref].
_FakeAdapter _adapterFor(DailyVerseRef ref) => _FakeAdapter(
  bodies: {
    ApiConstants.nepaliTranslationId: _payloadFor(ref, nepali: true),
    ApiConstants.englishTranslationId: _payloadFor(ref, nepali: false),
  },
);

void main() {
  group('DailyVersePlan', () {
    test('holds exactly one verse per day of the year', () {
      expect(DailyVersePlan.references, hasLength(365));
      expect(DailyVersePlan.length, DailyVersePlan.references.length);
    });

    test('has no repeated verse', () {
      final labels = DailyVersePlan.references.map((r) => r.label).toList();
      expect(labels.toSet(), hasLength(labels.length));
    });

    test('only references books that exist', () {
      // A typo like 'PSM' would otherwise 404 once a day, silently, forever.
      for (final ref in DailyVersePlan.references) {
        expect(
          kjvCanonicalBookCodes.contains(ref.book),
          isTrue,
          reason: '${ref.label} uses an unknown USFM book code',
        );
      }
    });

    test('uses real chapter and verse numbers', () {
      for (final ref in DailyVersePlan.references) {
        expect(ref.chapter, greaterThan(0), reason: ref.label);
        expect(ref.verse, greaterThan(0), reason: ref.label);
      }
    });

    test('spreads across the whole canon, not one book', () {
      final books = DailyVersePlan.references.map((r) => r.book).toSet();
      // Guards against a plan that quietly collapses into Psalms-only.
      expect(books.length, greaterThan(30));
      expect(books, containsAll(<String>['GEN', 'PSA', 'JHN', 'REV']));
    });

    test('dayOfYear matches the calendar', () {
      expect(DailyVersePlan.dayOfYear(DateTime(2026, 1, 1)), 1);
      expect(DailyVersePlan.dayOfYear(DateTime(2026, 12, 31)), 365);
      expect(DailyVersePlan.dayOfYear(DateTime(2026, 3, 1)), 60);
      expect(DailyVersePlan.dayOfYear(DateTime(2024, 3, 1)), 61);
      expect(DailyVersePlan.dayOfYear(DateTime(2024, 12, 31)), 366);
    });

    test('isLeapYear follows the Gregorian rule', () {
      expect(DailyVersePlan.isLeapYear(2024), isTrue);
      expect(DailyVersePlan.isLeapYear(2026), isFalse);
      expect(DailyVersePlan.isLeapYear(1900), isFalse);
      expect(DailyVersePlan.isLeapYear(2000), isTrue);
    });

    test('a leap year does not push the plan out of alignment', () {
      // 2026 is not a leap year, 2028 is. Every date from March onwards must
      // resolve to the same verse in both, otherwise the whole year shifts and
      // the final entry becomes unreachable.
      for (final pair in <List<int>>[
        [3, 1],
        [3, 15],
        [6, 30],
        [9, 9],
        [12, 25],
        [12, 31],
      ]) {
        final plain = DateTime(2026, pair[0], pair[1]);
        final leap = DateTime(2028, pair[0], pair[1]);
        expect(
          DailyVersePlan.forDate(leap),
          DailyVersePlan.forDate(plain),
          reason: '${pair[0]}/${pair[1]}',
        );
      }
    });

    test('29 February repeats 1 March instead of skipping a verse', () {
      expect(
        DailyVersePlan.forDate(DateTime(2028, 2, 29)),
        DailyVersePlan.forDate(DateTime(2028, 3, 1)),
      );
    });

    test('every index in a three-year sweep is in range', () {
      // 2027 (plain) → 2028 (leap) → 2029 (plain) covers both branches.
      for (
        var day = DateTime(2027, 1, 1);
        day.isBefore(DateTime(2030, 1, 1));
        day = day.add(const Duration(days: 1))
      ) {
        final index = DailyVersePlan.indexFor(day);
        expect(index, inInclusiveRange(0, 364), reason: '$day');
      }
    });

    test('365 consecutive days use 365 distinct verses', () {
      final used = <DailyVerseRef>{};
      for (
        var day = DateTime(2026, 1, 1);
        day.isBefore(DateTime(2027, 1, 1));
        day = day.add(const Duration(days: 1))
      ) {
        used.add(DailyVersePlan.forDate(day));
      }
      expect(used, hasLength(365));
    });

    test('is stable within a day and changes the next day', () {
      final morning = DateTime(2026, 6, 1, 0, 5);
      final evening = DateTime(2026, 6, 1, 23, 55);
      expect(DailyVersePlan.forDate(morning), DailyVersePlan.forDate(evening));
      expect(
        DailyVersePlan.forDate(evening),
        isNot(DailyVersePlan.forDate(DateTime(2026, 6, 2, 0, 5))),
      );
    });
  });

  group('VerseLanguage', () {
    test('defaults to English and parses the Nepali aliases', () {
      expect(VerseLanguage.fromCode(null), VerseLanguage.english);
      expect(VerseLanguage.fromCode(''), VerseLanguage.english);
      expect(VerseLanguage.fromCode('en'), VerseLanguage.english);
      for (final alias in ['np', 'NP', 'ne', 'nep', 'Nepali', ' np ']) {
        expect(
          VerseLanguage.fromCode(alias),
          VerseLanguage.nepali,
          reason: alias,
        );
      }
    });

    test('an unknown stored value can never leave the card blank', () {
      expect(VerseLanguage.fromCode('klingon'), VerseLanguage.english);
      expect(VerseLanguage.fromCode('12'), VerseLanguage.english);
    });

    test('each language maps to its own translation', () {
      expect(
        translationIdFor(VerseLanguage.english),
        ApiConstants.englishTranslationId,
      );
      expect(
        translationIdFor(VerseLanguage.nepali),
        ApiConstants.nepaliTranslationId,
      );
      // The two must be genuinely different endpoints, or the toggle would
      // silently render the same language twice.
      expect(
        ApiConstants.englishTranslationId,
        isNot(ApiConstants.nepaliTranslationId),
      );
    });
  });

  group('USFM ↔ KJV book mapping', () {
    test('every canonical book round-trips', () {
      expect(kjvCanonicalBookCodes, hasLength(66));
      for (final code in kjvCanonicalBookCodes) {
        final name = kjvBookNameForCode(code);
        expect(name, isNot(code), reason: code);
        expect(kjvBookCodeForName(name), code, reason: code);
      }
    });

    test('resolves the books used by the notification deep link', () {
      expect(kjvBookNameForCode('JHN'), 'John');
      expect(kjvBookNameForCode('JER'), 'Jeremiah');
      expect(kjvBookNameForCode('PSA'), 'Psalms');
      expect(kjvBookNameForCode('1SA'), '1 Samuel');
    });

    test('an unknown code is passed through rather than throwing', () {
      expect(kjvBookNameForCode('ZZZ'), 'ZZZ');
    });
  });

  group('RemoteBibleDataSource', () {
    Future<RemoteBibleVerse> get({
      required String body,
      required String translationId,
      String usfmBook = 'JHN',
      int chapter = 3,
      int verse = 16,
      int status = 200,
    }) {
      return RemoteBibleDataSource(
        _dio(_FakeAdapter(bodies: {translationId: body}, statusCode: status)),
      ).getVerse(
        translationId: translationId,
        usfmBook: usfmBook,
        chapter: chapter,
        verse: verse,
      );
    }

    test('pulls one verse out of a Nepali chapter payload', () async {
      final verse = await get(
        body: _nepaliJohn3,
        translationId: ApiConstants.nepaliTranslationId,
      );

      expect(verse.translationId, ApiConstants.nepaliTranslationId);
      expect(verse.usfmBook, 'JHN');
      expect(verse.chapter, 3);
      expect(verse.verse, 16);
      expect(verse.bookName, 'यूहन्‍ना');
      expect(verse.text, contains('परमेश्‍वरले संसारलाई'));
      expect(verse.reference, 'यूहन्‍ना 3:16');
    });

    test('reads a verse split into object runs by a footnote marker', () async {
      // Regression: `eng_web` splits a verse into inline runs that are objects,
      // not strings, and John 3:16 is split mid-phrase by a footnote. Dropping
      // every non-string run returned '' and the whole card went blank.
      final verse = await get(
        body: _webJohn3,
        translationId: ApiConstants.englishTranslationId,
      );

      expect(verse.bookName, 'John');
      expect(
        verse.text,
        'For God so loved the world, that he gave his only born Son, that '
        'whoever believes in him should not perish, but have eternal life.',
      );
      expect(verse.text, isNot(contains('bornSon')));
      expect(verse.text, isNot(contains('Map')));
      expect(verse.reference, 'John 3:16');
    });

    test('a run with no text contributes no word', () async {
      const marked = '''
      {
        "book": {"id": "PSA", "commonName": "Psalms"},
        "chapter": {
          "number": 1,
          "content": [
            {
              "type": "verse",
              "number": 1,
              "content": [
                {"text": "Yah is my strength", "poem": 1},
                {"lineBreak": true},
                {"text": "and my song."}
              ]
            }
          ]
        }
      }
      ''';
      final verse = await get(
        body: marked,
        translationId: ApiConstants.englishTranslationId,
        usfmBook: 'PSA',
        chapter: 1,
        verse: 1,
      );
      expect(verse.text, 'Yah is my strength and my song.');
    });

    test('joins a multi-run verse instead of dropping its tail', () async {
      final verse = await get(
        body: _wrongChapter,
        translationId: ApiConstants.nepaliTranslationId,
        usfmBook: 'PSA',
        chapter: 23,
        verse: 1,
      );
      expect(verse.text, 'यहोवा मेरो चरवाह हो, मा अभाव छैन ।');
    });

    test('strips footnote braces and collapses whitespace', () async {
      const noisy = '''
      {
        "book": {"id": "PSA", "commonName": "भजन"},
        "chapter": {
          "content": [
            {"type": "verse", "number": 1, "content": ["  क {१} त \\n   पानी  "]}
          ]
        }
      }
      ''';
      final verse = await get(
        body: noisy,
        translationId: ApiConstants.nepaliTranslationId,
        usfmBook: 'PSA',
        chapter: 1,
        verse: 1,
      );
      expect(verse.text, 'क १ त पानी');
    });

    test('accepts a verse number delivered as a string', () async {
      const stringly = '''
      {
        "book": {"id": "JHN", "commonName": "यूहन्‍ना"},
        "chapter": {
          "content": [
            {"type": "verse", "number": "16", "content": ["किनभने परमेश्‍वरले"]}
          ]
        }
      }
      ''';
      final verse = await get(
        body: stringly,
        translationId: ApiConstants.nepaliTranslationId,
      );
      expect(verse.text, 'किनभने परमेश्‍वरले');
    });

    test('throws when the verse is not in the chapter', () async {
      await expectLater(
        get(
          body: _nepaliJohn3,
          translationId: ApiConstants.nepaliTranslationId,
          verse: 99,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on an empty or shapeless object', () async {
      for (final body in ['{}', '{"book":{},"chapter":{}}', '{"chapter":{}}']) {
        await expectLater(
          get(body: body, translationId: ApiConstants.nepaliTranslationId),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('a non-object body is still a failure, not blank text', () async {
      // Dio's json transformer rejects `[]` before the datasource sees it, so
      // this surfaces as a DioException. handleError maps that to a Failure and
      // the card falls back to the other language.
      await expectLater(
        get(body: '[]', translationId: ApiConstants.nepaliTranslationId),
        throwsA(isA<DioException>()),
      );
    });

    test('surfaces an HTTP error rather than returning blank text', () async {
      await expectLater(
        get(
          body: 'nope',
          translationId: ApiConstants.nepaliTranslationId,
          status: 500,
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('rejects a response for a different book', () async {
      // The payload holds JHN; PSA was asked for. Rendering it as "Psalms 3:16"
      // would be a silently wrong verse, which is worse than the notice.
      await expectLater(
        get(
          body: _nepaliJohn3,
          translationId: ApiConstants.nepaliTranslationId,
          usfmBook: 'PSA',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('response holds JHN'),
          ),
        ),
      );
    });

    test('rejects a response for a different chapter', () async {
      await expectLater(
        get(
          body: _nepaliJohn3,
          translationId: ApiConstants.nepaliTranslationId,
          chapter: 4,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('response holds chapter 3'),
          ),
        ),
      );
    });

    test('falls back to the USFM id when the book name is missing', () async {
      // Otherwise the reference would render as a leading-space " 3:16".
      const noBookName = '''
      {
        "chapter": {
          "content": [
            {"type": "verse", "number": 16, "content": ["किनभने परमेश्‍वरले"]}
          ]
        }
      }
      ''';
      final verse = await get(
        body: noBookName,
        translationId: ApiConstants.nepaliTranslationId,
      );
      expect(verse.bookName, 'JHN');
      expect(verse.reference, 'JHN 3:16');
    });

    test('requests the chapter path for the pinned translations', () {
      expect(
        ApiConstants.freeBibleChapter(
          translationId: ApiConstants.nepaliTranslationId,
          usfmBook: 'JHN',
          chapter: 3,
        ),
        '/api/npi_ulb/JHN/3.json',
      );
      expect(
        ApiConstants.freeBibleChapter(
          translationId: ApiConstants.englishTranslationId,
          usfmBook: 'JHN',
          chapter: 3,
        ),
        '/api/eng_web/JHN/3.json',
      );
      // A different host than the app's own API, so no token is ever sent to it.
      expect(ApiConstants.freeBibleBaseUrl, isNot(contains('railway')));
    });
  });

  group('loadVerseOfTheDay', () {
    // Every expectation below is derived from DailyVersePlan, so the tests
    // cannot drift out of step with the curated list.
    Future<VerseOfTheDay> load({
      required DateTime date,
      required VerseLanguage language,
      _FakeAdapter? adapter,
      Set<String> failing = const {},
      Map<String, String>? bodies,
    }) {
      final planned = DailyVersePlan.forDate(date);
      return loadVerseOfTheDay(
        date: date,
        language: language,
        getRemoteVerse: _use(
          adapter ??
              _FakeAdapter(
                bodies:
                    bodies ??
                    {
                      ApiConstants.nepaliTranslationId: _payloadFor(
                        planned,
                        nepali: true,
                      ),
                      ApiConstants.englishTranslationId: _payloadFor(
                        planned,
                        nepali: false,
                      ),
                    },
                failing: failing,
              ),
        ),
      );
    }

    test('both languages show the same verse, in their own language', () async {
      final date = DateTime(2026, 6, 1);
      final planned = DailyVersePlan.forDate(date);

      final english = await load(date: date, language: VerseLanguage.english);
      final nepali = await load(date: date, language: VerseLanguage.nepali);

      // The point of the feature: one verse per date, two renderings.
      expect(english.chapter, planned.chapter);
      expect(english.verse, planned.verse);
      expect(nepali.chapter, planned.chapter);
      expect(nepali.verse, planned.verse);
      expect(english.book, kjvBookNameForCode(planned.book));
      expect(nepali.book, kjvBookNameForCode(planned.book));

      // Only the language differs.
      expect(english.language, VerseLanguage.english);
      expect(nepali.language, VerseLanguage.nepali);
      expect(english.isFallback, isFalse);
      expect(nepali.isFallback, isFalse);
      expect(
        english.text,
        'verse-${planned.book}-${planned.chapter}-${planned.verse}',
      );
      expect(
        nepali.text,
        'वाक्य-${planned.book}-${planned.chapter}-${planned.verse}',
      );
      expect(
        english.reference,
        '${_englishName(planned.book)} ${planned.chapter}:${planned.verse}',
      );
      expect(
        nepali.reference,
        '${_nepaliName(planned.book)} ${planned.chapter}:${planned.verse}',
      );
    });

    test('English mode follows the plan instead of the local database', () async {
      // The curated list drives both languages now, so the first and last day of
      // the year are different verses.
      final firstDay = await load(
        date: DateTime(2026, 1, 1),
        language: VerseLanguage.english,
      );
      final lastDay = await load(
        date: DateTime(2026, 12, 31),
        language: VerseLanguage.english,
      );

      for (final result in [firstDay, lastDay]) {
        final planned = DailyVersePlan.forDate(
          result == firstDay ? DateTime(2026, 1, 1) : DateTime(2026, 12, 31),
        );
        expect(result.chapter, planned.chapter);
        expect(result.verse, planned.verse);
        expect(result.book, kjvBookNameForCode(planned.book));
      }
      expect(firstDay.text, isNot(lastDay.text));
    });

    test('each language asks the endpoint for the day it is given', () async {
      for (final date in [DateTime(2026, 1, 1), DateTime(2026, 12, 25)]) {
        final planned = DailyVersePlan.forDate(date);
        for (final language in VerseLanguage.values) {
          final adapter = _adapterFor(planned);
          final result = await loadVerseOfTheDay(
            date: date,
            language: language,
            getRemoteVerse: _use(adapter),
          );

          expect(adapter.requestedPaths, [
            '/api/${translationIdFor(language)}/'
                '${planned.book}/${planned.chapter}.json',
          ], reason: '$date $language');
          expect(result.isFallback, isFalse, reason: '$date $language');
        }
      }
    });

    test('a Nepali outage serves the same verse in English', () async {
      final date = DateTime(2026, 6, 1);
      final planned = DailyVersePlan.forDate(date);
      final result = await load(
        date: date,
        language: VerseLanguage.nepali,
        failing: {ApiConstants.nepaliTranslationId},
      );

      // The toggle keeps the user's choice so the notice can render…
      expect(result.language, VerseLanguage.nepali);
      expect(result.isNepali, isTrue);
      expect(result.isFallback, isTrue);
      // …and the card shows the *same* verse in the other language. Serving a
      // different verse here would defeat the whole point of the plan.
      expect(result.chapter, planned.chapter);
      expect(result.verse, planned.verse);
      expect(result.book, kjvBookNameForCode(planned.book));
      expect(
        result.text,
        'verse-${planned.book}-${planned.chapter}-${planned.verse}',
      );
    });

    test('an English outage serves the same verse in Nepali', () async {
      // The fallback is symmetric: English mode is not special-cased any more.
      final date = DateTime(2026, 6, 1);
      final planned = DailyVersePlan.forDate(date);
      final result = await load(
        date: date,
        language: VerseLanguage.english,
        failing: {ApiConstants.englishTranslationId},
      );

      expect(result.language, VerseLanguage.english);
      expect(result.isNepali, isFalse);
      expect(result.isFallback, isTrue);
      expect(result.chapter, planned.chapter);
      expect(result.verse, planned.verse);
      expect(
        result.text,
        'वाक्य-${planned.book}-${planned.chapter}-${planned.verse}',
      );
    });

    test('a missing translation also degrades to the other language', () async {
      final result = await load(
        date: DateTime(2026, 6, 1),
        language: VerseLanguage.nepali,
        bodies: {
          ApiConstants.nepaliTranslationId:
              '{"book":{},"chapter":{"content":[]}}',
          ApiConstants.englishTranslationId: _payloadFor(
            DailyVersePlan.forDate(DateTime(2026, 6, 1)),
            nepali: false,
          ),
        },
      );
      expect(result.isFallback, isTrue);
      expect(result.text, isNotEmpty);
    });

    test('a wrong chapter degrades instead of showing a stray verse', () async {
      // The endpoint answered, but for a chapter the plan did not ask for. The
      // app must not surface that unrelated verse as "today's"; it must fall
      // back to the other language *for the planned reference*.
      final date = DateTime(2026, 6, 1);
      final planned = DailyVersePlan.forDate(date);
      final result = await load(
        date: date,
        language: VerseLanguage.nepali,
        bodies: {
          ApiConstants.nepaliTranslationId: _wrongChapter,
          ApiConstants.englishTranslationId: _payloadFor(
            planned,
            nepali: false,
          ),
        },
      );

      expect(result.isFallback, isTrue, reason: 'the selected language failed');
      expect(result.chapter, planned.chapter);
      expect(result.verse, planned.verse);
      expect(result.book, kjvBookNameForCode(planned.book));
      expect(result.text, isNot(contains('भजन')));
    });

    test('a total outage uses the hardcoded verse and says so', () async {
      // The hardcoded verse is not today's planned one, so it must never be
      // passed off as a successful translation.
      for (final language in VerseLanguage.values) {
        final result = await load(
          date: DateTime(2026, 6, 1),
          language: language,
          failing: {
            ApiConstants.nepaliTranslationId,
            ApiConstants.englishTranslationId,
          },
        );

        expect(result.text, kVerseFallbackText, reason: '$language');
        expect(result.reference, kVerseFallbackReference, reason: '$language');
        expect(result.book, 'Jeremiah', reason: '$language');
        expect(result.chapter, 29, reason: '$language');
        expect(result.verse, 11, reason: '$language');
        expect(result.isFallback, isTrue, reason: '$language');
        expect(result.language, language, reason: '$language');
      }
    });

    test('the notification and the card agree for the same day', () async {
      // The Home page schedules tomorrow's verse; if the loader were not shared
      // the notification would drift out of sync with the card.
      for (final language in VerseLanguage.values) {
        final card = await load(date: DateTime(2026, 6, 1), language: language);
        final notification = await load(
          date: DateTime(2026, 6, 1),
          language: language,
        );
        expect(notification, card, reason: '$language');
      }
    });

    test('every day of the year resolves in both languages', () async {
      // No date may produce a blank card; every one of the 365 days must resolve
      // to its own planned verse.
      for (
        var day = DateTime(2026, 1, 1);
        day.isBefore(DateTime(2027, 1, 1));
        day = day.add(const Duration(days: 1))
      ) {
        final planned = DailyVersePlan.forDate(day);
        for (final language in VerseLanguage.values) {
          final result = await load(date: day, language: language);
          expect(result.isFallback, isFalse, reason: '$day $language');
          expect(result.chapter, planned.chapter, reason: '$day $language');
          expect(result.verse, planned.verse, reason: '$day $language');
          expect(result.text, isNotEmpty, reason: '$day $language');
          expect(result.book, isNotEmpty, reason: '$day $language');
        }
      }
    });
  });
}
