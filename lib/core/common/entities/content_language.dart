/// The language every piece of **Bible content** is rendered in.
///
/// This is a *content* switch, not a UI locale. It decides the language of
/// verse text, book names, references, Bible fun facts and quiz questions.
/// The app's own chrome — buttons, labels, menus, error messages, section
/// headers — stays in the app's default UI language (English) in both modes,
/// so a half-translated screen can never be mistaken for a bug.
///
/// There is exactly one of these in the app: `contentLanguageProvider`
/// (`core/common/providers/content_language_provider.dart`). Every surface that
/// renders Bible content reads it, and every `EN | NP` control writes to it, so
/// one switch governs the whole app.
enum ContentLanguage {
  english('en', 'EN'),
  nepali('np', 'NP');

  const ContentLanguage(this.code, this.shortLabel);

  /// Persisted / wire code.
  final String code;

  /// Compact label rendered inside the `EN | NP` toggle.
  final String shortLabel;

  /// True when the content should be shown in Nepali.
  bool get isNepali => this == ContentLanguage.nepali;

  /// True when the content should be shown in English.
  bool get isEnglish => this == ContentLanguage.english;

  /// Tolerant parser for stored preferences.
  ///
  /// Accepts every alias a legacy language key could hold — the quiz and verse
  /// keys stored `np`, the games key stored the ISO `ne`, and a device locale
  /// can carry a region/script suffix such as `ne_NP` or `ne-Latn` — so a value
  /// written by an older build still resolves. Anything unknown falls back to
  /// English: a corrupt preference must never leave the Bible content blank.
  static ContentLanguage fromCode(String? code) {
    final normalized = code?.trim().toLowerCase().replaceAll('_', '-') ?? '';
    if (normalized.isEmpty) return ContentLanguage.english;
    final root = normalized.split('-').first;
    switch (root) {
      case 'np':
      case 'ne':
      case 'nep':
      case 'nepali':
        return ContentLanguage.nepali;
      default:
        return ContentLanguage.english;
    }
  }
}
