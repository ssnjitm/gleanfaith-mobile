import 'package:talker/talker.dart';

class LoggerService {
  static late final Talker _talker;

  static void init(Talker talker) {
    _talker = talker;
  }

  static void info(String message) => _talker.info(message);

  static void warning(String message) => _talker.warning(message);

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _talker.error(message, error, stackTrace);
  }

  static void debug(String message) => _talker.debug(message);

  static void verbose(String message) => _talker.verbose(message);
}
