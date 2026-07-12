import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/user_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  TaskEither<Failure, UserSettings> getSettings() {
    return TaskEither.tryCatch(
      () async {
        final model = await _localDataSource.getSettings();
        return model.toEntity();
      },
      (error, stackTrace) => CacheFailure(message: error.toString()),
    );
  }

  @override
  TaskEither<Failure, Unit> updateSettings(UserSettings settings) {
    return TaskEither.tryCatch(
      () async {
        final model = UserSettingsModel.fromEntity(settings);
        await _localDataSource.saveSettings(model);
        return unit;
      },
      (error, stackTrace) => CacheFailure(message: error.toString()),
    );
  }
}
