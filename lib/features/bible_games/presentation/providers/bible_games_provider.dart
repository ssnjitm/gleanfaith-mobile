import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_service.dart';
import '../../domain/entities/bible_game_entities.dart';
import '../../domain/services/bible_game_engine.dart';

/// Loads the canonical 66-book list (with chapter/verse counts and canonical
/// index) plus the longest/shortest verse stats, all from the offline Bible DB.
final bibleGamesDataProvider = FutureProvider<BibleGamesData>((ref) async {
  final rows = await DatabaseService.instance.getBooks();
  final extremesResult = await DatabaseService.instance.getVerseLengthExtremes();

  final books = <BibleGameBook>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final name = row['book'] as String? ?? '';
    final canonicalPos = kjvCanonicalBooks.indexOf(name);
    books.add(
      BibleGameBook.fromDbRow(
        row,
        canonicalIndex: canonicalPos == -1 ? i : canonicalPos,
      ),
    );
  }

  BibleGameExtremes? extremes;
  if (extremesResult != null) {
    extremes = BibleGameExtremes(
      longest: _statFromDbRow(extremesResult.longest),
      shortest: _statFromDbRow(extremesResult.shortest),
    );
  }

  return BibleGamesData(books: books, extremes: extremes);
});

/// All the fun facts the offline DB can produce, for the Home facts card.
/// Empty when the DB is unavailable (fallback/web mode).
final bibleFunFactsProvider = FutureProvider<List<FunFactRound>>((ref) async {
  final data = await ref.watch(bibleGamesDataProvider.future);
  if (data.isEmpty || data.extremes == null) return const [];
  return BibleGameEngine().funFactRounds(data.books, data.extremes!);
});

BibleVerseStat _statFromDbRow(Map<String, dynamic> row) {
  final reference =
      '${row['book']} ${row['chapter']}:${row['verse']}';
  final length = row['len'] is int
      ? row['len'] as int
      : (int.tryParse('${row['len']}') ?? 0);
  return BibleVerseStat(
    reference: reference,
    length: length,
    text: row['text'] as String? ?? '',
  );
}