import 'package:talker_flutter/talker_flutter.dart';

import 'core/services/database_service.dart';
import 'core/services/logger_service.dart';

class AppBootstrap {
  static late final DatabaseService databaseService;

  static Future<void> init() async {
    final talker = TalkerFlutter.init();
    LoggerService.init(talker);

    databaseService = DatabaseService();
    await databaseService.init();
  }

  static void dispose() {
    databaseService.dispose();
  }
}
