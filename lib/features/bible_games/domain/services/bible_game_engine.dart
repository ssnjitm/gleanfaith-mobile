import 'dart:math';

import '../entities/bible_game_entities.dart';
import '../entities/bible_game_localization.dart';

/// Pure, seedable generator for every Bible game round.
///
/// Construct with a fixed `Random(seed)` in tests (and for daily-sync games) so
/// a full run is reproducible. The engine never touches Flutter, Riverpod, the
/// database or fpdart — callers feed it the data bundles they already loaded.
///
/// Every generator takes the `BibleGameLanguage` the session is playing in and
/// fills the `display*` fields of the round it returns. Round *identity* fields
/// (book names, option values) always stay the canonical DB values, so a
/// localized round is still correct in English.
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
  ///
  /// The verse is expected to already be localized via
  /// `BibleGameVerse.localized` — its [BibleGameVerse.label] is what gets
  /// shown, and [BibleGameVerse.hasTranslation] drives the "no Nepali
  /// translation" hint in the UI.
  GuessBookRound guessBookRound({
    required List<BibleGameBook> books,
    required List<BibleGameVerse> verses,
    required BibleGameLanguage language,
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
    final words = verse.label
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final shown = words.take(wordsShown);
    return GuessBookRound(
      snippet: '${shown.join(' ')}${words.length > wordsShown ? ' ...' : ''}',
      fullText: verse.label,
      reference: verse.formattedReference,
      correctBook: correct.name,
      options: options,
      wordsShown: wordsShown,
      hint: bookHint(correct, language),
      displayCorrectBook: correct.label,
      displayOptions: [
        for (final name in options) _displayNameFor(books, name, language),
      ],
      displayReference: verse.referenceFor(language),
      hasTranslation: verse.hasTranslation,
    );
  }

  /// The rendered name of the book with identity [name], resolved from the
  /// [books] list (already localized by the caller) or, failing that, from the
  /// inline catalog.
  String _displayNameFor(
    List<BibleGameBook> books,
    String name,
    BibleGameLanguage language,
  ) {
    for (final book in books) {
      if (book.name == name) return book.label;
    }
    return bibleGameBookDataForName(name)?.nameFor(language) ?? name;
  }

  /// A gentle hint about a book's SIZE (short / mid / long). It never names
  /// the book nor gives away its canonical section, so several options always
  /// stay plausible.
  String bookHint(BibleGameBook book, BibleGameLanguage language) {
    final strings = BibleGameStrings.of(language);
    final chapters = book.chapterCount;
    if (chapters >= 40) return strings.hintLongerBook;
    if (chapters >= 16) return strings.hintMidBook;
    return strings.hintShorterBook;
  }

  /// Higher / Lower — two distinct books with different chapter counts; the
  /// player taps the one with more chapters.
  ///
  /// The books arrive already localized (`BibleGamesData.localized`), so both
  /// the tile labels and the chapter counts are in the active language.
  HigherLowerRound higherLowerRound(
    List<BibleGameBook> books, {
    BibleGameLanguage language = BibleGameLanguage.english,
  }) {
    var left = pick(books);
    var right = pick(books);
    var attempts = 0;
    while ((left.name == right.name || left.chapterCount == right.chapterCount) &&
        attempts < 50) {
      left = pick(books);
      right = pick(books);
      attempts++;
    }
    // A DB that reported no chapter counts (fallback mode) would make every
    // pair a 0-vs-0 tie and spin forever. Seed the counts from the inline
    // catalog so the game stays playable with no database at all.
    return HigherLowerRound(
      left: _withCatalogCounts(left, language),
      right: _withCatalogCounts(right, language),
    );
  }

  /// Ensures a book carries usable chapter/verse counts and a resolved label
  /// even when the offline database supplied neither.
  BibleGameBook _withCatalogCounts(
    BibleGameBook book,
    BibleGameLanguage language,
  ) {
    return book.localized(language);
  }

  /// Book Order Race — [numberOfBooks] random books, displayed shuffled; the
  /// player must tap them in canonical order.
  BookOrderRound bookOrderRound(
    List<BibleGameBook> books, {
    int numberOfBooks = 5,
    BibleGameLanguage language = BibleGameLanguage.english,
  }) {
    final chosen = sample(books, numberOfBooks);
    return BookOrderRound(
      shuffledBooks: shuffled([
        for (final book in chosen) _withCatalogCounts(book, language),
      ]),
    );
  }

  /// Find the Chapter — tap the tile holding the target "book chapter" on a
  /// [gridSize]-tile grid. Distractors are real book/chapter combos.
  ///
  /// Both the identity labels (English) and the rendered labels are produced
  /// here so a tap can be compared against [FindChapterRound.targetLabel]
  /// without ever touching the localized string.
  FindChapterRound findChapterRound(
    List<BibleGameBook> books, {
    int gridSize = 16,
    BibleGameLanguage language = BibleGameLanguage.english,
  }) {
    final localizedBooks = [
      for (final book in books) _withCatalogCounts(book, language),
    ];
    final targetBook = pick(localizedBooks);
    final targetChapter = pickFrom(targetBook.chapterCount) + 1;
    final targetLabel = '${targetBook.name} $targetChapter';
    final displayTargetLabel =
        '${targetBook.label} ${formatCount(targetChapter, language)}';
    // Dedupe on the identity label; the display label is derived from it, so
    // unique identities imply unique display labels.
    final tiles = <String>{targetLabel};
    var guard = 0;
    while (tiles.length < gridSize && guard < 300) {
      guard++;
      final book = pick(localizedBooks);
      if (book.chapterCount <= 0) continue;
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
      displayTargetLabel: displayTargetLabel,
      displayOptions: [
        for (final label in options) _displayChapterLabel(
          localizedBooks,
          label,
          language,
        ),
      ],
    );
  }

  /// Splits an identity `"<book name> <chapter>"` label back into its parts and
  /// rebuilds it with the localized book name and numerals.
  String _displayChapterLabel(
    List<BibleGameBook> books,
    String label,
    BibleGameLanguage language,
  ) {
    final separator = label.lastIndexOf(' ');
    if (separator < 0) return label;
    final name = label.substring(0, separator);
    final chapter = int.tryParse(label.substring(separator + 1));
    if (chapter == null) return label;
    final displayName = _displayNameFor(books, name, language);
    return '$displayName ${formatCount(chapter, language)}';
  }

  /// Fun Facts — as many interesting facts as the loaded data can produce.
  /// Fully deterministic (a fact is a fact, so randomness has no place here),
  /// which means the same data always yields the same facts in the same order.
  ///
  /// [books] should already be localized for [language] so the counts the facts
  /// quote are the real ones even in fallback mode, and every sentence is
  /// assembled from `BibleGameStrings` rather than an English literal.
  List<FunFactRound> funFactRounds(
    List<BibleGameBook> books,
    BibleGameExtremes extremes, {
    BibleGameLanguage language = BibleGameLanguage.english,
  }) {
    final strings = BibleGameStrings.of(language);

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

    /// `John 3:16` / `यूहन्ना ३:१६` from a raw DB reference string.
    String localizeReference(String reference) {
      final parts = reference.split(RegExp(r'\s+'));
      if (parts.length < 2) return reference;
      final name = parts.take(parts.length - 1).join(' ');
      final numbers = parts.last.split(':');
      final data = bibleGameBookDataForName(name);
      final chapter = int.tryParse(numbers.first);
      final verse = numbers.length > 1 ? int.tryParse(numbers[1]) : null;
      if (data == null || chapter == null || verse == null) return reference;
      final book = data.nameFor(language) ?? data.nameEn;
      return '$book ${formatCount(chapter, language)}:'
          '${formatCount(verse, language)}';
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
    final longestReference = localizeReference(longest.reference);
    final shortestReference = localizeReference(shortest.reference);

    return [
      _funFact(
        strings.factLongestVerse,
        longestReference,
        strings.factLongestVerseExplain(longestReference, longest.length),
      ),
      _funFact(
        strings.factShortestVerse,
        shortestReference,
        strings.factShortestVerseExplain(
          shortest.text,
          shortestReference,
          shortest.length,
        ),
      ),
      _funFact(
        strings.factMostChapters,
        mostChapters.label,
        strings.factChaptersOf(mostChapters.label, mostChapters.chapterCount),
      ),
      _funFact(
        strings.factFewestChapters,
        fewestChapters.label,
        fewestChapters.chapterCount == 1
            ? strings.factChaptersOfOne(
                fewestChapters.label,
                fewestChapters.chapterCount,
              )
            : strings.factChaptersOf(
                fewestChapters.label,
                fewestChapters.chapterCount,
              ),
      ),
      _funFact(
        strings.factMostVerses,
        mostVerses.label,
        strings.factVersesOf(mostVerses.label, mostVerses.verseCount),
      ),
      _funFact(
        strings.factFewestVerses,
        fewestVerses.label,
        fewestVerses.verseCount == 1
            ? strings.factVersesOfOne(
                fewestVerses.label,
                fewestVerses.verseCount,
              )
            : strings.factVersesOf(
                fewestVerses.label,
                fewestVerses.verseCount,
              ),
      ),
      if (ntByChapters.isNotEmpty)
        _funFact(
          strings.factNtMostChapters,
          ntByChapters.last.label,
          strings.factChaptersOf(
            ntByChapters.last.label,
            ntByChapters.last.chapterCount,
          ),
        ),
      if (ntByVerses.isNotEmpty)
        _funFact(
          strings.factNtMostVerses,
          ntByVerses.last.label,
          strings.factVersesOf(
            ntByVerses.last.label,
            ntByVerses.last.verseCount,
          ),
        ),
      _funFact(
        strings.factBookCount,
        formatCount(books.length, language),
        strings.factBookCountExplain(books.length),
      ),
      _funFact(
        strings.factOtCount,
        formatCount(oldTestament.length, language),
        strings.factOtCountExplain(oldTestament.length),
      ),
      _funFact(
        strings.factNtCount,
        formatCount(newTestament.length, language),
        strings.factNtCountExplain(newTestament.length),
      ),
      _funFact(
        strings.factTotalChapters,
        formatCount(totalChapters, language),
        strings.factTotalChaptersExplain(books.length, totalChapters),
      ),
      _funFact(
        strings.factTotalVerses,
        formatCount(totalVerses, language),
        strings.factTotalVersesExplain(books.length, totalVerses),
      ),
      if (singleChapterBooks.length > 1)
        _funFact(
          strings.factSingleChapter,
          formatCount(singleChapterBooks.length, language),
          strings.factSingleChapterExplain(
            singleChapterBooks.map((b) => b.label).join(', '),
          ),
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