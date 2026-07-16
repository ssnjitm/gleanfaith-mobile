import 'package:talker/talker.dart';

class LoggerService {
  static Talker? _talker;

  static void init(Talker talker) {
    _talker ??= talker;
  }

  static Talker get instance {
    _talker ??= Talker();
    return _talker!;
  }

  static void info(String message) => instance.info(message);

  static void warning(String message) => instance.warning(message);

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.error(message, error, stackTrace);
  }

  static void debug(String message) => instance.debug(message);

  static void verbose(String message) => instance.verbose(message);
}
