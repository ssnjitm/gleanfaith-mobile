import '../../domain/entities/bible_study_entities.dart';
import '../bible_study_mapper.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) => (value as num?)?.toInt() ?? 0;

class ReadingPositionModel {
  const ReadingPositionModel({
    this.bookId = '',
    this.chapter = 0,
    this.verse = 0,
    this.updatedAt,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final DateTime? updatedAt;

  factory ReadingPositionModel.fromJson(Map<String, dynamic> json) {
    return ReadingPositionModel(
      bookId: json['bookId'] as String? ?? '',
      chapter: _toInt(json['chapter']),
      verse: _toInt(json['verse']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  ReadingPosition toEntity() {
    return ReadingPosition(
      bookId: bookId,
      bookName: bookNameForCode(bookId),
      chapter: chapter,
      verse: verse,
      updatedAt: updatedAt,
    );
  }
}

class BookmarkModel {
  const BookmarkModel({
    this.id = '',
    this.bookId = '',
    this.chapter = 0,
    this.verse,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String bookId;
  final int chapter;
  final int? verse;
  final String note;
  final DateTime? createdAt;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      chapter: _toInt(json['chapter']),
      verse: json['verse'] == null ? null : _toInt(json['verse']),
      note: json['note'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Bookmark toEntity() {
    return Bookmark(
      id: id,
      bookId: bookId,
      bookName: bookNameForCode(bookId),
      chapter: chapter,
      verse: verse,
      note: note,
      createdAt: createdAt,
    );
  }
}

class ChapterNoteModel {
  const ChapterNoteModel({
    this.id = '',
    this.bookId = '',
    this.chapter = 0,
    this.content = '',
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final int chapter;
  final String content;
  final DateTime? updatedAt;

  factory ChapterNoteModel.fromJson(Map<String, dynamic> json) {
    return ChapterNoteModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      chapter: _toInt(json['chapter']),
      content: json['content'] as String? ?? '',
      updatedAt: _parseDate(json['updatedAt'] ?? json['createdAt']),
    );
  }

  ChapterNote toEntity() {
    return ChapterNote(
      id: id,
      bookId: bookId,
      bookName: bookNameForCode(bookId),
      chapter: chapter,
      content: content,
      updatedAt: updatedAt,
    );
  }
}