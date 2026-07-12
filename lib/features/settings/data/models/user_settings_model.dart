import 'package:equatable/equatable.dart';

import '../../domain/entities/user_settings.dart';

class UserSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;
  final int quizReminderInterval;

  const UserSettingsModel({
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.language = 'en',
    this.quizReminderInterval = 24,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      quizReminderInterval: json['quizReminderInterval'] as int? ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'language': language,
      'quizReminderInterval': quizReminderInterval,
    };
  }

  UserSettings toEntity() {
    return UserSettings(
      notificationsEnabled: notificationsEnabled,
      darkMode: darkMode,
      language: language,
      quizReminderInterval: quizReminderInterval,
    );
  }

  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      darkMode: entity.darkMode,
      language: entity.language,
      quizReminderInterval: entity.quizReminderInterval,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled, darkMode, language, quizReminderInterval];
}
