import 'package:equatable/equatable.dart';

import '../../domain/entities/user_settings.dart';

class UserSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final String themeMode;
  final String language;
  final int quizReminderInterval;
  final bool audioEnabled;
  final double soundVolume;

  const UserSettingsModel({
    this.notificationsEnabled = true,
    this.themeMode = 'system',
    this.language = 'en',
    this.quizReminderInterval = 24,
    this.audioEnabled = true,
    this.soundVolume = 1.0,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      quizReminderInterval: json['quizReminderInterval'] as int? ?? 24,
      audioEnabled: json['audioEnabled'] as bool? ?? true,
      // `as num?` because a stored 1 decodes as int, and a hard `as double?`
      // cast would throw and flip the whole settings page into an error state.
      // Clamped because a Slider throws if its value is outside 0..1, and this
      // is untrusted storage.
      soundVolume: _clampVolume((json['soundVolume'] as num?)?.toDouble() ?? 1.0),
    );
  }

  /// Keeps volume inside the 0.0 – 1.0 range a [Slider] accepts.
  static double _clampVolume(double value) {
    if (value.isNaN) return 1.0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode,
      'language': language,
      'quizReminderInterval': quizReminderInterval,
      'audioEnabled': audioEnabled,
      'soundVolume': soundVolume,
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
      audioEnabled: audioEnabled,
      soundVolume: soundVolume,
    );
  }

  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      themeMode: entity.themeMode.name,
      language: entity.language,
      quizReminderInterval: entity.quizReminderInterval,
      audioEnabled: entity.audioEnabled,
      soundVolume: _clampVolume(entity.soundVolume),
    );
  }

  @override
  List<Object?> get props => [
    notificationsEnabled,
    themeMode,
    language,
    quizReminderInterval,
    audioEnabled,
    soundVolume,
  ];
}
