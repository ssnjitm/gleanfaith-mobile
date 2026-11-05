import 'dart:convert';

import 'package:dio/dio.dart';

import '../../services/logger_service.dart';
import 'http_cache_entry.dart';
import 'http_cache_policy.dart';
import 'http_cache_store.dart';

/// Serves cacheable `GET` responses from [store] and records fresh ones.
///
/// Three behaviours, in order of how often they fire:
///
/// 1. **Fresh hit** — resolved before the request reaches the network, so the
///    page paints without a round trip.
/// 2. **Stale, then revalidate** — the stored `ETag` / `Last-Modified` is
///    replayed as `If-None-Match` / `If-Modified-Since`; a `304` refreshes the
///    timestamp without re-downloading the body.
/// 3. **Stale, network down** — a connection failure or a 5xx serves the last
///    known payload instead of an error screen. Auth and not-found errors are
///    never masked this way.
///
/// Anything the [policy] does not explicitly allow is passed straight through.
class HttpCacheInterceptor extends Interceptor {
  HttpCacheInterceptor({
    required HttpCacheStore store,
    this.policy = const HttpCachePolicy(),
    DateTime Function()? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now;

  final HttpCacheStore _store;
  final HttpCachePolicy policy;
  final DateTime Function() _clock;

  static const String _keyExtra = 'http_cache_key';
  static const String _ttlExtra = 'http_cache_ttl';
  static const String _staleExtra = 'http_cache_stale_entry';

  /// `METHOD url` — the query string is part of the identity, so a `?language=np`
  /// request never serves an `?language=en` body.
  static String cacheKey(RequestOptions options) =>
      '${options.method.toUpperCase()} ${options.uri}';

  /// Drops every stored response.
  ///
  /// Called when the signed-in identity changes (login / logout): the cache is
  /// keyed by URL only, so a second account on the same device would otherwise
  /// be served the first account's `/user/me` and `/leaderboard` payloads.
  Future<void> invalidateAll() => _store.clear();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final decision = policy.decide(options);
    if (!decision.cacheable) {
      handler.next(options);
      return;
    }

    final key = cacheKey(options);
    final ttl = decision.ttl!;
    options.extra[_keyExtra] = key;
    options.extra[_ttlExtra] = ttl;

    final entry = await _store.read(key);
    if (entry == null) {
      handler.next(options);
      return;
    }

    if (entry.isFresh(_clock(), ttl)) {
      LoggerService.debug('HTTP cache hit: ${options.uri.path}');
      handler.resolve(entry.toResponse(options));
      return;
    }

    // Stale. Ask the server to confirm rather than re-send the body.
    final etag = entry.etag;
    if (etag != null && etag.isNotEmpty) {
      options.headers['If-None-Match'] = etag;
    }
    final lastModified = entry.lastModified;
    if (lastModified != null && lastModified.isNotEmpty) {
      options.headers['If-Modified-Since'] = lastModified;
    }
    options.extra[_staleExtra] = entry;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;

    // A successful write makes the cached lists lie; drop them.
    if (policy.shouldInvalidate(options.method, options.uri.path)) {
      await _store.clear();
      handler.next(response);
      return;
    }

    final key = options.extra[_keyExtra];
    if (key is String && response.statusCode == 200) {
      final entry = _buildEntry(key, response);
      if (entry != null) {
        await _store.write(entry);
      }
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final stale = options.extra[_staleExtra];

    // 304: our copy is still current, so keep the body and move the clock.
    if (err.response?.statusCode == 304 && stale is HttpCacheEntry) {
      final refreshed = stale.refreshedAt(_clock());
      await _store.write(refreshed);
      LoggerService.debug('HTTP cache revalidated: ${options.uri.path}');
      handler.resolve(refreshed.toResponse(options));
      return;
    }

    if (stale is HttpCacheEntry && _recoverable(err)) {
      LoggerService.warning(
        'HTTP cache serving stale payload after ${_describe(err)}: '
        '${options.uri.path}',
      );
      handler.resolve(stale.toResponse(options, stale: true));
      return;
    }

    handler.next(err);
  }

  HttpCacheEntry? _buildEntry(String key, Response<dynamic> response) {
    final headers = response.headers;
    final cacheControl = _header(headers, 'cache-control')?.toLowerCase() ?? '';
    if (cacheControl.contains('no-store')) return null;

    if (response.data == null) return null;

    try {
      return HttpCacheEntry(
        key: key,
        statusCode: response.statusCode ?? 200,
        body: jsonEncode(response.data),
        headers: <String, List<String>>{
          for (final entry in headers.map.entries)
            entry.key: List<String>.from(entry.value),
        },
        storedAt: _clock(),
        etag: _header(headers, 'etag'),
        lastModified: _header(headers, 'last-modified'),
      );
    } catch (error) {
      // A body that cannot be re-encoded would produce an entry that later
      // throws on read. Skipping it is always correct.
      LoggerService.warning('HTTP cache skipped an unencodable response: $error');
      return null;
    }
  }

  /// Narrow on purpose: only transport-level failures and server-side faults
  /// fall back to cache. A 401/403/404/429 must reach the caller unchanged, or
  /// an expired session would silently look like a successful request.
  static bool _recoverable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.badCertificate:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500;
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return false;
    }
  }

  static String _describe(DioException err) {
    final status = err.response?.statusCode;
    if (status != null) return 'HTTP $status';
    return err.type.name;
  }

  static String? _header(Headers headers, String name) {
    final values = headers[name];
    if (values == null || values.isEmpty) return null;
    final value = values.first.trim();
    return value.isEmpty ? null : value;
  }
}
