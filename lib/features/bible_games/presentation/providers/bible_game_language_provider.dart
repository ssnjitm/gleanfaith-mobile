import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/entities/content_language.dart';
import '../../../../core/common/providers/content_language_provider.dart';
import '../../domain/entities/bible_game_localization.dart';

/// The language the Bible games render their **content** in.
///
/// It is derived from the global content language: the games are one of the
/// Bible-content surfaces the single global `EN | NP` control switches, so the
/// book names, the verse texts and the fun facts follow whatever the user
/// picked in Settings (or on the Home verse card).
///
/// The games used to own a separate persisted preference that defaulted to the
/// **device locale**, which meant the games could be in Nepali while the verse
/// card was in English. That preference is gone — one state, one control.
final bibleGameLanguageProvider = Provider<BibleGameLanguage>((ref) {
  return ref.watch(contentLanguageProvider) == ContentLanguage.nepali
      ? BibleGameLanguage.nepali
      : BibleGameLanguage.english;
});

/// Copy for the games' **chrome** — titles, buttons, dialogs, hints.
///
/// The app's own chrome is **always** English, in both modes: a half
/// translated UI reads as a bug, so the global control only ever switches
/// *content* (book names, verse text, fun-fact sentences) — never the app's
/// own labels.
///
/// The in-game content the engine generates (the round hints, the fun facts)
/// is produced from [BibleGameStrings.of] with the **content** language, so it
/// does follow the global control.
final bibleGameStringsProvider = Provider<BibleGameStrings>((ref) {
  return BibleGameStrings.english;
});
