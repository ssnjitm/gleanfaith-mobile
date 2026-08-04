import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'logger_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Database? _bibleDatabase;
  bool _isInitialized = false;
  bool _isFallbackMode = false;

  DatabaseService._internal();

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        await _initBibleDatabase();
        _isInitialized = true;
        LoggerService.info('✅ Database services initialized successfully');
      } else {
        _isFallbackMode = true;
        LoggerService.warning('🌐 Web platform - Bible database not available');
      }
    } catch (e) {
      LoggerService.error('❌ Failed to initialize database services: $e');
      _isFallbackMode = true;
      _isInitialized = true;
      LoggerService.warning('⚠️ Running in fallback mode - Bible features disabled');
    }
  }

  // Future<void> _initBibleDatabase() async {
  //   try {
  //     final documentsDir = await getApplicationDocumentsDirectory();
  //     final dbPath = join(documentsDir.path, 'topical_bible.db');
      
  //     LoggerService.info('📁 Database path: $dbPath');
      
  //     final dbFile = File(dbPath);
      
  //     // Check if database exists in documents directory
  //     if (!await dbFile.exists()) {
  //       LoggerService.info('📦 Database not found, copying from assets...');
        
  //       try {
  //         final assetData = await rootBundle.load('assets/databases/topical_bible.db');
  //         LoggerService.info('✅ Asset found! Size: ${assetData.lengthInBytes} bytes');
  //         await dbFile.writeAsBytes(assetData.buffer.asUint8List());
  //         LoggerService.info('✅ Database copied successfully');
  //       } catch (e) {
  //         LoggerService.error('Failed to copy database from assets: $e');
  //         throw Exception('Could not load Bible database: $e');
  //       }
  //     } else {
  //       final fileSize = await dbFile.length();
  //       LoggerService.info('📁 Existing database found: ${fileSize} bytes');
        
  //       if (fileSize == 0) {
  //         LoggerService.warning('⚠️ Database file is empty (0 bytes), re-copying...');
  //         await dbFile.delete();
  //         final assetData = await rootBundle.load('assets/databases/topical_bible.db');
  //         await dbFile.writeAsBytes(assetData.buffer.asUint8List());
  //         LoggerService.info('✅ Database re-copied');
  //       }
  //     }
      
  //     // Verify file exists and has content before opening
  //     if (!await dbFile.exists()) {
  //       throw Exception('Database file does not exist at: $dbPath');
  //     }
      
  //     final finalSize = await dbFile.length();
  //     LoggerService.info('📊 Final database size: $finalSize bytes');
      
  //     // Open database
  //     _bibleDatabase = await openDatabase(
  //       dbPath,
  //       readOnly: true,
  //       onConfigure: (db) async {
  //         await db.execute('PRAGMA journal_mode=WAL');
  //         await db.execute('PRAGMA synchronous=NORMAL');
  //         await db.execute('PRAGMA cache_size=10000');
  //       },
  //       onOpen: (db) async {
  //         try {
  //           // Check tables exist
  //           final tables = await db.rawQuery(
  //             "SELECT name FROM sqlite_master WHERE type='table'"
  //           );
  //           final tableNames = tables.map((t) => t['name'] as String).join(', ');
  //           LoggerService.info('📋 Tables found: $tableNames');
            
  //           // Check topics count
  //           final topicResult = await db.rawQuery('SELECT COUNT(*) as count FROM topics');
  //           final topicCount = topicResult.first['count'] as int? ?? 0;
  //           LoggerService.info('📚 Topics count: $topicCount');
            
  //           // Check verses count
  //           final versesResult = await db.rawQuery('SELECT COUNT(*) as count FROM bible_verses');
  //           final versesCount = versesResult.first['count'] as int? ?? 0;
  //           LoggerService.info('📖 Verses count: $versesCount');
            
  //           // Get sample topics
  //           if (topicCount > 0) {
  //             final sampleTopics = await db.rawQuery('SELECT topic_name FROM topics LIMIT 5');
  //             final samples = sampleTopics.map((t) => t['topic_name'] as String).join(', ');
  //             LoggerService.info('📝 Sample topics: $samples');
  //           }
            
  //           if (topicCount == 0 || versesCount == 0) {
  //             throw Exception('Database tables are empty! Topics: $topicCount, Verses: $versesCount');
  //           }
            
  //         } catch (e) {
  //           LoggerService.error('❌ Database verification failed: $e');
  //           rethrow;
  //         }
  //       },
  //     );
      
  //     LoggerService.info('✅ Bible database opened successfully');
      
  //   } catch (e) {
  //     LoggerService.error('❌ Failed to initialize Bible database: $e');
  //     rethrow;
  //   }
  // }

