import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storageService = ref.watch(storageProvider);
  return SettingsRepositoryImpl(SettingsLocalDataSource(storageService));
});

final getSettingsProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final updateSettingsProvider = Provider<UpdateSettings>((ref) {
  return UpdateSettings(ref.watch(settingsRepositoryProvider));
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
  final getSettings = ref.watch(getSettingsProvider);
  final updateSettings = ref.watch(updateSettingsProvider);
  return SettingsNotifier(getSettings, updateSettings);
});

class SettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;

  SettingsNotifier(this._getSettings, this._updateSettings)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    final result = await _getSettings().run();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (settings) => state = AsyncValue.data(settings),
    );
  }

  Future<void> updateSettings(UserSettings settings) async {
    final result = await _updateSettings(settings).run();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = AsyncValue.data(settings),
    );
  }
}
