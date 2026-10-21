import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/remote_bible_chapter.dart';
import '../../domain/entities/remote_bible_verse.dart';

/// Fetches scripture from the free, keyless Free Use Bible API.
///
/// Uses its own unauthenticated [Dio] rather than the app's `dioProvider`: the
/// host is unrelated to `ApiConstants.baseUrl`, no token should ever be sent to
/// a third party, and a slow or dead third party must not stall the auth
/// interceptor chain.
///
/// The API is chapter-grained, so one request returns the whole chapter
/// (~3-8 KB) and the requested verse is picked out of it. That is the finest
/// granularity the endpoint offers and is trivial at one request per day.
///
/// Both the English and the Nepali verse of the day come through here, from the
/// same [DailyVersePlan] reference, so a translation swap can never change which
/// verse a date points at.
class RemoteBibleDataSource {
  final Dio _dio;

  RemoteBibleDataSource(this._dio);

  /// Returns the text of [verse] in [usfmBook] [chapter] from [translationId],
  /// e.g. `ApiConstants.englishTranslationId`.
  ///
  /// Throws on any transport, status or parse problem — the repository turns
  /// those into a `Failure`.
  Future<RemoteBibleVerse> getVerse({
    required String translationId,
    required String usfmBook,
    required int chapter,
    required int verse,
  }) async {
    final data = await _fetchChapter(
      translationId: translationId,
      usfmBook: usfmBook,
      chapter: chapter,
    );

    final bookName = _readBookName(data, usfmBook);
    final text = _readVerseText(data, verse);
    if (text.isEmpty) {
      throw FormatException(
        'Verse $usfmBook $chapter:$verse missing from $translationId response',
      );
    }

    return RemoteBibleVerse(
      translationId: translationId,
      usfmBook: usfmBook,
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      text: text,
    );
  }

  /// Returns every verse of [chapter] in [usfmBook] from [translationId].
  ///
  /// This is what the Bible reader needs for a non-English chapter: the
  /// bundled SQLite database only ships the English KJV, so the Nepali text
  /// has to be fetched. The endpoint is chapter-grained, so one request covers
  /// the whole chapter and the verses come back in order.
  ///
  /// Throws on any transport, status or parse problem.
  Future<RemoteBibleChapter> getChapter({
    required String translationId,
    required String usfmBook,
    required int chapter,
  }) async {
    final data = await _fetchChapter(
      translationId: translationId,
      usfmBook: usfmBook,
      chapter: chapter,
    );

    final bookName = _readBookName(data, usfmBook);
    final verses = _readVerses(
      data,
      translationId: translationId,
      usfmBook: usfmBook,
      chapter: chapter,
    );
    if (verses.isEmpty) {
      throw FormatException(
        'Chapter $usfmBook $chapter missing from $translationId response',
      );
    }

    return RemoteBibleChapter(
      translationId: translationId,
      usfmBook: usfmBook,
      bookName: bookName,
      chapter: chapter,
      verses: verses,
    );
  }

  /// Returns the name of every book of [translationId], keyed by USFM id.
  ///
  /// The book list is the one place where the *names* of the books are needed
  /// in the selected language, and the endpoint serves them in the
  /// translation's own script (`यूहन्‍ना`). One request covers all 66 books, so
  /// the reader can localise its whole book grid without a request per book.
  ///
  /// Throws on any transport, status or parse problem.
  Future<Map<String, String>> getBookNames({required String translationId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.freeBibleBooks(translationId: translationId),
    );

    final data = response.data;
    if (data == null) {
      throw FormatException('Empty $translationId Bible books response');
    }

    final books = data['books'];
    if (books is! List) {
      throw FormatException('$translationId Bible books response has no books');
    }

    final names = <String, String>{};
    for (final entry in books) {
      if (entry is! Map) continue;

      final id = entry['id'];
      if (id is! String || id.trim().isEmpty) continue;

      final name = entry['commonName'] ?? entry['name'];
      if (name is! String || name.trim().isEmpty) continue;

      names[id.trim()] = name.trim();
    }

    if (names.isEmpty) {
      throw FormatException('$translationId Bible books response has no names');
    }

    return names;
  }

  /// Performs the request and validates that the payload really is the chapter
  /// that was asked for.
  Future<Map<String, dynamic>> _fetchChapter({
    required String translationId,
    required String usfmBook,
    required int chapter,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.freeBibleChapter(
        translationId: translationId,
        usfmBook: usfmBook,
        chapter: chapter,
      ),
    );

    final data = response.data;
    if (data == null) {
      throw FormatException('Empty $translationId Bible response');
    }

    _assertMatchesRequest(data, usfmBook, chapter);
    return data;
  }

