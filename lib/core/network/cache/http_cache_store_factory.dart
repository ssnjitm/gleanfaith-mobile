/// Chooses the store for the current platform.
///
/// `dart:io` cannot be imported on web, so the disk implementation is pulled in
/// conditionally and the browser falls back to the in-memory store.
library;

export 'http_cache_store_stub.dart'
    if (dart.library.io) 'http_cache_store_io.dart';
