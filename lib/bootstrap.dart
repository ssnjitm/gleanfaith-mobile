import 'package:talker_flutter/talker_flutter.dart';
import 'core/services/logger_service.dart';
import 'core/services/database_service.dart';

class AppBootstrap {
  static late final DatabaseService databaseService;
  static bool _isInitialized = false;

  static Future<void> init() async {
    // Prevent double initialization
    if (_isInitialized) return;

    try {
      final talker = TalkerFlutter.init();
      LoggerService.init(talker);
      
      LoggerService.info('🚀 Starting app bootstrap...');
      
      // Initialize database services
      databaseService = DatabaseService.instance;
      await databaseService.init();
      
      _isInitialized = true;
      
      // Log stats if available
      try {
        if (databaseService.isBibleAvailable) {
          final stats = await databaseService.getStats();
          LoggerService.info('📚 Bible database loaded: ${stats['topics']} topics, ${stats['verses']} verses');
        } else {
          LoggerService.warning('⚠️ Bible database not available (fallback mode)');
        }
      } catch (e) {
        LoggerService.warning('⚠️ Could not get Bible database stats: $e');
      }
      
      LoggerService.info('✅ App bootstrap completed successfully');
    } catch (e) {
      LoggerService.error('❌ App bootstrap failed: $e');
      // Don't rethrow - let the app continue
    }
  }

  static bool get isInitialized => _isInitialized;
}