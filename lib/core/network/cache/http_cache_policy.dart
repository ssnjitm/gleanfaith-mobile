import 'package:dio/dio.dart';

/// Which requests may be stored, and for how long.
///
/// Opt-in rather than opt-out. A default of "cache every GET" would silently
/// cache a quiz session or an auth response the first time somebody adds an
/// endpoint, and stale auth state is far more expensive to debug than a missed
/// cache entry. Everything not listed here goes straight to the network.
class HttpCachePolicy {
  const HttpCachePolicy();

  /// Set `options.extra[HttpCachePolicy.bypassExtra] = true` to force a live
  /// request (e.g. pull-to-refresh).
  static const String bypassExtra = 'http_cache_bypass';

  /// Paths that must never be cached, whatever else matches. Checked first.
  ///
  /// - `/auth` — tokens, OTP state, password flows.
  /// - `/quiz-schedule/session` — a running attempt; the question wording, the
  ///   answer key and the timer all mutate server-side, and a cached copy could
  ///   score against the wrong payload.
  /// - `/app/version/latest` — a self-update prompt served from cache would
  ///   keep offering a release the user already installed.
  static const List<String> neverCachePrefixes = <String>[
    '/auth',
    '/quiz-schedule/session',
    '/app/version',
    '/admin',
  ];

  /// Longest prefix wins, so `/content/categories` can outlive `/content`.
  static final List<({String prefix, Duration ttl})> rules =
      <({String prefix, Duration ttl})>[
    (prefix: '/content/categories', ttl: const Duration(minutes: 30)),
    (prefix: '/quiz-sets', ttl: const Duration(minutes: 30)),
    (prefix: '/content', ttl: const Duration(minutes: 5)),
    (prefix: '/courses', ttl: const Duration(minutes: 5)),
    (prefix: '/crosspuzzle', ttl: const Duration(minutes: 5)),
    (prefix: '/quiz-schedule/series', ttl: const Duration(minutes: 5)),
    (prefix: '/daily-quiz/upcoming', ttl: const Duration(minutes: 5)),
    (prefix: '/quiz-schedule/upcoming', ttl: const Duration(minutes: 2)),
    (prefix: '/daily-quiz/today', ttl: const Duration(minutes: 2)),
    (prefix: '/notifications', ttl: const Duration(minutes: 2)),
    (prefix: '/bookmarks', ttl: const Duration(minutes: 2)),
    (prefix: '/reading-history', ttl: const Duration(minutes: 1)),
    (prefix: '/notes', ttl: const Duration(minutes: 1)),
    (prefix: '/leaderboard', ttl: const Duration(minutes: 1)),
    (prefix: '/user', ttl: const Duration(minutes: 1)),
  ]..sort(
        (a, b) => b.prefix.length.compareTo(a.prefix.length),
      );

  /// Writes that should not drop the whole cache.
  ///
  /// Answering a quiz question is a write, but evicting every cached list on
  /// each of ten answers would make the cache useless for the rest of the
  /// attempt.
  static const List<String> noInvalidatePrefixes = <String>[
    '/quiz-schedule/session',
    '/auth',
  ];

  CacheDecision decide(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') {
      return const CacheDecision.denied('not a GET');
    }
    if (options.extra[bypassExtra] == true) {
      return const CacheDecision.denied('bypassed');
    }
    if (options.responseType != ResponseType.json) {
      return const CacheDecision.denied('not json');
    }

    final path = normalizePath(options.uri.path);
    for (final prefix in neverCachePrefixes) {
      if (_matches(path, prefix)) {
        return const CacheDecision.denied('never cached');
      }
    }
    for (final rule in rules) {
      if (_matches(path, rule.prefix)) {
        return CacheDecision.allowed(rule.ttl);
      }
    }
    return const CacheDecision.denied('no rule');
  }

  /// Whether a successful write should evict everything.
  bool shouldInvalidate(String method, String path) {
    if (method.toUpperCase() == 'GET') return false;
    final normalized = normalizePath(path);
    for (final prefix in noInvalidatePrefixes) {
      if (_matches(normalized, prefix)) return false;
    }
    return true;
  }

  /// Strips the API base path so rules read as `/content`, not `/api/v1/content`.
  static String normalizePath(String path) {
    const base = '/api/v1';
    if (path == base) return '/';
    if (path.startsWith('$base/')) return path.substring(base.length);
    return path;
  }

  static bool _matches(String path, String prefix) =>
      path == prefix || path.startsWith('$prefix/');
}

/// The outcome of [HttpCachePolicy.decide].
class CacheDecision {
  const CacheDecision.denied(this.reason)
      : cacheable = false,
        ttl = null;

  const CacheDecision.allowed(Duration this.ttl)
      : cacheable = true,
        reason = 'allowed';

  final bool cacheable;

  /// Only set when [cacheable] is true.
  final Duration? ttl;

  /// Why the decision went the way it did — surfaced in debug logs.
  final String reason;
}
