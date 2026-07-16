enum AppThemeMode { light, dark, system }

class UserSettings {
  final bool notificationsEnabled;
  final AppThemeMode themeMode;
  final String language;
  final int quizReminderInterval;

  const UserSettings({
    this.notificationsEnabled = true,
    this.themeMode = AppThemeMode.system,
    this.language = 'en',
    this.quizReminderInterval = 24,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    AppThemeMode? themeMode,
    String? language,
    int? quizReminderInterval,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      quizReminderInterval: quizReminderInterval ?? this.quizReminderInterval,
    );
  }
}
