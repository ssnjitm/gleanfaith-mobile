import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/features/bible_games/domain/entities/bible_game_entities.dart';
import 'package:glean_faith_app/features/bible_games/domain/services/bible_game_engine.dart';
import 'package:glean_faith_app/features/bible_games/domain/services/bible_game_session.dart';

BibleGameBook _book(
  String name, {
  int chapters = 10,
  required int index,
  String testament = 'Old Testament',
}) {
  return BibleGameBook(
    name: name,
    slug: name.toLowerCase().replaceAll(' ', '-'),
    testament: testament,
    chapterCount: chapters,
    verseCount: 50,
    canonicalIndex: index,
  );
}

final List<BibleGameBook> _books = [
  _book('Genesis', chapters: 50, index: 0),
  _book('Exodus', chapters: 40, index: 1),
  _book('Psalms', chapters: 150, index: 18),
  _book('Amos', chapters: 9, index: 29),
  _book('Matthew', chapters: 28, index: 39, testament: 'New Testament'),
  _book('John', chapters: 21, index: 42, testament: 'New Testament'),
  _book('Revelation', chapters: 22, index: 65, testament: 'New Testament'),
];

void main() {
  group('guessBookRound', () {
    test('returns 4 unique options always including the correct book', () {
      final engine = BibleGameEngine(random: Random(1));
      final round = engine.guessBookRound(
        books: _books,
        verses: const [
          BibleGameVerse(
            book: 'Psalms',
            chapter: 23,
            verse: 1,
            text: 'The LORD is my shepherd; I shall not want.',
          ),
        ],
      );
      expect(round.correctBook, 'Psalms');
      expect(round.options.length, 4);
      expect(round.options.toSet().length, 4);
      expect(round.options, contains('Psalms'));
    });

    test('snippet keeps only the first wordsShown words', () {
      final engine = BibleGameEngine(random: Random(2));
      final round = engine.guessBookRound(
        books: _books,
        wordsShown: 6,
        verses: const [
          BibleGameVerse(
            book: 'Genesis',
            chapter: 1,
            verse: 1,
            text:
                'In the beginning God created the heaven and the earth and the sea',
          ),
        ],
      );
      expect(round.snippet, startsWith('In the beginning God created the'));
      expect(round.correctBook, 'Genesis');
    });
  });

  group('higherLowerRound', () {
    test('picks two distinct books with different chapter counts', () {
      final engine = BibleGameEngine(random: Random(3));
      for (var i = 0; i < 50; i++) {
        final round = engine.higherLowerRound(_books);
        expect(round.left.name, isNot(round.right.name));
        expect(
          round.left.chapterCount,
          isNot(round.right.chapterCount),
        );
        final higher = round.higher;
        expect(
          higher.chapterCount,
          greaterThanOrEqualTo(round.left.chapterCount),
        );
        expect(
          higher.chapterCount,
          greaterThanOrEqualTo(round.right.chapterCount),
        );
        expect(
          higher.name == round.left.name || higher.name == round.right.name,
          isTrue,
        );
      }
    });
  });

  group('bookOrderRound', () {
    test('correctOrder sorts canonically and matches the shuffled set', () {
      final engine = BibleGameEngine(random: Random(4));
      final round = engine.bookOrderRound(_books, numberOfBooks: 5);
      expect(round.shuffledBooks.length, 5);
      final order = round.correctOrder;
      for (var i = 1; i < order.length; i++) {
        expect(order[i].canonicalIndex, greaterThan(order[i - 1].canonicalIndex));
      }
      expect(
        order.map((b) => b.name).toSet(),
        round.shuffledBooks.map((b) => b.name).toSet(),
      );
    });
  });

  group('findChapterRound', () {
    test('grid holds the target exactly once at correctIndex', () {
      final engine = BibleGameEngine(random: Random(5));
      for (var i = 0; i < 20; i++) {
        final round = engine.findChapterRound(_books, gridSize: 16);
        expect(round.options.length, 16);
        expect(round.options.where((o) => o == round.targetLabel).length, 1);
        expect(round.options[round.correctIndex], round.targetLabel);
        expect(round.targetChapter, greaterThan(0));
        expect(
          round.targetChapter,
          lessThanOrEqualTo(
            _books.firstWhere((b) => b.name == round.correctBook).chapterCount,
          ),
        );
      }
    });
  });

  group('funFactRounds', () {
    const extremes = BibleGameExtremes(
      longest: BibleVerseStat(
        reference: 'Esther 8:9',
        length: 534,
        text: 'letters and decrees about the Jews',
      ),
      shortest: BibleVerseStat(
        reference: 'John 11:35',
        length: 11,
        text: 'Jesus wept.',
      ),
    );

    test('every option list contains its correct answer', () {
      final engine = BibleGameEngine(random: Random(6));
      final rounds = engine.funFactRounds(_books, extremes);
      expect(rounds.length, greaterThanOrEqualTo(12));
      for (final round in rounds) {
        expect(round.options, contains(round.correct));
        expect(round.options.toSet().length, round.options.length);
        expect(round.prompt, isNotEmpty);
        expect(round.explain, isNotEmpty);
      }
    });

    test('names Psalms as the book with the most chapters in the fixture', () {
      final engine = BibleGameEngine(random: Random(7));
      final rounds = engine.funFactRounds(_books, extremes);
      final mostRound = rounds.firstWhere((r) => r.prompt.contains('MOST'));
      expect(mostRound.correct, 'Psalms');
    });

    test('facts are deterministic — same data, same order', () {
      final engine = BibleGameEngine(random: Random(1));
      final first = engine.funFactRounds(_books, extremes);
      final second = engine.funFactRounds(_books, extremes);
      expect(first.map((f) => f.prompt), second.map((f) => f.prompt));
      expect(first.map((f) => f.correct), second.map((f) => f.correct));
    });
  });

  group('bookHint', () {
    test('hints by book size without naming the book or its section', () {
      final engine = BibleGameEngine(random: Random(1));
      String hintFor(String name) =>
          engine.bookHint(_books.firstWhere((b) => b.name == name));

      expect(hintFor('Genesis'), 'One of the longer books of the Bible');
      expect(hintFor('Psalms'), 'One of the longer books of the Bible');
      expect(hintFor('Matthew'), 'A mid-sized book');
      expect(hintFor('John'), 'A mid-sized book');
      expect(hintFor('Revelation'), 'A mid-sized book');
      expect(hintFor('Amos'), 'A shorter book');
    });
  });

  test('same seed reproduces identical rounds', () {
    final engineA = BibleGameEngine(random: Random(42));
    final engineB = BibleGameEngine(random: Random(42));
    expect(
      engineA.findChapterRound(_books).options,
      engineB.findChapterRound(_books).options,
    );
    expect(
      engineA.bookOrderRound(_books).shuffledBooks.map((b) => b.name),
      engineB.bookOrderRound(_books).shuffledBooks.map((b) => b.name),
    );
  });

  group('GameSession', () {
    test('fresh sessions get different seeds so rounds differ per open', () {
      final sessionA = GameSession(seed: 1);
      final sessionB = GameSession(seed: 2);
      expect(sessionA.seed, isNot(sessionB.seed));
      expect(sessionA.seedForRound(0), isNot(sessionB.seedForRound(0)));
    });

    test('seedForRound is stable per session and varies across rounds', () {
      final session = GameSession(seed: 99);
      expect(session.seedForRound(3), session.seedForRound(3));
      expect(session.seedForRound(2), isNot(session.seedForRound(3)));
    });

    test('registerResult tracks score and streaks', () {
      final session = GameSession(seed: 7);
      session.registerResult(correct: true, points: 10);
      session.registerResult(correct: true, points: 10);
      session.registerResult(correct: false, points: 0);
      session.registerResult(correct: true, points: 10);
      expect(session.roundIndex, 4);
      expect(session.score, 30);
      expect(session.streak, 1);
      expect(session.bestStreak, 2);
    });

    test('advanceRound false does not increment roundIndex', () {
      final session = GameSession(seed: 7);
      session.registerResult(correct: true, points: 10, advanceRound: false);
      session.registerResult(correct: true, points: 10, advanceRound: false);
      expect(session.roundIndex, 0);
      expect(session.score, 20);
      expect(session.streak, 2);
    });
  });
}