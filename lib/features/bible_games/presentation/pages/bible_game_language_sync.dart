import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bible_game_entities.dart';
import '../../domain/entities/bible_game_localization.dart';
import '../providers/bible_game_language_provider.dart';
import '../providers/bible_games_provider.dart';

/// Keeps a game page in sync when the `EN | NP` toggle changes the language.
///
/// A page bakes the localized book names and round copy into its state when a
/// round is built, so a language switch has to rebuild that round — watching
/// the provider alone would only translate the surrounding labels and leave the
/// book names in the previous language.
mixin BibleGameLanguageSync<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// The language the currently displayed round was built with.
  BibleGameLanguage get roundLanguage;

  /// Reloads the localized catalog and rebuilds the visible round in [language].
  ///
  /// Called for both an explicit choice and a switch back to the device
  /// language, so it must be safe to run while a round is in progress. It
  /// deliberately keeps the [GameSession] — score and streak carry over, and
  /// only the round is replaced.
  Future<void> applyBibleGameLanguage(BibleGameLanguage language);

  /// The books localized for [language], straight from the shared provider.
  Future<List<BibleGameBook>> localizedBooks() async {
    final data = await ref.read(localizedBibleGamesDataProvider.future);
    return data.books;
  }

  /// Watches the language and re-applies it. Call this from `build`.
  void watchBibleGameLanguage() {
    ref.listen<BibleGameLanguage>(bibleGameLanguageProvider, (prev, next) {
      if (prev == null || prev == next) return;
      if (next == roundLanguage) return;
      unawaited(applyBibleGameLanguage(next));
    });
  }
}
