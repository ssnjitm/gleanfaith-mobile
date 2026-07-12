class UserSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;
  final int quizReminderInterval;

  const UserSettings({
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.language = 'en',
    this.quizReminderInterval = 24,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    String? language,
    int? quizReminderInterval,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      quizReminderInterval: quizReminderInterval ?? this.quizReminderInterval,
    );
  }
}