Future<void> _initBibleDatabase() async {
  try {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'topical_bible.db');
    
    LoggerService.info('📁 Database path: $dbPath');
    
    final dbFile = File(dbPath);
    
    // Check if database exists in documents directory
    if (!await dbFile.exists()) {
      LoggerService.info('📦 Database not found, copying from assets...');
      
      try {
        final assetData = await rootBundle.load('assets/databases/topical_bible.db');
        LoggerService.info('✅ Asset found! Size: ${assetData.lengthInBytes} bytes');
        await dbFile.writeAsBytes(assetData.buffer.asUint8List());
        LoggerService.info('✅ Database copied successfully');
      } catch (e) {
        LoggerService.error('Failed to copy database from assets: $e');
        throw Exception('Could not load Bible database: $e');
      }
    } else {
      final fileSize = await dbFile.length();
      LoggerService.info('📁 Existing database found: ${fileSize} bytes');
      
      if (fileSize == 0) {
        LoggerService.warning('⚠️ Database file is empty (0 bytes), re-copying...');
        await dbFile.delete();
        final assetData = await rootBundle.load('assets/databases/topical_bible.db');
        await dbFile.writeAsBytes(assetData.buffer.asUint8List());
        LoggerService.info('✅ Database re-copied');
      }
    }
    
    // Verify file exists and has content before opening
    if (!await dbFile.exists()) {
      throw Exception('Database file does not exist at: $dbPath');
    }
    
    final finalSize = await dbFile.length();
    LoggerService.info('📊 Final database size: $finalSize bytes');
    
    // Open database WITHOUT onConfigure (the PRAGMA statements are not needed for read-only)
    _bibleDatabase = await openDatabase(
      dbPath,
      readOnly: true,
      onOpen: (db) async {
        try {
          // Check tables exist
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"
          );
          final tableNames = tables.map((t) => t['name'] as String).join(', ');
          LoggerService.info('📋 Tables found: $tableNames');
          
          // Check topics count
          final topicResult = await db.rawQuery('SELECT COUNT(*) as count FROM topics');
          final topicCount = topicResult.first['count'] as int? ?? 0;
          LoggerService.info('📚 Topics count: $topicCount');
          
          // Check verses count
          final versesResult = await db.rawQuery('SELECT COUNT(*) as count FROM bible_verses');
          final versesCount = versesResult.first['count'] as int? ?? 0;
          LoggerService.info('📖 Verses count: $versesCount');
          
          // Get sample topics
          if (topicCount > 0) {
            final sampleTopics = await db.rawQuery('SELECT topic_name FROM topics LIMIT 5');
            final samples = sampleTopics.map((t) => t['topic_name'] as String).join(', ');
            LoggerService.info('📝 Sample topics: $samples');
          }
          
          if (topicCount == 0 || versesCount == 0) {
            throw Exception('Database tables are empty! Topics: $topicCount, Verses: $versesCount');
          }
          
        } catch (e) {
          LoggerService.error('❌ Database verification failed: $e');
          rethrow;
        }
      },
    );
    
    LoggerService.info('✅ Bible database opened successfully');
    
  } catch (e) {
    LoggerService.error('❌ Failed to initialize Bible database: $e');
    rethrow;
  }
}
  /// Get the Bible database instance
  Future<Database> get bibleDatabase async {
    if (_isFallbackMode) {
      throw DatabaseUnavailableException('Bible database is in fallback mode');
    }
    if (!_isInitialized) {
      await init();
    }
    if (_bibleDatabase == null) {
      throw DatabaseUnavailableException('Bible database not initialized');
    }
    return _bibleDatabase!;
  }

  /// Check if Bible database is available
  bool get isBibleAvailable => !_isFallbackMode && _isInitialized && _bibleDatabase != null;
  
  /// Check if running in fallback mode
  bool get isFallbackMode => _isFallbackMode;

  void dispose() {
    _bibleDatabase?.close();
    _isInitialized = false;
  }

  // ============================================================
  // BIBLE DATABASE QUERY METHODS (with fallback support)
  // ============================================================

  /// Search for topics matching a query string
  Future<List<Map<String, dynamic>>> searchTopics(String query) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT DISTINCT 
          t.id,
          t.topic_name,
          COUNT(tv.id) as verse_count
        FROM topics t
        JOIN topical_verses tv ON t.id = tv.topic_id
        WHERE t.topic_name LIKE ? COLLATE NOCASE
        GROUP BY t.id
        ORDER BY t.topic_name
        LIMIT 50
      ''', ['%$query%']);
    } catch (e) {
      LoggerService.error('searchTopics failed: $e');
      return [];
    }
  }

  /// Get all verses for a specific topic with full Bible text
  Future<List<Map<String, dynamic>>> getTopicVerses(
    String topicName, {
    int limit = 50,
  }) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT 
          t.topic_name,
          tv.verse_reference,
          bv.text AS verse_text,
          bv.book,
          bv.chapter,
          bv.verse,
          tv.votes
        FROM topics t
        JOIN topical_verses tv ON t.id = tv.topic_id
        JOIN bible_verses bv ON bv.book = tv.book 
                          AND bv.chapter = tv.chapter 
                          AND bv.verse >= tv.verse_start 
                          AND bv.verse <= tv.verse_end
        WHERE t.topic_name = ?
        ORDER BY tv.votes DESC, bv.chapter, bv.verse
        LIMIT ?
      ''', [topicName, limit]);
    } catch (e) {
      LoggerService.error('getTopicVerses failed: $e');
      return [];
    }
  }

  /// Search Bible text for verses containing keywords
  Future<List<Map<String, dynamic>>> searchBibleText(String query) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE text LIKE ? COLLATE NOCASE
        LIMIT 100
      ''', ['%$query%']);
    } catch (e) {
      LoggerService.error('searchBibleText failed: $e');
      return [];
    }
  }

  /// Get popular topics (by vote count and verse count)
  Future<List<Map<String, dynamic>>> getPopularTopics({int limit = 20}) async {
    if (!isBibleAvailable) {
      LoggerService.warning('⚠️ Bible database not available');
      return [];
    }
    
    try {
      final db = await bibleDatabase;
      LoggerService.info('🔍 Running getPopularTopics query...');
      
      final results = await db.rawQuery('''
        SELECT 
          t.topic_name,
          COUNT(tv.id) as verse_count,
          SUM(tv.votes) as total_votes
        FROM topics t
        JOIN topical_verses tv ON t.id = tv.topic_id
        GROUP BY t.id
        HAVING verse_count > 0
        ORDER BY total_votes DESC, verse_count DESC
        LIMIT ?
      ''', [limit]);
      
      LoggerService.info('✅ getPopularTopics returned ${results.length} results');
      if (results.isNotEmpty) {
        LoggerService.info('📝 First result: ${results.first['topic_name']}');
      }
      
      return results;
    } catch (e) {
      LoggerService.error('❌ getPopularTopics failed: $e');
      return [];
    }
  }

  /// Get topics that appear in a specific Bible book
  Future<List<Map<String, dynamic>>> getTopicsByBook(String book) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT DISTINCT
          t.topic_name,
          COUNT(tv.id) as verse_count
        FROM topics t
        JOIN topical_verses tv ON t.id = tv.topic_id
        WHERE tv.book = ?
        GROUP BY t.id
        ORDER BY verse_count DESC
        LIMIT 50
      ''', [book]);
    } catch (e) {
      LoggerService.error('getTopicsByBook failed: $e');
      return [];
    }
  }

  /// Get verse context (surrounding verses) for a specific reference
  Future<List<Map<String, dynamic>>> getVerseContext({
    required String book,
    required int chapter,
    required int verse,
    int contextRange = 2,
  }) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? 
          AND chapter = ? 
          AND verse BETWEEN ? AND ?
        ORDER BY verse
      ''', [book, chapter, verse - contextRange, verse + contextRange]);
    } catch (e) {
      LoggerService.error('getVerseContext failed: $e');
      return [];
    }
  }

  /// Get a single verse by reference
  Future<Map<String, dynamic>?> getVerse({
    required String book,
    required int chapter,
    required int verse,
  }) async {
    if (!isBibleAvailable) return null;
    try {
      final db = await bibleDatabase;
      final results = await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? AND chapter = ? AND verse = ?
        LIMIT 1
      ''', [book, chapter, verse]);
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      LoggerService.error('getVerse failed: $e');
      return null;
    }
  }

  /// Get random verses (for daily verse feature)
  Future<List<Map<String, dynamic>>> getRandomVerses({int count = 1}) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      return await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        ORDER BY RANDOM()
        LIMIT ?
      ''', [count]);
    } catch (e) {
      LoggerService.error('getRandomVerses failed: $e');
      return [];
    }
  }

  /// Get total counts for statistics
  Future<Map<String, int>> getStats() async {
    if (!isBibleAvailable) {
      return {
        'topics': 0,
        'verses': 0,
        'topicVerses': 0,
      };
    }
    try {
      final db = await bibleDatabase;
      final topicsResult = await db.rawQuery('SELECT COUNT(*) as count FROM topics');
      final versesResult = await db.rawQuery('SELECT COUNT(*) as count FROM bible_verses');
      final topicalResult = await db.rawQuery('SELECT COUNT(*) as count FROM topical_verses');
      
      return {
        'topics': topicsResult.first['count'] as int? ?? 0,
        'verses': versesResult.first['count'] as int? ?? 0,
        'topicVerses': topicalResult.first['count'] as int? ?? 0,
      };
    } catch (e) {
      LoggerService.error('getStats failed: $e');
      return {'topics': 0, 'verses': 0, 'topicVerses': 0};
    }
  }
}

/// Custom exception for database unavailability
class DatabaseUnavailableException implements Exception {
  final String message;
  DatabaseUnavailableException(this.message);
  @override
  String toString() => 'DatabaseUnavailableException: $message';
}