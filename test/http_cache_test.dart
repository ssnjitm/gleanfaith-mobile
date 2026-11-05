import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glean_faith_app/core/network/cache/http_cache_entry.dart';
import 'package:glean_faith_app/core/network/cache/http_cache_interceptor.dart';
import 'package:glean_faith_app/core/network/cache/http_cache_policy.dart';
import 'package:glean_faith_app/core/network/cache/http_cache_store.dart';

/// Stands in for the network. Every `fetch` is counted, so a test can prove a
/// cache hit never reached the socket.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final Future<ResponseBody> Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  int get calls => requests.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? payload, {int status = 200, Map<String, String>? headers}) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
      for (final entry in (headers ?? const <String, String>{}).entries)
        entry.key: <String>[entry.value],
    },
  );
}

void main() {
  group('MemoryHttpCacheStore', () {
    test('evicts the least recently used entry', () async {
      final store = MemoryHttpCacheStore(maxEntries: 2);
      final now = DateTime(2026, 1, 1);

      HttpCacheEntry entry(String key) => HttpCacheEntry(
            key: key,
            statusCode: 200,
            body: '{}',
            headers: const <String, List<String>>{},
            storedAt: now,
          );

      await store.write(entry('a'));
      await store.write(entry('b'));
      await store.read('a'); // a is now most-recently-used
      await store.write(entry('c'));

      expect(await store.length, 2);
      expect(await store.read('b'), isNull);
      expect(await store.read('a'), isNotNull);
      expect(await store.read('c'), isNotNull);
    });

    test('clear empties the store', () async {
      final store = MemoryHttpCacheStore();
      await store.write(
        HttpCacheEntry(
          key: 'k',
          statusCode: 200,
          body: '{}',
          headers: const <String, List<String>>{},
          storedAt: DateTime(2026, 1, 1),
        ),
      );
      await store.clear();
      expect(await store.length, 0);
    });
  });

  group('HttpCachePolicy', () {
    const policy = HttpCachePolicy();

    RequestOptions request(String method, String path) => RequestOptions(
          method: method,
          path: path,
          baseUrl: 'https://api.test',
        );

    test('allows read-only content endpoints', () {
      final decision = policy.decide(request('GET', '/api/v1/content'));
      expect(decision.cacheable, isTrue);
      expect(decision.ttl, const Duration(minutes: 5));
    });

    test('never caches auth or a running quiz session', () {
      expect(policy.decide(request('GET', '/api/v1/auth/me')).cacheable, isFalse);
      expect(
        policy.decide(request('GET', '/api/v1/quiz-schedule/session/abc')).cacheable,
        isFalse,
      );
      expect(policy.decide(request('GET', '/api/v1/app/version/latest')).cacheable,
          isFalse);
    });

    test('never caches a write', () {
      expect(policy.decide(request('POST', '/api/v1/content')).cacheable, isFalse);
    });

    test('honours the bypass flag', () {
      final options = request('GET', '/api/v1/content');
      options.extra[HttpCachePolicy.bypassExtra] = true;
      expect(policy.decide(options).cacheable, isFalse);
    });

    test('the longest matching prefix wins', () {
      // /content/categories must not inherit the 5 minute /content budget.
      final decision = policy.decide(request('GET', '/api/v1/content/categories'));
      expect(decision.ttl, const Duration(minutes: 30));
    });

    test('answering a quiz question does not evict the cache', () {
      expect(
        policy.shouldInvalidate(
          'POST',
          '/api/v1/quiz-schedule/session/abc/answer',
        ),
        isFalse,
      );
      expect(policy.shouldInvalidate('POST', '/api/v1/bookmarks'), isTrue);
      expect(policy.shouldInvalidate('GET', '/api/v1/bookmarks'), isFalse);
    });
  });

  group('HttpCacheInterceptor', () {
    late DateTime now;
    late MemoryHttpCacheStore store;
    late HttpCacheInterceptor cache;
    late _FakeAdapter adapter;
    late Dio dio;

    void build(Future<ResponseBody> Function(RequestOptions) respond) {
      adapter = _FakeAdapter(respond);
      dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(cache);
    }

    setUp(() {
      now = DateTime(2026, 1, 1, 12);
      store = MemoryHttpCacheStore();
      cache = HttpCacheInterceptor(store: store, clock: () => now);
    });

    test('a fresh entry is served without touching the network', () async {
      build((_) async => _json(<String, dynamic>{'value': 1}));

      final first = await dio.get<dynamic>('/user/me');
      expect(adapter.calls, 1);
      expect((first.data as Map)['value'], 1);
      expect(first.extra[HttpCacheMarkers.hit], isNull);

      now = now.add(const Duration(seconds: 20));
      final second = await dio.get<dynamic>('/user/me');

      expect(adapter.calls, 1, reason: 'the second call must be a cache hit');
      expect(second.extra[HttpCacheMarkers.hit], isTrue);
      expect((second.data as Map)['value'], 1);
    });

    test('an expired entry is re-fetched', () async {
      build((_) async => _json(<String, dynamic>{'value': 1}));

      await dio.get<dynamic>('/user/me');
      now = now.add(const Duration(minutes: 5));
      await dio.get<dynamic>('/user/me');

      expect(adapter.calls, 2);
    });

    test('a 304 revalidation keeps the body and moves the clock', () async {
      build((request) async {
        if (request.headers['If-None-Match'] == 'v1') {
          return _json(null, status: 304);
        }
        return _json(
          <String, dynamic>{'value': 1},
          headers: <String, String>{'etag': 'v1'},
        );
      });

      await dio.get<dynamic>('/user/me');
      now = now.add(const Duration(minutes: 5));

      final revalidated = await dio.get<dynamic>('/user/me');
      expect(adapter.calls, 2);
      expect(adapter.requests.last.headers['If-None-Match'], 'v1');
      expect((revalidated.data as Map)['value'], 1);
      expect(revalidated.extra[HttpCacheMarkers.hit], isTrue);

      // The refreshed timestamp means the next call is a plain hit again.
      final hit = await dio.get<dynamic>('/user/me');
      expect(adapter.calls, 2);
      expect(hit.extra[HttpCacheMarkers.hit], isTrue);
    });

    test('a connection failure falls back to the stale payload', () async {
      var up = true;
      build((options) async {
        if (!up) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        }
        return _json(<String, dynamic>{'value': 1});
      });

      await dio.get<dynamic>('/user/me');
      up = false;
      now = now.add(const Duration(minutes: 5));

      final stale = await dio.get<dynamic>('/user/me');
      expect((stale.data as Map)['value'], 1);
      expect(stale.extra[HttpCacheMarkers.hit], isTrue);
      expect(stale.extra[HttpCacheMarkers.stale], isTrue);
    });

    test('an auth failure is never masked by a stale payload', () async {
      var status = 200;
      build((_) async => _json(<String, dynamic>{'value': 1}, status: status));

      await dio.get<dynamic>('/user/me');
      status = 401;
      now = now.add(const Duration(minutes: 5));

      await expectLater(
        dio.get<dynamic>('/user/me'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 401),
        ),
      );
    });

    test('cacheable writes are not stored', () async {
      build((_) async => _json(<String, dynamic>{'value': 1}));

      await dio.post<dynamic>('/content');
      await dio.get<dynamic>('/content');

      expect(adapter.calls, 2, reason: 'the GET must still go to the network');
    });

    test('a 200 write evicts the cached GETs', () async {
      build((_) async => _json(<String, dynamic>{'value': 1}));

      await dio.get<dynamic>('/bookmarks');
      await dio.post<dynamic>('/bookmarks');
      await dio.get<dynamic>('/bookmarks');

      expect(adapter.calls, 3, reason: 'the POST must invalidate the list');
    });

    test('the query string is part of the key', () async {
      build((request) async => _json(<String, dynamic>{'q': request.uri.query}));

      final en = await dio.get<dynamic>('/content', queryParameters: {'language': 'en'});
      final np = await dio.get<dynamic>('/content', queryParameters: {'language': 'np'});

      expect(adapter.calls, 2);
      expect((en.data as Map)['q'], 'language=en');
      expect((np.data as Map)['q'], 'language=np');
    });

    test('invalidateAll drops everything', () async {
      build((_) async => _json(<String, dynamic>{'value': 1}));

      await dio.get<dynamic>('/user/me');
      await cache.invalidateAll();
      await dio.get<dynamic>('/user/me');

      expect(adapter.calls, 2);
    });

    test('a no-store response is not cached', () async {
      build(
        (_) async => _json(
          <String, dynamic>{'value': 1},
          headers: <String, String>{'cache-control': 'no-store'},
        ),
      );

      await dio.get<dynamic>('/user/me');
      await dio.get<dynamic>('/user/me');

      expect(adapter.calls, 2);
    });
  });
}
