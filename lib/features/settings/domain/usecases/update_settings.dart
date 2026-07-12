import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository _repository;

  UpdateSettings(this._repository);

  TaskEither<Failure, Unit> call(UserSettings settings) =>
      _repository.updateSettings(settings);
}
