import 'dart:io';
import 'dart:math';
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

  /// Search Bible text for verses containing keywords.
  ///
  /// Uses an AND match across all meaningful words for precision first,
  /// then falls back to an OR match ranked by relevance if nothing is found.
  /// Results are ranked by how early the phrase appears in the verse.
  Future<List<Map<String, dynamic>>> searchBibleText(String query) async {
    if (!isBibleAvailable) return [];
    try {
      final db = await bibleDatabase;
      final words = query
          .split(RegExp(r'\s+'))
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty && w.length >= 2)
          .toList();
      if (words.isEmpty) return [];

      // Precise: all words must appear (best for phrases).
      final andConditions = words.map((_) => 'text LIKE ? COLLATE NOCASE').join(' AND ');
      final andArgs = <Object>[...words.map((w) => '%$w%'), query.toLowerCase()];
      var results = await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE $andConditions
        ORDER BY instr(lower(text), lower(?)) ASC, length(text) ASC, chapter, verse
        LIMIT 100
      ''', andArgs);

      // Fallback: any word matches (best for keyword lists).
      if (results.isEmpty && words.length > 1) {
        final orConditions = words.map((_) => 'text LIKE ? COLLATE NOCASE').join(' OR ');
        final orArgs = <Object>[...words.map((w) => '%$w%'), query.toLowerCase()];
        results = await db.rawQuery('''
          SELECT 
            book,
            chapter,
            verse,
            text
          FROM bible_verses
          WHERE $orConditions
          ORDER BY instr(lower(text), lower(?)) ASC, length(text) ASC, chapter, verse
          LIMIT 100
        ''', orArgs);
      }
      return results;
    } catch (e) {
      LoggerService.error('searchBibleText failed: $e');
      return [];
    }
  }

  /// Search by a Bible reference such as "John 3:16", "Psalm 23",
  /// "1 Cor 13:4-7" or "Matthew 5:3-11".
  Future<List<Map<String, dynamic>>> searchByReference(String query) async {
    if (!isBibleAvailable) return [];
    try {
      final reference = _parseReference(query);
      if (reference == null) return [];

      final db = await bibleDatabase;

      if (reference.verse != null) {
        final verseEnd = reference.verseEnd ?? reference.verse;
        return await db.rawQuery('''
          SELECT 
            book,
            chapter,
            verse,
            text
          FROM bible_verses
          WHERE book = ? AND chapter = ? AND verse BETWEEN ? AND ?
          ORDER BY verse
          LIMIT 100
        ''', [reference.book, reference.chapter, reference.verse, verseEnd]);
      }

      return await db.rawQuery('''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? AND chapter = ?
        ORDER BY verse
        LIMIT 100
      ''', [reference.book, reference.chapter]);
    } catch (e) {
      LoggerService.error('searchByReference failed: $e');
      return [];
    }
  }

  /// Get a deterministic pseudo-random verse of the day.
  ///
  /// The verse stays constant for the whole day (so the VOTD doesn't change
  /// mid-day) but is drawn from a random book, chapter and verse each day by
  /// seeding the RNG with the current date. This guarantees the verse comes
  /// from a different book/chapter/verse every day instead of repeating from
  /// a single book.
  Future<Map<String, dynamic>?> getVerseOfTheDay() async {
    if (!isBibleAvailable) return null;
    try {
      final db = await bibleDatabase;

      // Date-seeded RNG so the pick is stable within a day, random across days.
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final random = Random(seed);

      // 1. Pick a random book from the whole Bible.
      final books = await db.rawQuery(
        'SELECT DISTINCT book FROM bible_verses ORDER BY book',
      );
      if (books.isEmpty) return null;
      final book = books[random.nextInt(books.length)]['book'] as String;

      // 2. Pick a random chapter within that book.
      final chapters = await db.rawQuery(
        'SELECT DISTINCT chapter FROM bible_verses WHERE book = ? ORDER BY chapter',
        [book],
      );
      if (chapters.isEmpty) return null;
      final chapter = chapters[random.nextInt(chapters.length)]['chapter'] as int;

      // 3. Pick a random verse within that chapter.
      final verses = await db.rawQuery(
        '''
        SELECT 
          book,
          chapter,
          verse,
          text
        FROM bible_verses
        WHERE book = ? AND chapter = ?
        ORDER BY verse
        ''',
        [book, chapter],
      );
      if (verses.isEmpty) return null;
      return verses[random.nextInt(verses.length)];
    } catch (e) {
      LoggerService.error('getVerseOfTheDay failed: $e');
      return null;
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

/// A parsed Bible reference (e.g. "John 3:16-18").
class BibleReference {
  final String book;
  final int chapter;
  final int? verse;
  final int? verseEnd;

  const BibleReference({
    required this.book,
    required this.chapter,
    this.verse,
    this.verseEnd,
  });
}

const List<String> _kjvBooks = [
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth',
  '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles',
  '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther',
  'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
  'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum',
  'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
  'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
  '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
  'Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John',
  '3 John', 'Jude', 'Revelation',
];

const Map<String, String> _bookAbbreviations = {
  'gen': 'Genesis',
  'genesis': 'Genesis',
  'exo': 'Exodus',
  'exod': 'Exodus',
  'exodus': 'Exodus',
  'lev': 'Leviticus',
  'leviticus': 'Leviticus',
  'num': 'Numbers',
  'numbers': 'Numbers',
  'deu': 'Deuteronomy',
  'deut': 'Deuteronomy',
  'deuteronomy': 'Deuteronomy',
  'josh': 'Joshua',
  'joshua': 'Joshua',
  'judg': 'Judges',
  'judges': 'Judges',
  'ruth': 'Ruth',
  '1 sam': '1 Samuel',
  '1 samuel': '1 Samuel',
  '2 sam': '2 Samuel',
  '2 samuel': '2 Samuel',
  '1 kin': '1 Kings',
  '1 kgs': '1 Kings',
  '1 kings': '1 Kings',
  '2 kin': '2 Kings',
  '2 kgs': '2 Kings',
  '2 kings': '2 Kings',
  '1 chr': '1 Chronicles',
  '1 chron': '1 Chronicles',
  '1 chronicles': '1 Chronicles',
  '2 chr': '2 Chronicles',
  '2 chron': '2 Chronicles',
  '2 chronicles': '2 Chronicles',
  'ezra': 'Ezra',
  'neh': 'Nehemiah',
  'nehemiah': 'Nehemiah',
  'est': 'Esther',
  'esther': 'Esther',
  'job': 'Job',
  'ps': 'Psalms',
  'psa': 'Psalms',
  'psalm': 'Psalms',
  'psalms': 'Psalms',
  'prov': 'Proverbs',
  'proverbs': 'Proverbs',
  'eccl': 'Ecclesiastes',
  'ecclesiastes': 'Ecclesiastes',
  'song': 'Song of Solomon',
  'sos': 'Song of Solomon',
  'song of solomon': 'Song of Solomon',
  'song of songs': 'Song of Solomon',
  'isa': 'Isaiah',
  'isiah': 'Isaiah',
  'isaiah': 'Isaiah',
  'jer': 'Jeremiah',
  'jeremiah': 'Jeremiah',
  'lam': 'Lamentations',
  'lamentations': 'Lamentations',
  'ezek': 'Ezekiel',
  'eze': 'Ezekiel',
  'ezekiel': 'Ezekiel',
  'dan': 'Daniel',
  'daniel': 'Daniel',
  'hos': 'Hosea',
  'hosea': 'Hosea',
  'joel': 'Joel',
  'amos': 'Amos',
  'obad': 'Obadiah',
  'obadiah': 'Obadiah',
  'jonah': 'Jonah',
  'mic': 'Micah',
  'micah': 'Micah',
  'nahum': 'Nahum',
  'nah': 'Nahum',
  'hab': 'Habakkuk',
  'habakkuk': 'Habakkuk',
  'zeph': 'Zephaniah',
  'zephaniah': 'Zephaniah',
  'hag': 'Haggai',
  'haggai': 'Haggai',
  'zech': 'Zechariah',
  'zechariah': 'Zechariah',
  'mal': 'Malachi',
  'malachi': 'Malachi',
  'matt': 'Matthew',
  'matthew': 'Matthew',
  'mark': 'Mark',
  'luke': 'Luke',
  'john': 'John',
  'acts': 'Acts',
  'rom': 'Romans',
  'romans': 'Romans',
  '1 cor': '1 Corinthians',
  '1 corinthians': '1 Corinthians',
  '2 cor': '2 Corinthians',
  '2 corinthians': '2 Corinthians',
  'gal': 'Galatians',
  'galatians': 'Galatians',
  'eph': 'Ephesians',
  'ephesians': 'Ephesians',
  'phil': 'Philippians',
  'philippians': 'Philippians',
  'col': 'Colossians',
  'colossians': 'Colossians',
  '1 thess': '1 Thessalonians',
  '1 thessalonians': '1 Thessalonians',
  '2 thess': '2 Thessalonians',
  '2 thessalonians': '2 Thessalonians',
  '1 tim': '1 Timothy',
  '1 timothy': '1 Timothy',
  '2 tim': '2 Timothy',
  '2 timothy': '2 Timothy',
  'titus': 'Titus',
  'philemon': 'Philemon',
  'phm': 'Philemon',
  'heb': 'Hebrews',
  'hebrews': 'Hebrews',
  'jas': 'James',
  'james': 'James',
  '1 pet': '1 Peter',
  '1 peter': '1 Peter',
  '2 pet': '2 Peter',
  '2 peter': '2 Peter',
  '1 jn': '1 John',
  '1 john': '1 John',
  '2 jn': '2 John',
  '2 john': '2 John',
  '3 jn': '3 John',
  '3 john': '3 John',
  'jude': 'Jude',
  'rev': 'Revelation',
  'revelation': 'Revelation',
};

/// Normalize a book name (handles abbreviations and partial names).
String? _normalizeBook(String input) {
  final lower = input.toLowerCase().trim();
  if (lower.isEmpty) return null;
  if (_bookAbbreviations.containsKey(lower)) return _bookAbbreviations[lower];

  final matches =
      _kjvBooks.where((b) => b.toLowerCase().startsWith(lower)).toList();
  if (matches.length == 1) return matches.first;
  return null;
}

/// Parse a free-text query into a structured [BibleReference].
BibleReference? _parseReference(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return null;

  // "Book C:V" or "Book C:V-V2"
  final refMatch =
      RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$').firstMatch(trimmed);
  if (refMatch != null) {
    final book = _normalizeBook(refMatch.group(1)!);
    if (book != null) {
      final verseEnd = refMatch.group(4);
      return BibleReference(
        book: book,
        chapter: int.parse(refMatch.group(2)!),
        verse: int.parse(refMatch.group(3)!),
        verseEnd: verseEnd != null ? int.parse(verseEnd) : null,
      );
    }
  }

  // "Book C"
  final chapterMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(trimmed);
  if (chapterMatch != null) {
    final book = _normalizeBook(chapterMatch.group(1)!);
    if (book != null) {
      return BibleReference(
        book: book,
        chapter: int.parse(chapterMatch.group(2)!),
      );
    }
  }

  return null;
}