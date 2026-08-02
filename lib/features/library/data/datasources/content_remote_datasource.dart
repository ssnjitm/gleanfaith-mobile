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
    final items = _asContentList(data);
    return items
        .map((e) => e is Map<String, dynamic> ? _toContentItem(e) : null)
        .whereType<ContentItem>()
        .toList();
  }

  List<dynamic> _asContentList(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['items'];
      if (inner is List) return inner;
      return const [];
    }
    if (data is List) return data;
    return const [];
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
      tags: _asListOfStrings(json['tags']),
      readTimeMinutes: _toInt(json['readTimeMinutes']),
    );
  }

  List<String> _asListOfStrings(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}