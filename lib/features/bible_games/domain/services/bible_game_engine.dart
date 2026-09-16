import 'dart:math';

import '../entities/bible_game_entities.dart';

/// Pure, seedable generator for every Bible game round.
///
/// Construct with a fixed `Random(seed)` in tests (and for daily-sync games) so
/// a full run is reproducible. The engine never touches Flutter, Riverpod, the
/// database or fpdart — callers feed it the data bundles they already loaded.
class BibleGameEngine {
  BibleGameEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  int pickFrom(int max) => _random.nextInt(max);

  T pick<T>(List<T> list) => list[pickFrom(list.length)];

  List<T> shuffled<T>(List<T> list) {
    final copy = [...list];
    for (var i = copy.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }

  /// Returns up to [n] distinct random elements from [source], optionally
  /// filtered by [where].
  List<T> sample<T>(List<T> source, int n, {bool Function(T)? where}) {
    final pool = where == null ? source : source.where(where).toList();
    if (pool.isEmpty) return const [];
    final count = n < pool.length ? n : pool.length;
    return shuffled(pool).take(count).toList();
  }

  /// Guess the Book — show the complete [verse] and offer four book options
  /// (distractors prefer the same testament so the game is fair, not trivially
  /// resolved by testament). A non-revealing genre hint helps narrow the field.
  GuessBookRound guessBookRound({
    required List<BibleGameBook> books,
    required List<BibleGameVerse> verses,
    int wordsShown = 8,
  }) {
    final verse = pick(verses);
    final correct = books.firstWhere(
      (b) => b.name == verse.book,
      orElse: () => books.first,
    );
    final sameTestament = sample(
      books,
      3,
      where: (b) => b.name != correct.name && b.testament == correct.testament,
    );
    final distractors = sameTestament.length >= 3
        ? sameTestament
        : sample(books, 3, where: (b) => b.name != correct.name);
    final options = shuffled([correct.name, ...distractors.map((b) => b.name)]);
    final words = verse.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final shown = words.take(wordsShown);
    return GuessBookRound(
      snippet: '${shown.join(' ')}${words.length > wordsShown ? ' …' : ''}',
      fullText: verse.text,
      reference: verse.formattedReference,
      correctBook: correct.name,
      options: options,
      wordsShown: wordsShown,
      hint: bookHint(correct),
    );
  }

  /// A gentle, non-revealing hint about a book's genre/section — enough to
  /// help pick between options without naming the answer.
  String bookHint(BibleGameBook book) {
    final index = book.canonicalIndex;
    if (book.testament != 'Old Testament') {
      if (index <= 42) return 'New Testament · the Gospels';
      if (index == 43) return 'New Testament · Acts';
      if (index <= 56) return 'New Testament · Paul’s letters';
      if (index <= 64) return 'New Testament · General letters';
      return 'New Testament · Revelation';
    }
    if (index <= 4) return 'Old Testament · the Law (Pentateuch)';
    if (index <= 15) return 'Old Testament · History';
    if (index <= 20) return 'Old Testament · Poetry & Wisdom';
    if (index <= 25) return 'Old Testament · Major Prophets';
    return 'Old Testament · Minor Prophets';
  }

  /// Higher / Lower — two distinct books with different chapter counts; the
  /// player taps the one with more chapters.
  HigherLowerRound higherLowerRound(List<BibleGameBook> books) {
    var left = pick(books);
    var right = pick(books);
    var attempts = 0;
    while ((left.name == right.name || left.chapterCount == right.chapterCount) &&
        attempts < 50) {
      left = pick(books);
      right = pick(books);
      attempts++;
    }
    return HigherLowerRound(left: left, right: right);
  }

  /// Book Order Race — [numberOfBooks] random books, displayed shuffled; the
  /// player must tap them in canonical order.
  BookOrderRound bookOrderRound(
    List<BibleGameBook> books, {
    int numberOfBooks = 5,
  }) {
    final chosen = sample(books, numberOfBooks);
    return BookOrderRound(shuffledBooks: shuffled(chosen));
  }

  /// Find the Chapter — tap the tile holding the target "book chapter" on a
  /// [gridSize]-tile grid. Distractors are real book/chapter combos.
  FindChapterRound findChapterRound(
    List<BibleGameBook> books, {
    int gridSize = 16,
  }) {
    final targetBook = pick(books);
    final targetChapter = pickFrom(targetBook.chapterCount) + 1;
    final targetLabel = '${targetBook.name} $targetChapter';
    final tiles = <String>{targetLabel};
    var guard = 0;
    while (tiles.length < gridSize && guard < 300) {
      guard++;
      final book = pick(books);
      final chapter = pickFrom(book.chapterCount) + 1;
      tiles.add('${book.name} $chapter');
    }
    final options = shuffled(tiles.toList());
    return FindChapterRound(
      targetLabel: targetLabel,
      correctBook: targetBook.name,
      targetChapter: targetChapter,
      options: options,
      correctIndex: options.indexOf(targetLabel),
    );
  }

  /// Fun Facts — a stable set of trivia rounds generated from real data.
  List<FunFactRound> funFactRounds(
    List<BibleGameBook> books,
    BibleGameExtremes extremes,
  ) {
    final mostChapters = books.reduce(
      (a, b) => a.chapterCount > b.chapterCount ? a : b,
    );
    final oneChapter = books.where((b) => b.chapterCount == 1).toList();
    final fewestChapters = pick(oneChapter.isEmpty ? books : oneChapter);

    final referenceDistractors = _distractorReferences(books).toSet().toList();

    return [
      FunFactRound(
        prompt: 'Which verse is the LONGEST in the Bible?',
        correct: extremes.longest.reference,
        options: shuffled(
          [
            extremes.longest.reference,
            ...referenceDistractors.where(
              (r) => r != extremes.longest.reference,
            ),
          ],
        ),
        explain:
            '${extremes.longest.reference} has ${extremes.longest.length} '
            'characters.',
      ),
      FunFactRound(
        prompt: 'Which verse is the SHORTEST in the Bible?',
        correct: extremes.shortest.reference,
        options: shuffled(
          [
            extremes.shortest.reference,
            ...referenceDistractors.where(
              (r) => r != extremes.shortest.reference,
            ),
          ],
        ),
        explain:
            '"${extremes.shortest.text}" — ${extremes.shortest.reference} '
            '(${extremes.shortest.length} characters).',
      ),
      FunFactRound(
        prompt: 'Which book has the MOST chapters?',
        correct: mostChapters.name,
        options: shuffled(
          [mostChapters.name, ..._bookDistractors(books, mostChapters.name)],
        ),
        explain: '${mostChapters.name} has ${mostChapters.chapterCount} '
            'chapters.',
      ),
      FunFactRound(
        prompt: 'Which book has the FEWEST chapters?',
        correct: fewestChapters.name,
        options: shuffled(
          [
            fewestChapters.name,
            ..._bookDistractors(books, fewestChapters.name),
          ],
        ),
        explain: '${fewestChapters.name} has ${fewestChapters.chapterCount} '
            'chapter${fewestChapters.chapterCount == 1 ? '' : 's'}.',
      ),
    ];
  }

  List<String> _bookDistractors(List<BibleGameBook> books, String avoid) {
    return sample(books, 3, where: (b) => b.name != avoid)
        .map((b) => b.name)
        .toList();
  }

  List<String> _distractorReferences(List<BibleGameBook> books) {
    final refs = <String>{};
    var guard = 0;
    while (refs.length < 4 && guard < 100) {
      guard++;
      final book = pick(books);
      final chapter = pickFrom(book.chapterCount) + 1;
      final verse = pickFrom(50) + 1;
      refs.add('${book.name} $chapter:$verse');
    }
    return refs.toList();
  }
}