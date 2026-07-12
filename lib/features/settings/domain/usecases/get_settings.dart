import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository _repository;

  GetSettings(this._repository);

  TaskEither<Failure, UserSettings> call() => _repository.getSettings();
}
