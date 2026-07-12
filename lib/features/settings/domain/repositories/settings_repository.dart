import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_settings.dart';

abstract class SettingsRepository {
  TaskEither<Failure, UserSettings> getSettings();
  TaskEither<Failure, Unit> updateSettings(UserSettings settings);
}
