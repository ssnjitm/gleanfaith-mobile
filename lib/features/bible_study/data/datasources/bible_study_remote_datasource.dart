import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/bible_study_models.dart';

/// Remote data source for continue-reading history, bookmarks and chapter
/// notes. All endpoints are JWT-protected; the Dio auth interceptor adds the
/// bearer token automatically.
class BibleStudyRemoteDataSource {
  final Dio _dio;

  BibleStudyRemoteDataSource(this._dio);

  // ── Continue reading ─────────────────────────────────────────────────────
  Future<ReadingPositionModel> saveReadingPosition({
    required String bookId,
    required int chapter,
    required int verse,
  }) async {
    final response = await _dio.post(
      ApiConstants.readingHistory,
      data: {
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
      },
    );
    return ReadingPositionModel.fromJson(_extractMap(response.data));
  }

  Future<List<ReadingPositionModel>> getRecentReading({
    int? limit,
    String? bookId,
  }) async {
    final response = await _dio.get(
      ApiConstants.readingHistoryRecent,
      queryParameters: {
        'limit': ?limit,
        'bookId': ?bookId,
      },
    );
    return _extractList(response.data).map(ReadingPositionModel.fromJson).toList();
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────
  Future<List<BookmarkModel>> getBookmarks({String? bookId, int? chapter}) async {
    final response = await _dio.get(
      ApiConstants.bookmarks,
      queryParameters: {
        'bookId': ?bookId,
        'chapter': ?chapter,
      },
    );
    return _extractList(response.data).map(BookmarkModel.fromJson).toList();
  }

  Future<BookmarkModel> createBookmark({
    required String bookId,
    required int chapter,
    int? verse,
    String note = '',
  }) async {
    final response = await _dio.post(
      ApiConstants.bookmarks,
      data: {
        'bookId': bookId,
        'chapter': chapter,
        'verse': ?verse,
        if (note.isNotEmpty) 'note': note,
      },
    );
    return BookmarkModel.fromJson(_extractMap(response.data));
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _dio.delete(ApiConstants.bookmarkById(bookmarkId));
  }

  // ── Chapter notes ───────────────────────────────────────────────────────
  Future<List<ChapterNoteModel>> getNotes({
    String? bookId,
    int? chapter,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiConstants.notes,
      queryParameters: {
        'bookId': ?bookId,
        'chapter': ?chapter,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _extractList(response.data).map(ChapterNoteModel.fromJson).toList();
  }

  Future<ChapterNoteModel> createNote({
    required String bookId,
    required int chapter,
    required String content,
  }) async {
    final response = await _dio.post(
      ApiConstants.notes,
      data: {
        'bookId': bookId,
        'chapter': chapter,
        'content': content,
      },
    );
    return ChapterNoteModel.fromJson(_extractMap(response.data));
  }

  Future<ChapterNoteModel> updateNote({
    required String noteId,
    String? content,
    int? chapter,
  }) async {
    final response = await _dio.patch(
      ApiConstants.noteById(noteId),
      data: {
        'content': ?content,
        'chapter': ?chapter,
      },
    );
    return ChapterNoteModel.fromJson(_extractMap(response.data));
  }

  Future<void> deleteNote(String noteId) async {
    await _dio.delete(ApiConstants.noteById(noteId));
  }

  // ── Response unwrapping helpers ─────────────────────────────────────────
  /// Pull a map out of a wrapped (`{status, data, message}`) or flat response.
  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    return response;
  }

  /// Pull a list of maps out of wrapped/flat responses that may key the list
  /// under `data`, `items`, `results`, `bookmarks`, `notes`, `history` etc.
  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return <Map<String, dynamic>>[];
    }

    final data = response['data'];
    if (data is List) {
      return _mapsFromList(data);
    }
    if (data is Map<String, dynamic>) {
      final inner = _firstListValue(data);
      if (inner.isNotEmpty) return inner;
    }

    return _firstListValue(response);
  }

  List<Map<String, dynamic>> _firstListValue(Map<String, dynamic> map) {
    for (final key in const [
      'items',
      'results',
      'data',
      'bookmarks',
      'notes',
      'history',
      'readingHistory',
    ]) {
      final value = map[key];
      if (value is List) return _mapsFromList(value);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _mapsFromList(List<dynamic> list) {
    return list.whereType<Map<String, dynamic>>().toList();
  }
}