// import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'core/services/logger_service.dart';
import 'core/services/database_service.dart';

class AppBootstrap {
  static late final DatabaseService databaseService;

  static Future<void> init() async {
    final talker = TalkerFlutter.init();
    LoggerService.init(talker);

    // Initialize database services
    databaseService = DatabaseService.instance;
    await databaseService.init();
    
    // Log stats if available
    try {
      final stats = await databaseService.getStats();
      LoggerService.info('Bible database stats: ${stats['topics']} topics, ${stats['verses']} verses');
    } catch (e) {
      LoggerService.warning('Could not get Bible database stats: $e');
    }
  }
}