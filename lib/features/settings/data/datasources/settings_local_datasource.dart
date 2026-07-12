import 'dart:convert';

import '../../../../core/services/storage_service.dart';
import '../models/user_settings_model.dart';

class SettingsLocalDataSource {
  final StorageService _storageService;
  static const String _settingsKey = 'user_settings';

  SettingsLocalDataSource(this._storageService);

  Future<UserSettingsModel> getSettings() async {
    final jsonString = await _storageService.read(_settingsKey);
    if (jsonString == null) return const UserSettingsModel();
    return UserSettingsModel.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    await _storageService.write(_settingsKey, json.encode(settings.toJson()));
  }
}
