import 'dart:convert';

import 'package:dio/dio.dart';

/// A single stored HTTP response.
///
/// The body is kept as the **raw JSON string** the server sent rather than as a
/// decoded map. Re-encoding a decoded body on every write costs CPU on the UI
/// isolate for no gain, and the decode has to happen on read anyway — which is
/// exactly what [Dio] would have done with the network response.
///
/// `headers` already carries the revalidation metadata (`etag`,
/// `last-modified`), so it is stored alongside the body instead of being split
/// into separate columns.
class HttpCacheEntry {
  const HttpCacheEntry({
    required this.key,
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.storedAt,
    this.etag,
    this.lastModified,
  });

  /// Cache key this entry was filed under (see `HttpCacheInterceptor.cacheKey`).
  final String key;

  final int statusCode;

  /// Raw response body, as received. Empty when the server sent no body.
  final String body;

  final Map<String, List<String>> headers;

  /// When this payload was fetched **or last revalidated**. A `304 Not
  /// Modified` refreshes this without touching [body], which is what makes a
  /// stale entry cheap to keep.
  final DateTime storedAt;

  /// `ETag` from the response, replayed as `If-None-Match` when stale.
  final String? etag;

  /// `Last-Modified` from the response, replayed as `If-Modified-Since`.
  final String? lastModified;

  /// Whether the payload is still inside its time-to-live.
  bool isFresh(DateTime now, Duration ttl) =>
      now.difference(storedAt) < ttl;

  /// Same payload, new timestamp — the result of a successful revalidation.
  HttpCacheEntry refreshedAt(DateTime now) => HttpCacheEntry(
        key: key,
        statusCode: statusCode,
        body: body,
        headers: headers,
        storedAt: now,
        etag: etag,
        lastModified: lastModified,
      );

  /// Rebuilds a [Response] the caller cannot tell apart from a network one,
  /// apart from the markers in `extra`.
  Response<dynamic> toResponse(
    RequestOptions requestOptions, {
    bool stale = false,
  }) {
    // A body that is not valid JSON must never be served from cache: a throw
    // here would turn a stale entry into a hard error at the call site.
    Object? decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        decoded = null;
      }
    }

    return Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      statusMessage: 'OK',
      headers: Headers.fromMap(
        <String, List<String>>{
          for (final entry in headers.entries)
            entry.key: List<String>.from(entry.value),
        },
      ),
      data: decoded,
      extra: <String, dynamic>{
        HttpCacheMarkers.hit: true,
        HttpCacheMarkers.stale: stale,
        HttpCacheMarkers.storedAt: storedAt,
      },
    );
  }

  factory HttpCacheEntry.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final headers = <String, List<String>>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((Object? name, Object? value) {
        if (name is! String) return;
        if (value is List) {
          headers[name] = value.whereType<Object>().map((e) => '$e').toList();
        } else if (value != null) {
          headers[name] = <String>['$value'];
        }
      });
    }

    return HttpCacheEntry(
      key: json['key'] as String? ?? '',
      statusCode: json['statusCode'] as int? ?? 200,
      body: json['body'] as String? ?? '',
      headers: headers,
      storedAt: _parseDate(json['storedAt']) ?? DateTime.now(),
      etag: json['etag'] as String?,
      lastModified: json['lastModified'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'statusCode': statusCode,
        'body': body,
        'headers': headers,
        'storedAt': storedAt.toIso8601String(),
        'etag': etag,
        'lastModified': lastModified,
      };

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

/// Keys read off `Response.extra` / `RequestOptions.extra` so callers (and
/// tests) do not depend on string literals.
class HttpCacheMarkers {
  HttpCacheMarkers._();

  /// `true` when the response was served from the cache.
  static const String hit = 'http_cache_hit';

  /// `true` when a stale entry was served because the network failed.
  static const String stale = 'http_cache_stale';

  /// The [DateTime] the payload was originally fetched.
  static const String storedAt = 'http_cache_stored_at';
}
