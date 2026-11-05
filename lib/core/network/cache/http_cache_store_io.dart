import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../services/logger_service.dart';
import 'http_cache_entry.dart';
import 'http_cache_store.dart';

/// Builds the platform's best available store.
///
/// Synchronous on purpose: `DioClient.create` is synchronous, and the whole
/// point of a cache is that it must not be able to delay client construction.
/// The disk is touched lazily on first use instead.
HttpCacheStore createHttpCacheStore() => DiskHttpCacheStore();

/// Persists the in-memory cache to the app support directory.
///
/// Never throws. A cache is an optimisation, so an unwritable directory, a
/// read-only container or a corrupt file all degrade to "no disk cache, keep
/// working" rather than to a failed app launch.
class DiskHttpCacheStore implements HttpCacheStore {
  DiskHttpCacheStore({
    this.maxEntries = 250,
    this.maxBytes = 2 * 1024 * 1024,
    this.flushDelay = const Duration(milliseconds: 400),
  });

  static const String _folderName = 'http_cache';
  static const String _fileName = 'responses.json';

  final int maxEntries;
  final int maxBytes;

  /// Writes are coalesced: a page that fires four requests should produce one
  /// file write, not four. `flutter_secure_storage` taught this codebase that
  /// lesson already (see the settings volume slider).
  final Duration flushDelay;

  final MemoryHttpCacheStore _memory = MemoryHttpCacheStore();
  final List<HttpCacheEntry> _pending = <HttpCacheEntry>[];

  File? _file;
  bool _loaded = false;
  Future<void>? _loading;
  Timer? _flushTimer;
  Future<void> _writeChain = Future<void>.value();

  @override
  Future<HttpCacheEntry?> read(String key) async {
    await _ensureLoaded();
    return _memory.read(key);
  }

  @override
  Future<void> write(HttpCacheEntry entry) async {
    await _ensureLoaded();
    await _memory.write(entry);
    _scheduleFlush();
  }

  @override
  Future<void> remove(String key) async {
    await _ensureLoaded();
    await _memory.remove(key);
    _scheduleFlush();
  }

  @override
  Future<void> clear() async {
    await _ensureLoaded();
    await _memory.clear();
    await _flushNow();
  }

  @override
  Future<int> get length async {
    await _ensureLoaded();
    return _memory.length;
  }

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final folder = Directory(
        '${directory.path}${Platform.pathSeparator}$_folderName',
      );
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      final file = File(
        '${folder.path}${Platform.pathSeparator}$_fileName',
      );
      _file = file;

      if (file.existsSync()) {
        final raw = await file.readAsString();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final entry = HttpCacheEntry.fromJson(
                  Map<String, dynamic>.from(item),
                );
                if (entry.key.isEmpty) continue;
                await _memory.write(entry);
              }
            }
          }
        }
      }
    } catch (error) {
      // Corrupt JSON, a locked file, a platform without path_provider: all mean
      // "no disk cache". Never surface this to the user.
      LoggerService.warning('HTTP cache running without disk persistence: $error');
      _file = null;
      await _memory.clear();
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  void _scheduleFlush() {
    if (_file == null) return;
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, () {
      unawaited(_flushNow());
    });
  }

  Future<void> _flushNow() {
    final file = _file;
    if (file == null) return Future<void>.value();
    _flushTimer?.cancel();
    // Chain the writes: two flushes must never interleave on the same file.
    _writeChain = _writeChain.then((_) => _write(file)).catchError((Object _) {});
    return _writeChain;
  }

  Future<void> _write(File file) async {
    try {
      final snapshot = _memory.snapshot();
      _pending.clear();

      // Serialise newest-first so the byte cap drops the oldest entries, which
      // are the ones the LRU would evict next anyway.
      var budget = maxBytes;
      for (final entry in snapshot.reversed) {
        final json = entry.toJson();
        final size = utf8.encode(jsonEncode(json)).length;
        if (size > budget) break;
        budget -= size;
        _pending.add(entry);
      }

      final encoded = jsonEncode(
        _pending.reversed.map((entry) => entry.toJson()).toList(),
      );
      await file.writeAsString(encoded, flush: false);
    } catch (error) {
      LoggerService.warning('HTTP cache write failed: $error');
    }
  }
}
