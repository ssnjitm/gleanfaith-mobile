import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/providers/core_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../data/datasources/remote_bible_datasource.dart';
import '../../data/repositories/remote_bible_repository_impl.dart';
import '../../domain/entities/remote_bible_verse.dart';
import '../../domain/entities/verse_of_the_day.dart';
import '../../domain/repositories/remote_bible_repository.dart';
import '../../domain/services/daily_verse_plan.dart';
import '../../domain/usecases/get_remote_verse.dart';
import 'bible_providers.dart';
import 'verse_language_provider.dart';

// ── Remote Bible wiring ───────────────────────────────────────────────────
//
// The repository/use-case chain mirrors the rest of the app, but sits on its own
// `freeBibleDioProvider` (a plain, unauthenticated Dio) so nothing about this
// third-party host can touch the app's own auth flow.

final remoteBibleRepositoryProvider = Provider<RemoteBibleRepository>((ref) {
  return RemoteBibleRepositoryImpl(
    RemoteBibleDataSource(ref.watch(freeBibleDioProvider)),
  );
});

final getRemoteVerseUseCaseProvider = Provider<GetRemoteVerseUseCase>((ref) {
  return GetRemoteVerseUseCase(ref.watch(remoteBibleRepositoryProvider));
});

/// Shown only when the endpoint is unreachable for both languages.
const String kVerseFallbackText =
    'For I know the plans I have for you, declares the Lord, plans to '
    'prosper you and not to harm you, plans to give you hope and a future.';

const String kVerseFallbackReference = 'Jeremiah 29:11';

/// Last-resort verse, used only when the remote endpoint cannot be reached at
/// all.
///
/// It cannot be today's planned verse, so it always counts as a fallback: the
/// card shows the "translation unavailable" notice rather than pretending the
/// hardcoded verse is the curated one.
VerseOfTheDay verseFallbackFor(VerseLanguage language) {
  return VerseOfTheDay(
    text: kVerseFallbackText,
    reference: kVerseFallbackReference,
    book: 'Jeremiah',
    chapter: 29,
    verse: 11,
    language: language,
    isFallback: true,
  );
}

/// The Free Use Bible translation id backing [language].
String translationIdFor(VerseLanguage language) {
  return language == VerseLanguage.nepali
      ? ApiConstants.nepaliTranslationId
      : ApiConstants.englishTranslationId;
}

/// The verse to show for [date] in [language].
///
/// **Both languages resolve the same verse.** [date] is mapped through
/// [DailyVersePlan] to a curated reference, and only the *text* differs between
/// English and Nepali. The plan was verified to return real text in both
/// translations for all 365 entries, so a toggle always re-renders one verse
/// rather than swapping in a second one — the date, the deep link and the 7:00 AM
/// notification all stay in agreement.
///
/// Deliberately a plain function rather than a `FutureProvider.family`: the Home
/// card needs *today*, while the 7:00 AM notification needs the verse for
/// whichever day it will fire on (often tomorrow). Both call this, so the
/// notification can never drift out of sync with the card it is meant to match.
///
/// Dependencies are passed in rather than read from a `Ref`, because the Home
/// page is a `ConsumerState` (holding a `WidgetRef`, which is not a `Ref`) and
/// the provider is not. Naming them also makes this unit-testable without a
/// ProviderContainer.
///
/// [date] is the calendar day the verse belongs to, not "now".
Future<VerseOfTheDay> loadVerseOfTheDay({
  required DateTime date,
  required VerseLanguage language,
  required GetRemoteVerseUseCase getRemoteVerse,
}) async {
  final planned = DailyVersePlan.forDate(date);
  final fetched = await _tryFetch(
    getRemoteVerse: getRemoteVerse,
    language: language,
    planned: planned,
  );

  if (fetched != null) {
    LoggerService.info(
      'Verse of the day ${planned.label} '
      '(${translationIdFor(language)}) -> ${fetched.reference}',
    );
    return _toVerseOfTheDay(fetched, language);
  }

  // The selected translation failed. Serve the same verse in the other language
  // rather than a different one: the reference is the whole point, so a fallback
  // that quietly changed the verse would be worse than the notice.
  final otherLanguage = language == VerseLanguage.nepali
      ? VerseLanguage.english
      : VerseLanguage.nepali;
  LoggerService.warning(
    'Verse of the day ${planned.label} unavailable in '
    '${translationIdFor(language)} for $date; '
    'falling back to ${translationIdFor(otherLanguage)}',
  );

  final fallback = await _tryFetch(
    getRemoteVerse: getRemoteVerse,
    language: otherLanguage,
    planned: planned,
  );

  if (fallback != null) {
    // The card keeps the user's *chosen* language so the toggle stays put and
    // the "translation unavailable" notice can render.
    return _toVerseOfTheDay(fallback, language, isFallback: true);
  }

  return verseFallbackFor(language);
}

/// Fetches [planned] in [language], returning `null` instead of throwing.
///
/// The failure is logged rather than propagated: every caller here has a
/// fallback, and a thrown error would skip straight to the hardcoded verse
/// without ever trying the other language.
Future<RemoteBibleVerse?> _tryFetch({
  required GetRemoteVerseUseCase getRemoteVerse,
  required VerseLanguage language,
  required DailyVerseRef planned,
}) async {
  try {
    final result = await getRemoteVerse(
      translationId: translationIdFor(language),
      usfmBook: planned.book,
      chapter: planned.chapter,
      verse: planned.verse,
    ).run();
    return await result.fold((failure) => null, (verse) => verse);
  } catch (error) {
    LoggerService.warning(
      'Verse of the day ${planned.label} '
      '(${translationIdFor(language)}) threw: $error',
    );
    return null;
  }
}

/// Maps a fetched verse onto the display entity.
///
/// The reference is localised because the endpoint returns the book name in the
/// translation's own script, but [VerseOfTheDay.book] stays the canonical
/// English name: it is what feeds `RouteNames.bibleVerse`, and a Nepali book name
/// there would produce a deep link to a book the reader cannot resolve — which
/// fails silently, leaving the card looking perfectly fine.
VerseOfTheDay _toVerseOfTheDay(
  RemoteBibleVerse verse,
  VerseLanguage language, {
  bool isFallback = false,
}) {
  return VerseOfTheDay(
    text: verse.text,
    reference: verse.reference,
    book: kjvBookNameForCode(verse.usfmBook),
    chapter: verse.chapter,
    verse: verse.verse,
    language: language,
    isFallback: isFallback,
  );
}

/// The verse of the day for *today*, in the selected language.
///
/// Recomputes automatically at local midnight because it watches
/// `currentDateProvider`, and refetches immediately when the `EN | NP` toggle
/// changes.
final verseOfTheDayDisplayProvider = FutureProvider<VerseOfTheDay>((ref) async {
  final now = ref.watch(currentDateProvider);
  final language = ref.watch(verseLanguageProvider);
  return loadVerseOfTheDay(
    date: DateTime(now.year, now.month, now.day),
    language: language,
    getRemoteVerse: ref.watch(getRemoteVerseUseCaseProvider),
  );
});
