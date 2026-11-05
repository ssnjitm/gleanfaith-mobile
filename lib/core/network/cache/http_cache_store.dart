import 'dart:collection';

import 'http_cache_entry.dart';

/// Persistence for [HttpCacheEntry] records.
///
/// Deliberately tiny: this is not a general-purpose HTTP cache. It stores a
/// handful of JSON list payloads so a page can render instantly on a return
/// visit instead of re-fetching, and so an offline launch degrades to the last
/// known data instead of an error screen.
abstract class HttpCacheStore {
  Future<HttpCacheEntry?> read(String key);

  Future<void> write(HttpCacheEntry entry);

  Future<void> remove(String key);

  Future<void> clear();

  Future<int> get length;
}

/// Smallest possible store: bounded LRU held in memory.
///
/// This is what web gets (there is no `dart:io` there) and what every platform
/// falls back to if the disk store cannot be opened. It still removes duplicate
/// fetches within a session, which is the bulk of the win.
class MemoryHttpCacheStore implements HttpCacheStore {
  MemoryHttpCacheStore({this.maxEntries = 250});

  final int maxEntries;

  /// Insertion-ordered, so the first key is the least recently used.
  final LinkedHashMap<String, HttpCacheEntry> _entries =
      LinkedHashMap<String, HttpCacheEntry>();

  @override
  Future<HttpCacheEntry?> read(String key) async {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    // Re-inserting moves it to the end — i.e. marks it most-recently-used.
    _entries[key] = entry;
    return entry;
  }

  @override
  Future<void> write(HttpCacheEntry entry) async {
    if (entry.key.isEmpty) return;
    _entries.remove(entry.key);
    _entries[entry.key] = entry;
    _evict();
  }

  @override
  Future<void> remove(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<int> get length async => _entries.length;

  /// Entries in least-recently-used-first order.
  ///
  /// Used by the disk store to persist the cache and to apply its byte cap
  /// without duplicating the LRU bookkeeping.
  List<HttpCacheEntry> snapshot() => List<HttpCacheEntry>.of(_entries.values);

  void _evict() {
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}
