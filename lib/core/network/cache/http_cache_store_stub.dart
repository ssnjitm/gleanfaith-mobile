import 'http_cache_store.dart';

/// Web build: there is no `dart:io`, so the cache lives only for the session.
///
/// Still worth having — it removes the duplicate fetches a tab switch produces
/// — it just cannot survive a reload.
HttpCacheStore createHttpCacheStore() => MemoryHttpCacheStore();
