import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/content_item.dart';
import 'package:dio/dio.dart';

class ContentRemoteDataSource {
  final Dio _dio;

  ContentRemoteDataSource(this._dio);

  Future<List<ContentItem>> getContents({String? type, String? search}) async {
    final response = await _dio.get(
      ApiConstants.content,
      queryParameters: {
        'type': ?type,
        'search': ?search,
        'status': 'published',
      },
    );
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>?)?.toList() ??
            (data['items'] as List<dynamic>?)?.toList() ??
            const []
        : (data as List<dynamic>? ?? const []);
    return items
        .map((e) => e is Map<String, dynamic>
            ? _toContentItem(e)
            : ContentItem(id: '', title: '', body: '', type: 'written'))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  ContentItem _toContentItem(Map<String, dynamic> json) {
    return ContentItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'written',
      fileUrl: json['fileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      bibleBook: json['bibleBook'] as String?,
      bibleChapter: _toInt(json['bibleChapter']),
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      readTimeMinutes: _toInt(json['readTimeMinutes']),
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}