enum AppThemeMode { light, dark, system }

class UserSettings {
  final bool notificationsEnabled;
  final AppThemeMode themeMode;
  final String language;
  final int quizReminderInterval;

  /// Whether bundled sound effects (correct / incorrect / countdown / ending)
  /// play during quizzes and Bible games.
  final bool audioEnabled;

  /// Effect volume, 0.0 – 1.0.
  final double soundVolume;

  const UserSettings({
    this.notificationsEnabled = true,
    this.themeMode = AppThemeMode.system,
    this.language = 'en',
    this.quizReminderInterval = 24,
    this.audioEnabled = true,
    this.soundVolume = 1.0,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    AppThemeMode? themeMode,
    String? language,
    int? quizReminderInterval,
    bool? audioEnabled,
    double? soundVolume,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      quizReminderInterval: quizReminderInterval ?? this.quizReminderInterval,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }
}
