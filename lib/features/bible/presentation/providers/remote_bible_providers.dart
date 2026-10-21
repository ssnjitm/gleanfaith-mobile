import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/entities/content_language.dart';
import '../../../../core/common/providers/content_language_provider.dart';
import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/datasources/remote_bible_datasource.dart';
import '../../data/repositories/remote_bible_repository_impl.dart';
import '../../domain/repositories/remote_bible_repository.dart';
import '../../domain/usecases/get_remote_book_names.dart';
import '../../domain/usecases/get_remote_chapter.dart';
import '../../domain/usecases/get_remote_verse.dart';

// -- Remote Bible wiring --------------------------------------------------
//
// The repository/use-case chain mirrors the rest of the app, but sits on its own
// `freeBibleDioProvider` (a plain, unauthenticated Dio) so nothing about this
// third-party host can touch the app's own auth flow.
//
// The remote endpoint is the only source of scripture **outside** the bundled
// English KJV database, which is why the Bible reader needs it: the global
// content language can ask for Nepali, and Nepali only exists there.

final remoteBibleRepositoryProvider = Provider<RemoteBibleRepository>((ref) {
  return RemoteBibleRepositoryImpl(
    RemoteBibleDataSource(ref.watch(freeBibleDioProvider)),
  );
});

final getRemoteVerseUseCaseProvider = Provider<GetRemoteVerseUseCase>((ref) {
  return GetRemoteVerseUseCase(ref.watch(remoteBibleRepositoryProvider));
});

final getRemoteChapterUseCaseProvider = Provider<GetRemoteChapterUseCase>((ref) {
  return GetRemoteChapterUseCase(ref.watch(remoteBibleRepositoryProvider));
});

final getRemoteBookNamesUseCaseProvider = Provider<GetRemoteBookNamesUseCase>((
  ref,
) {
  return GetRemoteBookNamesUseCase(ref.watch(remoteBibleRepositoryProvider));
});

/// The name of every book, in the **global** content language, keyed by USFM id.
///
/// English is served by the bundled offline KJV database, so its book names are
/// the canonical KJV ones and nothing has to be fetched. Nepali only exists on
/// the free remote endpoint, so the whole book list is fetched in one request
/// and cached for as long as the language stays put.
///
/// A failure is not fatal: the reader then keeps the English names, which is
/// the same "English until the translation arrives" behaviour the chapter
/// reader already has.
final bibleBookNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  if (language == ContentLanguage.english) return const {};

  final result = await ref
      .watch(getRemoteBookNamesUseCaseProvider)
      .call(translationId: ApiConstants.nepaliTranslationId)
      .run();

  return result.fold(
    (failure) => const <String, String>{},
    (names) => names,
  );
});
