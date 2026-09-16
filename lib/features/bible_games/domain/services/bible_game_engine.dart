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
  /// resolved by testament). A subtle, non-revealing hint helps a little.
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

  /// A gentle hint about a book's SIZE (short / mid / long). It never names
  /// the book nor gives away its canonical section, so several options always
  /// stay plausible.
  String bookHint(BibleGameBook book) {
    final chapters = book.chapterCount;
    if (chapters >= 40) return 'One of the longer books of the Bible';
    if (chapters >= 16) return 'A mid-sized book';
    return 'A shorter book';
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
  /// Fun Facts — as many interesting facts as the loaded data can produce.
  /// Fully deterministic (a fact is a fact — randomness has no place here), so
  /// the same data always yields the same facts in the same order.
  List<FunFactRound> funFactRounds(
    List<BibleGameBook> books,
    BibleGameExtremes extremes,
  ) {
    List<BibleGameBook> byChapters(Iterable<BibleGameBook> source) {
      final sorted = [...source]
        ..sort((a, b) {
          final byChapters = a.chapterCount.compareTo(b.chapterCount);
          return byChapters != 0 ? byChapters : a.name.compareTo(b.name);
        });
      return sorted;
    }

    List<BibleGameBook> byVerses(Iterable<BibleGameBook> source) {
      final sorted = [...source]
        ..sort((a, b) {
          final byVerses = a.verseCount.compareTo(b.verseCount);
          return byVerses != 0 ? byVerses : a.name.compareTo(b.name);
        });
      return sorted;
    }

    final orderedByChapters = byChapters(books);
    final orderedByVerses = byVerses(books);
    final oldTestament = books.where((b) => b.isOldTestament).toList();
    final newTestament = books.where((b) => b.isNewTestament).toList();
    final ntByChapters = byChapters(newTestament);
    final ntByVerses = byVerses(newTestament);
    final mostChapters = orderedByChapters.last;
    final fewestChapters = orderedByChapters.first;
    final mostVerses = orderedByVerses.last;
    final fewestVerses = orderedByVerses.first;
    final singleChapterBooks =
        books.where((b) => b.chapterCount == 1).toList();
    final totalChapters =
        books.fold<int>(0, (sum, b) => sum + b.chapterCount);
    final totalVerses = books.fold<int>(0, (sum, b) => sum + b.verseCount);
    final longest = extremes.longest;
    final shortest = extremes.shortest;

    return [
      _funFact(
        'Longest verse in the Bible',
        longest.reference,
        '${longest.reference} has ${longest.length} characters.',
      ),
      _funFact(
        'Shortest verse in the Bible',
        shortest.reference,
        '"${shortest.text}" — ${shortest.reference} has '
            '${shortest.length} characters.',
      ),
      _funFact(
        'Book with the MOST chapters',
        mostChapters.name,
        '${mostChapters.name} has ${mostChapters.chapterCount} chapters.',
      ),
      _funFact(
        'Book with the FEWEST chapters',
        fewestChapters.name,
        '${fewestChapters.name} has ${fewestChapters.chapterCount} '
            'chapter${fewestChapters.chapterCount == 1 ? '' : 's'}.',
      ),
      _funFact(
        'Book with the MOST verses',
        mostVerses.name,
        '${mostVerses.name} has ${mostVerses.verseCount} verses.',
      ),
      _funFact(
        'Book with the FEWEST verses',
        fewestVerses.name,
        '${fewestVerses.name} has ${fewestVerses.verseCount} verses.',
      ),
      if (ntByChapters.isNotEmpty)
        _funFact(
          'Most-chaptered book of the New Testament',
          ntByChapters.last.name,
          '${ntByChapters.last.name} has ${ntByChapters.last.chapterCount} '
              'chapters.',
        ),
      if (ntByVerses.isNotEmpty)
        _funFact(
          'Most-versed book of the New Testament',
          ntByVerses.last.name,
          '${ntByVerses.last.name} has ${ntByVerses.last.verseCount} verses.',
        ),
      _funFact(
        'Books in the Bible',
        '${books.length}',
        'The Protestant canon has 66 books (loaded ${books.length} locally).',
      ),
      _funFact(
        'Books in the Old Testament',
        '${oldTestament.length}',
        'The Old Testament has ${oldTestament.length} books.',
      ),
      _funFact(
        'Books in the New Testament',
        '${newTestament.length}',
        'The New Testament has ${newTestament.length} books.',
      ),
      _funFact(
        'Chapters in the whole Bible',
        '$totalChapters',
        'The ${books.length} books contain $totalChapters chapters.',
      ),
      _funFact(
        'Verses in the whole Bible',
        '$totalVerses',
        'The KJV chapter counts add up to $totalVerses verses.',
      ),
      if (singleChapterBooks.length > 1)
        _funFact(
          'Single-chapter books',
          '${singleChapterBooks.length}',
          '${singleChapterBooks.map((b) => b.name).join(', ')} each have '
              'one chapter.',
        ),
    ];
  }

  FunFactRound _funFact(String prompt, String correct, String explain) {
    return FunFactRound(
      prompt: prompt,
      correct: correct,
      options: [correct],
      explain: explain,
    );
  }
}