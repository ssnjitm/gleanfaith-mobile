import 'package:equatable/equatable.dart';

import '../../domain/entities/user_settings.dart';

class UserSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final String themeMode;
  final String language;
  final int quizReminderInterval;

  const UserSettingsModel({
    this.notificationsEnabled = true,
    this.themeMode = 'system',
    this.language = 'en',
    this.quizReminderInterval = 24,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      quizReminderInterval: json['quizReminderInterval'] as int? ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode,
      'language': language,
      'quizReminderInterval': quizReminderInterval,
    };
  }

  UserSettings toEntity() {
    return UserSettings(
      notificationsEnabled: notificationsEnabled,
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == themeMode,
        orElse: () => AppThemeMode.system,
      ),
      language: language,
      quizReminderInterval: quizReminderInterval,
    );
  }

  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      themeMode: entity.themeMode.name,
      language: entity.language,
      quizReminderInterval: entity.quizReminderInterval,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled, themeMode, language, quizReminderInterval];
}