  /// Rejects a response that is not the chapter that was asked for.
  ///
  /// The endpoint is keyed by path, so a misrouted request, a stale cache entry
  /// or a redirect would otherwise be rendered as "today's verse" with the right
  /// chapter label and completely unrelated text. Each field is checked only
  /// when present, so a slimmer payload still works.
  void _assertMatchesRequest(
    Map<String, dynamic> data,
    String usfmBook,
    int chapter,
  ) {
    final book = data['book'];
    if (book is Map<String, dynamic>) {
      final id = book['id'];
      if (id is String && id.trim().isNotEmpty && id.trim() != usfmBook) {
        throw FormatException(
          'Asked for $usfmBook $chapter but the response holds ${id.trim()}',
        );
      }
    }

    final block = data['chapter'];
    if (block is Map<String, dynamic>) {
      final number = block['number'];
      final parsed = number is int
          ? number
          : (number is num ? number.toInt() : int.tryParse('$number'));
      if (parsed != null && parsed != chapter) {
        throw FormatException(
          'Asked for $usfmBook $chapter but the response holds chapter $parsed',
        );
      }
    }
  }

  /// `data.book.commonName` is the book name in the translation's own script
  /// (`यूहन्‍ना`). Falls back to the raw USFM id so a reference is always
  /// renderable even if the book block is missing.
  String _readBookName(Map<String, dynamic> data, String usfmBook) {
    final book = data['book'];
    if (book is Map<String, dynamic>) {
      final name = book['commonName'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return usfmBook;
  }

  /// Walks `data.chapter.content`, which is a list of typed nodes
  /// (`{type: 'heading'|'verse', number: int, content: [...]}`), and pulls
  /// the plain text out of the node whose `number` matches [verse].
  String _readVerseText(Map<String, dynamic> data, int verse) {
    final chapter = data['chapter'];
    if (chapter is! Map<String, dynamic>) return '';

    final nodes = chapter['content'];
    if (nodes is! List) return '';

    for (final node in nodes) {
      if (node is! Map) continue;
      if (node['type'] != 'verse') continue;

      final number = node['number'];
      final parsed = number is int
          ? number
          : (number is num ? number.toInt() : int.tryParse('$number'));
      if (parsed != verse) continue;

      return _joinContent(node['content']);
    }
    return '';
  }

  /// Every verse of the chapter, in the order the endpoint returned them.
  ///
  /// Same walk as [_readVerseText] but it keeps every node instead of stopping
  /// at the first match — the reader needs the whole chapter, not one verse.
  List<RemoteBibleVerse> _readVerses(
    Map<String, dynamic> data, {
    required String translationId,
    required String usfmBook,
    required int chapter,
  }) {
    final block = data['chapter'];
    if (block is! Map<String, dynamic>) return const [];

    final nodes = block['content'];
    if (nodes is! List) return const [];

    final bookName = _readBookName(data, usfmBook);
    final verses = <RemoteBibleVerse>[];

    for (final node in nodes) {
      if (node is! Map) continue;
      if (node['type'] != 'verse') continue;

      final number = node['number'];
      final parsed = number is int
          ? number
          : (number is num ? number.toInt() : int.tryParse('$number'));
      if (parsed == null) continue;

      final text = _joinContent(node['content']);
      if (text.isEmpty) continue;

      verses.add(
        RemoteBibleVerse(
          translationId: translationId,
          usfmBook: usfmBook,
          bookName: bookName,
          chapter: chapter,
          verse: parsed,
          text: text,
        ),
      );
    }

    return verses;
  }

  /// Flattens a verse's inline `content` into plain text.
  ///
  /// The shape is translation-dependent and this is the single place that has to
  /// absorb the difference:
  ///
  /// * `npi_ulb` ships one plain [String] per verse.
  /// * `eng_web` splits a verse into inline runs, and each run is either a plain
  ///   [String] or an object carrying `text` plus decoration — `{text, poem: 1}`
  ///   for a line of acrostic poetry, `{text, wordsOfJesus: true}` for the words
  ///   of Christ. A run is therefore *not* guaranteed to be a string, and the
  ///   verse is not guaranteed to be a single run: John 3:16 arrives as
  ///   `born` / `{noteId}` / `Son,` because a footnote marker splits the phrase
  ///   mid-sentence.
  ///
  /// Runs are joined with a single space rather than concatenated, because the
  /// splits fall mid-sentence: concatenating would render "only bornSon".
  /// [_clean] then collapses the doubled space. An object with no `text` — a
  /// `{noteId: N}` marker or a `{lineBreak: true}` — contributes no word, and
  /// the separator already supplies the break, so it is skipped.
  ///
  /// Nothing is ever stringified blindly: a nested node can never leak a
  /// `Map.toString()` into the verse body.
  String _joinContent(dynamic content) {
    if (content is String) return _clean(content);
    if (content is! List) return '';

    final runs = <String>[];
    for (final part in content) {
      if (part is String) {
        runs.add(part);
        continue;
      }
      if (part is Map) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) runs.add(text);
      }
    }
    return _clean(runs.join(' '));
  }

  /// Collapses the whitespace the USFM source carries and strips the brace
  /// markers the bundled local database also uses for footnote anchors, so both
  /// languages render through the same widget.
  String _clean(String raw) {
    return raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
